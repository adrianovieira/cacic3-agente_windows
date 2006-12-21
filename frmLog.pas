(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informa��es da Previd�ncia Social, Brasil

Este arquivo � parte do programa CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais

O CACIC � um software livre; voc� pode redistribui-lo e/ou modifica-lo dentro dos termos da Licen�a P�blica Geral GNU como
publicada pela Funda��o do Software Livre (FSF); na vers�o 2 da Licen�a, ou (na sua opini�o) qualquer vers�o.

Este programa � distribuido na esperan�a que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUA��O a qualquer
MERCADO ou APLICA��O EM PARTICULAR. Veja a Licen�a P�blica Geral GNU para maiores detalhes.

Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral GNU, sob o t�tulo "LICENCA.txt", junto com este programa, se n�o, escreva para a Funda��o do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

unit frmLog;

interface
uses Forms, StdCtrls, Classes, Controls, SysUtils, ExtCtrls;
{
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, Buttons, Dialogs, Grids;
}

type
  TFormLog = class(TForm)
    MemoLog: TMemo;
    Bt_Fechar_Log: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Bt_Fechar_LogClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormLog: TFormLog;

implementation

{$R *.dfm}

Uses main;

procedure TFormLog.FormCreate(Sender: TObject);
var
  sl: TStringList;
  begin
    sl := TStringList.Create;
    try
      FormularioGeral.log_diario('');

      sl.LoadFromFile(ExtractFilePath(Application.Exename) + '\cacic2.log');
      MemoLog.Text := '';
      MemoLog.SetSelTextBuf(PChar(sl.Text));
    finally
      sl.Free;
  end;
end;


procedure TFormLog.Bt_Fechar_LogClick(Sender: TObject);
begin
  Release;
  Close;
end;


procedure TFormLog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Release;
   Close;
end;


end.
