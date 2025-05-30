unit Pokemon.Data;

interface

uses
  AK.Classes;

type
  TPokemonDatabase = class abstract
  strict private
    FName: string;
    FDataClass: TAKDynRecordMapClass;
    FData: TAKDynRecordMap;
    FFileName: string;
    FUrl: string;
    FIsOpen: Boolean;
    procedure CreateData;
    function GetConfig: TAKDynRecord;
    function GetData(const AKey: string): TAKDynRecord;
    function GetAsset(const AKey: string): Variant;
    function GetTranslation(const AKey, ALanguage: string): string;
    function GetKeyFieldName: string;
  strict protected
    property Records: TAKDynRecordMap read FData;
    procedure AfterOpen; virtual;
    procedure BeforeClose; virtual;
    constructor CreateInternal(const AName: string; const AClass: TAKDynRecordMapClass);
  public
    property Name: string read FName;
    property Config: TAKDynRecord read GetConfig;
    property Data[const AKey: string]: TAKDynRecord read GetData; default;
    property Asset[const AKey: string]: Variant read GetAsset;
    property _[const AKey, ALanguage: string]: string read GetTranslation;
    property FileName: string read FFileName write FFileName;
    property Url: string read FUrl write FUrl;
    property IsOpen: Boolean read FIsOpen;
    property KeyFieldName: string read GetKeyFieldName;
    procedure EnumData(const AProc: TAKDynRecordProc);
    procedure Open;
    procedure Close;
    function Find(const AColumnName: string; const AValue: Variant): TAKDynRecord; overload;
    function Find(const AColumnNames: array of string; const AValues: array of Variant): TAKDynRecord; overload;
    function FindKey(const AColumnName: string; const AValue: Variant): string; overload;
    function FindKey(const AColumnNames: array of string; const AValues: array of Variant): string; overload;
    function FindKeyFromAsset(const AValue: Variant): string;
    constructor Create(const AName: string); virtual; abstract;
    destructor Destroy; override;
  end;

  TPokemonDatabaseClass = class of TPokemonDatabase;

  TPokemonDatabaseCSV = class(TPokemonDatabase)
  public
    constructor Create(const AName: string); override;
  end;

  TPokemonDatabaseJSON = class(TPokemonDatabase)
  public
    constructor Create(const AName: string); override;
  end;

implementation

uses
  SysUtils,
  AK.Data, AK.Indy;

{ TPokemonDatabase }

procedure TPokemonDatabase.AfterOpen;
begin
end;

procedure TPokemonDatabase.BeforeClose;
begin
end;

procedure TPokemonDatabase.Close;
begin
  if not FIsOpen then
    Exit;
  BeforeClose;
  FData.Clear;
  FIsOpen := False;
end;

procedure TPokemonDatabase.CreateData;
begin
  FData := FDataClass.Create;
  FData.Config['FirstRowIsHeader'] := True;
  FData.Config['HeaderFromFirstRecord'] := True;
end;

constructor TPokemonDatabase.CreateInternal(const AName: string;
  const AClass: TAKDynRecordMapClass);
begin
  Assert(Assigned(AClass));

  inherited Create;
  FName := AName;
  FDataClass := AClass;
  CreateData;
  FIsOpen := False;
end;

destructor TPokemonDatabase.Destroy;
begin
  if FIsOpen then
    BeforeClose;
  FreeAndNil(FData);
  inherited;
end;

procedure TPokemonDatabase.EnumData(const AProc: TAKDynRecordProc);
begin
  FData.EnumRecords(AProc);
end;

function TPokemonDatabase.Find(const AColumnNames: array of string;
  const AValues: array of Variant): TAKDynRecord;
begin
  if not FIsOpen then
    raise Exception.CreateFmt('Dataset "%s" is not open.', [FName]);
  Result := FData.FindFirst(AColumnNames, AValues);
end;

function TPokemonDatabase.Find(const AColumnName: string; const AValue: Variant): TAKDynRecord;
begin
  if not FIsOpen then
    raise Exception.CreateFmt('Dataset "%s" is not open.', [FName]);
  Result := FData.FindFirst([AColumnName], [AValue]);
end;

function TPokemonDatabase.FindKey(const AColumnNames: array of string;
  const AValues: array of Variant): string;
var
  LRecord: TAKDynRecord;
begin
  LRecord := Find(AColumnNames, AValues);
  if Assigned(LRecord) then
    Result := LRecord.GetString(Config.GetString('KeyFieldName'));
end;

function TPokemonDatabase.FindKeyFromAsset(const AValue: Variant): string;
begin
  Result := FindKey(Config.GetString('AssetFieldName'), AValue);
end;

function TPokemonDatabase.FindKey(const AColumnName: string;
  const AValue: Variant): string;
var
  LRecord: TAKDynRecord;
begin
  LRecord := Find(AColumnName, AValue);
  if Assigned(LRecord) then
    Result := LRecord.GetString(Config.GetString('KeyFieldName'));
end;

function TPokemonDatabase.GetAsset(const AKey: string): Variant;
begin
  Result := Data[AKey][Config.GetString('AssetFieldName')];
end;

function TPokemonDatabase.GetConfig: TAKDynRecord;
begin
  Result := FData.Config;
end;

function TPokemonDatabase.GetData(const AKey: string): TAKDynRecord;
begin
  if not FIsOpen then
    raise Exception.CreateFmt('Dataset "%s" is not open.', [FName]);
  Result := FData[AKey];
end;

function TPokemonDatabase.GetKeyFieldName: string;
begin
  Result := FData.KeyFieldName;
end;

function TPokemonDatabase.GetTranslation(const AKey, ALanguage: string): string;
begin
  Result := Data[AKey].GetString(ALanguage);
end;

procedure TPokemonDatabase.Open;
var
  LHttp: TAKIndyHttp;
begin
  if FIsOpen then
    Exit;
  if FileName <> '' then
    FData.LoadFromFile(FileName)
  else if Url <> '' then
  begin
    LHttp := TAKIndyHttp.Create(nil);
    try
      FData.LoadData(LHttp.Get(Url));
    finally
      FreeAndNil(LHttp);
    end;
  end
  else
    raise Exception.Create('No loading data method specified.');

  FIsOpen := True;
  AfterOpen;
end;

{ TPokemonDatabaseCSV }

constructor TPokemonDatabaseCSV.Create(const AName: string);
begin
  CreateInternal(AName, TAKDynRecordMapCSV);
end;

{ TPokemonDatabaseJSON }

constructor TPokemonDatabaseJSON.Create(const AName: string);
begin
  CreateInternal(AName, TAKDynRecordMapJSON);
end;

end.
