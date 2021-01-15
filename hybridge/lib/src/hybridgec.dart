import 'dart:io' show Platform;
import 'dart:ffi';

import 'channelc.dart';
import 'transportc.dart';

class Hybridge {
  static final instance = Hybridge();
  final lib = DynamicLibrary.open(libpath());

  Pointer<ChannelStub> channelStub;
  Pointer<TransportStub> transportStub;

  Hybridge() {
    channelStub = lib.lookup("channelStub").cast<ChannelStub>();
    transportStub = lib.lookup("transportStub").cast<TransportStub>();
  }

  static String libpath() {
    var path = './hybridge_library/libHybridgeC.so';
    if (Platform.isMacOS) path = './hybridge_library/libHybridgeC.dylib';
    if (Platform.isWindows) path = r'hybridge_library\Debug\HybridgeCd.dll';
    return path;
  }
}
