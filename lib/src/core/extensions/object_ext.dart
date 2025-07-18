extension CastExt on Object {
  T cast<T>() => this as T;
  T? castOrNull<T>() => this is T ? this as T : null;
}
