<#

.SYNOPSIS
This script creates a instance of one of the Win32 templates using CMake

.DESCRIPTION
This script is intended for creating a template instance outside of Visual Studio using CMake for building instead.

.PARAMETER templatedir
Provides the directory to read for the source template (d3d11game_win32, etc.)

.PARAMETER projectname
This is name of the project (such as "Direct3DGame")

.PARAMETER targetdir
This is the name of the target directory for the project (must not already exist)

.EXAMPLE
This creates a new instance of the Direct3D 11 Game template:

.\createcmake.ps1 ../d3d11game_win32 Direct3DGame $Env:USERPROFILE\source\Direct3DGame

.EXAMPLE
This creates a new instance of the Direct3D 11 Game with Device Resources template:

.\createcmake.ps1 ../d3d11game_win32_dr Direct3DGame $Env:USERPROFILE\source\Direct3DGameDR

.EXAMPLE
This creates a new instance of the Direct3D 12 Game template:

.\createcmake.ps1 ../d3d12game_win32 Direct3DGame $Env:USERPROFILE\source\Direct3D12Game

.EXAMPLE
This creates a new instance of the Direct3D 12 Game with Device Resources template:

.\createcmake.ps1 ../d3d12game_win32_dr Direct3DGame $Env:USERPROFILE\source\Direct3D12GameDR

.LINK
https://github.com/walbourn/directx-vs-templates/wiki

#>

param (
    [string]$templatedir,
    [string]$projectname,
    [string]$targetdir
)

$cmake = $templatedir + "\CMakeLists.txt"


if (-not (Test-Path -Path $cmake)) {
    Write-Error -Message "$templatedir does not contain a CMake" -ErrorAction Stop
}

if (-not (Test-Path $targetdir)) {
    try {
        New-Item -Path $targetdir -ItemType Directory -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error -Message "Unable to create project directory '$targetdir'`n $_" -ErrorAction Stop
    }

    $files = Get-ChildItem $templatedir | Where {$_.extension -eq ".cpp"} | % { $_.FullName }
    $files += Get-ChildItem $templatedir | Where {$_.extension -eq ".h"} | % { $_.FullName }

Write-Host $files

    foreach ($file in $files) {
        $target = $targetdir + "\" + [System.IO.Path]::GetFileName($file)
Write-Host $target
        $i = Get-Content $file -Raw
        $o = $i.Replace("`$projectname$", $projectname)
        $o = $o.Replace("`$safeprojectname$", $projectname)

        $o | Set-Content -Path $target -NoNewline
    }
    
    Copy-Item ($templatedir + "\CMakeLists.txt") -Destination $targetdir
    Copy-Item ($templatedir + "\*.json") -Destination $targetdir
    Copy-Item ($templatedir + "\*.rc") -Destination $targetdir
    Copy-Item ($templatedir + "\directx.ico") -Destination $targetdir
    Copy-Item ($templatedir + "\settings.manifest") -Destination $targetdir
}
else {
    "ERROR: Project directory already exists"
}