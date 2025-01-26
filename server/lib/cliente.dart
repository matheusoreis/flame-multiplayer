import 'dart:convert';
import 'dart:io';
import 'package:server/net/buffers/writer.dart';

void main() async {
  final String serverUrl = 'ws://localhost:8080';

  try {
    final WebSocket socket = await WebSocket.connect(serverUrl);
    print('Conectado ao servidor: $serverUrl');

    final writer = Writer(2048);

    print('Digite um comando:');
    print('/acessar - Para acessar sua conta');
    print('/cadastrar - Para criar o personagem');
    print('/apagar - Para apagar o personagem');
    print('/selecionar - Para selecionar o personagem');
    print('/sair - Para fechar a conexão');

    // Escutando mensagens recebidas do servidor
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

    await for (var line in stdin
        .transform(
          utf8.decoder,
        )
        .transform(
          LineSplitter(),
        )) {
      if (line == '/sair') {
        print('Encerrando a conexão...');
        await socket.close();
        break;
      } else if (line == '/acessar') {
        writer.seek(0);
        writer.u16(2);
        writer.string('reisdevmatheus@gmail.com');
        writer.string('123456');

        socket.add(writer.getBuffer());
        print('Pacote enviado: ${writer.getBuffer()}');
      } else if (line == '/cadastrar') {
        writer.seek(0);
        writer.u16(3);
        writer.string('reisdevmatheus@gmail.com');
        writer.string('123456');

        socket.add(writer.getBuffer());
        print('Pacote enviado: ${writer.getBuffer()}');
      } else if (line == '/novo-personagem') {
        writer.seek(0);
        writer.u16(6);
        writer.string('Personagem1');
        writer.string('Azul');
        writer.boolean(true);
        writer.string('Curto');
        writer.string('Preto');
        writer.string('Azuis');
        writer.string('Azul Claro');
        writer.string('Camiseta');
        writer.string('Calças');

        socket.add(writer.getBuffer());
        print('Pacote enviado: ${writer.getBuffer()}');
      } else if (line == '/apagar-personagem') {
        writer.seek(0);
        writer.u16(7);
        writer.u16(7);

        socket.add(writer.getBuffer());
        print('Pacote enviado: ${writer.getBuffer()}');
      } else if (line == '/selecionar-personagem') {
        writer.seek(0);
        writer.u16(8);
        writer.u32(2);

        socket.add(writer.getBuffer());
        print('Pacote enviado: ${writer.getBuffer()}');
      } else {
        print('Comando não reconhecido. Tente novamente.');
      }
    }
  } catch (e) {
    print('Erro ao conectar ao servidor: $e');
  }
}
