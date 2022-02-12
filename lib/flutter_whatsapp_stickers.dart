// Copyright 2021 Vince Kruger. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_whatsapp_stickers/constants.dart';

/// Implementation of the WhatsApp Stickers API for Flutter.
class WhatsAppStickers {
  static const MethodChannel _channel = const MethodChannel(channelName);
  MessageHandler? _addStickerPackListener;

  /// Get the platform version
  static Future<String> get platformVersion async =>
      await _channel.invokeMethod(platform);

  /// Check if WhatsApp is installed
  /// This will check both the comsumer and business packages
  static Future<bool> get isWhatsAppInstalled async =>
      await _channel.invokeMethod(isWhatsApp);

  /// Check if the WhatsApp consumer package is installed
  static Future<bool> get isWhatsAppConsumerAppInstalled async =>
      await _channel.invokeMethod(isWhatsAppConsumer);

  /// Check if the WhatsApp business package is installed
  static Future<bool> get isWhatsAppSmbAppInstalled async =>
      await _channel.invokeMethod(isWhatsAppBusiness);

  /// Launch WhatsApp
  static void launchWhatsApp() {
    _channel.invokeMethod(launchApp);
  }

  /// Check if a sticker pack is installed on WhatsApp
  ///
  /// [stickerPackIdentifier] The sticker pack identifier
  Future<bool> isStickerPackInstalled(
      final String stickerPackIdentifier) async {
    return await _channel.invokeMethod(
        "isStickerPackInstalled", {"identifier": stickerPackIdentifier});
  }

  /// Updated sticker packs
  ///
  /// [stickerPackIdentifier] The sticker pack identider
  void updatedStickerPacks(String stickerPackIdentifier) {
    _channel.invokeMethod("updatedStickerPackContentsFile",
        {"identifier": stickerPackIdentifier});
  }

  /// Add a sticker pack to whatsapp.
  ///
  /// [packageName] The WhatsApp package name.
  /// [stickerPackIdentifier] The sticker pack identider
  /// [stickerPackName] The sticker pack name
  /// [listener] Sets up [MessageHandler] function for incoming events.
  void addStickerPack({
    required String stickerPackIdentifier,
    required String stickerPackName,
    WhatsAppPackage packageName = WhatsAppPackage.Consumer,
    MessageHandler? listener,
  }) {
    String packageString = consumerWhatsAppPackageName;
    if (packageName == WhatsAppPackage.Business) {
      packageString = businessWhatsAppPackageName;
    }

    _addStickerPackListener = listener;
    _channel.setMethodCallHandler(_handleMethod);
    _channel.invokeMethod(addPack, {
      "package": packageString,
      "identifier": stickerPackIdentifier,
      "name": stickerPackName,
    });
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onSuccess":
        String action = call.arguments['action'];
        bool result = call.arguments['result'];
        switch (action) {
          case 'success':
            _addStickerPackListener!(StickerPackResult.SUCCESS, result);
            break;
          case 'add_successful':
            _addStickerPackListener!(StickerPackResult.ADD_SUCCESSFUL, result);
            break;
          case 'already_added':
            _addStickerPackListener!(StickerPackResult.ALREADY_ADDED, result);
            break;
          case 'cancelled':
            _addStickerPackListener!(StickerPackResult.CANCELLED, result);
            break;
          default:
            _addStickerPackListener!(StickerPackResult.UNKNOWN, result);
        }
        return null;
      case "onError":
        bool result = call.arguments['result'];
        String error = call.arguments['error'] ?? null;
        _addStickerPackListener!(StickerPackResult.ERROR, result, error: error);
        return null;
      default:
        throw UnsupportedError("Unrecognized activity handler");
    }
  }
}

typedef Future<void> MessageHandler(final StickerPackResult action, bool status,
    {String? error});

enum StickerPackResult {
  SUCCESS,
  ADD_SUCCESSFUL,
  ALREADY_ADDED,
  CANCELLED,
  ERROR,
  UNKNOWN,
}

enum WhatsAppPackage {
  Consumer,
  Business,
}
