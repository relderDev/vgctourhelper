unit AK.Constants;

{$I AK.Defines.inc}

interface

uses
  SysUtils;

const
  URL_REGEX = '(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)';
  URL_REGEX_STRICT = 'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)';

  URL_PATH_UNSAFE_CHARS: set of Byte = [Ord(' '), Ord('"'), Ord(''''), Ord(','),
    Ord('<'), Ord('>'), Ord(','), Ord('^'), Ord(':'), Ord('['), Ord(']'),
    Ord('`'), Ord('+'), Ord('{'), Ord('}'), Ord(';'), Ord('@'), Ord('*'),
    Ord('!'), Ord('\'), Ord('|'), Ord('('), Ord(')'), Ord('$'), Ord('%')];
  URL_QUERY_RESERVED_CHARS: set of Byte = [Ord('?'), Ord('&'), Ord('=')];

  NULL_DATETIME = 0;

  DEFAULT_MACRO_BRACKET = '%';

  DEFAULT_DT_FORMAT: TFormatSettings = (
    DateSeparator: '/'; TimeSeparator: ':'; ShortDateFormat: 'mmddyyyy'; DecimalSeparator: '.'
  );
  ACCEPTED_DT_FORMATS: array[0..5] of TFormatSettings = (
    (DateSeparator: '-'; TimeSeparator: ':'; ShortDateFormat: 'yyyymmdd'; DecimalSeparator: '.'),
    (DateSeparator: '/'; TimeSeparator: ':'; ShortDateFormat: 'yyyymmdd'; DecimalSeparator: '.'),
    (DateSeparator: '-'; TimeSeparator: ':'; ShortDateFormat: 'ddmmyyyy'; DecimalSeparator: '.'),
    (DateSeparator: '/'; TimeSeparator: ':'; ShortDateFormat: 'ddmmyyyy'; DecimalSeparator: '.'),
    (DateSeparator: '-'; TimeSeparator: ':'; ShortDateFormat: 'mmddyyyy'; DecimalSeparator: '.'),
    (DateSeparator: '/'; TimeSeparator: ':'; ShortDateFormat: 'mmddyyyy'; DecimalSeparator: '.')
  );
  ACCEPTED_FLOAT_DECIMAL_SEPARATORS: array[0..3] of Char = ('.', ',', '/', ' ');
  ACCEPTED_FLOAT_THOUSAND_SEPARATOR: Char = #0;

  LOG_NONE = 0;
  LOG_MINIMAL = 1;
  LOG_LOW = 2;
  LOG_MEDIUM = 3;
  LOG_HIGH = 4;
  LOG_DETAILED = 5;

/// <summary>
///  Regex value to get all text enclosed in the given brackets.
/// </summary>
function BracketRegexText(const AOpenBracket: string; const ACloseBracket: string = ''): string;

/// <summary>
///  Utility to get the index of DEFAULT_DT_FORMAT in ACCEPTED_DT_FORMATS.
/// </summary>
function DefaultDTFormatIndex: Integer;

/// <summary>
///  Returns a string that describes the datetime part of a TFormatSettings
///  record. This is useful to compare string formats to Delphi formats.
/// </summary>
function DTFormatToStr(const ADTFormat: TFormatSettings; const AIncludeTime: Boolean): string;

/// <summary>
///  Checks if the given date time format is included in the accepted ones and
///  returns its index in the accepted datetime formats array.
/// </summary>
function IsAcceptedDTFormat(const ADateTimeFormat: string; out AIndex: Integer): Boolean; overload;

/// <summary>
///  Checks if the given date time format is included in the accepted ones.
/// </summary>
function IsAcceptedDTFormat(const ADateTimeFormat: string): Boolean; overload;

/// <summary>
///  Returns the name of the running executable.
/// </summary>
function AppName: string;

/// <summary>
///  Returns the folder path of the running application.
/// </summary>
function AppPath: string;

implementation

uses
  StrUtils, TypInfo, Rtti, RegularExpressions;

const
  BRACKET_REGEX = '(?<!\\)#open#([\s\S]*?)(?<!\\)#close#';

function BracketRegexText(const AOpenBracket, ACloseBracket: string): string;
var
  LCloseBracket: string;
begin
  Assert(AOpenBracket <> '');

  LCloseBracket := ACloseBracket;
  if LCloseBracket = '' then
    LCloseBracket := AOpenBracket;
  Result := ReplaceStr(ReplaceStr(BRACKET_REGEX, '#open#', AOpenBracket),
    '#close#', LCloseBracket);
end;

function FormatToStr(const AMacroChars, AFormat: string; const ASeparator: Char): string;
var
  LChar: Char;
  LPosIndex: Integer;
  I: Integer;
begin
  Assert(AFormat <> '');
  Result := UpCase(AFormat[1]);
  if Pos(Result, AnsiUpperCase(AMacroChars)) < 1 then
    raise Exception.CreateFmt('"%s" is not a valid format character.', [AFormat[1]]);

  LPosIndex := 1;
  for I := 2 to Length(AFormat) do
  begin
    LChar := UpCase(AFormat[I]);
    if Pos(LChar, AnsiUpperCase(AMacroChars)) < 1 then
      Continue;
    if LChar = UpCase(Result[LPosIndex]) then
      Result := Result + LChar
    else
    begin
      Result := Result + ASeparator + LChar;
      LPosIndex := Length(Result);
    end;
  end;
  Result := AnsiLowerCase(Result);
end;

function DefaultDTFormatIndex: Integer;
begin
  Assert(IsAcceptedDTFormat(DTFormatToStr(DEFAULT_DT_FORMAT, True), Result),
    'DEFAULT_DT_FORMAT is not an accepted date and time format.');
end;

function DTFormatToStr(const ADTFormat: TFormatSettings; const AIncludeTime: Boolean): string;
var
  LTimeFormat: string;
begin
  Result := FormatToStr('YMD', ADTFormat.ShortDateFormat, ADTFormat.DateSeparator);
  if AIncludeTime then
  begin
    LTimeFormat := ADTFormat.ShortTimeFormat;
    if LTimeFormat = '' then
      LTimeFormat := 'hhnnss';
    Result := Result + ' ' + FormatToStr('HNSZ', LTimeFormat, ADTFormat.TimeSeparator);
  end;
end;

function IsAcceptedDTFormat(const ADateTimeFormat: string; out AIndex: Integer): Boolean;
var
  LItem: TFormatSettings;
  I: Integer;
begin
  Result := False;
  AIndex := -1;
  for I := 0 to High(ACCEPTED_DT_FORMATS) do
  begin
    LItem := ACCEPTED_DT_FORMATS[I];
    if MatchText(ADateTimeFormat, [DTFormatToStr(LItem, True), DTFormatToStr(LItem, False)]) then
    begin
      AIndex := I;
      Result := True;
      Break;
    end;
  end;
end;

function IsAcceptedDTFormat(const ADateTimeFormat: string): Boolean;
var
  LThrow: Integer;
begin
  Result := IsAcceptedDTFormat(ADateTimeFormat, LThrow);
end;

function AppName: string;
var
  LExt: string;
begin
  Result := ExtractFileName(ParamStr(0));
  LExt := ExtractFileExt(Result);
  if string.EndsText(LExt, Result) then
    SetLength(Result, Length(Result) - Length(LExt));
end;

function AppPath: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

end.
