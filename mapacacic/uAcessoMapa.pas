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

unit uAcessoMapa;

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
    lbAviso: TLabel;
    pnMessageBox: TPanel;
    lbMensagens: TLabel;
    procedure btAcessoClick(Sender: TObject);
    procedure btCancelaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edNomeUsuarioAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
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
uses uMainMapa,
     CACIC_Comm;
{$R *.dfm}

procedure TfrmAcesso.btAcessoClick(Sender: TObject);
var strCommResponseAcesso,
    strLocalAux : String;
    boolAlert   : boolean;
begin
  frmMapaCacic.boolAcessoOK := false;
  boolAlert                 := false;

  // Autentica��o de Programa e Usu�rio
  strFieldsAndValuesToRequest :=                               'nm_acesso='           + objCacicCOMM.replaceInvalidHTTPChars( objCacic.enCrypt(edNomeUsuarioAcesso.Text))          + ',';
  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'te_senha='            + objCacicCOMM.replaceInvalidHTTPChars( objCacic.enCrypt(edSenhaAcesso.Text,false))          + ',';
  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'te_operacao='         + 'Autentication';

  strCommResponseAcesso := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'mapacacic/acesso', strFieldsAndValuesToRequest,objCacic.getLocalFolderName);
  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  if (strCommResponseAcesso <> '0') then
    Begin
      strLocalAux := trim(objCacic.deCrypt(objCacic.getValueFromTags('ID_USUARIO',strCommResponseAcesso)));
      if (strLocalAux <> '') then
        Begin
          frmMapaCacic.strId_usuario := strLocalAux;
          strLocalAux := '';
          frmMapaCacic.boolAcessoOK := true; // Acesso OK!
        End
      else
        Begin
          strLocalAux := 'Usu�rio/Senha incorretos ou Usu�rio sem Acesso Prim�rio/Secund�rio a este local!';
          boolAlert := true;
        End
    End
  else
    Begin
      strLocalAux := 'Problemas na comunica��o!';
      boolAlert := true;      
    End;

  frmMapaCacic.Mensagem(strLocalAux,boolAlert);

  if (frmMapaCacic.boolAcessoOK) then
    Begin
      lbAviso.Caption := 'USU�RIO AUTENTICADO: "' + trim(objCacic.deCrypt(objCacic.getValueFromTags('NM_USUARIO_COMPLETO',strCommResponseAcesso)))+'"';
      lbAviso.Font.Style := [fsBold];
      lbAviso.Font.Color := clGreen;
      Application.ProcessMessages;
      Sleep(3000);
    End
  else
    lbMensagens.Font.Color := clRed;

  frmMapaCacic.timerMessageShowTime.Enabled := true;

  objCacic.writeDailyLog(strLocalAux);

  Application.ProcessMessages;

  if (frmMapaCacic.boolAcessoOK) then
    Begin
      self.Close
    End
  else
    Begin
      objCacic.writeDebugLog('btAcessoClick: Acesso N�o Efetuado! Comandando fechamento.');    
      edNomeUsuarioAcesso.AutoSelect := false;
      edNomeUsuarioAcesso.SetFocus;
    End;
end;

Function TfrmAcesso.VerificaVersao : boolean;
var strCommResponseVerVersao,
    strAUXvv      : String;
begin
  Result := false;

  // Envio dos dados ao DataBase...
  strFieldsAndValuesToRequest :=                               'te_operacao='         + 'CheckVersion' + ',';
  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'MAPACACIC.EXE_HASH='  + objCacic.getFileHash(ParamStr(0));

  strCommResponseVerVersao := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'mapacacic/acesso', strFieldsAndValuesToRequest,objCacic.getLocalFolderName);
  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  objCacic.writeDebugLog('VerificaVersao: Analisando retorno...');
  if (strCommResponseVerVersao <> '0') then
    Begin
      objCacic.writeDebugLog('VerificaVersao: Retorno OK');
      strAUXvv := trim(objCacic.getValueFromTags('MAPACACIC.EXE_HASH',strCommResponseVerVersao));
      objCacic.writeDebugLog('VerificaVersao: MAPACACIC.EXE_HASH => ' + strAUXvv);
      if (strAUXvv = '') then
        Result := true
      else
        Begin
           ShowMessage('ATEN��O:' + #13#10 +
                       '-------'  + #13#10 + #13#10 +
                       'Encontra-se disponibilizada uma nova vers�o do MapaCACIC no servidor "' + objCacic.getWebManagerAddress + '"'+ #13#10 + #13#10 + #13#10 +
                       'P�r�metro Local.: "' + objCacic.getFileHash(ParamStr(0)) + '"' + #13#10 +
                       'Par�metro Remoto: "' + objCacic.getValueFromTags('MAPACACIC.EXE_HASH',strCommResponseVerVersao) + '"' + #13#10 + #13#10 + #13#10 +
                       'Acesse ao servidor e baixe um novo execut�vel atrav�s do link "Reposit�rio" da p�gina principal do Sistema CACIC.' + #13#10 + #13#10 + #13#10 +
                       'A execu��o est� sendo finalizada!' + #13#10 + #13#10 + #13#10);
           btCancelaClick(nil);
        End;
    End
  else
    Begin
      objCacic.writeDebugLog('VerificaVersao: Problema de Comunica��o!');
      MessageDLG(#13#10#13#10+'ATEN��O! H� problema na comunica��o com o m�dulo Gerente WEB.'+#13#10#13#10,mtWarning,[mbOK],0);
    End;
  Application.ProcessMessages;
end;


procedure TfrmAcesso.btCancelaClick(Sender: TObject);
begin
  lbMensagens.Caption := 'Aguarde... Finalizando!';
  Self.Close;  
  Application.ProcessMessages;
end;

procedure TfrmAcesso.FormCreate(Sender: TObject);
begin
  frmMapaCacic.lbMensagens.Caption  := 'Entrada de Dados para Autentica��o no M�dulo Gerente WEB Cacic';
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

procedure TfrmAcesso.edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not (trim(frmAcesso.edNomeUsuarioAcesso.Text) = '') and
     not (trim(frmAcesso.edSenhaAcesso.Text) = '')       then
     frmAcesso.btAcesso.Enabled := true
  else
     frmAcesso.btAcesso.Enabled := false;
end;

procedure TfrmAcesso.FormActivate(Sender: TObject);
begin
  strFrmAtual := 'Principal';
  lbAviso.Caption := 'Verificando Exist�ncia de Nova Vers�o.';
  frmMapaCacic.Mensagem(lbAviso.Caption);
  if (objCacic.getWebManagerAddress = '') then
    Begin
      frmMapaCacic.Mensagem('Favor verificar a instala��o do Cacic.' +#13#10 + 'N�o Existe Servidor de Aplica��o configurado!',true,3);
      frmMapaCacic.Finalizar(true);
    End;

  if not VerificaVersao then
    frmMapaCacic.Finalizar(false)
  else
    Begin
      lbNomeUsuarioAcesso.Visible := true;
      edNomeUsuarioAcesso.Visible := true;
      lbSenhaAcesso.Visible       := true;
      edSenhaAcesso.Visible       := true;
      lbAviso.Caption             := 'ATEN��O: O usu�rio deve estar cadastrado no Gerente WEB e deve ter acesso PRIM�RIO ou SECUND�RIO a este local';

      frmAcesso.edNomeUsuarioAcesso.SetFocus;
    End;
    
  frmMapaCacic.Mensagem('');
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
