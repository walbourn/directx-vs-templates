//
// Main.cpp
//

#include "pch.h"
#include "Game.h"

#include <ppltasks.h>

using namespace concurrency;
using namespace Windows::ApplicationModel;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::ApplicationModel::Activation;
using namespace Windows::UI::Core;
using namespace Windows::UI::Input;
using namespace Windows::UI::ViewManagement;
using namespace Windows::System;
using namespace Windows::Foundation;
using namespace Windows::Graphics::Display;
using namespace DirectX;

ref class ViewProvider sealed : public IFrameworkView
{
public:
    ViewProvider() :
        m_exit(false),
        m_visible(true),
        m_in_sizemove(false),
        m_DPI(96.f),
        m_logicalWidth(800.f),
        m_logicalHeight(600.f),
        m_nativeOrientation(DisplayOrientations::None),
        m_currentOrientation(DisplayOrientations::None)
    {
    }

    // IFrameworkView methods
    virtual void Initialize(CoreApplicationView^ applicationView)
    {
        applicationView->Activated +=
            ref new TypedEventHandler<CoreApplicationView^, IActivatedEventArgs^>(this, &ViewProvider::OnActivated);

        CoreApplication::Suspending +=
            ref new EventHandler<SuspendingEventArgs^>(this, &ViewProvider::OnSuspending);

        CoreApplication::Resuming +=
            ref new EventHandler<Platform::Object^>(this, &ViewProvider::OnResuming);

        m_game = std::make_unique<Game>();
    }

    virtual void Uninitialize()
    {
        m_game.reset();
    }

    virtual void SetWindow(CoreWindow^ window)
    {
        window->SizeChanged +=
            ref new TypedEventHandler<CoreWindow^, WindowSizeChangedEventArgs^>(this, &ViewProvider::OnWindowSizeChanged);

#if defined(NTDDI_WIN10_RS2) && (NTDDI_VERSION >= NTDDI_WIN10_RS2)
        try
        {
            window->ResizeStarted +=
                ref new TypedEventHandler<CoreWindow^, Object^>(this, &ViewProvider::OnResizeStarted);

            window->ResizeCompleted +=
                ref new TypedEventHandler<CoreWindow^, Object^>(this, &ViewProvider::OnResizeCompleted);
        }
        catch (...)
        {
            // Requires Windows 10 Creators Update (10.0.15063) or later
        }
#endif

        window->VisibilityChanged +=
            ref new TypedEventHandler<CoreWindow^, VisibilityChangedEventArgs^>(this, &ViewProvider::OnVisibilityChanged);

        window->Closed +=
            ref new TypedEventHandler<CoreWindow^, CoreWindowEventArgs^>(this, &ViewProvider::OnWindowClosed);

        auto dispatcher = CoreWindow::GetForCurrentThread()->Dispatcher;

        dispatcher->AcceleratorKeyActivated +=
            ref new TypedEventHandler<CoreDispatcher^, AcceleratorKeyEventArgs^>(this, &ViewProvider::OnAcceleratorKeyActivated);

        auto navigation = Windows::UI::Core::SystemNavigationManager::GetForCurrentView();

        navigation->BackRequested +=
            ref new EventHandler<BackRequestedEventArgs^>(this, &ViewProvider::OnBackRequested);

        auto currentDisplayInformation = DisplayInformation::GetForCurrentView();

        currentDisplayInformation->DpiChanged +=
            ref new TypedEventHandler<DisplayInformation^, Object^>(this, &ViewProvider::OnDpiChanged);

        currentDisplayInformation->OrientationChanged +=
            ref new TypedEventHandler<DisplayInformation^, Object^>(this, &ViewProvider::OnOrientationChanged);

        DisplayInformation::DisplayContentsInvalidated +=
            ref new TypedEventHandler<DisplayInformation^, Object^>(this, &ViewProvider::OnDisplayContentsInvalidated);

        m_DPI = currentDisplayInformation->LogicalDpi;

        m_logicalWidth = window->Bounds.Width;
        m_logicalHeight = window->Bounds.Height;

        m_nativeOrientation = currentDisplayInformation->NativeOrientation;
        m_currentOrientation = currentDisplayInformation->CurrentOrientation;

        int outputWidth = ConvertDipsToPixels(m_logicalWidth);
        int outputHeight = ConvertDipsToPixels(m_logicalHeight);

        DXGI_MODE_ROTATION rotation = ComputeDisplayRotation();

        if (rotation == DXGI_MODE_ROTATION_ROTATE90 || rotation == DXGI_MODE_ROTATION_ROTATE270)
        {
            std::swap(outputWidth, outputHeight);
        }

        m_game->Initialize(reinterpret_cast<IUnknown*>(window),
                           outputWidth, outputHeight, rotation );
    }

    virtual void Load(Platform::String^ entryPoint)
    {
    }

    virtual void Run()
    {
        while (!m_exit)
        {
            if (m_visible)
            {
                m_game->Tick();

                CoreWindow::GetForCurrentThread()->Dispatcher->ProcessEvents(CoreProcessEventsOption::ProcessAllIfPresent);
            }
            else
            {
                CoreWindow::GetForCurrentThread()->Dispatcher->ProcessEvents(CoreProcessEventsOption::ProcessOneAndAllPending);
            }
        }
    }

protected:
    // Event handlers
    void OnActivated(CoreApplicationView^ applicationView, IActivatedEventArgs^ args)
    {
        if (args->Kind == ActivationKind::Launch)
        {
            auto launchArgs = static_cast<LaunchActivatedEventArgs^>(args);

            if (launchArgs->PrelaunchActivated)
            {
                // Opt-out of Prelaunch
                CoreApplication::Exit();
                return;
            }
        }

        int w, h;
        m_game->GetDefaultSize(w, h);

        m_DPI = DisplayInformation::GetForCurrentView()->LogicalDpi;

        ApplicationView::PreferredLaunchWindowingMode = ApplicationViewWindowingMode::PreferredLaunchViewSize;
        // TODO: Change to ApplicationViewWindowingMode::FullScreen to default to full screen

        auto desiredSize = Size(ConvertPixelsToDips(w), ConvertPixelsToDips(h));

        ApplicationView::PreferredLaunchViewSize = desiredSize;

        auto view = ApplicationView::GetForCurrentView();

        auto minSize = Size(ConvertPixelsToDips(320), ConvertPixelsToDips(200));

        view->SetPreferredMinSize(minSize);

        CoreWindow::GetForCurrentThread()->Activate();

        view->FullScreenSystemOverlayMode = FullScreenSystemOverlayMode::Minimal;

        view->TryResizeView(desiredSize);
    }

    void OnSuspending(Platform::Object^ sender, SuspendingEventArgs^ args)
    {
        auto deferral = args->SuspendingOperation->GetDeferral();

        create_task([this, deferral]()
        {
            m_game->OnSuspending();

            deferral->Complete();
        });
    }

    void OnResuming(Platform::Object^ sender, Platform::Object^ args)
    {
        m_game->OnResuming();
    }

    void OnWindowSizeChanged(CoreWindow^ sender, WindowSizeChangedEventArgs^ args)
    {
        m_logicalWidth = sender->Bounds.Width;
        m_logicalHeight = sender->Bounds.Height;

        if (m_in_sizemove)
            return;

        HandleWindowSizeChanged();
    }

#if defined(NTDDI_WIN10_RS2) && (NTDDI_VERSION >= NTDDI_WIN10_RS2)
    void OnResizeStarted(CoreWindow^ sender, Platform::Object^ args)
    {
        m_in_sizemove = true;
    }

    void OnResizeCompleted(CoreWindow^ sender, Platform::Object^ args)
    {
        m_in_sizemove = false;

        HandleWindowSizeChanged();
    }
#endif

    void OnVisibilityChanged(CoreWindow^ sender, VisibilityChangedEventArgs^ args)
    {
        m_visible = args->Visible;
        if (m_visible)
            m_game->OnActivated();
        else
            m_game->OnDeactivated();
    }

    void OnWindowClosed(CoreWindow^ sender, CoreWindowEventArgs^ args)
    {
        m_exit = true;
    }

    void OnAcceleratorKeyActivated(CoreDispatcher^, AcceleratorKeyEventArgs^ args)
    {
        if (args->EventType == CoreAcceleratorKeyEventType::SystemKeyDown
            && args->VirtualKey == VirtualKey::Enter
            && args->KeyStatus.IsMenuKeyDown
            && !args->KeyStatus.WasKeyDown)
        {
            // Implements the classic ALT+ENTER fullscreen toggle
            auto view = ApplicationView::GetForCurrentView();

            if (view->IsFullScreenMode)
                view->ExitFullScreenMode();
            else
                view->TryEnterFullScreenMode();

            args->Handled = true;
        }
    }

    void OnBackRequested(Platform::Object^, Windows::UI::Core::BackRequestedEventArgs^ args)
    {
        // UWP on Xbox One triggers a back request whenever the B button is pressed
        // which can result in the app being suspended if unhandled
        args->Handled = true;
    }

    void OnDpiChanged(DisplayInformation^ sender, Object^ args)
    {
        m_DPI = sender->LogicalDpi;

        HandleWindowSizeChanged();
    }

    void OnOrientationChanged(DisplayInformation^ sender, Object^ args)
    {
        auto resizeManager = CoreWindowResizeManager::GetForCurrentView();
        resizeManager->ShouldWaitForLayoutCompletion = true;

        m_currentOrientation = sender->CurrentOrientation;

        HandleWindowSizeChanged();

        resizeManager->NotifyLayoutCompleted();
    }

    void OnDisplayContentsInvalidated(DisplayInformation^ sender, Object^ args)
    {
        m_game->ValidateDevice();
    }

private:
    bool                    m_exit;
    bool                    m_visible;
    bool                    m_in_sizemove;
    float                   m_DPI;
    float                   m_logicalWidth;
    float                   m_logicalHeight;
    std::unique_ptr<Game>   m_game;

    Windows::Graphics::Display::DisplayOrientations	m_nativeOrientation;
    Windows::Graphics::Display::DisplayOrientations	m_currentOrientation;

    inline int ConvertDipsToPixels(float dips) const
    {
        return int(dips * m_DPI / 96.f + 0.5f);
    }

    inline float ConvertPixelsToDips(int pixels) const
    {
        return (float(pixels) * 96.f / m_DPI);
    }

    DXGI_MODE_ROTATION ComputeDisplayRotation() const
    {
        DXGI_MODE_ROTATION rotation = DXGI_MODE_ROTATION_UNSPECIFIED;

        switch (m_nativeOrientation)
        {
        case DisplayOrientations::Landscape:
            switch (m_currentOrientation)
            {
            case DisplayOrientations::Landscape:
                rotation = DXGI_MODE_ROTATION_IDENTITY;
                break;

            case DisplayOrientations::Portrait:
                rotation = DXGI_MODE_ROTATION_ROTATE270;
                break;

            case DisplayOrientations::LandscapeFlipped:
                rotation = DXGI_MODE_ROTATION_ROTATE180;
                break;

            case DisplayOrientations::PortraitFlipped:
                rotation = DXGI_MODE_ROTATION_ROTATE90;
                break;
            }
            break;

        case DisplayOrientations::Portrait:
            switch (m_currentOrientation)
            {
            case DisplayOrientations::Landscape:
                rotation = DXGI_MODE_ROTATION_ROTATE90;
                break;

            case DisplayOrientations::Portrait:
                rotation = DXGI_MODE_ROTATION_IDENTITY;
                break;

            case DisplayOrientations::LandscapeFlipped:
                rotation = DXGI_MODE_ROTATION_ROTATE270;
                break;

            case DisplayOrientations::PortraitFlipped:
                rotation = DXGI_MODE_ROTATION_ROTATE180;
                break;
            }
            break;
        }

        return rotation;
    }

    void HandleWindowSizeChanged()
    {
        int outputWidth = ConvertDipsToPixels(m_logicalWidth);
        int outputHeight = ConvertDipsToPixels(m_logicalHeight);

        DXGI_MODE_ROTATION rotation = ComputeDisplayRotation();

        if (rotation == DXGI_MODE_ROTATION_ROTATE90 || rotation == DXGI_MODE_ROTATION_ROTATE270)
        {
            std::swap(outputWidth, outputHeight);
        }

        m_game->OnWindowSizeChanged(outputWidth, outputHeight, rotation);
    }
};

ref class ViewProviderFactory : IFrameworkViewSource
{
public:
    virtual IFrameworkView^ CreateView()
    {
        return ref new ViewProvider();
    }
};


// Entry point
[Platform::MTAThread]
int __cdecl main(Platform::Array<Platform::String^>^ /*argv*/)
{
    if (!XMVerifyCPUSupport())
    {
        throw std::exception("XMVerifyCPUSupport");
    }

    auto viewProviderFactory = ref new ViewProviderFactory();
    CoreApplication::Run(viewProviderFactory);
    return 0;
}


// Exit helper
void ExitGame() noexcept
{
    Windows::ApplicationModel::Core::CoreApplication::Exit();
}
