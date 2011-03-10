(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009 Dataprev - Empresa de Tecnologia e Informa��es da Previd�ncia Social, Brasil

Este arquivo � parte do programa CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais

O CACIC � um software livre; voc� pode redistribui-lo e/ou modifica-lo dentro dos termos da Licen�a P�blica Geral GNU como
publicada pela Funda��o do Software Livre (FSF); na vers�o 2 da Licen�a, ou (na sua opini�o) qualquer vers�o.

Este programa � distribuido na esperan�a que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUA��O a qualquer
MERCADO ou APLICA��O EM PARTICULAR. Veja a Licen�a P�blica Geral GNU para maiores detalhes.

Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral GNU, sob o t�tulo "LICENCA.txt", junto com este programa, se n�o, escreva para a Funda��o do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)
unit CACICserviceMain;

interface
uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  SvcMgr,
  ExtCtrls,
  CACIC_Library,
  tlhelp32,
  JwaWinNT,    { As units com prefixo Jwa constam do Pacote Jedi_API22a }
  JwaWinBase,  { que pode ser obtido em  http://sourceforge.net/projects/jedi-apilib/files/JEDI%20Windows%20API/JEDI%20API%202.2a%20and%20WSCL%200.9.2a/jedi_api22a_jwscl092a.zip/download }
  JwaWtsApi32,
  JwaWinSvc,
  JwaWinType,
  JwaNtStatus,
  Registry;

var
  intContaMinutos : integer;
  g_oCacic      : TCACIC;

const
  SE_DEBUG_NAME = 'SeDebugPrivilege';

type
  TCacicSustainService = class(TService)
    Timer_CHKsis: TTimer;
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure Timer_CHKsisTimer(Sender: TObject);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private

    { Internal Start & Stop methods }
    Procedure WMEndSession(var Msg : TWMEndSession) ;  message WM_ENDSESSION;
    procedure ExecutaCACIC;
//    procedure writeLog(strMsg : String);
    function  startapp(p_TargetFolderName, p_ApplicationName : String) : integer;

  public
    { Public declarations }

    function GetServiceController: TServiceController; override;
  end;

var
  CacicSustainService: TCacicSustainService;

function  CreateEnvironmentBlock(var lpEnvironment: Pointer;
                                 hToken: THandle;
                                 bInherit: BOOL): BOOL; stdcall; external 'userenv';
function  DestroyEnvironmentBlock(pEnvironment: Pointer): BOOL; stdcall; external 'userenv';

implementation

{$R *.DFM}

// Solu��o adaptada a partir do exemplo contido em http://www.codeproject.com/KB/vista-security/VistaSessions.aspx?msg=2750630
// para execu��o a partir de token do WinLogon, possibilitando a exibi��o do �cone da aplica��o na bandeja do systray em
// plataforma Microsoft Windows VISTA.
function TCacicSustainService.startapp(p_TargetFolderName, p_ApplicationName : String) : integer;
var
   pi : PROCESS_INFORMATION;
   si : STARTUPINFO;
   bresult : boolean;
   dwSessionId,winlogonPid : DWORD;
   hUserToken,hUserTokenDup,hPToken,hProcess,hsnap : THANDLE;
   dwCreationFlags : DWORD;
   procEntry : TPROCESSENTRY32;
   winlogonSessId : DWORD;
   tp : TOKEN_PRIVILEGES;
 //  luid : TLargeInteger;
   abcd, abc, dup : integer;
   lpenv : pointer;
   iResultOfCreateProcessAsUser : integer;

begin
  g_oCacic.writeDebugLog('TCACICservice.startapp : ' + p_TargetFolderName + p_ApplicationName);
  Result := 0;
  bresult := false;

  //TOKEN_ADJUST_SESSIONID := 256;

  // Log the client on to the local computer.


  dwSessionId := WTSGetActiveConsoleSessionId();
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hSnap = INVALID_HANDLE_VALUE) then
    begin
      result := 1;
      g_oCacic.writeDebugLog('TCACICservice.startapp : Error => INVALID_HANDLE_VALUE');
      exit;
    end;

  procEntry.dwSize := sizeof(TPROCESSENTRY32);

  if (not Process32First(hSnap, procEntry)) then
    begin
      result := 1;
      g_oCacic.writeDebugLog('TCACICservice.startapp : Error => not Process32First');
      exit;
    end;

  repeat
  if (comparetext(procEntry.szExeFile, 'winlogon.exe') = 0) then
    begin
      g_oCacic.writeDebugLog('TCACICservice.startapp : Winlogon Founded');
      // We found a winlogon process...

      // make sure it's running in the console session

      winlogonSessId := 0;
      if (ProcessIdToSessionId(procEntry.th32ProcessID, winlogonSessId) and (winlogonSessId = dwSessionId)) then
        begin
          winlogonPid := procEntry.th32ProcessID;
          g_oCacic.writeDebugLog('TCACICservice.startapp : ProcessIdToSessionId OK => ' + IntToStr(winlogonPid));
          break;
        end;
    end;

  until (not Process32Next(hSnap, procEntry));

  ////////////////////////////////////////////////////////////////////////

  WTSQueryUserToken(dwSessionId, hUserToken);
  dwCreationFlags := NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE;
  ZeroMemory(@si, sizeof(STARTUPINFO));
  si.cb := sizeof(STARTUPINFO);
  si.lpDesktop := 'winsta0\default';
  ZeroMemory(@pi, sizeof(pi));
  hProcess := OpenProcess(MAXIMUM_ALLOWED,FALSE,winlogonPid);

  if(not OpenProcessToken(hProcess,TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY
                 or TOKEN_DUPLICATE or TOKEN_ASSIGN_PRIMARY or TOKEN_ADJUST_SESSIONID
                          or TOKEN_READ or TOKEN_WRITE, hPToken)) then
    begin
      abcd := GetLastError();
      g_oCacic.writeDebugLog('TCACICservice.startApp : Process token open Error => ' + inttostr(GetLastError()));
    end;

  if (not LookupPrivilegeValue(nil,SE_DEBUG_NAME,tp.Privileges[0].Luid)) then
      g_oCacic.writeDebugLog('TCACICservice.startApp : Lookup Privilege value Error => ' + inttostr(GetLastError()));

  tp.PrivilegeCount := 1;
  tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

  DuplicateTokenEx(hPToken,MAXIMUM_ALLOWED,Nil,SecurityIdentification,TokenPrimary,hUserTokenDup);
  dup := GetLastError();

  // Adjust Token privilege

  SetTokenInformation(hUserTokenDup,TokenSessionId,pointer(dwSessionId),sizeof(DWORD));

  if (not AdjustTokenPrivileges(hUserTokenDup,FALSE,@tp,sizeof(TOKEN_PRIVILEGES),nil,nil)) then
    begin
      abc := GetLastError();
      g_oCacic.writeDebugLog('TCACICservice.startApp : Adjust Privilege value Error => ' + inttostr(GetLastError()));
    end;

  if (GetLastError() = ERROR_NOT_ALL_ASSIGNED) then
      g_oCacic.writeDebugLog('TCACICservice.startApp : Token does not have the provilege');

  lpEnv := nil;

  if(CreateEnvironmentBlock(lpEnv,hUserTokenDup,TRUE)) then
      dwCreationFlags := dwCreationFlags or CREATE_UNICODE_ENVIRONMENT
  else
    lpEnv := nil;

  // Launch the process in the client's logon session.
  bResult := CreateProcessAsUser( hUserTokenDup,                        // client's access token
                                  PAnsiChar(p_TargetFolderName + p_ApplicationName), // file to execute
                                  nil,                                  // command line
                                  nil,                                  // pointer to process SECURITY_ATTRIBUTES
                                  nil,                                  // pointer to thread SECURITY_ATTRIBUTES
                                  FALSE,                                // handles are not inheritable
                                  dwCreationFlags,                      // creation flags
                                  lpEnv,                                // pointer to new environment block
                                  PAnsiChar(p_TargetFolderName),   // name of current directory
                                  si,                                   // pointer to STARTUPINFO structure
                                  pi                                    // receives information about new process
                                 );

  // End impersonation of client.
  //GetLastError Shud be 0
  iResultOfCreateProcessAsUser := GetLastError();

  //Perform All the Close Handles tasks
  CloseHandle(hProcess);
  CloseHandle(hUserToken);
  CloseHandle(hUserTokenDup);
  CloseHandle(hPToken);

end;
//
procedure TCacicSustainService.WMEndSession(var Msg : TWMEndSession) ;
begin
  if Msg.EndSession = TRUE then
    g_oCacic.writeDebugLog('TCACICservice.WMEndSession : Windows finalizado em ' + FormatDateTime('dd/mm hh:nn:ss : ', Now)) ;
  inherited;
  Application.Free;
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  CacicSustainService.Controller(CtrlCode);
end;

function TCacicSustainService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TCacicSustainService.ServiceExecute(Sender: TService);
begin
  { Loop while service is active in SCM }
  While NOT Terminated do
  Begin
      { Process Service Requests }
      ServiceThread.ProcessRequests( False );
      { Allow system some time }
      Sleep(1);
  End;
end;

procedure TCacicSustainService.ServiceStart(Sender: TService; var Started: Boolean);
begin

  g_oCacic := TCACIC.Create;
  g_oCacic.setBoolCipher(true);

  // ATEN��O: A propriedade "Interactive" em FALSE para S.O. menor que VISTA inibe a exibi��o gr�fica para o servi�o e seus herdeiros,
  //          e assim o �cone da aplica��o n�o � mostrado na bandeja do sistema.
  Self.Interactive := not g_oCacic.isWindowsGEVista;

  g_oCacic.setLocalFolder(    g_oCacic.deCrypt(g_oCacic.GetValueFromFile('Configs', 'TeLocalFolder'    , g_oCacic.getWinDir + 'chksis.ini')));
  g_oCacic.setMainProgramName(g_oCacic.deCrypt(g_oCacic.GetValueFromFile('Configs', 'TeMainProgramName', g_oCacic.getWinDir + 'chksis.ini')));
  g_oCacic.setMainProgramHash(g_oCacic.deCrypt(g_oCacic.GetValueFromFile('Configs', 'TeMainProgramHash', g_oCacic.getWinDir + 'chksis.ini')));

  g_oCacic.checkDebugMode;

  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : O.S. Identification');
  g_oCacic.writeDebugLog('************************************************');
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindowsVista => '        + BoolToStr(g_oCacic.isWindowsVista       ,true) );
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindowsGEVista => '      + BoolToStr(g_oCacic.isWindowsGEVista     ,true) );
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindowsXP => '           + BoolToStr(g_oCacic.isWindowsXP          ,true) );
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindowsGEXP => '         + BoolToStr(g_oCacic.isWindowsGEXP        ,true) );
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindowsNTPlataform => '  + BoolToStr(g_oCacic.isWindowsNTPlataform ,true) );
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindows2000 => '         + BoolToStr(g_oCacic.isWindows2000        ,true) );
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindowsNT => '           + BoolToStr(g_oCacic.isWindowsNT          ,true) );
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : isWindows9xME => '         + BoolToStr(g_oCacic.isWindows9xME        ,true) );
  g_oCacic.writeDebugLog('************************************************');

  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : Interactive Mode=> '       + BoolToStr(Self.Interactive,true));
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : setLocalFolder => '        + g_oCacic.getLocalFolder());
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : setMainProgramName => '    + g_oCacic.getMainProgramName());
  g_oCacic.writeDebugLog('TCACICservice.ServiceStart : setMainProgramHash => '    + g_oCacic.getMainProgramHash());

  Started := true;

  ExecutaCACIC;

  // Intervalo de 1 minuto (60 segundos)
  // Normalmente a cada 120 minutos (2 horas) acontecer� a chamada ao chkSIS
  Timer_CHKsis.Interval := 60000;
  Timer_CHKsis.Enabled  := true;

  While not Terminated do
    Sleep(250);
end;

procedure TCacicSustainService.ExecutaCACIC;
Begin

  g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : BEGIN');

  g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : deleteFile => '+g_oCacic.getLocalFolder + 'aguarde_CACIC.txt');
  DeleteFile(PAnsiChar(g_oCacic.getLocalFolder + 'aguarde_CACIC.txt'));
  DeleteFile(PAnsiChar(g_oCacic.getLocalFolder + 'Temp\aguarde_UPDATE.txt'));
  Sleep(3000);

  g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Verificando "aguarde_CACIC.txt" e "aguarde_UPDATE.txt"');
  if not (FileExists(g_oCacic.getLocalFolder + 'aguarde_CACIC.txt')) and
     not (FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_UPDATE.txt')) then
    Begin
      // Se o arquivo indicador de execu��o n�o existir...
      g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : O arquivo "aguarde_CACIC.txt" n�o existe!');
      g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Invocando "chkSIS.exe" para verifica��o.');
      // Executo o CHKsis, verificando a estrutura do sistema
      Try
        if (g_oCacic.isWindowsGEVista) then
          Begin
            g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Ativando StartAPP('+g_oCacic.getWinDir+',chksis.exe)');
            CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
          End
        else
          Begin
            g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Ativando CreateSampleProcess(' + g_oCacic.getWinDir + 'chksis.exe)');
            g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
          End;
      Except
      End;

      Sleep(5000); // Espera de 5 segundos para o caso de n�o existir o Agente Principal...

      if FileExists(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName) then
        Begin
          g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Encontrado Agente Principal (' + g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName + ') com vers�o "' + g_oCacic.GetVersionInfo(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName) + '" para atualiza��o');

          CopyFile(PAnsiChar(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName),PAnsiChar(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName),false);
          Sleep(2000);

          // A fun��o MoveFile n�o estava excluindo o arquivo da origem. (???)
          DeleteFile(PAnsiChar(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName));
          Sleep(2000);

          // VERIFICO O HASH CODE DO AGENTE PRINCIPAL...
          g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : HASH Code do INI: "'+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs', 'TeMainProgramHash', g_oCacic.getWinDir + 'chksis.ini'))+'"');
          g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : HASH Code de "'+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName+'": "'+g_oCacic.getFileHash(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName)+'"');

          if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs', 'TeMainProgramHash', g_oCacic.getWinDir + 'chksis.ini')) = g_oCacic.getFileHash(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName) ) then
            Begin
              g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Agente Principal v�lido para execu��o!');
              // Executo o Agente Principal do CACIC
              if (g_oCacic.isWindowsGEVista) then
                CacicSustainService.startapp(g_oCacic.getLocalFolder,g_oCacic.getMainProgramName)
              else
                g_oCacic.createOneProcess(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName,false,SW_NORMAL);
            End
          else
            g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : HASH Code do Agente Principal INV�LIDO ou DIFERENTE');
        End
      else
        g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Arquivo "'+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName+'" N�O ENCONTRADO!');
    End
  else
    g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Cookie Bloqueado pelo Agente Principal ENCONTRADO - CACIC em Execu��o!');

  g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Verificando exist�ncia de nova vers�o deste servi�o para atualiza��o.');
  // Verifico a exist�ncia de nova vers�o do servi�o e finalizo em caso positivo...
  if (FileExists(g_oCacic.getWinDir + 'Temp\cacicservice.exe')) and
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs', 'TeServiceProgramHash', g_oCacic.getWinDir + 'chksis.ini')) = g_oCacic.getFileHash(g_oCacic.getWinDir + 'Temp\cacicservice.exe')) then
    Begin
        g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : TeServiceProgramHash => '+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs', 'TeServiceProgramHash', g_oCacic.getWinDir + 'chksis.ini')) );
        g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : Terminando para execu��o de atualiza��o...');
        CacicSustainService.ServiceThread.Terminate;
    End
  else
    g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : N�o foi encontrada nova vers�o disponibilizada deste servi�o.');

  g_oCacic.writeDebugLog('TCACICservice.ExecutaCACIC : END');
End;

procedure TCacicSustainService.Timer_CHKsisTimer(Sender: TObject);
begin
  g_oCacic.checkDebugMode;
  g_oCacic.writeDebugLog('TCACICservice.Timer_CHKsisTimer - BEGIN');

  inc(intContaMinutos);

  // A cada 2 horas o Verificador de Integridade do Sistema ser� chamado
  // Caso o DEBUG esteja ativo esse intervalo se reduz a 3 minutos
  if (intContaMinutos = 120) or (g_oCacic.inDebugMode and (intContaMinutos = 3))then
    Begin
      intContaMinutos := 0;
      g_oCacic.writeDebugLog('TCACICservice.Timer_CHKsisTimer : Criando processo "'+g_oCacic.getWinDir + 'chksis.exe');
      Try
        if (g_oCacic.isWindowsGEVista) then
            CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
        else
            g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
      Except
      End;
    End;

  g_oCacic.writeDebugLog('TCACICservice.Timer_CHKsisTimer - Chamando ExecutaCACIC...');

  ExecutaCACIC;

  g_oCacic.writeDebugLog('TCACICservice.Timer_CHKsisTimer - END');
end;

procedure TCacicSustainService.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  g_oCacic.writeDebugLog('TCACICservice.ServiceStop');
  Stopped := true;
end;

end.
