import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:server/core/player.dart';
import 'package:server/db/postgres.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/listener.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class AccessAccount implements Packet {
  final Services _services;
  late Listener _manager;
  late Postgres _pg;
  late Logger _logger;

  AccessAccount() : _services = Services() {
    _manager = _services.get<Listener>();
    _pg = _services.get<Postgres>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.accessAccount.index;
  late String email;
  late String password;

  @override
  void deserialize(Reader reader) {
    email = reader.string();
    password = reader.string();
  }

  Future<void> _sendAlert(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    await _manager.sendTo(player, alert);
  }

  @override
  Future<void> handle(Player player) async {
    try {
      final passwordHash = sha256.convert(utf8.encode(password)).toString();

      final result = await _pg.query(
        'SELECT id, password FROM accounts WHERE email = @email',
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        await _sendAlert(player, 'Usuário não encontrado!');

        return;
      }

      final storedPassword = result.first['password'] as String;

      if (storedPassword != passwordHash) {
        await _sendAlert(player, 'Senha incorreta!');

        return;
      }

      final databaseId = result.first['id'] as int;
      player.setDatabaseId(databaseId);

      _manager.sendTo(player, this);
    } catch (e, s) {
      _logger.error('Erro ao acessar conta: $e\n$s');

      await _sendAlert(
        player,
        'Erro interno no servidor. Tente novamente mais tarde.',
      );
    }
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
  }
}
