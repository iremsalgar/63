import 'package:cinemate/widgets/navi_bar.dart';
import 'package:flutter/material.dart';

class ForwardButton extends StatelessWidget {
  const ForwardButton({
    super.key,
  });

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
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NaviBar()));
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
