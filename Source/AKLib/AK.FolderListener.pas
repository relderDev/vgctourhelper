unit AK.FolderListener;

{$I AK.Defines.inc}

interface

uses
  SysUtils,{$IFNDEF WINAPI_ON} Threading, Generics.Collections,{$ELSE}
  Winapi.Windows, Winapi.Messages, Winapi.ShlObj,{$ENDIF}
  AK.Base;

type
  TAKFileEvent = (feUpdate, feRename, feDelete, feCreate);
  TAKFileObserverProc = reference to procedure (const AFileName: string; const AEvent: TAKFileEvent);
  TAKFolderListener = class;
  {$IFNDEF WINAPI_ON}
  TAKFileSnapshot = record
    FileName: string;
    Edited: TDateTime;
    Size: Integer;
    function CheckRename(const AFileSnapshot: TAKFileSnapshot): Boolean;
    constructor Create(const AName: string; const AEdited: TDateTime; const ASize: Integer);
  end;
  TAKDirSnapshot = class(TDictionary<string, TAKFileSnapshot>)
  public
    procedure Add(const AFileName: string; const AEdited: TDateTime; const ASize: Integer);
  end;
  TAKDirDifferences = TDictionary<string, TAKFileEvent>;
  {$ELSE}
  TAKMessageHandler = procedure (const AFileName: string; const AEvent: TAKFileEvent) of object;
  TAKFolderListenerMessageWindow = class
  strict private
    FHandle: HWND;
    FHandler: TAKMessageHandler;
    FPath: string;
    FNotifyHandle: Integer;
    FNotifyEntry: SHChangeNotifyEntry;
    class function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; static;
    procedure OnNotification(const AWParam: WPARAM; const ALParam: LPARAM);
    const WM_SHNOTIFY = WM_USER + 215;
  public
    constructor Create(const AHandler: TAKMessageHandler; const APath: string);
    destructor Destroy; override;
  end;
  {$ENDIF}

  TAKFolderListener = class
  strict private
    FFolderPath: string;
    FObserver: TAKFileObserverProc;
    FOnException: TAKExceptionProc;
    FPollingInterval: Integer;
    {$IFNDEF WINAPI_ON}
    FLastSnapshot: TAKDirSnapshot;
    FMonitorTask: ITask;
    FTaskStopped: Boolean;
    // This procedure must receive arguments by value because it's threaded.
    procedure NotifyToMainThread(AFileName: string; AEvent: TAKFileEvent);
    procedure DoMonitorTask;
    function CreateSnapshot: TAKDirSnapshot;
    function CompareNowWithSnapshot(out ADifferences: TAKDirDifferences): Boolean;
    {$ELSE}
    FMessagesWindow: TAKFolderListenerMessageWindow;
    {$ENDIF}
    procedure SetPollingInterval(const AValue: Integer);
    procedure SetOnException(const AValue: TAKExceptionProc);
    function GetIsRunning: Boolean;
  strict protected
    procedure ProcessNotification(const AFileName: string; const AEvent: TAKFileEvent); virtual;
  public
    ///<summary>The polling time interval. Unused on windows (always -1).</summary>
    property PollingInterval: Integer read FPollingInterval write SetPollingInterval;
    ///<summary>Procedure to call on exceptions.</summary>
    property OnException: TAKExceptionProc read FOnException write SetOnException;
    ///<summary>Returns whether or not the listener is active.</summary>
    property IsRunning: Boolean read GetIsRunning;
    ///<summary>Starts the listener.</summary>
    procedure Start;
    ///<summary>Stops the listener.</summary>
    procedure Stop;
    constructor Create(const APath: string; const AProc: TAKFileObserverProc);
    destructor Destroy; override;
  end;

implementation

uses
  {$IFNDEF WINAPI_ON}Classes, Generics.Defaults,{$ENDIF}
  AK.Utils;

{$IFNDEF WINAPI_ON}
{ TAKFileSnapshot }

function TAKFileSnapshot.CheckRename(const AFileSnapshot: TAKFileSnapshot): Boolean;
begin
  Result := (AFileSnapshot.Edited = Edited) and (AFileSnapshot.Size = Size);
end;

constructor TAKFileSnapshot.Create(const AName: string;
  const AEdited: TDateTime; const ASize: Integer);
begin
  FileName := AName;
  Edited := AEdited;
  Size := ASize;
end;

{ TAKDirSnapshot }

procedure TAKDirSnapshot.Add(const AFileName: string; const AEdited: TDateTime;
  const ASize: Integer);
begin
  Assert(AFileName <> '');
  Assert(AEdited <> 0);

  inherited Add(AFileName, TAKFileSnapshot.Create(AFileName, AEdited, ASize));
end;
{$ELSE}
function GetFileEvent(const AEventId: Integer): TAKFileEvent;
begin
  case AEventId of
    SHCNE_UPDATEITEM: Result := feUpdate;
    SHCNE_RENAMEITEM: Result := feRename;
    SHCNE_DELETE: Result := feDelete;
    SHCNE_CREATE: Result := feCreate;
    else raise Exception.CreateFmt('Unknown event id %d.', [AEventId]);
  end;
end;

{ TAKFolderListenerMessageWindow }

constructor TAKFolderListenerMessageWindow.Create(const AHandler: TAKMessageHandler; const APath: string);
var
  LWindowClass: WNDCLASS;
  LClassName: PChar;
begin
  Assert(Assigned(AHandler));
  Assert(DirectoryExists(APath, False));
  inherited Create;
  FHandler := AHandler;
  FPath := IncludeTrailingPathDelimiter(APath);

  LClassName := 'TAKFolderListenerHiddenWindow';
  ZeroMemory(@LWindowClass, SizeOf(LWindowClass));
  LWindowClass.lpfnWndProc := @WndProc;
  LWindowClass.hInstance := HInstance;
  LWindowClass.lpszClassName := LClassName;
  RegisterClass(LWindowClass);

  FHandle := CreateWindowEx(0, LClassName, '', WS_POPUP, 0, 0, 0, 0, 0, 0, HInstance, Self);
  SetWindowLongPtr(FHandle, GWLP_USERDATA, NativeInt(Self));
  FNotifyEntry.pidl := ILCreateFromPath(PChar(FPath));
  FNotifyEntry.fRecursive := False;
  FNotifyHandle := SHChangeNotifyRegister(FHandle,
    SHCNRF_ShellLevel or SHCNRF_InterruptLevel or SHCNRF_NewDelivery,
    SHCNE_UPDATEITEM or SHCNE_RENAMEITEM or SHCNE_DELETE or SHCNE_CREATE,
    WM_SHNOTIFY, 1, FNotifyEntry);
  if FNotifyHandle = 0 then
    raise Exception.Create('Invalid notify handle returned.');
end;

destructor TAKFolderListenerMessageWindow.Destroy;
begin
  SHChangeNotifyDeregister(FNotifyHandle);
  if Assigned(FNotifyEntry.pidl) then
    ILFree(FNotifyEntry.pidl);
  if FHandle <> 0 then
    DestroyWindow(FHandle);
  inherited;
end;

procedure TAKFolderListenerMessageWindow.OnNotification(const AWParam: NativeUInt; const ALParam: NativeInt);
var
  LPPIdList: PPIDLIST_ABSOLUTE;
  LPIdList: PItemIdList;
  LEvent: Integer;
  LPath: array[0..MAX_PATH] of Char;
  LLock: Pointer;
begin
  if ALParam = 0 then
    raise Exception.Create('Invalid message, LParam = 0.');
  LLock := Pointer(SHChangeNotification_Lock(AWParam, ALParam, LPPIdList, LEvent));
  if not Assigned(LLock) then
    raise Exception.Create('Invalid message, lock unassigned.');
  try
    if not Assigned(LPPidList) then
      raise Exception.Create('Invalid message, returned pointer unassigned.');

    LPIdList := PItemIdList(LPPIdList[0]);
    if not Assigned(LPIdList) then
      raise Exception.Create('Invalid message, unassigned list');

    if SHGetPathFromIDList(LPIdList, LPath) then
    begin
      if SameText(IncludeTrailingPathDelimiter(LPath), FPath) then
        Exit;
      if LEvent = SHCNE_RENAMEITEM then
      begin
        // On renames the new name is in the second slot.
        LPIdList := PItemIdList(LPPIdList[1]);
        if not Assigned(LPIdList) then
          raise Exception.Create('Invalid message, unassigned list');
        if not SHGetPathFromIDList(LPidList, LPath) then
          raise Exception.Create('Invalid message, list does not contain paths.');
      end;
      FHandler(LPath, GetFileEvent(LEvent));
    end
    else
      raise Exception.Create('Invalid message, list does not contain paths.');
  finally
    SHChangeNotification_Unlock(NativeUInt(LLock));
  end;
end;

class function TAKFolderListenerMessageWindow.WndProc(hWnd: HWND; Msg: UINT;
  wParam: WPARAM; lParam: LPARAM): LRESULT;
var
  LMsgWindow: TAKFolderListenerMessageWindow;
begin
  LMsgWindow := TAKFolderListenerMessageWindow(GetWindowLongPtr(hWnd, GWLP_USERDATA));
  if Assigned(LMsgWindow) then
  begin
    if Msg = WM_SHNOTIFY then
    begin
      LMsgWindow.OnNotification(wParam, lParam);
      Exit(0);
    end;
  end;
  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;
{$ENDIF}
{ TAKFolderListener }

constructor TAKFolderListener.Create(const APath: string; const AProc: TAKFileObserverProc);
begin
  Assert(Assigned(AProc));

  inherited Create;
  FFolderPath := APath;
  FObserver := AProc;
  {$IFNDEF WINAPI_ON}
  FPollingInterval := 2000; // Default is 2s.
  FTaskStopped := False;
  {$ELSE}
  FPollingInterval := -1; // For winapi use no polling interval is needed.
  {$ENDIF}
end;

destructor TAKFolderListener.Destroy;
begin
  Stop;
  inherited;
end;

function TAKFolderListener.GetIsRunning: Boolean;
begin
  {$IFNDEF WINAPI_ON}
  Result := Assigned(FMonitorTask) and (FMonitorTask.Status = TTaskStatus.Running);
  {$ELSE}
  Result := Assigned(FMessagesWindow);
  {$ENDIF}
end;

procedure TAKFolderListener.ProcessNotification(const AFileName: string; const AEvent: TAKFileEvent);
begin
  try
    FObserver(AFileName, AEvent);
  except
    on E: Exception do
      if Assigned(FOnException) then
        FOnException(E);
  end;
end;

procedure TAKFolderListener.SetOnException(const AValue: TAKExceptionProc);
begin
  if not IsRunning then
    FOnException := AValue;
end;

procedure TAKFolderListener.SetPollingInterval(const AValue: Integer);
begin
  {$IFNDEF WINAPI_ON}
  if IsRunning then
    Exit;
  if AValue < 100 then
    FPollingInterval := 100
  else
    FPollingInterval := AValue;
  {$ENDIF}
end;

procedure TAKFolderListener.Start;
begin
  if IsRunning then
    Exit;
  {$IFNDEF WINAPI_ON}
  FreeAndNil(FLastSnapshot);
  FLastSnapshot := CreateSnapshot;
  FTaskStopped := False;
  FMonitorTask := TTask.Run(DoMonitorTask);
  {$ELSE}
  try
    FMessagesWindow := TAKFolderListenerMessageWindow.Create(ProcessNotification, FFolderPath);
  except
    FreeAndNil(FMessagesWindow);
    raise
  end;
  {$ENDIF}
end;

procedure TAKFolderListener.Stop;
begin
  {$IFNDEF WINAPI_ON}
  if Assigned(FMonitorTask) then
  begin
    FTaskStopped := True;
    while Assigned(FMonitorTask) do
      Sleep(PollingInterval);
  end;
  FreeAndNil(FLastSnapshot);
  {$ELSE}
  FreeAndNil(FMessagesWindow);
  {$ENDIF}
end;

{$IFNDEF WINAPI_ON}
function TAKFolderListener.CompareNowWithSnapshot(out ADifferences: TAKDirDifferences): Boolean;
var
  LNow: TAKDirSnapshot;
  LFile: TAKFileSnapshot;
  LRenamed: TAKFileSnapshot;
  LIsRenamed: Boolean;
begin
  Assert(Assigned(FLastSnapshot));

  ADifferences := TAKDirDifferences.Create;
  try
    LNow := CreateSnapshot;
    try
      for LFile in FLastSnapshot.Values do
        if not LNow.ContainsKey(LFile.FileName) then
        begin
          LIsRenamed := False;
          // Rename if a new file matches size and edit datetime with a missing one.
          for LRenamed in LNow.Values do
            if not FLastSnapshot.ContainsKey(LRenamed.FileName) then
              if LFile.CheckRename(LRenamed) then
              begin
                ADifferences.Add(LRenamed.FileName, feRename);
                LIsRenamed := True;
                Break;
              end;
          // If no rename is found the file has been deleted.
          if not LIsRenamed then
            ADifferences.Add(LFile.FileName, feDelete);
        end
        else if LNow[LFile.FileName].Edited <> LFile.Edited then
          ADifferences.Add(LFile.FileName, feUpdate);

      for LFile in LNow.Values do
        if not FLastSnapshot.ContainsKey(LFile.FileName) and
        not ADifferences.ContainsKey(LFile.FileName) then
          ADifferences.Add(LFile.FileName, feCreate);

      FreeAndNil(FLastSnapshot);
      FLastSnapshot := LNow;
    except
      FreeAndNil(LNow);
      raise;
    end;

    Result := ADifferences.Count > 0;
    if not Result then
      FreeAndNil(ADifferences);
  except
    FreeAndNil(ADifferences);
    raise;
  end;
end;

function TAKFolderListener.CreateSnapshot: TAKDirSnapshot;
var
  LResult: TAKDirSnapshot;
begin
  LResult := TAKDirSnapshot.Create;
  try
    ScanFolder(FFolderPath, procedure (const APath: string; const AFile: TSearchRec)
      begin
        LResult.Add(APath + AFile.Name, AFile.TimeStamp, AFile.Size);
      end);
    Result := LResult;
  except
    on E: Exception do
    begin
      FreeAndNil(LResult);
      if Assigned(FOnException) then
        FOnException(E);
      raise;
    end;
  end;
end;

procedure TAKFolderListener.DoMonitorTask;
var
  LDifferences: TAKDirDifferences;
  LFileName: string;
begin
  try
    try
      while not FTaskStopped do
      begin
        Sleep(PollingInterval);
        if CompareNowWithSnapshot(LDifferences) then
        begin
          try
            for LFileName in LDifferences.Keys do
              NotifyToMainThread(LFileName, LDifferences[LFileName]);
          finally
            FreeAndNil(LDifferences);
          end;
        end;
      end;
    except
      on E: Exception do
      begin
        TThread.Queue(nil, procedure
        begin
          if Assigned(FOnException) then
            FOnException(E);
        end);
      end;
    end;
  finally
    FMonitorTask := nil;
  end;
end;

procedure TAKFolderListener.NotifyToMainThread(AFileName: string; AEvent: TAKFileEvent);
begin
  Assert(Assigned(FObserver));
  TThread.Queue(nil, procedure
    begin
      ProcessNotification(AFileName, AEvent);
    end);
end;
{$ENDIF}

end.
