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
                   Novo codigo
              *    Alterado o Constructor
}

unit EntityObjects.Firedac;

interface

{$I EntityObjects.inc}

uses
  System.Classes, System.SysUtils, Data.DB, EntityObjects.Base
{$IFDEF FIREDAC}
    , Firedac.Stan.Intf, Firedac.Stan.Option,
  Firedac.Stan.Param, Firedac.Stan.Error, Firedac.DatS, Firedac.Phys.Intf,
  Firedac.DApt.Intf, Firedac.Stan.Async, Firedac.DApt, Firedac.UI.Intf,
  Firedac.Stan.Def, Firedac.Stan.Pool, Firedac.Phys, Firedac.VCLUI.Wait,
  Firedac.Comp.Client, Firedac.Comp.DataSet
{$ENDIF};

{$ifdef FIREDAC}
type
  TEntityConnectionFiredac = class(TCustomEntityConnection)
  private
    FConnection: TFDConnection;
    function AllFields(const TableName: string): TStringList;
    procedure ClearDataSets;
  public
    procedure Init;override;
    constructor Create;override;
    destructor Destroy; override;
    function ExecuteCommand(const ACommand: string; openQuery: Boolean)
      : TDataSet; override;
    function GetList(Action: TConListAction; const Params: string = '')
      : TStringList; override;
    procedure SetConnectionString(const _ConnectionString: string); override;
  end;
{$endif}

implementation

{$IFDEF FIREDAC}

const
  TemporaryTagID = 397;

  { TEntityConnectionFiredac }

constructor TEntityConnectionFiredac.Create();
begin
  inherited Create;
  FConnection := TFDConnection.Create(nil);
end;

procedure TEntityConnectionFiredac.SetConnectionString
  (const _ConnectionString: string);
var
  LTemp: TStringList;
begin // fireTables
  LTemp := TStringList.Create;
  try
    FConnection.Connected := false;
    LTemp.CommaText := _ConnectionString;
    FConnection.Params.Assign(LTemp);
    FConnection.LoginPrompt := false;
    FConnection.Connected := true;
  finally
    LTemp.Free;
  end;

end;

destructor TEntityConnectionFiredac.Destroy;
begin
  FConnection.Free;
  inherited;
end;

function TEntityConnectionFiredac.ExecuteCommand(const ACommand: string;
  openQuery: Boolean): TDataSet;
begin
  Result := TFDQuery.Create(nil);
  with TFDQuery(Result) do
  begin
    AutoCalcFields := false;
    ResourceOptions.ParamExpand := false;
    ResourceOptions.ParamCreate := false;
    Connection := self.FConnection;
    TFDQuery(Result).SQL.Text := ACommand;
{$IFDEF ENTITY_LOG_SQL}
    SaveLog(SQL);
{$ENDIF}
    if openQuery then
      Open
    else
      ExecSQL;
  end; // with
  if not openQuery then
    FreeAndNil(Result); // Cuidado !!! funcionamento hibrido da função
end;

function TEntityConnectionFiredac.AllFields(const TableName: string)
  : TStringList;
begin
  with ExecuteCommand('SELECT * FROM ' + TableName + ' WHERE 1 = 0', true) do   { repensar em mudar a where  1=0  não é bom para o banco de dados }
  begin
    Tag := TemporaryTagID;
    Result := FieldDefList;
  end; // with
end;

procedure TEntityConnectionFiredac.ClearDataSets;
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

function TEntityConnectionFiredac.GetList(Action: TConListAction;
  const Params: string): TStringList;
begin
  Result := nil;
  case Action of
    claClear:
      ClearDataSets;
    claTables:
      begin
        Result := TStringList.Create;
        FConnection.GetTableNames('', '', '', Result);
      end;
    claFields: // Connection.GetFieldNames(Params,Result);
      Result := AllFields(Params);
  end;
end;


{ TEntityConnectionFiredac }

procedure TEntityConnectionFiredac.init;
begin
end;

{$endif}
end.
