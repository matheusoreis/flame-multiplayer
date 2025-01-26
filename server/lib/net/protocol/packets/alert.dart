import 'package:server/core/player.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/listener.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/utils/services.dart';

class Alert implements Packet {
  final Services _services;
  late Listener _manager;

  Alert() : _services = Services() {
    _manager = _services.get<Listener>();
  }

  @override
  int header = Headers.alert.index;
  late String message;
  late bool isNotification = false;

  @override
  void deserialize(Reader reader) {
    return;
  }

  @override
  Future<void> handle(Player player) async {
    await _manager.sendTo(player, this);
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
    writer.string(message);
    writer.boolean(isNotification);
  }
}
