<#

.SYNOPSIS
This script creates a instance of one of the Win32 templates using CMake

.DESCRIPTION
This script is intended for creating a template instance outside of Visual Studio using CMake for building instead.

.PARAMETER TemplateDir
Provides the directory to read for the source template (d3d11game_win32, etc.)

.PARAMETER ProjectName
This is name of the project (such as "Direct3DGame")

.PARAMETER TargetDir
This is the name of the target directory for the project (must not already exist). Defaults to the user's source directory.

.EXAMPLE
This creates a new instance of the Direct3D 11 Game template:

.\createcmake.ps1 d3d11game_win32 Direct3DGame $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 11 Game with Device Resources template:

.\createcmake.ps1 d3d11game_win32_dr Direct3DGameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 Game template:

.\createcmake.ps1 d3d12game_win32 Direct3D12Game $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 Game with Device Resources template:

.\createcmake.ps1 d3d12game_win32_dr Direct3D12GameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D UWP Game template:

.\createcmake.ps1 d3d11game_uwp_cppwinrt Direct3DUWPGame $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D UWP Game with Device Resources template:

.\createcmake.ps1 d3d11game_uwp_cppwinrt_dr Direct3DUWPGameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 UWP Game template:

.\createcmake.ps1 d3d12game_uwp_cppwinrt Direct3DUWP12Game $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 UWP Game with Device Resources template:

.\createcmake.ps1 d3d12game_uwp_cppwinrt_dr Direct3DUWP12GameDR $Env:USERPROFILE\source

.LINK
https://github.com/walbourn/directx-vs-templates/wiki

#>

param (
    [Parameter(
        Mandatory,
        Position = 0
    )]
    [string]$TemplateDir,
    [Parameter(
        Position = 1
    )]
    [string]$ProjectName = "Direct3DGameCMake",
    [Parameter(
        Position = 2
    )]
    [string]$TargetDir = "$Env:USERPROFILE\source"
)

$vcpkgBaseline = "670f6dddaafc59c5dfe0587a130d59a35c48ea38"

$reporoot = Split-Path -Path $PSScriptRoot -Parent

$TemplateDir = Join-Path -Path $reporoot -ChildPath $TemplateDir

$cmake = $TemplateDir + "\CMakeLists.txt"

if (-not (Test-Path -Path $cmake)) {
    Write-Error -Message "ERROR: $TemplateDir does not contain a CMake" -ErrorAction Stop
}

$TargetDir = Join-Path -Path $TargetDir -ChildPath $ProjectName

if (Test-Path $TargetDir) {
    Write-Error -Message "ERROR: Project directory already exists" -ErrorAction Stop
}

try {
    New-Item -Path $TargetDir -ItemType Directory -ErrorAction Stop | Out-Null
}
catch {
    Write-Error -Message "Unable to create project directory '$TargetDir'`n $_" -ErrorAction Stop
}

$files = Get-ChildItem $TemplateDir | Where {$_.extension -eq ".cpp"} | % { $_.FullName }
$files += Get-ChildItem $TemplateDir | Where {$_.extension -eq ".h"} | % { $_.FullName }

if (Test-Path -Path ($TemplateDir + "\Package.appxmanifest")) {
    $files += Get-ChildItem $TemplateDir | Where {$_.extension -eq ".appxmanifest"} | % { $_.FullName }
}

$guid = New-Guid
$locale = Get-WinSystemLocale
$safeprojectname = $ProjectName -replace '[ :`\/`*`?"<>|]','_'

foreach ($file in $files) {
    $target = $TargetDir + "\" + [System.IO.Path]::GetFileName($file)
    $i = Get-Content $file -Raw
    $o = $i.Replace("Version=`"1.0.0.0`" />", "Version=`"@CMAKE_PROJECT_VERSION@`" `
    ProcessorArchitecture=`"@DIRECTX_ARCH@`" />")
    $o = $o.Replace("<DisplayName>`$projectname$</DisplayName>", "<DisplayName>@PROJECT_NAME@</DisplayName>")
    $o = $o.Replace("DisplayName=`"`$projectname$`"", "DisplayName=`"@PROJECT_NAME@`"")
    $o = $o.Replace("Description=`"`$projectname$`"", "Description=`"@CMAKE_PROJECT_DESCRIPTION@`"")
    $o = $o.Replace("EntryPoint=`"`$safeprojectname$.App`"", "EntryPoint=`"@PROJECT_NAME@.App`"")
    $o = $o.Replace("`$projectname$", $ProjectName)
    $o = $o.Replace("`$safeprojectname$", $safeprojectname)
    $o = $o.Replace("`$guid9$", $guid)
    $o = $o.Replace("`$XmlEscapedPublisherDistinguishedName$", "CN=$Env:USERNAME")
    $o = $o.Replace("`$XmlEscapedPublisher$", "$Env:USERNAME")
    $o = $o.Replace("x-generate", $locale)
    $o = $o.Replace("`$targetnametoken$", "@PROJECT_NAME@")
    $o = $o.Replace("<TargetDeviceFamily Name=`"Windows.Universal`" MinVersion=`"10.0.0.0`" MaxVersionTested=`"10.0.0.0`" />",
"<TargetDeviceFamily Name=`"Windows.Universal`" MinVersion=`"@UWP_MIN_VERSION@`" MaxVersionTested=`"@UWP_MAX_TESTED_VERSION@`" /> `
    <PackageDependency Name=`"Microsoft.VCLibs.140.00.Debug`" MinVersion=`"@UWP_MIN_CRT_VERSION@`" Publisher=`"CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US`" />")

    $o | Set-Content -Path $target -NoNewline
}

Copy-Item ($reporoot + "\build\CompilerAndLinker.cmake") -Destination $TargetDir
Copy-Item ($TemplateDir + "\CMakeLists.txt") -Destination $TargetDir
Copy-Item ($TemplateDir + "\CMake*.json") -Destination $TargetDir

if (Test-Path -Path ($TemplateDir + "\vcpkg.json")) {
    Copy-Item ($TemplateDir + "\vcpkg*.json") -Destination $TargetDir

    $vcpkgConfig = $TargetDir + "\vcpkg-configuration.json"
    if (Test-Path $vcpkgConfig) {
        $i = Get-Content $vcpkgConfig -Raw
        $o = $i.Replace("`$vcpkghash$", $vcpkgBaseline)
        $o | Set-Content -Path $vcpkgConfig -NoNewline
    }
}

if (Test-Path -Path ($TemplateDir + "\settings.manifest")) {
    Copy-Item ($TemplateDir + "\*.rc") -Destination $TargetDir
    Copy-Item ($TemplateDir + "\directx.ico") -Destination $TargetDir
    Copy-Item ($TemplateDir + "\settings.manifest") -Destination $TargetDir
}
else {
    New-Item -Path ($TargetDir + "\Assets") -ItemType Directory | Out-Null
    Copy-Item ($TemplateDir + "\StoreLogo.png") -Destination ($TargetDir + "\Assets\StoreLogo.png")
    Copy-Item ($TemplateDir + "\Logo.scale-200.png") -Destination ($TargetDir + "\Assets\Logo.png")
    Copy-Item ($TemplateDir + "\SmallLogo.scale-200.png") -Destination ($TargetDir + "\Assets\SmallLogo.png")
    Copy-Item ($TemplateDir + "\SplashScreen.scale-200.png") -Destination ($TargetDir + "\Assets\SplashScreen.png")
    Copy-Item ($TemplateDir + "\WideLogo.scale-200.png") -Destination ($TargetDir + "\Assets\WideLogo.png")
}

Write-Host "New project in $TargetDir"
