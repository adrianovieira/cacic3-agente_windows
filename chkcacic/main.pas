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
======================================================================================================
ChkCacic.exe : Verificador/Instalador dos agentes prim�rios do CACIC
======================================================================================================

v 2.2.0.38
+ Acrescentado a obten��o de vers�o interna do S.O.
+ Acrescentado a inser��o dos agentes principais nas exce��es do FireWall interno do MS-Windows VISTA...
.
Diversas rebuilds...
.
v 2.2.0.17
+ Acrescentado o tratamento da passagem de op��es em linha de comando
  * chkcacic /serv=<TeManagerWebAddress> /dir=<TeLocalFolder>c:\%windir%\cacic
  Exemplo de uso: chkcacic /serv=UXbra001 /dir=Cacic

v 2.2.0.16
* Corrigido o fechamento do arquivo de configura��es de ChkSis

v 2.2.0.15
* Substitu�da a mensagem "File System diferente de "NTFS" por 'File System: "<NomeFileSystem>" - Ok!'

v 2.2.0.14
+ Cr�ticas/mensagens:
  "ATEN��O! N�o foi poss�vel estabelecer comunica��o com o m�dulo Gerente WEB em <servidor>." e
  "ATEN��O: N�o foi poss�vel efetuar FTP para <agente>. Verifique o Servidor de Updates."
+ Op��o checkbox "Exibe informa��es sobre o processo de instala��o" ao formul�rio de configura��o;
+ Bot�o "Sair" ao formul�rio de configura��o;
+ Execu��o autom�tica do Agente Principal ao fim da instala��o quando a unidade origem do ChkCacic n�o
  for mapeamento de rede ou unidade inv�lida.

- Retirados os campos "Frase para Sucesso na Instala��o" e "Frase para Insucesso na Instala��o"
  do formul�rio de configura��o, passando essas frases a serem fixas na aplica��o.
- Retirada a op��o radiobutton "Remove Vers�o Anterior?";

=====================================================================================================
*)


unit main;

interface

uses
  Windows,
  strUtils,
  SysUtils,
  Classes,
  Forms,
  idFTPCommon,
  idHTTP,
  Controls,
  StdCtrls,
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  variants,
  NTFileSecurity,
  IdFTP,
  Tlhelp32,
  ExtCtrls,
  CACIC_Library,
  WinSvc,
  ShellAPI,
  Dialogs;

var
  v_TeWebManagerAddress,
  v_TeLocalFolder,
  v_TeProcessInformations,
  v_InShowProcessInformations,
  v_TeSuccessPhrase,
  v_TeInsuccessPhrase,
  v_strLocalVersion,
  v_strRemoteVersion,
  v_strCipherClosed,
  v_strVersao_REM1,
  v_strVersao_LOC1,
  v_strCommResponse     : String;

var
  boolCommandLine : boolean;

var
  tstringlistRequest_Config  : TStringList;
  tstringstreamResponse_Config : TStringStream;

var
  g_oCacic: TCACIC;  /// Biblioteca CACIC_Library

procedure chkcacic;
procedure ComunicaInsucesso(strIndicador : String); //2.2.0.32
Procedure CriaFormConfigura;
Procedure GravaConfiguracoes;
Procedure MostraFormConfigura;

Function CheckAgentVersion(p_strAgentName : String) : integer; // 2.2.0.16
Function DelTree(DirName : string): Boolean; // 2.6.0.2
function FindWindowByTitle(WindowTitle: string): Hwnd;
function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
function GetNetworkUserName : String; // 2.2.0.32
function ListFileDir(Path: string):string;
function Posso_Rodar_CACIC : boolean;
function ServiceStart(sService : string ) : boolean;
function ServiceRunning(sMachine, sService: PChar): Boolean;
function ServiceStopped(sMachine, sService: PChar): Boolean;

type
  TfrmChkCACIC = class(TForm)
    IdFTP1: TIdFTP;
    procedure FormCreate(Sender: TObject);
    procedure FS_SetSecurity(p_Target : String);
    function  CommunicateTo(p_strAddress : String; p_tstringlistPostValues : TStringList) : boolean;
  end;

var
  frmChkCACIC: TfrmChkCACIC;
implementation

uses FormConfig;

{$R *.dfm}


function ServiceGetStatus(sMachine, sService: PChar): DWORD;
  {*******************************************}
  {*** Parameters: ***}
  {*** sService: specifies the name of the service to open
  {*** sMachine: specifies the name of the target computer
  {*** ***}
  {*** Return Values: ***}
  {*** -1 = Error opening service ***}
  {*** 1 = SERVICE_STOPPED ***}
  {*** 2 = SERVICE_START_PENDING ***}
  {*** 3 = SERVICE_STOP_PENDING ***}
  {*** 4 = SERVICE_RUNNING ***}
  {*** 5 = SERVICE_CONTINUE_PENDING ***}
  {*** 6 = SERVICE_PAUSE_PENDING ***}
  {*** 7 = SERVICE_PAUSED ***}
  {******************************************}
var
  SCManHandle, SvcHandle: SC_Handle;
  SS: TServiceStatus;
  dwStat: DWORD;
begin
  dwStat := 0;
  // Open service manager handle.
  g_oCacic.writeDebugLog('Executando OpenSCManager.SC_MANAGER_CONNECT');
  SCManHandle := OpenSCManager(sMachine, nil, SC_MANAGER_CONNECT);
  if (SCManHandle > 0) then
  begin
    g_oCacic.writeDebugLog('Executando OpenService.SERVICE_QUERY_STATUS');
    SvcHandle := OpenService(SCManHandle, sService, SERVICE_QUERY_STATUS);
    // if Service installed
    if (SvcHandle > 0) then
    begin
      g_oCacic.writeDebugLog('O servi�o "'+ sService +'" j� est� instalado.');
      // SS structure holds the service status (TServiceStatus);
      if (QueryServiceStatus(SvcHandle, SS)) then
        dwStat := ss.dwCurrentState;
      CloseServiceHandle(SvcHandle);
    end;
    CloseServiceHandle(SCManHandle);
  end;
  Result := dwStat;
end;

// start service
//
// return TRUE if successful
//
// sService
//   service name, ie: Alerter
//
function ServiceStart(sService : string ) : boolean;
var schm,
    schs   : SC_Handle;

    ss     : TServiceStatus;
    psTemp : PChar;
    dwChkP : DWord;
begin
  ss.dwCurrentState := 0;

  g_oCacic.writeDebugLog('Executando Service Start');

  // connect to the service control manager
  schm := OpenSCManager(Nil,Nil,SC_MANAGER_CONNECT);

  // if successful...
  if(schm > 0)then
    begin
      // open a handle to the specified service
      schs := OpenService(schm,PChar(sService),SERVICE_START or SERVICE_QUERY_STATUS);

      // if successful...
    if(schs > 0)then
      begin
        g_oCacic.writeDebugLog('Open Service OK');
        psTemp := Nil;
        if(StartService(schs,0,psTemp)) then
          begin
            g_oCacic.writeDebugLog('Entrando em Start Service');
            // check status
            if(QueryServiceStatus(schs,ss))then
              begin
                while(SERVICE_RUNNING <> ss.dwCurrentState)do
                  begin
                  // dwCheckPoint contains a value that the service increments periodically
                  // to report its progress during a lengthy operation.
                  dwChkP := ss.dwCheckPoint;

                  // wait a bit before checking status again
                  // dwWaitHint is the estimated amount of time the calling program should wait before calling
                  // QueryServiceStatus() again idle events should be handled here...

                  Sleep(ss.dwWaitHint);

                  if(not QueryServiceStatus(schs,ss))then
                    begin
                      break;
                    end;

                  if(ss.dwCheckPoint < dwChkP)then
                    begin
                      // QueryServiceStatus didn't increment dwCheckPoint as it should have.
                      // avoid an infinite loop by breaking
                      break;
                    end;
                end;
            end
        else
           g_oCacic.writeDebugLog('Oops! Problema com StartService!');
        end;

        // close service handle
        CloseServiceHandle(schs);
      end;

      // close service control manager handle
      CloseServiceHandle(schm);
    end
  else
    Configs.memoProgress.Lines.Add('Oops! Problema com o Service Control Manager!');
    // return TRUE if the service status is running
    Result := SERVICE_RUNNING = ss.dwCurrentState;
end;

function GetNetworkUserName : String;
  //  Gets the name of the user currently logged into the network on
  //  the local PC
var
  temp: PChar;
  Ptr: DWord;
const
  buff = 255;
begin
  ptr := buff;
  temp := StrAlloc(buff);
  GetUserName(temp, ptr);
  Result := string(temp);
  StrDispose(temp);
end;

procedure ComunicaInsucesso(strIndicador : String);
begin

  // Envio notifica��o de insucesso para o M�dulo Gerente Centralizado
  tstringlistRequest_Config.Clear;
  tstringlistRequest_Config.Values['cs_indicador']          := strIndicador;
  tstringlistRequest_Config.Values['id_usuario']            := GetNetworkUserName();
  tstringlistRequest_Config.Values['te_so']                 := g_oCacic.getWindowsStrId();
  Try
    Try
      frmChkCACIC.CommunicateTo(v_TeWebManagerAddress + '/ws/instalacacic.php', tstringlistRequest_Config);
    Except
    End;
  finally
  End;
end;

Procedure CriaFormConfigura;
begin
  g_oCacic.writeDebugLog('Chamando Cria��o do Formul�rio de Configura��es - 1');
  Application.CreateForm(TConfigs, FormConfig.Configs);
  FormConfig.Configs.pnVersao.Caption := 'v: ' + g_oCacic.getVersionInfo(ParamStr(0));
end;

Procedure MostraFormConfigura;
begin
  g_oCacic.writeDebugLog('Exibindo formul�rio de configura��es');
  FormConfig.Configs.ShowModal;
end;

Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
var IdFTP : TIdFTP;
begin
  Try
    g_oCacic.writeDebugLog('FTP: Criando instance');

    IdFTP               := TIdFTP.Create(nil);

    g_oCacic.writeDebugLog('FTP: Host       => "'+p_Host+'"');
    IdFTP.Host          := p_Host;

    g_oCacic.writeDebugLog('FTP: UserName   => "'+p_Username+'"');
    IdFTP.Username      := p_Username;

    g_oCacic.writeDebugLog('FTP: PassWord   => "**********"');
    IdFTP.Password      := p_Password;

    g_oCacic.writeDebugLog('FTP: PathServer => "'+p_PathServer+'"');
    IdFTP.Port          := strtoint(p_Port);

    g_oCacic.writeDebugLog('FTP: Setando TransferType para "ftBinary"');
    IdFTP.TransferType  := ftBinary;

    g_oCacic.writeDebugLog('FTP: Setando Passive para "true"');
    IdFTP.Passive := true;

    g_oCacic.writeDebugLog('FTP: Change to "'+p_PathServer+'"');
    Try
      if IdFTP.Connected = true then
        begin
          g_oCacic.writeDebugLog('FTP: Connected => Desconectando...');
          IdFTP.Disconnect;
        end;
      g_oCacic.writeDebugLog('FTP: Efetuando Conex�o...');
      IdFTP.Connect(true);
      g_oCacic.writeDebugLog('FTP: Change to "'+p_PathServer+'"');
      IdFTP.ChangeDir(p_PathServer);
      Try
        g_oCacic.writeDebugLog('Iniciando FTP de "'+p_Dest + p_File+'"');
        g_oCacic.writeDebugLog('HashCode de "'+p_File+'" Antes do FTP => '+g_oCacic.GetFileHash(p_Dest + p_File));
        IdFTP.Get(p_File, p_Dest + p_File, True, True);
        g_oCacic.writeDebugLog('HashCode de "'+p_Dest + p_File +'" Ap�s o FTP   => '+g_oCacic.GetFileHash(p_Dest + p_File));
      Finally
          Configs.memoProgress.Lines.Add('FTP Conclu�do de "'+p_File+'" para "'+p_Dest+'"');
          g_oCacic.writeDebugLog('HashCode de "'+p_Dest + p_File +'" Ap�s o FTP em Finally   => '+g_oCacic.GetFileHash(p_Dest + p_File));
          IdFTP.Disconnect;
          IdFTP.Free;
          result := true;
      End;
    Except
      Begin
        Configs.memoProgress.Lines.Add('FTP Mal Sucedido de "'+p_File+'"');
        g_oCacic.writeDebugLog('Oops! Problemas Sem In�cio de FTP...');
        result := false;
      End;
    end;
  Except
    result := false;
  End;
end;

// Fun��o para fixar o HomeDrive como letra para a pasta do CACIC
function FixLocalFolder(strLocalFolder : String) : String;
var tstrLocalFolder1,
    tstrLocalFolder2 : TStrings;
    intAUX : integer;
Begin
  Result := strLocalFolder;
  // Crio um array separado por ":" (Para o caso de ter sido informada a letra da unidade)
  tstrLocalFolder1 := TStrings.Create;
  tstrLocalFolder1 := g_oCacic.explode(strLocalFolder,':');

  if (tstrLocalFolder1.Count > 1) then
    Begin
      tstrLocalFolder2 := TStrings.Create;
      // Ignoro a letra informada...
      // Certifico-me de que as barras s�o invertidas... (erros acontecem)
      // Crio um array quebrado por "\"
      Result := StringReplace(tstrLocalFolder1[1],'/','\',[rfReplaceAll]);
      tstrLocalFolder2 := g_oCacic.explode(Result,'\');

      // Inicializo retorno com a unidade raiz do Sistema Operacional
      // Concateno ao retorno as partes que formar�o o caminho completo do CACIC
      Result := g_oCacic.getHomeDrive;
      for intAux := 0 to (tstrLocalFolder2.Count-1) do
        if (tstrLocalFolder2[intAux] <> '') then
            Result := Result + tstrLocalFolder2[intAux] + '\';
      tstrLocalFolder2.Free;
    End
  else
    Result := g_oCacic.getHomeDrive + strLocalFolder + '\';

  tstrLocalFolder1.Free;

  Result := StringReplace(Result,'\\','\',[rfReplaceAll]);
End;

procedure GravaConfiguracoes;
var chkcacic_ini : TextFile;
begin
   try
       g_oCacic.writeDebugLog('g_ocacic => setLocalFolder => '+Configs.Edit_TeLocalFolder.text+'\');

       FileSetAttr (ExtractFilePath(Application.Exename) + '\chkcacic.ini',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(chkcacic_ini,ExtractFilePath(Application.Exename) + '\chkcacic.ini'); {Associa o arquivo a uma vari�vel do tipo TextFile}
       Rewrite(chkcacic_ini); // Recria o arquivo...
       Append(chkcacic_ini);
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# A edi��o deste arquivo tamb�m pode ser feita com o comando "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OBRIGAT�RIOS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# te_web_manager_address');
       Writeln(chkcacic_ini,'#          Endere�o IP ou Nome(DNS) do servidor onde o M�dulo Gerente do CACIC foi instalado');
       Writeln(chkcacic_ini,'#          Ex1.: te_web_manager_address=10.xxx.yyy.zzz');
       Writeln(chkcacic_ini,'#          Ex2.: te_web_manager_address=uxesa001');
       Writeln(chkcacic_ini,'# te_local_folder');
       Writeln(chkcacic_ini,'#          Pasta a ser criada na esta��o para instala��o do CACIC agente principal');
       Writeln(chkcacic_ini,'#          Ex.: te_local_folder=Cacic');
       Writeln(chkcacic_ini,'# in_show_process_informations');
       Writeln(chkcacic_ini,'#          Indicador de exibicao de informa��es sobre o processo de instala��o');
       Writeln(chkcacic_ini,'#          Ex.: in_show_process=N');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OPCIONAIS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# (ATEN��O: N�O PREENCHER EM CASO DE CHKCACIC.INI PARA O NETLOGON!)');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# te_process_informations');
       Writeln(chkcacic_ini,'#          Informa��es a serem mostradas na janela de Instala��o/Recupera��o');
       Writeln(chkcacic_ini,'#          Ex.: Empresa-UF / Suporte T�cnico');
       Writeln(chkcacic_ini,'#                  Emails: email_do_suporte@xxxxxx.yyy.zz, outro_email@outro_dominio.xxx.yy');
       Writeln(chkcacic_ini,'#                  Telefones: (xx) yyyy-zzzz  /  (xx) yyyy-zzzz');
       Writeln(chkcacic_ini,'#                  Endere�o: Rua Nome_da_Rua, N� 99999');
       Writeln(chkcacic_ini,'#                            Cidade/UF');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# Recomenda��o Importante:');
       Writeln(chkcacic_ini,'# =======================');
       Writeln(chkcacic_ini,'# Para benef�cio da rede local, criar uma pasta "Modulos" no mesmo n�vel do chkcacic.exe, onde dever�o');
       Writeln(chkcacic_ini,'# ser colocados todos os arquivos execut�veis para uso do CACIC, pois, quando da necessidade de download');
       Writeln(chkcacic_ini,'# de m�dulo, o arquivo ser� apenas copiado e n�o ser� necess�rio o FTP:');
       Writeln(chkcacic_ini,'# MainProgramName........=> Agente Principal');
       Writeln(chkcacic_ini,'# cacicservice.exe ......=> Servi�o para Sustenta��o do Agente Principal');
       Writeln(chkcacic_ini,'# ger_cols.exe ..........=> Gerente de Coletas');
       Writeln(chkcacic_ini,'# srcacicsrv.exe ........=> Suporte Remoto Seguro');
       Writeln(chkcacic_ini,'# chksis.exe ............=> Check System Routine (chkcacic residente)');
       Writeln(chkcacic_ini,'# wscript.exe ...........=> Motor de Execu��o de Scripts VBS');
       Writeln(chkcacic_ini,'# col_anvi.exe ..........=> Agente Coletor de Informa��es de Anti-V�rus');
       Writeln(chkcacic_ini,'# col_comp.exe ..........=> Agente Coletor de Informa��es de Compartilhamentos');
       Writeln(chkcacic_ini,'# col_hard.exe ..........=> Agente Coletor de Informa��es de Hardware');
       Writeln(chkcacic_ini,'# col_moni.exe ..........=> Agente Coletor de Informa��es de Sistemas Monitorados');
       Writeln(chkcacic_ini,'# col_soft.exe ..........=> Agente Coletor de Informa��es de Software');
       Writeln(chkcacic_ini,'# col_undi.exe ..........=> Agente Coletor de Informa��es de Unidades de Disco');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# Exemplo de estrutura para KIT (CD) de instala��o');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# d:\chkcacic.exe');
       Writeln(chkcacic_ini,'# d:\chkcacic.ini');
       Writeln(chkcacic_ini,'#        \Modulos');
       Writeln(chkcacic_ini,'#             MainProgramName');
       Writeln(chkcacic_ini,'#             cacicservice.exe');
       Writeln(chkcacic_ini,'#             chksis.exe');
       Writeln(chkcacic_ini,'#             col_anvi.exe');
       Writeln(chkcacic_ini,'#             col_comp.exe');
       Writeln(chkcacic_ini,'#             col_hard.exe');
       Writeln(chkcacic_ini,'#             col_moni.exe');
       Writeln(chkcacic_ini,'#             col_soft.exe');
       Writeln(chkcacic_ini,'#             col_undi.exe');
       Writeln(chkcacic_ini,'#             ger_cols.exe');
       Writeln(chkcacic_ini,'#             srcacicsrv.exe');
       Writeln(chkcacic_ini,'#             ini_cols.exe');
       Writeln(chkcacic_ini,'#             wscript.exe');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# Obs.: Antes da grava��o do CD ou imagem, � necess�rio executar "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'[Configs]');

       // Atribui��o dos valores do form FormConfig �s vari�veis...
       if Configs.checkboxInShowProcessInformations.Checked then
         v_InShowProcessInformations             := 'S'
       else
         v_InShowProcessInformations             := 'N';

       v_TeProcessInformations := Configs.Memo_TeExtrasProcessInformations.Text;

       // Escrita dos par�metros obrigat�rios
       Writeln(chkcacic_ini,'TeWebManagerAddress='       + g_oCacic.Encrypt(v_TeWebManagerAddress));
       Writeln(chkcacic_ini,'TeLocalFolder='             + g_oCacic.Encrypt(FixLocalFolder(Configs.Edit_TeLocalFolder.text)));
       Writeln(chkcacic_ini,'InShowProcessInformations=' + g_oCacic.Encrypt(v_InShowProcessInformations));

       // Escrita dos valores opcionais quando existirem
       if (v_TeProcessInformations <>'') then
          Writeln(chkcacic_ini,'TeProcessInformations='+ g_oCacic.Encrypt(StringReplace(v_TeProcessInformations,#13#10,'*13*10',[rfReplaceAll])));
       CloseFile(chkcacic_ini); {Fecha o arquivo texto}

       g_oCacic.setLocalFolder(FixLocalFolder(Configs.Edit_TeLocalFolder.text));
   except
   end;
end;

Function ListFileDir(Path: string):string;
var
  SR: TSearchRec;
  FileList : string;
begin
  if FindFirst(Path, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr <> faDirectory) then
      begin
        if (FileList<>'') then FileList := FileList + '#';
        FileList := FileList + SR.Name;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
    Result := FileList;
  end;
end;


Function CheckAgentVersion(p_strAgentName : String) : integer; // 2.2.0.16
var v_array_AgentName : TStrings;
    intAux : integer;
Begin
  v_array_AgentName := g_oCacic.explode(p_strAgentName,'\');

  v_strRemoteVersion := g_oCacic.xmlGetValue(StringReplace(StrUpper(PChar(v_array_AgentName[v_array_AgentName.count-1])),'.EXE','',[rfReplaceAll]), v_strCommResponse);
  v_strLocalVersion  := g_oCacic.GetVersionInfo(p_strAgentName);

  g_oCacic.writeDebugLog('Checando vers�o de "'+p_strAgentName+'"');

  intAux := v_array_AgentName.Count;

  // V: 2.2.0.16
  // Verifico exist�ncia do arquivo "versoes_agentes.ini" para compara��o das vers�es dos agentes principais
  if (v_strRemoteVersion = '') AND FileExists(ExtractFilePath(Application.Exename)+'versoes_agentes.ini') then
    Begin
      if (g_oCacic.getValueFromFile('versoes_agentes',v_array_AgentName[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
        Begin
          g_oCacic.writeDebugLog('Encontrado arquivo "'+(ExtractFilePath(Application.Exename)+'versoes_agentes.ini')+'"');
          v_strRemoteVersion := g_oCacic.getValueFromFile('versoes_agentes',v_array_AgentName[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
        End;
    End;

  g_oCacic.writeDebugLog('Vers�o Remota: "'+v_strRemoteVersion+'" - Vers�o Local: "'+v_strLocalVersion+'"');

  if (v_strRemoteVersion + v_strLocalVersion <> '') and
     (v_strLocalVersion <> '0000') then
    Begin
      if (v_strRemoteVersion = v_strLocalVersion) then
        Result := 1
      else
        Result := 2;
    End
  else
    Result := 0;
End;

{
http://delphi.about.com/cs/adptips1999/a/bltip1199_2.htm
Use Sample:
if DelTree('c:\TempDir') then
  ShowMessage('Directory deleted!')
else
  ShowMessage('Errors occured!') ;
}

Function DelTree(DirName : string): Boolean;
var
  SHFileOpStruct : TSHFileOpStruct;
  DirBuf : array [0..255] of char;
begin
  try
   Fillchar(SHFileOpStruct,Sizeof(SHFileOpStruct),0) ;
   FillChar(DirBuf, Sizeof(DirBuf), 0 ) ;
   StrPCopy(DirBuf, DirName) ;
   with SHFileOpStruct do begin
    Wnd := 0;
    pFrom := @DirBuf;
    wFunc := FO_DELETE;
    fFlags := FOF_ALLOWUNDO;
    fFlags := fFlags or FOF_NOCONFIRMATION;
    fFlags := fFlags or FOF_SILENT;
   end;
    Result := (SHFileOperation(SHFileOpStruct) = 0) ;
   except
    Result := False;
  end;
end;

function Posso_Rodar_CACIC : boolean;
Begin
  result := false;

  // Se eu conseguir matar o arquivo abaixo � porque n�o h� outra sess�o deste agente aberta... (POG? N���o!  :) )
  g_oCacic.killFiles(g_oCacic.getLocalFolder,'aguarde_CACIC.txt');

  // Se o aguarde_CACIC.txt existir � porque refere-se a uma vers�o mais atual: 2.2.0.20 ou maior
  if  not (FileExists(g_oCacic.getLocalFolder + 'aguarde_CACIC.txt')) then
    result := true;
End;

procedure verifyAndGet(p_strModuleName,
                       p_strFileHash,
                       p_strDestinationFolderName : String);
var v_strFileHash,
    v_strDestinationFolderName : String;
Begin
    v_strDestinationFolderName := p_strDestinationFolderName + '\';
    v_strDestinationFolderName := StringReplace(v_strDestinationFolderName,'\\','\',[rfReplaceAll]);

    g_oCacic.writeDebugLog('Verificando m�dulo: '+v_strDestinationFolderName +p_strModuleName);
    // Verifico validade do M�dulo e mato-o em caso negativo.
    v_strFileHash := g_oCacic.GetFileHash(v_strDestinationFolderName + p_strModuleName);

    g_oCacic.writeDebugLog('verifyAndGet - HashCode Remot: "'+p_strFileHash+'"');
    g_oCacic.writeDebugLog('verifyAndGet - HashCode Local: "'+v_strFileHash+'"');

    If (v_strFileHash <> p_strFileHash) then
      g_oCacic.killFiles(v_strDestinationFolderName, p_strModuleName);

    If not FileExists(v_strDestinationFolderName + p_strModuleName) Then
      Begin
        if (FileExists(ExtractFilePath(Application.Exename) + '\Modulos\'+p_strModuleName)) then
          Begin
            g_oCacic.writeDebugLog('Copiando '+p_strModuleName+' de '+ExtractFilePath(Application.Exename)+'Modulos\');
            CopyFile(PChar(ExtractFilePath(Application.Exename) + 'Modulos\'+p_strModuleName), PChar(v_strDestinationFolderName + p_strModuleName),false);
            FileSetAttr (PChar(v_strDestinationFolderName + p_strModuleName),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED
          End
        else
          begin

            Try
              if not FTP(g_oCacic.xmlGetValue('te_serv_updates'              , v_strCommResponse),
                         g_oCacic.xmlGetValue('nu_porta_serv_updates'        , v_strCommResponse),
                         g_oCacic.xmlGetValue('nm_usuario_login_serv_updates', v_strCommResponse),
                         g_oCacic.xmlGetValue('te_senha_login_serv_updates'  , v_strCommResponse),
                         g_oCacic.xmlGetValue('te_path_serv_updates'         , v_strCommResponse),
                         p_strModuleName,
                         v_strDestinationFolderName) then
                  Configs.memoProgress.Lines.add('ATEN��O! N�o foi poss�vel efetuar FTP para "'+v_strDestinationFolderName + p_strModuleName+'".  Verifique o Servidor de Updates.');
            Except
              g_oCacic.writeDebugLog('FTP de "'+ v_strDestinationFolderName + p_strModuleName+'" Interrompido.');
            End;

            if not FileExists(v_strDestinationFolderName + p_strModuleName) Then
              Begin
                g_oCacic.writeDebugLog('Problemas Efetuando Download de '+ v_strDestinationFolderName + p_strModuleName+' (FTP)');
                g_oCacic.writeDebugLog('Conex�o:');
                g_oCacic.writeDebugLog(g_oCacic.xmlGetValue('te_serv_updates'              , v_strCommResponse)+', '+
                                   g_oCacic.xmlGetValue('nu_porta_serv_updates'        , v_strCommResponse)+', '+
                                   g_oCacic.xmlGetValue('nm_usuario_login_serv_updates', v_strCommResponse)+', '+
                                   g_oCacic.xmlGetValue('te_senha_login_serv_updates'  , v_strCommResponse)+', '+
                                   g_oCacic.xmlGetValue('te_path_serv_updates'         , v_strCommResponse));
              End
            else
                g_oCacic.writeDailyLog('Download Conclu�do de "'+p_strModuleName+'" (FTP)');
          end;
      End;
  End;

function TfrmChkCACIC.CommunicateTo(p_StrAddress : String; p_tstringlistPostValues : TStringList) : boolean;
var IdHTTP1: TIdHTTP;
    v_StrAddress : String;
Begin
  v_StrAddress := 'http://' + StringReplace(StringReplace(LowerCase(p_StrAddress),'//','/',[rfReplaceAll]),'http://','',[rfReplaceAll]);

  Result := false;
  Try
    g_oCacic.writeDailyLog('Iniciando comunica��o com Servidor Gerente WEB do CACIC');
    g_oCacic.writeDebugLog('Endere�o Alvo: "'+v_StrAddress+'"');

    IdHTTP1 := TIdHTTP.Create(nil);
    idHTTP1.AllowCookies                     := true;
    idHTTP1.ASCIIFilter                      := false;
    idHTTP1.AuthRetries                      := 1;
    idHTTP1.BoundPort                        := 0;
    idHTTP1.HandleRedirects                  := false;
    idHTTP1.ProxyParams.BasicAuthentication  := false;
    idHTTP1.ProxyParams.ProxyPort            := 0;
    idHTTP1.ReadTimeout                      := 0;
    idHTTP1.RecvBufferSize                   := 32768;
    idHTTP1.RedirectMaximum                  := 15;
    idHTTP1.Request.Accept                   := 'text/html, */*';
    idHTTP1.Request.BasicAuthentication      := true;
    idHTTP1.Request.ContentLength            := -1;
    idHTTP1.Request.ContentRangeStart        := 0;
    idHTTP1.Request.ContentRangeEnd          := 0;
    idHTTP1.Request.ContentType              := 'text/html';
    idHTTP1.SendBufferSize                   := 32768;
    idHTTP1.Tag                              := 0;

    g_oCacic.writeDebugLog('Efetuando POST...');
    IdHTTP1.Post(v_StrAddress, tstringlistRequest_Config, tstringstreamResponse_Config);
    g_oCacic.writeDebugLog('Retorno: "'+tstringstreamResponse_Config.DataString+'"');
    idHTTP1.Disconnect;
    idHTTP1.Free;

    v_strCommResponse := tstringstreamResponse_Config.DataString;
    Result := (Trim(UpperCase(g_oCacic.xmlGetValue('STATUS', v_strCommResponse))) = 'OK');
    if not boolCommandLine then
      Configs.memoProgress.Lines.Add('Comunica��o bem sucedida com "'+v_StrAddress+'".');
  Except
    Begin
      if not boolCommandLine then
        Configs.memoProgress.Lines.Add('N�o foi poss�vel estabelecer comunica��o com "'+v_StrAddress+'".');

      g_oCacic.writeDailyLog('**********************************************************');
      g_oCacic.writeDailyLog('Oops! N�o Foi Poss�vel Comunicar com o M�dulo Gerente WEB!');
      g_oCacic.writeDailyLog('**********************************************************');
    End
  End;

  g_oCacic.writeDebugLog('Retorno de comunica��o com servidor: '+v_strCommResponse);
End;

procedure chkcacic;
var boolConfigura,
    boolExistsAutoRun,
    boolIniFileExists : boolean;

    v_te_texto_janela_instalacao,
    v_modulos,
    strAux,
    strDateTimeMainProgram_BEGIN,
    strDateTimeGERCOLS_BEGIN,
    strDateTimeMainProgram_END,
    strDateTimeGERCOLS_END : String;

    v_array_modulos : TStrings;
    intAux : integer;

    wordServiceStatus : DWORD;
begin
  strDateTimeMainProgram_BEGIN    := '';
  strDateTimeMainProgram_END      := '';
  strDateTimeGERCOLS_BEGIN        := '';
  strDateTimeGERCOLS_END          := '';
  v_TeSuccessPhrase               := 'INSTALA��O/ATUALIZA��O EFETUADA COM SUCESSO!';
  v_TeInsuccessPhrase             := '*****  INSTALA��O/ATUALIZA��O N�O EFETUADA COM SUCESSO  *****';
  boolCommandLine                 := false;
  boolIniFileExists               := FileExists(ExtractFilePath(Application.Exename) + '\chkcacic.ini');

  g_oCacic := TCACIC.Create();
  g_oCacic.setBoolCipher(true);
  Try

  // 2.2.0.17 - Tratamento de op��es passadas em linha de comando
  // Grande dica do grande Cl�udio Filho (OpenOffice.org)
  if (ParamCount > 0) then
    Begin
      For intAux := 1 to ParamCount do
        Begin
          if LowerCase(Copy(ParamStr(intAux),1,6)) = '/serv=' then
            begin
              strAux := Trim(Copy(ParamStr(intAux),7,Length((ParamStr(intAux)))));
              v_TeWebManagerAddress := Trim(Copy(strAux,0,Pos(' ', strAux) - 1));
              If v_TeWebManagerAddress = '' Then
                v_TeWebManagerAddress := strAux;
              //g_oCacic.writeDailyLog('Par�metro "/serv" => "'+v_TeWebManagerAddress+'"');
            end;

          if LowerCase(Copy(ParamStr(intAux),1,5)) = '/dir=' then
            begin
              strAux := Trim(Copy(ParamStr(intAux),6,Length((ParamStr(intAux)))));
              v_TeLocalFolder := Trim(Copy(strAux,0,Pos(' ', strAux) - 1));
              If v_TeLocalFolder = '' Then
                v_TeLocalFolder := strAux;
              //g_oCacic.writeDailyLog('Par�metro "/dir" => "'+v_TeLocalFolder+'"');
            end;
        end;
        if not(v_TeWebManagerAddress='') and
           not(v_TeLocalFolder='')       then
           boolCommandLine := true;
    End
  else
    Begin
      v_TeWebManagerAddress := 'pwebcgi01/cacic3';
      v_TeLocalFolder       := 'Cacic';
      boolCommandLine      := true;
    End;

  g_oCacic.setWebManagerAddress(v_TeWebManagerAddress);

  // ATEN��O: Trecho para uso exclusivo no �mbito da DATAPREV a n�vel Brasil, para internaliza��o maci�a.
  //          Para envio � Comunidade, retirar as chaves mais abaixo, para que o c�digo padr�o seja descomentado.
  //          Anderson Peterle - NOV2010
  //v_TeWebManagerAddress           := 'UXRJO115';
  //v_cacic_dir                     := 'Cacic';
  //v_exibe_informacoes             := 'N'; // Manter o "N", pois, esse mesmo ChkCacic ser� colocado em NetLogons!

  // Se a chamada ao chkCACIC n�o passou par�metros de IP do Servidor nem Pasta Padr�o...
  // Obs.: Normalmente a chamada com passagem de par�metros � feita por script em servidor de dom�nio, para automatiza��o do processo
  if not boolCommandLine then
    Begin
      If not boolIniFileExists then
        Begin
          CriaFormConfigura;
          MostraFormConfigura;
        End;

      if (FileExists(g_oCacic.getWinDir + 'chksis.ini') and (g_oCacic.getValueFromFile('Configs', 'TeMainProgramHash'  , g_oCacic.getWinDir + 'chksis.ini') = '')) or
         not FileExists(g_oCacic.getWinDir + 'chksis.ini') then
        Begin
          // Vers�o anterior � 2.6 -> Elimino a pasta do sistema e arquivos de configuracoes externos
          Deltree(g_oCacic.getLocalFolder);

          g_oCacic.killFiles(g_oCacic.getWinDir,'chksis.exe');
          g_oCacic.killFiles(g_oCacic.getWinDir,'chksis.ini');
          g_oCacic.killFiles(g_oCacic.getWinDir,'chksis.dat');
          g_oCacic.killFiles(g_oCacic.getWinDir,'chksis.log');
        End;

      if FileExists(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName) then
        ShowMessage('ATEN��O: Ser� necess�rio finalizar o Agente Principal ('+g_oCacic.getMainProgramName+') (Use CTRL ALT DEL)');

      v_TeWebManagerAddress       := g_oCacic.getValueFromFile('Configs', 'TeWebManagerAddress'                 , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_TeLocalFolder             := g_oCacic.getValueFromFile('Configs', 'TeLocalFolder'                       , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_InShowProcessInformations := g_oCacic.getValueFromFile('Configs', 'InShowProcessInformations'           , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_TeProcessInformations     := StringReplace(g_oCacic.getValueFromFile('Configs', 'TeProcessInformations' , ExtractFilePath(Application.Exename) + '\chkcacic.ini'),'*13*10',#13#10,[rfReplaceAll]);
    End;

  // Tratamento do diret�rio informado para o CACIC, para que seja na unidade HomeDrive
  v_TeLocalFolder := FixLocalFolder(v_TeLocalFolder);

  g_oCacic.setLocalFolder(v_TeLocalFolder);
  g_oCacic.checkDebugMode;

  g_oCacic.writeDebugLog('Verificando pasta "'+g_oCacic.getLocalFolder+'"');
  // Verifico a exist�ncia do diret�rio configurado para o Cacic, normalmente CACIC
  if not DirectoryExists(g_oCacic.getLocalFolder) then
      begin
        g_oCacic.writeDailyLog('Criando pasta '+g_oCacic.getLocalFolder);
        ForceDirectories(g_oCacic.getLocalFolder);
      end;

  g_oCacic.writeDebugLog('Verificando pasta "'+g_oCacic.getLocalFolder+'Modulos'+'"');
  // Para eliminar vers�o 20014 e anteriores que provavelmente n�o fazem corretamente o AutoUpdate
  if not DirectoryExists(g_oCacic.getLocalFolder+'Modulos') then
      begin
        g_oCacic.killFiles(g_oCacic.getLocalFolder, g_oCacic.getMainProgramName);
        ForceDirectories(g_oCacic.getLocalFolder + 'Modulos');
        g_oCacic.writeDailyLog('Criando pasta '+g_oCacic.getLocalFolder+'Modulos');
      end;

  g_oCacic.writeDebugLog('Verificando pasta "'+g_oCacic.getLocalFolder+'Temp'+'"');
  // Crio o SubDiret�rio TEMP, caso n�o exista
  if not DirectoryExists(g_oCacic.getLocalFolder+'Temp') then
      begin
        ForceDirectories(g_oCacic.getLocalFolder + 'Temp');
        g_oCacic.writeDailyLog('Criando pasta '+g_oCacic.getLocalFolder+'Temp');
      end;



  g_oCacic.writeDebugLog('Tipo de Drive: '+intToStr(GetDriveType(nil)));

  if not (GetDriveType(nil) = DRIVE_REMOTE) and not boolCommandLine then
    Begin
      g_oCacic.writeDebugLog('Acionando Formul�rio de Configura��o');

      CriaFormConfigura;

      Configs.Visible := true;

      Configs.gbMandatory.BringToFront;
      Configs.gbMandatory.BringToFront;

      Configs.Label_TeWebManagerAddress.BringToFront;
      Configs.Edit_TeWebManagerAddress.Text             := v_TeWebManagerAddress;
      Configs.Edit_TeWebManagerAddress.ReadOnly         := true;
      Configs.Edit_TeWebManagerAddress.BringToFront;

      Configs.Label_TeLocalFolder.BringToFront;
      Configs.Edit_TeLocalFolder.Text                   := v_TeLocalFolder;
      Configs.Edit_TeLocalFolder.ReadOnly               := true;
      configs.Edit_TeLocalFolder.BringToFront;

      Configs.Label_TeProcessInformations.Visible       := false;

      Configs.checkboxInShowProcessInformations.Checked := true;
      Configs.checkboxInShowProcessInformations.Visible := false;

      Configs.Height                                    := 350;
      Configs.lbMensagemNaoAplicavel.Visible            := false;

      Configs.Memo_TeExtrasProcessInformations.Clear;
      Configs.Memo_TeExtrasProcessInformations.Top      := 15;
      Configs.Memo_TeExtrasProcessInformations.Height   := 196;

      Configs.gbMandatory.Caption                       := 'Configura��o';
      Configs.gbMandatory.Visible                       := true;

      Configs.gbOptional.Caption                        := 'Andamento da Instala��o/Atualiza��o';
      Configs.gbOptional.Visible                        := true;

      Configs.Refresh;
      Configs.Show;
    End;

  // Verifica se o S.O. � NT Like e se o Usu�rio est� com privil�gio administrativo...
  if (g_oCacic.isWindowsNTPlataform()) and (g_oCacic.isWindowsAdmin()) then
    Begin
      g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      g_oCacic.writeDebugLog(':::::::::::::: OBTENDO VALORES DO "chkcacic.ini" ::::::::::::::');
      g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      g_oCacic.writeDebugLog('Drive de Instala��o......................: '+g_oCacic.getHomeDrive);
      g_oCacic.writeDebugLog('Pasta para Instala��o Local..............: '+g_oCacic.getLocalFolder);
      g_oCacic.writeDebugLog('Endere�o de Acesso ao Gerente WEB........: '+v_TeWebManagerAddress);
      g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      boolConfigura := false;

      //chave AES. Recomenda-se que cada empresa/�rg�o altere a sua chave.
      //v_tstrCipherOpened := g_oCacic.cipherOpen(g_oCacic.getLocalFolder + g_oCacic.getDatFileName);

      g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      g_oCacic.writeDebugLog(':::::::::::::::::::: LIBERA��O DE FIREWALL ::::::::::::::::::::');
      g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');

      if (g_oCacic.isWindowsGEXP()) then // Se >= Maior ou Igual ao WinXP...
        Begin
          g_oCacic.writeDebugLog(':: S.O. Maior/Igual a WinXP');
          Try
            // Libero as policies do FireWall Interno
            if (g_oCacic.isWindowsGEVista()) then // Maior ou Igual ao VISTA...
              Begin
                g_oCacic.writeDebugLog(':: S.O. Maior/Igual a WinVISTA');
                Try
                  Begin
                    // Liberando as conex�es de Sa�da para o FTP
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getHomeDrive+'system32\\ftp.exe|Name=FTP|Desc=Programa de transfer�ncia de arquivos|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getHomeDrive+'system32\\ftp.exe|Name=FTP|Desc=Programa de transfer�ncia de arquivos|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getHomeDrive+'system32\\ftp.exe|Name=FTP|Desc=Programa de transfer�ncia de arquivos|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getHomeDrive+'system32\\ftp.exe|Name=FTP|Desc=Programa de transfer�ncia de arquivos|Edge=FALSE|');

                    // Liberando as conex�es de Sa�da para o Ger_Cols
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\ger_cols.exe|Name=GerCOLS|Desc=M�dulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\ger_cols.exe|Name=GerCOLS|Desc=M�dulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\ger_cols.exe|Name=GerCOLS|Desc=M�dulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\ger_cols.exe|Name=GerCOLS|Desc=M�dulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');

                    // Liberando as conex�es de Sa�da para o SrCACICsrv
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-SRCACICSRV-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\srcacicsrv.exe|Name=srCACICsrv|Desc=M�dulo Suporte Remoto Seguro do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-SRCACICSRV-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\srcacicsrv.exe|Name=srCACICsrv|Desc=M�dulo Suporte Remoto Seguro do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-SRCACICSRV-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\srcacicsrv.exe|Name=srCACICsrv|Desc=M�dulo Suporte Remoto Seguro do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-SRCACICSRV-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getLocalFolder+'Modulos\\srcacicsrv.exe|Name=srCACICsrv|Desc=M�dulo Suporte Remoto Seguro do Sistema CACIC|Edge=FALSE|');

                    // Liberando as conex�es de Sa�da para o ChkCacic
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkCACIC|Desc=M�dulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkCACIC|Desc=M�dulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkCACIC|Desc=M�dulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkCACIC|Desc=M�dulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');


                    // Liberando as conex�es de Sa�da para o ChkSis
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=M�dulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=M�dulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=M�dulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=M�dulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                  End
                Except
                  g_oCacic.writeDebugLog('Problema Liberando Policies de FireWall!');
                End;
              End
            else
              Begin
                g_oCacic.writeDebugLog(':: S.O. Menor que WinVISTA');
                // Acrescento o ChkCacic e srCACICsrv �s exce��es do FireWall nativo...
                {chkcacic}
                g_oCacic.writeDebugLog('Inserindo "'+ExtractFilePath(Application.Exename) + 'chkcacic" nas exce��es do FireWall!');
                g_oCacic.addApplicationToFirewall('chkCACIC - Instalador do Sistema CACIC',ExtractFilePath(Application.Exename) + Application.Exename,true);
                g_oCacic.addApplicationToFirewall('srCACICsrv - M�dulo de Suporte Remoto Seguro do Sistema CACIC',g_oCacic.getLocalFolder + 'Modulos\srcacicsrv.exe',true);
              End;
          Except
          End;
        End;

      g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');

      if (ParamCount > 0) and (LowerCase(Copy(ParamStr(1),1,7)) = '/config') then
          boolConfigura := true;

      while (v_TeWebManagerAddress = '') or (v_TeLocalFolder = '') or boolConfigura do
          Begin
              boolConfigura := false;
              CriaFormConfigura;

              Configs.Edit_TeWebManagerAddress.text                 := v_TeWebManagerAddress;
              Configs.Edit_TeLocalFolder.text                     := v_TeLocalFolder;
              if v_InShowProcessInformations = 'S' then
                Configs.checkboxInShowProcessInformations.Checked   := true
              else
                Configs.checkboxInShowProcessInformations.Checked   := false;

              Configs.Memo_TeExtrasProcessInformations.text := v_TeProcessInformations;
              MostraFormConfigura;
          End;

      if (ParamCount > 0) and (LowerCase(Copy(ParamStr(1),1,7)) = '/config') then
        Begin
         try
             g_oCacic.Free();
         except
         end;
         Application.Terminate;
        End;

      Try
        // Tento o contato com o m�dulo gerente WEB para obten��o de
        // dados para conex�o FTP e relativos �s vers�es atuais dos principais agentes
        // Busco as configura��es para acesso ao ambiente FTP - Updates
        tstringlistRequest_Config.Values['in_chkcacic'] := 'chkcacic';

        g_oCacic.writeDebugLog('Preparando Chamada ao Gerente WEB: "'+v_TeWebManagerAddress + '/ws/get_config.php"');
        if frmChkCACIC.CommunicateTo(v_TeWebManagerAddress + '/ws/get_config.php', tstringlistRequest_Config) then
          Begin
            g_oCacic.setMainProgramName(LowerCase(g_oCacic.xmlGetValue('te_MainProgramName',v_strCommResponse)));
            g_oCacic.setMainProgramHash(g_oCacic.xmlGetValue('te_MainProgramHash',v_strCommResponse));

            g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
            g_oCacic.writeDebugLog(':::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
            g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
            g_oCacic.writeDebugLog('Servidor de updates......................: ' + g_oCacic.xmlGetValue('te_serv_updates'              , v_strCommResponse));
            g_oCacic.writeDebugLog('Porta do servidor de updates.............: ' + g_oCacic.xmlGetValue('nu_porta_serv_updates'        , v_strCommResponse));
            g_oCacic.writeDebugLog('Usu�rio para login no servidor de updates: ' + g_oCacic.xmlGetValue('nm_usuario_login_serv_updates', v_strCommResponse));
            g_oCacic.writeDebugLog('Pasta no servidor de updates.............: ' + g_oCacic.xmlGetValue('te_path_serv_updates'         , v_strCommResponse));
            g_oCacic.writeDebugLog('Nome do Agente Principal.................: ' + g_oCacic.getMainProgramName);
            g_oCacic.writeDebugLog('C�digo Hash do Agente Principal..........: ' + g_oCacic.getMainProgramHash);
            g_oCacic.writeDebugLog(' ');
            g_oCacic.writeDebugLog('Vers�es dos Agentes Prim�rios:');
            g_oCacic.writeDebugLog('------------------------------');
            g_oCacic.writeDebugLog('Agente Principal.....................: (' +UpperCase( StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','',[rfReplaceAll])) +') '+g_oCacic.xmlGetValue( StringReplace(UpperCase(g_oCacic.getMainProgramName),'.EXE','',[rfReplaceAll]) , v_strCommResponse));
            g_oCacic.writeDebugLog('Gerente de Coletas...................: (GER_COLS) '+g_oCacic.xmlGetValue('GER_COLS', v_strCommResponse));
            g_oCacic.writeDebugLog('Verificador de Integridade do Sistema: (CHKSIS) '+g_oCacic.xmlGetValue('CHKSIS', v_strCommResponse));
            g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          End;
      Except
      End;

      // Se NTFS em NT/2K/XP...
      // If NTFS on NT Like...
      if (g_oCacic.isWindowsNTPlataform()) then
        Begin
          g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          g_oCacic.writeDebugLog('::::::: VERIFICANDO FILE SYSTEM E ATRIBUINDO PERMISS�ES :::::::');
          g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');

          // Atribui��o de acesso ao m�dulo principal e pastas

          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder);
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName);
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + StringReplace(LowerCase(g_oCacic.getMainProgramName),'.exe','.inf',[rfReplaceAll]));
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Logs\' + StringReplace(LowerCase(g_oCacic.getMainProgramName),'.exe','.log',[rfReplaceAll]));
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Temp');

          // Atribui��o de acesso aos m�dulos de gerenciamento de coletas e coletas para permiss�o de atualiza��es de vers�es
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\ger_cols.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\srcacicsrv.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\col_anvi.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\col_comp.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\col_hard.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\col_moni.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\col_soft.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\col_undi.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getLocalFolder + 'Modulos\wscript.exe');

          // Atribui��o de acesso para atualiza��o do m�dulo verificador de integridade do sistema e seus arquivos
          frmChkCACIC.FS_SetSecurity(g_oCacic.getWinDir + 'chksis.exe');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getWinDir + 'chksis.log');
          frmChkCACIC.FS_SetSecurity(g_oCacic.getWinDir + 'chksis.ini');

          // Atribui��o de acesso para atualiza��o/exclus�o de log do instalador
          frmChkCACIC.FS_SetSecurity(g_oCacic.getHomeDrive + 'chkcacic.log');
          g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        End;

      // Verifica��o de vers�o do agente principal e exclus�o em caso de vers�o antiga/diferente da atual
      If (FileExists(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName)) Then
          Begin
            v_strLocalVersion  := trim(g_oCacic.GetVersionInfo(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName));
            v_strRemoteVersion := StringReplace(g_oCacic.xmlGetValue( StringReplace(UpperCase(g_oCacic.getMainProgramName),'.EXE','',[rfReplaceAll]) , v_strCommResponse),'0103','',[rfReplaceAll]);

            // Pego as informa��es de dia/m�s/ano/horas/minutos/segundos/mil�simos que identificam o agente Principal
            strAux := g_oCacic.getLocalFolder + g_oCacic.getMainProgramName;
            strDateTimeMainProgram_BEGIN := FormatDateTime('ddmmyyyyhhnnsszzz', g_oCacic.getFolderDate(strAux));

            g_oCacic.writeDebugLog(':::Verifica��o de Agente Principal :::');
            g_oCacic.writeDebugLog('v_strLocalVersion : "' + v_strLocalVersion + '"');
            g_oCacic.writeDebugLog('v_strRemoteVersion : "' + v_strRemoteVersion + '"');

            if (v_strLocalVersion ='0000') or // Provavelmente vers�o muito antiga ou corrompida
               (v_strLocalVersion ='2208') or
               (v_strLocalVersion <> v_strRemoteVersion) then
               g_oCacic.killFiles(g_oCacic.getLocalFolder, g_oCacic.getMainProgramName);
          End;

      // Verifica��o de vers�o do ger_cols.exe e exclus�o em caso de vers�o antiga/diferente da atual
      If (FileExists(g_oCacic.getLocalFolder + 'Modulos\ger_cols.exe')) Then
        Begin
          strAux := g_oCacic.getLocalFolder + 'Modulos\ger_cols.exe';
          // Pego as informa��es de dia/m�s/ano/horas/minutos/segundos/mil�simos que identificam o agente Ger_Cols
          strDateTimeGERCOLS_BEGIN := FormatDateTime('ddmmyyyyhhnnsszzz', g_oCacic.getFolderDate(strAux));

          intAux := CheckAgentVersion(g_oCacic.getLocalFolder + 'Modulos\ger_cols.exe');
          // 0 => Arquivo de vers�es ou informa��o inexistente
          // 1 => Vers�es iguais
          // 2 => Vers�es diferentes
          if (intAux = 0) then
            Begin
              v_strLocalVersion  := StringReplace(trim(g_oCacic.GetVersionInfo(g_oCacic.getLocalFolder + 'Modulos\ger_cols.exe')),'.','',[rfReplaceAll]);
              v_strRemoteVersion := StringReplace(g_oCacic.xmlGetValue('GER_COLS' , v_strCommResponse),'0103','',[rfReplaceAll]);
            End;

          if (intAux = 2) or // Caso haja diferen�a na compara��o de vers�es com "versoes_agentes.ini"...
             (v_strLocalVersion ='0000') then // Provavelmente vers�o muito antiga ou corrompida
             g_oCacic.killFiles(g_oCacic.getLocalFolder + 'Modulos\', 'ger_cols.exe');
        End;

      // Verifica��o de vers�o do chksis.exe e exclus�o em caso de vers�o antiga/diferente da atual
      If (FileExists(g_oCacic.getWinDir + 'chksis.exe')) Then
        Begin
          intAux := CheckAgentVersion(g_oCacic.getWinDir + 'chksis.exe');
          // 0 => Arquivo de vers�es ou informa��o inexistente
          // 1 => Vers�es iguais
          // 2 => Vers�es diferentes
          if (intAux = 0) then
            Begin
              v_strLocalVersion  := StringReplace(trim(g_oCacic.GetVersionInfo(g_oCacic.getWinDir + 'chksis.exe')),'.','',[rfReplaceAll]);
              v_strRemoteVersion := StringReplace(g_oCacic.xmlGetValue('CHKSIS' , v_strCommResponse),'0103','',[rfReplaceAll]);
            End;

          if (intAux = 2) or // Caso haja diferen�a na compara��o de vers�es com "versoes_agentes.ini"...
             (v_strLocalVersion ='0000') then // Provavelmente vers�o muito antiga ou corrompida
            g_oCacic.killFiles(g_oCacic.getWinDir,'chksis.exe');
        End;

      // Tento detectar o ChkSis.EXE e copio ou fa�o FTP caso n�o exista
      verifyAndGet('chksis.exe',
                    g_oCacic.xmlGetValue('TE_HASH_CHKSIS', v_strCommResponse),
                    g_oCacic.getWinDir);

      // Tento detectar o ChkSis.INI e crio-o caso necess�rio
      If not FileExists(g_oCacic.getWinDir + 'chksis.ini') Then
        begin
          g_oCacic.writeDebugLog('Criando '+g_oCacic.getWinDir + 'chksis.ini');

          g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.Encrypt( v_TeWebManagerAddress)      ,g_oCacic.getWinDir + 'chksis.ini');
          g_oCacic.setValueToFile('Configs','TeLocalFolder'      ,g_oCacic.Encrypt( v_TeLocalFolder)            ,g_oCacic.getWinDir + 'chksis.ini');
          g_oCacic.setValueToFile('Configs','TeMainProgramName'  ,g_oCacic.Encrypt( g_oCacic.getMainProgramName),g_oCacic.getWinDir + 'chksis.ini');

          FileSetAttr ( PChar(g_oCacic.getWinDir + 'chksis.ini'),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
        end;


      // Verifica��o de exist�ncia do CacicService.exe
      g_oCacic.killFiles(g_oCacic.getWinDir,'cacicservice.exe');
      If (g_oCacic.isWindowsNTPlataform()) then
        Begin
          // Tento detectar o CACICservice.EXE e copio ou fa�o FTP caso n�o exista
          verifyAndGet('cacicservice.exe',
                        g_oCacic.xmlGetValue('TE_HASH_CACICSERVICE', v_strCommResponse),
                        g_oCacic.getWinDir);

          // O CACICservice usar� o arquivo de configura��es \Windows\chksis.ini
        End;

      strAux := g_oCacic.getLocalFolder + StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','.inf',[rfReplaceAll]);
      // Tento detectar o arquivo de configura��es/informa��es do Agente Principal e crio-o caso necess�rio
      If not FileExists(strAux) Then
          begin
            g_oCacic.writeDebugLog('Criando/Recriando ' + strAux);

            g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.Encrypt( v_TeWebManagerAddress)      , strAux);
            g_oCacic.setValueToFile('Configs','TeLocalFolder'      ,g_oCacic.Encrypt( v_TeLocalFolder)            , strAux);
            g_oCacic.setValueToFile('Configs','TeMainProgramName'  ,g_oCacic.Encrypt( g_oCacic.getMainProgramName), strAux);
          end;

      // Verifico se existe a pasta "Modulos"
      v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'\Modulos\*.exe');
      if (v_modulos <> '') then g_oCacic.writeDailyLog('Pasta "Modulos" encontrada..');

      // Tento detectar o Agente Principal e copio ou fa�o FTP caso n�o exista
      verifyAndGet(g_oCacic.getMainProgramName,
                   g_oCacic.getMainProgramHash,
                   g_oCacic.getLocalFolder);

      verifyAndGet('ger_cols.exe',
                   g_oCacic.xmlGetValue('TE_HASH_GER_COLS', v_strCommResponse),
                   g_oCacic.getLocalFolder + 'Modulos');

      // Caso exista a pasta "Modulos", copio todos os execut�veis para a pasta Cacic\Modulos, exceto o agente principal, ger_cols.exe e chksis.exe
      if (v_modulos <> '') then
        Begin
          v_array_modulos := g_oCacic.explode(v_modulos,'#');
          For intAux := 0 To v_array_modulos.count -1 Do
            Begin
              if (v_array_modulos[intAux]<> g_oCacic.getMainProgramName) and
                 (v_array_modulos[intAux]<>'ger_cols.exe') and
                 (v_array_modulos[intAux]<>'chksis.exe') then
                Begin
                  g_oCacic.writeDailyLog('Copiando '+v_array_modulos[intAux]+' de '+ExtractFilePath(Application.Exename)+'Modulos\');
                  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'Modulos\'+v_array_modulos[intAux]), PChar(g_oCacic.getLocalFolder + 'Modulos\'+v_array_modulos[intAux]),false);
                  FileSetAttr (PChar(g_oCacic.getLocalFolder + 'Modulos\'+v_array_modulos[intAux]),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
                End;
            End;
        End;

      // ATEN��O:
      // Ap�s testes no Vista, perceb� que o firewall nativo interrompia o FTP e truncava o agente com tamanho zero...
      // A nova tentativa abaixo ajudar� a sobrepor o agente truncado e corrompido

      // Tento detectar (de novo) o ChkSis.EXE e copio ou fa�o FTP caso n�o exista
      verifyAndGet('chksis.exe',
                    g_oCacic.xmlGetValue('TE_HASH_CHKSIS', v_strCommResponse),
                    g_oCacic.getWinDir);

      // Tento detectar (de novo) o Agente Principal e copio ou fa�o FTP caso n�o exista
      verifyAndGet(g_oCacic.getMainProgramName,
                   g_oCacic.getMainProgramHash,
                   g_oCacic.getLocalFolder);

      verifyAndGet('ger_cols.exe',
                   g_oCacic.xmlGetValue('TE_HASH_GER_COLS', v_strCommResponse),
                   g_oCacic.getLocalFolder + 'Modulos');

      if (g_oCacic.isWindowsNTPlataform) then
        Begin
          Try
            // Acrescento o Ger_Cols e srCacicSrv �s exce��es do FireWall nativo...

            {chksis}
            g_oCacic.writeDebugLog('Inserindo "'+g_oCacic.getWinDir + 'chksis" nas exce��es do FireWall!');
            g_oCacic.addApplicationToFirewall('chkSIS - M�dulo Verificador de Integridade do Sistema CACIC',g_oCacic.getWinDir + 'chksis.exe',true);

            {ger_cols}
            g_oCacic.writeDebugLog('Inserindo "'+g_oCacic.getLocalFolder + 'Modulos\ger_cols" nas exce��es do FireWall!');
            g_oCacic.addApplicationToFirewall('gerCOLS - M�dulo Gerente de Coletas do Sistema CACIC',g_oCacic.getLocalFolder+'Modulos\ger_cols.exe',true);

            {srcacicsrv}
            g_oCacic.writeDebugLog('Inserindo "'+g_oCacic.getLocalFolder + 'Modulos\srcacicsrv" nas exce��es do FireWall!');
            g_oCacic.addApplicationToFirewall('srCACICsrv - M�dulo Servidor de Suporte Remoto Seguro do Sistema CACIC',g_oCacic.getLocalFolder+'Modulos\srcacicsrv.exe',true);

          Except
          End;
        End;

      g_oCacic.writeDebugLog('Gravando registros para auto-execu��o');

      // Somente para S.O. NOT NT LIKE
      if NOT (g_oCacic.isWindowsNTPlataform) then
        Begin
          // Crio a chave/valor chksis para autoexecu��o do ChkSIS, caso n�o exista esta chave/valor
          g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine', g_oCacic.getWinDir + 'chksis.exe');

          boolExistsAutoRun := false;
          if (g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\' + StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','',[rfReplaceAll]) )=g_oCacic.getLocalFolder + g_oCacic.getMainProgramName) then
            boolExistsAutoRun := true
          else
            g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\' +StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','',[rfReplaceAll]) , g_oCacic.getLocalFolder + g_oCacic.getMainProgramName);
        End;

      g_oCacic.writeDebugLog('Abrindo Arquivo de Configura��es do ChkSis');

      g_oCacic.setValueToFile('Configs','TeWebManagerAddress'    , g_oCacic.enCrypt(v_TeWebManagerAddress)                                          , g_oCacic.getWinDir + 'chksis.ini');
      g_oCacic.setValueToFile('Configs','TeMainProgramName'      , g_oCacic.enCrypt(g_oCacic.getMainProgramName)                                    , g_oCacic.getWinDir + 'chksis.ini');
      g_oCacic.setValueToFile('Configs','TeMainProgramHash'      , g_oCacic.enCrypt(g_oCacic.getMainProgramHash)                                    , g_oCacic.getWinDir + 'chksis.ini');
      g_oCacic.setValueToFile('Configs','TeLocalFolder'          , g_oCacic.enCrypt(g_oCacic.getLocalFolder)                                        , g_oCacic.getWinDir + 'chksis.ini');
      g_oCacic.setValueToFile('Configs','TeServiceProgramHash'   , g_oCacic.enCrypt(g_oCacic.xmlGetValue('TE_HASH_CACICSERVICE', v_strCommResponse)), g_oCacic.getWinDir + 'chksis.ini');

      // Igualo as chaves TeWebManagerAddress dos arquivos chksis.ini e <agente principal>.ini!

      g_oCacic.writeDebugLog('Abrindo Arquivo de Configura��es do Agente Principal');

      g_oCacic.setValueToFile('Configs','TeWebManagerAddress'   , g_oCacic.enCrypt(v_TeWebManagerAddress)                                           , g_oCacic.getLocalFolder + StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','.inf',[rfReplaceAll]));
      g_oCacic.setValueToFile('Configs','TeMainProgramName'     , g_oCacic.enCrypt(g_oCacic.getMainProgramName)                                     , g_oCacic.getLocalFolder + StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','.inf',[rfReplaceAll]));
      g_oCacic.setValueToFile('Configs','TeMainProgramHash'     , g_oCacic.enCrypt(g_oCacic.getMainProgramHash)                                     , g_oCacic.getLocalFolder + StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','.inf',[rfReplaceAll]));
      g_oCacic.setValueToFile('Configs','TeLocalFolder'         , g_oCacic.enCrypt(g_oCacic.getLocalFolder)                                         , g_oCacic.getLocalFolder + StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','.inf',[rfReplaceAll]));
      g_oCacic.setValueToFile('Configs','TeServiceProgramHash'  , g_oCacic.enCrypt(g_oCacic.xmlGetValue('TE_HASH_CACICSERVICE', v_strCommResponse)) , g_oCacic.getLocalFolder + StringReplace(LowerCase(g_oCacic.getMainProgramName) ,'.exe','.inf',[rfReplaceAll]));

      g_oCacic.writeDebugLog('Resgatando informa��es para identifica��o de altera��o do agente CACIC3');
      // Pego as informa��es de dia/m�s/ano/horas/minutos/segundos/mil�simos que identificam os agentes
      strAux := g_oCacic.getLocalFolder + g_oCacic.getMainProgramName;
      strDateTimeMainProgram_END  := FormatDateTime('ddmmyyyyhhnnsszzz', g_oCacic.getFolderDate(strAux));
      g_oCacic.writeDebugLog('Inicial => "' + strDateTimeMainProgram_BEGIN  + '" Final => "' + strDateTimeMainProgram_END  + '"');

      g_oCacic.writeDebugLog('Resgatando informa��es para identifica��o de altera��o do agente GER_COLS');
      strAux := g_oCacic.getLocalFolder + 'Modulos\ger_cols.exe';
      strDateTimeGERCOLS_END := FormatDateTime('ddmmyyyyhhnnsszzz', g_oCacic.getFolderDate(strAux));
      g_oCacic.writeDebugLog('Inicial => "' + strDateTimeGERCOLS_BEGIN + '" Final => "' + strDateTimeGERCOLS_END + '"');

      // Caso o Cacic tenha sido baixado executo-o com par�metro de configura��o de servidor
      if ((strDateTimeMainProgram_BEGIN <> strDateTimeMainProgram_END) OR
          (strDateTimeGERCOLS_BEGIN <> strDateTimeGERCOLS_END)) then
          Begin
            v_te_texto_janela_instalacao := v_TeProcessInformations;

            if (g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\' + StringReplace(LowerCase(g_oCacic.getMainProgramName),'.exe','',[rfReplaceAll]) )=g_oCacic.getLocalFolder + g_oCacic.getMainProgramName) and
               (not g_oCacic.isWindowsNTPlataform()) or
               (g_oCacic.isWindowsNTPlataform()) and
               not boolCommandLine then
               configs.memoProgress.Lines.Add('Sistema CACIC - '+v_TeSuccessPhrase)
            else
              Begin
                if not boolCommandLine then
                  Configs.memoProgress.Lines.Add('Sistema CACIC - '+v_TeInsuccessPhrase);
                ComunicaInsucesso('1'); // O indicador "1" sinalizar� que n�o foi devido a privil�gio na esta��o
              End;
          End
      else
        g_oCacic.writeDailyLog('ATEN��O: Instala��o N�O REALIZADA ou ATUALIZA��O DESNECESS�RIA!');

      if Posso_Rodar_CACIC or
         not boolExistsAutoRun or
         (strDateTimeMainProgram_BEGIN <> strDateTimeMainProgram_END) then
        Begin
          // Se n�o for plataforma NT executo o agente principal
          if not (g_oCacic.isWindowsNTPlataform()) then
            Begin
              g_oCacic.writeDebugLog('Executando '+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /TeWebManagerAddress=' + v_TeWebManagerAddress);
              if (strDateTimeMainProgram_BEGIN <> strDateTimeMainProgram_END) then
                g_oCacic.createOneProcess(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /TeWebManagerAddress=' + v_TeWebManagerAddress+ ' /execute', false)
              else
                g_oCacic.createOneProcess(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /TeWebManagerAddress=' + v_TeWebManagerAddress , false);
            End
          else
            Begin

              {*** 1 = SERVICE_STOPPED ***}
              {*** 2 = SERVICE_START_PENDING ***}
              {*** 3 = SERVICE_STOP_PENDING ***}
              {*** 4 = SERVICE_RUNNING ***}
              {*** 5 = SERVICE_CONTINUE_PENDING ***}
              {*** 6 = SERVICE_PAUSE_PENDING ***}
              {*** 7 = SERVICE_PAUSED ***}

              // Verifico se o servi�o est� instalado/rodando,etc.
              wordServiceStatus := ServiceGetStatus(nil,'CacicSustainService');
              if (wordServiceStatus = 0) then
                Begin
                  // Instalo e Habilito o servi�o
                  g_oCacic.writeDailyLog('Instalando o CACICservice...');
                  g_oCacic.createOneProcess(g_oCacic.getWinDir + 'cacicservice.exe /install /silent',true);
                  g_oCacic.createOneProcess(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /TeWebManagerAddress=' + v_TeWebManagerAddress+ ' /execute', false)
                End
              else if (wordServiceStatus < 4)  then
                Begin
                  g_oCacic.writeDailyLog('Iniciando o CACICservice');
                  g_oCacic.createOneProcess(g_oCacic.getWinDir + 'cacicservice.exe -start', true);
                End
              else if (wordServiceStatus > 4)  then
                Begin
                  g_oCacic.writeDailyLog('Continuando o CACICservice');
                  g_oCacic.createOneProcess(g_oCacic.getWinDir + 'cacicservice.exe -continue', true);
                End
              else
                  g_oCacic.writeDailyLog('N�o instalei/iniciei o CACICservice. J� est� rodando...');
            End;

          if Posso_Rodar_CACIC and not boolCommandLine then
            MessageDLG(#13#10+'ATEN��O! � recomend�vel a reinicializa��o do sistema para in�cio de a��es do CACIC.',mtInformation,[mbOK],0);

        End
      else
        g_oCacic.writeDebugLog('Chave de Auto-Execu��o j� existente ou Execu��o j� iniciada...');
    End
  else
    Begin // Se NT/2000/XP/...
      if (v_InShowProcessInformations = 'S') and not boolCommandLine then
        MessageDLG(#13#10+'ATEN��O! Essa aplica��o requer execu��o com n�vel administrativo.',mtError,[mbOK],0);
      g_oCacic.writeDailyLog('Sem Privil�gios: Necess�rio ser administrador "local" da esta��o');
      ComunicaInsucesso('0'); // O indicador "0" (zero) sinalizar� falta de privil�gio na esta��o
    End;
  Except
    g_oCacic.writeDailyLog('Falha na Instala��o/Atualiza��o');
  End;

  try
    g_oCacic.Free;
  except
  end;

  Application.Terminate;
end;

function ServiceRunning(sMachine, sService: PChar): Boolean;
begin
  Result := SERVICE_RUNNING = ServiceGetStatus(sMachine, sService);
end;

function ServiceStopped(sMachine, sService: PChar): Boolean;
begin
  Result := SERVICE_STOPPED = ServiceGetStatus(sMachine, sService);
end;

function FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  NextTitle: array[0..260] of char;
begin
  // Get the first window
  NextHandle := GetWindow(Application.Handle, GW_HWNDFIRST);
  while NextHandle > 0 do
  begin
    // retrieve its text
    GetWindowText(NextHandle, NextTitle, 255);

    if (trim(StrPas(NextTitle))<> '') and (Pos(strlower(pchar(WindowTitle)), strlower(PChar(StrPas(NextTitle)))) <> 0) then
    begin
      Result := NextHandle;
      Exit;
    end
    else
      // Get the next window
      NextHandle := GetWindow(NextHandle, GW_HWNDNEXT);
  end;
  Result := 0;
end;

procedure TfrmChkCACIC.FormCreate(Sender: TObject);
begin
  Application.ShowMainForm     :=  false;
  tstringlistRequest_Config    := TStringList.Create;
  tstringstreamResponse_Config := TStringStream.Create('');

  chkcacic;

  Application.Terminate;
end;

procedure TfrmChkCACIC.FS_SetSecurity(p_Target : String);
var intAux : integer;
    v_FS_Security : TNTFileSecurity;
begin
  v_FS_Security := TNTFileSecurity.Create(nil);
  v_FS_Security.FileName := '';
  v_FS_Security.FileName := p_Target;
  v_FS_Security.RefreshSecurity;

  if (v_FS_Security.FileSystemName='NTFS')then
    Begin
      for intAux := 0 to Pred(v_FS_Security.EntryCount) do
        begin
          case v_FS_Security.EntryType[intAux] of seAlias, seDomain, seGroup :
            Begin   // If local group, alias or user...
              v_FS_Security.FileRights[intAux]       := [faAll];
              v_FS_Security.DirectoryRights[intAux]  := [faAll];
              g_oCacic.writeDebugLog(p_Target + ' [Full Access] >> '+v_FS_Security.EntryName[intAux]);
              //Setting total access on p_Target to local groups.
            End;
          End;
        end;

      // Atribui permiss�o total aos grupos locais
      // Set total permissions to local groups
      v_FS_Security.SetSecurity;
    end
  else
    g_oCacic.writeDailyLog('File System: "' + v_FS_Security.FileSystemName+'" - Ok!');

  v_FS_Security.Free;
end;
end.
