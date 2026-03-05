import 'package:flutter/widgets.dart';

class CustomePainCliper extends StatefulWidget {
  const CustomePainCliper({super.key});

  @override
  State<CustomePainCliper> createState() => _CustomePainCliperState();
}

class _CustomePainCliperState extends State<CustomePainCliper> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipPath(
          clipper: HexagonClipper(),
          child: Image.network(
            "https://picsum.photos/300",
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        )

      ],
    );
  }
}



class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.25, 0);
    path.lineTo(width * 0.75, 0);
    path.lineTo(width, height * 0.5);
    path.lineTo(width * 0.75, height);
    path.lineTo(width * 0.25, height);
    path.lineTo(0, height * 0.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
