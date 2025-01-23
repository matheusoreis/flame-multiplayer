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
  late String content;

  @override
  void deserialize(Reader reader) {
    content = reader.string();
  }

  @override
  void handle(Player player) {
    print('O jogador ${player.getAddress()} enviou o pacote do ping');
    print('Contendo: $content');

    _manager.sendTo(player, this);
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
    writer.string('Olá cliente, seja vem vindo ao servidor!');
  }
}
