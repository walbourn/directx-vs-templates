<#

.SYNOPSIS
This script creates a instance of one of the Win32 templates using MSBuild without the VS IDE

.DESCRIPTION
This script is intended for creating a template instance outside of Visual Studio using MSBuild.

.PARAMETER templatedir
Provides the directory to read for the source template (d3d11game_win32, etc.)

.PARAMETER projectname
This is name of the project (such as "Direct3DGame")

.PARAMETER targetdir
This is the name of the target directory for the project (must not already exist). Defaults to the user's source directory.

.PARAMETER platformtoolset
This is the VS platform toolset to use in the project (such as "v143").

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
    [string]$templatedir = "d3d11game_win32",
    [string]$projectname = "Direct3DGame",
    [string]$targetdir = "$Env:USERPROFILE\source",
    [string]$platformtoolset = "v143"
)

$templatedir = "..\" + $templatedir

$targetdir = $targetdir + "\" + $projectname

if (Test-Path $targetdir) {
    Write-Error -Message "ERROR: Project directory already exists" -ErrorAction Stop
}

try {
    New-Item -Path $targetdir -ItemType Directory -ErrorAction Stop | Out-Null
}
catch {
    Write-Error -Message "Unable to create project directory '$targetdir'`n $_" -ErrorAction Stop
}

$files = Get-ChildItem $templatedir | Where {$_.extension -eq ".cpp"} | % { $_.FullName }
$files += Get-ChildItem $templatedir | Where {$_.extension -eq ".h"} | % { $_.FullName }
$files += Get-ChildItem $templatedir | Where {$_.extension -eq ".vcxproj"} | % { $_.FullName }
$files += Get-ChildItem $templatedir | Where {$_.extension -eq ".filters"} | % { $_.FullName }

$projfile = Get-ChildItem $templatedir | Where {$_.extension -eq ".vcxproj"} | % { $_.Name }
$filterfile = Get-ChildItem $templatedir | Where {$_.extension -eq ".filters"} | % { $_.Name }

if (Test-Path -Path ($templatedir + "\Package.appxmanifest")) {
    $files += Get-ChildItem $templatedir | Where {$_.extension -eq ".appxmanifest"} | % { $_.FullName }
}

$guid1 = New-Guid
$guid2 = New-Guid
$guid3 = New-Guid
$guid9 = New-Guid
$locale = Get-WinSystemLocale

foreach ($file in $files) {
    $target = $targetdir + "\" + [System.IO.Path]::GetFileName($file)
    $i = Get-Content $file -Raw
    $o = $i.Replace("`$projectname$", $projectname)
    $o = $o.Replace("`$safeprojectname$", $projectname)
    $o = $o.Replace("`$guid1$", $guid1)
    $o = $o.Replace("`$guid2$", $guid2)
    $o = $o.Replace("`$guid3$", $guid3)
    $o = $o.Replace("`$guid9$", $guid9)
    $o = $o.Replace("`$targetplatformversion$", "10.0")
    $o = $o.Replace("`$targetplatformminversion$", "10.0.17763.0")
    $o = $o.Replace("`$if`$('`$platformtoolset$' == 'v142')/ZH:SHA_256 `$endif`$", "/ZH:SHA_256 ")
    $o = $o.Replace("`$platformtoolset$", $platformtoolset)
    $o = $o.Replace("`$currentuiculturename$", $locale)
    $o = $o.Replace("`$XmlEscapedPublisherDistinguishedName$", "CN=$Env:USERNAME")
    $o = $o.Replace("`$XmlEscapedPublisher$", "$Env:USERNAME")
    $o = $o.Replace("`$if`$(`$includeKeyFile`$==true)","")
    $o = $o.Replace("`$endif`$","")
    $o | Set-Content -Path $target -NoNewline
}

Rename-Item -Path ($targetdir + "\" + $projfile) -NewName ($projectname + ".vcxproj")
Rename-Item -Path ($targetdir + "\" + $filterfile) -NewName ($projectname + ".vcxproj.filters")

if (Test-Path -Path ($templatedir + "\settings.manifest")) {
    Copy-Item ($templatedir + "\*.rc") -Destination $targetdir
    Copy-Item ($templatedir + "\directx.ico") -Destination $targetdir
    Copy-Item ($templatedir + "\settings.manifest") -Destination $targetdir
}
else {  
    $cert = New-SelfSignedCertificate -Type Custom -Subject "CN=$Env:USERNAME" -KeyUsage DigitalSignature -FriendlyName "devcert" -CertStore Cert:\CurrentUser\My\ -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")    
    [System.Security.SecureString]$rootCertPassword = ConvertTo-SecureString -String "pwd" -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath ($targetdir + "\" + $projectname + "_TemporaryKey.pfx") -ProtectTo "$Env:USERNAME" | Out-Null
    New-Item -Path ($targetdir + "\Assets") -ItemType Directory | Out-Null
    Copy-Item ($templatedir + "\StoreLogo.png") -Destination ($targetdir + "\Assets\StoreLogo.png")    
    Copy-Item ($templatedir + "\StoreLogo.png") -Destination ($targetdir + "\Assets\StoreLogo.png")
    Copy-Item ($templatedir + "\Logo.scale-200.png") -Destination ($targetdir + "\Assets\Logo.scale-200.png")
    Copy-Item ($templatedir + "\SmallLogo.scale-200.png") -Destination ($targetdir + "\Assets\SmallLogo.scale-200.png")
    Copy-Item ($templatedir + "\SplashScreen.scale-200.png") -Destination ($targetdir + "\Assets\SplashScreen.scale-200.png")
    Copy-Item ($templatedir + "\WideLogo.scale-200.png") -Destination ($targetdir + "\Assets\WideLogo.scale-200.png")
}

Write-Host "New project in $targetdir"