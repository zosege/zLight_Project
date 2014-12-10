program LightPackServer;

uses
  Forms,
  uMain in 'uMain.pas' {frmMain},
  uWorkerLightPack in 'uWorkerLightPack.pas',
  uConst in 'uConst.pas',
  uPreviewOptions in 'uPreviewOptions.pas' {frmPreview},
  uFullscreenWatcher in 'uFullscreenWatcher.pas',
  uCOM in 'uCOM.pas',
  uLightsCountDlg in 'uLightsCountDlg.pas' {frmLightsCountDlg};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'zLight';
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmPreview, frmPreview);
  Application.CreateForm(TfrmLightsCountDlg, frmLightsCountDlg);
  Application.Run;
end.
