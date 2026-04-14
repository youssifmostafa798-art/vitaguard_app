import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSearch extends StatefulWidget {
  final ValueChanged<String>? onChanged;

  const HomeSearch({super.key, this.onChanged});

  @override
  State<HomeSearch> createState() => _HomeSearchState();
}

class _HomeSearchState extends State<HomeSearch> {
  // TextEditingController to manage search input state and enable clearing
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Initialize controller for search field
    _searchController = TextEditingController();
    // Listen to changes and trigger callback for real-time filtering
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Cleanup resources to prevent memory leaks
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Callback to notify parent widget of search changes (instant filtering)
  void _onSearchChanged() {
    widget.onChanged?.call(_searchController.text);
  }

  // Public method to clear search from parent widget if needed
  void clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xff003F6B)),
        color: Colors.white,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: Icon(Icons.search, size: 22.r),
          hintText: "Search",
          border: InputBorder.none,
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
