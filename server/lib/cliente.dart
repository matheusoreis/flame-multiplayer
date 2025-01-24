import 'dart:io';
import 'package:server/net/buffers/writer.dart';

void main() async {
  final String serverUrl = 'ws://localhost:8080';

  try {
    final WebSocket socket = await WebSocket.connect(serverUrl);

    print('Conectado ao servidor: $serverUrl');

    final writer = Writer(2048);

    writer.u16(5);
    writer.u16(1);
    // writer.string('reisdev.matheus@gmail.com');
    // writer.string('123456');

    socket.add(writer.getBuffer());
    print('Pacote enviado: ${writer.getBuffer()}');

    socket.listen(
      (data) {
        print('Recebido do servidor: $data');
      },
      onError: (error) {
        print('Erro no WebSocket: $error');
      },
      onDone: () {
        print('Conexão fechada pelo servidor');
        print('Close Code: ${socket.closeCode}');
        print('Close Reason: ${socket.closeReason}');
      },
    );
  } catch (e) {
    print('Erro ao conectar ao servidor: $e');
  }
}
