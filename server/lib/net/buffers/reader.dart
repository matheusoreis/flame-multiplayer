import 'dart:convert';
import 'dart:typed_data';

class Reader {
  late Uint8List _buffer;
  int offset = 0;
  bool littleEndian = true;

  Reader(Uint8List buffer) {
    _buffer = buffer;
  }

  void seek(int n) {
    offset = n;
  }

  Uint8List bytes(int len) {
    final buf = Uint8List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + offset,
      len,
    );

    offset += len;
    return buf;
  }

  int byte() {
    final n = _buffer[offset];

    offset += 1;
    return n;
  }

  int i16() {
    final n = ByteData.sublistView(_buffer).getInt16(
      offset,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 2;
    return n;
  }

  int u16() {
    final n = ByteData.sublistView(_buffer).getUint16(
      offset,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 2;
    return n;
  }

  int i32() {
    final n = ByteData.sublistView(_buffer).getInt32(
      offset,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 4;
    return n;
  }

  int u32() {
    final n = ByteData.sublistView(_buffer).getUint32(
      offset,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 4;
    return n;
  }

  double f32() {
    final n = ByteData.sublistView(_buffer).getFloat32(
      offset,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 4;
    return n;
  }

  double f64() {
    final n = ByteData.sublistView(_buffer).getFloat64(
      offset,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 8;
    return n;
  }

  bool boolean() {
    return byte() == 1;
  }

  String string() {
    final len = u32();
    final buf = bytes(len);
    return utf8.decode(buf);
  }
}
