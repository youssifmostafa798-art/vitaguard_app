import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/patient/models/guidance_video_model.dart';

class GuidanceVideoCard extends StatelessWidget {
  final GuidanceVideoModel video;

  const GuidanceVideoCard({super.key, required this.video});

  Future<void> _openUrl() async {
    final uri = Uri.parse(video.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch ${video.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openUrl,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Image + Play Icon
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand, // مهم جداً
                children: [
                  /// Background Image
                  /// change this photo
                  Positioned.fill(
                    top: 35,
                    child: Image.asset(video.image, fit: BoxFit.cover),
                  ),

                  /// Dark Overlay
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),

                  /// Play Button
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Title (لو موجود)
            if (video.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: CustemText(
                  text: video.title,
                  size: 18,
                  weight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
