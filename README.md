# Direct3D Game VS project templates
This repo contains simplified Visual C++ project templates. They are primarily intended for developer education, samples, and tutorials.

See [this blog post](http://blogs.msdn.com/b/chuckw/archive/2015/01/06/direct3d-win32-game-visual-studio-template.aspx) and [this one](http://blogs.msdn.com/b/chuckw/archive/2015/12/17/direct3d-game-visual-studio-templates-redux.aspx).

Documentation is available on [GitHub](https://github.com/walbourn/directx-vs-templates/wiki).

There are two versions of each template. The DR version adds a ``DeviceResources`` abstraction to isolate the device and swapchain code into it's own helper class.

For the UWP templates, there are C++/WinRT variants that use [C++ Windows Runtime language projections](https://blogs.msdn.microsoft.com/vcblog/2016/10/13/cwinrt-available-on-github/) rather than the C++/CX language extenions (``/ZW``).

``VSIX\Direct3DWin32Game.vsix`` installs the Direct3D Win32 Game template for VS 2013

``VSIX\Direct3DUWPGame.vsix`` installs the Direct3D UWP Game template and the Direct3D Win32 Game template for VS 2015 and VS 2017

> For VS 2015, the package requires the [Visual C++](https://blogs.msdn.microsoft.com/vcblog/2015/07/24/setup-changes-in-visual-studio-2015-affecting-c-developers/) and [Windows Tools](https://blogs.msdn.microsoft.com/vcblog/2015/07/29/developing-for-windows-10-with-visual-c-2015/) optional features are installed.

> For VS 2017, the package requires the *Universal Windows Platform development* workload (``Microsoft.VisualStudio.Workload.Universal``) with the *C++ Universal Windows Platform tools* (``Microsoft.VisualStudio.ComponentGroup.UWP.VC``). The Win32 templates require the *Desktop development with C++* workload (``Microsoft.VisualStudio.Workload.NativeDesktop``).

All content and source code for this package are subject to the terms of the [MIT License](http://opensource.org/licenses/MIT).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
