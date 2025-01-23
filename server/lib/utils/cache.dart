import 'package:server/core/constants.dart';
import 'package:server/core/player.dart';
import 'package:server/utils/slots.dart';

class Cache {
  final players = Slots<Player>(Constants.maxPlayers);
}
