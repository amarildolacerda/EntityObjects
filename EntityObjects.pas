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

unit EntityObjects;

interface

{$I EntityObjects.inc}

uses
  Windows, Messages, SysUtils,
  EntityObjects.Base,
{$IFNDEF VER130}
  Variants,
{$ENDIF}
  Classes, TypInfo,
  DB;

type

  TEntity = class;

  TConditionList = class;

  TConditionItem = class
  private
    fOwner: TConditionList;
    procedure SetOwner(const Value: TConditionList);
  protected
    property Owner: TConditionList read fOwner write SetOwner;
    function LOName: string;
  public
    prefix, separator, suffix: string;
    LogicalOperator: TLogicalOperator;
    property FieldName: string read prefix write prefix;
    property ConditionValue: string read suffix write suffix;
    function Expression: string; virtual;
  end;

  TConditionList = class(TConditionItem)
  private
    fList: TList;
    function getItem(Index: integer): TConditionItem;
    function getCount: integer;
  protected
    Parent: TEntity;
    function Where(conditions: array of TConditionItem;
      op: TLogicalOperator = _AND_): TConditionList;
  public
    property Item[Index: integer]: TConditionItem read getItem; default;
    property Count: integer read getCount;
    function Add(Value: TSearchCompare): TConditionItem; overload;
    procedure Add(_item: TConditionItem); overload;
    function Remove(_item: TConditionItem): Boolean;
    function Expression: string; override;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function _OR(conditions: array of TConditionItem;
      op: TLogicalOperator = _AND_): TConditionList;
    function _AND(conditions: array of TConditionItem;
      op: TLogicalOperator = _AND_): TConditionList;
    procedure Select;
  end;

  TFieldAttribute = (faNotNull, faAutoIncrement, faUnique, faPrimarykey);
  TFieldAttributes = set of TFieldAttribute;

  TEntityField = class
  private
    fParent: TEntity;
    FName: string;
    FFieldType: TFieldType;
    fForeignEntity: TEntity;
    FSize: integer;
    FieldAttributes: TFieldAttributes;
    procedure SetFieldType(const _Value: TFieldType);
    procedure SetName(const _Value: string);
    procedure SetForeignEntity(const _Value: TEntity);
    procedure SetSize(const _Value: integer);
    procedure SetAttribute(const _Value: string);
    function getAttribute: string;
    function NewCondition(SearchCompare: TSearchCompare): TConditionItem;
    procedure SetAutoInc(_Value: Boolean);
    function getAutoInc: Boolean;
  protected
    FValue: Variant;
    isModified: Boolean;
    procedure SetValue(const _Value: Variant); virtual;
    function getValue: Variant; virtual;
  public
    ignore: Boolean;
    property ForeignEntity: TEntity read fForeignEntity write SetForeignEntity;
    property Value: Variant read getValue write SetValue;
    property Name: string read FName write SetName;
    property FieldType: TFieldType read FFieldType write SetFieldType;
    property Size: integer read FSize write SetSize;
    property Parent: TEntity read fParent;
    property isAutoInc: Boolean read getAutoInc write SetAutoInc;
    { DONE -c1.06 : Auto increment control }
    property Attribute: string read getAttribute write SetAttribute;
    function AsInteger: integer;
    function AsFloat: Double;
    function AsDate: TDateTime;
    function AsString: string;
    function SqlFormat: string;
    constructor Create(_Parent: TEntity);
    { }
    function Greater(Search: Variant): TConditionItem;
    function Less(Search: Variant): TConditionItem;
    function Contains(Search: Variant): TConditionItem;
    function Equals(Search: Variant): TConditionItem;
    {$IFDEF EQUALS_EXISTS} overload; {$ENDIF}
  end;

  TEntityEvent = function(Sender: TEntityField): Boolean of object;

  TEntity = class
  private
    FItems, FRelations: TList;
    FPrimaryKey: TEntityField;
    isNewRecord, keepDataSet: Boolean;
    FTableName: string;
    FState: TEntityState;
    F_IsEmpty, FCreated: Boolean;
    FConditionList: TConditionList;
    FEntityConnection: IEntityConnection;
    { DONE -c1.1 : Allow to use many connections }
    AutoIncType: TAutoIncrementType;
    procedure SetPrimaryKey(const _Value: TEntityField);
    function getPrimaryKey: TEntityField;
    function NothingToDo: Boolean;
    procedure SetTableName(const _Value: string);
    function getTableName: string;
    function getPKValueFromDB: Variant;
    function Clone: TEntity;
    procedure SetEntityConnection(const Value: IEntityConnection);
  protected
    needReload: Boolean;
    function GetCount: integer;
    function GetItem(const Index: integer): TEntityField;
    function GetField(const Name: string): TEntityField;
    function CommaText(options: TCommaTextOptions;
      ignorePK: Boolean = true): string;
    function IndexOf(const Search: string): integer;
    procedure AddRelation(field: TEntityField);
    procedure CheckConnection;
    function SetFieldsValues(Source: TDataSet = nil): Boolean;
    procedure LoadFromTable; virtual;
    procedure FillSqlElements(var sSELECT, sFROM, sWHERE: string); virtual;
    procedure SetReady(all: Boolean = false);
    function SelectCommand: string;
  public
    DataSet: TDataSet;
    BeforeInsert, OnList: TEntityEvent;
    property IsEmpty: Boolean read F_IsEmpty;
    property TableName: string read getTableName write SetTableName;
    property PrimaryKey: TEntityField read getPrimaryKey write SetPrimaryKey;
    property Field[const Name: string]: TEntityField read getField; default;
    property State: TEntityState read FState;
    property ConditionList: TConditionList read FConditionList;
    property Created: Boolean read FCreated;
    property EntityConnection: IEntityConnection read FEntityConnection
      write SetEntityConnection;
    constructor Create; overload; virtual;
    destructor Destroy; override;
    function AddField(const Name: string; FieldType: TFieldType;
      isPrimaryKey: Boolean = false; Size: integer = 0): TEntityField;
    procedure Assign(obj: TPersistent; const keyField: string = '');
    procedure NewRecord;
    procedure Edit(const keyValue: string = '');
    procedure Cancel;
    function SaveChanges: Boolean; virtual;
    procedure ClearFields;
    function DatabaseScript(run: Boolean; tables: TStrings = nil): string;
    procedure Delete(_field: TEntityField = nil);
    procedure List(Event: TEntityEvent; keyField: string; keyValue: string = '';
      SearchCompare: TSearchCompare = scEquals); overload;
    procedure List(const keyField: string; Event: TEntityEvent); overload;
    function Where(conditions: array of TConditionItem;
      op: TLogicalOperator = _AND_): TConditionList;
    function Find(const Search: Variant; const FieldName: string = '';
      _keepDataSet: Boolean = false): Boolean;
    procedure setConnectionString(const _Value: string); deprecated;
    function MaxPKValue: integer;
  end;


function fieldTypeToStr(FieldType: TFieldType; Size: integer): string;
function StrToFieldType(const Str: string): TFieldType;

implementation

function TEntity.AddField(const Name: string; FieldType: TFieldType;
  isPrimaryKey: Boolean = false; Size: integer = 0): TEntityField;
var
  i: integer;
begin
  i := IndexOf(Name);
  if i > -1 then
  begin
    Result := TEntityField(FItems[i]);
    Exit;
  end;
  Result := TEntityField.Create(Self);
  Result.Name := Name;
  if isPrimaryKey then
    PrimaryKey := Result;
  Result.FieldType := FieldType;
  if Size > 0 then
    Result.Size := Size;
  FItems.Add(Result);
end;

constructor TEntity.Create;
begin
  FItems := TList.Create();
  FConditionList := TConditionList.Create;
  F_IsEmpty := true;
  SetReady();
end;

destructor TEntity.Destroy;
var
  i: integer;
  Item: TEntityField;
begin
  for i := FItems.Count - 1 downto 0 do
  begin
    Item := TEntityField(FItems[i]);
    Item.Free;
  end; // for
  FItems.Free;
  if FRelations <> nil then
    FRelations.Free;
  { }
  FConditionList.Free;
  inherited;
end;

function TEntity.getItem(const Index: integer): TEntityField;
begin
  if (index < 0) or (index >= FItems.Count) then
    Result := nil
  else
    Result := TEntityField(FItems[index]);
end;

function TEntity.getField(const Name: string): TEntityField;
begin
  Result := getItem(IndexOf(Name));
  if Result = nil then
    raise Exception.Create('Field "' + Name + '" not found in Table "' +
      FTableName + '"')
end;

procedure TEntity.ClearFields;
var
  i: integer;
  Item: TEntityField;
begin
  for i := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[i]);
    if (Item.ForeignEntity = nil) and not Item.ignore then
      case Item.FieldType of
        ftString:
          Item.Value := '';
        ftFloat:
          Item.Value := 0.00;
        ftInteger:
          Item.Value := 0;
        ftDate:
          Item.Value := Now;
      end; // if..case
  end; // for
  needReload := false;
end;

procedure TEntity.NewRecord;
begin
  Edit();
  isNewRecord := true;
end;

function TEntity.SaveChanges: Boolean;
var
  command: string;
  attr_pk: Boolean;
begin
  Result := true;
  if isNewRecord then
  begin
    if Assigned(BeforeInsert) and not BeforeInsert(PrimaryKey) then
    begin
      Result := false;
      Exit;
    end;
    attr_pk := (PrimaryKey.isAutoInc);
    command := 'INSERT INTO ' + TableName + '(' + CommaText([ctoNames], attr_pk)
      + ') VALUES (' + CommaText([ctoValues], attr_pk) + ')';
  end
  else if NothingToDo then
    Exit
  else
    command := 'UPDATE ' + TableName + ' SET ' + CommaText([ctoNames, ctoValues]
      ) + ' WHERE ' + PrimaryKey.Name + '=' + PrimaryKey.SqlFormat;
  CheckConnection();
  try
    EntityConnection.ExecuteCommand(command, false);
    FState := estLoading;
    if isNewRecord and (FRelations <> nil) and (PrimaryKey.isAutoInc) then
      PrimaryKey.Value := getPKValueFromDB();
    { DONE -c1.05 : Get PK value if current entity is ForeignEntity }
  except
    Result := false;
  end;
  SetReady();
  isNewRecord := false;
end;

procedure TEntity.SetPrimaryKey(const _Value: TEntityField);
begin
  if FPrimaryKey <> nil then
    with FPrimaryKey do
    begin
      FieldAttributes := FieldAttributes - [faPrimarykey];
    end; // if..with
  FPrimaryKey := _Value;
  with FPrimaryKey do
  begin
    FieldAttributes := FieldAttributes + [faPrimarykey]
  end; // with
end;

function TEntity.CommaText(options: TCommaTextOptions;
  ignorePK: Boolean): string;
var
  i: integer;
  Item: TEntityField;
  hasFields, hasValues: Boolean;
  separator: string;
  { ### local function ### }
  function AppendField(const suffix: string): string;
  begin
    if hasFields then
      Result := separator
    else
      Result := '';
    Result := Result + Item.Name + suffix;
    hasFields := true;
  end;
  function AppendValue: string;
  begin
    if hasValues then
      Result := separator
    else
      Result := '';
    Result := Result + Item.SqlFormat;
    hasValues := (options = [ctoValues]);
  end;

{ ###################### }
begin
  hasFields := false;
  hasValues := false;
  if options = [] then
  begin
    separator := ' AND ';
  end
  Else
  begin
    separator := ',';
  end; // if..else
  Result := '';
  for i := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[i]);
    if (Item = FPrimaryKey) and ignorePK then
      Continue;
    { }
    if ctoNames in options then
    begin
      if not(ctoValues in options) then
        Result := Result + AppendField('')
      else if not Item.isModified then
        Continue
      else
        Result := Result + AppendField('='); // name AND value
    end;
    if ctoValues in options then
    begin
      Result := Result + AppendValue();
    end;
    if options = [] then
    begin
      Result := Result + AppendField('=') + AppendValue();
    end;
  end; // for
end;

function TEntity.getPrimaryKey: TEntityField;
begin
  if FPrimaryKey <> nil then
    Result := FPrimaryKey
  else if FItems.Count = 0 then
    raise Exception.Create('TEntity - Primary Key missing!')
  else
    Result := TEntityField(FItems[0]);
end;

function TEntity.NothingToDo: Boolean;
var
  i: integer;
  Item: TEntityField;
begin
  Result := true;
  for i := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[i]);
    if Item.isModified then
    begin
      Result := false;
      Exit;
    end;
  end; // for
end;

procedure TEntity.SetTableName(const _Value: string);
begin
  FTableName := _Value;
end;

function TEntity.getTableName: string;
begin
  if Trim(FTableName) = '' then
    raise Exception.Create('TEntity - TableName empty');
  Result := FTableName;
end;

procedure TEntity.LoadFromTable;
begin
  CheckConnection();
  if (EntityConnection.Settings.JoinTables) and (FRelations <> nil) then
  begin
    Exit;
  end;
  FState := estLoading;
  needReload := false;
  if DataSet <> nil then
    DataSet.Free;
  DataSet := EntityConnection.ExecuteCommand(selectCommand, true);
  F_IsEmpty := DataSet.IsEmpty;
  while not DataSet.Eof do
  begin
    if not setFieldsValues then
      Break;
    DataSet.Next;
  end; // while
  if not keepDataSet then
    FreeAndNil(DataSet);
  SetReady();
end;

function TEntity.IndexOf(const Search: string): integer;
var
  Item: TEntityField;
begin
  for Result := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[Result]);
    if SameText(Item.Name, Search) then
      Exit;
  end; // for
  Result := -1;
end;

procedure TEntity.setConnectionString(const _Value: string);
begin
  if not assigned(FEntityConnection) then
     raise Exception.Create('Falta definir o tipo de driver de conexão a utilizar');
  FEntityConnection.SetConnectionString(_value);
end;

function TEntity.DatabaseScript(run: Boolean; tables: TStrings): string;
var
  i: integer;
  Item: TEntityField;
  command: string;
  needDestroy: Boolean;
  FieldList: TStringList;
  hasFields: Boolean;
begin
  CheckConnection();
  hasFields := false;
  { DONE -c0.82 : ALTER TABLE... }
  if tables = nil then
  begin
    tables := EntityConnection.GetList(claTables);
    needDestroy := true;
  end
  Else
    needDestroy := false;
  { }
  if tables.IndexOf(Self.TableName) = -1 then
  begin
    command := 'CREATE TABLE ' + TableName + '(';
    FCreated := true;
    { DONE -c1.04 : identify tables that were recently created }
    FieldList := nil;
  end
  Else
  begin
    command := '';
    FieldList := EntityConnection.GetList(claFields, TableName);
  end; // if..else
  Result := '';
  for i := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[i]);
    if (FieldList <> nil) then
      if FieldList.IndexOf(Item.Name) = -1 then
      begin
        if command = '' then
          command := 'ALTER TABLE ' + TableName;
        command := command + '  ADD';
      end
      Else
      begin
        if Item.ForeignEntity <> nil then
          Result := Result + Item.ForeignEntity.DatabaseScript(run, tables);
        Continue;
      end; // if..else
    if hasFields then
      command := command + ',';
    command := command + #13#10#9 + Item.Name + ' ' +
      fieldTypeToStr(Item.FieldType, Item.Size);
    if Item.FieldAttributes <> [] then
      command := command + ' ' + Item.Attribute;
    { DONE -c0.90 : Field Attributes }
    hasFields := true;
    if Item.ForeignEntity <> nil then
    begin
      command := command + ' REFERENCES ' + Item.ForeignEntity.TableName + '(' +
        Item.ForeignEntity.PrimaryKey.Name + ')';
      Result := Result + Item.ForeignEntity.DatabaseScript(run, tables);
    end;
  end; // for
  if needDestroy then
  begin
    if (FieldList <> nil) then
      EntityConnection.GetList(claClear);
    tables.Free;
  end;
  if command = '' then
    Exit;
  { }
  Result := Result + command;
  if FieldList = nil then
    Result := Result + { #13#10+ } ');' { #13#10 };
  // --- Run Create Table script: ------
  if run then
  begin
    EntityConnection.ExecuteCommand(Result, false);
    Result := '';
  end;
end;

procedure TEntity.AddRelation(field: TEntityField);
begin
  if FRelations = nil then
    FRelations := TList.Create;
  FRelations.Add(field);
end;

procedure TEntity.Delete(_field: TEntityField);
var
  command: string;
  i: integer;
  Item: TEntityField;
begin
  if FRelations <> nil then
    for i := 0 to FRelations.Count - 1 do
    begin
      Item := TEntityField(FRelations[i]);
      Item.Parent.Delete(Item);
    end; // for
  if _field = nil then
    _field := PrimaryKey;
  command := 'DELETE FROM ' + TableName + ' WHERE ' + _field.Name + '=' +
    _field.SqlFormat;
  CheckConnection();
  EntityConnection.ExecuteCommand(command, false);
end;

procedure TEntity.FillSqlElements(var sSELECT, sFROM, sWHERE: string);
var
  i: integer;
  Item: TEntityField;
begin
  if sFROM <> '' then
    sFROM := sFROM + ',';
  sFROM := sFROM + #13#10#9 + Self.TableName;
  for i := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[i]);
    if (Item.ForeignEntity <> nil) and (EntityConnection.Settings.JoinTables)
    then
    begin
      with FConditionList.Add(scEquals) do
      begin
        FieldName := Self.TableName + '.' + Item.Name;
        ConditionValue := Item.ForeignEntity.TableName + '.' +
          Item.ForeignEntity.PrimaryKey.Name;
      end; // with
      Item.ForeignEntity.FillSqlElements(sSELECT, sFROM, sWHERE);
    end
    Else if not Item.ignore then
    begin
      if sSELECT <> '' then
        sSELECT := sSELECT + ',';
      sSELECT := sSELECT + #13#10#9;
      if EntityConnection.Settings.JoinTables then
        sSELECT := sSELECT + Self.TableName + '.';
      sSELECT := sSELECT + Item.Name;
    end; // if..else
  end; // for i
  if (FConditionList.Count = 0) and
    ((FRelations = nil) OR not EntityConnection.Settings.JoinTables) then
    with FConditionList.Add(scEquals) do
    begin
      FieldName := PrimaryKey.Name;
      ConditionValue := PrimaryKey.SqlFormat;
    end; // with
  sWHERE := sWHERE + FConditionList.Expression;
  { DONE -c0.93 : item.Conditions }
end;

function TEntity.selectCommand: string;
var
  s1, s2, s3: string;
begin
  needReload := false;
  s1 := '';
  s2 := '';
  s3 := '';
  FillSqlElements(s1, s2, s3); { DONE -c0.81 : SELECT .. JOIN ... }
  Result := 'SELECT ' + s1 + #13#10'FROM ' + s2 + #13#10'WHERE ' + s3;
  FConditionList.Clear;
end;

function TEntity.setFieldsValues(Source: TDataSet): Boolean;
var
  i: integer;
  Item: TEntityField;
  _field: TField;
begin
  Result := false;
  if Source = nil then
  begin
    Source := Self.DataSet;
  end;
  { }
  for i := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[i]);
    if (Item.ForeignEntity <> nil) and (EntityConnection.Settings.JoinTables)
    then
    begin
      Item.ForeignEntity.setFieldsValues(Source);
    end;
    _field := Source.FindField(Item.Name);
    if _field <> nil then
      Item.Value := _field.AsVariant;
    if Assigned(OnList) then
    begin
      Result := OnList(Item);
      if not Result then
        Exit;
    end;
    Item.isModified := false;
  end; // for
end;

function TEntity.Where(conditions: array of TConditionItem;
  op: TLogicalOperator): TConditionList;
begin
  Result := FConditionList;
  FConditionList.Where(conditions, op);
  { DONE -c0.97 : combinations of conditions such as
    (x AND y) OR (z AND w)
    (x OR y) AND (z OR w) ... }
  Result.Parent := Self;
  SetReady();
end;

procedure TEntity.Cancel;
begin
  SetReady();
  isNewRecord := false;
end;

function TEntity.Find(const Search: Variant; const FieldName: string;
  _keepDataSet: Boolean): Boolean;
var
  _field: TEntityField;
begin
  ConditionList.Clear;
  { ----- }
  if FieldName = '' then
    _field := PrimaryKey
  else
    _field := getField(FieldName);
  { ----- }
  _field.ignore := true; { DONE -c1.01 : Ignore field used in Find }
  _field.Equals(Search);
  Self.keepDataSet := _keepDataSet;
  LoadFromTable;
  Result := not IsEmpty;
  _field.ignore := false;
  { ----- }
end;

procedure TEntity.Assign(obj: TPersistent; const keyField: string);
var
  PropCount, i: integer;
  PropList: PPropList;
  PropInfo: PPropInfo;
  propType: TFieldType;
  _field: TEntityField;
begin
  PropList := nil;
  if TableName = '' then
    TableName := obj.ClassName;
  { DONE -c1.03 : Run-time type information (RTTI) }
  try
    PropCount := GetTypeData(obj.ClassInfo)^.PropCount;
    GetMem(PropList, PropCount * SizeOf(Pointer));
    GetPropInfos(obj.ClassInfo, PropList);
    for i := 0 to PropCount - 1 do
    begin
      PropInfo := PropList^[i];
      propType := StrToFieldType(PropInfo^.propType^.Name);
      _field := AddField(PropInfo^.Name, propType, false, 30);
      if SameText(_field.Name, keyField) then
      begin
        PrimaryKey := _field;
      end;
      _field.Value := GetPropValue(obj, PropInfo^.Name);
    end; // for
  finally
    FreeMem(PropList);
  end;
  needReload := false;
end;

procedure TEntity.SetReady(all: Boolean);
var
  i: integer;
  Item: TEntityField;
begin
  FState := estReady;
  if all then
    for i := 0 to FItems.Count - 1 do
    begin
      Item := TEntityField(FItems[i]);
      if (Item.ForeignEntity = nil) then
        Continue;
      Item.ForeignEntity.SetReady( { true ? } );
      Item.ForeignEntity.ConditionList.Clear;
    end; // if..for
end;

procedure TEntity.Edit(const keyValue: string = '');
begin
  FState := estEditing;
  if keyValue <> '' then
    PrimaryKey.Value := keyValue;
end;

procedure TEntity.List(Event: TEntityEvent; keyField, keyValue: string;
  SearchCompare: TSearchCompare);
var
  _field: TEntityField;
  Master, Detail: TEntity;
begin
  { DONE -c1.09 : New way to list values from Entity }
  Master := Self[keyField].ForeignEntity;
  Detail := Self.Clone();
  Detail.OnList := Event;
  _field := Detail.getField(keyField);
  if Master = nil then
  begin
    _field.Value := keyValue;
    _field.NewCondition(SearchCompare);
  end
  else
  begin
    _field.ignore := true;
    _field.Equals(Master.PrimaryKey.Value);
  end;
  Detail.LoadFromTable;
  Detail.Free;
end;

procedure TEntity.CheckConnection;
begin
  if EntityConnection = nil then
    raise Exception.Create('EntityConnection missing for ' + TableName);
end;

function TEntity.getCount: integer;
begin
  Result := FItems.Count;
end;

procedure TEntity.SetEntityConnection(const Value: IEntityConnection);
var
  i: integer;
  Item: TEntityField;
begin
  if FEntityConnection <> Value then
    FEntityConnection := nil;
  FEntityConnection := Value;
  if (Value = nil) then
    Exit;
  { }
  for i := 0 to FItems.Count - 1 do
  begin
    Item := TEntityField(FItems[i]);
    if (Item.ForeignEntity <> nil) and
      (Item.ForeignEntity.EntityConnection = nil) then
      Item.ForeignEntity.EntityConnection := FEntityConnection;
  end; // for
  if (FEntityConnection.Settings.AutoIncType = aitNone) then
    FEntityConnection.Settings.AutoIncType := Self.AutoIncType;
end;

{ TEntityField }

function TEntityField.AsDate: TDateTime;
begin
{$IFDEF VER130}
  Result := VarToDateTime(Value);
{$ELSE}
  Result := Value;
{$ENDIF}
end;

function TEntityField.AsFloat: Double;
{$IFDEF VER130}
var
  var2: Variant;
begin
  VarCast(var2, Value, varDouble);
  Result := var2;
{$ELSE}
begin
  Result := Value;
{$ENDIF}
end;

function TEntityField.AsInteger: integer;
{$IFDEF VER130}
var
  var2: Variant;
begin
  VarCast(var2, Value, varInteger);
  Result := var2;
{$ELSE}
begin
  Result := Value;
{$ENDIF}
end;

function TEntityField.AsString: string;
begin
{$IFDEF VER130}
  Result := VarToStr(Value);
{$ELSE}
  Result := Value;
{$ENDIF}
end;

constructor TEntityField.Create(_Parent: TEntity);
begin
  fParent := _Parent;
end;

function TEntity.getPKValueFromDB: Variant;
var
  Str: string;
begin
  Str := 'SELECT ' + PrimaryKey.Name + ' FROM ' + TableName + ' WHERE ' +
    CommaText([], true);
  { DONE -c0.99 : Auto_inc values }   { DONE -c1.05 : Dont use MAX to get last/current record }
  with EntityConnection.ExecuteCommand(Str, true) do
  begin
    Result := Fields[0].AsVariant;
    Free;
  end; // with
end;

function TEntityField.getValue: Variant;
begin
  if fParent.needReload and (fParent.State = estReady) then
    fParent.LoadFromTable;
  Result := FValue;
end;

procedure TEntityField.SetFieldType(const _Value: TFieldType);
begin
  FFieldType := _Value;
end;

procedure TEntityField.SetForeignEntity(const _Value: TEntity);
begin
  fForeignEntity := _Value;
  if fForeignEntity <> nil then
    fForeignEntity.AddRelation(Self);
  if (fParent.EntityConnection <> nil) and
    (fForeignEntity.EntityConnection = nil) then
  begin
    fForeignEntity.EntityConnection := fParent.EntityConnection;
  end;
end;

procedure TEntityField.SetSize(const _Value: integer);
begin
  FSize := _Value;
end;

procedure TEntityField.SetAttribute(const _Value: string);
const
  AttrID: array [TFieldAttribute] of string = ('NOT NULL', '', 'UNIQUE',
    'PRIMARY KEY');
var
  i: TFieldAttribute;
begin
  for i := Low(TFieldAttribute) to High(TFieldAttribute) do
  begin
    if i <> faAutoIncrement then
    begin
      if Pos(AttrID[i], _Value) = 0 then
        Continue;
      if i = faPrimarykey then
        fParent.PrimaryKey := Self;
    end
    Else if Pos('IDENTITY(', _Value) > 0 then
    begin
      if (fParent.EntityConnection = nil) then
        fParent.AutoIncType := aitSqlServer
      else
        fParent.EntityConnection.Settings.AutoIncType := aitSqlServer;
    end
    Else if Pos('AUTO_INCREMENT', _Value) > 0 then
    begin
      if (fParent.EntityConnection = nil) then
        fParent.AutoIncType :=
          aitMySql { DONE -c1.22 : Bug fix: AutoIncType lost if Connection not assigned }
      else
        fParent.EntityConnection.Settings.AutoIncType := aitMySql;
    end
    Else
    begin
      Continue;
    end; // if..else
    FieldAttributes := FieldAttributes + [i];
  end; // for
end;

function TEntityField.getAttribute: string;
const
  AttrID: array [TFieldAttribute] of string = (' NOT NULL', '', ' UNIQUE',
    ' PRIMARY KEY');
var
  i: TFieldAttribute;
begin
  Result := '';
  for i := Low(TFieldAttribute) to High(TFieldAttribute) do
    if i in FieldAttributes then
    begin
      if i <> faAutoIncrement then
      begin
        Result := Result + AttrID[i];
      end
      Else if (fParent.EntityConnection <> nil) then
        case fParent.EntityConnection.Settings.AutoIncType of
          aitMySql:
            Result := Result + ' AUTO_INCREMENT';
          aitSqlServer:
            Result := Result + ' IDENTITY(1,1)';
        end; // ele..case
    end; // for..if
end;

procedure TEntityField.SetAutoInc(_Value: Boolean);
begin
  if _Value then
  begin
    FieldAttributes := FieldAttributes + [faAutoIncrement];
  end
  Else
  begin
    FieldAttributes := FieldAttributes - [faAutoIncrement];
  end; // if..else
end;

function TEntityField.getAutoInc: Boolean;
begin
  Result := (faAutoIncrement in FieldAttributes);
end;

procedure TEntityField.SetName(const _Value: string);
begin
  FName := _Value;
end;

procedure TEntityField.SetValue(const _Value: Variant);
begin
{$IFDEF VER130}
  if not VarIsNull(FValue) then
  begin
    if VarToStr(FValue) = VarToStr(_Value) then
      Exit;
  end;
{$ELSE}
  if FValue <> Unassigned then
  begin
    if FValue = _Value then
      Exit;
  end;
{$ENDIF}
  FValue := _Value;
  if ignore then
    Exit; { DONE -c1.07 : Dont perform validations on ignored fields }
  // --------------------
  if ForeignEntity <> nil then
  begin
    ForeignEntity.PrimaryKey.Equals(_Value);
    ForeignEntity.SetReady();
  end
  Else if (fParent.PrimaryKey = Self) and (fParent.State <> estEditing) then
  begin
    fParent.needReload := (fParent.State = estReady);
  end;
  // --------------------
  isModified := true;
end;

function TEntityField.SqlFormat: string;
var
  p: integer;
begin
  if ForeignEntity <> nil then
  begin
    Result := ForeignEntity.PrimaryKey.SqlFormat;
    Exit;
  end;
  case FieldType of
    ftString, ftDate:
      begin
        if FieldType = ftDate then
          Result := FormatDateTime
            (fParent.EntityConnection.Settings.DateFormat, AsDate)
        else
          Result := AsString;
        Result := QuotedStr(Result);
      end;
    ftFloat:
      begin
        Result := FormatFloat
          (fParent.EntityConnection.Settings.FloatFormat, AsFloat);
        p := Pos(',', Result);
        if p > 0 then
          Result[p] := '.';
      end;
    ftInteger:
      Result := IntToStr(AsInteger);
  end; // case
end;

function TEntityField.Contains(Search: Variant): TConditionItem;
begin
  FValue := Search;
  Result := NewCondition(scContains);
end;

function TEntityField.Equals(Search: Variant): TConditionItem;
begin
  FValue := Search;
  Result := NewCondition(scEquals);
end;

function TEntityField.Greater(Search: Variant): TConditionItem;
begin
  FValue := Search;
  Result := NewCondition(scGreater);
end;

function TEntityField.Less(Search: Variant): TConditionItem;
begin
  FValue := Search;
  Result := NewCondition(scLess);
end;

function TEntityField.NewCondition(SearchCompare: TSearchCompare)
  : TConditionItem;
var
  alias: string;
begin
  fParent.Edit();
  Result := fParent.ConditionList.Add(SearchCompare);
  if fParent.EntityConnection.Settings.JoinTables then
    alias := Parent.TableName + '.'
  else
    alias := '';
  Result.FieldName := alias + Self.Name;
  if SearchCompare = scContains then
    with fParent.EntityConnection.Settings do
    begin
      FValue := StartLikeExpr + FValue + EndLikeExpr;
    end; // with
  Result.ConditionValue := Self.SqlFormat;
  fParent.needReload := true;
end;


function fieldTypeToStr(FieldType: TFieldType; Size: integer): string;
begin
  case FieldType of
    ftString, ftFixedChar:
      begin
        if Size < 1 then
          Size := 50;
        if FieldType = ftFixedChar then
          Result := 'Char('
        else
          Result := 'varChar(';
        Result := Result + IntToStr(Size) + ')';
      end;
    ftInteger, ftAutoInc:
      Result := 'integer';
    ftFloat:
      Result := 'float';
    ftDate:
      Result := 'date';
    ftBoolean:
      Result := 'char(1)';
  end; // case
end;

function StrToFieldType(const Str: string): TFieldType;
begin
  if SameText(Str, 'integer') then
    Result := ftInteger
  else if SameText(Str, 'double') then
    Result := ftFloat
  else if SameText(Str, 'TDate') then
    Result := ftDate
  else if SameText(Str, 'Boolean') then
    Result := ftBoolean
  else if SameText(Str, 'String') then
    Result := ftString
  else
    Result := ftUnknown;
end;

function TEntity.Clone: TEntity;
begin
  Result := TEntity(ClassType.NewInstance).Create;
  Result.EntityConnection := Self.EntityConnection;
end;

{ TConditionList }

function TConditionList.Add(Value: TSearchCompare): TConditionItem;
const
  comparisons: array [TSearchCompare] of string = (' > ', // scGreater
    ' < ', // scLess
    ' LIKE ', // scContains
    ' = ' // scEquals
    );
begin
  Result := TConditionItem.Create;
  Result.separator := comparisons[Value];
  Add(Result);
end;

procedure TConditionList.Add(_item: TConditionItem);
begin
  fList.Add(_item);
  _item.Owner := Self;
end;

constructor TConditionList.Create;
begin
  fList := TList.Create;
end;

destructor TConditionList.Destroy;
begin
  Clear;
  fList.Free;
  inherited;
end;

function TConditionList.Expression: string;
var
  i: integer;
begin
  Result := prefix;
  for i := 0 to fList.Count - 1 do
  begin
    if i > 0 then
      Result := Result + getItem(i - 1).LOName;
    Result := Result + #13#10#9 + getItem(i).Expression;
  end; // for
  Result := Result + suffix;
end;

function TConditionList.getCount: integer;
begin
  Result := fList.Count;
end;

function TConditionList.getItem(Index: integer): TConditionItem;
begin
  Result := TConditionItem(fList[Index]);
end;

function TConditionList._AND(conditions: array of TConditionItem;
  op: TLogicalOperator): TConditionList;
begin
  TConditionItem(fList.Last).LogicalOperator := _AND_;
  Result := Where(conditions, op);
end;

function TConditionList.Where(conditions: array of TConditionItem;
  op: TLogicalOperator): TConditionList;
var
  i: integer;
begin
  Result := TConditionList.Create;
  Result.prefix := '(';
  Result.suffix := ')';
  for i := Low(conditions) to High(conditions) do
  begin
    conditions[i].LogicalOperator := op;
    Result.Add(conditions[i]);
  end; // for
  Self.Add(Result);
end;

function TConditionList._OR(conditions: array of TConditionItem;
  op: TLogicalOperator): TConditionList;
begin
  TConditionItem(fList.Last).LogicalOperator := _OR_;
  Result := Where(conditions, op);
end;

procedure TConditionList.Clear;
var
  condition: TConditionItem;
begin
  while fList.Count > 0 do
  begin
    condition := getItem(0);
    condition.Free;
    fList.Delete(0);
  end; // while
end;

function TConditionList.Remove(_item: TConditionItem): Boolean;
var
  p: integer;
begin
  p := fList.IndexOf(_item);
  Result := (p > -1);
  if Result then
  begin
    fList.Delete(p);
  end;
end;

procedure TConditionList.Select;
begin
  if Parent = nil then
    Exit;
  Parent.LoadFromTable;
  Parent.SetReady(true);
end;

{ TConditionItem }

function TConditionItem.Expression: string;
begin
  Result := FieldName + separator + ConditionValue
end;

function TConditionItem.LOName: string;
const
  LONames: array [TLogicalOperator] of string = (' AND ', ' OR ');
begin
  Result := LONames[Self.LogicalOperator];
end;

procedure TConditionItem.SetOwner(const Value: TConditionList);
begin
  if fOwner <> nil then
  begin
    fOwner.Remove(Self);
  end;
  fOwner := Value;
end;

procedure TEntity.List(const keyField: string; Event: TEntityEvent);
var
  dField: TField; // DataSet Field
  _field: TEntityField;
begin
  { DONE -c1.22 : List only one field }
  if DataSet = nil then
    Exit;
  dField := DataSet.FindField(keyField);
  if (dField = nil) then
    Exit;
  Self.OnList := Event;
  _field := getField(keyField);
  _field.ignore := true;
  while not DataSet.Eof do
  begin
    _field.Value := dField.AsVariant;
    if not Event(_field) then
      Break;
    DataSet.Next;
  end; // while
  Self.OnList := nil;
  _field.ignore := false;
  keepDataSet := false;
  FreeAndNil(DataSet);
end;

function TEntity.MaxPKValue: integer;
var
  command: string;
begin
  command := 'SELECT Max(' + PrimaryKey.Name + ') FROM ' + TableName;
  DataSet := EntityConnection.ExecuteCommand(command, true);
  Result := DataSet.Fields[0].AsInteger;
  FreeAndNil(DataSet);
end;


end.
