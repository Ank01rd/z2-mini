; ============================================================
;  Z2 Mini � ��������� ����� ���������� (Liquid Glass Edition)
;  ������: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" z2mini.iss
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
OutputDir=out
OutputBaseFilename=z2_mini_setup_v{#MyAppVersion}
SetupIconFile=..\assets\lock.ico
WizardSmallImageFile=..\assets\z2m_black_logo_256.png
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
Source: "app\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

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
  BG   = $140E0B;   // #0B0E14 � ��� ����
  CARD = $161414;   // #141416 � ���� �����/������
  TXT  = $F8F6F8;   // #F5F6F8 � �����
  ACC  = $FAA560;   // #60A5FA � ������

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
    end;
    if Ctl is TWinControl then
      ColorAll(TWinControl(Ctl));
  end;
end;

procedure InitializeWizard();
begin
  WizardForm.Font.Name := 'Segoe UI';
  WizardForm.Color := BG;
  WizardForm.OuterPage.Color := BG;
  WizardForm.InnerPage.Color := BG;
  WizardForm.PageNameLabel.Font.Color := ACC;
  WizardForm.PageDescriptionLabel.Font.Color := TXT;
  ColorAll(WizardForm.OuterPage);
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  ColorAll(WizardForm.InnerPage);
end;
