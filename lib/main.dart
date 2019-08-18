import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:screen/screen.dart';

void main() => runApp(VideoPlayerApp());

class VideoPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candle',
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerScreen({Key key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;
  Timer _timer;
  Timer _finalTimer;
  double _percent = 0.0;
  int _totalTimeInSeconds = 120;
  int _timerInterval = 5;

  @override
  void initState() {
    // Create and store the VideoPlayerController. The VideoPlayerController
    // offers several different constructors to play videos from assets, files,
    // or the internet.
    _controller = VideoPlayerController.asset(
      'lib/videos/candle.mp4',
    );

    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = _controller.initialize();

    // Use the controller to loop the video.
    _controller.setLooping(true);

    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();

    super.dispose();
  }

  void _onTick() {
    setState(() {
     _percent = _percent + (100 / (_totalTimeInSeconds / _timerInterval));
     if (_percent > 100) {
       _percent = 100;
     }
     _timer = new Timer(new Duration(seconds: _timerInterval), _onTick);
    });
  }

  void _onFinalTimeComplete() {
    setState(() {
      _percent = 1.0;
      _timer.cancel();
      _controller.pause();
      AudioCache player = new AudioCache();
      const alarmAudioPath = "sounds/templeBell.mp3";
      player.play(alarmAudioPath, volume: 0.3);
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      // Use a FutureBuilder to display a loading spinner while waiting for the
      // VideoPlayerController to finish initializing.
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
            return Column(
                // Use the VideoPlayer widget to display the video.
                children: [
                  Expanded(
                    child: VideoPlayer(_controller),
                  ),
                  LinearProgressIndicator(
                    value: _percent * .01,
                  ),
                ],
            );
            //return VideoPlayer(_controller);
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Wrap the play or pause in a call to `setState`. This ensures the
          // correct icon is shown.
          setState(() {
            // If the video is playing, pause it.
            if (_controller.value.isPlaying) {
              _controller.pause();
              Screen.keepOn(false);
              _timer.cancel();
            } else {
              // If the video is paused, play it.
              _controller.play();
              Screen.keepOn(true);
              _timer = new Timer(new Duration(seconds: 3), _onTick);
              if (_finalTimer == null) {
                _finalTimer = new Timer(new Duration(seconds: _totalTimeInSeconds), _onFinalTimeComplete);
              }
            }
          });
        },
        // Display the correct icon depending on the state of the player.
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

