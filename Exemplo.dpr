program Exemplo;

uses
  Vcl.Forms,
  uExemplo in 'uExemplo.pas' {Form9},
  EntityObjects.Firedac in 'EntityObjects.Firedac.pas',
  EntityObjects.Base in 'EntityObjects.Base.pas',
  EntityObjects.DbxExpress in 'EntityObjects.DbxExpress.pas',
  EntityObjects.ADO in 'EntityObjects.ADO.pas',
  EntityObjects.SQLDb in 'EntityObjects.SQLDb.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm9, Form9);
  Application.Run;
end.
