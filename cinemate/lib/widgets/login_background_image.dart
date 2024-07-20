import 'package:flutter/material.dart';

class LoginBackgroundImage extends StatelessWidget {
  const LoginBackgroundImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      left: 0,
      child: Container(
        height: 300,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/image/backgroundPopcorn.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 90, left: 20),
          color: Colors.black.withOpacity(0.70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: "Welcome To ",
                  style: TextStyle(fontSize: 25, color: Colors.amber[700]),
                  children: const [
                    TextSpan(
                      text: "CineMate",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
