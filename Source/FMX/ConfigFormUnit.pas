unit ConfigFormUnit;

{$I AK.Defines.inc}

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  AK.Classes, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.EditBox,
  FMX.ScrollBox;

type
  TVertScrollBoxHelper = class Helper for TVertScrollBox
  strict private
    function GetVertScrollBar: TScrollBar;
  public
    property VScrollBar: TScrollBar read GetVertScrollBar;
    procedure Init;
  end;

  TConfigForm = class(TForm)
  strict private
    FSectionFont: TFont;
    FSubsectionFont: TFont;
    FLastComponentBottom: Integer;
    FSectionCounter: Integer;
    FSubSectionCounter: Integer;
    FConfig: TAKDynRecord;
    FCustomFields: Boolean;
    procedure SetupEditor(const AEditor: TControl; const AName: string);
    procedure AddSection(const AText: string);
    procedure AddSubSection(const AText: string);
    procedure AddEditor(const AName, AValue: string; const AComment: string = '');
    procedure LoadDefaults(const AFileName: string);
    procedure ApplyConfig(const AConfig: TAKDynRecord);
    function AddLabel(const AText: string): TLabel;
    function AddTitle(const AName, AText: string; const AFont: TFont): TLabel;
    function GetMaxWidth(const AControl: TControl): Single;
  public
    procedure AfterConstruction; override;
    procedure Init(const AFileName: string);
    procedure Show(const AConfig: TAKDynRecord);
    destructor Destroy; override;
  published
    Controls_ScrollBox: TVertScrollBox;
    Cancel_Button: TButton;
    Save_Button: TButton;
    procedure FormHide(Sender: TObject);
    procedure Cancel_ButtonClick(Sender: TObject);
    procedure Save_ButtonClick(Sender: TObject);
  end;

implementation

uses
  FMX.Text, FMX.DateTimeCtrls, FMX.NumberBox,
  AK.Utils;

{$R *.fmx}

function FindChildControl(const AControl: TControl; const AName: string): TControl;
begin
  for Result in AControl.Controls do
    if Result.Name = AName then
      Exit;
  Result := nil;
end;

{ TConfigForm }

procedure TConfigForm.AddEditor(const AName, AValue, AComment: string);
var
  LValue: Variant;
  LTypeName: string;
  LCheckBox: TCheckBox;
  LDTPicker: TDateEdit;
  LNumber: TNumberBox;
  LEdit: TEdit;
begin
  LValue := AKVarFromString(AValue);
  LTypeName := AKVarTypeName(LValue);
  if LTypeName = 'Boolean' then
  begin
    LCheckBox := TCheckBox.Create(Self);
    SetupEditor(LCheckBox, AName);
    LCheckBox.IsChecked := LValue;
    LCheckBox.Text := '';
  end
  else if LTypeName = 'DateTime' then
  begin
    LDTPicker := TDateEdit.Create(Self);
    SetupEditor(LDTPicker, AName);
    LDTPicker.DateTime := LValue;
    LDTPicker.TextSettings.Font.Size := 11;
  end
  else if LTypeName = 'Integer' then
  begin
    LNumber := TNumberBox.Create(Self);
    SetupEditor(LNumber, AName);
    LNumber.ValueType := TNumValueType.Integer;
    LNumber.Value := LValue;
    LNumber.TextSettings.Font.Size := 11;
  end
  else if LTypeName = 'Float' then
  begin
    LNumber := TNumberBox.Create(Self);
    SetupEditor(LNumber, AName);
    LNumber.ValueType := TNumValueType.Float;
    LNumber.Value := LValue;
    LNumber.TextSettings.Font.Size := 11;
  end
  else
  begin
    LEdit := TEdit.Create(Self);
    SetupEditor(LEdit, AName);
    if VarIsNull(LValue) or VarIsEmpty(LValue) then
      LEdit.Text := ''
    else
      LEdit.Text := LValue;
    {$IFDEF D23+}
    if AComment <> '' then
      LEdit.TextPrompt := AComment;
    {$ENDIF}
    LEdit.TextSettings.Font.Size := 11;
  end;
end;

function TConfigForm.AddLabel(const AText: string): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Controls_ScrollBox;
  Result.StyledSettings := [];
  Result.TextAlign := TTextAlign.Trailing;
  Result.TextSettings.Font.Size := 11;
  Result.Name := AText + '_Label';
  Result.Text := AText;
  Result.Position.X := 10;
  Result.Position.Y := FLastComponentBottom + 13;
end;

procedure TConfigForm.AddSection(const AText: string);
begin
  Inc(FLastComponentBottom, 10);
  AddTitle('Section' + IntToStr(FSectionCounter) + '_Title', AText, FSectionFont);
  Inc(FSectionCounter);
  FSubsectionCounter := 0;
end;

procedure TConfigForm.AddSubSection(const AText: string);
begin
  AddTitle(Format('Section%d_%d_Title', [FSectionCounter, FSubsectionCounter]),
    AText, FSubsectionFont).TextAlign := TTextAlign.Leading;
  Inc(FSubsectionCounter);
end;

function TConfigForm.AddTitle(const AName, AText: string; const AFont: TFont): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Controls_ScrollBox;
  Result.StyledSettings := [];
  Result.Name := AName;
  Result.Text := AText;
  Result.TextSettings.Font := AFont;
  Result.AutoSize := False;
  Result.TextAlign := TTextAlign.Center;
  Result.Position.X := 10;
  Result.Position.Y := FLastComponentBottom + 10;
  Result.Width := GetMaxWidth(Result);
  FLastComponentBottom := Trunc(Result.Position.Y + Result.Height);
end;

procedure TConfigForm.AfterConstruction;
begin
  inherited;
  FSectionFont := TFont.Create;
  FSectionFont.Size := 14;
  FSectionFont.Style := [TFontStyle.fsBold];
  FSubsectionFont := TFont.Create;
  FSubsectionFont.Size := 12;
  FSubsectionFont.Style := [TFontStyle.fsBold];
  FLastComponentBottom := 0;
  FSectionCounter := 0;
  FSubsectionCounter := 0;
  FCustomFields := False;
end;

procedure TConfigForm.ApplyConfig(const AConfig: TAKDynRecord);
begin
  Assert(Assigned(AConfig));
  FConfig := AConfig;
  AConfig.EnumAllFieldNames(
    procedure (const AFieldName: string)
    var
      LControl: TControl;
    begin
      LControl := FindChildControl(Controls_ScrollBox.Content, AFieldName);
      if not Assigned(LControl) then
      begin
        if not FCustomFields then
          AddSection('Custom properties');
        AddEditor(AFieldName, AConfig.GetString(AFieldName));
      end
      else if LControl is TCheckBox then
        (LControl as TCheckBox).IsChecked := AConfig.GetBoolean(AFieldName)
      else if LControl is TDateEdit then
        (LControl as TDateEdit).DateTime := AConfig.GetDateTime(AFieldName)
      else if LControl is TNumberBox then
      begin
        if AConfig.FieldType[AFieldName] = 'Integer' then
          (LControl as TNumberBox).Value := AConfig.GetInteger(AFieldName)
        else
          (LControl as TNumberBox).Value := AConfig.GetFloat(AFieldName);
      end
      else
        (LControl as TEdit).Text := AConfig.GetString(AFieldName);
    end);
end;

procedure TConfigForm.Cancel_ButtonClick(Sender: TObject);
begin
  Hide;
end;

destructor TConfigForm.Destroy;
begin
  FreeAndNil(FSectionFont);
  FreeAndNil(FSubsectionFont);
  inherited;
end;

procedure TConfigForm.FormHide(Sender: TObject);
begin
  FConfig := nil;
end;

function TConfigForm.GetMaxWidth(const AControl: TControl): Single;
begin
  if Assigned(Controls_ScrollBox.VScrollBar) then
    Result := Controls_ScrollBox.Width - 10 - AControl.Position.X - Controls_ScrollBox.VScrollBar.Width
  else
    Result := Controls_ScrollBox.Width - 10 - AControl.Position.X;
end;

procedure TConfigForm.Init(const AFileName: string);
begin
  Controls_ScrollBox.Init;
  LoadDefaults(AFileName);
end;

procedure TConfigForm.LoadDefaults(const AFileName: string);
var
  LDefaults: TStringList;
  I: Integer;
begin
  LDefaults := TStringList.Create;
  try
    LDefaults.NameValueSeparator := ':';
    LDefaults.LoadFromFile(AFileName, TEncoding.UTF8);
    for I := 0 to LDefaults.Count - 1 do
    begin
      if LDefaults[I].StartsWith('#### ') then
        AddSection(StripPrefix(LDefaults[I], '#### '))
      else if LDefaults[I].StartsWith('### ') then
        AddSubSection(StripPrefix(LDefaults[I], '### '))
      else if LDefaults[I].StartsWith('#') then
        Continue
      else if Trim(LDefaults[I]) = '' then
        Continue
      else
      begin
        if (I > 0) and LDefaults[I - 1].StartsWith('# ') then
          AddEditor(Trim(LDefaults.Names[I]), Trim(LDefaults.ValueFromIndex[I]), StripPrefix(LDefaults[I - 1], '# '))
        else
          AddEditor(Trim(LDefaults.Names[I]), Trim(LDefaults.ValueFromIndex[I]));
      end;
    end;
  finally
    FreeAndNil(LDefaults);
  end;

end;

procedure TConfigForm.Save_ButtonClick(Sender: TObject);
var
  LControl: TControl;
begin
  for LControl in Controls_ScrollBox.Content.Controls do
  begin
    if LControl is TLabel then
      Continue;
    if LControl is TCheckBox then
      FConfig.SetBoolean(LControl.Name, (LControl as TCheckBox).IsChecked)
    else if LControl is TDateEdit then
      FConfig.SetDateTime(LControl.Name, (LControl as TDateEdit).DateTime)
    else if LControl is TNumberBox then
      FConfig[LControl.Name] := (LControl as TNumberBox).Value
    else
      FConfig.SetString(LControl.Name, (LControl as TEdit).Text);
  end;
  Hide;
end;

procedure TConfigForm.SetupEditor(const AEditor: TControl; const AName: string);
var
  LLabel: TLabel;
begin
  Assert(Assigned(AEditor));

  LLabel := AddLabel(AName);
  AEditor.Name := AName;
  AEditor.Parent := Controls_ScrollBox;
  AEditor.Position.X := LLabel.Position.X + LLabel.Width + 10;
  AEditor.Position.Y := LLabel.Position.Y - 3;
  AEditor.Width := GetMaxWidth(AEditor);
  FLastComponentBottom := Trunc(AEditor.Position.Y + AEditor.Height);
end;

procedure TConfigForm.Show(const AConfig: TAKDynRecord);
begin
  ApplyConfig(AConfig);
  inherited Show;
end;

{ TVertScrollBoxHelper }

function TVertScrollBoxHelper.GetVertScrollBar: TScrollBar;
begin
  Result := FindStyleResource('vscrollbar') as TScrollBar;
end;

procedure TVertScrollBoxHelper.Init;
var
  LScrollBar: TScrollBar;
begin
  ApplyStyleLookup;
  LScrollBar := VScrollBar;
  Assert(Assigned(LScrollBar));
  LScrollBar.Visible := True;
end;

end.
