part of 'transfer_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ephemeral X25519 key pair — a fresh one is generated per transfer session.
// Shared secret → HKDF-SHA256 → 32-byte AES-256-GCM key.
// ─────────────────────────────────────────────────────────────────────────────

final _x25519 = X25519();
final _aesGcm = AesGcm.with256bits(nonceLength: 12);
final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

class _SessionCrypto {
  _SessionCrypto({required this.keyPair, required this.publicKeyBytes});

  final SimpleKeyPair keyPair;
  final List<int> publicKeyBytes;
  SecretKey? _sessionKey;

  bool get hasSessionKey => _sessionKey != null;

  // Derive shared session key after receiving the remote public key.
  Future<void> deriveKey(
    List<int> remotePublicKeyBytes,
    String sessionId,
  ) async {
    final remotePubKey = SimplePublicKey(
      remotePublicKeyBytes,
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: remotePubKey,
    );
    _sessionKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode(sessionId),
      info: utf8.encode('dinoshare-v1-transfer'),
    );
  }

  SecretKey get sessionKey {
    assert(_sessionKey != null, 'deriveKey must be called first');
    return _sessionKey!;
  }
}

Future<_SessionCrypto> _generateCrypto() async {
  final keyPair = await _x25519.newKeyPair();
  final pubKey = await keyPair.extractPublicKey();
  return _SessionCrypto(keyPair: keyPair, publicKeyBytes: pubKey.bytes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Wire-format for encrypted messages
//
// [4 bytes: total_len (big-endian)] [12 bytes: nonce] [ciphertext] [16 bytes: GCM tag]
//
// total_len = 12 + len(ciphertext) + 16
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _writeEncrypted(
  Socket socket,
  List<int> plaintext,
  SecretKey key,
) async {
  final nonce = _aesGcm.newNonce();
  final box = await _aesGcm.encrypt(plaintext, secretKey: key, nonce: nonce);
  final payload = Uint8List(12 + box.cipherText.length + 16);
  payload.setRange(0, 12, nonce);
  payload.setRange(12, 12 + box.cipherText.length, box.cipherText);
  payload.setRange(12 + box.cipherText.length, payload.length, box.mac.bytes);
  socket.add(_uint32BE(payload.length));
  socket.add(payload);
}

Future<void> _writeEncryptedJson(
  Socket socket,
  Map<String, dynamic> data,
  SecretKey key,
) => _writeEncrypted(socket, utf8.encode(jsonEncode(data)), key);

Future<Uint8List> _readEncrypted(
  _SocketStreamReader reader,
  SecretKey key,
) async {
  final lenBytes = await reader.readBytes(4);
  final len = _readUint32BE(lenBytes);
  // Minimum valid frame: 12-byte nonce + 0-byte ciphertext + 16-byte GCM tag.
  if (len < 28 || len > _kMaxEncryptedPayloadBytes) {
    throw StateError('Encrypted message length out of bounds: $len');
  }
  final payload = await reader.readBytes(len);
  final nonce = payload.sublist(0, 12);
  final cipherText = payload.sublist(12, len - 16);
  final mac = payload.sublist(len - 16);
  final plaintext = await _aesGcm.decrypt(
    SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
    secretKey: key,
  );
  return Uint8List.fromList(plaintext);
}

Future<Map<String, dynamic>> _readEncryptedJson(
  _SocketStreamReader reader,
  SecretKey key,
) async {
  final bytes = await _readEncrypted(reader, key);
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

// Sends encrypted file data in _kEncryptChunkSize blocks, finishing with an
// empty sentinel block so the receiver knows when the file ends.
Future<void> _sendEncryptedFileData(
  Socket socket,
  _SocketStreamReader reader,
  RandomAccessFile raf,
  int length,
  SecretKey key,
  void Function(int) onBytes,
) async {
  var remaining = length;
  while (remaining > 0) {
    final toRead = min(_kEncryptChunkSize, remaining);
    final chunk = await raf.read(toRead);
    if (chunk.isEmpty) break;
    await _writeEncrypted(socket, chunk, key);
    await socket.flush();
    final ack = await _readEncryptedJson(reader, key);
    if (ack['type'] != 'progress_ack' || ack['bytes'] != chunk.length) {
      throw StateError('Receiver progress acknowledgement failed');
    }
    remaining -= chunk.length;
    onBytes(chunk.length);
  }
  // Empty sentinel
  await _writeEncrypted(socket, const [], key);
}

// Receives encrypted file blocks until sentinel or expectedBytes received.
Future<void> _receiveEncryptedFileData(
  Socket socket,
  _SocketStreamReader reader,
  IOSink sink,
  int expectedBytes,
  SecretKey key,
  void Function(int) onBytes,
) async {
  var received = 0;
  while (received < expectedBytes) {
    final chunk = await _readEncrypted(reader, key);
    if (chunk.isEmpty) break; // sentinel
    sink.add(chunk);
    received += chunk.length;
    onBytes(chunk.length);
    await _writeEncryptedJson(socket, {
      'type': 'progress_ack',
      'bytes': chunk.length,
    }, key);
    await socket.flush();
  }

  // Consume the empty sentinel frame that terminates the encrypted stream.
  if (received >= expectedBytes) {
    final sentinel = await _readEncrypted(reader, key);
    if (sentinel.isNotEmpty) {
      throw StateError('Expected encrypted sentinel after file data');
    }
  }
}
