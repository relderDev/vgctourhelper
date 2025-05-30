unit UseAKLib;

interface

implementation

uses
  AK.Crypt;

initialization
  // The encryption key should be a GUID in the form '{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}'
  TAKAESEncrypter.SetKey('Write your GUID key here!');

end.
