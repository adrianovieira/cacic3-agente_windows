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

unit frmLog;

interface
uses  Forms,
      StdCtrls,
      Classes,
      Controls,
      SysUtils,
      ExtCtrls,
      ComCtrls;

type
  TFormLog = class(TForm)
    MemoLog: TMemo;
    Bt_Fechar_Log: TButton;
    listLogsDisponiveis: TListView;
    staticLogsDisponiveis: TStaticText;
    staticVisualizacao: TStaticText;
    procedure Bt_Fechar_LogClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure listLogsDisponiveisClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    procedure findLogFiles;
  public
    { Public declarations }
  end;

var
  FormLog           : TFormLog;
  itemIndexAtual    : integer;
  strLogsFolderName : String;

implementation

{$R *.dfm}

Uses main;

procedure TFormLog.Bt_Fechar_LogClick(Sender: TObject);
begin
  Release;
  Close;
end;


procedure TFormLog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Release;
   Close;
end;


procedure TFormLog.listLogsDisponiveisClick(Sender: TObject);
var sl: TStringList;
begin
  if (listLogsDisponiveis.ItemIndex >= 0) then
    Begin
      sl := TStringList.Create;
      sl.Sorted := false;

      try
        MemoLog.Clear;
        sl.LoadFromFile(g_oCacic.getLocalFolder + strLogsFolderName + '\' + listLogsDisponiveis.Items[listLogsDisponiveis.ItemIndex].Caption);
        staticVisualizacao.Caption := 'Visualiza��o (' + g_oCacic.getLocalFolder + strLogsFolderName + '\' + listLogsDisponiveis.Items[listLogsDisponiveis.ItemIndex].Caption + ')';
        itemIndexAtual := listLogsDisponiveis.ItemIndex;
        MemoLog.SetSelTextBuf(PChar(sl.Text));
      finally
        sl.Free;
      end;
    End
  else
    listLogsDisponiveis.ItemIndex := itemIndexAtual;
end;

procedure TFormLog.findLogFiles;
var SearchRec : TSearchRec;
    intSearch,
    intAux    : Integer;
    listItem  : TListItem;
begin
  g_oCacic.writeDebugLog('findLogFiles - BEGIN');

  listLogsDisponiveis.Clear;

  Try
    intSearch := FindFirst(g_oCacic.getLocalFolder + strLogsFolderName + '\*.log', faAnyFile, SearchRec);

    while intSearch = 0 do
      begin
        listItem := listLogsDisponiveis.Items.Add;
        listItem.Caption := SearchRec.Name;

        listItem.SubItems.Add(DateToStr(FileDateToDateTime(FileAge(g_oCacic.getLocalFolder + strLogsFolderName + '\' + SearchRec.Name))));
        listItem.SubItems.Add(FormularioGeral.getSizeInBytes(FormularioGeral.GetFileSize(g_oCacic.getLocalFolder + strLogsFolderName +  '\' + SearchRec.Name),''));

        intSearch := FindNext(SearchRec);
      end;
    listLogsDisponiveis.ItemIndex := itemIndexAtual;
  Finally
    SysUtils.FindClose(SearchRec);
  End;

  g_oCacic.writeDebugLog('findLogFiles - END');
end;

procedure TFormLog.FormActivate(Sender: TObject);
begin
  itemIndexAtual    := 0;
  g_intStatus       := -1;
  strLogsFolderName := 'Logs';

  findLogFiles;
  listLogsDisponiveisClick(self);
end;

end.
