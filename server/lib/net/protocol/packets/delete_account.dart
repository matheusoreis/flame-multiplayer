import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:server/core/player.dart';
import 'package:server/db/sqlite.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/services.dart';

class DeleteAccount implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;

  DeleteAccount() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
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

  @override
  Future<void> handle(Player player) async {
    final result = await _sqlite.executeQuery(
      'SELECT * FROM accounts WHERE email = ?',
      [email],
    );

    if (result.isEmpty) {
      final alert = Alert()
        ..message = 'Conta não encontrada!'
        ..isNotification = true;

      await _manager.sendTo(player, alert);

      return;
    }

    final storedPassword = result[0]['password'] as String;
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    if (storedPassword != hashedPassword) {
      final alert = Alert()
        ..message = 'Senha incorreta!'
        ..isNotification = true;

      await _manager.sendTo(player, alert);

      return;
    }

    await _sqlite.executeQuery(
      'DELETE FROM accounts WHERE email = ?',
      [email],
    );

    await _manager.sendTo(player, this);
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
  }
}
