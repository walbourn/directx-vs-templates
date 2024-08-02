cmake_minimum_required (VERSION 3.20)

project(CMakeDirect3D12Game
  DESCRIPTION "CMake example for Direct3D 12 Game (Win32)"
  LANGUAGES CXX)

option(BUILD_TEST_TEMPLATE "Ignore warnings related to TODOs" OFF)

option(ENABLE_CODE_ANALYSIS "Use Static Code Analysis on build" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

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
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Aa][Rr][Mm]64EC$")
    set(DIRECTX_ARCH arm64ec)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Ww][Ii][Nn]32$")
    set(DIRECTX_ARCH x86)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Xx]64$")
    set(DIRECTX_ARCH x64)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Aa][Rr][Mm]$")
    set(DIRECTX_ARCH arm)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Aa][Rr][Mm]64$")
    set(DIRECTX_ARCH arm64)
elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT MATCHES "^[Aa][Rr][Mm]64EC$")
    set(DIRECTX_ARCH arm64ec)
endif()

add_executable(${PROJECT_NAME} WIN32
    Game.cpp
    Game.h
    Main.cpp
    StepTimer.h
    pch.h
    d3dx12.h
)

if(NOT MINGW)
    target_precompile_headers(${PROJECT_NAME} PRIVATE pch.h)
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE
    d3d12.lib dxgi.lib dxguid.lib uuid.lib
    kernel32.lib user32.lib
    comdlg32.lib advapi32.lib shell32.lib
    ole32.lib oleaut32.lib
    runtimeobject.lib
)

if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /Wall /EHsc /GR "$<$<NOT:$<CONFIG:DEBUG>>:/guard:cf>")
    target_link_options(${PROJECT_NAME} PRIVATE "$<$<NOT:$<CONFIG:DEBUG>>:/guard:cf>" /DYNAMICBASE /NXCOMPAT)

    if((CMAKE_SIZEOF_VOID_P EQUAL 4) AND (NOT ${DIRECTX_ARCH} MATCHES "^arm"))
        target_link_options(${PROJECT_NAME} PRIVATE /SAFESEH)
    endif()

    if((MSVC_VERSION GREATER_EQUAL 1928)
       AND (CMAKE_SIZEOF_VOID_P EQUAL 8)
       AND ((NOT (CMAKE_CXX_COMPILER_ID MATCHES "Clang|IntelLLVM")) OR (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 13.0)))
        target_compile_options(${PROJECT_NAME} PRIVATE "$<$<NOT:$<CONFIG:DEBUG>>:/guard:ehcont>")
        target_link_options(${PROJECT_NAME} PRIVATE "$<$<NOT:$<CONFIG:DEBUG>>:/guard:ehcont>")
    endif()
else()
    target_compile_definitions(${PROJECT_NAME} PRIVATE $<IF:$<CONFIG:DEBUG>,_DEBUG,NDEBUG>)
endif()

if(NOT ${DIRECTX_ARCH} MATCHES "^arm")
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(ARCH_SSE2 $<$<CXX_COMPILER_ID:MSVC,Intel>:/arch:SSE2> $<$<NOT:$<CXX_COMPILER_ID:MSVC,Intel>>:-msse2>)
    else()
        set(ARCH_SSE2 $<$<NOT:$<CXX_COMPILER_ID:MSVC,Intel>>:-msse2>)
    endif()

    target_compile_options(${PROJECT_NAME} PRIVATE ${ARCH_SSE2})
endif()

if(MINGW)
    find_package(directxmath CONFIG REQUIRED)
    find_package(directx-headers CONFIG REQUIRED)
else()
    find_package(directxmath CONFIG QUIET)
    find_package(directx-headers CONFIG QUIET)
endif()

find_package(directx12-agility CONFIG QUIET)
find_package(directx-dxc CONFIG QUIET)

if(directxmath_FOUND)
    message(STATUS "Using DirectXMath package")
    target_link_libraries(${PROJECT_NAME} PUBLIC Microsoft::DirectXMath)
endif()

if(directx-headers_FOUND)
    message(STATUS "Using DirectX-Headers package")
    target_link_libraries(${PROJECT_NAME} PUBLIC Microsoft::DirectX-Headers Microsoft::DirectX-Guids)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USING_DIRECTX_HEADERS)
endif()

if(directx12-agility_FOUND)
    message(STATUS "Using DirectX12 Agility SDK")
    target_link_libraries(${PROJECT_NAME} PUBLIC Microsoft::DirectX12-Agility)
    target_compile_definitions(${PROJECT_NAME} PRIVATE USING_D3D12_AGILITY_SDK)
endif()

if(directx-dxc_FOUND)
    message(STATUS "Using DirectXShaderCompiler (DXC)")
    target_link_libraries(${PROJECT_NAME} PUBLIC Microsoft::DirectXShaderCompiler)
else()
    find_program(DIRECTX_DXC_TOOL DXC.EXE REQUIRED NO_CMAKE_SYSTEM_PATH)
endif()

# Uncomment if using the DirectX Tool Kit
# find_package(directxtk12 CONFIG REQUIRED)
# target_link_libraries(${PROJECT_NAME} PRIVATE Microsoft::DirectXTK12)

if(MINGW)
    target_link_options(${PROJECT_NAME} PRIVATE -municode)
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|IntelLLVM")
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wpedantic -Wextra
        "-Wno-c++98-compat" "-Wno-c++98-compat-pedantic"
        "-Wno-exit-time-destructors" "-Wno-global-constructors" "-Wno-language-extension-token"
        "-Wno-missing-prototypes" "-Wno-missing-variable-declarations" "-Wno-reserved-id-macro"
        "-Wno-float-equal" "-Wno-switch-enum" "-Wno-tautological-type-limit-compare")

    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 16.0)
        target_compile_options(${PROJECT_NAME} PRIVATE /ZH:SHA_256 "-Wno-unsafe-buffer-usage")
    endif()

    if(BUILD_TEST_TEMPLATE)
        target_compile_options(${PROJECT_NAME} PRIVATE "-Wno-unused-value")
    endif()
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    target_compile_options(${PROJECT_NAME} PRIVATE -Wno-ignored-attributes)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
    target_compile_options(${PROJECT_NAME} PRIVATE /Zc:__cplusplus /Zc:inline /fp:fast /Qdiag-disable:161)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    target_compile_options(${PROJECT_NAME} PRIVATE
         /sdl /permissive- /Zc:__cplusplus /Zc:inline /fp:fast
         "/wd4061" "/wd4365" "/wd4514" "/wd4571" "/wd4668" "/wd4710" "/wd4820" "/wd5039" "/wd5045"
         "/wd4265" "/wd4625" "/wd4626" "/wd4986" "/wd5204" "/wd5220")

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
    target_compile_definitions(${PROJECT_NAME} PRIVATE _UNICODE UNICODE _WIN32_WINNT=0x0A00)
endif()

set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})

if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.21")
   add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E $<IF:$<BOOL:$<TARGET_RUNTIME_DLLS:${PROJECT_NAME}>>,copy,true>
      $<TARGET_RUNTIME_DLLS:${PROJECT_NAME}> $<TARGET_FILE_DIR:${PROJECT_NAME}>
      COMMAND_EXPAND_LISTS
      )
endif()

if(TARGET Microsoft::DirectX12-Agility)
   file(MAKE_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/D3D12")
   add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_PROPERTY:Microsoft::DirectX12-Core,IMPORTED_LOCATION_RELEASE> $<TARGET_FILE_DIR:${PROJECT_NAME}>/D3D12
      COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_PROPERTY:Microsoft::DirectX12-Layers,IMPORTED_LOCATION_DEBUG> $<TARGET_FILE_DIR:${PROJECT_NAME}>/D3D12
      COMMAND ${CMAKE_COMMAND} -E rm -f $<TARGET_FILE_DIR:${PROJECT_NAME}>/D3D12Core.dll
      COMMAND ${CMAKE_COMMAND} -E rm -f $<TARGET_FILE_DIR:${PROJECT_NAME}>/d3d12SDKLayers.dll
      COMMAND_EXPAND_LISTS
      )
endif()
