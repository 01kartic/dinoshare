part of 'transfer_service.dart';

// Discovery uses a fixed port so all devices on LAN listen on the same address.
// Control port is random (44001-47999) per app launch, announced in discovery.
const String _kDiscoverPing = 'dinoshare_DISCOVER_V1';
const String _kGroupAddress = '239.255.42.42';
const int _kDiscoveryPort = 44000;

// ── Normal-mode transfer constants ──────────────────────────────────────────
const int _kNormalSocketBuffer = 4 * 1024 * 1024; // 4 MB
const int _kNormalParallelConns = 8;
const int _kNormalLargeFileThreshold = 10 * 1024 * 1024; // 10 MB

// ── Full-power-mode transfer constants ───────────────────────────────────────
const int _kPowerSocketBuffer = 16 * 1024 * 1024; // 16 MB
const int _kPowerParallelConns = 16;
const int _kPowerParallelChunkSize = 8 * 1024 * 1024; // 8 MB chunks
const int _kNormalParallelChunkSize = 4 * 1024 * 1024; // 4 MB chunks
const int _kPowerLargeFileThreshold = 1 * 1024 * 1024; // 1 MB

// Each AES-GCM encrypted block carries this many plaintext bytes.
const int _kEncryptChunkSize = 256 * 1024; // 256 KB

// ── Security limits ──────────────────────────────────────────────────────────
// Maximum byte length of a single plaintext handshake/control line before we
// consider it a protocol violation and drop the connection.
const int _kMaxLineLengthBytes = 64 * 1024; // 64 KB

// Maximum byte length of a single encrypted wire frame (nonce + ciphertext +
// GCM tag).  Plaintext cap ≈ this minus 28 bytes of framing overhead.
// Must be larger than _kEncryptChunkSize + 28.
const int _kMaxEncryptedPayloadBytes = 512 * 1024; // 512 KB

// ── Platform-specific socket option constants ────────────────────────────────
// macOS/iOS/BSD  : SOL_SOCKET=0xFFFF, SO_SNDBUF=0x1001, SO_RCVBUF=0x1002
// Linux/Android  : SOL_SOCKET=1,      SO_SNDBUF=7,      SO_RCVBUF=8
// Windows        : same as macOS
int get _kSolSocket => (Platform.isAndroid || Platform.isLinux) ? 1 : 0xFFFF;
int get _kSoSndbuf => (Platform.isAndroid || Platform.isLinux) ? 7 : 0x1001;
int get _kSoRcvbuf => (Platform.isAndroid || Platform.isLinux) ? 8 : 0x1002;

Uint8List _int32LE(int value) {
  final bd = ByteData(4);
  bd.setInt32(0, value, Endian.little);
  return bd.buffer.asUint8List();
}

Uint8List _uint32BE(int value) {
  final bd = ByteData(4);
  bd.setUint32(0, value, Endian.big);
  return bd.buffer.asUint8List();
}

int _readUint32BE(Uint8List bytes, [int offset = 0]) {
  return ByteData.view(
    bytes.buffer,
    bytes.offsetInBytes + offset,
    4,
  ).getUint32(0, Endian.big);
}
