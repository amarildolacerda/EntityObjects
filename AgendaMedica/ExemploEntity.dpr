program ExemploEntity;

uses
  Forms,
  {$ifdef FPC}
  Interfaces,
  {$endif}
  Dados in 'Dados.pas',
  ModeloCadastroPessoas in 'ModeloCadastroPessoas.pas' {frmModeloCadastroPessoas},
  CadastroMedicos in 'CadastroMedicos.pas' {frmCadastroMedicos},
  CadastroPacientes in 'CadastroPacientes.pas' {frmCadastroPacientes},
  Principal in 'Principal.pas' {frmPrincipal};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
