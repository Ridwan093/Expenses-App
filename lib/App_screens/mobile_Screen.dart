

import 'package:expense_management1/App_screens/mobile_addTask.dart';
import 'package:expense_management1/App_settings/commons.dart';
import 'package:expense_management1/Layout_managment/app_widget/customise_dialog.dart';
import 'package:expense_management1/Layout_managment/app_widget/fiter_withDate.dart';
import 'package:expense_management1/main.dart';
import 'package:expense_management1/model/database_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sembast/sembast.dart';

double totalBalance = 0.0;
List<Expense> expenses = [];

class MobileScreen extends StatefulWidget {
  final Database database;
  const MobileScreen({super.key, required this.database});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  bool isEditing = false;
  int editingId = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();

    _loadDistinctDates();
    //   _controller = AnimationController(
    //     vsync: this,
    //     duration: const Duration(milliseconds: 500),
    //   );

    //   _fadeAnimation = Tween<double>(
    //     begin: 0.0,
    //     end: 2.0,
    //   ).animate(_controller);
  }

  Icon checkPriority({required String priorityss}) {
    switch (priorityss) {
      case "High":
        return const Icon(Icons.arrow_upward, color: mainColor, size: 10);

      case "Low":
        return const Icon(Icons.arrow_downward,
            color: Colors.blueGrey, size: 10);

      default:
        return const Icon(Icons.arrow_upward, color: mainColor, size: 10);
    }
  }

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

  String selectedDate = "Filter"; // Default selected date

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

  String searchTerm = '';
  void _filterExpensesByTitle(String value) {
    final filteredExpenses = expenses.where((expense) {
      final title = expense.title.toLowerCase();
      return title.contains(value.toLowerCase());
    }).toList();

    setState(() {
      searchTerm = value;
      expenses = filteredExpenses;

      if (value.isEmpty) {
        _loadExpenses();
      }
    });
  }

  Future<void> _filterExpensesByDate(String selectedDate) async {
    final store = intMapStoreFactory.store('expenses');
    final finder = Finder(sortOrders: [SortOrder('date')]);
    List<Expense> filteredExpenses = [];

    if (selectedDate == 'Today') {
      final today = DateTime.now();
      final formattedToday = DateFormat('yyyy-MM-dd').format(today);
      final records = await store.find(widget.database, finder: finder);

      filteredExpenses = records
          .map((record) {
            final expenseDate =
                DateFormat('yyyy-MM-dd').parse(record.value['date'] as String);

            return Expense(
              type: record.value["type"] as String,
              priority: record.value["priority"] as String,
              id: record.key,
              title: record.value['title'] as String,
              amount: record.value['amount'] as double,
              date: expenseDate,
            );
          })
          .where((expense) =>
              expense.date.isAtSameMomentAs(today) ||
              (expense.date.isBefore(today) &&
                  expense.date.isAfter(today.subtract(Duration(days: 1)))))
          .toList();
    } else if (selectedDate == 'Yesterday') {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final formattedYesterday = DateFormat('yyyy-MM-dd').format(yesterday);
      final records = await store.find(widget.database, finder: finder);

      filteredExpenses = records
          .map((record) {
            final expenseDate =
                DateFormat('yyyy-MM-dd').parse(record.value['date'] as String);

            return Expense(
              type: record.value["type"] as String,
              priority: record.value["priority"] as String,
              id: record.key,
              title: record.value['title'] as String,
              amount: record.value['amount'] as double,
              date: expenseDate,
            );
          })
          .where((expense) =>
              expense.date.isAtSameMomentAs(yesterday) ||
              (expense.date.isBefore(yesterday) &&
                  expense.date.isAfter(yesterday.subtract(Duration(days: 1)))))
          .toList();
    } else {
      // Handle other date selections
      final selectedDateTime = DateFormat('yyyy-MM-dd').parse(selectedDate);
      final records = await store.find(widget.database, finder: finder);

      filteredExpenses = records
          .map((record) {
            final expenseDate =
                DateFormat('yyyy-MM-dd').parse(record.value['date'] as String);

            return Expense(
              type: record.value["type"] as String,
              priority: record.value["priority"] as String,
              id: record.key,
              title: record.value['title'] as String,
              amount: record.value['amount'] as double,
              date: expenseDate,
            );
          })
          .where((expense) => expense.date.isAtSameMomentAs(selectedDateTime))
          .toList();
    }

    setState(() {
      expenses = filteredExpenses;
    });
  }

  // Future<void> _filterExpensesByDate(String selectedDate) async {
  //   final store = intMapStoreFactory.store('expenses');
  //   final finder = Finder(
  //     filter: Filter.equals('date', selectedDate),
  //     sortOrders: [SortOrder('date')],
  //   );

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

  Future<void> _filterExpensesBytitle(String title) async {
    final store = intMapStoreFactory.store('expenses');
    final finder = Finder(
      filter: Filter.equals('title', title),
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

  @override
  void dispose() {
    super.dispose();
  }

  Icon icon({required String priorityss}) {
    switch (priorityss) {
      case "High":
        return const Icon(
          Icons.arrow_upward,
          color: mainColor,
          size: 12,
        );

      case "Low":
        return const Icon(
          Icons.arrow_downward,
          color: Colors.yellow,
          size: 12,
        );

      default:
        return const Icon(
          Icons.arrow_upward,
          color: mainColor,
          size: 12,
        );
    }
  }

  onRefresh() {
    setState(() {
      _loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    String formattedTotalSpending =
        NumberFormat('#,##0.00', 'en_US').format(totalBalance);
    return Scaffold(
      bottomNavigationBar: ClipPath(
        clipper: BottomAppBarClipper(), // Use a custom clipper
        child: BottomAppBar(
          color: mainColor, // Set your desired background color
          shape:
              const CircularNotchedRectangle(), // Match the FloatingActionButton shape
          notchMargin: 10.0, // Adjust the notch margin as needed

          child: Row(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Total spending:',
                      style: TextStyle(
                        color: Colors.white,
                        // Change the color as needed
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' \$$formattedTotalSpending', // Make sure to include a space before the number
                      style: TextStyle(
                          color: Colors.blueGrey, // Change the color as needed
                          fontSize: 15,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: mainColor,
          elevation: 20,
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddTask(database: widget.database)));
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: SafeArea(
        child: Container(
          height: size.height,
          width: size.width,
          decoration: BoxDecoration(
            border: Border.all(
              style: BorderStyle.solid,
              color: mainColor.withOpacity(.7),
            ),
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "all your work speed",
                          style: TextStyle(
                            fontFamily: GoogleFonts.ingridDarling().fontFamily,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 30, right: 10),
                      height: 50,
                      width: 258,
                      decoration: BoxDecoration(
                          color: mainColor,
                          borderRadius: BorderRadius.circular(15)),
                      child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              labelText: "Search",
                              labelStyle: TextStyle(
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  color: Colors.white),
                              suffixIcon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              )),
                          onChanged: _filterExpensesByTitle),
                    ),
                    const SizedBox(height: 16),
                    // RichText(
                    //   text: TextSpan(
                    //     style: DefaultTextStyle.of(context).style,
                    //     children: <TextSpan>[
                    //       const TextSpan(
                    //         text: 'Total spending:',
                    //         style: TextStyle(
                    //           color: mainColor,
                    //           // Change the color as needed
                    //           fontSize: 15,
                    //           fontWeight: FontWeight.bold,
                    //           decoration: TextDecoration.none,
                    //         ),
                    //       ),
                    //       TextSpan(
                    //         text:
                    //             ' \$$formattedTotalSpending', // Make sure to include a space before the number
                    //         style: TextStyle(
                    //             color: Colors
                    //                 .black, // Change the color as needed
                    //             fontSize: 15,
                    //             fontFamily: GoogleFonts.poppins().fontFamily,
                    //             fontWeight: FontWeight.bold,
                    //             decoration: TextDecoration.none,
                    //             decorationColor: Colors.black),
                    //       ),
                    //     ],
                    //   ),
                    // )
                  ],
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropdown(
                        left: 20,
                        items: distinctDates,
                        value: selectedDate,
                        onChanged: (newValue) {
                          setState(() {
                            selectedDate = newValue;

                            _filterExpensesByDate(selectedDate);
                          });
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: ListTile(
                                minLeadingWidth: 0,
                                title: buildingTiletext("Item list", 60),
                              ),
                            ),
                          ),
                          Expanded(
                            // padding:
                            //     const EdgeInsets.only(left: 0),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: ListTile(
                                title: buildingTiletext("Price", 40),
                              ),
                            ),
                          ),
                          Expanded(
                            // padding:
                            //     const EdgeInsets.only(left: 0),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: ListTile(
                                title: buildingTiletext("Date", 40),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 2,
                        child: RefreshIndicator(
                          color: mainColor,
                          onRefresh: () async {
                            await _loadExpenses();
                          },
                          child: ListView.separated(
                              itemBuilder: (BuildContext context, int index) {
                                return buildItemList(ex: expenses[index]);
                              },
                              separatorBuilder: (context, i) => const Divider(),
                              itemCount: expenses.length),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildItemList({required Expense ex}) {
    final currentDate = DateTime.now();
    final today = _dateFormat.parse(currentDate.toString());

    final yesterday = currentDate.subtract(const Duration(days: 1));

    final formattedDate = ex.date == today
        ? 'Today'
        : (ex.date == yesterday ? 'Yesterday' : _dateFormat.format(ex.date));
    String formattedTotalSpending =
        NumberFormat('#,##0.00', 'en_US').format(ex.amount);

    return InkWell(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ExpenseDeleteDialog(onDelete: () {
              _deleteExpense(ex.id);
            });
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
              child: ListTile(
            title: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: Text(
                    "̇${ex.title}",
                    style: const TextStyle(
                        fontSize: 15,
                        textBaseline: TextBaseline.ideographic,
                        leadingDistribution:
                            TextLeadingDistribution.proportional),
                  ),
                ),
                checkPriority(priorityss: ex.priority)
              ],
            ),
            subtitle: Text(
              "Spending on ${ex.type}",
              style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 12,
                  color: Colors.grey),
            ),
          )),
          Flexible(
              flex: 1,
              child: Text("\$$formattedTotalSpending                        ")),
          Flexible(flex: 1, child: Text("$formattedDate         ")),
        ],
      ),
    );
  }

  Widget buildingTiletext(String text, double width) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          height: 3.9,
          width: width,
          color: mainColor,
        )
      ],
    );
  }
}
