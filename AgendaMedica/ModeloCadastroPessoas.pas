unit ModeloCadastroPessoas;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, ExtCtrls,
  EntityObjects,EntityObjects.Base, Dados,
  ComCtrls, Buttons, DBGrids;

type
  TfrmModeloCadastroPessoas = class(TForm)
    pan_botoes: TPanel;
    btnNovo: TBitBtn;
    btnEdita: TBitBtn;
    btnApaga: TBitBtn;
    btnGrava: TBitBtn;
    btnCancela: TBitBtn;
    areaEdicao: TPanel;
    edtId: TEdit;
    lblId: TLabel;
    edtNome: TEdit;
    lblNome: TLabel;
    pan_Pesquisa: TPanel;
    btPesquisa: TSpeedButton;
    lbl_Pesquisa: TLabel;
    edtPesquisa: TEdit;
    grid: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure btnCancelaClick(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnGravaClick(Sender: TObject);
    procedure btnApagaClick(Sender: TObject);
    procedure btPesquisaClick(Sender: TObject);
    procedure gridDblClick(Sender: TObject);
    procedure edtPesquisaChange(Sender: TObject);
  private
    campos_lidos: integer;
    f_Editando, inclusao: Boolean;
    f_EditRetorno: TEdit;
    function PreencheGrid(Sender: TEntityField): Boolean;
    procedure SetEditando(const Value: Boolean);
    procedure CarregaCampos(com_dados: Boolean);
    function TemDados: Boolean;
    procedure AtualizaGrid;
    procedure setComponenteRetorno(const Value: TEdit);
  protected
    function Pessoa: TPessoa; virtual; abstract;
  public
    property ComponenteRetorno: TEdit read f_EditRetorno write setComponenteRetorno;
    property Editando: Boolean read f_Editando write SetEditando;
  end;


const
  cCOL_ID = 0;
  cCOL_NOME = 1;

  
implementation

{$R *.dfm}

procedure TfrmModeloCadastroPessoas.FormCreate(Sender: TObject);
begin
  grid.Rows[0].CommaText := 'id,Nome';
  SetEditando(false);
end;

function TfrmModeloCadastroPessoas.TemDados: Boolean;
begin
  Result := ( grid.Cells[cCOL_ID,grid.Row] <> '' ); 
end;

procedure TfrmModeloCadastroPessoas.SetEditando(const Value: Boolean);
begin
  f_Editando := Value;
  btnNovo.Enabled     := not f_Editando;
  btnEdita.Enabled    := not f_Editando AND TemDados;
  btnGrava.Enabled    := f_Editando;
  btnCancela.Enabled  := f_Editando;
  btnApaga.Enabled    := not f_Editando;
  grid.Enabled        := NOT f_Editando;
  edtNome.Enabled     := f_Editando;
end;

procedure TfrmModeloCadastroPessoas.btnCancelaClick(Sender: TObject);
begin
  Pessoa.Cancel;
  Editando := false;
end;

procedure TfrmModeloCadastroPessoas.btnNovoClick(Sender: TObject);
begin
  inclusao := (Sender = btnNovo);
  if inclusao then
    Pessoa.NewRecord
  else
    Pessoa.Edit( grid.Cells[cCOL_ID,grid.Row] );
    //Pessoa['id'].Value := grid.Cells[cCOL_ID,grid.Row];
  CarregaCampos(Sender = btnEdita);
  Editando := true;
  edtNome.SetFocus;
end;

procedure TfrmModeloCadastroPessoas.btnGravaClick(Sender: TObject);
begin
  Pessoa['nome'].Value := edtNome.Text;
  if Pessoa.SaveChanges then
    AtualizaGrid;
  Editando := false;
end;

procedure TfrmModeloCadastroPessoas.AtualizaGrid;
const
  aQtCampos: array[Boolean] of integer = (0,2);
begin
  if inclusao then
    begin
      campos_lidos := aQtCampos[TemDados];
      PreencheGrid(Pessoa['id']);
      PreencheGrid(Pessoa['nome']);
    end
  Else
    begin
      grid.Cells[cCOL_NOME,grid.Row] := Pessoa['nome'].AsString;
    end; // if..else
end;

procedure TfrmModeloCadastroPessoas.btnApagaClick(Sender: TObject);
var
  i: integer;
begin
  if (MessageBox(0, 'Deseja mesmo apagar o registro?', 'Confirmação', MB_ICONQUESTION or MB_YESNO) = idNO) then
    Exit;
  {}
  Pessoa['id'].Value := grid.Cells[cCOL_ID,grid.Row];
  Pessoa.Delete();
  for i := grid.Row to grid.RowCount-2 do
  begin
    grid.Rows[i].CommaText := grid.Rows[i+1].CommaText;
  end; // for
  grid.RowCount := grid.RowCount - 1;
end;

procedure TfrmModeloCadastroPessoas.btPesquisaClick(Sender: TObject);
begin
  grid.RowCount := 2;
  campos_lidos := 0;
  {$ifdef FPC}
  Pessoa.List(@PreencheGrid,'nome',edtPesquisa.Text,scContains);
  {$else}
  Pessoa.List(PreencheGrid,'nome',edtPesquisa.Text,scContains);
  {$endif}
  edtPesquisa.Text := '';
  btnEdita.Enabled := not f_Editando AND TemDados;
  grid.SetFocus;
end;

function TfrmModeloCadastroPessoas.PreencheGrid(Sender: TEntityField): Boolean;
var
  coluna, linha: integer;
begin
  Result := true;
  if SameText(Sender.Name,'nome') then
    coluna := cCOL_NOME
  else
    coluna := cCOL_ID;
  {}
  linha := grid.RowCount;
  if campos_lidos = 2 then
    begin
      grid.RowCount := grid.RowCount + 1;
      campos_lidos := 0;
    end
  else
    Dec(linha);
  grid.Cells[coluna,linha] := Sender.AsString;
  grid.Row := linha;
  Inc(campos_lidos);
end;

procedure TfrmModeloCadastroPessoas.CarregaCampos(com_dados: Boolean);
begin
  if com_dados then
    begin
      edtId.Text   := grid.Cells[cCOL_ID,grid.Row];
      edtNome.Text := grid.Cells[cCOL_NOME,grid.Row];
    end
  Else
    begin
      edtId.Text   := '';
      edtNome.Text := '';
    end; // if..else
end;

procedure TfrmModeloCadastroPessoas.gridDblClick(Sender: TObject);
begin
  if not TemDados then Exit;
  {}
  ModalResult := mrOK;
end;

procedure TfrmModeloCadastroPessoas.edtPesquisaChange(Sender: TObject);
begin
  btPesquisa.Enabled := (edtPesquisa.Text <> '');
end;

procedure TfrmModeloCadastroPessoas.setComponenteRetorno(
  const Value: TEdit);
begin
  f_EditRetorno := Value;
  f_EditRetorno.Tag := StrToIntDef(grid.Cells[cCOL_ID,grid.Row],0);
  f_EditRetorno.Text := grid.Cells[cCOL_NOME,grid.Row];
end;

end.
