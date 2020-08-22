/*
 * Copyright 2020 Nimrod Dayan nimroddayan.com
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 *
 */

import 'dart:async';

import 'package:flutter/services.dart';

/// Singleton API for managing Network Service Discovery
///
/// Get the singleton by calling FlutterNsd() and listen to its [stream] for [NsdServiceInfo] emissions.
/// Then invoke [discoverServices] to start service discovery.
/// Stop discovery by calling [stopDiscovery] when you're done.
///
class FlutterNsd {
  static const MethodChannel _channel = const MethodChannel('com.nimroddayan/flutter_nsd');
  static final FlutterNsd _instance = FlutterNsd._internal();

  final _streamController = StreamController<NsdServiceInfo>();

  /// Factory for getting [FlutterNsd] singleton object
  factory FlutterNsd() {
    return _instance;
  }

  FlutterNsd._internal();

  /// Stream that emits a [NsdServiceInfo] for each service discovered or a [NsdError] in case of an error.
  Stream<NsdServiceInfo> get stream => _streamController.stream;

  /// Start network service discovery for [serviceType] for an infinite amount
  /// of time (or until the app process is killed). Make sure to call [stopDiscovery] when you're done.
  Future<void> discoverServices(String serviceType) async {
    await _channel.invokeMethod('startDiscovery', {'serviceType': '$serviceType'});

    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'onStartDiscoveryFailed':
          _streamController.addError(NsdException());
          break;
        case 'onStopDiscoveryFailed':
          _streamController.addError(NsdException());
          break;
        case 'onResolveFailed':
          _streamController.addError(NsdException());
          break;
        case 'onDiscoveryStopped':
          _channel.setMethodCallHandler(null);
          break;
        case 'onServiceResolved':
          final String ip = call.arguments['hostname'];
          final int port = call.arguments['port'];
          final String name = call.arguments['name'];
          _streamController.add(NsdServiceInfo(ip, port, name));
          break;
        default:
          _streamController.addError(UnsupportedError('Method ${call.method} is unsupported'));
      }
      return null;
    });
  }

  /// Stop network service discovery
  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopDiscovery');
  }
}

/// Info class for holding discovered service
class NsdServiceInfo {
  final String hostname;
  final int port;
  final String name;

  NsdServiceInfo(this.hostname, this.port, this.name);
}

// Generic error thrown when an error has occurred during discovery
class NsdException extends Error {
}
