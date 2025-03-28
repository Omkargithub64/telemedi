import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:developer';
import 'call.dart';

class Room extends StatefulWidget {
  const Room({super.key});

  @override
  State<Room> createState() => _RoomState();
}

class _RoomState extends State<Room> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: onjoin, child: const Text("Join")),
      ),
    );
  }

  Future<void> onjoin() async {
    await _handelCameraAndMic(Permission.camera);
    await _handelCameraAndMic(Permission.microphone);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoomScreen(),
      ),
    );
  }

  Future<void> _handelCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
  }
}
