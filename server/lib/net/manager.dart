import 'dart:io';
import 'dart:typed_data';

import 'package:server/core/constants.dart';
import 'package:server/core/player.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/utils/cache.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class Manager {
  final Services _services;
  late final Logger _logger;
  late final Cache _cache;

  Manager() : _services = Services() {
    _logger = _services.get<Logger>();
    _cache = _services.get<Cache>();
  }

  void websocketOpen(HttpRequest request, WebSocket socket) {
    // Obtem o IP do socket.
    final address = request.connectionInfo?.remoteAddress.address ?? '';
    _logger.info('Nova conexão de: $address');

    // Verifica os slots disponíveis.
    final avaliableId = _cache.players.getFirstEmptySlot();
    if (avaliableId == null) {
      _fullServer(socket, address);
      return;
    }

    // cria o jogador.
    final player = Player(
      avaliableId,
      socket,
      Writer(Constants.packetSize),
      address,
    );

    // Adiciona o jogador aos slots.
    _cache.players.add(player);

    // Escuta os eventos do socket.
    socket.listen(
      (message) => _websocketMessage(player, message),
      onError: (error) => _websocketError(player, error),
      onDone: () => _websocketDone(player),
    );
  }

  Future<void> _websocketMessage(Player player, dynamic message) async {
    // Verifica se a mensagem não é bytes.
    if (message is! Uint8List) {
      await player.disconnect('Esse tipo de mensagem não é suportado.');
      return;
    }

    final reader = Reader(message);
    final packetId = reader.u16();

    if (packetId >= Headers.values.length) {
      await player.disconnect('Cabeçalho de pacote inválido.');
      return;
    }

    // Direciona o pacote para o seu Packet correto.
    final header = Headers.values[packetId];
    if (packets.containsKey(header)) {
      final packet = packets[header]!();

      packet.deserialize(reader);
      packet.handle(player);
    } else {
      await player.disconnect('Tipo de pacote desconhecido.');
    }
  }

  void _websocketError(Player player, Object error) {
    _logger.error('Erro na conexão ${player.getAddress()}: $error');

    // Em caso de erro desconecta o jogador.
    player.disconnect(
      'O servidor identificou um erro na sua conexão! Desconectando.',
    );
  }

  void _websocketDone(Player player) {
    _logger.info(
      'Jogador ${player.getAddress()} se desconectou do servidor.',
    );

    // Ao finalizar a conexão remove o jogador dos slots.
    _cache.players.remove(player.id);
  }

  Future<void> _fullServer(WebSocket socket, String address) async {
    // Cria um jogador temporário.
    final player = Player(
      -1,
      socket,
      Writer(0),
      address,
    );

    _logger.info(
      'O servidor está cheio! Desconectando o cliente ${player.id}',
    );

    // Desconecta o jogador temporário.
    await player.disconnect(
      'O servidor está cheio, tente novamente mais tarde!',
    );
  }

  Future<void> sendTo(Player player, Packet packet) async {
    if (player.getSocket().readyState != WebSocket.open) {
      _logger.error('Socket não está aberto para o jogador ${player.id}');
      return;
    }

    // Faz a tentativa de envio do pacote para o jogador.
    try {
      final socket = player.getSocket();

      // Reseta o buffer de envio.
      player.sendBuffer.seek(0);

      // Serializa o pacote.
      packet.serialize(player.sendBuffer);

      // Envia o pacote para o jogador.
      socket.add(player.sendBuffer.getBuffer());
      await socket.done;
    } catch (e) {
      _logger.error('Erro ao enviar pacote para o jogador ${player.id}: $e');
      await player.disconnect('Erro ao enviar pacote.');
    }
  }

  Future<void> sendToAll(Packet packet) async {
    // Envia o pacote para todos os jogadores nos slots.
    await _sendToAllPlayers((player) async {
      await sendTo(player, packet);
    });
  }

  Future<void> sendToAllExcept(Player except, Packet packet) async {
    // Envia o pacote para todos os jogadores exceto o except nos slots.
    await _sendToAllPlayers((player) async {
      // Remove o except da lista
      if (player != except) {
        await sendTo(player, packet);
      }
    });
  }

  Future<void> _sendToAllPlayers(Future<void> Function(Player) action) async {
    // Obtem todos os jogadores nos slots.
    for (var i in _cache.players.getFilledSlots()) {
      // Obtem o jogador presente no slots.
      final player = _cache.players.get(i);

      if (player == null) {
        continue;
      }

      await action(player);
    }
  }

  Future<void> stop(HttpServer server) async {
    for (var i in _cache.players.getFilledSlots()) {
      final player = _cache.players.get(i);

      if (player == null) {
        continue;
      }

      await player.disconnect(
        'O servidor foi fechado!',
      );
    }

    await server.close();
    exit(0);
  }
}
