unit CadastroPacientes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ModeloCadastroPessoas, Grids, Buttons, StdCtrls, ExtCtrls, Dados;

type
  TfrmCadastroPacientes = class(TfrmModeloCadastroPessoas)
  private
    { Private declarations }
  protected
    function Pessoa: TPessoa; override;
  public
    { Public declarations }
  end;

var
  frmCadastroPacientes: TfrmCadastroPacientes;

implementation

{$R *.dfm}

{ TfrmCadastroPacientes }

function TfrmCadastroPacientes.Pessoa: TPessoa;
begin
  Result := Dados.paciente;
end;

end.
