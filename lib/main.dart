


import 'package:expenses_app/App_screens/mobile_Screen.dart';
import 'package:expenses_app/App_screens/webScreen.dart';
import 'package:expenses_app/Layout_managment/App_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

Future<Database> openExpenseDatabase() async {
  if (kIsWeb) {
    // Set up the database for web using sembast_web
    final databaseFactory = databaseFactoryWeb;
    const dbPath =
        'expense_database.db'; // Change this to your desired database name
    const databasePath = dbPath;
    return await databaseFactory.openDatabase(databasePath);
  } else {
    // For non-web platforms, use a different database directory
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocumentDir.path,
        'expense_database.db'); // Change this to your desired database name

    // Set up the database for desktop (e.g., Windows, macOS) using sembast_io
    final databaseFactory = databaseFactoryIo;

    return await databaseFactory.openDatabase(dbPath);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database when the app starts
  final database = await openExpenseDatabase();

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Database database;

  MyApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Responsive(
          webScreen: WebScreen(database: database),
          mobileScreen: MobileScreen(database: database)),
    );
  }
}
