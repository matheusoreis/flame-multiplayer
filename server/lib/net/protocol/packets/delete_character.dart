import 'package:server/core/player.dart';
import 'package:server/db/postgres.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/listener.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/services.dart';

class DeleteCharacter implements Packet {
  final Services _services;
  late Listener _manager;
  late Postgres _pg;

  DeleteCharacter() : _services = Services() {
    _manager = _services.get<Listener>();
    _pg = _services.get<Postgres>();
  }

  @override
  int header = Headers.deleteCharacter.index;
  late int characterId;

  @override
  void deserialize(Reader reader) {
    characterId = reader.u16();
  }

  Future<void> _sendAlert(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    _manager.sendTo(player, alert);
  }

  Future<bool> _doesCharacterBelongToPlayer(Player player) async {
    final result = await _pg.query(
      'SELECT 1 FROM character_accounts WHERE account_id = @accountId AND character_id = @characterId',
      parameters: {
        'accountId': player.getDatabaseId(),
        'characterId': characterId,
      },
    );

    return result.isNotEmpty;
  }

  Future<void> _deleteCharacter() async {
    await _pg.runTransaction((tx) async {
      await tx.execute(
        'DELETE FROM character_accounts WHERE character_id = @characterId',
        parameters: {'characterId': characterId},
      );

      await tx.execute(
        'DELETE FROM characters WHERE id = @characterId',
        parameters: {'characterId': characterId},
      );
    });
  }

  @override
  Future<void> handle(Player player) async {
    if (player.getDatabaseId() == null) {
      await _sendAlert(
        player,
        'Você precisa estar autenticado para deletar um personagem.',
      );
      return;
    }

    try {
      final doesBelong = await _doesCharacterBelongToPlayer(player);

      if (!doesBelong) {
        await _sendAlert(
          player,
          'Personagem inválido ou não pertence a você.',
        );

        return;
      }

      await _deleteCharacter();

      _manager.sendTo(player, this);
    } catch (e) {
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
