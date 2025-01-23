import 'package:server/net/manager.dart';
import 'package:server/server.dart';
import 'package:server/utils/cache.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

void main(List<String> arguments) {
  final services = Services();
  services.registerSingleton<Logger>(Logger());
  services.registerSingleton<Cache>(Cache());
  services.registerFactory<Manager>(() => Manager());

  final server = Server();
  server.start(8080);
}
