import 'package:flutter/material.dart';

class CustomTextFieldSignUp extends StatelessWidget {
  const CustomTextFieldSignUp(
      {super.key,
      required this.prefixIcon,
      required this.hintText,
      required this.controller});

  final Icon? prefixIcon;
  final String? hintText;
  final TextEditingController? controller;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon,
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black45),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
          )
        ],
      ),
    );
  }
}
