unit AK.RepositoryManagers;

{$I AK.Defines.inc}

interface

uses
  SysUtils, Classes, Generics.Collections, JSON,
  AK.Logger, AK.Base, AK.Indy;

type
  TAKRepoAction = (raPull, raPush, raDelete);

  TAKRepoFile = record
    Action: TAKRepoAction;
    Source: string;
    Destination: string;
    constructor Create(const AAction: TAKRepoAction; const ASource, ADestination: string);
  end;
  TAKRepoFiles = array of TAKRepoFile;

  TAKRepoCommit = record
  strict private
    function HasDestination(const ADestination: string): Boolean;
  public
    Message: string;
    Branch: string;
    Files: TAKRepoFiles;
    ActionInfo: string;
    procedure AddFile(const AAction: TAKRepoAction; const ASource, ADestination: string);
    procedure Empty;
    function IsEmpty: Boolean;
    constructor Create(const AMessage, ABranch: string);
  end;

  /// <summary>
  ///  Base class that implements the basic structure for a repo manager. It
  ///  implements standalone file-logging, all the configurable variables and
  ///  the main method "routing". It does not implement any actual HTTP request
  ///  since they depend entirely on the repository type. Uses a HTTP client
  ///  descending from the TIdHttp from the Indy library (see AK.Indy.pas).
  ///  Usage: for pull requests just use the Pull and PullFile methods, while
  ///  for push and delete requests create a commit with BeginCommit and call
  ///  AddToCommit for each file that has to be created/edited/deleted; once all
  ///  files have been added call SendCommit. To edit/delete a single file you
  ///  could also use the SinglePush and SingleDelete methods.
  /// </summary>
  TAKRepoManager = class abstract(TAKBase)
  strict private
    FHttp: TAKIndyHttp;
    FToken: string;
    FTokenFileName: string;
    FContentType: string;
    FRepoOwner: string;
    FRepoName: string;
    FRepoRootPath: string;
    FDownloadFolder: string;
    FCommit: TAKRepoCommit;
    FCurReqAction: string;
    FCurReqResource: string;
    FRaiseErrors: Boolean;
    procedure BeforeRequest(const AMethod: string);
    procedure AfterRequest(const AMethod: string);
    procedure DownloadFileFromResponse(var AResponse: string);
    procedure SetToken(const AValue: string);
    procedure SetTokenFileName(const AValue: string);
    procedure SetAuthorization(const AValue: string);
    procedure SetAccept(const AValue: string);
    procedure SetContentType(const AValue: string);
    procedure SetRepoRootPath(const AValue: string);
    procedure SetDownloadFolder(const AValue: string);
    function GetBranch(const ABranch: string): string;
    function Request(const ACommit: TAKRepoCommit): Boolean; overload;
    function Request(const AResourcePath, ABranch: string): string; overload;
    function GetDownloadFolder: string;
    function GetAuthorization: string;
    function GetAccept: string;
    function GetContentType: string;
  strict protected
    /// <summary>Authorization header value.</summary>
    property Authorization: string read GetAuthorization write SetAuthorization;
    /// <summary>Accept header value.</summary>
    property Accept: string read GetAccept write SetAccept;
    /// <summary>Content-Type header value (always empty for pull requests).</summary>
    property ContentType: string read GetContentType write SetContentType;
    /// <summary>Current action (Pull, Push, Delete or Mixed Commit), if any.</summary>
    property CurReqAction: string read FCurReqAction;
    /// <summary>Current requested resource, if any.</summary>
    property CurReqResource: string read FCurReqResource write FCurReqResource;

    function CreateLogger: TAKLogger; override;
    function FormatLog(const AString: string): string; override;
    function DoHttpRequest(const AMethod: TAKHttpMethod; const AUrl: string;
      const ASource: TStream; const AIgnoreReplies: array of Int16): string; overload;
    function DoHttpRequest(const AMethod: TAKHttpMethod; const AUrl: string;
      const ASource: TStream): string; overload;

    /// <summary>
    ///  This method is invoked anytime the token value has been changed,
    ///  override it to perform custom actions such as setting the Authorization
    ///  header. The default implementation does nothing.
    /// </summary>
    procedure OnTokenChanged; virtual;

    /// <summary>
    ///  Returns the log file name. Override it to change the log file name
    ///  without having to change the logger.
    /// </summary>
    class function GetLogFileName: string; virtual;

    { Methods to be implemented }

    /// <summary>
    ///  The default branch name for the repository (e.g. "main" for GitHub,
    ///  "master" for SVN, ...).
    /// </summary>
    function DefaultBranchName: string; virtual; abstract;

    /// <summary>
    ///  This function should return a stream filled with the contents of the
    ///  file to download while passing its name (relative to the root of the
    ///  repository) as an output parameter. When the response does not
    ///  represent a file, returned stream is expected to be nil.
    /// </summary>
    function ProcessResponseToDownload(const AResponse: string;
      out AFileName: string): TMemoryStream; virtual; abstract;

    /// <summary>
    ///  Main function that handler the HTTP requests that read the contents on
    ///  the repository. The returned value depends on the repository.
    /// </summary>
    /// <remarks>
    ///  AResourcePath could be a file or a directory.
    /// </remarks>
    function DoPullRequest(const AResourcePath, ABranch: string): string; virtual; abstract;

    /// <summary>
    ///  Main function that handles the HTTP requests that modify the contents
    ///  on the repository. Returns true when it's successful.
    /// </summary>
    function DoEditRequest(const ACommit: TAKRepoCommit): Boolean; virtual; abstract;
  public
    { Configurable properties }
    /// <summary>Authentication token value.</summary>
    property Token: string read FToken write SetToken;
    /// <summary>File where token value is stored (encrypted).</summary>
    property TokenFileName: string read FTokenFileName write SetTokenFileName;
    /// <summary>The name of the repository owner.</summary>
    property RepoOwner: string read FRepoOwner write FRepoOwner;
    /// <summary>The name of the repository.</summary>
    property RepoName: string read FRepoName write FRepoName;
    /// <summary>The local path that represents the root of the repository.</summary>
    property RepoRootPath: string read FRepoRootPath write SetRepoRootPath;
    /// <summary>
    ///  The folder in which downloaded files are put. When not manually set it
    ///  returns RepoRootPath.
    /// </summary>
    property DownloadFolder: string read GetDownloadFolder write SetDownloadFolder;
    /// <summary>Request exceptions are not raised when False. Defaults to True.</summary>
    /// <remarks>Errors on commit state are always raised.</remarks>
    property RaiseErrors: Boolean read FRaiseErrors write FRaiseErrors;

    /// <summary>
    ///  Requests the specified resource and behaves differently depending on
    ///  its type: for a file it downloads it under the download folder (the
    ///  default is RepoRootPath), preserving its relative path to the root of
    ///  the repository, and it's downloaded name is returned; for a directory
    ///  it is downloaded recursively and the returned value may vary; for any
    ///  other type the HTTP response text is returned.
    /// <summary>
    function Pull(const AResourcePath: string; const ABranch: string = ''): string;

    /// <summary>
    ///  Shortcut to multiple Pull calls. Returns the list of each return value,
    ///  separated by a line break.
    /// </summary>
    function PullFiles(const AResourcePaths: array of string; const ABranch: string = ''): string;

    /// <summary>
    ///  Posts a file to the given path on the repo server. When ADestination
    ///  doesn't end with a file extension, the file name is appended at the end
    ///  of it, otherwise it's used as the full name for the pushed file.
    /// </summary>
    function SinglePush(const AMessage, AFileName, ADestination, ABranch: string): Boolean; overload;

    /// <summary>
    ///  Posts a file to the corresponding path (relative to the RepoRootPath)
    ///  on the repo server. Returns true on success.
    /// </summary>
    function SinglePush(const AMessage, AFileName: string; const ABranch: string = ''): Boolean; overload;

    /// <summary>
    ///  Deletes the given resource and returns the text response of the server.
    ///  Returns true on success.
    /// </summary>
    function SingleDelete(const AMessage, AResourcePath: string; const ABranch: string = ''): Boolean;

    /// <summary>
    ///  Creates and starts a new commit.
    /// </summary>
    procedure BeginCommit(const AMessage, ABranch: string);

    /// <summary>
    ///  Adds a file to be processed in the current commit. The given file must
    ///  exist for PUSH commits. If the given destination doesn't end with a
    ///  file extension, it is considered to be a path and the file name is
    ///  appendended at the end, accordingly (the delimiter is added if needed).
    /// </summary>
    procedure AddToCommit(const AAction: TAKRepoAction; const AFileName, ADestination: string); overload;

    /// <summary>
    ///  Adds a file to be processed in the current commit. The given file must
    ///  exist for PUSH commits. The destination path is obtained extracting the
    ///  relative path of the given file to the RepoRootPath.
    /// </summary>
    procedure AddToCommit(const AAction: TAKRepoAction; const AFileName: string); overload;

    /// <summary>
    ///  Cancels the current commit, if any.
    /// </summary>
    procedure CancelCommit;

    /// <summary>
    ///  Sends the current commit to the repository. Returns true on success.
    /// </summary>
    function SendCommit: Boolean;

    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Class to manage Github repositories via the Github API.
  /// </summary>
  TAKGithubRepoManager = class(TAKRepoManager)
  strict private
    FBaseUrl: string;
    const
      DEFAULT_BASE_URL = 'https://api.github.com/repos';
      DEFAULT_ACCEPT = 'application/vnd.github.v3+json';
    procedure JSONObjectUse(const AString: string; const AProc: TProc<TJSONObject>);
    procedure JSONObjectGet(const AUrl: string; const AProc: TProc<TJSONObject>);
    function CreateFileBlob(const AFileName: string): string;
    function ApplyCommitToTree(const ACommit: TAKRepoCommit; const ATree: TJSONArray): Boolean;
    function GetBaseUrl: string;
    function GetContentUrl(const AResourcePath, ABranch: string): string;
    function GetRefUrl(const ABranch: string): string;
    function GetCommitUrl(const ABranch: string): string;
    function GetTreeUrl(const ASha: string = ''): string;
    function GetBlobUrl: string;
  strict protected
    procedure OnTokenChanged; override;
    function DefaultBranchName: string; override;
    function ProcessResponseToDownload(const AResponse: string; out AFileName: string): TMemoryStream; override;
    function DoPullRequest(const AResourcePath, ABranch: string): string; override;
    function DoEditRequest(const ACommit: TAKRepoCommit): Boolean; override;
  public
    property BaseUrl: string read GetBaseUrl write FBaseUrl;

    constructor Create;
  end;

implementation

uses
  StrUtils, IOUtils,
  AK.Constants, AK.Utils, AK.Crypt;

function GetRequestFunctionName(const AMethod: TAKHttpMethod): string;
begin
  case AMethod of
    hmGet: Result := 'PULL';
    hmPost: Result := 'PUSH';
    hmPut: Result := 'PUSH';
    hmDelete: Result := 'DELETE';
  end;
end;

{ TAKRepoActionedFile }

constructor TAKRepoFile.Create(const AAction: TAKRepoAction; const ASource, ADestination: string);
begin
  Action := AAction;
  Source := ASource;
  Destination := ADestination;
end;

{ TAKRepoCommit }

procedure TAKRepoCommit.AddFile(const AAction: TAKRepoAction; const ASource, ADestination: string);
var
  LLength: Integer;
begin
  if HasDestination(ADestination) then
    raise EAKError<TAKRepoCommit>.Create('Destination file already listed.');
  LLength := Length(Files);
  SetLength(Files, LLength + 1);
  Files[LLength] := TAKRepoFile.Create(AAction, ASource, ADestination);
end;

constructor TAKRepoCommit.Create(const AMessage, ABranch: string);
begin
  Assert((AMessage <> '') and (ABranch <> ''));

  Message := AMessage;
  Branch := ABranch;
end;

procedure TAKRepoCommit.Empty;
begin
  Message := '';
  Branch := '';
  SetLength(Files, 0);
end;

function TAKRepoCommit.HasDestination(const ADestination: string): Boolean;
var
  I: Integer;
begin
  for I := Low(Files) to High(Files) do
    if Files[I].Destination = ADestination then
      Exit(True);
  Result := False;
end;

function TAKRepoCommit.IsEmpty: Boolean;
begin
  Result := (Message = '') and (Branch = '') and (Length(Files) = 0);
end;

{ TAKRepoManager }

procedure TAKRepoManager.AddToCommit(const AAction: TAKRepoAction; const AFileName, ADestination: string);
var
  LDestination: string;
begin
  if FCommit.IsEmpty then
    raise AKException(EAKStateError, 'A commit is not being processed yet, begin it first.');
  Assert(AAction <> raPull, 'PULL actions do not take part in a commit.');
  Assert((AFileName <> '') or (ADestination <> ''));

{
  1. AFileName = ''
    1.1 ADestination = '' => Assertion failure
    1.2 ADestination = 'some/path/' => 'some/path/'
    1.3 ADestination = 'some/path' => 'some/path/'
    1.4 ADestination = 'some/path/doc.pdf' => 'some/path/doc.pdf'

  2. AFileName = 'some\local\path\text.txt'
    2.1 ADestination = '' => 'text.txt'
    2.2 ADestination = 'some/path/' => 'some/path/text.txt'
    2.3 ADestination = 'some/path' => 'some/path/text.txt'
    2.4 ADestination = 'some/path/doc.pdf' => 'some/path/doc.pdf'
}
  LDestination := ADestination;
  if LDestination = '' then
    LDestination := ExtractFileName(AFileName)
  else if ExtractFileExt(LDestination) = '' then
  begin
    if LDestination[High(LDestination)] <> '/' then
      LDestination := LDestination + '/';
    LDestination := LDestination + ExtractFileName(AFileName);
  end;

  case AAction of
    raPull: raise AKException(EAKDataError,'Unexpected commit action.');
    raPush: Assert(FileExists(AFileName), 'File "%s" not found.');
    raDelete: ; // Everything has already been accounted for deletes.
  end;

  FCommit.AddFile(AAction, AFileName, LDestination);
  if FCommit.ActionInfo = '' then
    FCommit.ActionInfo := TAKEnum<TAKRepoAction>.Name(AAction)
  else if FCommit.ActionInfo <> TAKEnum<TAKRepoAction>.Name(AAction) then
    FCommit.ActionInfo := 'Mixed Commit'
end;

procedure TAKRepoManager.AddToCommit(const AAction: TAKRepoAction; const AFileName: string);
var
  LDestination: string;
begin
  LDestination := SlicePath(AFileName, RepoRootPath);
  if LDestination = '' then
    raise AKException(EAKNotFoundError, 'File "%s" is not under repository path "%s".',
      [AFileName, RepoRootPath]);

  LDestination := ReplaceStr(LDestination, PathDelim, '/');
  AddToCommit(AAction, AFileName, LDestination);
end;

procedure TAKRepoManager.AfterRequest(const AMethod: string);
var
  LIndex: Integer;
begin
  LIndex := FHttp.Request.CustomHeaders.IndexOfName('Content-Type');
  if LIndex > -1 then
    FHttp.Request.CustomHeaders.Delete(LIndex);
end;

procedure TAKRepoManager.BeforeRequest(const AMethod: string);
begin
  if not SameText(AMethod, 'GET') then
    FHttp.Request.CustomHeaders.Values['Content-Type'] := FContentType;
end;

procedure TAKRepoManager.BeginCommit(const AMessage, ABranch: string);
begin
  if not FCommit.IsEmpty then
    raise AKException(EAKStateError, 'A commit is already being processed, send or cancel it first.');
  FCommit := TAKRepoCommit.Create(AMessage, GetBranch(ABranch));
end;

procedure TAKRepoManager.CancelCommit;
begin
  // Just clear it Delphi-side. Repository servers usually have their own way to
  // clean orphans, tipically a timed garbage collector.
  FCommit.Empty;
end;

constructor TAKRepoManager.Create;
begin
  inherited;
  FHttp := TAKIndyHttp.Create(nil);
  FHttp.BeforeRequest := BeforeRequest;
  FHttp.AfterRequest := AfterRequest;
  FRaiseErrors := True;
  TokenFileName := AppPath + 'repo_token.txt';
  if FToken <> '' then
    OnTokenChanged;
  Logger.FormatLog := FormatLog;
end;

function TAKRepoManager.CreateLogger: TAKLogger;
begin
  Result := TAKFileLogger.Create(GetLogFileName);
end;

destructor TAKRepoManager.Destroy;
begin
  FreeAndNil(FHttp);
  inherited;
end;

function TAKRepoManager.DoHttpRequest(const AMethod: TAKHttpMethod; const AUrl: string;
  const ASource: TStream; const AIgnoreReplies: array of Int16): string;
begin
  Result := FHttp.DoRequest(AMethod, AUrl, ASource, AIgnoreReplies);
end;

function TAKRepoManager.DoHttpRequest(const AMethod: TAKHttpMethod;
  const AUrl: string; const ASource: TStream): string;
begin
  Result := DoHttpRequest(AMethod, AUrl, ASource, []);
end;

procedure TAKRepoManager.DownloadFileFromResponse(var AResponse: string);
var
  LStream: TMemoryStream;
  LFileName: string;
begin
  LStream := ProcessResponseToDownload(AResponse, LFileName);
  if not Assigned(LStream) then
    Exit;
  try
    AResponse := DownloadFolder + LFileName;
    SaveStreamToFile(AResponse, LStream);
  finally
    FreeAndNil(LStream);
  end;
end;

function TAKRepoManager.FormatLog(const AString: string): string;
begin
  Result := Format('[%s %s%s] %s', [AKClassName, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now),
    IfThen(FCurReqAction <> '', ' ' + FCurReqAction), AString]);
end;

function TAKRepoManager.GetAccept: string;
begin
  Result := FHttp.Request.CustomHeaders.Values['Accept'];
end;

function TAKRepoManager.GetAuthorization: string;
begin
  Result := FHttp.Request.CustomHeaders.Values['Authorization'];
end;

function TAKRepoManager.GetBranch(const ABranch: string): string;
begin
  if ABranch = '' then
    Result := DefaultBranchName
  else
    Result := ABranch;
end;

function TAKRepoManager.GetContentType: string;
begin
  Result := FHttp.Request.CustomHeaders.Values['Content-Type'];
end;

function TAKRepoManager.GetDownloadFolder: string;
begin
  Result := FDownloadFolder;
  if Result = '' then
    Result := RepoRootPath;
end;

class function TAKRepoManager.GetLogFileName: string;
begin
  Result := Format('%s%s_%s.log', [AppPath, AKClassName, FormatDateTime('yyyymm', Now)]);
end;

procedure TAKRepoManager.OnTokenChanged;
begin
end;

function TAKRepoManager.Pull(const AResourcePath, ABranch: string): string;
begin
  Result := Request(AResourcePath, GetBranch(ABranch));
end;

function TAKRepoManager.PullFiles(const AResourcePaths: array of string;
  const ABranch: string): string;
var
  LBranch: string;
  I: Integer;
begin
  Result := '';
  LBranch := GetBranch(ABranch);
  for I := Low(AResourcePaths) to High(AResourcePaths) do
    if Result = '' then
      Result := Request(AResourcePaths[I], LBranch)
    else
      Result := Result + sLineBreak + Request(AResourcePaths[I], LBranch);
end;

function TAKRepoManager.Request(const AResourcePath, ABranch: string): string;
begin
  FCurReqAction := 'Pull';
  try
    Logger.Log('New request.', LOG_MEDIUM);
    try
      Result := DoPullRequest(AResourcePath, ABranch);
      Logger.Log('Request completed.', LOG_MEDIUM);
      DownloadFileFromResponse(Result);
    except
      on E: Exception do
      begin
        Logger.Log('ERROR: %s', [E.Message], LOG_MINIMAL);
        if CurReqResource <> '' then
          Logger.Log('While requesting resource "%s".', [CurReqResource], LOG_HIGH);
        if FRaiseErrors then
          raise;
      end;
    end;
  finally
    FCurReqAction := '';
    FCurReqResource := '';
  end;
end;


function TAKRepoManager.Request(const ACommit: TAKRepoCommit): Boolean;
begin
  FCurReqAction := ACommit.ActionInfo;
  try
    Result := False;
    if Length(ACommit.Files) = 0 then
    begin
      Logger.Log('No file for this request: exited.', LOG_MEDIUM);
      Exit;
    end;
    Logger.Log('New request.', LOG_MEDIUM);
    try
      Result := DoEditRequest(ACommit);
      Logger.Log('Request completed.', LOG_MEDIUM);
    except
      on E: Exception do
      begin
        Logger.Log('ERROR: %s', [E.Message], LOG_MINIMAL);
        if CurReqResource <> '' then
          Logger.Log('While requesting resource "%s".', [CurReqResource], LOG_HIGH);
        if FRaiseErrors then
          raise;
      end;
    end;
  finally
    FCurReqAction := '';
    FCurReqResource := '';
  end;
end;

function TAKRepoManager.SendCommit: Boolean;
begin
  if FCommit.IsEmpty then
    raise AKException(EAKStateError, 'A commit is not being processed yet, begin it first.');
  try
    Result := Request(FCommit);
  finally
    FCommit.Empty;
  end;
end;

procedure TAKRepoManager.SetAccept(const AValue: string);
begin
  FHttp.Request.CustomHeaders.Values['Accept'] := AValue;
end;

procedure TAKRepoManager.SetAuthorization(const AValue: string);
begin
  FHttp.Request.CustomHeaders.Values['Authorization'] := AValue;
end;

procedure TAKRepoManager.SetContentType(const AValue: string);
begin
  FContentType := AValue;
  FHttp.Request.CustomHeaders.Values['Content-Type'] := AValue;
end;

procedure TAKRepoManager.SetDownloadFolder(const AValue: string);
begin
  if DirectoryExists(AValue) then
    FDownloadFolder := IncludeTrailingPathDelimiter(AValue);
end;

procedure TAKRepoManager.SetRepoRootPath(const AValue: string);
begin
  if not DirectoryExists(AValue) then
    raise AKException(EAKNotFoundError, 'Directory "%s" not found.', [AValue]);
  FRepoRootPath := IncludeTrailingPathDelimiter(AValue);
end;

procedure TAKRepoManager.SetToken(const AValue: string);
var
  LEncrypter: TAKAESEncrypter;
begin
  if (AValue = '') or (AValue = FToken) then
    Exit;

  FToken := AValue;
  if FTokenFileName <> '' then
  begin
    LEncrypter := TAKAESEncrypter.Create;
    try
      SaveTextToFile(FTokenFileName, LEncrypter.EncryptString(FToken));
    finally
      FreeAndNil(LEncrypter);
    end;
  end;
  OnTokenChanged;
end;

procedure TAKRepoManager.SetTokenFileName(const AValue: string);
var
  LContent: string;
  LEncrypter: TAKAESEncrypter;
begin
  FTokenFileName := AValue;
  if not FileExists(AValue) then
    Exit;

  LContent := LoadTextFromFile(AValue);
  if LContent = '' then
    Exit;

  LEncrypter := TAKAESEncrypter.Create;
  try
    LContent := LEncrypter.DecryptString(LContent);
    if FToken <> LContent then
    begin
      FToken := LContent;
      OnTokenChanged;
    end;
  finally
    FreeAndNil(LEncrypter);
  end;
end;

function TAKRepoManager.SingleDelete(const AMessage, AResourcePath,
  ABranch: string): Boolean;
begin
  BeginCommit(AMessage, ABranch);
  try
    AddToCommit(raDelete, '', AResourcePath);
    Result := SendCommit;
  except
    CancelCommit;
    raise;
  end;
end;

function TAKRepoManager.SinglePush(const AMessage, AFileName, ADestination,
  ABranch: string): Boolean;
begin
  BeginCommit(AMessage, ABranch);
  try
    AddToCommit(raPush, AFileName, ADestination);
    Result := SendCommit;
  except
    CancelCommit;
    raise;
  end;
end;

function TAKRepoManager.SinglePush(const AMessage, AFileName,
  ABranch: string): Boolean;
begin
  Result := SinglePush(AMessage, AFileName, '', ABranch);
end;

{ TAKGithubRepoManager }

function TAKGithubRepoManager.ApplyCommitToTree(const ACommit: TAKRepoCommit;
  const ATree: TJSONArray): Boolean;
var
  LFile: TAKRepoFile;
  LIsDirectory: Boolean;
  LBlobSha: string;
  LItem: TJSONObject;
  I: Integer;

  function DoFileMatch(const ADestination, AFile: string): Boolean;
  begin
    if LIsDirectory then
      Result := Pos(ADestination, AFile) > 0
    else
      Result := ADestination = AFile;
  end;
begin
  Result := False;
  for LFile in ACommit.Files do
  begin
    LIsDirectory := LFile.Destination[High(LFile.Destination)] = '/';
    if LFile.Action = raPush then
      LBlobSha := CreateFileBlob(LFile.Source);
    for I := ATree.Count - 1 downto 0 do
    begin
      LItem := ATree[I] as TJSONObject;

      // Remove folders: git does not need them and they can involuntarily
      // preserve files that are being deleted. Removing them is secure, simple
      // and harmless.
      if LItem.GetValue<string>('type') = 'tree' then
      begin
        ATree.Remove(I);
        Continue;
      end;

      // Skip all the non files.
      if LItem.GetValue<string>('type') <> 'blob' then
        Continue;
      // Process only the searched file and its subfiles (if it is a directory).
      if not DoFileMatch(LFile.Destination, LItem.GetValue<string>('path')) then
        Continue;

      Result := True;
      if LBlobSha = '' then
      begin
        // If blob SHA is empty it's a delete - remove the matching file.
        ATree.Remove(I);
        if not LIsDirectory then
          Break;
      end
      else
      begin
        // If not it's an update, just replace the blob SHA.
        LItem.RemovePair('sha');
        LItem.AddPair('sha', LBlobSha);
        LBlobSha := ''; // Clear this to mark it as done.
        Break;
      end;
    end;
    // If the blob SHA is not empty it's an unprocessed file - add it.
    if LBlobSha <> '' then
    begin
      Result := True;
      ATree.Add(TJSONObject.ParseJSONValue(Format(
        '{"path": "%s", "mode": "100644", "type": "blob", "sha": "%s"}',
        [LFile.Destination, LBlobSha])) as TJSONObject);
    end;
  end;
end;

constructor TAKGithubRepoManager.Create;
begin
  inherited Create;
  BaseUrl := DEFAULT_BASE_URL;
  Accept := DEFAULT_ACCEPT;
  RepoRootPath := AppPath;
end;

function TAKGithubRepoManager.CreateFileBlob(const AFileName: string): string;
var
  LContent: string;
  LBody: TStringStream;
  LResult: string;
begin
  Assert(FileExists(AFileName));

  LContent := TAKIndyEncoderMIME.EncodeBytes(TFile.ReadAllBytes(AFileName));
  LBody := TStringStream.Create(Format('{"content": "%s", "encoding": "base64"}', [LContent]));
  try
    JSONObjectUse(DoHttpRequest(hmPost, GetBlobUrl, LBody),
      procedure (AObject: TJSONObject)
      begin
        LResult := AObject.GetValue<string>('sha');
      end);
    Result := LResult;
  finally
    FreeAndNil(LBody);
  end;
end;

function TAKGithubRepoManager.DefaultBranchName: string;
begin
  Result := 'main';
end;

function TAKGithubRepoManager.DoEditRequest(const ACommit: TAKRepoCommit): Boolean;
const
  EMPTY_TREE_SHA = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';
var
  LCommitSha: string;
  LTreeSha: string;
  LNewTree: TJSONArray;
  LBody: string;
  LStream: TStringStream;
begin
  // Get commit and tree SHAs.
  Logger.Log('Fetching last commit data...', LOG_HIGH);
  JSONObjectGet(GetCommitUrl(ACommit.Branch), procedure (AObject: TJSONObject)
    begin
      LCommitSha := AObject.GetValue<string>('sha');
      LTreeSha := AObject.GetValue<string>('commit.tree.sha');
    end);
  Logger.Log('Done.', LOG_HIGH);
  Logger.Log('Commit: %s, Tree: %s.', [LCommitSha, LTreeSha], LOG_DETAILED);

  // Get full tree, apply edits on it, and set it as the JSON body.
  Logger.Log('Applying the edits on the tree...', LOG_HIGH);
  if LTreeSha = EMPTY_TREE_SHA then
  begin
    LNewTree := TJSONArray.Create;
    try
      if ApplyCommitToTree(ACommit, LNewTree) then
        LBody := Format('{"tree": %s}', [LNewTree.ToJSON]);
      // no "else" case: if it was unmodified LTreeSha is already correct.
    finally
      FreeAndNil(LNewTree);
    end;
  end
  else
  begin
    JSONObjectGet(GetTreeUrl(LTreeSha), procedure (AObject: TJSONObject)
      var
        LTree: TJSONArray;
      begin
        LTree := AObject.GetValue<TJSONArray>('tree');
        if ApplyCommitToTree(ACommit, LTree) and (LTree.Count > 0) then
          LBody := Format('{"tree": %s}', [LTree.ToJSON])
        else if LTree.Count = 0 then
          LTreeSha := EMPTY_TREE_SHA;
        // no "else" case: if it was unmodified LTreeSha is already correct.
      end);
  end;
  Logger.Log('Done.', LOG_HIGH);

  if LBody <> '' then
  begin
    Logger.Log('The tree was edited, posting it...', LOG_DETAILED);
    LStream := TStringStream.Create(LBody, TEncoding.UTF8);
    try
      CurReqResource := GetTreeUrl;
      JSONObjectUse(DoHttpRequest(hmPost, CurReqResource, LStream),
        procedure (AObject: TJSONObject)
        begin
          LTreeSha := AObject.GetValue<string>('sha');
        end);
    finally
      FreeAndNil(LStream);
    end;
    Logger.Log('Tree posted: %s.', [LTreeSha], LOG_DETAILED);
  end
  else
    Logger.Log('The tree is unmodified or empty: %s.', [LTreeSha], LOG_DETAILED);

  // Post the new commit with the new tree SHA.
  Logger.Log('Creating the new commit...', LOG_HIGH);
  LBody := Format('{"message": "%s", "tree": "%s", "parents": ["%s"]}',
    [EscapeJSONString(ACommit.Message), LTreeSha, LCommitSha]);
  LStream := TStringStream.Create(LBody, TEncoding.UTF8);
  try
    CurReqResource := GetCommitUrl('');
    JSONObjectUse(DoHttpRequest(hmPost, CurReqResource, LStream),
      procedure (AObject: TJSONObject)
      begin
        LBody := Format('{"sha": "%s", "force": false}', [AObject.GetValue<string>('sha')]);
      end);
  finally
    FreeAndNil(LStream);
  end;
  Logger.Log('Done.', LOG_HIGH);

  // Patch the branch to make the new commit active.
  Logger.Log('Applying the commit...', LOG_HIGH);
  LStream := TStringStream.Create(LBody, TEncoding.UTF8);
  try
    CurReqResource := GetRefUrl(ACommit.Branch);
    DoHttpRequest(hmPatch, CurReqResource, LStream);
  finally
    FreeAndNil(LStream);
  end;
  Logger.Log('Done.', LOG_HIGH);
  Result := True;
end;

function TAKGithubRepoManager.DoPullRequest(const AResourcePath,
  ABranch: string): string;
var
  LResponse: TJSONValue;
  LItem: TJSONValue;
  LFileType: string;
  LFilePath: string;
  LStream: TBytesStream;
begin
  CurReqResource := GetContentUrl(AResourcePath, ABranch);
  LResponse := TJSONObject.ParseJSONValue(DoHttpRequest(hmGet, CurReqResource, nil));
  if not Assigned(LResponse) then
    raise AKException(EAKFormatError, 'Invalid JSON.');
  try
    if LResponse is TJSONObject then
      // Plain response (non-directory), default behaviour.
      Result := LResponse.ToJSON
    else if LResponse is TJSONArray then
    begin
      // Directory: enumerate its contents.
      for LItem in (LResponse as TJSONArray) do
      begin
        LFileType := LItem.GetValue<string>('type');
        LFilePath := LItem.GetValue<string>('path');
        CurReqResource := LFilePath;
        if SameText(LFileType, 'dir') then
        begin
          // Subdirectory: make a recursive call on it.
          Logger.Log('Subdirectory "%s" found, recursive call.', [LFilePath], LOG_HIGH);
          DoPullRequest(LFilePath, ABranch);
        end
        else if SameText(LFileType, 'file') then
        begin
          // File: download it.
          Logger.Log('Found file "%s".', [LFilePath], LOG_HIGH);
          LStream := TBytesStream.Create(TAKIndyEncoderMime.DecodeBytes(LItem.GetValue<string>('content')));
          try
            SaveStreamToFile(DownloadFolder + ReplaceStr(LFilePath, '/', PathDelim), LStream);
          finally
            FreeAndNil(LStream);
          end;
        end
        else
          // Skip everything that is neither a file or a directory.
          Logger.Log('Found "%s" of unknown type "%s": skipped.', [LFilePath, LFileType], LOG_HIGH);
      end;
    end
    else
      // Unexpected JSON structure in response.
      raise AKException(EAKFormatError, 'Unexpected JSON response (%s).', [LResponse.ToJSON]);
  finally
    FreeAndNil(LResponse);
  end;
end;

function TAKGithubRepoManager.GetBaseUrl: string;
begin
  if FBaseUrl[High(FBaseUrl)] = '/' then
    System.Delete(FBaseUrl, High(FBaseUrl), 1);
  Result := FBaseUrl;
end;

function TAKGithubRepoManager.GetBlobUrl: string;
begin
  Result := Format('%s/%s/%s/git/blobs', [BaseUrl, RepoOwner, RepoName]);
end;

function TAKGithubRepoManager.GetCommitUrl(const ABranch: string): string;
begin
  if ABranch = '' then
    Result := Format('%s/%s/%s/git/commits', [BaseUrl, RepoOwner, RepoName])
  else
    Result := Format('%s/%s/%s/commits/%s', [BaseUrl, RepoOwner, RepoName, ABranch]);
end;

function TAKGithubRepoManager.GetContentUrl(const AResourcePath, ABranch: string): string;
begin
  Result := Format('%s/%s/%s/contents/%s?ref=%s', [BaseUrl, RepoOwner, RepoName,
    EncodeURLPath(AResourcePath), ABranch]);
end;

function TAKGithubRepoManager.GetRefUrl(const ABranch: string): string;
begin
  Result := Format('%s/%s/%s/git/refs/heads/%s', [BaseUrl, RepoOwner, RepoName, ABranch]);
end;

function TAKGithubRepoManager.GetTreeUrl(const ASha: string): string;
begin
  Result := Format('%s/%s/%s/git/trees', [BaseUrl, RepoOwner, RepoName]);
  if ASha <> '' then
    Result := Format(Result + '/%s?recursive=1', [ASha]);
end;

procedure TAKGithubRepoManager.JSONObjectGet(const AUrl: string;
  const AProc: TProc<TJSONObject>);
begin
  CurReqResource := AUrl;
  JSONObjectUse(DoHttpRequest(hmGet, AUrl, nil), AProc);
end;

procedure TAKGithubRepoManager.JSONObjectUse(const AString: string;
  const AProc: TProc<TJSONObject>);
var
  LValue: TJSONValue;
begin
  Assert(Assigned(AProc));

  LValue := TJSONObject.ParseJSONValue(AString);
  if not Assigned(LValue) then
    raise AKException(EAKFormatError, 'Invalid JSON (%s).', [AString]);
  try
    if not (LValue is TJSONObject) then
      raise AKException(EAKFormatError, 'Invalid JSON object (%s).', [LValue.ToJSON]);
    AProc(LValue as TJSONObject);
  finally
    FreeAndNil(LValue);
  end;
end;

procedure TAKGithubRepoManager.OnTokenChanged;
begin
  inherited;
  Authorization := 'token ' + Token;
end;

function TAKGithubRepoManager.ProcessResponseToDownload(const AResponse: string;
  out AFileName: string): TMemoryStream;
var
  LJSONValue: TJSONValue;
  LJSONObject: TJSONObject;
  LBase64: string;
  LContent: TBytes;
begin
  Result := nil;
  LJSONValue := TJSONObject.ParseJSONValue(AResponse);
  if not Assigned(LJSONValue) then
    Exit;
  try
    if not (LJSONValue is TJSONObject) then
      raise AKException(EAKFormatError, 'Invalid JSON object "%s".', [AResponse]);
    LJSONObject := LJSONValue as TJSONObject;
    if LJSONObject.TryGetValue<string>('path', AFileName) then
      AFileName := ReplaceStr(AFileName, '/', PathDelim)
    else
      Exit;
    if LJSONObject.TryGetValue<string>('content', LBase64) then
      LContent := TAKIndyEncoderMime.DecodeBytes(LBase64)
    else
      Exit;

    Result := TBytesStream.Create(LContent);
  finally
    FreeAndNil(LJSONValue);
  end;
end;

end.
