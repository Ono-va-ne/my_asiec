import 'package:flutter/foundation.dart' show kIsWeb;

export 'logger_setup_web.dart'
    if (dart.library.io) 'logger_setup_mobile.dart';