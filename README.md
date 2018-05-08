# Direct3D Game VS project templates
This repo contains simplified Visual C++ project templates. They are primarily intended for developer education, samples, and tutorials.

See [this blog post](http://blogs.msdn.com/b/chuckw/archive/2015/01/06/direct3d-win32-game-visual-studio-template.aspx) and [this one](http://blogs.msdn.com/b/chuckw/archive/2015/12/17/direct3d-game-visual-studio-templates-redux.aspx).

Documentation is available on [GitHub](https://github.com/walbourn/directx-vs-templates/wiki).

There are two versions of each template. The DR version adds a ``DeviceResources`` ([DX11](https://github.com/Microsoft/DirectXTK/wiki/DeviceResources) or [DX12](https://github.com/Microsoft/DirectXTK12/wiki/DeviceResources)) abstraction to isolate the device and swapchain code into it's own helper class.

For the UWP templates, there are C++/WinRT variants that use [C++ Windows Runtime language projections](https://blogs.msdn.microsoft.com/vcblog/2016/10/13/cwinrt-available-on-github/) rather than the C++/CX language extenions (``/ZW``).

# VS 2015
``VSIX\Direct3DUWPGame.vsix`` installs the Direct3D UWP Game templates and the Direct3D Win32 Game templates for VS 2015

The package requires the [Visual C++](https://blogs.msdn.microsoft.com/vcblog/2015/07/24/setup-changes-in-visual-studio-2015-affecting-c-developers/) and [Windows Tools](https://blogs.msdn.microsoft.com/vcblog/2015/07/29/developing-for-windows-10-with-visual-c-2015/) optional features are installed, and requires Windows 10 Anniversary Update SDK (14393) or later.

> For C++/WinRT projects, use cppwinrt NuGet package [2017.2.28](https://www.nuget.org/packages/cppwinrt/2017.2.28.4) with the Windows 10 Anniversary Update SDK (14393).

# VS 2017
The ``VSIX\Direct3DUWPGame.vsix`` also works for VS 2017. Use of the Visual Studio 2017 15.7 update or later is recommended.

The package requires the *Universal Windows Platform development* workload (``Microsoft.VisualStudio.Workload.Universal``) with the *C++ Universal Windows Platform tools* (``Microsoft.VisualStudio.ComponentGroup.UWP.VC``). The Win32 templates require the *Desktop development with C++* workload (``Microsoft.VisualStudio.Workload.NativeDesktop``). It is recommended you make use of the Windows 10 April 2018 Update SDK (17134).

# Rebuilding the VSIX
Building the VSIX project requires VS 2017 with the *Visual Studio extension development* (``Microsoft.VisualStudio.Workload.VisualStudioExtension``) and *.NET desktop development* (``Microsoft.VisualStudio.Workload.ManagedDesktop``) workloads.

# Notices
All content and source code for this package are subject to the terms of the [MIT License](http://opensource.org/licenses/MIT).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
