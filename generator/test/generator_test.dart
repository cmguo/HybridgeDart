import 'dart:async';
import 'package:hybridge/hybridge.dart';
import 'package:hybridge_generator/src/generator.dart';
import 'package:source_gen_test/src/build_log_tracking.dart';
import 'package:source_gen_test/src/init_library_reader.dart';
import 'package:source_gen_test/src/test_annotated_classes.dart';

Future<void> main() async {
  final reader = await initializeLibraryReaderForDirectory(
      'test/src', 'generator_test_src.dart');
  initializeBuildLogTracking();
  testAnnotatedElements<Export>(
      reader, HybridgeExportGenerator(HybridgeOptions()));
  final reader2 = await initializeLibraryReaderForDirectory(
      'test/src', 'generator_test_src2.dart');
  testAnnotatedElements<Import>(
      reader2, HybridgeImportGenerator(HybridgeOptions()));
}
