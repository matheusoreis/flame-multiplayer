import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';

enum Headers { ping }

abstract class Packet {
  late int header;

  void serialize(Writer writer);
  void deserialize(Reader reader);
  void handle(int id);
}
