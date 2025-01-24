import 'dart:io';

import 'package:server/net/buffers/writer.dart';

class Player {
  final int id;
  final WebSocket _socket;
  final Writer sendBuffer;
  final String _address;

  String getAddress() {
    return _address;
  }

  WebSocket getSocket() {
    return _socket;
  }

  Player(
    this.id,
    this._socket,
    this.sendBuffer,
    this._address,
  );

  Future<void> disconnect(String reason) async {
    await _socket.close(1003, reason);
  }
}
