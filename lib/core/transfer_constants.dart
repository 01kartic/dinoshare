part of 'transfer_service.dart';

// Discovery uses a fixed port so all devices on LAN listen on the same address.
// Control port is random (44001-47999) per app launch, announced in discovery.
const String _kDiscoverPing = 'dinoshare_DISCOVER_V1';
const String _kGroupAddress = '239.255.42.42';
const int _kDiscoveryPort = 44000;

// ── Normal-mode transfer constants ──────────────────────────────────────────
const int _kNormalSocketBuffer = 4 * 1024 * 1024; // 4 MB
const int _kNormalChunkSize = 1 * 1024 * 1024; // 1 MB reads
const int _kNormalParallelConns = 8;
const int _kNormalLargeFileThreshold = 10 * 1024 * 1024; // 10 MB
const int _kNormalFlushThreshold = 4 * 1024 * 1024; // 4 MB

// ── Full-power-mode transfer constants ───────────────────────────────────────
const int _kPowerSocketBuffer = 16 * 1024 * 1024; // 16 MB
const int _kPowerChunkSize = 4 * 1024 * 1024; // 4 MB reads
const int _kPowerParallelConns = 16;
const int _kPowerParallelChunkSize = 8 * 1024 * 1024; // 8 MB chunks
const int _kNormalParallelChunkSize = 4 * 1024 * 1024; // 4 MB chunks
const int _kPowerLargeFileThreshold = 1 * 1024 * 1024; // 1 MB
const int _kPowerFlushThreshold = 16 * 1024 * 1024; // 16 MB

// Each AES-GCM encrypted block carries this many plaintext bytes.
const int _kEncryptChunkSize = 256 * 1024; // 256 KB

// Files larger than this are split into sequential sub-chunks inside
// _sendSingleFile so the sender receives an ACK (and updates progress)
// every _kProgressChunkSize bytes instead of waiting for the entire file.
const int _kProgressChunkSize = 2 * 1024 * 1024; // 2 MB

// ── Security limits ──────────────────────────────────────────────────────────
// Maximum byte length of a single plaintext handshake/control line before we
// consider it a protocol violation and drop the connection.
const int _kMaxLineLengthBytes = 64 * 1024; // 64 KB

// Maximum byte length of a single encrypted wire frame (nonce + ciphertext +
// GCM tag).  Plaintext cap ≈ this minus 28 bytes of framing overhead.
// Must be larger than _kEncryptChunkSize + 28.
const int _kMaxEncryptedPayloadBytes = 512 * 1024; // 512 KB

// Reject transfer_request claims above this threshold before doing disk checks.
// Prevents integer-overflow and unreasonable progress-display values.
const int _kMaxTransferBytes = 10 * 1024 * 1024 * 1024 * 1024; // 10 TB

// Only one unanswered incoming request is handled at a time to prevent a
// spammer from flooding the pending-request map.
const int _kMaxPendingIncoming = 1;

// Upper bound on the number of parallel chunks for a single large file.
// Limits temp-file proliferation if a malicious sender sends an unrealistic
// totalChunks value.
const int _kMaxChunks = 256;

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
