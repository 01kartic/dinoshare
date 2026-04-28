part of 'state_index.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Transfer history: load, save, add, clear
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _loadTransferHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kTransferHistory);
  if (raw == null || raw.isEmpty) {
    appTransferHistory.value = [];
    return;
  }
  try {
    final list =
        (jsonDecode(raw) as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TransferHistoryItem.fromJson)
            .toList();
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    appTransferHistory.value = list;
  } catch (_) {
    appTransferHistory.value = [];
  }
}

Future<void> addTransferToHistory(TransferSession session) async {
  if (session.status != TransferStatus.completed) return;
  if (session.completedItems.isEmpty) return;

  final item = TransferHistoryItem.fromSession(session);
  final current = List<TransferHistoryItem>.from(appTransferHistory.value);
  current.removeWhere((h) => h.id == item.id);
  current.insert(0, item);
  if (current.length > 100) current.removeRange(100, current.length);
  appTransferHistory.value = current;
  await _saveTransferHistory();
}

Future<void> _saveTransferHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final json = jsonEncode(
    appTransferHistory.value.map((i) => i.toJson()).toList(),
  );
  await prefs.setString(_kTransferHistory, json);
}

Future<void> clearTransferHistory() async {
  appTransferHistory.value = [];
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kTransferHistory);
}
