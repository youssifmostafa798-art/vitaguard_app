import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/widgets.dart';

class ScreenHelper {
  static init(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }
}
