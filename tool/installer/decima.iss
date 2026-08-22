; Instalador Windows do Decima — Inno Setup 6.3+
;
; Não compilar este arquivo direto: use tool/installer/build_installer.sh,
; que sincroniza a cópia de build no Windows, gera o release e define os
; símbolos abaixo. Os caminhos são relativos a este .iss.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

#define AppName "Decima"
#define AppPublisher "Wevasoft"
#define AppExeName "decima.exe"
#define AppUrl "https://github.com/wevertonj/decima"

[Setup]
; AppId identifica o produto entre versões — nunca alterar, senão upgrades
; passam a instalar lado a lado em vez de substituir.
AppId={{E20ED7B0-F0D6-478C-936B-55AFB6081BA4}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases
VersionInfoVersion={#AppVersion}
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}

; Instalação por usuário (%LOCALAPPDATA%\Programs\Decima) — sem prompt de UAC.
; 'commandline' (e não 'dialog') mantém o /ALLUSERS disponível para quem quiser
; instalar para todos, sem impor a tela de escolha de modo na abertura.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}

; x64compatible (Inno 6.3+) cobre também Windows ARM64 com emulação x64.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir={#OutputDir}
OutputBaseFilename=decima-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma2/normal
SolidCompression=yes
; Sem estas diretivas o LZMA roda single-thread dentro do proprio ISCC.exe
; (32-bit) — nesta maquina isso degenerou para ~52 KB/s (Etapa 14.1).
; O processo separado usa o islzma64.exe (64-bit) e os block threads dividem
; o fluxo em blocos comprimidos em paralelo, ao custo marginal de compressao.
LZMAUseSeparateProcess=yes
LZMANumBlockThreads=4

; Wizard mínimo: idioma (só se o sistema não casar), tarefas, instalação, fim.
WizardStyle=modern
ShowLanguageDialog=auto
DisableWelcomePage=yes
DisableDirPage=auto
DisableProgramGroupPage=yes
DisableReadyPage=yes
; Fecha o Decima aberto antes de sobrescrever os binários (upgrade in-place).
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Bundle completo do Flutter: decima.exe, flutter_windows.dll, DLLs de plugin,
; runtime C++ (staged pelo build_installer.sh) e data\ (icudtl.dat, assets, app.so).
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

; O banco e as preferências ficam em %APPDATA%\Wevasoft\Decima e sobrevivem
; à desinstalação por design — reinstalar não perde histórico.
