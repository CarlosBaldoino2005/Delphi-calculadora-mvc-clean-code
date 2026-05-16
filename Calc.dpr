program Calc;

uses
  Vcl.Forms,
  Calculadora in 'Calculadora.pas' {frmCalculadora},
  uCalcController in 'uCalcController.pas',
  uCalcModel in 'uCalcModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmCalculadora, frmCalculadora);
  Application.Run;
end.
