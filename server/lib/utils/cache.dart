import 'package:server/core/player.dart';
import 'package:server/utils/slots.dart';

class Cache {
  final Slots<Player> players = Slots<Player>(100);
}
