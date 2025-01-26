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

class SelectCharacter implements Packet {
  final Services _services;
  late Listener _manager;
  late Postgres _pg;
  late Logger _logger;

  SelectCharacter() : _services = Services() {
    _manager = _services.get<Listener>();
    _pg = _services.get<Postgres>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.selectCharacter.index;
  late int characterId;
  late Player player;

  @override
  void deserialize(Reader reader) {
    characterId = reader.u32();
  }

  Future<void> _sendAlert(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    await _manager.sendTo(player, alert);
  }

  @override
  Future<void> handle(Player player) async {
    this.player = player;

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
      SELECT c.* 
      FROM characters c
      INNER JOIN character_accounts ca ON c.id = ca.character_id
      WHERE c.id = @characterId AND ca.account_id = @accountId
      ''',
        parameters: {
          'characterId': characterId,
          'accountId': player.getDatabaseId(),
        },
      );

      if (result.isEmpty) {
        await _sendAlert(
          player,
          'Personagem não encontrado ou não pertence à sua conta!',
        );
        return;
      }

      final characterData = result.first;
      player.setCharacter(characterData);

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

    Character? character = player.getCharacter();
    if (character == null) {
      return;
    }

    writer.u32(character.id);
    writer.string(character.name);
    writer.string(character.color);
    writer.boolean(character.isMale);
    writer.string(character.hair);
    writer.string(character.hairColor);
    writer.string(character.eye);
    writer.string(character.eyeColor);
    writer.string(character.shirt);
    writer.string(character.pants);
  }
}
