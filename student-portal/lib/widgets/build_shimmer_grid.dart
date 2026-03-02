import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildShimmerGrid({required bool isMobile}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        6,
        (index) => Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  );
}
