import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:video_player/video_player.dart';

class VideoEditorScreen extends StatefulWidget {
  final File video;
  const VideoEditorScreen({super.key, required this.video});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  late VideoPlayerController _controller;
  late Duration _videoDuration;
  late Duration _currentPosition;
  late RangeValues _trimValues;

  bool _isPlaying = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = Duration.zero;
    _controller = VideoPlayerController.file(widget.video)
      ..initialize().then((_) {
        setState(() {
          _videoDuration = _controller.value.duration;
          _trimValues = RangeValues(0, _videoDuration.inMilliseconds.toDouble());
        });
      });

    _controller.addListener(() {
      setState(() {
        _currentPosition = _controller.value.position;
      });
      if (_controller.value.position >= Duration(milliseconds: _trimValues.end.toInt())) {
        _controller.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        if (_controller.value.position >= Duration(milliseconds: _trimValues.end.toInt())) {
          _controller.seekTo(Duration(milliseconds: _trimValues.start.toInt()));
        }
        _controller.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _exportVideo() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final editor = VideoEditorBuilder(videoPath: widget.video.path);
      final outputPath = await editor.trim(
        startTimeMs: _trimValues.start.toInt(),
        endTimeMs: _trimValues.end.toInt(),
      ).export(onProgress: (progress) {
        // You can use this to show a progress bar
      });

      if (mounted && outputPath != null) {
        Navigator.of(context).pop(File(outputPath));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error exporting video: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isExporting ? null : _exportVideo,
          ),
        ],
      ),
      body: _controller.value.isInitialized
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 70,
                            color: Colors.white.withOpacity(_isPlaying ? 0.7 : 1),
                          ),
                          onPressed: _togglePlayPause,
                        )
                      ],
                    ),
                  ),
                ),
                if (_isExporting)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text("Exporting... please wait."),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Slider(
                        value: _currentPosition.inMilliseconds.toDouble().clamp(0.0, _videoDuration.inMilliseconds.toDouble()),
                        min: 0,
                        max: _videoDuration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _controller.seekTo(Duration(milliseconds: value.toInt()));
                        },
                      ),
                      RangeSlider(
                        values: _trimValues,
                        min: 0,
                        max: _videoDuration.inMilliseconds.toDouble(),
                        onChanged: (values) {
                          setState(() {
                            _trimValues = values;
                          });
                          _controller.seekTo(Duration(milliseconds: values.start.toInt()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(Duration(milliseconds: _trimValues.start.toInt()))),
                          Text(_formatDuration(Duration(milliseconds: _trimValues.end.toInt()))),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
}
