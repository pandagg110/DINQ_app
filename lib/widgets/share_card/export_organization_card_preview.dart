import 'package:flutter/material.dart';

import '../../models/organization_share_models.dart';
import 'organization_share_card.dart';

/// 组织分享卡片预览，对齐 Web `ExportCard.tsx` organization 分支。
class ExportOrganizationCardPreview extends StatelessWidget {
  const ExportOrganizationCardPreview({
    super.key,
    required this.org,
    this.height = 315,
  });

  final OrganizationShareTarget org;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 600).clamp(
            0.0,
            constraints.maxHeight / 315,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 600 * scale,
              height: 315 * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 1200,
                  height: 630,
                  child: OrganizationShareCard(org: org),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
