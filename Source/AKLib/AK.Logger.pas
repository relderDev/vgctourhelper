unit AK.Logger;

{$I AK.Defines.inc}

interface

uses
  SysUtils, Generics.Collections,
  AK.Constants;

type
  TAKWriteLogProc = reference to procedure (const AString: string);
  TAKFormatLogFunc = reference to function (const AString: string): string;
  TAKLogger = class;
  TAKLoggerOutputs = class(TList<TAKLogger>)
  strict private
    FOwned: TList<Integer>;
  public
    procedure Add(const AWrite: TAKWriteLogProc; const AFormat: TAKFormatLogFunc); overload;
    procedure Add(const ALogger: TAKLogger); overload;
    constructor Create;
    destructor Destroy; override;
  end;
  TAKLoggerClass = class of TAKLogger;

  /// <summary>
  ///  Base class for logging purposes, it has three main characteristics:
  ///  <ol><li>the Level determines which messages are actually logged</li>
  ///  <li>the FormatLog function formats the message before logging it</li>
  ///  <li>the WriteLog actually prints the log message in some way</li></ol>
  ///  This abstract class by default formats a log message by adding a
  ///  datetime stamp enclosed in square brackets before it and sends it to the
  ///  application-scoped logger instance (see TKAppLogger). Each instance can
  ///  hold any number of outputs, which can be added with AddLogOutput.
  /// </summary>
  TAKLogger = class
  strict private
    FLevel: Integer;
    FEncoding: TEncoding;
    FFormatLog: TAKFormatLogFunc;
    FWriteLog: TAKWriteLogProc;
    FOutputs: TAKLoggerOutputs;
    procedure SetFormatLog(const AValue: TAKFormatLogFunc);
    procedure SetWriteLog(const AValue: TAKWriteLogProc);
    function DefaultFormatLog(const AString: string): string;
  strict protected
    procedure DefaultWriteLog(const AString: string); virtual;
  public
    property Level: Integer read FLevel write FLevel;
    property Encoding: TEncoding read FEncoding write FEncoding;
    property FormatLog: TAKFormatLogFunc read FFormatLog write SetFormatLog;
    property WriteLog: TAKWriteLogProc read FWriteLog write SetWriteLog;
    procedure AddLogOutput(const AProc: TAKWriteLogProc; const AFormat: TAKFormatLogFunc = nil); overload;
    procedure AddLogOutput(const ALogger: TAKLogger); overload;
    procedure Log(const AString: string; const ALevel: Integer = LOG_MEDIUM); overload;
    procedure Log(const AString: string; const AValues: array of const;
      const ALevel: Integer = LOG_MEDIUM); overload;
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Application-scoped singleton logger. It is the recipient for all loggers
  ///  that have not set the property WriteLog. The default implementation uses
  ///  WriteLn for console applications and does nothing for other app types.
  ///  Set WriteLog value of the instance in order to customize your application
  ///  log messages.
  /// </summary>
  TAKAppLogger = class(TAKLogger)
  strict private
    class var FInstance: TAKAppLogger;
    class function GetInstance: TAKLogger; static;
  public
    class property Instance: TAKLogger read GetInstance;
    constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  ///  Implements a file-based logger.
  /// </summary>
  TAKFileLogger = class(TAKLogger)
  strict private
    FFileName: string;
  strict protected
    procedure DefaultWriteLog(const AString: string); override;
  public
    property FileName: string read FFileName write FFileName;
    constructor Create(const AFileName: string = '');
  end;

implementation

uses
  IOUtils;

{ TAKLoggerOutputs }

procedure TAKLoggerOutputs.Add(const AWrite: TAKWriteLogProc; const AFormat: TAKFormatLogFunc);
var
  LLogger: TAKLogger;
begin
  LLogger := TAKLogger.Create;
  LLogger.Level := LOG_DETAILED;
  LLogger.WriteLog := AWrite;
  LLogger.FormatLog := AFormat;
  FOwned.Add(inherited Add(LLogger));
end;

procedure TAKLoggerOutputs.Add(const ALogger: TAKLogger);
begin
  Assert(Assigned(ALogger));

  inherited Add(ALogger);
end;

constructor TAKLoggerOutputs.Create;
begin
  inherited Create;
  FOwned := TList<Integer>.Create;
end;

destructor TAKLoggerOutputs.Destroy;
var
  I: Integer;
begin
  for I in FOwned do
    FreeAndNil(Items[I]);
  FreeAndNil(FOwned);
  inherited;
end;

{ TAKLogger }

procedure TAKLogger.AddLogOutput(const AProc: TAKWriteLogProc; const AFormat: TAKFormatLogFunc);
begin
  Assert(Assigned(AProc));

  if not Assigned(AFormat) then
    FOutputs.Add(AProc, FormatLog)
  else
    FOutputs.Add(AProc, AFormat);
end;

procedure TAKLogger.AddLogOutput(const ALogger: TAKLogger);
begin
  Assert(Assigned(ALogger));
  Assert(ALogger <> Self);
  Assert(not ALogger.FOutputs.Contains(Self), 'Logger output loop detected.');

  if not FOutputs.Contains(ALogger) then
    FOutputs.Add(ALogger);
end;

constructor TAKLogger.Create;
begin
  inherited Create;

  {$IFDEF DEBUG}
  FLevel := LOG_DETAILED;
  {$ELSE}
  FLevel := LOG_MEDIUM;
  {$ENDIF}
  FEncoding := TEncoding.UTF8;
  FFormatLog := DefaultFormatLog;
  FWriteLog := DefaultWriteLog;
  FOutputs := TAKLoggerOutputs.Create;
end;

function TAKLogger.DefaultFormatLog(const AString: string): string;
begin
  Result := Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AString]);
end;

procedure TAKLogger.DefaultWriteLog(const AString: string);
begin
  TAKAppLogger.Instance.WriteLog(AString);
end;

destructor TAKLogger.Destroy;
begin
  FreeAndNil(FOutputs);

  inherited;
end;

procedure TAKLogger.Log(const AString: string; const AValues: array of const;
  const ALevel: Integer);
begin
  Log(Format(AString, AValues), ALevel);
end;

procedure TAKLogger.Log(const AString: string; const ALevel: Integer);
var
  LOutput: TAKLogger;
begin
  if ALevel <= Level then
  begin
    WriteLog(FormatLog(AString));
    for LOutput in FOutputs do
    begin
      LOutput.Log(AString, ALevel);
    end;
  end;
end;

procedure TAKLogger.SetFormatLog(const AValue: TAKFormatLogFunc);
begin
  Assert(Assigned(AValue));

  FFormatLog := AValue;
end;

procedure TAKLogger.SetWriteLog(const AValue: TAKWriteLogProc);
begin
  Assert(Assigned(AValue));

  FWriteLog := AValue;
end;

{ TAKAppLogger }

constructor TAKAppLogger.Create;
begin
  {$IFDEF CONSOLE}
  WriteLog := procedure (const AString: string)
    begin
      WriteLn(AString);
    end;
  {$ELSE}
  WriteLog := procedure (const AString: string) begin end;
  {$ENDIF}
end;

class destructor TAKAppLogger.Destroy;
begin
  FreeAndNil(FInstance);
end;

class function TAKAppLogger.GetInstance: TAKLogger;
begin
  if not Assigned(FInstance) then
    FInstance := TAKAppLogger.Create;
  Result := FInstance;
end;

{ TAKFileLogger }

constructor TAKFileLogger.Create(const AFileName: string);
begin
  inherited Create;
  if AFileName = '' then
    FFileName := Format('%s%s_%s_log.txt', [AppPath, FormatDateTime('yymm', Now), AppName])
  else
    FFileName := AFileName;
end;

procedure TAKFileLogger.DefaultWriteLog(const AString: string);
begin
  if not FileExists(FileName) then
    TFile.WriteAllText(FileName, AString + sLineBreak, Encoding)
  else
    TFile.AppendAllText(FileName, AString + sLineBreak, Encoding);
end;

end.
