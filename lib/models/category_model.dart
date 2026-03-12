import 'package:flutter/material.dart';

class CategoryModel {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  CategoryModel({required this.icon, required this.title, this.onTap});
}



