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

class DeleteAccount implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;
  late Logger _logger;

  DeleteAccount() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.deleteAccount.index;
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
      final result = await _sqlite.executeQuery(
        'SELECT * FROM accounts WHERE email = ?',
        [email],
      );

      if (result.isEmpty) {
        await _sendAlert(player, 'Conta não encontrada!');

        return;
      }

      final storedPassword = result[0]['password'] as String;
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      if (storedPassword != hashedPassword) {
        await _sendAlert(player, 'Senha incorreta!');

        return;
      }

      await _sqlite.executeQuery(
        'DELETE FROM accounts WHERE email = ?',
        [email],
      );

      await _manager.sendTo(player, this);
    } catch (e, s) {
      _logger.error('Erro ao apagar conta: $e\n$s');

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
