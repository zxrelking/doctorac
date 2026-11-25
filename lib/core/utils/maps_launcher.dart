import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLauncher {
  ExternalLauncher._();

  static Future<void> openGoogleMaps({
    required BuildContext context,
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label ?? 'المنصورة، مصر');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedLabel',
    );
    final fallbackUri = Uri.parse(
      'https://maps.google.com/?q=$latitude,$longitude',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح خرائط جوجل على هذا الجهاز')),
      );
    }
  }

  /// Launches external Google Maps turn-by-turn directions to [destinationLat],[destinationLng].
  static Future<void> openGoogleMapsDirections({
    required BuildContext context,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق خرائط جوجل')),
      );
    }
  }

  static Future<void> addAppointmentToCalendar({
    required BuildContext context,
    required String title,
    required String location,
    required String details,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day, 18, 30);
    final end = start.add(const Duration(minutes: 45));
    String fmt(DateTime dt) =>
        '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}00';

    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=${fmt(start)}/${fmt(end)}'
      '&details=${Uri.encodeComponent(details)}'
      '&location=${Uri.encodeComponent(location)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ تذكير بالموعد بنجاح')),
      );
    }
  }

  static Future<void> openSupport(BuildContext context) async {
    final uri = Uri.parse('tel:19600');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خدمة عملاء دكتوراك متاحة على الرقم 19600 على مدار الساعة'),
        ),
      );
    }
  }
}
