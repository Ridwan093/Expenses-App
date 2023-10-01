import 'dart:developer';

import 'package:expense_management1/App_screens/mobile_Screen.dart';
import 'package:expense_management1/App_screens/webScreen.dart';
import 'package:expense_management1/App_settings/commons.dart';
import 'package:expense_management1/Layout_managment/App_layout.dart';
import 'package:expense_management1/model/database_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class ExpenseScreen extends StatefulWidget {
  final Database database;

  ExpenseScreen({required this.database});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  List<Expense> expenses = [];
  bool isEditing = false;
  int editingId = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();

    _loadDistinctDates();
  }

  // Future<void> _loadExpenses() async {
  //   final store = intMapStoreFactory.store('expenses');
  //   final finder = Finder(sortOrders: [SortOrder('date')]);
  //   final records = await store.find(widget.database, finder: finder);

  //   setState(() {
  //     expenses = records.map((record) {
  //       return Expense(
  //         type: record.value["type"] as String,
  //         priority: record.value["priority"] as String,
  //         id: record.key,
  //         title: record.value['title'] as String,
  //         amount: record.value['amount'] as double,
  //         date: _dateFormat.parse(record.value['date'] as String),
  //       );
  //     }).toList();
  //   });
  // }

  Future<void> _loadExpenses() async {
    final store = intMapStoreFactory.store('expenses');
    final finder = Finder(sortOrders: [SortOrder('date')]);
    final records = await store.find(widget.database, finder: finder);

    setState(() {
      expenses = records.map((record) {
        final expenseDate = _dateFormat.parse(record.value['date'] as String);

        return Expense(
          type: record.value["type"] as String,
          priority: record.value["priority"] as String,
          id: record.key,
          title: record.value['title'] as String,
          amount: record.value['amount'] as double,
          date: expenseDate,
        );
      }).toList();

      if (expenses.isNotEmpty) {
        totalBalance = calculateTotalBalance(expenses);
      }
    });
  }

  Future<void> _insertExpense(Expense expense) async {
    final store = intMapStoreFactory.store('expenses');
    final finder = Finder(sortOrders: [SortOrder('date')]);
    await store.add(widget.database, expense.toMap());
    log('Expense added: ${expense.title}');
    _loadExpenses();
  }

  Future<void> _updateExpense(Expense expense) async {
    final store = intMapStoreFactory.store('expenses');
    final finder = Finder(sortOrders: [SortOrder('date')]);
    await store.record(expense.id).update(widget.database, expense.toMap());
    _loadExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    final store = intMapStoreFactory.store('expenses');
    await store.record(id).delete(widget.database);
    _loadExpenses();
    setState(() {
      if (expenses.isEmpty) {
        totalBalance = 0.0;
      }
    });
  }

  Future<void> _filterExpensesByDate(String selectedDate) async {
    final store = intMapStoreFactory.store('expenses');
    final finder = Finder(
      filter: Filter.equals('date', selectedDate),
      sortOrders: [SortOrder('date')],
    );

    final records = await store.find(widget.database, finder: finder);

    setState(() {
      expenses = records.map((record) {
        return Expense(
          type: record.value["type"] as String,
          priority: record.value["priority"] as String,
          id: record.key,
          title: record.value['title'] as String,
          amount: record.value['amount'] as double,
          date: _dateFormat.parse(record.value['date'] as String),
        );
      }).toList();
    });
  }

  final List<String> expenseCategories = [
    'Pound',
    'Fish',
    'Enveroment',
    'Transport',
    'Other'
  ];
  final List<String> prirortys = [
    'High',
    'Low',
  ];

  // Create a variable to store the selected category
  String selectedCategory = 'Pound';
  String prirorty = 'High';
  CircleAvatar checkPriority({required String priorityss}) {
    switch (priorityss) {
      case "High":
        return const CircleAvatar(
          child: Icon(Icons.high_quality),
        );

      case "Low":
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.low_priority),
        );

      default:
        return const CircleAvatar(
          child: Icon(Icons.high_quality),
        );
    }
  }

  double totalBalance = 0.0;
  Future<List<String>> _getDistinctDates() async {
    final store = intMapStoreFactory.store('expenses');
    final finder = Finder(
      sortOrders: [SortOrder('date')],
    );

    final records = await store.find(widget.database, finder: finder);

    final distinctDates = records
        .map((record) {
          final date = record.value['date'] as String;
          return DateFormat('yyyy-MM-dd').parse(date);
        })
        .toSet()
        .toList();

    final formattedDates = distinctDates.map((date) {
      final currentDate = DateTime.now();
      final today = _dateFormat.parse(currentDate.toString());
      final yesterday = currentDate.subtract(Duration(days: 1));

      return date == today
          ? 'Today'
          : (date == yesterday ? 'Yesterday' : _dateFormat.format(date));
    }).toList();

    return formattedDates;
  }

  String selectedDate = 'Today'; // Default selected date

  List<String> distinctDates = [];

  Future<void> _loadDistinctDates() async {
    final dates = await _getDistinctDates();
    setState(() {
      distinctDates = dates;
    });
  }

  double calculateTotalBalance(List<Expense> expenses) {
    double totalBalance = 0.0;
    for (var expense in expenses) {
      totalBalance += expense.amount;
    }
    return totalBalance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text("Total" + totalBalance.toString()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text("Total" + totalBalance.toString()),
          )
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: InputDecoration(labelText: 'Title'),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        decoration: InputDecoration(labelText: 'Amount'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _dateController,
                        decoration: InputDecoration(labelText: 'Date'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final title = _titleController.text;
                        final amount = double.parse(_amountController.text);
                        // final date = _dateFormat.parse(_dateController.text);

                        final newExpense = Expense(
                            type: selectedCategory,
                            priority: prirorty,
                            id: 0,
                            title: title,
                            amount: amount,
                            date: DateTime.now());

                        if (isEditing) {
                          newExpense.id = editingId;
                          _updateExpense(newExpense);
                        } else {
                          _insertExpense(newExpense);
                        }

                        _titleController.clear();
                        _amountController.clear();
                        _dateController.clear();
                        setState(() {
                          isEditing = false;
                        });
                      },
                      child: Text(isEditing ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: prirorty,
                onChanged: (String? newValue) {
                  setState(() {
                    prirorty = newValue!;
                  });
                },
                items: prirortys.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                items: expenseCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              // Text('Filter expenses by date:'),
              // ElevatedButton(
              //   onPressed: () async {
              //     final selectedDate = await showDatePicker(
              //       context: context,
              //       initialDate: DateTime.now(),
              //       firstDate: DateTime(2000),
              //       lastDate: DateTime(2101),
              //     );
              //     if (selectedDate != null) {
              //       _filterExpensesByDate(selectedDate);
              //     }
              //   },
              //   child: Text('Select Date'),
              // ),
              // DropdownButton<String>(
              //   value: selectedDate,
              //   onChanged: (String? newValue) {
              //     setState(() {
              //       selectedDate = newValue!;
              //       _filterExpensesByDate(selectedDate);
              //     });
              //   },
              //   items: distinctDates.map((String date) {
              //     return DropdownMenuItem<String>(
              //       value: date,
              //       child: Text(date),
              //     );
              //   }).toList(),
              // ),
              SizedBox(
                height: 300,
                child: Expanded(
                  child: ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final currentDate = DateTime.now();
                      final today = _dateFormat.parse(currentDate.toString());

                      final yesterday = currentDate.subtract(Duration(days: 1));

                      final formattedDate = expense.date == today
                          ? 'Today'
                          : (expense.date == yesterday
                              ? 'Yesterday'
                              : _dateFormat.format(expense.date));

                      return ListTile(
                        title: Text(expense.title),
                        subtitle:
                            Text('\$${expense.amount.toStringAsFixed(2)}'),
                        leading: checkPriority(priorityss: expense.priority),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteExpense(expense.id);
                          },
                        ),
                        onTap: () {
                          setState(() {
                            isEditing = true;
                            editingId = expense.id;
                            _titleController.text = expense.title;
                            _amountController.text = expense.amount.toString();
                            _dateController.text =
                                _dateFormat.format(expense.date);
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          log("messag");
          setState(() {
            isEditing = false;
            editingId = 0;
            _titleController.text = '';
            _amountController.text = '';
            _dateController.text = _dateFormat.format(DateTime.now());
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Manager'),
      ),
      body: Column(
          // Your existing body content here
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Your existing FloatingActionButton code
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: ClipPath(
        clipper: BottomAppBarClipper(), // Use a custom clipper
        child: BottomAppBar(
          color: Colors.blue, // Set your desired background color
          shape:
              CircularNotchedRectangle(), // Match the FloatingActionButton shape
          notchMargin: 10.0, // Adjust the notch margin as needed
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.home),
                onPressed: () {},
                color: Colors.white,
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {},
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 4,
      size.height + 20,
      size.width / 2,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height + 20,
      size.width,
      size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
