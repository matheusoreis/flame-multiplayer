import 'package:server/core/character.dart';
import 'package:server/core/player.dart';
import 'package:server/db/sqlite.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class CharacterList implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;
  late Logger _logger;

  CharacterList() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.characterList.index;
  late int databaseId;
  late int charactersSlots = 0;
  late List<Character> characters;

  @override
  void deserialize(Reader reader) {
    databaseId = reader.u16();
  }

  Future<void> _sendAlert(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    await _manager.sendTo(player, alert);
  }

  @override
  Future<void> handle(Player player) async {
    try {
      final accountResult = await _sqlite.executeQuery(
        'SELECT characters FROM accounts WHERE id = ?',
        [databaseId],
      );

      if (accountResult.isNotEmpty) {
        charactersSlots = accountResult[0]['characters'];
      }

      final result = await _sqlite.executeQuery(
        'SELECT * FROM characters WHERE id IN (SELECT character_id FROM character_accounts WHERE account_id = ?)',
        [databaseId],
      );

      characters = result.map((row) => Character.fromMap(row)).toList();

      _manager.sendTo(player, this);
    } catch (e, s) {
      _logger.error('Erro ao listar os personagens: $e\n$s');

      await _sendAlert(
        player,
        'Erro interno no servidor. Tente novamente mais tarde.',
      );
    }
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
    writer.byte(charactersSlots);
    writer.byte(characters.length);

    if (characters.isNotEmpty) {
      for (var character in characters) {
        writer.u16(character.id);
        writer.string(character.name);
        writer.string(character.color);
        writer.boolean(character.isMale);
        writer.string(character.hair);
        writer.string(character.hairColor);
        writer.string(character.eye);
        writer.string(character.eyeColor);
        writer.string(character.shirt);
        writer.string(character.pants);
        writer.string(character.createdAt.toString());
      }
    }
  }
}
