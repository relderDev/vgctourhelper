unit AK.Utils;

{$I AK.Defines.inc}

interface

uses
  SysUtils, Classes, RegularExpressions, Xml.XMLIntf,
  AK.Constants, AK.Base;

/// <summary>
///  Returns a 32-character GUID string.
/// </summary>
function CreateCompactGuidStr: string;

/// <summary>
///  Concats each step with trailing path delimiters and expands {App} macros.
/// </summary>
function ConcatPath(const ASingleSteps: array of string): string;

/// <summary>
///  Removes all steps (folders) before the given one (included) from the path.
///  The result does not have the leading path delimiter.
/// </summary>
function SlicePath(const APath, ARemoveUntil: string): string;

/// <summary>
///  Replaces each instance of CRLF and LF with the given break in a string.
/// </summary>
function FormatLineBreaks(const AText: string; const ALineBreak: string = sLineBreak): string;

/// <summary>
///  Adds the given number of indent characters before each line in a string.
/// </summary>
/// <remarks>
///  Only CRLF instances and single LF instances are considered line breaks.
/// </remarks>
function IndentLines(const AText: string; const AIndent: Integer;
  const AIndentChar: Char = ' '): string;

/// <summary>
///  Tries to convert the given string to a TDateTime, checking all accepted
///  formats in their order. DEFAULT_DT_FORMAT is always checked first.
/// </summary>
function IsDateTimeString(const AValue: string; out AResult: TDateTime): Boolean;

/// <summary>
///  Tries to convert the given string to a floating point value, checking all
///  listed decimal separators in their order.
/// </summary>
/// <remarks>
///  ACCEPTED_FLOAT_THOUSAND_SEPARATOR is the only accepted thousand separator
///  (which should be #0 - no thousand separator at all).
/// </remarks>
function IsFloatString(const AValue: string; out AResult: Double): Boolean;

/// <summary>
///  Casts a string as a char. Returns #0 for empty strings and raises an error
///  if the given string has more than one character.
/// </summary>
function AsChar(const AString: string): Char;

/// <summary>
///  Checks if the given string represents a URL.
/// </summary>
function IsUrl(const AString: string; const AStrict: Boolean = False): Boolean;

/// <summary>
///  Returns whether or not the string is enclosed in the given character.
/// </summary>
function IsEnclosed(const AString: string; const AEnclosure: Char): Boolean;

/// <summary>
///  Returns whether or not the string is enclosed in single quotes.
/// </summary>
function IsQuoted(const AString: string): Boolean;

/// <summary>
///  Returns whether or not the string is enclosed in double quotes.
/// </summary>
function IsDQuoted(const AString: string): Boolean;

/// <summary>
///  Removes the first and the last character of the string.
/// </summary>
function DeQuote(const AString: string): string;

/// <summary>
///  Removes the given prefix from the given string, case insensitive.
/// </summary>
function StripPrefix(const AString, APrefix: string): string;

/// <summary>
///  Removes the given suffix from the given string, case insensitive.
/// </summary>
function StripSuffix(const AString, ASuffix: string): string;

/// <summary>
///  Removes the given prefix and suffix from the given string (in this order),
///  case insensitive.
/// </summary>
function StripPrefixAndSuffix(const AString, APrefix, ASuffix: string): string;

/// <summary>
///  Performs StripPrefix on each given prefix, in the order in which they
///  appear in the given array.
/// </summary>
function StripPrefixes(const AString: string; const APrefixes: array of string): string;

/// <summary>
///  Performs StripSuffix on each given suffix, in the order in which they
///  appear in the given array.
/// </summary>
function StripSuffixes(const AString: string; const ASuffixes: array of string): string;

/// <summary>
///  Performs StripPrefixAndSuffix on each valid entry of the given arrays. If
///  the arrays differ in length, the function that is called on the "remaining"
///  entries is chosen accordingly.
/// </summary>
function StripPrefixesAndSuffixes(const AString: string; const APrefixes, ASuffixes: array of string): string;

/// <summary>
///  Performs a string replace with each couple of AFrom and ATo.
/// </summary>
/// <remarks>
///  Raises an error if the sizes of AFrom and ATo do not match.
/// </remarks>
procedure ChainReplace(var AStr: string; const AFrom, ATo: array of string;
  const ACaseSensitive: Boolean = False);

/// <summary>
///  Replaces all the instances of AFrom from the given string and replaces them
///  with ATo, indented in the same way as AFrom was.
/// </summary>
/// <remarks>
///  In order to extract AFrom's indent only line feeds are accounted.
/// </remarks>
function ReplaceAndIndent(const AString, AFrom, ATo: string;
  const ACaseSensitive: Boolean = False; const AIndentChar: Char = ' '): string;

/// <summary>Adds a '/' at the end of the string when not already present.</summary>
function IncludeTrailingSlash(const AString: string): string;

/// <summary>
///  Encodes a string by replacing all unsafe URL characters with the respective
///  %NN value, accounting for the presence/absence of query and fragment parts.
/// </summary>
/// <remarks>
///  Spaces are never encoded with "+" and always encoded with "%20".
/// </remarks>
function EncodeURLPath(const AString: string; const AHasQuery: Boolean = False;
  const AHasFragment: Boolean = False): string;

/// <summary>
///  Adds the specified path under the given URL while mantaining query string
///  and fragment on the new URL.
/// </summary>
function GetUrlSubPath(const AOriginalUrl, ASubPath: string): string;

/// <summary>
///  Adds the specified folder under the given URL while mantaining query string
///  and fragment on the new URL. It's the same as GetUrlSubPath but places a
///  trailing slash in the URL after the given sub folder (before the query).
/// </summary>
function GetUrlSubFolder(const AOriginalUrl, ASubFolder: string): string;

/// <summary>
///  Checks if a variant can be converted to Integer.
/// </summary>
function AKVarIsInteger(const AValue: Variant): Boolean;

/// <summary>
///  Checks if a variant can be converted to Float.
/// </summary>
function AKVarIsFloat(const AValue: Variant; out AResult: Double;
  const AFormat: TFormatSettings): Boolean;

/// <summary>
///  Casts a string value to the appropriate Variant.
/// </summary>
function AKVarFromString(const AValue: string; const AFloatFormat: TFormatSettings;
  const AStrictDTFormatIndex: Integer): Variant; overload;

/// <summary>
///  Casts a string value to the appropriate Variant.
/// </summary>
function AKVarFromString(const AValue: string): Variant; overload;

/// <summary>
///  Casts a variant as string formatting it.
/// </summary>
function AKVarToString(const AValue: Variant; const AFloatFormat: TFormatSettings): string; overload;

/// <summary>
///  Casts a variant as string formatting it.
/// </summary>
function AKVarToString(const AValue: Variant): string; overload;

/// <summary>
///  Returns the name of the variant recognized type.
/// </summary>
function AKVarTypeName(const AValue: Variant): string;

/// <summary>
///  Creates a directory if it does not exist.
/// </summary>
procedure CreateDirectory(const APath: string);

/// <summary>
///  Deletes a directory recursively.
/// </summary>
procedure DeleteDirectory(const APath: string);

/// <summary>
///  Writes text on a file. Creates file directory if it doesn't exist.
/// </summary>
procedure SaveTextToFile(const AFileName, AContent: string; const AEncoding: TEncoding); overload;

/// <summary>
///  Writes text on a file (UTF-8). Creates file directory if it doesn't exist.
/// </summary>
procedure SaveTextToFile(const AFileName, AContent: string); overload;

/// <summary>
///  Writes stream on a file. Creates file directory if it doesn't exist.
/// </summary>
procedure SaveStreamToFile(const AFileName: string; const AStream: TCustomMemoryStream);

/// <summary>
///  Appends text on a file. Creates file (and file directory) if it doesn't
///  exist.
/// </summary>
procedure AppendTextToFile(const AFileName, AContent: string; const AEncoding: TEncoding); overload;

/// <summary>
///  Appends text on a file (UTF-8). Creates file (and file directory) if it
///  doesn't exist.
/// </summary>
procedure AppendTextToFile(const AFileName, AContent: string); overload;

/// <summary>
///  Reads the text from a file.
/// </summary>
function LoadTextFromFile(const AFileName: string; const AEncoding: TEncoding): string; overload;

/// <summary>
///  Reads the text from a file (UTF-8).
/// </summary>
function LoadTextFromFile(const AFileName: string): string; overload;

/// <summary>
///  Creates, uses and deletes a temporary text file.
/// </summary>
procedure TempTextFile(const AContent: string; const AProc: TAKStringProc;
  const AExt: string = '.txt');

/// <summary>
///  Iterates on any file in the given path that matches the wildcard, calling
///  AFileNameProc on its name. If ARecursive is true it scans subfolders.
/// </summary>
procedure ScanFolder(const APath: string; const AFileNameProc: TAKStringProc;
  const AWildCard: string = '*'; const ARecursive: Boolean = False); overload;

/// <summary>
///  Iterates on any file in the given path that matches the wildcard, calling
///  AFileProc on the TSearchRec representing it. If ARecursive is true it scans
///  subfolders.
/// </summary>
procedure ScanFolder(const APath: string; const AFileProc: TAKFileProc;
  const AWildCard: string = '*'; const ARecursive: Boolean = False); overload;

/// <summary>
///  Escapes all special characters of the given string.
/// </summary>
function EscapeJSONString(const AString: string): string;

/// <summary>
///  Returns whether or not the node has a child node named as the given name.
/// </summary>
function XMLNodeHasChild(const ANode: IXMLNode; const AName: string): Boolean;

/// <summary>
///  Returns the first child node, if any, otherwise returns nil.
/// </summary>
function XMLNodeFirstChild(const ANode: IXMLNode): IXMLNode;

/// <summary>
///  Returns the last child node, if any, otherwise returns nil.
/// </summary>
function XMLNodeLastChild(const ANode: IXMLNode): IXMLNode;

/// <summary>
///  Creates a list of appropriated HTML nodes to include the given files onto
///  a HTML document, separated by line breaks. When AIncludePath is not empty
///  it replaces the pre-existing directory path of each included file with it.
///  Files with unsupported extensions are skipped.
/// </summary>
/// <remarks>
///  Currently supports only .js and .css files.
/// </remarks>
function HTMLInclude(const AIncludeFiles: array of string; const AIncludePath: string = ''): string;

type
  /// <summary>
  ///  Helper record for handling name and values of enum types. Works for enum
  ///  defined as [prefix][ValueName], where prefix is written in lowercase.
  /// </summary>
  TAKEnum<T> = record
  strict private
    class function GetPrefixCount(const AFullName: string): Integer; static;
  public
    class function Name(const AValue: T): string; static;
    class function Value(const AName: string): T; static;
  end;

  TAKMatchReplaceFunction = reference to function (const AMatch, AInput: string; const AIndex: Integer): string;

  /// <summary>
  ///  Helper record for handling more complex replace regex without having to
  ///  define objects only to do so. The given replace function not only does
  ///  receive the matching value but also the original input string and the
  ///  index of the position at which the match occurres (TMatch.Index refers to
  ///  the string that is being modified, thus, for each replace action after
  ///  the first one, it most likely cannot be used on the original string).
  /// </summary>
  TAKRegex = record
  strict private
    FRegex: TRegEx;
    FReplaceFunc: TAKMatchReplaceFunction;
    FInput: string;
    FIncrement: Integer;
    function ReplaceMatch(const AMatch: TMatch): string;
  public
    function Replace(const AInput: string): string;
    constructor Create(const APattern: string; const AReplaceFunc: TAKMatchReplaceFunction;
      const AOptions: TRegExOptions = [roNotEmpty]);
  end;

  /// <summary>
  ///  Helper record for handling complex macro substitutions. It uses TAKRegex
  ///  and passes the match value stripped of the macro brackets. When argument
  ///  APreserveSpaceIndent is True each multi-lined result of a replace is
  ///  indented the same way as the macro was (space-indentation only).
  /// </summary>
  TAKMacroReplacer = record
  strict private
    FRegex: TAKRegex;
    const BACKSLASH_PLACEHOLDER = '{BACKSLASH}';
  public
    function Replace(const AInput: string): string;
    constructor Create(const AOpen, AClose: string; const AReplaceFunc: TAKMatchReplaceFunction;
      const APreserveSpaceIndent: Boolean = False; const ACaseSensitive: Boolean = True);
  end;

implementation

uses
  StrUtils, Variants, IOUtils, Rtti, TypInfo, NetEncoding;

function CreateCompactGuidStr: string;
var
  I: Integer;
  LBuffer: array[0..15] of Byte;
begin
  CreateGUID(TGUID(LBuffer));
  Result := '';
  for I := 0 to 15 do
    Result := Result + IntToHex(LBuffer[I], 2);
end;

function ConcatPath(const ASingleSteps: array of string): string;
var
  LStep: string;
begin
  for LStep in ASingleSteps do
    Result := Result + IncludeTrailingPathDelimiter(LStep);
  Result := ReplaceText(Result, '{App}', AppPath);
end;

function SlicePath(const APath, ARemoveUntil: string): string;
var
  LRemoveUntil: string;
  LPosition: Integer;
begin
  Result := '';
  LRemoveUntil := IncludeTrailingPathDelimiter(ARemoveUntil);
  {$IFDEF MSWINDOWS}
  LPosition := Pos(UpperCase(LRemoveUntil), UpperCase(APath));
  {$ELSE}
  LPosition := Pos(LRemoveUntil, APath);
  {$ENDIF}
  if LPosition = 1 then
    Result := Copy(APath, Length(LRemoveUntil) + Low(string));
end;

function FormatLineBreaks(const AText, ALineBreak: string): string;
begin
  Result := ReplaceStr(AText, #013, '');
  Result := ReplaceStr(Result, #010, ALineBreak);
end;

function IndentLines(const AText: string; const AIndent: Integer;
  const AIndentChar: Char): string;
var
  LIndent: string;
begin
  if AIndent < 1 then
    Exit(AText);
  LIndent := StringOfChar(AIndentChar, AIndent);
  Result := ReplaceStr(AText, #013, '');
  Result := LIndent + string.Join(sLineBreak + LIndent, Result.Split([#010]));
end;

function IsDateTimeString(const AValue: string; out AResult: TDateTime): Boolean;
var
  LFormat: TFormatSettings;
begin
  Result := False;
  if TryStrToDateTime(AValue, AResult, DEFAULT_DT_FORMAT) then
    Exit(True);
  for LFormat in ACCEPTED_DT_FORMATS do
    if TryStrToDateTime(AValue, AResult, LFormat) then
      Exit(True);
end;

function IsFloatString(const AValue: string; out AResult: Double): Boolean;
var
  LFormat: TFormatSettings;
  LChar: Char;
begin
  Result := False;
  LFormat := TFormatSettings.Create;
  LFormat.ThousandSeparator := ACCEPTED_FLOAT_THOUSAND_SEPARATOR;
  for LChar in ACCEPTED_FLOAT_DECIMAL_SEPARATORS do
  begin
    LFormat.DecimalSeparator := LChar;
    if TryStrToFloat(AValue, AResult, LFormat) then
      Exit(True);
  end;
end;

function AsChar(const AString: string): Char;
var
  LLength: Integer;
begin
  LLength := Length(AString);
  case LLength of
    0: Result := #0;
    1: Result := AString[Low(AString)];
    else raise EAKError<Char>.CreateFmt('"%s" cannot be casted as Char.', [AString]);
  end;
end;

function IsUrl(const AString: string; const AStrict: Boolean): Boolean;
var
  LRegex: TRegEx;
begin
  if AString.StartsWith('http://localhost/') then
    Exit(True);
  if AStrict then
    LRegex := TRegEx.Create(URL_REGEX_STRICT)
  else
    LRegex := TRegEx.Create(URL_REGEX);
  Result := LRegex.Match(AString).Value = Trim(AString);
end;

function IsEnclosed(const AString: string; const AEnclosure: Char): Boolean;
begin
  if AString = '' then
    Exit(False);
  if Length(AString) < 2 then
    Exit(False);

  Result := (AString[Low(AString)] = AEnclosure) and (AString[High(AString)] = AEnclosure);
end;

function IsQuoted(const AString: string): Boolean;
begin
  Result := IsEnclosed(AString, '''');
end;

function IsDQuoted(const AString: string): Boolean;
begin
  Result := IsEnclosed(AString, '"');
end;

function DeQuote(const AString: string): string;
begin
  Result := Copy(AString, Low(AString) + 1, Length(AString) - 2);
end;

function StripPrefix(const AString, APrefix: string): string;
begin
  Result := AString;
  if string.StartsText(APrefix, Result) then
    Result := Copy(Result, Low(Result) + Length(APrefix));
end;

function StripSuffix(const AString, ASuffix: string): string;
begin
  Result := AString;
  if string.EndsText(ASuffix, Result) then
    SetLength(Result, Length(Result) - Length(ASuffix));
end;

function StripPrefixAndSuffix(const AString, APrefix, ASuffix: string): string;
begin
  Result := StripSuffix(StripPrefix(AString, APrefix), ASuffix);
end;

function StripPrefixes(const AString: string; const APrefixes: array of string): string;
var
  I: Integer;
begin
  Result := AString;
  for I := Low(APrefixes) to High(APrefixes) do
    Result := StripPrefix(Result, APrefixes[I]);
end;

function StripSuffixes(const AString: string; const ASuffixes: array of string): string;
var
  I: Integer;
begin
  Result := AString;
  for I := Low(ASuffixes) to High(ASuffixes) do
    Result := StripSuffix(Result, ASuffixes[I]);
end;

function StripPrefixesAndSuffixes(const AString: string; const APrefixes,
  ASuffixes: array of string): string;
var
  LPrefixesLen: Integer;
  LSuffixesLen: Integer;
  I: Integer;
begin
  Result := AString;
  LPrefixesLen := Length(APrefixes);
  LSuffixesLen := Length(ASuffixes);
  if LPrefixesLen > LSuffixesLen then
  begin
    for I := 0 to LSuffixesLen - 1 do
      Result := StripPrefixAndSuffix(Result, APrefixes[I], ASuffixes[I]);
    for I := LSuffixesLen to LPrefixesLen do
      Result := StripPrefix(Result, APrefixes[I]);
  end
  else if LPrefixesLen < LSuffixesLen then
  begin
    for I := 0 to LPrefixesLen - 1 do
      Result := StripPrefixAndSuffix(Result, APrefixes[I], ASuffixes[I]);
    for I := LPrefixesLen to LSuffixesLen - 1 do
      Result := StripSuffix(Result, ASuffixes[I]);
  end
  else
    for I := 0 to LSuffixesLen - 1 do
      Result := StripPrefixAndSuffix(Result, APrefixes[I], ASuffixes[I]);
end;

procedure ChainReplace(var AStr: string; const AFrom, ATo: array of string;
  const ACaseSensitive: Boolean = False);
var
  I: Integer;
begin
  Assert(Length(AFrom) = Length(ATo));

  if ACaseSensitive then
    for I := Low(AFrom) to High(AFrom) do
      AStr := ReplaceStr(AStr, AFrom[I], ATo[I])
  else
    for I := Low(AFrom) to High(AFrom) do
      AStr := ReplaceText(AStr, AFrom[I], ATo[I]);
end;

function ReplaceAndIndent(const AString, AFrom, ATo: string;
  const ACaseSensitive: Boolean; const AIndentChar: Char): string;
var
  LOptions: TRegExOptions;
  LRegex: TAKRegex;
begin
  if ACaseSensitive then
    LOptions := [roNotEmpty]
  else
    LOptions := [roNotEmpty, roIgnoreCase];

  LRegex := TAKRegex.Create(AFrom, function (const AMatch, AInput: string; const AIndex: Integer): string
    var
      LIndent: Integer;
      LIndex: Integer;
      I: Integer;
    begin
      Result := ATo;
      // One liners do not need to be indented, they already are when replaced.
      if not Result.Contains(#010) then
        Exit;
      // Take the first character before the match (if any).
      LIndex := AIndex - 1;
      if LIndex < Low(AInput) then
        Exit;
      // If only space characters are found between the match and the previous
      // line break (or the start of the string) count them, otherwise exit.
      LIndent := 0;
      for I := LIndex downto Low(AInput) do
      begin
        if AInput[I] = AIndentChar then
          Inc(LIndent)
        else if AInput[I] = #010 then
          Break
        else
          Exit;
      end;
      // Indent lines and remove the extra indent added on the first line.
      Result := Copy(IndentLines(Result, LIndent, AIndentChar), LIndent + Low(Result));
    end, LOptions);

  Result := LRegex.Replace(AString);
end;

function IncludeTrailingSlash(const AString: string): string;
begin
  if AString[High(AString)] <> '/' then
    Result := AString + '/'
  else
    Result := AString;
end;

function EncodeURLPath(const AString: string; const AHasQuery, AHasFragment: Boolean): string;
var
  LUnsafe: set of Byte;
begin
  if AHasQuery and AHasFragment then
    LUnsafe := URL_PATH_UNSAFE_CHARS
  else if AHasQuery then
    LUnsafe := URL_PATH_UNSAFE_CHARS + [Ord('#')]
  else if AHasFragment then
    LUnsafe := URL_PATH_UNSAFE_CHARS + URL_QUERY_RESERVED_CHARS
  else
    LUnsafe := URL_PATH_UNSAFE_CHARS + URL_QUERY_RESERVED_CHARS + [Ord('#')];

  Result := TNetEncoding.URL.Encode(AString, LUnsafe,
    [TURLEncoding.TEncodeOption.EncodePercent]);    
end;

function GetUrlSubPath(const AOriginalUrl, ASubPath: string): string;
var
  LSubFolder: string;
  LSeparator: Char;
  LParts: TArray<string>;
begin
  LSubFolder := EncodeUrlPath(ASubPath);

  if Pos('?', AOriginalUrl) > 0 then
    LSeparator := '?'
  else if Pos('#', AOriginalUrl) > 0 then
    LSeparator := '#'
  else
    Exit(IncludeTrailingSlash(AOriginalUrl) + LSubFolder);
    
  LParts := AOriginalUrl.Split([LSeparator]);  
  if Length(LParts) <> 2 then
    raise EAKError<string>.CreateFmt('Invalid URL "%s".', [AOriginalUrl]);  

  Result := LParts[0] + LSubFolder + LSeparator + LParts[1];
end;

function GetUrlSubFolder(const AOriginalUrl, ASubFolder: string): string;
begin
  Result := GetUrlSubPath(AOriginalUrl, IncludeTrailingSlash(ASubFolder));
end;

function AKVarIsInteger(const AValue: Variant): Boolean;
var
  LThrow: Integer;
begin
  Result := VarIsOrdinal(AValue);
  if not Result then
  begin
    if VarIsStr(AValue) then
      Result := TryStrToInt(AValue, LThrow)
    else if VarIsFloat(AValue) then
      Result := Frac(AValue) = 0.0
  end;
end;

function AKVarIsFloat(const AValue: Variant; out AResult: Double;
  const AFormat: TFormatSettings): Boolean;
begin
  Result := VarIsFloat(AValue) or VarIsOrdinal(AValue);
  if not Result and VarIsStr(AValue) then
  begin
    if AFormat.ThousandSeparator = ACCEPTED_FLOAT_THOUSAND_SEPARATOR then
      Result := IsFloatString(AValue, AResult)
    else
      Result := TryStrToFloat(AValue, AResult, AFormat);
  end;
end;

function AKVarFromString(const AValue: string; const AFloatFormat: TFormatSettings;
  const AStrictDTFormatIndex: Integer): Variant;
var
  LFloat: Double;
  LDateTime: TDateTime;
begin
  if AValue = '' then
    Result := Null
  else if MatchText(AValue, ['True', 'False']) then
    Result := StrToBool(AValue)
  else if AKVarIsInteger(AValue) then
    Result := StrToInt(AValue)
  else if AKVarIsFloat(AValue, LFloat, AFloatFormat) then
    Result := LFloat
  else if (AStrictDTFormatIndex = -1) and IsDateTimeString(AValue, LDateTime) then
    Result := LDateTime
  else if TryStrToDateTime(AValue, LDateTime, ACCEPTED_DT_FORMATS[AStrictDTFormatIndex]) then
    Result := LDateTime
  else
    Result := AValue;
end;

function AKVarFromString(const AValue: string): Variant;
var
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Create;
  LFormat.ThousandSeparator := #0;
  Result := AKVarFromString(AValue, LFormat, -1);
end;

function AKVarToString(const AValue: Variant; const AFloatFormat: TFormatSettings): string;
begin
  if VarIsNull(AValue) or VarIsEmpty(AValue) then
    Exit('');

  if VarIsType(AValue, varDate) then
    Result := FormatDateTime(DTFormatToStr(DEFAULT_DT_FORMAT, True), AValue)
  else if VarIsFloat(AValue) then
    Result := FloatToStr(AValue, AFloatFormat)
  else
    Result := AValue;
end;

function AKVarToString(const AValue: Variant): string;
var
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Create;
  LFormat.ThousandSeparator := #0;
  Result := AKVarToString(AValue, LFormat);
end;

function AKVarTypeName(const AValue: Variant): string;
begin
  if VarIsType(AValue, varBoolean) then
    Result := 'Boolean'
  else if VarIsOrdinal(AValue) then
    Result := 'Integer'
  else if VarIsType(AValue, varDate) then
    Result := 'DateTime'
  else if VarIsFloat(AValue) then
    Result := 'Float'
  else if VarIsStr(AValue) then
    Result := 'String'
  else
    Result := VarTypeAsText(VarType(AValue));
 // Result := StringReplace(GetEnumName(TypeInfo(TVarType), VarType(LItem)),
 //   'var', '', []);
end;

procedure CreateDirectory(const APath: string);
begin
  if not DirectoryExists(APath, False) then
    TDirectory.CreateDirectory(APath);
end;

procedure DeleteDirectory(const APath: string);
begin
  if DirectoryExists(APath, False) then
    TDirectory.Delete(APath, True);
end;

procedure SaveTextToFile(const AFileName, AContent: string; const AEncoding: TEncoding);
begin
  CreateDirectory(ExtractFileDir(AFileName));
  TFile.WriteAllText(AFileName, AContent, AEncoding);
end;

procedure SaveTextToFile(const AFileName, AContent: string);
begin
  SaveTextToFile(AFileName, AContent, TEncoding.UTF8NoBOM);
end;

procedure SaveStreamToFile(const AFileName: string; const AStream: TCustomMemoryStream);
begin
  Assert(Assigned(AStream));

  CreateDirectory(ExtractFileDir(AFileName));
  AStream.SaveToFile(AFileName);
end;

procedure AppendTextToFile(const AFileName, AContent: string; const AEncoding: TEncoding);
begin
  if not FileExists(AFileName) then
    SaveTextToFile(AFileName, AContent, AEncoding)
  else
    TFile.AppendAllText(AFileName, AContent, AEncoding);
end;

procedure AppendTextToFile(const AFileName, AContent: string);
begin
  AppendTextToFile(AFileName, AContent, TEncoding.UTF8NoBOM);
end;

function LoadTextFromFile(const AFileName: string; const AEncoding: TEncoding): string;
begin
  Result := TFile.ReadAllText(AFileName, AEncoding);
end;

function LoadTextFromFile(const AFileName: string): string;
begin
  Result := TFile.ReadAllText(AFileName, TEncoding.UTF8);
end;

procedure TempTextFile(const AContent: string; const AProc: TAKStringProc;
  const AExt: string);
var
  LFileName: string;
begin
  Assert(Assigned(AProc));

  LFileName := AppPath + 'tmp_' + CreateCompactGuidStr + AExt;
  SaveTextToFile(LFileName, AContent);
  try
    AProc(LFileName);
  finally
    DeleteFile(LFileName);
  end;
end;

function EscapeJSONString(const AString: string): string;
begin
  Result := AString;
  ChainReplace(Result, ['\', '"', #013, #010, #009, '/'],
    ['\\', '\"', '\r', '\n', '\t', '\/'], True);
end;

procedure ScanFolder(const APath: string; const AFileNameProc: TAKStringProc;
  const AWildCard: string; const ARecursive: Boolean);
begin
  Assert(Assigned(AFileNameProc));

  ScanFolder(APath, procedure (const AFilePath: string; const AFile: TSearchRec)
    begin
      AFileNameProc(AFilePath + AFile.Name);
    end, AWildCard, ARecursive);
end;

procedure ScanFolder(const APath: string; const AFileProc: TAKFileProc;
  const AWildCard: string; const ARecursive: Boolean);
var
  LFolderName: string;
  LSearch: TSearchRec;
  LResult: Integer;
begin
  Assert(Assigned(AFileProc));

  LFolderName := IncludeTrailingPathDelimiter(APath);
  LResult := FindFirst(LFolderName + AWildCard, faAnyFile, LSearch);
  while LResult = 0 do
  begin
    if (LSearch.Attr and faDirectory <> 0) then
    begin
      if ARecursive and not MatchText(LSearch.Name, ['.', '..']) then
        ScanFolder(LFolderName + LSearch.Name, AFileProc, AWildCard, True)
      else
        LResult := FindNext(LSearch);
    end
    else
    begin
      AFileProc(LFolderName, LSearch);
      LResult := FindNext(LSearch);
    end;
  end;
  FindClose(LSearch);
end;

function XMLNodeHasChild(const ANode: IXMLNode; const AName: string): Boolean;
var
  I: Integer;
begin
  Assert(Assigned(ANode));

  Result := False;
  if not ANode.HasChildNodes then
    Exit;

  for I := 0 to ANode.ChildNodes.Count - 1 do
    if ANode.ChildNodes[I].NodeName = AName then
      Exit(True);
end;

function XMLNodeFirstChild(const ANode: IXMLNode): IXMLNode;
begin
  Assert(Assigned(ANode));

  Result := nil;
  if ANode.ChildNodes.Count > 0 then
    Result := ANode.ChildNodes[0];
end;

function XMLNodeLastChild(const ANode: IXMLNode): IXMLNode;
begin
  Assert(Assigned(ANode));

  Result := nil;
  if ANode.ChildNodes.Count > 0 then
    Result := ANode.ChildNodes[ANode.ChildNodes.Count - 1];
end;

function HTMLInclude(const AIncludeFiles: array of string; const AIncludePath: string): string;
const
  JS_TEMPLATE = '<script type="text/javascript" src="%s"></script>';
  CSS_TEMPLATE = '<link rel="stylesheet" href="%s">';
var
  LItem: string;
  LExt: string;
  LTemplate: string;
  I: Integer;
begin
  Result := '';
  for I := 0 to High(AIncludeFiles) do
  begin
    LItem := ReplaceStr(Trim(AIncludeFiles[I]), '"', '\"');
    LExt := ExtractFileExt(LItem);
    if SameText(LExt, '.css') then
      LTemplate := CSS_TEMPLATE
    else if SameText(LExt, '.js') then
      LTemplate := JS_TEMPLATE
    else
      Continue;
    if AIncludePath <> '' then
      LItem := AIncludePath + ExtractFileName(LItem);

    if Result = '' then
      Result := Format(LTemplate, [LItem])
    else
      Result := Result + sLineBreak + Format(LTemplate, [LItem]);
  end;
end;

{ TAKEnum<T> }

class function TAKEnum<T>.GetPrefixCount(const AFullName: string): Integer;
var
  LChar: Char;
begin
  Result := 0;
  for LChar in AFullName do
    if LChar = UpCase(LChar) then
      Break
    else
      Inc(Result);
end;

class function TAKEnum<T>.Name(const AValue: T): string;
var
  LType: PTypeInfo;
begin
  LType := TypeInfo(T);
  if LType^.Kind <> tkEnumeration then
    raise EAKError<TAKEnum<T>>.CreateFmt('Invalid enum type (%s).', [LType^.Name]);

  Result := TRttiEnumerationType.GetName<T>(AValue);
  Result := Copy(Result, Low(Result) + GetPrefixCount(Result));
end;

class function TAKEnum<T>.Value(const AName: string): T;
var
  LType: PTypeInfo;
  LFirstValue: Integer;
  LResult: Integer;
  LFirstName: string;
  LPrefix: string;
begin
  LType := TypeInfo(T);
  if LType^.Kind <> tkEnumeration then
    raise EAKError<TAKEnum<T>>.CreateFmt('Invalid enum type (%s).', [LType^.Name]);

  LFirstValue := GetTypeData(LType)^.MinValue;
  LFirstName := GetEnumName(LType, LFirstValue);
  LPrefix := Copy(LFirstName, Low(LFirstName), GetPrefixCount(LFirstName));
  LResult := GetEnumValue(LType, LPrefix + AName);
  if LResult < LFirstValue then
    raise EAKError<T>.CreateFmt('Value "%s" not found for enum type %s.',
      [LPrefix + AName, LType^.Name]);

  Result := TRttiEnumerationType.GetValue<T>(LPrefix + AName);
end;

{ TAKRegex }

constructor TAKRegex.Create(const APattern: string;
  const AReplaceFunc: TAKMatchReplaceFunction; const AOptions: TRegExOptions);
begin
  Assert(Assigned(AReplaceFunc));

  FRegex := TRegEx.Create(APattern, AOptions);
  FReplaceFunc := AReplaceFunc;
  FIncrement := 0;
end;

function TAKRegex.Replace(const AInput: string): string;
begin
  FIncrement := 0;
  FInput := AInput;
  Result := FRegex.Replace(AInput, ReplaceMatch);
  FInput := '';
  FIncrement := 0;
end;

function TAKRegex.ReplaceMatch(const AMatch: TMatch): string;
begin
  Result := FReplaceFunc(AMatch.Value, FInput, AMatch.Index - FIncrement);
  Inc(FIncrement, Length(Result) - Length(AMatch.Value));
end;

{ TAKMacroRegex }

constructor TAKMacroReplacer.Create(const AOpen, AClose: string;
  const AReplaceFunc: TAKMatchReplaceFunction;
  const APreserveSpaceIndent, ACaseSensitive: Boolean);
var
  LOptions: TRegExOptions;
begin
  Assert(Assigned(AReplaceFunc));

  if not ACaseSensitive then
    LOptions := [roNotEmpty, roIgnoreCase]
  else
    LOptions := [roNotEmpty];
  FRegex := TAKRegex.Create(BracketRegexText(AOpen, AClose),
    function (const AMatch, AInput: string; const AIndex: Integer): string
    var
      LClean: string;
      LIndex: Integer;
      LIndent: Integer;
      I: Integer;
    begin
      // Remove open and close macro brackets from the match.
      LClean := ReplaceText(AMatch, AOpen, '');
      if AClose <> '' then
        LClean := ReplaceText(LClean, AClose, '');

      // Apply the given replace function on the clean value.
      Result := AReplaceFunc(LClean, AInput, AIndex);

      // If the result is empty never restore the macro.
      if Result = '' then
        Exit;

      // If the replace function does nothing restore the macro.
      if Result = LClean then
        Exit(AMatch);

      // Avoid involuntarily escaping the next macro.
      if Result.Contains('\') then
        Result := ReplaceStr(Result, '\', BACKSLASH_PLACEHOLDER);

      // If space indentation has not to be preserved the replacing is done.
      if (not APreserveSpaceIndent) or (not Result.Contains(#010)) then
        Exit;

      // Take the first character before the match (if any).
      LIndex := AIndex - 1;
      if LIndex < Low(AInput) then
        Exit;
      // If only space characters are found between the match and the previous
      // line break (or the start of the string) count them, otherwise exit.
      LIndent := 0;
      for I := LIndex downto Low(AInput) do
      begin
        if AInput[I] = ' ' then
          Inc(LIndent)
        else if AInput[I] = #010 then
          Break
        else
          Exit;
      end;
      // Indent lines and remove the extra indent added on the first line.
      Result := Copy(IndentLines(Result, LIndent, ' '), LIndent + Low(Result));
    end, LOptions);
end;

function TAKMacroReplacer.Replace(const AInput: string): string;
begin
  // Replace and then restore backslashes.
  Result := ReplaceStr(FRegex.Replace(AInput), BACKSLASH_PLACEHOLDER, '\');
end;

end.
