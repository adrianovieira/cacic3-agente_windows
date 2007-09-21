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

unit main;

interface

uses  Windows,
      Messages,
      Forms,
      Menus,
      Classes,
      SysUtils,
      Controls,
      StdCtrls,
      ExtCtrls,
      ShellAPI,
      registry,
      dialogs,
      PJVersionInfo,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64, ComCtrls;


const WM_MYMESSAGE = WM_USER+100;

// Declara��o das vari�veis globais.
var p_path_cacic,
    p_path_cacic_ini,
    p_Shell_Command,
    p_Shell_Path,
    v_versao        : string;
    BatchFile : TStringList;
    v_icon_tray : integer;
    v_CipherKey,
    v_SeparatorKey,
    v_IV,
    v_DatFileName,
    v_DataCacic2DAT,
    v_Tamanho_Arquivo,
    v_te_so                   : string;
    v_tstrCipherOpened        : TStrings;
    v_Debugs                  : Boolean;

type
  TFormularioGeral = class(TForm)
    Pn_InfosGerais: TPanel;
    Bt_Fechar_InfosGerais: TButton;
    Pn_SisMoni: TPanel;
    Lb_SisMoni: TLabel;
    Pn_TCPIP: TPanel;
    Lb_TCPIP: TLabel;
    GB_InfosTCPIP: TGroupBox;
    ST_VL_MacAddress: TStaticText;
    ST_LB_MacAddress: TStaticText;
    ST_LB_NomeHost: TStaticText;
    ST_VL_NomeHost: TStaticText;
    ST_LB_IpEstacao: TStaticText;
    ST_LB_IpRede: TStaticText;
    ST_LB_DominioDNS: TStaticText;
    ST_LB_DnsPrimario: TStaticText;
    ST_LB_DnsSecundario: TStaticText;
    ST_LB_Gateway: TStaticText;
    ST_LB_Mascara: TStaticText;
    ST_LB_ServidorDHCP: TStaticText;
    ST_LB_WinsPrimario: TStaticText;
    ST_LB_WinsSecundario: TStaticText;
    ST_VL_IpEstacao: TStaticText;
    ST_VL_DNSPrimario: TStaticText;
    ST_VL_DNSSecundario: TStaticText;
    ST_VL_Gateway: TStaticText;
    ST_VL_Mascara: TStaticText;
    ST_VL_ServidorDHCP: TStaticText;
    ST_VL_WinsPrimario: TStaticText;
    ST_VL_WinsSecundario: TStaticText;
    ST_VL_DominioDNS: TStaticText;
    ST_VL_IpRede: TStaticText;
    Pn_Linha1_TCPIP: TPanel;
    Pn_Linha2_TCPIP: TPanel;
    Pn_Linha3_TCPIP: TPanel;
    Pn_Linha4_TCPIP: TPanel;
    Pn_Linha6_TCPIP: TPanel;
    Pn_Linha5_TCPIP: TPanel;
    Timer_Nu_Intervalo: TTimer;
    Timer_Nu_Exec_Apos: TTimer;
    PopupMenu1: TPopupMenu;
    Mnu_LogAtividades: TMenuItem;
    Mnu_Configuracoes: TMenuItem;
    Mnu_ExecutarAgora: TMenuItem;
    Mnu_InfosTCP: TMenuItem;
    Mnu_InfosPatrimoniais: TMenuItem;
    Mnu_FinalizarCacic: TMenuItem;
    listSistemasMonitorados: TListView;
    Panel1: TPanel;
    Label1: TLabel;
    listaColetas: TListView;
    lbDataColeta: TLabel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure RemoveIconesMortos;
    procedure ChecaCONFIGS;
    procedure CriaFormSenha(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function  ChecaGERCOLS : boolean;
    procedure Sair(Sender: TObject);
    procedure MinimizaParaTrayArea(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ExecutaCacic(Sender: TObject);
    procedure SetaVariaveisGlobais;
    procedure Log_Diario(strMsg : String);
    procedure Log_DEBUG(p_msg : string);
    procedure ExibirLogAtividades(Sender: TObject);
    procedure ExibirConfiguracoes(Sender: TObject);
    procedure Mnu_InfosPatrimoniaisClick(Sender: TObject);
    procedure HabilitaTCP;
    procedure HabilitaPatrimonio;
    procedure Matar(v_dir,v_files: string);
    Procedure DelValorReg(Chave: String);

    function  GetRootKey(strRootKey: String): HKEY;
    function  GetWinVer: Integer;
    function  FindWindowByTitle(WindowTitle: string): Hwnd;
    function  GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    Function  RemoveZerosFimString(Texto : String) : String;
    procedure Mnu_InfosTCPClick(Sender: TObject);
    procedure Bt_Fechar_InfosGeraisClick(Sender: TObject);
    function  Get_File_Size(sFileToExamine: string; bInKBytes: Boolean): string;
    function  Posso_Rodar : boolean;
    function  abstraiCSD(p_te_so : String) : integer;    
  private
    ShutdownEmExecucao : Boolean;
    IsMenuOpen : Boolean;
    NotifyStruc : TNotifyIconData; {Estrutura do tray icon}
    procedure InicializaTray(v_Hint:string);
    procedure Finaliza;
    procedure Invoca_GerCols(Sender: TObject;p_acao:string);
    function  GetVersionInfo(p_File: string):string;
    function  VerFmt(const MS, LS: DWORD): string;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure TrayMessage(var Msg: TMessage); message WM_MYMESSAGE; {The tray procedure to look for mouse input}
    // A procedure WMQueryEndSession � usada para detectar o
    // Shutdown do Windows e "derrubar" o Cacic.
    procedure WMQueryEndSession(var Msg : TWMQueryEndSession); Message WM_QUERYENDSESSION;
    procedure WMMENUSELECT(var msg: TWMMENUSELECT); message WM_MENUSELECT;
  public
    Function  Implode(p_Array : TStrings ; p_Separador : String) : String;
    function  HomeDrive : string;
    function  GetFolderDate(Folder: string): TDateTime;
    Function  CipherClose : String;
    Function  CipherOpen : TStrings;
    Function  Explode(Texto, Separador : String) : TStrings;
    Function  GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
    Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
    function  PadWithZeros(const str : string; size : integer) : string;
    function  EnCrypt(p_Data : String) : String;
    function  DeCrypt(p_Data : String) : String;

  end;

var FormularioGeral: TFormularioGeral;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

implementation


{$R *.dfm}

Uses StrUtils, Inifiles, frmConfiguracoes, frmSenha, frmLog;

// Pad a string with zeros so that it is a multiple of size
function TFormularioGeral.PadWithZeros(const str : string; size : integer) : string;
var
  origsize, i : integer;
begin
  Result := str;
  origsize := Length(Result);
  if ((origsize mod size) <> 0) or (origsize = 0) then
  begin
    SetLength(Result,((origsize div size)+1)*size);
    for i := origsize+1 to Length(Result) do
      Result[i] := #0;
  end;
end;


// Encrypt a string and return the Base64 encoded result
function TFormularioGeral.EnCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    // Pad Key, IV and Data with zeros as appropriate
    l_Key   := PadWithZeros(v_CipherKey,KeySize);
    l_IV    := PadWithZeros(v_IV,BlockSize);
    l_Data  := PadWithZeros(p_Data,BlockSize);

    // Create the cipher and initialise according to the key length
    l_Cipher := TDCP_rijndael.Create(nil);
    if Length(v_CipherKey) <= 16 then
      l_Cipher.Init(l_Key[1],128,@l_IV[1])
    else if Length(v_CipherKey) <= 24 then
      l_Cipher.Init(l_Key[1],192,@l_IV[1])
    else
      l_Cipher.Init(l_Key[1],256,@l_IV[1]);

    // Encrypt the data
    l_Cipher.EncryptCBC(l_Data[1],l_Data[1],Length(l_Data));

    // Free the cipher and clear sensitive information
    l_Cipher.Free;
    FillChar(l_Key[1],Length(l_Key),0);

    // Return the Base64 encoded result
    Result := Base64EncodeStr(l_Data);
  Except
    log_diario('Erro no Processo de Criptografia');
  End;
end;

function TFormularioGeral.DeCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    // Pad Key and IV with zeros as appropriate
    l_Key := PadWithZeros(v_CipherKey,KeySize);
    l_IV := PadWithZeros(v_IV,BlockSize);

    // Decode the Base64 encoded string
    l_Data := Base64DecodeStr(p_Data);

    // Create the cipher and initialise according to the key length
    l_Cipher := TDCP_rijndael.Create(nil);
    if Length(v_CipherKey) <= 16 then
      l_Cipher.Init(l_Key[1],128,@l_IV[1])
    else if Length(v_CipherKey) <= 24 then
      l_Cipher.Init(l_Key[1],192,@l_IV[1])
    else
      l_Cipher.Init(l_Key[1],256,@l_IV[1]);

    // Decrypt the data
    l_Cipher.DecryptCBC(l_Data[1],l_Data[1],Length(l_Data));

    // Free the cipher and clear sensitive information
    l_Cipher.Free;
    FillChar(l_Key[1],Length(l_Key),0);

    // Return the result
    Result := trim(RemoveZerosFimString(l_Data));
  Except
    log_diario('Erro no Processo de Decriptografia');
  End;
end;

function Pode_Coletar : boolean;
var v_JANELAS_EXCECAO, v_plural1, v_plural2 : string;
    tstrJANELAS : TStrings;
    h : hwnd;
    v_contador, intContaJANELAS, intAux : integer;
Begin
    // Se eu conseguir matar o arquivo abaixo � porque Ger_Cols e Ini_Cols j� finalizaram suas atividades...
    FormularioGeral.Matar(p_path_cacic+'temp\','aguarde_GER.txt');
    FormularioGeral.Matar(p_path_cacic+'temp\','aguarde_INI.txt');
    intContaJANELAS := 0;
    h := 0;

    if  (not (FileExists(p_path_cacic + 'temp\aguarde_GER.txt'))  and
         not (FileExists(p_path_cacic + 'temp\aguarde_INI.txt'))) then
        Begin
          FormularioGeral.CipherOpen;
          // Verifica��o das janelas abertas para que n�o aconte�a coletas caso haja aplica��es pesadas rodando (configurado no M�dulo Gerente)
          v_JANELAS_EXCECAO := FormularioGeral.getValorDatMemoria('Configs.TE_JANELAS_EXCECAO',v_tstrCipherOpened);

          FormularioGeral.log_DEBUG('Verificando Janelas para Exce��o...');
          tstrJANELAS := TStrings.Create;
          if (v_JANELAS_EXCECAO <> '') then
            Begin
              tstrJANELAS := FormularioGeral.explode(trim(v_JANELAS_EXCECAO),',');
              if (tstrJANELAS.Count > 0) then
                  for intAux := 0 to tstrJANELAS.Count-1 Do
                    Begin
                      h := FormularioGeral.FindWindowByTitle(tstrJANELAS[intAux]);
                      if h <> 0 then intContaJANELAS := 1;
                      break;
                    End;
            End;

            // Caso alguma janela tenha algum nome de aplica��o cadastrada como "cr�tica" ou "pesada"...
            if (intContaJANELAS > 0) then
              Begin
                FormularioGeral.log_diario('EXECU��O DE ATIVIDADES ADIADA!');
                v_contador := 0;
                v_plural1 := '';
                v_plural2 := '�O';
                for intAux := 0 to tstrJANELAS.Count-1 Do
                  Begin
                    h := FormularioGeral.FindWindowByTitle(tstrJANELAS[intAux]);
                    if h <> 0 then
                      Begin
                        v_contador := v_contador + 1;
                        FormularioGeral.log_diario('-> Aplica��o/Janela ' + inttostr(v_contador) + ': ' + tstrJANELAS[intAux]);
                      End;
                  End;
                if (v_contador > 1) then
                  Begin
                    v_plural1  := 'S';
                    v_plural2 := '�ES';
                  End;
                FormularioGeral.log_diario('-> PARA PROCEDER, FINALIZE A' + v_plural1 + ' APLICA�' + v_plural2 + ' LISTADA' + v_plural1 + ' ACIMA.');

            // N�mero de minutos para iniciar a execu��o (60.000 milisegundos correspondem a 1 minuto). Acrescento 1, pois se for zero ele n�o executa.
            FormularioGeral.Timer_Nu_Exec_Apos.Enabled  := False;
            FormularioGeral.Timer_Nu_Exec_Apos.Interval := strtoint(FormularioGeral.getValorDatMemoria('Configs.NU_EXEC_APOS',v_tstrCipherOpened)) * 60000;
            FormularioGeral.Timer_Nu_Exec_Apos.Enabled  := True;
          End;
        End;

     if (intContaJANELAS = 0) and
        (h = 0) and
        (not FileExists(p_path_cacic + 'temp\aguarde_GER.txt')) and
        (not FileExists(p_path_cacic + 'temp\aguarde_INI.txt')) then
          Result := true
     else
        Begin
          FormularioGeral.log_DEBUG('A��o NEGADA!');
          if (intContaJANELAS=0) then
            if (FileExists(p_path_cacic + 'temp\aguarde_GER.txt')) then
              FormularioGeral.log_DEBUG('Gerente de Coletas em atividade.')
            else if (FileExists(p_path_cacic + 'temp\aguarde_INI.txt')) then
              FormularioGeral.log_DEBUG('Inicializador de Coletas em atividade.')
            else FormularioGeral.CipherClose;
          Result := false;
        End;

End;


function TFormularioGeral.HomeDrive : string;
var
WinDir : array [0..144] of char;
begin
GetWindowsDirectory (WinDir, 144);
Result := StrPas (WinDir);
end;
function TFormularioGeral.GetFolderDate(Folder: string): TDateTime;
var
  Rec: TSearchRec;
  Found: Integer;
  Date: TDateTime;
begin
  if Folder[Length(folder)] = '\' then
    Delete(Folder, Length(folder), 1);
  Result := 0;
  Found  := FindFirst(Folder, faDirectory, Rec);
  try
    if Found = 0 then
    begin
      Date   := FileDateToDateTime(Rec.Time);
      Result := Date;
    end;
  finally
    FindClose(Rec);
  end;
end;

Function TFormularioGeral.Implode(p_Array : TStrings ; p_Separador : String) : String;
var intAux : integer;
    strAux : string;
Begin
    strAux := '';
    For intAux := 0 To p_Array.Count -1 do
      Begin
        if (strAux<>'') then strAux := strAux + p_Separador;
        strAux := strAux + p_Array[intAux];
      End;
    Implode := strAux;
end;

Function TFormularioGeral.CipherClose : String;
var v_DatFile                 : TextFile;
    intAux                    : integer;
    v_strCipherOpenImploded ,
    v_strCipherClosed         : string;
begin

  log_DEBUG('Fechando '+v_DatFileName);
  if v_Debugs then
    for intAux := 0 to (v_tstrCipherOpened.Count-1) do
      log_DEBUG('Posi��o ['+inttostr(intAux)+']='+v_tstrCipherOpened[intAux]);

   try
       {
       v_Tamanho_Arquivo := Get_File_Size(v_DatFileName,true);

       if (v_Tamanho_Arquivo = '0') or
          (v_Tamanho_Arquivo = '-1') then FormularioGeral.Matar(p_path_cacic,'cacic2.dat');
       }

       FileSetAttr (v_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000

       log_DEBUG('Localizando arquivo: '+v_DatFileName);
       AssignFile(v_DatFile,v_DatFileName); {Associa o arquivo a uma vari�vel do tipo TextFile}
       {$IOChecks off}
       log_DEBUG('Abrindo arquivo: '+v_DatFileName);
       ReWrite(v_DatFile); {Abre o arquivo texto}
       {$IOChecks on}
       {
       if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
          begin
            if v_Debugs then log_DEBUG('Recriando arquivo: '+v_DatFileName);
            Rewrite (v_DatFile);
            if v_Debugs then log_DEBUG('Append(1) no arquivo: '+v_DatFileName);
            Append(v_DatFile);
          end
       else
       }
       log_DEBUG('Append(2) no arquivo: '+v_DatFileName);
       Append(v_DatFile);
       log_DEBUG('Criando vetor para criptografia.');
       v_strCipherOpenImploded := Implode(v_tstrCipherOpened,v_SeparatorKey);

       log_DEBUG('Salvando a string "'+v_strCipherOpenImploded+'" em '+v_DatFileName);
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded);
       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}
       CloseFile(v_DatFile);
   except
     log_diario('ERRO NA GRAVA��O DO ARQUIVO DE CONFIGURA��ES.('+v_DatFileName+')');
   end;
   log_DEBUG(v_DatFileName+' fechado com sucesso!');
end;

function TFormularioGeral.Get_File_Size(sFileToExamine: string; bInKBytes: Boolean): string;
var
  SearchRec: TSearchRec;
  sgPath: string;
  inRetval, I1: Integer;
begin
  sgPath := ExpandFileName(sFileToExamine);
  try
    inRetval := FindFirst(ExpandFileName(sFileToExamine), faAnyFile, SearchRec);
    if inRetval = 0 then
      I1 := SearchRec.Size
    else
      I1 := -1;
  finally
    SysUtils.FindClose(SearchRec);
  end;
  Result := trim(IntToStr(I1));
end;

Function TFormularioGeral.CipherOpen : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
begin

  if (v_DataCacic2DAT = '') or (v_DataCacic2DAT <> FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(p_path_cacic + 'cacic2.dat'))) then
    Begin
      v_DataCacic2DAT      := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(p_path_cacic + 'cacic2.dat'));
      log_DEBUG('Abrindo '+v_DatFileName +' - DateTime Cacic2.dat=> '+v_DataCacic2DAT);
      v_strCipherOpened   := '';

      v_Tamanho_Arquivo := Get_File_Size(v_DatFileName,true);

      if (v_Tamanho_Arquivo = '0') or
         (v_Tamanho_Arquivo = '-1') then FormularioGeral.Matar(p_path_cacic,'cacic2.dat');

      if FileExists(v_DatFileName) then
        begin
          log_DEBUG(v_DatFileName+' j� existe!');
          AssignFile(v_DatFile,v_DatFileName);
          log_DEBUG('Abrindo '+v_DatFileName);

          {$IOChecks off}
          Reset(v_DatFile);
          {$IOChecks on}

          log_DEBUG('Verifica��o de Exist�ncia.');
          if (IOResult <> 0)then // Arquivo n�o existe, ser� recriado.
             begin
               log_DEBUG('Recriando "'+v_DatFileName+'"');
               Rewrite (v_DatFile);
               log_DEBUG('Inserindo Primeira Linha.');
               Append(v_DatFile);
             end;

          log_DEBUG('Lendo '+v_DatFileName);
          Readln(v_DatFile,v_strCipherClosed);
          log_DEBUG('Povoando Vari�vel');
          while not EOF(v_DatFile) do Readln(v_DatFile,v_strCipherClosed);
          log_DEBUG('Fechando '+v_DatFileName);
          CloseFile(v_DatFile);
          log_DEBUG('Chamando Criptografia de conte�do');
          v_strCipherOpened:= Decrypt(v_strCipherClosed);
        end;
        if (trim(v_strCipherOpened)<>'') then
          v_tstrCipherOpened := explode(v_strCipherOpened,v_SeparatorKey)
        else
          Begin
            v_tstrCipherOpened := explode('Configs.ID_SO'+v_SeparatorKey+inttostr(GetWinVer)+v_SeparatorKey+
                                          'Configs.Endereco_WS'+v_SeparatorKey+'/cacic2/ws/',v_SeparatorKey);
            log_DEBUG(v_DatFileName+' Inexistente. Criado o DAT em mem�ria.');
          End;

        Result := v_tstrCipherOpened;

        if Result.Count mod 2 = 0 then
            Result.Add('');

        {
        log_DEBUG(v_DatFileName+' aberto com sucesso!');
        if v_Debugs then
          for intAux := 0 to (v_tstrCipherOpened.Count-1) do
            log_DEBUG('Posi��o ['+inttostr(intAux)+'] do MemoryDAT: '+Result[intAux]);
        }
    End
  else log_DEBUG('Cacic2.dat ainda n�o alterado! N�o foi necess�rio reabr�-lo.');
end;

Procedure TFormularioGeral.SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
var v_Aux : string;
begin
    v_Aux := RemoveZerosFimString(p_Valor);
    log_DEBUG('Gravando Chave: "'+p_Chave+'" em MemoryDAT => "'+v_Aux+'"');

    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1] := v_Aux
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(v_Aux);
      End;
end;

Function TFormularioGeral.GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
begin
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        Result := trim(p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1])
    else
        Result := '';
    log_DEBUG('Resgatando Chave: "'+p_Chave+'" de MemoryDAT => "'+Result+'"');
end;

function TFormularioGeral.VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function TFormularioGeral.GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;

Procedure TFormularioGeral.RemoveIconesMortos;
var
  TrayWindow : HWnd;
  WindowRect : TRect;
  SmallIconWidth : Integer;
  SmallIconHeight : Integer;
  CursorPos : TPoint;
  Row : Integer;
  Col : Integer;
begin
  { Get tray window handle and bounding rectangle }
  TrayWindow := FindWindowEx(FindWindow('Shell_TrayWnd',NIL),0,'TrayNotifyWnd',NIL);
  if not GetWindowRect(TrayWindow,WindowRect) then
    Exit;
  { Get small icon metrics }
  SmallIconWidth := GetSystemMetrics(SM_CXSMICON);
  SmallIconHeight := GetSystemMetrics(SM_CYSMICON);
  { Save current mouse position }
  GetCursorPos(CursorPos);
  { Sweep the mouse cursor over each icon in the tray in both dimensions }
  with WindowRect do
  begin
    for Row := 0 to (Bottom - Top) DIV SmallIconHeight do
    begin
      for Col := 0 to (Right - Left) DIV SmallIconWidth do
      begin
        SetCursorPos(Left + Col * SmallIconWidth, Top + Row * SmallIconHeight);
        Sleep(0);
      end;
    end;
  end;
  { Restore mouse position }
  SetCursorPos(CursorPos.X,CursorPos.Y);
  { Redraw tray window (to fix bug in multi-line tray area) }
  RedrawWindow(TrayWindow,NIL,0,RDW_INVALIDATE OR RDW_ERASE OR RDW_UPDATENOW);
End;

Procedure TFormularioGeral.DelValorReg(Chave: String);
var RegDelValorReg: TRegistry;
    strRootKey, strKey, strValue : String;
    ListaAuxDel : TStrings;
    I : Integer;
begin
    ListaAuxDel := FormularioGeral.Explode(Chave, '\');
    strRootKey := ListaAuxDel[0];
    For I := 1 To ListaAuxDel.Count - 2 Do strKey := strKey + ListaAuxDel[I] + '\';
    strValue := ListaAuxDel[ListaAuxDel.Count - 1];
    RegDelValorReg := TRegistry.Create;

    try
        RegDelValorReg.Access := KEY_WRITE;
        RegDelValorReg.Rootkey := FormularioGeral.GetRootKey(strRootKey);

        if RegDelValorReg.OpenKey(strKey, True) then
        RegDelValorReg.DeleteValue(strValue);
    finally
      RegDelValorReg.CloseKey;
    end;
    RegDelValorReg.Free;
    ListaAuxDel.Free;
end;

function TFormularioGeral.GetRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;


procedure TFormularioGeral.WMMENUSELECT(var msg: TWMMENUSELECT);
begin
  inherited;
  IsMenuOpen := not ((msg.MenuFlag and $FFFF > 0) and
    (msg.Menu = 0));
end;

// Verifico a exist�ncia do Gerente de Coletas, caso n�o exista, o chksis.exe far� download!
function TFormularioGeral.ChecaGERCOLS : boolean;
var strFraseVersao : String;
Begin
  log_DEBUG('Verificando exist�ncia do Gerente de Coletas...');
  if not (FileExists(p_path_cacic + 'modulos\ger_cols.exe')) then
    Begin
      strFraseVersao := 'CACIC  V:' + getVersionInfo(ParamStr(0));
      if not (getValorDatMemoria('TcpIp.TE_IP',v_tstrCipherOpened) = '') then
        strFraseVersao := strFraseVersao + #13#10 + 'IP: '+getValorDatMemoria('TcpIp.TE_IP',v_tstrCipherOpened);

      InicializaTray(strFraseVersao);
      log_diario('Acionando recuperador de M�dulo Gerente de Coletas.');
      WinExec(PChar(HomeDrive + '\chksis.exe'),SW_HIDE);

      sleep(30000); // 30 segundos de espera para download do ger_cols.exe
      if (FileExists(p_path_cacic + 'modulos\ger_cols.exe')) then
        Begin
          log_diario('M�dulo Gerente de Coletas RECUPERADO COM SUCESSO!');
          InicializaTray('');
        End
      else
          log_diario('M�dulo Gerente de Coletas N�O RECUPERADO!');
    End;
End;

procedure ExibirConfiguracoes(Sender: TObject);
begin
  // SJI = Senha J� Informada...
  // Esse valor � inicializado com "N"
  if (FormularioGeral.getValorDatMemoria('Configs.SJI',v_tstrCipherOpened)='') and
     (FormularioGeral.getValorDatMemoria('Configs.EnderecoServidor',v_tstrCipherOpened)<>'') then
    begin
      FormularioGeral.CriaFormSenha(nil);
      formSenha.ShowModal;
    end;

  if (FormularioGeral.getValorDatMemoria('Configs.SJI',v_tstrCipherOpened)<>'') or
     (FormularioGeral.getValorDatMemoria('Configs.EnderecoServidor',v_tstrCipherOpened)='') then
    begin
      Application.CreateForm(TFormConfiguracoes, FormConfiguracoes);
      FormConfiguracoes.ShowModal;
    end;
end;

procedure TFormularioGeral.CriaFormSenha(Sender: TObject);
begin
    // Caso ainda n�o exista senha para administra��o do CACIC, define ADMINCACIC como inicial.
    if (getValorDatMemoria('Configs.TE_SENHA_ADM_AGENTE',v_tstrCipherOpened)='') Then
      Begin
         SetValorDatMemoria('Configs.TE_SENHA_ADM_AGENTE', 'ADMINCACIC',v_tstrCipherOpened);
      End;

    Application.CreateForm(TFormSenha, FormSenha);
end;

procedure TFormularioGeral.ChecaCONFIGS;
var strAux        : string;
Begin

  // Verifico se o endere�o do servidor do cacic foi configurado.
  if (GetValorDatMemoria('Configs.EnderecoServidor',v_tstrCipherOpened)='') then
    Begin
      strAux := getValorChaveRegIni('Cacic2','ip_serv_cacic',HomeDrive + '\chksis.ini');

      if (strAux='') then
        begin
          strAux := 'ATEN��O: Endere�o do servidor do CACIC ainda n�o foi configurado.';
          log_diario(strAux);
          log_diario('Ativando m�dulo de configura��o de endere�o de servidor.');
          MessageDlg(strAux + #13#10 + 'Por favor, informe o endere�o do servidor do CACIC na tela que ser� exibida a seguir.', mtWarning, [mbOk], 0);
          ExibirConfiguracoes(Nil);
        end
      else SetValorDatMemoria('Configs.EnderecoServidor',strAux,v_tstrCipherOpened);
    End;

end;

// Dica baixada de http://procedure.blig.ig.com.br/
procedure TFormularioGeral.Matar(v_dir,v_files: string);
var
SearchRec: TSearchRec;
Result: Integer;
begin
  Result:=FindFirst(v_dir+v_files, faAnyFile, SearchRec);
  while result=0 do
    begin
      log_DEBUG('Tentativa de Exclus�o de "'+v_dir + SearchRec.Name+'"');
      DeleteFile(v_dir+SearchRec.Name);
      Result:=FindNext(SearchRec);
    end;
end;

procedure TFormularioGeral.HabilitaTCP;
Begin
  // Desabilita/Habilita a op��o de Informa��es de TCP/IP
  Mnu_InfosTCP.Enabled := False;
  if (getValorDatMemoria('TcpIp.TE_NOME_HOST'      ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_IP'             ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.ID_IP_REDE'        ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_DOMINIO_DNS'    ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_DNS_PRIMARIO'   ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_DNS_SECUNDARIO' ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_GATEWAY'        ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_MASCARA'        ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_SERV_DHCP'      ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_WINS_PRIMARIO'  ,v_tstrCipherOpened) +
      getValorDatMemoria('TcpIp.TE_WINS_SECUNDARIO',v_tstrCipherOpened) <> '') then Mnu_InfosTCP.Enabled := True;
End;

Function TFormularioGeral.Explode(Texto, Separador : String) : TStrings;
var
    strItem       : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres,
    TamanhoSeparador,
    I : Integer;
Begin
    ListaAuxUTILS    := TStringList.Create;
    strItem          := '';
    NumCaracteres    := Length(Texto);
    TamanhoSeparador := Length(Separador);
    I                := 1;
    While I <= NumCaracteres Do
      Begin
        If (Copy(Texto,I,TamanhoSeparador) = Separador) or (I = NumCaracteres) Then
          Begin
            if (I = NumCaracteres) then strItem := strItem + Texto[I];
            ListaAuxUTILS.Add(trim(strItem));
            strItem := '';
            I := I + (TamanhoSeparador-1);
          end
        Else
            strItem := strItem + Texto[I];

        I := I + 1;
      End;
    Explode := ListaAuxUTILS;
end;
Function TFormularioGeral.RemoveZerosFimString(Texto : String) : String;
var I       : Integer;
    strAux  : string;
Begin
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := Length(Texto) downto 0 do
       if (ord(Texto[I])<>0) Then
         strAux := Texto[I] + strAux;
   Result := trim(strAux);
end;

procedure TFormularioGeral.HabilitaPatrimonio;
Begin
  // Desabilita/Habilita a op��o de Informa��es Patrimoniais
  Mnu_InfosPatrimoniais.Enabled := False;
  if (getValorDatMemoria('Configs.CS_COLETA_PATRIMONIO',v_tstrCipherOpened) = 'S') then Mnu_InfosPatrimoniais.Enabled := True;
End;


//Para buscar do Arquivo INI...
// Marreta devido a limita��es do KERNEL w9x no tratamento de arquivos texto e suas se��es
function TFormularioGeral.getValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var
  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    Result := '';
    if (FileExists(p_IniFileName)) then
      Begin
        v_SectionName := '[' + p_SectionName + ']';
        v_Size_Section := strLen(PChar(v_SectionName));
        v_KeyName := p_KeyName + '=';
        v_Size_Key     := strLen(PChar(v_KeyName));
        FileText := TStringList.Create;
        try
          FileText.LoadFromFile(p_IniFileName);
          For i := 0 To FileText.Count - 1 Do
            Begin
              if (LowerCase(Trim(PChar(Copy(FileText[i],1,v_Size_Section)))) = LowerCase(Trim(PChar(v_SectionName)))) then
                Begin
                  For j := i to FileText.Count - 1 Do
                    Begin
                      if (LowerCase(Trim(PChar(Copy(FileText[j],1,v_Size_Key)))) = LowerCase(Trim(PChar(v_KeyName)))) then
                        Begin
                          Result := trim(PChar(Copy(FileText[j],v_Size_Key + 1,strLen(PChar(FileText[j]))-v_Size_Key)));
                          Break;
                        End;
                    End;
                End;
              if (Result <> '') then break;
            End;
        finally
          FileText.Free;
        end;
      end
    else Result := '';

    log_DEBUG('Resgatei '+p_SectionName+'/'+p_KeyName+' de '+p_IniFileName+' => "'+Result+'"');
  end;


function TFormularioGeral.GetWinVer: Integer;
const
  { operating system (OS)constants }
  cOsUnknown = 0;
  cOsWin95 = 1;
  cOsWin95OSR2 = 2;  // N�o implementado.
  cOsWin98 = 3;
  cOsWin98SE = 4;
  cOsWinME = 5;
  cOsWinNT = 6;
  cOsWin2000 = 7;
  cOsXP = 8;
var
  osVerInfo: TOSVersionInfo;
  platformID,
  majorVer,
  minorVer : Integer;
  CSDVersion : String;
begin
  Result := cOsUnknown;
  { set operating system type flag }
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
  begin
    platformId        :=      osVerInfo.dwPlatformId;
    majorVer          :=      osVerInfo.dwMajorVersion;
    minorVer          :=      osVerInfo.dwMinorVersion;
    CSDVersion        := trim(osVerInfo.szCSDVersion);
    case osVerInfo.dwPlatformId of
      VER_PLATFORM_WIN32_NT: { Windows NT/2000 }
        begin
          if majorVer <= 4 then
            Result := cOsWinNT
          else if (majorVer = 5) and (minorVer = 0) then
            Result := cOsWin2000
          else if (majorVer = 5) and (minorVer = 1) then
            Result := cOsXP
          else
            Result := cOsUnknown;
        end;
      VER_PLATFORM_WIN32_WINDOWS:  { Windows 9x/ME }
        begin
          if (majorVer = 4) and (minorVer = 0) then
            Result := cOsWin95
          else if (majorVer = 4) and (minorVer = 10) then
          begin
            if osVerInfo.szCSDVersion[1] = 'A' then
              Result := cOsWin98SE
            else
              Result := cOsWin98;
          end
          else if (majorVer = 4) and (minorVer = 90) then
            Result := cOsWinME
          else
            Result := cOsUnknown;
        end;
      else
        Result := cOsUnknown;
    end;
  end
  else
    Result := cOsUnknown;
  // A partir da vers�o 2.2.0.24, defino o valor da ID Interna e atribuo-a sem o CSDVersion � vers�o externa
  v_te_so := IntToStr(platformId) + '.' +
             IntToStr(majorVer)   + '.' +
             IntToStr(minorVer)   +
             IfThen(CSDVersion='','','.'+CSDVersion);
  if (Result = 0) then
    Result := abstraiCSD(v_te_so);

end;
function TFormularioGeral.abstraiCSD(p_te_so : String) : integer;
  var tstrTe_so : tstrings;
  Begin
    tstrTe_so := Explode(p_te_so, '.');
    Result := StrToInt(tstrTe_so[0] + tstrTe_so[1] + tstrTe_so[2]);
  End;

procedure TFormularioGeral.log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

function TFormularioGeral.Posso_Rodar : boolean;
Begin
  result := false;

  log_debug('Verificando concomit�ncia de sess�es');
  // Se eu conseguir matar o arquivo abaixo � porque n�o h� outra sess�o deste agente aberta... (POG? N���o!  :) )
  FormularioGeral.Matar(p_path_cacic,'aguarde_CACIC.txt');
  if  (not (FileExists(p_path_cacic + 'aguarde_CACIC.txt'))) then
    result := true;
End;

procedure TFormularioGeral.FormCreate(Sender: TObject);
var strAux,
    v_ip_serv_cacic,
    v_cacic_dir,
    v_windir,
    strFraseVersao : string;
    intAux : integer;
    v_Aguarde : TextFile;
    v_SystemDrive : TStrings;
begin
      Try
         // De acordo com a vers�o do OS, determino o ShellCommand para chamadas externas.
         if ((GetWinVer <> 0) and (GetWinVer > 5)) or
              (abstraiCSD(v_te_so) >= 250) then //Se NT/2K/XP... then
          Begin
            //p_Shell_Command := GetEnvironmentVariable('SYSTEMROOT') + '\system32\cmd.exe /c '; //NT/2K/XP
            p_Shell_Path    := HomeDrive + '\system32\'; //NT/2K/XP
            p_Shell_Command := 'cmd.exe'; //NT/2K/XP
            strAux := HomeDrive + '\';  //Ex.: c:\windows\
          End
         else
          Begin
            v_windir := GetEnvironmentVariable('windir');
            if (trim(v_windir) <> '') then v_windir := v_windir + '\';
            //p_Shell_Command := v_windir + 'command.com /c ';
            p_Shell_Path    := v_windir;
            p_Shell_Command := 'command.com';
            strAux := GetEnvironmentVariable('windir') + '\';  //Ex.: c:\windows\
          End;

         v_SystemDrive := explode(strAux,'\');
         v_cacic_dir := v_SystemDrive[0] + '\' + getValorChaveRegIni('Cacic2','cacic_dir',strAux + 'chksis.ini') + '\';

         // Caminho do aplicativo
         if (v_cacic_dir <> '') then
           p_path_cacic := v_cacic_dir
         else
           p_path_cacic := ExtractFilePath(Application.Exename) ;

         v_Debugs := false;
         if DirectoryExists(p_path_cacic + 'Temp\Debugs') then
            Begin
             if (FormatDateTime('ddmmyyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
               Begin
                 v_Debugs := true;
                 log_DEBUG('Pasta "' + p_path_cacic + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
               End;
            End;

         log_DEBUG('Pasta do Sistema: "' + p_path_cacic + '"');

         if Posso_Rodar then
            Begin
              // Uma forma f�cil de evitar que outra sess�o deste agente seja iniciada! (POG? N����ooo!) :))))
              AssignFile(v_Aguarde,p_path_cacic + 'aguarde_CACIC.txt'); {Associa o arquivo a uma vari�vel do tipo TextFile}
              {$IOChecks off}
              Reset(v_Aguarde); {Abre o arquivo texto}
              {$IOChecks on}
              if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
                Rewrite (v_Aguarde);

              Append(v_Aguarde);
              Writeln(v_Aguarde,'Apenas um pseudo-cookie para evitar sess�es concomitantes...');
              Append(v_Aguarde);
              Writeln(v_Aguarde,'Futuramente penso em colocar aqui o pID, para possibilitar finaliza��o via software externo...');
              Append(v_Aguarde);

              // Chave AES. Recomenda-se que cada empresa altere a sua chave.
              // Esta chave � passada como par�metro para o Gerente de Coletas que, por sua vez,
              // passa para o Inicializador de Coletas e este passa para os coletores...
              v_CipherKey          := 'CacicBrasil';
              v_IV                 := 'abcdefghijklmnop';
              v_SeparatorKey       := '=CacicIsFree='; // Usada apenas para o cacic2.dat
              v_DatFileName        := p_path_cacic + 'cacic2.dat';
              v_DataCacic2DAT      := '';
              v_tstrCipherOpened   := TStrings.Create;
              v_tstrCipherOpened   := CipherOpen;

              if FileExists(p_path_cacic + 'cacic2.ini') then
                Begin
                  log_DEBUG('O arquivo "'+p_path_cacic + 'cacic2.ini" ainda existe. Vou resgatar algumas chaves/valores');
                  SetValorDatMemoria('Configs.EnderecoServidor'               ,getValorChaveRegIni('Configs'    ,'EnderecoServidor'                 ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.IN_EXIBE_BANDEJA'               ,getValorChaveRegIni('Configs'    ,'IN_EXIBE_BANDEJA'                 ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.TE_JANELAS_EXCECAO'             ,getValorChaveRegIni('Configs'    ,'TE_JANELAS_EXCECAO'               ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.NU_EXEC_APOS'                   ,getValorChaveRegIni('Configs'    ,'NU_EXEC_APOS'                     ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.NU_INTERVALO_EXEC'              ,getValorChaveRegIni('Configs'    ,'NU_INTERVALO_EXEC'                ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.Endereco_WS'                    ,getValorChaveRegIni('Configs'    ,'Endereco_WS'                      ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.TE_SENHA_ADM_AGENTE'            ,getValorChaveRegIni('Configs'    ,'TE_SENHA_ADM_AGENTE'              ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.NU_INTERVALO_RENOVACAO_PATRIM'  ,getValorChaveRegIni('Configs'    ,'NU_INTERVALO_RENOVACAO_PATRIM'    ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA'            ,getValorChaveRegIni('Configs'    ,'DT_HR_ULTIMA_COLETA'              ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS'       ,getValorChaveRegIni('TcpIp'      ,'TE_ENDERECOS_MAC_INVALIDOS'       ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('TcpIp.ID_IP_REDE'                       ,getValorChaveRegIni('TcpIp'      ,'ID_IP_REDE'                       ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('TcpIp.TE_IP'                            ,getValorChaveRegIni('TcpIp'      ,'TE_IP'                            ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('TcpIp.TE_MASCARA'                       ,getValorChaveRegIni('TcpIp'      ,'TE_MASCARA'                       ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Patrimonio.ultima_rede_obtida'          ,getValorChaveRegIni('Patrimonio' ,'ultima_rede_obtida'               ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  SetValorDatMemoria('Patrimonio.dt_ultima_renovacao'         ,getValorChaveRegIni('Patrimonio' ,'dt_ultima_renovacao'              ,p_path_cacic + 'cacic2.ini'),v_tstrCipherOpened);
                  Matar(p_path_cacic,'cacic2.ini');
                End;

              if (ParamCount > 0) then //Caso o Cacic2 seja chamado com passagem de par�metros...
                Begin
                  // Par�metros poss�veis (aceitos)
                  //   /ip_serv_cacic =>  Endere�o IP do M�dulo Gerente. Ex.: 10.71.0.212
                  //   /atualizacao   =>  O CACIC foi chamado pelo batch de AutoUpdate e deve ir direto para o ExecutaCacic.

                  // Chamada com par�metros pelo chkcacic.exe ou linha de comando
                  For intAux := 1 to ParamCount do
                    Begin
                      if LowerCase(Copy(ParamStr(intAux),1,15)) = '/ip_serv_cacic=' then
                        begin
                          log_DEBUG('Par�metro /ip_serv_cacic recebido...');
                          strAux := Trim(Copy(ParamStr(intAux),16,Length((ParamStr(intAux)))));
                          v_ip_serv_cacic := Trim(Copy(strAux,0,Pos('/', strAux) - 1));
                          If (v_ip_serv_cacic = '') Then v_ip_serv_cacic := strAux;
                          SetValorDatMemoria('Configs.EnderecoServidor',v_ip_serv_cacic,v_tstrCipherOpened);
                        end;
                    end;

                    If  FindCmdLineSwitch('execute', True) or
                        FindCmdLineSwitch('atualizacao', True) Then
                        begin
                          if FindCmdLineSwitch('atualizacao', True) then
                            begin
                              log_DEBUG('Op��o /atualizacao recebida...');
                              Log_Diario('Reinicializando com vers�o '+getVersionInfo(ParamStr(0)));
                            end
                          else
                            begin
                              log_DEBUG('Op��o /execute recebida...');
                              log_diario('Op��o para execu��o imediata encontrada...');
                            end;
                          ExecutaCacic(nil);
                        end;
                End;

              // Os timers iniciam-se desabilitados... Mais � frente receber�o par�metros de tempo para execu��o.
              Timer_Nu_Exec_Apos.Enabled  := False;
              Timer_Nu_Intervalo.Enabled  := False;

              // Derruba o cacic durante o shutdown do windows.
              ShutdownEmExecucao := False;

              // N�o mostrar o formul�rio...
              Application.ShowMainForm:=false;

              Try
                // A chamada abaixo define os valores usados pelo agente principal.
                SetaVariaveisGlobais;
              Except
                log_diario('PROBLEMAS SETANDO VARI�VEIS GLOBAIS!');
              End;

              // Envia o �cone para a bandeja com HINT mostrando Vers�o...
              strFraseVersao := 'CACIC  V:' + getVersionInfo(ParamStr(0));
              if not (getValorDatMemoria('TcpIp.TE_IP',v_tstrCipherOpened) = '') then
                strFraseVersao := strFraseVersao + #13#10 + 'IP: '+ getValorDatMemoria('TcpIp.TE_IP',v_tstrCipherOpened);

              InicializaTray(strFraseVersao);
              CipherClose;
            End
         else
            Begin
              log_DEBUG('Agente finalizado devido a concomit�ncia de sess�es...');
              Finaliza;
            End;
      Except
        log_diario('PROBLEMAS NA INICIALIZA��O (2)');
      End;
end;

procedure TFormularioGeral.SetaVariaveisGlobais;
var v_aux : string;
Begin
  Try

    // Inicializa��o do indicador de SENHA J� INFORMADA
    SetValorDatMemoria('Configs.SJI','',v_tstrCipherOpened);

    if (getValorDatMemoria('Configs.IN_EXIBE_BANDEJA' ,v_tstrCipherOpened) = '') then SetValorDatMemoria('Configs.IN_EXIBE_BANDEJA' , 'S'    ,v_tstrCipherOpened);
    if (getValorDatMemoria('Configs.NU_EXEC_APOS'     ,v_tstrCipherOpened) = '') then SetValorDatMemoria('Configs.NU_EXEC_APOS'     , '12345',v_tstrCipherOpened);
    if (getValorDatMemoria('Configs.NU_INTERVALO_EXEC',v_tstrCipherOpened) = '') then SetValorDatMemoria('Configs.NU_INTERVALO_EXEC', '4'    ,v_tstrCipherOpened);
    // IN_EXIBE_BANDEJA     O valor padr�o � mostrar o �cone na bandeja.
    // NU_EXEC_APOS         Assumir� o padr�o de 0 minutos para execu��o imediata em caso de primeira execu��o (instala��o).
    // NU_INTERVALO_EXEC    Assumir� o padr�o de 4 horas para o intervalo, no caso de problemas.

    // N�mero de horas do intervalo (3.600.000 milisegundos correspondem a 1 hora).
    Timer_Nu_Intervalo.Enabled  := False;
    Timer_Nu_Intervalo.Interval := (strtoint(getValorDatMemoria('Configs.NU_INTERVALO_EXEC',v_tstrCipherOpened))) * 3600000;
    Timer_Nu_Intervalo.Enabled  := True;

    // N�mero de minutos para iniciar a execu��o (60.000 milisegundos correspondem a 1 minuto). Acrescento 1, pois se for zero ele n�o executa.
    Timer_Nu_Exec_Apos.Enabled  := False;
    Timer_Nu_Exec_Apos.Interval := strtoint(getValorDatMemoria('Configs.NU_EXEC_APOS',v_tstrCipherOpened)) * 60000;

    // Se for a primeir�ssima execu��o do agente naquela m�quina (ap�s sua instala��o) j� faz todas as coletas configuradas, sem esperar os minutos definidos pelo administrador.
    If (getValorDatMemoria('Configs.NU_EXEC_APOS',v_tstrCipherOpened) = '12345') then // Flag usada na inicializa��o. S� entra nesse if se for a primeira execu��o do cacic ap�s carregado.
      begin
        Timer_Nu_Exec_Apos.Interval := 60000; // 60 segundos para chamar Ger_Cols /coletas
      end
    else log_diario('Executar as a��es automaticamente a cada ' +getValorDatMemoria('Configs.NU_INTERVALO_EXEC',v_tstrCipherOpened) + ' horas.');

    Timer_Nu_Exec_Apos.Enabled  := True;

    v_aux := getValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA',v_tstrCipherOpened);
    if (v_aux <> '') and (Copy(v_aux, 1, 8) <> Copy(FormatDateTime('YYYYmmddHHnnss', Now), 1, 8)) then Timer_Nu_Exec_Apos.Enabled  := True;

    // Desabilita/Habilita a op��o de Informa��es Patrimoniais
    HabilitaPatrimonio;

    // Desabilita/Habilita a op��o de Informa��es Gerais
    HabilitaTCP;

  Except
    log_diario('PROBLEMAS NA INICIALIZA��O (1)');
  End;
end;

procedure TFormularioGeral.log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (p_path_cacic + 'cacic2.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(HistoricoLog,p_path_cacic + 'cacic2.log'); {Associa o arquivo a uma vari�vel do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       if (trim(strMsg) <> '') then
          begin
             DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path_cacic + 'cacic2.log')));
             DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
             if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI n�o � da data atual...
                begin
                  Rewrite (HistoricoLog); //Cria/Recria o arquivo
                  Append(HistoricoLog);
                  Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
                end;
             Append(HistoricoLog);
             Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Agente Principal] '+strMsg); {Grava a string Texto no arquivo texto}
             CloseFile(HistoricoLog); {Fecha o arquivo texto}
          end
      else CloseFile(HistoricoLog);;

   except
    log_diario('PROBLEMAS NA CRIA��O DO ARQUIVO LOG');
   end;

end;
procedure TFormularioGeral.Finaliza;
Begin
  Try
    Shell_NotifyIcon(NIM_Delete,@NotifyStruc);
    Shell_NotifyIcon(NIM_MODIFY,@NotifyStruc);
    RemoveIconesMortos;
  Except
    log_diario('PROBLEMAS NA FINALIZA��O');
  End;
  FreeMemory(0);
  Halt(0);
  Application.Terminate;
End;

procedure TFormularioGeral.Sair(Sender: TObject);
begin
  CriaFormSenha(nil);
  formSenha.ShowModal;
  If (getValorDatMemoria('Configs.SJI',v_tstrCipherOpened) =  'S') Then Finaliza;
end;

procedure TFormularioGeral.Invoca_GerCols(Sender: TObject;p_acao:string);
var v_versao : string;
begin
  Matar(p_path_cacic + 'temp\','*.txt');
  Matar(p_path_cacic + 'temp\','*.ini');

  // Caso exista o Gerente de Coletas ser� verificada a vers�o e exclu�da caso antiga(Uma forma de a��o pr�-ativa)
  If (FileExists(p_path_cacic + 'modulos\ger_cols.exe')) Then
      Begin
      v_versao := trim(GetVersionInfo(p_path_cacic + 'modulos\ger_cols.exe'));
      if (v_versao = '0.0.0.0') then // Provavelmente arquivo corrompido ou vers�o muito antiga
          Begin
            log_diario('Excluindo vers�o ('+v_versao+') de Ger_Cols.exe');
            Matar(p_path_cacic + 'modulos\','ger_cols.exe');
          End;
      End;

  if ChecaGERCOLS then
    Begin
      ChecaCONFIGS;
      CipherClose;
      log_diario('Invocando Gerente de Coletas com a��o: "'+p_acao+'"');
      Timer_Nu_Exec_Apos.Enabled  := False;
      WinExec(PChar(p_path_cacic + 'modulos\GER_COLS.EXE /'+p_acao+' /p_CipherKey='+v_CipherKey),SW_HIDE);
    End;
end;

function TFormularioGeral.FindWindowByTitle(WindowTitle: string): Hwnd;
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

procedure TFormularioGeral.ExecutaCacic(Sender: TObject);
var intAux,
    intContaExec    : integer;
    v_mensagem,
    v_tipo_mensagem,
    v_TE_FILA_FTP,
    v_Aux1,
    v_Aux2,
    v_Aux3,
    strFraseVersao  : string;
    v_MsgDlgType    : TMsgDlgType;
    v_Repete        : boolean;
begin

   log_DEBUG('Execu��o - Resgate de poss�veis novos valores no DAT.');

   CipherOpen;

   try
     if FindCmdLineSwitch('execute', True) or
        FindCmdLineSwitch('atualizacao', True) or
        Pode_Coletar Then
        Begin
          log_DEBUG('Preparando chamada ao Gerente de Coletas...');
          // Se foi gerado o arquivo ger_erro.txt o Log conter� a mensagem al� gravada como valor de chave
          // O Gerente de Coletas dever� ser eliminado para que seja baixado novamente por ChecaGERCOLS
          if (FileExists(p_path_cacic + 'ger_erro.txt')) then
            Begin
              log_diario('Gerente de Coletas eliminado devido a falha:');
              log_diario(getValorDatMemoria('Erro_Fatal_Descricao',v_tstrCipherOpened));
              SetaVariaveisGlobais;
              Matar(p_path_cacic,'ger_erro.txt');
              Matar(p_path_cacic+'modulos\','ger_cols.exe');
            End;

          if (FileExists(p_path_cacic + 'temp\reset.txt')) then
            Begin
              Matar(p_path_cacic+'temp\','reset.txt');
              log_diario('Reinicializando...');
              SetaVariaveisGlobais;
            End;
          Timer_Nu_Exec_Apos.Enabled  := False;

          intContaExec := 1;
          If (FileExists(p_path_cacic + 'temp\cacic2.bat') or
              FileExists(p_path_cacic + 'temp\ger_cols.exe')) Then
              intContaExec := 2;

          // Muda HINT
          InicializaTray('');

          // Loop para poss�vel necessidade de updates de Agente Principal e/ou Gerente de Coletas
          For intAux := intContaExec to 2 do
            Begin
              if (intAux = 1) then
                Begin
                  log_DEBUG('Controle de Execu��es='+inttostr(intContaExec));
                  log_diario('Iniciando execu��o de atividades.');

                  v_Repete := true;
                  while v_Repete do
                    Begin
                      v_Repete := false;
                      Mnu_InfosPatrimoniais.Enabled := False;
                      Mnu_InfosTCP.Enabled          := False;
                      Mnu_ExecutarAgora.Enabled     := False;
                      v_Aux1 := Mnu_InfosPatrimoniais.Caption;
                      v_Aux2 := Mnu_InfosTCP.Caption;
                      v_Aux3 := Mnu_ExecutarAgora.Caption;
                      Mnu_InfosPatrimoniais.Caption := 'Aguarde, coleta em a��o!';
                      Mnu_InfosTCP.Caption          := Mnu_InfosPatrimoniais.Caption;
                      Mnu_ExecutarAgora.Caption     := Mnu_InfosPatrimoniais.Caption;


                      log_DEBUG('Primeira chamada ao Gerente de Coletas...');
                      Invoca_GerCols(nil,'coletas');
                      sleep(3000); // Pausa para in�cio do Gerente de Coletas e cria��o do arquivo temp\aguarde_GER.txt

                      // Pausas de 10 segundos para o caso de ser(em) baixada(s) nova(s) vers�o(�es) de Ger_Cols e/ou Cacic2.
                      while not Pode_Coletar do
                        Begin
                          log_DEBUG('Aguardando mais 15 segundos...');
                          sleep(15000);
                        End;
                      Mnu_InfosPatrimoniais.Caption := v_Aux1;
                      Mnu_InfosTCP.Caption          := v_Aux2;
                      Mnu_ExecutarAgora.Caption     := v_Aux3;
                      Mnu_ExecutarAgora.Enabled     := true;

                      CipherOpen;
                      // Neste caso o Gerente de Coletas dever� fazer novo contato devido � permiss�o de criptografia ter sido colocada em espera pelo pr�ximo contato.
                      if (FormularioGeral.getValorDatMemoria('Configs.CS_CIPHER',v_tstrCipherOpened)='2') then
                        Begin
                          v_Repete := true;
                          log_Debug('Criptografia ser� colocada em n�vel 2...');
                        End;
                    End;

                  // Verifico se foi gravada alguma mensagem pelo Gerente de Coletas e mostro
                  CipherOpen;
                  v_mensagem      := getValorDatMemoria('Mensagens.te_mensagem',v_tstrCipherOpened);
                  v_tipo_mensagem := getValorDatMemoria('Mensagens.cs_tipo'    ,v_tstrCipherOpened);
                  if (v_mensagem <> '') then
                    Begin
                      if      (v_tipo_mensagem='mtError')       then v_MsgDlgType := mtError
                      else if (v_tipo_mensagem='mtInformation') then v_MsgDlgType := mtInformation
                      else if (v_tipo_mensagem='mtWarning')     then v_MsgDlgType := mtWarning;
                      MessageDlg(v_mensagem,v_MsgDlgType, [mbOk], 0);
                      SetValorDatMemoria('Mensagens.te_mensagem', '',v_tstrCipherOpened);
                      SetValorDatMemoria('Mensagens.cs_tipo', '',v_tstrCipherOpened);
                    End;

                  // Verifico se TE_FILA_FTP foi setado (por Ger_Cols) e obede�o ao intervalo para nova tentativa de coletas
                  // Caso TE_FILA_FTP inicie com # � porque j� passou nessa condi��o e deve iniciar nova tentativa de FTP...
                  v_TE_FILA_FTP := getValorDatMemoria('Configs.TE_FILA_FTP',v_tstrCipherOpened);
                  if (Copy(v_TE_FILA_FTP,1,1) <> '#') and
                     (v_TE_FILA_FTP <> '0') and
                     (v_TE_FILA_FTP <> '') then
                    Begin
                      // Busquei o n�mero de milisegundos setados em TE_FILA_FTP e o obede�o...
                      // 60.000 milisegundos correspondem a 60 segundos (1 minuto).
                      // Acrescento 1, pois se for zero ele n�o executa.
                      Timer_Nu_Exec_Apos.Enabled  := False;
                      Timer_Nu_Exec_Apos.Interval :=  strtoint(v_TE_FILA_FTP) * 60000;
                      Timer_Nu_Exec_Apos.Enabled  := True;
                      log_diario('FTP de coletores adiado pelo M�dulo Gerente.');
                      log_diario('Nova tentativa em aproximadamente ' + v_TE_FILA_FTP+ ' minuto(s).');
                      SetValorDatMemoria('Configs.TE_FILA_FTP','#' + v_TE_FILA_FTP,v_tstrCipherOpened);
                    End;

                  // Desabilita/Habilita a op��o de Informa��es Patrimoniais
                  HabilitaPatrimonio;

                  // Desabilita/Habilita a op��o de Informa��es de TCP/IP
                  HabilitaTCP;

                  // Para evitar uma reexecu��o de Ger_Cols sem necessidade...
                  intContaExec := 3;
                End;

              // Caso tenha sido baixada nova c�pia do Gerente de Coletas, esta dever� ser movida para cima da atual
              if (FileExists(p_path_cacic + 'temp\ger_cols.exe')) then
                Begin
                  log_diario('Atualizando vers�o do Gerente de Coletas para '+getVersionInfo(p_path_cacic + 'temp\ger_cols.exe'));
                  // O MoveFileEx n�o se deu bem no Win98!  :|
                  // MoveFileEx(PChar(p_path_cacic + 'temp\ger_cols.exe'),PChar(p_path_cacic + 'modulos\ger_cols.exe'),MOVEFILE_REPLACE_EXISTING);

                  CopyFile(PChar(p_path_cacic + 'temp\ger_cols.exe'),PChar(p_path_cacic + 'modulos\ger_cols.exe'),false);
                  sleep(2000); // 2 segundos de espera pela c�pia!  :) (Rwindows!)

                  Matar(p_path_cacic+'temp\','ger_cols.exe');
                  sleep(2000); // 2 segundos de espera pela dele��o!

                  intContaExec := 2; // For�ar� uma reexecu��o de Ger_Cols...
                End;

              // Caso tenha sido baixada nova c�pia do Agente Principal, esta dever� ser movida para cima da atual pelo Gerente de Coletas...
              if (FileExists(p_path_cacic + 'temp\cacic2.exe')) then  //AutoUpdate!
                Begin
                  // Verifico e excluo o Gerente de Coletas caso a vers�o seja anterior ao 1� release
                  v_versao := getVersionInfo(p_path_cacic + 'modulos\ger_cols.exe');
                  if ((copy(v_versao,1,5)='2.0.0') or // Vers�es anteriores ao 1� Release...
                      (v_versao = '2.0.1.2') or // Tivemos alguns problemas nas vers�es 2.0.1.2, 2.0.1.3 e 2.0.1.4
                      (v_versao = '2.0.1.3') or
                      (v_versao = '2.0.1.4') or
                      (v_versao = '0.0.0.0')) then // Provavelmente arquivo corrompido ou vers�o muito antiga
                    Begin
                      Matar(p_path_cacic+'modulos\','ger_cols.exe');
                      sleep(2000); // 2 segundos de espera pela dele��o!
                    End;

                  // Agora o Gerente de Coletas ser� invocado para fazer a atualiza��o da vers�o do Agente Principal
                  log_diario('Invocando Gerente de Coletas para Atualiza��o do Agente Principal.');
                  Invoca_GerCols(nil,'UpdatePrincipal');
                  log_diario('Finalizando... (Atualiza��o em aproximadamente 20 segundos).');
                  Finaliza;
                  {
                  // O m�todo abaixo foi descartado devido � janela MS-DOS que em algumas m�quinas
                  // permaneciam abertas e minimizadas e, em alguns casos, escureciam totalmente a tela do usu�rio,
                  // causando muito descontentamento!  :|
                  FileSetAttr(p_path_cacic + 'cacic2.exe', 0);
                  Batchfile := TStringList.Create;
                  Batchfile.Add('@echo off');
                  Batchfile.Add(':Label1');
                  Batchfile.Add('del ' + p_path_cacic + 'cacic2.exe');
                  Batchfile.Add('if Exist ' + p_path_cacic + 'cacic2.exe goto Label1');
                  Batchfile.Add('move ' + p_path_cacic + 'temp\cacic2.exe ' + p_path_cacic + 'cacic2.exe');
                  Batchfile.Add(p_path_cacic + 'cacic2.exe /atualizacao');
                  Batchfile.SaveToFile(p_path_cacic + 'Temp\cacic2.bat');
                  BatchFile.Free;
                  log_diario('* Atualizando vers�o do m�dulo Principal');
                  Shell_NotifyIcon(NIM_Delete,@NotifyStruc);
                  Shell_NotifyIcon(NIM_MODIFY,@NotifyStruc);
                  Executa(p_Shell_Path + p_Shell_Command + 'Temp\cacic2.bat /c',SW_HIDE);
                  FreeMemory(0);
                  Halt(0);
                  }
                End;

                {
                // N�o usar VBS pois, o processo morre quando o CACIC � finalizado.
                // E tamb�m pela depend�ncia do WSH, certo?!!  :|
                Begin
                  main.frmMain.log_diario('* Atualizando vers�o do m�dulo Principal');
                  FileSetAttr(p_path_cacic + 'cacic2.exe', 0);
                  Batchfile := TStringList.Create;
                  Batchfile.Add('Dim fso,fsoDEL,v_pausa,WshShell');
                  Batchfile.Add('Set fsoDEL = CreateObject("Scripting.FileSystemObject")');
                  Batchfile.Add('While (fsoDEL.FileExists("'+p_path_cacic+'cacic2.exe"))');
                  Batchfile.Add('   fsoDEL.DeleteFile("'+p_path_cacic+'cacic2.exe")');
                  Batchfile.Add('Wend');
                  Batchfile.Add('Set fso = CreateObject("Scripting.FileSystemObject")');
                  Batchfile.Add('fso.MoveFile ' + p_path_cacic + 'temp\cacic2.exe, "' + p_path_cacic + 'cacic2.exe"');
                  Batchfile.Add('Set WshShell = WScript.CreateObject("WScript.Shell")');
                  Batchfile.Add('WshShell.Run "' + p_path_cacic + 'cacic2.exe /atualizacao",10,FALSE');
                  Batchfile.Add('For v_pausa = 1 to 5000:next');
                  Batchfile.Add('WScript.Quit');
                  Batchfile.SaveToFile(p_path_cacic + 'Temp\cacic2.vbs');
                  Batchfile.SaveToFile(p_path_cacic + 'Temp\cacic21.vbs');
                  BatchFile.Free;
                  Executa_VBS('cacic2');
                  Shell_NotifyIcon(NIM_Delete,@NotifyStruc);
                  Shell_NotifyIcon(NIM_MODIFY,@NotifyStruc);
                  FreeMemory(0);
                  Halt(0);
                  Application.Terminate;
                End;
              }

              // A exist�ncia de "temp\cacic2.bat" significa AutoUpdate j� executado!
              // Essa verifica��o foi usada no modelo antigo de AutoUpdate e deve ser mantida
              // at� a total converg�ncia de vers�es para 2.0.1.16+...
              if (FileExists(p_path_cacic + 'temp\cacic2.bat')) then
                  Matar(p_path_cacic+'temp\','cacic2.bat');

              // O loop 1 foi dedicado a atualiza��es de vers�es e afins...
              // O loop 2 dever� invocar as coletas propriamente ditas...
              if (intContaExec = 2) then
                Begin
                  log_DEBUG('Segunda chamada ao Gerente de Coletas...');
                  Invoca_GerCols(nil,'coletas');
                  intContaExec := 3;
                End;

            End;
        End;
        // Volta a mostrar a vers�o no HINT...
        strFraseVersao := 'CACIC  V:' + getVersionInfo(ParamStr(0));
        if not (getValorDatMemoria('TcpIp.TE_IP',v_tstrCipherOpened) = '') then
          strFraseVersao := strFraseVersao + #13#10 + 'IP: '+getValorDatMemoria('TcpIp.TE_IP',v_tstrCipherOpened);

        InicializaTray(strFraseVersao);

    except
      log_diario('PROBLEMAS AO TENTAR ATIVAR COLETAS.');
    end;
end;

procedure TFormularioGeral.ExibirLogAtividades(Sender: TObject);
begin
     Application.CreateForm(tformLog,formLog);
     formLog.ShowModal;
end;

procedure TFormularioGeral.ExibirConfiguracoes(Sender: TObject);
begin
  // SJI = Senha J� Informada...
  // Esse valor � inicializado com "N"
  if (FormularioGeral.getValorDatMemoria('Configs.SJI',v_tstrCipherOpened)='') and
     (FormularioGeral.getValorDatMemoria('Configs.EnderecoServidor',v_tstrCipherOpened)<>'') then
    begin
      FormularioGeral.CriaFormSenha(nil);
      formSenha.ShowModal;
    end;

  if (FormularioGeral.getValorDatMemoria('Configs.SJI',v_tstrCipherOpened)<>'') or
     (FormularioGeral.getValorDatMemoria('Configs.EnderecoServidor',v_tstrCipherOpened)='') then
    begin
      Application.CreateForm(TFormConfiguracoes, FormConfiguracoes);
      FormConfiguracoes.ShowModal;
    end;

end;

procedure TFormularioGeral.Mnu_InfosPatrimoniaisClick(Sender: TObject);
var v_abre_janela_patrimonio : boolean;
begin
v_abre_janela_patrimonio := true;
If (( getValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1' ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2' ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.te_localizacao_complementar'   ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.te_info_patrimonio1'           ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.te_info_patrimonio2'           ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.te_info_patrimonio3'           ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.te_info_patrimonio4'           ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.te_info_patrimonio5'           ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.te_info_patrimonio6'           ,v_tstrCipherOpened)+
      getValorDatMemoria('Patrimonio.ultima_rede_obtida'            ,v_tstrCipherOpened))<>'') then
  Begin
    SetValorDatMemoria('Configs.SJI','',v_tstrCipherOpened);
    CriaFormSenha(nil);
    formSenha.ShowModal;
    if (getValorDatMemoria('Configs.SJI',v_tstrCipherOpened)<>'S') then
      Begin
        v_abre_janela_patrimonio := false;
      End;
  End;

if (v_abre_janela_patrimonio) then
  begin
    if (ChecaGERCOLS) then
      Begin
        ChecaCONFIGS;
        Invoca_GerCols(nil,'patrimonio');
      End;
  end;
end;

//=======================================================================
// Todo o c�digo deste ponto em diante est� relacionado �s rotinas de
// de inclus�o do �cone do programa na bandeja do sistema
//=======================================================================
procedure TFormularioGeral.InicializaTray(v_Hint:string);
begin

     {Estrutura do tray icon sendo criada.}
     NotifyStruc.cbSize := SizeOf(NotifyStruc);
     NotifyStruc.Wnd := Handle;
     NotifyStruc.uID := 1;
     NotifyStruc.uFlags := NIF_ICON or NIF_TIP or NIF_MESSAGE;
     NotifyStruc.uCallbackMessage := WM_MYMESSAGE; {User defined message}
     NotifyStruc.hIcon :=  Application.Icon.Handle;

     if (v_Hint = '') then
        v_Hint := 'Aguarde...';

     log_DEBUG('Setando o HINT do Systray para: "'+v_Hint+'"');

     // Atualiza o conte�do do tip da bandeja
     StrPCopy(NotifyStruc.szTip, v_Hint);

     if (getValorDatMemoria('Configs.IN_EXIBE_BANDEJA',v_tstrCipherOpened) <> 'N') Then
      Begin
       Shell_NotifyIcon(NIM_ADD, @NotifyStruc);
      End
     else
      Begin
        Shell_NotifyIcon(HIDE_WINDOW,@NotifyStruc);
        Shell_NotifyIcon(NIM_Delete,@NotifyStruc);
      End;
     Shell_NotifyIcon(nim_Modify,@NotifyStruc);
end;

procedure TFormularioGeral.WMSysCommand;
begin  // Captura o minimizar da janela
  if (Msg.CmdType = SC_MINIMIZE) or (Msg.CmdType = SC_MAXIMIZE) then
  Begin
       MinimizaParaTrayArea(Nil);
       Exit;
  end;
  DefaultHandler(Msg);
end;

procedure TFormularioGeral.TrayMessage(var Msg: TMessage);
var Posicao : TPoint;
begin
  if (Msg.LParam=WM_RBUTTONDOWN) then
    Begin
       Mnu_InfosPatrimoniais.Enabled := False;
       // Habilita a op��o de menu caso a coleta de patrimonio esteja habilitado.
       HabilitaPatrimonio;
       SetForegroundWindow(Handle);
       GetCursorPos(Posicao);
       PopupMenu1.Popup(Posicao.X, Posicao.Y);
    end;

end;

procedure TFormularioGeral.MinimizaParaTrayArea(Sender: TObject);
begin
    FormularioGeral.Visible:=false;
    if (getValorDatMemoria('Configs.IN_EXIBE_BANDEJA',v_tstrCipherOpened) <> 'N') Then
      Begin
        Shell_NotifyIcon(NIM_ADD,@NotifyStruc);
      End
    else
      Begin
        Shell_NotifyIcon(HIDE_WINDOW,@NotifyStruc);
        Shell_NotifyIcon(nim_Modify,@NotifyStruc);
      End;
end;
// -------------------------------------
// Fim dos c�digos da bandeja do sistema
// -------------------------------------

procedure TFormularioGeral.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   // Esse evento � colocado em Nil durante o shutdown do windows.
   // Ver o evento WMQueryEndSession.
   CanClose := False;
   MinimizaParaTrayArea(Nil);
end;

procedure TFormularioGeral.WMQueryEndSession(var Msg: TWMQueryEndSession);
begin
   // Quando h� um shutdown do windows em execu��o, libera o close.
   OnCloseQuery := Nil;
   Application.Terminate;
   inherited // Continue ShutDown request
end;

procedure TFormularioGeral.Mnu_InfosTCPClick(Sender: TObject);
var v_tripa_perfis, v_tripa_infos_coletadas,strAux : string;
    v_array_perfis, v_array_tripa_infos_coletadas, v_array_infos_coletadas,tstringsAux : tstrings;
    v_conta_perfis, v_conta_infos_coletadas, intAux, intAux1 : integer;
    v_achei : boolean;
begin
    FormularioGeral.Enabled       := true;
    FormularioGeral.Visible       := true;

    ST_VL_NomeHost.Caption        := getValorDatMemoria('TcpIp.TE_NOME_HOST'       ,v_tstrCipherOpened);
    ST_VL_IPEstacao.Caption       := getValorDatMemoria('TcpIp.TE_IP'              ,v_tstrCipherOpened);
    ST_VL_MacAddress.Caption      := getValorDatMemoria('TcpIp.TE_NODE_ADDRESS'    ,v_tstrCipherOpened);
    ST_VL_IPRede.Caption          := getValorDatMemoria('TcpIp.ID_IP_REDE'         ,v_tstrCipherOpened);
    ST_VL_DominioDNS.Caption      := getValorDatMemoria('TcpIp.TE_DOMINIO_DNS'     ,v_tstrCipherOpened);
    ST_VL_DNSPrimario.Caption     := getValorDatMemoria('TcpIp.TE_DNS_PRIMARIO'    ,v_tstrCipherOpened);
    ST_VL_DNSSecundario.Caption   := getValorDatMemoria('TcpIp.TE_DNS_SECUNDARIO'  ,v_tstrCipherOpened);
    ST_VL_Gateway.Caption         := getValorDatMemoria('TcpIp.TE_GATEWAY'         ,v_tstrCipherOpened);
    ST_VL_Mascara.Caption         := getValorDatMemoria('TcpIp.TE_MASCARA'         ,v_tstrCipherOpened);
    ST_VL_ServidorDHCP.Caption    := getValorDatMemoria('TcpIp.TE_SERV_DHCP'       ,v_tstrCipherOpened);
    ST_VL_WinsPrimario.Caption    := getValorDatMemoria('TcpIp.TE_WINS_PRIMARIO'   ,v_tstrCipherOpened);
    ST_VL_WinsSecundario.Caption  := getValorDatMemoria('TcpIp.TE_WINS_SECUNDARIO' ,v_tstrCipherOpened);

    // Exibi��o das informa��es de Sistemas Monitorados...
    v_conta_perfis := 1;
    v_conta_infos_coletadas := 0;
    v_tripa_perfis := '*';
    while v_tripa_perfis <> '' do
      begin

        v_tripa_perfis := getValorDatMemoria('Coletas.SIS' + trim(inttostr(v_conta_perfis)),v_tstrCipherOpened);
        v_conta_perfis := v_conta_perfis + 1;

        if (trim(v_tripa_perfis) <> '') then
          Begin
            v_array_perfis := explode(v_tripa_perfis,',');

            // ATEN��O!!! Antes da implementa��o de INFORMA��ES GERAIS o Count ia at� 11, ok?!
            if (v_array_perfis.Count > 11) and (v_array_perfis[11]='S') then
              Begin
                v_tripa_infos_coletadas := getValorDatMemoria('Coletas.Sistemas_Monitorados',v_tstrCipherOpened);

                if (trim(v_tripa_infos_coletadas) <> '') then
                  Begin
                    v_array_tripa_infos_coletadas := explode(v_tripa_infos_coletadas,'#');
                    for intAux := 0 to v_array_tripa_infos_coletadas.Count-1 Do
                      Begin
                        v_array_infos_coletadas := explode(v_array_tripa_infos_coletadas[intAux],',');

                        if (v_array_infos_coletadas[0]=v_array_perfis[0]) then
                          Begin
                            if  ((trim(v_array_infos_coletadas[1])<>'') and (trim(v_array_infos_coletadas[1])<>'?')) or
                                ((trim(v_array_infos_coletadas[3])<>'') and (trim(v_array_infos_coletadas[3])<>'?')) then
                              Begin
                                v_achei := false;
                                listSistemasMonitorados.Items.Add;
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].Caption := Format('%2d', [v_conta_infos_coletadas+1])+') '+v_array_perfis[12];
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].SubItems.Add(v_array_infos_coletadas[1]);
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].SubItems.Add(v_array_infos_coletadas[3]);
                                v_conta_infos_coletadas := v_conta_infos_coletadas + 1;

                              End;
                          End;
                      End;
                  End;
              End;
          End;
      end;

    lbDataColeta.Caption := '('+FormatDateTime('dd/mm/yyyy', now)+')';

    strAux := GetValorDatMemoria('Coletas.HOJE', v_tstrCipherOpened);
    if (strAux <> '') then
      Begin
        if (copy(strAux,0,8) = FormatDateTime('yyyymmdd', Date)) then
          Begin
            // Vamos reaproveitar algumas vari�veis!...

            v_array_perfis := explode(strAux,'#');
            for intAux := 1 to v_array_perfis.Count-1 Do
              Begin
                v_array_infos_coletadas := explode(v_array_perfis[intAux],',');
                listaColetas.Items.Add;
                listaColetas.Items[intAux-1].Caption := v_array_infos_coletadas[0];
                listaColetas.Items[intAux-1].SubItems.Add(v_array_infos_coletadas[1]);

                // Verifico se houve problema na coleta...
                if (v_array_infos_coletadas[2]<>'99999999') then
                  listaColetas.Items[intAux-1].SubItems.Add(v_array_infos_coletadas[2])
                else
                  Begin
                    listaColetas.Items[intAux-1].SubItems.Add('--------');
                    v_array_infos_coletadas[3] := v_array_infos_coletadas[2];
                  End;

                // C�digos Poss�veis: -1 : Problema no Envio da Coleta
                //                     1 : Coleta Enviada
                //                     0 : Sem Coleta para Envio
                strAux := IfThen(v_array_infos_coletadas[3]='1','Coleta Enviada ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='-1','Problema Enviando Coleta ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='0','Sem Coleta para Envio ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='99999999','Problema no Processo de Coleta!','Status Desconhecido!'))));
                listaColetas.Items[intAux-1].SubItems.Add(strAux);
              End;
          End
      End
    else
      Begin
        listSistemasMonitorados.Items.Add;
        listSistemasMonitorados.Items[0].Caption := 'N�o H� Coletas Registradas Nesta Data';
      End;
  end;

procedure TFormularioGeral.Bt_Fechar_InfosGeraisClick(Sender: TObject);
  begin
    FormularioGeral.Enabled := false;
    FormularioGeral.Visible := false;
  end;

end.
