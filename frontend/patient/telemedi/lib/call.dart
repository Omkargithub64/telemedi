import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = "f9baa6f6f8a442e59264c1895147ad90";
const token =
    "007eJxTYMi2nGRRtUjjrtLi+y0LVu49VDtX22VW3Vu3GRMK13MmGKorMBikJJmYWRonGiQaG5lYmphaWCQbmJiYm1iYW5iZG6SZSj5+mt4QyMjwO7CFmZEBAkF8VgZDI2MTUwYGADxBHhI=";
const channel = "12345";

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _micEnabled = true;
  bool _videoEnabled = true;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _toggleMic() {
    setState(() {
      _micEnabled = !_micEnabled;
      _engine.muteLocalAudioStream(!_micEnabled);
    });
  }

  void _toggleVideo() {
    setState(() {
      _videoEnabled = !_videoEnabled;
      _engine.muteLocalVideoStream(!_videoEnabled);
    });
  }

  void _leaveCall() {
    _dispose();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFe6f0fa),
              Color(0xFFf7f9fc),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Video Consultation",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2980b9),
                        letterSpacing: 1.2,
                        shadows: [
                          const Shadow(
                            color: Colors.black12,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.videocam, color: Color(0xFF2980b9)),
                  ],
                ),
              ),

              // Video Streams
              Expanded(
                child: Stack(
                  children: [
                    // Remote Video (Main View)
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _remoteVideo(),
                      ),
                    ),

                    // Local Video (Picture-in-Picture)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _localUserJoined
                              ? AgoraVideoView(
                                  controller: VideoViewController(
                                    rtcEngine: _engine,
                                    canvas: const VideoCanvas(uid: 0),
                                  ),
                                )
                              : const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2980b9)),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: _micEnabled ? Icons.mic : Icons.mic_off,
                      color: const Color(0xFF2ecc71),
                      onPressed: _toggleMic,
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      icon: _videoEnabled ? Icons.videocam : Icons.videocam_off,
                      color: const Color(0xFF3498db),
                      onPressed: _toggleVideo,
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: const Color(0xFFe74c3c),
                      onPressed: _leaveCall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    } else {
      return Container(
        color: const Color(0xFF34495e),
        child: const Center(
          child: Text(
            "Waiting for doctor to join...",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        elevation: 5,
      ),
      child: Icon(
        icon,
        size: 28,
        color: Colors.white,
      ),
    );
  }
}
