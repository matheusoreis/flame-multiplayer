import 'package:server/core/player.dart';
import 'package:server/db/sqlite.dart';
import 'package:server/net/buffers/reader.dart';
import 'package:server/net/buffers/writer.dart';
import 'package:server/net/manager.dart';
import 'package:server/net/protocol/packet.dart';
import 'package:server/net/protocol/packets/alert.dart';
import 'package:server/utils/services.dart';

class CreateCharacter implements Packet {
  final Services _services;
  late Manager _manager;
  late Sqlite _sqlite;

  CreateCharacter() : _services = Services() {
    _manager = _services.get<Manager>();
    _sqlite = _services.get<Sqlite>();
  }

  @override
  int header = Headers.createCharacter.index;
  late int databaseId;
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
    databaseId = reader.u16();
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

  Future<int> _getCharacterSlots() async {
    final accountResult = await _sqlite.executeQuery(
      'SELECT characters FROM accounts WHERE id = ?',
      [databaseId],
    );

    return accountResult.isNotEmpty ? accountResult[0]['characters'] : 3;
  }

  Future<int> _getCharacterCount() async {
    final characterCountResult = await _sqlite.executeQuery(
      'SELECT COUNT(*) FROM character_accounts WHERE account_id = ?',
      [databaseId],
    );

    bool isNotEmpty = characterCountResult.isNotEmpty;

    return isNotEmpty ? characterCountResult[0]['COUNT(*)'] : 0;
  }

  Future<void> _sendAlertToPlayer(Player player, String message) async {
    final alert = Alert()
      ..message = message
      ..isNotification = true;

    _manager.sendTo(player, alert);
  }

  @override
  Future<void> handle(Player player) async {
    final characterSlots = await _getCharacterSlots();
    final characterCount = await _getCharacterCount();

    if (characterCount >= characterSlots) {
      await _sendAlertToPlayer(player, 'Você atingiu o limite de personagens!');

      return;
    }

    await _sqlite.executeTransaction((db) async {
      db.execute(
        'INSERT INTO characters (name, color, is_male, hair, hair_color, eye, eye_color, shirt, pants, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          name,
          color,
          isMale ? 1 : 0,
          hair,
          hairColor,
          eye,
          eyeColor,
          shirt,
          pants,
          DateTime.now().toIso8601String(),
        ],
      );

      final newCharacterId = db.select(
        'SELECT last_insert_rowid() AS id',
      )[0]['id'];

      db.execute(
        'INSERT INTO character_accounts (account_id, character_id) VALUES (?, ?)',
        [databaseId, newCharacterId],
      );
    });

    _manager.sendTo(player, this);
  }

  @override
  void serialize(Writer writer) {
    writer.u16(header);
  }
}
