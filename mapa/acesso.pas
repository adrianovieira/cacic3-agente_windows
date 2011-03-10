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

unit acesso;

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
  StdCtrls,
  ExtCtrls,
  dialogs;

type
  TfrmAcesso = class(TForm)
    btAcesso: TButton;
    btCancela: TButton;
    pnAcesso: TPanel;
    lbNomeUsuarioAcesso: TLabel;
    edNomeUsuarioAcesso: TEdit;
    lbSenhaAcesso: TLabel;
    edSenhaAcesso: TEdit;
    pnMensagens: TPanel;
    lbMsg_Erro_Senha: TLabel;
    lbAviso: TLabel;
    tm_Mensagem: TTimer;
    lbVersao: TLabel;
    lbTeWebManagerAddress: TLabel;
    edTeWebManagerAddress: TLabel;
    procedure btAcessoClick(Sender: TObject);
    procedure btCancelaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edNomeUsuarioAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tm_MensagemTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function  VerificaVersao : boolean;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAcesso: TfrmAcesso;

implementation
uses main_mapa;
{$R *.dfm}

procedure TfrmAcesso.btAcessoClick(Sender: TObject);
var Request_mapa : TStringList;
    strRetorno,
    str_local_Aux : String;
begin
  frmMapaCacic.boolAcessoOK := false;
  Request_mapa:=TStringList.Create;

  lbMsg_Erro_Senha.Caption := str_local_Aux;

  // Autentica��o de Programa e Usu�rio
  Request_mapa.Values['nm_acesso']      := g_oCacic.enCrypt(edNomeUsuarioAcesso.Text);
  Request_mapa.Values['te_senha']       := g_oCacic.enCrypt(edSenhaAcesso.Text);
  Request_mapa.Values['cs_MapaCacic']   := g_oCacic.enCrypt('S');
  Request_mapa.Values['te_operacao']    := g_oCacic.enCrypt('Autentication');
  Request_mapa.Values['te_versao_mapa'] := g_oCacic.enCrypt(g_oCacic.getVersionInfo(ParamStr(0)));

  strRetorno := frmMapaCacic.ComunicaServidor('mapa_acesso.php', Request_mapa, 'Autenticando o Acesso...');
  Request_mapa.free;

  if (g_oCacic.xmlGetValue('STATUS', strRetorno)='OK') then
    Begin
      str_local_Aux := trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('ID_USUARIO',strRetorno)));
      if (str_local_Aux <> '') then
        Begin
          frmMapaCacic.strId_usuario := str_local_Aux;
          str_local_Aux := '';
          frmMapaCacic.boolAcessoOK := true; // Acesso OK!
        End
      else
        Begin
          str_local_Aux := 'Usu�rio/Senha incorretos ou Usu�rio sem Acesso Prim�rio/Secund�rio a este local!';
        End
    End
  else
    Begin
      str_local_Aux := 'Problemas na comunica��o!';
    End;

  lbMsg_Erro_Senha.Caption := str_local_Aux;

  if (frmMapaCacic.boolAcessoOK) then
    Begin
      lbAviso.Caption := 'USU�RIO AUTENTICADO: "' + trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('NM_USUARIO_COMPLETO',strRetorno)))+'"';
      lbAviso.Font.Style := [fsBold];
      lbAviso.Font.Color := clGreen;
      Application.ProcessMessages;
      Sleep(3000);
    End
  else
    lbMsg_Erro_Senha.Font.Color := clRed;

  tm_Mensagem.Enabled := true;

  g_oCacic.writeDailyLog(str_local_Aux);

  Application.ProcessMessages;

  if (frmMapaCacic.boolAcessoOK) then
    self.Close
  else
    Begin
      edNomeUsuarioAcesso.AutoSelect := false;
      edNomeUsuarioAcesso.SetFocus;
    End;
end;

Function TfrmAcesso.VerificaVersao : boolean;
var Request_mapa : TStringList;
    strRetorno,
    strAUX       : String;
begin
  Result := false;
  Request_mapa:=TStringList.Create;

  // Envio dos dados ao DataBase...
  Request_mapa.Values['cs_MapaCacic']   := g_oCacic.enCrypt('S');
  Request_mapa.Values['te_operacao']    := g_oCacic.enCrypt('Autentication');
  Request_mapa.Values['te_versao_mapa'] := g_oCacic.enCrypt(g_oCacic.getVersionInfo(ParamStr(0)));

  strRetorno := frmMapaCacic.ComunicaServidor('mapa_acesso.php', Request_mapa, 'Verificando Vers�o...');
  Request_mapa.free;

  if (g_oCacic.xmlGetValue('STATUS', strRetorno)='OK') then
    Begin
      strAUX := trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_VERSAO_MAPA',strRetorno)));
      if (strAUX = '') then
        Result := true
      else
        MessageDLG(#13#10#13#10+'ATEN��O! Encontra-se disponibilizada a vers�o "'+strAUX+'".'+#13#10#13#10+'Acesse o Gerente WEB do CACIC, op��o "Reposit�rio" e baixe o programa "MapaCACIC"!'+#13#10,mtWarning,[mbOK],0);
    End
  else
    MessageDLG(#13#10#13#10+'ATEN��O! H� problema na comunica��o com o m�dulo Gerente WEB.'+#13#10#13#10,mtWarning,[mbOK],0);
end;


procedure TfrmAcesso.btCancelaClick(Sender: TObject);
begin
  lbMsg_Erro_Senha.Caption := 'Aguarde... Finalizando!';
  Application.ProcessMessages;
  Self.Close;
  boolFinalizar := true;
end;

procedure TfrmAcesso.FormCreate(Sender: TObject);
begin
  intPausaPadrao                          := 3000; //(3 mil milisegundos = 3 segundos)
  frmAcesso.lbVersao.Caption              := 'Vers�o: ' + g_oCacic.getVersionInfo(ParamStr(0));
  frmMapaCacic.lbMensagens.Caption        := 'Entrada de Dados para Autentica��o no M�dulo Gerente WEB Cacic';
end;

procedure TfrmAcesso.edNomeUsuarioAcessoKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not (trim(frmAcesso.edNomeUsuarioAcesso.Text) = '') and
     not (trim(frmAcesso.edSenhaAcesso.Text) = '')       then
     frmAcesso.btAcesso.Enabled := true
  else
     frmAcesso.btAcesso.Enabled := false;
end;

procedure TfrmAcesso.FormShow(Sender: TObject);
begin
  frmAcesso.edNomeUsuarioAcesso.SetFocus;
end;

procedure TfrmAcesso.edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not (trim(frmAcesso.edNomeUsuarioAcesso.Text) = '') and
     not (trim(frmAcesso.edSenhaAcesso.Text) = '')       then
     frmAcesso.btAcesso.Enabled := true
  else
     frmAcesso.btAcesso.Enabled := false;
end;

procedure TfrmAcesso.tm_MensagemTimer(Sender: TObject);
begin
  tm_Mensagem.Enabled := false;
  lbMsg_Erro_Senha.Caption := '';
  lbMsg_Erro_Senha.Font.Color := clBlack;
end;

procedure TfrmAcesso.FormActivate(Sender: TObject);
begin
  if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + 'GER_COLS.inf'))='') then
    Begin
      frmMapaCacic.Mensagem('Favor verificar a instala��o do Cacic.' +#13#10 + 'N�o Existe Servidor de Aplica��o configurado!',true,intPausaPadrao);
      frmMapaCacic.Finalizar(true);
    End
  else
    frmAcesso.edTeWebManagerAddress.Caption := frmMapaCacic.edTeWebManagerAddress.Caption;

  if not VerificaVersao then
    frmMapaCacic.Finalizar(false);
end;

procedure TfrmAcesso.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  IF (key = VK_RETURN) then
    Begin
      if (edNomeUsuarioAcesso.Focused) and (trim(edNomeUsuarioAcesso.Text) <> '') then
        edSenhaAcesso.SetFocus
      else if (edSenhaAcesso.Focused) and (trim(edSenhaAcesso.Text) <> '') then
        btAcessoClick(nil);
    End;
end;

end.
