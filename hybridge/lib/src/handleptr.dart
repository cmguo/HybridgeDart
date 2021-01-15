import 'dart:ffi';

class Handle extends Struct {
  Pointer<Void> callback;

  Handle(this.callback);

  static Handle fromCallback<C extends Struct>(C callback) {
    return Handle(callback.addressOf.cast<Void>());
  }
}
