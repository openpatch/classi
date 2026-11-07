import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Raised when no usable `typst` binary is found.
class TypstUnavailableException implements Exception {
  const TypstUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A `typst` invocation failed; [details] is Typst's own error output,
/// which is usually precise enough to show as-is.
class TypstFailureException implements Exception {
  const TypstFailureException(this.message, {this.details = ''});

  final String message;
  final String details;

  @override
  String toString() => details.isEmpty ? message : '$message\n$details';
}

typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    });

Future<ProcessResult> _defaultRunner(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) => Process.run(
  executable,
  arguments,
  workingDirectory: workingDirectory,
  stdoutEncoding: utf8,
  stderrEncoding: utf8,
);

/// Thin wrapper around the `typst` command line.
///
/// Only available on desktop platforms where classi can start external
/// programs (Linux, Windows). Android and the sandboxed macOS build enter
/// points but do not talk to Typst.
class TypstService {
  TypstService({
    this.configuredBinary,
    ProcessRunner? runner,
    this.timeout = const Duration(minutes: 2),
  }) : _run = runner ?? _defaultRunner;

  /// Explicit path to the `typst` binary from the settings, if any.
  final String? configuredBinary;
  final ProcessRunner _run;
  final Duration timeout;

  static bool get isSupportedPlatform => Platform.isLinux || Platform.isWindows;

  String? _resolved;

  /// The binary to run: the configured path, else `typst` on the PATH.
  Future<String> resolveBinary() async {
    if (_resolved != null) return _resolved!;
    final configured = configuredBinary?.trim();
    if (configured != null && configured.isNotEmpty) {
      if (await File(configured).exists()) return _resolved = configured;
      throw TypstUnavailableException(
        'The configured Typst binary does not exist: $configured',
      );
    }
    final name = Platform.isWindows ? 'typst.exe' : 'typst';
    final separator = Platform.isWindows ? ';' : ':';
    for (final dir in (Platform.environment['PATH'] ?? '').split(separator)) {
      if (dir.isEmpty) continue;
      final candidate = p.join(dir, name);
      if (await File(candidate).exists()) return _resolved = candidate;
    }
    throw const TypstUnavailableException(
      'Typst was not found. Install it or set its path in the settings.',
    );
  }

  /// `typst --version`, e.g. `typst 0.15.1 (9dfd3a08)`.
  Future<String> version() async {
    final result = await _invoke([
      '--version',
    ], failure: 'typst --version failed');
    return (result.stdout as String).trim();
  }

  /// The JSON value of the first element labelled [label] in [main].
  Future<String> queryValue({
    required File main,
    required Directory root,
    required String label,
    Map<String, String> inputs = const {},
  }) async {
    final inputArgs = [
      for (final e in inputs.entries) ...['--input', '${e.key}=${e.value}'],
    ];
    final eval = await _invoke(
      [
        'eval',
        '--root',
        root.path,
        '--in',
        main.path,
        ...inputArgs,
        'query(<$label>).first().value',
      ],
      workingDirectory: root.path,
      allowFailure: true,
    );
    if (eval.exitCode == 0) return (eval.stdout as String).trim();

    final stderr = '${eval.stderr}';
    // Typst before `eval` existed: fall back to the older `query` command.
    if (stderr.contains("unrecognized subcommand") ||
        stderr.contains("unexpected argument 'eval'")) {
      final query = await _invoke(
        [
          'query',
          '--root',
          root.path,
          ...inputArgs,
          main.path,
          '<$label>',
          '--field',
          'value',
          '--one',
        ],
        workingDirectory: root.path,
        failure: 'Typst could not read the document',
      );
      return (query.stdout as String).trim();
    }
    throw TypstFailureException(
      'Typst could not read the document',
      details: _clean(stderr),
    );
  }

  Future<void> compile({
    required File input,
    required Directory root,
    required File output,
    Map<String, String> inputs = const {},
    String? pages,
  }) async {
    await _invoke(
      [
        'compile',
        '--root',
        root.path,
        for (final e in inputs.entries) ...['--input', '${e.key}=${e.value}'],
        if (pages != null) ...['--pages', pages, '--no-pdf-tags'],
        input.path,
        output.path,
      ],
      workingDirectory: root.path,
      failure: 'Typst could not compile the document',
    );
  }

  Future<ProcessResult> _invoke(
    List<String> args, {
    String? workingDirectory,
    String failure = 'Typst failed',
    bool allowFailure = false,
  }) async {
    final binary = await resolveBinary();
    final ProcessResult result;
    try {
      result = await _run(
        binary,
        args,
        workingDirectory: workingDirectory,
      ).timeout(timeout);
    } on TimeoutException {
      throw TypstFailureException('$failure: Typst did not finish in time.');
    } on ProcessException catch (error) {
      throw TypstUnavailableException(
        'Typst could not be started: ${error.message}',
      );
    }
    if (result.exitCode != 0 && !allowFailure) {
      throw TypstFailureException(failure, details: _clean('${result.stderr}'));
    }
    return result;
  }

  /// Drops warnings that are noise for a teacher (deprecations, PDF tags).
  static String _clean(String stderr) {
    final blocks = stderr.trim().split(RegExp(r'\n(?=warning:|error:)'));
    return blocks.where((b) => !b.startsWith('warning:')).join('\n').trim();
  }
}
