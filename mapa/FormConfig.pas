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

unit FormConfig;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,main_mapa, PJVersionInfo, NTFileSecurity, ExtCtrls;

type
  TConfigs = class(TForm)
    Button_Gravar: TButton;
    PJVersionInfo1: TPJVersionInfo;
    btCancelaOperacao: TButton;
    pnConfiguracoes: TPanel;
    Label_ip_serv_cacic: TLabel;
    Edit_ip_serv_cacic: TEdit;
    Label_cacic_dir: TLabel;
    Edit_cacic_dir: TEdit;
    lbConfiguracoes: TLabel;
    pnVersao: TPanel;
    lbVersao: TLabel;
    procedure Button_GravarClick(Sender: TObject);
    procedure Edit_ip_serv_cacicExit(Sender: TObject);
    procedure Edit_cacic_dirExit(Sender: TObject);
    procedure GravaConfiguracoes;
    procedure btCancelaOperacaoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Configs: TConfigs;
  v_ip_serv_cacic,
  v_cacic_dir : String;


implementation

{$R *.dfm}

procedure TConfigs.Button_GravarClick(Sender: TObject);
begin
  Configs.GravaConfiguracoes;
  Close;
end;

procedure TConfigs.GravaConfiguracoes;
var mapa_ini : TextFile;
begin
   try
       FileSetAttr (ExtractFilePath(Application.Exename) + '\MapaCacic.ini',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(mapa_ini,ExtractFilePath(Application.Exename) + '\MapaCacic.ini'); {Associa o arquivo a uma vari�vel do tipo TextFile}
       Rewrite (mapa_ini); // Recria o arquivo...
       Append(mapa_ini);
       Writeln(mapa_ini,'');
       Writeln(mapa_ini,'# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #');
       Writeln(mapa_ini,'# CHAVES E VALORES OBRIGAT�RIOS PARA USO DO MapaCacic.exe                          #');
       Writeln(mapa_ini,'# =================================================================  #');
       Writeln(mapa_ini,'# ip_serv_cacic                                                                                                             #');
       Writeln(mapa_ini,'#          IP ou Identifica��o do servidor onde o M�dulo Gerente do CACIC foi instalado#');
       Writeln(mapa_ini,'#          Ex.: ip_serv_cacic=UXRJO115                                                                          #');
       Writeln(mapa_ini,'#               ip_serv_cacic=10.xxx.yyy.zzz                                                                    #');
       Writeln(mapa_ini,'# cacic_dir                                                                                                           #');
       Writeln(mapa_ini,'#          Pasta a ser criada na esta��o para instala��o do CACIC agente                    #');
       Writeln(mapa_ini,'#          Ex.: cacic_dir=Cacic                                                                                          #');
       Writeln(mapa_ini,'# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #');
       Writeln(mapa_ini,'');
       Writeln(mapa_ini,'[Cacic2]');

       // Atribui��o dos valores do form FormConfig �s vari�veis...
       v_ip_serv_cacic                 := Configs.Edit_ip_serv_cacic.text;
       v_cacic_dir                     := Configs.Edit_cacic_dir.text;

       // Escrita dos par�metros obrigat�rios
       Writeln(mapa_ini,'ip_serv_cacic='+v_ip_serv_cacic);
       Writeln(mapa_ini,'cacic_dir='+v_cacic_dir);

       CloseFile(mapa_ini); {Fecha o arquivo texto}
   except
   end;
end;

procedure TConfigs.Edit_ip_serv_cacicExit(Sender: TObject);
begin
if trim(Edit_ip_serv_cacic.Text) = '' then Edit_ip_serv_cacic.SetFocus;
end;

procedure TConfigs.Edit_cacic_dirExit(Sender: TObject);
begin
if trim(Edit_cacic_dir.Text) = '' then Edit_cacic_dir.Text := 'Cacic';
end;

procedure TConfigs.btCancelaOperacaoClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TConfigs.FormCreate(Sender: TObject);
begin
  Configs.lbVersao.Caption := 'v: ' + frmMapaCacic.GetVersionInfo(ParamStr(0));
end;

end.
