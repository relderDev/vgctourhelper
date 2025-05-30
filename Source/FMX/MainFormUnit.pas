unit MainFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.ExtCtrls,
  AK.FolderListener,
  VGCStreaming, FolderListenerFormUnit, ConfigFormUnit, RepoTokenFormUnit;

type
  TMainForm = class(TForm)
  strict private
    FFolderListener: TFolderListenerForm;
    FConfigEditor: TConfigForm;
    FRepoTokenEditor: TRepoTokenForm;
    FTournament: TVGCStreamingTournament;
    FTournamentPrefix: string;
    FTourStarted: Boolean;
    procedure DoLog(const AString: string);
    procedure DoLogFmt(const AString: string; const AValues: array of const);
    procedure EnableAndFillStreamRounds;
    procedure EnableAndFillStreamMatches(const ARoundNumber: Integer);
    procedure UpdateTournament;
    procedure ExtractTournamentPrefix(const AFileName: string);
    procedure StartMonitoring(const AFileName: string);
    function Browse(const AFileMasks, AFileDescriptions: array of string): Boolean;
    function IsTournamentFileName(const AFileName: string): Boolean;
    function OnFileChanged(const AFileName: string; const AEvent: TAKFileEvent): string;
    function OpenDialog(const AMessage: string; const AButtons: TMsgDlgButtons  = [TMsgDlgBtn.mbOK];
      const AType: TMsgDlgType = TMsgDlgType.mtInformation): Boolean;
    function OpenDialogFmt(const AMessage: string; const AValues: array of const;
      const AButtons: TMsgDlgButtons = [TMsgDlgBtn.mbOK]; const AType: TMsgDlgType = TMsgDlgType.mtInformation): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    TournamentName_Edit: TEdit;
    TournamentName_Label: TLabel;
    TournamentBrowseFile_Button: TButton;
    TournamentXml_Edit: TEdit;
    TournamentXml_Label: TLabel;
    TournamentInit_Button: TButton;
    Pastes_Label: TLabel;
    Pastes_Edit: TEdit;
    PastesBrowseFile_Button: TButton;
    TournamentStart_Button: TButton;
    PastesPrint_Button: TButton;
    Logger_ListBox: TListBox;
    TournamentAutoUpdate_CheckBox: TCheckBox;
    TournamentAutoUpdateShow_Button: TButton;
    StreamMatch_PopupBox: TPopupBox;
    StreamMatchSelect_Button: TButton;
    StreamMatchSwitch_Button: TButton;
    StreamMatch_Label: TLabel;
    ReloadConfig_Button: TButton;
    Config_Edit: TEdit;
    Config_Label: TLabel;
    ConfigBrowseFile_Button: TButton;
    Settings_Label: TLabel;
    Streaming_Label: TLabel;
    OtherConfig_Label: TLabel;
    RepoToken_Button: TButton;
    LogLevel_Label: TLabel;
    LogLevel_PopupBox: TPopupBox;
    KeepDataOpen_CheckBox: TCheckBox;
    SinglePasteId_Edit: TEdit;
    SinglePastePrint_Button: TButton;
    SinglePasteId_Label: TLabel;
    SinglePasteValue_Label: TLabel;
    SinglePasteTitle_Label: TLabel;
    ConfigEdit_Button: TButton;
    StreamRound_PopupBox: TPopupBox;
    StreamRound_Label: TLabel;
    KeepDataOpen_Label: TLabel;
    TournamentAutoUpdate_Label: TLabel;
    SinglePasteValue_Memo: TMemo;
    FileOpenDialog: TOpenDialog;
    procedure FormShow(Sender: TObject);
    procedure TournamentXml_EditChange(Sender: TObject);
    procedure TournamentBrowseFile_ButtonClick(Sender: TObject);
    procedure TournamentAutoUpdateShow_ButtonClick(Sender: TObject);
    procedure TournamentInit_ButtonClick(Sender: TObject);
    procedure Pastes_EditChange(Sender: TObject);
    procedure PastesBrowseFile_ButtonClick(Sender: TObject);
    procedure KeepDataOpen_CheckBoxClick(Sender: TObject);
    procedure PastesPrint_ButtonClick(Sender: TObject);
    procedure SinglePastePrint_ButtonClick(Sender: TObject);
    procedure TournamentStart_ButtonClick(Sender: TObject);
    procedure StreamRound_PopupBoxChange(Sender: TObject);
    procedure StreamMatchSwitch_ButtonClick(Sender: TObject);
    procedure StreamMatchSelect_ButtonClick(Sender: TObject);
    procedure ConfigBrowseFile_ButtonClick(Sender: TObject);
    procedure ReloadConfig_ButtonClick(Sender: TObject);
    procedure LogLevel_PopupBoxChange(Sender: TObject);
    procedure ConfigEdit_ButtonClick(Sender: TObject);
    procedure RepoToken_ButtonClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

uses
  RegularExpressions, FMX.DialogService,
  Pokemon.Context, VGCTournament,
  AK.Constants;

{$R *.fmx}

{ TMainForm }

function TMainForm.Browse(const AFileMasks, AFileDescriptions: array of string): Boolean;
var
  LLength: Integer;
  LFilter: string;
  I: Integer;
begin
  LLength := Length(AFileMasks);
  Assert(LLength = Length(AFileDescriptions));

  if LLength = 0 then
    LFilter := 'Any file|*.*'
  else
  begin
    for I := 0 to LLength - 1 do
      LFilter := Format('%s%s|%s|', [LFilter, AFileDescriptions[I], AFileMasks[I]]);
    Delete(LFilter, High(LFilter), 1);
  end;
  FileOpenDialog.Filter := LFilter;
  Result := FileOpenDialog.Execute;
end;

procedure TMainForm.ConfigBrowseFile_ButtonClick(Sender: TObject);
begin
  if Browse(['*.yaml; *.yml'], ['Config YAML file']) then
    Config_Edit.Text := FileOpenDialog.FileName;
end;

procedure TMainForm.ConfigEdit_ButtonClick(Sender: TObject);
const
  DEFAULTS_FILE = 'Resources\config_template.yaml';
  DEFAULTS_MISSING = 'Cannot edit config file, missing file "%s".';
var
  LDefaultsFileName: string;
begin
  if not Assigned(FConfigEditor) then
  begin
    LDefaultsFileName := AppPath + DEFAULTS_FILE;
    if not FileExists(LDefaultsFileName) then
      raise Exception.CreateFmt(DEFAULTS_MISSING, [LDefaultsFileName]);
    FConfigEditor := TConfigForm.Create(Self);
    FConfigEditor.Init(LDefaultsFileName);
    PokemonContext.SaveOnExit := True;
  end;
  FConfigEditor.Show(PokemonContext.Config);
end;

constructor TMainForm.Create(AOwner: TComponent);
begin
  // Create the instance of the tournament before initializing components.
  FTournament := TVGCStreamingTournament.Create;
  // Initialize components (a event that could need FTournament might trigger).
  inherited Create(AOwner);
  // Setup logging for FTournament.
  FTournament.Logger.Level := LogLevel_PopupBox.ItemIndex;
  FTournament.Logger.WriteLog := DoLog;
  FTournament.Logger.FormatLog := function (const AString: string): string
    begin
      Result := AString;
    end;
  // Log repository status: it does not change during the run - even if the
  // config is reloaded. Just turn off and on the application.
  if Assigned(FTournament.Repository) then
  begin
    DoLogFmt('Repository configured - owner: %s, name: %s',
      [FTournament.Repository.RepoOwner, FTournament.Repository.RepoName]);
    if FTournament.Repository.Token <> '' then
      DoLog('Repository token initialized.')
    else
      DoLog('Repository token empty.');
    FRepoTokenEditor := TRepoTokenForm.Create(Self);
    RepoToken_Button.Visible := True;
  end
  else
    DoLog('Repository not configured.');
  FTourStarted := False;
end;

destructor TMainForm.Destroy;
begin
  FreeAndNil(FTournament);
  inherited;
end;

procedure TMainForm.DoLog(const AString: string);
begin
  Logger_ListBox.Items.Add(AString);
  Application.ProcessMessages;
  Logger_ListBox.ItemIndex := Logger_ListBox.Count - 1;
end;

procedure TMainForm.DoLogFmt(const AString: string; const AValues: array of const);
begin
  DoLog(Format(AString, AValues));
end;

procedure TMainForm.EnableAndFillStreamMatches(const ARoundNumber: Integer);
begin
  StreamMatch_PopupBox.Clear;
  if FTournament.RoundCount <= ARoundNumber then
    raise Exception.CreateFmt('Invalid round number %d.', [ARoundNumber]);
  FTournament[ARoundNumber].EnumMatches(procedure (const ATableNumber: Integer; const AMatch: TVGCMatch)
    begin
      StreamMatch_PopupBox.Items.AddObject(AMatch.AsString(False), AMatch);
    end, False);
  StreamMatch_PopupBox.ItemIndex := 0;
  StreamMatch_PopupBox.Enabled := True;
  StreamMatchSwitch_Button.Enabled := True;
  StreamMatchSelect_Button.Enabled := True;
end;

procedure TMainForm.EnableAndFillStreamRounds;
var
  I: Integer;
begin
  StreamRound_PopupBox.Clear;
  if FTournament.RoundCount < 1 then
    Exit;
  for I := 0 to FTournament.RoundCount - 1 do
    StreamRound_PopupBox.Items.AddObject(FTournament[I].DisplayName, TObject(FTournament[I].Number));
  StreamRound_PopupBox.ItemIndex := FTournament.RoundCount - 1;
  StreamRound_PopupBox.Enabled := True;
  EnableAndFillStreamMatches(FTournament.LastRound.Number);
end;

procedure TMainForm.ExtractTournamentPrefix(const AFileName: string);
var
  LFileName: string;
  LRegEx: TRegEx;
begin
  LFileName := ExtractFileName(AFileName);
  LRegEx := TRegEx.Create('^(.+)_r\d+-(start|begin|end)\.tdf', [roNotEmpty, roIgnoreCase]);
  Assert(LRegEx.IsMatch(LFileName));
  FTournamentPrefix := LRegEx.Match(LFileName).Groups[1].Value;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  TournamentXml_Edit.SetFocus;
end;

function TMainForm.IsTournamentFileName(const AFileName: string): Boolean;
var
  LRegEx: TRegEx;
begin
  Assert(FTournamentPrefix <> '');

  LRegEx := TRegEx.Create('^' + FTournamentPrefix + '_r\d+-(start|begin|end)\.tdf', [roNotEmpty, roIgnoreCase]);
  Result := LRegEx.IsMatch(ExtractFileName(AFileName));
end;

procedure TMainForm.KeepDataOpen_CheckBoxClick(Sender: TObject);
begin
  PokemonContext.KeepDataOpen := KeepDataOpen_CheckBox.IsChecked;
end;

procedure TMainForm.LogLevel_PopupBoxChange(Sender: TObject);
begin
  FTournament.Logger.Level := LogLevel_PopupBox.ItemIndex;
end;

function TMainForm.OnFileChanged(const AFileName: string; const AEvent: TAKFileEvent): string;
begin
  Result := 'Skipped';
  case AEvent of
    feUpdate, feCreate: if IsTournamentFileName(AFileName) then
    begin
      Result := 'Used';
      TournamentXml_Edit.Text := AFileName;
      UpdateTournament;
    end;
  end;
end;

procedure TMainForm.PastesBrowseFile_ButtonClick(Sender: TObject);
begin
  if Browse(['*.csv'], ['CSV file']) then
    Pastes_Edit.Text := FileOpenDialog.FileName;
end;

procedure TMainForm.PastesPrint_ButtonClick(Sender: TObject);
begin
  FTournament.AddPokepasteCSV(Pastes_Edit.Text);
  {
    Shai thinks it's better to let the user import multiple CSVs so the
    following lines are commented
  }
  //Pastes_Edit.Enabled := False;
  //PastesBrowseFile_Button.Enabled := False;
  //PastesPrint_Button.Enabled := False;

  FTournament.PrintPlayerTeamlists;
  TournamentStart_Button.Enabled := True;
end;

procedure TMainForm.Pastes_EditChange(Sender: TObject);
begin
  PastesPrint_Button.Enabled := FileExists(Pastes_Edit.Text);
end;

procedure TMainForm.ReloadConfig_ButtonClick(Sender: TObject);
const
  WARN_MSG = 'File "%s" not found, reload config with default values?';
var
  LFileName: string;
begin
  LFileName := Config_Edit.Text;
  TPokemonContext.ConfigName := LFileName;
  if not FileExists(LFileName) then
    if OpenDialogFmt(WARN_MSG, [LFileName], [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbCancel], TMsgDlgType.mtWarning) then
      LFileName := 'default values'
    else
      Exit;
  DoLog('Reloading configuration...');
  TPokemonContext.ReloadConfig;
  DoLogFmt('Configuration reloaded (%s).', [LFileName]);
end;

procedure TMainForm.RepoToken_ButtonClick(Sender: TObject);
begin
  Assert(Assigned(FTournament));
  Assert(Assigned(FTournament.Repository));
  Assert(Assigned(FRepoTokenEditor));

  FRepoTokenEditor.Show(procedure (const AToken: string)
    begin
      FTournament.Repository.Token := AToken;
      if AToken <> '' then
        DoLog('Repository token initialized.');
    end, FTournament.Repository.Token);
end;

procedure TMainForm.SinglePastePrint_ButtonClick(Sender: TObject);
begin
  FTournament.AddSinglePokepaste(SinglePasteId_Edit.Text, SinglePasteValue_Memo.Text);
  SinglePasteId_Edit.Text := '';
  SinglePasteValue_Memo.Text := '';
  if OpenDialog('Done! Want to add another one?', [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo]) then
    SinglePasteId_Edit.SetFocus;
end;

procedure TMainForm.StartMonitoring(const AFileName: string);
begin
  if not Assigned(FFolderListener) then
    FFolderListener := TFolderListenerForm.Create(Self);
  TournamentAutoUpdateShow_Button.Visible := True;
  FFolderListener.Start(ExtractFileDir(AFileName), OnFileChanged);
end;

procedure TMainForm.StreamMatchSelect_ButtonClick(Sender: TObject);
var
  LIndex: Integer;
begin
  LIndex := StreamMatch_PopupBox.ItemIndex;
  if LIndex < 0 then
    Exit;
  FTournament.PrintMatch(StreamMatch_PopupBox.Items.Objects[LIndex] as TVGCMatch);
  OpenDialog('Done!');
end;

procedure TMainForm.StreamMatchSwitch_ButtonClick(Sender: TObject);
var
  LIndex: Integer;
  LMatch: TVGCMatch;
begin
  if StreamMatch_PopupBox.ItemIndex < 0 then
    Exit;
  with StreamMatch_PopupBox do
  begin
    LIndex := ItemIndex;
    LMatch := Items.Objects[LIndex] as TVGCMatch;
    LMatch.Switch;
    Items[LIndex] := LMatch.AsString(False);
    ItemIndex := LIndex;
  end;
end;

procedure TMainForm.StreamRound_PopupBoxChange(Sender: TObject);
begin
  EnableAndFillStreamMatches(Integer(StreamRound_PopupBox.Items.Objects[StreamRound_PopupBox.ItemIndex]));
end;

procedure TMainForm.TournamentAutoUpdateShow_ButtonClick(Sender: TObject);
begin
  FFolderListener.Show;
end;

procedure TMainForm.TournamentBrowseFile_ButtonClick(Sender: TObject);
begin
  if Browse(['*.tdf'], ['TOM Output file']) then
    TournamentXml_Edit.Text := FileOpenDialog.FileName;
end;

procedure TMainForm.TournamentInit_ButtonClick(Sender: TObject);
begin
  if TournamentName_Edit.Text <> '' then
    FTournament.Name := TournamentName_Edit.Text;

  FTournament.Initialize(TournamentXml_Edit.Text);
  TournamentInit_Button.Enabled := False;
  TournamentAutoUpdate_CheckBox.Enabled := False;
  Pastes_Edit.Enabled := True;
  PastesBrowseFile_Button.Enabled := True;
  KeepDataOpen_CheckBox.Enabled := True;
  SinglePasteId_Edit.Enabled := True;
  SinglePasteValue_Memo.Enabled := True;
  SinglePastePrint_Button.Enabled := True;

  if TournamentAutoUpdate_CheckBox.IsChecked then
  begin
    TournamentXml_Edit.Enabled := False;
    TournamentBrowseFile_Button.Enabled := False;
    ExtractTournamentPrefix(TournamentXml_Edit.Text);
    StartMonitoring(TournamentXml_Edit.Text);
  end;
end;

procedure TMainForm.TournamentStart_ButtonClick(Sender: TObject);
begin
  if not FTourStarted then
  begin
    FTourStarted := True;
    if TournamentAutoUpdate_CheckBox.IsChecked then
      TournamentStart_Button.Enabled := False
    else
      TournamentStart_Button.Text := 'Update!';
  end;
  UpdateTournament;
end;

procedure TMainForm.TournamentXml_EditChange(Sender: TObject);
begin
  if not FTourStarted then
  begin
    TournamentInit_Button.Enabled := FileExists(TournamentXml_Edit.Text);
    TournamentAutoUpdate_CheckBox.Enabled := TournamentInit_Button.Enabled;
  end;
end;

procedure TMainForm.UpdateTournament;
begin
  if FTournament.Update(TournamentXml_Edit.Text) then
    EnableAndFillStreamRounds;
end;

function TMainForm.OpenDialog(const AMessage: string; const AButtons: TMsgDlgButtons;
   const AType: TMsgDlgType): Boolean;
var
  LDefaultButton: TMsgDlgBtn;
  LResult: Boolean;
begin
  LResult := False;
  LDefaultButton := TMsgDlgBtn.mbOK;
  if not (TMsgDlgBtn.mbOK in AButtons) then
  begin
    if TMsgDlgBtn.mbYes in AButtons then
      LDefaultButton := TMsgDlgBtn.mbYes
    else if TMsgDlgBtn.mbYesToAll in AButtons then
      LDefaultButton := TMsgDlgBtn.mbYesToAll
    else if TMsgDlgBtn.mbAll in AButtons then
      LDefaultButton := TMsgDlgBtn.mbAll
    else
      for LDefaultButton in AButtons do
        Break;
  end;

  TDialogService.MessageDialog(AMessage, AType, AButtons, LDefaultButton, 0,
    procedure (const AResult: TModalResult) begin LResult := IsPositiveResult(AResult) end);
  Result := LResult;
end;

function TMainForm.OpenDialogFmt(const AMessage: string; const AValues: array of const;
  const AButtons: TMsgDlgButtons; const AType: TMsgDlgType): Boolean;
begin
  Result := OpenDialog(Format(AMessage, AValues), AButtons, AType);
end;


end.
