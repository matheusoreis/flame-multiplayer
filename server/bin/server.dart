import 'package:server/db/postgres.dart';
import 'package:server/net/listener.dart';
import 'package:server/server.dart';
import 'package:server/utils/cache.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

Future<void> main(List<String> arguments) async {
  final services = Services();
  services.registerSingleton<Logger>(Logger());
  services.registerSingleton(Postgres(
    host: 'localhost',
    database: 'server',
    username: 'server',
    password: 'server',
  ));
  services.registerSingleton<Cache>(Cache());
  services.registerSingleton<Listener>(Listener());

  final logger = services.get<Logger>();
  final pg = services.get<Postgres>();
  try {
    await pg.connect();
    logger.info('Conexão com o banco de dados estabelecida.');
  } catch (e) {
    logger.error('Erro ao conectar ao banco de dados: $e');

    return;
  }

  final server = Server();
  try {
    await server.start(8080);
    logger.info('Servidor iniciado na porta 8080.');
  } catch (e) {
    logger.error('Erro ao iniciar o servidor: $e');
    await pg.close();
  }
}
