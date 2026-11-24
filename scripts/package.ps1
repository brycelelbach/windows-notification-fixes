$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$out=Join-Path $root 'artifacts'
$stage=Join-Path $out ('package-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
foreach($item in @('dist','src','tests','scripts','docs','README.md','NOTICE','LICENSE','VERSION')){Copy-Item -LiteralPath (Join-Path $root $item) -Destination $stage -Recurse}
$zip=Join-Path $out "windows-notification-fixes-v$version.zip"
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
$hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $([IO.Path]::GetFileName($zip))" | Set-Content -LiteralPath (Join-Path $out 'SHA256SUMS.txt') -Encoding ascii
Write-Output $zip
# Staging is inside ignored artifacts and retained; no recursive deletion of computed paths.
