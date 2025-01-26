import 'dart:io';

import 'package:server/core/character.dart';
import 'package:server/net/buffers/writer.dart';

class Player {
  final int id;
  final WebSocket _socket;
  final Writer _buffer;
  final String _address;
  int? _databaseId;
  Character? _character;

  Player(
    this.id,
    this._socket,
    this._buffer,
    this._address,
  );

  String getAddress() {
    return _address;
  }

  WebSocket getSocket() {
    return _socket;
  }

  void setDatabaseId(int id) {
    _databaseId = id;
  }

  Writer getBuffer() {
    return _buffer;
  }

  int? getDatabaseId() {
    if (_databaseId == null) {
      disconnect(
        'Não foi possível verificar a procedência da sua solicitação!',
      );

      return null;
    }

    return _databaseId;
  }

  void setCharacter(Map<String, dynamic> characterData) {
    _character = Character.fromMap(characterData);
  }

  Character? getCharacter() {
    if (_databaseId == null) {
      disconnect(
        'Não foi possível verificar a procedência da sua solicitação!',
      );

      return null;
    }

    return _character;
  }

  Future<void> disconnect(String reason) async {
    await _socket.close(1003, reason);
  }
}
