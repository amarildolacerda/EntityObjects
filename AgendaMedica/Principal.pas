unit Principal;

interface

{$I EntityObjects.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons,
{$IFDEF FPC}
  Calendar,
{$ENDIF}
  Dados, EntityObjects, EntityObjects.Base, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  FireDAC.Stan.Intf, FireDAC.Phys, FireDAC.Phys.SQLite;

{$DEFINE CONEXAO_BD_ADO}

type

  { TfrmPrincipal }

  TfrmPrincipal = class(TForm)
    lblMedico: TLabel;
    lblPaciente: TLabel;
    edtMedico: TEdit;
    edtPaciente: TEdit;
    cbxHorario: TComboBox;
    lblHorario: TLabel;
    btGravar: TButton;
    btVerificar: TButton;
    lbl_Disponivel: TLabel;
    cbxMarcados: TComboBox;
    Label1: TLabel;
    btnFiltraMedico: TSpeedButton;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    procedure lblMedicoClick(Sender: TObject);
    procedure lblPacienteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btGravarClick(Sender: TObject);
    procedure btVerificarClick(Sender: TObject);
    procedure calDataClick(Sender: TObject);
    procedure exibeConsultaAgendada(Sender: TObject);
  private
    procedure criaCalendario();
    function verificaHorario(Sender: TEntityField): Boolean;
    procedure preencheTodosHorarios;
    function TudoOK: Boolean;
  public
{$IFDEF FPC}
    calData: TCalendar;
{$ELSE}
    calData: TMonthCalendar;
{$ENDIF}
    function DataSelecionada: TDateTime;
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses {$IFDEF FIREDAC} EntityObjects.Firedac, {$ELSE}
{$IFDEF FPC} EntityObjects.SQLDb, {$ELSE}
{$IFDEF CONEXAO_BD_ADO}
  EntityObjects.ADO,
{$ELSE}
  EntityObjects.DbxExpress,
{$ENDIF}{$ENDIF}{$ENDIF} CadastroMedicos, CadastroPacientes;

{$R *.dfm}

procedure TfrmPrincipal.criaCalendario();
begin
{$IFDEF FPC}
  calData := TCalendar.Create(self);
  calData.onClick := @calDataClick;
  calData.DateTime := Now;
{$ELSE}
  calData := TMonthCalendar.Create(self);
  calData.onClick := calDataClick;
  calData.Date := Now;
{$ENDIF}
  calData.Parent := self;
  calData.Left := 16;
  calData.Top := 16;
  calData.Height := 161;
  calData.Width := 176;
  calData.TabOrder := 0;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
{$IFDEF FIREDAC}
  agenda := TAgenda.Create(TEntityConnectionFiredac);
{$ELSE}
{$IFDEF FPC}
  agenda := TAgenda.Create(TEntityFConnectionSqlDb);
{$ELSE}
{$IFDEF CONEXAO_BD_ADO}
  agenda := TAgenda.Create(TEntityConnectionADO);
{$ELSE}
  agenda := TAgenda.Create(TEntityConnectionDbExpress);
{$ENDIF}
{$ENDIF}
{$ENDIF}

  { ******************************************
    ATENÇÃO:
    ---------------------------------------
    A partir da versão 1.24 do EntityObjects,
    Você receberá a mensagem de "deprecated"
    para a conexão por string.

    Em vez disso, você pode criar sua própria classe de conexão,
    conforme exemplo abaixo:

    agenda.EntityConnection := TMinhaClasseDeConexao.Create(...)
    ¨^^^^^^^^^^^^^^^

    Recomenda-se NÃO DESTRUÍ-LA!!!
    ****************************************** }

{$IFDEF FIREDAC}
  agenda.setConnectionString
    ('DriverID=SQLITE,ServerName=localhost,Database=agenda.sqlite,user_name=MeuUsuario,password=123');
{$ELSE}
{$IFDEF FPC}
  // Conexão para mySql com Lazarus...
  agenda.setConnectionString
    ('type=MySql,Host=localhost,User=root,Database=agenda');
{$ELSE}
{$IFDEF CONEXAO_BD_ADO}
  // Conexão ADO (Definida no início deste arquivo:)
  agenda.setConnectionString
    ('Provider=MSDASQL.1;Persist Security Info=False;Data Source=ODBC_agenda');
{$ELSE}
  // Conexão DbExpress para Delphi XE...
  agenda.setConnectionString
    ('DriverName=Firebird,Database=c:\temp\AGENDA.FDB,User_Name=sysdba,Password=123');
{$ENDIF}
{$ENDIF}
{$ENDIF}
  agenda.DatabaseScript(true); // Cria as tabelas, se necessário
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  Caption := 'Exemplo de Agenda medica - usando EntityObjects para ' +
    cIDE_VERSION;
  criaCalendario();
end;

procedure TfrmPrincipal.lblMedicoClick(Sender: TObject);
begin
  frmCadastroMedicos := TfrmCadastroMedicos.Create(self);
  if frmCadastroMedicos.ShowModal = mrOK then
  begin
    frmCadastroMedicos.ComponenteRetorno := edtMedico;
  end;
  frmCadastroMedicos.Free;
end;

procedure TfrmPrincipal.lblPacienteClick(Sender: TObject);
begin
  frmCadastroPacientes := TfrmCadastroPacientes.Create(self);
  if frmCadastroPacientes.ShowModal = mrOK then
  begin
    frmCadastroPacientes.ComponenteRetorno := edtPaciente;
  end;
  frmCadastroPacientes.Free;
end;

procedure TfrmPrincipal.preencheTodosHorarios;
begin
  cbxHorario.Items.CommaText :=
    '08:00,08:30,09:00,09:30,10:00,10:30,11:00,11:30' +
    ',13:00,13:30,14:00,14:30,15:00,15:30,16:00,16:30,17:00,17:30,18:00,18:30';
  cbxMarcados.Items.Clear;
end;

function TfrmPrincipal.verificaHorario(Sender: TEntityField): Boolean;
var
  idx_hora: integer;
begin
  Result := true;
  idx_hora := cbxHorario.Items.IndexOf(Sender.AsString);
  { ---- Se o horário já existe, remove do ComboBox --- }
  if idx_hora > -1 then
  begin
    cbxHorario.Items.Delete(idx_hora);
  end;
  { --------------------------------------------------- }
  cbxMarcados.Items.Add(Sender.AsString);
end;

function TfrmPrincipal.TudoOK: Boolean;
begin
  Result := false;
  if cbxHorario.ItemIndex = -1 then
  begin
    MessageBox(0, 'Selecione um Horário!', 'Aviso', MB_ICONWARNING or MB_OK);
    Exit;
  end;
  if edtMedico.Text = '' then
  begin
    MessageBox(0, 'Selecione um Médico!', 'Aviso', MB_ICONWARNING or MB_OK);
    Exit;
  end;
  if edtPaciente.Text = '' then
  begin
    MessageBox(0, 'Selecione um Paciente!', 'Aviso', MB_ICONWARNING or MB_OK);
    Exit;
  end;
  Result := true;
end;

procedure TfrmPrincipal.btGravarClick(Sender: TObject);
begin
  if not TudoOK then
    Exit;
  { ---- Grava o registro na Agenda médica: ---- }
  agenda.NewRecord;
  agenda['data'].Value := DataSelecionada;
  agenda['hora'].Value := cbxHorario.Text;
  agenda['medico'].Value := edtMedico.Tag;
  agenda['paciente'].Value := edtPaciente.Tag;
  if not agenda.SaveChanges then
    Exit;
  verificaHorario(agenda['hora']);
  cbxHorario.Enabled := false;
  cbxMarcados.Enabled := false;
  { -------------------------------------------- }
  MessageBox(0, 'Registro gravado com sucesso!', 'Sucesso',
    MB_ICONINFORMATION or MB_OK);
end;

procedure TfrmPrincipal.btVerificarClick(Sender: TObject);
begin
  preencheTodosHorarios();
  if agenda.Find(DataSelecionada, 'data', true) then
{$IFDEF FPC}
    agenda.List('hora', @verificaHorario);
{$ELSE}
    agenda.List('hora', verificaHorario);
{$ENDIF}
  cbxHorario.Enabled := true;
  cbxHorario.SetFocus;
  cbxHorario.DroppedDown := true;
  cbxMarcados.Enabled := true;
end;

procedure TfrmPrincipal.calDataClick(Sender: TObject);
begin
  cbxHorario.Enabled := false;
  cbxMarcados.Enabled := false;
end;

procedure TfrmPrincipal.exibeConsultaAgendada(Sender: TObject);
begin
  { ***--- Sintaxe de consulta parecida com LINQ ----- }
  with agenda do
    Where([data.Equals(DataSelecionada), hora.Equals(cbxMarcados.Text)]
      ).Select();
  { -----------------------------------------------*** }
  edtMedico.Text := medico['nome'].AsString;
  edtPaciente.Text := paciente['nome'].AsString;
end;

function TfrmPrincipal.DataSelecionada: TDateTime;
begin
{$IFDEF FPC}
  Result := calData.DateTime;
{$ELSE}
  Result := calData.Date;
{$ENDIF}
end;

end.
