//
// Main.cpp
//

#include "pch.h"
#include "Game.h"

using namespace winrt::Windows::ApplicationModel;
using namespace winrt::Windows::ApplicationModel::Core;
using namespace winrt::Windows::ApplicationModel::Activation;
using namespace winrt::Windows::UI::Core;
using namespace winrt::Windows::UI::Input;
using namespace winrt::Windows::UI::ViewManagement;
using namespace winrt::Windows::System;
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Graphics::Display;
using namespace DirectX;

class ViewProvider : public winrt::implements<ViewProvider, IFrameworkView>
{
public:
    ViewProvider() noexcept :
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
    void Initialize(CoreApplicationView const & applicationView)
    {
        applicationView.Activated({ this, &ViewProvider::OnActivated });

        CoreApplication::Suspending({ this, &ViewProvider::OnSuspending });

        CoreApplication::Resuming({ this, &ViewProvider::OnResuming });

        m_game = std::make_unique<Game>();
    }

    void Uninitialize() noexcept
    {
        m_game.reset();
    }

    void SetWindow(CoreWindow const & window)
    {
        window.SizeChanged({ this, &ViewProvider::OnWindowSizeChanged });

#if defined(NTDDI_WIN10_RS2) && (NTDDI_VERSION >= NTDDI_WIN10_RS2)
        try
        {
            window.ResizeStarted([this](auto&&, auto&&) { m_in_sizemove = true; });

            window.ResizeCompleted([this](auto&&, auto&&) { m_in_sizemove = false; HandleWindowSizeChanged(); });
        }
        catch (...)
        {
            // Requires Windows 10 Creators Update (10.0.15063) or later
        }
#endif

        window.VisibilityChanged({ this, &ViewProvider::OnVisibilityChanged });

        window.Closed([this](auto&&, auto&&) { m_exit = true; });

        auto dispatcher = CoreWindow::GetForCurrentThread().Dispatcher();

        dispatcher.AcceleratorKeyActivated({ this, &ViewProvider::OnAcceleratorKeyActivated });

        auto navigation = SystemNavigationManager::GetForCurrentView();

        // UWP on Xbox One triggers a back request whenever the B button is pressed
        // which can result in the app being suspended if unhandled
        navigation.BackRequested([](const winrt::Windows::Foundation::IInspectable&, const BackRequestedEventArgs& args)
        {
            args.Handled(true);
        });

        auto currentDisplayInformation = DisplayInformation::GetForCurrentView();

        currentDisplayInformation.DpiChanged({ this, &ViewProvider::OnDpiChanged });

        currentDisplayInformation.OrientationChanged({ this, &ViewProvider::OnOrientationChanged });

        DisplayInformation::DisplayContentsInvalidated({ this, &ViewProvider::OnDisplayContentsInvalidated });

        m_DPI = currentDisplayInformation.LogicalDpi();

        m_logicalWidth = window.Bounds().Width;
        m_logicalHeight = window.Bounds().Height;

        m_nativeOrientation = currentDisplayInformation.NativeOrientation();
        m_currentOrientation = currentDisplayInformation.CurrentOrientation();

        int outputWidth = ConvertDipsToPixels(m_logicalWidth);
        int outputHeight = ConvertDipsToPixels(m_logicalHeight);

        DXGI_MODE_ROTATION rotation = ComputeDisplayRotation();

        if (rotation == DXGI_MODE_ROTATION_ROTATE90 || rotation == DXGI_MODE_ROTATION_ROTATE270)
        {
            std::swap(outputWidth, outputHeight);
        }

        auto windowPtr = static_cast<::IUnknown*>(winrt::get_abi(window));
        m_game->Initialize(windowPtr, outputWidth, outputHeight, rotation);
    }

    void Load(winrt::hstring const &) noexcept
    {
    }

    void Run()
    {
        while (!m_exit)
        {
            if (m_visible)
            {
                m_game->Tick();

                CoreWindow::GetForCurrentThread().Dispatcher().ProcessEvents(CoreProcessEventsOption::ProcessAllIfPresent);
            }
            else
            {
                CoreWindow::GetForCurrentThread().Dispatcher().ProcessEvents(CoreProcessEventsOption::ProcessOneAndAllPending);
            }
        }
    }

protected:
    // Event handlers
    void OnActivated(CoreApplicationView const & /*applicationView*/, IActivatedEventArgs const & args)
    {
        if (args.Kind() == ActivationKind::Launch)
        {
            auto launchArgs = (const LaunchActivatedEventArgs*)(&args);

            if (launchArgs->PrelaunchActivated())
            {
                // Opt-out of Prelaunch
                CoreApplication::Exit();
                return;
            }
        }

        int w, h;
        m_game->GetDefaultSize(w, h);

        m_DPI = DisplayInformation::GetForCurrentView().LogicalDpi();

        ApplicationView::PreferredLaunchWindowingMode(ApplicationViewWindowingMode::PreferredLaunchViewSize);
        // Change to ApplicationViewWindowingMode::FullScreen to default to full screen

        auto desiredSize = Size(ConvertPixelsToDips(w), ConvertPixelsToDips(h));

        ApplicationView::PreferredLaunchViewSize(desiredSize);

        auto view = ApplicationView::GetForCurrentView();

        auto minSize = Size(ConvertPixelsToDips(320), ConvertPixelsToDips(200));

        view.SetPreferredMinSize(minSize);

        CoreWindow::GetForCurrentThread().Activate();

        view.FullScreenSystemOverlayMode(FullScreenSystemOverlayMode::Minimal);

        view.TryResizeView(desiredSize);
    }

    void OnSuspending(IInspectable const & /*sender*/, SuspendingEventArgs const & args)
    {
        auto deferral = args.SuspendingOperation().GetDeferral();

        auto f = std::async(std::launch::async, [this, deferral]()
        {
            m_game->OnSuspending();

            deferral.Complete();
        });
    }

    void OnResuming(IInspectable const & /*sender*/, IInspectable const & /*args*/)
    {
        m_game->OnResuming();
    }

    void OnWindowSizeChanged(CoreWindow const & sender, WindowSizeChangedEventArgs const & /*args*/)
    {
        m_logicalWidth = sender.Bounds().Width;
        m_logicalHeight = sender.Bounds().Height;

        if (m_in_sizemove)
            return;

        HandleWindowSizeChanged();
    }

    void OnVisibilityChanged(CoreWindow const & /*sender*/, VisibilityChangedEventArgs const & args)
    {
        m_visible = args.Visible();
        if (m_visible)
            m_game->OnActivated();
        else
            m_game->OnDeactivated();
    }

    void OnAcceleratorKeyActivated(CoreDispatcher const &, AcceleratorKeyEventArgs const & args)
    {
        if (args.EventType() == CoreAcceleratorKeyEventType::SystemKeyDown
            && args.VirtualKey() == VirtualKey::Enter
            && args.KeyStatus().IsMenuKeyDown
            && !args.KeyStatus().WasKeyDown)
        {
            // Implements the classic ALT+ENTER fullscreen toggle
            auto view = ApplicationView::GetForCurrentView();

            if (view.IsFullScreenMode())
                view.ExitFullScreenMode();
            else
                view.TryEnterFullScreenMode();

            args.Handled(true);
        }
    }

    void OnDpiChanged(DisplayInformation const & sender, IInspectable const & /*args*/)
    {
        m_DPI = sender.LogicalDpi();

        HandleWindowSizeChanged();
    }

    void OnOrientationChanged(DisplayInformation const & sender, IInspectable const & /*args*/)
    {
        auto resizeManager = CoreWindowResizeManager::GetForCurrentView();
        resizeManager.ShouldWaitForLayoutCompletion(true);

        m_currentOrientation = sender.CurrentOrientation();

        HandleWindowSizeChanged();

        resizeManager.NotifyLayoutCompleted();
    }

    void OnDisplayContentsInvalidated(DisplayInformation const & /*sender*/, IInspectable const & /*args*/)
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

    winrt::Windows::Graphics::Display::DisplayOrientations	m_nativeOrientation;
    winrt::Windows::Graphics::Display::DisplayOrientations	m_currentOrientation;

    inline int ConvertDipsToPixels(float dips) const noexcept
    {
        return int(dips * m_DPI / 96.f + 0.5f);
    }

    inline float ConvertPixelsToDips(int pixels) const noexcept
    {
        return (float(pixels) * 96.f / m_DPI);
    }

    DXGI_MODE_ROTATION ComputeDisplayRotation() const noexcept
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

class ViewProviderFactory : public winrt::implements<ViewProviderFactory, IFrameworkViewSource>
{
public:
    IFrameworkView CreateView()
    {
        return winrt::make<ViewProvider>();
    }
};


// Entry point
int WINAPI wWinMain(
    _In_ HINSTANCE /*hInstance*/,
    _In_ HINSTANCE /*hPrevInstance*/,
    _In_ LPWSTR    /*lpCmdLine*/,
    _In_ int       /*nCmdShow*/
)
{
    if (!XMVerifyCPUSupport())
    {
        throw std::exception("XMVerifyCPUSupport");
    }

    auto viewProviderFactory = winrt::make<ViewProviderFactory>();
    CoreApplication::Run(viewProviderFactory);
    return 0;
}


// Exit helper
void ExitGame() noexcept
{
    winrt::Windows::ApplicationModel::Core::CoreApplication::Exit();
}
