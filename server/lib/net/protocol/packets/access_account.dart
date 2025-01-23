import 'package:server/core/player.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/utils/services.dart';

class AccessAccount implements Packet {
  final Services _services;
  late Manager _manager;

  AccessAccount() : _services = Services() {
    _manager = _services.get<Manager>();
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

  @override
  Future<void> handle(Player player) async {
    _manager.sendTo(player, this);
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
  }
}
