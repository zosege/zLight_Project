unit uMain;

//{$define DEBUG}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Math, StdCtrls, pngimage, GR32, Comms,
  uWorkerLightPack, uConst, Registry, CoolTrayIcon, Menus, XPMan, ComCtrls,
  Spin, uFullscreenWatcher, uCOM;

type
  TfrmMain = class(TForm)
    timFPSCalc: TTimer;
    timTimeout: TTimer;
    dlgColor: TColorDialog;
    trayIcon: TCoolTrayIcon;
    pmPopup: TPopupMenu;
    miRestore: TMenuItem;
    miMinimize: TMenuItem;
    miSep1: TMenuItem;
    miExit: TMenuItem;
    miMode: TMenuItem;
    miSep2: TMenuItem;
    xpTheme: TXPManifest;
    miSetColor: TMenuItem;
    miPort: TMenuItem;
    sbStatus: TStatusBar;
    gbPreview: TGroupBox;
    cbLivePreview: TCheckBox;
    gbMode: TGroupBox;
    cbMode: TComboBox;
    labColorText: TLabel;
    shColor: TShape;
    labParamText: TLabel;
    edUserParam: TSpinEdit;
    gbCaptureParams: TGroupBox;
    cbDWMActive: TCheckBox;
    labPixelsDepthText: TLabel;
    edPixelsDepth: TSpinEdit;
    gbLEDsParams: TGroupBox;
    cbGamma: TCheckBox;
    labMaxLevelText: TLabel;
    edMaxLevel: TSpinEdit;
    btnDbg: TButton;
    gbApplicationParams: TGroupBox;
    cbAutoRun: TCheckBox;
    imgPreview: TImage;
    cbRunMinimized: TCheckBox;
    labComPortText: TLabel;
    cbComPort: TComboBox;
    btnEnterGamma: TButton;
    dlgOpen: TOpenDialog;
    procedure timFPSCalcTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure cbModeChange(Sender: TObject);
    procedure shColorMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure cbAutoRunClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure trayIconDblClick(Sender: TObject);
    procedure trayIconStartup(Sender: TObject; var ShowMainForm: Boolean);
    procedure miSetColorClick(Sender: TObject);
    procedure miSep1Click(Sender: TObject);
    procedure cbModeDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure miSep1DrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure miSep1MeasureItem(Sender: TObject; ACanvas: TCanvas;
      var Width, Height: Integer);
    procedure miSep2Click(Sender: TObject);
    procedure edPixelsDepthChange(Sender: TObject);
    procedure edPixelsDepthEnter(Sender: TObject);
    procedure edPixelsDepthExit(Sender: TObject);
    procedure cbDWMActiveClick(Sender: TObject);
    procedure btnDbgClick(Sender: TObject);
    procedure sbStatusDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
      const Rect: TRect);
    procedure edUserParamChange(Sender: TObject);
    procedure btnDbgExit(Sender: TObject);
    procedure cbComPortChange(Sender: TObject);
    procedure pmPopupPopup(Sender: TObject);
    procedure btnEnterGammaClick(Sender: TObject);
    procedure cbGammaClick(Sender: TObject);
    procedure edMaxLevelChange(Sender: TObject);
    procedure sbStatusMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    procedure WMHotKey(var Msg: TWMHotKey); message WM_HOTKEY;
  public
    { Public declarations }
    procedure RealignPreviewWindow;

    procedure OnIdle(Sender:TObject; var Done:boolean);
    procedure ApplicationMinimize(Sender: TObject);
    procedure ApplicationRestore(Sender: TObject);

    procedure FullscreenStarted(aHandle: THandle; aRect: TRect);
    procedure FullscreenStopped(aHandle: THandle; aRect: TRect);

    procedure SetLinkState(aState: TLinkState; aPort: Byte; aBaudRate: TBaudRate);
    procedure SetLatency(aLatency: Extended);
    procedure SetConfig(aConfig: Integer);
    procedure SetErrors(aDelta: Integer);
    procedure SetPower(aCurrent: Extended);
  end;


procedure LoadSettings;
procedure SaveSettings;
procedure DoAutoRun;
procedure InitializePopupMenu;
procedure LoadModeIcons;
function WSAErrorToTextSystem(ErrCode: DWORD): String;
function GetCOMPortIndex(aPort: Byte): Integer;

function BaudRateToInt(aBaudRate: TBaudRate): Integer;
function IntToBaudRate(aInteger: Integer): TBaudRate;

procedure RegisterHotKeys;
procedure UnRegisterHotKeys;

Var
  frmMain: TfrmMain;
  Worker: TWorker = Nil;
  FullscreenWatcher: TFullScreenWatcher = Nil;
  Communication: TCommunication = Nil;

  ApplicationMinimized: Boolean = False;

  ModeIcons: Array [0..TotalModeIcons-1] of TPNGObject;
  LogoIcon: TPNGObject;
  LogoBlackIcon: TPNGObject;
  Icon128Icon: TPNGObject;

  iconConnectGreen: TPNGObject;
  iconConnectRed: TPNGObject;
  iconConnectYellow: TPNGObject;
  iconLatency: TPNGObject;
  iconLeds: TPNGObject;
  iconError: TPNGObject;
  iconFullscreen: TPNGObject;
  iconPower: TPNGObject;

implementation

uses uPreviewOptions, uLightsCountDlg;

{$R *.dfm}
{$R icons.res}

procedure TfrmMain.timFPSCalcTimer(Sender: TObject);
var fps: Integer;
begin
  if Worker = nil then exit;

  fps:=Worker.GetFPS;
  If fps > 0 then
    begin
      SetLatency(timFPSCalc.Interval/fps);
      Worker.NullFPS;
    end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
Struc:    _SYSTEM_INFO;
begin
  Randomize;

  Application.OnIdle:=OnIdle;
  Application.OnMinimize:=ApplicationMinimize;
  Application.OnRestore:=ApplicationRestore;

  // Последнее ядро, низший приоритет
  GetSystemInfo(Struc);
  SetProcessAffinityMask(GetCurrentProcess, 1 shl (Struc.dwNumberOfProcessors-1));
  SetPriorityClass(GetCurrentProcess, IDLE_PRIORITY_CLASS);

  // Потоки
  // Генерерующий цвета светодиодов
  Worker:=TWorker.Create(False);
  // Следящий за полноэкранными приложениями
  FullscreenWatcher:=TFullScreenWatcher.Create(False);
  FullscreenWatcher.SetEvents(FullscreenStarted, FullscreenStopped);
  // Для связи
  Communication:=TCommunication.Create(False);
  Communication.SetOnProcs(SetLinkState, SetErrors);

  LoadSettings;
  LoadModeIcons;

  // Настройка потока связи
  Communication.SetGamma(cbGamma.Checked);
  Communication.SetMaxLevel(edMaxLevel.Value);

  RealignPreviewWindow;

  InitializePopupMenu;

  SetConfig(LightsAll);

  RegisterHotKeys;

  // Дадим приложению нормально свалить с экрана
  Application.ProcessMessages;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  Worker.Done;
  Worker.Free;

  FullscreenWatcher.Done;
  FullscreenWatcher.Free;

  Communication.Done;
  Communication.Free;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Try
    SaveSettings;
  Except
    ON E: Exception Do ;
  End;
  UnRegisterHotKeys;
end;


procedure TfrmMain.OnIdle(Sender:TObject; var Done:boolean);
var
  i: Integer;
  tmpR, tmpG, tmpB: Byte;
  Power: Extended;
  B: TBitmap;
  localLights: PColor;
const
  LEDMaxPower = 0.02;{A}
begin
  Done:=True;
  Power:=-1;
  If ApplicationMinimized then Exit; // свернутое нет смысла обновлять
  
  If not cbLivePreview.Checked then
    Begin
      imgPreview.Canvas.Brush.Color:=clBtnFace;
      imgPreview.Canvas.FillRect(imgPreview.Canvas.ClipRect);
      if Icon128Icon <> Nil then
        imgPreview.Canvas.Draw((imgPreview.Width - Icon128Icon.Width) div 2, (imgPreview.Height - Icon128Icon.Height) div 2, Icon128Icon);

      Power:=0;
      localLights:=Lights;
      For i:=0 to LightsAll-1 do
        begin
          tmpR:=Round(Byte(localLights^ shr  0)/255*edMaxLevel.Value);
          tmpG:=Round(Byte(localLights^ shr  8)/255*edMaxLevel.Value);
          tmpB:=Round(Byte(localLights^ shr 16)/255*edMaxLevel.Value);
          If cbGamma.Checked then
            begin
              tmpR:=gammaR[tmpR];
              tmpG:=gammaG[tmpG];
              tmpB:=gammaB[tmpB];
            end;

          Power:=Power + tmpR/255*LEDMaxPower + tmpG/255*LEDMaxPower + tmpB/255*LEDMaxPower;
          Inc(localLights);
        end;
    End
  Else
    Begin
      B:=Nil;
      Try
        B:=TBitmap.Create;
        B.Width:=imgPreview.Width;
        B.Height:=imgPreview.Height;
        B.Canvas.Brush.Color:=clBlack;
        B.Canvas.FillRect(B.Canvas.ClipRect);

        if LogoIcon <> Nil then
          B.Canvas.Draw((B.Width - LogoIcon.Width) div 2, (B.Height - LogoIcon.Height) div 2, LogoIcon);

        Power:=0;
        localLights:=Lights;
        For i:=0 to LightsAll-1 do
          begin
            tmpR:=Round(Byte(localLights^ shr  0)/255*edMaxLevel.Value);
            tmpG:=Round(Byte(localLights^ shr  8)/255*edMaxLevel.Value);
            tmpB:=Round(Byte(localLights^ shr 16)/255*edMaxLevel.Value);
            If cbGamma.Checked then
              begin
                tmpR:=gammaR[tmpR];
                tmpG:=gammaG[tmpG];
                tmpB:=gammaB[tmpB];
              end;
            Power:=Power + tmpR/255*LEDMaxPower + tmpG/255*LEDMaxPower + tmpB/255*LEDMaxPower;
            Inc(localLights);

            B.Canvas.Brush.Color:=RGB(tmpR, tmpG, tmpB);
            // Левое поле
            If (LightsLeft > 0) and (i >= 0) and (i <= LightsLeft-1) Then
              B.Canvas.FillRect(Rect(0, B.Height - LEDPreviewSize - Round((i+1)*((B.Height - LEDPreviewSize*2) / LightsLeft)), LEDPreviewSize, B.Height - LEDPreviewSize - Round((i)*((B.Height-LEDPreviewSize*2) / LightsLeft))));
            // Верхнее поле
            If (LightsTop > 0) and (i >= LightsLeft) and (i <= LightsLeft+LightsTop-1) Then
            B.Canvas.FillRect(Rect(LEDPreviewSize + Round((i-LightsLeft)*((B.Width - LEDPreviewSize*2) / LightsTop)), 0, LEDPreviewSize + Round((i-LightsLeft + 1)*((B.Width - LEDPreviewSize*2) / LightsTop)), LEDPreviewSize));
            // Правое поле
            If (LightsRight > 0) and (i >= LightsLeft+LightsTop) and (i <= LightsLeft+LightsTop+LightsRight-1) Then
              B.Canvas.FillRect(Rect(B.Width - LEDPreviewSize, LEDPreviewSize + Round((i-LightsLeft-LightsTop)*((B.Height - LEDPreviewSize*2) / LightsRight)), B.Width, LEDPreviewSize + Round((i-LightsLeft-LightsTop + 1)*((B.Height - LEDPreviewSize*2) / LightsRight))));
            // Нижнее поле
            If (LightsBottom > 0) and (i >= LightsLeft+LightsTop+LightsRight) and (i <= LightsAll-1) Then
              B.Canvas.FillRect(Rect(B.Width - LEDPreviewSize - Round((i-LightsLeft-LightsTop-LightsRight+1)*((B.Width - LEDPreviewSize*2) / LightsBottom)), B.Height - LEDPreviewSize, B.Width - LEDPreviewSize - Round((i-LightsLeft-LightsTop-LightsRight)*((B.Width - LEDPreviewSize*2) / LightsBottom)), Height));
          end;

        B.Canvas.Font:=frmMain.Font;
        B.Canvas.Font.Size:=13;
        B.Canvas.Font.Color:=clWhite;
        B.Canvas.Brush.Color:=clBlack;
        B.Canvas.TextOut(LEDPreviewSize + (B.Width - LEDPreviewSize*2 - B.Canvas.TextWidth(IntToStr(LightsTop))) div 2, LEDPreviewSize + 4, IntToStr(LightsTop));
        B.Canvas.TextOut(LEDPreviewSize + (B.Width - LEDPreviewSize*2 - B.Canvas.TextWidth(IntToStr(LightsBottom))) div 2, B.Height - LEDPreviewSize - 4 - B.Canvas.TextHeight(IntToStr(LightsBottom)), IntToStr(LightsBottom));
        B.Canvas.TextOut(LEDPreviewSize + 4, LEDPreviewSize + (B.Height - LEDPreviewSize*2 - B.Canvas.TextHeight(IntToStr(LightsLeft)))div 2, IntToStr(LightsLeft));
        B.Canvas.TextOut(B.Width - LEDPreviewSize - 4 - B.Canvas.TextWidth(IntToStr(LightsRight)), LEDPreviewSize + (B.Height - LEDPreviewSize*2 - B.Canvas.TextHeight(IntToStr(LightsRight)))div 2, IntToStr(LightsRight));

        B.Canvas.Brush.Color:=frmMain.Color;
        B.Canvas.FillRect(Rect(0                                , 0                                 , LEDPreviewSize  , LEDPreviewSize   ));
        B.Canvas.FillRect(Rect(B.Width - LEDPreviewSize, 0                                 , B.Width, LEDPreviewSize   ));
        B.Canvas.FillRect(Rect(0                                , B.Height - LEDPreviewSize, LEDPreviewSize  , B.Height));
        B.Canvas.FillRect(Rect(B.Width - LEDPreviewSize, B.Height - LEDPreviewSize, B.Width, B.Height));

        imgPreview.Canvas.Draw(0, 0, B);
      Except
        On E: Exception Do ;
      End;
      If B <> Nil then B.Free;    
    end; // else
  SetPower(Power);
end;

procedure TfrmMain.cbModeChange(Sender: TObject);
begin
  miMode.ImageIndex:=cbMode.ItemIndex;
  miMode.Items[cbMode.ItemIndex].Checked:=True;

  If Worker = nil then Exit;
  Worker.SetMode(cbMode.ItemIndex);
end;

procedure TfrmMain.shColorMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  If Worker = nil then Exit;

  dlgColor.Color:=shColor.Brush.Color;
  If not dlgColor.Execute then Exit;
  shColor.Brush.Color:=dlgColor.Color;

  Worker.SetColor(shColor.Brush.Color);
end;

procedure SaveSettings;
var Reg: TRegistry;
    i: Integer;
begin
  Reg:=Nil;

  Try
    Reg:=TRegistry.Create;
    Reg.RootKey:=HKEY_CURRENT_USER;
    If not Reg.OpenKey('\Software\µSoft\LightPackServer\', False) Then
      Reg.CreateKey('\Software\µSoft\LightPackServer\');

    If not Reg.OpenKey('\Software\µSoft\LightPackServer\', False) Then
      Exit;

    Reg.WriteInteger('ModeIndex', frmMain.cbMode.ItemIndex);
    Reg.WriteInteger('UserColor', frmMain.shColor.Brush.Color);
    Reg.WriteInteger('UserParam', frmMain.edUserParam.Value);
    Reg.WriteInteger('PixelsDepth', frmMain.edPixelsDepth.Value);
    Reg.WriteInteger('MaxLevel', frmMain.edMaxLevel.Value);
    Reg.WriteBool('AutoRun', frmMain.cbAutoRun.Checked);
    Reg.WriteBool('Gamma', frmMain.cbGamma.Checked);
    Reg.WriteBool('DWMDisabler', frmMain.cbDWMActive.Checked);
    Reg.WriteBool('LivePreview', frmMain.cbLivePreview.Checked);
    Reg.WriteInteger('Port', Communication.GetPortNumber);
    Reg.WriteInteger('BaudRate', BaudRateToInt(Communication.GetBaudRate));
    Reg.WriteBool('RunMinimized', frmMain.cbRunMinimized.Checked);
    Reg.WriteInteger('LightsLeft', LightsLeft);
    Reg.WriteInteger('LightsTop', LightsTop);
    Reg.WriteInteger('LightsRight', LightsRight);
    Reg.WriteInteger('LightsBottom', LightsBottom);

    For i:=0 to Application.ComponentCount-1 do
      begin
        If not (Application.Components[i] is TForm) then Continue;
        Reg.WriteInteger((Application.Components[i] As TForm).Name+'.Top', (Application.Components[i] As TForm).Top);
        Reg.WriteInteger((Application.Components[i] As TForm).Name+'.Left', (Application.Components[i] As TForm).Left);
      end;

    // Записываем гамму
    Reg.WriteBinaryData('GammaRed'  , gammaR, Length(gammaR));
    Reg.WriteBinaryData('GammaGreen', gammaG, Length(gammaG));
    Reg.WriteBinaryData('GammaBlue' , gammaB, Length(gammaB));
  Except
    On E: Exception Do ;
  End;

  If Reg <> Nil Then
    Reg.Free;
end;

procedure LoadSettings;
var Reg: TRegistry;
    i: Integer;
begin
  Reg:=Nil;

  Try
    Reg:=TRegistry.Create;
    Reg.RootKey:=HKEY_CURRENT_USER;

    If not Reg.OpenKey('\Software\µSoft\LightPackServer\', False) Then
      Exit;

    If Reg.ValueExists('ModeIndex') Then
      Begin
        frmMain.cbMode.ItemIndex:=Max(Min(Reg.ReadInteger('ModeIndex'), frmMain.cbMode.Items.Count-1), 0);
        If Worker <> nil then
          Worker.SetMode(frmMain.cbMode.ItemIndex);
      End;

    If Reg.ValueExists('UserColor') Then
      Begin
        frmMain.shColor.Brush.Color:=Reg.ReadInteger('UserColor');
        // Специально так, чтобы не показывался диалог!
        If Worker <> nil then
          Worker.SetColor(frmMain.shColor.Brush.Color);
      End;

    If Reg.ValueExists('UserParam') Then
      Begin
        frmMain.edUserParam.Value:=Reg.ReadInteger('UserParam');
        frmMain.edUserParam.OnChange(frmMain.edUserParam);
      End;

    If Reg.ValueExists('AutoRun') Then
      Begin
        frmMain.cbAutoRun.Checked:=Reg.ReadBool('AutoRun');
        frmMain.cbAutoRun.OnClick(frmMain.cbAutoRun);
      End;

    If Reg.ValueExists('Gamma') Then
      frmMain.cbGamma.Checked:=Reg.ReadBool('Gamma');

    If Reg.ValueExists('DWMDisabler') Then
      Begin
        frmMain.cbDWMActive.Checked:=Reg.ReadBool('DWMDisabler');
        frmMain.cbDWMActive.OnClick(frmMain.cbDWMActive);
      End;

    If Reg.ValueExists('LivePreview') Then
      frmMain.cbLivePreview.Checked:=Reg.ReadBool('LivePreview');

    If Reg.ValueExists('PixelsDepth') Then
      Begin
        frmMain.edPixelsDepth.Value:=Reg.ReadInteger('PixelsDepth');
        frmMain.edPixelsDepth.OnChange(frmMain.edPixelsDepth);
      End;

    If Reg.ValueExists('MaxLevel') Then
      frmMain.edMaxLevel.Value:=Reg.ReadInteger('MaxLevel');

    If Reg.ValueExists('Port') Then
      Communication.SetPortNumber(Reg.ReadInteger('Port'));

    If Reg.ValueExists('BaudRate') Then
      Communication.SetBaudRate(IntToBaudRate(Reg.ReadInteger('BaudRate')));

    If Reg.ValueExists('RunMinimized') Then
      frmMain.cbRunMinimized.Checked:=Reg.ReadBool('RunMinimized');

    If Reg.ValueExists('LightsLeft') Then
      LightsLeft:=Reg.ReadInteger('LightsLeft');

    If Reg.ValueExists('LightsTop') Then
      LightsTop:=Reg.ReadInteger('LightsTop');

    If Reg.ValueExists('LightsRight') Then
      LightsRight:=Reg.ReadInteger('LightsRight');

    If Reg.ValueExists('LightsBottom') Then
      LightsBottom:=Reg.ReadInteger('LightsBottom');

    If Worker <> nil then
      Worker.SetLEDsCount(LightsLeft, LightsTop, LightsRight, LightsBottom);

    For i:=0 to Application.ComponentCount-1 do
      begin
        If not (Application.Components[i] is TForm) then Continue;
        If Reg.ValueExists((Application.Components[i] As TForm).Name+'.Top') then
          Begin
            (Application.Components[i] As TForm).Top:=Reg.ReadInteger((Application.Components[i] As TForm).Name+'.Top');
            If (Application.Components[i] As TForm).Top < 0 then (Application.Components[i] As TForm).Top:=0;
            If (Application.Components[i] As TForm).Top + (Application.Components[i] As TForm).Height > Screen.DesktopHeight then (Application.Components[i] As TForm).Top:=Screen.DesktopHeight - (Application.Components[i] As TForm).Height;
          End
        Else
          (Application.Components[i] As TForm).Top:=(Screen.Monitors[0].Height - (Application.Components[i] As TForm).Height) div 2;

        If Reg.ValueExists((Application.Components[i] As TForm).Name+'.Left') then
          Begin
            (Application.Components[i] As TForm).Left:=Reg.ReadInteger((Application.Components[i] As TForm).Name+'.Left');
            If (Application.Components[i] As TForm).Left < 0 then (Application.Components[i] As TForm).Left:=0;
            If (Application.Components[i] As TForm).Left + (Application.Components[i] As TForm).Width > Screen.DesktopWidth then (Application.Components[i] As TForm).Left:=Screen.DesktopWidth - (Application.Components[i] As TForm).Width;
          End
        Else
          (Application.Components[i] As TForm).Left:=(Screen.Monitors[0].Width - (Application.Components[i] As TForm).Width) div 2;
      end;

    // Считываем гамму
    If Reg.ValueExists('GammaRed') then
      Reg.ReadBinaryData('GammaRed'  , gammaR, Length(gammaR));

    If Reg.ValueExists('GammaGreen') then
      Reg.WriteBinaryData('GammaGreen', gammaG, Length(gammaG));

    If Reg.ValueExists('GammaBlue') then
      Reg.WriteBinaryData('GammaBlue' , gammaB, Length(gammaB));
  Except
    On E: Exception Do ;
  End;

  If Reg <> Nil Then
    Reg.Free;
end;

procedure DoAutoRun;
var Reg: TRegistry;
begin
  Reg:=Nil;
  Try
    Reg:=TRegistry.Create;
    Reg.RootKey:=HKEY_CURRENT_USER;
    If not Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run\', False) Then Exit;

    If frmMain.cbAutoRun.Checked Then
      Reg.WriteString('LightPackServer', Application.ExeName)
    Else
      Reg.DeleteValue('LightPackServer');
  Except
    On E: Exception Do
      frmMain.cbAutoRun.Checked:=False;
  End;

  If Reg <> Nil Then
    Reg.Free;
end;

procedure TfrmMain.cbAutoRunClick(Sender: TObject);
begin
  DoAutoRun;
end;

procedure TfrmMain.ApplicationMinimize(Sender: TObject);
begin
  ApplicationMinimized:=True;
  miMinimize.Visible:=False;
  miRestore.Visible:=True;
end;

procedure TfrmMain.ApplicationRestore(Sender: TObject);
begin
  ApplicationMinimized:=False;
  miMinimize.Visible:=True;
  miRestore.Visible:=False;
  Application.RestoreTopMosts;
  Application.BringToFront;
  Application.MainForm.Visible:=True;
end;

procedure InitializePopupMenu;
var i: Integer;
    MI: TMenuItem;
    hCom: THandle;
    dwError: DWORD;
begin
  frmMain.miMode.Clear;
  For i:=0 to frmMain.cbMode.Items.Count-1 Do
    Begin
      MI:=TMenuItem.Create(frmMain.pmPopup);
      MI.Caption:=frmMain.cbMode.Items[i];
      MI.Tag:=i;
      MI.ImageIndex:=i;
      MI.OnClick:=frmMain.miSep1.OnClick;
      MI.RadioItem:=True;
      MI.GroupIndex:=1;
      MI.OnDrawItem:=frmMain.miSep1.OnDrawItem;
      MI.OnMeasureItem:=frmMain.miSep1.OnMeasureItem;
      If i = frmMain.cbMode.ItemIndex then
        MI.Checked:=True;
      frmMain.miMode.Add(MI);
    End;

  frmMain.miPort.Clear;
  frmMain.cbComPort.Items.Clear;
  For i:=1 to 256 Do
    Begin
      hCom := CreateFile(PChar('\\.\COM'+IntToStr(i)), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
      if (hCom = INVALID_HANDLE_VALUE) Then
        Begin
          dwError := GetLastError;
//          frmMain.Caption:='['+IntToStr(dwError)+'] '+WSAErrorToTextSystem(dwError);
          If dwError <> 5 then Continue; // порт просто кем-то занят!
        End;
      CloseHandle(hCom);

      frmMain.cbComPort.Items.AddObject('COM'+IntToStr(i), TObject(i));

      MI:=TMenuItem.Create(frmMain.pmPopup);
      MI.Caption:='COM'+IntToStr(i);
      MI.Tag:=i;
      MI.ImageIndex:=-1;
      MI.OnClick:=frmMain.miSep2.OnClick;
      MI.RadioItem:=True;
      MI.GroupIndex:=2;
      MI.OnDrawItem:=frmMain.miSep1.OnDrawItem;
      MI.OnMeasureItem:=frmMain.miSep1.OnMeasureItem;
      If i-1 = Communication.GetPortNumber then
        begin
          MI.Checked:=True;
          frmMain.cbComPort.ItemIndex:=frmMain.cbComPort.Items.Count-1;
        end;
      frmMain.miPort.Add(MI);
    End;
end;


procedure TfrmMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.trayIconDblClick(Sender: TObject);
begin
  If not ApplicationMinimized Then
    Application.Minimize
  Else
    Begin
      Application.Restore;
      Application.BringToFront;
    End;
end;

procedure TfrmMain.trayIconStartup(Sender: TObject;
  var ShowMainForm: Boolean);
begin
  LoadSettings;

  If cbRunMinimized.Checked then
    PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 1);
end;

procedure TfrmMain.miSetColorClick(Sender: TObject);
begin
  shColor.OnMouseDown(shColor, mbLeft, [], 0, 0);
end;

procedure TfrmMain.miSep1Click(Sender: TObject);
begin
  cbMode.ItemIndex:=(Sender As TMenuItem).Tag;
  cbMode.OnChange(cbMode);
end;

procedure LoadModeIcons;
var
   Res: TResourceStream;
   i: Integer;
begin
  For i:=0 to TotalModeIcons-1 do
    Begin
      ModeIcons[i]:=Nil;
      Try
        Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('Mode'+IntToStr(i)));
        ModeIcons[i]:=TPNGObject.Create;
        ModeIcons[i].LoadFromStream(Res);
        Res.Free;
      Except
        On E: Exception Do ;
      End;
    End;

  LogoIcon:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('Logo'));
    LogoIcon:=TPNGObject.Create;
    LogoIcon.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  LogoBlackIcon:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('LogoBlack'));
    LogoBlackIcon:=TPNGObject.Create;
    LogoBlackIcon.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  Icon128Icon:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('Icon128'));
    Icon128Icon:=TPNGObject.Create;
    Icon128Icon.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  iconConnectGreen:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stConnectGreen'));
    iconConnectGreen:=TPNGObject.Create;
    iconConnectGreen.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  iconConnectYellow:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stConnectYellow'));
    iconConnectYellow:=TPNGObject.Create;
    iconConnectYellow.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  iconConnectRed:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stConnectRed'));
    iconConnectRed:=TPNGObject.Create;
    iconConnectRed.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  iconLatency:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stLatency'));
    iconLatency:=TPNGObject.Create;
    iconLatency.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  iconLeds:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stLeds'));
    iconLeds:=TPNGObject.Create;
    iconLeds.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  iconError:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stError'));
    iconError:=TPNGObject.Create;
    iconError.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;

  iconFullscreen:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stFullscreen'));
    iconFullscreen:=TPNGObject.Create;
    iconFullscreen.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;


  iconPower:=Nil;
  Try
    Res:=TResourceStream.Create(HInstance, 'PNG', Pchar('stPower'));
    iconPower:=TPNGObject.Create;
    iconPower.LoadFromStream(Res);
    Res.Free;
  Except
    On E: Exception Do ;
  End;
end;

procedure TfrmMain.cbModeDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
   B: TBitmap;
   FG, BG: TColor;
begin
  B:=Nil;
  Try
    B:=TBitmap.Create;
    B.Width:=Rect.Right - Rect.Left;
    B.Height:=Rect.Bottom - Rect.Top;

    If odSelected in State then
      Begin
        FG:=clHighlightText;
        BG:=clHighlight;
      End
    Else
      Begin
        FG:=clWindowText;
        BG:=clWindow;
      End;

    B.Canvas.Brush.Color:=BG;
    B.Canvas.Font:=Font;
    B.Canvas.Font.Color:=FG;
    B.Canvas.Pen.Color:=FG;

    B.Canvas.FillRect(B.Canvas.ClipRect);
    If ModeIcons[Index] <> Nil then
      B.Canvas.Draw(2, 1, ModeIcons[Index]);
    B.Canvas.TextOut(2+16+2, 2, (Control As TComboBox).Items[Index]);

    (Control As TComboBox).Canvas.Draw(Rect.Left, Rect.Top, B);
  Except
    On E: Exception Do
      inherited;
  End;

  If B <> nil then B.Free;
end;

procedure TfrmMain.miSep1DrawItem(Sender: TObject; ACanvas: TCanvas;
  ARect: TRect; Selected: Boolean);
var
   B: TBitmap;
   FG, BG: TColor;
begin
  B:=Nil;
  Try
    B:=TBitmap.Create;
    B.Width:=ARect.Right - ARect.Left;
    B.Height:=ARect.Bottom - ARect.Top;

    If (Sender As TMenuItem).Caption = '-' then
      Begin
        FG:=clBtnShadow;
        BG:=clMenu;
      End
    Else If Selected then
      Begin
        FG:=clMenuText;
        BG:=clMenuHighlight;
      End
    Else
      Begin
        FG:=clMenuText;
        BG:=clMenuBar;
      End;

    B.Canvas.Brush.Color:=BG;
    B.Canvas.Font:=Font;
    B.Canvas.Font.Color:=FG;
    B.Canvas.Pen.Color:=FG;

    B.Canvas.FillRect(B.Canvas.ClipRect);

    If (Sender As TMenuItem).Caption = '-' then
      Begin
        B.Canvas.MoveTo(0, B.Height div 2);
        B.Canvas.LineTo(B.Width, B.Height div 2);
      End
    Else
      Begin
        If (Sender As TMenuItem).Checked then
          Begin
            B.Canvas.Font.Style:=[fsBold];
            If not Selected then
              Begin
                B.Canvas.Brush.Color:=clActiveCaption;
                B.Canvas.Font.Color:=clCaptionText;
                B.Canvas.FillRect(B.Canvas.ClipRect);
              End;  
            B.Canvas.Pen.Color:=clBtnShadow;
            B.Canvas.MoveTo(0, 0);
            B.Canvas.LineTo(B.Width-1, 0);
            B.Canvas.LineTo(B.Width-1, B.Height-1);
            B.Canvas.LineTo(0, B.Height-1);
            B.Canvas.LineTo(0, 0);
            B.Canvas.Pen.Color:=cl3DDkShadow;
            B.Canvas.MoveTo(1, 1);
            B.Canvas.LineTo(B.Width-2, 1);
            B.Canvas.LineTo(B.Width-2, B.Height-2);
            B.Canvas.LineTo(1, B.Height-2);
            B.Canvas.LineTo(1, 1);
            B.Canvas.Pen.Color:=FG;
          End;

        If ((Sender As TMenuItem).ImageIndex >= 0) and (ModeIcons[(Sender As TMenuItem).ImageIndex] <> Nil) then
          Begin
            B.Canvas.Draw(2, 3, ModeIcons[(Sender As TMenuItem).ImageIndex]);
            B.Canvas.TextOut(2+16+2, 4, (Sender As TMenuItem).Caption);
          End
        Else
          B.Canvas.TextOut(2+16+2, 2, (Sender As TMenuItem).Caption);

        If ((Sender As TMenuItem).Tag = -2) then
          Begin
            B.Canvas.Brush.Color:=shColor.Brush.Color;
            B.Canvas.FillRect(Rect(2, 2, 2+14, 2+14));
            B.Canvas.Brush.Color:=shColor.Pen.Color;
            B.Canvas.FrameRect(Rect(2, 2, 2+14, 2+14));
          End;
      End;
      
    ACanvas.Draw(ARect.Left, ARect.Top, B);
  Except
    On E: Exception Do
      inherited;
  End;

  If B <> nil then B.Free;
end;

procedure TfrmMain.miSep1MeasureItem(Sender: TObject; ACanvas: TCanvas;
  var Width, Height: Integer);
begin
  Width:=Width + 16;
  If (Sender As TMenuItem).Count > 0 then
    Width:=Width + 16;

  If (Sender As TMenuItem).ImageIndex >= 0 then
    Height:=22;
end;

function MAKELANGID(p, s: word): word;
begin
  Result:= (((WORD(s)) shl 10) + WORD(p));
end;

function WSAErrorToTextSystem(ErrCode: DWORD): String;
var
    lpMsgBuf: PAnsiChar;
    i: integer;
begin
  try
    // Retrieve the system error message for the last-error code


    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER or
        FORMAT_MESSAGE_FROM_SYSTEM or
        FORMAT_MESSAGE_IGNORE_INSERTS,
        nil,
        ErrCode,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        @lpMsgBuf,
        0, nil );

    // Display the error message and exit the process
    Result:=lpMsgBuf;

    // Удаляем лишние переносы строк
    While True Do
      Begin
        i:=Pos(#13, Result);
        if I <= 0 then Break;
        Delete(Result, i, 1);
      End;
    While True Do
      Begin
        i:=Pos(#10, Result);
        if I <= 0 then Break;
        Delete(Result, i, 1);
      End;
    // Удаляем точку в конце
    If Result[Length(Result)] = '.' Then
      Delete(Result, Length(Result), 1);

    LocalFree(Cardinal(lpMsgBuf));
  except
    on E: Exception do
      Result:='нет описания ошибки';
  end;
End;

procedure TfrmMain.miSep2Click(Sender: TObject);
begin
  If Communication = nil then Exit;

  Communication.SetPortNumber((Sender As TMenuItem).Tag-1);
  (Sender As TMenuItem).Checked:=True;

  SaveSettings;
end;

procedure TfrmMain.RealignPreviewWindow;
const
  mult = 5;
var
  delta: Extended;
begin
  imgPreview.Picture:=Nil;
  imgPreview.Width:=Worker.ScreenStartWidth div mult + LEDPreviewSize*2;
  imgPreview.Height:=Worker.ScreenStartHeight div mult + LEDPreviewSize*2;

  gbPreview.Width:=imgPreview.Left*2+imgPreview.Width;
  gbPreview.Height:=imgPreview.Left*2+10+imgPreview.Height;

  ClientWidth:=gbPreview.Left + gbPreview.Width + gbMode.Left;
  ClientHeight:=gbPreview.Top*2+gbPreview.Height + sbStatus.Height;

  If ClientHeight < gbApplicationParams.Top + gbApplicationParams.Height + gbPreview.Top + sbStatus.Height then
    Begin
      ClientHeight := gbApplicationParams.Top + gbApplicationParams.Height + gbPreview.Top + sbStatus.Height;
      gbPreview.Height:=gbApplicationParams.Top + gbApplicationParams.Height - gbPreview.Top;
      imgPreview.Top:=(gbPreview.Height - imgPreview.Height) div 2 + 4;
    End
  else
    begin
      Delta:= gbPreview.Height - (gbApplicationParams.Top + gbApplicationParams.Height);
      gbCaptureParams.Top    :=Round(gbMode.Top + gbMode.Height + 7 + Delta/3);
      gbLEDsParams.Top       :=Round(gbCaptureParams.Top + gbCaptureParams.Height + 7 + Delta/3);
      gbApplicationParams.Top:=Round(gbLEDsParams.Top + gbLEDsParams.Height + 6 + Delta/3);
    end;

  If Left + Width > Screen.DesktopWidth then
    Left:=Screen.Width - Width;
  If Top + Height > Screen.Height then
    Top:=Screen.Height - Height;
end;

procedure TfrmMain.edPixelsDepthChange(Sender: TObject);
begin
  if Assigned(frmPreview) then frmPreview.ShowEx((Sender As TSpinEdit).Value);
  if frmMain.Visible then frmMain.Activate;
  if frmMain.Visible then edPixelsDepth.SetFocus;

  If Worker = nil then Exit;

  Worker.SetPixelsDepth((Sender As TSpinEdit).Value);
end;

procedure TfrmMain.edPixelsDepthEnter(Sender: TObject);
begin
  if Assigned(frmPreview) then frmPreview.ShowEx((Sender As TSpinEdit).Value);
  if frmMain.Visible then frmMain.Activate;
  if frmMain.Visible then edPixelsDepth.SetFocus;
end;

procedure TfrmMain.edPixelsDepthExit(Sender: TObject);
begin
  frmPreview.Hide;
end;

procedure TfrmMain.cbDWMActiveClick(Sender: TObject);
begin
  If FullscreenWatcher = Nil Then Exit;

  FullscreenWatcher.SetDWMActive((Sender As TCheckBox).Checked);
end;

procedure TfrmMain.FullscreenStarted(aHandle: THandle; aRect: TRect);
//var
//  buf: Array [0..MAX_PATH-1] of Char;
begin
// GetWindowText(aHandle, buf, MAX_PATH);
// caption:='YES - [' + buf+'] - '+Format('%d,%d - %d,%d', [aRect.Left, aRect.Top, aRect.Right-aRect.Left, aRect.Bottom-aRect.Top]);

  sbStatus.Panels[4].Text:='Да';
end;

procedure TfrmMain.FullscreenStopped(aHandle: THandle; aRect: TRect);
begin
  sbStatus.Panels[4].Text:='Нет';
end;

procedure TfrmMain.btnDbgClick(Sender: TObject);
var
  ColorChannels: Array [0..2] of String;
begin
  cbGamma.Checked:=False;
  edMaxLevel.Value:=255;
  cbMode.ItemIndex:=0;

  ColorChannels[0]:='Красный';
  ColorChannels[1]:='Зелёный';
  ColorChannels[2]:='Синий';
  
  if btnDbg.Tag = 0 then
    btnDbg.Caption:='Замерьте баланс белого'
  else if btnDbg.Tag < 49 then
    btnDbg.Caption:=Format('Замерьте яркость канала "%s" в точке %s/255', [ColorChannels[(btnDbg.Tag-1) div 16], FormatFloat('000',17*((btnDbg.Tag-1) mod 16))]);

  case btnDbg.Tag of
        0: frmPreview.ShowSolidColor(clWhite); // for WhiteBalance Calibration
    1..16: frmPreview.ShowSolidColor(RGB(17*((btnDbg.Tag-1) mod 16), 0                         , 0                         ));
   17..32: frmPreview.ShowSolidColor(RGB(0                         , 17*((btnDbg.Tag-1) mod 16), 0                         ));
   33..48: frmPreview.ShowSolidColor(RGB(0                         , 0                         , 17*((btnDbg.Tag-1) mod 16)));
  else
    frmPreview.Hide;
    btnDbg.Caption:='Запустить утилиту замера гамма-коррекции';
    cbGamma.Checked:=True;
  end;

  frmMain.Activate;
  btnDbg.SetFocus;

  btnDbg.Tag:=btnDbg.Tag+1;
  if btnDbg.Tag >= 50 then btnDbg.Tag:=0;

end;

procedure TfrmMain.SetLinkState(aState: TLinkState; aPort: Byte; aBaudRate: TBaudRate);
begin
  sbStatus.Panels[0].Text:=Format('%dCOM%d (%d кбод)', [Integer(aState), aPort+1, Round(BaudRateToInt(aBaudRate)/1024)]);
end;

procedure TfrmMain.SetLatency(aLatency: Extended);
begin
  sbStatus.Panels[1].Text:=Format('~%d мс', [Round(aLatency)]);
end;

procedure TfrmMain.SetConfig(aConfig: Integer);
begin
  sbStatus.Panels[2].Text:=Format('%d шт.', [aConfig]);
end;

procedure TfrmMain.SetErrors(aDelta: Integer);
begin
  sbStatus.Panels[3].Text:=Format('%d', [StrToIntDef(sbStatus.Panels[3].Text, 0)+aDelta]);
end;

procedure TfrmMain.SetPower(aCurrent: Extended);
const
  Voltage = 5; // V
begin
  If aCurrent < 0 then
    sbStatus.Panels[5].Text:='н/д'
  else
    sbStatus.Panels[5].Text:=Format('%.1f Вт (%d В; %.1f А)', [aCurrent*Voltage, Voltage, aCurrent]);
end;

procedure TfrmMain.sbStatusDrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
var
  B: TBitmap;
  icon: TPNGObject;
  text: String;
begin
  B:=Nil;
  icon:=nil;
  text:='';
  
Try
  B:=TBitmap.Create;

  B.Width:=Rect.Right - Rect.Left;
  B.Height:=Rect.Bottom - Rect.Top;

  B.Canvas.Brush.Color:=clBtnFace;
  B.Canvas.Pen.Color:=clBtnText;
  B.Canvas.Font:=frmMain.Font;

  B.Canvas.FillRect(B.Canvas.ClipRect);

  Case Panel.Index of
    0: Begin
         text:=Copy(Panel.Text, 2, Length(Panel.Text));
         Case TLinkState(StrToIntDef(Panel.Text[1], Integer(lsDisconnected))) of
           lsConnected:
             Begin
               icon:=iconConnectGreen;
               B.Canvas.Font.Color:=clGreen;
             End;
           lsDisconnected:
             Begin
               icon:=iconConnectRed;
               B.Canvas.Font.Color:=clRed;
             End;
           lsReadyToConnect:
             Begin
               icon:=iconConnectYellow;
               B.Canvas.Font.Color:=clOlive;
             End;
         End;
       End;
    1: Begin
         text:=Panel.Text;
         icon:=iconLatency;
         B.Canvas.Font.Color:=clBtnText;
       End;
    2: Begin
         text:=Panel.Text;
         icon:=iconLeds;
         B.Canvas.Font.Color:=clBtnText;
       End;
    3: Begin
         text:=Panel.Text;
         If StrToIntDef(text, 0) = 0 then
           Begin
             icon:=nil;
             B.Canvas.Font.Color:=clGreen;
           End
         Else
           Begin
             icon:=iconError;
             B.Canvas.Font.Color:=clRed;
           End;  
       End;
    4: Begin
         text:=Panel.Text;
         If AnsiLowerCase(text) = 'да' then
           Begin
             icon:=iconFullscreen;
             B.Canvas.Font.Color:=clBlue;
           End
         Else
           Begin
             icon:=nil;
             B.Canvas.Font.Color:=clBtnText;
           End;
       End;
    5: Begin
         text:=Panel.Text;
         icon:=iconPower;
         If AnsiLowerCase(text) = 'н/д' then
           B.Canvas.Font.Color:=clBtnShadow
         Else
           B.Canvas.Font.Color:=clBtnText;
       End;
  Else
    icon:=nil;
    text:=''; 
    B.Canvas.Font.Color:=clBtnFace;
  End;

  If icon <> nil then
    Begin
      B.Canvas.Draw(2, 1, icon);
      B.Canvas.TextOut(2+icon.Width+4, 2, text);
    End
  else
    B.Canvas.TextOut(2, 2, text);

  StatusBar.Canvas.Draw(Rect.Left, Rect.Top, B);
Except
  On E: Exception Do ;
End;

If B<>Nil then B.Free;
end;

procedure TfrmMain.edUserParamChange(Sender: TObject);
var
  aParam: Extended;
begin
  If Worker = nil then Exit;

  aParam:=(Sender As TSpinEdit).Value;

  Worker.SetParam(aParam);
end;

procedure TfrmMain.btnDbgExit(Sender: TObject);
begin
  frmPreview.Hide;
  btnDbg.Caption:='Запустить утилиту замера гамма-коррекции';
  btnDbg.Tag:=0;
end;

procedure TfrmMain.cbComPortChange(Sender: TObject);
begin
  If Communication = Nil then Exit;

  Communication.SetPortNumber(Integer((Sender As TComboBox).Items.Objects[(Sender As TComboBox).ItemIndex])-1);
  SaveSettings;
end;

procedure TfrmMain.pmPopupPopup(Sender: TObject);
var
  i: Integer;
  portCache: Byte;
begin
  portCache:=Communication.GetPortNumber;
  for i:=0 to miPort.Count-1 do
    miPort.Items[i].Checked:=(miPort.Items[i].Tag-1) = portCache;
end;

procedure TfrmMain.btnEnterGammaClick(Sender: TObject);
var
  f: TStringList;
  i: integer;
  str: String;
  ch, index, realval: byte;
begin
  if not dlgOpen.Execute then Exit;

  f:=nil;

  Try
    f:=TStringList.Create;
    f.LoadFromFile(dlgOpen.FileName);
    for i:=0 to f.Count-1 do
      begin
        str:=f[i];
        ch:=Ord(Copy(str,1,1)[1]);
        Delete(str, 1, 2);
        index:=StrToInt(Copy(str, 1, Pos(#9, str)-1));
        Delete(str, 1, Pos(#9, str));
        realval:=StrToInt(str);

        Case ch of
          Ord('R'): gammaR[index]:=realval;
          Ord('G'): gammaG[index]:=realval;
          Ord('B'): gammaB[index]:=realval;
        End;
      end;
  Except
    On E: Exception Do ;
  End;

  If f<>nil then f.Free;
end;

function GetCOMPortIndex(aPort: Byte): Integer;
var
  i: Integer;
  MI: TMenuItem;
begin
  For i:=0 to frmMain.cbComPort.Items.Count-1 do
    begin
      if Integer(frmMain.cbComPort.Items.Objects[i]) <> aPort then Continue;
      Result:=i;
      Exit;
    end;

  frmMain.cbComPort.Items.AddObject('COM'+IntToStr(aPort+1), TObject(aPort));

  MI:=TMenuItem.Create(frmMain.pmPopup);
  MI.Caption:='COM'+IntToStr(aPort+1);
  MI.Tag:=aPort;
  MI.ImageIndex:=-1;
  MI.OnClick:=frmMain.miSep2.OnClick;
  MI.RadioItem:=True;
  MI.GroupIndex:=2;
  MI.OnDrawItem:=frmMain.miSep1.OnDrawItem;
  MI.OnMeasureItem:=frmMain.miSep1.OnMeasureItem;
  If aPort = Communication.GetPortNumber then
    MI.Checked:=True;
  frmMain.miPort.Add(MI);

  Result:=frmMain.cbComPort.Items.Count-1;
end;

procedure TfrmMain.cbGammaClick(Sender: TObject);
begin
  If Communication = nil then Exit;

  Communication.SetGamma((Sender As TCHeckBox).Checked);
end;

procedure TfrmMain.edMaxLevelChange(Sender: TObject);
begin
  If Communication = nil then Exit;

  Communication.SetMaxLevel((Sender As TSpinEdit).Value);
end;

function BaudRateToInt(aBaudRate: TBaudRate): Integer;
begin
  Case aBaudRate of
        br45: Result:=    45;
        br50: Result:=    50;
        br75: Result:=    75;
       br110: Result:=   110;
       br300: Result:=   300;
       br600: Result:=   600;
      br1200: Result:=  1200;
      br2400: Result:=  2400;
      br4800: Result:=  4800;
      br9600: Result:=  9600;
     br14400: Result:= 14400;
     br19200: Result:= 19200;
     br38400: Result:= 38400;
     br56000: Result:= 56000;
     br57600: Result:= 57600;
    br115200: Result:=115200;
    br230400: Result:=230400;
    br460800: Result:=460800;
    br921600: Result:=921600;
      Custom: Result:=115200;
  Else
              Result:=115200;
  End;
end;

function IntToBaudRate(aInteger: Integer): TBaudRate;
begin
  Case aInteger of
        45: Result:=    br45;
        50: Result:=    br50;
        75: Result:=    br75;
       110: Result:=   br110;
       300: Result:=   br300;
       600: Result:=   br600;
      1200: Result:=  br1200;
      2400: Result:=  br2400;
      4800: Result:=  br4800;
      9600: Result:=  br9600;
     14400: Result:= br14400;
     19200: Result:= br19200;
     38400: Result:= br38400;
     56000: Result:= br56000;
     57600: Result:= br57600;
    115200: Result:=br115200;
    230400: Result:=br230400;
    460800: Result:=br460800;
    921600: Result:=br921600;
  Else
            Result:=br115200;
  End;
end;

procedure RegisterHotKeys;
begin
  RegisterHotKey(frmMain.Handle, 1111, modWin           , Ord('Q'));
  RegisterHotKey(frmMain.Handle, 2222, modWin + modCtrl , VK_LEFT );
  RegisterHotKey(frmMain.Handle, 3333, modWin + modCtrl , VK_RIGHT);
  RegisterHotKey(frmMain.Handle, 4444, modWin + modCtrl , VK_UP   );
  RegisterHotKey(frmMain.Handle, 5555, modWin + modCtrl , VK_DOWN );
end;

procedure UnRegisterHotKeys;
begin
  UnRegisterHotKey(frmMain.Handle, 1111);
  UnRegisterHotKey(frmMain.Handle, 2222);
  UnRegisterHotKey(frmMain.Handle, 3333);
  UnRegisterHotKey(frmMain.Handle, 4444);
  UnRegisterHotKey(frmMain.Handle, 5555);
end;

// Trap Hotkey Messages
procedure TfrmMain.WMHotKey(var Msg: TWMHotKey);
begin
  case Msg.HotKey of
     1111: //WIN+Q (Вкл./выкл.)
       Begin
         If cbMode.ItemIndex <> 0 then
           cbMode.ItemIndex:=0
         else
           cbMode.ItemIndex:=cbMode.Items.Count-1;
         cbMode.OnChange(cbMode);
       End;

     2222: //WIN+Ctrl+Влево (Предыдущий режим)
       Begin
         If cbMode.ItemIndex > 0 then
           cbMode.ItemIndex:=cbMode.ItemIndex-1;
         cbMode.OnChange(cbMode);
       End;

     3333: //WIN+Ctrl+Вправо (Следующий режим)
       Begin
         If cbMode.ItemIndex < cbMode.Items.Count-1 then
           cbMode.ItemIndex:=cbMode.ItemIndex+1;
         cbMode.OnChange(cbMode);
       End;

     4444: //WIN+Ctrl+Вверх (Ярче)
       Begin
         If edMaxLevel.Value < edMaxLevel.MaxValue then
         edMaxLevel.Value:=edMaxLevel.Value+1;
         edMaxLevel.OnChange(edMaxLevel);
       End;

     5555: //WIN+Ctrl+Вниз (Темнее)
       Begin
         If edMaxLevel.Value > edMaxLevel.MinValue then
         edMaxLevel.Value:=edMaxLevel.Value-1;
         edMaxLevel.OnChange(edMaxLevel);
       End;
  end;
end;
  
procedure TfrmMain.sbStatusMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var L, T, R, B: Integer;  
begin
  If (X < sbStatus.Panels[0].Width + sbStatus.Panels[1].Width                           ) then Exit;
  If (X > sbStatus.Panels[0].Width + sbStatus.Panels[1].Width + sbStatus.Panels[2].Width) then Exit;

  L:=LightsLeft;
  T:=LightsTop;
  R:=LightsRight;
  B:=LightsBottom;

  If frmLightsCountDlg.ShowModalEx(L, T, R, B) <> mrOk then Exit;

  Worker.SetLEDsCount(L, T, R, B);
  SetConfig(LightsAll);
  SaveSettings;
end;

end.
