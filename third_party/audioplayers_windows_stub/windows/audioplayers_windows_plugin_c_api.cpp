#include "include/audioplayers_windows/audioplayers_windows_plugin.h"

void AudioplayersWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  (void)registrar;
}

void AudioplayersWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  AudioplayersWindowsPluginRegisterWithRegistrar(registrar);
}
