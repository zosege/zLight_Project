object frmMain: TfrmMain
  Left = 766
  Top = 245
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'zLightController Emulator'
  ClientHeight = 257
  ClientWidth = 377
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 29
    Height = 13
    Caption = #1055#1086#1088#1090':'
  end
  object imgPreview: TImage
    Left = 8
    Top = 32
    Width = 360
    Height = 220
  end
  object edPort: TSpinEdit
    Left = 40
    Top = 5
    Width = 52
    Height = 22
    MaxValue = 256
    MinValue = 1
    TabOrder = 0
    Value = 4
    OnChange = edPortChange
  end
  object btnStart: TButton
    Left = 96
    Top = 3
    Width = 137
    Height = 25
    Caption = #1054#1090#1082#1088#1099#1090#1100' '#1080' '#1085#1072#1095#1072#1090#1100
    TabOrder = 1
    OnClick = btnStartClick
  end
  object btnStop: TButton
    Left = 240
    Top = 3
    Width = 89
    Height = 25
    Caption = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100
    TabOrder = 2
    OnClick = btnStopClick
  end
  object cpCOM: TComPort
    BaudRate = br230400
    CustomBaudRate = 0
    Port = 3
    Parity = prNone
    StopBits = sbOneStopBit
    DataBits = 8
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    WriteBufSize = 10240
    ReadBufSize = 10240
    FlowControl.OutCtsFlow = False
    FlowControl.OutDsrFlow = False
    FlowControl.ControlDtr = dtrDisable
    FlowControl.ControlRts = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    Timeouts.RdIntervalTO = -1
    Timeouts.RdTotalTOMultiplier = 0
    Timeouts.RdTotalTOConstant = 0
    Timeouts.WrTotalTOMultiplier = 100
    Timeouts.WrTotalTOConstant = 1000
    OnRxChar = cpCOMRxChar
    Left = 8
    Top = 40
  end
  object timFPS: TTimer
    OnTimer = timFPSTimer
    Left = 48
    Top = 40
  end
end
