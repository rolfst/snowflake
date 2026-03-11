{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str enum ints;

  cfg = config.modules.desktop.virtual.winapps;
in
{
  options.modules.desktop.virtual.winapps = {
    enable = mkEnableOption "WinApps (Windows applications via RDP)";

    backend = mkOption {
      type = enum [
        "docker"
        "podman"
        "libvirt"
      ];
      default = "docker";
      description = "Virtualization backend for the Windows VM.";
    };

    rdpUser = mkOption {
      type = str;
      default = "MyWindowsUser";
      description = "Windows RDP username.";
    };

    rdpPass = mkOption {
      type = str;
      default = "MyWindowsPassword";
      description = "Windows RDP password. For production use, change this.";
    };

    rdpIp = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "IP address of the Windows VM. Use 127.0.0.1 for Docker/Podman.";
    };

    vmName = mkOption {
      type = str;
      default = "RDPWindows";
      description = "Libvirt VM name (only used with libvirt backend).";
    };

    rdpScale = mkOption {
      type = enum [
        "100"
        "140"
        "180"
      ];
      default = "100";
      description = "Display scaling factor for RDP sessions.";
    };

    docker = {
      windowsVersion = mkOption {
        type = str;
        default = "11";
        description = "Windows version for the Docker container (e.g. '10', '11').";
      };

      ramSize = mkOption {
        type = str;
        default = "4G";
        description = "RAM allocated to the Windows VM.";
      };

      cpuCores = mkOption {
        type = ints.positive;
        default = 4;
        description = "CPU cores allocated to the Windows VM.";
      };

      diskSize = mkOption {
        type = str;
        default = "64G";
        description = "Size of the primary virtual hard disk.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Core: packages, groups, kernel modules ────────────────────────
    {
      assertions = [
        {
          assertion =
            (cfg.backend == "docker" && config.modules.virtualize.docker.enable)
            || (cfg.backend == "podman" && config.modules.virtualize.podman.enable)
            || (cfg.backend == "libvirt" && config.modules.virtualize.enable);
          message = ''
            modules.desktop.virtual.winapps: backend "${cfg.backend}" requires
            the corresponding virtualization module to be enabled.
              - docker  → modules.virtualize.docker.enable = true
              - podman  → modules.virtualize.podman.enable = true
              - libvirt → modules.virtualize.enable = true
          '';
        }
      ];

      user.packages = [
        inputs.winapps.packages."${pkgs.stdenv.hostPlatform.system}".winapps
        inputs.winapps.packages."${pkgs.stdenv.hostPlatform.system}".winapps-launcher
      ];

      # winapps checks for kvm group membership explicitly
      user.extraGroups = [ "kvm" ];

      # Required for Docker networking / folder sharing with the host
      boot.kernelModules = [
        "ip_tables"
        "iptable_nat"
      ];

      # ── winapps.conf ──────────────────────────────────────────────
      create.configFile."winapps/winapps.conf" = {
        text = ''
          ##################################
          #   WINAPPS CONFIGURATION FILE   #
          ##################################

          RDP_USER="${cfg.rdpUser}"
          RDP_PASS="${cfg.rdpPass}"
          RDP_DOMAIN=""
          RDP_IP="${cfg.rdpIp}"
          VM_NAME="${cfg.vmName}"
          WAFLAVOR="${cfg.backend}"
          RDP_SCALE="${cfg.rdpScale}"
          REMOVABLE_MEDIA="/run/media"
          RDP_FLAGS="/cert:tofu /sound /microphone +home-drive"
          DEBUG="true"
          AUTOPAUSE="off"
          AUTOPAUSE_TIME="300"
          FREERDP_COMMAND=""
        '';
      };
    }

    # ── Docker backend: compose.yaml + oem files ──────────────────────
    (mkIf (cfg.backend == "docker") {
      create.configFile = {
        "winapps/compose.yaml" = {
          text = ''
            # For documentation, FAQ, additional configuration options and technical help,
            # visit: https://github.com/dockur/windows
            name: "winapps"
            volumes:
              data:
            services:
              windows:
                image: ghcr.io/dockur/windows:latest
                container_name: WinApps
                environment:
                  VERSION: "${cfg.docker.windowsVersion}"
                  RAM_SIZE: "${cfg.docker.ramSize}"
                  CPU_CORES: "${toString cfg.docker.cpuCores}"
                  DISK_SIZE: "${cfg.docker.diskSize}"
                  USERNAME: "${cfg.rdpUser}"
                  PASSWORD: "${cfg.rdpPass}"
                  HOME: "''${HOME}"
                ports:
                  - 8006:8006
                  - 3389:3389/tcp
                  - 3389:3389/udp
                cap_add:
                  - NET_ADMIN
                stop_grace_period: 120s
                restart: on-failure
                volumes:
                  - data:/storage
                  - ''${HOME}:/shared
                  - ./oem:/oem
                devices:
                  - /dev/kvm
                  - /dev/net/tun
          '';
        };

        # ── OEM post-install scripts ────────────────────────────────
        "winapps/oem/install.bat" = {
          text = ''
            @echo off
            title WinApps Setup Wizard

            :: Check for administrative privileges
            fltmc >nul 2>&1 || (
                echo [INFO] Script not running as administrator. Attempting to relaunch with elevation...
                powershell -Command "Start-Process '%~f0' -Verb runAs"
                exit /b
            )

            echo ============================================
            echo             WinApps Setup Wizard
            echo ============================================
            echo.
            echo [INFO] Starting setup...

            :: Apply RDP and system configuration tweaks
            echo [INFO] Importing "RDPApps.reg"...
            if exist "%~dp0RDPApps.reg" (
                reg import "%~dp0RDPApps.reg" >nul 2>&1
                if %ERRORLEVEL% equ 0 (
                    echo [SUCCESS] Imported "RDPApps.reg".
                ) else (
                    echo [ERROR] Failed to import "RDPApps.reg".
                )
            ) else (
                echo [ERROR] "RDPApps.reg" not found. Skipping...
            )

            :: Allow Remote Desktop connections through the firewall
            echo [INFO] Allowing Remote Desktop connections through the firewall...
            powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
              -Command "if (Get-Command Enable-NetFirewallRule -ErrorAction SilentlyContinue) { try { Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction Stop; exit 0 } catch { exit 1 } } else { exit 2 }" >nul 2>&1
            if %ERRORLEVEL% equ 0 (
                echo [SUCCESS] Firewall changes applied successfully.
            ) else (
                :: Fallback to using 'netsh' to make the firewall modification
                netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1
                if %ERRORLEVEL% equ 0 (
                    echo [SUCCESS] Firewall changes applied successfully.
                ) else (
                    echo [ERROR] Failed to apply firewall changes.
                    echo         Please manually enable Remote Desktop via 'Settings --> System --> Remote Desktop'.
                )
            )

            :: Configure the system clock to use UTC instead of local time
            if exist "%~dp0Container.reg" (
                echo [INFO] Importing "Container.reg"...
                reg import "%~dp0Container.reg" >nul 2>&1
                if %ERRORLEVEL% equ 0 (
                    echo [SUCCESS] Imported "Container.reg".
                ) else (
                    echo [ERROR] Failed to import "Container.reg".
                )
            ) else (
                echo [WARNING] "Container.reg" not found. Skipping...
            )

            :: Create a startup task to clean up stale network profiles
            echo [INFO] Creating network profile cleanup task...
            set "scriptpath=%windir%\NetProfileCleanup.ps1"
            set "taskname=WinApps_NetworkProfileCleanup"
            set "command=powershell.exe -ExecutionPolicy Bypass -File ""%scriptpath%"""

            copy /Y "%~dp0NetProfileCleanup.ps1" "%scriptpath%" >nul
            if %ERRORLEVEL% neq 0 (
                echo [ERROR] Failed to copy "NetProfileCleanup.ps1" to "%windir%".
            ) else (
                schtasks /create /tn "%taskname%" /tr "%command%" /sc onstart /ru "SYSTEM" /rl HIGHEST /f >nul 2>&1
                if %ERRORLEVEL% equ 0 (
                    echo [SUCCESS] Created scheduled task "%taskname%".
                ) else (
                    echo [ERROR] Failed to create scheduled task "%taskname%".
                )
            )

            REM Create time sync task
            copy %~dp0\TimeSync.ps1 %windir%
            set "taskname2=TimeSync"
            set "command2=powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%windir%\TimeSync.ps1\""

            schtasks /query /tn "%taskname2%" >nul
            if %ERRORLEVEL% equ 0 (
                echo %DATE% %TIME% Task "%taskname2%" already exists, skipping creation.
            ) else (
                schtasks /create /tn "%taskname2%" /tr "%command2%" /sc onlogon /rl HIGHEST /f
                if %ERRORLEVEL% equ 0 (
                    echo %DATE% %TIME% Scheduled task "%taskname2%" created successfully.
                ) else (
                    echo %DATE% %TIME% Failed to create scheduled task %taskname2%.
                )
            )
          '';
        };

        "winapps/oem/RDPApps.reg" = {
          text = ''
            Windows Registry Editor Version 5.00

            ; Enable Remote Desktop
            [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server]
            "fDenyTSConnections"=dword:00000000

            ; Require Network Level Authentication (NLA) for Remote Desktop
            [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp]
            "UserAuthentication"=dword:00000001

            ; Disable RemoteApp allowlist so all applications can be used
            [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList]
            "fDisabledAllowList"=dword:00000001

            ; Allow unlisted programs in Remote Desktop sessions
            [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services]
            "fAllowUnlistedRemotePrograms"=dword:00000001

            ; Disable Windows 11 snap bar
            [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
            "EnableSnapBar"=dword:00000000

            ; Disable automatic administrator logon at startup
            [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
            "AutoAdminLogon"="0"

            ; Always use the server keyboard layout
            [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout]
            "IgnoreRemoteKeyboardLayout"=dword:00000001

            ; Disable network discovery prompt after each host reboot
            [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff]
          '';
        };

        "winapps/oem/Container.reg" = {
          text = ''
            Windows Registry Editor Version 5.00

            [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation]
            "RealTimeIsUniversal"=dword:00000001
          '';
        };

        "winapps/oem/NetProfileCleanup.ps1" = {
          text = ''
            $currentProfile = (Get-NetConnectionProfile).Name
            $profilesKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
            $profiles = Get-ChildItem -Path $profilesKey

            foreach ($profile in $profiles) {
                $profilePath = "$profilesKey\$($profile.PSChildName)"
                $profileName = (Get-ItemProperty -Path $profilePath).ProfileName
                if ($profileName -ne $currentProfile) {
                    Remove-Item -Path $profilePath -Recurse
                    Write-Host "Deleted profile: $profileName"
                }
            }

            $profiles = Get-ChildItem -Path $profilesKey
            foreach ($profile in $profiles) {
                $profilePath = "$profilesKey\$($profile.PSChildName)"
                $profileName = (Get-ItemProperty -Path $profilePath).ProfileName
                if ($profileName -eq $currentProfile) {
                    Set-ItemProperty -Path $profilePath -Name "ProfileName" -Value "WinApps"
                    Write-Host "Renamed profile to: WinApps"
                }
            }
          '';
        };

        "winapps/oem/TimeSync.ps1" = {
          text = ''
            $filePath = "\\tsclient\home\.local\share\winapps\sleep_marker"
            $networkPath = "\\tsclient\home"

            function Monitor-File {
                while ($true) {
                    try {
                        $null = Test-Path -Path $networkPath -ErrorAction Stop
                        if (Test-Path -Path $filePath) {
                            w32tm /resync /quiet
                            Remove-Item -Path $filePath -Force
                        }
                    }
                    catch {
                        # Network location not available, continue monitoring
                    }
                    Start-Sleep -Seconds 3000
                }
            }

            Monitor-File
          '';
        };
      };
    })
  ]);
}
