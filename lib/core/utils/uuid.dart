import 'dart:math';

class Uuid {
  static final Random _rand = Random.secure();

  static String v4() {
    final bytes = List<int>.generate(16, (_) => _rand.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();

    return '${b.sublist(0, 4).join()}'
        '-${b.sublist(4, 6).join()}'
        '-${b.sublist(6, 8).join()}'
        '-${b.sublist(8, 10).join()}'
        '-${b.sublist(10, 16).join()}';
  }
}
