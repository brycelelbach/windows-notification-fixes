[CmdletBinding(SupportsShouldProcess=$true)]
param([Parameter(Mandatory=$true)][string]$BackupPath)
$ErrorActionPreference='Stop'
$backup=(Resolve-Path -LiteralPath $BackupPath).Path
$expectedRoot=[IO.Path]::GetFullPath((Join-Path $env:ProgramData 'WindowsNotificationFixes\backups'))+[IO.Path]::DirectorySeparatorChar
if(-not ($backup+[IO.Path]::DirectorySeparatorChar).StartsWith($expectedRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Backup must be inside ProgramData\WindowsNotificationFixes\backups'}
$state=Import-Clixml -LiteralPath (Join-Path $backup 'state.clixml')
$id='local@compact-notifications-background'
if($state.modId -ne $id){throw 'Unexpected backup identity'}
$key="HKLM:\SOFTWARE\Windhawk\Engine\Mods\$id"
$original='HKLM:\SOFTWARE\Windhawk\Engine\Mods\compact-notifications'
$data=Join-Path $env:ProgramData 'Windhawk'
$source=Join-Path $data "ModsSource\$id.wh.cpp"
$sound=Join-Path $env:ProgramData 'WindowsNotificationFixes\calendar-ding.wav'
if(-not $PSCmdlet.ShouldProcess($key,"Restore only this mod and its previous settings from $backup")){return}
$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run PowerShell as administrator'}
if(Test-Path -LiteralPath $key){Set-ItemProperty -LiteralPath $key -Name Disabled -Value 1}
$session=[Diagnostics.Process]::GetCurrentProcess().SessionId
for($i=0;$i -lt 40;$i++){
 $loaded=@(Get-Process -Name explorer,ShellExperienceHost -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | ForEach-Object { @($_.Modules) | Where-Object ModuleName -like 'local@compact-notifications-background*' })
 if($loaded.Count -eq 0){break}; Start-Sleep -Milliseconds 500
}
if($loaded.Count){throw 'Mod did not unload; backup remains intact'}
# Constant, validated registry subtree only; no filesystem directory is deleted.
if(Test-Path -LiteralPath $key){Remove-Item -LiteralPath $key -Recurse -Force}
if($state.hadMod){ & reg.exe import (Join-Path $backup 'mod.reg') | Out-Null; if($LASTEXITCODE){throw 'Registry restore failed'} }
if($state.hadSource){Copy-Item -LiteralPath (Join-Path $backup 'source.wh.cpp') -Destination $source -Force}
elseif(Test-Path -LiteralPath $source){Remove-Item -LiteralPath $source}
if($state.hadOriginal){Set-ItemProperty -LiteralPath $original -Name Disabled -Value $state.originalDisabled}
if($state.soundExisted){Copy-Item -LiteralPath (Join-Path $backup 'calendar-ding.wav') -Destination $sound -Force}
elseif(Test-Path -LiteralPath $sound){Remove-Item -LiteralPath $sound}
$profilePath=Join-Path $data 'userprofile.json'
$profile=Get-Content -Raw -LiteralPath $profilePath | ConvertFrom-Json
foreach($entry in @(@{name=$id;value=$state.modProfile},@{name='compact-notifications';value=$state.originalProfile})){
 if($null -ne $entry.value){$profile.mods | Add-Member -NotePropertyName $entry.name -NotePropertyValue $entry.value -Force}
 else{$profile.mods.PSObject.Properties.Remove($entry.name)}
}
[IO.File]::WriteAllText($profilePath,($profile | ConvertTo-Json -Depth 40),[Text.UTF8Encoding]::new($false))
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NotificationDurationRestore { [DllImport("user32.dll", SetLastError=true)] public static extern bool SystemParametersInfo(uint action,uint param,IntPtr value,uint flags); }'
if(-not [NotificationDurationRestore]::SystemParametersInfo(0x2017,0,[IntPtr]([int]$state.messageDuration),3)){throw 'Could not restore display duration'}
@{restored=$true;backup=$backup;at=[DateTimeOffset]::Now.ToString('o')} | ConvertTo-Json
