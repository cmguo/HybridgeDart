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
