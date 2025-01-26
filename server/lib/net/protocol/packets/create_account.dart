import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:server/core/player.dart';
import 'package:server/db/postgres.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/listener.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/email.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class CreateAccount implements Packet {
  final Services _services;
  late Listener _manager;
  late Postgres _pg;
  late Logger _logger;

  CreateAccount() : _services = Services() {
    _manager = _services.get<Listener>();
    _pg = _services.get<Postgres>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.createAccount.index;
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
      if (!isValidEmail(email)) {
        await _sendAlert(player, 'O email fornecido não é válido.');

        return;
      }

      final existingAccounts = await _pg.query(
        'SELECT id FROM accounts WHERE email = @email',
        parameters: {'email': email},
      );

      if (existingAccounts.isNotEmpty) {
        await _sendAlert(player, 'Já existe uma conta com este email.');

        return;
      }

      final hashedPassword = sha256.convert(utf8.encode(password)).toString();

      await _pg.query(
        '''
      INSERT INTO accounts (email, password, created_at)
      VALUES (@Email, @Password, NOW())
      ''',
        parameters: {
          'Email': email,
          'Password': hashedPassword,
        },
      );

      _manager.sendTo(player, this);
    } catch (e, s) {
      _logger.error('Erro ao criar conta: $e\n$s');

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
