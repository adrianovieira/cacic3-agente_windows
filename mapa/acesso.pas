unit acesso;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

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
    pnVersao: TPanel;
    lbVersao: TLabel;
    tm_Mensagem: TTimer;
    procedure btAcessoClick(Sender: TObject);
    procedure btCancelaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edNomeUsuarioAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tm_MensagemTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var frmAcesso: TfrmAcesso;

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

  // Envio dos dados ao DataBase...
  Request_mapa.Values['nm_acesso']    := frmMapaCacic.EnCrypt(edNomeUsuarioAcesso.Text);
  Request_mapa.Values['te_senha']     := frmMapaCacic.EnCrypt(edSenhaAcesso.Text);
  Request_mapa.Values['cs_MapaCacic'] := frmMapaCacic.EnCrypt('S');


  strRetorno := frmMapaCacic.ComunicaServidor('mapa_acesso.php', Request_mapa, 'Autenticando o Acesso...');
  Request_mapa.free;

  if (frmMapaCacic.XML_RetornaValor('STATUS', strRetorno)='OK') then
    Begin
      str_local_Aux := trim(frmMapaCacic.DeCrypt(frmMapaCacic.XML_RetornaValor('ID_USUARIO',strRetorno)));
      if (str_local_Aux <> '') then
        Begin
          frmMapaCacic.strId_usuario := str_local_Aux;
          str_local_Aux := '';
          frmMapaCacic.boolAcessoOK := true; // Acesso OK!
        End
      else
        Begin
          str_local_Aux := 'Usu�rio/Senha Incorretos ou N�vel de Acesso N�o Permitido!';
        End
    End
  else
    Begin
      str_local_Aux := 'Problemas na Comunica��o!';
    End;

  lbMsg_Erro_Senha.Caption := str_local_Aux;

  if (frmMapaCacic.boolAcessoOK) then
    Begin
      lbAviso.Caption := 'USU�RIO AUTENTICADO: "' + trim(frmMapaCacic.DeCrypt(frmMapaCacic.XML_RetornaValor('NM_USUARIO_COMPLETO',strRetorno)))+'"';
      lbAviso.Font.Style := [fsBold];
      lbAviso.Font.Color := clGreen;
      Application.ProcessMessages;
      Sleep(3000);
    End
  else
    lbMsg_Erro_Senha.Font.Color := clRed;

  tm_Mensagem.Enabled := true;

  frmMapaCacic.log_diario(str_local_Aux);

  Application.ProcessMessages;

  if (frmMapaCacic.boolAcessoOK) then
    Close
  else
    Begin
      edNomeUsuarioAcesso.AutoSelect := false;
      edNomeUsuarioAcesso.SetFocus;
    End
end;


procedure TfrmAcesso.btCancelaClick(Sender: TObject);
begin
  lbMsg_Erro_Senha.Caption := 'Aguarde... Finalizando!';
  Application.ProcessMessages;
  frmMapaCacic.Finalizar(true);
end;

procedure TfrmAcesso.FormCreate(Sender: TObject);
begin
  frmAcesso.lbVersao.Caption        := 'v: ' + frmMapaCacic.GetVersionInfo(ParamStr(0));
  frmMapaCacic.tStringsCipherOpened := frmMapaCacic.CipherOpen(frmMapaCacic.strDatFileName);
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

end.
