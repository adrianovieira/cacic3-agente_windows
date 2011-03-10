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

program col_comp;
{$R *.res}

uses
  Windows,
  SysUtils,
  Classes,
  Registry, // Utilizado em Executa_Col_Comp
  CACIC_Library in '..\CACIC_Library.pas';

var
  g_oCacic : TCACIC;

procedure Executa_Col_comp;

	function RetornaValorShareNT(ValorReg : String; LimiteEsq : String; LimiteDir : String) : String;
	var intAux, intAux2 : Integer;
	Begin
	    intAux := Pos(LimiteEsq, ValorReg) + Length(LimiteEsq);
	    if (LimiteDir = 'Fim') Then intAux2 := Length(ValorReg) - 1
	    Else intAux2 := Pos(LimiteDir, ValorReg) - intAux - 1;
	    result := Trim(Copy(ValorReg, intAux, intAux2));
	end;

var Reg_RCC : TRegistry;
    ChaveRegistro, ValorChaveRegistro, nm_compartilhamento, nm_dir_compart,
    in_senha_escrita,	in_senha_leitura, te_comentario, strTripaDados, strAux,
    cs_tipo_permissao, cs_tipo_compart  : String;
    I, intAux: Integer;
    Lista_RCC : TStringList;
Begin
  Try
    Begin
      g_oCacic.setValueToFile('Col_Comp','Inicio', g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      nm_compartilhamento := '';
      nm_dir_compart := '';
      cs_tipo_compart := ' ';
      cs_tipo_permissao := ' ';
      in_senha_leitura := '';
      in_senha_escrita := '';
      g_oCacic.writeDailyLog('Coletando informa��es de Compartilhamentos.');
      Reg_RCC := TRegistry.Create;
      Reg_RCC.LazyWrite := False;
      Lista_RCC := TStringList.Create;
      Reg_RCC.Rootkey := HKEY_LOCAL_MACHINE;
      strTripaDados := '';

      if Win32Platform = VER_PLATFORM_WIN32_NT then
      Begin  // 2k, xp, nt.
          ChaveRegistro := '\System\ControlSet001\Services\lanmanserver\Shares\';
          Reg_RCC.OpenKeyReadOnly(ChaveRegistro);
          Reg_RCC.GetValueNames(Lista_RCC);
          Reg_RCC.CloseKey;
          For I := 0 To Lista_RCC.Count - 1 Do
          Begin
             nm_compartilhamento := Lista_RCC.Strings[i];
             strAux := g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE' + ChaveRegistro + nm_compartilhamento);
             nm_dir_compart := RetornaValorShareNT(strAux, 'Path=', 'Permissions=');
             te_comentario := RetornaValorShareNT(strAux, 'Remark=', 'Type=');
             cs_tipo_compart := RetornaValorShareNT(strAux, 'Type=', 'Fim');
             if (cs_tipo_compart = '0') Then cs_tipo_compart := 'D' Else cs_tipo_compart := 'I';
             if (strTripaDados <> '') then
                strTripaDados := strTripaDados + '<REG>'; // Delimitador de REGISTRO

             strTripaDados := strTripaDados + nm_compartilhamento + '<FIELD>' +
                                              nm_dir_compart      + '<FIELD>' +
                                              cs_tipo_compart     + '<FIELD>' +
                                              te_comentario;
          end;
      end
      Else
      Begin
          ChaveRegistro := '\Software\Microsoft\Windows\CurrentVersion\Network\LanMan\';
          Reg_RCC.OpenKeyReadOnly(ChaveRegistro);
          Reg_RCC.GetKeyNames(Lista_RCC);
          Reg_RCC.CloseKey;
          For I := 0 To Lista_RCC.Count - 1 Do
          Begin
             nm_compartilhamento := Lista_RCC.Strings[i];
             Reg_RCC.OpenKey(ChaveRegistro + nm_compartilhamento, True);
             nm_dir_compart := Reg_RCC.ReadString('Path');
             te_comentario := Reg_RCC.ReadString('Remark');
             if (Reg_RCC.GetDataSize('Parm1enc') = 0) Then in_senha_escrita := '0' Else in_senha_escrita := '1';
             if (Reg_RCC.GetDataSize('Parm2enc') = 0) Then in_senha_leitura := '0' Else in_senha_leitura := '1';
             if (Reg_RCC.ReadInteger('Type') = 0) Then cs_tipo_compart := 'D' Else cs_tipo_compart := 'I';
             intAux := Reg_RCC.ReadInteger('Flags');
             Case intAux of    //http://www.la2600.org/talks/chronology/enigma/19971107.html
               401 : cs_tipo_permissao := 'S'; // Somente Leitura.
               258 : cs_tipo_permissao := 'C'; // Completo.
               259 : cs_tipo_permissao := 'D'; // Depende de senha.
             end;
             Reg_RCC.CloseKey;
             {
             strXML := strXML + '<compart>' +
                          '<nm_compartilhamento>' + nm_compartilhamento + '</nm_compartilhamento>' +
                          '<nm_dir_compart>' + nm_dir_compart + '</nm_dir_compart>' +
                          '<cs_tipo_compart>' + cs_tipo_compart + '</cs_tipo_compart>' +
                          '<cs_tipo_permissao>' + cs_tipo_permissao + '</cs_tipo_permissao>' +
                          '<in_senha_leitura>' + in_senha_leitura + '</in_senha_leitura>' +
                          '<in_senha_escrita>' + in_senha_escrita + '</in_senha_escrita>' +
                          '<te_comentario>' + te_comentario + '</te_comentario>' +
                       '</compart>';
             }
             if (strTripaDados <> '') then
                strTripaDados := strTripaDados + '<REG>'; // Delimitador de REGISTRO

             strTripaDados := strTripaDados + nm_compartilhamento + '<FIELD>' +
                                              nm_dir_compart      + '<FIELD>' +
                                              cs_tipo_compart     + '<FIELD>' +
                                              te_comentario       + '<FIELD>' +
                                              in_senha_leitura    + '<FIELD>' +
                                              in_senha_escrita    + '<FIELD>' +
                                              cs_tipo_permissao;
          end;
      end;

      Reg_RCC.Free;
      Lista_RCC.Free;


      // Obtenho do registro o valor que foi previamente armazenado
      ValorChaveRegistro := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','Compartilhamentos',g_oCacic.getLocalFolder + 'GER_COLS.inf')));
      g_oCacic.setValueToFile('Col_Comp','Fim', g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

      // Se essas informa��es forem diferentes significa que houve alguma altera��o
      // na configura��o. Nesse caso, gravo as informa��es no BD Central e, se n�o houver
      // problemas durante esse procedimento, atualizo as informa��es no registro local.
      If ((g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_COLETA_FORCADA_COMP',g_oCacic.getLocalFolder + 'GER_COLS.inf')) = 'S') or (strTripaDados <> ValorChaveRegistro)) and
         (strTripaDados <> '') Then
        g_oCacic.setValueToFile('Col_Comp','UVC', g_oCacic.enCrypt(strTripaDados), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName)
      else
        g_oCacic.setValueToFile('Col_Comp','nada', g_oCacic.enCrypt('nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

    End;
  Except
    Begin
      g_oCacic.setValueToFile('Col_Comp','nada', g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Comp','Fim', g_oCacic.enCrypt( '99999999'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
    End;
  End;
end;

const
  CACIC_APP_NAME = 'col_comp';

begin
  g_oCacic := TCACIC.Create();

  g_oCacic.setBoolCipher(true);

  if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
        Begin
          g_oCacic.setLocalFolder( g_oCacic.GetParam('LocalFolder') );

          if (g_oCacic.getLocalFolder <> '') then
            Begin
               g_oCacic.checkDebugMode;

               Try
                  Executa_Col_comp;
               Except
                  g_oCacic.setValueToFile('Col_Comp','nada', g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
               End;
               Halt(0);
            End;
        End;
   g_oCacic.Free();
end.
