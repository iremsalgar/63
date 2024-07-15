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
            image: NetworkImage(
              "https://variety.com/wp-content/uploads/2023/03/Movie-Theater-Film-Cinema-Exhibition-Placeholder.jpg?w=1000",
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 90, left: 20),
          color: const Color.fromARGB(255, 93, 122, 183).withOpacity(0.85),
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
