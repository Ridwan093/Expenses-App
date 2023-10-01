
import 'package:expenses_app/App_settings/commons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String value;
  final Function(String) onChanged;
  final double left;

  CustomDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.left,
  });

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  bool isDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isDropdownOpen = !isDropdownOpen;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(left: widget.left),
            child: Row(
              children: [
                Text(
                  widget.value,
                  style: GoogleFonts.inknutAntiqua(
                      fontSize: 30, color: Colors.black),
                ),
                Container(
                  height: 17,
                  width: 25,
                  decoration: BoxDecoration(
                      color: mainColor, borderRadius: BorderRadius.circular(5)),
                  child: const Center(
                      child: Icon(Icons.arrow_downward,
                          size: 10, color: Colors.white)),
                )
              ],
            ),
          ),
        ),
        if (isDropdownOpen)
          AnimatedContainer(
            margin: const EdgeInsets.only(left: 16),
            width: 130,
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              border: Border.all(color: mainColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView(
              shrinkWrap: true,
              children: widget.items.map((item) {
                return ListTile(
                  title: Text(item),
                  onTap: () {
                    widget.onChanged(item);
                    setState(() {
                      isDropdownOpen = false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
