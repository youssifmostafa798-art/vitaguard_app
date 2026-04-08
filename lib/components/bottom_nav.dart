import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HomeBottomNav({super.key, required this.currentIndex, this.onTap});

  @override
  State<HomeBottomNav> createState() => _HomeBottomNavState();
}

class _HomeBottomNavState extends State<HomeBottomNav>
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
  void didUpdateWidget(HomeBottomNav oldWidget) {
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
      // 🔽 (تصغير حجم البار من الخارج)
      margin: EdgeInsets.all(14.r), // كان 20.r
      // 🔽 (تصغير ارتفاع البار من الداخل)
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h), // كان 10

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
          _buildAnimatedIconButton(index: 0, icon: Icons.home, label: 'Home'),
          _buildAnimatedIconButton(index: 1, icon: Icons.chat, label: 'Chat'),
          _buildAnimatedIconButton(
            index: 2,
            icon: Icons.health_and_safety,
            label: "Model",
          ),
          _buildAnimatedIconButton(
            index: 3,
            icon: Icons.monitor_heart,
            label: "Device",
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

          // 🔽 (تصغير مساحة الزر)
          padding: EdgeInsets.symmetric(
            vertical: 6.h, // كان 8.h
            horizontal: isSelected ? 12.w : 7.w, // كان 16 / 8
          ),

          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff003F6B).withValues(alpha: 0.1)
                : Colors.transparent,

            // 🔽 (تصغير Radius الزر)
            borderRadius: BorderRadius.circular(25.r), // كان 30
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

                      // 🔽 (تصغير حجم الأيقونة)
                      size: 22.r, // كان 28.r

                      color: isSelected ? const Color(0xff003F6B) : Colors.grey,
                    ),
                  );
                },
              ),

              if (isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,

                  // 🔽 (تصغير المسافة بين الأيقونة والنص)
                  margin: EdgeInsets.only(left: 4.w), // كان 5.w

                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xff003F6B),
                      fontWeight: FontWeight.bold,

                      // 🔽 (تصغير حجم الخط)
                      fontSize: 8.sp, // كان 10.sp
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
