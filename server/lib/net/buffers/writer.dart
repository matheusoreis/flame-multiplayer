import 'dart:typed_data';
import 'dart:convert';

class Writer {
  late Uint8List buffer;
  int offset = 0;
  bool littleEndian = true;

  Writer(int capacity) {
    buffer = Uint8List(capacity);
  }

  Uint8List getBuffer() {
    return Uint8List.view(buffer.buffer, 0, offset);
  }

  void bytes(Uint8List buf) {
    buffer.setRange(offset, offset + buf.length, buf);
    offset += buf.length;
  }

  void byte(int value) {
    buffer[offset] = value & 0xff;
    offset += 1;
  }

  void i16(int value) {
    ByteData.sublistView(buffer).setInt16(
      offset,
      value,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 2;
  }

  void u16(int value) {
    ByteData.sublistView(buffer).setUint16(
      offset,
      value,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 2;
  }

  void i32(int value) {
    ByteData.sublistView(buffer).setInt32(
      offset,
      value,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 4;
  }

  void u32(int value) {
    ByteData.sublistView(buffer).setUint32(
      offset,
      value,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 4;
  }

  void f32(double value) {
    ByteData.sublistView(buffer).setFloat32(
      offset,
      value,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 4;
  }

  void f64(double value) {
    ByteData.sublistView(buffer).setFloat64(
      offset,
      value,
      littleEndian ? Endian.little : Endian.big,
    );

    offset += 8;
  }

  void boolean(bool value) {
    byte(value ? 1 : 0);
  }

  void string(String value) {
    final encoded = utf8.encode(value);
    u32(encoded.length);
    bytes(Uint8List.fromList(encoded));
  }
}
