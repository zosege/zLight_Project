object frmLightsCountDlg: TfrmLightsCountDlg
  Left = 1315
  Top = 354
  BorderStyle = bsDialog
  Caption = #1063#1080#1089#1083#1086' '#1089#1074#1077#1090#1086#1076#1080#1086#1076#1086#1074
  ClientHeight = 239
  ClientWidth = 241
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object labText1: TLabel
    Left = 96
    Top = 48
    Width = 49
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = #1057#1074#1077#1088#1093#1091':'
  end
  object labText4: TLabel
    Left = 96
    Top = 96
    Width = 49
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = #1057#1085#1080#1079#1091':'
  end
  object labText3: TLabel
    Left = 160
    Top = 72
    Width = 49
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = #1057#1087#1088#1072#1074#1072':'
  end
  object labText2: TLabel
    Left = 32
    Top = 72
    Width = 49
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = #1057#1083#1077#1074#1072':'
  end
  object labPromt: TLabel
    Left = 8
    Top = 8
    Width = 225
    Height = 33
    Alignment = taCenter
    AutoSize = False
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1089#1074#1077#1090#1086#1076#1080#1086#1076#1086#1074' '#1076#1083#1103' '#1082#1072#1078#1076#1086#1081' '#1089#1090#1086#1088#1086#1085#1099' '#1101#1082#1088#1072#1085#1072':'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    WordWrap = True
  end
  object labTotal: TLabel
    Left = 32
    Top = 154
    Width = 201
    Height = 13
    AutoSize = False
    Caption = #1048#1090#1086#1075#1086': ? '#1089#1074#1077#1090#1086#1076#1080#1086#1076#1086#1074
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowFrame
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object bevSeparator: TBevel
    Left = 8
    Top = 144
    Width = 225
    Height = 2
    Shape = bsTopLine
  end
  object shBottomRect: TShape
    Left = 0
    Top = 198
    Width = 241
    Height = 41
    Align = alBottom
    Pen.Color = clWhite
  end
  object labPower: TLabel
    Left = 32
    Top = 174
    Width = 201
    Height = 13
    AutoSize = False
    Caption = #1055#1080#1082#1086#1074#1072#1103' '#1084#1086#1097#1085#1086#1089#1090#1100': ? '#1042#1090
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 4227327
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object imgLEDs: TImage
    Left = 8
    Top = 152
    Width = 105
    Height = 105
    Visible = False
  end
  object imgPower: TImage
    Left = 8
    Top = 166
    Width = 105
    Height = 105
    Visible = False
  end
  object edLeft: TSpinEdit
    Left = 32
    Top = 88
    Width = 49
    Height = 22
    MaxValue = 512
    MinValue = 0
    TabOrder = 0
    Value = 40
    OnChange = edLeftChange
  end
  object edTop: TSpinEdit
    Left = 96
    Top = 64
    Width = 49
    Height = 22
    MaxValue = 512
    MinValue = 0
    TabOrder = 1
    Value = 62
    OnChange = edLeftChange
  end
  object edRight: TSpinEdit
    Left = 160
    Top = 88
    Width = 49
    Height = 22
    MaxValue = 512
    MinValue = 0
    TabOrder = 2
    Value = 40
    OnChange = edLeftChange
  end
  object edBottom: TSpinEdit
    Left = 96
    Top = 112
    Width = 49
    Height = 22
    MaxValue = 512
    MinValue = 0
    TabOrder = 3
    Value = 62
    OnChange = edLeftChange
  end
  object btnOk: TBitBtn
    Left = 48
    Top = 208
    Width = 75
    Height = 25
    Caption = #1054#1050
    Default = True
    TabOrder = 4
    OnClick = btnOkClick
    Glyph.Data = {
      36030000424D3603000000000000360000002800000010000000100000000100
      18000000000000030000120B0000120B00000000000000000000E6F4F6E6F4F6
      E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4
      F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6CAE4D882BA8D388B3D24
      792824762838833D82B48DCAE1D8E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6
      E6F4F6A4D1B12F8E3442A05287CA9A9BD3AB9BD2AB83C7963D974C2E7B33A4C9
      B0E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6A4D4B4248F296DBE83A8DBB587CC9866
      BC7D64BA7C86CB98A5D9B466B77D237226A4C9B0E6F4F6E6F4F6E6F4F6CBE8DC
      31A04372C287A8DBB260BC775CBA7359B87059B56F58B56F5BB774A5D9B369B8
      7F2F7E34CBE3D9E6F4F6E6F4F683CC9B4CB064AADDB464C1795FBE7175C585D4
      ECD98ACD9956B66C58B56E5CB774A6DAB4419B4E82B68CE6F4F6E6F4F63BB45B
      91D29F8DD49A64C37479C987F2FAF4FFFFFFFDFEFD86CB9657B76D5BB97285CC
      9787C79A388A3DE6F4F6E6F4F626B048A6DCAF70CA7F73CA80F0F9F1FFFFFFEB
      F7EDFFFFFFFBFDFC88CD965BB97167BE7DA0D7AF227E26E6F4F6E6F4F62DB651
      A7DDB172CC8066C773B0E1B7D2EED663C170B8E3BFFFFFFFFBFDFC8CD09969C1
      7EA1D7AE228326E6F4F6E6F4F647C36B95D7A191D79B69C97664C66F61C46E61
      C36F61C26FB9E4C0FFFFFFE3F4E68BD1998BCE9D39973EE6F4F6E6F4F68ED9A8
      57BF70AFE1B76DCC7A68C87265C77063C56E62C46E63C471B6E3BE6FC77EACDF
      B548A95E82C28FE6F4F6E6F4F6CFEDE146C4657FCE90AEE1B56DCC7A6ACA7668
      C87268C87468C8756BC979ACDFB476C48931A041CBE7DBE6F4F6E6F4F6E6F4F6
      AEE5C53CC25C7FCE90AFE1B792D89D77CE8377CE8392D89DAEE1B578C88B26A1
      3AA5D8B8E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6AFE5C547C76859C27496D7A3A5
      DCAEA5DCAE95D6A150B96A33B254A5DCBBE6F4F6E6F4F6E6F4F6E6F4F6E6F4F6
      E6F4F6E6F4F6CFEEE292DDAB51C9713AC05C36BE5A45C1698AD6A6CCEBDFE6F4
      F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6
      F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6}
  end
  object btnCancel: TBitBtn
    Left = 128
    Top = 208
    Width = 75
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 5
    OnClick = btnCancelClick
    Glyph.Data = {
      36030000424D3603000000000000360000002800000010000000100000000100
      18000000000000030000120B0000120B00000000000000000000E6F4F6E6F4F6
      E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4
      F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F61112F10000F10000F100
      00F10000EF0000EF0000ED1011EEE6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6
      E6F4F61112F51A20F53C4CF93A49F83847F83545F83443F73242F7141BF11516
      EEE6F4F6E6F4F6E6F4F6E6F4F6E6F4F61112F71D23F94453FA2429F91212F70F
      0FF60C0CF50909F5161BF53343F7141BF11516EEE6F4F6E6F4F6E6F4F61112F9
      1F25FA4A58FB4247FBC9C9FD3B3BF91313F71010F63333F7C5C5FD3035F73444
      F7141BF21516EEE6F4F6E6F4F60000FB4F5DFD3237FBCBCBFEF2F2FFEBEBFE3B
      3BF93939F8EAEAFEF1F1FEC5C5FD181DF63343F70000EFE6F4F6E6F4F60000FD
      525FFD2828FC4747FCECECFFF2F2FFECECFFECECFEF1F1FFEAEAFE3434F70B0B
      F53545F80000EFE6F4F6E6F4F60000FD5562FE2C2CFD2929FC4848FCEDEDFFF2
      F2FFF2F2FFECECFE3A3AF91212F70F0FF63848F80000F1E6F4F6E6F4F60000FD
      5764FE3030FD2D2DFD4B4BFCEDEDFFF2F2FFF2F2FFECECFF3D3DF91616F81313
      F73C4BF80000F1E6F4F6E6F4F60000FF5A67FE3333FE5050FDEDEDFFF3F3FFED
      EDFFEDEDFFF2F2FFECECFE3E3EFA1717F83F4EF90000F1E6F4F6E6F4F60000FF
      5B68FF4347FECFCFFFF3F3FFEDEDFF4C4CFC4A4AFCECECFFF2F2FFCACAFE2A2F
      FA4251FA0000F3E6F4F6E6F4F61213FE262BFF5D6AFF585BFFCFCFFF5252FE2F
      2FFD2C2CFD4B4BFCCCCCFE484CFB4957FB1D23F91213F5E6F4F6E6F4F6E6F4F6
      1213FE262BFF5D6AFF4347FF3434FE3232FE3030FD2D2DFD383CFC4F5DFC1F25
      FA1213F7E6F4F6E6F4F6E6F4F6E6F4F6E6F4F61213FE262BFF5C69FF5B68FF5A
      67FE5865FE5663FE5461FE2227FC0C0CFBE6F4F6E6F4F6E6F4F6E6F4F6E6F4F6
      E6F4F6E6F4F61112FE0000FF0000FF0000FF0000FD0000FD0000FD1112FCE6F4
      F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6
      F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6E6F4F6}
  end
end
