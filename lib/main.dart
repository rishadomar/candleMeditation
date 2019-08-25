import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _Preferences {
  final String _showProgressText = "showProgress";
  final String _playSoundAtEndText = "playSoundAtEnd";
  final String _playingTimeText = "playingTime";

  // read prefs - if not there set default values
  // be able to write prefs

  /// ------------------------------------------------------------
  /// Method that returns the user decision to allow notifications
  /// ------------------------------------------------------------
  Future<bool> getShowProgress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showProgressText) ?? false;
  }

  Future<bool> getPlaySoundAtEnd() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_playSoundAtEndText) ?? false;
  }

  Future<int> getPlayingTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_playingTimeText) ?? false;
  }

  /// ------------------------------------------------------------
  /// Method that returns the user decision to allow notifications
  /// ------------------------------------------------------------
  Future<bool> setShowProgress(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_showProgressText, value);
  }

  Future<bool> setPlaySoundAtEnd(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_playSoundAtEndText, value);
  }

  Future<bool> setPlayingTime(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_playingTimeText, value);
  }
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController _videoPlayerController;
  Future<void> _initializeVideoPlayerFuture;
  Timer _timer;
  double _percent = 0.0;
  int _playingTime = 5; // minutes
  int _timerInterval = 5;
  bool _showProgress = true;
  bool _playSoundAtEnd = true;
  _Preferences _preferences = new _Preferences();

  Future<void> _loadPreferences() async {
    _showProgress = await _preferences.getShowProgress();
    _playingTime = await _preferences.getPlayingTime();
    _playSoundAtEnd = await _preferences.getPlaySoundAtEnd();
  }

  @override
  void initState() {
    // Create and store the VideoPlayerController. The VideoPlayerController
    // offers several different constructors to play videos from assets, files,
    // or the internet.
    _videoPlayerController = VideoPlayerController.asset(
      'lib/videos/candle.mp4',
    );

    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = _videoPlayerController.initialize();

    // Use the controller to loop the video.
    _videoPlayerController.setLooping(true);

    _loadPreferences();

    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _videoPlayerController.dispose();

    super.dispose();
  }

  void _onTick() {
    double progressValue = _percent + (100 / ((_playingTime * 60) / _timerInterval));
    if (_showProgress) {
      setState(() {
        if (progressValue > 100) {
          _percent = 100;
        } else {
          _percent = progressValue;
        }
      });
    } else {
      if (progressValue > 100) {
        _percent = 100;
      } else {
        _percent = progressValue;
      }
    }
    if (_percent >= 100) {
      _allDone();
    } else {
      _timer = new Timer(new Duration(seconds: _timerInterval), _onTick);
    }
  }

  void _allDone() {
    setState(() {
      _percent = 0.0;
      _timer.cancel();
      _videoPlayerController.pause();
      Screen.keepOn(false);
      if (_playSoundAtEnd) {
        AudioCache player = new AudioCache();
        const alarmAudioPath = "sounds/templeBell.mp3";
        player.play(alarmAudioPath, volume: 0.3);
      }
    });
  }

  void _onShowProgressChange(bool newValue) {
    _showProgress = newValue;
    _preferences.setShowProgress(newValue);
  }

  void _onPlaySoundAtEndChange(bool newValue) {
    _playSoundAtEnd = newValue;
    _preferences.setPlaySoundAtEnd(newValue);
  }

  void _onPlayingTimeChanged(double newValue) {
    int minutes = newValue.round();
    if (_playingTime > 0) {
      _percent = (_percent * newValue) / (_playingTime * 60);
    }
    _preferences.setPlayingTime(minutes);
    setState(() {
      _playingTime = minutes;
    });
  }

  Drawer _makeDrawer() {
    // Add a ListView to the drawer. This ensures the user can scroll
    // through the options in the drawer if there isn't enough vertical
    // space to fit everything.
    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 40.0,
            child: DrawerHeader(
                child: Text('Settings', style: TextStyle(color: Colors.white)),
                decoration: BoxDecoration(color: Colors.blue),
                margin: EdgeInsets.all(5.0),
                padding: EdgeInsets.all(2.0)),
          ),
          Container(
            padding: new EdgeInsets.all(15.0),
            child: new Center(
              child: new Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Icon(Icons.timer),
                      Text('Session Time'),
                      Text((_playingTime).toStringAsFixed(0) + ' minutes')
                    ],
                  ),
                  Slider(
                    activeColor: Colors.indigoAccent,
                    min: 0.0,
                    max: 15.0,
                    onChanged: _onPlayingTimeChanged,
                    value: _playingTime.toDouble(),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Icon(Icons.forward),
                      Text('Show progress?'),
                      Switch(
                        value: _showProgress,
                        onChanged: _onShowProgressChange,
                      )
                    ],
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Icon(Icons.alarm),
                      Text('Play sound at end?'),
                      Switch(
                        value: _playSoundAtEnd,
                        onChanged: _onPlaySoundAtEndChange,
                      )
                    ],
                  ),
                  Divider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      // Use a FutureBuilder to display a loading spinner while waiting for the
      // VideoPlayerController to finish initializing.
      drawer: _makeDrawer(),
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
                  child: VideoPlayer(_videoPlayerController),
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
            if (_videoPlayerController.value.isPlaying) {
              _videoPlayerController.pause();
              Screen.keepOn(false);
              _timer.cancel();
            } else {
              // If the video is paused, play it.
              _videoPlayerController.play();
              Screen.keepOn(true);
              _timer = new Timer(new Duration(seconds: 3), _onTick);
            }
          });
        },
        // Display the correct icon depending on the state of the player.
        child: Icon(
          _videoPlayerController.value.isPlaying
              ? Icons.pause
              : Icons.play_arrow,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
