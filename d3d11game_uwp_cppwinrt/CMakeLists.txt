cmake_minimum_required (VERSION 3.20)

project(CMakeDirect3DGame
  DESCRIPTION "CMake example for Direct3D 11 Game (UWP)"
  LANGUAGES CXX
  VERSION 1.0.0.0)

option(BUILD_TEST_TEMPLATE "Ignore warnings related to TODOs" OFF)

option(ENABLE_CODE_ANALYSIS "Use Static Code Analysis on build" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set(CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release)

if(DEFINED VCPKG_TARGET_ARCHITECTURE)
    set(DIRECTX_ARCH ${VCPKG_TARGET_ARCHITECTURE})
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Ww][Ii][Nn]32$")
    set(DIRECTX_ARCH x86)
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Xx]64$")
    set(DIRECTX_ARCH x64)
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Aa][Rr][Mm]$")
    set(DIRECTX_ARCH arm)
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Aa][Rr][Mm]64$")
    set(DIRECTX_ARCH arm64)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Ww][Ii][Nn]32$")
    set(DIRECTX_ARCH x86)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Xx]64$")
    set(DIRECTX_ARCH x64)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Aa][Rr][Mm]$")
    set(DIRECTX_ARCH arm)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Aa][Rr][Mm]64$")
    set(DIRECTX_ARCH arm64)
endif()

if(NOT WINDOWS_STORE)
    message(FATAL_ERROR "ERROR: Must be built for WindowsStore")
endif()

add_executable(${PROJECT_NAME} WIN32
    Game.cpp
    Game.h
    Main.cpp
    StepTimer.h
    pch.h
)

target_precompile_headers(${PROJECT_NAME} PRIVATE pch.h )

target_link_libraries(${PROJECT_NAME} PRIVATE
    d3d11.lib dxgi.lib dxguid.lib uuid.lib)

if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /Wall /EHsc /GR /bigobj "$<$<NOT:$<CONFIG:DEBUG>>:/guard:cf>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<NOT:$<CONFIG:DEBUG>>:/guard:cf>" /DYNAMICBASE /NXCOMPAT /APPCONTAINER /MANIFEST:NO)

    if((CMAKE_SIZEOF_VOID_P EQUAL 4) AND (NOT ${DIRECTX_ARCH} MATCHES "^arm"))
        target_compile_options(${PROJECT_NAME} PRIVATE /arch:SSE2)
        target_link_options(${PROJECT_NAME} PRIVATE /SAFESEH)
    endif()

    if((MSVC_VERSION GREATER_EQUAL 1928)
       AND (CMAKE_SIZEOF_VOID_P EQUAL 8)
       AND ((NOT (CMAKE_CXX_COMPILER_ID MATCHES "Clang|IntelLLVM")) OR (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 13.0)))
        target_compile_options(${PROJECT_NAME} PRIVATE "$<$<NOT:$<CONFIG:DEBUG>>:/guard:ehcont>")
        target_link_options(${PROJECT_NAME} PRIVATE "$<$<NOT:$<CONFIG:DEBUG>>:/guard:ehcont>")
    endif()
endif()

find_package(cppwinrt CONFIG QUIET)
find_package(directxmath CONFIG QUIET)
find_package(directx-headers CONFIG QUIET)

if(cppwinrt_FOUND)
    message(STATUS "Using C++/WinRT package")
    target_link_libraries(${PROJECT_NAME} PRIVATE Microsoft::CppWinRT)
    # CPPWINRT_TOOL is the .winmd to header generation tool
endif()

if(directxmath_FOUND)
    message(STATUS "Using DirectXMath package")
    target_link_libraries(${PROJECT_NAME} PUBLIC Microsoft::DirectXMath)
endif()

if(directx-headers_FOUND)
    message(STATUS "Using DirectX-Headers package")
    target_link_libraries(${PROJECT_NAME} PUBLIC Microsoft::DirectX-Headers Microsoft::DirectX-Guids)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USING_DIRECTX_HEADERS)
endif()

# Uncomment if using the DirectX Tool Kit
# find_package(directxtk CONFIG REQUIRED)
# target_link_libraries(${PROJECT_NAME} PRIVATE Microsoft::DirectXTK)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|IntelLLVM")
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wpedantic -Wextra
        "-Wno-c++98-compat" "-Wno-c++98-compat-pedantic"
        "-Wno-exit-time-destructors" "-Wno-global-constructors" "-Wno-language-extension-token"
        "-Wno-missing-prototypes" "-Wno-missing-variable-declarations" "-Wno-reserved-id-macro")

    target_compile_definitions(${PROJECT_NAME} PRIVATE _SILENCE_CLANG_COROUTINE_MESSAGE)

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 16.0)
        target_compile_options(${PROJECT_NAME} PRIVATE /ZH:SHA_256 "-Wno-unsafe-buffer-usage")
    endif()

    if(BUILD_TEST_TEMPLATE)
        target_compile_options(${PROJECT_NAME} PRIVATE "-Wno-unused-value")
    endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    target_compile_options(${PROJECT_NAME} PRIVATE
         /sdl /permissive- /Zc:__cplusplus /Zc:inline /fp:fast
         "/wd4061" "/wd4265" "/wd4297" "/wd4355" "/wd4365" "/wd4371" "/wd4514" "/wd4555"
         "/wd4571" "/wd4623" "/wd4625" "/wd4626" "/wd4668" "/wd4710" "/wd4820" "/wd4946"
         "/wd5026" "/wd5027" "/wd5039" "/wd5045" "/wd5204" "/wd5220")

    target_compile_options(${PROJECT_NAME} PRIVATE /await)

    if(ENABLE_CODE_ANALYSIS)
        target_compile_options(${PROJECT_NAME} PRIVATE /analyze)
    endif()

    if(CMAKE_INTERPROCEDURAL_OPTIMIZATION)
        target_compile_options(${PROJECT_NAME} PRIVATE /Gy /Gw)
    endif()

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.24)
      target_compile_options(${PROJECT_NAME} PRIVATE /ZH:SHA_256)
    endif()

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.26)
        target_compile_options(${PROJECT_NAME} PRIVATE /Zc:preprocessor /wd5105)
    endif()

    if((CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.27) AND (NOT (${DIRECTX_ARCH} MATCHES "^arm")))
        target_link_options(${PROJECT_NAME} PRIVATE /CETCOMPAT)
    endif()

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.28)
        target_compile_options(${PROJECT_NAME} PRIVATE /Zc:lambda)
    endif()

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.32)
        target_compile_options(${PROJECT_NAME} PRIVATE "/wd5246")
    endif()

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.34)
        target_compile_options(${PROJECT_NAME} PRIVATE /wd5262 /wd5264)
    endif()

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.35)
        target_compile_options(${PROJECT_NAME} PRIVATE /Zc:checkGwOdr $<$<VERSION_GREATER_EQUAL:${CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION},10.0.22000>:/Zc:templateScope>)
    endif()

    if(BUILD_TEST_TEMPLATE)
        target_compile_options(${PROJECT_NAME} PRIVATE "/wd4555")
    endif()
endif()

if(WIN32)
    target_compile_definitions(${PROJECT_NAME} PRIVATE _WIN32_WINNT=0x0A00 WINAPI_FAMILY=WINAPI_FAMILY_APP _UNICODE UNICODE)
endif()

set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})

set(UWP_MIN_VERSION 10.0.17763.0)
set(UWP_MAX_TESTED_VERSION 10.0.19041.0)
set(UWP_MIN_CRT_VERSION 14.0.30704.0)
configure_file(Package.appxmanifest AppxManifest.xml @ONLY)

add_custom_command(
  TARGET ${PROJECT_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_CURRENT_BINARY_DIR}/AppxManifest.xml
    $<TARGET_FILE_DIR:${PROJECT_NAME}>
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/Assets
    $<TARGET_FILE_DIR:${PROJECT_NAME}>/Assets
    )

# Loose install from PowerShell
# Add-AppxPackage -Register <cmake_binary_dir>\bin\CMake\AppxManifest.xml
#
# Visual Studio: Debug -> Other Debug Targets -> Debug Installed App Package...
#
# Remove from PowerShell
# Get-AppxPackage -Name <guid-in-package.appxmanifest> | Remove-AppxPackage
