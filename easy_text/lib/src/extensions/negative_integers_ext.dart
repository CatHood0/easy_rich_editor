extension NegativeIntegersExt on int {
  int get nonNegative => this < 0 ? 0 : this;
}
