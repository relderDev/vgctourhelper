program VGCTourHelperGUI;

uses
  FMX.Forms,
  MainFormUnit in '..\..\Source\FMX\MainFormUnit.pas' {MainForm},
  FolderListenerFormUnit in '..\..\Source\FMX\FolderListenerFormUnit.pas',
  ConfigFormUnit in '..\..\Source\FMX\ConfigFormUnit.pas',
  RepoTokenFormUnit in '..\..\Source\FMX\RepoTokenFormUnit.pas',
  Pokemon.Constants in '..\..\Source\Pokemon.Constants.pas',
  Pokemon.Context in '..\..\Source\Pokemon.Context.pas',
  Pokemon.Data in '..\..\Source\Pokemon.Data.pas',
  Pokemon in '..\..\Source\Pokemon.pas',
  UseAKLib in '..\..\Source\UseAKLib.pas',
  VGCPlayer in '..\..\Source\VGCPlayer.pas',
  VGCStreaming in '..\..\Source\VGCStreaming.pas',
  VGCTournament in '..\..\Source\VGCTournament.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
