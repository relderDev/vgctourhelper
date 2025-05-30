unit AK.Indy;

{$I AK.Defines.inc}

interface

uses
  SysUtils, Classes, IdHttp {$IFNDEF UNICODE}, IdGlobal{$ENDIF},
  AK.Base;

type
  TAKHttpMethod = (hmGet, hmPost, hmPut, hmDelete, hmHead, hmPatch, hmConnect, hmOptions, hmTrace);

  /// <summary>
  ///  Small subclass that always uses SSL and provides the DoRequest public
  ///  method to easily manage requests with body and ignored responses. Utility
  ///  properties BeforeRequest and AfterRequest (when assigned) are invoked on
  ///  each request with the http method string as the only argument.
  /// </summary>
  /// <remarks>
  ///  This class sets the HandleRedirects property as True by default.
  /// </remarks>
  TAKIndyHttp = class(TIdHttp)
  strict private
    FBeforeRequest: TAKStringProc;
    FAfterRequest: TAKStringProc;
  strict protected
    procedure DoRequest(const AMethod: TIdHTTPMethod; AURL: string;
      ASource, AResponseContent: TStream; AIgnoreReplies: array of Int16); overload; override;
  public
    property BeforeRequest: TAKStringProc write FBeforeRequest;
    property AfterRequest: TAKStringProc write FAfterRequest;

    function DoRequest(const AMethod: TAKHttpMethod; const AUrl: string;
      const ASource: TStream; const AIgnoreReplies: array of Int16
      {$IFNDEF UNICODE}; ADestEncoding: IIdTextEncoding = nil{$ENDIF}): string; reintroduce; overload;

    constructor Create(AOwner: TComponent);
  end;

  /// <summary>Shell class to cast TIdEncoderMIME to RTL types.</summary>
  TAKIndyEncoderMIME = class
  public
    class function EncodeBytes(const ABytes: TBytes): string;
    class function EncodeString(const AString: string): string;
    class function DecodeBytes(const AString: string): TBytes;
    class function DecodeString(const AString: string): string;
  end;

implementation

uses
  IdSSLOpenSSL, IdGlobalProtocols, IdCoderMIME {$IFDEF UNICODE}, IdGlobal{$ENDIF},
  AK.Utils;

{ TAKIndyHttp }

constructor TAKIndyHttp.Create(AOwner: TComponent);
var
  LHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  inherited;
  LHandler := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
  LHandler.SSLOptions.SSLVersions := [sslvTLSv1,sslvTLSv1_1,sslvTLSv1_2];
  IOHandler := LHandler;
  HandleRedirects := True;
end;

procedure TAKIndyHttp.DoRequest(const AMethod: TIdHTTPMethod; AURL: string;
  ASource, AResponseContent: TStream; AIgnoreReplies: array of Int16);
begin
  if Assigned(FBeforeRequest) then
    FBeforeRequest(AMethod);
  inherited;
  if Assigned(FAfterRequest) then
    FAfterRequest(AMethod);
end;

function TAKIndyHttp.DoRequest(const AMethod: TAKHttpMethod; const AUrl: string;
  const ASource: TStream; const AIgnoreReplies: array of Int16
  {$IFNDEF UNICODE}; ADestEncoding: IIdTextEncoding{$ENDIF}): string;
var
  LMethod: TIdHTTPMethod;
  LStream: TMemoryStream;
begin
  LMethod := UpperCase(TAKEnum<TAKHttpMethod>.Name(AMethod));
  LStream := TMemoryStream.Create;
  try
    DoRequest(LMethod, AUrl, ASource, LStream, AIgnoreReplies);
    LStream.Position := 0;
    Result := ReadStringAsCharset(LStream, Response.CharSet{$IFNDEF UNICODE}, ADestEncoding{$ENDIF});
  finally
    FreeAndNil(LStream);
  end;
end;

{ TAKIndyEncoderMIME }

class function TAKIndyEncoderMIME.DecodeBytes(const AString: string): TBytes;
begin
  Result := TBytes(TIdDecoderMIME.DecodeBytes(AString));
end;

class function TAKIndyEncoderMIME.DecodeString(const AString: string): string;
begin
  Result := TIdDecoderMIME.DecodeString(AString);
end;

class function TAKIndyEncoderMIME.EncodeBytes(const ABytes: TBytes): string;
begin
  Result := TIdEncoderMIME.EncodeBytes(TIdBytes(ABytes));
end;

class function TAKIndyEncoderMIME.EncodeString(const AString: string): string;
begin
  Result := TIdEncoderMIME.EncodeString(AString);
end;

end.
