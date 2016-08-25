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

}

unit EntityObjects.DbxExpress;

interface

{$I EntityObjects.inc}

uses
  Classes, SysUtils, DB, EntityObjects.Base, Data.SqlExpr,
  Data.DBXFirebird, Data.DbxMySql, Data.DbxMSSQL, Data.DbxOracle;

{$IFDEF DELPHI_XE_SUP}

type
  { DONE -c1.23 : Connection for Delphi XE... }
  TEntityConnectionDbExpress = class(TCustomEntityConnection)
  private
    FConnection: TSQLConnection;
    function AllFields(const TableName: string): TStringList;
    procedure ClearDataSets;
  public
    procedure Init; override;
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

{ TEntityConnectionDbExpress }
{$IFDEF DELPHI_XE_SUP}

const
  TemporaryTagID = 397;

procedure TEntityConnectionDbExpress.Init;
begin

end;

constructor TEntityConnectionDbExpress.Create();
begin
  inherited Create;
  FConnection := TSQLConnection.Create(nil);
end;

procedure TEntityConnectionDbExpress.SetConnectionString
  (const _ConnectionString: string);
var
  LTemp: TStringList;
begin
  LTemp := TStringList.Create;
  try
    LTemp.CommaText := _ConnectionString;
    FConnection.Connected := false;
    FConnection.DriverName := LTemp.Values['DriverName'];
    FConnection.Params.Values['DriverName'] := LTemp.Values['DriverName'];
    FConnection.Params.Values['Database'] := LTemp.Values['Database'];
    FConnection.Params.Values['User_Name'] := LTemp.Values['User_Name'];
    FConnection.Params.Values['Password'] := LTemp.Values['Password'];
    FConnection.LoginPrompt := false;
    FConnection.Connected := true;
  finally
    LTemp.Free;
  end;
end;

destructor TEntityConnectionDbExpress.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TEntityConnectionDbExpress.ExecuteCommand(const command: string;
  openQuery: Boolean): TDataSet;
begin
  Result := TSqlQuery.Create(nil);
  with TSqlQuery(Result) do
  begin
    AutoCalcFields := false;
    ParamCheck := false;
    SQLConnection := Self.FConnection;
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
    FreeAndNil(Result); { Cuidado ... funcionamento hibrido da função }
end;

function TEntityConnectionDbExpress.AllFields(const TableName: string)
  : TStringList;
begin
  with ExecuteCommand('SELECT * FROM ' + TableName + ' WHERE 1 = 0', true)
    do { nao é bom esta where   1=0 - sem sugestao ainda }
  begin
    Tag := TemporaryTagID;
    Result := FieldDefList;
  end; // with
end;

procedure TEntityConnectionDbExpress.ClearDataSets;
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

function TEntityConnectionDbExpress.GetList(Action: TConListAction;
  const Params: string): TStringList;
begin
  Result := nil;
  case Action of
    claClear:
      ClearDataSets;
    claTables:
      begin
        Result := TStringList.Create;
        FConnection.GetTableNames(Result);
      end;
    claFields: // Connection.GetFieldNames(Params,Result);
      Result := AllFields(Params);
  end;
end;
{$ENDIF}

end.
