import 'package:server/core/character.dart';
import 'package:server/core/player.dart';
import 'package:server/db/postgres.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/listener.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class CharacterList implements Packet {
  final Services _services;
  late Listener _manager;
  late Postgres _pg;
  late Logger _logger;

  CharacterList() : _services = Services() {
    _manager = _services.get<Listener>();
    _pg = _services.get<Postgres>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.characterList.index;
  late int charactersSlots = 0;
  late List<Character> characters;

  @override
  void deserialize(Reader reader) {
    return;
  }

  Future<void> _sendAlert(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    await _manager.sendTo(player, alert);
  }

  @override
  Future<void> handle(Player player) async {
    if (player.getDatabaseId() == null) {
      await _sendAlert(
        player,
        'Você precisa estar autenticado para criar um personagem.',
      );

      return;
    }

    try {
      final result = await _pg.query(
        '''
        SELECT id, name, color, is_male, hair, hair_color, eye, eye_color, shirt, pants, created_at
        FROM characters
        WHERE account_id = @accountId
        ''',
        parameters: {
          'accountId': player.getDatabaseId(),
        },
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
        writer.string(character.createdAt.toIso8601String());
      }
    }
  }
}
