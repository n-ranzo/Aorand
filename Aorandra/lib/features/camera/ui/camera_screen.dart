// lib/screens/camera/camera_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'preview_screen.dart';

// ================================
// ENUMS
// ================================ 

enum CameraMode { post, story, aoris }
enum FlashType { off, on, auto }

// ================================
// CAMERA SCREEN
// ================================

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  bool isTakingPicture = false;
  // ================================
  // CAMERA VARIABLES
  // ================================

  CameraController? _controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;

  // ================================
  // UI STATE
  // ================================

  bool showTopBar = false;
  bool showModes = false;
  Offset startDrag = Offset.zero;
  bool showPreviewControls = false;
  bool isMultiPicking = false;

  // ================================
  // FLASH & RECORDING
  // ================================

  FlashType flashMode = FlashType.off;
  bool isRecording = false;
  double recordingProgress = 0;
  Timer? recordingTimer;
  double totalProgress = 0;

  // ================================
  // SEGMENTS (MULTI-CLIP)
  // ================================

  List<XFile> recordedSegments = [];
  List<double> segmentProgress = [];
  List<XFile> capturedPostImages = [];

  // ================================
  // MODE & TIMER
  // ================================

  CameraMode currentMode = CameraMode.story;
  double maxVideoSeconds = 30;

  double originalMaxVideoSeconds = 30;
  DateTime? recordingStartTime;

  // TIMER
  int timerSeconds = 0;
  int countdownValue = 0;
  bool isCountingDown = false;
  Timer? countdownTimer;

  // ================================
  // LIFECYCLE
  // ================================

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ================================
  // CAMERA INIT & SWITCH
  // ================================

  Future<void> _initCamera() async {
    cameras = await availableCameras();

    _controller = CameraController(
      cameras![selectedCameraIndex],
      ResolutionPreset.max,
      enableAudio: true,
    );

    await _controller!.initialize();
    setState(() {});
  }

  Future<void> _switchCamera() async {
    selectedCameraIndex = selectedCameraIndex == 0 ? 1 : 0;

    await _controller?.dispose();

    _controller = CameraController(
      cameras![selectedCameraIndex],
      ResolutionPreset.max,
      enableAudio: true,
    );

    await _controller!.initialize();
    setState(() {});
  }
  

  // ================================
  // FLASH CONTROL
  // ================================

  Future<void> _setFlash() async {
  if (flashMode == FlashType.off) {
    flashMode = FlashType.on;
  } else if (flashMode == FlashType.on) {
    flashMode = FlashType.auto;
  } else {
    flashMode = FlashType.off;
  }

  setState(() {});
}

  // ================================
  // PHOTO & VIDEO
  // ================================

Future<void> _takePicture() async {
  if (isTakingPicture) return;

  isTakingPicture = true;

  try {
    // =========================
    // APPLY FLASH BEFORE SHOT
    // =========================
    if (flashMode == FlashType.off) {
      await _controller!.setFlashMode(FlashMode.off);
    } else if (flashMode == FlashType.on) {
      await _controller!.setFlashMode(FlashMode.torch);
    } else {
      await _controller!.setFlashMode(FlashMode.auto);
    }

    // =========================
    // TAKE PHOTO
    // =========================
    final image = await _controller!.takePicture();

    // =========================
    // TURN FLASH OFF AFTER SHOT
    // =========================
    await _controller!.setFlashMode(FlashMode.off);

    // =========================
    // TURM FLASH OFF AFTER SHOT
    // =========================
    
    if (flashMode != FlashType.on) {
      await _controller!.setFlashMode(FlashMode.off);
    }

    // =========================
    // POST MODE = multi photos
    // =========================
    if (currentMode == CameraMode.post) {
      setState(() {
        capturedPostImages.add(image);
        showPreviewControls = true;
      });
    }

    // =========================
    // STORY = direct preview
    // =========================
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            videos: [File(image.path)],
            type: "story",
          ),
        ),
      );
    }
  } catch (e) {
    print("CAMERA ERROR: $e");
  } finally {
    isTakingPicture = false;
  }
}

 Future<void> _startVideo() async {
  if (_controller == null || !_controller!.value.isInitialized) return;

  await _controller!.startVideoRecording();

  // ================================
  // LIMIT BASED ON MODE
  // ================================
  double maxLimit = 30;

  if (currentMode == CameraMode.story) {
    maxLimit = 15;
  } else if (currentMode == CameraMode.aoris) {
    maxLimit = 60;
  }

  // ================================
  // USER VALUE (SLIDER)
  // ================================
  int maxSeconds = maxVideoSeconds.toInt();

  // CLAMP (only if not unlimited)
  if (maxSeconds != 0 && maxSeconds > maxLimit) {
    maxSeconds = maxLimit.toInt();
  }

  // ================================
  // START RECORDING STATE
  // ================================
  setState(() {
    isRecording = true;
    recordingProgress = 0;
    showPreviewControls = false;
  });

  // ================================
  // START TIME
  // ================================
  recordingStartTime = DateTime.now();

  // ================================
  // REAL-TIME TIMER
  // ================================
  recordingTimer =
      Timer.periodic(const Duration(milliseconds: 16), (t) {
    final elapsed = DateTime.now()
        .difference(recordingStartTime!)
        .inMilliseconds;

    double progress;

    // NO LIMIT MODE
    if (maxSeconds == 0) {
      progress = 0; // infinite recording
    } else {
      progress = elapsed / (maxSeconds * 1000);
    }

    setState(() {
      recordingProgress = progress.clamp(0.0, 1.0);
    });

    // AUTO STOP ONLY IF LIMITED
    if (maxSeconds != 0 && recordingProgress >= 1) {
      _stopVideo();
    }
  });
}

  Future<void> _stopVideo() async {
    if (!_controller!.value.isRecordingVideo) return;

    final video = await _controller!.stopVideoRecording();

    recordingTimer?.cancel();

    setState(() {
      isRecording = false;
      segmentProgress.add(recordingProgress);

      totalProgress += recordingProgress;
      if (totalProgress > 1) totalProgress = 1;

      recordingProgress = 0;
      showPreviewControls = true;
    });

    recordedSegments.add(video);
  }

Future<void> _pickFromGallery() async {
  final picker = ImagePicker();

  final XFile? file = await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (file == null) return;

  final path = file.path;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PreviewScreen(
        videos: [File(path)],
        type: currentMode == CameraMode.story
            ? "story"
            : currentMode == CameraMode.aoris
                ? "aoris"
                : "post",
      ),
    ),
  );
}

  // ================================
  // TIMER SHEET
  // ================================

  void _showTimerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Set recording limit",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  Slider(
                    value: maxVideoSeconds,
                    min: 0,
                    max: 60,
                    divisions: 59,
                    onChanged: (value) {
                      setModalState(() {
                        maxVideoSeconds = value;
                      });
                    },
                  ),

                  Text(
                    "${maxVideoSeconds.toInt()}s",
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _timerOption("None", 0, setModalState),
                      _timerOption("3s", 3, setModalState),
                      _timerOption("5s", 5, setModalState),
                      _timerOption("10s", 10, setModalState),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

   // ================================
  // TIMER OPTION WIDGET
  // ================================

  Widget _timerOption(String text, int value, Function setModalState) {
    final isSelected = timerSeconds == value;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          timerSeconds = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  // ================================
  // COUNTDOWN TIMER
  // ================================

  void _startCountdownAndCapture() {
    if (timerSeconds == 0) {
      if (currentMode == CameraMode.aoris) {
        _startVideo();
      } else {
        _takePicture();
      }
      return;
    }

    setState(() {
      countdownValue = timerSeconds;
      isCountingDown = true;
    });

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdownValue > 1) {
        setState(() {
          countdownValue--;
        });
      } else {
        t.cancel();

        setState(() {
          isCountingDown = false;
          countdownValue = 0;
        });

        if (currentMode == CameraMode.aoris) {
          _startVideo();
        } else {
          _takePicture();
        }
      }
    });
  }

  // ================================
  // UI BUILDERS - PREVIEW
  // ================================

 Widget _buildPreview() {
  // ================================
  // CAMERA PREVIEW (FULLSCREEN BASE)
  // ================================
  final preview = SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.previewSize!.height,
        height: _controller!.value.previewSize!.width,
        child: CameraPreview(_controller!),
      ),
    ),
  );

  // ================================
  // POST MODE (4:5 + TOP OFFSET)
  // ================================
  if (currentMode == CameraMode.post) {
    return Stack(
      children: [

        // Blurred background (same preview with opacity)
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: preview,
          ),
        ),

        // Main 4:5 preview (aligned to top like PreviewScreen)
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 100), // 👈 adjust this value if needed
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: preview,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================
  // STORY + AORIS (FULLSCREEN)
  // ================================
  return preview;
}

 // ================================
  // UI BUILDERS - POST COUNTER
  // ================================

Widget _buildPostCounter() {
  if (currentMode != CameraMode.post) {
    return const SizedBox();
  }

  return Positioned(
    bottom: 175,
    right: 35,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          "${capturedPostImages.length + recordedSegments.length}", 
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

  // ================================
  // UI BUILDERS - CAPTURE BUTTON
  // ================================

Widget _buildCapture() {
  return Positioned(
    bottom: 140,
    left: 0,
    right: 0,
    child: Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTapUp: (_) {
          // AORIS (start / stop)
          if (currentMode == CameraMode.aoris) {
            if (isRecording) {
              _stopVideo();
            } else {
              _startCountdownAndCapture();
            }
            return;
          }

          // POST + STORY (photo)
          if (isRecording || isTakingPicture) return;
          _takePicture();
        },

        onLongPressStart: (_) {
          // POST + STORY (video)
          if (currentMode != CameraMode.aoris) {
            if (isRecording || isTakingPicture) return;
            _startVideo();
          }
        },

        onLongPressEnd: (_) {
          if (currentMode != CameraMode.aoris && isRecording) {
            _stopVideo();
          }
        },

        child: Stack(
          alignment: Alignment.center,
          children: [

            // SAME PROGRESS FOR ALL MODES
            CustomPaint(
              size: const Size(110, 110),
              painter: ProgressPainter(
                // AORIS segments / POST & STORY
                segments: segmentProgress,

                // AORIS current progress / POST & STORY = 0
                current: isRecording ? recordingProgress : 0,

                strokeWidth: 7,
                gap: 0.025,
                gapColor: Colors.black,
                currentColor: Colors.white,
                strokeCap: StrokeCap.butt,

                segmentColors: const [
                  Color.fromARGB(255, 31, 1, 5),
                  Color.fromARGB(255, 34, 0, 19),
                  Color.fromARGB(255, 43, 1, 1),
                  Color.fromARGB(255, 46, 1, 31),
                  Color.fromARGB(255, 185, 8, 47),
                  Color.fromARGB(255, 65, 2, 26),
                ],
              ),
            ),

            // OUTER CIRCLE 
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),

            // INNER BUTTON
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: isRecording ? 45 : 70,
              height: isRecording ? 45 : 70,
              decoration: BoxDecoration(
                gradient: isRecording
                    ? const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 31, 1, 5),
                          Color.fromARGB(255, 34, 0, 19),
                          Color.fromARGB(255, 43, 1, 1),
                          Color.fromARGB(255, 46, 1, 31),
                          Color.fromARGB(255, 185, 8, 47),
                          Color.fromARGB(255, 65, 2, 26),
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xfff5f5f5),
                          Color(0xffdcdcdc),
                        ],
                      ),
                borderRadius:
                    BorderRadius.circular(isRecording ? 12 : 50),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  // ================================
  // UI BUILDERS - COUNTDOWN
  // ================================

  Widget _buildCountdownText() {
    if (!isCountingDown) return const SizedBox();

    return Center(
      child: Text(
        "$countdownValue",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 80,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================================
  // UI BUILDERS - TOP CONTROLS
  // ================================

  Widget _buildExitButton() {
    return Positioned(
      top: 50,
      left: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.close, color: Colors.white, size: 28),
      ),
    );
  }

Widget _buildBottomActions() {
  return Positioned(
    bottom: 90,
    left: 0,
    right: 0,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        // ============================
        // UNDO BUTTON
        // ============================
        if (recordedSegments.isNotEmpty ||
            capturedPostImages.isNotEmpty)
          GestureDetector(
            onTap: () {
              setState(() {

                if (recordedSegments.isNotEmpty) {
                  recordedSegments.removeLast();
                  segmentProgress.removeLast();

                  totalProgress = segmentProgress.fold(
                    0.0,
                    (sum, item) => sum + item,
                  );
                } 
                
                else if (capturedPostImages.isNotEmpty) {
                  capturedPostImages.removeLast();
                }

                if (capturedPostImages.isEmpty &&
                    recordedSegments.isEmpty) {
                  showPreviewControls = false;
                }

              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "Undo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),

        // ============================
        // NEXT BUTTON
        // ============================
        if (showPreviewControls)
          GestureDetector(
            onTap: () {

              // 🔥 تحديد النوع الصحيح
              final String type = currentMode == CameraMode.story
                  ? "story"
                  : currentMode == CameraMode.aoris
                      ? "aoris"
                      : "post";

              // ============================
              // MEDIA (POST / STORY / AORIS)
              // ============================
              final media = [
                ...capturedPostImages.map((e) => File(e.path)),
                ...recordedSegments.map((e) => File(e.path)),
              ];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreviewScreen(
                    videos: media,
                    type: type, // 🔥 الحل هون
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
  // ================================
  // UI BUILDERS - MODES
  // ================================

  Widget _buildModes() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: showModes ? 80 : -120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeItem("POST", CameraMode.post),
              const SizedBox(width: 25),
              _modeItem("STORY", CameraMode.story),
              const SizedBox(width: 25),
              _modeItem("AORIS", CameraMode.aoris),
            ],
          ),
        ),
      ),
    );
  }
  
 Widget _buildTopBar() {
  return AnimatedPositioned(
    duration: const Duration(milliseconds: 250),

    top: showTopBar ? 60 : -100,
    right: 20,

    child: Row(
      children: [
        // FLASH
        GestureDetector(
          onTap: _setFlash,
          child: Icon(
            flashMode == FlashType.off
                ? Icons.flash_off
                : flashMode == FlashType.on
                    ? Icons.flash_on
                    : Icons.flash_auto,
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 15),

        // ⏱ TIMER (ONLY FOR AORIS)
        if (currentMode == CameraMode.aoris) ...[
          GestureDetector(
            onTap: _showTimerSheet,
            child: const Icon(Icons.timer, color: Colors.white),
          ),
          const SizedBox(width: 15),
        ],

        // SETTINGS
        const Icon(Icons.settings, color: Colors.white),
      ],
    ),
  );
}

  Widget _modeItem(String text, CameraMode mode) {
  final isActive = currentMode == mode;

  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      setState(() {
        currentMode = mode;
      });
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 👈 المسافة
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white54,
          fontSize: isActive ? 15 : 13,
          fontWeight: FontWeight.w600,
        ),
        child: Text(text),
      ),
    ),
  );
}

  // ================================
  // UI BUILDERS - BOTTOM ICONS
  // ================================

 Widget _buildGallery() {
  return Positioned(
    bottom: 60,
    left: 30,
    child: Row(
      children: [

        // SINGLE PHOTO
        GestureDetector(
          onTap: _pickFromGallery,
          child: const Icon(
            Icons.photo,
            color: Colors.white,
            size: 28,
          ),
        ),

        // MULTIPLE PHOTOS (POST ONLY)
        if (currentMode == CameraMode.post) ...[
          const SizedBox(width: 16),

          GestureDetector(
            onTap: _pickMultipleFromGallery,
            child: const Icon(
              Icons.collections,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ],
    ),
  );
}

Future<void> _pickMultipleFromGallery() async {
  final picker = ImagePicker();

  final List<XFile> files =
      await picker.pickMultiImage();

  if (files.isEmpty) return;

  setState(() {
    capturedPostImages.addAll(files);
    showPreviewControls = true;
  });
}

  Widget _buildFlip() {
    return Positioned(
      bottom: 60,
      right: 30,
      child: GestureDetector(
        onTap: _switchCamera,
        child: const Icon(Icons.flip_camera_ios, color: Colors.white),
      ),
    );
  }

  // ================================
  // MAIN BUILD
  // ================================

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanStart: (details) {
          startDrag = details.localPosition;
        },
        onPanEnd: (details) {
          final velocityY = details.velocity.pixelsPerSecond.dy;

          if (startDrag.dy < 250) {
            if (velocityY > 200) {
              setState(() => showTopBar = true);
            } else if (velocityY < -200) {
              setState(() => showTopBar = false);
            }
          }

          if (startDrag.dy > screenHeight - 300) {
            if (velocityY < -200) {
              setState(() => showModes = true);
            } else if (velocityY > 200) {
              setState(() => showModes = false);
            }
          }
        },
        child: Stack(
          children: [
            _buildPreview(),
            _buildCapture(),
            _buildBottomActions(),
            _buildExitButton(),
            _buildTopBar(),
            _buildModes(),
            _buildGallery(),
            _buildFlip(),
            _buildCountdownText(),
            _buildPostCounter(),
          ],
        ),
      ),
    );
  }
}

// ================================
// PROGRESS PAINTER (SEGMENTED)
// ================================

class ProgressPainter extends CustomPainter {
  final List<double> segments;
  final double current;

  // Customization
  final double strokeWidth;
  final double gap;
  final List<Color> segmentColors;
  final Color currentColor;
  final Color gapColor;
  final StrokeCap strokeCap;

  ProgressPainter({
    required this.segments,
    required this.current,
    this.strokeWidth = 7,
    this.gap = 0.025,
    this.segmentColors = const [
      Colors.pink,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ],
    this.currentColor = Colors.white,
    this.gapColor = Colors.black,
    this.strokeCap = StrokeCap.butt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2,
    );

    double startAngle = -1.57;
    const fullCircle = 6.28318;

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    final gapPaint = Paint()
      ..color = gapColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    // ================================
    // SEGMENTS
    // ================================
    for (double segment in segments) {
      paint.shader = SweepGradient(
        colors: segmentColors,
      ).createShader(rect);

      final sweep = (fullCircle * segment) - gap;

      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        paint,
      );

      // gap
      canvas.drawArc(
        rect,
        startAngle + sweep,
        gap,
        false,
        gapPaint,
      );

      startAngle += fullCircle * segment;
    }

    // ================================
    // CURRENT RECORDING
    // ================================
    if (current > 0) {
      paint.shader = SweepGradient(
        colors: [currentColor, currentColor],
      ).createShader(rect);

      canvas.drawArc(
        rect,
        startAngle,
        fullCircle * current,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SmallProgressPainter extends CustomPainter {
  final double progress;

  SmallProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2,
    );

    final paint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -1.57,
      6.28 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}