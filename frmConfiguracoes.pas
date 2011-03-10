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

unit frmConfiguracoes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Buttons, StdCtrls, ExtCtrls, main,dialogs;

type
  TFormConfiguracoes = class(TForm)
    Label_WebManagerAddress: TLabel;
    Edit_WebManagerAddress: TEdit;
    BtN_Confirmar: TButton;
    Bv1_Configuracoes: TBevel;
    Btn_Cancelar: TButton;
    Btn_OK: TButton;
    procedure pro_Btn_OK(Sender: TObject);
    procedure pro_Btn_Cancelar(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure pro_Btn_Confirmar(Sender: TObject);
    procedure AtualizaConfiguracoes(p_strSectionName, p_strKeyName, p_strValue : String);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormConfiguracoes: TFormConfiguracoes;

implementation

uses CACIC_Library;


{$R *.dfm}

procedure TFormConfiguracoes.AtualizaConfiguracoes(p_strSectionName, p_strKeyName, p_strValue : String);
begin
    g_oCacic.setValueToFile(p_strSectionName, p_strKeyName, g_oCacic.enCrypt( p_strValue), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
end;

procedure TFormConfiguracoes.pro_Btn_OK(Sender: TObject);
begin
    AtualizaConfiguracoes('Configs','TeWebManagerAddress',Edit_WebManagerAddress.Text);
    Btn_Cancelar.Click;
end;

procedure TFormConfiguracoes.pro_Btn_Cancelar(Sender: TObject);
begin
  release;
  Close;
end;


procedure TFormConfiguracoes.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Btn_Cancelar.Click;
end;


procedure TFormConfiguracoes.FormCreate(Sender: TObject);
begin
  Edit_WebManagerAddress.Text      := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
end;

procedure TFormConfiguracoes.pro_Btn_Confirmar(Sender: TObject);
Begin
   If Trim(Edit_WebManagerAddress.Text) = '' Then
   Begin
      MessageDlg('Erro na configura��o: ' + #13#10 + 'N�o foi especificado o endere�o do servidor do CACIC.', mtInformation, [mbOk], 0);
      Exit;
   end;

   try
     FormConfiguracoes.AtualizaConfiguracoes('Configs','TeWebManagerAddress',Trim(Edit_WebManagerAddress.Text));
   finally
   end;
   Btn_Cancelar.Click;
end;

end.
