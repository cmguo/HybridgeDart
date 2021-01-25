import 'package:source_gen_test/annotations.dart';
import 'package:hybridge/hybridge.dart';

@ShouldGenerate(
  r'''
class EmptyProxyProxy extends EmptyProxy {
  EmptyProxyProxy(this.proxy);

  final ProxyObject proxy;
}
''',
  contains: true,
)
@Import()
abstract class EmptyProxy {}

@ShouldGenerate(
  r'''
  @override
  Future<int> x() {
    return proxy.invokeMethod("x", []);
  }
''',
  contains: true,
)
@Import()
abstract class MethodProxy {
  Future<int> x();
}

@ShouldGenerate(
  r'''
  @override
  Future<int> x() {
    return proxy.invokeMethod("xxx", []);
  }
''',
  contains: true,
)
@Import()
abstract class RenameMethodProxy {
  @Name("xxx")
  Future<int> x();
}

@ShouldGenerate(
  r'''
  @override
  Future<int> x(int a, int b) {
    return proxy.invokeMethod("x", [a, b]);
  }
''',
  contains: true,
)
@Import()
abstract class MethodArgsProxy {
  Future<int> x(int a, int b);
}

@ShouldGenerate(
  r'''
  @override
  int get x => proxy.readProperty("x");
  @override
  set x(int value) => proxy.writeProperty("x", value);
''',
  contains: true,
)
@Import()
abstract class FieldProxy {
  int x;
}
