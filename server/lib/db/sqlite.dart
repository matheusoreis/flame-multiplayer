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
  final String dllPath;
  final String dbPath;

  _QueryData(
    this.sendPort,
    this.query,
    this.parameters,
    this.dllPath,
    this.dbPath,
  );
}

class Sqlite {
  final Services _services;
  late final Logger _logger;
  late final String _dllPath;
  late final String _dbPath;

  Sqlite() : _services = Services() {
    _logger = _services.get<Logger>();

    _dllPath = 'bin/db/sqlite3.dll';
    _dbPath = 'bin/db/sqlite.db';

    if (!File(_dllPath).existsSync()) {
      throw ('A DLL do SQLite3 não foi encontrada em $_dllPath!');
    }

    if (!File(_dbPath).existsSync()) {
      throw ('O arquivo do banco de dados SQLite não foi encontrado em $_dbPath!');
    }

    _logger.info('SQLite3 configurado com sucesso.');
  }

  Future<List<Map<String, dynamic>>> executeQuery(
    String query,
    List<dynamic> parameters,
  ) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _executeQueryInIsolate,
      _QueryData(receivePort.sendPort, query, parameters, _dllPath, _dbPath),
    );

    final result = await receivePort.first;
    receivePort.close();

    return result as List<Map<String, dynamic>>;
  }

  Future<void> insertData(
    String query,
    List<dynamic> parameters,
  ) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _insertDataInIsolate,
      _QueryData(receivePort.sendPort, query, parameters, _dllPath, _dbPath),
    );

    await receivePort.first;
    receivePort.close();
  }

  static void _executeQueryInIsolate(_QueryData data) {
    open.overrideFor(OperatingSystem.windows, () {
      return DynamicLibrary.open(data.dllPath);
    });

    final db = sqlite3.open(data.dbPath);
    final stmt = db.prepare(data.query);

    final resultSet = stmt.select(data.parameters);

    final result =
        resultSet.map((row) => Map<String, dynamic>.from(row)).toList();

    data.sendPort.send(result);

    stmt.dispose();
    db.dispose();
  }

  static void _insertDataInIsolate(_QueryData data) {
    open.overrideFor(OperatingSystem.windows, () {
      return DynamicLibrary.open(data.dllPath);
    });

    final db = sqlite3.open(data.dbPath);
    final stmt = db.prepare(data.query);

    stmt.execute(data.parameters);

    data.sendPort.send('Data inserted successfully');

    stmt.dispose();
    db.dispose();
  }
}
