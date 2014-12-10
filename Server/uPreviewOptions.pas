unit uPreviewOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, pngimage, ComCtrls;

type
  TfrmPreview = class(TForm)
    imgLogo: TImage;
    timTimeout: TTimer;
    pbHider: TProgressBar;
    procedure FormClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure timTimeoutTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ShowEx(PixelsDepth: Integer);
    procedure ShowSolidColor(aColor: TColor);
  end;

var
  frmPreview: TfrmPreview;

implementation

uses uMain;

{$R *.dfm}

procedure TfrmPreview.ShowEx(PixelsDepth: Integer);
begin
  Color:=clBlack;

  timTimeout.Enabled:=False;
  timTimeout.Tag:=300;
  pbHider.Visible:=True;
  timTimeout.Enabled:=True;

  If not Visible then Show;

  SetBounds(PixelsDepth, PixelsDepth, Screen.Monitors[0].Width-PixelsDepth*2, Screen.Monitors[0].Height-PixelsDepth*2);
end;

procedure TfrmPreview.ShowSolidColor(aColor: TColor);
begin
  Color:=aColor;

  timTimeout.Enabled:=False;
  timTimeout.Tag:=300;
  pbHider.Visible:=False;

  If not Visible then Show;

  SetBounds(0, 0, Screen.Monitors[0].Width, Screen.Monitors[0].Height);
end;

procedure TfrmPreview.FormClick(Sender: TObject);
begin
  Hide;
end;

procedure TfrmPreview.FormResize(Sender: TObject);
begin
  imgLogo.SetBounds((ClientWidth - imgLogo.Width) div 2, (ClientHeight - imgLogo.Height) div 2, imgLogo.Width, imgLogo.Height);
  pbHider.SetBounds((ClientWidth - pbHider.Width) div 2, imgLogo.Height + imgLogo.Top + 16, pbHider.Width, pbHider.Height);
end;

procedure TfrmPreview.FormCreate(Sender: TObject);
begin
  imgLogo.Picture.Assign(Icon128Icon);
end;

procedure TfrmPreview.timTimeoutTimer(Sender: TObject);
begin
  timTimeout.Tag:=timTimeout.Tag-1;
  pbHider.Position:=Round(timTimeout.Tag/300*100);
  If timTimeout.Tag > 0 then Exit;

  timTimeout.Tag:=0;
  timTimeout.Enabled:=False;
  
  Hide;
end;

end.
