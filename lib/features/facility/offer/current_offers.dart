import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/features/facility/offer/add_offer.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_bottom.dart';

class _OfferDisplayData {
  const _OfferDisplayData({
    required this.displayName,
    required this.displayDetails,
    required this.discountPercent,
    required this.originalPrice,
  });

  factory _OfferDisplayData.fromResult(Object result) {
    if (result is Map<Object?, Object?>) {
      return _OfferDisplayData(
        displayName: result['displayName']?.toString() ?? '',
        displayDetails: result['displayDetails']?.toString() ?? '',
        discountPercent: _toInt(result['discountPercent']),
        originalPrice: _toInt(result['originalPrice']),
      );
    }

    return _OfferDisplayData(
      displayName: result.toString(),
      displayDetails: "Offer details",
      discountPercent: 0,
      originalPrice: 0,
    );
  }

  final String displayName;
  final String displayDetails;
  final int discountPercent;
  final int originalPrice;

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

const List<_OfferDisplayData> _demoOffers = [
  _OfferDisplayData(
    displayName: "Free Checkup Offer",
    displayDetails: "Get a full checkup for a limited time",
    discountPercent: 50,
    originalPrice: 300,
  ),
  _OfferDisplayData(
    displayName: "Full Vital Analysis",
    displayDetails: "Includes blood pressure, temperature, and pulse report",
    discountPercent: 30,
    originalPrice: 500,
  ),
  _OfferDisplayData(
    displayName: "Home Visit Discount",
    displayDetails: "Special discount for home visit services",
    discountPercent: 20,
    originalPrice: 700,
  ),
];

class CurrentOffers extends StatefulWidget {
  const CurrentOffers({super.key});

  @override
  State<CurrentOffers> createState() => _CurrentOffersState();
}

class _CurrentOffersState extends State<CurrentOffers> {
  final List<_OfferDisplayData> offers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(
        title: "Current Offers",
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AppBackground(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (offers.isEmpty)
                  _buildDemoOffers()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: offers.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return _OfferCard(
                        offer: offer,
                        onDelete: () {
                          setState(() {
                            offers.removeAt(index);
                          });
                        },
                      );
                    },
                  ),

                SizedBox(height: 32.h),

                Button(
                  title: "Create",
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddOffer()),
                    );

                    if (result != null && result.toString().isNotEmpty) {
                      setState(() {
                        offers.add(_OfferDisplayData.fromResult(result));
                      });
                    }
                  },
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoOffers() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _demoOffers.length,
      separatorBuilder: (_, _) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        return _OfferCard(offer: _demoOffers[index]);
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    this.onDelete,
  });

  final _OfferDisplayData offer;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff003F6B);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.12),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  color: primaryColor,
                  size: 25.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.displayName,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      offer.displayDetails,
                      style: TextStyle(
                        color: primaryColor.withValues(alpha: 0.68),
                        fontSize: 13.sp,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Text(
                  "${offer.discountPercent}% OFF",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                SizedBox(width: 6.w),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: primaryColor,
                  ),
                  tooltip: "Remove offer",
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32.w,
                    minHeight: 32.w,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.percent_rounded, color: primaryColor, size: 17.sp),
              SizedBox(width: 6.w),
              Text(
                "Discount: ${offer.discountPercent}%",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.payments_outlined, color: primaryColor, size: 16.sp),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  "Original Price: ${offer.originalPrice}",
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: primaryColor.withValues(alpha: 0.72),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
