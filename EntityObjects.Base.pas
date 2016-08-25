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


}

unit EntityObjects.Base;

interface

{$I EntityObjects.inc}

uses Classes, Sysutils, DB;

const
{$IFDEF FPC}
  cIDE_VERSION = 'Lazarus';
{$ELSE}
{$IFDEF DELPHI_XE_SUP}
  cIDE_VERSION = 'Delphi XE...';
{$ELSE}
  cIDE_VERSION = 'Delphi 5, 6, 7...';
{$ENDIF}
{$ENDIF}

type

  TSearchCompare = (scGreater, scLess, scContains, scEquals);
  TLogicalOperator = (_AND_, _OR_);

  TAutoIncrementType = (aitNone, aitMySql, aitSqlServer);
  TConListAction = (claTables, claFields, claClear);

  TEntitySettings = class
    JoinTables: Boolean;
    DateFormat, FloatFormat, StartLikeExpr, EndLikeExpr: string;
    AutoIncType: TAutoIncrementType;
  end;

  IEntityConnection = interface
    ['{554FCF89-B973-44D4-B462-43EE435CD9F4}']
    function Settings: TEntitySettings;
    function ExecuteCommand(const command: string; openQuery: Boolean)
      : TDataSet;
    function GetList(Action: TConListAction; const Params: string = '')
      : TStringList;
    procedure SetConnectionString(const _ConnectionString: string);
  end;

  TCommaTextOptions = set of (ctoNames, ctoValues);
  TEntityState = (estReady, estLoading, estEditing);

  { TCustomEntityConnection }
  TCustomEntityConnection = class(TInterfacedObject, IEntityConnection)
  private
    f_Settings: TEntitySettings;
{$IFDEF ENTITY_LOG_SQL}
    Log_id: integer;
    procedure SaveLog(Strings: TStrings);
{$ENDIF}
  public
    constructor create;
    destructor destroy; override;
    function Settings: TEntitySettings; virtual;
    function ExecuteCommand(const command: string; openQuery: Boolean)
      : TDataSet; virtual; abstract;
    function GetList(Action: TConListAction; const Params: string = '')
      : TStringList; virtual; abstract;
    procedure SetConnectionString(const _ConnectionString: string);
      virtual; abstract;
  end;

implementation

{$IFDEF ENTITY_LOG_SQL}

procedure TCustomEntityConnection.SaveLog(Strings: TStrings);
var
  LogFile: string;
begin
  Inc(Log_id);
  LogFile := '.\' + FormatDateTime('yyyyddmmhhnn', Now) + '_' +
    Copy(Strings.Text, 1, 3) + '_' + IntToStr(Log_id) + '.sql';
  Strings.SaveToFile(LogFile);
end;
{$ENDIF}

constructor TCustomEntityConnection.create;
begin
  inherited;
  f_Settings := TEntitySettings.create;
  with f_Settings do
  begin
    JoinTables := false;
    DateFormat := 'yyyy/mm/dd';
    FloatFormat := '###0.00';
    StartLikeExpr := '%';
    EndLikeExpr := '%';
    AutoIncType := aitNone;
  end; // with

end;

destructor TCustomEntityConnection.destroy;
begin
  f_Settings.Free;
  inherited;
end;

function TCustomEntityConnection.Settings: TEntitySettings;
begin
  Result := f_Settings;
end;

end.
