unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, Comms, ExtCtrls;

type
  TMode = (mdWaitLen, mdWaitData);
  
  TfrmMain = class(TForm)
    Label1: TLabel;
    edPort: TSpinEdit;
    btnStart: TButton;
    imgPreview: TImage;
    btnStop: TButton;
    cpCOM: TComPort;
    timFPS: TTimer;
    procedure edPortChange(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure cpCOMRxChar(Sender: TObject; InQue: Cardinal);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure timFPSTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  Run: Boolean = False;
  Lights: Array [0..204-1] of TColor;
  Mode: TMode = mdWaitLen;
  DataReadedTotal: Integer = 0;
  Data: String = '';
  FPS: Integer = 0;
implementation

{$R *.dfm}

procedure TfrmMain.edPortChange(Sender: TObject);
begin
  cpCOM.Port:=edPort.Value-1;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  Run:=False;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  cpCOM.Open;
  cpCOM.WriteString('z', true);
  
  Run:=True;

  While Run Do
    Begin
      Application.ProcessMessages;
    End;

  cpCOM.Close;
end;

procedure TfrmMain.cpCOMRxChar(Sender: TObject; InQue: Cardinal);
var
  Buf: Array [0..1024] of Char;
  i, len: Integer;
  B: TBitmap;
begin
  For i:=0 to 1024 do
    Buf[i]:=' ';

  if InQue <= 0 then Exit;
  If Mode =  mdWaitLen then
    Begin
      cpCOM.Read(Buf, 1, True);
      len:=Ord(Buf[0]);
      if len <> Length(Lights) then
        begin
          Sleep(50);
          Application.ProcessMessages;
          cpCOM.WriteString('z', true);
          exit;
        end;
      Mode:=mdWaitData;
      DataReadedTotal:=0;
      Data:='';
      InQue:=InQue-1;
    End;

  if InQue <= 0 then Exit;
  If Mode =  mdWaitData then
    Begin
      len:=cpCOM.Read(Buf, InQue, True);
      For i:=0 to len-1 do
        Data:=Data + Buf[i];
      DataReadedTotal:=DataReadedTotal + len;
      if DataReadedTotal >= 204*3 then
        Begin
          Mode:=mdWaitLen;
          for i:=0 to 204-1 do
            begin
              Lights[i]:=RGB(Ord(Data[i*3+1+1]),   // G
                             Ord(Data[i*3+0+1]),   // R
                             Ord(Data[i*3+2+1]));  // B
            end;

          B:=TBitmap.Create;
          B.Width:=imgPreview.Width;
          B.Height:=imgPreview.Height;
          B.Canvas.Brush.Color:=clBtnFace;
          B.Canvas.FillRect(B.Canvas.ClipRect);

          For i:=Low(Lights) to High(Lights) do
            begin
              B.Canvas.Brush.Color:=Lights[i];
              If i in [0..39] then
                B.Canvas.FillRect(Rect(0, Round(B.Height - (B.Height-40)/40*i - 20), 20, Round(B.Height - (B.Height-40)/40*(i+1) - 20)));
              If i in [40..40+62-1] then
                B.Canvas.FillRect(Rect(Round(20 + (B.Width-40)/62*(i-40)), 0, Round(20 + (B.Width-40)/62*(i-40+1)), 20));
              If i in [40+62..40+62+40-1] then
                B.Canvas.FillRect(Rect(B.Width - 20, Round(20+(B.Height-40)/40*(i-40-62)), B.Width, Round(20+(B.Height-40)/40*(i-40-62+1))));
              If i in [40+62+40..204-1] then
                B.Canvas.FillRect(Rect(Round(B.Width - (B.Width-40)/62*(i-40-62-40) - 20), B.Height-20, Round(B.Width - (B.Width-40)/62*(i-40-62-40+1) - 20), B.Height));
            end;

          imgPreview.Canvas.Draw(0, 0, B);
          B.Free;

          Application.ProcessMessages;
          if Run = False then Exit;
          cpCOM.WriteString('z', true);
          Inc(FPS);
        End;
    End;

end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  btnStop.Click;
end;

procedure TfrmMain.timFPSTimer(Sender: TObject);
begin
  If FPS > 0 then
    Caption:=Format('FPS: %1.1f', [timFPS.Interval/FPS]);
  FPS:=0;
end;

end.
