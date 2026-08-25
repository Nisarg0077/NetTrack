[Setup]
AppId={{2A8E1D9F-7B3C-4E2F-A5C8-1D9F7B3C4E2F}
AppName=NetTrack
AppVersion=1.1.0
AppPublisher=NetTrack
DefaultDirName={autopf}\NetTrack
DisableProgramGroupPage=yes
OutputDir=D:\PROG\Flutter\dataUsageTracker\installer
OutputBaseFilename=NetTrack_Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "D:\PROG\Flutter\dataUsageTracker\build\windows\x64\runner\Release\net_track.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\PROG\Flutter\dataUsageTracker\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\NetTrack"; Filename: "{app}\net_track.exe"
Name: "{autodesktop}\NetTrack"; Filename: "{app}\net_track.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\net_track.exe"; Description: "{cm:LaunchProgram,NetTrack}"; Flags: nowait postinstall skipifsilent
