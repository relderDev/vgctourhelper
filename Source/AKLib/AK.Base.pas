unit AK.Base;

{$I AK.Defines.inc}

interface

uses
  SysUtils, Classes, TypInfo, RegularExpressions, Generics.Collections,
  AK.Constants, AK.Logger;

type
  TAKStringProc = reference to procedure (const AString: string);
  TAKStringFunc = reference to function (const AString: string): string;
  TAKStringPredicate = reference to function (const AString: string): Boolean;
  TAKVarStringProc = reference to procedure (var AString: string);
  TAKVarStringPredicate = reference to function (const AString: string): Boolean;
  TAKStringEnumProc = reference to procedure (const AProc: TAKStringProc);
  TAKFileProc = reference to procedure (const APath: string; const AFileRef: TSearchRec);
  TAKExceptionProc = reference to procedure (const AException: Exception);

  EAKErrorClass = class of EAKError;
  TAKBase = class;
  TAKComponent = class;

  /// <summary>Base error for generic types in the AK library (uses RTTI).</summary>
  EAKError<T> = class(Exception)
  strict private
    FCallerType: PTypeInfo;
    function GetCallerTypeName: string;
  public
    property CallerType: PTypeInfo read FCallerType;
    property CallerTypeName: string read GetCallerTypeName;
    constructor Create(const AMessage: string);
    constructor CreateFmt(const AMessage: string; const AValues: array of const);
  end;
  /// <summary>Base error for AK class instances.</summary>
  EAKError = class(Exception)
  strict private
    FCallerClass: TClass;
    function GetCallerAKClassName: string;
  public
    property CallerClass: TClass read FCallerClass;
    property CallerAKClassName: string read GetCallerAKClassName;
    constructor Create(const ACallerClass: TClass; const AMessage: string);
    constructor CreateFmt(const ACallerClass: TClass; const AMessage: string;
      const AValues: array of const);
  end;
  /// <summary>Assertion failure.</summary>
  EAKAssertionFailure = class(EAKError);
  /// <summary>Something is invalid or missing in class implementation.</summary>
  EAKImplError = class(EAKError)
  strict private
    FSourceClass: TClass;
    function GetSourceAKClassName: string;
  public
    property SourceClass: TClass read FSourceClass write FSourceClass;
    property SourceAKClassName: string read GetSourceAKClassName;
  end;
  /// <summary>Something is invalid or missing in configuration data.</summary>
  EAKConfigError = class(EAKError);
  /// <summary>Duplicate are not allowed.</summary>
  EAKDupError = class(EAKError);
  /// <summary>Some Resource, data or value not found.</summary>
  EAKNotFoundError = class(EAKError);
  /// <summary>Non-conforming data or argument is passed.</summary>
  EAKDataError = class(EAKError);
  /// <summary>Unexpected type or structure.</summary>
  EAKTypeError = class(EAKError);
  /// <summary>Unrecognized string content.</summary>
  EAKFormatError = class(EAKError);
  /// <summary>State and action mismatch.</summary>
  EAKStateError = class(EAKError);
  /// <summary>Cross (mutual) dependency error.</summary>
  EAKCrossDepError = class(EAKError);

  EAKErrorProc = reference to procedure (const AError: EAKError);

  IAKObserver = interface
  ['{91237995-DBD3-4432-A957-BF28B81CE284}']
    procedure ReceiveNotification(const ASubject: TObject; const AEvent, AContent: string);
  end;

  IAKObserverSubscription = record
    Observer: IAKObserver;
    Events: string;
  end;

  /// <summary>
  ///  Abstract class that grants the capability to notify events to its
  ///  observers and to be notified by the subjects it observes.
  ///  It has disabled reference counting: it should never be passed or created
  ///  as an interface.
  /// </summary>
  TAKSubject = class abstract(TObject, IInterface, IAKObserver)
  strict private
    FSubscriptions: array of IAKObserverSubscription;
  public
    { Interface methods }
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    procedure ReceiveNotification(const ASubject: TObject; const AEvent, AContent: string); virtual;
    { Subject methods }
    procedure AddObserver(const AObserver: IAKObserver; const AEventList: array of string); overload;
    procedure AddObserver(const AObserver: IAKObserver); overload;
    procedure RemoveObserver(const AObserver: IAKObserver);
    procedure NotifyObservers(const AEvent, AContent: string);
    procedure NotifyObserversAs(const ASubject: TObject; const AEvent, AContent: string); virtual;
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Abstract class that grants the capability to notify events to its
  ///  observers and to be notified by the subjects it observes. It inherits the
  ///  component traits, too.
  /// </summary>
  TAKSubjectComponent = class abstract(TComponent, IAKObserver)
  strict private
    FSubscriptions: array of IAKObserverSubscription;
  public
    { Interface methods }
    procedure ReceiveNotification(const ASubject: TObject; const AEvent, AContent: string); virtual; abstract;
    { Subject methods }
    procedure AddObserver(const AObserver: IAKObserver; const AEventList: array of string); overload;
    procedure AddObserver(const AObserver: IAKObserver); overload;
    procedure RemoveObserver(const AObserver: IAKObserver);
    procedure NotifyObservers(const AEvent, AContent: string);
    procedure NotifyObserversAs(const ASubject: TObject; const AEvent, AContent: string); virtual;
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Abstract class used for granting utilities to all descendants, as well as
  ///  observer and subject capabilities. Default logger will log onto the
  ///  application-scoped logger (see AK.Logger).
  /// </summary>
  TAKBase = class abstract(TAKSubject)
  strict private
    FLogger: TAKLogger;
    FErrorClass: EAKErrorClass;
    FOnError: EAKErrorProc;
    FIsLoggerLinked: Boolean;
    FAutoLogOnError: Boolean;
    procedure SetErrorClass(const AValue: EAKErrorClass);
  strict protected
    property ErrorClass: EAKErrorClass read FErrorClass write SetErrorClass;
    function CreateLogger: TAKLogger; virtual;
    procedure Assert(const ACondition: Boolean; const AMessage: string = 'Assertion failure');
    function AKException(const AMessage: string): EAKError; overload;
    function AKException(const AMessage: string; const AValues: array of const): EAKError; overload;
    function AKException(const AClass: EAKErrorClass; const AMessage: string): EAKError; overload;
    function AKException(const AClass: EAKErrorClass; const AMessage: string;
      const AValues: array of const): EAKError; overload;
    function FormatLog(const AString: string): string; virtual;
  public
    property Logger: TAKLogger read FLogger;
    property OnError: EAKErrorProc read FOnError write FOnError;
    property AutoLogOnError: Boolean read FAutoLogOnError write FAutoLogOnError;
    procedure LinkLogger(const AAKObject: TAKBase); overload;
    procedure LinkLogger(const AAKComponent: TAKComponent); overload;
    procedure DelinkLogger;
    constructor Create;
    destructor Destroy; override;
    class function AKClassName: string; virtual;
  end;

  /// <summary>
  ///  Abstract class used for granting utilities to all descendants, as well as
  ///  component, observer and subject capabilities. Default logger will log
  ///  onto the application-scoped logger (see AK.Logger).
  /// </summary>
  TAKComponent = class abstract(TAKSubjectComponent)
  strict private
    FLogger: TAKLogger;
    FErrorClass: EAKErrorClass;
    FOnError: EAKErrorProc;
    FIsLoggerLinked: Boolean;
    FAutoLogOnError: Boolean;
    procedure SetErrorClass(const AValue: EAKErrorClass);
  strict protected
    property ErrorClass: EAKErrorClass read FErrorClass write SetErrorClass;
    function CreateLogger: TAKLogger; virtual;
    procedure Assert(const ACondition: Boolean; const AMessage: string = 'Assertion failure');
    function AKException(const AMessage: string): EAKError; overload;
    function AKException(const AMessage: string; const AValues: array of const): EAKError; overload;
    function AKException(const AClass: EAKErrorClass; const AMessage: string): EAKError; overload;
    function AKException(const AClass: EAKErrorClass; const AMessage: string;
      const AValues: array of const): EAKError; overload;
    function FormatLog(const AString: string): string; virtual;
    function GetOwner: TAKComponent; reintroduce;
  public
    property Owner: TAKComponent read GetOwner;
    property Logger: TAKLogger read FLogger;
    property OnError: EAKErrorProc read FOnError write FOnError;
    property AutoLogOnError: Boolean read FAutoLogOnError write FAutoLogOnError;
    procedure LinkLogger(const AAKObject: TAKBase); overload;
    procedure LinkLogger(const AAKComponent: TAKComponent); overload;
    procedure DelinkLogger;
    constructor Create(const AOwner: TAKComponent); reintroduce; virtual;
    destructor Destroy; override;
    class function AKClassName: string; virtual;
  end;

  TAKExpanderMethod = function (const AString: string): string of object;

  TAKExpander = record
  private
    FMethod: TAKExpanderMethod;
    function Instance: TObject; inline;
    function GetMacroValue(const AMacroName: string): string;
  public
    constructor Create(const AMethod: TAKExpanderMethod);
  end;

  /// <summary>
  ///  Abstract class that adds the capability to expand macros to an object.
  ///  All descendants must implement GetMacroValue method.
  /// </summary>
  TAKExpanderBase = class abstract(TAKBase)
  strict private
    FMacroBracket: string;
    FPreserveMacros: Boolean;
    FBeforeExpand: TAKVarStringProc;
    function ReplaceMacro(const AMatch: TMatch): string;
  strict protected
    function GetMacroValue(const AMacroName: string): string; virtual; abstract;
  public
    property MacroBracket: string read FMacroBracket write FMacroBracket;
    property PreserveMacros: Boolean read FPreserveMacros write FPreserveMacros;

    /// <summary>
    ///  Replaces the macros in the given string calling GetMacroValue on them.
    ///  If GetMacroValue returns an empty string, the macro is left as it was.
    ///  In order to replace a macro with an empty string ABeforeExpand must set
    ///  its name to an empty string. Macros are enclosed by unescaped
    ///  MacroBracket strings.
    ///  Application macros are expanded as well (after record macros).
    /// <summary>
    procedure ExpandMacros(var AString: string; const ABeforeExpand: TAKVarStringProc = nil);

    constructor Create;
    function AsExpander: TAKExpander;
  end;

  /// <summary>
  ///  Abstract class that adds the capability to expand macros to an object.
  ///  All descendants must implement GetMacroValue method.
  /// </summary>
  TAKExpanderComponent = class abstract(TAKComponent)
  strict private
    FMacroBracket: string;
    FPreserveMacros: Boolean;
    FBeforeExpand: TAKVarStringProc;
    function ReplaceMacro(const AMatch: TMatch): string;
  strict protected
    function GetMacroValue(const AMacroName: string): string; virtual; abstract;
  public
    property MacroBracket: string read FMacroBracket write FMacroBracket;
    property PreserveMacros: Boolean read FPreserveMacros write FPreserveMacros;

    /// <summary>
    ///  Replaces the macros in the given string calling GetMacroValue on them.
    ///  If GetMacroValue returns an empty string, the macro is left as it was.
    ///  In order to replace a macro with an empty string ABeforeExpand must set
    ///  its name to an empty string. Macros are enclosed by unescaped
    ///  MacroBracket strings.
    ///  Application macros are expanded as well (after record macros).
    /// <summary>
    procedure ExpandMacros(var AString: string; const ABeforeExpand: TAKVarStringProc = nil);

    constructor Create(const AOwner: TAKComponent); override;
    function AsExpander: TAKExpander;
  end;

  /// <summary>
  ///  Utility singleton class to register application-scoped macros. All of
  ///  these macros will be expanded when expanding macros of any TAKExpander.
  ///  A TAKExpander can also be registered directly as a list of application
  ///  macros via the RegisterExpander method with a namespace prefix: they
  ///  will be named "Namespace:MacroName".
  /// </summary>
  TAKAppMacrosRegistry = class(TAKBase)
  strict private
    FMacros: TDictionary<string, TAKStringFunc>;
    FExpanders: TDictionary<string, TAKExpander>;
    FMacroBracket: string;
    FPreserveMacros: Boolean;
    class var FInstance: TAKAppMacrosRegistry;
    class function GetInstance: TAKAppMacrosRegistry; static;
    function ReplaceMacro(const AMatch: TMatch): string;
  public
    procedure ReceiveNotification(const ASubject: TObject; const AEvent, AContent: string); override;
  public
    property MacroBracket: string read FMacroBracket write FMacroBracket;
    class property Instance: TAKAppMacrosRegistry read GetInstance;
    procedure RegisterMacro(const AMacroName: string; const AReplaceFunc: TAKStringFunc); overload;
    procedure RegisterMacro(const AMacroName, AMacroValue: string); overload;
    procedure RegisterExpander(const ANamespace: string; const AExpander: TAKExpander);
    procedure UnregisterMacro(const AMacroName: string);
    procedure UnregisterExpander(const ANamespace: string);
    procedure Expand(var AString: string; const APreserveMacros: Boolean = True);
    constructor Create;
    destructor Destroy; override;
    class destructor Destroy;
  end;

  TUTF8NoBOM = class(TUTF8Encoding)
  public
    function GetPreamble: TBytes; override;
  end;

  TEncodingHelper = class Helper for TEncoding
  strict private
    class var FUTF8NoBOM: TUTF8NoBOM;
  public
    class function UTF8NoBom: TEncoding;
    class destructor Destroy;
  end;

implementation

uses
  StrUtils, Rtti, Generics.Defaults;

{ NOT NEEDED ANYMORE KEEPING IT JUST IN CASE
function AsAKExpander(const AObject: TObject): TAKExpander;
var
  LContext: TRttiContext;
  LMethod: TRttiMethod;
  LMethodPointer: TMethod;

  procedure AssertValidCast(const ACondition: Boolean);
  begin
    if not ACondition then
      raise EAKError<TAKExpander>.CreateFmt('Invalid cast (%s).', [AObject.ClassName]);
  end;
begin
  Assert(Assigned(AObject));

  LMethod := LContext.GetType(AObject.ClassType).GetMethod('GetMacroValue');
  AssertValidCast(Assigned(LMethod));
  AssertValidCast(not LMethod.IsClassMethod);
  AssertValidCast(Length(LMethod.GetParameters) = 1);
  AssertValidCast(LMethod.GetParameters[0].Flags = []);
  AssertValidCast(LMethod.GetParameters[0].ParamType.Name = 'string');
  AssertValidCast(Assigned(LMethod.ReturnType));
  AssertValidCast(LMethod.ReturnType.Name = 'string');
  LMethodPointer.Code := LMethod.CodeAddress;
  LMethodPointer.Data := AObject;
  Result := TAKExpander.Create(TAKExpanderMethod(LMethodPointer));
end;}

{ EAKError<T> }

constructor EAKError<T>.Create(const AMessage: string);
begin
  FCallerType := TypeInfo(T);
  {$IFDEF DEBUG}
  inherited Create(Format('[Error on type %s] %s', [CallerTypeName, AMessage]));
  {$ELSE}
  inherited Create(AMessage);
  {$ENDIF}
end;

constructor EAKError<T>.CreateFmt(const AMessage: string; const AValues: array of const);
begin
  Create(Format(AMessage, AValues));
end;

function EAKError<T>.GetCallerTypeName: string;
begin
  Result := TRttiContext.Create.GetType(FCallerType).Name;
end;

{ EAKError }

constructor EAKError.Create(const ACallerClass: TClass; const AMessage: string);
begin
  Assert(Assigned(ACallerClass));
  Assert(ACallerClass.InheritsFrom(TAKBase) or ACallerClass.InheritsFrom(TAKComponent));

  FCallerClass := ACallerClass;
  {$IFDEF DEBUG}
  inherited CreateFmt('[%s] %s', [FCallerClass.ClassName, AMessage]);
  {$ELSE}
  inherited Create(AMessage);
  {$ENDIF}
end;

constructor EAKError.CreateFmt(const ACallerClass: TClass;
  const AMessage: string; const AValues: array of const);
begin
  Create(ACallerClass, Format(AMessage, AValues));
end;

function EAKError.GetCallerAKClassName: string;
begin
  if FCallerClass.InheritsFrom(TAKBase) then
    Result := TAKBase(FCallerClass).AKClassName
  else if FCallerClass.InheritsFrom(TAKComponent) then
    Result := TAKComponent(FCallerClass).AKClassName;
end;

{ EAKImplError }

function EAKImplError.GetSourceAKClassName: string;
begin
  Result := '';
  if Assigned(FSourceClass) then
  begin
    if FSourceClass.InheritsFrom(TAKBase) then
      Result := TAKBase(FSourceClass).AKClassName
    else if FSourceClass.InheritsFrom(TAKComponent) then
      Result := TAKComponent(FSourceClass).AKClassName;
  end;
end;

{ TAKSubject }

procedure TAKSubject.AddObserver(const AObserver: IAKObserver; const AEventList: array of string);
var
  LLength: Integer;
begin
  LLength := Length(FSubscriptions);
  SetLength(FSubscriptions, LLength + 1);
  FSubscriptions[LLength].Observer := AObserver;
  FSubscriptions[LLength].Events := UpperCase(string.Join('|', AEventList));
end;

procedure TAKSubject.AddObserver(const AObserver: IAKObserver);
var
  LLength: Integer;
begin
  LLength := Length(FSubscriptions);
  SetLength(FSubscriptions, LLength + 1);
  FSubscriptions[LLength].Observer := AObserver;
  FSubscriptions[LLength].Events := '';
end;

destructor TAKSubject.Destroy;
begin
  NotifyObservers('Destroy', '');
  inherited;
end;

procedure TAKSubject.NotifyObservers(const AEvent, AContent: string);
begin
  NotifyObserversAs(Self, AEvent, AContent);
end;

procedure TAKSubject.NotifyObserversAs(const ASubject: TObject; const AEvent,
  AContent: string);
var
  LSubscription: IAKObserverSubscription;

  function IsSubscribedToEvent(const ASub: IAKObserverSubscription): Boolean;
  var
    LEvent: string;
  begin
    if ASub.Events = '' then
      Exit(True);

    LEvent := '|' + UpperCase(AEvent) + '|';
    Result := Pos(LEvent, '|' + ASub.Events + '|') > 0;
  end;
begin
  for LSubscription in FSubscriptions do
    if IsSubscribedToEvent(LSubscription)  then
      LSubscription.Observer.ReceiveNotification(ASubject, AEvent, AContent);
end;

function TAKSubject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TAKSubject.ReceiveNotification(const ASubject: TObject;
  const AEvent, AContent: string);
begin
end;

procedure TAKSubject.RemoveObserver(const AObserver: IAKObserver);
var
  LHigh: Integer;
  LIndex: Integer;
  I: Integer;
begin
  LHigh := High(FSubscriptions);
  LIndex := -1;
  for I := 0 to LHigh do
    if FSubscriptions[I].Observer = AObserver then
    begin
      LIndex := I;
      Break;
    end;
  if LIndex = -1 then
    Exit;
  for I := LIndex + 1 to LHigh do
    FSubscriptions[I - 1] := FSubscriptions[I];
  SetLength(FSubscriptions, LHigh);
end;

function TAKSubject._AddRef: Integer;
begin
  Result := -1;
end;

function TAKSubject._Release: Integer;
begin
  Result := -1;
end;

{ TAKSubjectComponent }

procedure TAKSubjectComponent.AddObserver(const AObserver: IAKObserver;
  const AEventList: array of string);
var
  LLength: Integer;
begin
  LLength := Length(FSubscriptions);
  SetLength(FSubscriptions, LLength + 1);
  FSubscriptions[LLength].Observer := AObserver;
  FSubscriptions[LLength].Events := UpperCase(string.Join('|', AEventList));
end;

procedure TAKSubjectComponent.AddObserver(const AObserver: IAKObserver);
var
  LLength: Integer;
begin
  LLength := Length(FSubscriptions);
  SetLength(FSubscriptions, LLength + 1);
  FSubscriptions[LLength].Observer := AObserver;
  FSubscriptions[LLength].Events := '';
end;

destructor TAKSubjectComponent.Destroy;
begin
  NotifyObservers('Destroy', '');
  inherited;
end;

procedure TAKSubjectComponent.NotifyObservers(const AEvent, AContent: string);
begin
  NotifyObserversAs(Self, AEvent, AContent);
end;

procedure TAKSubjectComponent.NotifyObserversAs(const ASubject: TObject;
  const AEvent, AContent: string);
var
  LSubscription: IAKObserverSubscription;

  function IsSubscribedToEvent(const ASub: IAKObserverSubscription): Boolean;
  var
    LEvent: string;
  begin
    if ASub.Events = '' then
      Exit(True);

    LEvent := '|' + UpperCase(AEvent) + '|';
    Result := Pos(LEvent, '|' + ASub.Events + '|') > 0;
  end;
begin
  for LSubscription in FSubscriptions do
    if IsSubscribedToEvent(LSubscription)  then
      LSubscription.Observer.ReceiveNotification(ASubject, AEvent, AContent);
end;

procedure TAKSubjectComponent.RemoveObserver(const AObserver: IAKObserver);
var
  LHigh: Integer;
  LIndex: Integer;
  I: Integer;
begin
  LHigh := High(FSubscriptions);
  LIndex := -1;
  for I := 0 to LHigh do
    if FSubscriptions[I].Observer = AObserver then
    begin
      LIndex := I;
      Break;
    end;
  if LIndex = -1 then
    Exit;
  for I := LIndex + 1 to LHigh do
    FSubscriptions[I - 1] := FSubscriptions[I];
  SetLength(FSubscriptions, LHigh);
end;

{ TAKBase }

class function TAKBase.AKClassName: string;
begin
  Result := ClassName;
  if string.StartsText('T', Result) then
    System.Delete(Result, Low(Result), 1);
  if string.StartsText('AK', Result) then
    System.Delete(Result, Low(Result), 2);
end;

function TAKBase.AKException(const AClass: EAKErrorClass;
  const AMessage: string): EAKError;
begin
  Assert(Assigned(AClass));

  if FAutoLogOnError then
    {$IFDEF DEBUG}
    Logger.Log('{%s} %s', [EAKErrorClass.ClassName, AMessage], 1);
    {$ELSE}
    Logger.Log(AMessage, 1);
    {$ENDIF}

  Result := AClass.Create(ClassType, AMessage);
  if Assigned(FOnError) then
    FOnError(Result);
end;

function TAKBase.AKException(const AMessage: string): EAKError;
begin
  Result := AKException(FErrorClass, AMessage);
end;

function TAKBase.AKException(const AClass: EAKErrorClass; const AMessage: string;
  const AValues: array of const): EAKError;
begin
  Result := AKException(AClass, Format(AMessage, AValues));
end;

procedure TAKBase.Assert(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise AKException(EAKAssertionFailure, AMessage);
end;

function TAKBase.AKException(const AMessage: string; const AValues: array of const): EAKError;
begin
  Result := AKException(Format(AMessage, AValues));
end;

constructor TAKBase.Create;
begin
  inherited;
  FLogger := CreateLogger;
  FErrorClass := EAKError;
  FIsLoggerLinked := False;
  FAutoLogOnError := False;
end;

function TAKBase.CreateLogger: TAKLogger;
begin
  Result := TAKLogger.Create;
  Result.Encoding := TEncoding.UTF8NoBom;
end;

procedure TAKBase.DelinkLogger;
begin
  if FIsLoggerLinked then
  begin
    FLogger := CreateLogger;
    FIsLoggerLinked := False;
  end;
end;

destructor TAKBase.Destroy;
begin
  if not FIsLoggerLinked then
    FreeAndNil(FLogger);
  inherited;
end;

function TAKBase.FormatLog(const AString: string): string;
begin
  Result := Format('[%s %s] %s', [AKClassName,
    FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AString]);
end;

procedure TAKBase.LinkLogger(const AAKComponent: TAKComponent);
begin
  Assert(Assigned(AAKComponent));

  if FLogger = AAKComponent.Logger then
    raise AKException(EAKCrossDepError, 'Linking logger to itself.');

  if not FIsLoggerLinked then
    FreeAndNil(FLogger);
  FLogger := AAKComponent.Logger;
  FIsLoggerLinked := True;
end;

procedure TAKBase.LinkLogger(const AAKObject: TAKBase);
begin
  Assert(Assigned(AAKObject));

  if FLogger = AAKObject.Logger then
    raise AKException(EAKCrossDepError, 'Linking logger to itself.');

  if not FIsLoggerLinked then
    FreeAndNil(FLogger);
  FLogger := AAKObject.Logger;
  FIsLoggerLinked := True;
end;

procedure TAKBase.SetErrorClass(const AValue: EAKErrorClass);
begin
  Assert(Assigned(AValue));
  FErrorClass := AValue;
end;

{ TAKComponent }

class function TAKComponent.AKClassName: string;
begin
  Result := ClassName;
  if string.StartsText('T', Result) then
    System.Delete(Result, Low(Result), 1);
  if string.StartsText('AK', Result) then
    System.Delete(Result, Low(Result), 2);
end;

function TAKComponent.AKException(const AClass: EAKErrorClass;
  const AMessage: string): EAKError;
begin
  Assert(Assigned(AClass));

  if FAutoLogOnError then
    {$IFDEF DEBUG}
    Logger.Log('{%s} %s', [EAKErrorClass.ClassName, AMessage], 1);
    {$ELSE}
    Logger.Log(AMessage, 1);
    {$ENDIF}

  Result := AClass.Create(ClassType, AMessage);
  if Assigned(FOnError) then
    FOnError(Result);
end;

function TAKComponent.AKException(const AMessage: string): EAKError;
begin
  Result := AKException(FErrorClass, AMessage);
end;

function TAKComponent.AKException(const AClass: EAKErrorClass;
  const AMessage: string; const AValues: array of const): EAKError;
begin
  Result := AKException(AClass, Format(AMessage, AValues));
end;

function TAKComponent.AKException(const AMessage: string;
  const AValues: array of const): EAKError;
begin
  Result := AKException(Format(AMessage, AValues));
end;

procedure TAKComponent.Assert(const ACondition: Boolean;
  const AMessage: string);
begin
  if not ACondition then
    raise AKException(EAKAssertionFailure, AMessage);
end;

constructor TAKComponent.Create(const AOwner: TAKComponent);
begin
  inherited Create(AOwner);
  FLogger := CreateLogger;
  FErrorClass := EAKError;
  FIsLoggerLinked := False;
  FAutoLogOnError := False;
end;

function TAKComponent.CreateLogger: TAKLogger;
begin
  Result := TAKLogger.Create;
  Result.Encoding := TEncoding.UTF8NoBom;
end;

procedure TAKComponent.DelinkLogger;
begin
  if FIsLoggerLinked then
  begin
    FLogger := CreateLogger;
    FIsLoggerLinked := False;
  end;
end;

destructor TAKComponent.Destroy;
begin
  if not FIsLoggerLinked then
    FreeAndNil(FLogger);
  inherited;
end;

function TAKComponent.FormatLog(const AString: string): string;
begin
  Result := Format('[%s %s] %s', [AKClassName,
    FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AString]);
end;

function TAKComponent.GetOwner: TAKComponent;
begin
  Result := inherited Owner as TAKComponent;
end;

procedure TAKComponent.LinkLogger(const AAKComponent: TAKComponent);
begin
  Assert(Assigned(AAKComponent));

  if FLogger = AAKComponent.Logger then
    raise AKException(EAKCrossDepError, 'Linking logger to itself.');

  if not FIsLoggerLinked then
    FreeAndNil(FLogger);
  FLogger := AAKComponent.Logger;
  FIsLoggerLinked := True;
end;

procedure TAKComponent.LinkLogger(const AAKObject: TAKBase);
begin
  Assert(Assigned(AAKObject));

  if FLogger = AAKObject.Logger then
    raise AKException(EAKCrossDepError, 'Linking logger to itself.');

  if not FIsLoggerLinked then
    FreeAndNil(FLogger);
  FLogger := AAKObject.Logger;
  FIsLoggerLinked := True;
end;

procedure TAKComponent.SetErrorClass(const AValue: EAKErrorClass);
begin
  Assert(Assigned(AValue));
  FErrorClass := AValue;
end;

{ TAKExpander }

constructor TAKExpander.Create(const AMethod: TAKExpanderMethod);
begin
  Assert(Assigned(TMethod(AMethod).Code));
  Assert(Assigned(TMethod(AMethod).Data));

  FMethod := AMethod;
end;

function TAKExpander.GetMacroValue(const AMacroName: string): string;
begin
  Result := FMethod(AMacroName);
end;

function TAKExpander.Instance: TObject;
begin
  Result := TObject(TMethod(FMethod).Data);
end;

{ TAKExpanderBase }

function TAKExpanderBase.AsExpander: TAKExpander;
begin
  Result := TAKExpander.Create(GetMacroValue);
end;

constructor TAKExpanderBase.Create;
begin
  inherited Create;
  FMacroBracket := DEFAULT_MACRO_BRACKET;
  FPreserveMacros := True;
end;

procedure TAKExpanderBase.ExpandMacros(var AString: string;
  const ABeforeExpand: TAKVarStringProc);
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create(BracketRegexText(MacroBracket), [roIgnoreCase, roNotEmpty]);
  FBeforeExpand := ABeforeExpand;
  AString := LRegex.Replace(AString, ReplaceMacro);
  FBeforeExpand := nil;
  if PreserveMacros then
    AString := ReplaceStr(AString, '{Backslash}', '\');
  TAKAppMacrosRegistry.Instance.Expand(AString);
end;

function TAKExpanderBase.ReplaceMacro(const AMatch: TMatch): string;
var
  LCleanName: string;
begin
  LCleanName := ReplaceStr(AMatch.Value, MacroBracket, '');
  if Assigned(FBeforeExpand) then
    FBeforeExpand(LCleanName);
  if LCleanName = '' then
    Exit('');
  Result := GetMacroValue(LCleanName);
  if PreserveMacros and Result.Contains('\') then
    Result := ReplaceStr(Result, '\', '{Backslash}');
  if Result = '' then
    Result := AMatch.Value;
end;

{ TAKExpanderComponent }

function TAKExpanderComponent.AsExpander: TAKExpander;
begin
  Result := TAKExpander.Create(GetMacroValue);
end;

constructor TAKExpanderComponent.Create(const AOwner: TAKComponent);
begin
  inherited Create(AOwner);
  FMacroBracket := DEFAULT_MACRO_BRACKET;
  FPreserveMacros := True;
end;

procedure TAKExpanderComponent.ExpandMacros(var AString: string;
  const ABeforeExpand: TAKVarStringProc);
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create(BracketRegexText(MacroBracket), [roIgnoreCase, roNotEmpty]);
  FBeforeExpand := ABeforeExpand;
  AString := LRegex.Replace(AString, ReplaceMacro);
  FBeforeExpand := nil;
  if PreserveMacros then
    AString := ReplaceStr(AString, '{Backslash}', '\');
  TAKAppMacrosRegistry.Instance.Expand(AString);
end;

function TAKExpanderComponent.ReplaceMacro(const AMatch: TMatch): string;
var
  LCleanName: string;
begin
  LCleanName := ReplaceStr(AMatch.Value, MacroBracket, '');
  if Assigned(FBeforeExpand) then
    FBeforeExpand(LCleanName);
  if LCleanName = '' then
    Exit('');
  Result := GetMacroValue(LCleanName);
  if PreserveMacros and Result.Contains('\') then
    Result := ReplaceStr(Result, '\', '{Backslash}');
  if Result = '' then
    Result := AMatch.Value;
end;

{ TAKAppMacrosRegistry }

constructor TAKAppMacrosRegistry.Create;
begin
  inherited;
  FMacros := TDictionary<string, TAKStringFunc>.Create(TIStringComparer.Ordinal);
  FExpanders := TDictionary<string, TAKExpander>.Create(TIStringComparer.Ordinal);
  FMacroBracket := DEFAULT_MACRO_BRACKET;
  FPreserveMacros := True;
end;

class destructor TAKAppMacrosRegistry.Destroy;
begin
  FreeAndNil(FInstance);
end;

destructor TAKAppMacrosRegistry.Destroy;
begin
  FreeAndNil(FMacros);
  FreeAndNil(FExpanders);
  inherited;
end;

procedure TAKAppMacrosRegistry.Expand(var AString: string; const APreserveMacros: Boolean);
var
  LRegex: TRegEx;
begin
  LRegex := TRegEx.Create(BracketRegexText(MacroBracket), [roIgnoreCase, roNotEmpty]);
  FPreserveMacros := APreserveMacros;
  AString := LRegex.Replace(AString, ReplaceMacro);
  if FPreserveMacros then
    AString := ReplaceStr(AString, '{Backslash}', '\');
end;

class function TAKAppMacrosRegistry.GetInstance: TAKAppMacrosRegistry;
begin
  if not Assigned(FInstance) then
    FInstance := TAKAppMacrosRegistry.Create;
  Result := FInstance;
end;

procedure TAKAppMacrosRegistry.RegisterMacro(const AMacroName: string;
  const AReplaceFunc: TAKStringFunc);
begin
  Assert(Pos(AMacroName, ':') = 0, 'The character ":" is reserved, cannot be used in macros.');

  if FMacros.ContainsKey(AMacroName) then
    raise AKException(EAKDupError, 'Macro "%s" already defined.', [AMacroName]);
  FMacros.Add(AMacroName, AReplaceFunc);
end;

procedure TAKAppMacrosRegistry.RegisterMacro(const AMacroName, AMacroValue: string);
begin
  RegisterMacro(AMacroName,
    function (const AMacroName: string): string
    begin
      Result := AMacroValue;
    end);
end;

procedure TAKAppMacrosRegistry.ReceiveNotification(const ASubject: TObject;
  const AEvent, AContent: string);
var
  LKey: string;
begin
  inherited;
  for LKey in FExpanders.Keys do
    if FExpanders[LKey].Instance = ASubject then
      FExpanders.Remove(LKey);
end;

procedure TAKAppMacrosRegistry.RegisterExpander(const ANamespace: string;
  const AExpander: TAKExpander);
begin
  Assert(ANamespace <> '');
  if FExpanders.ContainsKey(ANamespace) then
    raise AKException(EAKDupError, 'Namespace "%s" already in use.', [ANamespace]);

  FExpanders.Add(ANamespace, AExpander);
  if AExpander.Instance is TAKSubject then
    (AExpander.Instance as TAKSubject).AddObserver(Self, ['Destroy'])
  else if AExpander.Instance is TAKSubjectComponent then
    (AExpander.Instance as TAKSubjectComponent).AddObserver(Self, ['Destroy']);
end;

function TAKAppMacrosRegistry.ReplaceMacro(const AMatch: TMatch): string;
var
  LMacroName: string;
  LIndex: Integer;
  LNamespace: string;
begin
  Result := AMatch.Value;
  LMacroName := ReplaceStr(Result, MacroBracket, '');
  LIndex := Pos(':', LMacroName);
  if LIndex > 0 then
  begin
    LNamespace := Copy(LMacroName, Low(LMacroName), LIndex - 1);
    if not FExpanders.ContainsKey(LNamespace) then
      Exit;
    LMacroName := Copy(LMacroName, LIndex + Low(LMacroName));
    Result := FExpanders[LNamespace].GetMacroValue(LMacroName);
  end
  else if FMacros.ContainsKey(LMacroName) then
    Result := FMacros[LMacroName](LMacroName)
  else
    Exit;

  if FPreserveMacros and Result.Contains('\') then
    Result := ReplaceStr(Result, '\', '{Backslash}');
end;

procedure TAKAppMacrosRegistry.UnregisterMacro(const AMacroName: string);
begin
  FMacros.Remove(AMacroName);
end;

procedure TAKAppMacrosRegistry.UnregisterExpander(const ANamespace: string);
begin
  if ANamespace = '' then
    Exit;

  FExpanders.Remove(ANamespace);
end;

{ TUTF8NoBOM }

function TUTF8NoBOM.GetPreamble: TBytes;
begin
  Result := [];
end;

{ TEncodingHelper }

class destructor TEncodingHelper.Destroy;
begin
  FreeAndNil(FUTF8NoBOM);
end;

class function TEncodingHelper.UTF8NoBom: TEncoding;
begin
  if not Assigned(FUTF8NoBOM) then
    FUTF8NoBOM := TUTF8NoBOM.Create;
  Result := FUTF8NoBOM;
end;

initialization
  TAKAppLogger.Instance.Encoding := TEncoding.UTF8NoBom;

end.
