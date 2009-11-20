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
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  main,
  PJVersionInfo,
  NTFileSecurity,
  Buttons,
  ExtCtrls;

type
  TConfigs = class(TForm)
    Edit_ip_serv_cacic: TEdit;
    Edit_cacic_dir: TEdit;
    gbObrigatorio: TGroupBox;
    Label_ip_serv_cacic: TLabel;
    Label_cacic_dir: TLabel;
    gbOpcional: TGroupBox;
    lbMensagemNaoAplicavel: TLabel;
    Label_te_instala_informacoes_extras: TLabel;
    Button_Gravar: TButton;
    Memo_te_instala_informacoes_extras: TMemo;
    PJVersionInfo1: TPJVersionInfo;
    ckboxExibeInformacoes: TCheckBox;
    btSair: TButton;
    pnVersao: TPanel;
    lbVersao: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button_GravarClick(Sender: TObject);
    procedure ckboxExibeInformacoesClick(Sender: TObject);
    procedure btSairClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Configs: TConfigs;

implementation

{$R *.dfm}

procedure TConfigs.Button_GravarClick(Sender: TObject);
begin
  if trim(Edit_cacic_dir.Text) = '' then
    Edit_cacic_dir.Text := 'Cacic';

  if trim(Edit_ip_serv_cacic.Text)  = '' then
    Edit_ip_serv_cacic.SetFocus
  else
    Begin
      main.GravaConfiguracoes;
      Close;
      Application.terminate;
    End;
end;

procedure TConfigs.ckboxExibeInformacoesClick(Sender: TObject);
begin
  if ckboxExibeInformacoes.Checked then
    Begin
      Memo_te_instala_informacoes_extras.Enabled := true;
      Memo_te_instala_informacoes_extras.Color   := clWindow;
      v_exibe_informacoes := 'S';
    End
  else
    Begin
      Memo_te_instala_informacoes_extras.Enabled := false;
      Memo_te_instala_informacoes_extras.Color   := clInactiveBorder;
      v_exibe_informacoes := 'N';
    End;
end;

procedure TConfigs.btSairClick(Sender: TObject);
begin
  Close;
  Application.Terminate;
end;

end.
