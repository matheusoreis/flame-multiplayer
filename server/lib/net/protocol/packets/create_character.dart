import 'package:server/core/player.dart';
import 'package:server/db/postgres.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/listener.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class CreateCharacter implements Packet {
  final Services _services;
  late Listener _manager;
  late Postgres _pg;
  late Logger _logger;

  CreateCharacter() : _services = Services() {
    _manager = _services.get<Listener>();
    _pg = _services.get<Postgres>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.createCharacter.index;
  late String name;
  late String color;
  late bool isMale;
  late String hair;
  late String hairColor;
  late String eye;
  late String eyeColor;
  late String shirt;
  late String pants;

  @override
  void deserialize(Reader reader) {
    name = reader.string();
    color = reader.string();
    isMale = reader.boolean();
    hair = reader.string();
    hairColor = reader.string();
    eye = reader.string();
    eyeColor = reader.string();
    shirt = reader.string();
    pants = reader.string();
  }

  Future<int> _getCharacterSlots(Player player) async {
    final result = await _pg.query(
      'SELECT characters FROM accounts WHERE id = @id',
      parameters: {'id': player.getDatabaseId()},
    );

    return result.isNotEmpty ? result.first['characters'] as int : 3;
  }

  Future<int> _getCharacterCount(Player player) async {
    final result = await _pg.query(
      'SELECT COUNT(*) AS count FROM character_accounts WHERE account_id = @id',
      parameters: {'id': player.getDatabaseId()},
    );

    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<void> _sendAlert(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    _manager.sendTo(player, alert);
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
      final characterSlots = await _getCharacterSlots(player);
      final characterCount = await _getCharacterCount(player);

      if (characterCount >= characterSlots) {
        await _sendAlert(player, 'Você atingiu o limite de personagens!');

        return;
      }

      final result = await _pg.query(
        '''
      INSERT INTO characters (
        name, color, is_male, hair, hair_color, eye, eye_color, shirt, pants, created_at
      ) VALUES (
        @name, @color, @is_male, @hair, @hair_color, @eye, @eye_color, @shirt, @pants, NOW()
      )
      RETURNING id
      ''',
        parameters: {
          'name': name,
          'color': color,
          'is_male': isMale,
          'hair': hair,
          'hair_color': hairColor,
          'eye': eye,
          'eye_color': eyeColor,
          'shirt': shirt,
          'pants': pants,
        },
      );

      final characterId = result.first['id'] as int;

      await _pg.query(
        '''
      INSERT INTO character_accounts (account_id, character_id)
      VALUES (@account_id, @character_id)
      ''',
        parameters: {
          'account_id': player.getDatabaseId(),
          'character_id': characterId,
        },
      );

      _manager.sendTo(player, this);
    } catch (e, s) {
      _logger.error('Erro ao criar o personagem: $e\n$s');

      await _sendAlert(
        player,
        'Erro interno no servidor. Tente novamente mais tarde.',
      );
    }
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
  }
}
