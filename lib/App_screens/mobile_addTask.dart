// ignore_for_file: file_names

import 'dart:developer';

import 'package:expense_management1/App_screens/mobile_Screen.dart';
import 'package:expense_management1/App_settings/commons.dart';
import 'package:expense_management1/model/database_model.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sembast/sembast.dart';

class AddTask extends StatefulWidget {
  final Database database;
  const AddTask({super.key, required this.database});

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
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

  @override
  void initState() {
    super.initState();
    _loadExpenses();

    // _loadDistinctDates();
    //   _controller = AnimationController(
    //     vsync: this,
    //     duration: const Duration(milliseconds: 500),
    //   );

    //   _fadeAnimation = Tween<double>(
    //     begin: 0.0,
    //     end: 2.0,
    //   ).animate(_controller);
  }

  double calculateTotalBalance(List<Expense> expenses) {
    double totalBalance = 0.0;
    for (var expense in expenses) {
      totalBalance += expense.amount;
    }
    return totalBalance;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        body: Center(
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          height: MediaQuery.of(context).size.height / 2 + 180,
          width: MediaQuery.of(context).size.width / 2 + 200,
          child: Row(children: [
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
                              fontFamily: GoogleFonts.imprima().fontFamily,
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
                        keyboardType: const TextInputType.numberWithOptions(),
                        labale: "Amount",
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 20),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            items: prirortys.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: TextStyle(
                                      color: mainColor,
                                      fontFamily:
                                          GoogleFonts.inter().fontFamily,
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
                                fontFamily: GoogleFonts.inter().fontFamily,
                                fontSize: 10),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Spend type was require*",
                          style: TextStyle(
                              // color: mainColor,
                              fontFamily: GoogleFonts.inter().fontFamily,
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
                          items: expenseCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(
                                    color: mainColor,
                                    fontFamily: GoogleFonts.inter().fontFamily,
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
                      if (_titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                backgroundColor: mainColor,
                                content: Text("Title is require")));
                      } else if (_amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                backgroundColor: mainColor,
                                content: Text("Amount is require")));
                      } else {
                        final title = _titleController.text;
                        final amount = double.parse(_amountController.text);
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
                        Navigator.pop(context);

                        _titleController.clear();
                        _amountController.clear();
                      }
                      // final date = _dateFormat.parse(_dateController.text);

                      // _dateController.clear();
                    })
                  ],
                ),
              ),
            )),
          ])),
    ));
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
      required Widget icon,
      required TextInputType keyboardType,
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
