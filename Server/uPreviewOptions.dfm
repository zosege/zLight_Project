object frmPreview: TfrmPreview
  Left = 282
  Top = 218
  AlphaBlendValue = 0
  BorderStyle = bsNone
  ClientHeight = 637
  ClientWidth = 1289
  Color = clBlack
  TransparentColorValue = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnClick = FormClick
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object imgLogo: TImage
    Left = 576
    Top = 296
    Width = 128
    Height = 128
    OnClick = FormClick
  end
  object pbHider: TProgressBar
    Left = 560
    Top = 448
    Width = 150
    Height = 17
    Smooth = True
    TabOrder = 0
  end
  object timTimeout: TTimer
    Enabled = False
    Interval = 10
    OnTimer = timTimeoutTimer
    Left = 216
    Top = 80
  end
end
