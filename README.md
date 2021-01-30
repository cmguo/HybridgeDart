# HybridgeDart
支持 dart 与其他开发语言相互调用的工具

通过 BasicMessageChannel 与 native （Android、iOS）通讯，可以实现 flutter 与 native 之间的相互调用。

举例，在 dart 中有 ExampleObject 这样一个类 (example.dart)
```dart
class ExampleObject {
  int x = 0;

  int inc() {
    return x++;
  }

  int add(int d) {
    return x += d;
  }
}
```
# 发布 Dart 对象
如果 flutter 的对象，想提供给 native 使用，只要简单完成下列几步就 OK 了。
* 声明可以发布的类
```dart
part 'example.g.dart';

@Export()
class ExampleObject {
  ...
}
```
* 配置构建依赖，自动生成导出相关的代码
```
dev_dependencies:
  hybridge_generator: 1.0.0
  build_runner: ^1.4.0
```
* 在 Channel 中注册对象
```dart
  MetaObject.add(ExampleObject, ExampleObjectMetaObject());
  Channel cp = Channel();
  cp.registerObject("test", ExampleObject());
  cp.connectTo(FlutterTransport("com.test.transport"));
```
* 在 Native 端访问 dart 对象
  使用各平台自己的 Hybridge 库，通过相同名称的 FlutterTransport 来访问该 Channel 中的对象。

# 接收 Native 对象
如果想在 flutter 中访问 native 的对象
* 首先，在 Native 端发布对象
  使用各平台自己的 Hybridge 库，通过相同名称的 FlutterTransport 以及 Channel 来发布对象。
* 在 Dart 声明兼容的对象接口
```dart
abstract class IExampleObject {
  int get x;
  set x(int value);
  Future<int> inc();
  Future<int> add(int d);
}
```
* 在 Channel 在接收 Native 的对象
```dart
Channel cr = Channel();
cr.connectTo(FlutterTransport("com.test.transport"), callback: (objects) {
    IExampleObject po = objects["test"];);
    po.inc().then((value) {
      print("inc() -> $value");
      print("x: ${po.x}");
    });
  }
});
```

