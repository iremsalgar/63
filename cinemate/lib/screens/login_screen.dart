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
  final _formKeySignUp = GlobalKey<FormState>();
  final _formKeySignIn = GlobalKey<FormState>();

  final usernameControllerUp = TextEditingController();
  final emailControllerUp = TextEditingController();
  final passControllerUp = TextEditingController();
  final emailControllerIn = TextEditingController();
  final passControllerIn = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    usernameControllerUp.dispose();
    emailControllerUp.dispose();
    passControllerUp.dispose();
    emailControllerIn.dispose();
    passControllerIn.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Sign up successful! You can now log in.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isLoginScreen = true; // Switch to login screen
                });
                // Clear controllers after successful sign-up
                usernameControllerUp.clear();
                emailControllerUp.clear();
                passControllerUp.clear();
              },
            ),
          ],
        );
      },
    );
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
                formKey: _formKeySignUp,
                usernameController: usernameControllerUp,
                emailController: emailControllerUp,
                passController: passControllerUp,
                onSuccess: _showSuccessDialog), // Pass success callback
          if (isLoginScreen)
            LoginButton(
                formKey: _formKeySignIn,
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
              Form(
                key: _formKeySignUp,
                child: Column(
                  children: [
                    CustomTextFieldSignUp(
                      controller: usernameControllerUp,
                      hintText: "Name-Surname:",
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name-Surname cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextFieldSignUp(
                      controller: emailControllerUp,
                      hintText: "E-Mail:",
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-Mail cannot be empty';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                          return 'Enter a valid e-mail address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextFieldSignUp(
                      controller: passControllerUp,
                      hintText: "Password:",
                      prefixIcon: const Icon(
                        Icons.password,
                        color: Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                          return 'Password must contain at least one special character';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            if (isLoginScreen)
              Form(
                key: _formKeySignIn,
                child: Column(
                  children: [
                    CustomTextfield(
                      keyboardType: TextInputType.emailAddress,
                      controller: emailControllerIn,
                      hintText: "E-Mail:",
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-Mail cannot be empty';
                        }
                        return null;
                      },
                    ),
                    CustomTextfield(
                      keyboardType: TextInputType.visiblePassword,
                      controller: passControllerIn,
                      hintText: "Password:",
                      prefixIcon: const Icon(
                        Icons.password,
                        color: Colors.black,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            if (isLoginScreen)
              TextButton(
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 180, bottom: 60)),
                onPressed: () {
                  setState(() {
                    isLoginScreen = false;
                  });
                },
                child: Text(
                  "Don't Have An Account?",
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passController,
    required this.onSuccess,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passController;
  final VoidCallback onSuccess; // Callback

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
            onTap: () async {
              if (formKey.currentState!.validate()) {
                try {
                  bool emailExists = await FirebaseAuthService()
                      .isEmailAlreadyRegistered(emailController.text);
                  bool usernameExists = await FirebaseAuthService()
                      .isUsernameAlreadyRegistered(usernameController.text);

                  if (emailExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                        'E-mail is already registered.',
                        style: TextStyle(color: Colors.black),
                      )),
                    );
                    return;
                  }

                  if (usernameExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Username is already taken.',
                              style: TextStyle(color: Colors.black))),
                    );
                    return;
                  }

                  bool signUpSuccess = await FirebaseAuthService().signUp(
                    username: usernameController.text,
                    email: emailController.text,
                    password: passController.text,
                  );

                  if (signUpSuccess) {
                    onSuccess(); // Call onSuccess callback only if sign up is successful
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Sign up failed: $e',
                            style: const TextStyle(color: Colors.black))),
                  );
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.formKey,
    required this.emailControllerIn,
    required this.passControllerIn,
  });

  final GlobalKey<FormState> formKey;
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
              if (formKey.currentState!.validate()) {
                FirebaseAuthService().signIn(
                  context,
                  email: emailControllerIn.text,
                  password: passControllerIn.text,
                );
                emailControllerIn.clear();
                passControllerIn.clear();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      ),
    );
  }
}
