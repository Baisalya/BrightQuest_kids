#ifndef FLUTTER_PLUGIN_AUDIOPLAYERS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIOPLAYERS_WINDOWS_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

// BrightQuest deliberately provides a no-op Windows registration shim.
// Actual Windows BGM/SFX playback is handled by the app's MCI backend.
FLUTTER_PLUGIN_EXPORT void AudioplayersWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

// Kept as a compatibility alias for Flutter/plugin variants that use the
// C-API-suffixed registration symbol.
FLUTTER_PLUGIN_EXPORT void AudioplayersWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_AUDIOPLAYERS_WINDOWS_PLUGIN_H_
