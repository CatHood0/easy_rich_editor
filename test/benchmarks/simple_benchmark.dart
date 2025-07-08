import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter/animation.dart';

// Create a new benchmark by extending BenchmarkBase
class SimpleBenchmark extends BenchmarkBase {
  final VoidCallback callback;
  const SimpleBenchmark(this.callback) : super('Template');

  static void main(VoidCallback callback) {
    SimpleBenchmark(callback).report();
  }

  // The benchmark code.
  @override
  void run() => callback();

  // Not measured setup code executed prior to the benchmark runs.
  @override
  void setup() {}

  // Not measured teardown code executed after the benchmark runs.
  @override
  void teardown() {}

  // To opt into the reporting the time per run() instead of per 10 run() calls.
  @override
  void exercise() {}
}
