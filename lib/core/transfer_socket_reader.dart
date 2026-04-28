part of 'transfer_service.dart';

class _PendingIncoming {
  const _PendingIncoming({required this.request, required this.socket});

  final IncomingTransferRequest request;
  final Socket socket;
}

/// Buffers a raw [Socket] stream and provides convenient typed reads.
class _SocketStreamReader {
  _SocketStreamReader(Socket socket)
    : _iterator = StreamIterator<List<int>>(socket);

  final StreamIterator<List<int>> _iterator;
  Uint8List _buf = Uint8List(0);

  // ── Primitive reads ──────────────────────────────────────────────────────

  Future<String> readLine() async {
    while (true) {
      final idx = _buf.indexOf(10 /* '\n' */);
      if (idx >= 0) {
        final line = utf8.decode(_buf.sublist(0, idx)).trimRight();
        _buf = _buf.sublist(idx + 1);
        return line;
      }
      if (_buf.length > _kMaxLineLengthBytes) {
        throw StateError('Protocol message exceeds maximum allowed length');
      }
      await _fill();
    }
  }

  /// Read exactly [n] bytes.
  Future<Uint8List> readBytes(int n) async {
    while (_buf.length < n) {
      await _fill();
    }
    final result = _buf.sublist(0, n);
    _buf = _buf.sublist(n);
    return result;
  }

  /// Stream [totalBytes] of raw data into [sink], calling [onChunk] per write.
  Future<void> readToSink(
    int totalBytes,
    IOSink sink,
    void Function(int) onChunk,
  ) async {
    var remaining = totalBytes;
    while (remaining > 0) {
      if (_buf.isNotEmpty) {
        final take = min(remaining, _buf.length);
        sink.add(_buf.sublist(0, take));
        onChunk(take);
        _buf = _buf.sublist(take);
        remaining -= take;
        continue;
      }
      await _fill();
      // If buffer is now larger than remaining, use it directly.
      final chunk = _buf;
      if (chunk.length <= remaining) {
        sink.add(chunk);
        onChunk(chunk.length);
        remaining -= chunk.length;
        _buf = Uint8List(0);
      }
      // Otherwise the loop will drain correctly via the top branch.
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<void> _fill() async {
    final ok = await _iterator.moveNext();
    if (!ok) throw StateError('Connection closed unexpectedly');
    _append(_iterator.current);
  }

  void _append(List<int> chunk) {
    if (_buf.isEmpty) {
      _buf = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    } else {
      final merged = Uint8List(_buf.length + chunk.length);
      merged.setRange(0, _buf.length, _buf);
      merged.setRange(_buf.length, merged.length, chunk);
      _buf = merged;
    }
  }
}
