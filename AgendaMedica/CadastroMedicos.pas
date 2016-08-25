unit CadastroMedicos;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ModeloCadastroPessoas, Grids, Buttons, StdCtrls, ExtCtrls, Dados;

type
  TfrmCadastroMedicos = class(TfrmModeloCadastroPessoas)
  private
    { Private declarations }
  protected
    function Pessoa: TPessoa; override;
  public
    { Public declarations }
  end;

var
  frmCadastroMedicos: TfrmCadastroMedicos;

implementation

{$R *.dfm}

{ TfrmCadastroMedicos }

function TfrmCadastroMedicos.Pessoa: TPessoa;
begin
  Result := Dados.medico;
end;

end.
