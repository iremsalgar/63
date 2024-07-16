import 'package:cinemate/services/auth.dart';
import 'package:cinemate/widgets/login_background_image.dart';
import 'package:cinemate/widgets/signuptextfield.dart';
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

  final usernameControllerUp = TextEditingController();
  final emailControllerUp = TextEditingController();
  final passControllerUp = TextEditingController();
  final emailControllerIn = TextEditingController();
  final passControllerIn = TextEditingController();
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    usernameControllerUp.dispose();
    emailControllerUp.dispose();
    passControllerUp.dispose();
    emailControllerIn.dispose();
    passControllerIn.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const LoginBackgroundImage(),
          loginFrontContainer(context),
          if (!isLoginScreen)
            SignUpButton(
                usernameController: usernameControllerUp,
                emailController: emailControllerUp,
                passController: passControllerUp),
          if (isLoginScreen)
            LoginButton(
                emailControllerIn: emailControllerIn,
                passControllerIn: passControllerIn),
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
              CustomTextFieldSignUp(
                  controller: usernameControllerUp,
                  hintText: "Name-Surname:",
                  prefixIcon: const Icon(Icons.person)),
            const SizedBox(height: 10),
            if (!isLoginScreen)
              CustomTextFieldSignUp(
                controller: emailControllerUp,
                hintText: "E-Mail:",
                prefixIcon: const Icon(Icons.email),
              ),
            const SizedBox(height: 10),
            if (!isLoginScreen)
              CustomTextFieldSignUp(
                controller: passControllerUp,
                hintText: "Password:",
                prefixIcon: const Icon(Icons.password),
              ),
            if (isLoginScreen)
              CustomTextfield(
                controller: emailControllerIn,
                hintText: "E-Mail:",
                prefixIcon: const Icon(Icons.email),
              ),
            if (isLoginScreen)
              CustomTextfield(
                controller: passControllerIn,
                hintText: "Password:",
                prefixIcon: const Icon(Icons.password),
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

class SignUpButton extends StatelessWidget {
  const SignUpButton({
    super.key,
    required this.usernameController,
    required this.emailController,
    required this.passController,
  });
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: 555,
        right: 0,
        left: 0,
        child: Center(
          child: Container(
            height: 90,
            width: 90,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                  )
                ]),
            child: GestureDetector(
              onTap: () {
                FirebaseAuthService().signUp(
                  username: usernameController.text,
                  name: usernameController.text,
                  email: emailController.text,
                  password: passController.text,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(30)),
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ));
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.emailControllerIn,
    required this.passControllerIn,
  });

  final TextEditingController emailControllerIn;
  final TextEditingController passControllerIn;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: 555,
        right: 0,
        left: 0,
        child: Center(
          child: Container(
            height: 90,
            width: 90,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                  )
                ]),
            child: GestureDetector(
              onTap: () {
                FirebaseAuthService().signIn(
                  context,
                  email: emailControllerIn.text,
                  password: passControllerIn.text,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(30)),
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ));
  }
}
