import 'dart:convert';
import 'dart:io';

import 'package:server/net/manager.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class Server {
  final Services _services;
  late final Logger _logger;
  late final Manager _manager;

  HttpServer? _httpServer;

  Server() : _services = Services() {
    _logger = _services.get<Logger>();
    _manager = _services.get<Manager>();
  }

  Future<void> start(int port) async {
    try {
      _httpServer = await HttpServer.bind('0.0.0.0', port);

      _logger.info('Servidor iniciado com sucesso!');
      _logger.info('Servidor escutando em: 0.0.0.0:$port');
      _logger.info('Aguardando por novas conexões...');

      _logger.info('Digite /help para obter os comandos disponíveis');
      _listenToTerminal();

      await for (HttpRequest request in _httpServer!) {
        if (!WebSocketTransformer.isUpgradeRequest(request)) {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('O acesso HTTP não é permitido')
            ..close();
          return;
        }

        final WebSocket socket = await WebSocketTransformer.upgrade(request);
        _manager.websocketOpen(request, socket);
      }
    } catch (e, s) {
      _logger.error('Falha ao iniciar o servidor, erro: $e\n$s');
    }
  }

  Future<void> _listenToTerminal() async {
    var value = stdin.transform(utf8.decoder).transform(LineSplitter());

    await for (String command in value) {
      if (command == '/exit') {
        await _manager.stop(_httpServer!);
      } else if (command == '/help') {
        _showAvaliableCommands();
      } else {
        _logger.info('Comando desconhecido: $command');
      }
    }
  }

  void _showAvaliableCommands() {
    _logger.info('Comandos disponíveis:');

    const List<String> commands = [
      '/exit - Encerra o servidor.',
      '/help - Exibe a mensagem de ajuda.'
    ];

    for (var command in commands) {
      _logger.info(command);
    }
  }
}
