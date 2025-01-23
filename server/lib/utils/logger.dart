import 'dart:io';

class Logger {
  final int _red = 31;
  final int _green = 32;
  final int _yellow = 33;
  final int _blue = 34;

  String _colorText(String message, int color) {
    return '\x1B[${color}m$message\x1B[0m';
  }

  String _getTime() {
    var now = DateTime.now();
    var date = "${now.day}/${now.month}/${now.year}";
    var hour = now.hour.toString().padLeft(2, '0');
    var minute = now.minute.toString().padLeft(2, '0');

    return "$date $hour:$minute";
  }

  void info(String message) {
    final prefix = _colorText("[INFO]", _green);
    final time = _getTime();
    final log = _colorText(message, _green);

    stdout.writeln("$prefix $time - $log");
  }

  void warning(String message) {
    final prefix = _colorText("[WARN]", _yellow);
    final time = _getTime();
    final log = _colorText(message, _yellow);

    stdout.writeln("$prefix $time - $log");
  }

  void player(String message) {
    final prefix = _colorText("[PLAYER]", _blue);
    final time = _getTime();
    final log = _colorText(message, _blue);

    stdout.writeln("$prefix $time - $log");
  }

  void error(String message) {
    final prefix = _colorText("[ERROR]", _red);
    final time = _getTime();
    final log = _colorText(message, _red);

    stdout.writeln("$prefix $time - $log");
  }
}
