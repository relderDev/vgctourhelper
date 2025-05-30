unit AK.Data;

interface

uses
  RegularExpressions,
  AK.Classes;

type
  TAKDynRecordCollectionCSV = class(TAKDynRecordCollection)
  strict private
    FSplittingHeader: Boolean;
    const SEP_MACRO = '%SEP%';
    procedure SetColumnDelimiter(const AValue: Char);
    procedure SetTextDelimiter(const AValue: Char);
    procedure SetFirstRowIsHeader(const AValue: Boolean);
    function ReplaceTextMatch(const AMatch: TMatch): string;
    function SplitColumns(const ARow: string; const AIsHeader: Boolean): TArray<string>;
    function GetColumnDelimiter: Char;
    function GetTextDelimiter: Char;
    function GetFirstRowIsHeader: Boolean;
  strict protected
    procedure InternalLoadData(const AData: string); override;
  public
    property ColumnDelimiter: Char read GetColumnDelimiter write SetColumnDelimiter;
    property TextDelimiter: Char read GetTextDelimiter write SetTextDelimiter;
    property FirstRowIsHeader: Boolean read GetFirstRowIsHeader write SetFirstRowIsHeader;
  end;

  TAKDynRecordMapCSV = class(TAKDynRecordMap)
  strict private
    FSplittingHeader: Boolean;
    const SEP_MACRO = '%SEP%';
    procedure SetColumnDelimiter(const AValue: Char);
    procedure SetTextDelimiter(const AValue: Char);
    procedure SetFirstRowIsHeader(const AValue: Boolean);
    //procedure SetKeyFieldName(const AValue: string);
    function ReplaceTextMatch(const AMatch: TMatch): string;
    function SplitColumns(const ARow: string; const AIsHeader: Boolean): TArray<string>;
    function GetColumnDelimiter: Char;
    function GetTextDelimiter: Char;
    function GetFirstRowIsHeader: Boolean;
  strict protected
    procedure InternalLoadData(const AData: string); override;
    function GetKeyFieldName: string; override;
  public
    property ColumnDelimiter: Char read GetColumnDelimiter write SetColumnDelimiter;
    property TextDelimiter: Char read GetTextDelimiter write SetTextDelimiter;
    property FirstRowIsHeader: Boolean read GetFirstRowIsHeader write SetFirstRowIsHeader;
    property KeyFieldName: string read GetKeyFieldName;// write SetKeyFieldName;
  end;

  TAKDynRecordCollectionJSON = class(TAKDynRecordCollection)
  strict private
    procedure SetHeaderFromFirstRecord(const AValue: Boolean);
    function GetHeaderFromFirstRecord: Boolean;
  strict protected
    procedure InternalLoadData(const AData: string); override;
  public
    property HeaderFromFirstRecord: Boolean read GetHeaderFromFirstRecord write SetHeaderFromFirstRecord;
  end;

  TAKDynRecordMapJSON = class(TAKDynRecordMap)
  strict private
    //procedure SetKeyFieldName(const AValue: string);
    procedure SetHeaderFromFirstRecord(const AValue: Boolean);
    function GetHeaderFromFirstRecord: Boolean;
  strict protected
    procedure InternalLoadData(const AData: string); override;
    function GetKeyFieldName: string; override;
  public
    property HeaderFromFirstRecord: Boolean read GetHeaderFromFirstRecord write SetHeaderFromFirstRecord;
    property KeyFieldName: string read GetKeyFieldName;// write SetKeyFieldName;
  end;

implementation

uses
  SysUtils, StrUtils, Classes, JSON, Generics.Collections,
  AK.Constants, AK.Base, AK.Utils;

{ TAKDynRecordCollectionCSV }

function TAKDynRecordCollectionCSV.GetColumnDelimiter: Char;
begin
  Result := AsChar(Config.GetString('ColumnDelimiter', ';'));
end;

function TAKDynRecordCollectionCSV.GetFirstRowIsHeader: Boolean;
begin
  Result := Config.GetBoolean('FirstRowIsHeader', True);
end;

function TAKDynRecordCollectionCSV.GetTextDelimiter: Char;
begin
  Result := AsChar(Config.GetString('TextDelimiter', '"'));
end;

procedure TAKDynRecordCollectionCSV.InternalLoadData(const AData: string);
var
  LList: TStringList;
  LRow: string;
begin
  inherited;
  if (FieldCount < 1) and not FirstRowIsHeader then
    raise AKException('No header defined.');

  LList := TStringList.Create;
  try
    LList.Text := AData;
    if FirstRowIsHeader then
    begin
      SetHeader(SplitColumns(LList[0], True));
      LList.Delete(0);
    end;
    for LRow in LList do
      AddRecord(SplitColumns(LRow, False));
  finally
    FreeAndNil(LList);
  end;
end;

function TAKDynRecordCollectionCSV.ReplaceTextMatch(const AMatch: TMatch): string;
begin
  if FSplittingHeader then
    Result := ReplaceStr(ReplaceStr(AMatch.Value, ColumnDelimiter, SEP_MACRO),
      TextDelimiter, '')
  else
    Result := ReplaceStr(ReplaceStr(AMatch.Value, ColumnDelimiter, SEP_MACRO),
      TextDelimiter, '"');
end;

procedure TAKDynRecordCollectionCSV.SetColumnDelimiter(const AValue: Char);
begin
  Config.SetString('ColumnDelimiter', AValue);
end;

procedure TAKDynRecordCollectionCSV.SetFirstRowIsHeader(const AValue: Boolean);
begin
  Config.SetBoolean('FirstRowIsHeader', AValue);
end;

procedure TAKDynRecordCollectionCSV.SetTextDelimiter(const AValue: Char);
begin
  Config.SetString('TextDelimiter', AValue);
end;

function TAKDynRecordCollectionCSV.SplitColumns(const ARow: string; const AIsHeader: Boolean): TArray<string>;
var
  LCleanRow: string;
  LRegex: TRegEx;
  I: Integer;
begin
  LCleanRow := ARow;
  FSplittingHeader := AIsHeader;
  if TextDelimiter <> #0 then
  begin
    LRegex := TRegEx.Create(BracketRegexText(TextDelimiter), [roIgnoreCase, roNotEmpty]);
    LCleanRow := LRegex.Replace(LCleanRow, ReplaceTextMatch);
  end;
  Result := LCleanRow.Split([ColumnDelimiter]);
  if Pos(SEP_MACRO, LCleanRow) > 0 then
    for I := 0 to High(Result) do
      Result[I] := ReplaceStr(Result[I], SEP_MACRO, ColumnDelimiter);
end;

{ TAKDynRecordMapCSV }

function TAKDynRecordMapCSV.GetColumnDelimiter: Char;
begin
  Result := AsChar(Config.GetString('ColumnDelimiter', ';'));
end;

function TAKDynRecordMapCSV.GetFirstRowIsHeader: Boolean;
begin
  Result := Config.GetBoolean('FirstRowIsHeader', True);
end;

function TAKDynRecordMapCSV.GetKeyFieldName: string;
begin
  Result := inherited;
  if Result = '' then
    Result := Config.GetString('KeyFieldName');
end;

function TAKDynRecordMapCSV.GetTextDelimiter: Char;
begin
  Result := AsChar(Config.GetString('TextDelimiter', '"'));
end;

procedure TAKDynRecordMapCSV.InternalLoadData(const AData: string);
var
  LList: TStringList;
  LRow: string;
begin
  inherited;
  if (FieldCount < 1) and not FirstRowIsHeader then
    raise AKException('No header defined.');

  LList := TStringList.Create;
  try
    LList.Text := AData;
    if FirstRowIsHeader then
    begin
      if KeyFieldName = '' then
        raise AKException('Key field name must not be empty.');
      SetHeader(SplitColumns(LList[0], True), KeyFieldName);
      LList.Delete(0);
    end;
    for LRow in LList do
      AddRecord(SplitColumns(LRow, False));
  finally
    FreeAndNil(LList);
  end;
end;

function TAKDynRecordMapCSV.ReplaceTextMatch(const AMatch: TMatch): string;
begin
  if FSplittingHeader then
    Result := ReplaceStr(ReplaceStr(AMatch.Value, ColumnDelimiter, SEP_MACRO),
      TextDelimiter, '')
  else
    Result := ReplaceStr(ReplaceStr(AMatch.Value, ColumnDelimiter, SEP_MACRO),
      TextDelimiter, '"');
end;

procedure TAKDynRecordMapCSV.SetColumnDelimiter(const AValue: Char);
begin
  Config.SetString('ColumnDelimiter', AValue);
end;

procedure TAKDynRecordMapCSV.SetFirstRowIsHeader(const AValue: Boolean);
begin
  Config.SetBoolean('FirstRowIsHeader', AValue);
end;

{procedure TAKDynRecordMapCSV.SetKeyFieldName(const AValue: string);
begin
  Config.SetString('KeyFieldName', AValue);
end;}

procedure TAKDynRecordMapCSV.SetTextDelimiter(const AValue: Char);
begin
  Config.SetString('TextDelimiter', AValue);
end;

function TAKDynRecordMapCSV.SplitColumns(const ARow: string; const AIsHeader: Boolean): TArray<string>;
var
  LCleanRow: string;
  LRegex: TRegEx;
  I: Integer;
begin
  LCleanRow := ARow;
  FSplittingHeader := AIsHeader;
  if TextDelimiter <> #0 then
  begin
    LRegex := TRegEx.Create(BracketRegexText(TextDelimiter), [roIgnoreCase, roNotEmpty]);
    LCleanRow := LRegex.Replace(LCleanRow, ReplaceTextMatch);
  end;
  Result := LCleanRow.Split([ColumnDelimiter]);
  if Pos(SEP_MACRO, LCleanRow) > 0 then
    for I := 0 to High(Result) do
      Result[I] := ReplaceStr(Result[I], SEP_MACRO, ColumnDelimiter);
end;

{ TAKDynRecordCollectionJSON }

function TAKDynRecordCollectionJSON.GetHeaderFromFirstRecord: Boolean;
begin
  Result := Config.GetBoolean('HeaderFromFirstRecord');
end;

procedure TAKDynRecordCollectionJSON.InternalLoadData(const AData: string);
var
  LValue: TJSONValue;
  LObject: TJSONObject;
  LArray: TJSONArray;
  LHeader: array of string;
  I: Integer;
begin
  inherited;
  if (FieldCount < 1) and not HeaderFromFirstRecord then
    raise AKException('No header defined.');

  // Most errors in this routine are type errors.
  ErrorClass := EAKTypeError;
  LValue := TJSONObject.ParseJSONValue(AData);
  try
    if not Assigned(LValue) then
      raise AKException(EAKFormatError, 'Invalid JSON (%s).', [AData]);
    if LValue is TJSONObject then
    begin
      LObject := LValue as TJSONObject;
      if LObject.Count <> 1 then
        raise AKException('JSON root element must have one single property.');
      if not (LObject.Pairs[0].JsonValue is TJSONArray) then
        raise AKException('JSON root element property must be an array.');
      LArray := LObject.Pairs[0].JsonValue as TJSONArray;
    end
    else if LValue is TJSONArray then
      LArray := LValue as TJSONArray
    else
      raise AKException('Invalid JSON root element (%s).', [LValue.ClassName]);
    if LArray.Count = 0 then
      Exit;

    if HeaderFromFirstRecord then
    begin
      if not (LArray[0] is TJSONObject) then
        raise AKException('Records must be represented by JSON objects.');
      LObject := LArray[0] as TJSONObject;
      SetLength(LHeader, LObject.Count);
      for I := 0 to LObject.Count - 1 do
        LHeader[I] := LObject.Pairs[I].JsonString.Value;
      SetHeader(LHeader);
    end;

    for I := 0 to LArray.Count - 1 do
      if not (LArray[I] is TJSONObject) then
        raise AKException('Records must be represented by JSON objects.')
      else
        AddRecord(LArray[I] as TJSONObject);
  finally
    FreeAndNil(LValue);
    ErrorClass := EAKConfigError;
  end;
end;

procedure TAKDynRecordCollectionJSON.SetHeaderFromFirstRecord(const AValue: Boolean);
begin
  Config.SetBoolean('HeaderFromFirstRecord', AValue);
end;

{ TAKDynRecordMapJSON }

function TAKDynRecordMapJSON.GetHeaderFromFirstRecord: Boolean;
begin
  Result := Config.GetBoolean('HeaderFromFirstRecord');
end;

function TAKDynRecordMapJSON.GetKeyFieldName: string;
begin
  Result := inherited;
  if Result = '' then
    Result := Config.GetString('KeyFieldName');
end;

procedure TAKDynRecordMapJSON.InternalLoadData(const AData: string);
var
  LValue: TJSONValue;
  LObject: TJSONObject;
  LArray: TJSONArray;
  LHeader: array of string;
  I: Integer;
begin
  inherited;
  if (FieldCount < 1) and not HeaderFromFirstRecord then
    raise AKException('No header defined.');

  ErrorClass := EAKTypeError;
  LValue := TJSONObject.ParseJSONValue(AData);
  try
    if not Assigned(LValue) then
      raise AKException(EAKFormatError, 'Invalid JSON.');
    if LValue is TJSONObject then
    begin
      LObject := LValue as TJSONObject;
      if LObject.Count <> 1 then
        raise AKException('JSON root element must have one single property.');
      if not (LObject.Pairs[0].JsonValue is TJSONArray) then
        raise AKException('JSON root element property must be an array.');
      LArray := LObject.Pairs[0].JsonValue as TJSONArray;
    end
    else if LValue is TJSONArray then
      LArray := LValue as TJSONArray
    else
      raise AKException('Invalid JSON root element (%s).', [LValue.ClassName]);
    if LArray.Count = 0 then
      Exit;

    if HeaderFromFirstRecord then
    begin
      if KeyFieldName = '' then
        raise AKException(EAKConfigError, 'Key field name must not be empty.');
      if not (LArray[0] is TJSONObject) then
        raise AKException('Records must be represented by JSON objects.');
      LObject := LArray[0] as TJSONObject;
      SetLength(LHeader, LObject.Count);
      for I := 0 to LObject.Count - 1 do
        LHeader[I] := LObject.Pairs[I].JsonString.Value;
      SetHeader(LHeader, KeyFieldName);
    end;

    for I := 0 to LArray.Count - 1 do
      if not (LArray[I] is TJSONObject) then
        raise AKException('Records must be represented by JSON objects.')
      else
        AddRecord(LArray[I] as TJSONObject);
  finally
    FreeAndNil(LValue);
    ErrorClass := EAKConfigError;
  end;
end;

procedure TAKDynRecordMapJSON.SetHeaderFromFirstRecord(const AValue: Boolean);
begin
  Config.SetBoolean('HeaderFromFirstRecord', AValue);
end;

{procedure TAKDynRecordMapJSON.SetKeyFieldName(const AValue: string);
begin
  Config.SetString('KeyFieldName', AValue);
end;}

end.
