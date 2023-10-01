import 'dart:developer';

import 'package:expense_management1/App_settings/commons.dart';
import 'package:expense_management1/Layout_managment/app_widget/customise_dialog.dart';
import 'package:expense_management1/Layout_managment/app_widget/fiter_withDate.dart';
import 'package:expense_management1/model/database_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sembast/sembast.dart';

class WebScreen extends StatefulWidget {
  final Database database;
  const WebScreen({super.key, required this.database});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen>
    with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  Duration _duration = Duration(milliseconds: 1000);
  String selectedCategory = 'Pound';
  String prirorty = 'High';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> prirortys = [
    'High',
    'Low',
  ];

  final List<String> expenseCategories = [
    'Pound',
    'Fish',
    'Enveroment',
    'Transport',
    'Other'
  ];
  bool isSowCotainer = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<Expense> expenses = [];
  bool isEditing = false;
  int editingId = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();

    _loadDistinctDates();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(_controller);
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

  String selectedDate = 'Filter'; // Default selected date

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

  Future<void> _insertExpense(Expense expense) async {
    final store = intMapStoreFactory.store('expenses');
    // final finder = Finder(sortOrders: [SortOrder('date')]);
    await store.add(widget.database, expense.toMap());
    log('Expense added: ${expense.title}');
    _loadExpenses();
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
                  expense.date
                      .isAfter(today.subtract(const Duration(days: 1)))))
          .toList();
    } else if (selectedDate == 'Yesterday') {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      // final formattedYesterday = DateFormat('yyyy-MM-dd').format(yesterday);
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
      // Handle other date selections if needed
    }

    setState(() {
      expenses = filteredExpenses;
    });
  }

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
    _controller.dispose();
    super.dispose();
  }

  void toggleContainer() {
    setState(() {
      isSowCotainer = !isSowCotainer;
      if (isSowCotainer) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final containerWidth = screenWidth / 2 + 200;
    final containerHeight = screenHeight / 2 + 200;
    final size = MediaQuery.of(context).size;
    String formattedTotalSpending =
        NumberFormat('#,##0.00', 'en_US').format(totalBalance);

    return Scaffold(
      floatingActionButton: Material(
        elevation: 20,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: toggleContainer,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: mainColor,
            ),
            child: Center(
              child: Icon(
                !isSowCotainer ? Icons.add : Icons.close,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: SizedBox(
              height: screenHeight,
              width: screenWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 50, bottom: 50),
                child: Stack(
                  // alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        "all your work speed",
                        style: TextStyle(
                          fontFamily: GoogleFonts.ingridDarling().fontFamily,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.only(left: 70),
                        height: containerHeight,
                        width: containerWidth,
                        decoration: BoxDecoration(
                          color: mainColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        margin: const EdgeInsets.only(right: 40),
                        height: containerHeight,
                        width: containerWidth,
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
                              Align(
                                alignment: Alignment.topRight,
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 30, right: 20),
                                      height: 50,
                                      width: 258,
                                      decoration: BoxDecoration(
                                          color: mainColor,
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: Flexible(
                                        child: TextField(
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15)),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15)),
                                                labelText: "Search",
                                                labelStyle: TextStyle(
                                                    fontFamily:
                                                        GoogleFonts.poppins()
                                                            .fontFamily,
                                                    color: Colors.white),
                                                suffixIcon: const Icon(
                                                  Icons.search,
                                                  color: Colors.white,
                                                )),
                                            onChanged: _filterExpensesByTitle),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: <TextSpan>[
                                          const TextSpan(
                                            text: 'Total spending:',
                                            style: TextStyle(
                                              color: mainColor,
                                              // Change the color as needed
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                ' \$$formattedTotalSpending', // Make sure to include a space before the number
                                            style: TextStyle(
                                                color: Colors
                                                    .black, // Change the color as needed
                                                fontSize: 20,
                                                fontFamily:
                                                    GoogleFonts.poppins()
                                                        .fontFamily,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.none,
                                                decorationColor: Colors.black),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SingleChildScrollView(
                                  // padding: const EdgeInsets.only(left: 30),
                                  child: Column(
                                    children: [
                                      CustomDropdown(
                                        left: 90.0,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 40),
                                              child: ListTile(
                                                minLeadingWidth: 0,
                                                title: buildingTiletext(
                                                    "Item list", 60),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            // padding:
                                            //     const EdgeInsets.only(left: 0),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 180),
                                              child: ListTile(
                                                title: buildingTiletext(
                                                    "Price", 40),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            // padding:
                                            //     const EdgeInsets.only(left: 0),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 70),
                                              child: ListTile(
                                                title: buildingTiletext(
                                                    "Date", 40),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                2,
                                        child: ListView.separated(
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return buildItemList(
                                                  ex: expenses[index]);
                                            },
                                            separatorBuilder: (context, i) =>
                                                const Divider(),
                                            itemCount: expenses.length),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
              duration: _duration,
              top: !isSowCotainer ? -500 : 40,
              curve: Curves.bounceInOut,
              child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Material(
                    borderRadius: BorderRadius.circular(20),
                    elevation: 10,
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                        height: MediaQuery.of(context).size.height / 2 + 180,
                        width: MediaQuery.of(context).size.width / 2 + 200,
                        child: Row(
                          children: [
                            Expanded(
                                child: Container(
                              height: size.height,
                              width: size.width,
                              color: Colors.white,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(top: 40),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 45),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          "Add task",
                                          style: TextStyle(
                                              fontFamily: GoogleFonts.imprima()
                                                  .fontFamily,
                                              fontSize: 23),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    buildTextfild(
                                        keyboardType: TextInputType.name,
                                        labale: "Name",
                                        icon: Image.asset(
                                          "assets/g4.png",
                                          color: Colors.grey.shade100,
                                          height: 100,
                                        ),
                                        controller: _titleController),
                                    const SizedBox(
                                      height: 40,
                                    ),
                                    buildTextfild(
                                        keyboardType: const TextInputType
                                            .numberWithOptions(),
                                        labale: "Amount",
                                        icon: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 20),
                                          child: Image.asset(
                                            "assets/wallet.png",
                                            color: Colors.grey.shade300,
                                            height: 35,
                                            width: 35,
                                          ),
                                        ),
                                        controller: _amountController),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Center(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          DropdownButton<String>(
                                            iconEnabledColor: mainColor,
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: mainColor,
                                            ),
                                            value: prirorty,
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                prirorty = newValue!;
                                              });
                                            },
                                            items: prirortys
                                                .map((String category) {
                                              return DropdownMenuItem<String>(
                                                value: category,
                                                child: Text(
                                                  category,
                                                  style: TextStyle(
                                                      color: mainColor,
                                                      fontFamily:
                                                          GoogleFonts.inter()
                                                              .fontFamily,
                                                      fontSize: 12),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          Text(
                                            "Adding priority is optional.",
                                            style: TextStyle(
                                                // color: mainColor,
                                                fontFamily: GoogleFonts.inter()
                                                    .fontFamily,
                                                fontSize: 10),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Spend type was require*",
                                          style: TextStyle(
                                              // color: mainColor,
                                              fontFamily: GoogleFonts.inter()
                                                  .fontFamily,
                                              fontSize: 9),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        DropdownButton<String>(
                                          iconEnabledColor: mainColor,
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                            color: mainColor,
                                          ),
                                          value: selectedCategory,
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedCategory = newValue!;
                                            });
                                          },
                                          items: expenseCategories
                                              .map((String category) {
                                            return DropdownMenuItem<String>(
                                              value: category,
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                    color: mainColor,
                                                    fontFamily:
                                                        GoogleFonts.inter()
                                                            .fontFamily,
                                                    fontSize: 12),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    buildSubmitbutton(ontap: () {
                                      final title = _titleController.text;
                                      final amount =
                                          double.parse(_amountController.text);
                                      // final date = _dateFormat.parse(_dateController.text);

                                      final newExpense = Expense(
                                          type: selectedCategory,
                                          priority: prirorty,
                                          id: 0,
                                          title: title,
                                          amount: amount,
                                          date: DateTime.now());

                                      // if (isEditing) {
                                      //   newExpense.id = editingId;
                                      //   _updateExpense(newExpense);
                                      // } else {
                                      _insertExpense(newExpense);
                                      setState(() {
                                        isSowCotainer = false;
                                      });

                                      _titleController.clear();
                                      _amountController.clear();
                                      // _dateController.clear();
                                    })
                                  ],
                                ),
                              ),
                            )),
                            Expanded(
                                child: SizedBox(
                              height: size.height,
                              width: size.width,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 20, top: 10),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: Material(
                                          elevation: 20,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: InkWell(
                                            onTap: () {},
                                            child: Container(
                                              height: 50,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: mainColor),
                                              child: const Center(
                                                child: Icon(Icons.close,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Padding(
                                    //   padding: const EdgeInsets.only(right: 20, top: 10),
                                    //   child: Align(
                                    //     alignment: Alignment.topRight,
                                    //     child: Text(
                                    //       "all your work speed",
                                    //       style: TextStyle(
                                    //         fontSize: 20,
                                    //         fontFamily: GoogleFonts.ingridDarling().fontFamily,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                    const SizedBox(
                                      height: 125,
                                    ),
                                    Image.network(
                                        "https://i.imgur.com/XKR9WJL.png")
                                  ],
                                ),
                              ),
                            ))
                          ],
                        )),
                  )))
        ],
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
      onTap: () {
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
                Text(
                  "̇${ex.title}",
                  style: const TextStyle(
                      textBaseline: TextBaseline.ideographic,
                      leadingDistribution:
                          TextLeadingDistribution.proportional),
                ),
                const Icon(Icons.highlight)
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
          Flexible(child: Text("\$$formattedTotalSpending       ")),
          Flexible(child: Text(formattedDate)),
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

  Widget buildSubmitbutton({required VoidCallback ontap}) {
    return InkWell(
      onTap: ontap,
      child: Container(
        height: 40,
        width: 300,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: mainColor),
        child: const Center(
          child: Text("Submit", style: TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }

  Widget buildTextfild(
      {required String labale,
      required TextInputType keyboardType,
      required Widget icon,
      required TextEditingController controller}) {
    return Container(
      height: 40,
      width: 300,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: mainColor),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelText: labale,
            labelStyle: const TextStyle(color: Colors.white54),
            suffixIcon: icon),
        controller: controller,
      ),
    );
  }
}
