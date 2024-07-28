import 'package:flutter/material.dart';

class CustomTextfield extends StatefulWidget {
  const CustomTextfield(
      {super.key,
      required this.keyboardType,
      required this.prefixIcon,
      required this.validator,
      required this.hintText,
      required this.controller});

  final Icon? prefixIcon;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
            cursorColor: Colors.amber[700],
            controller: widget.controller,
            maxLength: 50,
            obscureText: widget.hintText!.toLowerCase().contains('password')
                ? _obscureText
                : false,
            keyboardType: widget.keyboardType,
            style: TextStyle(color: Colors.amber[700]),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.black),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.hintText!.toLowerCase().contains('password')
                  ? IconButton(
                      icon: Icon(_obscureText
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: _togglePasswordVisibility,
                    )
                  : null,
              suffixIconColor: Colors.black,
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black45),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
            validator: widget.validator,
          ),
        ],
      ),
    );
  }
}
