import 'package:server/core/player.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/protocol/packets/ping.dart';

enum Headers { ping }

abstract class Packet {
  late int header;

  void serialize(Writer writer);
  void deserialize(Reader reader);
  void handle(Player player);
}

final Map<Headers, Packet Function()> packets = {
  Headers.ping: () => Ping(),
};
