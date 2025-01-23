import 'package:server/core/player.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/utils/services.dart';

class Ping implements Packet {
  final Services _services;
  late Manager _manager;

  Ping() : _services = Services() {
    _manager = _services.get<Manager>();
  }

  @override
  int header = Headers.ping.index;

  @override
  void deserialize(Reader reader) {
    return;
  }

  @override
  void handle(Player player) {
    _manager.sendTo(player, this);
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
  }
}
