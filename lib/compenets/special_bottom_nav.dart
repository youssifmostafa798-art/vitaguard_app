import 'package:flutter/material.dart';

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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
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
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(45),
        border: Border.all(color: const Color(0xff003F6B), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home with animation
          _buildAnimatedIconButton(index: 0, icon: Icons.home, label: 'Chats'),

          // Chat with animation
          _buildAnimatedIconButton(
            index: 1,
            icon: Icons.fact_check,
            label: 'Report',
          ),

          // Model with animation
          _buildAnimatedIconButton(
            index: 2,
            icon: Icons.discount_outlined,
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
            vertical: 8,
            horizontal: isSelected ? 16 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff003F6B).withValues(
                    alpha: 0.1,
                  ) // تم التعديل هنا
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  double scale =
                      (isSelected && _animationController.isAnimating)
                      ? _scaleAnimation.value
                      : 1.0;

                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      icon,
                      size: 26,
                      color: isSelected ? const Color(0xff003F6B) : Colors.grey,
                    ),
                  );
                },
              ),

              // Animated Label
              if (isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(left: 5),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xff003F6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
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
