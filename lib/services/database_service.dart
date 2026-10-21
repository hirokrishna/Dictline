import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class WordModel {
  final int? id;
  final String language;
  final String word;
  final String phonetics;
  final String partOfSpeech;
  final String definition;
  final String exampleEn;
  final String? exampleFr;
  final int level;
  final int isMastered;

  WordModel({
    this.id,
    required this.language,
    required this.word,
    required this.phonetics,
    required this.partOfSpeech,
    required this.definition,
    required this.exampleEn,
    this.exampleFr,
    required this.level,
    this.isMastered = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language': language,
      'word': word,
      'phonetics': phonetics,
      'partOfSpeech': partOfSpeech,
      'definition': definition,
      'exampleEn': exampleEn,
      'exampleFr': exampleFr,
      'level': level,
      'isMastered': isMastered,
    };
  }

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'],
      language: map['language'],
      word: map['word'],
      phonetics: map['phonetics'],
      partOfSpeech: map['partOfSpeech'],
      definition: map['definition'],
      exampleEn: map['exampleEn'],
      exampleFr: map['exampleFr'],
      level: map['level'],
      isMastered: map['isMastered'],
    );
  }
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocab_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language TEXT NOT NULL,
        word TEXT NOT NULL,
        phonetics TEXT NOT NULL,
        partOfSpeech TEXT NOT NULL,
        definition TEXT NOT NULL,
        exampleEn TEXT NOT NULL,
        exampleFr TEXT,
        level INTEGER NOT NULL,
        isMastered INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    String jsonString = await rootBundle.loadString('assets/initial_words.json');
    List<dynamic> jsonList = jsonDecode(jsonString);
    
    for (var item in jsonList) {
      await db.insert('words', WordModel.fromMap(item).toMap());
    }
  }

  Future<List<WordModel>> getWordsByTrackAndLevel(String language, int level) async {
    final db = await instance.database;
    final result = await db.query(
      'words',
      where: 'language = ? AND level = ?',
      whereArgs: [language, level],
    );
    return result.map((json) => WordModel.fromMap(json)).toList();
  }

  Future<void> markAsMastered(int id) async {
    final db = await instance.database;
    await db.update(
      'words',
      {'isMastered': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> checkForNewLevelsOnline(String language, int currentLevel) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/vocab/sync?lang=$language&level=${currentLevel + 1}')
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> newWords = jsonDecode(response.body);
        final db = await instance.database;
        for (var w in newWords) {
          await db.insert('words', WordModel.fromMap(w).toMap());
        }
        return true;
      }
    } catch (_) {}
    return false;
  }
}
