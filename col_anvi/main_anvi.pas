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

unit main_anvi;

interface

uses Windows, Forms, classes, sysutils, inifiles, Registry, TLHELP32, ShellAPI,
  PJVersionInfo;
var  p_path_cacic, p_path_cacic_ini : string;

type
  Tfrm_col_anvi = class(TForm)
    PJVersionInfo1: TPJVersionInfo;
    procedure Executa_Col_Anvi;
    procedure Log_Historico(strMsg : String);
    Function  Crip(PNome: String): String;
    Function  DesCrip(PNome: String): String;
    function  SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
//    function  GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
    function  GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    function  GetValorChaveRegEdit(Chave: String): Variant;
    function  GetRootKey(strRootKey: String): HKEY;
    Function  Explode(Texto, Separador : String) : TStrings;
    Function  RemoveCaracteresEspeciais(Texto : String) : String;
    function GetVersionInfo(p_File: string):string;
    function VerFmt(const MS, LS: DWORD): string;
    function  ProgramaRodando(NomePrograma: String): Boolean;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
var
  frm_col_anvi: Tfrm_col_anvi;


implementation

{$R *.dfm}
function Tfrm_col_anvi.VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

{ TMainForm }

function Tfrm_col_anvi.GetVersionInfo(p_File: string):string;
begin
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
end;

//Para gravar no Arquivo INI...
function Tfrm_col_anvi.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    FileSetAttr (p_Path,0);
    Reg_Ini := TIniFile.Create(p_Path);
//    Reg_Ini.WriteString(frm_col_anvi.Crip(p_Secao), frm_col_anvi.Crip(p_Chave), frm_col_anvi.Crip(p_Valor));
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

//Para buscar do Arquivo INI...
//function Tfrm_col_anvi.GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
//var Reg_Ini: TIniFile;
//begin
//    FileSetAttr (p_Path,0);
//    Reg_Ini := TIniFile.Create(p_Path);
////    Result  := frm_col_anvi.DesCrip(Reg_Ini.ReadString(frm_col_anvi.Crip(p_Secao), frm_col_anvi.Crip(p_Chave), ''));
//    Result  := Reg_Ini.ReadString(p_Secao, p_Chave, '');
//    Reg_Ini.Free;
//end;
function Tfrm_col_anvi.GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
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


Function Tfrm_col_anvi.Explode(Texto, Separador : String) : TStrings;
var
    strItem : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres, I : Integer;
Begin
    ListaAuxUTILS := TStringList.Create;
    strItem := '';
    NumCaracteres := Length(Texto);
    For I := 0 To NumCaracteres Do
    If (Texto[I] = Separador) or (I = NumCaracteres) Then
    Begin
       If (I = NumCaracteres) then strItem := strItem + Texto[I];
       ListaAuxUTILS.Add(Trim(strItem));
       strItem := '';
    end
    Else strItem := strItem + Texto[I];
      Explode := ListaAuxUTILS;
end;

function Tfrm_col_anvi.GetRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

Function Tfrm_col_anvi.RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espa�o onde houver caracteres especiais
   Result := strAux;
end;

function Tfrm_col_anvi.GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    Result := '';
    ListaAuxGet := frm_col_anvi.Explode(Chave, '\');

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
               Result := frm_col_anvi.RemoveCaracteresEspeciais(s);
             end
        end;
    finally
    RegEditGet.CloseKey;
    RegEditGet.Free;
    ListaAuxGet.Free;

    end;
end;


// Simples rotinas de Criptografa��o e Descriptografa��o
// Baixadas de http://www.costaweb.com.br/forum/delphi/474.shtml
Function Tfrm_col_anvi.Crip(PNome: String): String;
Var
  TamI, TamF: Integer;
  SenA, SenM, SenD: String;
Begin
    SenA := Trim(PNome);
    TamF := Length(SenA);
    if (TamF > 1) then
      begin
        SenM := '';
        SenD := '';
        For TamI := TamF Downto 1 do
            Begin
                SenM := SenM + Copy(SenA,TamI,1);
            End;
        SenD := Chr(TamF+95)+Copy(SenM,1,1)+Copy(SenA,1,1)+Copy(SenM,2,TamF-2)+Chr(75+TamF);
      end
    else SenD := SenA;
    Result := SenD;
End;

Function Tfrm_col_anvi.DesCrip(PNome: String): String;
Var
  TamI, TamF: Integer;
  SenA, SenM, SenD: String;
Begin
    SenA := Trim(PNome);
    TamF := Length(SenA) - 2;
    if (TamF > 1) then
      begin
        SenM := '';
        SenD := '';
        SenA := Copy(SenA,2,TamF);
        SenM := Copy(SenA,1,1)+Copy(SenA,3,TamF)+Copy(SenA,2,1);
        For TamI := TamF Downto 1 do
            Begin
                SenD := SenD + Copy(SenM,TamI,1);
            End;
      end
    else SenD := SenA;
    Result := SenD;
End;

procedure Tfrm_col_anvi.Log_Historico(strMsg : String);
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
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
//       FileSetAttr (ExtractFilePath(Application.Exename) + '\cacic2.log',6); // Muda o atributo para arquivo de SISTEMA e OCULTO

   except
     Log_Historico('Erro na grava��o do log!');
   end;
end;

{
function Tfrm_col_anvi.getVersionInfo(Arquivo : String) : String;
var
   VerInfoSize, VerValueSize, Dummy : DWORD;
   VerInfo : Pointer;
   VerValue : PVSFixedFileInfo;
   V1,       // Major Version
   V2,       // Minor Version
   V3,       // Release
   V4: Word; // Build Number
begin
    Try
    messagedlg('Passo 1...',mtConfirmation,[mbok],0);
       VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
    messagedlg('Passo 2...',mtConfirmation,[mbok],0);
       GetMem(VerInfo, VerInfoSize);
    messagedlg('Passo 3...',mtConfirmation,[mbok],0);
       GetFileVersionInfo(PChar(Arquivo), 0, VerInfoSize, VerInfo);
    messagedlg('Passo 4...',mtConfirmation,[mbok],0);
       VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    messagedlg('Passo 5...',mtConfirmation,[mbok],0);
       With VerValue^ do
       begin
    messagedlg('Passo 6...',mtConfirmation,[mbok],0);
         V1 := dwFileVersionMS shr 16;
    messagedlg('Passo 7...',mtConfirmation,[mbok],0);
         V2 := dwFileVersionMS and $FFFF;
    messagedlg('Passo 8...',mtConfirmation,[mbok],0);
         V3 := dwFileVersionLS shr 16;
    messagedlg('Passo 9...',mtConfirmation,[mbok],0);
         V4 := dwFileVersionLS and $FFFF;
    messagedlg('Passo 10...',mtConfirmation,[mbok],0);
       end;
    messagedlg('Passo 11...',mtConfirmation,[mbok],0);
       FreeMem(VerInfo, VerInfoSize);
    messagedlg('Passo 12...',mtConfirmation,[mbok],0);
       Result := IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3) + '.' + IntToStr(V4);
    messagedlg('Passo 13...',mtConfirmation,[mbok],0);
    Except
    messagedlg('Passo 14...',mtConfirmation,[mbok],0);
       Result := '?.?.?.?';
    End;
end;
}


function Tfrm_col_anvi.ProgramaRodando(NomePrograma: String): Boolean;
var
  IsRunning, ContinueTest: Boolean;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  IsRunning := False;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueTest := Process32First(FSnapshotHandle, FProcessEntry32);
  while ContinueTest do
  begin
    IsRunning :=  UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(NomePrograma);
    if IsRunning then  ContinueTest := False
    else ContinueTest := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
  Result := IsRunning;
end;


procedure Tfrm_col_anvi.Executa_Col_Anvi;
var Lista1_RCO : TStringList;
    Lista2_RCO : TStrings;
    nu_versao_engine, dt_hr_instalacao, nu_versao_pattern, ChaveRegistro, te_servidor, in_ativo,
    NomeExecutavel, ValorChaveColetado, ValorChaveRegistro, strAux, strDirTrend : String;
    searchResult : TSearchRec;  // Necess�rio apenas para Win9x
begin
  Try
       nu_versao_engine   := '';
       nu_versao_pattern  := '';
       Log_Historico('* Coletando informa��es de Antiv�rus OfficeScan.');
       If Win32Platform = VER_PLATFORM_WIN32_WINDOWS Then { Windows 9x/ME }
       Begin
           ChaveRegistro := 'HKEY_LOCAL_MACHINE\Software\TrendMicro\OfficeScanCorp\CurrentVersion';
           NomeExecutavel := 'pccwin97.exe';
           dt_hr_instalacao  := frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\Install Date') + frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\Install Time');
           strDirTrend := frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\Application Path');
           If FileExists(strDirTrend + '\filter32.vxd') Then
           Begin
             // Em m�quinas Windows 9X a vers�o do engine e do pattern n�o s�o gravadas no registro. Tenho que pegar direto dos arquivos.
             Lista2_RCO := frm_col_anvi.Explode(frm_col_anvi.getVersionInfo(strDirTrend + 'filter32.vxd'), '.'); // Pego s� os dois primeiros d�gitos. Por exemplo: 6.640.0.1001  vira  6.640.
             nu_versao_engine := Lista2_RCO[0] + '.' + Lista2_RCO[1];
             Lista2_RCO.Free;
           end
           Else nu_versao_engine := '0';
           // A gambiarra para coletar a vers�o do pattern � obter a maior extens�o do arquivo lpt$vpn
           if FindFirst(strDirTrend + '\lpt$vpn.*', faAnyFile, searchResult) = 0 then
           begin
             Lista1_RCO := TStringList.Create;
             repeat Lista1_RCO.Add(ExtractFileExt(searchResult.Name));
             until FindNext(searchResult) <> 0;
             Sysutils.FindClose(searchResult);
             Lista1_RCO.Sort; // Ordeno, para, em seguida, obter o �ltimo.
             strAux := Lista1_RCO[Lista1_RCO.Count - 1];
             Lista1_RCO.Free;
             nu_versao_pattern := Copy(strAux, 2, Length(strAux)); // Removo o '.' da extens�o.
           end;
       end
       Else
       Begin  // NT a XP
           ChaveRegistro := 'HKEY_LOCAL_MACHINE\Software\TrendMicro\PC-cillinNTCorp\CurrentVersion';
           NomeExecutavel := 'ntrtscan.exe';
           dt_hr_instalacao  := frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\InstDate') + frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\InstTime');
           nu_versao_engine  := frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\Misc.\EngineZipVer');
           nu_versao_pattern := frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\Misc.\PatternVer');
           nu_versao_pattern := Copy(nu_versao_pattern, 2, Length(nu_versao_pattern)-3);
       end;
       te_servidor       := frm_col_anvi.GetValorChaveRegEdit(ChaveRegistro + '\Server');
       If (frm_col_anvi.ProgramaRodando(NomeExecutavel)) Then in_ativo := '1' Else in_ativo := '0';
       // Monto a string que ser� comparada com o valor armazenado no registro.
       ValorChaveColetado := Trim(nu_versao_engine + ';' +
                                  nu_versao_pattern  + ';' +
                                  te_servidor + ';' +
                                  dt_hr_instalacao + ';' +
                                  in_ativo);
       // Obtenho do registro o valor que foi previamente armazenado
       ValorChaveRegistro := Trim(GetValorChaveRegIni('Coleta','OfficeScan',p_path_cacic_ini));

       // Se essas informa��es forem diferentes significa que houve alguma altera��o
       // na configura��o. Nesse caso, gravo as informa��es no BD Central
       // e, se n�o houver problemas durante esse procedimento, atualizo as
       // informa��es no registro.

       If (GetValorChaveRegIni('Configs','IN_COLETA_FORCADA_ANVI',p_path_cacic_ini)='S') or (ValorChaveColetado <> ValorChaveRegistro) Then
        Begin
             frm_col_anvi.SetValorChaveRegIni('Col_Anvi','nu_versao_engine'  , nu_versao_engine  ,frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
             frm_col_anvi.SetValorChaveRegIni('Col_Anvi','nu_versao_pattern' , nu_versao_pattern ,frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
             frm_col_anvi.SetValorChaveRegIni('Col_Anvi','dt_hr_instalacao'  , dt_hr_instalacao  ,frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
             frm_col_anvi.SetValorChaveRegIni('Col_Anvi','te_servidor'       , te_servidor       ,frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
             frm_col_anvi.SetValorChaveRegIni('Col_Anvi','in_ativo'          , in_ativo          ,frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
             frm_col_anvi.SetValorChaveRegIni('Col_Anvi','ValorChaveColetado', ValorChaveColetado,frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
        end
        else frm_col_anvi.SetValorChaveRegIni('Col_Anvi', 'nada', 'nada',frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
       application.Terminate;
  Except
    frm_col_anvi.SetValorChaveRegIni('Col_Anvi', 'nada', 'nada',frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
    application.Terminate;
  End;
end;
procedure Tfrm_col_anvi.FormCreate(Sender: TObject);
var tstrTripa1 : TStrings;
    intAux     : integer;
begin
     //Pegarei o n�vel anterior do diret�rio, que deve ser, por exemplo \Cacic, para leitura do cacic2.ini
     tstrTripa1 := explode(ExtractFilePath(Application.Exename),'\');
     p_path_cacic := '';
     For intAux := 0 to tstrTripa1.Count -2 do
       begin
         p_path_cacic := p_path_cacic + tstrTripa1[intAux] + '\';
       end;
     p_path_cacic_ini := p_path_cacic + 'cacic2.ini';
     Application.ShowMainForm := false;

     Try
        Executa_Col_Anvi;
     Except
        frm_col_anvi.SetValorChaveRegIni('Col_Anvi', 'nada', 'nada',frm_col_anvi.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_anvi.ini');
        application.Terminate;
     End;
end;

end.
