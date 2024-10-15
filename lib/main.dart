// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, empty_catches

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyMusicPlayerApp());
}

class MyMusicPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF260120),
        hintColor: Color(0xFF3F0140),
        scaffoldBackgroundColor: Color(0xFFF2EFDC),
      ),
      home: MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<FileSystemEntity>? _songs;
  int _currentIndex = 0;
  String? _currentSongUri;
  bool _isRepeatEnabled = false;
  Duration? _currentSongDuration;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchSongs();

    // Listen for playback position updates
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen for playback completion
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        if (_isRepeatEnabled) {
          _playSong(_currentSongUri!);
        } else {
          _playNext();
        }
      }
      setState(() {});
    });
  }

  Future<void> _fetchSongs() async {
    var status = await Permission.storage.request();

    if (status.isGranted) {
      List<FileSystemEntity> allFiles = [];
      Directory rootDir = Directory('/storage/emulated/0/');
      allFiles = await _getAllMp3Files(rootDir);

      setState(() {
        _songs = allFiles;
        if (_songs!.isNotEmpty) {
          _playSong(_songs![_currentIndex].path);
        } else {}
      });
    } else {}
  }

  Future<List<FileSystemEntity>> _getAllMp3Files(Directory dir) async {
    List<FileSystemEntity> audioFiles = [];
    try {
      List<FileSystemEntity> files = dir.listSync();
      for (FileSystemEntity file in files) {
        if (file is Directory) {
          audioFiles.addAll(await _getAllMp3Files(file));
        } else if (file.path.endsWith('.mp3')) {
          audioFiles.add(file);
        }
      }
    } catch (e) {}
    return audioFiles;
  }

  void _playSong(String url) async {
    await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
    _currentSongUri = url;

    // Retrieve the duration
    final duration = _audioPlayer.duration;
    setState(() {
      _currentSongDuration = duration;
    });

    _audioPlayer.play();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _playNext() {
    if (_isRepeatEnabled) {
      _playSong(_songs![_currentIndex].path);
    } else {
      // Proceed to the next song if not at the end of the list
      if (_songs != null && _currentIndex < _songs!.length - 1) {
        _currentIndex++;
        _playSong(_songs![_currentIndex].path);
      } else {
        // Optionally, reset to the first song if at the end
        _currentIndex = 0;
        _playSong(_songs![_currentIndex].path);
      }
    }
  }

  void _playPrevious() {
    if (_songs != null && _currentIndex > 0) {
      _currentIndex--;
      _playSong(_songs![_currentIndex].path);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFBF7315),
              Color(0xFF804E11),
              Color(0xFF3F0140),
              Color(0xFF0B0109),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: Color(0xFFBF7315),
                borderRadius: BorderRadius.circular(150),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    spreadRadius: 10,
                    blurRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _songs != null && _songs!.isNotEmpty
                      ? _songs![_currentIndex].uri.pathSegments.last
                      : 'No Song Selected',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center, // Center the text
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _songs != null && _songs!.isNotEmpty
                    ? _songs![_currentIndex].path.split('/').last
                    : 'Unknown Artist',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Slider(
                    value: _currentPosition.inSeconds.toDouble(),
                    min: 0.0,
                    max: _currentSongDuration?.inSeconds.toDouble() ?? 0.0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                    onChanged: (value) {
                      setState(() {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _currentSongDuration != null
                              ? _formatDuration(_currentSongDuration!)
                              : '00:00',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isRepeatEnabled ? Icons.repeat_one : Icons.repeat,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isRepeatEnabled =
                          !_isRepeatEnabled; // Toggle repeat state
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: _playPrevious,
                ),
                IconButton(
                  iconSize: 100,
                  icon: Icon(
                    _audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_audioPlayer.playing) {
                        _audioPlayer.pause();
                      } else {
                        if (_songs != null && _songs!.isNotEmpty) {
                          if (_currentSongUri == _songs![_currentIndex].path) {
                            _audioPlayer.play();
                          } else {
                            _playSong(_songs![_currentIndex].path);
                          }
                        }
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: Colors.white),
                  onPressed: _playNext,
                ),
                IconButton(
                  icon: Icon(Icons.list, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongListScreen(
                          songs: _songs,
                          currentIndex: _currentIndex,
                          onSongTap: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _playSong(_songs![index].path);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Slider(
                value: _audioPlayer.volume,
                activeColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _audioPlayer.setVolume(value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SongListScreen extends StatelessWidget {
  final List<FileSystemEntity>? songs;
  final Function(int) onSongTap;
  final int currentIndex;

  const SongListScreen({
    required this.songs,
    required this.onSongTap,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Song List',
          style:
              TextStyle(color: Colors.white), // Set title text color to white
        ),
        backgroundColor: Color(0xFF3F0140),
        iconTheme: IconThemeData(
            color: Colors.white), // Set back button color to white
      ),
      body: ListView.builder(
        itemCount: songs?.length ?? 0,
        itemBuilder: (context, index) {
          final song = songs![index];
          return ListTile(
            title: Text(
              song.path.split('/').last,
              style: TextStyle(
                color: index == currentIndex ? Color(0xFFBF7315) : Colors.black,
                fontWeight:
                    index == currentIndex ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            tileColor: index == currentIndex ? Color(0xFFEDE3C8) : null,
            onTap: () {
              onSongTap(index);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
