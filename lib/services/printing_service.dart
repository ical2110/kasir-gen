import 'printing_service_stub.dart';
import 'printing_service_stub.dart'
    if (dart.library.io) 'printing_service_mobile.dart'
    if (dart.library.html) 'printing_service_web.dart' as implementation;

export 'printing_service_stub.dart';

/// Select the supported implementation at compile time.
PrintingService getPrintingService() => implementation.getPrintingService();
