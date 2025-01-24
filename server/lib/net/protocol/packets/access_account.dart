import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:server/core/player.dart';
import 'package:server/db/sqlite.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class AccessAccount implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;
  late Logger _logger;

  AccessAccount() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.accessAccount.index;
  late String email;
  late String password;
  late int databaseId;

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

      final result = await _sqlite.executeQuery(
        'SELECT id, password FROM accounts WHERE email = ?',
        [email],
      );

      if (result.isEmpty) {
        await _sendAlert(player, 'Usuário não encontrado!');
        return;
      }

      final storedPassword = result[0]['password'] as String;

      if (storedPassword != passwordHash) {
        await _sendAlert(player, 'Senha incorreta!');

        return;
      }

      databaseId = result[0]['id'] as int;

      _manager.sendTo(player, this);
    } catch (e, stackTrace) {
      _logger.error('Erro ao acessar conta: $e\n$stackTrace');

      await _sendAlert(
        player,
        'Erro interno no servidor. Tente novamente mais tarde.',
      );
    }
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
    writer.u16(databaseId);
  }
}
