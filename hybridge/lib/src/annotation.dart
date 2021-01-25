import 'package:meta/meta.dart';

import 'variant.dart';

@immutable
class Export {
  final String className;

  const Export({this.className});
}

@immutable
class Import {
  final String className;

  const Import({this.className});
}

@immutable
class Ignore {}

@immutable
class Name {
  final String value;

  const Name(this.value);
}

@immutable
class VType {
  final ValueType value;

  const VType(this.value);
}
