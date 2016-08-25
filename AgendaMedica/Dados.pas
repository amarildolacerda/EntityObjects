unit Dados;

interface


{$I EntityObjects.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes,
  EntityObjects, EntityObjects.base, {$ifdef FIREDAC}EntityObjects.Firedac,{$endif} DB;

type

  TPessoa = class(TEntity)
  public
    constructor Create; override;
  end;

  TMedico = class(TPessoa)
  public
    constructor Create; override;
  end;

  TPaciente = class(TPessoa)
  public
    constructor Create; override;
  end;

  { TAgenda }

  TAgenda = class(TEntity)
  private
    fData,fHora: TEntityField;
  public
    property data: TEntityField read fData;
    property hora: TEntityField read fHora;
    constructor Create; override;
  end;

var
  agenda: TAgenda;
  medico,paciente: TPessoa;


implementation


{ TVeiculo }


{ TPessoa }

constructor TPessoa.Create;
begin
  inherited;
  AddField('id',ftInteger,true)
  .Attribute := 'AUTO_INCREMENT'; { <<----  Somente para MySql !!!
                                    (Para MS Sql Server, use IDENTITY(1,1)
                                    e para outros bancos use trigger
                                    ou o evento BeforeInsert do TEntity
  }
  AddField('nome',ftString,false,30).Attribute := 'UNIQUE NOT NULL';
end;

{ TMedico }

constructor TMedico.Create;
begin
  inherited; // ver TPessoa
  TableName := 'Medico';
end;

{ TPaciente }

constructor TPaciente.Create;
begin
  inherited; // ver TPessoa
  TableName := 'Paciente';
end;

{ TAgenda }

constructor TAgenda.Create;
begin
  inherited;
  TableName := 'Agenda';
  fData := AddField('data',ftDate);
  fHora := AddField('hora',ftString,false,5);
  {--- Relacionamentos com outras tabelas: ---}
  if medico = nil then
  begin
    medico := TMedico.Create;
    medico.EntityConnection := self.EntityConnection;
  end;
  AddField('medico',ftInteger).ForeignEntity := medico;
  if paciente = nil then
  begin
    paciente := TPaciente.Create;
    paciente.EntityConnection := self.EntityConnection;
  end;
  AddField('paciente',ftInteger).ForeignEntity := paciente;
end;

end.
