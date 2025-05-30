unit RepoTokenFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.StdCtrls, FMX.Controls.Presentation,
  AK.Base;

type
  TRepoTokenForm = class(TForm)
  strict private
    FOnSave: TAKStringProc;
  public
    procedure Show(const AOnSave: TAKStringProc; const AValue: string);
  published
    Save_Button: TButton;
    Cancel_Button: TButton;
    Token_Edit: TEdit;
    TogglePassword_Button: TButton;
    TokenLengthTitle_Label: TLabel;
    TokenLengthValue_Label: TLabel;
    procedure Token_EditTyping(Sender: TObject);
    procedure TogglePassword_ButtonClick(Sender: TObject);
    procedure Cancel_ButtonClick(Sender: TObject);
    procedure Save_ButtonClick(Sender: TObject);
  end;

implementation

{$R *.fmx}

{ TRepoTokenForm }

procedure TRepoTokenForm.Cancel_ButtonClick(Sender: TObject);
begin
  Hide;
end;

procedure TRepoTokenForm.Save_ButtonClick(Sender: TObject);
begin
  if Token_Edit.Text <> '' then
    FOnSave(Token_Edit.Text);
  Hide;
end;

procedure TRepoTokenForm.Show(const AOnSave: TAKStringProc; const AValue: string);
begin
  Assert(Assigned(AOnSave));

  FOnSave := AOnSave;
  Token_Edit.Password := True;
  Token_Edit.Text := AValue;
  TokenLengthValue_Label.Text := IntToStr(Length(AValue));
  inherited Show;
end;

procedure TRepoTokenForm.TogglePassword_ButtonClick(Sender: TObject);
begin
  Token_Edit.Password := not Token_Edit.Password;
end;

procedure TRepoTokenForm.Token_EditTyping(Sender: TObject);
begin
  TokenLengthValue_Label.Text := IntToStr(Length(Token_Edit.Text));
end;

end.
