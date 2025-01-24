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

class AccessAccount implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;

  AccessAccount() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
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

  @override
  Future<void> handle(Player player) async {
    final passwordHash = sha256.convert(utf8.encode(password)).toString();

    final result = await _sqlite.executeQuery(
      'SELECT * FROM accounts WHERE email = ?',
      [email],
    );

    if (result.isEmpty) {
      final alert = Alert()
        ..message = 'Usuário não encontrado!'
        ..isNotification = true;

      await _manager.sendTo(player, alert);

      return;
    }

    final storedPassword = result[0]['password'] as String;

    if (storedPassword != passwordHash) {
      final alert = Alert()
        ..message = 'Senha incorreta!'
        ..isNotification = true;

      await _manager.sendTo(player, alert);

      return;
    }

    databaseId = result[0]['id'];
    _manager.sendTo(player, this);
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
    writer.u16(databaseId);
  }
}
