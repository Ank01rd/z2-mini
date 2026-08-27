; ============================================================
;  Z2 Mini � ��������� ����� ���������� (Liquid Glass Edition)
;  �����: ���������� ����, ������������� ������ ������
; ============================================================
#define MyAppName "Z2 Mini"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "Ank01rd"
#define MyAppURL "https://github.com/Ank01rd/ZapretManager"
#define MyAppExe "z2_mini.exe"

[Setup]
AppId={{Z2MINI-2025-LIQUIDGLASS}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\Z2Mini
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=C:\Users\nikit\Desktop\z2_mini\installer\out
OutputBaseFilename=z2_mini_setup_v{#MyAppVersion}
SetupIconFile=C:\Users\nikit\Desktop\z2_mini\assets\lock.ico
WizardSmallImageFile=C:\Users\nikit\Desktop\z2_mini\assets\z2m_black_logo_256.png
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#MyAppName}
VersionInfoVersion={#MyAppVersion}.0
DisableWelcomePage=yes
DisableProgramGroupPage=yes

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "����� �� ������� �����"; Flags: checkedonce
Name: "autostart"; Description: "��������� ������ � Windows"; Flags: unchecked

[Files]
Source: "C:\Users\nikit\Desktop\z2_mini\installer\app\*"; DestDir: "{app}"; Excludes: "out\*,z2mini.iss"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: autostart

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "��������� {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill"; Parameters: "/IM {#MyAppExe} /F"; Flags: runhidden; RunOnceId: "KillZ2"
Filename: "schtasks"; Parameters: "/Delete /TN ""Z2-AutoStart"" /F"; Flags: runhidden; RunOnceId: "DelTask"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
const
  BG   = $140E0B;
  CARD = $161414;
  TXT  = $F8F6F8;
  ACC  = $FAA560;

procedure ColorAll(Parent: TWinControl);
var
  I: Integer;
  Ctl: TControl;
begin
  for I := 0 to Parent.ControlCount - 1 do
  begin
    Ctl := Parent.Controls[I];
    if Ctl is TNewStaticText then
      TNewStaticText(Ctl).Font.Color := TXT
    else if Ctl is TLabel then
      TLabel(Ctl).Font.Color := TXT
    else if Ctl is TCheckBox then
      TCheckBox(Ctl).Font.Color := TXT
    else if Ctl is TNewCheckBox then
      TNewCheckBox(Ctl).Font.Color := TXT
    else if Ctl is TRadioButton then
      TRadioButton(Ctl).Font.Color := TXT
    else if Ctl is TEdit then
    begin
      TEdit(Ctl).Color := CARD;
      TEdit(Ctl).Font.Color := TXT;
    end
    else if Ctl is TComboBox then
    begin
      TComboBox(Ctl).Color := CARD;
      TComboBox(Ctl).Font.Color := TXT;
    end
    else if Ctl is TListBox then
    begin
      TListBox(Ctl).Color := CARD;
      TListBox(Ctl).Font.Color := TXT;
    end
    else if Ctl is TNewCheckListBox then
    begin
      TNewCheckListBox(Ctl).Color := CARD;
      TNewCheckListBox(Ctl).Font.Color := TXT;
    end;
    if Ctl is TWinControl then
      ColorAll(TWinControl(Ctl));
  end;
end;

procedure PaintPages();
begin
  WizardForm.Color := BG;
  WizardForm.MainPanel.Color := BG;
  WizardForm.InnerPage.Color := BG;
  WizardForm.WelcomePage.Color := BG;
  WizardForm.FinishedPage.Color := BG;
  WizardForm.SelectDirPage.Color := BG;
  WizardForm.SelectTasksPage.Color := BG;
  WizardForm.ReadyPage.Color := BG;
  WizardForm.PreparingPage.Color := BG;
  WizardForm.InstallingPage.Color := BG;
end;

procedure InitializeWizard();
begin
  WizardForm.Font.Name := 'Segoe UI';
  PaintPages();
  WizardForm.MainPanel.Color := BG;
  WizardForm.PageNameLabel.Font.Color := ACC;
  WizardForm.PageDescriptionLabel.Font.Color := TXT;
  WizardForm.TasksList.Color := CARD;
  WizardForm.TasksList.Font.Color := TXT;
  WizardForm.DirEdit.Color := CARD;
  WizardForm.DirEdit.Font.Color := TXT;
  ColorAll(WizardForm);
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  PaintPages();
  WizardForm.MainPanel.Color := BG;
  ColorAll(WizardForm.InnerPage);
end;