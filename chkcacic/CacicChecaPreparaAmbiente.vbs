'==========================================================================================================================================================
' C�digo VBScript para Checagem e Prepara��o do Ambiente Computacional Baseado no Sistema Operacional MS-Windows para Instala��o do Sistema
' CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais
'
' NOME: CacicChecaPreparaAmbiente.vbs
'
' AUTOR: Anderson Peterle - anderson.peterle@previdencia.gov.br
' DATA : 21/09/2009 01:36AM
'
' OBJETIVOS: 
' 1) Verificar a exist�ncia do programa execut�vel referente ao processo Mantenedor de Integridade do Sistema CACIC nas esta��es de trabalho com MS-Windows
' 2) Caso o objetivo 1 seja positivo, exclus�o de todos os arquivos e chaves de execu��o autom�tica (Registry) referentes �s vers�es antigas do CACIC
'
' EXECU��O: cscript CacicChecaPreparaAmbiente.vbs <PastaCheckCacic> //B
'==========================================================================================================================================================

' Crio o objeto para os trabalhos com arquivos e diret�rios
Set fileSys  = CreateObject("Scripting.FileSystemObject")

' Verifico a exist�ncia do execut�vel do Servi�o para Manuten��o de Integridade do Agente Principal
' Caso n�o exista o execut�vel do servi�o, entendo que a esta��o cont�m alguma vers�o antiga do CACIC
If not fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\cacicsvc.exe") Then
	' Crio um objeto para acesso ao Registry
	Set WSHShell = CreateObject("WScript.Shell")

	' Exclus�o da chave para execu��o autom�tica do Agente Principal (cacic2.exe)	
	If RegExist("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\cacic2") Then 
		WSHShell.RegDelete( "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\cacic2" )
	End If

	' Exclus�o da chave para execu��o autom�tica do Agente Verificador de Integridade (chksis.exe)	
	If RegExist("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine") Then 	
		WSHShell.RegDelete( "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine" )
	End If
		
	' Exclus�o dos arquivos que comp�em o Verificador de Integridade do Sistema (ChkSis)
	' O "TRUE" � para confirmar a exclus�o de arquivos ReadOnly
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.exe") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.exe"),TRUE	
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.ini") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.ini"),TRUE	
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.dat") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.dat"),TRUE	
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.log") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.log"),TRUE				

    
	' Exclus�o da pasta de instala��o do CACIC
	Set objArgs = WScript.Arguments
	if objArgs.Count > 0 Then 
		strCacicFolder = GetINIString("Cacic2", "cacic_dir", "Cacic", objArgs(0))	
		if fileSys.FolderExists(Left(fileSys.GetSpecialFolder(0), 3) & strCacicFolder) Then
			fileSys.DeleteFolder(Left(fileSys.GetSpecialFolder(0), 3) & strCacicFolder)		
		End If
	End If
End If

' Fun��o para verifica��o de exist�ncia de chave do Registry
Function RegExist(Key)
	On Error Resume Next
	Set WshShellChecaReg=Wscript.CreateObject("Wscript.Shell")
	Kexist=WshShellChecaReg.RegRead(Key)
	If Err.number=0 then
		RegExist=True
	Else
		RegExist=False
	End If
End Function

' Fun��o para leitura de chave em arquivo INI
Function GetINIString(Section, KeyName, Default, FileName)
  Dim INIContents, PosSection, PosEndSection, sContents, Value, Found
  
  ' Carrega o conte�do do arquivo INI em uma string
  INIContents = GetFile(FileName)

  ' Procura pela se��o
  PosSection = InStr(1, INIContents, "[" & Section & "]", vbTextCompare)
  If PosSection>0 Then
    ' Caso a se��o exista, encontra o seu fim
    PosEndSection = InStr(PosSection, INIContents, vbCrLf & "[")
    ' Se for a �ltima se��o...
    If PosEndSection = 0 Then PosEndSection = Len(INIContents)+1
    
    ' Separa os conte�dos da se��o
    sContents = Mid(INIContents, PosSection, PosEndSection - PosSection)

    If InStr(1, sContents, vbCrLf & KeyName & "=", vbTextCompare)>0 Then
      Found = True
      ' Separa valor de chave
      Value = SeparateField(sContents, vbCrLf & KeyName & "=", vbCrLf)
    End If
  End If
  If isempty(Found) Then Value = Default
  GetINIString = Value
End Function

' Separa um campo entre Inicio e Fim
Function SeparateField(ByVal sFrom, ByVal sStart, ByVal sEnd)
  Dim PosB: PosB = InStr(1, sFrom, sStart, 1)
  If PosB > 0 Then
    PosB = PosB + Len(sStart)
    Dim PosE: PosE = InStr(PosB, sFrom, sEnd, 1)
    If PosE = 0 Then PosE = InStr(PosB, sFrom, vbCrLf, 1)
    If PosE = 0 Then PosE = Len(sFrom) + 1
    SeparateField = Mid(sFrom, PosB, PosE - PosB)
  End If
End Function


' Fun��o para leitura de um arquivo
Function GetFile(ByVal FileName)
  Dim FS: Set FS = CreateObject("Scripting.FileSystemObject")
  ' Caso n�o seja informada a pasta, usa a do MS-Windows
  If InStr(FileName, ":\") = 0 And Left (FileName,2)<>"\\" Then 
    FileName = FS.GetSpecialFolder(0) & "\" & FileName
  End If
  On Error Resume Next

  GetFile = FS.OpenTextFile(FileName).ReadAll
End Function