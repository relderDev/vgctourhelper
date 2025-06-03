unit AK.Classes;

{$I AK.Defines.inc}

interface

uses
  SysUtils, JSON, Generics.Collections, Xml.XMLIntf,
  AK.Constants, AK.Base;

type
  /// <summary>
  ///  A meaning to hold data efficiently without excessive restrictions or
  ///  massive overheads. It works as a string-key dictionary with file saving
  ///  and loading capabilities and holds utility methods to cast/set its field
  ///  values as delphi types. It can also hold objects (it never owns them).
  /// </summary>
  TAKDynRecord = class(TAKExpanderBase)
  strict private
    FItems: TDictionary<string, Variant>;
    FComments: TDictionary<string, string>;
    FDateTimeFormatIndex: Integer;
    FStrictDateTimeFormat: Boolean;
    FFloatFormatSettings: TFormatSettings;
    procedure SetDateTimeFormat(const AValue: string);
    procedure SetValue(const AName: string; const AValue: Variant);
    procedure SetFieldComment(const AName, AValue: string);
    function HasNotNull(const AName: string): Boolean;
    function GetFormattedComment(const AComment: string; const AIndent: Integer): string;
    function GetDateTimeFormatSettings: TFormatSettings;
    function GetDateTimeFormat: string;
    function GetValue(const AName: string): Variant;
    function GetFieldComment(const AName: string): string;
    function GetFieldType(const AName: string): string;
    function GetFieldCount: Integer;
  strict protected
    function GetMacroValue(const AMacroName: string): string; override;
  public
    { Get, set and handle data }
    property DateTimeFormatSettings: TFormatSettings read GetDateTimeFormatSettings;
    property DateTimeFormat: string read GetDateTimeFormat write SetDateTimeFormat;
    property StrictDateTimeFormat: Boolean read FStrictDateTimeFormat write FStrictDateTimeFormat;
    property FloatFormatSettings: TFormatSettings read FFloatFormatSettings write FFloatFormatSettings;
    property Fields[const AName: string]: Variant read GetValue write SetValue; default;
    property FieldType[const AName: string]: string read GetFieldType;
    property FieldComment[const AName: string]: string read GetFieldComment write SetFieldComment;
    property FieldCount: Integer read GetFieldCount;
    procedure LoadFromFile(const AFileName: string; const AEncoding: TEncoding); overload;
    procedure LoadFromFile(const AFileName: string); overload;
    procedure LoadFromXML(const AXMLRoot: IXMLNode); virtual;
    procedure LoadFromJSON(const AJSONObject: TJSONObject); virtual;
    procedure SaveToFile(const AFileName: string; const AIncludeComments: Boolean; const AEncoding: TEncoding); overload;
    procedure SaveToFile(const AFileName: string; const AIncludeComments: Boolean); overload;
    procedure Clear;
    procedure Remove(const AName: string);
    /// <summary>Stores the string value as the appropriate variant type.</summary>
    procedure SetValueFromText(const AName, AText: string);
    /// <summary>Stores the value always as a string.</summary>
    /// <remarks>Does not store empty values, while Fields[] always does.</remarks>
    procedure SetString(const AName, AValue: string);
    procedure SetBoolean(const AName: string; const AValue: Boolean);
    procedure SetInteger(const AName: string; const AValue: Integer);
    procedure SetFloat(const AName: string; const AValue: Double);
    procedure SetDateTime(const AName: string; const AValue: TDateTime);
    procedure SetObject(const AName: string; const AValue: TObject);
    function HasField(const AName: string): Boolean;
    function GetString(const AName: string; const ADefault: string = ''): string;
    function GetBoolean(const AName: string; const ADefault: Boolean = False): Boolean;
    function GetInteger(const AName: string; const ADefault: Integer = 0): Integer;
    function GetFloat(const AName: string; const ADefault: Double = 0.0): Double;
    function GetDateTime(const AName: string; const ADefault: TDateTime = NULL_DATETIME): TDateTime;
    function GetObject(const AName: string; const ADefault: TObject = nil): TObject;

    /// <summary>
    ///  Iterates on all the field names.
    /// </summary>
    procedure EnumAllFieldNames(const AProc: TAKStringProc);

    /// <summary>
    ///  Iterates on all the field names for which APredicate evaluates to true.
    /// </summary>
    procedure EnumFieldNames(const AProc: TAKStringProc;
      const APredicate: TAKStringPredicate);
  public
    { Formatted data options }
    function AsText(const AIncludeComments: Boolean = True; const AIndent: Integer = 0): string; overload;
    function AsTypedText: string;
    function AsJSONString(const ABeautified: Boolean = False): string;
  public
    { Class methods }
    constructor Create;
    destructor Destroy; override;
  end;

  TAKDynRecordProc = reference to procedure (const ARecord: TAKDynRecord);
  TAKDynRecordPredicate = reference to function (const ARecord: TAKDynRecord): Boolean;
  TAKDynRecords = array of TAKDynRecord;

  /// <summary>
  ///  Abstract class to handle TAKDynRecord objects. It's declared just to avoid
  ///  repeating code in its descendants - it should never be referenced as is.
  /// </summary>
  TAKDynRecordSet = class abstract(TAKBase)
  strict private
    FConfig: TAKDynRecord;
    FHeader: array of string;
    FFieldCount: Integer;
    FFileName: string;
    FBeforeAddXML: TAKDynRecordProc;
    FBeforeAddJSON: TAKDynRecordProc;
    procedure AppendXMLRecord(const AXMLData: IXMLNode; const ACleanIt: Boolean);
    procedure AppendJSONRecord(const AJSONData: TJSONObject; const ACleanIt: Boolean);
    function GetHeader(const AIndex: Integer): string;
  strict protected
    property Header[const AIndex: Integer]: string read GetHeader;
    procedure CheckSetHeader; virtual;
    procedure AppendRecord(const ARecord: TAKDynRecord); virtual; abstract;
    procedure InternalLoadData(const AData: string); virtual;
    procedure InternalSetHeader(const AColumns: array of string);
    function GetCount: Integer; virtual; abstract;
  public
    property Config: TAKDynRecord read FConfig;
    property FieldCount: Integer read FFieldCount;
    property Count: Integer read GetCount;
    property FileName: string read FFileName;
    property BeforeAddXML: TAKDynRecordProc read FBeforeAddXML write FBeforeAddXML;
    property BeforeAddJSON: TAKDynRecordProc read FBeforeAddJSON write FBeforeAddJSON;

    /// <summary>
    ///  Adds a record that holds the given values.
    /// </summary>
    /// <remarks>
    ///  The header must be set before adding a record and its fields must
    ///  be the only ones declared on the record.
    /// </remarks>
    procedure AddRecord(const AValues: array of Variant); overload;

    /// <summary>
    ///  Adds a record setting its values from the given string values (see
    ///  TAKDynRecord.SetValueFromText).
    /// </summary>
    /// <remarks>
    ///  The header must be set before adding a record and its fields must
    ///  be the only ones declared on the record.
    /// </remarks>
    procedure AddRecord(const AValues: array of string); overload;

    /// <summary>
    ///  Adds a record.
    /// </summary>
    /// <remarks>
    ///  The header must be set before adding a record and its fields must
    ///  be the only ones declared on the record.
    /// </remarks>
    procedure AddRecord(const ARecord: TAKDynRecord); overload;

    /// <summary>
    ///  Adds a record loaded with the XML data.
    /// </summary>
    /// <remarks>
    ///  The header must be set before adding a record and its fields must
    ///  be the only ones declared on the record.
    /// </remarks>
    procedure AddRecord(const AXML: IXMLNode); overload;

    /// <summary>
    ///  Adds a record loaded with the JSON data.
    /// </summary>
    /// <remarks>
    ///  The header must be set before adding a record and its fields must
    ///  be the only ones declared on the record.
    /// </remarks>
    procedure AddRecord(const AJSON: TJSONObject); overload;

    /// <summary>
    ///  Adds a record loaded with the XML data after having removed all fields
    ///  that aren't on the header.
    /// </summary>
    /// <remarks>
    ///  The header must be set before adding external XML.
    /// </remarks>
    procedure AddExternalXML(const AXML: IXMLNode);

    /// <summary>
    ///  Adds a record loaded with the JSON data after having removed all fields
    ///  that aren't on the header.
    /// </summary>
    /// <remarks>
    ///  The header must be set before adding external JSON.
    /// </remarks>
    procedure AddExternalJSON(const AJSON: TJSONObject);

    /// <summary>
    ///  Clears all the records and loads the data. The header could already be
    ///  set or it can derived from the data itself, depending on the
    ///  implementation of InternalLoadData.
    /// </summary>
    procedure LoadData(const AData: string);

    /// <summary>
    ///  Reads the given text file and calls LoadData on its contents.
    /// </summary>
    procedure LoadFromFile(const AFileName: string; const AEncoding: TEncoding); overload;

    /// <summary>
    ///  Reads the given text file and calls LoadData on its contents.
    /// </summary>
    procedure LoadFromFile(const AFileName: string); overload;

    procedure Clear; virtual; abstract;
    function FindFirst(const ANames: array of string; const AValues: array of Variant): TAKDynRecord; virtual; abstract;
    function FindAll(const ANames: array of string; const AValues: array of Variant): TAKDynRecords; virtual; abstract;
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Handles TAKDynRecord objects in a non-indexed manner. Use it to handle
  ///  generic collection of data without any warranties on uniqueness of the
  ///  data. Each record must have the fields declared in the header.
  /// </summary>
  TAKDynRecordCollection = class(TAKDynRecordSet)
  strict private
    FRecords: TAKDynRecords;
    FCount: Integer;
    function RecordIndex(const ARecord: TAKDynRecord): Integer;
    function GetRecord(const AIndex: Integer): TAKDynRecord;
  strict protected
    procedure AppendRecord(const ARecord: TAKDynRecord); override;
    function GetCount: Integer; override;
  public
    property Records[const AIndex: Integer]: TAKDynRecord read GetRecord; default;
    procedure SetHeader(const AColumnNames: array of string);
    procedure RemoveRecord(const ARecord: TAKDynRecord); overload;
    procedure RemoveRecord(const AIndex: Integer); overload;
    procedure Clear; override;
    procedure EnumRecords(const AProc: TAKDynRecordProc);
    function FindFirst(const ANames: array of string; const AValues: array of Variant): TAKDynRecord; override;
    function FindAll(const ANames: array of string; const AValues: array of Variant): TAKDynRecords; override;
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Handles TAKDynRecord objects in a indexed manner. Use it to handle a set
  ///  of data that has at least one unique field (the key field). Each record
  ///  must have the fields declared in the header.
  /// </summary>
  TAKDynRecordMap = class(TAKDynRecordSet)
  strict private
    FKeyIndex: Integer;
    FRecords: TObjectDictionary<string, TAKDynRecord>;
    function RecordKey(const ARecord: TAKDynRecord): string;
    function GetRecord(const AKey: string): TAKDynRecord;
  strict protected
    procedure CheckSetHeader; override;
    procedure AppendRecord(const ARecord: TAKDynRecord); override;
    function GetCount: Integer; override;
    function GetKeyFieldName: string; virtual;
  public
    property Records[const AKey: string]: TAKDynRecord read GetRecord; default;
    property KeyFieldName: string read GetKeyFieldName;
    procedure SetHeader(const AColumnNames: array of string; const AKeyIndex: Integer); overload;
    procedure SetHeader(const AColumnNames: array of string; const AKeyFieldName: string); overload;
    procedure RemoveRecord(const ARecord: TAKDynRecord); overload;
    procedure RemoveRecord(const AKey: string); overload;
    procedure Clear; override;
    procedure EnumRecords(const AProc: TAKDynRecordProc);
    function FindRecord(const AKey: string): TAKDynRecord;
    function FindFirst(const ANames: array of string; const AValues: array of Variant): TAKDynRecord; override;
    function FindAll(const ANames: array of string; const AValues: array of Variant): TAKDynRecords; override;
    constructor Create;
    destructor Destroy; override;
  end;

  TAKDynRecordCollectionClass = class of TAKDynRecordCollection;
  TAKDynRecordMapClass = class of TAKDynRecordMap;

implementation

uses
  StrUtils, Variants, Classes, TypInfo, Generics.Defaults,
  AK.Utils;

{ TAKDynRecord }

function TAKDynRecord.AsJSONString(const ABeautified: Boolean): string;
var
  LSeparator: string;
  LIndent: Integer;
  LName: string;
  LItem: string;
  LValues: string;
begin
  Result := '{#values#}';
  LSeparator := ', ';
  LIndent := 0;
  if ABeautified then
  begin
    Result := '{' + sLineBreak + '#values#' + sLineBreak + '}';
    LSeparator := ',' + sLineBreak;
    LIndent := 2;
  end;
  LValues := '';
  for LName in FItems.Keys do
  begin
    if FieldType[LName] = 'String' then
      LItem := Format('"%s": "%s"', [LName, EscapeJSONString(GetString(LName))])
    else
      LItem := Format('"%s": %s', [LName, GetString(LName)]);
    if LValues = '' then
      LValues := LItem
    else
      LValues := LValues + LSeparator + LItem;
  end;
  Result := ReplaceStr(Result, '#values#', IndentLines(LValues, LIndent));
end;

function TAKDynRecord.AsText(const AIncludeComments: Boolean; const AIndent: Integer): string;
var
  LName: string;
  LLine: string;
  LComment: string;
begin
  for LName in FItems.Keys do
  begin
    LLine := '';
    LComment := FieldComment[LName];
    if AIncludeComments and (LComment <> '') then
      LLine := sLineBreak + GetFormattedComment(LComment, AIndent) + sLineBreak;
    LLine := LLine + StringOfChar(' ', AIndent) + LName + ': ' + GetString(LName);
    if Result = '' then
      Result := LLine
    else
      Result := Result + sLineBreak + LLine;
  end;
  if Pos(sLineBreak, Result) = 1 then
    Delete(Result, Low(Result), Length(sLineBreak));
end;

function TAKDynRecord.AsTypedText: string;
var
  LName: string;
  LLine: string;
begin
  Result := '';
  for LName in FItems.Keys do
  begin
    LLine := Format('[%s] %s: %s', [FieldType[LName], LName, GetString(LName)]);
    if Result = '' then
      Result := LLine
    else
      Result := Result + sLineBreak + LLine;
  end;
end;

procedure TAKDynRecord.Clear;
begin
  FItems.Clear;
end;

constructor TAKDynRecord.Create;
begin
  inherited;
  FItems := TDictionary<string, Variant>.Create(TIStringComparer.Ordinal);
  FComments := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  FDateTimeFormatIndex := -1;
  FStrictDateTimeFormat := False;
  FFloatFormatSettings := TFormatSettings.Create;
  FFloatFormatSettings.ThousandSeparator := #0;
end;

destructor TAKDynRecord.Destroy;
begin
  FreeAndNil(FItems);
  FreeAndNil(FComments);
  inherited;
end;

procedure TAKDynRecord.EnumAllFieldNames(const AProc: TAKStringProc);
var
  LName: string;
begin
  Assert(Assigned(AProc));

  for LName in FItems.Keys do
    AProc(LName);
end;

procedure TAKDynRecord.EnumFieldNames(const AProc: TAKStringProc;
  const APredicate: TAKStringPredicate);
var
  LName: string;
begin
  Assert(Assigned(AProc));
  Assert(Assigned(APredicate));

  for LName in FItems.Keys do
    if APredicate(LName) then
      AProc(LName);
end;

function TAKDynRecord.GetBoolean(const AName: string;
  const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
  if HasNotNull(AName) and AKVarIsInteger(Fields[AName]) then
    Result := Fields[AName];
end;

function TAKDynRecord.GetDateTime(const AName: string;
  const ADefault: TDateTime): TDateTime;
begin
  Result := ADefault;
  if HasNotNull(AName) and VarIsType(Fields[AName], varDate) then
    Result := Fields[AName];
end;

function TAKDynRecord.GetDateTimeFormat: string;
begin
  Result := DTFormatToStr(DateTimeFormatSettings, True);
end;

function TAKDynRecord.GetDateTimeFormatSettings: TFormatSettings;
begin
  if FDateTimeFormatIndex > -1 then
    Result := ACCEPTED_DT_FORMATS[FDateTimeFormatIndex]
  else
    Result := DEFAULT_DT_FORMAT;
end;

function TAKDynRecord.GetFieldComment(const AName: string): string;
begin
  if FComments.ContainsKey(AName) then
    Result := FComments[AName];
end;

function TAKDynRecord.GetFieldCount: Integer;
begin
  Result := FItems.Count;
end;

function TAKDynRecord.GetFieldType(const AName: string): string;
begin
  if HasField(AName) then
    Result := AKVarTypeName(FItems[AName]);
end;

function TAKDynRecord.GetFloat(const AName: string;
  const ADefault: Double): Double;
var
  LResult: Double;
begin
  Result := ADefault;
  if HasNotNull(AName) and AKVarIsFloat(Fields[AName], LResult, FloatFormatSettings) then
    Result := LResult;
end;

function TAKDynRecord.GetFormattedComment(const AComment: string; const AIndent: Integer): string;
var
  LLines: TArray<string>;
  I: Integer;
begin
  Result := '';
  LLines := AComment.Split([sLineBreak]);
  for I := Low(LLines) to High(LLines) do
    if Result = '' then
      Result := StringOfChar(' ', AIndent) + '# ' + LLines[I]
    else
      Result := Result + sLineBreak + StringOfChar(' ', AIndent) + '# ' + LLines[I];
end;

function TAKDynRecord.GetInteger(const AName: string;
  const ADefault: Integer): Integer;
begin
  Result := ADefault;
  if HasNotNull(AName) and AKVarIsInteger(Fields[AName]) then
    Result := Fields[AName];
end;

function TAKDynRecord.GetMacroValue(const AMacroName: string): string;
begin
  Result := GetString(AMacroName);
end;

function TAKDynRecord.GetObject(const AName: string; const ADefault: TObject): TObject;
begin
  Result := ADefault;
  if HasNotNull(AName) and VarIsOrdinal(Fields[AName]) then
    Result := TObject(NativeInt(Fields[AName]));
end;

function TAKDynRecord.GetString(const AName, ADefault: string): string;
begin
  Result := ADefault;
  if HasNotNull(AName) then
    if VarIsType(Fields[AName], varDate) then
      Result := FormatDateTime(DateTimeFormat, Fields[AName])
    else if VarIsFloat(Fields[AName]) then
      Result := FloatToStr(Fields[AName], FloatFormatSettings)
    else
      Result := Fields[AName];
end;

function TAKDynRecord.GetValue(const AName: string): Variant;
var
  LName: string;
begin
  Result := Unassigned;
  LName := Trim(AName);
  if HasField(LName) then
    Result := FItems[LName];
end;

function TAKDynRecord.HasField(const AName: string): Boolean;
begin
  Result := FItems.ContainsKey(AName);
end;

function TAKDynRecord.HasNotNull(const AName: string): Boolean;
begin
  Result := HasField(AName) and not VarIsNull(Fields[AName])
    and not VarIsEmpty(Fields[AName]);
end;

procedure TAKDynRecord.LoadFromFile(const AFileName: string;
  const AEncoding: TEncoding);
var
  LList: TStringList;
  LName: string;
  LComment: string;
  LLine: string;
  I: Integer;
  J: Integer;
begin
  if not FileExists(AFileName) then
    raise AKException(EAKNotFoundError, 'File "%s" not found.', [AFileName]);

  Clear;
  LList := TStringList.Create;
  try
    LList.NameValueSeparator := ':';
    LList.LoadFromFile(AFileName, AEncoding);
    for I := 0 to LList.Count - 1 do
    begin
      if Trim(LList[I]) = '' then
        Continue; // Skip empty lines
      if Trim(LList[I])[Low(LList[I])] = '#' then
        Continue; // Skip comments

      LName := LList.Names[I];
      SetValueFromText(LName, LList.ValueFromIndex[I]);
      if HasField(LName) then
      begin
        LComment := '';
        for J := I - 1 downto 0 do
        begin
          LLine := Trim(LList[J]);
          if (LLine = '') or (LLine[Low(LLine)] <> '#') then
            Break;
          if LComment = '' then
            LComment := LLine
          else
            LComment := LLine + sLineBreak + LComment;
        end;
        SetFieldComment(LName, LComment);
      end;
    end;
  finally
    FreeAndNil(LList);
  end;
end;

procedure TAKDynRecord.LoadFromFile(const AFileName: string);
begin
  LoadFromFile(AFileName, TEncoding.UTF8);
end;

procedure TAKDynRecord.LoadFromJSON(const AJSONObject: TJSONObject);
var
  LPair: TJSONPair;
  LValue: TJSONValue;
begin
  Assert(Assigned(AJSONObject));

  Clear;
  for LPair in AJSONObject do
  begin
    LValue := LPair.JsonValue;
    if LValue is TJSONNull then
      Fields[LPair.JsonString.Value] := Null
    else
      SetValueFromText(LPair.JsonString.Value, LPair.JsonValue.AsType<string>);
  end;
end;

procedure TAKDynRecord.LoadFromXML(const AXMLRoot: IXMLNode);
var
  LList: IXMLNodeList;
  I: Integer;

  function IsPureTextNode(const ANode: IXMLNode): Boolean;
  begin
    Result := ANode.ChildNodes.Count = 0;
    if not Result and (ANode.ChildNodes.Count = 1) then
      Result := ANode.ChildNodes[0].ChildNodes.Count = 0;
  end;
begin
  Assert(Assigned(AXMLRoot));

  Clear;
  LList := AXMLRoot.ChildNodes;
  for I := 0 to LList.Count - 1 do
    if IsPureTextNode(LList[I]) then
      SetValueFromText(LList[I].NodeName, LList[I].Text);
end;

procedure TAKDynRecord.Remove(const AName: string);
begin
  FItems.Remove(AName);
end;

procedure TAKDynRecord.SaveToFile(const AFileName: string; const AIncludeComments: Boolean;
  const AEncoding: TEncoding);
begin
  SaveTextToFile(AFileName, AsText(AIncludeComments), AEncoding);
end;

procedure TAKDynRecord.SaveToFile(const AFileName: string; const AIncludeComments: Boolean);
begin
  SaveToFile(AFileName, AIncludeComments, TEncoding.UTF8NoBOM);
end;

procedure TAKDynRecord.SetBoolean(const AName: string; const AValue: Boolean);
begin
  Fields[AName] := AValue;
end;

procedure TAKDynRecord.SetDateTime(const AName: string; const AValue: TDateTime);
begin
  Fields[AName] := AValue;
end;

procedure TAKDynRecord.SetDateTimeFormat(const AValue: string);
begin
  if not IsAcceptedDTFormat(AValue, FDateTimeFormatIndex) then
    raise AKException(EAKFormatError, 'Invalid DateTime format "%s".', [AValue]);
end;

procedure TAKDynRecord.SetFieldComment(const AName, AValue: string);
var
  LValue: string;

  function StripCommentPrefix(const ALine: string): string;
  var
    LLine: string;
    I: Integer;
  begin
    LLine := Trim(ALine);
    for I := Low(LLine) to High(LLine) do
      if LLine[I] <> '#' then
      begin
        Result := Trim(Copy(ALine, I));
        Break;
      end;
  end;
  function StripCommentPrefixes(const ALines: TArray<string>): string;
  var
    I: Integer;
  begin
    for I := Low(ALines) to High(ALines) do
      ALines[I] := StripCommentPrefix(ALines[I]);
    Result := string.Join(sLineBreak, ALines);
  end;
begin
  if Pos(sLineBreak, AValue) > 0 then
    LValue := StripCommentPrefixes(AValue.Split([sLineBreak]))
  else
    LValue := StripCommentPrefix(AValue);

  if FComments.ContainsKey(AName) then
    FComments[AName] := LValue
  else
    FComments.Add(AName, LValue);
end;

procedure TAKDynRecord.SetFloat(const AName: string; const AValue: Double);
begin
  Fields[AName] := AValue;
end;

procedure TAKDynRecord.SetInteger(const AName: string; const AValue: Integer);
begin
  Fields[AName] := AValue;
end;

procedure TAKDynRecord.SetObject(const AName: string; const AValue: TObject);
begin
  Fields[AName] := NativeInt(Pointer(AValue));
end;

procedure TAKDynRecord.SetString(const AName, AValue: string);
begin
  if Trim(AValue) <> '' then
    Fields[AName] := Trim(AValue);
end;

procedure TAKDynRecord.SetValue(const AName: string; const AValue: Variant);
var
  LName: string;
begin
  LName := Trim(AName);
  if LName = '' then
    raise AKException(EAKConfigError, 'Cannot set a record field with an empty name.');
  if HasField(LName) then
    FItems[LName] := AValue
  else
    FItems.Add(LName, AValue);
end;

procedure TAKDynRecord.SetValueFromText(const AName, AText: string);
var
  LFormatIndex: Integer;
  LValue: Variant;
begin
  LFormatIndex := -1;
  if FStrictDateTimeFormat then
  begin
    if FDateTimeFormatIndex = -1 then
      LFormatIndex := DefaultDTFormatIndex
    else
      LFormatIndex := FDateTimeFormatIndex;
  end;
  LValue := AKVarFromString(Trim(AText), FloatFormatSettings, LFormatIndex);
  if not VarIsNull(LValue) then
    Fields[AName] := LValue;
end;

{ TAKDynRecordSet }

procedure TAKDynRecordSet.AddExternalJSON(const AJSON: TJSONObject);
begin
  AppendJSONRecord(AJSON, True);
end;

procedure TAKDynRecordSet.AddExternalXML(const AXML: IXMLNode);
begin
  AppendXMLRecord(AXML, True);
end;

procedure TAKDynRecordSet.AddRecord(const AValues: array of Variant);
var
  LRecord: TAKDynRecord;
  I: Integer;
begin
  CheckSetHeader;
  if Length(AValues) <> FieldCount then
    raise AKException(EAKDataError, 'Invalid data (%d fields for %d headers).',
      [Length(AValues), FieldCount]);
  LRecord := TAKDynRecord.Create;
  try
    for I := 0 to FieldCount - 1 do
      LRecord[FHeader[I]] := AValues[I];
    AppendRecord(LRecord);
  except
    FreeAndNil(LRecord);
    raise;
  end;
end;

procedure TAKDynRecordSet.AddRecord(const AValues: array of string);
var
  LRecord: TAKDynRecord;
  I: Integer;
begin
  CheckSetHeader;
  if Length(AValues) <> FieldCount then
    raise AKException(EAKDataError, 'Invalid data (%d fields for %d headers).',
      [Length(AValues), FieldCount]);
  LRecord := TAKDynRecord.Create;
  try
    for I := 0 to FieldCount - 1 do
      if IsDQuoted(AValues[I]) then
        LRecord.SetString(FHeader[I], DeQuote(AValues[I]))
      else
        LRecord.SetValueFromText(FHeader[I], AValues[I]);
    AppendRecord(LRecord);
  except
    FreeAndNil(LRecord);
    raise;
  end;
end;

procedure TAKDynRecordSet.AddRecord(const ARecord: TAKDynRecord);
begin
  CheckSetHeader;
  AppendRecord(ARecord);
end;

procedure TAKDynRecordSet.AddRecord(const AXML: IXMLNode);
begin
  AppendXMLRecord(AXML, False);
end;

procedure TAKDynRecordSet.AddRecord(const AJSON: TJSONObject);
begin
  AppendJSONRecord(AJSON, False);
end;

procedure TAKDynRecordSet.AppendJSONRecord(const AJSONData: TJSONObject;
  const ACleanIt: Boolean);
var
  LRecord: TAKDynRecord;
begin
  LRecord := TAKDynRecord.Create;
  try
    LRecord.LoadFromJSON(AJSONData);
    if Assigned(BeforeAddJSON) then
      BeforeAddJSON(LRecord);
    CheckSetHeader;
    if ACleanIt then
      LRecord.EnumFieldNames(LRecord.Remove,
        function (const AName: string): Boolean
        begin
          Result := not MatchText(AName, FHeader);
        end);
    AppendRecord(LRecord);
  except
    FreeAndNil(LRecord);
    raise;
  end;
end;

procedure TAKDynRecordSet.AppendXMLRecord(const AXMLData: IXMLNode;
  const ACleanIt: Boolean);
var
  LRecord: TAKDynRecord;
begin
  LRecord := TAKDynRecord.Create;
  try
    LRecord.LoadFromXML(AXMLData);
    if Assigned(BeforeAddXML) then
      BeforeAddXML(LRecord);
    CheckSetHeader;
    if ACleanIt then
      LRecord.EnumFieldNames(LRecord.Remove,
        function (const AName: string): Boolean
        begin
          Result := not MatchText(AName, FHeader);
        end);
    AppendRecord(LRecord);
  except
    FreeAndNil(LRecord);
    raise;
  end;
end;

procedure TAKDynRecordSet.CheckSetHeader;
begin
  if FFieldCount < 1 then
    raise AKException('Header not set.');
end;

constructor TAKDynRecordSet.Create;
begin
  inherited Create;
  FConfig := TAKDynRecord.Create;
  FFieldCount := -1;
  // Most raised errors by record sets are config errors.
  ErrorClass := EAKConfigError;
end;

destructor TAKDynRecordSet.Destroy;
begin
  FreeAndNil(FConfig);
  inherited;
end;

function TAKDynRecordSet.GetHeader(const AIndex: Integer): string;
begin
  Result := FHeader[AIndex];
end;

procedure TAKDynRecordSet.InternalLoadData(const AData: string);
begin
end;

procedure TAKDynRecordSet.InternalSetHeader(const AColumns: array of string);
var
  LFieldCount: Integer;
  I: Integer;
begin
  LFieldCount := Length(AColumns);
  if LFieldCount < 1 then
    raise AKException('Header must have at least one column.');
  Clear;
  FFieldCount := LFieldCount;
  SetLength(FHeader, FFieldCount);
  for I := 0 to FFieldCount - 1 do
  begin
    if AColumns[I] = '' then
      raise AKException('Column names must not be empty.');
    FHeader[I] := AColumns[I];
  end;
end;

procedure TAKDynRecordSet.LoadData(const AData: string);
begin
  Clear;
  InternalLoadData(AData);
end;

procedure TAKDynRecordSet.LoadFromFile(const AFileName: string;
  const AEncoding: TEncoding);
begin
  if not FileExists(AFileName) then
    raise AKException(EAKNotFoundError, 'File "%s" not found.', [AFileName]);

  FFileName := AFileName;
  LoadData(LoadTextFromFile(AFileName, AEncoding));
end;

procedure TAKDynRecordSet.LoadFromFile(const AFileName: string);
begin
  LoadFromFile(AFileName, TEncoding.UTF8);
end;

{ TAKDynRecordCollection }

procedure TAKDynRecordCollection.AppendRecord(const ARecord: TAKDynRecord);
begin
  inherited;
  Inc(FCount);
  SetLength(FRecords, FCount);
  FRecords[FCount - 1] := ARecord;
end;

procedure TAKDynRecordCollection.Clear;
var
  I: Integer;
begin
  inherited;
  for I := 0 to FCount - 1 do
    FreeAndNil(FRecords[I]);
  SetLength(FRecords, 0);
  FCount := 0;
end;

constructor TAKDynRecordCollection.Create;
begin
  inherited Create;
  FCount := 0;
end;

destructor TAKDynRecordCollection.Destroy;
begin
  Clear;
  inherited;
end;

procedure TAKDynRecordCollection.EnumRecords(const AProc: TAKDynRecordProc);
var
  LRecord: TAKDynRecord;
begin
  Assert(Assigned(AProc));

  for LRecord in FRecords do
    AProc(LRecord);
end;

function TAKDynRecordCollection.FindAll(const ANames: array of string;
  const AValues: array of Variant): TAKDynRecords;
var
  LLength: Integer;
  LRecord: TAKDynRecord;
  LTempLength: Integer;
  I: Integer;
begin
  LLength := Length(ANames);
  Assert(LLength = Length(AValues));

  Result := [];
  for LRecord in FRecords do
  begin
    for I := 0 to LLength - 1 do
    begin
      if LRecord[ANames[I]] <> AValues[I] then
        Break;
      if I = LLength - 1 then
      begin
        LTempLength := Length(Result);
        SetLength(Result, LTempLength + 1);
        Result[LTempLength] := LRecord;
      end;
    end;
  end;
end;

function TAKDynRecordCollection.FindFirst(const ANames: array of string;
  const AValues: array of Variant): TAKDynRecord;
var
  LLength: Integer;
  LRecord: TAKDynRecord;
  I: Integer;
begin
  LLength := Length(ANames);
  Assert(LLength = Length(AValues));

  Result := nil;
  for LRecord in FRecords do
  begin
    for I := 0 to LLength - 1 do
    begin
      if LRecord[ANames[I]] <> AValues[I] then
        Break;
      if I = LLength - 1 then
        Exit(LRecord);
    end;
  end;
end;

function TAKDynRecordCollection.GetCount: Integer;
begin
  Result := FCount;
end;

function TAKDynRecordCollection.GetRecord(const AIndex: Integer): TAKDynRecord;
begin
  Result := FRecords[AIndex];
end;

function TAKDynRecordCollection.RecordIndex(const ARecord: TAKDynRecord): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FCount - 1 do
    if FRecords[I] = ARecord then
      Exit(I);
end;

procedure TAKDynRecordCollection.RemoveRecord(const AIndex: Integer);
var
  I: Integer;
begin
  if (AIndex < 0) or (AIndex > FCount - 1) then
    Exit;

  FreeAndNil(FRecords[AIndex]);
  Dec(FCount);
  for I := AIndex downto FCount - 1 do
    FRecords[I] := FRecords[I + 1];
  SetLength(FRecords, FCount);
end;

procedure TAKDynRecordCollection.RemoveRecord(const ARecord: TAKDynRecord);
begin
  RemoveRecord(RecordIndex(ARecord));
end;

procedure TAKDynRecordCollection.SetHeader(const AColumnNames: array of string);
begin
  InternalSetHeader(AColumnNames);
end;

{ TAKDynRecordMap }

procedure TAKDynRecordMap.AppendRecord(const ARecord: TAKDynRecord);
var
  LKeyValue: string;
begin
  inherited;
  LKeyValue := ARecord.GetString(GetKeyFieldName);
  if FRecords.ContainsKey(LKeyValue) then
    raise AKException(EAKDupError, 'A record with key "%s" does already exist.',
      [LKeyValue]);
  FRecords.Add(LKeyValue, ARecord);
end;

procedure TAKDynRecordMap.CheckSetHeader;
begin
  inherited;
  if (FKeyIndex < 0) or (FKeyIndex >= FieldCount) then
    raise AKException('Invalid key index (%d).', [FKeyIndex]);
end;

procedure TAKDynRecordMap.Clear;
begin
  inherited;
  FRecords.Clear;
end;

constructor TAKDynRecordMap.Create;
begin
  inherited Create;
  FKeyIndex := -1;
  FRecords := TObjectDictionary<string, TAKDynRecord>.Create([doOwnsValues]);
end;

destructor TAKDynRecordMap.Destroy;
begin
  FreeAndNil(FRecords);
  inherited;
end;

procedure TAKDynRecordMap.EnumRecords(const AProc: TAKDynRecordProc);
var
  LRecord: TAKDynRecord;
begin
  Assert(Assigned(AProc));

  for LRecord in FRecords.Values do
    AProc(LRecord);
end;

function TAKDynRecordMap.FindAll(const ANames: array of string;
  const AValues: array of Variant): TAKDynRecords;
var
  LLength: Integer;
  LKeyIndex: Integer;
  LRecord: TAKDynRecord;
  LTempLength: Integer;
  I: Integer;
begin
  LLength := Length(ANames);
  Assert(LLength = Length(AValues));

  Result := [];
  LKeyIndex := IndexText(GetKeyFieldName, ANames);
  if LKeyIndex <> -1 then
  begin
    LRecord := FindRecord(AValues[LKeyIndex]);
    if Assigned(LRecord) then
      Result := [LRecord];
    Exit;
  end;
  for LRecord in FRecords.Values do
  begin
    for I := 0 to LLength - 1 do
    begin
      if LRecord[ANames[I]] <> AValues[I] then
        Break;
      if I = LLength - 1 then
      begin
        LTempLength := Length(Result);
        SetLength(Result, LTempLength + 1);
        Result[LTempLength] := LRecord;
      end;
    end;
  end;
end;

function TAKDynRecordMap.FindFirst(const ANames: array of string;
  const AValues: array of Variant): TAKDynRecord;
var
  LLength: Integer;
  LKeyIndex: Integer;
  LRecord: TAKDynRecord;
  I: Integer;
begin
  LLength := Length(ANames);
  Assert(LLength = Length(AValues));

  Result := nil;
  LKeyIndex := IndexText(GetKeyFieldName, ANames);
  if LKeyIndex <> -1 then
    Exit(FindRecord(AValues[LKeyIndex]));
  for LRecord in FRecords.Values do
  begin
    for I := 0 to LLength - 1 do
    begin
      if LRecord[ANames[I]] <> AValues[I] then
        Break;
      if I = LLength - 1 then
        Exit(LRecord);
    end;
  end;
end;

function TAKDynRecordMap.FindRecord(const AKey: string): TAKDynRecord;
begin
  Result := nil;
  if FRecords.ContainsKey(AKey) then
    Result := FRecords[AKey];
end;

function TAKDynRecordMap.GetCount: Integer;
begin
  Result := FRecords.Count;
end;

function TAKDynRecordMap.GetKeyFieldName: string;
begin
  if (FKeyIndex > -1) and (FKeyIndex < FieldCount) then
    Result := Header[FKeyIndex];
end;

function TAKDynRecordMap.GetRecord(const AKey: string): TAKDynRecord;
begin
  Result := FindRecord(AKey);
  if not Assigned(Result) then
    raise AKException(EAKNotFoundError, 'No record found for key "%s".', [AKey]);
end;

function TAKDynRecordMap.RecordKey(const ARecord: TAKDynRecord): string;
var
  LKey: string;
begin
  for LKey in FRecords.Keys do
    if FRecords[LKey] = ARecord then
      Exit(LKey);
end;

procedure TAKDynRecordMap.RemoveRecord(const AKey: string);
begin
  FRecords.Remove(AKey);
end;

procedure TAKDynRecordMap.RemoveRecord(const ARecord: TAKDynRecord);
var
  LKey: string;
begin
  LKey := RecordKey(ARecord);
  if LKey <> '' then
    FRecords.Remove(LKey);
end;

procedure TAKDynRecordMap.SetHeader(const AColumnNames: array of string;
  const AKeyIndex: Integer);
begin
  if (AKeyIndex < 0) or (AKeyIndex >= Length(AColumnNames)) then
    raise AKException('Invalid key index %d (%d).',
      [AKeyIndex, Length(AColumnNames)]);
  FKeyIndex := AKeyIndex;
  InternalSetHeader(AColumnNames);
end;

procedure TAKDynRecordMap.SetHeader(const AColumnNames: array of string;
  const AKeyFieldName: string);
var
  LKeyIndex: Integer;
begin
  LKeyIndex := IndexText(AKeyFieldName, AColumnNames);
  if LKeyIndex = -1 then
    raise AKException('Key field name "%s" not found.',
      [AKeyFieldName]);

  SetHeader(AColumnNames, LKeyIndex);
end;

end.
