import 'package:cinemate/widgets/forward_button.dart';
import 'package:cinemate/widgets/login_background_image.dart';
import 'package:cinemate/widgets/social_login_button.dart';
import 'package:cinemate/widgets/textfield.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginScreen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LoginBackgroundImage(),
          loginFrontContainer(context),
          const ForwardButton(),
          if (isLoginScreen) const SocialLoginButton()
        ],
      ),
    );
  }

  Positioned loginFrontContainer(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Positioned(
      top: 230,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: screenHeight * 0.42,
        width: screenWidth - 40,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 5)
          ],
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLoginScreen = true;
                    });
                  },
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isLoginScreen ? Colors.black : Colors.black12,
                        ),
                      ),
                      if (isLoginScreen)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          height: 2,
                          width: 52,
                          color: Colors.orange,
                        )
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLoginScreen = false;
                    });
                  },
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        "SIGN UP",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isLoginScreen ? Colors.black12 : Colors.black,
                        ),
                      ),
                      if (!isLoginScreen)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          height: 2,
                          width: 52,
                          color: Colors.orange,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!isLoginScreen)
              const CustomTextfield(
                  hintText: "Name-Surname:", prefixIcon: Icon(Icons.person)),
            const SizedBox(height: 10),
            const CustomTextfield(
              hintText: "E-Mail:",
              prefixIcon: Icon(Icons.email),
            ),
            const SizedBox(height: 10),
            const CustomTextfield(
              hintText: "Password:",
              prefixIcon: Icon(Icons.password),
            ),
            const SizedBox(height: 10),
            if (isLoginScreen)
              TextButton(
                onPressed: () {
                  setState(() {
                    isLoginScreen = false;
                  });
                },
                child: Text(
                  "Don't Have An Account?",
                  style: TextStyle(color: Colors.amber[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
