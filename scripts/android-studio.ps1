# Open Flutter project with the same D-drive environment as flutter.ps1.
$ErrorActionPreference = 'Stop'
if (Get-Process studio64 -ErrorAction SilentlyContinue) {
    throw 'Android Studio is already running. Open D:\project\flutter_nexusft in the existing window.'
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
Start-Process -FilePath 'D:\Program Files\Android\Android Studio\bin\studio64.exe' -ArgumentList $projectDirectory

