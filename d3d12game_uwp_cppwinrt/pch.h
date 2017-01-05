//
// pch.h
// Header for standard system include files.
//

#pragma once

// Use the C++ standard templated min/max
#define NOMINMAX

#include <wrl/client.h>
#include <wrl/event.h>

#include <d3d12.h>
#include <dxgi1_4.h>
#include <DirectXMath.h>
#include <DirectXColors.h>

#include "d3dx12.h"

#include <algorithm>
#include <exception>
#include <future>
#include <memory>
#include <stdexcept>

#ifdef _DEBUG
#include <dxgidebug.h>
#endif

#include "winrt/Windows.ApplicationModel.h"
#include "winrt/Windows.ApplicationModel.Core.h"
#include "winrt/Windows.ApplicationModel.Activation.h"
#include "winrt/Windows.Foundation.h"
#include "winrt/Windows.Graphics.Display.h"
#include "winrt/Windows.System.h"
#include "winrt/Windows.UI.Core.h"
#include "winrt/Windows.UI.Input.h"
#include "winrt/Windows.UI.ViewManagement.h"

namespace DX
{
    inline void ThrowIfFailed(HRESULT hr)
    {
        if (FAILED(hr))
        {
            // Set a breakpoint on this line to catch DirectX API errors
            throw std::exception();
        }
    }
}