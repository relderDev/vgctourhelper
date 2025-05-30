unit Pokemon.Context;

interface

uses
  AK.Classes,
  Pokemon.Data;

type
  TPokemonDataType = (dtPokemon, dtType, dtItem, dtAbility, dtMove);

  TPokemonDataLanguage = (dlEn, dlDe, dlFr, dlEs, dlIt, dlJp, dlKr, dlZh, dlTw);

  TPokemonContext = class
  strict private
    FPokemon: TPokemonDatabase;
    FTypes: TPokemonDatabase;
    FItems: TPokemonDatabase;
    FAbilities: TPokemonDatabase;
    FMoves: TPokemonDatabase;
    FConfig: TAKDynRecord;
    FLanguage: TPokemonDataLanguage;
    FSVGTeraTypes: TAKDynRecord;
    FSaveOnExit: Boolean;
    class var FConfigName: string;
    class var FInstance: TPokemonContext;
    procedure SetConfigDefaults;
    procedure LoadSVGTeratypes;
    procedure FreeData;
    procedure SetDataPath(const AValue: string);
    procedure SetAssetsBaseUrl(const AValue: string);
    procedure SetAssetsFolder(const ADataType: TPokemonDataType; const AValue: string);
    procedure SetKeepDataOpen(const AValue: Boolean);
    procedure SetLanguage(const AValue: string);
    function DefaultKeyFieldName(const ADataType: TPokemonDataType): string;
    function DefaultDataFileName(const ADataType: TPokemonDataType): string;
    function DefaultAssetFieldName(const ADataType: TPokemonDataType): string;
    function InitDatabase(const ADataType: TPokemonDataType): TPokemonDatabase;
    function GetDatabase(const ADataType: TPokemonDataType): TPokemonDatabase;
    function GetDataPath: string;
    function GetAssetsBaseUrl: string;
    function GetAssetsFolder(const ADataType: TPokemonDataType): string;
    function GetAssetsUrl(const ADataType: TPokemonDataType): string;
    function GetIsOpen(const ADataType: TPokemonDataType): Boolean;
    function GetIsAllOpen: Boolean;
    function GetKeepDataOpen: Boolean;
    function GetTranslation(const ADataType: TPokemonDataType; const AKey: string): string;
    function GetSVGTera(const AType: string): string;
    function GetLanguage: string;
    function GetLanguageExtended: string;
    class function GetInstance: TPokemonContext; static;
  strict protected
    property AssetsBaseUrl: string read GetAssetsBaseUrl write SetAssetsBaseUrl;
    property AssetsFolder[const ADataType: TPokemonDataType]: string read GetAssetsFolder write SetAssetsFolder;
  public
    property Config: TAKDynRecord read FConfig;
    property DataPath: string read GetDataPath write SetDataPath;
    property AssetsUrl[const ADataType: TPokemonDataType]: string read GetAssetsUrl;
    property IsOpen[const ADataType: TPokemonDataType]: Boolean read GetIsOpen;
    property IsAllOpen: Boolean read GetIsAllOpen;
    property KeepDataOpen: Boolean read GetKeepDataOpen write SetKeepDataOpen;
    property Database[const ADataType: TPokemonDataType]: TPokemonDatabase read GetDatabase; default;
    property _[const ADataType: TPokemonDataType; const AKey: string]: string read GetTranslation;
    property SVGTera[const AType: string]: string read GetSVGTera;
    property Lang: TPokemonDataLanguage read FLanguage;
    property Language: string read GetLanguage write SetLanguage;
    property LanguageExtended: string read GetLanguageExtended;
    property SaveOnExit: Boolean read FSaveOnExit write FSaveOnExit;
    class property ConfigName: string read FConfigName write FConfigName;
    class property Instance: TPokemonContext read GetInstance;
    procedure Open(const ADataType: TPokemonDataType); overload;
    procedure Open; overload;
    procedure Close(const ADataType: TPokemonDataType); overload;
    procedure Close; overload;
    constructor Create;
    destructor Destroy; override;
    class procedure ReloadConfig;
    class destructor Destroy;
  end;

function PokemonContext: TPokemonContext;
function PokemonDataTypeName(const ADataType: TPokemonDataType): string;
function PokemonDataLanguageName(const ADataLanguage: TPokemonDataLanguage): string;

implementation

uses
  SysUtils, StrUtils, TypInfo, Winapi.Windows,
  AK.Constants, AK.Base, AK.Utils, AK.Indy,
  Pokemon.Constants;

function PokemonContext: TPokemonContext;
begin
  Result := TPokemonContext.Instance;
end;

function PokemonDataTypeName(const ADataType: TPokemonDataType): string;
begin
  Result := TAKEnum<TPokemonDataType>.Name(ADataType);
end;

function PokemonDataLanguageName(const ADataLanguage: TPokemonDataLanguage): string;
begin
  Result := LowerCase(TAKEnum<TPokemonDataLanguage>.Name(ADataLanguage));
end;

{ TPokemonContext }

procedure TPokemonContext.Close(const ADataType: TPokemonDataType);
begin
  if not KeepDataOpen then
    GetDatabase(ADataType).Close;
end;

procedure TPokemonContext.Close;
var
  LDataType: TPokemonDataType;
begin
  for LDataType := Low(TPokemonDataType) to High(TPokemonDataType) do
    Close(LDataType);
end;

constructor TPokemonContext.Create;
begin
  inherited Create;

  FConfig := TAKDynRecord.Create;
  if ConfigName = '' then
    ConfigName := 'Config.yaml';
  if FileExists(AppPath + ConfigName) then
    Config.LoadFromFile(AppPath + ConfigName);
  SetConfigDefaults;
  Language := Config.GetString('Language', 'en');
  FSVGTeraTypes := TAKDynRecord.Create;
  FSaveOnExit := False;

  // Add all "Config:MacroName" macros to the application's scope.
  TAKAppMacrosRegistry.Instance.RegisterExpander('Config', Config.AsExpander);
end;

destructor TPokemonContext.Destroy;
begin
  FreeData;
  FreeAndNil(FSVGTeraTypes);
  if SaveOnExit then
    Config.SaveToFile(AppPath + ConfigName);
  FreeAndNil(FConfig);
  inherited;
end;

function TPokemonContext.DefaultAssetFieldName(const ADataType: TPokemonDataType): string;
begin
  case ADataType of
    dtPokemon: Result := 'Dex_Number';
    dtItem: Result := 'Number2';
    dtType: Result := 'Type';
  end;
end;

function TPokemonContext.DefaultDataFileName(const ADataType: TPokemonDataType): string;
begin
  case ADataType of
    dtPokemon: Result := 'Pokemon.csv';
    dtType: Result := 'Colors.csv';
    dtItem: Result := 'Items.csv';
    dtAbility: Result := 'Abilities.csv';
    dtMove: Result := 'Moves.csv';
  end;
end;

function TPokemonContext.DefaultKeyFieldName(const ADataType: TPokemonDataType): string;
begin
  case ADataType of
    dtPokemon: Result := 'Pokémon';
    dtType: Result := 'Type';
    dtItem: Result := 'Item';
    dtAbility: Result := 'English';
    dtMove: Result := 'Move';
  end;
end;

class destructor TPokemonContext.Destroy;
begin
  FreeAndNil(FInstance);
end;

procedure TPokemonContext.FreeData;
begin
  FreeAndNil(FPokemon);
  FreeAndNil(FTypes);
  FreeAndNil(FItems);
  FreeAndNil(FAbilities);
  FreeAndNil(FMoves);
end;

function TPokemonContext.GetAssetsBaseUrl: string;
begin
  Result := Config.GetString('AssetsUrl',
    'https://cdn.jsdelivr.net/gh/relderDev/vgctourhelper-resources@latest/Assets/');
end;

function TPokemonContext.GetAssetsFolder(const ADataType: TPokemonDataType): string;
var
  LTypeName: string;
begin
  LTypeName := PokemonDataTypeName(ADataType);
  if not MatchText(LTypeName, POKEMON_ASSETS_DATA) then
    raise Exception.CreateFmt('No assets for data type "%s".', [LTypeName]);

  Result := Config.GetString(LTypeName + 'AssetsFolder',
    LTypeName + IfThen(not SameText(LTypeName, 'Pokemon'), 's') + '/');
end;

function TPokemonContext.GetAssetsUrl(const ADataType: TPokemonDataType): string;
begin
  Result := AssetsBaseUrl + AssetsFolder[ADataType];
end;

function TPokemonContext.GetDatabase(const ADataType: TPokemonDataType): TPokemonDatabase;
begin
  case ADataType of
    dtPokemon:
    begin
      if not Assigned(FPokemon) then
        FPokemon := InitDatabase(ADataType);
      Result := FPokemon;
    end;
    dtType:
    begin
      if not Assigned(FTypes) then
        FTypes := InitDatabase(ADataType);
      Result := FTypes;
    end;
    dtItem:
    begin
      if not Assigned(FItems) then
        FItems := InitDatabase(ADataType);
      Result := FItems;
    end;
    dtAbility:
    begin
      if not Assigned(FAbilities) then
        FAbilities := InitDatabase(ADataType);
      Result := FAbilities;
    end;
    dtMove:
    begin
      if not Assigned(FMoves) then
        FMoves := InitDatabase(ADataType);
      Result := FMoves;
    end;
    else
      raise Exception.CreateFmt('Unsupported data type "%s".', [PokemonDataTypeName(ADataType)]);
  end;
end;

function TPokemonContext.GetDataPath: string;
begin
  Result := ReplaceText(Config.GetString('DataPath'), '{App}', AppPath);
  if Result = '' then
    Result := ConcatPath(DEFAULT_DATA_PATH);
  Result := IncludeTrailingPathDelimiter(Result);
end;

class function TPokemonContext.GetInstance: TPokemonContext;
begin
  if not Assigned(FInstance) then
    FInstance := TPokemonContext.Create;
  Result := FInstance;
end;

function TPokemonContext.GetIsAllOpen: Boolean;
var
  LDataType: TPokemonDataType;
begin
  Result := True;
  for LDataType := Low(TPokemonDataType) to High(TPokemonDataType) do
    if not IsOpen[LDataType] then
      Exit(False);
end;

function TPokemonContext.GetIsOpen(const ADataType: TPokemonDataType): Boolean;
begin
  Result := GetDatabase(ADataType).IsOpen;
end;

function TPokemonContext.GetKeepDataOpen: Boolean;
begin
  Result := Config.GetBoolean('KeepDataOpen');
end;

function TPokemonContext.GetLanguage: string;
begin
  Result := PokemonDataLanguageName(FLanguage);
end;

function TPokemonContext.GetLanguageExtended: string;
begin
  case FLanguage of
    dlEn: Result := 'English';
    dlDe: Result := 'German';
    dlFr: Result := 'French';
    dlEs: Result := 'Spanish';
    dlIt: Result := 'Italian';
    dlJp: Result := 'Japanese';
    dlKr: Result := 'Korean';
    dlZh: Result := 'Chinese 1';
    dlTw: Result := 'Chinese 2';
  end;
end;

function TPokemonContext.GetSVGTera(const AType: string): string;
begin
  Result := FSVGTeraTypes.GetString(AType);
end;

function TPokemonContext.GetTranslation(const ADataType: TPokemonDataType;
  const AKey: string): string;
begin
  Result := GetDatabase(ADataType)._[AKey, LanguageExtended];
end;

function TPokemonContext.InitDatabase(const ADataType: TPokemonDataType): TPokemonDatabase;
var
  LTypeName: string;
  LDataFormat: string;
  LAssetFieldName: string;
begin
  LTypeName := PokemonDataTypeName(ADataType);
  LDataFormat := Config.GetString(LTypeName + 'DataFormat', 'CSV');
  if SameText(LDataFormat, 'CSV') then
    Result := TPokemonDatabaseCSV.Create(LTypeName)
  else if SameText(LDataFormat, 'JSON') then
    Result := TPokemonDatabaseJSON.Create(LTypeName)
  else
    raise Exception.CreateFmt('Format "%s" not supported.', [LDataFormat]);

  Result.FileName := DataPath + Config.GetString(LTypeName + 'DataFile', DefaultDataFileName(ADataType));
  Result.Url := Config.GetString(LTypeName + 'DataUrl');
  Result.Config['ColumnDelimiter'] := Config.GetString('ColumnDelimiter', ';');
  Result.Config['TextDelimiter'] := Config.GetString('TextDelimiter', '"');
  Result.Config['FirstRowIsHeader'] := Config.GetBoolean('FirstRowIsHeader', True);
  Result.Config['HeaderFromFirstRecord'] := Config.GetBoolean('HeaderFromFirstRecord', True);
  Result.Config['KeyFieldName'] := Config.GetString(LTypeName + 'KeyFieldName',
    DefaultKeyFieldName(ADataType));
  LAssetFieldName := Config.GetString(LTypeName + 'AssetFieldName', DefaultAssetFieldName(ADataType));
  if LAssetFieldName <> '' then
    Result.Config['AssetFieldName'] := LAssetFieldName;
end;

procedure TPokemonContext.LoadSVGTeratypes;
var
  LUrl: string;
  LBaseSVG: string;
  LHttp: TAKIndyHttp;
begin
  // Exit if already loaded.
  if FSVGTeraTypes.FieldCount > 0 then
    Exit;

  LUrl := AssetsUrl[dtType];
  LHttp := TAKIndyHttp.Create(nil);
  try
    LBaseSVG := LHttp.Get(LUrl + 'teratype.svg');
    // Tera stellar has a different background from the others.
    FSVGTeraTypes['Stellar'] := LHttp.Get(LUrl + 'teratype_stellar.svg');
    FTypes.EnumData(procedure (const ATypeRecord: TAKDynRecord)
      var
        LType: string;
        LFileName: string;
        LSVG: string;
      begin
        LType := ATypeRecord[FTypes.KeyFieldName];
        LFileName := LUrl + LType + '.svg';
        if SameText(LType, 'Stellar') then
          LSVG := FSVGTeraTypes[LType] + LHttp.Get(LFileName)
        else
          LSVG := LBaseSVG + LHttp.Get(LFileName);
        ATypeRecord.ExpandMacros(LSVG);
        FSVGTeraTypes[LType] := LSVG;
      end);
  finally
    FreeAndNil(LHttp);
  end;
end;

procedure TPokemonContext.Open;
var
  LDataType: TPokemonDataType;
begin
  for LDataType := Low(TPokemonDataType) to High(TPokemonDataType) do
    Open(LDataType);
end;

class procedure TPokemonContext.ReloadConfig;
begin
  FreeAndNil(FInstance);
end;

procedure TPokemonContext.Open(const ADataType: TPokemonDataType);
begin
  GetDatabase(ADataType).Open;
  // Store SVG for teratypes in memory.
  if ADataType = dtType then
    LoadSVGTeratypes;
end;

procedure TPokemonContext.SetAssetsBaseUrl(const AValue: string);
begin
  Assert(AValue <> '');

  Config.SetString('AssetsUrl', AValue + IfThen(AValue[High(AValue)] <> '/', '/'));
end;

procedure TPokemonContext.SetAssetsFolder(const ADataType: TPokemonDataType;
  const AValue: string);
begin
  Assert(AValue <> '');

  Config.SetString(PokemonDataTypeName(ADataType) + 'AssetsFolder',
    AValue + IfThen(AValue[High(AValue)] <> '/', '/'));
end;

procedure TPokemonContext.SetConfigDefaults;
var
  LTypeName: string;
  LType: TPokemonDataType;
begin
  AssetsBaseUrl := AssetsBaseUrl;
  for LTypeName in POKEMON_ASSETS_DATA do
  begin
    LType := TAKEnum<TPokemonDataType>.Value(LTypeName);
    AssetsFolder[LType] := AssetsFolder[LType];
  end;
end;

procedure TPokemonContext.SetDataPath(const AValue: string);
begin
  Assert(AValue <> '');

  Config.SetString('DataPath', AValue);
end;

procedure TPokemonContext.SetKeepDataOpen(const AValue: Boolean);
begin
  if KeepDataOpen and not AValue then
    Close;
  Config.SetBoolean('KeepDataOpen', AValue);
end;

procedure TPokemonContext.SetLanguage(const AValue: string);
begin
  Assert(Length(AValue) = 2);
  FLanguage := TAKEnum<TPokemonDataLanguage>.Value(AValue);
end;

end.
