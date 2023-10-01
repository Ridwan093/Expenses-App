import 'package:flutter/material.dart';

class ExpenseDeleteDialog extends StatelessWidget {
  final VoidCallback onDelete;

  ExpenseDeleteDialog({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete Expense'),
      content: Text('Are you sure you want to delete this expense?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onDelete(); // Call the onDelete callback to delete the expense
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Delete'),
        ),
      ],
    );
  }
}

// To show the dialog, you can call it like this:
void showDeleteExpenseDialog(BuildContext context, VoidCallback onDelete) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ExpenseDeleteDialog(onDelete: onDelete);
    },
  );
}

