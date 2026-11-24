$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$out=Join-Path $root 'artifacts'
$stage=Join-Path $out ('package-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
foreach($item in @('src','tests','scripts','docs','README.md','NOTICE','LICENSE','VERSION')){Copy-Item -LiteralPath (Join-Path $root $item) -Destination $stage -Recurse}
$dist=Join-Path $root 'dist'
$manifest=Get-Content -LiteralPath (Join-Path $dist 'manifest.json') -Raw | ConvertFrom-Json
$stageDist=Join-Path $stage 'dist'
New-Item -ItemType Directory -Path $stageDist | Out-Null
foreach($file in @('manifest.json')+@($manifest.files.PSObject.Properties.Name)){
 if([IO.Path]::GetFileName($file) -ne $file){throw 'Manifest path must be a filename'}
 Copy-Item -LiteralPath (Join-Path $dist $file) -Destination $stageDist
}
$zip=Join-Path $out "windows-notification-fixes-v$version.zip"
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
$hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $([IO.Path]::GetFileName($zip))" | Set-Content -LiteralPath (Join-Path $out 'SHA256SUMS.txt') -Encoding ascii
Write-Output $zip
# Staging is inside ignored artifacts and retained; no recursive deletion of computed paths.
