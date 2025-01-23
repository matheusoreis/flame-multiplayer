import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/protocol/packet.dart';

class Ping implements Packet {
  @override
  int header = Headers.ping.index;

  @override
  void deserialize(Reader reader) {}

  @override
  void handle(int id) {}

  @override
  void serialize(Writer writer) {}
}
