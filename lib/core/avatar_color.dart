import 'package:flutter/material.dart';
import 'package:vitaguard_app/models/message_model.dart';

Color getAvatarColor(MessageSender sender) {
  switch (sender) {
    case MessageSender.doctor:
      return const Color(0xFF00A3FF);
    case MessageSender.facility:
      return const Color(0xFF9C27B0);
    case MessageSender.user:
      return Colors.green;
    case MessageSender.patient:
      return const Color(0xFF00A3FF);
    case MessageSender.companion:
      return const Color(0xFF00A3FF);
  }
}



