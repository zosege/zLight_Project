unit uLightsCountDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, Spin;

type
  TfrmLightsCountDlg = class(TForm)
    edLeft: TSpinEdit;
    edTop: TSpinEdit;
    edRight: TSpinEdit;
    edBottom: TSpinEdit;
    labText1: TLabel;
    labText4: TLabel;
    labText3: TLabel;
    labText2: TLabel;
    labPromt: TLabel;
    labTotal: TLabel;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    bevSeparator: TBevel;
    shBottomRect: TShape;
    labPower: TLabel;
    imgLEDs: TImage;
    imgPower: TImage;
    procedure edLeftChange(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function ShowModalEx(var aLeft, aTop, aRight, aBottom: Integer): TModalResult;
  end;

var
  frmLightsCountDlg: TfrmLightsCountDlg;

implementation

uses uMain;

{$R *.dfm}

function TfrmLightsCountDlg.ShowModalEx(var aLeft, aTop, aRight, aBottom: Integer): TModalResult;
begin
  edLeft.Value   := aLeft  ;
  edTop.Value    := aTop   ;
  edRight.Value  := aRight ;
  edBottom.Value := aBottom;

  edTop.OnChange(edTop);

  Result:=ShowModal;

  If Result <> mrOk then Exit;

  aLeft   := edLeft.Value  ;
  aTop    := edTop.Value   ;
  aRight  := edRight.Value ;
  aBottom := edBottom.Value;
end;

procedure TfrmLightsCountDlg.edLeftChange(Sender: TObject);
  function GetLEDNameEndings(aCount: Integer): String;
  begin
    If aCount < 20 then
      Case aCount of
        0, 5..19: Result:='светодиодов';
               1: Result:='светодиод';
            2..4: Result:='светодиода';
      End
    Else
      Case aCount mod 10 of
        0, 5..9: Result:='светодиодов';
              1: Result:='светодиод';
           2..4: Result:='светодиода';
      End
  end;

var
  Count: Integer;
  Power: Extended;
begin
  Count:=edLeft.Value + edTop.Value + edRight.Value + edBottom.Value;
  Power:=All * 5{V} * 0.06{A};
  
  labTotal.Caption:=Format('Итого: %d %s', [Count, GetLEDNameEndings(Count)]);
  labPower.Caption:=Format('Пиковая мощность: %.2f Вт', [Power]);

  Case Trunc(Power*100) of
       0..7499: labPower.Font.Color:=clGreen;
    7500..8999: labPower.Font.Color:=$004080FF;
  Else
            labPower.Font.Color:=clRed;
  End;
end;

procedure TfrmLightsCountDlg.btnOkClick(Sender: TObject);
var All: Integer;
begin
  All:=edLeft.Value + edTop.Value + edRight.Value + edBottom.Value;
  If All < 1 then
    Begin
      Application.MessageBox('Необходимо задать как минимум 1 светодиод!', 'Внимание', MB_ICONWARNING);
      Exit;
    End;

  If All > 1023 then
    Begin
      Application.MessageBox('Необходимо задать не более 1023 светодиодов суммарно!', 'Внимание', MB_ICONWARNING);
      Exit;
    End;

  If edLeft.Value <> edRight.Value then
    Begin
      If Application.MessageBox('Количество светодиодов слева и справа не равно! Продолжить всё равно?'#13#13'Примечание: в некоторых режимах разное количество светодиодов на противоположных сторонах может привести к дефектам отображения.', 'Вопрос', MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) <> mrYes Then
        Exit;
    End;

  If edTop.Value <> edBottom.Value then
    Begin
      If Application.MessageBox('Количество светодиодов сверху и снизу не равно! Продолжить всё равно?'#13#13'Примечание: в некоторых режимах разное количество светодиодов на противоположных сторонах может привести к дефектам отображения.', 'Вопрос', MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2) <> mrYes Then
        Exit;
    End;

  ModalResult:=mrOk
end;

procedure TfrmLightsCountDlg.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TfrmLightsCountDlg.FormCreate(Sender: TObject);
begin
  If Assigned(iconLeds) then
    Begin
      imgLEDs.Picture.Assign(iconLeds);
      imgLEDs.AutoSize:=True;
      imgLEDs.AutoSize:=False;
      imgLEDs.Top:=labTotal.Top - (imgLEDs.Height - labTotal.Height) div 2;
      imgLEDs.Visible:=True;
      labTotal.Left:=imgLEDs.Left + imgLEDs.Width + 4;
    End
  else
    labTotal.Left:=8;
  labTotal.Width:=ClientWidth - labTotal.Left - 8;

  If Assigned(iconPower) then
    Begin
      imgPower.Picture.Assign(iconPower);
      imgPower.AutoSize:=True;
      imgPower.AutoSize:=False;
      imgPower.Top:=labPower.Top - (imgPower.Height - labPower.Height) div 2;
      imgPower.Visible:=True;
      labPower.Left:=imgPower.Left + imgPower.Width + 4;
    End
  else
    labPower.Left:=8;
  labPower.Width:=ClientWidth - labPower.Left - 8;
end;

end.
