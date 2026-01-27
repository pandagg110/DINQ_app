import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/asset_path.dart';

class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({
    super.key,
    this.isMobile = false,
    this.isSaving = false,
  });

  final bool isMobile;
  final bool isSaving;

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  bool _moreMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Center(
            child: _buildToolbar(),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Button
            _buildIconButton(
              icon: Icons.add,
              onPressed: () {
                // TODO: Handle add card
              },
            ),

            // Link Button
            _buildIconButton(
              icon: Icons.link,
              onPressed: () {
                // TODO: Handle add link
              },
            ),

            // Image/Video Button
            _buildImageButton(),

            _buildDivider(),

            // More Options
            _buildMoreButton(),
          ],
        ),
      ),
    );
  }


  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD3D3D3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Handle add image/video
          },
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SvgPicture.asset(
              assetPath('images/card/image.svg'),
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _moreMenuOpen ? Colors.white.withOpacity(0.15) : Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _moreMenuOpen = !_moreMenuOpen;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                Icons.more_horiz,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // More Menu Dropdown with fade in/out animation
        Positioned(
          bottom: 42,
          left: -59, // Center the 150px menu relative to 32px button: (150-32)/2 = 59
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: _moreMenuOpen
                ? _buildMoreMenu(key: const ValueKey('more_menu'))
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreMenu({Key? key}) {
    return Stack(
      key: key,
      clipBehavior: Clip.none,
      children: [
          Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMoreMenuItem(
                  icon: Icons.refresh,
                  label: 'Regenerate',
                  onTap: () {
                    setState(() => _moreMenuOpen = false);
                    // TODO: Handle regenerate
                  },
                ),
              _buildMoreMenuItem(
                icon: Icons.rotate_right,
                label: 'Update',
                onTap: () {
                  setState(() => _moreMenuOpen = false);
                  // TODO: Handle update
                },
              ),
                _buildMoreMenuItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    setState(() => _moreMenuOpen = false);
                    // TODO: Handle settings
                  },
                ),
              ],
            ),
          ),
          // Arrow indicator
          Positioned(
            bottom: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: 0.785398, // 45 degrees
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: const Color(0xFF171717),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF171717),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.15),
    );
  }
}

