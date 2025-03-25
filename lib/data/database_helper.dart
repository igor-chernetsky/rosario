import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rosario/models/pattern.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "Roario.db";
  static const _databaseVersion = 1;

  static const table = 'pattern_v1';

  static const columnId = '_id';
  static const columnName = 'name';
  static const columnMatrix = 'matrix';
  static const columnColors = 'colors';
  static const columnPatternId = 'patternId';

  late Database _db;

  matrixToString(List<List<Color?>> matrix) {
    return matrix
        .map((e) => e.map((col) => col?.value.toString()).join(','))
        .join(';');
  }

  List<List<Color?>> stringToMatrix(String value) {
    return value
        .split(';')
        .map((element) => element
            .split(',')
            .map((color) => color == 'null' ? null : Color(int.parse(color)))
            .toList())
        .toList();
  }

  colorsToString(List<Color?> colorsList) {
    return colorsList.map((col) => col?.value.toString()).join(',');
  }

  List<Color> stringToColors(String value) {
    return value.split(',').map((color) => Color(int.parse(color))).toList();
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId TEXT PRIMARY KEY,
            $columnPatternId TEXT NOT NULL,
            $columnName TEXT NOT NULL,
            $columnMatrix TEXT NOT NULL,
            $columnColors TEXT NOT NULL
          )
          ''');
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(BeadsPattern pattern) async {
    var colors =
        pattern.colors == null ? null : colorsToString(pattern.colors!);
    Map<String, dynamic> row = {
      columnId: pattern.id,
      columnName: pattern.name,
      columnPatternId: pattern.patternId,
      columnMatrix: matrixToString(pattern.matrix!),
      columnColors: colors,
    };
    return await _db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<BeadsPattern>> queryAllRows() async {
    var response = await _db.query(table);
    response.map((item) {});
    var data = await _db.query(table);
    var result = data.map((element) {
      var matrix = stringToMatrix(element[columnMatrix] as String);
      List<Color> colors = (element[columnColors] == '')
          ? []
          : stringToColors(element[columnColors] as String);
      return BeadsPattern(
          id: element[columnId] as String,
          name: element[columnName] as String,
          patternId: element[columnPatternId] as String,
          height: matrix.length,
          width: matrix[0].length,
          colors: colors,
          matrix: matrix);
    }).toList();
    return result;
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryRowCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(BeadsPattern pattern) async {
    var colors =
        pattern.colors == null ? null : colorsToString(pattern.colors!);
    Map<String, dynamic> row = {
      columnId: pattern.id,
      columnName: pattern.name,
      columnPatternId: pattern.patternId,
      columnMatrix: matrixToString(pattern.matrix!),
      columnColors: colors
    };
    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [pattern.id],
    );
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(String id) async {
    return await _db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
