object Form1: TForm1
  Left = 241
  Top = 28
  ActiveControl = Edit_FraseOriginal
  BorderStyle = bsToolWindow
  Caption = 'TestaCrypt - Teste de Criptografia do Sistema CACIC'
  ClientHeight = 521
  ClientWidth = 530
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox_Conexao: TGroupBox
    Left = 5
    Top = 2
    Width = 520
    Height = 60
    Caption = 'Conex'#227'o'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -8
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object Label_CaminhoScript: TLabel
      Left = 8
      Top = 17
      Width = 179
      Height = 13
      Caption = 'Script para Teste (caminho completo):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -8
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Edit_ScriptPath: TEdit
      Left = 7
      Top = 33
      Width = 508
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      MaxLength = 100
      ParentFont = False
      TabOrder = 0
      Text = 'http://10.0.135.167/cacic2/ws/testacrypt.php'
    end
  end
  object GroupBox_TestesCliente: TGroupBox
    Left = 5
    Top = 69
    Width = 520
    Height = 152
    Caption = 'Lado Cliente'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object Label_FraseOriginal: TLabel
      Left = 8
      Top = 64
      Width = 67
      Height = 13
      Caption = 'Frase Original:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_FraseCriptografadaEnviadaEstacao: TLabel
      Left = 8
      Top = 110
      Width = 200
      Height = 13
      Caption = 'Frase Criptografada (Enviada ao Servidor):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object Label_IVStation: TLabel
      Left = 8
      Top = 20
      Width = 123
      Height = 13
      Caption = 'IV (Vetor de Inicializa'#231#227'o):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_CipherKeyStation: TLabel
      Left = 264
      Top = 20
      Width = 51
      Height = 13
      Caption = 'CipherKey:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Edit_FraseOriginal: TEdit
      Left = 8
      Top = 80
      Width = 506
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      TabOrder = 0
      OnEnter = Edit_FraseOriginalEnter
      OnKeyUp = Edit_FraseOriginalKeyUp
    end
    object Edit_FraseCriptografadaEnviadaEstacao: TEdit
      Left = 8
      Top = 125
      Width = 506
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ReadOnly = True
      TabOrder = 3
      Visible = False
      OnChange = Edit_FraseCriptografadaEnviadaEstacaoChange
    end
    object Edit_IVStation: TEdit
      Left = 8
      Top = 35
      Width = 250
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      TabOrder = 1
    end
    object Edit_CipherKeyStation: TEdit
      Left = 264
      Top = 35
      Width = 250
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      TabOrder = 2
      OnChange = Edit_CipherKeyStationChange
    end
  end
  object Button_EfetuaTeste: TButton
    Left = 87
    Top = 464
    Width = 150
    Height = 30
    Caption = 'Efetua Teste'
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = Button_EfetuaTesteClick
  end
  object Button_Finaliza: TButton
    Left = 289
    Top = 464
    Width = 150
    Height = 30
    Caption = 'Finaliza'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = Button_FinalizaClick
  end
  object GroupBox_TesteServidor: TGroupBox
    Left = 5
    Top = 229
    Width = 520
    Height = 109
    Caption = 'Lado Servidor'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    Visible = False
    object Label_IVServer: TLabel
      Left = 8
      Top = 20
      Width = 123
      Height = 13
      Caption = 'IV (Vetor de Inicializa'#231#227'o):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_CipherKeyServer: TLabel
      Left = 264
      Top = 20
      Width = 51
      Height = 13
      Caption = 'CipherKey:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_FraseCriptografadaRecebidaServidor: TLabel
      Left = 8
      Top = 66
      Width = 207
      Height = 13
      Caption = 'Frase Criptografada (Recebida no Servidor):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Edit_IVServer: TEdit
      Left = 8
      Top = 35
      Width = 250
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
      OnChange = Edit_IVServerChange
    end
    object Edit_CipherKeyServer: TEdit
      Left = 264
      Top = 35
      Width = 250
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ReadOnly = True
      TabOrder = 1
    end
    object Edit_FraseCriptografadaRecebidaServidor: TEdit
      Left = 8
      Top = 81
      Width = 506
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ReadOnly = True
      TabOrder = 2
    end
  end
  object GroupBox_Resultado: TGroupBox
    Left = 5
    Top = 346
    Width = 520
    Height = 107
    Caption = 'Resultado'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
    Visible = False
    object Label_FraseDecriptografadaDevolvidaServidor: TLabel
      Left = 8
      Top = 64
      Width = 231
      Height = 13
      Caption = 'Frase DeCriptografada (Devolvida pelo Servidor):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_OperacaoRecebidaServidor: TLabel
      Left = 8
      Top = 18
      Width = 156
      Height = 13
      Caption = 'Opera'#231#227'o Solicitada ao Servidor:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Edit_FraseDecriptografadaDevolvidaServidor: TEdit
      Left = 8
      Top = 79
      Width = 506
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
    end
    object Edit_OperacaoRecebidaServidor: TEdit
      Left = 6
      Top = 33
      Width = 506
      Height = 21
      TabStop = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ReadOnly = True
      TabOrder = 1
      OnChange = Edit_OperacaoRecebidaServidorChange
    end
  end
  object StatusBar_Mensagens: TStatusBar
    Left = 0
    Top = 502
    Width = 530
    Height = 19
    Panels = <>
  end
end
