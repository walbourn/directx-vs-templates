<#

.SYNOPSIS
This script creates a instance of one of the Win32 templates using MSBuild without the VS IDE.

.DESCRIPTION
This script is intended for creating a template instance outside of Visual Studio using MSBuild.

.PARAMETER TemplateDir
Provides the directory to read for the source template (d3d11game_win32, etc.)

.PARAMETER ProjectName
This is name of the project (such as "Direct3DGame")

.PARAMETER TargetDir
This is the name of the target directory for the project (must not already exist). Defaults to the user's source directory.

.PARAMETER PlatformToolset
This is the VS platform toolset to use in the project (such as "v143").

.PARAMETER makepfx
This determines for UWP projects if the temporary pfx file is created (defaulst to false).

.EXAMPLE
This creates a new instance of the Direct3D 11 Game template:

.\createmsbuild.ps1 d3d11game_win32 Direct3DGame $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 11 Game with Device Resources template:

.\createmsbuild.ps1 d3d11game_win32_dr Direct3DGameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 Game template:

.\createmsbuild.ps1 d3d12game_win32 Direct3D12Game $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 Game with Device Resources template:

.\createmsbuild.ps1 d3d12game_win32_dr Direct3D12GameDR $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D UWP Game template:

.\createmsbuild.ps1 d3d11game_uwp Direct3DUWPGame $Env:USERPROFILE\source
.\createmsbuild.ps1 d3d11game_uwp_cppwinrt Direct3DUWPGameCPP $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D UWP Game with Device Resources template:

.\createmsbuild.ps1 d3d11game_uwp_dr Direct3DUWPGameDR $Env:USERPROFILE\source
.\createmsbuild.ps1 d3d11game_uwp_cppwinrt_dr Direct3DUWPGameDRCPP $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 UWP Game template:

.\createmsbuild.ps1 d3d12game_uwp Direct3DUWP12Game $Env:USERPROFILE\source
.\createmsbuild.ps1 d3d12game_uwp_cppwinrt Direct3DUWP12GameCPP $Env:USERPROFILE\source

.EXAMPLE
This creates a new instance of the Direct3D 12 UWP Game with Device Resources template:

.\createmsbuild.ps1 d3d12game_uwp_dr Direct3DUWP12GameDR $Env:USERPROFILE\source
.\createmsbuild.ps1 d3d12game_uwp_cppwinrt_dr Direct3DUWP12GameDRCPP $Env:USERPROFILE\source

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
    [string]$ProjectName = "Direct3DGameVCPKG",
    [Parameter(
        Position = 2
    )]
    [string]$TargetDir = "$Env:USERPROFILE\source",
    [Parameter(
        Position = 3
    )]
    [string]$PlatformToolset = "v143",
    [Parameter(
        Position = 4
    )]
    [bool]$makepfx = $false
)

$vcpkgBaseline = "670f6dddaafc59c5dfe0587a130d59a35c48ea38"

if (-Not ($PlatformToolset -match 'v[0-9][0-9][0-9]'))
{
    Write-Error -Message "ERROR: Invalid platform toolset" -ErrorAction Stop
}

$reporoot = Split-Path -Path $PSScriptRoot -Parent

$TemplateDir = Join-Path -Path $reporoot -ChildPath $TemplateDir

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
$files += Get-ChildItem $TemplateDir | Where {$_.extension -eq ".vcxproj"} | % { $_.FullName }
$files += Get-ChildItem $TemplateDir | Where {$_.extension -eq ".filters"} | % { $_.FullName }

$projfile = Get-ChildItem $TemplateDir | Where {$_.extension -eq ".vcxproj"} | % { $_.Name }
$filterfile = Get-ChildItem $TemplateDir | Where {$_.extension -eq ".filters"} | % { $_.Name }

if (Test-Path -Path ($TemplateDir + "\Package.appxmanifest")) {
    $files += Get-ChildItem $TemplateDir | Where {$_.extension -eq ".appxmanifest"} | % { $_.FullName }
}

$guid1 = New-Guid
$guid2 = New-Guid
$guid3 = New-Guid
$guid9 = New-Guid
$locale = Get-WinSystemLocale
$safeprojectname = $ProjectName -replace '[ :`\/`*`?"<>|]','_'

foreach ($file in $files) {
    $target = $TargetDir + "\" + [System.IO.Path]::GetFileName($file)
    $i = Get-Content $file -Raw
    $o = $i.Replace("`$projectname$", $ProjectName)
    $o = $o.Replace("`$safeprojectname$", $safeprojectname)
    $o = $o.Replace("`$guid1$", $guid1)
    $o = $o.Replace("`$guid2$", $guid2)
    $o = $o.Replace("`$guid3$", $guid3)
    $o = $o.Replace("`$guid9$", $guid9)
    $o = $o.Replace("`$targetplatformversion$", "10.0")
    $o = $o.Replace("`$targetplatformminversion$", "10.0.17763.0")
    $o = $o.Replace("`$platformtoolset$", $PlatformToolset)
    $o = $o.Replace("`$currentuiculturename$", $locale)
    $o = $o.Replace("`$XmlEscapedPublisherDistinguishedName$", "CN=$Env:USERNAME")
    $o = $o.Replace("`$XmlEscapedPublisher$", "$Env:USERNAME")

    if ($makepfx -eq $true) {
        $o = $o.Replace("`$if`$(`$includeKeyFile`$==true)","")
        $o = $o.Replace("`$endif`$","")
    }
    else
    {
        $o = $o -replace '\$if\$\(\$includeKeyFile\$==true\)\r\n.*<.*\r\n.*\$endif\$\r\n',''
    }

    $o | Set-Content -Path $target -NoNewline
}

Rename-Item -Path ($TargetDir + "\" + $projfile) -NewName ($ProjectName + ".vcxproj")
Rename-Item -Path ($TargetDir + "\" + $filterfile) -NewName ($ProjectName + ".vcxproj.filters")

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
    if ($makepfx -eq $true) {
        $cert = New-SelfSignedCertificate -Type Custom -Subject "CN=$Env:USERNAME" -KeyUsage DigitalSignature -FriendlyName "devcert" -CertStore Cert:\CurrentUser\My\ -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
        [System.Security.SecureString]$rootCertPassword = ConvertTo-SecureString -String "pwd" -Force -AsPlainText
        Export-PfxCertificate -Cert $cert -FilePath ($TargetDir + "\" + $ProjectName + "_TemporaryKey.pfx") -ProtectTo "$Env:USERNAME" | Out-Null
    }
    New-Item -Path ($TargetDir + "\Assets") -ItemType Directory | Out-Null
    Copy-Item ($TemplateDir + "\StoreLogo.png") -Destination ($TargetDir + "\Assets\StoreLogo.png")
    Copy-Item ($TemplateDir + "\StoreLogo.png") -Destination ($TargetDir + "\Assets\StoreLogo.png")
    Copy-Item ($TemplateDir + "\Logo.scale-200.png") -Destination ($TargetDir + "\Assets\Logo.scale-200.png")
    Copy-Item ($TemplateDir + "\SmallLogo.scale-200.png") -Destination ($TargetDir + "\Assets\SmallLogo.scale-200.png")
    Copy-Item ($TemplateDir + "\SplashScreen.scale-200.png") -Destination ($TargetDir + "\Assets\SplashScreen.scale-200.png")
    Copy-Item ($TemplateDir + "\WideLogo.scale-200.png") -Destination ($TargetDir + "\Assets\WideLogo.scale-200.png")
}

Write-Host "New project in $TargetDir"