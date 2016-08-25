unit uExemplo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants, System.Classes, Vcl.Graphics,
  EntityObjects,EntityObjects.Base, EntityObjects.Firedac,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

type
  TForm9 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FEntity : TEntity;
  public
    { Public declarations }
  end;

var
  Form9: TForm9;

implementation

{$R *.dfm}

procedure TForm9.FormCreate(Sender: TObject);
var conn:IEntityConnection;
begin
   FEntity := TEntity.create;
   conn := TEntityConnectionFiredac.Create('DriverID=SQLITE,ServerName=localhost,Database=agenda.sqlite,user_name=sysdba,password=masterkey');
   FEntity.EntityConnection := conn;
end;

procedure TForm9.FormDestroy(Sender: TObject);
begin
   FEntity.Free;
end;

end.
