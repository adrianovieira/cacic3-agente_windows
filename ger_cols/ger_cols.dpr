(*
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informa��es da Previd�ncia Social, Brasil

Este arquivo � parte do programa CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais

O CACIC � um software livre; voc� pode redistribui-lo e/ou modifica-lo dentro dos termos da Licen�a P�blica Geral GNU como
publicada pela Funda��o do Software Livre (FSF); na vers�o 2 da Licen�a, ou (na sua opini�o) qualquer vers�o.

Este programa � distribuido na esperan�a que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUA��O a qualquer
MERCADO ou APLICA��O EM PARTICULAR. Veja a Licen�a P�blica Geral GNU para maiores detalhes.

Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral GNU, sob o t�tulo "LICENCA.txt", junto com este programa, se n�o, escreva para a Funda��o do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

NOTA: O componente MiTeC System Information Component (MSIC) � baseado na classe TComponent e cont�m alguns subcomponentes baseados na classe TPersistent
      Este componente � apenas freeware e n�o open-source, e foi baixado de http://www.mitec.cz/Downloads/MSIC.zip
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

program ger_cols;
{$R *.res}

uses
  ShellApi,
  Windows,
  SysUtils,
  Classes,
  IdTCPConnection,
  IdTCPClient,
  IdHTTP,
  IdFTP,
  idFTPCommon,
  IdBaseComponent,
  IdComponent,
  PJVersionInfo,
  MSI_Machine,
  MSI_NETWORK,
  MSI_XML_Reports,
  StrUtils,
  Math,
  WinSock,
  NB30,
  IniFiles,
  Registry,
  LibXmlParser in 'LibXmlParser.pas',
  ZLibEx,
  CACIC_Library in '..\CACIC_Library.pas';

{$APPTYPE CONSOLE}
var
  v_scripter,
  p_Shell_Command,
  v_acao_gercols,
  v_Tamanho_Arquivo,
  v_Endereco_Servidor,
  v_Aux,
  strAux,
  endereco_servidor_cacic,
  v_ModulosOpcoes,
  v_ResultCompress,
  v_ResultUnCompress : string;

var
  v_Aguarde                 : TextFile;

var
  CountUPD,
  intAux,
  intMontaBatch,
  intLoop : integer;

var
  tstrTripa1,
  v_tstrCipherOpened,
  v_tstrCipherOpened1,
  tstringsAux               : TStrings;

var
  v_Debugs,
  l_cs_cipher,
  l_cs_compress,
  v_CS_AUTO_UPDATE          : boolean;

var
  BatchFile,
  Request_Ger_Cols          : TStringList;

var
  g_oCacic: TCACIC;

const
  CACIC_APP_NAME            = 'ger_cols';

procedure log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (g_oCacic.getCacicPath + 'cacic2.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(HistoricoLog,g_oCacic.getCacicPath + 'cacic2.log'); {Associa o arquivo a uma vari�vel do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(g_oCacic.getCacicPath + 'cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI n�o � da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Gerente de Coletas] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
       if (trim(v_acao_gercols)='') then v_acao_gercols := strMsg;
   except
   end;
end;

// Gerador de Palavras-Chave
function GeraPalavraChave: String;
var intLimite,
    intContaLetras : integer;
    strPalavra,
    strCaracter    : String;
begin
  Randomize;
  strPalavra  := '';
  intLimite  := RandomRange(10,30); // Gerarei uma palavra com tamanho m�nimo 10 e m�ximo 30
  for intContaLetras := 1 to intLimite do
    Begin
      strCaracter := '.';
      while not (strCaracter[1] in ['0'..'9','A'..'Z','a'..'z']) do
        Begin
          if (strCaracter = '.') then strCaracter := '';
          Randomize;
          strCaracter := chr(RandomRange(1,250));
        End;

      strPalavra := strPalavra + strCaracter;
    End;
  Result := strPalavra;
end;

function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;

procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

function Compress(p_strToCompress : string) : String;
var   v_tstrToCompress, v_tstrCompressed : TStringStream;
      Zip : TZCompressionStream;
begin
  v_tstrToCompress := TStringStream.Create('');
  v_tstrCompressed := TStringStream.Create(p_strToCompress);
  Zip := TZCompressionStream.Create(v_tstrCompressed,zcLevel9);
  Zip.CopyFrom(v_tstrToCompress,v_tstrToCompress.Size);
  Zip.Free;

  Result := ZlibEx.ZCompressStrWeb(v_tstrCompressed.DataString);
end; {Compress}

function DeCompress(p_ToDeCompress : String) : String;
var v_tstrToDeCompress, v_tstrDeCompressed : TStringStream;
    DeZip: TZDecompressionStream;
    i: Integer;
    Buf: array[0..1023]of Byte;
begin
  v_tstrDeCompressed := TstringStream.Create('');
  v_tstrToDeCompress   := TstringStream.Create(p_ToDeCompress);
  DeZip:=TZDecompressionStream.Create(v_tstrDeCompressed);
try
  repeat
  i:=DeZip.Read(Buf, SizeOf(Buf));
  if i <> 0 then v_tstrDeCompressed.Write(buf,i);
  until i <= 0;
except
end;

DeZip.Free;
  Result := ZlibEx.ZDecompressStrEx(v_tstrDeCompressed.DataString);
end; {DeCompress}

Function RemoveCaracteresEspeciais(Texto, p_Fill : String; p_start, p_end:integer) : String;
var I : Integer;
Begin
//     if ord(Texto[I]) in [32..126] Then
//   else strAux := strAux + ' ';  // Coloca um espa�o onde houver caracteres especiais
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := 0 To Length(Texto) Do
       if ord(Texto[I]) in [p_start..p_end] Then
         strAux := strAux + Texto[I]
       else
         strAux := strAux + p_Fill;
   Result := trim(strAux);
end;

Function RemoveZerosFimString(Texto : String) : String;
var I : Integer;
Begin
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := Length(Texto) downto 0 do
       if (ord(Texto[I])<>0) Then
         strAux := Texto[I] + strAux;
   Result := trim(strAux);
end;

Function XML_RetornaValor(Tag : String; Fonte : String): String;
VAR
  Parser : TXmlParser;
begin
  Parser := TXmlParser.Create;
  Parser.Normalize := TRUE;
  Parser.LoadFromBuffer(PAnsiChar(Fonte));
  Parser.StartScan;
  WHILE Parser.Scan DO
  Begin
    if (Parser.CurPartType in [ptContent, ptCData]) Then  // Process Parser.CurContent field here
    begin
         if (UpperCase(Parser.CurName) = UpperCase(Tag)) then
            Result := RemoveZerosFimString(Parser.CurContent);
     end;
  end;
  Parser.Free;
  log_DEBUG('XML Parser retornando: "'+Result+'" para Tag "'+Tag+'"');
end;

function StringtoHex(Data: string): string;
var
  i, i2: Integer;
  s: string;
begin
  i2 := 1;
  for i := 1 to Length(Data) do
  begin
    Inc(i2);
    if i2 = 2 then
    begin
      s  := s + ' ';
      i2 := 1;
    end;
    s := s + IntToHex(Ord(Data[i]), 2);
  end;
  Result := s;
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
var v_Aux     : string;
begin
    log_DEBUG('SetValorDatMemoria - Gravando Chave "'+p_Chave+'" com Valor "'+p_Valor+'"');
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    v_Aux := RemoveZerosFimString(p_Valor);
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1] := v_Aux
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(v_Aux);
      End;
end;

Function GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
var intTamanhoLista,
    intIndiceChave : integer;
begin
    log_DEBUG('GetValorDatMemoria - Resgatando Chave: "'+p_Chave+'"...');
    intIndiceChave := p_tstrCipherOpened.IndexOf(p_Chave);
    log_DEBUG('GetValorDatMemoria - �ndice: '+intToStr(intIndiceChave));
    if (intIndiceChave <> -1) then
      Begin
        intTamanhoLista := p_tstrCipherOpened.Count;
        log_DEBUG('GetValorDatMemoria - Tamanho da Lista: '+intToStr(intTamanhoLista));
        if ((intIndiceChave + 1) < intTamanhoLista) then
          Result := trim(p_tstrCipherOpened[intIndiceChave + 1])
        else
          Result := '';
      End
    else
        Result := '';

    log_DEBUG('GetValorDatMemoria - Retornando "'+Result+'"');
end;

procedure Matar(v_dir,v_files: string);
var SearchRec: TSearchRec;
    Result: Integer;
begin
  Result:=FindFirst(v_dir+v_files, faAnyFile, SearchRec);
  while result=0 do
    begin
      log_DEBUG('Excluindo: "'+v_dir+SearchRec.Name+'"');
      DeleteFile(PChar(v_dir+SearchRec.Name));
      Result:=FindNext(SearchRec);
    end;
end;

Function CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
var v_strCipherOpenImploded,
    v_strCipherClosed,
    strAux                  : string;
    v_DatFile,
    v_DatFileDebug          : TextFile;
    v_cs_cipher             : boolean;
begin
   try
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma vari�vel do tipo TextFile}

       // Cria��o do arquivo .DAT
       Rewrite (v_DatFile);
       Append(v_DatFile);

       if v_Debugs then
         Begin
           strAux := StringReplace(p_DatFileName,'.dat','_Debug.dat',[rfReplaceAll]);
           AssignFile(v_DatFileDebug,strAux); {Associa o arquivo a uma vari�vel do tipo TextFile}

           // Cria��o do arquivo .DAT para Debug
           {$IOChecks off}
           Rewrite (v_DatFileDebug);
           {$IOChecks on}
           Append(v_DatFileDebug);
         End;

       v_strCipherOpenImploded := g_oCacic.implode(p_tstrCipherOpened,g_oCacic.getSeparatorKey);

       v_cs_cipher := l_cs_cipher;
       l_cs_cipher := true;
       log_DEBUG('Rotina de Fechamento do cacic2.dat ATIVANDO criptografia.');
       v_strCipherClosed := g_oCacic.enCrypt(v_strCipherOpenImploded);

       l_cs_cipher := v_cs_cipher;
       log_DEBUG('Rotina de Fechamento do cacic2.dat RESTAURANDO estado da criptografia.');
       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}
       if v_Debugs then
          Begin
            Writeln(v_DatFileDebug,StringReplace(v_strCipherOpenImploded,g_oCacic.getSeparatorKey,#13#10,[rfReplaceAll]));
            CloseFile(v_DatFileDebug);
          End;
       CloseFile(v_DatFile);
   except
     log_diario('ERRO NA GRAVA��O DO ARQUIVO DE CONFIGURA��ES.');
   end;

   // Pausa (5 seg.) para conclus�o da opera��o de ESCRITA do arquivo .DAT
   sleep(5000);
end;

Function CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
    //intLoop           : integer;
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
      v_strCipherOpened:= g_oCacic.deCrypt(v_strCipherClosed);
      l_cs_cipher := v_cs_cipher;
      log_DEBUG('Rotina de Abertura do cacic2.dat RESTAURANDO estado da criptografia.');
    end;
    if (trim(v_strCipherOpened)<>'') then
      Result := g_oCacic.explode(v_strCipherOpened,g_oCacic.getSeparatorKey)
    else
      Result := g_oCacic.explode('Configs.ID_SO'+g_oCacic.getSeparatorKey+g_oCacic.getWindowsStrId()+g_oCacic.getSeparatorKey+'Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorKey);

    if Result.Count mod 2 = 0 then
        Result.Add('');

end;

procedure Apaga_Temps;
begin
  Matar(g_oCacic.getCacicPath + 'temp\','*.vbs');
  Matar(g_oCacic.getCacicPath + 'temp\','*.txt');
end;

procedure Finalizar(p_pausa:boolean);
Begin
  CipherClose(g_oCacic.getDatFileName, v_tstrCipherOpened);
  Apaga_Temps;
  if p_pausa then sleep(2000); // Pausa de 2 segundos para conclus�o de opera��es de arquivos.
End;

procedure Sair;
Begin
  log_DEBUG('Liberando Mem�ria - FreeMemory(0)');
  FreeMemory(0);
  log_DEBUG('Suspendendo - Halt(0)');
  Halt(0);
End;

procedure Seta_l_cs_cipher(p_strRetorno : String);
var v_Aux : string;
Begin
  l_cs_cipher := false;

  v_Aux := XML_RetornaValor('cs_cipher',p_strRetorno);
  if (p_strRetorno = '') or (v_Aux = '') then v_Aux := '3';

  if (v_Aux='1') then
    Begin
      log_DEBUG('ATIVANDO Criptografia!');
      l_cs_cipher := true;
    End
  else if (v_Aux='2') then
    Begin
      log_diario('Setando criptografia para n�vel 2 e finalizando para rechamada.');
      SetValorDatMemoria('Configs.CS_CIPHER', v_Aux,v_tstrCipherOpened);
      Finalizar(true);
      Sair;
    End;
  SetValorDatMemoria('Configs.CS_CIPHER', v_Aux,v_tstrCipherOpened);
End;

procedure Seta_l_cs_compress(p_strRetorno : String);
var v_Aux : string;
Begin
  l_cs_compress := false;

  v_Aux := XML_RetornaValor('cs_compress',p_strRetorno);
  if v_Aux = '' then v_Aux := '3';

  if (v_Aux='1') then
    Begin
      log_DEBUG('ATIVANDO Compress�o!');
      l_cs_compress := true;
    End
  else log_DEBUG('DESATIVANDO Compress�o!');

  SetValorDatMemoria('Configs.CS_COMPRESS', v_Aux,v_tstrCipherOpened);
End;

//Para buscar do Arquivo INI...
// Marreta devido a limita��es do KERNEL w9x no tratamento de arquivos texto e suas se��es
function GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var
  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    Result := '';
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
                      Result := PChar(Copy(FileText[j],v_Size_Key + 1,strLen(PChar(FileText[j]))-v_Size_Key));
                      Break;
                    End;
                End;
            End;
          if (Result <> '') then break;
        End;
    finally
      FileText.Free;
    end;
  end;


function GetFolderDate(Folder: string): TDateTime;
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

function GetRootKey(strRootKey: String): HKEY;
begin
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

// Fun��o adaptada de http://www.latiumsoftware.com/en/delphi/00004.php
// Para buscar do RegEdit...
function GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
      Result := '';
      ListaAuxGet := g_oCacic.explode(Chave, '\');

      strRootKey := ListaAuxGet[0];
      For I := 1 To ListaAuxGet.Count - 2 Do strKey := strKey + ListaAuxGet[I] + '\';

      strValue := ListaAuxGet[ListaAuxGet.Count - 1];
      if (strValue = '(Padr�o)') then strValue := ''; // Para os casos de se querer buscar o valor default (Padr�o)
      RegEditGet := TRegistry.Create;

      RegEditGet.Access   := KEY_READ;
      RegEditGet.Rootkey  := GetRootKey(strRootKey);
      if RegEditGet.OpenKeyReadOnly(strKey) then // Somente para leitura no Registry
        Begin
         RegDataType := RegEditGet.GetDataType(strValue);
         if (RegDataType = rdString) or (RegDataType = rdExpandString) then Result := RegEditGet.ReadString(strValue)
         else if RegDataType = rdInteger then Result := RegEditGet.ReadInteger(strValue)
         else if (RegDataType = rdBinary) or (RegDataType = rdUnknown) then
          begin
           DataSize := RegEditGet.GetDataSize(strValue);
           if DataSize = -1 then exit;
           SetLength(s, DataSize);
           Len := RegEditGet.ReadBinaryData(strValue, PChar(s)^, DataSize);
           if Len <> DataSize then exit;
           Result := RemoveCaracteresEspeciais(s,' ',32,126);
          end
        end;
    finally
      RegEditGet.CloseKey;
      RegEditGet.Free;
      ListaAuxGet.Free;
    end;
end;

function SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
var RegEditSet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue : String;
    ListaAuxSet : TStrings;
    I : Integer;
begin
    ListaAuxSet := g_oCacic.explode(Chave, '\');
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

Procedure DelValorReg(Chave: String);
var RegDelValorReg: TRegistry;
    strRootKey, strKey, strValue : String;
    ListaAuxDel : TStrings;
    I : Integer;
begin
    ListaAuxDel := g_oCacic.explode(Chave, '\');
    strRootKey := ListaAuxDel[0];
    For I := 1 To ListaAuxDel.Count - 2 Do strKey := strKey + ListaAuxDel[I] + '\';
    strValue := ListaAuxDel[ListaAuxDel.Count - 1];
    RegDelValorReg := TRegistry.Create;

    try
        RegDelValorReg.Access := KEY_WRITE;
        RegDelValorReg.Rootkey := GetRootKey(strRootKey);

        if RegDelValorReg.OpenKey(strKey, True) then
        RegDelValorReg.DeleteValue(strValue);
    finally
      RegDelValorReg.CloseKey;
    end;
    RegDelValorReg.Free;
    ListaAuxDel.Free;
end;

function Get_File_Size(sFileToExamine: string; bInKBytes: Boolean): string;
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
  Result := IntToStr(I1);
end;

function LastPos(SubStr, S: string): Integer;
var
  Found, Len, Pos: integer;
begin
  Pos := Length(S);
  Len := Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do
  begin
    if Copy(S, Pos, Len) = SubStr then
      Found := Pos;
    Dec(Pos);
  end;
  LastPos := Found;
end;

function GetMACAddress: string;
var
  NCB: PNCB;
  Adapter: PAdapterStatus;

  URetCode: PChar;
  RetCode: char;
  I: integer;
  Lenum: PlanaEnum;
  _SystemID: string;
  TMPSTR: string;
begin
  Result    := '';
  _SystemID := '';
  Getmem(NCB, SizeOf(TNCB));
  Fillchar(NCB^, SizeOf(TNCB), 0);

  Getmem(Lenum, SizeOf(TLanaEnum));
  Fillchar(Lenum^, SizeOf(TLanaEnum), 0);

  Getmem(Adapter, SizeOf(TAdapterStatus));
  Fillchar(Adapter^, SizeOf(TAdapterStatus), 0);

  Lenum.Length    := chr(0);
  NCB.ncb_command := chr(NCBENUM);
  NCB.ncb_buffer  := Pointer(Lenum);
  NCB.ncb_length  := SizeOf(Lenum);
  RetCode         := Netbios(NCB);

  i := 0;
  repeat
    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBRESET);
    Ncb.ncb_lana_num := lenum.lana[I];
    RetCode          := Netbios(Ncb);

    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBASTAT);
    Ncb.ncb_lana_num := lenum.lana[I];
    // Must be 16
    Ncb.ncb_callname := '*               ';

    Ncb.ncb_buffer := Pointer(Adapter);

    Ncb.ncb_length := SizeOf(TAdapterStatus);
    RetCode        := Netbios(Ncb);
    //---- calc _systemId from mac-address[2-5] XOR mac-address[1]...
    if (RetCode = chr(0)) or (RetCode = chr(6)) then
    begin
      _SystemId := IntToHex(Ord(Adapter.adapter_address[0]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[1]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[2]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[3]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[4]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[5]), 2);
    end;
    Inc(i);
  until (I >= Ord(Lenum.Length)) or (_SystemID <> '00-00-00-00-00-00');
  FreeMem(NCB);
  FreeMem(Adapter);
  FreeMem(Lenum);
  GetMacAddress := _SystemID;
end;

Function GetWorkgroup : String;
var listaAux_GWG : TStrings;
begin
   If Win32Platform = VER_PLATFORM_WIN32_WINDOWS Then { Windows 9x/ME }
       Result := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VxD\VNETSUP\Workgroup')
   Else If Win32Platform = VER_PLATFORM_WIN32_NT Then
     Begin
       Try
          strAux := GetValorChaveRegEdit('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Last Domain');
          listaAux_GWG := g_oCacic.explode(strAux, ',');
          Result := Trim(listaAux_GWG[2]);
          listaAux_GWG.Free;
       Except
          Result := '';
       end;
     end;

   Try
     // XP
     if Result='' then Result := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultDomainName');
   Except
   End;
end;

function GetIPRede(IP_Computador : String ; MascaraRede : String) : String;
var L1_GIR, L2_GIR : TStrings;
    aux1, aux2, aux3, aux4, aux5 : string;
    j, i : short;

    function IntToBin(Value: LongInt;  Digits: Integer): String;
    var i: Integer;
    begin
       Result:='';
       for i:=Digits downto 0 do
          if Value and (1 shl i)<>0 then  Result:=Result + '1'
          else  Result:=Result + '0';
    end;

    function BinToInt(Value: String): LongInt;
    var i,Size: Integer;
        aux : Extended;
    begin
        aux := 0;
        Size := Length(Value);
        For i := Size - 1 downto 0 do
        Begin
           if Copy(Value, i+1, 1) = '1' Then aux := aux + IntPower(2, (Size - 1) - i);
        end;
       Result := Round(aux);
    end;
begin
  Try
   L1_GIR := g_oCacic.explode(IP_Computador, '.');
   L2_GIR := g_oCacic.explode(MascaraRede, '.');

   //Percorre cada um dos 4 octetos dos endere�os
   for i := 0 to 3  do
   Begin
       aux1 := IntToBin(StrToInt(L1_GIR[i]), 7);
       aux2 := IntToBin(StrToInt(L2_GIR[i]), 7);
       aux4 := '';
       for j := 1 to Length(aux1) do
       Begin
           If ((aux1[j] = '0') or (aux2[j] = '0')) then aux3 := '0' else aux3 := '1';
           aux4 := aux4 + aux3;
       end;
       aux5 := aux5 + inttostr(BinToInt(aux4)) + '.';
   end;
   L1_GIR.Free;
   L2_GIR.Free;
   aux5 := Copy(aux5, 0, Length(aux5)-1);

     // Para os casos em que a rotina GetIPRede n�o funcionar!  (Ex.: Win95x em NoteBook)
     if (aux5 = '') or (aux5 = IP_Computador) or (aux5 = '0.0.0.0')then
        begin
        aux5 := '';
        i := 0;
        for j := 1 to Length(IP_Computador) do
          Begin
           If (IP_Computador[j] = '.') then i := i + 1;
           if (i < 3) then
              begin
                aux5 := aux5 + IP_Computador[j];
              end
           else
              begin
                if (i = 3) then //Consideraremos provisoriamente que a m�scara seja 255.255.255.0
                    begin
                      aux5 := aux5 + '.0';
                      i := 30; // Para n�o entrar mais nessa condi��o!
                    end;
              end;
          end;
     end;
   Result := aux5;
  Except
   Result := '';
  End;
end;

// Fun��o criada devido a diverg�ncias entre os valores retornados pelos m�todos dos componentes MSI e seus Reports.
function Parse(p_ClassName, p_SectionName, p_DataName:string; p_Report : TStringList) : String;
var intClasses, intSections, intDatas, v_achei_SectionName, v_array_SectionName_Count : integer;
    v_ClassName, v_DataName, v_string_consulta : string;
    v_array_SectionName : tstrings;
begin
    Result              := '';
    if (p_SectionName <> '') then
      Begin
        v_array_SectionName := g_oCacic.explode(p_SectionName,'/');
        v_array_SectionName_Count := v_array_SectionName.Count;
      End
    else v_array_SectionName_Count := 0;
    v_achei_SectionName := 0;
    v_ClassName         := 'classname="' + p_ClassName + '">';
    v_DataName          := '<data name="' + p_DataName + '"';

    intClasses          := 0;
    try
      While intClasses < p_Report.Count Do
        Begin
          if (pos(v_ClassName,p_Report[intClasses])>0) then
            Begin
              intSections := intClasses;
              While intSections < p_Report.Count Do
                Begin
                  if (p_SectionName<>'') then
                    Begin
                      v_string_consulta := '<section name="' + v_array_SectionName[v_achei_SectionName]+'">';
                      if (pos(v_string_consulta,p_Report[intSections])>0) then v_achei_SectionName := v_achei_SectionName+1;
                    End;

                  if (v_achei_SectionName = v_array_SectionName_Count) then
                    Begin

                      intDatas := intSections;
                      While intDatas < p_Report.Count Do
                        Begin

                          if (pos(v_DataName,p_Report[intDatas])>0) then
                            Begin
                              Result := Copy(p_Report[intDatas],pos('>',p_Report[intDatas])+1,length(p_Report[intDatas]));
                              Result := StringReplace(Result,'</data>','',[rfReplaceAll]);
                              intClasses  := p_Report.Count;
                              intSections := p_Report.Count;
                              intDatas    := p_Report.Count;
                            End;
                            intDatas := intDatas + 1;
                        End; //for intDatas...
                    End; // if pos(v_SectionName...
                    intSections := intSections + 1;
                End; // for intSections...
            End; // if pos(v_ClassName...
            intClasses := intClasses + 1;
        End; // for intClasses...
    except
        Begin
          log_diario('ERRO! Problema na rotina parse');
        End;
    end;
end;

procedure Grava_Debugs(strMsg : String);
var
    DebugsFile : TextFile;
    strDataArqLocal, strDataAtual, v_file_debugs : string;
begin
   try
       v_file_debugs := g_oCacic.getCacicPath + '\Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt';
       FileSetAttr (v_file_debugs,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(DebugsFile,v_file_debugs); {Associa o arquivo a uma vari�vel do tipo TextFile}

       {$IOChecks off}
       Reset(DebugsFile); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
          begin
            Rewrite(DebugsFile);
            Append(DebugsFile);
            Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Debug <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(v_file_debugs)));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);

       if (strDataAtual <> strDataArqLocal) then // Se o arquivo n�o � da data atual...
          begin
            Rewrite(DebugsFile); //Cria/Recria o arquivo
            Append(DebugsFile);
            Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Debug <=======================');
          end;

       Append(DebugsFile);
       Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(DebugsFile); {Fecha o arquivo texto}
   except
     log_diario('Erro na grava��o do Debug!');
   end;
end;

//Para gravar no Arquivo INI...
function SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    if (FileGetAttr(p_Path) and faReadOnly) > 0 then
    FileSetAttr(p_Path, FileGetAttr(p_Path) xor faReadOnly);

    Reg_Ini := TIniFile.Create(p_Path);
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

function GetIP: string;
var ipwsa:TWSAData; p:PHostEnt; s:array[0..128] of char; c:pchar;
begin
  wsastartup(257,ipwsa);
  GetHostName(@s, 128);
  p := GetHostByName(@s);
  c := iNet_ntoa(PInAddr(p^.h_addr_list^)^);
  Result := String(c);
end;

Function ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
var Response_CS     : TStringStream;
    strEndereco,
    v_Endereco_WS,
    strAux          : String;
    idHTTP1         : TIdHTTP;
    intAux          : integer;
    v_AuxRequest    : TStringList;
Begin
    v_AuxRequest := TStringList.Create;
    v_AuxRequest := Request;

    // A partir da vers�o 2.0.2.5+ envio um Classificador indicativo de dados criptografados...
    v_AuxRequest.Values['cs_cipher']   := GetValorDatMemoria('Configs.CS_CIPHER',v_tstrCipherOpened);

    // A partir da vers�o 2.0.2.18+ envio um Classificador indicativo de dados compactados...
    v_AuxRequest.Values['cs_compress']   := GetValorDatMemoria('Configs.CS_COMPRESS',v_tstrCipherOpened);

    strAux := GetValorDatMemoria('TcpIp.TE_IP', v_tstrCipherOpened);
    if (strAux = '') then
        strAux := 'A.B.C.D'; // Apenas para for�ar que o Gerente extraia via _SERVER[REMOTE_ADDR]

    // Tratamentos de valores para tr�fego POST:
    v_AuxRequest.Values['te_node_address']   := StringReplace(g_oCacic.EnCrypt(GetValorDatMemoria('TcpIp.TE_NODE_ADDRESS'   , v_tstrCipherOpened)),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_so']             := StringReplace(g_oCacic.EnCrypt(g_oCacic.getWindowsStrId()                                        ),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_ip']             := StringReplace(g_oCacic.EnCrypt(strAux                                                            ),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['id_ip_rede']        := StringReplace(g_oCacic.EnCrypt(GetValorDatMemoria('TcpIp.ID_IP_REDE'        , v_tstrCipherOpened)),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_workgroup']      := StringReplace(g_oCacic.EnCrypt(GetValorDatMemoria('TcpIp.TE_WORKGROUP'      , v_tstrCipherOpened)),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_nome_computador']:= StringReplace(g_oCacic.EnCrypt(GetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR', v_tstrCipherOpened)),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['id_ip_estacao']     := StringReplace(g_oCacic.EnCrypt(GetIP                                                             ),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_versao_cacic']   := StringReplace(g_oCacic.EnCrypt(getVersionInfo(g_oCacic.getCacicPath + 'cacic2.exe')                       ),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_versao_gercols'] := StringReplace(g_oCacic.EnCrypt(getVersionInfo(ParamStr(0))                                       ),'+','<MAIS>',[rfReplaceAll]);

    v_Endereco_WS       := GetValorDatMemoria('Configs.Endereco_WS', v_tstrCipherOpened);
    v_Endereco_Servidor := GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened);

    if (trim(v_Endereco_WS)='') then
      Begin
        v_Endereco_WS := '/cacic2/ws/';
        SetValorDatMemoria('Configs.Endereco_WS', v_Endereco_WS, v_tstrCipherOpened);
      End;

    if (trim(v_Endereco_Servidor)='') then
        v_Endereco_Servidor := Trim(GetValorChaveRegIni('Configs','EnderecoServidor',g_oCacic.getCacicPath + 'cacic2.ini'));

    strEndereco := 'http://' + v_Endereco_Servidor + v_Endereco_WS + URL;

    if (trim(MsgAcao)='') then
        MsgAcao := '>> Enviando informa��es iniciais ao Gerente WEB.';

    if (trim(MsgAcao)<>'.') then
        log_diario(MsgAcao);

    Response_CS := TStringStream.Create('');

    log_DEBUG('Iniciando comunica��o com http://' + v_Endereco_Servidor + v_Endereco_WS + URL);

    Try
       idHTTP1 := TIdHTTP.Create(nil);
       idHTTP1.AllowCookies                     := true;
       idHTTP1.ASCIIFilter                      := false; // ATEN��O: Esta propriedade deixa de existir na pr�xima vers�o do Indy (10.x)
       idHTTP1.AuthRetries                      := 1;     // ATEN��O: Esta propriedade deixa de existir na pr�xima vers�o do Indy (10.x)
       idHTTP1.BoundPort                        := 0;
       idHTTP1.HandleRedirects                  := false;
       idHTTP1.ProxyParams.BasicAuthentication  := false;
       idHTTP1.ProxyParams.ProxyPort            := 0;
       idHTTP1.ReadTimeout                      := 0;
       idHTTP1.RedirectMaximum                  := 15;
       idHTTP1.Request.UserAgent                := StringReplace(g_oCacic.enCrypt('AGENTE_CACIC'),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Username                 := StringReplace(g_oCacic.enCrypt('USER_CACIC'),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Password                 := StringReplace(g_oCacic.enCrypt('PW_CACIC'),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Accept                   := 'text/html, */*';
       idHTTP1.Request.BasicAuthentication      := true;
       idHTTP1.Request.ContentLength            := -1;
       idHTTP1.Request.ContentRangeStart        := 0;
       idHTTP1.Request.ContentRangeEnd          := 0;
       idHTTP1.Request.ContentType              := 'text/html';
       idHTTP1.RecvBufferSize                   := 32768; // ATEN��O: Esta propriedade deixa de existir na pr�xima vers�o do Indy (10.x)
       idHTTP1.SendBufferSize                   := 32768; // ATEN��O: Esta propriedade deixa de existir na pr�xima vers�o do Indy (10.x)
       idHTTP1.Tag                              := 0;

       // ATEN��O: Substituo os sinais de "+" acima por <MAIS> devido a problemas encontrados no envio POST

       if v_Debugs then
          Begin
            Log_Debug('te_so => '+g_oCacic.getWindowsStrId);
            Log_Debug('Valores de REQUEST para envio ao Gerente WEB:');
            for intAux := 0 to v_AuxRequest.count -1 do
                Log_Debug('#'+inttostr(intAux)+': '+v_AuxRequest[intAux]);
          End;

       IdHTTP1.Post(strEndereco, v_AuxRequest, Response_CS);
       idHTTP1.Disconnect;
       idHTTP1.Free;

       log_DEBUG('Retorno: "'+Response_CS.DataString+'"');
    Except
       log_diario('ERRO! Comunica��o imposs�vel com o endere�o ' + strEndereco + Response_CS.DataString);
       result := '0';
       Exit;
    end;

    Try
      if (UpperCase(XML_RetornaValor('Status', Response_CS.DataString)) <> 'OK') Then
        Begin
           log_diario('PROBLEMAS DURANTE A COMUNICA��O:');
           log_diario('Endere�o: ' + strEndereco);
           log_diario('Mensagem: ' + Response_CS.DataString);
           result := '0';
           setValorDatMemoria('Configs.ConexaoOK','N',v_tstrCipherOpened);
        end
      Else
        Begin
           setValorDatMemoria('Configs.ConexaoOK','S',v_tstrCipherOpened);
           result := Response_CS.DataString;
        end;
      Response_CS.Free;
    Except
      Begin
        log_diario('PROBLEMAS DURANTE A COMUNICA��O:');
        log_diario('Endere�o: ' + strEndereco);
        log_diario('Mensagem: ' + Response_CS.DataString);
        result := '0';
      End;
    End;
end;

procedure GetInfoPatrimonio;
var strDt_ultima_renovacao_patrim,
    strUltimaRedeObtida,
    strRetorno,
    strIntervaloRenovacaoPatrimonio   : string;
    intHoje                           : Integer;
    Request_Ger_Cols                  : TStringList;
Begin
    // Solicita ao servidor as configura��es para a Coleta de Informa��es de Patrim�nio
    Request_Ger_Cols:=TStringList.Create;

    strRetorno := ComunicaServidor('get_patrimonio.php', Request_Ger_Cols, '.');
    SetValorDatMemoria('Patrimonio.Configs', strRetorno, v_tstrCipherOpened);
    SetValorDatMemoria('Patrimonio.cs_abre_janela_patr', g_oCacic.deCrypt(XML_RetornaValor('cs_abre_janela_patr', strRetorno)), v_tstrCipherOpened);

    Request_Ger_Cols.Free;

    strUltimaRedeObtida := GetValorDatMemoria('Patrimonio.ultima_rede_obtida', v_tstrCipherOpened);
    strDt_ultima_renovacao_patrim := GetValorDatMemoria('Patrimonio.dt_ultima_renovacao_patrim', v_tstrCipherOpened);

    // Inicializa como "N' os valores de Remanejamento e Renova��o que ser�o lidos pelo m�dulo de Coleta de Informa��es Patrimoniais.
    SetValorDatMemoria('Patrimonio.in_alteracao_fisica', 'N', v_tstrCipherOpened);
    SetValorDatMemoria('Patrimonio.in_renovacao_informacoes', 'N', v_tstrCipherOpened);

    if (strUltimaRedeObtida <> '') and
       (GetValorDatMemoria('TcpIp.ID_IP_REDE', v_tstrCipherOpened) <> strUltimaRedeObtida) and
       (GetValorDatMemoria('Patrimonio.cs_abre_janela_patr', v_tstrCipherOpened)='S') then
      Begin
        // Neste caso seto como "S" o valor de Remanejamento para ser lido pelo m�dulo de Coleta de Informa��es Patrimoniais.
        SetValorDatMemoria('Patrimonio.in_alteracao_fisica', 'S', v_tstrCipherOpened);
      end
    Else
      Begin
        intHoje := StrToInt(FormatDateTime('yyyymmdd', Date));
        strIntervaloRenovacaoPatrimonio := GetValorDatMemoria('Configs.NU_INTERVALO_RENOVACAO_PATRIMONIO', v_tstrCipherOpened);
        if ((strUltimaRedeObtida <> '') and (strIntervaloRenovacaoPatrimonio <> '') and ((intHoje - StrToInt64(strDt_ultima_renovacao_patrim)) >= strtoint(strIntervaloRenovacaoPatrimonio))) or
           (GetValorDatMemoria('Configs.IN_COLETA_FORCADA_PATR', v_tstrCipherOpened) = 'S') Then
          Begin
            // E neste caso seto como "S" o valor de Renova��o de Informa��es para ser lido pelo m�dulo de Coleta de Informa��es Patrimoniais.
            SetValorDatMemoria('Patrimonio.in_renovacao_informacoes', 'S', v_tstrCipherOpened);
          end;
      end;
end;

// Baixada de http://www.geocities.com/SiliconValley/Bay/1058/fdelphi.html
Function Rat(OQue: String; Onde: String) : Integer;
//  Procura uma string dentro de outra, da direita para esquerda
//  Retorna a posi��o onde foi encontrada ou 0 caso n�o seja encontrada
var
Pos   : Integer;
Tam1  : Integer;
Tam2  : Integer;
Achou : Boolean;
begin
Tam1   := Length(OQue);
Tam2   := Length(Onde);
Pos    := Tam2-Tam1+1;
Achou  := False;
while (Pos >= 1) and not Achou do
      begin
      if Copy(Onde, Pos, Tam1) = OQue then
         begin
         Achou := True
         end
      else
         begin
         Pos := Pos - 1;
         end;
      end;
Result := Pos;
end;

Function PegaDadosIPConfig(p_array_campos: TStringList; p_array_valores: TStringList; p_tripa:String; p_excecao:String): String;
var tstrOR, tstrAND, tstrEXCECOES : TStrings;
var intAux1, intAux2, intAux3, intAux4, v_conta, v_conta_EXCECOES : integer;

Begin
   Result   := '';
   tstrOR   := g_oCacic.explode(p_tripa,';'); // OR

    for intAux1 := 0 to tstrOR.Count-1 Do
      Begin
        tstrAND  := g_oCacic.explode(tstrOR[intAux1],','); // AND
        for intAux2 := 0 to p_array_campos.Count-1 Do
          Begin
            v_conta := 0;
            for intAux3 := 0 to tstrAND.Count-1 Do
              Begin
                if (LastPos(tstrAND[intAux3],StrLower(PChar(p_array_campos[intAux2]))) > 0) then
                  Begin
                    v_conta := v_conta + 1;
                  End;
              End;
            if (v_conta = tstrAND.Count) then
              Begin
                v_conta_EXCECOES := 0;
                if (p_excecao <> '') then
                  Begin
                    tstrEXCECOES  := g_oCacic.explode(p_excecao,','); // Excecoes a serem tratadas
                    for intAux4 := 0 to tstrEXCECOES.Count-1 Do
                      Begin
                        if (rat(tstrEXCECOES[intAux4],p_array_valores[intAux2]) > 0) then
                          Begin
                            v_conta_EXCECOES := 1;
                            break;
                          End;
                      End;
                  End;
              if (v_conta_EXCECOES = 0) then
                Begin
                  Result := p_array_valores[intAux2];
                  break;
                End;
              End;
          End;
        if (v_conta = tstrAND.Count) then
          Begin
            break;
          End
        else
          Begin
            Result := '';
          End;
      End;
End;

Function FTP_Get(strHost, strUser, strPass, strArq, strDirOrigem, strDirDestino, strTipo : String; intPort : integer) : Boolean;
var IdFTP1 : TIdFTP;
begin
    log_DEBUG('Instanciando FTP...');
    IdFTP1                := TIdFTP.Create(IdFTP1);
    log_DEBUG('FTP Instanciado!');
    IdFTP1.Host           := strHost;
    IdFTP1.Username       := strUser;
    IdFTP1.Password       := strPass;
    IdFTP1.Port           := intPort;
    IdFTP1.Passive        := true;
    if (strTipo = 'ASC') then
      IdFTP1.TransferType := ftASCII
    else
      IdFTP1.TransferType := ftBinary;

    log_DEBUG('Iniciando FTP de '+strArq +' para '+StringReplace(strDirDestino + '\' + strArq,'\\','\',[rfReplaceAll]));
    log_DEBUG('Host........ ='+IdFTP1.Host);
    log_DEBUG('UserName.... ='+IdFTP1.Username);
    log_DEBUG('Port........ ='+inttostr(IdFTP1.Port));
    log_DEBUG('Pasta Origem ='+strDirOrigem);

    Try
      if IdFTP1.Connected = true then
        begin
          IdFTP1.Disconnect;
        end;
      //IdFTP1.Connect(True);
      IdFTP1.Connect;
      IdFTP1.ChangeDir(strDirOrigem);
      Try
        // Substituo \\ por \ devido a algumas vezes em que o DirDestino assume o valor de DirTemp...
        log_DEBUG('FTP - Size de "'+strArq+'" Antes => '+IntToSTR(IdFTP1.Size(strArq)));
        IdFTP1.Get(strArq, StringReplace(strDirDestino + '\' + strArq,'\\','\',[rfReplaceAll]), True);
        log_DEBUG('FTP - Size de "'+strDirDestino + '\' + strArq +'" Ap�s => '+Get_File_Size(strDirDestino + '\' + strArq,true));
      Finally
        result := true;
        log_DEBUG('FTP - Size de "'+strDirDestino + '\' + strArq +'" Ap�s em Finally => '+Get_File_Size(strDirDestino + '\' + strArq,true));
        idFTP1.Disconnect;
        IdFTP1.Free;
      End;
    Except
        log_DEBUG('FTP - Erro - Size de "'+strDirDestino + '\' + strArq +'" Ap�s em Except => '+Get_File_Size(strDirDestino + '\' + strArq,true));
        result := false;
    end;
end;

procedure CriaTXT(p_Dir, p_File : string);
var v_TXT : TextFile;
begin
  AssignFile(v_TXT,p_Dir + '\' + p_File + '.txt'); {Associa o arquivo a uma vari�vel do tipo TextFile}
  Rewrite (v_TXT);
  Closefile(v_TXT);
end;

function Ver_UPD(p_File, p_Nome_Modulo, p_Dir_Inst, p_Dir_Temp : string; p_Medir_FTP:boolean) : integer;
var Baixar      : boolean;
    strAux,
    strAux1,
    v_versao_disponivel,
    v_Dir_Temp,
    v_versao_atual,
    strHashLocal,
    strHashRemoto : String;
Begin
   log_DEBUG('Verificando necessidade de FTP para "'+p_Nome_Modulo +'" ('+p_File+')');
   Result := 0;
   Try

       if (trim(p_Dir_Temp)='') then
          Begin
            v_Dir_Temp := p_Dir_Inst;
          End
       else
          Begin
            v_Dir_Temp := g_oCacic.getCacicPath + p_Dir_Temp;
          End;

       v_versao_disponivel := '';
       v_versao_atual      := '';
       if not (p_Medir_FTP) then
          Begin
            v_versao_disponivel := StringReplace(GetValorDatMemoria('Configs.'+UpperCase('DT_VERSAO_'+ p_File + '_DISPONIVEL'), v_tstrCipherOpened),'.EXE','',[rfReplaceAll]);

            log_DEBUG('Vers�o Dispon�vel para "'+p_Nome_Modulo+'": '+v_versao_disponivel);
            if (trim(v_versao_disponivel)='') then v_versao_disponivel := '*';

            v_versao_atual := trim(StringReplace(GetVersionInfo(p_Dir_Inst + p_File + '.exe'),'.','',[rfReplaceAll]));

            if (v_versao_atual = '0.0.0.0') then
              Begin
                Matar(p_Dir_Inst,p_File + '.exe');
                v_versao_atual := '';
              End;

            // Aten��o: Foi acrescentada a string "0103", s�mbolo do dia/m�s de primeira release, para simular vers�o maior no GER_COLS at� 02/2005.
            // Solu��o provis�ria at� total converg�ncia das vers�es para 2.0.1.x
            if (v_versao_atual <> '') then v_versao_atual := v_versao_atual + '0103';
          End;

       v_Tamanho_Arquivo := Get_File_Size(p_Dir_Inst + p_File + '.exe',true);
       Baixar := false;

       if not (FileExists(p_Dir_Inst + p_File + '.exe')) then
          Begin
            if (p_Medir_FTP) then Result := 1
            else
              Begin
                log_diario(p_Nome_Modulo + ' inexistente');
                log_diario('<< Efetuando FTP do ' + p_Nome_Modulo);
                Baixar := true;
              End
          End
       else
          Begin
            strHashLocal  := g_oCacic.getFileHash(p_Dir_Inst + p_File + '.exe');
            strHashRemoto := GetValorDatMemoria('Configs.TE_HASH_'+UpperCase(p_File), v_tstrCipherOpened);
            // TESTE
            //if (UpperCase(p_File) = 'GER_COLS') or (UpperCase(p_File) = 'CACIC2') then
            //  strHashLocal := strHashRemoto;
            //
            log_DEBUG('Ver_UPD => '+p_File+'  [strHashLocal]: '+strHashLocal+' [strHashRemoto]: '+strHashRemoto);
           if ((strHashRemoto <> '') and (strHashLocal <> strHashRemoto)) or (v_Tamanho_Arquivo = '0') or (v_Tamanho_Arquivo = '-1') or (trim(GetVersionInfo(p_Dir_Inst + p_File + '.exe'))='0.0.0.0') then
              Begin
                if (p_Medir_FTP) then
                  Result := 1
                else
                  Begin
                    log_diario(p_Nome_Modulo + ' corrompido');
                    log_diario('<< Efetuando FTP do ' + p_Nome_Modulo);
                    Baixar := true;
                  End;
              End;
          End;

       if (Baixar) or ((v_versao_atual <> v_versao_disponivel) and (v_versao_disponivel <> '*')) Then
        Begin
           if (v_versao_atual <> v_versao_disponivel) and not Baixar then
                log_diario('<< Recebendo m�dulo ' + p_Nome_Modulo);

           Try
             log_DEBUG('Baixando: '+ p_File + '.exe para '+v_Dir_Temp);
             if (FTP_Get(GetValorDatMemoria('Configs.TE_SERV_UPDATES', v_tstrCipherOpened),
                         GetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES', v_tstrCipherOpened),
                         GetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES', v_tstrCipherOpened),
                         p_File + '.exe',
                         GetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES', v_tstrCipherOpened),
                         v_Dir_Temp,
                         'BIN',
                         strtoint(GetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES', v_tstrCipherOpened))) = False) Then
               Begin
                log_diario('ERRO!');
                strAux  := 'N�o foi poss�vel baixar o m�dulo "'+ p_Nome_Modulo + '".';
                strAux1 := 'Verifique se foi disponibilizado no Servidor de Updates pelo administrador do Gerente WEB.';
                log_diario(strAux);
                log_diario(strAux1);
                if (GetValorDatMemoria('Configs.IN_EXIBE_ERROS_CRITICOS', v_tstrCipherOpened) = 'S') Then
                  Begin
                    SetValorDatMemoria('Mensagens.cs_tipo', 'mtError', v_tstrCipherOpened);
                    SetValorDatMemoria('Mensagens.te_mensagem', strAux + '. ' + strAux1, v_tstrCipherOpened);
                  End;
               end
             else log_diario('Vers�o Atual-> '+v_versao_atual+' / Vers�o Recebida-> '+v_versao_disponivel);
           Except
              log_diario('N�o foi poss�vel baixar o m�dulo '+ p_Nome_Modulo + '.');
           End;
        end;
   Except
        Begin
          CriaTXT(g_oCacic.getCacicPath,'ger_erro');
          SetValorDatMemoria('Erro_Fatal','PROBLEMAS COM ROTINA DE EXECU��O DE UPDATES DE VERS�ES. N�o foi poss�vel baixar o m�dulo '+ p_Nome_Modulo + '.', v_tstrCipherOpened);
          log_diario('PROBLEMAS COM ROTINA DE EXECU��O DE UPDATES DE VERS�ES.');
        End;
   End;
End;

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

// Dica baixada de http://www.swissdelphicenter.ch/torry/showcode.php?id=1142
function GetDomainName: AnsiString;
type
 WKSTA_INFO_100 = record
   wki100_platform_id: Integer;
   wki100_computername: PWideChar;
   wki100_langroup: PWideChar;
   wki100_ver_major: Integer;
   wki100_ver_minor: Integer;
 end;

 WKSTA_USER_INFO_1 = record
   wkui1_username: PChar;
   wkui1_logon_domain: PChar;
   wkui1_logon_server: PChar;
   wkui1_oth_domains: PChar;
 end;
type
 //Win9X ANSI prototypes from RADMIN32.DLL and RLOCAL32.DLL

 TWin95_NetUserGetInfo = function(ServerName, UserName: PChar; Level: DWORD; var
   BfrPtr: Pointer): Integer;
 stdcall;
 TWin95_NetApiBufferFree = function(BufPtr: Pointer): Integer;
 stdcall;
 TWin95_NetWkstaUserGetInfo = function(Reserved: PChar; Level: Integer; var
   BufPtr: Pointer): Integer;
 stdcall;

 //WinNT UNICODE equivalents from NETAPI32.DLL

 TWinNT_NetWkstaGetInfo = function(ServerName: PWideChar; level: Integer; var
   BufPtr: Pointer): Integer;
 stdcall;
 TWinNT_NetApiBufferFree = function(BufPtr: Pointer): Integer;
 stdcall;

 function IsWinNT: Boolean;
 var
   VersionInfo: TOSVersionInfo;
 begin
   VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
   Result := GetVersionEx(VersionInfo);
   if Result then
     Result := VersionInfo.dwPlatformID = VER_PLATFORM_WIN32_NT;
 end;
var

 Win95_NetUserGetInfo: TWin95_NetUserGetInfo;
 Win95_NetWkstaUserGetInfo: TWin95_NetWkstaUserGetInfo;
 Win95_NetApiBufferFree: TWin95_NetApiBufferFree;

 WinNT_NetWkstaGetInfo: TWinNT_NetWkstaGetInfo;
 WinNT_NetApiBufferFree: TWinNT_NetApiBufferFree;

 WSNT: ^WKSTA_INFO_100;
 WS95: ^WKSTA_USER_INFO_1;

 EC: DWORD;
 hNETAPI: THandle;
begin
 try

   Result := '';

   if IsWinNT then
   begin
     hNETAPI := LoadLibrary('NETAPI32.DLL');
     if hNETAPI <> 0 then
     begin @WinNT_NetWkstaGetInfo := GetProcAddress(hNETAPI, 'NetWkstaGetInfo');
         @WinNT_NetApiBufferFree  := GetProcAddress(hNETAPI, 'NetApiBufferFree');

       EC := WinNT_NetWkstaGetInfo(nil, 100, Pointer(WSNT));
       if EC = 0 then
       begin
         Result := WideCharToString(WSNT^.wki100_langroup);
         WinNT_NetApiBufferFree(Pointer(WSNT));
       end;
     end;
   end
   else
   begin
     hNETAPI := LoadLibrary('RADMIN32.DLL');
     if hNETAPI <> 0 then
     begin @Win95_NetApiBufferFree := GetProcAddress(hNETAPI, 'NetApiBufferFree');
         @Win95_NetUserGetInfo := GetProcAddress(hNETAPI, 'NetUserGetInfoA');

       EC := Win95_NetWkstaUserGetInfo(nil, 1, Pointer(WS95));
       if EC = 0 then
       begin
         Result := WS95^.wkui1_logon_domain;
         Win95_NetApiBufferFree(Pointer(WS95));
       end;
     end;
   end;

 finally
   if hNETAPI <> 0 then
     FreeLibrary(hNETAPI);
 end;
end;

function ChecaAgente(agentFolder, agentName : String) : boolean;
var strFraseVersao : String;
Begin
  Result := true;

  log_DEBUG('Verificando exist�ncia e tamanho de "'+agentFolder+'\'+agentName+'"');
  v_Tamanho_Arquivo := Get_File_Size(agentFolder+'\'+agentName,true);

  log_DEBUG('Resultado: #'+v_Tamanho_Arquivo);

  if (v_Tamanho_Arquivo = '0') or (v_Tamanho_Arquivo = '-1') then
    Begin
      Result := false;

      Matar(agentFolder+'\',agentName);

      Ver_UPD(StringReplace(LowerCase(agentName),'.exe','',[rfReplaceAll]),agentName,agentFolder+'\','Temp',false);

      sleep(15000); // 15 segundos de espera para download do agente
      v_Tamanho_Arquivo := Get_File_Size(agentFolder+'\'+agentName,true);
      if not(v_Tamanho_Arquivo = '0') and not(v_Tamanho_Arquivo = '-1') then
        Begin
          log_diario('Agente "'+agentFolder+'\'+agentName+'" RECUPERADO COM SUCESSO!');
          Result := True;
        End
      else
          log_diario('Agente "'+agentFolder+'\'+agentName+'" N�O RECUPERADO!');
    End;
End;

procedure Patrimnio1Click(Sender: TObject);
begin
  SetValorDatMemoria('Patrimonio.dt_ultima_renovacao_patrim','', v_tstrCipherOpened);
  if ChecaAgente(g_oCacic.getCacicPath + 'modulos', 'ini_cols.exe') then
    g_oCacic.createSampleProcess( g_oCacic.getCacicPath + 'modulos\ini_cols.exe /p_ModulosOpcoes=col_patr,wait,user#', CACIC_PROCESS_WAIT );

  if (FileExists(g_oCacic.getCacicPath + 'Temp\col_patr.dat')) then
	  Begin
		log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_patr.dat encontrado.');
		v_acao_gercols := '* Preparando envio de informa��es de Patrim�nio.';
		v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_patr.dat');

		// Armazeno dados para informa��es de coletas na data, via menu popup do Systray
		SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es Patrimoniais', v_tstrCipherOpened);

		// Armazeno as horas de in�cio e fim das coletas
		SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Patr.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
		SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Patr.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

		if (GetValorDatMemoria('Col_Patr.nada',v_tstrCipherOpened1)='') then
		  Begin
			// Prepara��o para envio...
			Request_Ger_Cols.Values['id_unid_organizacional_nivel1']  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1'  ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['id_unid_organizacional_nivel1a'] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1a' ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['id_unid_organizacional_nivel2']  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel2'  ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['te_localizacao_complementar'  ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_localizacao_complementar'    ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['te_info_patrimonio1'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio1'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['te_info_patrimonio2'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio2'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['te_info_patrimonio3'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio3'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['te_info_patrimonio4'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio4'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['te_info_patrimonio5'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio5'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
			Request_Ger_Cols.Values['te_info_patrimonio6'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio6'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);

			if v_Debugs then
				For intLoop := 0 to Request_Ger_Cols.Count-1 do
					log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Patr: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

			if (ComunicaServidor('set_patrimonio.php', Request_Ger_Cols, '>> Enviando informa��es de Patrim�nio para o Gerente WEB.') <> '0') Then
				Begin
				  // Armazeno o Status Positivo de Envio
				  SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

				  // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
				  //Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
				  SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1' , GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1',v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1a', GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1a',v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2' , GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel2',v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.te_localizacao_complementar'   , GetValorDatMemoria('Col_Patr.te_localizacao_complementar'  ,v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.te_info_patrimonio1'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio1'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.te_info_patrimonio2'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio2'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.te_info_patrimonio3'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio3'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.te_info_patrimonio4'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio4'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.te_info_patrimonio5'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio5'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.te_info_patrimonio6'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio6'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
				  SetValorDatMemoria('Patrimonio.ultima_rede_obtida'            , GetValorDatMemoria('TcpIp.ID_IP_REDE'                      ,v_tstrCipherOpened) , v_tstrCipherOpened);
				  intAux := 1;
				End
			else
			  // Armazeno o Status Negativo de Envio
			  SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
		  End
		else
		  // Armazeno o Status Nulo de Envio
		  SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

		Request_Ger_Cols.Clear;
		Matar(g_oCacic.getCacicPath+'Temp\','col_patr.dat');
	  End;
end;

procedure ChecaCipher;
begin
    // Os valores poss�veis ser�o 0-DESLIGADO 1-LIGADO 2-ESPERA PARA LIGAR (Ser� transformado em "1") 3-Ainda se comunicar� com o Gerente WEB
    l_cs_cipher  := false;
    v_Aux := GetValorDatMemoria('Configs.CS_CIPHER', v_tstrCipherOpened);
    if (v_Aux='1') or (v_Aux='2') then
        Begin
          l_cs_cipher  := true;
          SetValorDatMemoria('Configs.CS_CIPHER','1', v_tstrCipherOpened);
        End
    else
        SetValorDatMemoria('Configs.CS_CIPHER','3', v_tstrCipherOpened);

end;

procedure ChecaCompress;
begin
    // Os valores poss�veis ser�o 0-DESLIGADO 1-LIGADO 2-ESPERA PARA LIGAR (Ser� transformado em "1") 3-Ainda se comunicar� com o Gerente WEB
    l_cs_compress  := false;
    v_Aux := GetValorDatMemoria('Configs.CS_COMPRESS', v_tstrCipherOpened);
    if (v_Aux='1') or (v_Aux='2') then
        Begin
          l_cs_compress  := true;
          SetValorDatMemoria('Configs.CS_COMPRESS','1', v_tstrCipherOpened);
        End
    else
        SetValorDatMemoria('Configs.CS_COMPRESS','3', v_tstrCipherOpened);
end;

procedure BuscaConfigs(p_mensagem_log : boolean);
var Request_SVG, v_array_campos, v_array_valores, v_Report : TStringList;
    intAux1, intAux2, intAux3, intAux4, v_conta_EXCECOES, v_index_ethernet : integer;
    strRetorno, strTripa, strAux3, ValorChaveRegistro, ValorRetornado, v_mensagem_log,
    v_mascara,te_ip,te_mascara, te_gateway, te_serv_dhcp, te_dns_primario, te_dns_secundario, te_wins_primario, te_wins_secundario, te_nome_host, te_dominio_dns, te_dominio_windows,
    v_mac_address,v_metodo_obtencao,v_nome_arquivo,IpConfigLINHA, v_enderecos_mac_invalidos, v_win_dir, v_dir_command, v_dir_ipcfg, v_win_dir_command, v_win_dir_ipcfg, v_te_serv_cacic : string;
    tstrTripa1, tstrTripa2, tstrTripa3, tstrTripa4, tstrTripa5, tstrEXCECOES : TStrings;
    IpConfigTXT, chksis_ini : textfile;

    v_oMachine : TMiTec_Machine;
    v_TCPIP     : TMiTeC_TCPIP;
    v_NETWORK : TMiTeC_Network;
Begin
  Try
    ChecaCipher;
    ChecaCompress;

    v_acao_gercols := 'Instanciando TMiTeC_Machine...';
    v_oMachine := TMiTec_Machine.Create(nil);
    v_oMachine.RefreshData();

    v_acao_gercols := 'Instanciando TMiTeC_TcpIp...';
    v_TCPIP := TMiTeC_tcpip.Create(nil);
    v_tcpip.RefreshData;

    // Caso exista a pasta ..temp/debugs, ser� criado o arquivo di�rio debug_<coletor>.txt
    // Usar esse recurso apenas para debug de coletas mal-sucedidas atrav�s do componente MSI MiTeC.
    if (v_Debugs) then
      Begin
        log_DEBUG('Montando ambiente para busca de configura��es...');
        v_Report := TStringList.Create;
        MSI_XML_Reports.TCPIP_XML_Report(v_TCPIP,true,v_Report);
        for intAux1:=0 to v_Report.count-1 do
            Grava_Debugs(v_report[intAux1]);

        v_Report.Free;
      End;
    v_tcpip.RefreshData;

    v_index_ethernet := -1;

    for intAux1:=0 to v_tcpip.AdapterCount -1 do
        if (v_index_ethernet=-1) and (v_tcpip.Adapter[intAux1].Typ=atEthernet) and (v_tcpip.Adapter[intAux1].IPAddress[0]<>'0.0.0.0') then v_index_ethernet := intAux1;

    if (v_index_ethernet=-1) then
        v_index_ethernet := 0;

    Try v_mac_address      := v_tcpip.Adapter[v_index_ethernet].Address                    except v_mac_address       := ''; end;
    Try te_mascara         := v_tcpip.Adapter[v_index_ethernet].IPAddressMask[0]           except te_mascara          := ''; end;
    Try te_ip              := v_tcpip.Adapter[v_index_ethernet].IPAddress[0]               except te_ip               := ''; end;
    Try te_nome_host       := v_oMachine.MachineName                                       except te_nome_host        := ''; end;

    if (v_mac_address='') or (te_ip='') then
      Begin
        v_acao_gercols := 'Instanciando TMiTeC_Network...';
        v_NETWORK := TMiTeC_Network.Create(nil);
        v_NETWORK.RefreshData;

        // Caso exista a pasta ..temp/debugs, ser� criado o arquivo di�rio debug_<coletor>.txt
        // Usar esse recurso apenas para debug de coletas mal-sucedidas atrav�s do componente MSI MiTeC.
        v_acao_gercols := 'Instanciando Report para TMiTeC_Network...';
        v_Report := TStringList.Create;
        if (v_Debugs) then
          Begin
            v_acao_gercols := 'Gerando Report para TMiTeC_Network...';
            MSI_XML_Reports.Network_XML_Report(v_NETWORK,true,v_Report);

            for intAux1:=0 to v_Report.count-1 do
              Begin
                v_acao_gercols := 'Gravando Report para TMiTeC_Network...';
                Grava_Debugs(v_report[intAux1]);
              End;
          End;
        v_NETWORK.RefreshData;

        v_mac_address  := parse('TNetwork','MACAdresses','MACAddress[0]',v_Report);
        te_ip          := parse('TNetwork','IPAddresses','IPAddress[0]',v_Report);

        v_Report.Free;
      End;

    // Verifico comunica��o com o M�dulo Gerente WEB.
    Request_SVG := TStringList.Create;
    Request_SVG.Values['in_teste']          := StringReplace(g_oCacic.enCrypt('OK'),'+','<MAIS>',[rfReplaceAll]);

    v_acao_gercols := 'Preparando teste de comunica��o com M�dulo Gerente WEB.';

    log_DEBUG('Teste de Comunica��o.');

    Try
      v_te_serv_cacic := GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened);

      intAux2 := (v_tcpip.Adapter[v_index_ethernet].IPAddress.Count)-1;
      if intAux2 < 0 then intAux2 := 0;

      // Testando a comunica��o com o M�dulo Gerente WEB.
      for intAux1 := 0 to intAux2 do
        Begin
          v_acao_gercols := 'Setando Request.te_ip com ' + v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1];
          SetValorDatMemoria('TcpIp.TE_IP',v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1], v_tstrCipherOpened);
          Try
            strRetorno := ComunicaServidor('get_config.php', Request_SVG, 'Testando comunica��o com o M�dulo Gerente WEB.');
            Seta_l_cs_cipher(strRetorno);
            Seta_l_cs_compress(strRetorno);

            v_Aux := g_oCacic.deCrypt(XML_RetornaValor('te_serv_cacic', strRetorno));
            if (v_te_serv_cacic <> v_Aux) and (v_Aux <> '') then
               SetValorDatMemoria('Configs.EnderecoServidor',v_Aux, v_tstrCipherOpened);

            if (strRetorno <> '0') and (g_oCacic.deCrypt(XML_RetornaValor('te_rede_ok', strRetorno))<>'N') Then
              Begin
                v_acao_gercols := 'IP/M�scara usados: ' + v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1]+'/'+v_tcpip.Adapter[v_index_ethernet].IPAddressMask[intAux1]+' validados pelo M�dulo Gerente WEB.';
                te_ip      := v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1];
                te_mascara := v_tcpip.Adapter[v_index_ethernet].IPAddressMask[intAux1];
                log_diario(v_acao_gercols);
                break;
              End;
          except log_diario('Insucesso na comunica��o com o M�dulo Gerente WEB.');
          end
        End;
    Except
      Begin
        v_acao_gercols := 'Teste de comunica��o com o M�dulo Gerente WEB.';

        // Nova tentativa, preciso reinicializar o objeto devido aos restos da opera��o anterior... (Eu acho!)  :)
        Request_SVG.Free;
        Request_SVG := TStringList.Create;
        Request_SVG.Values['in_teste']          := StringReplace(g_oCacic.enCrypt('OK'),'+','<MAIS>',[rfReplaceAll]);
        Try
          strRetorno := ComunicaServidor('get_config.php', Request_SVG, 'Teste de comunica��o com o M�dulo Gerente WEB.');
          Seta_l_cs_cipher(strRetorno);
          Seta_l_cs_compress(strRetorno);

          v_Aux := g_oCacic.deCrypt(XML_RetornaValor('te_serv_cacic', strRetorno));
          if (v_te_serv_cacic <> v_Aux) and (v_Aux <> '') then
             SetValorDatMemoria('Configs.EnderecoServidor',v_Aux, v_tstrCipherOpened);

          if (strRetorno <> '0') and (g_oCacic.deCrypt(XML_RetornaValor('te_rede_ok', strRetorno))<>'N') Then
            Begin
              v_acao_gercols := 'IP validado pelo M�dulo Gerente WEB.';
              log_diario(v_acao_gercols);
            End
          else log_diario('Insucesso na comunica��o com o M�dulo Gerente WEB.');
        except
          log_diario('Problemas no teste de comunica��o com o M�dulo Gerente WEB.');
        end;
      End;
    End;
    Request_SVG.Free;

    Try te_gateway         := v_tcpip.Adapter[v_index_ethernet].Gateway_IPAddress[0]       except te_gateway          := ''; end;
    Try te_serv_dhcp       := v_tcpip.Adapter[v_index_ethernet].DHCP_IPAddress[0]          except te_serv_dhcp        := ''; end;
    Try te_dns_primario    := v_tcpip.DNSServers[0]                                        except te_dns_primario     := ''; end;
    Try te_dns_secundario  := v_tcpip.DNSServers[1]                                        except te_dns_secundario   := ''; end;
    Try te_wins_primario   := v_tcpip.Adapter[v_index_ethernet].PrimaryWINS_IPAddress[0]   except te_wins_primario    := ''; end;
    Try te_wins_secundario := v_tcpip.Adapter[v_index_ethernet].SecondaryWINS_IPAddress[0] except te_wins_secundario  := ''; end;
    Try te_dominio_dns     := v_tcpip.DomainName                                           except te_dominio_dns      := ''; end;

    v_acao_gercols := 'Setando endere�o WS para /cacic2/ws/';
    // Setando /cacic2/ws/ como caminho de pseudo-WebServices
    SetValorDatMemoria('Configs.Endereco_WS','/cacic2/ws/', v_tstrCipherOpened);

    v_acao_gercols := 'Setando TE_FILA_FTP=0';
    // Setando controle de FTP para 0 (0=tempo de espera para FTP   de algum componente do sistema)
    SetValorDatMemoria('Configs.TE_FILA_FTP','0', v_tstrCipherOpened);
    CountUPD := 0;

    // Verifico e contabilizo as necessidades de FTP dos agentes (instala��o ou atualiza��o)
    // Para poss�vel requisi��o de acesso ao grupo FTP... (Essa medida visa balancear o acesso aos servidores de atualiza��o de vers�es, principalmente quando � um �nico S.A.V.)
    v_acao_gercols := 'Contabilizando necessidade de Updates...';

    // O valor "true" para o 5� par�metro da fun��o Ver_UPD informa para apenas verificar a necessidade de FTP do referido objeto.
    CountUPD := CountUPD + Ver_UPD('ini_cols'                                         ,'Inicializador de Coletas'                         ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD(StringReplace(v_scripter,'.exe','',[rfReplaceAll]) ,'Interpretador VBS'                                ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('chksis'                                           ,'Verificador de Integridade do Sistema'            ,g_oCacic.getWinDir                ,'',true);
    CountUPD := CountUPD + Ver_UPD('cacic2'                                           ,'Agente Principal'                                 ,g_oCacic.getCacicPath             ,'Temp',true);
    CountUPD := CountUPD + Ver_UPD('srcacicsrv'                                       ,'Suporte Remoto Seguro'                            ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('ger_cols'                                         ,'Gerente de Coletas'                               ,g_oCacic.getCacicPath + 'modulos\','Temp',true);
    CountUPD := CountUPD + Ver_UPD('col_anvi'                                         ,'Coletor de Informa��es de Anti-V�rus OfficeScan'  ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_comp'                                         ,'Coletor de Informa��es de Compartilhamentos'      ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_hard'                                         ,'Coletor de Informa��es de Hardware'               ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_patr'                                         ,'Coletor de Informa��es de Patrim�nio/Loc.F�s.'    ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_moni'                                         ,'Coletor de Informa��es de Sistemas Monitorados'   ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_soft'                                         ,'Coletor de Informa��es de Softwares B�sicos'      ,g_oCacic.getCacicPath + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_undi'                                         ,'Coletor de Informa��es de Unidades de Disco'      ,g_oCacic.getCacicPath + 'modulos\','',true);



    // Verifica exist�ncia dos dados de configura��es principais e estado de CountUPD. Caso verdadeiro, simula uma instala��o pelo chkCACIC...
    if  ((GetValorDatMemoria('Configs.TE_SERV_UPDATES'              , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES', v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES'  , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES'         , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES'        , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS'     , v_tstrCipherOpened) = '') or
         (CountUPD > 0)) and
         (GetValorDatMemoria('Configs.ID_FTP', v_tstrCipherOpened) = '') then
        Begin
          log_DEBUG('Preparando contato com m�dulo Gerente WEB para Downloads.');
          v_acao_gercols := 'Contactando o m�dulo Gerente WEB: get_config.php...';
          Request_SVG := TStringList.Create;
          Request_SVG.Values['in_chkcacic']   := StringReplace(g_oCacic.enCrypt('chkcacic'),'+','<MAIS>',[rfReplaceAll]);
          Request_SVG.Values['te_fila_ftp']   := StringReplace(g_oCacic.enCrypt('1'),'+','<MAIS>',[rfReplaceAll]); // Indicar� que o agente quer entrar no grupo para FTP
          //Request_SVG.Values['id_ip_estacao'] := EnCrypt(GetIP,l_cs_compress); // Informar� o IP para registro na tabela redes_grupos_FTP

          log_DEBUG(v_acao_gercols + ' Par�metros: in_chkcacic="'+Request_SVG.Values['in_chkcacic']+'", te_fila_ftp="'+Request_SVG.Values['te_fila_ftp']+'" e id_ip_estacao="'+Request_SVG.Values['id_ip_estacao']+'"');
          strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);
          Seta_l_cs_cipher(strRetorno);
          Seta_l_cs_compress(strRetorno);



          Request_SVG.Free;
          if (strRetorno <> '0') Then
            Begin
              SetValorDatMemoria('Configs.TE_SERV_UPDATES'              ,g_oCacic.deCrypt(XML_RetornaValor('te_serv_updates'                   , strRetorno)), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES',g_oCacic.DeCrypt(XML_RetornaValor('nm_usuario_login_serv_updates'     , strRetorno)), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES'  ,g_oCacic.DeCrypt(XML_RetornaValor('te_senha_login_serv_updates'       , strRetorno)), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES'         ,g_oCacic.DeCrypt(XML_RetornaValor('te_path_serv_updates'              , strRetorno)), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES'        ,g_oCacic.DeCrypt(XML_RetornaValor('nu_porta_serv_updates'             , strRetorno)), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.TE_FILA_FTP'                  ,g_oCacic.DeCrypt(XML_RetornaValor('te_fila_ftp'                       , strRetorno)), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.ID_FTP'                       ,g_oCacic.DeCrypt(XML_RetornaValor('id_ftp'                            , strRetorno)), v_tstrCipherOpened);
              SetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS'     ,g_oCacic.DeCrypt(XML_RetornaValor('te_enderecos_mac_invalidos'        , strRetorno)), v_tstrCipherOpened);
            End;
        End;

    v_Aux := GetValorDatMemoria('Configs.TE_FILA_FTP', v_tstrCipherOpened);
    // Caso seja necess�rio fazer algum FTP e o M�dulo Gerente Web tenha devolvido um tempo para espera eu finalizo e espero o tempo para uma nova tentativa
    if (CountUPD > 0) and (v_Aux <> '') and (v_Aux <> '0') then
      Begin
        log_DEBUG('Finalizando para nova tentativa de FTP em '+v_Aux+' minuto(s)');
        Finalizar(true);
        Sair;
      End;

    v_acao_gercols := 'Verificando vers�es do scripter e chksis';
    log_DEBUG(''+v_acao_gercols);

    Ver_UPD(StringReplace(v_scripter,'.exe','',[rfReplaceAll]),'Interpretador VBS'                    ,g_oCacic.getCacicPath + 'modulos\','',false);
    Ver_UPD('chksis'                                          ,'Verificador de Integridade do Sistema',g_oCacic.getWinDir    +'\'        ,'',false);

    // O m�dulo de Suporte Remoto � opcional, atrav�s da op��o Administra��o / M�dulos
    {
    log_diario('Verificando nova vers�o para m�dulo Suporte Remoto Seguro.');
    // Caso encontre nova vers�o de srCACICsrv esta ser� gravada em modulos.
    Ver_UPD('srcacicsrv','Suporte Remoto Seguro',g_oCacic.getCacicPath + 'modulos\','',false);
    }

    // Verifico exist�ncia do chksis.ini
    if not (FileExists(g_oCacic.getWinDir + 'chksis.ini')) then
      Begin
         Try
           v_acao_gercols := 'chksis.ini inexistente, recriando...';
           tstrTripa1  := g_oCacic.explode(g_oCacic.getCacicPath,'\');
           AssignFile(chksis_ini,g_oCacic.getWinDir + 'chksis.ini'); {Associa o arquivo a uma vari�vel do tipo TextFile}
           Rewrite(chksis_ini); // Recria o arquivo...
           Append(chksis_ini);
           Writeln(chksis_ini,'[Cacic2]');
           Writeln(chksis_ini,'ip_serv_cacic='+GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened));
           Writeln(chksis_ini,'cacic_dir='+StringReplace(tstrTripa1[1],'\','',[rfReplaceAll]));
           Writeln(chksis_ini,'rem_cacic_v0x=S');
           CloseFile(chksis_ini); {Fecha o arquivo texto}
         Except
           log_diario('Erro na recupera��o de chksis.');
         End;
      End;

    v_mensagem_log  := '<< Obtendo configura��es a partir do Gerente WEB.';

    if (not p_mensagem_log) then v_mensagem_log := '';

  // Caso a obten��o dos dados de TCP via MSI_NETWORK/TCP tenha falhado...
  if (v_mac_address='') or (te_mascara='')    or (te_ip='')           or (te_gateway='') or
     (te_nome_host='')  or (te_serv_dhcp='' ) or (te_dns_primario='') or (te_wins_primario='') or
     (te_wins_secundario='') then
    Begin
      v_nome_arquivo    := g_oCacic.getCacicPath + 'Temp\ipconfig.txt';
      v_metodo_obtencao := 'WMI Object';
      v_acao_gercols    := 'Criando batch para obten��o de IPCONFIG via WMI...';
      Try
         Batchfile := TStringList.Create;
         Batchfile.Add('Dim FileSys,FileSysOk,IPConfigFile,IPConfigFileOK,strComputer,objWMIService,colItems,colUser,v_ok');
         Batchfile.Add('Set FileSys  = WScript.CreateObject("Scripting.FileSystemObject")');
         Batchfile.Add('Set IPConfigFile= FileSys.CreateTextFile("'+ v_nome_arquivo + '", True)');
         Batchfile.Add('On Error Resume Next');
         Batchfile.Add('strComputer = "."');
         Batchfile.Add('v_ok        = ""');
         Batchfile.Add('Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")');
         Batchfile.Add('Set colItems      = objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE")');
         Batchfile.Add('For Each objItem in colItems');
         Batchfile.Add('  ipconfigfile.WriteLine "Endere�o f�sico.........: " & objItem.MACAddress');
         Batchfile.Add('  ipconfigfile.WriteLine "Endere�o ip.............: " & objItem.IPAddress(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "M�scara de Sub-rede.....: " & objItem.IPSubnet(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Gateway padr�o..........: " & objItem.DefaultIPGateway(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Nome do host............: " & objItem.DNSHostName');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor DHCP...........: " & objItem.DHCPServer');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidores DNS..........: " & objItem.DNSDomain');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor WINS Primario..: " & objItem.WINSPrimaryServer');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor WINS Secundario: " & objItem.WINSSecondaryServer');
         Batchfile.Add('  v_ok = "OK"');
         Batchfile.Add('Next');
         Batchfile.Add('Set GetUser = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")');
         Batchfile.Add('Set colUser       = GetUser.ExecQuery("Select * from Win32_ComputerSystem")');
         Batchfile.Add('For Each objUser in colUser');
         Batchfile.Add('	ipconfigfile.WriteLine "Dom�nio/Usu�rio Logado..: " & objUser.UserName');
         Batchfile.Add('Next');
         Batchfile.Add('IPConfigFile.Close');
         Batchfile.Add('if v_ok = "OK" then');
         Batchfile.Add('  Set FileSysOK      = WScript.CreateObject("Scripting.FileSystemObject")');
         Batchfile.Add('  Set IPConfigFileOK = FileSysOK.CreateTextFile("'+g_oCacic.getCacicPath + 'Temp\ipconfi1.txt", True)');
         Batchfile.Add('  IPConfigFileOK.Close');
         Batchfile.Add('end if');
         Batchfile.Add('WScript.Quit');
         Batchfile.SaveToFile(g_oCacic.getCacicPath + 'Temp\ipconfig.vbs');
         BatchFile.Free;
         v_acao_gercols := 'Invocando execu��o de VBS para obten��o de IPCONFIG...';
         log_DEBUG('Executando "'+g_oCacic.getCacicPath + 'modulos\' + v_scripter + ' //b ' + g_oCacic.getCacicPath + 'temp\ipconfig.vbs"');

         if ChecaAgente(g_oCacic.getCacicPath + 'modulos', v_scripter) then
           WinExec(PChar(g_oCacic.getCacicPath + 'modulos\' + v_scripter + ' //b ' + g_oCacic.getCacicPath + 'temp\ipconfig.vbs'), SW_HIDE);
      Except
        Begin
          log_diario('Erro na gera��o do ipconfig.txt pelo ' + v_metodo_obtencao+'.');
        End;
      End;

      // Para aguardar o processamento acima, caso aconte�a
      sleep(5000);

      v_Tamanho_Arquivo := Get_File_Size(g_oCacic.getCacicPath + 'Temp\ipconfig.txt',true);
      if not (FileExists(g_oCacic.getCacicPath + 'Temp\ipconfi1.txt')) or (v_Tamanho_Arquivo='0')  then // O arquivo ipconfig.txt foi gerado vazio, tentarei IPConfig ou WinIPcfg!
        Begin
          Try
             v_win_dir          := g_oCacic.getWinDir;
             v_win_dir_command  := g_oCacic.getWinDir;
             v_win_dir_ipcfg    := g_oCacic.getWinDir;
             v_dir_command      := '';
             v_dir_ipcfg        := '';

             // Defini��o do comando para obten��o de informa��es de TCP (Ipconfig ou WinIpCFG)
             if (strtoint(GetValorDatMemoria('Configs.ID_SO', v_tstrCipherOpened)) > 5) then
                Begin
                  v_metodo_obtencao := 'Execu��o de IPConfig';
                  if      (fileexists(v_win_dir_command + '\system32\cmd.exe'))          then v_dir_command := '\system32'
                  else if (fileexists(v_win_dir_command + '\system32\dllcache\cmd.exe')) then v_dir_command := '\system32\dllcache'
                  else if (fileexists(v_win_dir_command + '\system\cmd.exe'))            then v_dir_command := '\system'
                  else if (fileexists(LeftStr(v_win_dir_command,2) + '\cmd.exe')) then
                    Begin
                      v_win_dir_command := LeftStr(v_win_dir_command,2);
                      v_dir_command     := '\';
                    End;

                  if      (fileexists(v_win_dir + '\system32\ipconfig.exe'))     then v_dir_ipcfg := '\system32'
                  else if (fileexists(v_win_dir + '\ipconfig.exe'))              then v_dir_ipcfg := '\'
                  else if (fileexists(v_win_dir + '\system\ipconfig.exe'))       then v_dir_ipcfg := '\system'
                  else if (fileexists(LeftStr(v_win_dir,2) + '\ipconfig.exe')) then
                    Begin
                      v_win_dir_ipcfg := LeftStr(v_win_dir_command,2);
                      v_dir_ipcfg     := '\';
                    End;

                  WinExec(PChar(v_win_dir + v_dir_command + '\cmd.exe /c ' + v_win_dir + v_dir_ipcfg + '\ipconfig.exe /all > ' + v_nome_arquivo), SW_MINIMIZE);
                End
             else
                Begin
                  v_metodo_obtencao := 'Execu��o de WinIPCfg';
                  if      (fileexists(v_win_dir_command + '\system32\command.com'))          then v_dir_command := '\system32'
                  else if (fileexists(v_win_dir_command + '\system32\dllcache\command.com')) then v_dir_command := '\system32\dllcache'
                  else if (fileexists(v_win_dir_command + '\system\command.com'))            then v_dir_command := '\system'
                  else if (fileexists(LeftStr(v_win_dir_command,2) + '\command.com')) then
                    Begin
                      v_win_dir_command := LeftStr(v_win_dir_command,2);
                      v_dir_command     := '\';
                    End;

                  if      (fileexists(v_win_dir + '\system32\winipcfg.exe'))     then v_dir_ipcfg := '\system32'
                  else if (fileexists(v_win_dir + '\winipcfg.exe'))              then v_dir_ipcfg := '\'
                  else if (fileexists(v_win_dir + '\system\winipcfg.exe'))       then v_dir_ipcfg := '\system'
                  else if (fileexists(LeftStr(v_win_dir,2) + '\winipcfg.exe')) then
                    Begin
                      v_win_dir_ipcfg := LeftStr(v_win_dir_command,2);
                      v_dir_ipcfg     := '\';
                    End;
                  WinExec(PChar(v_win_dir + v_dir_command + '\command.com /c ' + v_win_dir + v_dir_ipcfg + '\winipcfg.exe /all /batch ' + v_nome_arquivo), SW_MINIMIZE);
                End;
          Except log_diario('Erro na gera��o do ipconfig.txt pelo ' + v_metodo_obtencao+'.');
          End;
        End;

      sleep(3000); // 3 Segundos para finaliza��o do ipconfig...

      // Seto a forma de obten��o das informa��es de TCP...
      SetValorDatMemoria('TcpIp.TE_ORIGEM_MAC',v_metodo_obtencao, v_tstrCipherOpened);
      v_mac_address := '';
      v_acao_gercols := 'Criando StringLists para campos e valores de temp/ipconfig.txt...';
      v_array_campos  := TStringList.Create;
      v_array_valores := TStringList.Create;
      Try
        v_acao_gercols := 'Acessando o arquivo ' + v_nome_arquivo;
        AssignFile(IpConfigTXT, v_nome_arquivo);
        v_acao_gercols := 'Abrindo o arquivo ' + v_nome_arquivo;
        Reset(IpConfigTXT);
        while not Eof(IpConfigTXT) do
         begin
           v_acao_gercols := 'Lendo linha ' + IpConfigLINHA + ' de ' + v_nome_arquivo;
           ReadLn(IpConfigTXT, IpConfigLINHA);
           IpConfigLINHA := trim (IpConfigLINHA);
           intAux1 := LastPos(': ',PChar(IpConfigLINHA));
           if (intAux1 > 0) then
             Begin
               v_acao_gercols := 'Adicionando ' + copy(IpConfigLINHA,1,intAux1) + ' � matriz campos';
               v_array_campos.Add(copy(IpConfigLINHA,1,intAux1));
               v_acao_gercols := 'Adicionando ' + copy(IpConfigLINHA,intAux1 + 2, length(IpConfigLINHA)) + ' � matriz valores';
               v_array_valores.Add(copy(IpConfigLINHA,intAux1 + 2, length(IpConfigLINHA)));
             End;
         end;
      Except log_diario('Erro na extra��o de informa��es do ipconfig.txt.');
      End; // fim do Try

      v_acao_gercols := 'Fechando ' + v_nome_arquivo;

      // Pausa para total unlock do arquivo
      sleep(2000);

      // Fecho o arquivo
      CloseFile(IpConfigTXT);
      v_acao_gercols := 'Arquivo ' + v_nome_arquivo + ' fechado com sucesso!';
      sleep(1000);

      if (v_array_campos.Count > 0) then
        Begin
           v_acao_gercols := 'Definindo pseudo MAC�s...';
           // Vamos desviar dos famosos pseudo-MAC�s...
           v_enderecos_mac_invalidos := GetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS', v_tstrCipherOpened);
           if (v_enderecos_mac_invalidos <> '') then v_enderecos_mac_invalidos := v_enderecos_mac_invalidos + ',';
           v_enderecos_mac_invalidos := v_enderecos_mac_invalidos + '00:00:00:00:00:00';

           v_acao_gercols := 'Extraindo informa��es TCP via PegaDadosIPConfig...';
           // Os par�metros para a chamada � fun��o PegaDadosIPConfig devem estar estar em min�sculo.
           if (v_mac_address='')      then Try v_mac_address      := PegaDadosIPConfig(v_array_campos,v_array_valores,'endere,sico;physical,address;direcci,adaptador',v_enderecos_mac_invalidos) Except v_mac_address      := ''; end;
           if (te_mascara='')         then Try te_mascara         := PegaDadosIPConfig(v_array_campos,v_array_valores,'scara,sub,rede;sub,net,mask;scara,subred','255.255.255.255;')         Except te_mascara         := ''; end;
           if (te_ip='')              then Try te_ip              := PegaDadosIPConfig(v_array_campos,v_array_valores,'endere,ip;ip,address;direcci,ip','0.0.0.0')                         Except te_ip              := ''; end;
           if (te_gateway='')         then Try te_gateway         := PegaDadosIPConfig(v_array_campos,v_array_valores,'gateway,padr;gateway,definido;default,gateway;puerta,enlace,predeterminada','')       Except te_gateway         := ''; end;
           if (te_nome_host='')       then Try te_nome_host       := PegaDadosIPConfig(v_array_campos,v_array_valores,'nome,host;host,name;nombre,del,host','')                                 Except te_nome_host       := ''; end;
           if (te_serv_dhcp='')       then Try te_serv_dhcp       := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,dhcp;dhcp,server','')                           Except te_serv_dhcp       := ''; end;
           if (te_dns_primario='')    then Try te_dns_primario    := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidores,dns;dns,servers','')                          Except te_dns_primario    := ''; end;
           if (te_wins_primario='')   then Try te_wins_primario   := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,wins,prim;wins,server,primary','')              Except te_wins_primario   := ''; end;
           if (te_wins_secundario='') then Try te_wins_secundario := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,wins,secund;wins,server,secondary','')          Except te_wins_secundario := ''; end;

           if (g_oCacic.isWindowsNT()) then //Se NT/2K/XP
             Try
                te_dominio_windows := PegaDadosIPConfig(v_array_campos,v_array_valores,'usu,rio,logado;usu,rio,logado','')
             Except
                te_dominio_windows := 'N�o Identificado';
             end
           else
             Try
                te_dominio_windows := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\MSNP32\NetworkProvider\AuthenticatingAgent') + '@' + GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Network\Logon\username')
             Except te_dominio_windows := 'N�o Identificado';
             end;

        End // fim do Begin
      Else
        Begin
          Try
             if (v_mac_address = '') then
                Begin
                  v_mac_address := GetMACAddress;
                  SetValorDatMemoria('TcpIp.TE_ORIGEM_MAC','utils_GetMACaddress', v_tstrCipherOpened);
                End;
             if (v_mac_address = '') then
                Begin
                  v_mac_address := Trim(v_tcpip.Adapter[v_index_ethernet].Address);
                  SetValorDatMemoria('TcpIp.TE_ORIGEM_MAC','MSI_TCP.Adapter['+IntToStr(v_index_ethernet)+'].Address', v_tstrCipherOpened);
                End;

             if (v_mac_address <> '') then
                Begin
                  v_enderecos_mac_invalidos := GetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS', v_tstrCipherOpened);
                  v_conta_EXCECOES := 0;
                  if (v_enderecos_mac_invalidos <> '') then
                    Begin
                      tstrEXCECOES  := g_oCacic.explode(v_enderecos_mac_invalidos,','); // Excecoes a serem tratadas
                      for intAux4 := 0 to tstrEXCECOES.Count-1 Do
                        Begin
                          if (rat(tstrEXCECOES[intAux4],v_mac_address) > 0) then
                            Begin
                              v_conta_EXCECOES := 1;
                              break;
                            End;
                        End;

                      if (v_conta_EXCECOES > 0) then
                        Begin
                          v_mac_address := '';
                        End;
                    End;
                End;
              Except log_diario('Erro na obten��o de informa��es de rede! (GetMACAddress).');
              End;
        End;

      // Deleto os arquivos usados na obten��o via VBScript e CMD/Command
      v_acao_gercols := 'Excluindo arquivo '+v_nome_arquivo+', usado na obten��o de IPCONFIG...';
      log_DEBUG('Excluindo: "'+v_nome_arquivo+'"');
      DeleteFile(v_nome_arquivo);

      v_acao_gercols := 'Excluindo arquivo '+g_oCacic.getCacicPath + 'Temp\ipconfi1.txt, usado na obten��o de IPCONFIG...';
      Matar(g_oCacic.getCacicPath+'Temp\','ipconfi1.txt');

      v_acao_gercols := 'Excluindo arquivo '+g_oCacic.getCacicPath + 'Temp\ipconfig.vbs, usado na obten��o de IPCONFIG...';
      Matar(g_oCacic.getCacicPath+'Temp\','ipconfig.vbs');
    End;

    v_mascara := te_mascara;
    // Em 12/08/2005, extin��o da obrigatoriedade de obten��o de M�scara de Rede na esta��o.
    // O c�lculo para obten��o deste par�metro poder� ser feito pelo m�dulo Gerente Web atrav�s do script get_config.php
    // if (trim(v_mascara)='') then v_mascara := '255.255.255.0';

    try
      if (trim(GetIPRede(te_ip, te_mascara))<>'') then
      SetValorDatMemoria('TcpIp.ID_IP_REDE',GetIPRede(te_ip, te_mascara), v_tstrCipherOpened);
    except
       log_diario('Erro setando IP_REDE.');
    end;

    try
      SetValorDatMemoria('TcpIp.TE_NODE_ADDRESS',StringReplace(v_mac_address,':','-',[rfReplaceAll]), v_tstrCipherOpened);
    except
       log_diario('Erro setando NODE_ADDRESS.');
    end;

    Try
      SetValorDatMemoria('TcpIp.TE_NOME_HOST',TE_NOME_HOST, v_tstrCipherOpened);
    Except
      log_diario('Erro setando NOME_HOST.');
    End;

    try
       SetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR' ,TE_NOME_HOST, v_tstrCipherOpened);
    except
       log_diario('Erro setando NOME_COMPUTADOR.');
    end;

    Try
      SetValorDatMemoria('TcpIp.TE_WORKGROUP',GetWorkgroup, v_tstrCipherOpened);
    except
      log_diario('Erro setando TE_WORKGROUP.');
    end;

    if (GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened)<>'') then
        begin
            // Passei a enviar sempre a vers�o do CACIC...
            // Solicito do servidor a configura��o que foi definida pelo administrador do CACIC.
            Request_SVG := TStringList.Create;

            //Tratamento de Sistemas Monitorados
            intAux4 := 1;
            strAux3 := '';
            ValorChaveRegistro := '*';
            while ValorChaveRegistro <> '' do
              begin
                strAux3 := 'SIS' + trim(inttostr(intAux4));
                ValorChaveRegistro  := GetValorDatMemoria('Coletas.'+strAux3, v_tstrCipherOpened);

                if (ValorChaveRegistro <> '') then
                  Begin
                     tstrTripa1  := g_oCacic.explode(ValorChaveRegistro,'#');
                     for intAux1 := 0 to tstrTripa1.Count-1 Do
                       Begin
                         tstrTripa2  := g_oCacic.explode(tstrTripa1[intAux1],',');
                         //Apenas os dois primeiros itens, id_aplicativo e dt_atualizacao
                         strTripa := strTripa + tstrTripa2[0] + ',' + tstrTripa2[1]+'#';
                       end;
                  End; //If
                intAux4 := intAux4 + 1;
              end; //While

             // Proposital, para for�ar a chegada dos perfis, solu��o tempor�ria...
             Request_SVG.Values['te_tripa_perfis']       := StringReplace(g_oCacic.enCrypt(''),'+','<MAIS>',[rfReplaceAll]);

             // Gero e armazeno uma palavra-chave e a envio ao Gerente WEB para atualiza��o no BD.
             // Essa palavra-chave ser� usada para o acesso ao Agente Principal
             strAux := GeraPalavraChave;

             SetValorDatMemoria('Configs.te_palavra_chave',strAux, v_tstrCipherOpened);

             // Verifico se srCACIC est� em execu��o e em caso positivo entrego a chave atualizada
             Matar(g_oCacic.getCacicPath+'Temp\','aguarde_SRCACIC.txt');
             sleep(2000);
             if (FileExists(g_oCacic.getCacicPath + 'Temp\aguarde_SRCACIC.txt')) then
                Begin
                  // Alguns cuidados necess�rios ao tr�fego e recep��o de valores pelo Gerente WEB
                  // Some cares about send and receive at Gerente WEB
                  v_Aux := StringReplace(strAux                       ,' ' ,'<ESPACE>'  ,[rfReplaceAll]);
                  v_Aux := StringReplace(v_Aux                        ,'"' ,'<AD>'      ,[rfReplaceAll]);
                  v_Aux := StringReplace(v_Aux                        ,'''','<AS>'      ,[rfReplaceAll]);
                  v_Aux := StringReplace(v_Aux                        ,'\' ,'<BarrInv>' ,[rfReplaceAll]);
                  v_Aux := StringReplace(g_oCacic.enCrypt(v_Aux)      ,'+' ,'<MAIS>'    ,[rfReplaceAll]);

                  log_DEBUG('Invocando "'+g_oCacic.getCacicPath + 'modulos\srcacicsrv.exe -update [' + v_Aux + ']' );
                  WinExec(PChar(g_oCacic.getCacicPath + 'modulos\srcacicsrv.exe -update [' + v_Aux + ']'),SW_NORMAL);
                End;


             Request_SVG.Values['te_palavra_chave']       := g_oCacic.enCrypt(strAux);
             v_te_serv_cacic := GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened);

             strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);

             // A vers�o com criptografia do M�dulo Gerente WEB retornar� o valor cs_cipher=1(Quando receber "1") ou cs_cipher=2(Quando receber "3")
             Seta_l_cs_cipher(strRetorno);

             // A vers�o com compress�o do M�dulo Gerente WEB retornar� o valor cs_compress=1(Quando receber "1") ou cs_compress=2(Quando receber "3")
             Seta_l_cs_compress(strRetorno);

             v_te_serv_cacic := g_oCacic.deCrypt(XML_RetornaValor('te_serv_cacic',strRetorno));

             if (strRetorno <> '0') and
                (v_te_serv_cacic<>'') and
                (v_te_serv_cacic<>GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened)) then
                Begin
                  v_mensagem_log := 'Novo endere�o para Gerente WEB: '+v_te_serv_cacic;
                  SetValorDatMemoria('Configs.EnderecoServidor',v_te_serv_cacic, v_tstrCipherOpened);
                  log_DEBUG('Setando Criptografia para 3. (Primeiro contato)');
                  Seta_l_cs_cipher('');
                  log_DEBUG('Refazendo comunica��o');

                  // Passei a enviar sempre a vers�o do CACIC...
                  // Solicito do servidor a configura��o que foi definida pelo administrador do CACIC.
                  Request_SVG.Free;
                  Request_SVG := TStringList.Create;
                  Request_SVG.Values['te_tripa_perfis']    := StringReplace(g_oCacic.enCrypt(''),'+','<MAIS>',[rfReplaceAll]);
                  strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);
                  Seta_l_cs_cipher(strRetorno);
                  Seta_l_cs_compress(strRetorno);
                End;

             Request_SVG.Free;

             if (strRetorno <> '0') Then
              Begin
                ValorRetornado := g_oCacic.deCrypt(XML_RetornaValor('SISTEMAS_MONITORADOS_PERFIS', strRetorno));
                log_DEBUG('Valor Retornado para Sistemas Monitorados: "'+ValorRetornado+'"');
                IF (ValorRetornado <> '') then
                Begin
                     intAux4 := 1;
                     strAux3 := '*';
                     while strAux3 <> '' do
                      begin
                        strAux3 := GetValorDatMemoria('Coletas.SIS' + trim(inttostr(intAux4)), v_tstrCipherOpened);
                        if (trim(strAux3)<>'') then
                          Begin
                            strAux3 := 'SIS' + trim(inttostr(intAux4));
                            SetValorDatMemoria('Coletas.'+strAux3,'', v_tstrCipherOpened);
                          End;
                        intAux4 := intAux4 + 1;
                      end;

                   intAux4 := 0;
                   tstrTripa3  := g_oCacic.explode(ValorRetornado,'#');
                   for intAux3 := 0 to tstrTripa3.Count-1 Do
                   Begin
                     strAux3 := 'SIS' + trim(inttostr(intAux4));
                     tstrTripa4  := g_oCacic.explode(tstrTripa3[intAux3],',');
                     while strAux3 <> '' do
                      begin
                        intAux4 := intAux4 + 1;
                        strAux3 := GetValorDatMemoria('Coletas.SIS' + trim(inttostr(intAux4)), v_tstrCipherOpened);
                        if (trim(strAux3)<>'') then
                          Begin
                            tstrTripa5 := g_oCacic.explode(strAux3,',');
                            if (tstrTripa5[0] = tstrTripa4[0]) then strAux3 := '';
                          End;
                      end;
                     strAux3 := 'SIS' + trim(inttostr(intAux4));
                     SetValorDatMemoria('Coletas.'+strAux3,tstrTripa3[intAux3], v_tstrCipherOpened);
                   end;
                end;

                log_DEBUG('Armazenando valores obtidos no DAT Mem�ria.');
                v_acao_gercols := 'Armazenando valores obtidos no DAT Mem�ria.';

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //Grava��o no CACIC2.DAT dos valores de REDE, COMPUTADOR e EXECU��O obtidos, para consulta pelos outros m�dulos...
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                SetValorDatMemoria('Configs.CS_AUTO_UPDATE'                 ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_auto_update'          , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_HARDWARE'             ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_coleta_hardware'      , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_SOFTWARE'             ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_coleta_software'      , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_MONITORADO'           ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_coleta_monitorado'    , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_OFFICESCAN'           ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_coleta_officescan'    , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_COMPARTILHAMENTOS'    ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_coleta_compart'       , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_UNID_DISC'            ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_coleta_unid_disc'     , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_PATRIMONIO'           ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_coleta_patrimonio'    , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_SUPORTE_REMOTO'              ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('cs_suporte_remoto'       , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_CACIC2_DISPONIVEL'    ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_cacic2_disponivel'       , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_CACIC2'                 ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_cacic2'                    , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_GER_COLS_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_ger_cols_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_GER_COLS'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_ger_cols'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_CHKSIS_DISPONIVEL'    ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_chksis_disponivel'       , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_CHKSIS'                 ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_chksis'                    , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_ANVI_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_col_anvi_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_COL_ANVI'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_col_anvi'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_COMP_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_col_comp_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_COL_COMP'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_col_comp'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_HARD_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_col_hard_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_COL_HARD'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_col_hard'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_MONI_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_col_moni_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_COL_MONI'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_col_moni'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_PATR_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_col_patr_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_COL_PATR'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_col_patr'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_SOFT_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_col_soft_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_COL_SOFT'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_col_soft'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_UNDI_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_col_undi_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_COL_UNDI'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_col_undi'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_INI_COLS_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_ini_cols_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_INI_COLS'               ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_ini_cols'                  , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_INI_COLS_DISPONIVEL'  ,g_oCacic.deCrypt(XML_RetornaValor('dt_versao_ini_cols_disponivel'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_SRCACICSRV'             ,g_oCacic.deCrypt(XML_RetornaValor('te_hash_srcacicsrv'                , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_SRCACICSRV_DISPONIVEL',g_oCacic.deCrypt(XML_RetornaValor('dt_versao_srcacicsrv_disponivel'   , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_HASH_'+StringReplace(v_scripter,'.exe','',[rfReplaceAll]),g_oCacic.deCrypt(XML_RetornaValor('te_hash_'+StringReplace(v_scripter,'.exe','',[rfReplaceAll]),strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_SERV_UPDATES'                ,g_oCacic.deCrypt(XML_RetornaValor('te_serv_updates'                   , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES'          ,g_oCacic.deCrypt(XML_RetornaValor('nu_porta_serv_updates'             , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES'           ,g_oCacic.deCrypt(XML_RetornaValor('te_path_serv_updates'              , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES'  ,g_oCacic.deCrypt(XML_RetornaValor('nm_usuario_login_serv_updates'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES'    ,g_oCacic.deCrypt(XML_RetornaValor('te_senha_login_serv_updates'       , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.IN_EXIBE_ERROS_CRITICOS'        ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('in_exibe_erros_criticos' , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_SENHA_ADM_AGENTE'            ,g_oCacic.deCrypt(XML_RetornaValor('te_senha_adm_agente'               , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_INTERVALO_RENOVACAO_PATRIM'  ,g_oCacic.deCrypt(XML_RetornaValor('nu_intervalo_renovacao_patrim'     , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_INTERVALO_EXEC'              ,g_oCacic.deCrypt(XML_RetornaValor('nu_intervalo_exec'                 , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_EXEC_APOS'                   ,g_oCacic.deCrypt(XML_RetornaValor('nu_exec_apos'                      , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.IN_EXIBE_BANDEJA'               ,UpperCase(g_oCacic.deCrypt(XML_RetornaValor('in_exibe_bandeja'        , strRetorno))), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_JANELAS_EXCECAO'             ,g_oCacic.deCrypt(XML_RetornaValor('te_janelas_excecao'                , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS'       ,g_oCacic.deCrypt(XML_RetornaValor('te_enderecos_mac_invalidos'        , strRetorno)) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA'           ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada'     , strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_ANVI'      ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada_anvi', strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_COMP'      ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada_comp', strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_HARD'      ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada_hard', strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_MONI'      ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada_moni', strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_PATR'      ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada_patr', strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_SOFT'      ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada_soft', strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_UNDI'      ,stringreplace(stringreplace(stringreplace(g_oCacic.deCrypt(XML_RetornaValor('dt_hr_coleta_forcada_undi', strRetorno)),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
              end;


            // Envio de Dados de TCP_IP
            if (te_dominio_windows = '') then
              Begin
                Try
                  if (g_oCacic.isWindowsNT()) then //Se NT/2K/XP
                     te_dominio_windows := GetNetworkUserName + '@' + GetDomainName
                  else
                     te_dominio_windows := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Network\Logon\username')+ '@' + GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\MSNP32\NetworkProvider\AuthenticatingAgent');
                Except te_dominio_windows := 'N�o Identificado';
                End;
              End;

            Request_SVG := TStringList.Create;
            Request_SVG.Values['te_mascara']         := StringReplace(g_oCacic.enCrypt(te_mascara),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_gateway']         := StringReplace(g_oCacic.enCrypt(te_gateway),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_serv_dhcp']       := StringReplace(g_oCacic.enCrypt(te_serv_dhcp),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dns_primario']    := StringReplace(g_oCacic.enCrypt(te_dns_primario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dns_secundario']  := StringReplace(g_oCacic.enCrypt(te_dns_secundario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_wins_primario']   := StringReplace(g_oCacic.enCrypt(te_wins_primario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_wins_secundario'] := StringReplace(g_oCacic.enCrypt(te_wins_secundario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_nome_host']       := StringReplace(g_oCacic.enCrypt(te_nome_host),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dominio_dns']     := StringReplace(g_oCacic.enCrypt(te_dominio_dns),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_origem_mac']      := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('TcpIp.TE_ORIGEM_MAC', v_tstrCipherOpened)),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dominio_windows'] := StringReplace(g_oCacic.enCrypt(te_dominio_windows),'+','<MAIS>',[rfReplaceAll]);

            v_acao_gercols := 'Contactando m�dulo Gerente WEB: set_tcp_ip.php';

            strRetorno := ComunicaServidor('set_tcp_ip.php', Request_SVG, '>> Enviando configura��es de TCP/IP ao Gerente WEB.');
            if (strRetorno <> '0') Then
              Begin
                SetValorDatMemoria('TcpIp.te_mascara'        , te_mascara        , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_gateway'        , te_gateway        , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_serv_dhcp'      , te_serv_dhcp      , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_dns_primario'   , te_dns_primario   , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_dns_secundario' , te_dns_secundario , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_wins_primario'  , te_wins_primario  , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_wins_secundario', te_wins_secundario, v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_nome_host'      , te_nome_host      , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_dominio_dns'    , te_dominio_dns    , v_tstrCipherOpened);
              End;

            Request_SVG.Free;


        end;
  v_tcpip.Free;
  except log_diario('PROBLEMAS EM BUSCACONFIGS - ' + v_acao_gercols+'.');
  End;
end;

procedure Executa_Ger_Cols;
var strDtHrColetaForcada,
    strDtHrUltimaColeta : String;
Begin
  Try
          // Par�metros poss�veis (aceitos)
          //   /ip_serv_cacic =>  Endere�o IP do M�dulo Gerente. Ex.: 10.71.0.212
          //   /cacic_dir     =>  Diret�rio para instala��o do Cacic na esta��o. Ex.: Cacic
          //   /coletas       =>  Chamada para ativa��o das coletas
          //   /patrimonio    =>  Chamada para ativa��o do Formul�rio de Patrim�nio
          // UpdatePrincipal  =>  Atualiza��o do Agente Principal
          // Chamada com par�metros pelo chkcacic.exe ou linha de comando
          // Chamada efetuada pelo Cacic2.exe quando da exist�ncia de temp\cacic2.exe para AutoUpdate
          If FindCmdLineSwitch('UpdatePrincipal', True) Then
            Begin
               log_DEBUG('Op��o /UpdatePrincipal recebida...');
               // 15 segundos de tempo total at� a execu��o do novo cacic2.exe
               sleep(7000);
               v_acao_gercols := 'Atualiza��o do Agente Principal - Excluindo '+g_oCacic.getCacicPath + 'cacic2.exe';
               Matar(g_oCacic.getCacicPath,'cacic2.exe');
               sleep(2000);

               v_acao_gercols := 'Atualiza��o do Agente Principal - Copiando '+g_oCacic.getCacicPath + 'temp\cacic2.exe para '+g_oCacic.getCacicPath + 'cacic2.exe';
               log_DEBUG('Copiando '+g_oCacic.getCacicPath + 'temp\cacic2.exe para '+g_oCacic.getCacicPath + 'cacic2.exe');
               CopyFile(pChar(g_oCacic.getCacicPath + 'temp\cacic2.exe'),pChar(g_oCacic.getCacicPath + 'cacic2.exe'),FALSE {Fail if Exists});
               sleep(2000);

               v_acao_gercols := 'Atualiza��o do Agente Principal - Excluindo '+g_oCacic.getCacicPath + 'temp\cacic2.exe';
               Matar(g_oCacic.getCacicPath+'temp\','cacic2.exe');
               sleep(2000);

               SetValorDatMemoria('Configs.NU_EXEC_APOS','12345', v_tstrCipherOpened); // Para que o Agente Principal comande a coleta logo ap�s 1 minuto...
               sleep(2000);

               log_DEBUG('Invocando atualiza��o do Agente Principal...');

               v_acao_gercols := 'Atualiza��o do Agente Principal - Invocando '+g_oCacic.getCacicPath + 'cacic2.exe /atualizacao';
               Finalizar(false);

               if ChecaAgente(g_oCacic.getCacicPath, 'cacic2.exe') then
                  WinExec(PChar(g_oCacic.getCacicPath + 'cacic2.exe /atualizacao'), SW_MINIMIZE);
               Sair;
              end;

          For intAux := 1 to ParamCount do
            Begin
              if LowerCase(Copy(ParamStr(intAux),1,15)) = '/ip_serv_cacic=' then
                begin
                  v_acao_gercols := 'Configurando ip_serv_cacic.';
                  strAux := Trim(Copy(ParamStr(intAux),16,Length((ParamStr(intAux)))));
                  endereco_servidor_cacic := Trim(Copy(strAux,0,Pos('/', strAux) - 1));
                  log_DEBUG('Par�metro /ip_serv_cacic recebido com valor="'+endereco_servidor_cacic+'"');
                  If endereco_servidor_cacic = '' Then endereco_servidor_cacic := strAux;
                  SetValorDatMemoria('Configs.EnderecoServidor', endereco_servidor_cacic, v_tstrCipherOpened);
                end;
            end;

          // Chamada com par�metros pelo chkcacic.exe ou linha de comando
          For intAux := 1 to ParamCount do
            Begin
              If LowerCase(Copy(ParamStr(intAux),1,11)) = '/cacic_dir=' then
                Begin
                  v_acao_gercols := 'Configurando diret�rio para o CACIC. (Registry para w95/95OSR2/98/98SE/ME)';
                  // Identifico a vers�o do Windows
                  If (g_oCacic.isWindows9xME()) then
                    begin
                    //Se for 95/95OSR2/98/98SE/ME fa�o aqui...  (Em NT Like isto � feito no LoginScript)
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2', Trim(Copy(ParamStr(intAux),12,Length((ParamStr(intAux))))) + '\cacic2.exe');
                    log_DEBUG('Setando Chave de AutoExecu��o...');
                    end;
                  log_DEBUG('Par�metro /cacic_dir recebido com valor="'+Trim(Copy(ParamStr(intAux),12,Length((ParamStr(intAux)))))+'"');
                end;
            End;

          // Chamada efetuada pelo Cacic2.exe quando o usu�rio clica no menu "Informa��es Patrimoniais"
          // Caso existam informa��es patrimoniais preenchidas, ser� pedida a senha configurada no m�dulo gerente WEB
          If FindCmdLineSwitch('patrimonio', True) Then
            Begin
              log_DEBUG('Op��o /patrimonio recebida...');
              v_acao_gercols := 'Invocando Col_Patr.';
              log_DEBUG('Chamando Coletor de Patrim�nio...');
              Patrimnio1Click(Nil);
              Finalizar(false);
              CriaTXT(g_oCacic.getCacicPath+'temp','coletas');
              Sair;
            End;

          If FindCmdLineSwitch('BuscaConfigsPrimeira', True) Then
            begin
              log_DEBUG('Op��o /BuscaConfigsPrimeira recebida...');
              BuscaConfigs(false);
              Batchfile := TStringList.Create;
              Batchfile.Add('*** Simula��o de cookie para cacic2.exe recarregar os valores de configura��es ***');
              // A exist�ncia deste arquivo for�ar� o Cacic2.exe a recarregar valores das configura��es obtidas e gravadas no Cacic2.DAT
              Batchfile.SaveToFile(g_oCacic.getCacicPath + 'Temp\reset.txt');
              BatchFile.Free;
              log_DEBUG('Configura��es apanhadas no m�dulo Gerente WEB. Retornando ao Agente Principal...');
              Finalizar(false);
              Sair;
            end;

          // Chamada temporizada efetuada pelo Cacic2.exe
        If FindCmdLineSwitch('coletas', True) Then
            begin
              log_DEBUG('Par�metro(op��o) /coletas recebido...');
              v_acao_gercols := 'Ger_Cols invocado para coletas...';

              // Verificando o registro de coletas do dia e eliminando datas diferentes...
              strAux := GetValorDatMemoria('Coletas.HOJE', v_tstrCipherOpened);
              if (strAux = '') or
                 (copy(strAux,0,8) <> FormatDateTime('yyyymmdd', Date)) then
                 SetValorDatMemoria('Coletas.HOJE', FormatDateTime('yyyymmdd', Date),v_tstrCipherOpened);

              BuscaConfigs(true);

              // Abaixo eu testo se existe um endere�o configurado para n�o disparar os procedimentos de coleta em v�o.
              if (GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened)<>'') then
                  begin
                      v_CS_AUTO_UPDATE := (GetValorDatMemoria('Configs.CS_AUTO_UPDATE', v_tstrCipherOpened) = 'S');
                      if (v_CS_AUTO_UPDATE) then
                          Begin
                            log_DEBUG('Indicador CS_AUTO_UPDATE=S encontrado.');
                            log_diario('Verificando Agente Principal, Gerente de Coletas e Suporte Remoto.');

                            // Caso encontre nova vers�o de cacic2.exe esta ser� gravada em temp e ocorrer� o autoupdate em sua pr�xima tentativa de chamada ao Ger_Cols.
                            v_acao_gercols := 'Verificando vers�o do Agente Principal';
                            log_diario('Verificando nova vers�o para m�dulo Principal.');
                            Ver_UPD('cacic2','Agente Principal',g_oCacic.getCacicPath,'Temp',false);

                            log_diario('Verificando nova vers�o para m�dulo Gerente de Coletas.');
                            // Caso encontre nova vers�o de Ger_Cols esta ser� gravada em temp e ocorrer� o autoupdate.
                            Ver_UPD('ger_cols','Gerente de Coletas',g_oCacic.getCacicPath + 'modulos\','Temp',false);

                            // O m�dulo de Suporte Remoto � opcional...
                            if (GetValorDatMemoria('Configs.CS_SUPORTE_REMOTO'         , v_tstrCipherOpened) = 'S') then
                              Begin
                                log_diario('Verificando nova vers�o para m�dulo Suporte Remoto Seguro.');
                                // Caso encontre nova vers�o de srCACICsrv esta ser� gravada em modulos.
                                Ver_UPD('srcacicsrv','Suporte Remoto Seguro',g_oCacic.getCacicPath + 'modulos\','Modulos',false);
                              End;

                            if (FileExists(g_oCacic.getCacicPath + 'Temp\ger_cols.exe')) or
                               (FileExists(g_oCacic.getCacicPath + 'Temp\cacic2.exe'))  then
                                Begin
                                  log_diario('Finalizando... (Update em � 1 minuto).');
                                  Finalizar(false);
                                  Sair;
                                End;
                          End;

                      if ((GetValorDatMemoria('Configs.CS_COLETA_HARDWARE'         , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_SOFTWARE'         , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_MONITORADO'       , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_OFFICESCAN'       , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_COMPARTILHAMENTOS', v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_UNID_DISC'        , v_tstrCipherOpened) = 'S')) and
                          not FileExists(g_oCacic.getCacicPath + 'Temp\ger_cols.exe')  then
                          begin
                             v_acao_gercols := 'Montando script de coletas';
                             // Monto o batch de coletas de acordo com as configura��es
                             log_diario('Verificando novas vers�es para Coletores de Informa��es.');
                             intMontaBatch := 0;
                             v_ModulosOpcoes := '';
                             strDtHrUltimaColeta := '0';
                             Try
                               strDtHrUltimaColeta := GetValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA', v_tstrCipherOpened);
                             Except
                             End;
                             if (strDtHrUltimaColeta = '') then
                                strDtHrUltimaColeta := '0';

                             if (GetValorDatMemoria('Configs.CS_COLETA_PATRIMONIO', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_PATR', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta For�ada PATR: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora �ltima Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_PATR','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_PATR','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_patr','Coletor de Informa��es de Patrim�nio/Loc.F�s.',g_oCacic.getCacicPath + 'modulos\','',false);
                                   if (FileExists(g_oCacic.getCacicPath + 'Modulos\col_patr.exe'))  then
                                      Begin
                                         GetInfoPatrimonio;
                                         // S� chamo o Coletor de Patrim�nio caso haja altera��o de localiza��o(e esteja configurado no m�dulo gerente WEB a abertura autom�tica da janela)
                                         // ou o prazo de renova��o esteja vencido ou seja o momento da instala��o
                                         if (GetValorDatMemoria('Patrimonio.in_alteracao_fisica'     , v_tstrCipherOpened) = 'S') or
                                            (GetValorDatMemoria('Patrimonio.in_renovacao_informacoes', v_tstrCipherOpened) = 'S') or
                                            (GetValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA'        , v_tstrCipherOpened)         = '' ) then
                                              Begin
                                                 intMontaBatch := 1;
                                                 if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                                 v_ModulosOpcoes := v_ModulosOpcoes + 'col_patr,wait,system';
                                              End;
                                      End
                                   Else
                                      log_diario('Execut�vel Col_Patr Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_OFFICESCAN'       , v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_ANVI', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta For�ada ANVI: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora �ltima Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_ANVI','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_ANVI','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_anvi','Coletor de Informa��es de Anti-V�rus OfficeScan',g_oCacic.getCacicPath + 'modulos\','',false);
                                   if (FileExists(g_oCacic.getCacicPath + 'Modulos\col_anvi.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_anvi,nowait,system';
                                      End
                                   Else log_diario('Execut�vel Col_Anvi Inexistente!');

                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_COMPARTILHAMENTOS', v_tstrCipherOpened) = 'S') then
                                begin

                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_COMP', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta For�ada COMP: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora �ltima Coleta GERAL: '+strDtHrUltimaColeta);
                                  if not(strDtHrColetaForcada = '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_COMP','S', v_tstrCipherOpened)
                                  else
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_COMP','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_comp','Coletor de Informa��es de Compartilhamentos',g_oCacic.getCacicPath + 'modulos\','',false);
                                   if (FileExists(g_oCacic.getCacicPath + 'Modulos\col_comp.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_comp,nowait,system';
                                      End
                                   Else
                                      log_diario('Execut�vel Col_Comp Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_HARDWARE', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_HARD', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta For�ada HARD: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora �ltima Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_HARD','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_HARD','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_hard','Coletor de Informa��es de Hardware',g_oCacic.getCacicPath + 'modulos\','',false);
                                   if (FileExists(g_oCacic.getCacicPath + 'Modulos\col_hard.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_hard,nowait,system';
                                      End
                                   Else
                                      log_diario('Execut�vel Col_Hard Inexistente!');
                                end;


                             if (GetValorDatMemoria('Configs.CS_COLETA_MONITORADO', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_MONI', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta For�ada MONI: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora �ltima Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_MONI','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_MONI','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_moni','Coletor de Informa��es de Sistemas Monitorados',g_oCacic.getCacicPath + 'modulos\','',false);
                                   if (FileExists(g_oCacic.getCacicPath + 'Modulos\col_moni.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_moni,wait,system';
                                      End
                                   Else
                                      log_diario('Execut�vel Col_Moni Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_SOFTWARE', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_SOFT', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta For�ada SOFT: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora �ltima Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_SOFT','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_SOFT','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_soft','Coletor de Informa��es de Softwares B�sicos',g_oCacic.getCacicPath + 'modulos\','',false);
                                   if (FileExists(g_oCacic.getCacicPath + 'Modulos\col_soft.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_soft,nowait,system';
                                      End
                                   Else
                                      log_diario('Execut�vel Col_Soft Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_UNID_DISC', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_UNDI', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta For�ada UNDI: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora �ltima Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_UNDI','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_UNDI','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_undi','Coletor de Informa��es de Unidades de Disco',g_oCacic.getCacicPath + 'modulos\','',false);
                                   if (FileExists(g_oCacic.getCacicPath + 'Modulos\col_undi.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_undi,nowait,system';
                                      End
                                   Else
                                      log_diario('Execut�vel Col_Undi Inexistente!');
                                end;
                             if (countUPD > 0) or
                                (GetValorDatMemoria('Configs.ID_FTP',v_tstrCipherOpened)<>'') then
                                Begin
                                  Request_Ger_Cols := TStringList.Create;
                                  Request_Ger_Cols.Values['in_chkcacic']   := StringReplace(g_oCacic.enCrypt('chkcacic'),'+','<MAIS>',[rfReplaceAll]);
                                  Request_Ger_Cols.Values['te_fila_ftp']   := StringReplace(g_oCacic.enCrypt('2'),'+','<MAIS>',[rfReplaceAll]); // Indicar� sucesso na opera��o de FTP e liberar� lugar para o pr�ximo
                                  Request_Ger_Cols.Values['id_ftp']        := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Configs.ID_FTP',v_tstrCipherOpened)),'+','<MAIS>',[rfReplaceAll]); // Indicar� sucesso na opera��o de FTP e liberar� lugar para o pr�ximo
                                  ComunicaServidor('get_config.php', Request_Ger_Cols, '>> Liberando Grupo FTP!...');
                                  Request_Ger_Cols.Free;
                                  SetValorDatMemoria('Configs.ID_FTP','', v_tstrCipherOpened)
                                End;
                             if (intMontaBatch > 0) then
                                Begin
                                     Ver_UPD('ini_cols','Inicializador de Coletas',g_oCacic.getCacicPath + 'modulos\','',false);
                                     log_diario('Iniciando coletas.');
                                     Finalizar(false);
                                     Matar(g_oCacic.getCacicPath + 'temp\','*.dat');
                                     CriaTXT(g_oCacic.getCacicPath+'temp','coletas');
                                     g_oCacic.createSampleProcess( g_oCacic.getCacicPath + 'modulos\ini_cols.exe /p_ModulosOpcoes=' + v_ModulosOpcoes, CACIC_PROCESS_WAIT );
                                End;

                          end
                       else
                          begin
                             if not FileExists(g_oCacic.getCacicPath + 'Temp\ger_cols.exe') and
                                not FileExists(g_oCacic.getCacicPath + 'modulos\ger_cols.exe')  then
                                  log_diario('M�dulo Gerente de Coletas inexistente.')
                             else log_diario('Nenhuma coleta configurada para essa subrede / esta��o / S.O.');
                          end;
                  End;
            end;

        // Caso n�o existam os arquivos abaixo, ser� finalizado.
        if (FileExists(g_oCacic.getCacicPath + 'Temp\coletas.txt')) or (FileExists(g_oCacic.getCacicPath + 'Temp\coletas.bat')) then
            begin
              log_DEBUG('Encontrado indicador de Coletas - Realizando leituras...');
              v_tstrCipherOpened1 := TStrings.Create;

              // Envio das informa��es coletadas com exclus�o dos arquivos batchs e inis utilizados...
              Request_Ger_Cols:=TStringList.Create;
              intAux := 0;

              if (FileExists(g_oCacic.getCacicPath + 'Temp\col_anvi.dat')) then
                  Begin
                    log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_anvi.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informa��es de Anti-V�rus.';
                    v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_anvi.dat');

                    // Armazeno dados para informa��es de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es sobre Anti-V�rus OfficeScan', v_tstrCipherOpened);

                    // Armazeno as horas de in�cio e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Anvi.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Anvi.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Anvi.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Prepara��o para envio...
                        Request_Ger_Cols.Values['nu_versao_engine' ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Anvi.nu_versao_engine' ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['nu_versao_pattern'] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Anvi.nu_versao_pattern',v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['dt_hr_instalacao' ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Anvi.dt_hr_instalacao' ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_servidor'      ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Anvi.te_servidor'      ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['in_ativo'         ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Anvi.in_ativo'         ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Anvi: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_officescan.php', Request_Ger_Cols, '>> Enviando informa��es de Antiv�rus OfficeScan para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
                            //Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
                            strAux := GetValorDatMemoria('Col_Anvi.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.OfficeScan',strAux, v_tstrCipherOpened) ;
                            intAux := 1;
                          End
                        else
                            // Armazeno o Status Negativo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);

                      End
                    Else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(g_oCacic.getCacicPath+'Temp\','col_anvi.dat');
                  End;

              if (FileExists(g_oCacic.getCacicPath + 'Temp\col_comp.dat')) then
                  Begin
                    log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_comp.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informa��es de Compartilhamentos.';
                    v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_comp.dat');

                    // Armazeno dados para informa��es de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es sobre Compartilhamentos', v_tstrCipherOpened);

                    // Armazeno as horas de in�cio e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Comp.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Comp.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Comp.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Prepara��o para envio...
                        Request_Ger_Cols.Values['CompartilhamentosLocais'] := StringReplace(g_oCacic.enCrypt(StringReplace(GetValorDatMemoria('Col_Comp.UVC',v_tstrCipherOpened1),'\','<BarrInv>',[rfReplaceAll])),'+','<MAIS>',[rfReplaceAll]);
                        if v_Debugs then
                          Begin
                            log_DEBUG('Col_Comp.UVC => '+GetValorDatMemoria('Col_Comp.UVC',v_tstrCipherOpened1));
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Comp: '+Request_Ger_Cols.ValueFromIndex[intLoop]);
                          End;

                        if (ComunicaServidor('set_compart.php', Request_Ger_Cols, '>> Enviando informa��es de Compartilhamentos para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
                            //Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
                            strAux := GetValorDatMemoria('Col_Comp.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Compartilhamentos', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        Else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(g_oCacic.getCacicPath+'Temp\','col_comp.dat');
                  End;

              if (FileExists(g_oCacic.getCacicPath + 'Temp\col_hard.dat')) then
                  Begin
                    log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_hard.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informa��es de Hardware.';
                    v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_hard.dat');

                    // Armazeno dados para informa��es de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es sobre Hardware', v_tstrCipherOpened);

                    // Armazeno as horas de in�cio e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Hard.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Hard.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Hard.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Prepara��o para envio...
                        Request_Ger_Cols.Values['te_Tripa_TCPIP'          ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_Tripa_TCPIP'          ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_Tripa_CPU'            ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_Tripa_CPU'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_Tripa_CDROM'          ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_Tripa_CDROM'          ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_mae_fabricante' ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_placa_mae_fabricante' ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_mae_desc'       ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_placa_mae_desc'       ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_mem_ram'              ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.qt_mem_ram'              ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_mem_ram_desc'         ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_mem_ram_desc'         ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_desc'            ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_bios_desc'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_data'            ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_bios_data'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_fabricante'      ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_bios_fabricante'      ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_placa_video_cores'    ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.qt_placa_video_cores'    ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_video_desc'     ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_placa_video_desc'     ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_placa_video_mem'      ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.qt_placa_video_mem'      ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_video_resolucao'] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_placa_video_resolucao',v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_som_desc'       ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_placa_som_desc'       ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_teclado_desc'         ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_teclado_desc'         ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_mouse_desc'           ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_mouse_desc'           ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_modem_desc'           ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Hard.te_modem_desc'           ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Hard: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_hardware.php', Request_Ger_Cols, '>> Enviando informa��es de Hardware para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
                            //Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
                            strAux :=GetValorDatMemoria('Col_Hard.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Hardware', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(g_oCacic.getCacicPath+'Temp\','col_hard.dat');
                  End;

              if (FileExists(g_oCacic.getCacicPath + 'Temp\col_patr.dat')) then
                  Begin
                    log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_patr.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informa��es de Patrim�nio.';
                    v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_patr.dat');

                    // Armazeno dados para informa��es de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es Patrimoniais', v_tstrCipherOpened);

                    // Armazeno as horas de in�cio e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Patr.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Patr.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Patr.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Prepara��o para envio...
                        Request_Ger_Cols.Values['id_unid_organizacional_nivel1']  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1'  ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['id_unid_organizacional_nivel1a'] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1a' ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['id_unid_organizacional_nivel2']  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel2'  ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_localizacao_complementar'  ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_localizacao_complementar'    ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio1'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio1'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio2'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio2'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio3'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio3'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio4'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio4'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio5'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio5'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio6'          ]  := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio6'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Patr: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_patrimonio.php', Request_Ger_Cols, '>> Enviando informa��es de Patrim�nio para o Gerente WEB.') <> '0') Then
                            Begin
                              // Armazeno o Status Positivo de Envio
                              SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                              // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
                              //Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
                              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1' , GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1',v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1a', GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1a',v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2' , GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel2',v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_localizacao_complementar'   , GetValorDatMemoria('Col_Patr.te_localizacao_complementar'  ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio1'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio1'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio2'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio2'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio3'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio3'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio4'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio4'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio5'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio5'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio6'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio6'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.ultima_rede_obtida'            , GetValorDatMemoria('TcpIp.ID_IP_REDE'                      ,v_tstrCipherOpened) , v_tstrCipherOpened);
                              intAux := 1;
                            End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(g_oCacic.getCacicPath+'Temp\','col_patr.dat');
                  End;

              if (FileExists(g_oCacic.getCacicPath + 'Temp\col_moni.dat')) then
                  Begin
                    log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_moni.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informa��es de Sistemas Monitorados.';
                    v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_moni.dat');

                    // Armazeno dados para informa��es de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es sobre Sistemas Monitorados', v_tstrCipherOpened);

                    // Armazeno as horas de in�cio e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Moni.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Moni.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Moni.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Prepara��o para envio...
                        Request_Ger_Cols.Values['te_tripa_monitorados'] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Moni.UVC',v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Moni: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_monitorado.php', Request_Ger_Cols, '>> Enviando informa��es de Sistemas Monitorados para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
                            //Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
                            strAux := GetValorDatMemoria('Col_Moni.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Sistemas_Monitorados', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(g_oCacic.getCacicPath+'Temp\','col_moni.dat');
                  End;

              if (FileExists(g_oCacic.getCacicPath + 'Temp\col_soft.dat')) then
                  Begin
                    log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_soft.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informa��es de Softwares.';
                    v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_soft.dat');

                    // Armazeno dados para informa��es de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es sobre Softwares', v_tstrCipherOpened);

                    // Armazeno as horas de in�cio e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Soft.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Soft.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Soft.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Prepara��o para envio...
                        Request_Ger_Cols.Values['te_versao_bde'           ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_bde'           ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_dao'           ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_dao'           ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_ado'           ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_ado'           ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_odbc'          ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_odbc'          ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_directx'       ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_directx'       ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_acrobat_reader'] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_acrobat_reader',v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_ie'            ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_ie'            ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_mozilla'       ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_mozilla'       ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_jre'           ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_versao_jre'           ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_inventario_softwares' ] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Soft.te_inventario_softwares' ,v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_variaveis_ambiente'   ] := StringReplace(g_oCacic.enCrypt(StringReplace(GetValorDatMemoria('Col_Soft.te_variaveis_ambiente',v_tstrCipherOpened1),'\','<BarrInv>',[rfReplaceAll])),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Soft: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_software.php', Request_Ger_Cols, '>> Enviando informa��es de Softwares B�sicos para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
                            // Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
                            strAux := GetValorDatMemoria('Col_Soft.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Software', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(g_oCacic.getCacicPath+'Temp\','col_soft.dat');
                  End;

              if (FileExists(g_oCacic.getCacicPath + 'Temp\col_undi.dat')) then
                  Begin
                    log_DEBUG('Indicador '+g_oCacic.getCacicPath + 'Temp\col_undi.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informa��es de Unidades de Disco.';
                    v_tstrCipherOpened1  := CipherOpen(g_oCacic.getCacicPath + 'Temp\col_undi.dat');

                    // Armazeno dados para informa��es de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informa��es sobre Unidades de Disco', v_tstrCipherOpened);

                    // Armazeno as horas de in�cio e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Undi.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Undi.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Undi.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Prepara��o para envio...
                        Request_Ger_Cols.Values['UnidadesDiscos'] := StringReplace(g_oCacic.enCrypt(GetValorDatMemoria('Col_Undi.UVC',v_tstrCipherOpened1)),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Undi: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_unid_discos.php', Request_Ger_Cols, '>> Enviando informa��es de Unidades de Disco para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso n�o tenha havido nenhum erro durante o envio das informa��es para o BD
                            //Sobreponho a informa��o no registro para posterior compara��o, na pr�xima execu��o.
                            strAux := GetValorDatMemoria('Col_Undi.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.UnidadesDisco', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(g_oCacic.getCacicPath+'Temp\','col_undi.dat');
                  End;
              Request_Ger_Cols.Free;

              // Reinicializo o indicador de Fila de Espera para FTP
              SetValorDatMemoria('Configs.TE_FILA_FTP','0', v_tstrCipherOpened);

              if (intAux = 0) then
                  log_diario('Sem informa��es para envio ao Gerente WEB.')
              else begin
                  // Atualiza a data de �ltima coleta
                  SetValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA',FormatDateTime('YYYYmmddHHnnss', Now), v_tstrCipherOpened);
                  log_diario('Os dados coletados - e n�o redundantes - foram enviados ao Gerente WEB.');
              end;
            end;
  Except
    Begin
     log_diario('PROBLEMAS EM EXECUTA_GER_COLS! A��o: ' + v_acao_gercols+'.');
     CriaTXT(g_oCacic.getCacicPath,'ger_erro');
     Finalizar(false);
     SetValorDatMemoria('Erro_Fatal_Descricao', v_acao_gercols, v_tstrCipherOpened);
    End;
  End;

End;

var v_path_cacic : String;
begin
   g_oCacic := TCACIC.Create();

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then begin
     Try
       // Pegarei o n�vel anterior do diret�rio, que deve ser, por exemplo \Cacic, para leitura do cacic2.DAT
       tstrTripa1   := g_oCacic.explode(ExtractFilePath(ParamStr(0)),'\');
       v_path_cacic := '';
       For intAux := 0 to tstrTripa1.Count -2 do
           v_path_cacic := v_path_cacic + tstrTripa1[intAux] + '\';

       g_oCacic.setCacicPath(v_path_cacic);
       v_Debugs := false;
       if DirectoryExists(g_oCacic.getCacicPath + 'Temp\Debugs') then
           if (FormatDateTime('ddmmyyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
          Begin
            v_Debugs := true;
            log_DEBUG('Pasta "' + g_oCacic.getCacicPath + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
          End;

       g_oCacic.setCacicPath(g_oCacic.getCacicPath);



       // De acordo com a vers�o do OS, determina-se o ShellCommand para chamadas externas.
       p_Shell_Command := 'cmd.exe /c '; //NT/2K/XP
       if(g_oCacic.isWindows9xME()) then
          p_Shell_Command := 'command.com /c ';

       if not DirectoryExists(g_oCacic.getCacicPath + 'Temp') then
         ForceDirectories(g_oCacic.getCacicPath + 'Temp');

       v_tstrCipherOpened := TStrings.Create;
       v_tstrCipherOpened := CipherOpen(g_oCacic.getDatFileName);

       // N�o tirar desta posi��o
       SetValorDatMemoria('Configs.TE_SO',g_oCacic.getWindowsStrId(), v_tstrCipherOpened);

       log_DEBUG('Te_So obtido: "' + g_oCacic.getWindowsStrId() +'"');

       v_scripter := 'wscript.exe';
       // A exist�ncia e bloqueio do arquivo abaixo evitar� que Cacic2.exe chame o Ger_Cols quando este estiver em funcionamento
       AssignFile(v_Aguarde,g_oCacic.getCacicPath + 'temp\aguarde_GER.txt'); {Associa o arquivo a uma vari�vel do tipo TextFile}
       {$IOChecks off}
       Reset(v_Aguarde); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
         Rewrite (v_Aguarde);

       Append(v_Aguarde);
       Writeln(v_Aguarde,'Apenas um pseudo-cookie para o Cacic2 esperar o t�rmino de Ger_Cols');
       Append(v_Aguarde);

       ChecaCipher;
       ChecaCompress;

       Executa_Ger_Cols;
       Finalizar(true);
     Except
       Begin
        log_diario('PROBLEMAS EM EXECUTA_GER_COLS! A��o: ' + v_acao_gercols+'.');
        CriaTXT(g_oCacic.getCacicPath,'ger_erro');
        Finalizar(false);
        SetValorDatMemoria('Erro_Fatal_Descricao', v_acao_gercols, v_tstrCipherOpened);
       End;
     End;
   End;

   g_oCacic.Free();
end.
