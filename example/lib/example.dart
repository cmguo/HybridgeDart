import 'package:hybridge/hybridge.dart';

part 'example.g.dart';

@Export()
class ExampleObject {
  int x = 0;

  int inc() {
    return x++;
  }

  int add(int d) {
    return x += d;
  }
}

@Import(className: "ExampleObject")
abstract class IExampleObject {
  int get x;
  set x(int value);
  Future<int> inc();
  Future<int> add(int d);
}
