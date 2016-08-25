{ *************************************************************************** }
{ }
{ }
{ }
{ Entity Framework for Delphi - version 1.24
  {     Código Original criado por: by Julio Cascalles - 2015/2016 - Brasil
  { }
{ }
{ *************************************************************************** }
{ }
{ Licensed under the Apache License, Version 2.0 (the "License"); }
{ you may not use this file except in compliance with the License. }
{ You may obtain a copy of the License at }
{ }
{ http://www.apache.org/licenses/LICENSE-2.0 }
{ }
{ Unless required by applicable law or agreed to in writing, software }
{ distributed under the License is distributed on an "AS IS" BASIS, }
{ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{ See the License for the specific language governing permissions and }
{ limitations under the License. }
{ }
{ *************************************************************************** }

{
  Alterações:

  Legendas:
  +  incluido novo....
  *  correção de funcionalidades
  -  retirado
  =  sem alterações significativas

  24/08/2016  =    por: Amarildo Lacerda
                   feito separação do codigo por UNIT para permitir acoplar
                   drivers de banco de dados diverentes na mesma estrutura;
                   não foi adicionado novo recurso (somente preparação)
              *    alterado o construtor

}

unit EntityObjects.ADO;

interface

uses
  Classes, SysUtils, DB, ADODB, EntityObjects.Base; {$DEFINE OLD_VERSION}
{$IFDEF OLD_VERSION}

type
  TEntityConnectionADO = class(TCustomEntityConnection)
  private
    FConnection: TADOConnection;
  protected
    procedure ClearDataSets;
    function AllTables: TStringList;
    function AllFields(const TableName: string): TStringList;
  public
   procedure Init;override;
   constructor Create();
    destructor Destroy; override;
    function ExecuteCommand(const command: string; openQuery: Boolean)
      : TDataSet; override;
    function GetList(Action: TConListAction; const Params: string = '')
      : TStringList; override;
    procedure SetConnectionString(const _ConnectionString: string); override;
  end;
{$ENDIF}

implementation

{$IFDEF OLD_VERSION}

const
  TemporaryTagID = 397;

function TEntityConnectionADO.AllFields(const TableName: string): TStringList;
begin
  with ExecuteCommand('SELECT * FROM ' + TableName + ' WHERE 1 = 0', true) do   { vale a pena repensar nesta where ... nao tenho sugestão no momento - amarildo lacerda}
  begin
    Tag := TemporaryTagID;
    Result := FieldDefList;
  end; // with
end;

{
   cuidado !!! o codigo que chamar esta function tem que controlar o FREE para não causar MemoryLeak (amarildo lacerda)
}
function TEntityConnectionADO.AllTables: TStringList;
begin
  Result := TStringList.Create;
  FConnection.GetTableNames(Result);
end;

procedure TEntityConnectionADO.ClearDataSets;
var
  i: integer;
  LTemp: TList;
  DataSet: TDataSet;
begin
  LTemp := TList.Create;
  try
    with FConnection do
      for i := 0 to DataSetCount - 1 do
      begin
        if DataSets[i].Tag = TemporaryTagID then
          LTemp.Add(DataSets[i]);
      end; // for
    while LTemp.Count > 0 do
    begin
      DataSet := TDataSet(LTemp[0]);
      DataSet.Free;
      LTemp.Delete(0);
    end; // while
  finally
    LTemp.Free;
  end;
end;


procedure TEntityConnectionADO.Init;
begin
end;

constructor TEntityConnectionADO.Create();
begin
  inherited Create;
  FConnection := TADOConnection.Create(nil);
end;

procedure TEntityConnectionADO.SetConnectionString
  (const _ConnectionString: string);
begin
  FConnection.Connected := false;
  FConnection.LoginPrompt := false;
  FConnection.ConnectionString := _ConnectionString;
end;

destructor TEntityConnectionADO.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TEntityConnectionADO.ExecuteCommand(const command: string;
  openQuery: Boolean): TDataSet;
begin
  Result := TADOQuery.Create(nil);
  with TADOQuery(Result) do
  begin
    AutoCalcFields := false;
    CursorType := ctStatic;
    LockType := ltReadOnly;
    EnableBCD := false;
    ParamCheck := false;
    Connection := Self.FConnection;
    MaxRecords := 200;
    SQL.Text := command;
{$IFDEF ENTITY_LOG_SQL}
    SaveLog(SQL);
{$ENDIF}
    if openQuery then
      Open
    else
      ExecSQL;
  end; // with
  if not openQuery then
    FreeAndNil(Result);    // cuidado... funcionamento hibrido da função...
end;

function TEntityConnectionADO.GetList(Action: TConListAction;
  const Params: string): TStringList;
begin
  Result := nil;
  case Action of
    claTables:
      Result := AllTables;
    claFields:
      Result := AllFields(Params);
    claClear:
      ClearDataSets;
  end; // case
end;

{$ENDIF}

end.
