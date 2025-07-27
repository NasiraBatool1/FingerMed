import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  const AnimatedButton({Key? key, required this.onPressed, required this.text}):super(key:key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _widthAnimation = Tween<double>(begin: 200, end: 50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _startAnimation() {
    _controller.forward().then((_) {
      widget.onPressed();
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
      return GestureDetector(
          onTap: _startAnimation,
          child: Container(
          width: _widthAnimation.value,
          height: 50,
          decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(25),
    ),
            alignment: Alignment.center,
            child: _widthAnimation.value > 75
                ? Text(
              widget.text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
      );
      },
        );
  }
}