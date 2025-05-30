unit FolderListenerFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Generics.Collections, System.Generics.Defaults, System.Rtti, System.Threading,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Grid.Style, FMX.ScrollBox, FMX.Grid, FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls,
  AK.FolderListener;

type
  TFileObserverFunc = reference to function (const AFileName: string; const AEvent: TAKFileEvent): string;

  TFolderListenerForm = class(TForm)
  strict private
    FRowCount: Integer;
    FGridResized: Boolean;
    FListener: TAKFolderListener;
    FFileObserverFunc: TFileObserverFunc;
    procedure ScrollGridIfNeeded(const AGrid: TStringGrid);
    procedure InitChangedFilesGrid;
    procedure AddAction(const AFileName, AEvent, AAction: string);
    procedure AddError(const AMessage: string);
    procedure StartMonitoring;
  public
    procedure PerformAction(const AFileName: string; const AEvent: TAKFileEvent);
    procedure Start(const AFolder: string; const AFunc: TFileObserverFunc);
    destructor Destroy; override;
  published
    Folder_Edit: TEdit;
    Folder_Label: TLabel;
    DateStamp_Edit: TEdit;
    DateStamp_Label: TLabel;
    ChangedFiles_StringGrid: TStringGrid;
    ChangedFilesName_StringColumn: TStringColumn;
    ChangedFilesEvent_StringColumn: TStringColumn;
    ChangedFilesAction_StringColumn: TStringColumn;
  end;

implementation

uses
  AK.Utils;

{$R *.fmx}

{ TFolderListenerForm }

procedure TFolderListenerForm.AddAction(const AFileName, AEvent, AAction: string);
begin
  Inc(FRowCount);
  ChangedFiles_StringGrid.RowCount := FRowCount;
  ChangedFiles_StringGrid.Cells[0, FRowCount - 1] := AFileName;
  ChangedFiles_StringGrid.Cells[1, FRowCount - 1] := AEvent;
  ChangedFiles_StringGrid.Cells[2, FRowCount - 1] := AAction;
  ScrollGridIfNeeded(ChangedFiles_StringGrid);
end;

procedure TFolderListenerForm.AddError(const AMessage: string);
begin
  AddAction('', Format('An error occurred: %s.', [AMessage]), '');
end;

destructor TFolderListenerForm.Destroy;
begin
  FreeAndNil(FListener);
  inherited;
end;

procedure TFolderListenerForm.InitChangedFilesGrid;
begin
  ChangedFilesName_StringColumn.Header := 'FILE';
  ChangedFilesEvent_StringColumn.Header := 'EVENT';
  ChangedFilesAction_StringColumn.Header := 'ACTION';
end;

procedure TFolderListenerForm.PerformAction(const AFileName: string; const AEvent: TAKFileEvent);
begin
  AddAction(AFileName, TAKEnum<TAKFileEvent>.Name(AEvent), FFileObserverFunc(AFileName, AEvent));
  DateStamp_Edit.Text := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now);
end;

procedure TFolderListenerForm.ScrollGridIfNeeded(const AGrid: TStringGrid);
begin
  if AGrid.VScrollBar.Visible then
  begin
    if not FGridResized then
    begin
      ChangedFilesName_StringColumn.Width := ChangedFilesName_StringColumn.Width - AGrid.VScrollBar.Width;
      FGridResized := True;
    end;
    AGrid.VScrollBar.Value := AGrid.VScrollBar.Max;
  end;
end;

procedure TFolderListenerForm.Start(const AFolder: string; const AFunc: TFileObserverFunc);
begin
  Assert(Assigned(AFunc));

  FFileObserverFunc := AFunc;
  FRowCount := 0;
  FGridResized := False;
  InitChangedFilesGrid;
  Folder_Edit.Text := AFolder;
  FListener := TAKFolderListener.Create(AFolder, PerformAction);
  FListener.OnException := procedure (const AException: Exception)
    begin
      AddError(AException.Message);
    end;
  StartMonitoring;
end;

procedure TFolderListenerForm.StartMonitoring;
begin
  FListener.Start;
end;

end.
