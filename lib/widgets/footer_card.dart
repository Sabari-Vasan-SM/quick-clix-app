import 'package:flutter/material.dart';

typedef LinkTapCallback = Future<void> Function(String url);

class FooterCard extends StatelessWidget {
  const FooterCard({
    required this.showContacts,
    required this.onToggleContacts,
    required this.onTapLink,
    super.key,
  });

  final bool showContacts;
  final VoidCallback onToggleContacts;
  final LinkTapCallback onTapLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A122338)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  'https://avatars.githubusercontent.com/u/144119741?v=4',
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Designed and developed by Sabarivasan',
                  style: TextStyle(
                    color: Color(0xFF395069),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEAF3FA),
              foregroundColor: const Color(0xFF122338),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: onToggleContacts,
            child: Text(
              showContacts ? 'Hide Developer Contact' : 'Developer Contact',
            ),
          ),
          if (showContacts) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _linkChip('Portfolio', () {
                  onTapLink('https://portfolio.vasan.tech/');
                }),
                _linkChip('LinkedIn', () {
                  onTapLink(
                    'https://www.linkedin.com/in/sabarivasan-s-m-b10229255/',
                  );
                }),
                _linkChip('GitHub', () {
                  onTapLink('https://github.com/Sabari-Vasan-SM');
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _linkChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFBFD8EA)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      avatar: const Icon(Icons.open_in_new, size: 16, color: Color(0xFFFF6B3D)),
    );
  }
}
