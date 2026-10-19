# Project-local launcher: keep SDKs and build caches on D drive.
$ErrorActionPreference = 'Stop'
$flutterExecutable = 'D:\development\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutterExecutable)) {
    throw 'Flutter SDK is missing at D:\development\flutter.'
}
$env:PUB_CACHE = 'D:\development\cache\pub'
$env:GRADLE_USER_HOME = 'D:\development\cache\gradle'
$env:ANDROID_HOME = 'D:\Android\Sdk'
$env:ANDROID_USER_HOME = 'D:\Android\user'
$env:ANDROID_AVD_HOME = 'D:\Android\avd'
$env:JAVA_HOME = 'D:\Program Files\Android\Android Studio\jbr'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:Path = 'D:\development\flutter\bin;' + $env:Path
$projectDirectory = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $projectDirectory
try {
    if ($args.Count -gt 0 -and ($args[0] -eq 'run' -or ($args[0] -eq 'build' -and $args.Count -gt 1 -and $args[1] -eq 'apk'))) {
        & (Join-Path $PSScriptRoot 'check-android-requirements.ps1')
    }
    & $flutterExecutable @args
    $flutterExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $flutterExitCode

