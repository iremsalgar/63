import 'package:cinemate/widgets/outlined_button.dart';
import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: MediaQuery.of(context).size.height - 200,
        right: 0,
        left: 0,
        child: Column(
          children: [
            Text(
              "Or Sign-up With",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              color: Colors.amber,
              width: 130,
              height: 2,
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomOutlinedButton(
                      onPressed: () {},
                      icons: Icons.facebook_rounded,
                      text: "Facebook",
                      background: Colors.blue),
                  CustomOutlinedButton(
                      onPressed: () {},
                      icons: Icons.g_mobiledata_rounded,
                      text: "Google",
                      background: Colors.red)
                ],
              ),
            )
          ],
        ));
  }
}
