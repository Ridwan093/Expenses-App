
import 'package:intl/intl.dart';

class Expense {
  int id;
  final String title;
  final double amount;
  final String type;

  final String priority;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.priority,
    required this.type,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'type': type,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date), // Format date as string
    };
  }
}