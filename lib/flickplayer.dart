import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late FlickManager flickManager;
  final String videoPositionKey = 'video_position';

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.networkUrl(
        Uri.parse(
            'https://firebasestorage.googleapis.com/v0/b/firestore-b93ae.appspot.com/o/01%20Timing%20_%20The%20Motion%20Magic.mp4?alt=media&token=353052a5-c073-4e55-b65d-86d130af2be1'),
      ),
    );
    _loadVideoPosition();
  }

  @override
  void dispose() {
    _saveVideoPosition();
    flickManager.dispose();
    super.dispose();
  }

  void _loadVideoPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedPosition = prefs.getInt(videoPositionKey);

    if (savedPosition != null) {
      // Delay seeking until the video is initialized
      flickManager.flickVideoManager!.videoPlayerController!.addListener(() {
        if (flickManager
            .flickVideoManager!.videoPlayerController!.value.isInitialized) {
          flickManager.flickControlManager!
              .seekTo(Duration(seconds: savedPosition));
        }
      });
    }
  }

  void _saveVideoPosition() async {
    final position =
        flickManager.flickVideoManager!.videoPlayerController!.value.position;
    int positionInSeconds = position.inSeconds;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(videoPositionKey, positionInSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Video Example'),
      ),
      body: Center(
        child: SizedBox(
          height: 200,
          width: 360,
          child: FlickVideoPlayer(
            flickManager: flickManager,
            flickVideoWithControls: FlickVideoWithControls(
              controls: CustomFlickControls(flickManager: flickManager),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomFlickControls extends StatefulWidget {
  final FlickManager flickManager;

  const CustomFlickControls({super.key, required this.flickManager});

  @override
  // ignore: library_private_types_in_public_api
  _CustomFlickControlsState createState() => _CustomFlickControlsState();
}

class _CustomFlickControlsState extends State<CustomFlickControls> {
  late FlickManager flickManager;
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    flickManager = widget.flickManager;
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  // void _startHideControlsTimer() {
  //   _hideControlsTimer?.cancel();
  //   _hideControlsTimer = Timer(Duration(seconds: 3), () {
  //     setState(() {
  //       _controlsVisible = false;
  //     });
  //   });
  // }

  void _toggleControlsVisibility() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    // if (_controlsVisible) {
    //   _startHideControlsTimer();
    // } else {
    //   _hideControlsTimer?.cancel();
    // }
  }

  @override
  Widget build(BuildContext context) {
    VideoPlayerValue videoPlayerValue =
        flickManager.flickVideoManager!.videoPlayerController!.value;

    return GestureDetector(
      onTap: () {
        _toggleControlsVisibility();
      },
      onDoubleTap: () {
        flickManager.flickControlManager!.togglePlay();
        _toggleControlsVisibility();
      },
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FlickFullScreenToggle(
                    color: Colors.white,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Duration currentPosition = videoPlayerValue.position;
                      flickManager.flickControlManager!.seekTo(
                        Duration(seconds: currentPosition.inSeconds - 10),
                      );
                      _toggleControlsVisibility();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      videoPlayerValue.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      flickManager.flickControlManager!.togglePlay();
                      _toggleControlsVisibility();
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Duration currentPosition = videoPlayerValue.position;
                      flickManager.flickControlManager!.seekTo(
                        Duration(seconds: currentPosition.inSeconds + 10),
                      );
                      _toggleControlsVisibility();
                    },
                  ),
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FlickCurrentPosition(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  FlickTotalDuration(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ],
              ),
              FlickVideoProgressBar(
                flickProgressBarSettings: FlickProgressBarSettings(
                  height: 5,
                  handleRadius: 5,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white38,
                  playedColor: const Color.fromARGB(255, 240, 80, 80),
                  handleColor: const Color.fromARGB(255, 240, 80, 80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
