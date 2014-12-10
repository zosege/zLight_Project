unit uWorkerLightPack;

interface

uses
  uConst, Classes, Graphics, GR32, SysUtils, Windows, Forms, Math;

type

  TWorkMode = record
    Index: Integer;
    FrameNumber: Integer;
    UserColor: TColor;
    TurnOnTime: Extended;
    UserParam: Extended;
  end;

  TLightsArray = Array of TColor;

  TWorker = class(TThread)
     constructor Create(CreateSuspended: Boolean);
  private
    { Private declarations }
    NeedRun: Boolean;
    FPS: Integer;
    resLights1: TLightsArray;
    resLights2: TLightsArray;
    tmpLights: TLightsArray;
    oldLights: TLightsArray;

    MainResLights: Boolean;

    PixelsDepth: Integer;

    Mode: TWorkMode;

    procedure SetLeftLight(TopPosition: Integer; Color: TColor);
    procedure SetTopLight(LeftPosition: Integer; Color: TColor);
    procedure SetRightLight(TopPosition: Integer; Color: TColor);
    procedure SetBottomLight(LeftPosition: Integer; Color: TColor);

    procedure SetAllLeftLight(Color: TColor);
    procedure SetAllTopLight(Color: TColor);
    procedure SetAllRightLight(Color: TColor);
    procedure SetAllBottomLight(Color: TColor);

    procedure SetAllLight(Color: TColor);

    procedure BackUpLights;
  protected
    { Protected declarations }
    DesktopCanvas: TCanvas;
    procedure CheckScreenResolution;

    procedure LightPackMode;
    procedure PartyMode;

    procedure PoliceLights;
    procedure RunLight(Reverse: Boolean);
    procedure RunLights(Reverse: Boolean; PulseWidth: Byte);
    procedure RunLine(Direction: Byte);
    procedure Rainbow(Reverse: Boolean);
    procedure CircleRainbow(Reverse: Boolean);
    procedure RunRainbow(Direction: Byte);
    procedure Strobe(Speed: Byte);
    procedure BlurStrobe(Speed: Byte);
    procedure Fire;
    procedure RandomLights;
    procedure SolidColor;
    procedure ColorTransit;
    procedure TurnOff;
  public
    { Public declarations }
    ScreenStartWidth: Integer;
    ScreenStartHeight: Integer;
    tmpBitmap: TBitmap32;

    procedure Execute; override;
    procedure Done;

    function  GetFPS: Integer;
    procedure NullFPS;

    procedure ScreenShot;
    procedure MuxLights;
    procedure OutLights;

    procedure SetPixelsDepth(aNewValue: Integer);

    procedure SetMode(aMode: Integer);
    procedure SetColor(aColor: TColor);
    procedure SetParam(aParam: Extended);
    procedure SetLEDsCount(aLeft, aTop, aRight, aBottom: Integer);

    procedure Initialize; 
  end;

var
  FPS: Integer = 0;

Function GetMaxColorBmp(B: TBitmap32; R: TRect): TColor;
Function RGB(r, g, b: Byte): TColor;
Function RainbowColor(Delta_0_1535: WORD; aReverse: Boolean): TColor;
Function MixColor(aC1, aC2: TColor; Alpha: Byte): TColor;

implementation

uses uMain, DateUtils;

Function GetMaxColorBmp(B: TBitmap32; R: TRect): TColor;
Var
  i, j, Pix: Integer;
  Er, Eg, Eb: DWORD; // ���������� ��� ������� � 16 �����. 
  C32: TColor32;
begin
  Result:= clBlack;
  Try
    Pix:= (R.Right-R.Left)*(R.Bottom-R.Top);
    if Pix <=         0 then Exit; // ������� ��������� �������
    if Pix >  4096*4096 then Exit; // ������� ������� �������

    Er:= 0; Eg:= 0; Eb:= 0;
    For j:= R.Top To R.Bottom-1 Do
      begin
        For i:= R.Left To R.Right-1 Do
          begin
            C32:=B.PixelS[i,j];
            Er:= Er + (C32 and $00FF0000) shr 16;
            Eg:= Eg + (C32 and $0000FF00) shr  8;
            Eb:= Eb + (C32 and $000000FF)       ;
          end;
      end;

    Result:= RGB(Round(Er/Pix),
                 Round(Eg/Pix),
                 Round(Eb/Pix));
  Except
    On E: Exception Do ;
  End;
end;

function RGB(r, g, b: Byte): TColor;
begin
  Result:=(r shl 0) or (g shl 8) or (b shl 16);
end;

function RainbowColor(Delta_0_1535: WORD; aReverse: Boolean): TColor;
var r, g, b: Byte;
begin
  if aReverse then
    Delta_0_1535:=1535 - Delta_0_1535;
  case Delta_0_1535 of
      0 ..  255:
      Begin
        r:=255;                 g:=Delta_0_1535;      b:=0;                    // maxR    >G    0B
      End;
    256 ..  511:
      Begin
        r:=767-Delta_0_1535;    g:=255;               b:=0;                    //   <R  maxG    0B
      End;
    512 ..  767:
      Begin
        r:=0;                   g:=255;               b:=Delta_0_1535 - 768;   //   0R  maxG    >B
      End;
    768 .. 1023:
      Begin
        r:=0;                   g:=1023-Delta_0_1535; b:=255;                  //   0R    <G  maxB
      End;
   1024 .. 1279:
      Begin
        r:=Delta_0_1535 - 1024; g:=0;                 b:=255;                  //   >R    0G  maxB
      End;
   1280 .. 1535:
      Begin
        r:=255;                 g:=0;                 b:=1535 - Delta_0_1535;  // maxR    0G    <B
      End;
  Else
    r:=0; g:=0; b:=0;
  end;
  Result:=RGB(r, g, b);
end;

function MixColor(aC1, aC2: TColor; Alpha: Byte): TColor;
begin
  aC1:=ColorToRGB(aC1);
  aC2:=ColorToRGB(aC2);
  If (Alpha = 255) or (aC1 = aC2) then
    Result:=aC1
  else If Alpha = 0 then
    Result:=aC2
  else
  Result:=RGB(
    Trunc(GetRValue(aC1)*Alpha/255 + GetRValue(aC2)*((255-Alpha)/255)),
    Trunc(GetGValue(aC1)*Alpha/255 + GetGValue(aC2)*((255-Alpha)/255)),
    Trunc(GetBValue(aC1)*Alpha/255 + GetBValue(aC2)*((255-Alpha)/255))
             );
end;

procedure TWorker.SetLeftLight(TopPosition: Integer; Color: TColor);
begin
  If LightsLeft <= 0 then Exit;

  TopPosition:=LightsLeft-1 - TopPosition;
  If TopPosition >=LightsLeft Then Exit;
  If TopPosition < 0          Then Exit;

  tmpLights[TopPosition]:=Color;
end;

procedure TWorker.SetTopLight(LeftPosition: Integer; Color: TColor);
begin
  If LightsTop <= 0 then Exit;

  LeftPosition:=LightsLeft + (LeftPosition);
  If LeftPosition >= LightsLeft+LightsTop Then Exit;
  If LeftPosition < LightsLeft            Then Exit;

  tmpLights[LeftPosition]:=Color;
end;

procedure TWorker.SetRightLight(TopPosition: Integer; Color: TColor);
begin
  If LightsRight <= 0 then Exit;

  TopPosition:=LightsLeft + LightsTop + (TopPosition);
  If TopPosition >= LightsLeft+LightsTop+LightsRight Then Exit;
  If TopPosition <  LightsLeft+LightsTop             Then Exit;

  tmpLights[TopPosition]:=Color;
end;

procedure TWorker.SetBottomLight(LeftPosition: Integer; Color: TColor);
begin
  If LightsBottom <= 0 then Exit;

  LeftPosition:=LightsLeft + LightsTop + LightsRight + (LightsBottom - LeftPosition - 1);
  If LeftPosition >= LightsAll                            Then Exit;
  If LeftPosition <  LightsLeft + LightsTop + LightsRight Then Exit;

  tmpLights[LeftPosition]:=Color;
end;

procedure TWorker.SetAllLeftLight(Color: TColor);
var i: Integer;
begin
  If LightsLeft <=0 then Exit;

  for i:=0 to LightsLeft-1 do
    tmpLights[i]:=Color;
end;

procedure TWorker.SetAllTopLight(Color: TColor);
var i: Integer;
begin
  If LightsTop <=0 then Exit;

  for i:=LightsLeft to LightsLeft+LightsTop-1 do
    tmpLights[i]:=Color;
end;

procedure TWorker.SetAllRightLight(Color: TColor);
var i: Integer;
begin
  If LightsRight <=0 then Exit;

  for i:=LightsLeft+LightsTop to LightsLeft+LightsTop+LightsRight-1 do
    tmpLights[i]:=Color;
end;

procedure TWorker.SetAllBottomLight(Color: TColor);
var i: Integer;
begin
  If LightsBottom <=0 then Exit;

  for i:=LightsLeft+LightsTop+LightsRight to LightsAll-1 do
    tmpLights[i]:=Color;
end;

procedure TWorker.SetAllLight(Color: TColor);
var i: Integer;
begin
  If LightsAll <=0 then Exit;

  for i:=0 to LightsAll-1 do
    tmpLights[i]:=Color;
end;

procedure TWorker.BackUpLights;
var i: Integer;
begin
  If LightsAll <=0 then Exit;

  If Self.MainResLights then
    for i:=0 to LightsAll-1 do
      oldLights[i]:=resLights1[i]
  else
    for i:=0 to LightsAll-1 do
      oldLights[i]:=resLights2[i];
end;

constructor TWorker.Create(CreateSuspended: Boolean);
begin
  Inherited;
  Self.FreeOnTerminate:=False;
  Self.Suspended:=CreateSuspended;
  Self.NeedRun:=True;
  Self.PixelsDepth:=30;
  Self.Priority:=tpHighest;

  Self.Mode.Index:=0;
  Self.Mode.FrameNumber:=0;
  Self.Mode.UserColor:=clWhite;
  Self.Mode.UserParam:=4;

  Self.tmpBitmap:=Nil;
  Self.DesktopCanvas:=Nil;

  Self.MainResLights:=True;

  Self.SetLEDsCount(LightsLeft, LightsTop, LightsRight, LightsBottom);

  Self.BackUpLights;
  Self.Mode.TurnOnTime:=Now;

  Initialize;
end;

procedure TWorker.Initialize;
begin
  // ������� �������, ������� ����� ������������
  Self.ScreenStartWidth:=Screen.Monitors[0].Width;
  Self.ScreenStartHeight:=Screen.Monitors[0].Height;

  If Self.DesktopCanvas <> nil then Self.DesktopCanvas.Free;
  If Self.tmpBitmap <> nil then Self.tmpBitmap.Free;

  Self.DesktopCanvas:=TCanvas.Create;
  Self.DesktopCanvas.Handle:=GetDC(0);

  tmpBitmap:=TBitmap32.Create;
  tmpBitmap.Canvas.CopyMode:=SRCCOPY;
  tmpBitmap.Width:=ScreenStartWidth;
  tmpBitmap.Height:=ScreenStartHeight;
  tmpBitmap.Clear(clBlue);
  tmpBitmap.DrawMode:=dmBlend;
end;

procedure TWorker.CheckScreenResolution;
begin
  If (Screen.Monitors[0].Width = ScreenStartWidth) and
     (Screen.Monitors[0].Height = ScreenStartHeight) then
    Exit;

  Initialize;
  frmMain.RealignPreviewWindow;
end;

procedure TWorker.Execute;
begin
  While (Self.NeedRun) Do
    Begin
      CheckScreenResolution;
      
      Inc(Self.FPS);

      If Self.Mode.Index=0 then
        Self.LightPackMode
      else
        Self.PartyMode;  

      MuxLights;
      OutLights;
  end; // while

  // ����������� ������
  tmpBitmap.Free;
  DesktopCanvas.Free;
end;

procedure TWorker.Done;
begin
  Self.NeedRun:=False;
end;

procedure TWorker.NullFPS;
begin
  Self.FPS:=0;
end;

function TWorker.GetFPS: Integer;
begin
  Result:=Self.FPS;
end;

procedure TWorker.MuxLights;
const
    TransferTime = 0.5;
    MiddleFrames = 3;
var i: Integer;
    sec: Extended;
begin
  If LightsAll <= 0 then Exit;

  sec:=86400*(Now - Self.Mode.TurnOnTime);

  If sec < TransferTime then
    Begin
      If Self.MainResLights then
        For i:=0 to LightsAll-1 do
          Self.resLights1[i]:=MixColor(Self.tmpLights[i], Self.oldLights[i], Round(255*sec/TransferTime))
      Else
        For i:=0 to LightsAll-1 do
          Self.resLights2[i]:=MixColor(Self.tmpLights[i], Self.oldLights[i], Round(255*sec/TransferTime));
    End
  Else If Self.MainResLights then
    Move((@Self.tmpLights[0])^, (@Self.resLights1[0])^, LightsAll*4)
  else
    Move((@Self.tmpLights[0])^, (@Self.resLights2[0])^, LightsAll*4);
end;

procedure TWorker.OutLights;
begin
  If Self.MainResLights then
    Lights:=@Self.resLights1[0]
  Else
    Lights:=@Self.resLights2[0];

  Self.MainResLights:=not Self.MainResLights;  
end;

procedure TWorker.ScreenShot;
begin
  tmpBitmap.Draw(tmpBitmap.Canvas.ClipRect, tmpBitmap.Canvas.ClipRect, DesktopCanvas.Handle); // ~50 ��

//  BitBlt(tmpBitmap.Canvas.Handle, 0, 0, ScreenStartWidth, ScreenStartHeight, DesktopCanvas.Handle, 0, 0, SRCCOPY); // ~70 ��

//  tmpBitmap.Canvas.CopyRect(tmpBitmap.ClipRect, DesktopCanvas, tmpBitmap.ClipRect);           // ~50 ��
end;

procedure TWorker.SetMode(aMode: Integer);
begin
  Self.BackUpLights;
  
  Self.Mode.Index:=aMode;
  Self.Mode.FrameNumber:=0;
  Self.Mode.TurnOnTime:=Now;
end;

procedure TWorker.SetColor(aColor: TColor);
begin
  Self.Mode.UserColor:=aColor;
end;

procedure TWorker.SetParam(aParam: Extended);
begin
  Self.Mode.UserParam:=aParam;
end;

procedure TWorker.SetLEDsCount(aLeft, aTop, aRight, aBottom: Integer);
begin
  LightsLeft:=aLeft;
  LightsTop:=aTop;
  LightsRight:=aRight;
  LightsBottom:=aBottom;
  LightsAll:=LightsLeft + LightsTop + LightsRight + LightsBottom;

  SetLength(Self.resLights1, LightsAll);
  SetLength(Self.resLights2, LightsAll);
  SetLength(Self.tmpLights, LightsAll);
  SetLength(Self.oldLights, LightsAll);
end;


procedure TWorker.SetPixelsDepth(aNewValue: Integer);
begin
  If aNewValue < 1 then Exit;
  If aNewValue > (ScreenStartHeight div 2) then Exit;
  
  Self.PixelsDepth:=aNewValue;
end;

procedure TWorker.LightPackMode;
var
  i: Integer;
begin
  // �������� �������� ������
  ScreenShot;

  // �������� �� ����� ������ � ������ ���������� ����������� �� ������ ������� (LightsXXX) � ������� ������� ����� (PixelsDepth),
  // ������: ������ ����� ���� ������, �������� �� ������� �������, � ��������� ������� ���� � ������ �������
  For i:=0 to Length(tmpLights)-1 do
    begin
      // ����� ���� ������
      If (LightsLeft > 0) and (i >= 0) and (i <= LightsLeft-1)  Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(0, tmpBitmap.Height - Round((i+1)*(tmpBitmap.Height/LightsLeft)), PixelsDepth, tmpBitmap.Height - Round(i*(tmpBitmap.Height/LightsLeft))));
      // ������� ���� ������
      If (LightsTop > 0) and (i >= LightsLeft) and (i <= LightsLeft+LightsTop-1) Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(Round((i-LightsLeft)*(tmpBitmap.Width/LightsTop)), 0, Round((i-LightsLeft+1)*(tmpBitmap.Width/LightsTop)), PixelsDepth));
      // ������ ���� ������
      If (LightsRight > 0) and (i >= LightsLeft+LightsTop) and (i <= LightsLeft+LightsTop+LightsRight-1) Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(tmpBitmap.Width - PixelsDepth, Round((i-LightsLeft-LightsTop)*(tmpBitmap.Height/LightsRight)), tmpBitmap.Width, Round((i-LightsLeft-LightsTop+1)*(tmpBitmap.Height/LightsRight))));
      // ������ ���� ������
      If (LightsBottom > 0) and (i >= LightsLeft+LightsTop+LightsRight) and (i <= LightsAll-1) Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(tmpBitmap.Width - Round((i-LightsLeft-LightsTop-LightsRight+1)*(tmpBitmap.Width/LightsBottom)), tmpBitmap.Height - PixelsDepth, tmpBitmap.Width - Round((i-LightsLeft-LightsTop-LightsRight)*(tmpBitmap.Width/LightsBottom)), tmpBitmap.Height));

      if not Self.NeedRun then Exit;
    end;
end;

procedure TWorker.PartyMode;
begin
  Case Self.Mode.Index of
     1: PoliceLights;               // ����������� ����
     2: RunLight(False);            // �������� ������
     3: RunLight(True);             // �������� ������ (�������� �����������)
     4: RunLights(False,            // �������� �������
          Round(Self.Mode.UserParam));
     5: RunLights(True,             // �������� ������� (�������� �����������)
          Round(Self.Mode.UserParam));
     6: RunLine(DIR_DOWN);          // �������� ����� (����)
     7: RunLine(DIR_UP);            // �������� ����� (�����)
     8: RunLine(DIR_RIGHT);         // �������� ����� (������)
     9: RunLine(DIR_LEFT);          // �������� ����� (�����)
    10: Rainbow(False);             // ������
    11: Rainbow(True);              // ������ (�������� �����������)
    12: CircleRainbow(False);       // �������� ����
    13: CircleRainbow(True);        // �������� ���� (�������� �����������)
    14: RunRainbow(DIR_DOWN);       // �������� ������ (����)
    15: RunRainbow(DIR_UP);         // �������� ������ (�����)
    16: RunRainbow(DIR_RIGHT);      // �������� ������ (������)
    17: RunRainbow(DIR_LEFT);       // �������� ������ (�����)
    18: Strobe(SPEED_SLOW);         // ���������� (�������)
    19: Strobe(SPEED_MID);          // ���������� (������)
    20: Strobe(SPEED_HIGH);         // ���������� (������)
    21: BlurStrobe(SPEED_SLOW);     // ������� ���������� (�������)
    22: BlurStrobe(SPEED_MID);      // ������� ���������� (������)
    23: BlurStrobe(SPEED_HIGH);     // ������� ���������� (������)
    24: Fire;                       // �����
    25: RandomLights;               // ��������
    26: SolidColor;                 // ������ ����
    27: ColorTransit;               // ������� ��������
    28: TurnOff;                    // ��������� �����
  Else
    TurnOff;                    
  End;
end;

procedure TWorker.PoliceLights;
Var i: Integer;
begin
  SetAllLight(clBlack);
  Case Self.Mode.FrameNumber of
    0, 2, 4: Begin
         SetAllLeftLight(clRed);
         For i:=0 to LightsTop div 3 do
           SetTopLight(i, MixColor(clRed, clBlack, Round(255 - (i/(LightsTop div 3)*255))));
         For i:=0 to LightsBottom div 3 do
           SetBottomLight(i, MixColor(clRed, clBlack, Round(255 - (i/(LightsTop div 3)*255))));
       End;
    6, 8, 10: Begin
         SetAllRightLight(clBlue);
         For i:=2*LightsTop div 3 to LightsTop-1 do
           SetTopLight(i, MixColor(clBlue, clBlack, Round(((i-2*LightsTop div 3)/(LightsTop div 3)*255))));
         For i:=2*LightsBottom div 3 to LightsBottom-1 do
           SetBottomLight(i, MixColor(clBlue, clBlack, Round(((i-2*LightsBottom div 3)/(LightsTop div 3)*255))));
       End;
    12,14,16: Begin
         For i:=LightsTop div 3 to LightsTop div 2 do
           SetTopLight(i, MixColor(Self.Mode.UserColor, clBlack, Round(((i-1*LightsTop div 3)/(LightsTop div 2 - LightsTop div 3)*255))));
         For i:=LightsTop div 2+1 to 2*LightsTop div 3 do
           SetTopLight(i, MixColor(Self.Mode.UserColor, clBlack, 255-Round(((i-1*LightsTop div 2)/(LightsTop div 2 - LightsTop div 3)*255))));
         For i:=LightsBottom div 3 to LightsBottom div 2 do
           SetBottomLight(i, MixColor(Self.Mode.UserColor, clBlack, Round(((i-1*LightsBottom div 3)/(LightsBottom div 2 - LightsBottom div 3)*255))));
         For i:=LightsBottom div 2+1 to 2*LightsBottom div 3 do
           SetBottomLight(i, MixColor(Self.Mode.UserColor, clBlack, 255-Round(((i-1*LightsBottom div 2)/(LightsBottom div 2 - LightsBottom div 3)*255))));
       End;
  End;

  Inc(Self.Mode.FrameNumber);
  If Self.Mode.FrameNumber > 25 then Self.Mode.FrameNumber:=0;

  Sleep(50);
end;

procedure TWorker.RunLight(Reverse: Boolean);
var 
    i: Integer;
begin
  If (not Reverse) then
    For i:=0 to LightsAll-1 Do
      begin
        If (LightsLeft   > 0 ) and (i >= 0                               ) and (i < LightsLeft                      ) then
          tmpLights[i]:=Integer(i = Self.Mode.FrameNumber) * Self.Mode.UserColor;
        If (LightsTop    > 0 ) and (i >= LightsLeft                      ) and (i < LightsLeft+LightsTop            ) then
          tmpLights[i]:=Integer(i = Self.Mode.FrameNumber) * Self.Mode.UserColor;
        If (LightsRight  > 0 ) and (i >= LightsLeft+LightsTop            ) and (i < LightsLeft+LightsTop+LightsRight) then
          tmpLights[i]:=Integer(i = Self.Mode.FrameNumber) * Self.Mode.UserColor;
        If (LightsBottom > 0 ) and (i >= LightsLeft+LightsTop+LightsRight) and (i < LightsAll                       ) then
          tmpLights[i]:=Integer(i = Self.Mode.FrameNumber) * Self.Mode.UserColor;
      end
   else
    For i:=0 to LightsAll-1 Do
      begin
        If (LightsLeft   > 0 ) and (i >= 0                               ) and (i < LightsLeft                      ) then
          tmpLights[i]:=Integer(i = (LightsAll - Self.Mode.FrameNumber)) * Self.Mode.UserColor;
        If (LightsTop    > 0 ) and (i >= LightsLeft                      ) and (i < LightsLeft+LightsTop            ) then
          tmpLights[i]:=Integer(i = (LightsAll - Self.Mode.FrameNumber)) * Self.Mode.UserColor;
        If (LightsRight  > 0 ) and (i >= LightsLeft+LightsTop            ) and (i < LightsLeft+LightsTop+LightsRight) then
          tmpLights[i]:=Integer(i = (LightsAll - Self.Mode.FrameNumber)) * Self.Mode.UserColor;
        If (LightsBottom > 0 ) and (i >= LightsLeft+LightsTop+LightsRight) and (i < LightsAll                       ) then
          tmpLights[i]:=Integer(i = (LightsAll - Self.Mode.FrameNumber)) * Self.Mode.UserColor;
      end;

  Inc(Self.Mode.FrameNumber);
  If Self.Mode.FrameNumber >= LightsAll then Self.Mode.FrameNumber:=0;

  Sleep(Round(32 / Self.Mode.UserParam));  
end;

procedure TWorker.RunLights(Reverse: Boolean; PulseWidth: Byte);
var
    i: Integer;
begin
  // ����� "�������� �������"

  // � ������ ����������� ��������
  If (not Reverse) then
    // ���� ����������� �� ��������� �� ����������� ������ � ������ ����� �������� ������������� ���� ����������������, ���� ������ �����
    For i:=0 to LightsAll-1 Do
      tmpLights[i]:=Integer((i mod PulseWidth) = (Self.Mode.FrameNumber mod PulseWidth)) * Self.Mode.UserColor
   else
    For i:=0 to LightsAll-1 Do
      tmpLights[i]:=Integer((PulseWidth-1)-(i mod PulseWidth) = (Self.Mode.FrameNumber mod PulseWidth)) * Self.Mode.UserColor;

  // ����������� ����� ��������
  Inc(Self.Mode.FrameNumber);
  // ������������
  If Self.Mode.FrameNumber >= PulseWidth then Self.Mode.FrameNumber:=0;
  // ����������� �����
  Sleep(40);
end;

procedure TWorker.RunLine(Direction: Byte);
begin
  // ����� "�������� �����"

  // ����� ��� �����
  SetAllLight(clBlack);

  // ���� ����������� ������ "����"
  If Direction = DIR_DOWN then
   begin
    // �������� �������� ������������� ���������������� ���� (0%-25%-50%-100%) � ������ ������ �����
    Case Self.Mode.FrameNumber of
      0, 4: SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 64));
      1, 3: SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 128));
      2:    SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 255));
    End;

    // ������ �������� �� ������� ����� ������ (7 ��) ������������� ���������������� ���� (0%-25%-50%-100%) � ������ ������ �����
    SetLeftLight  (-7+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));
    SetLeftLight  (-6+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetLeftLight  (-5+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetLeftLight  (-4+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 255));
    SetLeftLight  (-3+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetLeftLight  (-2+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetLeftLight  (-1+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));

    // ������� �������� �� ������� ����� ������ (7 ��) ������������� ���������������� ���� (0%-25%-50%-100%) � ������ ������ �����
    SetRightLight  (-7+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));
    SetRightLight  (-6+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetRightLight  (-5+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetRightLight  (-4+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 255));
    SetRightLight  (-3+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetRightLight  (-2+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetRightLight  (-1+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));

    // ������� �������� ������������� ���������������� ���� (0%-25%-50%-100%) � ������ ������ �����
    If Self.Mode.FrameNumber in [LightsLeft+1, LightsLeft+5] then
      SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack,  64));
    If Self.Mode.FrameNumber in [LightsLeft+2, LightsLeft+4] then
      SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack, 128));
    If Self.Mode.FrameNumber in [LightsLeft+3] then
      SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack, 255));
   end
  // ���� ����������� ������ "�����"
  Else If Direction = DIR_UP then
   begin
// ����� ��� ����������, ������ �������� �������� �������
    Case Self.Mode.FrameNumber of
      0, 4: SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack, 64));
      1, 3: SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack, 128));
      2: SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack, 255));
    End;

    SetLeftLight  (LightsLeft - (-7+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));
    SetLeftLight  (LightsLeft - (-6+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetLeftLight  (LightsLeft - (-5+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetLeftLight  (LightsLeft - (-4+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 255));
    SetLeftLight  (LightsLeft - (-3+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetLeftLight  (LightsLeft - (-2+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetLeftLight  (LightsLeft - (-1+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));

    SetRightLight(LightsRight - (-7+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));
    SetRightLight(LightsRight - (-6+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetRightLight(LightsRight - (-5+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetRightLight(LightsRight - (-4+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 255));
    SetRightLight(LightsRight - (-3+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetRightLight(LightsRight - (-2+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetRightLight(LightsRight - (-1+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));

    If Self.Mode.FrameNumber in [LightsLeft+1, LightsLeft+5] then
      SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 64));
    If Self.Mode.FrameNumber in [LightsLeft+2, LightsLeft+4] then
      SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 128));
    If Self.Mode.FrameNumber in [LightsLeft+3] then
      SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 255));
   end
  // ���� ����������� ������ "������"
  Else If Direction = DIR_RIGHT then
   begin
    Case Self.Mode.FrameNumber of
      0, 4: SetAllLeftLight(MixColor(Self.Mode.UserColor, clBlack, 64));
      1, 3: SetAllLeftLight(MixColor(Self.Mode.UserColor, clBlack, 128));
      2: SetAllLeftLight(MixColor(Self.Mode.UserColor, clBlack, 255));
    End;

    SetTopLight  (-7+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 64));
    SetTopLight  (-6+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetTopLight  (-5+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetTopLight  (-4+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 255));
    SetTopLight  (-3+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetTopLight  (-2+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetTopLight  (-1+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 64));

    SetBottomLight  (-7+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 64));
    SetBottomLight  (-6+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetBottomLight  (-5+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetBottomLight  (-4+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 255));
    SetBottomLight  (-3+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetBottomLight  (-2+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetBottomLight  (-1+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 64));

    If Self.Mode.FrameNumber in [LightsTop+1, LightsTop+5] then
      SetAllRightLight(MixColor(Self.Mode.UserColor, clBlack, 64));
    If Self.Mode.FrameNumber in [LightsTop+2, LightsTop+4] then
      SetAllRightLight(MixColor(Self.Mode.UserColor, clBlack, 128));
    If Self.Mode.FrameNumber in [LightsTop+3] then
      SetAllRightLight(MixColor(Self.Mode.UserColor, clBlack, 255));
   end
  // ���� ����������� ������ "�����"
  Else If Direction = DIR_LEFT then
   begin
    Case Self.Mode.FrameNumber of
      0, 4: SetAllRightLight(MixColor(Self.Mode.UserColor, clBlack, 64));
      1, 3: SetAllRightLight(MixColor(Self.Mode.UserColor, clBlack, 128));
      2: SetAllRightLight(MixColor(Self.Mode.UserColor, clBlack, 255));
    End;

    SetTopLight  (LightsTop - (-7+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));
    SetTopLight  (LightsTop - (-6+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetTopLight  (LightsTop - (-5+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetTopLight  (LightsTop - (-4+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 255));
    SetTopLight  (LightsTop - (-3+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetTopLight  (LightsTop - (-2+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetTopLight  (LightsTop - (-1+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));

    SetBottomLight(LightsBottom - (-7+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));
    SetBottomLight(LightsBottom - (-6+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetBottomLight(LightsBottom - (-5+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetBottomLight(LightsBottom - (-4+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 255));
    SetBottomLight(LightsBottom - (-3+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 192));
    SetBottomLight(LightsBottom - (-2+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 128));
    SetBottomLight(LightsBottom - (-1+Self.Mode.FrameNumber), MixColor(Self.Mode.UserColor, clBlack, 64));

    If Self.Mode.FrameNumber in [LightsTop+1, LightsTop+5] then
      SetAllLeftLight(MixColor(Self.Mode.UserColor, clBlack, 64));
    If Self.Mode.FrameNumber in [LightsTop+2, LightsTop+4] then
      SetAllLeftLight(MixColor(Self.Mode.UserColor, clBlack, 128));
    If Self.Mode.FrameNumber in [LightsTop+3] then
      SetAllLeftLight(MixColor(Self.Mode.UserColor, clBlack, 255));
   end;

  // ����������� ����� ��������
  Inc(Self.Mode.FrameNumber);
  // ������������
  If Self.Mode.FrameNumber >= Max(Max(Max(LightsLeft, LightsTop), LightsBottom), LightsRight) + 20 then Self.Mode.FrameNumber:=0;
  // ����������� �����
  Sleep(Round(160 / Self.Mode.UserParam));
end;

procedure TWorker.Rainbow(Reverse: Boolean);
begin
  // ����� "������"

  // ���� ����������� ������������� �������� ����, �� ������� ���������������� ������ ����� � � ������ �����������
  SetAllLight(RainbowColor(Self.Mode.FrameNumber, Reverse));

  // ����������� ����� ��������
  Inc(Self.Mode.FrameNumber);
  // ������������
  If Self.Mode.FrameNumber > 1535 then Self.Mode.FrameNumber:=0;
  // ����������� �����
  Sleep(Round(32 / Self.Mode.UserParam));
end;

procedure TWorker.CircleRainbow(Reverse: Boolean);
var i: Integer;
begin
  // ����� "�������� ����"

  // ���� �������� �����������, �� ���� ����������� ����������� ������ �������� �������� �� ������� �������, �� ������� � ����������� �� ������ �����
  If Reverse then
    For i:=0 to LightsAll-1 do
      tmpLights[i]:=RainbowColor((Round(1535*i/LightsAll) + Self.Mode.FrameNumber) mod 1535, False)
  // ���� ������ �����������, �� ���� ����������� ����������� ������ �������� �������� ������ ������� �������, �� ������� � ����������� �� ������ �����
  Else
    For i:=0 to LightsAll-1 do
      tmpLights[i]:=RainbowColor((Round(1535*i/LightsAll) + (1535-Self.Mode.FrameNumber)) mod 1535, False);

  // ����������� ����� ��������
  Inc(Self.Mode.FrameNumber);
  // ������������
  If Self.Mode.FrameNumber > 1535 then Self.Mode.FrameNumber:=0;
  // ����������� �����
  Sleep(Round(32 / Self.Mode.UserParam));
end;

procedure TWorker.RunRainbow(Direction: Byte);
var i: Integer;
begin
  // ����� "�������� ������"

  // ����� ��� �����
  SetAllLight(clBlack);

  // ���� ����������� ������ "����"
  If Direction = DIR_DOWN then
   begin
    If LightsLeft<=0 then Exit;
    If LightsRight<=0 then Exit;

    // ������� ������� ����� �������� ������� �� ������, � ����������� �� ������ ����� ��������
    SetAllTopLight(RainbowColor(Round(1535+Self.Mode.FrameNumber/LightsLeft*1535) mod 1535, True));

    // ����� ������� ����� ������ �������� �� ������ � ������������ �������, ��������� �� ������ ����� ��������
    For i:=0 to LightsLeft-1 do
      SetLeftLight(i, RainbowColor((Round((LightsLeft-i)/LightsLeft*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
    // ������ ������� ����� ������ �������� �� ������ � ������������ �������, ��������� �� ������ ����� ��������
    For i:=0 to LightsRight-1 do
      SetRightLight(i, RainbowColor((Round((LightsLeft-i)/LightsRight*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));

    // ������ ������� ����� �������� ������� �� ������, � ����������� �� ������ ����� ��������
    SetAllBottomLight(RainbowColor((Round(Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
   end
  // ���� ����������� ������ "�����"
  Else If Direction = DIR_UP then
   begin
// ����� ��� ����������, ������ �������� ��������
    If LightsLeft<=0 then Exit;
    If LightsRight<=0 then Exit;

    SetAllTopLight(RainbowColor(Round(Self.Mode.FrameNumber/LightsLeft*1535) mod 1535, True));

    For i:=0 to LightsLeft-1 do
      SetLeftLight(i, RainbowColor((Round((i)/LightsLeft*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
    For i:=0 to LightsRight-1 do
      SetRightLight(i, RainbowColor((Round((i)/LightsRight*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));

    SetAllBottomLight(RainbowColor((Round(1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
   end
  // ���� ����������� ������ "������"
  Else If Direction = DIR_RIGHT then
   begin
    If LightsTop<=0 then Exit;
    If LightsBottom<=0 then Exit;

    SetAllLeftLight(RainbowColor(Round(1535+Self.Mode.FrameNumber/LightsLeft*1535) mod 1535, True));

    For i:=0 to LightsTop-1 do
      SetTopLight(i, RainbowColor((Round((LightsTop-i)/LightsTop*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
    For i:=0 to LightsBottom-1 do
      SetBottomLight(i, RainbowColor((Round((LightsBottom-i)/LightsBottom*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));

    SetAllRightLight(RainbowColor((Round(Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
   end
  // ���� ����������� ������ "�����"
  Else If Direction = DIR_LEFT then
   begin
    If LightsTop<=0 then Exit;
    If LightsBottom<=0 then Exit;

    SetAllLeftLight(RainbowColor(Round(Self.Mode.FrameNumber/LightsLeft*1535) mod 1535, True));

    For i:=0 to LightsTop-1 do
      SetTopLight(i, RainbowColor((Round((i)/LightsTop*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
    For i:=0 to LightsBottom-1 do
      SetBottomLight(i, RainbowColor((Round((i)/LightsBottom*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));

    SetAllRightLight(RainbowColor((Round(1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
   end;

  // ����������� ����� ��������
  Inc(Self.Mode.FrameNumber);
  // ������������
  If Self.Mode.FrameNumber >= LightsLeft then Self.Mode.FrameNumber:=0;
  // ����������� �����
  Sleep(Round(320 / Self.Mode.UserParam));
end;

procedure TWorker.Strobe(Speed: Byte);
begin
  // ����� "����������"

  // �� ������ �������� ����� ���������� �� ���� ����������� ������ ������� (100%) ��� ������ (0%) ����������������� �����
  If Self.Mode.FrameNumber = 0 then
    SetAllLight(Self.Mode.UserColor)
  Else
    SetAllLight(clBlack);
  
  // ����������� ����� ��������
  Inc(Self.Mode.FrameNumber);
  // ������������
  If Self.Mode.FrameNumber >= 4 then Self.Mode.FrameNumber:=0;
  // � ����������� �� �������� ������, ����������� ��������
  Case Speed of
    SPEED_SLOW: Sleep(Round(480 / Self.Mode.UserParam));
    SPEED_MID : Sleep(Round(240 / Self.Mode.UserParam));
    SPEED_HIGH: Sleep(Round(120 / Self.Mode.UserParam));
  End;
end;

procedure TWorker.BlurStrobe(Speed: Byte);
begin
  // ����� "������� ����������"

  // �� ������ �������� ����� ���������� �� ���� ����������� ��������� ������� (25%->50%->75%->100%->75%->50%->25%->0%...) ����������������� �����
  Case Self.Mode.FrameNumber of
    0: SetAllLight(MixColor(Self.Mode.UserColor, clBlack, 64));
    1: SetAllLight(MixColor(Self.Mode.UserColor, clBlack, 128));
    2: SetAllLight(MixColor(Self.Mode.UserColor, clBlack, 192));
    3: SetAllLight(MixColor(Self.Mode.UserColor, clBlack, 255));
    4: SetAllLight(MixColor(Self.Mode.UserColor, clBlack, 192));
    5: SetAllLight(MixColor(Self.Mode.UserColor, clBlack, 128));
    6: SetAllLight(MixColor(Self.Mode.UserColor, clBlack, 64));
  Else
    SetAllLight(clBlack);
  End;

  // ����������� ����� ��������
  Inc(Self.Mode.FrameNumber);
  // ������������
  If Self.Mode.FrameNumber >= 10 then Self.Mode.FrameNumber:=0;

  // � ����������� �� �������� ������, ����������� ��������
  Case Speed of
    SPEED_SLOW: Sleep(Round(200 / Self.Mode.UserParam));
    SPEED_MID : Sleep(Round(100 / Self.Mode.UserParam));
    SPEED_HIGH: Sleep(Round( 50 / Self.Mode.UserParam));
  End;
end;

procedure TWorker.Fire;
var
 i: Integer;
 yellow: Integer;
begin
  // ����� "������"

  // ��������� ��� ����������
  SetAllLight(clBlack);
  Yellow:=255 - Round((Self.Mode.UserParam-1)/204*255);
  
  // � ����� �������� ����� ���������� ������� �������� ������������ ������-��������� ������ � ������ � �����
  For i:=0 to LightsLeft-1 do
    SetLeftLight((LightsLeft-1-i), MixColor(RainbowColor(Random(255-Yellow+Round(i/LightsLeft*Yellow)), False), clBlack, 255-Round(i/LightsLeft*255)));
  // � ������ �������� ����� ���������� ������� �������� ������������ ������-��������� ������ � ������ � �����
  For i:=0 to LightsRight-1 do
    SetRightLight((LightsRight-1-i), MixColor(RainbowColor(Random(255-Yellow+Round(i/LightsRight*Yellow)), False), clBlack, 255-Round(i/LightsRight*255)));
  // � ������ �������� ����� ���������� ������������ ������-��������� �����
  For i:=0 to LightsBottom-1 do
    SetBottomLight(i, RainbowColor(Random(255-Yellow), False));

  // ����������� �����
  Sleep(60);
end;

procedure TWorker.RandomLights;
begin
  // ����� "��������"

  // ��������� ��� ����������
  SetAllLight(clBlack);

  // �� ������ ������� �������� ������� ����� � �������� � ��� ���� ������������ ���� ������������ ������ �� ������
  Case Random(20) of
    0: SetLeftLight  (Random(LightsLeft  ), RainbowColor(Random(1535), False));
    1: SetTopLight   (Random(LightsTop   ), RainbowColor(Random(1535), False));
    2: SetRightLight (Random(LightsRight ), RainbowColor(Random(1535), False));
    3: SetBottomLight(Random(LightsBottom), RainbowColor(Random(1535), False));
  End;

  // ����������� �����
  Sleep(Round(500 / Self.Mode.UserParam));
end;

procedure TWorker.SolidColor;
begin
  // ����� "�������� ����"

  // ���������� ��� ���������� � ���������������� ���� � ���� ���������� ����� �������
  SetAllLight(Self.Mode.UserColor);
  Sleep(40);
end;

procedure TWorker.ColorTransit;
  procedure TransitLight(aNowColor, aNewColor: TColor; aProgress: Extended);
  var
    I: Integer;
    LeftLights, RightLights: Integer;
    LeftInt, RightInt: Integer;
    LeftFrac, RightFrac: Extended;
    LeftFirst, RightFirst: Integer;
    LeftLast, RightLast: Integer;
    begin
      // �������� ���� ������ �� ������, ����������� ��������� ���� � ������ ������ �����

      // ������ ��������� ��� ������ ������ � �������
      LeftFirst:=LightsLeft + LightsTop div 2 - 1;
      RightFirst:=LeftFirst+1;

      // ��������� ��������� ��� ������ ������ � �������
      LeftLast:=LightsLeft + LightsTop + LightsRight + LightsBottom div 2 - 1;
      RightLast:=LeftLast-1;

      // ����� ����������� � ����� � ������ �������
      LeftLights:=LightsTop div 2 + LightsLeft + LightsBottom div 2;
      RightLights:=LightsTop div 2 + LightsRight + LightsBottom div 2;

      // �������� �������� �������� ���������� ����������� ������� ��������� ����� ������ � ����� � ������ ������
      LeftInt:=Trunc(LeftLights*aProgress);
      RightInt:=Trunc(RightLights*aProgress);
      // � ������� �������� (MixColor) � ����� � ������ �������
      LeftFrac:=Frac(LeftLights*aProgress);
      RightFrac:=Frac(RightLights*aProgress);

      // ��������� ������ ������
      For i:=LeftFirst downto 0 do
        begin
          if LeftInt > 0 then
            Begin
              tmpLights[i]:=aNewColor;
              Dec(LeftInt);
            End
          Else if LeftFrac > 0 then
            Begin
              tmpLights[i]:=MixColor(aNewColor, aNowColor, Trunc(255*LeftFrac));
              LeftFrac:=0;
            End
          Else
            tmpLights[i]:=aNowColor;
        end;

      // ��������� ������ ������ (������ �����, ��������� ������ ����������� ���� � ������-������� ����)
      For i:=LightsAll-1 downto LeftLast do
        begin
          if LeftInt > 0 then
            Begin
              tmpLights[i]:=aNewColor;
              Dec(LeftInt);
            End
          Else if LeftFrac > 0 then
            Begin
              tmpLights[i]:=MixColor(aNewColor, aNowColor, Trunc(255*LeftFrac));
              LeftFrac:=0;
            End
          Else
            tmpLights[i]:=aNowColor;
        end;

      // ��������� ������� ������
      For i:=RightFirst to RightLast do
        begin
          if RightInt > 0 then
            Begin
              tmpLights[i]:=aNewColor;
              Dec(RightInt);
            End
          Else if RightFrac > 0 then
            Begin
              tmpLights[i]:=MixColor(aNewColor, aNowColor, Trunc(255*RightFrac));
              RightFrac:=0;
            End
          Else
            tmpLights[i]:=aNowColor;
        end;
    end;
const
  SleepVal     =  10; // ms   // �������� ����� �������
  NormalTime   =   6; // sec  // ������������ ��� ����� ����� � �������
  TransferTime =   2; // sec  // ������������ �������� ����� ����� � �������
  TotalColors  =   6;         // ���������� ������, ������� ����� � �������

var
  Colors: Array [0..TotalColors-1] of TColor; // ����� �������
  AllTotalFrames: Integer;                    // ����� ���������� ������ ��� ����� ������, ������������� ��� ������������ ������ � ������� ����������
  TotalFrames: Integer;                       // ���������� ������ ��� ������������� ������ ����� �������� �����, ������������� ��� ����� ���� ������ ����������
  SolidFrames: Integer;                       // ���������� ������ ��� ����� �����, �������������� �� ������ �������� ����� ������� � ��������� NormalTime
  TransferFrames: Integer;                    // ���������� ������ �������� ����� �����, �������������� �� ������ �������� ����� ������� � ��������� TransferTime

begin
  // ����� "�������� �����"

  // ������ ���������� ������
  SolidFrames:=Round(NormalTime*1000/SleepVal);
  TransferFrames:=Round(TransferTime*1000/SleepVal);
  TotalFrames:=SolidFrames + TransferFrames;
  AllTotalFrames:=TotalColors*TotalFrames;

  // ���������� ������� ������ �� ������ ���������� ������������� �����
  Colors[ 0]:=Self.Mode.UserColor;                          // ���������������� ����
  Colors[ 1]:=MixColor(Self.Mode.UserColor, clLime, 128);   // �������
  Colors[ 2]:=MixColor(Self.Mode.UserColor, clRed, 128);    // �������
  Colors[ 3]:=MixColor(Self.Mode.UserColor, clBlue, 128);   // �����
  Colors[ 4]:=MixColor(Self.Mode.UserColor, clGreen, 128);  // Ҹ���-�������
  Colors[ 5]:=MixColor(Self.Mode.UserColor, clYellow, 128); // ������

  // �� ������ �������� ����� ���������� ��� ������ ����������:
  If Self.Mode.FrameNumber mod TotalFrames < SolidFrames then           // ��������� ����� ���� ���� (��� �������� ����� �����)
    SetAllLight(Colors[Self.Mode.FrameNumber div TotalFrames])
  else if Self.Mode.FrameNumber div TotalFrames + 1 < TotalColors then  // ���������� �������� ����� �����, ������ ������� ���� �� ��������� � ������� ������
    TransitLight(Colors[Self.Mode.FrameNumber div TotalFrames], Colors[Self.Mode.FrameNumber div TotalFrames + 1], (Self.Mode.FrameNumber mod TotalFrames - SolidFrames) / TransferFrames)
  else                                                           // ���������� �������� ����� �����, ������ ������� ���� ��������� � ������� ������
    TransitLight(Colors[Self.Mode.FrameNumber div TotalFrames], Colors[0], (Self.Mode.FrameNumber mod TotalFrames - SolidFrames) / TransferFrames);

  // ����� �����
  Inc(Self.Mode.FrameNumber);
  // ������ ������ �������, ���� ����������
  If Self.Mode.FrameNumber >= AllTotalFrames then Self.Mode.FrameNumber:=0;
  // ����������� �����
  Sleep(Round(40 / Self.Mode.UserParam));
end;

procedure TWorker.TurnOff;
begin
  // ����� "���������", ������ ����������� ������ �� ��� ���������� � ���� ���������� ������� �������
  SetAllLight(clBlack);
  Sleep(40);
end;

end.
