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

program cacic2;

uses
  Forms,
  Windows,
  Dialogs,
  main in 'main.pas' {FormularioGeral},
  frmSenha in 'frmsenha.pas' {formSenha},
  frmConfiguracoes in 'frmConfiguracoes.pas' {FormConfiguracoes},
  frmLog in 'frmLog.pas' {FormLog},
  LibXmlParser,
  CACIC_Library in 'CACIC_Library.pas';

{$R *.res}

const
  CACIC_APP_NAME = 'cacic2';

var
  hwind:HWND;
  oCacic : TCACIC;

begin
   oCacic := TCACIC.Create();
   
   if( oCacic.isAppRunning( CACIC_APP_NAME ) )
     then begin
        hwind := 0;
        repeat			// The string 'My app' must match your App Title (below)
           hwind:=Windows.FindWindowEx(0,hwind,'TApplication', CACIC_APP_NAME );
        until (hwind<>Application.Handle);
        IF (hwind<>0) then
        begin
           Windows.ShowWindow(hwind,SW_SHOWNORMAL);
           Windows.SetForegroundWindow(hwind);
        end;
        FreeMemory(0);
        Halt(0);
     end;

   oCacic.Free();

   // Preventing application button showing in the task bar
   SetWindowLong(Application.Handle, GWL_EXSTYLE, GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW and not WS_EX_APPWINDOW );
   Application.Initialize;
   Application.Title := 'cacic2';
   Application.CreateForm(TFormularioGeral, FormularioGeral);
   Application.Run;
end.
