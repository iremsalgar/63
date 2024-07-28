import 'package:flutter/material.dart';

class CustomTextFieldSignUp extends StatelessWidget {
  const CustomTextFieldSignUp(
      {super.key,
      required this.prefixIcon,
      required this.validator,
      required this.hintText,
      required this.controller});

  final Icon? prefixIcon;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
            cursorColor: Colors.amber[700],
            controller: controller,
            style: TextStyle(color: Colors.amber[700]),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black),
              prefixIcon: prefixIcon,
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black45),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
