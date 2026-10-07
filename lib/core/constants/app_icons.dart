// File: app_icons.dart
// Centralized icon mapping using Iconsax Flutter
// Replace all Material Icons with Iconsax equivalents

import 'package:flutter/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Centralized app icons using Iconsax design system
/// 
/// Usage:
/// ```dart
/// Icon(AppIcons.qrScanner)
/// Icon(AppIcons.check)
/// ```
class AppIcons {
  AppIcons._(); // Private constructor to prevent instantiation

  // Navigation & Actions
  static const IconData arrowBack = Iconsax.arrow_left;
  static const IconData arrowForward = Iconsax.arrow_right;
  static const IconData arrowDown = Iconsax.arrow_down_1;
  static const IconData arrowDropDown = Iconsax.arrow_down_1;
  static const IconData chevronRight = Iconsax.arrow_right_3;
  static const IconData close = Iconsax.close_circle;
  static const IconData unfoldMore = Iconsax.arrow_down;

  // Status & Feedback
  static const IconData check = Iconsax.tick_circle;
  static const IconData checkCircle = Iconsax.tick_circle;
  static const IconData error = Iconsax.danger;
  static const IconData errorOutline = Iconsax.danger;
  static const IconData block = Iconsax.close_circle;

  // Scanner & Camera
  static const IconData qrScanner = Iconsax.scan_barcode;
  static const IconData camera = Iconsax.camera;
  static const IconData noCamera = Iconsax.camera_slash;

  // Auth & Security
  static const IconData logout = Iconsax.logout;
  static const IconData lock = Iconsax.lock;
  static const IconData lockOutline = Iconsax.lock;
  static const IconData visibility = Iconsax.eye;
  static const IconData visibilityOff = Iconsax.eye_slash;

  // User & People
  static const IconData person = Iconsax.user;
  static const IconData personOutline = Iconsax.user;
  static const IconData people = Iconsax.people;
  static const IconData group = Iconsax.people;

  // Location & Building
  static const IconData location = Iconsax.location;
  static const IconData meetingRoom = Iconsax.building;
  static const IconData door = Iconsax.security_safe;
  static const IconData sensorDoor = Iconsax.security_safe;

  // Time & History
  static const IconData clock = Iconsax.clock;
  static const IconData schedule = Iconsax.clock;
  static const IconData accessTime = Iconsax.clock;
  static const IconData history = Iconsax.clock;
  static const IconData historyToggleOff = Iconsax.clock;

  // Dashboard & Categories
  static const IconData dashboard = Iconsax.category;
  static const IconData category = Iconsax.category;

  // Network & Connectivity
  static const IconData wifi = Iconsax.wifi;
  static const IconData wifiOff = Iconsax.wifi_square;

  // Input & Keyboard
  static const IconData keyboard = Iconsax.keyboard;

  // Other
    static const IconData replay = Iconsax.refresh;
    static const IconData refresh = Iconsax.refresh;
    static const IconData searchOff = Iconsax.search_normal_1;
    static const IconData science = Iconsax.mobile;

    // Settings
    static const IconData sun = Iconsax.sun;
    static const IconData moon = Iconsax.moon;
    static const IconData language = Iconsax.global;
  }
