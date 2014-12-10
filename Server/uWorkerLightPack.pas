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
  Er, Eg, Eb: DWORD; // достаточно для области в 16 Мпикс. 
  C32: TColor32;
begin
  Result:= clBlack;
  Try
    Pix:= (R.Right-R.Left)*(R.Bottom-R.Top);
    if Pix <=         0 then Exit; // слижком маленькая область
    if Pix >  4096*4096 then Exit; // слижком большая область

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
  // Создаем объекты, которые будем использовать
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

  // Освобождаем память
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
  tmpBitmap.Draw(tmpBitmap.Canvas.ClipRect, tmpBitmap.Canvas.ClipRect, DesktopCanvas.Handle); // ~50 мс

//  BitBlt(tmpBitmap.Canvas.Handle, 0, 0, ScreenStartWidth, ScreenStartHeight, DesktopCanvas.Handle, 0, 0, SRCCOPY); // ~70 мс

//  tmpBitmap.Canvas.CopyRect(tmpBitmap.ClipRect, DesktopCanvas, tmpBitmap.ClipRect);           // ~50 мс
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
  // Получаем скриншот экрана
  ScreenShot;

  // Проходим по краям экрана с учетом количества светодиодов на каждую сторону (LightsXXX) и глубины захвата краев (PixelsDepth),
  // начало: нижний левый угол экрана, движение по часовой стрелке, и вычисляем средний цвет в каждой области
  For i:=0 to Length(tmpLights)-1 do
    begin
      // Левый край экрана
      If (LightsLeft > 0) and (i >= 0) and (i <= LightsLeft-1)  Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(0, tmpBitmap.Height - Round((i+1)*(tmpBitmap.Height/LightsLeft)), PixelsDepth, tmpBitmap.Height - Round(i*(tmpBitmap.Height/LightsLeft))));
      // Верхний край экрана
      If (LightsTop > 0) and (i >= LightsLeft) and (i <= LightsLeft+LightsTop-1) Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(Round((i-LightsLeft)*(tmpBitmap.Width/LightsTop)), 0, Round((i-LightsLeft+1)*(tmpBitmap.Width/LightsTop)), PixelsDepth));
      // Правый край экрана
      If (LightsRight > 0) and (i >= LightsLeft+LightsTop) and (i <= LightsLeft+LightsTop+LightsRight-1) Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(tmpBitmap.Width - PixelsDepth, Round((i-LightsLeft-LightsTop)*(tmpBitmap.Height/LightsRight)), tmpBitmap.Width, Round((i-LightsLeft-LightsTop+1)*(tmpBitmap.Height/LightsRight))));
      // Нижний край экрана
      If (LightsBottom > 0) and (i >= LightsLeft+LightsTop+LightsRight) and (i <= LightsAll-1) Then
        tmpLights[i]:=GetMaxColorBmp(tmpBitmap, Rect(tmpBitmap.Width - Round((i-LightsLeft-LightsTop-LightsRight+1)*(tmpBitmap.Width/LightsBottom)), tmpBitmap.Height - PixelsDepth, tmpBitmap.Width - Round((i-LightsLeft-LightsTop-LightsRight)*(tmpBitmap.Width/LightsBottom)), tmpBitmap.Height));

      if not Self.NeedRun then Exit;
    end;
end;

procedure TWorker.PartyMode;
begin
  Case Self.Mode.Index of
     1: PoliceLights;               // Полицейские огни
     2: RunLight(False);            // Бегающий огонек
     3: RunLight(True);             // Бегающий огонек (обратное направление)
     4: RunLights(False,            // Бегающие огоньки
          Round(Self.Mode.UserParam));
     5: RunLights(True,             // Бегающие огоньки (обратное направление)
          Round(Self.Mode.UserParam));
     6: RunLine(DIR_DOWN);          // Бегающая линия (вниз)
     7: RunLine(DIR_UP);            // Бегающая линия (вверх)
     8: RunLine(DIR_RIGHT);         // Бегающая линия (вправо)
     9: RunLine(DIR_LEFT);          // Бегающая линия (влево)
    10: Rainbow(False);             // Радуга
    11: Rainbow(True);              // Радуга (обратное направление)
    12: CircleRainbow(False);       // Радужный круг
    13: CircleRainbow(True);        // Радужный круг (обратное направление)
    14: RunRainbow(DIR_DOWN);       // Бегающая радуга (вниз)
    15: RunRainbow(DIR_UP);         // Бегающая радуга (вверх)
    16: RunRainbow(DIR_RIGHT);      // Бегающая радуга (вправо)
    17: RunRainbow(DIR_LEFT);       // Бегающая радуга (влево)
    18: Strobe(SPEED_SLOW);         // Стробоскоп (медлено)
    19: Strobe(SPEED_MID);          // Стробоскоп (средне)
    20: Strobe(SPEED_HIGH);         // Стробоскоп (быстро)
    21: BlurStrobe(SPEED_SLOW);     // Плавный стробоскоп (медлено)
    22: BlurStrobe(SPEED_MID);      // Плавный стробоскоп (средне)
    23: BlurStrobe(SPEED_HIGH);     // Плавный стробоскоп (быстро)
    24: Fire;                       // Костёр
    25: RandomLights;               // Всполохи
    26: SolidColor;                 // Чистый цвет
    27: ColorTransit;               // Цветные переходы
    28: TurnOff;                    // Отключить ленту
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
  // Режим "Бегающие огоньки"

  // С учетом направления анимации
  If (not Reverse) then
    // Всем светодиодам на основании их порядкового номера и номера кадра анимации присваивается либо пользовательский, либо черный цвета
    For i:=0 to LightsAll-1 Do
      tmpLights[i]:=Integer((i mod PulseWidth) = (Self.Mode.FrameNumber mod PulseWidth)) * Self.Mode.UserColor
   else
    For i:=0 to LightsAll-1 Do
      tmpLights[i]:=Integer((PulseWidth-1)-(i mod PulseWidth) = (Self.Mode.FrameNumber mod PulseWidth)) * Self.Mode.UserColor;

  // Продвижение кадра анимации
  Inc(Self.Mode.FrameNumber);
  // Зацикливание
  If Self.Mode.FrameNumber >= PulseWidth then Self.Mode.FrameNumber:=0;
  // Межкадровая пауза
  Sleep(40);
end;

procedure TWorker.RunLine(Direction: Byte);
begin
  // Режим "Бегающая линия"

  // Тушим все диоды
  SetAllLight(clBlack);

  // Если направление режима "вниз"
  If Direction = DIR_DOWN then
   begin
    // Верхнему сегменту присваивается пользователський цвет (0%-25%-50%-100%) с учетом номера кадра
    Case Self.Mode.FrameNumber of
      0, 4: SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 64));
      1, 3: SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 128));
      2:    SetAllTopLight(MixColor(Self.Mode.UserColor, clBlack, 255));
    End;

    // Левому сегменту со сдвигом части диодов (7 шт) присваивается пользователський цвет (0%-25%-50%-100%) с учетом номера кадра
    SetLeftLight  (-7+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));
    SetLeftLight  (-6+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetLeftLight  (-5+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetLeftLight  (-4+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 255));
    SetLeftLight  (-3+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetLeftLight  (-2+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetLeftLight  (-1+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));

    // Правому сегменту со сдвигом части диодов (7 шт) присваивается пользователський цвет (0%-25%-50%-100%) с учетом номера кадра
    SetRightLight  (-7+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));
    SetRightLight  (-6+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetRightLight  (-5+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetRightLight  (-4+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 255));
    SetRightLight  (-3+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 192));
    SetRightLight  (-2+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack, 128));
    SetRightLight  (-1+Self.Mode.FrameNumber, MixColor(Self.Mode.UserColor, clBlack,  64));

    // Нижнему сегменту присваивается пользователський цвет (0%-25%-50%-100%) с учетом номера кадра
    If Self.Mode.FrameNumber in [LightsLeft+1, LightsLeft+5] then
      SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack,  64));
    If Self.Mode.FrameNumber in [LightsLeft+2, LightsLeft+4] then
      SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack, 128));
    If Self.Mode.FrameNumber in [LightsLeft+3] then
      SetAllBottomLight(MixColor(Self.Mode.UserColor, clBlack, 255));
   end
  // Если направление режима "вверх"
  Else If Direction = DIR_UP then
   begin
// Далее все аналогично, только сегменты меняются местами
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
  // Если направление режима "вправо"
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
  // Если направление режима "влево"
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

  // Продвижение кадра анимации
  Inc(Self.Mode.FrameNumber);
  // Зацикливание
  If Self.Mode.FrameNumber >= Max(Max(Max(LightsLeft, LightsTop), LightsBottom), LightsRight) + 20 then Self.Mode.FrameNumber:=0;
  // Межкадровая пауза
  Sleep(Round(160 / Self.Mode.UserParam));
end;

procedure TWorker.Rainbow(Reverse: Boolean);
begin
  // Режим "Радуга"

  // Всем светодиодам присваивается радужный цвет, со сдвигом пропорциональным номеру кадра и с учетом направления
  SetAllLight(RainbowColor(Self.Mode.FrameNumber, Reverse));

  // Продвижение кадра анимации
  Inc(Self.Mode.FrameNumber);
  // Зацикливание
  If Self.Mode.FrameNumber > 1535 then Self.Mode.FrameNumber:=0;
  // Межкадровая пауза
  Sleep(Round(32 / Self.Mode.UserParam));
end;

procedure TWorker.CircleRainbow(Reverse: Boolean);
var i: Integer;
begin
  // Режим "Радужный круг"

  // Если обратное направление, то всем светодиодам присваиваем полный радужный градиент по часовой стрелке, со сдвигом в зависимости от нмоера кадра
  If Reverse then
    For i:=0 to LightsAll-1 do
      tmpLights[i]:=RainbowColor((Round(1535*i/LightsAll) + Self.Mode.FrameNumber) mod 1535, False)
  // Если прямое направление, то всем светодиодам присваиваем полный радужный градиент против часовой стрелки, со сдвигом в зависимости от нмоера кадра
  Else
    For i:=0 to LightsAll-1 do
      tmpLights[i]:=RainbowColor((Round(1535*i/LightsAll) + (1535-Self.Mode.FrameNumber)) mod 1535, False);

  // Продвижение кадра анимации
  Inc(Self.Mode.FrameNumber);
  // Зацикливание
  If Self.Mode.FrameNumber > 1535 then Self.Mode.FrameNumber:=0;
  // Межкадровая пауза
  Sleep(Round(32 / Self.Mode.UserParam));
end;

procedure TWorker.RunRainbow(Direction: Byte);
var i: Integer;
begin
  // Режим "Бегающая радуга"

  // Тушим все диоды
  SetAllLight(clBlack);

  // Если направление режима "вниз"
  If Direction = DIR_DOWN then
   begin
    If LightsLeft<=0 then Exit;
    If LightsRight<=0 then Exit;

    // Верхний сегмент имеет сплошной оттенок из радуги, в зависимости от номера кадра анимации
    SetAllTopLight(RainbowColor(Round(1535+Self.Mode.FrameNumber/LightsLeft*1535) mod 1535, True));

    // Левый сегмент имеет полный градиент из радуги с вертикальным сдвигом, зависящим от номера кадра анимации
    For i:=0 to LightsLeft-1 do
      SetLeftLight(i, RainbowColor((Round((LightsLeft-i)/LightsLeft*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
    // Правый сегмент имеет полный градиент из радуги с вертикальным сдвигом, зависящим от номера кадра анимации
    For i:=0 to LightsRight-1 do
      SetRightLight(i, RainbowColor((Round((LightsLeft-i)/LightsRight*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));

    // Нижний сегмент имеет сплошной оттенок из радуги, в зависимости от номера кадра анимации
    SetAllBottomLight(RainbowColor((Round(Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
   end
  // Если направление режима "вверх"
  Else If Direction = DIR_UP then
   begin
// Далее все аналогично, просто меняются сегменты
    If LightsLeft<=0 then Exit;
    If LightsRight<=0 then Exit;

    SetAllTopLight(RainbowColor(Round(Self.Mode.FrameNumber/LightsLeft*1535) mod 1535, True));

    For i:=0 to LightsLeft-1 do
      SetLeftLight(i, RainbowColor((Round((i)/LightsLeft*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
    For i:=0 to LightsRight-1 do
      SetRightLight(i, RainbowColor((Round((i)/LightsRight*1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));

    SetAllBottomLight(RainbowColor((Round(1535+Self.Mode.FrameNumber/LightsLeft*1535)) mod 1535, True));
   end
  // Если направление режима "вправо"
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
  // Если направление режима "влево"
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

  // Продвижение кадра анимации
  Inc(Self.Mode.FrameNumber);
  // Зацикливание
  If Self.Mode.FrameNumber >= LightsLeft then Self.Mode.FrameNumber:=0;
  // Межкадровая пауза
  Sleep(Round(320 / Self.Mode.UserParam));
end;

procedure TWorker.Strobe(Speed: Byte);
begin
  // Режим "Стробоскоп"

  // На основе текущего кадра генерируем во всех светодиодах полную яркость (100%) или черный (0%) пользовательского цвета
  If Self.Mode.FrameNumber = 0 then
    SetAllLight(Self.Mode.UserColor)
  Else
    SetAllLight(clBlack);
  
  // Продвижение кадра анимации
  Inc(Self.Mode.FrameNumber);
  // Зацикливание
  If Self.Mode.FrameNumber >= 4 then Self.Mode.FrameNumber:=0;
  // В зависимости от скорости режима, межкадровая задержка
  Case Speed of
    SPEED_SLOW: Sleep(Round(480 / Self.Mode.UserParam));
    SPEED_MID : Sleep(Round(240 / Self.Mode.UserParam));
    SPEED_HIGH: Sleep(Round(120 / Self.Mode.UserParam));
  End;
end;

procedure TWorker.BlurStrobe(Speed: Byte);
begin
  // Режим "Плавный стробоскоп"

  // На основе текущего кадра генерируем во всех светодиодах различную яркость (25%->50%->75%->100%->75%->50%->25%->0%...) пользовательского цвета
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

  // Продвижение кадра анимации
  Inc(Self.Mode.FrameNumber);
  // Зацикливание
  If Self.Mode.FrameNumber >= 10 then Self.Mode.FrameNumber:=0;

  // В зависимости от скорости режима, межкадровая задержка
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
  // Режим "Костер"

  // Выключаем все светодиоды
  SetAllLight(clBlack);
  Yellow:=255 - Round((Self.Mode.UserParam-1)/204*255);
  
  // В левом сегменте ленты генерируем плавный градиент произвольных красно-оранжевых цветов в черный к верху
  For i:=0 to LightsLeft-1 do
    SetLeftLight((LightsLeft-1-i), MixColor(RainbowColor(Random(255-Yellow+Round(i/LightsLeft*Yellow)), False), clBlack, 255-Round(i/LightsLeft*255)));
  // В правом сегменте ленты генерируем плавный градиент произвольных красно-оранжевых цветов в черный к верху
  For i:=0 to LightsRight-1 do
    SetRightLight((LightsRight-1-i), MixColor(RainbowColor(Random(255-Yellow+Round(i/LightsRight*Yellow)), False), clBlack, 255-Round(i/LightsRight*255)));
  // В нижнем сегменте ленты генерируем произвольные красно-оранжевые цвета
  For i:=0 to LightsBottom-1 do
    SetBottomLight(i, RainbowColor(Random(255-Yellow), False));

  // Межкадровая пауза
  Sleep(60);
end;

procedure TWorker.RandomLights;
begin
  // Режим "Всполохи"

  // Выключаем все светодиоды
  SetAllLight(clBlack);

  // На основе рандома выбираем сегмент ленты и зажигаем в нем один произвольный диод произвольным цветом из радуги
  Case Random(20) of
    0: SetLeftLight  (Random(LightsLeft  ), RainbowColor(Random(1535), False));
    1: SetTopLight   (Random(LightsTop   ), RainbowColor(Random(1535), False));
    2: SetRightLight (Random(LightsRight ), RainbowColor(Random(1535), False));
    3: SetBottomLight(Random(LightsBottom), RainbowColor(Random(1535), False));
  End;

  // Межкадровая пауза
  Sleep(Round(500 / Self.Mode.UserParam));
end;

procedure TWorker.SolidColor;
begin
  // Режим "Сплошной цвет"

  // Выставляем все светодиоды в пользовательский цвет и даем процессору время поспать
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
      // Анимация идет сверху из центра, попиксельно опускаясь вниз к центру нижней грани

      // Первый светодиод для левого рукава и правого
      LeftFirst:=LightsLeft + LightsTop div 2 - 1;
      RightFirst:=LeftFirst+1;

      // Последний светодиод для левого рукава и правого
      LeftLast:=LightsLeft + LightsTop + LightsRight + LightsBottom div 2 - 1;
      RightLast:=LeftLast-1;

      // Всего светодиодов в левом и правом рукавах
      LeftLights:=LightsTop div 2 + LightsLeft + LightsBottom div 2;
      RightLights:=LightsTop div 2 + LightsRight + LightsBottom div 2;

      // Учитывая прогресс анимации количество светодиодов горящих полностью новым цветом в левом и правом рукава
      LeftInt:=Trunc(LeftLights*aProgress);
      RightInt:=Trunc(RightLights*aProgress);
      // и горящих частично (MixColor) в левом и правом рукавах
      LeftFrac:=Frac(LeftLights*aProgress);
      RightFrac:=Frac(RightLights*aProgress);

      // Обработка левого рукава
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

      // Обработка левого рукава (вторая часть, поскольку массив светодиодов идет с левого-нижнего угла)
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

      // Обработка правого рукава
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
  SleepVal     =  10; // ms   // задержка между кадрами
  NormalTime   =   6; // sec  // длительность без смены цвета в рукавах
  TransferTime =   2; // sec  // длительность анимации смены цвета в рукавах
  TotalColors  =   6;         // количество цветов, которые будут у рукавов

var
  Colors: Array [0..TotalColors-1] of TColor; // Цвета рукавов
  AllTotalFrames: Integer;                    // Общее количество кадров для ВСЕГО режима, расчитывается как произведение нижней и верхней переменной
  TotalFrames: Integer;                       // Количество кадров для осуществления одного цикла перехода цвета, расчитывается как сумма двух нижних переменных
  SolidFrames: Integer;                       // Колиечство кадров без смены цвета, рассчитывается на основе задержки между кадрами и константы NormalTime
  TransferFrames: Integer;                    // Колиечство кадров анимации смены цвета, рассчитывается на основе задержки между кадрами и константы TransferTime

begin
  // Режим "Переходы цвета"

  // Расчет количества кадров
  SolidFrames:=Round(NormalTime*1000/SleepVal);
  TransferFrames:=Round(TransferTime*1000/SleepVal);
  TotalFrames:=SolidFrames + TransferFrames;
  AllTotalFrames:=TotalColors*TotalFrames;

  // Подготовка массива цветов на основе выбранного пользователем цвета
  Colors[ 0]:=Self.Mode.UserColor;                          // Пользовательский цвет
  Colors[ 1]:=MixColor(Self.Mode.UserColor, clLime, 128);   // Зеленее
  Colors[ 2]:=MixColor(Self.Mode.UserColor, clRed, 128);    // Краснее
  Colors[ 3]:=MixColor(Self.Mode.UserColor, clBlue, 128);   // Синее
  Colors[ 4]:=MixColor(Self.Mode.UserColor, clGreen, 128);  // Тёмно-зеленее
  Colors[ 5]:=MixColor(Self.Mode.UserColor, clYellow, 128); // Желтее

  // На основе текущего кадра определяем что сейчас происходит:
  If Self.Mode.FrameNumber mod TotalFrames < SolidFrames then           // Постояяно горит один цвет (нет анимации смены цвета)
    SetAllLight(Colors[Self.Mode.FrameNumber div TotalFrames])
  else if Self.Mode.FrameNumber div TotalFrames + 1 < TotalColors then  // Происходит анимация смены цвета, причем текущий цвет не последний в массиве цветов
    TransitLight(Colors[Self.Mode.FrameNumber div TotalFrames], Colors[Self.Mode.FrameNumber div TotalFrames + 1], (Self.Mode.FrameNumber mod TotalFrames - SolidFrames) / TransferFrames)
  else                                                           // Происходит анимация смены цвета, причем текущий цвет последний в массиве цветов
    TransitLight(Colors[Self.Mode.FrameNumber div TotalFrames], Colors[0], (Self.Mode.FrameNumber mod TotalFrames - SolidFrames) / TransferFrames);

  // Смена кадра
  Inc(Self.Mode.FrameNumber);
  // Начало режима сначала, если необходимо
  If Self.Mode.FrameNumber >= AllTotalFrames then Self.Mode.FrameNumber:=0;
  // Межкадровая пауза
  Sleep(Round(40 / Self.Mode.UserParam));
end;

procedure TWorker.TurnOff;
begin
  // Режим "ОТКЛЮЧЕНО", просто заталкиваем черный на все светодиоды и даем процессору времени поспать
  SetAllLight(clBlack);
  Sleep(40);
end;

end.
