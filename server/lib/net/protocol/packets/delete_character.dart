import 'package:server/core/player.dart';
import 'package:server/db/sqlite.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/logger.dart';
import 'package:server/utils/services.dart';

class DeleteCharacter implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;
  late Logger _logger;

  DeleteCharacter() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
    _logger = _services.get<Logger>();
  }

  @override
  int header = Headers.deleteCharacter.index;
  late int databaseId;
  late int characterId;

  @override
  void deserialize(Reader reader) {
    databaseId = reader.u16();
    characterId = reader.u16();
  }

  Future<void> _sendAlert(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    _manager.sendTo(player, alert);
  }

  Future<bool> _doesCharacterBelongToPlayer(int databaseId) async {
    final result = await _sqlite.executeQuery(
      'SELECT 1 FROM character_accounts WHERE account_id = ? AND character_id = ?',
      [databaseId, characterId],
    );

    return result.isNotEmpty;
  }

  Future<void> _deleteCharacter() async {
    await _sqlite.executeTransaction((db) async {
      db.execute(
        'DELETE FROM character_accounts WHERE character_id = ?',
        [characterId],
      );

      db.execute(
        'DELETE FROM characters WHERE id = ?',
        [characterId],
      );
    });
  }

  @override
  Future<void> handle(Player player) async {
    try {
      if (!await _doesCharacterBelongToPlayer(databaseId)) {
        await _sendAlert(player, 'Personagem inválido ou não pertence a você.');
        return;
      }

      await _deleteCharacter();

      _manager.sendTo(player, this);
    } catch (e, s) {
      _logger.error('Erro ao apagar o personagem: $e\n$s');

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
