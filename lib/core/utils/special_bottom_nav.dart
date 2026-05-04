import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SpecialBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SpecialBottomNav({super.key, required this.currentIndex, this.onTap});

  @override
  State<SpecialBottomNav> createState() => _SpecialBottomNavState();
}

class _SpecialBottomNavState extends State<SpecialBottomNav>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(SpecialBottomNav oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(14.r),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: const Color(0xff003F6B), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAnimatedIconButton(
            index: 0,
            icon: LucideIcons.home,
            label: 'Chats',
          ),
          _buildAnimatedIconButton(
            index: 1,
            icon: LucideIcons.fileText,
            label: 'Report',
          ),
          _buildAnimatedIconButton(
            index: 2,
            icon: LucideIcons.percent,
            label: "Offer",
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIconButton({
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
          padding: EdgeInsets.symmetric(
            vertical: 8.h,
            horizontal: isSelected ? 12.w : 7.w,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff003F6B).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
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
