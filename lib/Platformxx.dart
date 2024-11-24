import 'dart:io';

/// 系统平台
class Platformxx_c {
  Platformxx_c._();

  static const bool isWeb = false;

  @pragma("vm:platform-const")
  static final isAndroid = (false == isWeb && Platform.isAndroid);
  @pragma("vm:platform-const")
  static final bool isIOS = (false == isWeb && Platform.isIOS);
  @pragma("vm:platform-const")
  static final bool isMobile = (isAndroid || isIOS);

  @pragma("vm:platform-const")
  static final bool isLinux = (false == isWeb && Platform.isLinux);
  @pragma("vm:platform-const")
  static final bool isMacOS = (false == isWeb && Platform.isMacOS);
  @pragma("vm:platform-const")
  static final bool isWindows = (false == isWeb && Platform.isWindows);
  @pragma("vm:platform-const")
  static final bool isDesktop = (isWindows || isMacOS || isLinux);

  @pragma("vm:platform-const")
  static final bool isFuchsia = (false == isWeb && Platform.isFuchsia);

  static const String AndroidStr = "android",
      IosStr = "ios",
      WebStr = "web",
      WindowsStr = "windows",
      LinuxStr = "linux",
      MacosStr = "macos";

  static final String currentPlatformName = () {
    if (Platformxx_c.isWeb) {
      return Platformxx_c.WebStr;
    } else if (Platformxx_c.isAndroid) {
      return Platformxx_c.AndroidStr;
    } else if (Platformxx_c.isIOS) {
      return Platformxx_c.IosStr;
    } else if (Platformxx_c.isWindows) {
      return Platformxx_c.WindowsStr;
    } else if (Platformxx_c.isLinux) {
      return Platformxx_c.LinuxStr;
    } else if (Platformxx_c.isMacOS) {
      return Platformxx_c.MacosStr;
    } else {
      // 错误
      return "";
    }
  }();

  static final String currentPlatformName_CN = () {
    if (Platformxx_c.isWeb) {
      return "Web";
    } else if (Platformxx_c.isAndroid) {
      return "安卓";
    } else if (Platformxx_c.isIOS) {
      return "IPhone";
    } else if (Platformxx_c.isWindows) {
      return "Windows";
    } else if (Platformxx_c.isLinux) {
      return "Linux";
    } else if (Platformxx_c.isMacOS) {
      return "Mac";
    } else {
      // 错误
      return "";
    }
  }();
}
