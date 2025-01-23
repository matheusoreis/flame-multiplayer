import 'package:server/core/player.dart';
import 'package:server/db/sqlite.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/utils/services.dart';

class CreateAccount implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;

  CreateAccount() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
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

  @override
  Future<void> handle(Player player) async {
    final result = await _sqlite.executeQuery(
      'SELECT * FROM users WHERE email = ?',
      [email],
    );
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
  }
}
