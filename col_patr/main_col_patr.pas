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

unit main_col_patr;

interface

uses  IniFiles,
      Windows,
      Sysutils,    // Deve ser colocado ap�s o Windows acima, nunca antes
      Registry,
      LibXmlParser,
      XML,
      StdCtrls,
      Controls,
      Classes,
      Forms,
      PJVersionInfo,
      DIALOGS,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64,
      ExtCtrls,
      Math;

var  p_path_cacic       : String;
     v_Dados_Patrimonio : TStrings;
     v_CipherKey,
     v_IV,
     v_strCipherClosed,
     v_strCipherOpened,
     v_configs,
     v_option           : String;
     v_Debugs,
     l_cs_cipher        : boolean;

var v_tstrCipherOpened,
    v_tstrCipherOpened1             : TStrings;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

type
  TFormPatrimonio = class(TForm)
    GroupBox1: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    GroupBox2: TGroupBox;
    Etiqueta1: TLabel;
    Etiqueta2: TLabel;
    Etiqueta3: TLabel;
    id_unid_organizacional_nivel1: TComboBox;
    id_unid_organizacional_nivel2: TComboBox;
    te_localizacao_complementar: TEdit;
    Button2: TButton;
    Etiqueta4: TLabel;
    Etiqueta5: TLabel;
    Etiqueta6: TLabel;
    Etiqueta7: TLabel;
    Etiqueta8: TLabel;
    Etiqueta9: TLabel;
    te_info_patrimonio1: TEdit;
    te_info_patrimonio2: TEdit;
    te_info_patrimonio3: TEdit;
    te_info_patrimonio4: TEdit;
    te_info_patrimonio5: TEdit;
    te_info_patrimonio6: TEdit;
    Etiqueta1a: TLabel;
    id_unid_organizacional_nivel1a: TComboBox;
    Panel1: TPanel;
    lbVersao: TLabel;

    function  SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
    function  GetValorChaveRegEdit(Chave: String): Variant;
    function  GetRootKey(strRootKey: String): HKEY;
    Function  RemoveCaracteresEspeciais(Texto, p_Fill : String; p_start, p_end:integer) : String;
    function  HomeDrive : string;
    Function  Implode(p_Array : TStrings ; p_Separador : String) : String;
    Function  CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
    function  GetWinVer: Integer;
    Function  Explode(Texto, Separador : String) : TStrings;
    Function  CipherOpen(p_DatFileName : string) : TStrings;
    Function  GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
    function  PadWithZeros(const str : string; size : integer) : string;
    function  EnCrypt(p_Data : String) : String;
    function  DeCrypt(p_Data : String) : String;
    procedure FormCreate(Sender: TObject);
    procedure MontaCombos;
    procedure MontaInterface;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure id_unid_organizacional_nivel1Change(Sender: TObject);
    procedure AtualizaPatrimonio(Sender: TObject);
    procedure RecuperaValoresAnteriores;
    procedure log_diario(strMsg : String);
    procedure log_DEBUG(p_msg:string);
    Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
    function  GetVersionInfo(p_File: string):string;
    function  VerFmt(const MS, LS: DWORD): string;
    function  GetFolderDate(Folder: string): TDateTime;
    procedure id_unid_organizacional_nivel1aChange(Sender: TObject);
  private
    var_id_unid_organizacional_nivel1,
    var_id_unid_organizacional_nivel1a,
    var_id_unid_organizacional_nivel2,
    var_id_Local,
    var_te_localizacao_complementar,
    var_te_info_patrimonio1,
    var_te_info_patrimonio2,
    var_te_info_patrimonio3,
    var_te_info_patrimonio4,
    var_te_info_patrimonio5,
    var_te_info_patrimonio6 : String;
  public
  end;

var
  FormPatrimonio: TFormPatrimonio;

implementation

{$R *.dfm}


// Estruturas de dados para armazenar os itens da uon1 e uon2
type
  TRegistroUON1 = record
    id1 : String;
    nm1 : String;
  end;
  TVetorUON1 = array of TRegistroUON1;

  TRegistroUON1a = record
    id1     : String;
    id1a    : String;
    nm1a    : String;
    id_local: String;
  end;

  TVetorUON1a = array of TRegistroUON1a;

  TRegistroUON2 = record
    id1a    : String;
    id2     : String;
    nm2     : String;
    id_local: String;
  end;
  TVetorUON2 = array of TRegistroUON2;

var VetorUON1  : TVetorUON1;
    VetorUON1a : TVetorUON1a;
    VetorUON2  : TVetorUON2;

    // Esse array � usado apenas para saber a uon1a, ap�s a filtragem pelo uon1
    VetorUON1aFiltrado : array of String;

    // Esse array � usado apenas para saber a uon2, ap�s a filtragem pelo uon1
    VetorUON2Filtrado : array of String;

// Pad a string with zeros so that it is a multiple of size
function TFormPatrimonio.PadWithZeros(const str : string; size : integer) : string;
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

function TFormPatrimonio.GetFolderDate(Folder: string): TDateTime;
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

// Encrypt a string and return the Base64 encoded result
function TFormPatrimonio.EnCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    if l_cs_cipher then
      Begin

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
      End
    else
      Begin
        log_DEBUG('Criptografia(DESATIVADA) de "'+p_Data+'"');
        Result := p_Data;
      End;
  Except
    log_diario('Erro no Processo de Criptografia');
  End;
end;

function TFormPatrimonio.DeCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    if l_cs_cipher then
      Begin
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
        log_DEBUG('DeCriptografia(ATIVADA) de "'+p_Data+'" => "'+l_Data+'"');
        // Return the result
        Result := trim(l_Data);
      End
    else
      Begin
        log_DEBUG('DeCriptografia(DESATIVADA) de "'+p_Data+'"');
        Result := p_Data;
      End;
  Except
    log_diario('Erro no Processo de Decriptografia');
  End;
end;

function TFormPatrimonio.HomeDrive : string;
var
WinDir : array [0..144] of char;
begin
GetWindowsDirectory (WinDir, 144);
Result := StrPas (WinDir);
end;

Function TFormPatrimonio.Implode(p_Array : TStrings ; p_Separador : String) : String;
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

Function TFormPatrimonio.CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
var v_strCipherOpenImploded : string;
    v_DatFile               : TextFile;
    v_cs_cipher             : boolean;
begin
   try
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma vari�vel do tipo TextFile}

       // Cria��o do arquivo .DAT
       Rewrite (v_DatFile);
       Append(v_DatFile);

       v_strCipherOpenImploded := FormPatrimonio.Implode(p_tstrCipherOpened,'=CacicIsFree=');
       v_cs_cipher := l_cs_cipher;
       l_cs_cipher := true;
       log_DEBUG('Rotina de Fechamento do cacic2.dat ATIVANDO criptografia.');
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded);
       l_cs_cipher := v_cs_cipher;
       log_DEBUG('Rotina de Fechamento do cacic2.dat RESTAURANDO estado da criptografia.');

       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}

       CloseFile(v_DatFile);
   except
   end;
end;
function TFormPatrimonio.GetWinVer: Integer;
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
  majorVer, minorVer: Integer;
begin
  Result := cOsUnknown;
  { set operating system type flag }
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
  begin
    majorVer := osVerInfo.dwMajorVersion;
    minorVer := osVerInfo.dwMinorVersion;
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
end;
Function TFormPatrimonio.Explode(Texto, Separador : String) : TStrings;
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


Function TFormPatrimonio.CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
    intLoop           : integer;
    v_cs_cipher       : boolean;
begin
  v_strCipherOpened    := '';
  if FileExists(p_DatFileName) then
    begin
      AssignFile(v_DatFile,p_DatFileName);
      {$IOChecks off}
      Reset(v_DatFile);
      {$IOChecks on}
      if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
         begin
           Rewrite (v_DatFile);
           Append(v_DatFile);
         end;

      Readln(v_DatFile,v_strCipherClosed);
      while not EOF(v_DatFile) do Readln(v_DatFile,v_strCipherClosed);
      CloseFile(v_DatFile);
      v_cs_cipher := l_cs_cipher;
      l_cs_cipher := true;
      log_DEBUG('Rotina de Abertura do cacic2.dat ATIVANDO criptografia.');
      v_strCipherOpened:= DeCrypt(v_strCipherClosed);
      l_cs_cipher := v_cs_cipher;
      log_DEBUG('Rotina de Abertura do cacic2.dat RESTAURANDO estado da criptografia.');
    end;
    if (trim(v_strCipherOpened)<>'') then
      Result := explode(v_strCipherOpened,'=CacicIsFree=')
    else
      Result := explode('Configs.ID_SO=CacicIsFree='+inttostr(GetWinVer)+'=CacicIsFree=Configs.Endereco_WS=CacicIsFree=/cacic2/ws/','=CacicIsFree=');

    if Result.Count mod 2 = 0 then
        Result.Add('');

    log_DEBUG('MemoryDAT aberto com sucesso!');
    if v_Debugs then
      for intLoop := 0 to (Result.Count-1) do
        log_DEBUG('Posi��o ['+inttostr(intLoop)+'] do MemoryDAT: '+Result[intLoop]);

end;

Procedure TFormPatrimonio.SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
begin
    log_DEBUG('Gravando Chave: "'+p_Chave+ '" => "'+p_Valor+'"');
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(p_Valor);
      End;
end;
Function TFormPatrimonio.GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
begin

    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := trim(p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1])
    else
      Result := '';
    log_DEBUG('Resgatando Chave: "'+p_Chave+ '" => "'+Result+'"');      
end;

function TFormPatrimonio.SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
var RegEditSet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue : String;
    ListaAuxSet : TStrings;
    I : Integer;
begin
    ListaAuxSet := Explode(Chave, '\');
    strRootKey := ListaAuxSet[0];
    For I := 1 To ListaAuxSet.Count - 2 Do strKey := strKey + ListaAuxSet[I] + '\';
    strValue := ListaAuxSet[ListaAuxSet.Count - 1];

    RegEditSet := TRegistry.Create;
    try
        RegEditSet.Access := KEY_WRITE;
        RegEditSet.Rootkey := GetRootKey(strRootKey);

        if RegEditSet.OpenKey(strKey, True) then
        Begin
            RegDataType := RegEditSet.GetDataType(strValue);
            if RegDataType = rdString then
              begin
                RegEditSet.WriteString(strValue, Dado);
              end
            else if RegDataType = rdExpandString then
              begin
                RegEditSet.WriteExpandString(strValue, Dado);
              end
            else if RegDataType = rdInteger then
              begin
                RegEditSet.WriteInteger(strValue, Dado);
              end
            else
              begin
                RegEditSet.WriteString(strValue, Dado);
              end;

        end;
    finally
      RegEditSet.CloseKey;
    end;
    ListaAuxSet.Free;
    RegEditSet.Free;
end;


function TFormPatrimonio.GetRootKey(strRootKey: String): HKEY;
begin
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

function TformPatrimonio.VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function TformPatrimonio.GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;

procedure TformPatrimonio.log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;


procedure TformPatrimonio.log_diario(strMsg : String);
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
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path_cacic + 'cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI n�o � da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Coletor PATR] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
     log_diario('Erro na grava��o do log!');
   end;
end;

Function RetornaValorVetorUON1(id1 : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1)-1)  Do
       If (VetorUON1[I].id1 = id1) Then Result := VetorUON1[I].nm1;
end;

Function RetornaValorVetorUON1a(id1a : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1a)-1)  Do
       If (VetorUON1a[I].id1a     = id1a) Then Result := VetorUON1a[I].nm1a;
end;
Function RetornaValorVetorUON2(id2, idLocal : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON2)-1)  Do
       If (VetorUON2[I].id2      = id2) and
          (VetorUON2[I].id_local = idLocal) Then Result := VetorUON2[I].nm2;
end;


procedure TFormPatrimonio.RecuperaValoresAnteriores;
begin
    Etiqueta1.Caption  := DeCrypt(XML.XML_RetornaValor('te_etiqueta1', v_configs));
    Etiqueta1a.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta1a', v_configs));

    var_id_unid_organizacional_nivel1 := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1',v_tstrCipherOpened);
    if (var_id_unid_organizacional_nivel1='') then var_id_unid_organizacional_nivel1 := DeCrypt(XML.XML_RetornaValor('ID_UON1', v_configs));

    var_id_unid_organizacional_nivel1a := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1a',v_tstrCipherOpened);
    if (var_id_unid_organizacional_nivel1a='') then var_id_unid_organizacional_nivel1a := DeCrypt(XML.XML_RetornaValor('ID_UON1a', v_configs));

    var_id_unid_organizacional_nivel2 := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2',v_tstrCipherOpened);
    if (var_id_unid_organizacional_nivel2='') then var_id_unid_organizacional_nivel2 := DeCrypt(XML.XML_RetornaValor('ID_UON2', v_configs));

    var_te_localizacao_complementar   := GetValorDatMemoria('Patrimonio.te_localizacao_complementar',v_tstrCipherOpened);
    if (var_te_localizacao_complementar='') then var_te_localizacao_complementar := DeCrypt(XML.XML_RetornaValor('TE_LOC_COMPL', v_configs));

    // Tentarei buscar informa��o gravada no Registry
    var_te_info_patrimonio1           := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1');
    if (var_te_info_patrimonio1='') then
      Begin
        var_te_info_patrimonio1           := GetValorDatMemoria('Patrimonio.te_info_patrimonio1',v_tstrCipherOpened);
      End;
    if (var_te_info_patrimonio1='') then var_te_info_patrimonio1 := DeCrypt(XML.XML_RetornaValor('TE_INFO1', v_configs));

    var_te_info_patrimonio2           := GetValorDatMemoria('Patrimonio.te_info_patrimonio2',v_tstrCipherOpened);
    if (var_te_info_patrimonio2='') then var_te_info_patrimonio2 := DeCrypt(XML.XML_RetornaValor('TE_INFO2', v_configs));

    var_te_info_patrimonio3           := GetValorDatMemoria('Patrimonio.te_info_patrimonio3',v_tstrCipherOpened);
    if (var_te_info_patrimonio3='') then var_te_info_patrimonio3 := DeCrypt(XML.XML_RetornaValor('TE_INFO3', v_configs));

    // Tentarei buscar informa��o gravada no Registry
    var_te_info_patrimonio4           := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4');
    if (var_te_info_patrimonio4='') then
      Begin
        var_te_info_patrimonio4           := GetValorDatMemoria('Patrimonio.te_info_patrimonio4',v_tstrCipherOpened);
      End;
    if (var_te_info_patrimonio4='') then var_te_info_patrimonio4 := DeCrypt(XML.XML_RetornaValor('TE_INFO4', v_configs));

    var_te_info_patrimonio5           := GetValorDatMemoria('Patrimonio.te_info_patrimonio5',v_tstrCipherOpened);
    if (var_te_info_patrimonio5='') then var_te_info_patrimonio5 := DeCrypt(XML.XML_RetornaValor('TE_INFO5', v_configs));

    var_te_info_patrimonio6           := GetValorDatMemoria('Patrimonio.te_info_patrimonio6',v_tstrCipherOpened);
    if (var_te_info_patrimonio6='') then var_te_info_patrimonio6 := DeCrypt(XML.XML_RetornaValor('TE_INFO6', v_configs));

    Try
      id_unid_organizacional_nivel1.ItemIndex := id_unid_organizacional_nivel1.Items.IndexOf(RetornaValorVetorUON1(var_id_unid_organizacional_nivel1));
      id_unid_organizacional_nivel1Change(Nil); // Para filtrar os valores do combo2 de acordo com o valor selecionado no combo1

    Except
    end;

    Try
      id_unid_organizacional_nivel1a.ItemIndex := id_unid_organizacional_nivel1a.Items.IndexOf(RetornaValorVetorUON1a(var_id_unid_organizacional_nivel1a));
      id_unid_organizacional_nivel1aChange(Nil); // Para filtrar os valores do combo3 de acordo com o valor selecionado no combo2
    Except
    End;
    
    Try
      id_unid_organizacional_nivel2.ItemIndex := id_unid_organizacional_nivel2.Items.IndexOf(RetornaValorVetorUON2(var_id_unid_organizacional_nivel2,var_id_Local));
    Except
    end;


    te_localizacao_complementar.Text  := var_te_localizacao_complementar;
    te_info_patrimonio1.Text          := var_te_info_patrimonio1;
    te_info_patrimonio2.Text          := var_te_info_patrimonio2;
    te_info_patrimonio3.Text          := var_te_info_patrimonio3;
    te_info_patrimonio4.Text          := var_te_info_patrimonio4;
    te_info_patrimonio5.Text          := var_te_info_patrimonio5;
    te_info_patrimonio6.Text          := var_te_info_patrimonio6;
end;



procedure TFormPatrimonio.MontaCombos;
var Parser   : TXmlParser;
    i        : integer;
    v_Tag    : boolean;
    strAux,
    strAux1,
    strTagName,
    strItemName  : string;
begin
  Parser := TXmlParser.Create;
  Parser.Normalize := True;
  Parser.LoadFromBuffer(PAnsiChar(v_Configs));
  log_DEBUG('v_Configs: '+v_Configs);
  Parser.StartScan;
  i := -1;
  strItemName := '';
  strTagName  := '';
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o n�mero de itens recebidos.
          strTagName := 'IT1';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1')Then
       Begin
         strAux1 := DeCrypt(Parser.CurContent);
         if      (strItemName = 'ID1') then
           Begin
             VetorUON1[i].id1 := strAux1;
             log_DEBUG('Gravei VetorUON1.id1: "'+strAux1+'"');
           End
         else if (strItemName = 'NM1') then
           Begin
             VetorUON1[i].nm1 := strAux1;
             log_DEBUG('Gravei VetorUON1.nm1: "'+strAux1+'"');
           End;
       End;
    End;

  // C�digo para montar o combo 2
  Parser.StartScan;
  strTagName := '';
  strAux1    := '';
  i := -1;
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1A') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1a, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o n�mero de itens recebidos.
          strTagName := 'IT1A';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1A') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1A')Then
        Begin
          strAux1 := DeCrypt(Parser.CurContent);
          if      (strItemName = 'ID1') then
            Begin
              VetorUON1a[i].id1 := strAux1;
              log_DEBUG('Gravei VetorUON1a.id1: "'+strAux1+'"');
            End
          else if (strItemName = 'SG_LOC') then
            Begin
              strAux := ' ('+strAux1 + ')';
            End
          else if (strItemName = 'ID1A') then
            Begin
              VetorUON1a[i].id1a := strAux1;
              log_DEBUG('Gravei VetorUON1a.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'NM1A') then
            Begin
              VetorUON1a[i].nm1a := strAux1+strAux;
              log_DEBUG('Gravei VetorUON1a.nm1a: "'+strAux1+strAux+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON1a[i].id_local := strAux1;
              log_DEBUG('Gravei VetorUON1a.id_local: "'+strAux1+'"');
            End;

        End;
    end;

  // C�digo para montar o combo 3
  Parser.StartScan;
  strTagName := '';
  i := -1;
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT2') Then
       Begin
          i := i + 1;
          SetLength(VetorUON2, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o n�mero de itens recebidos.
          strTagName := 'IT2';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT2') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT2')Then
        Begin
          strAux1  := DeCrypt(Parser.CurContent);
          if      (strItemName = 'ID1A') then
            Begin
              VetorUON2[i].id1a := strAux1;
              log_DEBUG('Gravei VetorUON2.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'ID2') then
            Begin
              VetorUON2[i].id2 := strAux1;
              log_DEBUG('Gravei VetorUON2.id2: "'+strAux1+'"');
            End
          else if (strItemName = 'NM2') then
            Begin
              VetorUON2[i].nm2 := strAux1;
              log_DEBUG('Gravei VetorUON2.nm2: "'+strAux1+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON2[i].id_local := strAux1;
              log_DEBUG('Gravei VetorUON2.id_local: "'+strAux1+'"');
            End;

        End;
    end;
  Parser.Free;
  // Como os itens do combo1 nunca mudam durante a execu��o do programa (ao contrario dos combo2 e 3), posso colocar o seu preenchimento aqui mesmo.
  id_unid_organizacional_nivel1.Items.Clear;
  For i := 0 to Length(VetorUON1) - 1 Do
     id_unid_organizacional_nivel1.Items.Add(VetorUON1[i].nm1);

end;


procedure TFormPatrimonio.id_unid_organizacional_nivel1Change(Sender: TObject);
var i, j: Word;
    strAux,
    strIdUON1 : String;
begin
      // Filtro os itens do combo2, de acordo com o item selecionado no combo1
      strIdUON1 := VetorUON1[id_unid_organizacional_nivel1.ItemIndex].id1;
      id_unid_organizacional_nivel1a.Items.Clear;
      id_unid_organizacional_nivel2.Items.Clear;
      id_unid_organizacional_nivel1a.Enabled := false;
      id_unid_organizacional_nivel2.Enabled  := false;
      SetLength(VetorUON1aFiltrado, 0);

      For i := 0 to Length(VetorUON1a) - 1 Do
      Begin
          Try
            if VetorUON1a[i].id1 = strIdUON1 then
              Begin
                id_unid_organizacional_nivel1a.Items.Add(VetorUON1a[i].nm1a);
                j := Length(VetorUON1aFiltrado);
                SetLength(VetorUON1aFiltrado, j + 1);
                VetorUON1aFiltrado[j] := VetorUON1a[i].id1a;
              end;
          Except
          End;
      end;
      if (id_unid_organizacional_nivel1a.Items.Count > 0) then
        Begin
          id_unid_organizacional_nivel1a.Enabled   := true;
          id_unid_organizacional_nivel1a.ItemIndex := 0;
          id_unid_organizacional_nivel1aChange(nil);
        End;

end;
procedure TFormPatrimonio.id_unid_organizacional_nivel1aChange(
  Sender: TObject);
var i, j: Word;
    strIdUON1a,
    strIdLocal : String;
    intAux     : integer;
begin
      // Filtro os itens do combo2, de acordo com o item selecionado no combo1
      intAux := IfThen(id_unid_organizacional_nivel1a.Items.Count > 1,id_unid_organizacional_nivel1a.ItemIndex+1,0);
      strIdUON1a := VetorUON1a[intAux].id1a;
      strIdLocal := VetorUON1a[intAux].id_local;
      id_unid_organizacional_nivel2.Items.Clear;
      id_unid_organizacional_nivel2.Enabled  := false;
      SetLength(VetorUON2Filtrado, 0);

      For i := 0 to Length(VetorUON2) - 1 Do
      Begin
          Try
            if (VetorUON2[i].id1a     = strIdUON1a) and
               (VetorUON2[i].id_local = strIdLocal) then
              Begin
                id_unid_organizacional_nivel2.Items.Add(VetorUON2[i].nm2);
                j := Length(VetorUON2Filtrado);
                SetLength(VetorUON2Filtrado, j + 1);
                VetorUON2Filtrado[j] := VetorUON2[i].id2 + '#' + VetorUON2[i].id_local;
              end;
          Except
          End;
      end;
      if (id_unid_organizacional_nivel2.Items.Count > 0) then
        Begin
          id_unid_organizacional_nivel2.Enabled := true;
          id_unid_organizacional_nivel2.ItemIndex := 0;
        End;
end;

procedure TFormPatrimonio.AtualizaPatrimonio(Sender: TObject);
var strIdUON1,
    strIdUON1a,
    strIdUON2,
    strIdLocal,
    strRetorno : String;
    tstrAux    : TStrings;
begin
     tstrAux := TStrings.Create;
     tstrAux := explode(VetorUON2Filtrado[id_unid_organizacional_nivel2.ItemIndex],'#');
     Try
        strIdUON1  := VetorUON1[id_unid_organizacional_nivel1.ItemIndex].id1;
        strIdUON1a := VetorUON1aFiltrado[id_unid_organizacional_nivel1a.ItemIndex];
        strIdUON2  := tstrAux[0];
        strIdLocal := tstrAux[1];
     Except
     end;
     tstrAux.Free;

     SetValorDatMemoria('Col_Patr.Fim', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
     if (strIdUON1  <> var_id_unid_organizacional_nivel1) or
        (strIdUON1a <> var_id_unid_organizacional_nivel1a) or
        (strIdUON2  <> var_id_unid_organizacional_nivel2) or
         (te_localizacao_complementar.Text <> var_te_localizacao_complementar) or
         (te_info_patrimonio1.Text <> var_te_info_patrimonio1) or
         (te_info_patrimonio2.Text <> var_te_info_patrimonio2) or
         (te_info_patrimonio3.Text <> var_te_info_patrimonio3) or
         (te_info_patrimonio4.Text <> var_te_info_patrimonio4) or
         (te_info_patrimonio5.Text <> var_te_info_patrimonio5) or
         (te_info_patrimonio6.Text <> var_te_info_patrimonio6) then
      begin
         //Envio via rede para ao Agente Gerente, para grava��o no BD.
         SetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1' , strIdUON1, v_tstrCipherOpened1);
         SetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1a', strIdUON1a, v_tstrCipherOpened1);
         SetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel2' , strIdUON2, v_tstrCipherOpened1);
         SetValorDatMemoria('Col_Patr.te_localizacao_complementar'   , te_localizacao_complementar.Text, v_tstrCipherOpened1);
         SetValorDatMemoria('Col_Patr.te_info_patrimonio1'           , te_info_patrimonio1.Text, v_tstrCipherOpened1);
         SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1', te_info_patrimonio1.Text);
         SetValorDatMemoria('Col_Patr.te_info_patrimonio2'           , te_info_patrimonio2.Text, v_tstrCipherOpened1);
         SetValorDatMemoria('Col_Patr.te_info_patrimonio3'           , te_info_patrimonio3.Text, v_tstrCipherOpened1);
         SetValorDatMemoria('Col_Patr.te_info_patrimonio4'           , te_info_patrimonio4.Text, v_tstrCipherOpened1);
         SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4', te_info_patrimonio4.Text);
         SetValorDatMemoria('Col_Patr.te_info_patrimonio5'           , te_info_patrimonio5.Text, v_tstrCipherOpened1);
         SetValorDatMemoria('Col_Patr.te_info_patrimonio6'           , te_info_patrimonio6.Text, v_tstrCipherOpened1);
         CipherClose(p_path_cacic + 'temp\col_patr.dat', v_tstrCipherOpened1);
      end
    else
      Begin
        SetValorDatMemoria('Col_Patr.nada', 'nada', v_tstrCipherOpened1);
        CipherClose(p_path_cacic + 'temp\col_patr.dat', v_tstrCipherOpened1);
      End;
    Application.Terminate;
end;

procedure TFormPatrimonio.MontaInterface;
Begin
   // Se houve altera��o na configura��o da interface, atualizo os dados no registro e depois monto a interface.
   // Caso, contr�rio, pego direto do registro.

   Etiqueta1.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta1', v_configs));
   id_unid_organizacional_nivel1.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta1', v_configs));

   Etiqueta1a.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta1a', v_configs));
   id_unid_organizacional_nivel1a.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta1a', v_configs));

   Etiqueta2.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta2', v_configs));
   id_unid_organizacional_nivel2.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta2', v_configs));

   Etiqueta3.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta3', v_configs));

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta4', v_configs)) = 'S') then
   begin
      Etiqueta4.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta4', v_configs));
      te_info_patrimonio1.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta4', v_configs));
      te_info_patrimonio1.visible := True;
   end
   else begin
      Etiqueta4.Visible := False;
      te_info_patrimonio1.visible := False;

   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta5', v_configs)) = 'S') then
   begin
      Etiqueta5.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta5', v_configs));
      te_info_patrimonio2.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta5', v_configs));
      te_info_patrimonio2.visible := True;
   end
   else begin
      Etiqueta5.Visible := False;
      te_info_patrimonio2.visible := False;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta6', v_configs)) = 'S') then
   begin
      Etiqueta6.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta6', v_configs));
      te_info_patrimonio3.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta6', v_configs));
      te_info_patrimonio3.visible := True;
   end
   else begin
      Etiqueta6.Visible := False;
      te_info_patrimonio3.visible := False;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta7', v_configs)) = 'S') then
   begin
      Etiqueta7.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta7', v_configs));
      te_info_patrimonio4.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta7', v_configs));
      te_info_patrimonio4.visible := True;
   end  else
   begin
      Etiqueta7.Visible := False;
      te_info_patrimonio4.visible := False;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta8', v_configs)) = 'S') then
   begin
      Etiqueta8.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta8', v_configs));
      te_info_patrimonio5.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta8', v_configs));
      te_info_patrimonio5.visible := True;
   end else
   begin
      Etiqueta8.Visible := False;
      te_info_patrimonio5.visible := False;
  end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta9', v_configs)) = 'S') then
  begin
     Etiqueta9.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta9', v_configs));
     te_info_patrimonio6.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta9', v_configs));
     te_info_patrimonio6.visible := True;
  end
  else begin
     Etiqueta9.Visible := False;
     te_info_patrimonio6.visible := False;
  end;
end;

procedure TFormPatrimonio.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   SetValorDatMemoria('Col_Patr.nada', 'nada', v_tstrCipherOpened1);
   CipherClose(p_path_cacic + 'temp\col_patr.dat', v_tstrCipherOpened1);
   Application.Terminate;
end;
// Fun��o adaptada de http://www.latiumsoftware.com/en/delphi/00004.php
//Para buscar do RegEdit...
function TFormPatrimonio.GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    Result := '';
    ListaAuxGet := Explode(Chave, '\');

    strRootKey := ListaAuxGet[0];
    For I := 1 To ListaAuxGet.Count - 2 Do strKey := strKey + ListaAuxGet[I] + '\';
    strValue := ListaAuxGet[ListaAuxGet.Count - 1];
    if (strValue = '(Padr�o)') then strValue := ''; //Para os casos de se querer buscar o valor default (Padr�o)
    RegEditGet := TRegistry.Create;

        RegEditGet.Access := KEY_READ;
        RegEditGet.Rootkey := GetRootKey(strRootKey);
        if RegEditGet.OpenKeyReadOnly(strKey) then //teste
        Begin
             RegDataType := RegEditGet.GetDataType(strValue);
             if (RegDataType = rdString) or (RegDataType = rdExpandString) then Result := RegEditGet.ReadString(strValue)
             else if RegDataType = rdInteger then Result := RegEditGet.ReadInteger(strValue)
             else if (RegDataType = rdBinary) or (RegDataType = rdUnknown)
             then
             begin
               DataSize := RegEditGet.GetDataSize(strValue);
               if DataSize = -1 then exit;
               SetLength(s, DataSize);
               Len := RegEditGet.ReadBinaryData(strValue, PChar(s)^, DataSize);
               if Len <> DataSize then exit;
               Result := trim(RemoveCaracteresEspeciais(s,' ',32,126));
             end
        end;
    finally
    RegEditGet.CloseKey;
    RegEditGet.Free;
    ListaAuxGet.Free;

    end;
end;

Function TFormPatrimonio.RemoveCaracteresEspeciais(Texto, p_Fill : String; p_start, p_end:integer) : String;
var I : Integer;
    strAux : String;
Begin
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := 0 To Length(Texto) Do
       if ord(Texto[I]) in [p_start..p_end] Then
         strAux := strAux + Texto[I]
       else
         strAux := strAux + p_Fill;
   Result := strAux;
end;

procedure TFormPatrimonio.FormCreate(Sender: TObject);
var boolColeta  : boolean;
    tstrTripa1  : TStrings;
    i,intAux    : integer;
    v_Aux       : String;
Begin

  if (ParamCount>0) then
    Begin
      FormPatrimonio.lbVersao.Caption          := 'Vers�o: ' + GetVersionInfo(ParamStr(0));
      For intAux := 1 to ParamCount do
        Begin
          if LowerCase(Copy(ParamStr(intAux),1,13)) = '/p_cipherkey=' then
            v_CipherKey := Trim(Copy(ParamStr(intAux),14,Length((ParamStr(intAux)))));
        End;

       if (trim(v_CipherKey)<>'') then
          Begin
            v_option := 'system';
            For intAux := 1 to ParamCount do
              Begin
                if LowerCase(Copy(ParamStr(intAux),1,10)) = '/p_option=' then
                  v_option := Trim(Copy(ParamStr(intAux),11,Length((ParamStr(intAux)))));
              End;

            tstrTripa1 := explode(ExtractFilePath(Application.Exename),'\'); //Pegarei o n�vel anterior do diret�rio, que deve ser, por exemplo \Cacic
            p_path_cacic := '';
            For i := 0 to tstrTripa1.Count -2 do
              begin
                p_path_cacic := p_path_cacic + tstrTripa1[i] + '\';
              end;

            v_Debugs := false;
            if DirectoryExists(p_path_cacic + 'Temp\Debugs') then
              Begin
                if (FormatDateTime('ddmmyyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                  Begin
                    v_Debugs := true;
                    log_DEBUG('Pasta "' + p_path_cacic + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
                  End;
              End;

            // A chave AES foi obtida no par�metro p_CipherKey. Recomenda-se que cada empresa altere a sua chave.
            v_IV                := 'abcdefghijklmnop';
            v_tstrCipherOpened  := TStrings.Create;
            v_tstrCipherOpened  := CipherOpen(p_path_cacic + 'cacic2.dat');

            v_tstrCipherOpened1 := TStrings.Create;
            v_tstrCipherOpened1 := CipherOpen(p_path_cacic + 'temp\col_patr.dat');

            // Os valores poss�veis ser�o 0-DESLIGADO 1-LIGADO 2-ESPERA PARA LIGAR (Ser� transformado em "1") 3-Ainda se comunicar� com o Gerente WEB
            l_cs_cipher  := false;
            v_Aux := GetValorDatMemoria('Configs.CS_CIPHER', v_tstrCipherOpened);
            if (v_Aux='1')then
               Begin
                 l_cs_cipher  := true;
               End;

            Try
              boolColeta := false;
              if (GetValorDatMemoria('Patrimonio.in_alteracao_fisica',v_tstrCipherOpened)= 'S') then
                Begin
                  // Solicita o cadastramento de informa��es de patrim�nio caso seja detectado remanejamento para uma nova rede.
                  MessageDlg('Aten��o: foi identificada uma altera��o na localiza��o f�sica deste computador. Por favor, confirme as informa��es que ser�o apresentadas na tela que ser� exibida a seguir.', mtInformation, [mbOk], 0);
                  boolColeta := true;
                End
              Else if (GetValorDatMemoria('Patrimonio.in_renovacao_informacoes',v_tstrCipherOpened)= 'S') and (v_option='system') then
                Begin
                  // Solicita o cadastramento de informa��es de patrim�nio caso tenha completado o prazo configurado para renova��o de informa��es.
                  MessageDlg('Aten��o: � necess�rio o preenchimento/atualiza��o das informa��es de Patrim�nio e Localiza��o F�sica deste computador. Por favor, confirme as informa��es que ser�o apresentadas na tela que ser� exibida a seguir.', mtInformation, [mbOk], 0);
                  boolColeta := true;
                end
              Else if (GetValorDatMemoria('Patrimonio.dt_ultima_renovacao_patrim',v_tstrCipherOpened)= '') then
                Begin
                  // Solicita o cadastramento de informa��es de patrim�nio caso ainda n�o tenha sido cadastrado.
                  boolColeta := true;
                end;

              if boolColeta then
                  Begin
                    SetValorDatMemoria('Col_Patr.Inicio', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
                    log_diario('Coletando informa��es de Patrim�nio e Localiza��o F�sica.');
                    v_configs := GetValorDatMemoria('Patrimonio.Configs',v_tstrCipherOpened);
                    log_DEBUG('Configura��es obtidas: '+v_configs);

                    MontaInterface;
                    MontaCombos;
                    RecuperaValoresAnteriores;
                    
                  End;
            Except
              SetValorDatMemoria('Col_Patr.nada','nada', v_tstrCipherOpened1);
              SetValorDatMemoria('Col_Patr.Fim', '99999999', v_tstrCipherOpened1);
              CipherClose(p_path_cacic + 'temp\col_patr.dat', v_tstrCipherOpened1);
              Application.Terminate;
            End;
          End;
    End;
end;



end.
