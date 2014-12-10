unit uCOM;

interface

uses uConst, Classes, SysUtils, Comms, ExtCtrls, Graphics;


type
  DWORD = Longword;
  
  TOnStateChanges = procedure (aState: TLinkState; aPortNumber: Byte; aBaudRate: TBaudRate) of object;
  TOnError        = procedure (aDelta: Integer) of object;
   
  TCommunication = class(TThread)
     constructor Create(CreateSuspended: Boolean);
  private
    { Private declarations }
    NeedRun: Boolean;
    Active: Boolean;
    FOnStateChanges: TOnStateChanges;
    FOnError: TOnError;

    FComPort: TComPort;
    FTimeoutTimer: TTimer;

    FGamma: Boolean;
    FMaxLevel: Byte;

    FErrorsInARow: Byte;
  protected
    { Protected declarations }
    procedure PortOpened(Sender: TObject);
    procedure PortClosed(Sender: TObject);
    procedure RxChar(Sender: TObject; InQue: DWORD);
    procedure PortError(Sender: TObject);

    procedure Timeout(Sender: TObject);
  public
    { Public declarations }
    procedure Execute; override;
    procedure Done;
    procedure SetOnProcs(aStateChanges: TOnStateChanges; aOnError: TOnError);
    procedure SetPortNumber(aPort: Byte);
    procedure SetBaudRate(aBaudRate: TBaudRate);
    procedure SetGamma(aGamma: Boolean);
    procedure SetMaxLevel(aMaxLevel: Byte);
    procedure SendData;

    function  GetPortNumber: Byte;
    function  GetBaudRate: TBaudRate;
  end;

implementation

uses uMain;

constructor TCommunication.Create(CreateSuspended: Boolean);
begin
  Inherited;
  Self.FreeOnTerminate:=False;
  Self.Suspended:=CreateSuspended;
  Self.NeedRun:=True;
  Self.Active:=False;
  Self.Priority:=tpTimeCritical;

  Self.FOnStateChanges:=Nil;
  Self.FOnError:=Nil;

  Self.FGamma:=True;
  Self.FMaxLevel:=255;

  Self.FComPort:=TComPort.Create(nil);
  Self.FComPort.Port:=0;
  Self.FComPort.BaudRate:=br230400;
  Self.FComPort.DataBits:=8;
  Self.FComPort.Parity:=prNone;
  Self.FComPort.StopBits:=sbOneStopBit;
  Self.FComPort.OnRxChar:=Self.RxChar;
  Self.FComPort.OnOpen:=Self.PortOpened;
  Self.FComPort.OnClose:=Self.PortClosed;
  Self.FComPort.OnError:=Self.PortError;

  Self.FTimeoutTimer:=TTimer.Create(nil);
  Self.FTimeoutTimer.Enabled:=False;
  Self.FTimeoutTimer.Interval:=1000;
  Self.FTimeoutTimer.OnTimer:=Self.Timeout;

  Self.FErrorsInARow:=0;
end;

procedure TCommunication.Execute;
const
  MaxErrors = 3;
begin
  while True Do
    Begin
      If not Self.NeedRun then Exit;

      Sleep(500);

      If not Self.Active then Continue;

      If not Self.FComPort.Connected then
        Begin
          Self.SetPortNumber(Self.FComPort.Port);
          Continue;
        End;

      If Self.FErrorsInARow >= MaxErrors then
        begin
          Self.FErrorsInARow:=0;
          Self.SetPortNumber(Self.FComPort.Port);
          Continue;
        end;
    End;
end;

procedure TCommunication.Done;
begin
  Self.NeedRun:=False;
end;

procedure TCommunication.PortOpened(Sender: TObject);
begin
  If not Assigned(Self.FOnStateChanges) then Exit;

  Self.FOnStateChanges(lsReadyToConnect, Self.FComPort.Port, Self.FComPort.BaudRate);
end;

procedure TCommunication.PortClosed(Sender: TObject);
begin
  If not Assigned(Self.FOnStateChanges) then Exit;

  Self.FOnStateChanges(lsDisconnected, Self.FComPort.Port, Self.FComPort.BaudRate);
end;

procedure TCommunication.PortError(Sender: TObject);
begin
  If not Assigned(Self.FOnStateChanges) then Exit;
  If Self.FComPort.Connected then
    Self.FOnStateChanges(lsReadyToConnect, Self.FComPort.Port, Self.FComPort.BaudRate)
  else
    Self.FOnStateChanges(lsDisconnected, Self.FComPort.Port, Self.FComPort.BaudRate);
end;

procedure TCommunication.RxChar(Sender: TObject; InQue: DWORD);
var B: Byte;
begin
 While (InQue >= 1) do
   Begin
     Self.FComPort.Read(B, 1, True);
     if B = Ord('z') then
       Self.SendData
     else
       Begin
         If Assigned(Self.FOnError) then
           Self.FOnError(1);
         Inc(Self.FErrorsInARow);  
       End;
     Dec(InQue);
   End;
end;

procedure TCommunication.SetOnProcs(aStateChanges: TOnStateChanges; aOnError: TOnError);
begin
  if Assigned(aStateChanges) then
    Self.FOnStateChanges:=aStateChanges;

  if Assigned(aOnError) then
    Self.FOnError:=aOnError;
end;

procedure TCommunication.SetPortNumber(aPort: Byte);
begin
  If (Self = Nil) then Exit;
  
  Self.Active:=False;

  If Self.FComPort.Connected then
    Try
      Self.FComPort.Close;
    Except
      On E: Exception Do
        If Assigned(Self.FOnStateChanges) then
          Self.FOnStateChanges(lsDisconnected, Self.FComPort.Port, Self.FComPort.BaudRate);
    End;

  Self.FComPort.Port:=aPort;

  Try
    Self.FComPort.Open;
  Except
    On E: Exception Do
      If Assigned(Self.FOnStateChanges) then
        Self.FOnStateChanges(lsDisconnected, Self.FComPort.Port, Self.FComPort.BaudRate);
  End;

  Self.Active:=True;
end;

procedure TCommunication.SetBaudRate(aBaudRate: TBaudRate);
begin
  If Self = Nil Then Exit;
  
  Self.Active:=False;

  If Self.FComPort.Connected then
    Try
      Self.FComPort.Close;
    Except
      On E: Exception Do
        If Assigned(Self.FOnStateChanges) then
          Self.FOnStateChanges(lsDisconnected, Self.FComPort.Port, Self.FComPort.BaudRate);
    End;

  Self.FComPort.BaudRate:=aBaudRate;

  Try
    Self.FComPort.Open;
  Except
    On E: Exception Do
      If Assigned(Self.FOnStateChanges) then
        Self.FOnStateChanges(lsDisconnected, Self.FComPort.Port, Self.FComPort.BaudRate);
  End;

  Self.Active:=True;
end;

procedure TCommunication.SendData;
var mas: Array of Byte;
    i: Integer;
    localLights: PColor;
begin
  If Assigned(Self.FOnStateChanges) then
    Self.FOnStateChanges(lsConnected, Self.FComPort.Port, Self.FComPort.BaudRate);

  SetLength(mas, LightsAll*3+2);

//  mas[0]:=(LightsAll shr 0) and $FF;
//  mas[1]:=(LightsAll shr 8) and $FF;
//  mas[0]:=$AA;
//  mas[1]:=$55;

  localLights:=Lights;
  for i:=0 to LightsAll-1 do
    begin
      mas[0+i*3]:=Round(Byte(localLights^ shr  0)/255 * FMaxLevel); // R
      mas[1+i*3]:=Round(Byte(localLights^ shr  8)/255 * FMaxLevel); // G
      mas[2+i*3]:=Round(Byte(localLights^ shr 16)/255 * FMaxLevel); // B
      Inc(localLights);
    end;

  If FGamma then
    Begin
      for i:=0 to LightsAll-1 do
        begin
          mas[0+i*3]:=gammaR[mas[0+i*3]];
          mas[1+i*3]:=gammaG[mas[1+i*3]];
          mas[2+i*3]:=gammaB[mas[2+i*3]];
        end;
    End;

  Try
    Self.FComPort.Write(mas[0], Length(Mas), True);

    Self.FTimeoutTimer.Enabled:=False;
    Self.FTimeoutTimer.Enabled:=True;
  Except
    On E: Exception Do
      Begin
        Try
          Self.FComPort.Close;
        Except
          On E: Exception Do ;
        End;
      End;
  End;
end;

procedure TCommunication.SetGamma(aGamma: Boolean);
begin
  Self.FGamma:=aGamma;
end;

procedure TCommunication.SetMaxLevel(aMaxLevel: Byte);
begin
  Self.FMaxLevel:=aMaxLevel;
end;

procedure TCommunication.Timeout(Sender: TObject);
begin
  Self.FTimeoutTimer.Enabled:=False;

  If Assigned(Self.FOnError) then
    Self.FOnError(+1);

  If Assigned(Self.FOnStateChanges) then
    Self.FOnStateChanges(lsReadyToConnect, Self.FComPort.Port, Self.FComPort.BaudRate);

  Inc(Self.FErrorsInARow);
end;

function TCommunication.GetPortNumber: Byte;
begin
  Result:=Self.FComPort.Port;
end;

function TCommunication.GetBaudRate: TBaudRate;
begin
  Result:=Self.FComPort.BaudRate;
end;

end.
