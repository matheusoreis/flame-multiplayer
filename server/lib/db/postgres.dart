import 'package:postgres/postgres.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class Postgres {
  final Services _services;
  late Endpoint _endpoint;
  late Connection _connection;
  late Logger _logger;

  Postgres({
    required String host,
    required String database,
    required String username,
    required String password,
    int port = 5432,
  }) : _services = Services() {
    _endpoint = Endpoint(
      host: host,
      database: database,
      username: username,
      password: password,
      port: port,
    );

    _logger = _services.get<Logger>();
  }

  Future<void> connect() async {
    _connection = await Connection.open(_endpoint);
    _logger.info('Conexão estabelecida com o banco de dados.');
  }

  Future<void> close() async {
    await _connection.close();
    _logger.info('Conexão encerrada.');
  }

  Future<int> execute(String sql, {Map<String, dynamic>? parameters}) async {
    final result = await _connection.execute(
      Sql.named(sql),
      parameters: parameters,
    );

    return result.affectedRows;
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await _connection.execute(
      Sql.named(sql),
      parameters: parameters,
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  Future<void> runTransaction(Future<void> Function(Session) action) async {
    await _connection.runTx(action);
  }
}
