import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as a;

class DbHelper{



  Future<Database> openExpenseDatabase() async {
  final dbPath = join(await a.getDatabasesPath(), 'expenses.db');
  final database = await databaseFactoryIo.openDatabase(dbPath);


  return database;
}
}