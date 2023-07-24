import 'package:flutter/material.dart';

class EditSwitch extends StatelessWidget {
  final bool isEditing;
  final Function change;
  const EditSwitch({super.key, required this.isEditing, required this.change});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 80,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Switch(
            thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                (Set<MaterialState> states) {
              return isEditing
                  ? const Icon(
                      Icons.visibility,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.edit,
                      color: Colors.indigo,
                    );
            }),
            value: isEditing,
            onChanged: (bool value) => change(value)),
      ),
    );
  }
}
