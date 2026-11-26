import 'package:flutter/material.dart';
import 'package:school_log/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  static const style = TextStyle(
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(header: true, child: Text(text, style: style));
  }
}

class SectionCaption extends StatelessWidget {
  const SectionCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        height: 1.4,
        color: AppColors.caption,
      ),
    );
  }
}

class ValueBullet extends StatelessWidget {
  const ValueBullet({
    super.key,
    required this.label,
    required this.value,
    this.fontSize = 15,
  });

  final String label;
  final String value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: EdgeInsets.only(top: fontSize * 0.55, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.4,
                color: AppColors.body,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class BulletLine extends StatelessWidget {
  const BulletLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BodyNote extends StatelessWidget {
  const BodyNote(this.text, {super.key, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppColors.body,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class OutlineChoiceButton extends StatelessWidget {
  const OutlineChoiceButton({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
