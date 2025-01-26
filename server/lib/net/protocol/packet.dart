import 'package:server/core/player.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/protocol/packets/access_account.dart';
import 'package:server/net/protocol/packets/character_list.dart';
import 'package:server/net/protocol/packets/create_account.dart';
import 'package:server/net/protocol/packets/create_character.dart';
import 'package:server/net/protocol/packets/delete_account.dart';
import 'package:server/net/protocol/packets/delete_character.dart';
import 'package:server/net/protocol/packets/ping.dart';
import 'package:server/net/protocol/packets/select_character.dart';

enum Headers {
  ping,
  alert,
  accessAccount,
  createAccount,
  deleteAccount,
  characterList,
  createCharacter,
  deleteCharacter,
  selectCharacter,
}

abstract class Packet {
  late int header;

  void serialize(Writer writer);
  void deserialize(Reader reader);
  Future<void> handle(Player player);
}

final Map<Headers, Packet Function()> packets = {
  Headers.ping: () => Ping(),
  Headers.accessAccount: () => AccessAccount(),
  Headers.createAccount: () => CreateAccount(),
  Headers.deleteAccount: () => DeleteAccount(),
  Headers.characterList: () => CharacterList(),
  Headers.createCharacter: () => CreateCharacter(),
  Headers.deleteCharacter: () => DeleteCharacter(),
  Headers.selectCharacter: () => SelectCharacter(),
};
