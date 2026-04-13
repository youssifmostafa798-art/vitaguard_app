import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Configuration for a navigation item
class NavItemConfig {
  final int index;
  final IconData icon;
  final String label;

  const NavItemConfig({
    required this.index,
    required this.icon,
    required this.label,
  });
}

/// FlexibleNavBar - Flexible Bottom Navigation with visibility control
///
/// Features:
/// - Animated icon scaling on selection
/// - Flexible item visibility (hide specific buttons)
/// - Fully responsive with flutter_screenutil
/// - Clean separation of concerns
class FlexibleNavBar extends StatefulWidget {
  /// Currently selected index
  final int currentIndex;

  /// Callback when a tab is tapped
  final ValueChanged<int>? onTap;

  /// List of indexes to hide (e.g., [3] hides the Device tab)
  /// Empty by default, meaning all items are visible
  /// This provides more intuitive control: you specify what to HIDE
  final List<int> hiddenIndexes;

  const FlexibleNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.hiddenIndexes = const [],
  });

  @override
  State<FlexibleNavBar> createState() => _FlexibleNavBarState();
}

class _FlexibleNavBarState extends State<FlexibleNavBar>
    with SingleTickerProviderStateMixin {
  /// All available navigation items
  /// Modify this list to add/remove/reorder items globally
  static const List<NavItemConfig> _allNavItems = [
    NavItemConfig(index: 0, icon: Icons.home, label: 'Home'),
    NavItemConfig(index: 1, icon: Icons.chat, label: 'Chat'),
    NavItemConfig(index: 2, icon: Icons.health_and_safety, label: 'Model'),
    NavItemConfig(index: 3, icon: Icons.monitor_heart, label: 'Device'),
  ];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticInOut),
    );
  }

  @override
  void didUpdateWidget(FlexibleNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Returns the list of visible items based on hiddenIndexes
  List<NavItemConfig> get _visibleItems {
    return _allNavItems
        .where((item) => !widget.hiddenIndexes.contains(item.index))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer margin for spacing from screen edges
      margin: EdgeInsets.all(14.r),
      // Inner padding for icon/text spacing
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: const Color(0xff003F6B), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),

      // Use _visibleItems to dynamically build only non-hidden buttons
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _visibleItems
            .map(
              (item) => _buildAnimatedNavButton(
                index: item.index,
                icon: item.icon,
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Builds an animated nav button with selection state and scaling animation
  ///
  /// Parameters:
  /// - [index]: The unique index of this navigation item
  /// - [icon]: The Material icon to display
  /// - [label]: The text label shown when selected
  Widget _buildAnimatedNavButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap?.call(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,

          // Adaptive padding based on selection state
          padding: EdgeInsets.symmetric(
            vertical: 6.h,
            horizontal: isSelected ? 12.w : 7.w,
          ),

          decoration: BoxDecoration(
            // Subtle background color when selected
            color: isSelected
                ? const Color(0xff003F6B).withValues(alpha: 0.1)
                : Colors.transparent,

            borderRadius: BorderRadius.circular(25.r),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon with scale effect on selection
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  // Apply scaling animation only when this item is selected and animation is running
                  final scale = (isSelected && _animationController.isAnimating)
                      ? _scaleAnimation.value
                      : 1.0;

                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      icon,
                      size: 22.r,
                      color: isSelected ? const Color(0xff003F6B) : Colors.grey,
                    ),
                  );
                },
              ),

              // Text label - only shown when item is selected
              if (isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(left: 4.w),

                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xff003F6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 8.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
