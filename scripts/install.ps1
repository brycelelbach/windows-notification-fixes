[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$PackageRoot=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$id='local@compact-notifications-background'
$base='HKLM:\SOFTWARE\Windhawk\Engine\Mods'
$key=Join-Path $base $id
$original=Join-Path $base 'compact-notifications'
$dataRoot=Join-Path $env:ProgramData 'Windhawk'
$profilePath=Join-Path $dataRoot 'userprofile.json'
$sourcePath=Join-Path $dataRoot "ModsSource\$id.wh.cpp"
$dist=Join-Path $PackageRoot 'dist'
$manifest=Get-Content -Raw -LiteralPath (Join-Path $dist 'manifest.json') | ConvertFrom-Json
if($manifest.modId -ne $id -or $manifest.architecture -ne 'x86-64'){throw 'Unexpected package identity'}
if(-not [Environment]::Is64BitProcess -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64'){throw 'Use x64 PowerShell on x64 Windows'}
if(!(Test-Path -LiteralPath $profilePath)){throw 'Install Windhawk in standard mode and open it once first'}
$installedWh=(Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Windhawk' -ErrorAction SilentlyContinue).DisplayVersion
if(-not $installedWh){$installedWh=(Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Windhawk' -ErrorAction SilentlyContinue).DisplayVersion}
if(-not $installedWh -and (Test-Path -LiteralPath (Join-Path $env:ProgramFiles 'Windhawk\windhawk.exe'))){$installedWh=(Get-Item -LiteralPath (Join-Path $env:ProgramFiles 'Windhawk\windhawk.exe')).VersionInfo.ProductVersion}
if($installedWh -notin @($manifest.windhawkVersion,($manifest.windhawkVersion+'.0'))){throw "This build requires Windhawk $($manifest.windhawkVersion); found '$installedWh'. Use the source installation method for other versions."}
foreach($entry in $manifest.files.PSObject.Properties){
 if([IO.Path]::GetFileName($entry.Name) -ne $entry.Name){throw 'Manifest filename must not contain a path'}
 if((Get-FileHash -LiteralPath (Join-Path $dist $entry.Name) -Algorithm SHA256).Hash -ne $entry.Value){throw "Checksum mismatch: $($entry.Name)"}
}
$dllName="$($id)_$($manifest.modVersion)_64.dll"
if(-not $manifest.files.PSObject.Properties[$dllName] -or -not $manifest.files.PSObject.Properties['compact-notifications.wh.cpp']){throw 'Incomplete build manifest'}
$windowsSound=Join-Path $env:WINDIR 'Media\Windows Notify Calendar.wav'
if(!(Test-Path -LiteralPath $windowsSound)){throw 'Windows calendar sound is missing; use manual settings and choose your own sound'}
$assetRoot=Join-Path $env:ProgramData 'WindowsNotificationFixes'
$soundPath=Join-Path $assetRoot 'calendar-ding.wav'
$backup=Join-Path $assetRoot ('backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,8))
if(-not $PSCmdlet.ShouldProcess("$key; $sourcePath", "Install mod $($manifest.modVersion), copy the Windows ding, and set 60 seconds; backup to $backup")){return}
$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run PowerShell as administrator'}
$session=[Diagnostics.Process]::GetCurrentProcess().SessionId
function Get-LoadedFix {
 @(Get-Process -Name explorer,ShellExperienceHost -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | ForEach-Object { @($_.Modules) | Where-Object ModuleName -like 'local@compact-notifications-background*' | ForEach-Object ModuleName })
}
function Write-Profile($profile) { [IO.File]::WriteAllText($profilePath,($profile | ConvertTo-Json -Depth 40),[Text.UTF8Encoding]::new($false)) }
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$hadMod=Test-Path -LiteralPath $key
$profile=Get-Content -Raw -LiteralPath $profilePath | ConvertFrom-Json
$state=@{modId=$id;hadMod=$hadMod;hadSource=(Test-Path -LiteralPath $sourcePath);hadOriginal=(Test-Path -LiteralPath $original);modProfile=$profile.mods.$id;originalProfile=$profile.mods.'compact-notifications';soundExisted=(Test-Path -LiteralPath $soundPath);messageDuration=(Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Accessibility' -Name MessageDuration).MessageDuration}
if($hadMod){
 & reg.exe export "HKLM\SOFTWARE\Windhawk\Engine\Mods\$id" (Join-Path $backup 'mod.reg') /y | Out-Null
 if($LASTEXITCODE){throw 'Registry backup failed'}
}
if($state.hadSource){Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $backup 'source.wh.cpp')}
if($state.hadOriginal){$state.originalDisabled=(Get-ItemProperty -LiteralPath $original).Disabled}
if($state.soundExisted){Copy-Item -LiteralPath $soundPath -Destination (Join-Path $backup 'calendar-ding.wav')}
$state | Export-Clixml -LiteralPath (Join-Path $backup 'state.clixml')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'restore.ps1') -Destination (Join-Path $backup 'restore.ps1')
$changed=$false
try {
 $changed=$true
 if($hadMod){Set-ItemProperty -LiteralPath $key -Name Disabled -Value 1}
 if($state.hadOriginal){Set-ItemProperty -LiteralPath $original -Name Disabled -Value 1}
 for($i=0;$i -lt 40 -and (Get-LoadedFix).Count -gt 0;$i++){Start-Sleep -Milliseconds 500}
 if((Get-LoadedFix).Count -gt 0){throw 'Previous mod did not unload'}
 foreach($dir in @((Join-Path $dataRoot 'Engine\Mods\64'),(Join-Path $dataRoot 'ModsSource'),$assetRoot)){New-Item -ItemType Directory -Path $dir -Force | Out-Null}
 Copy-Item -LiteralPath (Join-Path $dist $dllName) -Destination (Join-Path $dataRoot "Engine\Mods\64\$dllName") -Force
 Copy-Item -LiteralPath (Join-Path $dist 'compact-notifications.wh.cpp') -Destination $sourcePath -Force
 Copy-Item -LiteralPath $windowsSound -Destination $soundPath -Force
 if(!(Test-Path -LiteralPath $key)){New-Item -Path $key -Force | Out-Null}
 $strings=@{LibraryFileName=$dllName;Include='ShellExperienceHost.exe|explorer.exe';Exclude='';Architecture='x86-64';Version=$manifest.modVersion}
 if(-not $hadMod){$strings.IncludeCustom='';$strings.ExcludeCustom=''}
 foreach($entry in $strings.GetEnumerator()){New-ItemProperty -LiteralPath $key -Name $entry.Key -Value $entry.Value -PropertyType String -Force | Out-Null}
 if(-not $hadMod){foreach($name in @('LoggingEnabled','DebugLoggingEnabled','IncludeExcludeCustomOnly','PatternsMatchCriticalSystemProcesses')){New-ItemProperty -LiteralPath $key -Name $name -Value 0 -PropertyType DWord -Force | Out-Null}}
 $settings=Join-Path $key 'Settings'
 if(!(Test-Path -LiteralPath $settings)){New-Item -Path $settings -Force | Out-Null}
 $defaults=@{
  'appearance.theme'='light';'appearance.size'=100;'appearance.maxLines'=3;'appearance.width'=420;'appearance.cornerRadius'=12;'appearance.opacity'=100;'appearance.cardColor'='#FFE066';'appearance.textColor'='#1B1B1B';'appearance.margin'=8;
  'avatars.show'=1;'avatars.shape'='circle';'avatars.appName'=1;'animation.enabled'=1;'animation.playful'=0;'animation.speed'=100;'animation.maxCards'=10;
  'position.monitor'='primary';'position.corner'='topRight';'behavior.showActions'=1;'behavior.copyCodes'=1;'behavior.copyInSystemLanguage'=1;'behavior.markdown'=1;'behavior.highlightPriority'=1;'behavior.unmuteAll'=0;'behavior.priorityColor'='#F0A020';
  'sound.mode'='card';'sound.outlookClosedReminders'=1;'appRules[0].app'='';'appRules[0].show'='card';'appRules[0].buttons'=1;'appRules[0].replyBox'=1;'appRules[0].avatar'=1
 }
 foreach($entry in $defaults.GetEnumerator()){
  if(-not (Get-Item -LiteralPath $settings).GetValueNames().Contains($entry.Key)){
   $kind=if($entry.Value -is [int]){'DWord'}else{'String'}
   New-ItemProperty -LiteralPath $settings -Name $entry.Key -Value $entry.Value -PropertyType $kind -Force | Out-Null
  }
 }
 New-ItemProperty -LiteralPath $settings -Name 'sound.file' -Value $soundPath -PropertyType String -Force | Out-Null
 New-ItemProperty -LiteralPath $key -Name SettingsChangeTime -Value ([int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -band 0x7fffffff)) -PropertyType DWord -Force | Out-Null
 # Read again to preserve other mods changed since the backup.
 $profile=Get-Content -Raw -LiteralPath $profilePath | ConvertFrom-Json
 $profile.mods | Add-Member -NotePropertyName $id -NotePropertyValue ([pscustomobject]@{version=$manifest.modVersion}) -Force
 if($profile.mods.'compact-notifications'){$profile.mods.'compact-notifications' | Add-Member -NotePropertyName disabled -NotePropertyValue $true -Force}
 Write-Profile $profile
 Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NotificationDurationInstaller { [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint action,uint param,IntPtr value,uint flags); }'
 if(-not [NotificationDurationInstaller]::SystemParametersInfo(0x2017,0,[IntPtr]60,3)){throw 'Could not set notification duration'}
 New-ItemProperty -LiteralPath $key -Name Disabled -Value 0 -PropertyType DWord -Force | Out-Null
 for($i=0;$i -lt 40 -and $dllName -notin (Get-LoadedFix);$i++){Start-Sleep -Milliseconds 500}
 if($dllName -notin (Get-LoadedFix)){throw 'New mod did not load in Explorer'}
 $receipt=@{success=$true;version=$manifest.modVersion;backup=$backup;loaded=(Get-LoadedFix);sound=$soundPath;duration=60;at=[DateTimeOffset]::Now.ToString('o')}
 $receipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $assetRoot 'last-install.json') -Encoding UTF8
 $receipt | ConvertTo-Json
} catch {
 $failure=$_.Exception.Message
 if($changed){ & (Join-Path $backup 'restore.ps1') -BackupPath $backup -Confirm:$false }
 throw "Installation failed and rollback was attempted: $failure. Backup: $backup"
}
