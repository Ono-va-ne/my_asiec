import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  // ФИКСИРОВАННЫЙ ВЕКТОР ИНИЦИАЛИЗАЦИИ (ровно 16 символов = 16 байт)
  // Теперь он НЕ сбрасывается и НЕ генерируется заново при перезапуске приложения!
  static final _iv = encrypt.IV.fromUtf8('college_iv_12345');

  // 32-байтный ключ чата
  static encrypt.Key _getKeyForChat(int chatId) {
    final rawKey = 'college_messenger_secret_chat_$chatId'.padRight(32, '0').substring(0, 32);
    return encrypt.Key.fromUtf8(rawKey);
  }

  // Зашифровать открытый текст в Base64
  static String encryptText(String plainText, int chatId) {
    if (plainText.isEmpty) return '';
    final encrypter = encrypt.Encrypter(encrypt.AES(_getKeyForChat(chatId)));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  // Расшифровать Base64 в открытый текст
  static String decryptText(String cipherText, int chatId) {
    if (cipherText.isEmpty) return '';
    
    try {
      final sanitizedText = cipherText.replaceAll(' ', '+');
      final encrypter = encrypt.Encrypter(encrypt.AES(_getKeyForChat(chatId)));
      return encrypter.decrypt64(sanitizedText, iv: _iv);
    } catch (e) {
      // Если это старое нешифрованное сообщение или не Base64 — возвращаем как есть
      return cipherText;
    }
  }
}