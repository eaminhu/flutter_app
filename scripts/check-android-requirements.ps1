param([string]$SdkRoot='D:\Android\Sdk')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$requirements=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'android-build-requirements.json') | ConvertFrom-Json
$lockHash=(Get-FileHash -LiteralPath (Join-Path $projectRoot 'pubspec.lock') -Algorithm SHA256).Hash
if($lockHash -ne $requirements.pubspecLockSha256) {
    throw 'Dependency lock changed. Review native Android build requirements before updating android-build-requirements.json.'
}
$missing=@($requirements.sdkDirectories | Where-Object { !(Test-Path -LiteralPath (Join-Path $SdkRoot $_) -PathType Container) })
if($missing.Count -gt 0) {
    throw ('Missing Android SDK components: '+($missing -join ', ')+'. Obtain explicit installation approval before building.')
}
Write-Output 'Android native build requirements passed.'

