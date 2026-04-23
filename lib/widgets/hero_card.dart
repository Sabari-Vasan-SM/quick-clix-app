import 'package:flutter/material.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1A122338)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temporary Universal Clipboard',
            style: TextStyle(
              color: Color(0xFFDB4A1F),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Quickclix',
            style: TextStyle(
              color: Color(0xFF122338),
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Share text or files instantly with a one-time 4-digit PIN. Content stays available for 15 minutes and self-destructs after retrieval.',
            style: TextStyle(color: Color(0xFF395069), height: 1.4),
          ),
        ],
      ),
    );
  }
}
