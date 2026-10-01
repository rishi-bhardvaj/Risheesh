import 'dart:io';
import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8787', help: 'Port to bind')
    ..addOption('host', abbr: 'H', defaultsTo: '127.0.0.1', help: 'Host to bind')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage information');

  final results = parser.parse(arguments);
  if (results['help'] as bool) {
    stdout.writeln('Career OS Server - Companion Ingestion and Sync Engine');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final port = int.tryParse(results['port'] as String) ?? 8787;
  final host = results['host'] as String;

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler((Request request) {
    if (request.url.path == 'healthz') {
      return Response.ok('{"ok":true}', headers: {'content-type': 'application/json'});
    }
    return Response.ok('{"message":"Career OS Server active"}', headers: {'content-type': 'application/json'});
  });

  final server = await io.serve(handler, host, port);
  stdout.writeln('Career OS Server listening on http://${server.address.host}:${server.port}');
}
