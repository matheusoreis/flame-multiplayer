import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

class _QueryData {
  final SendPort sendPort;
  final String query;
  final List<dynamic> parameters;

  _QueryData(this.sendPort, this.query, this.parameters);
}

class Sqlite {
  final Services _services;
  late Logger _logger;
  late Database _db;

  Sqlite() : _services = Services() {
    _logger = _services.get<Logger>();

    final String path = 'bin/db/';
    final String dllPath = '$path/sqlite3.dll';

    if (!File(dllPath).existsSync()) {
      throw ('A DLL do SQLite3 não foi encontrada em $dllPath!');
    }

    open.overrideFor(OperatingSystem.windows, () {
      return DynamicLibrary.open(dllPath);
    });

    _logger.info('SQLite3 carregado na versão ${sqlite3.version.libVersion}');
    _db = sqlite3.open('bin/db/sqlite.db');
  }

  Future<List<Map<String, dynamic>>> executeQuery(
    String query,
    List<dynamic> parameters,
  ) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _executeQuery,
      _QueryData(receivePort.sendPort, query, parameters),
    );

    final result = await receivePort.first;

    receivePort.close();
    isolate.kill(priority: Isolate.immediate);

    return result;
  }

  Future<void> insertData(
    String query,
    List<dynamic> parameters,
  ) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _insertData,
      _QueryData(receivePort.sendPort, query, parameters),
    );

    await receivePort.first;

    receivePort.close();
    isolate.kill(priority: Isolate.immediate);
  }

  void _executeQuery(_QueryData data) {
    final stmt = _db.prepare(data.query);

    final resultSet = stmt.select(data.parameters);

    final result = resultSet.map((row) {
      return {
        'id': row['id'],
        'name': row['name'],
      };
    }).toList();

    data.sendPort.send(result);

    stmt.dispose();
  }

  void _insertData(_QueryData data) {
    final stmt = _db.prepare(data.query);

    stmt.execute(data.parameters);

    data.sendPort.send('Data inserted successfully');

    stmt.dispose();
  }

  void close() {
    _db.dispose();
  }
}
