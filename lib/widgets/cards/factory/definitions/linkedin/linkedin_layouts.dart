import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import 'linkedin_components.dart';

class LinkedInLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/LinkedIn.png', size: 40),
          
          // Bottom Section: Organization Logos
          Align(
            alignment: Alignment.bottomLeft,
            child: LinkedInComponents.buildAvatarGroup(
              careerJourney: careerJourney.take(7).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Timeline
  static Widget build2x4Layout({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/LinkedIn.png', size: 40),
          
          const SizedBox(height: 16),
          
          // Timeline Section
          Expanded(
            child: LinkedInComponents.buildVerticalTimeline(
              careerJourney: careerJourney,
            ),
          ),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal Timeline
  static Widget build4x2Layout({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/LinkedIn.png', size: 40),
          
          // Timeline Section
          SizedBox(
            height: 64,
            child: LinkedInComponents.buildHorizontalTimeline(
              careerJourney: careerJourney,
            ),
          ),
        ],
      ),
    );
  }

  // 4x4 Size - Full with Chart
  static Widget build4x4Layout({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Icon
          const AssetIcon(asset: 'icons/logo/LinkedIn.png', size: 40),
          
          const SizedBox(height: 16),
          
          // Chart Section
          Expanded(
            child: LinkedInComponents.buildCareerChart(
              careerJourney: careerJourney,
            ),
          ),
        ],
      ),
    );
  }
}

