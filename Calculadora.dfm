object frmCalculadora: TfrmCalculadora
  Left = 0
  Top = 0
  Caption = 'Calculadora Cientifica (MVC)'
  ClientHeight = 680
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  KeyPreview = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  OnResize = FormResize
  TextHeight = 17
  object pnlDisplay: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 120
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 0
    object lblExpression: TLabel
      Left = 12
      Top = 8
      Width = 476
      Height = 17
      Alignment = taRightJustify
      AutoSize = False
      Caption = ''
    end
    object lblDisplay: TLabel
      Left = 12
      Top = 32
      Width = 476
      Height = 44
      Alignment = taRightJustify
      AutoSize = False
      Caption = '0'
      Layout = tlCenter
    end
    object lblAngleMode: TLabel
      Left = 12
      Top = 88
      Width = 200
      Height = 17
      Caption = 'Angulo: Graus'
    end
    object lblMemory: TLabel
      Left = 280
      Top = 88
      Width = 208
      Height = 17
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Memoria: --'
    end
  end
  object pnlKeypad: TPanel
    Left = 0
    Top = 120
    Width = 500
    Height = 560
    Align = alClient
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 1
  end
end
