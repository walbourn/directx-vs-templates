#Direct3D Game VS project templates
This repo contains simplified Visual C++ project templates. They are primarily intended for developer education, samples, and tutorials.

See [this blog post](http://blogs.msdn.com/b/chuckw/archive/2015/01/06/direct3d-win32-game-visual-studio-template.aspx) and [this one](http://blogs.msdn.com/b/chuckw/archive/2015/12/17/direct3d-game-visual-studio-templates-redux.aspx)

There are two versions of each template. The DR version adds a ``DeviceResources`` abstraction to isolate the device and swapchain code into it's own helper class.

``VSIX\Direct3DWin32Game.vsix`` installs the Direct3D Win32 Game template for VS 2013

``VSIX\Direct3DUWPGame.vsix`` installs the Direct3D UWP Game template and the Direct3D Win32 Game template for VS 2015