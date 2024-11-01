#ifndef AppVersion
#define AppVersion "1.0"
#endif

#define AppName "camconnect"
#define CaptureName "CamConnect Video Capture"
#define AppPublisher "davidsahani@github.com"
#define AppURL "https://github.com/davidsahani/camconnect"
#define AppExeName AppName + ".exe"

[Setup]
AppId={{C092631D-4445-4428-816C-6EDCAA190259}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
PrivilegesRequired=admin
OutputDir=build
OutputBaseFilename={#AppName}-setup
SetupIconFile=camconnect\assets\logo.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\{#AppName}\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\{#AppName}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
; Register 32-bit filter during install
Filename: "regsvr32.exe"; Parameters: "/i:UnityCaptureName=""{#CaptureName}"" ""{app}\filters\UnityCaptureFilter32.dll"""; Check: Is32Bit
; Register 64-bit filter during install
Filename: "regsvr32.exe"; Parameters: "/i:UnityCaptureName=""{#CaptureName}"" ""{app}\filters\UnityCaptureFilter64.dll"""; Check: Is64Bit

[UninstallRun]
; Unregister 32-bit filter during uninstall
Filename: "regsvr32.exe"; Parameters: "/u ""{app}\filters\UnityCaptureFilter32.dll"""; Check: Is32Bit; RunOnceId: "Unregister32BitFilter"
; Unregister 64-bit filter during uninstall
Filename: "regsvr32.exe"; Parameters: "/u ""{app}\filters\UnityCaptureFilter64.dll"""; Check: Is64Bit; RunOnceId: "Unregister64BitFilter"

[Code]
// Check if system is 32-bit
function Is32Bit: Boolean;
begin
  Result := (ProcessorArchitecture = paX86);
end;

// Check if system is 64-bit
function Is64Bit: Boolean;
begin
  Result := (ProcessorArchitecture = paX64);
end;