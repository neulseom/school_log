import 'package:flutter/material.dart';
import 'package:school_log/theme/app_theme.dart';

class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, this.width = 232});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.46,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink, width: 4),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '스쿨로그',
              style: TextStyle(
                fontFamily: 'BlackHanSans',
                fontSize: 54,
                height: 1,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
