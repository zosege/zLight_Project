unit uFullscreenWatcher;

interface

uses uConst, WinSVC, Classes, Windows, Forms;

const
  DWMServiceName = 'UxSms';

type
  TFullscreenState = (fssYes, fssNo, fssUnknown);
  TDWMState        = (dwmActive, dwmDisabled, dwmUnknown);
  TFullscreenEvent = procedure (aHandle: THandle; aRect: TRect) of object;
  
  TFullScreenWatcher = class(TThread)
     constructor Create(CreateSuspended: Boolean);
  private
    { Private declarations }
    NeedRun: Boolean;
    Active: Boolean;
    State: TFullscreenState;
    DWMWasState: TDWMState;
    DWMNowState: TDWMState;
    FOnStarted: TFullscreenEvent;
    FOnStopped: TFullscreenEvent;
  protected
    { Protected declarations }
    function  GetDWMState: TDWMState;
    procedure EnableDWM;
    procedure DisableDWM;
  public
    { Public declarations }

    procedure Execute; override;
    procedure Done;
    procedure SetEvents(aStartedProc, aStoppedProc: TFullscreenEvent);
    procedure SetDWMActive(aState: Boolean);
    procedure FullscreenStarted;
    procedure FullscreenStopped;
  end;

implementation

uses uMain;

constructor TFullScreenWatcher.Create(CreateSuspended: Boolean);
begin
  Inherited;
  Self.FreeOnTerminate:=False;
  Self.Suspended:=CreateSuspended;
  Self.NeedRun:=True;
  Self.Priority:=tpLower;
  Self.Active:=False;
  Self.State:=fssUnknown;
  Self.DWMWasState:=dwmUnknown;
  Self.DWMNowState:=dwmUnknown;
  Self.FOnStarted:=Nil;
  Self.FOnStopped:=Nil;
end;

procedure TFullScreenWatcher.Execute;
var
  aHandle: HWND;
  aRect: TRect;
begin

  While (Self.NeedRun) Do
    Begin
      Sleep(100); // вполне хватит 10 раз в секунду проверять

      aHandle:=GetForegroundWindow;
      If not GetWindowRect(aHandle, aRect)        then Continue;

      If (aRect.Left   <> Screen.Monitors[0].Left  ) or
         (aRect.Top    <> Screen.Monitors[0].Top   ) or
         (aRect.Right  <> Screen.Monitors[0].Width ) or
         (aRect.Bottom <> Screen.Monitors[0].Height) then
        Begin
          If Self.State = fssYes then
            Begin
              If Self.Active then Self.FullscreenStopped;
              If Assigned(Self.FOnStopped) then Self.FOnStopped(aHandle, aRect);
            End;
          Self.State:=fssNo;
        End
      Else
        Begin
          If Self.State = fssNo then
            Begin
              If Self.Active then Self.FullscreenStarted;
              If Assigned(Self.FOnStarted) then Self.FOnStarted(aHandle, aRect);
            End;
          Self.State:=fssYes;
        End
    end; // while
end;

procedure TFullScreenWatcher.Done;
begin
  Self.NeedRun:=False;
end;

procedure TFullScreenWatcher.SetEvents(aStartedProc, aStoppedProc: TFullscreenEvent);
begin
  if Assigned(aStartedProc) then
    Self.FOnStarted:=aStartedProc;

  if Assigned(aStoppedProc) then
    Self.FOnStopped:=aStoppedProc;
end;

procedure TFullScreenWatcher.SetDWMActive(aState: Boolean);
begin
  Self.Active:=aState;
  If aState = False then
    begin
      If (Self.DWMNowState <> Self.DWMWasState) and (Self.DWMWasState <> dwmUnknown) then
        Self.FullscreenStopped;
    end;
end;

procedure TFullScreenWatcher.FullscreenStarted;
begin
  Self.DWMWasState:=GetDWMState;

  If Self.DWMWasState = dwmDisabled then
    Self.DWMNowState:=dwmDisabled // nothing to do...
  Else
    begin
      DisableDWM;
      Self.DWMNowState:=GetDWMState;
    end;
end;

procedure TFullScreenWatcher.FullscreenStopped;
begin
  Self.DWMWasState:=GetDWMState;

  If Self.DWMWasState = dwmActive then
    Self.DWMNowState:=dwmActive // nothing to do...
  Else
    begin
      EnableDWM;
      Self.DWMNowState:=GetDWMState;
    end;
end;

function TFullScreenWatcher.GetDWMState: TDWMSTate;
  function ServiceGetStatus(sMachine, sService: string ): DWord;
    var
      h_manager,h_svc    : SC_Handle;
      service_status     : TServiceStatus;
      hStat : DWord;
    begin
      hStat := 1;
      h_manager := OpenSCManager(PChar(sMachine) ,Nil, SC_MANAGER_CONNECT);
      if h_manager > 0 then
        begin
           h_svc := OpenService(h_manager,PChar(sService), SERVICE_QUERY_STATUS);
           if h_svc > 0 then
             begin
               if(QueryServiceStatus(h_svc, service_status)) then
                 hStat := service_status.dwCurrentState;
               CloseServiceHandle(h_svc);
             end;
           CloseServiceHandle(h_manager);
        end;
      Result := hStat;
    end;
begin
  Case ServiceGetStatus('', DWMServiceName) of
    SERVICE_STOPPED:          Result:=dwmDisabled;
    SERVICE_RUNNING:          Result:=dwmActive;
    SERVICE_PAUSED:           Result:=dwmDisabled;
    SERVICE_START_PENDING:    Result:=dwmActive;
    SERVICE_STOP_PENDING:     Result:=dwmDisabled;
    SERVICE_CONTINUE_PENDING: Result:=dwmActive;
    SERVICE_PAUSE_PENDING:    Result:=dwmDisabled;
  Else
    Result:=dwmUnknown;
  End;
end;

procedure TFullScreenWatcher.EnableDWM;
  function ServiceStart(aMachine, aServiceName : string ) : boolean;
  // aMachine это UNC путь, либо локальный компьютер если пусто
  var
    h_manager,h_svc: SC_Handle;
    svc_status: TServiceStatus;
    Temp: PChar;
    dwCheckPoint: DWord;
  begin
    svc_status.dwCurrentState := 1;
    h_manager := OpenSCManager(PChar(aMachine), Nil, SC_MANAGER_CONNECT);
    if h_manager > 0 then
      begin
        h_svc := OpenService(h_manager, PChar(aServiceName), SERVICE_START or SERVICE_QUERY_STATUS);
        if h_svc > 0 then
          begin
            temp := nil;
            if (StartService(h_svc,0,temp)) then
              if (QueryServiceStatus(h_svc,svc_status)) then
                begin
                  while (SERVICE_RUNNING <> svc_status.dwCurrentState) do
                    begin
                      dwCheckPoint := svc_status.dwCheckPoint;
                      Sleep(svc_status.dwWaitHint);
                      if (not QueryServiceStatus(h_svc,svc_status)) then
                        break;
                      if (svc_status.dwCheckPoint < dwCheckPoint) then
                        begin
                         // QueryServiceStatus не увеличивает dwCheckPoint
                         break;
                        end;

                    end;

                end;
            CloseServiceHandle(h_svc);
          end;
        CloseServiceHandle(h_manager);
      end;
    Result := SERVICE_RUNNING = svc_status.dwCurrentState;
  end;
begin
  ServiceStart('', DWMServiceName);
end;

procedure TFullScreenWatcher.DisableDWM;
  function ServiceStop(aMachine,aServiceName : string ) : boolean;
  // aMachine это UNC путь, либо локальный компьютер если пусто
  var
    h_manager,h_svc   : SC_Handle;
    svc_status     : TServiceStatus;
    dwCheckPoint : DWord;
  begin
    h_manager:=OpenSCManager(PChar(aMachine),nil, SC_MANAGER_CONNECT);
    if h_manager > 0 then
      begin
         h_svc := OpenService(h_manager,PChar(aServiceName), SERVICE_STOP or SERVICE_QUERY_STATUS);
         if h_svc > 0 then
           begin
             if(ControlService(h_svc,SERVICE_CONTROL_STOP, svc_status))then
               begin
                 if(QueryServiceStatus(h_svc,svc_status))then
                   begin
                     while(SERVICE_STOPPED <> svc_status.dwCurrentState)do
                       begin
                         dwCheckPoint := svc_status.dwCheckPoint;
                         Sleep(svc_status.dwWaitHint);
                         if (not QueryServiceStatus(h_svc,svc_status)) then
                           begin
                             // couldn't check status
                             break;
                           end;
                         if(svc_status.dwCheckPoint < dwCheckPoint)then
                           break;
                       end;
                   end;
               end;
             CloseServiceHandle(h_svc);
           end;
         CloseServiceHandle(h_manager);
      end;
    Result := SERVICE_STOPPED = svc_status.dwCurrentState;
  end;
begin
  ServiceStop('', DWMServiceName);
end;

end.
