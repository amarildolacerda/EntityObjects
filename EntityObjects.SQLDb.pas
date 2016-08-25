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
              *    Alterado o construtor
              *   removido memoryleaks
              +   incluido SetConnectionsString (interfaced)
}

unit EntityObjects.SQLDb;


interface

{$I EntityObjects.inc}

uses
  Classes, SysUtils, DB, EntityObjects.base
{$IFDEF FPC}, mysql50conn, mssqlconn, pqFConnection, oracleFConnection,
  IBFConnection, SQLDb{$ENDIF};

{$IFDEF FPC}

type
  TSqlDbType = (sdtSqlServer, sdtSybase, sdtPostGre, sdtMySql, sdtOracle,
    sdtFireBird, sdtUnknown);

  TEntityFConnectionSqlDb = class(TCustomEntityFConnection)
  private
    FConnection: TSQLFConnection;
    FTransaction: TSQLTransaction;
    function TypeOfDb(const Str: string): TSqlDbType;
  public
    constructor Create();
    destructor Destroy; override;
    function ExecuteCommand(const command: string; openQuery: Boolean)
      : TDataSet; override;
    function GetList(Action: TConListAction; const Params: string = '')
      : TStringList; override;
    procedure SetFConnectionString(const _FConnectionString: string); override;
  end;
{$ENDIF}

implementation

{$IFDEF FPC}

function TEntityFConnectionSqlDb.TypeOfDb(const Str: string): TSqlDbType;
const
  dbTypes: array [TSqlDbType] of string = ('SqlServer', 'Sybase', 'PostGre',
    'MySql', 'Oracle', 'FireBird', '');
begin
  for Result := sdtSqlServer to sdtFireBird do
  begin
    if SameText(Str, dbTypes[Result]) then
      Exit;
  end; // for
  Result := sdtUnknown;
end;

constructor TEntityFConnectionSqlDb.Create();
begin
  inherited Create;
end;

procedure TEntityFConnectionSqlDb.SetFConnectionString
  (const _FConnectionString: string);
var
  LTemp: TStringList;
begin
  LTemp := TStringList.Create;
  try
    LTemp.CommaText := _FConnectionString;
    case TypeOfDb(LTemp.Values['Type']) of
      sdtSqlServer:
        begin
          FConnection := TMsSqlFConnection.Create(nil);
          Settings.AutoIncType := aitSqlServer;
        end;
      sdtSybase:
        FConnection := TSybaseFConnection.Create(nil);
      sdtPostGre:
        FConnection := TPQFConnection.Create(nil);
      sdtMySql:
        begin
          FConnection := TMySQLFConnectionDef.FConnectionClass.Create(nil);
          TFConnectionName(FConnection).Port :=
            StrToIntDef(LTemp.Values['Port'], 3306);
          Settings.AutoIncType := aitMySql;
        end;
      sdtOracle:
        FConnection := TOracleFConnection.Create(nil);
      sdtFireBird:
        FConnection := TIBFConnection.Create(nil);
      sdtUnknown:
        raise Exception.Create('Unknown Database type');
    end;
    FConnection.HostName := LTemp.Values['Host'];
    FConnection.DatabaseName := LTemp.Values['Database'];
    FConnection.UserName := LTemp.Values['User'];
    FTransaction := TSQLTransaction.Create(nil);
    FTransaction.DataBase := FConnection;
  finally
    LTemp.Free;
  end;
end;

destructor TEntityFConnectionSqlDb.Destroy;
begin
  if assigned(FTransaction) then // precisa testar - é criado dinâmico
     FTransaction.Free;
  if assigned(FConnection) then
     FConnection.Free;
  inherited Destroy;
end;

{
   cuidado !!! o codigo que chamar esta function tem que controlar o FREE para não causar MemoryLeak (amarildo lacerda)
}
function TEntityFConnectionSqlDb.ExecuteCommand(const command: string;
  openQuery: Boolean): TDataSet;
begin
  Result := TSqlQuery.Create(nil);
  with TSqlQuery(Result) do
  begin
    ReadOnly := true;
    AutoCalcFields := false;
    ParamCheck := false;
    UniDirectional := true;
    DataBase := FConnection;
    Options := [sqoAutoCommit];
    FTransaction := self.Transaction;
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
    FreeAndNil(Result);   // Não é bom que a funcao tenha funciomento hibrido... deixa usuario confuso, já que o chamador dever fazer FREE (amarildo lacerda)
end;

{
   cuidado !!! o codigo que chamar esta function tem que controlar o FREE para não causar MemoryLeak (amarildo lacerda)
}
function TEntityFConnectionSqlDb.GetList(Action: TConListAction;
  const Params: string): TStringList;
begin
  Result := nil;
  if Action = claClear then
    Exit;
  Result := TStringList.Create;
  case Action of
    claTables:
      FConnection.GetTableNames(Result);
    claFields:
      FConnection.GetFieldNames(Params, Result);
  end;
end;
{$ENDIF}

end.
