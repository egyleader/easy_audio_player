// lib/src/widgets/components/waveform_widget.dart
//
// NOTE: This widget uses the just_waveform package which only supports
// Android, iOS, and macOS. On web, Linux, and Windows the [showWaveform]
// parameter on ExpandedPlayer is silently ignored and this widget is
// never rendered. This is by design — see platform requirements in the
// package README.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

import '../../models/audio_player_theme.dart';
import '../../models/audio_track.dart';

/// Returns true if the current platform supports just_waveform.
bool get isWaveformSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

class WaveformWidget extends StatefulWidget {
  final AudioTrack? track;
  final AudioPlayerTheme theme;

  const WaveformWidget({super.key, required this.track, required this.theme});

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  Stream<WaveformProgress>? _waveformStream;
  String? _lastTrackId;

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.track?.id != _lastTrackId) {
      _loadWaveform(widget.track);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWaveform(widget.track);
  }

  void _loadWaveform(AudioTrack? track) {
    if (track == null) {
      setState(() { _waveformStream = null; _lastTrackId = null; });
      return;
    }
    _lastTrackId = track.id;

    // Only supports local files — network tracks not supported by just_waveform
    if (track.sourceType != TrackSourceType.file) {
      setState(() { _waveformStream = null; });
      return;
    }

    final audioFile = track.file!;

    setState(() {
      _waveformStream = JustWaveform.extract(
        audioInFile: audioFile,
        waveOutFile: File('${audioFile.path}.wave'),
        zoom: const WaveformZoom.pixelsPerSecond(100),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_waveformStream == null) {
      return LinearProgressIndicator(color: widget.theme.waveformColor);
    }
    return StreamBuilder<WaveformProgress>(
      stream: _waveformStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.waveform == null) {
          return LinearProgressIndicator(
            value: snapshot.data?.progress,
            color: widget.theme.waveformColor,
          );
        }
        return _WaveformPainter(
          waveform: snapshot.data!.waveform!,
          color: widget.theme.waveformColor ?? Colors.blue,
        );
      },
    );
  }
}

class _WaveformPainter extends StatelessWidget {
  final Waveform waveform;
  final Color color;

  const _WaveformPainter({required this.waveform, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformCustomPainter(waveform: waveform, color: color),
      child: const SizedBox(height: 80, width: double.infinity),
    );
  }
}

class _WaveformCustomPainter extends CustomPainter {
  final Waveform waveform;
  final Color color;

  _WaveformCustomPainter({required this.waveform, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final step = size.width / waveform.length;
    for (int i = 0; i < waveform.length; i++) {
      final x = i * step;
      final amplitude = waveform.getPixelMax(i) / 32768.0;
      final barHeight = amplitude * size.height;
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformCustomPainter oldDelegate) =>
      waveform != oldDelegate.waveform;
}
