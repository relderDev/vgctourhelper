unit Pokemon;

interface

uses
  RegularExpressions, Generics.Collections,
  AK.Classes;

type
  TPokemon = class
  strict private
    FData: TAKDynRecord;
    FText: string;
    FOpenText: string;
    procedure ProcessText;
    procedure ProcessOpenText;
    procedure SetSpecies(const ASpeciesName: string);
    procedure SetFirstLine(const AFirstLine: string);
    procedure SetStatsFromLine(const AStatKind, AStatLine: string);
    procedure AddTranslation;
    procedure ApplyTypeMacrosToText(var AText: string);
    procedure ApplyMoveMacrosToText(var AText: string);
    function InsertTypesInText(const AMatch: TMatch): string;
    function InsertMovesInText(const AMatch: TMatch): string;
    function GetFirstLine: string;
    function GetStatStr(const AStatName, AStatKind: string): string;
    function GetStatsLine(const AStatKind: string): string;
    function GetMovesText: string;
    function GetPasteInfo(const AName: string): string;
  strict private
    { Setters and Getters }
    procedure SetData(const APropertyName, AValue: string);
    procedure SetDisplayValue(const APropertyName, AValue: string);
    procedure SetStat(const AStatName, AStatKind: string; const AStatValue: Integer);
    procedure SetMove(const AIndex: Integer; const AValue: string);
    function GetData(const APropertyName: string): string;
    function GetDisplayValue(const APropertyName: string): string;
    function GetStat(const AStatName, AStatKind: string): Integer;
    function GetMove(const AIndex: Integer): string;
    function GetText: string;
    function GetOpenText: string;
  private
    function DataAsText: string;
  public
    property Data[const APropertyName: string]: string read GetData write SetData; default;
    property DisplayValue[const APropertyName: string]: string read GetDisplayValue write SetDisplayValue;
    property Stat[const AStatName, AStatKind: string]: Integer read GetStat write SetStat;
    property Move[const AIndex: Integer]: string read GetMove write SetMove;
    property Text: string read GetText;
    property OpenText: string read GetOpenText;
    procedure LoadFromText(const AText: string);
    procedure ApplyToText(var AText: string; const AApplyTranslation: Boolean);
    constructor Create;
    destructor Destroy; override;
  end;

  TPokemonTeam = class
  strict private
    FPokemon: array[0..5] of TPokemon;
    FCount: Integer;
    function GetPokemon(const AIndex: Integer): TPokemon;
  public
    property Count: Integer read FCount default 0;
    property Pokemon[const AIndex: Integer]: TPokemon read GetPokemon; default;
    procedure Initialize(const APokepasteText: string);
    function ApplyTeamToText(const AText: string; const AApplyTranslation: Boolean): string;
    function AsText: string;
    function ApplyToTemplate(const APokemonTemplate: string;
      const AApplyTranslation: Boolean): string;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils, StrUtils, Classes,
  AK.Utils, AK.Constants,
  Pokemon.Constants, Pokemon.Context;

{ TPokemon }

procedure TPokemon.AddTranslation;
var
  LPrefix: string;
  LItem: string;
  LDataType: TPokemonDataType;
begin
  if PokemonContext.Lang = dlEn then
    Exit;
  LPrefix := PokemonContext.Language;
  for LItem in POKEMON_TRANSLATABLE_DATA do
  begin
    if Data[LItem] = POKEMON_NULL_DATA then
      Continue;
    LDataType := TAKEnum<TPokemonDataType>.Value(StripPrefixesAndSuffixes(LItem,
      ['Tera'], ['0', '1', '2', '3']));
    Data[Format('__%s_%s', [LPrefix, LItem])] := PokemonContext._[LDataType, Data[LItem]];
  end;
end;

procedure TPokemon.ApplyMoveMacrosToText(var AText: string);
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create(BracketRegexText('<%Moves%>'), [roIgnoreCase, roNotEmpty]);
  AText := LRegex.Replace(AText, InsertMovesInText);
end;

procedure TPokemon.ApplyToText(var AText: string; const AApplyTranslation: Boolean);
begin
  ApplyTypeMacrosToText(AText);
  ApplyMoveMacrosToText(AText);
  FData.ExpandMacros(AText, procedure (var AMacroValue: string)
    var
      LDisplayMacro: string;
      LTranslatedMacro: string;
    begin
      LTranslatedMacro := Format('__%s_%s', [PokemonContext.Language, AMacroValue]);
      LDisplayMacro := Format('__dp_%s', [AMacroValue]);

      if SameText(AMacroValue, 'Type2') and (Data['Type2'] = POKEMON_NULL_DATA) then
        AMacroValue := ''
      else if AApplyTranslation and (Data[LTranslatedMacro] <> POKEMON_NULL_DATA) then
        AMacroValue := LTranslatedMacro
      else if Data[LDisplayMacro] <> POKEMON_NULL_DATA then
        AMacroValue := LDisplayMacro;
    end);
end;

procedure TPokemon.ApplyTypeMacrosToText(var AText: string);
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create(BracketRegexText('<%Types%>'), [roIgnoreCase, roNotEmpty]);
  AText := LRegex.Replace(AText, InsertTypesInText);
end;

constructor TPokemon.Create;
begin
  FData := TAKDynRecord.Create;
end;

function TPokemon.DataAsText: string;
begin
  Result := FData.AsTypedText;
end;

destructor TPokemon.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

function TPokemon.GetData(const APropertyName: string): string;
begin
  Result := FData.GetString(APropertyName, POKEMON_NULL_DATA);
end;

function TPokemon.GetDisplayValue(const APropertyName: string): string;
begin
  Result := FData.GetString('__dp_' + APropertyName);
  if Result = '' then
    Result := FData.GetString(APropertyName);
end;

function TPokemon.GetFirstLine: string;
begin
  if Data['Nickname'] <> '' then
    Result := POKEMON_FIRST_ROW_NICK
  else
    Result := POKEMON_FIRST_ROW;
  if Data['Gender'] <> '' then
    Result := Result + POKEMON_GENDER;
  if Data['Item'] <> '' then
    Result := Result + POKEMON_ITEM;
  FData.ExpandMacros(Result);
end;

function TPokemon.GetMove(const AIndex: Integer): string;
begin
  Result := FData.GetString('Move' + IntToStr(AIndex));
end;

function TPokemon.GetMovesText: string;
var
  LMove: string;
  I: Integer;
begin
  for I in [0..3] do
  begin
    LMove := Move[I];
    if LMove = '' then
      Continue;
    if Result = '' then
      Result := '- ' + LMove
    else
      Result := Result + sLineBreak + '- ' + LMove;
  end;
end;

function TPokemon.GetOpenText: string;
begin
  if FOpenText = '' then
    ProcessOpenText;
  Result := FOpenText;
end;

function TPokemon.GetPasteInfo(const AName: string): string;
var
  LName: string;
begin
  LName := AName;
  if MatchText(LName, ['EVs', 'IVs']) then
    Exit(GetStatsLine(Copy(LName, Low(LName), 2)));
  if SameText(LName, 'Nature') then
    Exit(Format('%s %s', [Data['Nature'], 'Nature']));
  if SameText(LName, 'Moves') then
    Exit(GetMovesText);
  if SameText(LName, 'TeraType') then
    LName := 'Tera Type';
  Result := Format('%s: %s', [LName, Data[AName]]);
end;

function TPokemon.GetStat(const AStatName, AStatKind: string): Integer;
var
  LDefault: Integer;
begin
  LDefault := 0;
  if SameText(AStatKind, 'IV') then
    LDefault := 31;
  Result := FData.GetInteger(AStatName + '_' + AStatKind, LDefault);
end;

function TPokemon.GetStatsLine(const AStatKind: string): string;
var
  LStatName: string;
  LStatStr: string;
begin
  for LStatName in POKEMON_STATS do
  begin
    LStatStr := GetStatStr(LStatName, AStatKind);
    if LStatStr = '' then
      Continue;
    if Result = '' then
      Result := LStatStr
    else
      Result := Result + ' / ' + LStatStr;
  end;
  if AStatKind <> '' then
    Result := Format('%ss: %s', [AStatKind, Result]);
end;

function TPokemon.GetStatStr(const AStatName, AStatKind: string): string;
var
  LDefault: Integer;
  LValue: Integer;
begin
  LDefault := 0;
  if SameText(AStatKind, 'IV') then
    LDefault := 31;
  LValue := Stat[AStatName, AStatKind];
  if LValue <> LDefault then
    Result := Format('%d %s', [LValue, AStatName]);
end;

function TPokemon.GetText: string;
begin
  if FText = '' then
    ProcessText;
  Result := FText;
end;

function TPokemon.InsertMovesInText(const AMatch: TMatch): string;
var
  LTemplate: string;
  I: Integer;
begin
  LTemplate := ReplaceText(AMatch.Value, '<%Moves%>', '');
  Result := '';
  for I in MOVES_RANGE do
  begin
    if Move[I] = '' then
      Continue;
    if Result = '' then
      Result := ReplaceText(LTemplate, '#n#', IntToStr(I))
    else
      Result := Result + sLineBreak + ReplaceText(LTemplate, '#n#', IntToStr(I));
  end;
end;

function TPokemon.InsertTypesInText(const AMatch: TMatch): string;
var
  LTemplate: string;
  I: Integer;
begin
  LTemplate := ReplaceText(AMatch.Value, '<%Types%>', '');
  Result := '';
  for I in TYPES_RANGE do
  begin
    if Data['Type' + IntToStr(I)] = POKEMON_NULL_DATA then
      Continue;
    if Result = '' then
      Result := ReplaceText(LTemplate, '#n#', IntToStr(I))
    else
      Result := Result + sLineBreak + ReplaceText(LTemplate, '#n#', IntToStr(I));
  end;

end;

procedure TPokemon.LoadFromText(const AText: string);
const
  PASTE_NAMES: array[0..5] of string = (
    'Ability', 'Level', 'Shiny', 'Tera Type', 'EVs', 'IVs'
  );
var
  LList: TStringList;
  LName: string;
  LValue: string;
  I: Integer;
begin
  LList := TStringList.Create;
  try
    LList.NameValueSeparator := ':';
    LList.Text := AText;
    // Minimal pokemon paste has 4 lines
    Assert(LList.Count > 3);

    // Parse first line on its own and delete it
    SetFirstLine(LList[0]);
    LList.Delete(0);

    // Parse each "Name: Value" line and delete it
    for LName in PASTE_NAMES do
    begin
      LValue := Trim(LList.Values[LName]);
      if LValue <> '' then
      begin
        if MatchStr(LName, ['EVs', 'IVs']) then
          SetStatsFromLine(Copy(LName, Low(LName), 2), LValue)
        else
          Data[ReplaceStr(LName, ' ', '')] := LValue;
        LList.Delete(LList.IndexOfName(LName));
      end;
    end;

    // Remaining lines are nature (if present) and moves: set and delete nature
    Assert((LList.Count > 1) and (LList.Count < 6));
    if string.EndsText('Nature', Trim(LList[0])) then
    begin
      Data['Nature'] := Trim(ReplaceText(LList[0], 'Nature', ''));
      LList.Delete(0);
    end;

    // Finally set moves, no need to delete them because they are last
    for I := 0 to LList.Count - 1 do
      Move[I] := Trim(Copy(LList[I], Low(LList[I]) + 1));
  finally
    FreeAndNil(LList);
  end;
  if PokemonContext.Config.GetBoolean('LoadTranslations', True) then
    AddTranslation;
  FText := '';
  FOpenText := '';
end;

procedure TPokemon.ProcessText;
var
  LFirstLine: string;
  LPasteElement: string;
begin
  LFirstLine := GetFirstLine;
  FText := LFirstLine;
  for LPasteElement in POKEMON_CTS_TEMPLATE_BODY do
    FText := FText + sLineBreak + GetPasteInfo(LPasteElement);
end;

procedure TPokemon.ProcessOpenText;
var
  LFirstLine: string;
  LPasteElement: string;
begin
  LFirstLine := GetFirstLine;
  FOpenText := LFirstLine;
  for LPasteElement in POKEMON_OTS_TEMPLATE_BODY do
    FOpenText := FOpenText + sLineBreak + GetPasteInfo(LPasteElement);
end;

procedure TPokemon.SetData(const APropertyName, AValue: string);
begin
  FData.SetValueFromText(APropertyName, AValue);

  if MatchText(APropertyName, POKEMON_OTS_TEMPLATE_BODY)
  or MatchText(APropertyName, ['Item', 'Gender', 'Pokemon', 'Nickname']) then
  begin
    FText := '';
    FOpenText := '';
  end
  else if MatchText(APropertyName, POKEMON_CTS_TEMPLATE_BODY) then
    FText := '';
  if SameText(APropertyName, 'TeraType') then
    FData.SetString('TeraTypeSvg', PokemonContext.SVGTera[AValue]);
end;

procedure TPokemon.SetDisplayValue(const APropertyName, AValue: string);
begin
  FData.SetValueFromText('__dp_' + APropertyName, AValue);
end;

procedure TPokemon.SetFirstLine(const AFirstLine: string);
var
  LLine: string;
  LItemPos: Integer;
  LParts: TArray<string>;
  LCount: Integer;

  function IsGender(const AString: string): Boolean;
  begin
    Result := Length(Trim(AString)) = 1;
    if Result then
      Data['Gender'] := Trim(AString);
  end;
begin
  Assert(AFirstLine <> '');
  LItemPos := Pos('@', AFirstLine);
  if LItemPos > 0 then
  begin
    LLine := Copy(AFirstLine, Low(AFirstLine), LItemPos - 1);
    DisplayValue['Item'] := Trim(Copy(AFirstLine, LItemPos + 1));
    FData.SetString('Item', PokemonContext[dtItem].FindKey('Item', DisplayValue['Item']));
    FData.SetString('ItemAsset', 'item_' + FData.GetString('Item') + '.png');
  end
  else
    LLine := AFirstLine;
  LParts := LLine.Split(['(', ')']);
  LCount := Length(LParts);
  case LCount of
    1: SetSpecies(Trim(LParts[0])); // Just species
    2: raise Exception.CreateFmt('Invalid pokemon text (%s).', [LLine]); // Should never happen
    3: // Either nickname or gender
    begin
      if not IsGender(LParts[1]) then
      begin
        Data['Nickname'] := Trim(LParts[0]);
        SetSpecies(Trim(LParts[1]));
      end
      else
        SetSpecies(Trim(LParts[0]));
    end;
    4: // Nickname that includes one bracket character, no gender
    begin
      Data['Nickname'] := Trim(LParts[0] + ')' + LParts[1]);
      SetSpecies(Trim(LParts[2]));
    end;
    else // Both nickname and gender or nickname with 2+ bracket characters
    begin
      LLine := Trim(Copy(LLine, Low(LLine), LastDelimiter('(', LLine) - 1));
      if not IsGender(LParts[LCount - 2]) then
      begin
        SetSpecies(Trim(LParts[LCount - 2]));
        Data['Nickname'] := LLine;
      end
      else
      begin
        SetSpecies(Trim(LParts[LCount - 4]));
        Data['Nickname'] := Trim(Copy(LLine, Low(LLine), LastDelimiter('(', LLine) - 1));
      end;
    end;
  end;
end;

procedure TPokemon.SetMove(const AIndex: Integer; const AValue: string);
var
  LMove: string;
begin
  LMove := 'Move' + IntToStr(AIndex);
  FData.SetString(LMove, AValue);
  FData.SetString(LMove + 'Type', PokemonContext[dtMove][AValue].GetString('Type'));
  FText := '';
  FOpenText := '';
end;

procedure TPokemon.SetSpecies(const ASpeciesName: string);
var
  LData: TAKDynRecord;
  LType1: string;
  LType2: string;
  LStat: string;
begin
  LData := PokemonContext[dtPokemon][ASpeciesName];
  Data['Pokemon'] := ASpeciesName;
  FData.SetString('PokemonIndex', LData.GetString('Dex_Number'));
  LType1 := LData.GetString('Type1');
  LType2 := LData.GetString('Type2');
  Assert(LType1 <> '', Format('Missing type on pokemon "%s"', [ASpeciesName]));
  Data['Type1'] := LType1;
  if (LType2 <> '') and not SameText(LType1, LType2) then
    Data['Type2'] := LType2;
  for LStat in POKEMON_STATS do
    Stat[LStat, 'Base'] := LData.GetInteger('Base_' + LStat);
end;

procedure TPokemon.SetStat(const AStatName, AStatKind: string;
  const AStatValue: Integer);
begin
  FData.SetInteger(AStatName + '_' + AStatKind, AStatValue);
  FText := '';
end;

procedure TPokemon.SetStatsFromLine(const AStatKind, AStatLine: string);
var
  LAll: TArray<string>;
  LNameValue: string;
  LSplitted: TArray<string>;
begin
  LAll := AStatLine.Split([' / ']);
  for LNameValue in LAll do
  begin
    LSplitted := LNameValue.Split([' ']);
    Assert(Length(LSplitted) = 2);
    Stat[LSplitted[1], AStatKind] := StrToInt(LSplitted[0]);
  end;
end;

{ TPokemonTeam }

function TPokemonTeam.ApplyTeamToText(const AText: string; const AApplyTranslation: Boolean): string;
var
  LText: string;
  I: Integer;
begin
  Result := '';
  for I := 0 to FCount - 1 do
  begin
    LText := AText;
    FPokemon[I].ApplyToText(LText, AApplyTranslation);
    Result := Format('%s== POKEMON (%d) == ' + sLineBreak + '%s' + sLineBreak,
      [Result, I + 1, LText]);
  end;
end;

function TPokemonTeam.ApplyToTemplate(const APokemonTemplate: string;
  const AApplyTranslation: Boolean): string;
var
  LItem: string;
  I: Integer;
begin
  for I := 0 to High(FPokemon) do
  begin
    LItem := APokemonTemplate;
    FPokemon[I].ApplyToText(LItem, AApplyTranslation);
    LItem := ReplaceText(LItem, '%TeamIndex%', IntToStr(I));
    if Result = '' then
      Result := LItem
    else
      Result := Result + sLineBreak + LItem;
  end;
end;

function TPokemonTeam.AsText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FCount - 1 do
    Result := Result + '== POKEMON ==' + sLineBreak + FPokemon[I].DataAsText + sLineBreak;
end;

destructor TPokemonTeam.Destroy;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FreeAndNil(FPokemon[I]);
  inherited;
end;

function TPokemonTeam.GetPokemon(const AIndex: Integer): TPokemon;
begin
  Assert(FCount > 0, 'Pokemon team has not been initialized.');
  if AIndex < 0 then
    raise Exception.CreateFmt('Invalid pokemon index %d.', [AIndex]);
  if AIndex >= FCount then
    raise Exception.CreateFmt('No pokemon at index %d.', [AIndex]);

  Result := FPokemon[AIndex];
end;

procedure TPokemonTeam.Initialize(const APokepasteText: string);
var
  LPokemon: TArray<string>;
  LIndex: Integer;
  LText: string;
  I: Integer;
begin
  LPokemon := APokepasteText.Split([sLineBreak + sLineBreak]);
  LIndex := 0;
  for I := 0 to High(LPokemon) do
  begin
    LText := Trim(LPokemon[I]);
    if LText <> '' then
    begin
      FPokemon[LIndex] := TPokemon.Create;
      FPokemon[LIndex].LoadFromText(LText);
      Inc(LIndex);
      if LIndex > 5 then
        Break;
    end;
  end;
  FCount := LIndex;
end;

end.
