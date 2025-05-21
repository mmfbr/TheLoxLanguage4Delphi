program LoxIDE;

uses
  Vcl.Forms,
  LoxIDE.MainForm in 'LoxIDE.MainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
