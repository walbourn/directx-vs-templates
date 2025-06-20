# Direct3D Game VS project templates
This repo contains simplified Visual C++ project templates. They are primarily intended for developer education, samples, and tutorials.

See [this blog post](https://walbourn.github.io/direct3d-win32-game-visual-studio-template/) and [this one](https://walbourn.github.io/direct3d-game-visual-studio-templates-redux/).

Documentation is available on [GitHub](https://github.com/walbourn/directx-vs-templates/wiki).

There are two versions of each template. The DR version adds a ``DeviceResources`` ([DX11](https://github.com/Microsoft/DirectXTK/wiki/DeviceResources) or [DX12](https://github.com/Microsoft/DirectXTK12/wiki/DeviceResources)) abstraction to isolate the device and swapchain code into it's own helper class.

For the UWP templates, there are C++/WinRT variants that use [C++ Windows Runtime language projections](https://docs.microsoft.com/en-us/windows/uwp/cpp-and-winrt-apis/) rather than the C++/CX language extensions (``/ZW``).

## VS 2019

The ``VSIX\Direct3DUWPGame.vsix`` suports VS 2019. Use of Visual Studio 2019 16.11 update is recommended.

The package requires the *Universal Windows Platform development* workload (``Microsoft.VisualStudio.Workload.Universal``) with the *C++ Universal Windows Platform tools* (``Microsoft.VisualStudio.ComponentGroup.UWP.VC``). The Win32 templates require the *Desktop development with C++* workload (``Microsoft.VisualStudio.Workload.NativeDesktop``). It is recommended you make use of the Windows 10 SDK (19041) or later.

## VS 2022

The ``VSIX\Direct3DUWPGame.vsix`` also works for VS 2022.

The package requires the *Universal Windows Platform development* workload (``Microsoft.VisualStudio.Workload.Universal``) with the *C++ Universal Windows Platform tools* (``Microsoft.VisualStudio.ComponentGroup.UWP.VC``). The Win32 templates require the *Desktop development with C++* workload (``Microsoft.VisualStudio.Workload.NativeDesktop``). It is recommended you make use of the Windows SDK (22000) or later.

The "Direct3D Win32 Game VCPKG" and "Direct3D12 Win32 Game VCPKG" templates require *vcpkg Package Manager* (``Microsoft.VisualStudio.Component.Vcpkg``).

## Rebuilding the VSIX

Building the VSIX project requires VS 2019 with the *.NET desktop development* (``Microsoft.VisualStudio.Workload.ManagedDesktop``) and *Visual Studio extension development* (``Microsoft.VisualStudio.Workload.VisualStudioExtension``)  workloads.

Before loading the `VSIX.sln`, run **VSIX\src\updatetemplates.cmd/.ps1** which creates the ZIPs of the individual templates.

## Notices

All content and source code for this package are subject to the terms of the [MIT License](https://github.com/walbourn/directx-vs-templates/blob/main/LICENSE).

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
