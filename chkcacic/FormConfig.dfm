object Configs: TConfigs
  Left = 164
  Top = 137
  Width = 461
  Height = 440
  Caption = 'Configura'#231#245'es do CHKCACIC'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 402
    Top = 380
    Width = 27
    Height = 12
    Caption = 'Label1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -9
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
  end
  object GroupBox2: TGroupBox
    Left = 5
    Top = 114
    Width = 444
    Height = 239
    Caption = 'Par'#226'metros Opcionais'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    object Label1: TLabel
      Left = 132
      Top = 0
      Width = 231
      Height = 13
      Caption = '(N'#227'o preencher para o CHKCACIC do NetLogon)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_te_instala_frase_sucesso: TLabel
      Left = 8
      Top = 25
      Width = 161
      Height = 13
      Caption = 'Frase para Sucesso na Instala'#231#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_te_instala_frase_insucesso: TLabel
      Left = 8
      Top = 74
      Width = 168
      Height = 13
      Caption = 'Frase para Insucesso na Instala'#231#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_te_instala_informacoes_extras: TLabel
      Left = 8
      Top = 121
      Width = 89
      Height = 13
      Caption = 'Informa'#231#245'es extras'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Edit_te_instala_frase_sucesso: TEdit
      Left = 8
      Top = 41
      Width = 427
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      TabOrder = 0
    end
    object Edit_te_instala_frase_insucesso: TEdit
      Left = 8
      Top = 89
      Width = 427
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      TabOrder = 1
    end
    object Memo_te_instala_informacoes_extras: TMemo
      Left = 8
      Top = 136
      Width = 425
      Height = 97
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
  end
  object GroupBox1: TGroupBox
    Left = 5
    Top = 16
    Width = 444
    Height = 81
    Caption = 'Par'#226'metros Obrigat'#243'rios'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object Label_ip_serv_cacic: TLabel
      Left = 80
      Top = 24
      Width = 143
      Height = 13
      Caption = 'Identificador do Servidor WEB'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_cacic_dir: TLabel
      Left = 245
      Top = 24
      Width = 103
      Height = 13
      Caption = 'Pasta para Instala'#231#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
  end
  object Edit_ip_serv_cacic: TEdit
    Left = 85
    Top = 56
    Width = 145
    Height = 21
    MaxLength = 100
    TabOrder = 0
    OnExit = Edit_ip_serv_cacicExit
  end
  object Edit_cacic_dir: TEdit
    Left = 250
    Top = 56
    Width = 121
    Height = 21
    MaxLength = 15
    TabOrder = 1
    Text = 'Cacic'
    OnExit = Edit_cacic_dirExit
  end
  object Button_Gravar: TButton
    Left = 170
    Top = 367
    Width = 121
    Height = 25
    Caption = 'Gravar Configura'#231#245'es'
    TabOrder = 4
    OnClick = Button_GravarClick
  end
  object PJVersionInfo1: TPJVersionInfo
    Left = 360
    Top = 360
  end
end
