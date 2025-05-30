unit AK.Crypt;

{$I AK.Defines.inc}

interface

uses
  SysUtils,
  SynCrypto,
  AK.Base;

type
  /// <summary>
  ///  Offers utility methods to simmetrically encrypt and decrypt strings.
  ///  Internally uses Base64 strings and synopse's encryption class TAESCTR
  ///  (see unit SynCrypto.pas). Remember to call SetKey before creating
  ///  instances of this class: not doing so will result in an error. As a rule
  ///  of thumb the key should be set in the initialization section of a project
  ///  unit - the standard way to do that is to define a UseAKLib unit.
  /// </summary>
  TAKAESEncrypter = class(TAKBase)
  strict private
    FEngine: TAESCTR;
    FRaiseErrors: Boolean;
    FUrlSafe: Boolean;
    class var FKey: TGUID;
    procedure FromBase64ToUrl(var ABase64: string);
    procedure FromUrlToBase64(var ABase64Url: string);
  public
    /// <summary>
    ///  True: errors can be raised in the DecryptString methods; False: no
    ///  error is raised but an empty string is returned when decryption fails.
    /// </summary>
    /// <remarks>
    ///  Defaults to True.
    /// </remarks>
    property RaiseErrors: Boolean read FRaiseErrors write FRaiseErrors;

    /// <summary>
    ///  True: encrypted strings are returned in Base64Url format; False:
    ///  encrypted strings are returned in Base64 format.
    /// </summary>
    /// <remarks>
    ///  Defaults to False.
    /// </remarks>
    property UrlSafe: Boolean read FUrlSafe write FUrlSafe;

    /// <summary>
    ///  Encrypts the given string.
    /// </summary>
    function EncryptString(const AStringToEncode: string; const AEncoding: TEncoding): string; overload;

    /// <summary>
    ///  Encrypts the given string. The string is supposed to be UTF-8 encoded.
    /// </summary>
    function EncryptString(const AStringToEncode: string): string; overload;

    /// <summary>
    ///  Decrypts the given string.
    /// </summary>
    function DecryptString(const AEncodedString: string; const AEncoding: TEncoding): string; overload;

    /// <summary>
    ///  Decrypts the given string. The string is supposed to be UTF-8 encoded.
    /// </summary>
    function DecryptString(const AEncodedString: string): string; overload;

    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///  The only purpose of this constructor is setting an empty GUID as key.
    /// </summary>
    class constructor Create;

    /// <summary>
    ///  Sets the encryption key. It must be invoked one single time for the
    ///  entire application run, before creating any instance of this class. The
    ///  standard way to invoking it is in the initialization section of the
    ///  UseAKLib unit.
    /// </summary>
    class procedure SetKey(const AString: string);
  end;

implementation

uses
  StrUtils, NetEncoding,
  SynCommons,
  AK.Utils;

{ TAKAESEncrypter }

class constructor TAKAESEncrypter.Create;
begin
  FKey := TGUID.Empty;
end;

constructor TAKAESEncrypter.Create;
var
  LKey: UTF8String;
  LSHA: TSHA256;
  LDigest: THash256;
begin
  if FKey = TGUID.Empty then
    raise AKException(EAKConfigError, 'Encryption key was not set.');
  inherited Create;
  LKey := StringToUTF8(SysUtils.GUIDToString(FKey));
  LSHA.Full(Pointer(LKey), Length(LKey), LDigest);
  FEngine := TAESCTR.Create(LDigest, 256);
  FillZero(LDigest);
  FRaiseErrors := True;
  FUrlSafe := False;
end;

function TAKAESEncrypter.DecryptString(const AEncodedString: string;
  const AEncoding: TEncoding): string;
var
  LEncodedString: string;
  LInput: TBytes;
  LOutput: TBytes;
begin
  LEncodedString := AEncodedString;
  if UrlSafe then
    FromUrlToBase64(LEncodedString);
  LInput := TNetEncoding.Base64.Decode(AEncoding.GetBytes(LEncodedString));
  LOutput := FEngine.DecryptPKCS7(LInput, True, RaiseErrors);
  if LOutput <> nil then
    Result := AEncoding.GetString(LOutput)
end;

function TAKAESEncrypter.DecryptString(const AEncodedString: string): string;
begin
  Result := DecryptString(AEncodedString, TEncoding.UTF8);
end;

destructor TAKAESEncrypter.Destroy;
begin
  FreeAndNil(FEngine);
  inherited;
end;

function TAKAESEncrypter.EncryptString(const AStringToEncode: string;
  const AEncoding: TEncoding): string;
var
  LInput: TBytes;
  LOutput: TBytes;
begin
  LInput := AEncoding.GetBytes(AStringToEncode);
  LOutput := FEngine.EncryptPKCS7(LInput, True);
  Result := AEncoding.GetString(TNetEncoding.Base64.Encode(LOutput));
  if UrlSafe then
    FromBase64ToUrl(Result);
end;

function TAKAESEncrypter.EncryptString(const AStringToEncode: string): string;
begin
  Result := EncryptString(AStringToEncode, TEncoding.UTF8);
end;

procedure TAKAESEncrypter.FromBase64ToUrl(var ABase64: string);
begin
  ChainReplace(ABase64, ['+', '/', sLineBreak], ['-', '_', ''], True);
end;

procedure TAKAESEncrypter.FromUrlToBase64(var ABase64Url: string);
begin
  ChainReplace(ABase64Url, ['-', '_'], ['+', '/'], True);
end;

class procedure TAKAESEncrypter.SetKey(const AString: string);
begin
  if FKey <> TGUID.Empty then
    raise EAKConfigError.Create(Self, 'A encryption key was already set.');
  FKey := TGUID.Create(AString);
end;

end.
