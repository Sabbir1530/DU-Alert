import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';

class MediaViewer extends StatelessWidget {
  final List<Map<String, dynamic>> media;

  const MediaViewer({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    if (media.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _MediaTile(item: media.first),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: media.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, index) => SizedBox(
            width: 280,
            child: _MediaTile(item: media[index]),
          ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _MediaTile({required this.item});

  String _mediaUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    final base = AppConstants.serverOrigin.endsWith('/')
        ? AppConstants.serverOrigin.substring(
            0,
            AppConstants.serverOrigin.length - 1,
          )
        : AppConstants.serverOrigin;
    final path = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
    return '$base$path';
  }

  String _detectType(String pathOrType) {
    final value = pathOrType.toLowerCase();

    if (['image', 'video', 'pdf', 'file'].contains(value)) {
      return value;
    }

    if (
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.png') ||
        value.endsWith('.gif') ||
        value.endsWith('.webp') ||
        value.endsWith('.heic') ||
        value.endsWith('.heif')) {
      return 'image';
    }
    if (
        value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.webm') ||
        value.endsWith('.m4v')) {
      return 'video';
    }
    if (value.endsWith('.pdf')) return 'pdf';
    return 'file';
  }

  Future<void> _openExternal(BuildContext context, String fileUrl) async {
    final uri = Uri.tryParse(_mediaUrl(fileUrl));
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = item['file_url']?.toString() ?? item['url']?.toString() ?? '';
    final absoluteUrl = _mediaUrl(fileUrl);
    final type = _detectType(
      item['file_type']?.toString() ?? item['type']?.toString() ?? fileUrl,
    );

    if (type == 'image') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _ImageFullscreenScreen(imageUrl: absoluteUrl),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            absoluteUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      );
    }

    IconData icon;
    String label;
    if (type == 'video') {
      icon = Icons.play_circle_outline;
      label = 'Video';
    } else if (type == 'pdf') {
      icon = Icons.picture_as_pdf_outlined;
      label = 'PDF';
    } else {
      icon = Icons.insert_drive_file_outlined;
      label = 'File';
    }

    return InkWell(
      onTap: () => _openExternal(context, fileUrl),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                fileUrl.split('/').last,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap to open',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFullscreenScreen extends StatelessWidget {
  final String imageUrl;

  const _ImageFullscreenScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
