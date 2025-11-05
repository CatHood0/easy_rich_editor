import 'package:flutter/foundation.dart';

final bool kIsMacOS = defaultTargetPlatform == TargetPlatform.macOS;
final bool kIsWindows = defaultTargetPlatform == TargetPlatform.windows;
final bool kIsLinux = defaultTargetPlatform == TargetPlatform.linux;
final bool kIsAndroid = defaultTargetPlatform == TargetPlatform.android;
final bool kIsIOS = defaultTargetPlatform == TargetPlatform.iOS;

final bool kIsDesktop = kIsMacOS || kIsLinux || kIsWindows;
final bool kIsMobile = kIsIOS || kIsAndroid;
