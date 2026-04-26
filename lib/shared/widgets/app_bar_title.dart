import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle?.trim();
    if (subtitleText == null || subtitleText.isEmpty) {
      return Text(title, overflow: TextOverflow.ellipsis);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, overflow: TextOverflow.ellipsis),
        Text(
          subtitleText,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
