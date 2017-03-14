Add-Type -A System.IO.Compression.FileSystem
$src = $PSScriptRoot + "\..\..\"
$vsix = $PSScriptRoot + "\Direct3DGame\ProjectTemplates\"
rd -recurse $vsix -EA SilentlyContinue > $null
md $vsix > $null
Write-Host "Updating .ZIP files..."
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d11game_uwp", $vsix + "Direct3DUWPGame.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d11game_uwp_dr", $vsix + "Direct3DUWPGameDR.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d11game_win32", $vsix + "Direct3DWin32Game.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d11game_win32_dr", $vsix + "Direct3DWin32GameDR.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d12game_uwp", $vsix + "Direct3D12UWPGame.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d12game_uwp_dr", $vsix + "Direct3D12UWPGameDR.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d12game_win32", $vsix + "Direct3D12Win32Game.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d12game_win32_dr", $vsix + "Direct3D12Win32GameDR.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d11game_uwp_cppwinrt", $vsix + "Direct3DUWPGameCppWinRT.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d11game_uwp_cppwinrt_dr", $vsix + "Direct3DUWPGameCppWinRTDR.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d12game_uwp_cppwinrt", $vsix + "Direct3D12UWPGameCppWinRT.zip")
[IO.Compression.ZipFile]::CreateFromDirectory($src + "d3d12game_uwp_cppwinrt_dr", $vsix + "Direct3D12UWPGameCppWinRTDR.zip")
Write-Host "Completed."
