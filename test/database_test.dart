import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pilahnusa_mobile/models/classification_result.dart';
import 'package:pilahnusa_mobile/models/history_item.dart';
import 'package:pilahnusa_mobile/models/waste_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper & Models Test', () {
    test('WASTE_DATA_MAP contains all 10 classes', () {
      expect(CLASS_LABELS.length, 10);
      for (final label in CLASS_LABELS) {
        expect(WASTE_DATA_MAP.containsKey(label), true, reason: 'Missing label $label in map');
      }
    });

    test('ClassificationResult creates correctly from label and confidence', () {
      final res = ClassificationResult.fromLabelAndConfidence('Botol Plastik', 95.5);
      expect(res.name, 'Botol Plastik');
      expect(res.category, 'anorganik');
      expect(res.confidence, 95.5);
      expect(res.decompositionTime, '450 Tahun');
      expect(res.recyclingTips.isNotEmpty, true);
      expect(res.youtubeTutorials.isNotEmpty, true);
    });

    test('SQLite in-memory insert, query, stats, and delete operations', () async {
      // Test direct SQLite table schema & queries matching DatabaseHelper
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

      // Create scan_history table
      await db.execute('''
        CREATE TABLE scan_history (
          id TEXT PRIMARY KEY,
          timestamp TEXT NOT NULL,
          image_path TEXT,
          image_base64 TEXT,
          user_feedback TEXT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          confidence REAL NOT NULL,
          description TEXT NOT NULL,
          disposal_guide TEXT NOT NULL,
          environmental_impact TEXT,
          decomposition_time TEXT NOT NULL,
          economic_value TEXT,
          recycling_tips TEXT NOT NULL,
          recycling_potential TEXT NOT NULL,
          youtube_tutorials TEXT NOT NULL
        )
      ''');

      // Insert item 1 (Organik)
      final item1 = HistoryItem(
        id: 'test-uuid-1',
        timestamp: DateTime.now(),
        imagePath: '/path/to/apple.jpg',
        imageBase64: 'data:image/jpeg;base64,abc123',
        result: ClassificationResult.fromLabelAndConfidence('Sisa Buah dan Sayur', 91.2),
      );
      await db.insert('scan_history', item1.toMap());

      // Insert item 2 (Anorganik)
      final item2 = HistoryItem(
        id: 'test-uuid-2',
        timestamp: DateTime.now(),
        imagePath: '/path/to/bottle.jpg',
        imageBase64: 'data:image/jpeg;base64,xyz789',
        result: ClassificationResult.fromLabelAndConfidence('Botol Plastik', 89.0),
      );
      await db.insert('scan_history', item2.toMap());

      // Check all history
      final maps = await db.query('scan_history', orderBy: 'timestamp DESC');
      final historyList = maps.map((m) => HistoryItem.fromMap(m)).toList();
      expect(historyList.length, 2);

      // Check stats
      final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM scan_history'));
      final organik = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM scan_history WHERE LOWER(category) = 'organik'"));
      final anorganik = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM scan_history WHERE LOWER(category) = 'anorganik'"));
      expect(total, 2);
      expect(organik, 1);
      expect(anorganik, 1);

      // Delete 1 item
      await db.delete('scan_history', where: 'id = ?', whereArgs: ['test-uuid-1']);
      final remaining = await db.query('scan_history');
      expect(remaining.length, 1);

      await db.close();
    });
  });
}
