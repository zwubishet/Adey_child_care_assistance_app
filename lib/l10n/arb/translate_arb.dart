import 'dart:convert';
import 'dart:io';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'prompt_contexts.dart';
import 'fallback_translations.dart';

void main(List<String> args) async {
  // Check for API key environment variable
  const apiKey = 'AIzaSyCZd4CRpV_LRLKsCfNSE2DI3DgEA4_xj2c';
  if (apiKey.isEmpty || apiKey.contains('YOUR_GEMINI_API_KEY')) {
    print('Error: Please provide a valid Gemini API key.');
    return;
  }
  Gemini.init(apiKey: apiKey);

  // Check for command-line arguments
  if (args.isEmpty) {
    stderr.writeln('Please provide the path to the input ARB file.');
    exit(1);
  }

  final inputFilePath = args[0];
  final outputFilePath = args.length > 1 ? args[1] : 'app_am.arb';

  try {
    // Read input ARB file
    final inputFile = File(inputFilePath);
    if (!await inputFile.exists()) {
      stderr.writeln('Input file does not exist: $inputFilePath');
      exit(1);
    }

    final inputContent = await inputFile.readAsString();
    final inputJson = jsonDecode(inputContent) as Map<String, dynamic>;

    // Translation cache
    final translationCache = <String, String>{};
    const batchSize = 10;
    final failedKeys = <String>[];

    // Logging setup
    final logFile = File('translation_log.txt');
    final logSink = logFile.openWrite(mode: FileMode.append);
    logSink.writeln('Translation started at ${DateTime.now()}');

    // Process keys in batches
    final keysToTranslate =
        inputJson.keys
            .where((key) => !key.startsWith('@') && key != 'motherAppTitle')
            .toList();

    for (var i = 0; i < keysToTranslate.length; i += batchSize) {
      final batchKeys = keysToTranslate.sublist(
        i,
        (i + batchSize).clamp(0, keysToTranslate.length),
      );

      for (final key in batchKeys) {
        final value = inputJson[key] as String;
        final context =
            promptContexts[key] ??
            'Translate "$value" to Amharic for a mobile app, using a clear and neutral tone.';
        final fallback = fallbackTranslations[key];

        // Check cache first
        if (translationCache.containsKey(key)) {
          logSink.writeln(
            '[$key] Used cached translation: ${translationCache[key]}',
          );
          continue;
        }

        // Validate placeholders
        final placeholders =
            RegExp(
              r'\{[^}]+\}',
            ).allMatches(value).map((m) => m.group(0)!).toSet();
        if (placeholders.isNotEmpty) {
          logSink.writeln('[$key] Contains placeholders: $placeholders');
        }

        try {
          final prompt = '''

$context
Ensure the translation:

    Is accurate and natural in Amharic.

    Preserves any placeholders (e.g., {name}, {date}) exactly as they appear in the original.

    Uses a tone appropriate for a mobile app interface.
    Provide only the translated text as the response.
    ''';

          // Use flutter_gemini API
          final response = await Gemini.instance.text(prompt);
          // Access the text content from the response
          final translatedText =
              response?.content?.parts?.isNotEmpty == true
                  ? response!.content!.parts!.first.toString().trim()
                  : null;

          if (translatedText == null || translatedText.isEmpty) {
            logSink.writeln('[$key] Failed: Empty response from Gemini');
            failedKeys.add(key);
            translationCache[key] = fallback ?? value;
            continue;
          }

          // Validate placeholders in translation
          final translatedPlaceholders =
              RegExp(
                r'{[^}]+}',
              ).allMatches(translatedText).map((m) => m.group(0)!).toSet();
          if (translatedPlaceholders.length != placeholders.length ||
              !placeholders.every((p) => translatedText.contains(p))) {
            logSink.writeln(
              '[$key] Failed: Placeholder mismatch. Expected $placeholders, got $translatedPlaceholders',
            );
            failedKeys.add(key);
            translationCache[key] = fallback ?? value;
            continue;
          }

          // Store in cache
          translationCache[key] = translatedText;
          logSink.writeln('[$key] Translated: $translatedText');
        } catch (e) {
          logSink.writeln('[$key] Failed: $e');
          failedKeys.add(key);
          translationCache[key] = fallback ?? value;
        }
      }

      // Avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Prepare output JSON
    final outputJson = <String, dynamic>{};
    inputJson.forEach((key, value) {
      if (key.startsWith('@')) {
        outputJson[key] = value;
      } else if (key == 'motherAppTitle') {
        outputJson[key] = fallbackTranslations[key] ?? value;
      } else {
        outputJson[key] =
            translationCache[key] ?? fallbackTranslations[key] ?? value;
      }
    });

    // Write output ARB file
    final outputFile = File(outputFilePath);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(outputJson),
      flush: true,
    );

    // Log summary
    logSink.writeln('Translation completed at ${DateTime.now()}');
    logSink.writeln('Total keys processed: ${keysToTranslate.length}');
    logSink.writeln('Failed keys: ${failedKeys.length}');
    if (failedKeys.isNotEmpty) {
      logSink.writeln('Keys that failed: $failedKeys');
    }
    logSink.writeln('Output written to: $outputFilePath');

    await logSink.flush();
    await logSink.close();

    print('Translation completed. Output written to $outputFilePath');
    if (failedKeys.isNotEmpty) {
      print(
        'Warning: ${failedKeys.length} keys failed translation. Check translation_log.txt for details.',
      );
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
