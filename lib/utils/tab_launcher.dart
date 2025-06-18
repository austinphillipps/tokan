import 'package:flutter/foundation.dart' show kIsWeb;

import 'tab_launcher_stub.dart'
    if (dart.library.html) 'tab_launcher_web.dart';

/// Opens [url] in a new browser tab when running on web.
void openTab(String url) {
  if (kIsWeb) {
    openTabImpl(url);
  }
}
