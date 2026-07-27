import 'package:flutter/material.dart';
import 'package:ppn_great/core/locale/locale_provider.dart';

/// ปุ่มสลับภาษา TH / EN ดีไซน์สวยงามระดับพรีเมียม
class LanguageSwitchButton extends StatelessWidget {
  final bool isCompact;

  const LanguageSwitchButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeProvider,
      builder: (context, child) {
        final isThai = localeProvider.isThai;

        return InkWell(
          onTap: () => localeProvider.toggleLocale(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: isCompact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLangBadge("TH", isThai),
                const SizedBox(width: 4),
                _buildLangBadge("EN", !isThai),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangBadge(String lang, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lang,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
