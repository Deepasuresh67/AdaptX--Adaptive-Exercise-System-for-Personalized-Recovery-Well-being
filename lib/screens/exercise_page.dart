import 'dart:async';
import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'exercise_completion_screen.dart';
import '../models/exercise.dart';
import '../models/exercise_progress.dart';
import '../services/progress_service.dart';
import 'package:uuid/uuid.dart';
import 'exercise_video_preview_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/audio_countdown_timer.dart';

class ExercisePage extends StatefulWidget {
  final String userId;
  final String mood;
  final String exerciseType;
  final String healthCondition;

  const ExercisePage({
    super.key,
    required this.userId,
    required this.mood,
    required this.exerciseType,
    required this.healthCondition,
  });

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class ExerciseSession {
  final DateTime date;
  final int duration;
  final String category;

  ExerciseSession({
    required this.date,
    required this.duration,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'duration': duration,
        'category': category,
      };

  factory ExerciseSession.fromMap(Map<String, dynamic> map) => ExerciseSession(
        date: DateTime.parse(map['date']),
        duration: map['duration'],
        category: map['category'],
      );
}

class _ExercisePageState extends State<ExercisePage> {
  final CountDownController _controller = CountDownController();
  Timer? _totalTimer;
  List<ExerciseSession> _history = [];
  int _currentExerciseIndex = 0;
  bool _isStarted = false;
  bool _isBreakTime = false;
  int _totalExerciseTime = 0;
  int _totalBreakTime = 0;
  bool _isCompleted = false;
  final ProgressService _progressService = ProgressService();
  final _uuid = const Uuid();
  Exercise? _currentExercise;
  List<Exercise> _exercises = [];
  final int _breakDuration = 30;
  Timer? _breakTimer;
  final bool _isExerciseComplete = false;
  final CountDownController _breakTimerController = CountDownController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  Timer? _countdownSoundTimer;
  bool _isExerciseInProgress = false;
  final int _lastSpokenNumber = 0;

  // Global variable to track pending audio tasks
  List<Future<void>> _pendingAudioTasks = [];

  // Define mood-based exercise selection and intensity rules
  final Map<String, Map<String, dynamic>> moodRules = {
    'Happy': {
      'intensity': 1.2,
      'breakDuration': 15,
    },
    'Energetic': {
      'intensity': 1.5,
      'breakDuration': 10,
    },
    'Tired': {
      'intensity': 0.7,
      'breakDuration': 40,
    },
    'Stressed': {
      'intensity': 0.8,
      'breakDuration': 30,
    },
    'Neutral': {
      'intensity': 1.0,
      'breakDuration': 20,
    },
  };

  // Define exercises by pain type
  final Map<String, List<Exercise>> _exercisesByPain = {
    'Neck Pain': [
      Exercise(
        id: '1',
        name: 'Neck Rotation',
        description:
            'Slowly rotate your neck in a circular motion to release neck stiffness.',
        duration: 45,
        reps: 8,
        videoUrl: 'assets/videos/Neck_pain/neck_rotation.mp4',
        instructions:
            'Sit straight and rotate your neck slowly in circular motions',
        benefits: 'Improves neck mobility and reduces stiffness',
        precautions: 'Perform slowly and stop if you feel pain',
        difficulty: 1,
        category: 'Neck Pain',
      ),
      Exercise(
        id: '2',
        name: 'Side Neck Stretch',
        description:
            'Gently tilt your head to each side to stretch neck muscles.',
        duration: 30,
        reps: 10,
        videoUrl: 'assets/videos/Neck_pain/side_neck_rotation.mp4',
        instructions: 'Gently tilt your head to each side',
        benefits: 'Relieves neck tension and improves flexibility',
        precautions: 'Stop if you feel any pain',
        difficulty: 1,
        category: 'Neck Pain',
      ),
      Exercise(
        id: '3',
        name: 'Chin Tucks',
        description: 'Gently tuck your chin to stretch the back of your neck.',
        duration: 30,
        reps: 10,
        videoUrl: 'assets/videos/Neck_pain/chin_tuck.mp4',
        instructions: 'Gently tuck your chin towards your chest',
        benefits: 'Strengthens neck muscles and improves posture',
        precautions: 'Perform slowly and controlled',
        difficulty: 2,
        category: 'Neck Pain',
      ),
      Exercise(
        id: '4',
        name: 'Neck Side Bend',
        description:
            'Gently bend your neck to each side to stretch neck muscles.',
        duration: 30,
        reps: 8,
        videoUrl: 'assets/videos/Neck_pain/neck_side_bend.mp4',
        instructions: 'Gently bend your neck to each side',
        benefits: 'Improves lateral neck flexibility',
        precautions: 'Keep movements slow and controlled',
        difficulty: 2,
        category: 'Neck Pain',
      ),
      Exercise(
        id: '5',
        name: 'Neck Extension',
        description:
            'Gently tilt your head back to stretch the front of your neck.',
        duration: 30,
        reps: 8,
        videoUrl: 'assets/videos/Neck_pain/neck_extension.mp4',
        instructions: 'Gently tilt your head back',
        benefits: 'Stretches front neck muscles',
        precautions: 'Perform slowly and avoid overextension',
        difficulty: 2,
        category: 'Neck Pain',
      ),
    ],
    'Shoulder Pain': [
      Exercise(
        id: '6',
        name: 'Shoulder Stretch',
        description:
            'Relieve tension in your shoulders by gently stretching your arms across your chest.',
        duration: 30,
        reps: 10,
        videoUrl: 'assets/videos/Shoulder_pain/shoulder_stretch.mp4',
        instructions: 'Gently stretch your arms across your chest',
        benefits: 'Relieves shoulder tension and improves flexibility',
        precautions: 'Keep movements controlled and avoid pain',
        difficulty: 1,
        category: 'Shoulder Pain',
      ),
      Exercise(
        id: '7',
        name: 'Arm Circles',
        description:
            'Extend your arms and make circular motions to improve shoulder mobility.',
        duration: 60,
        reps: 12,
        videoUrl: 'assets/videos/Shoulder_pain/arm_circles.mp4',
        instructions: 'Make circular motions with your arms',
        benefits: 'Improves shoulder mobility and range of motion',
        precautions: 'Start with small circles and gradually increase size',
        difficulty: 2,
        category: 'Shoulder Pain',
      ),
      Exercise(
        id: '8',
        name: 'Shoulder Rolls',
        description:
            'Roll your shoulders forward and backward to relieve tension.',
        duration: 45,
        reps: 10,
        videoUrl: 'assets/videos/Shoulder_pain/shoulder_rolls.mp4',
        instructions: 'Roll your shoulders in circular motions',
        benefits: 'Relieves shoulder tension and improves mobility',
        precautions: 'Keep movements smooth and controlled',
        difficulty: 1,
        category: 'Shoulder Pain',
      ),
      Exercise(
        id: '9',
        name: 'Cross-Body Shoulder Stretch',
        description:
            'Stretch one arm across your body to stretch the shoulder.',
        duration: 30,
        reps: 8,
        videoUrl:
            'assets/videos/Shoulder_pain/cross_body_ shoulder_stretch.mp4',
        instructions: 'Stretch one arm across your body',
        benefits: 'Improves shoulder flexibility and reduces tension',
        precautions: 'Hold stretch gently and avoid pain',
        difficulty: 1,
        category: 'Shoulder Pain',
      ),
      Exercise(
        id: '10',
        name: 'Wall Angels',
        description:
            'Stand against a wall and move your arms up and down to improve shoulder mobility.',
        duration: 60,
        reps: 10,
        videoUrl: 'assets/videos/Shoulder_pain/angels_wall.mp4',
        instructions: 'Move arms up and down while standing against wall',
        benefits: 'Improves shoulder mobility and posture',
        precautions: 'Keep back against wall and move slowly',
        difficulty: 2,
        category: 'Shoulder Pain',
      ),
    ],
    'Back Pain': [
      Exercise(
        id: '11',
        name: 'Cat-Cow Stretch',
        description:
            'Alternate between arching and rounding your back while on all fours.',
        duration: 45,
        reps: 10,
        videoUrl: 'assets/videos/Back_pain/cat_cow.mp4',
        instructions: 'Alternate between arching and rounding your back',
        benefits: 'Improves spinal mobility and reduces back pain',
        precautions: 'Move slowly and avoid pain',
        difficulty: 1,
        category: 'Back Pain',
      ),
      Exercise(
        id: '12',
        name: 'Child\'s Pose',
        description:
            'Sit back on your heels and stretch your arms forward to stretch your lower back.',
        duration: 60,
        reps: 8,
        videoUrl: 'assets/videos/Back_pain/child_pose.mp4',
        instructions: 'Sit back on heels and stretch arms forward',
        benefits: 'Relieves lower back tension and improves flexibility',
        precautions: 'Hold pose gently and avoid pain',
        difficulty: 1,
        category: 'Back Pain',
      ),
      Exercise(
        id: '13',
        name: 'Seated Spinal Twist',
        description:
            'Twist your torso while seated to improve spinal mobility.',
        duration: 45,
        reps: 8,
        videoUrl: 'assets/videos/Back_pain/seated_spinal_twist.mp4',
        instructions: 'Twist torso while seated',
        benefits: 'Improves spinal mobility and reduces stiffness',
        precautions: 'Twist gently and avoid pain',
        difficulty: 2,
        category: 'Back Pain',
      ),
      Exercise(
        id: '14',
        name: 'Pelvic Tilts',
        description:
            'Lie on your back and tilt your pelvis to stretch your lower back.',
        duration: 30,
        reps: 12,
        videoUrl: 'assets/videos/Back_pain/pelvic_tilt.mp4',
        instructions: 'Tilt pelvis while lying on back',
        benefits: 'Strengthens core and improves lower back mobility',
        precautions: 'Keep movements controlled and avoid pain',
        difficulty: 1,
        category: 'Back Pain',
      ),
      Exercise(
        id: '15',
        name: 'Knee-to-Chest Stretch',
        description:
            'Lie on your back and pull one knee to your chest to stretch your lower back.',
        duration: 30,
        reps: 8,
        videoUrl: 'assets/videos/Back_pain/knee_to_chest_ stretching.mp4',
        instructions: 'Pull knee to chest while lying on back',
        benefits: 'Relieves lower back tension and improves flexibility',
        precautions: 'Pull gently and avoid pain',
        difficulty: 1,
        category: 'Back Pain',
      ),
    ],
    'Wrist Pain': [
      Exercise(
        id: '16',
        name: 'Wrist Flexor Stretch',
        description:
            'Extend your arm and pull back on your fingers to stretch the wrist.',
        duration: 30,
        reps: 10,
        videoUrl: 'assets/videos/Wrist_pain/wrist_flexor_stretch.mp4',
        instructions: 'Pull back on fingers to stretch wrist',
        benefits: 'Improves wrist flexibility and reduces pain',
        precautions: 'Stretch gently and avoid pain',
        difficulty: 1,
        category: 'Wrist Pain',
      ),
      Exercise(
        id: '17',
        name: 'Wrist Extensor Stretch',
        description:
            'Extend your arm and push down on your fingers to stretch the wrist.',
        duration: 30,
        reps: 10,
        videoUrl: 'assets/videos/Wrist_pain/wrist_extensor_stretch.mp4',
        instructions: 'Push down on fingers to stretch wrist',
        benefits: 'Improves wrist mobility and reduces tension',
        precautions: 'Stretch gently and avoid pain',
        difficulty: 1,
        category: 'Wrist Pain',
      ),
      Exercise(
        id: '18',
        name: 'Wrist Rotations',
        description:
            'Rotate your wrists in circular motions to improve mobility.',
        duration: 30,
        reps: 12,
        videoUrl: 'assets/videos/Wrist_pain/wrist_rotations.mp4',
        instructions: 'Rotate wrists in circular motions',
        benefits: 'Improves wrist mobility and reduces stiffness',
        precautions: 'Rotate slowly and avoid pain',
        difficulty: 1,
        category: 'Wrist Pain',
      ),
      Exercise(
        id: '19',
        name: 'Finger Stretch',
        description: 'Spread your fingers wide and hold to stretch the hand.',
        duration: 30,
        reps: 8,
        videoUrl: 'assets/videos/Wrist_pain/finger_stretching.mp4',
        instructions: 'Spread fingers wide and hold',
        benefits: 'Improves hand flexibility and reduces tension',
        precautions: 'Stretch gently and avoid pain',
        difficulty: 1,
        category: 'Wrist Pain',
      ),
      Exercise(
        id: '20',
        name: 'Grip Strengthening',
        description: 'Use a stress ball to strengthen your grip.',
        duration: 30,
        reps: 12,
        videoUrl: 'assets/videos/Wrist_pain/grip_strengthening.mp4',
        instructions: 'Squeeze stress ball repeatedly',
        benefits: 'Strengthens grip and improves hand function',
        precautions: 'Squeeze gently and avoid pain',
        difficulty: 2,
        category: 'Wrist Pain',
      ),
    ],
    'Knee Pain': [
      Exercise(
        id: '21',
        name: 'Knee Flexion',
        description:
            'Gently bend your knee while seated to improve flexibility.',
        duration: 30,
        reps: 10,
        videoUrl: 'assets/videos/Knee_pain/knee_flexion.mp4',
        instructions: 'Bend knee while seated',
        benefits: 'Improves knee flexibility and reduces pain',
        precautions: 'Bend gently and avoid pain',
        difficulty: 1,
        category: 'Knee Pain',
      ),
      Exercise(
        id: '22',
        name: 'Quadriceps Stretch',
        description:
            'Stand and pull your heel towards your buttock to stretch the front of your thigh.',
        duration: 30,
        reps: 8,
        videoUrl: 'assets/videos/Knee_pain/quadriceps_stretch.mp4',
        instructions: 'Pull heel towards buttock',
        benefits: 'Improves thigh flexibility and reduces knee tension',
        precautions: 'Stretch gently and avoid pain',
        difficulty: 2,
        category: 'Knee Pain',
      ),
      Exercise(
        id: '23',
        name: 'Hamstring Stretch',
        description:
            'Sit and reach for your toes to stretch the back of your thigh.',
        duration: 30,
        reps: 8,
        videoUrl: 'assets/videos/Knee_pain/hamstring_stretch.mp4',
        instructions: 'Reach for toes while seated',
        benefits: 'Improves hamstring flexibility and reduces knee tension',
        precautions: 'Stretch gently and avoid pain',
        difficulty: 2,
        category: 'Knee Pain',
      ),
      Exercise(
        id: '24',
        name: 'Calf Stretch',
        description:
            'Stand and lean against a wall to stretch your calf muscles.',
        duration: 30,
        reps: 8,
        videoUrl: 'assets/videos/Knee_pain/calf_rehabilitation.mp4',
        instructions: 'Lean against wall to stretch calf',
        benefits: 'Improves calf flexibility and reduces knee tension',
        precautions: 'Stretch gently and avoid pain',
        difficulty: 1,
        category: 'Knee Pain',
      ),
      Exercise(
        id: '25',
        name: 'Seated Leg Raises',
        description: 'Sit and lift your leg to strengthen your quadriceps.',
        duration: 30,
        reps: 12,
        videoUrl: 'assets/videos/Knee_pain/seated_leg_raises.mp4',
        instructions: 'Lift leg while seated',
        benefits: 'Strengthens quadriceps and improves knee stability',
        precautions: 'Lift gently and avoid pain',
        difficulty: 2,
        category: 'Knee Pain',
      ),
    ],
  };

  // Flag to track if video is currently being shown
  bool _isShowingVideo = false;

  List<Exercise> _getExercisesForMood() {
    // Get all exercises for the current pain type
    final allExercises = _exercisesByPain[widget.exerciseType] ?? [];

    // If no exercises available for the pain type, return empty list
    if (allExercises.isEmpty) {
      return [];
    }

    // Get mood-based adjustments
    final moodRule = moodRules[widget.mood] ??
        {
          'intensity': 1.0,
          'breakDuration': 20,
        };

    final intensity = moodRule['intensity'] as double;

    // Filter exercises based on mood
    List<Exercise> filteredExercises = [];

    switch (widget.mood) {
      case 'Energetic':
        // Show all exercises with increased intensity
        filteredExercises = allExercises;
        break;

      case 'Happy':
        // Show 4 exercises with slightly increased intensity
        filteredExercises = allExercises.take(4).toList();
        break;

      case 'Neutral':
        // Show 3 exercises with normal intensity
        filteredExercises = allExercises.take(3).toList();
        break;

      case 'Tired':
        // Show 3 easy exercises with reduced intensity
        filteredExercises = allExercises
            .where((exercise) => exercise.difficulty <= 2)
            .take(3)
            .toList();
        break;

      case 'Stressed':
        // Show 3 easy exercises with normal intensity
        filteredExercises = allExercises
            .where((exercise) => exercise.difficulty <= 2)
            .take(3)
            .toList();
        break;

      default:
        // Default to 3 exercises with normal intensity
        filteredExercises = allExercises.take(3).toList();
    }

    // Apply intensity adjustments to all exercises
    return filteredExercises.map((exercise) {
      final adjustedDuration = (exercise.duration * intensity).round();
      final adjustedReps = (exercise.reps * intensity).round();
      return exercise.copyWith(
        duration: adjustedDuration,
        reps: adjustedReps,
      );
    }).toList();
  }

  void _loadExercises() {
    setState(() {
      _exercises = _getExercisesForMood();
      _currentExerciseIndex = 0;
      _isCompleted = false;
      _isBreakTime = false;
      _totalExerciseTime = 0;
      _totalBreakTime = 0;
      _currentExercise = _exercises.isNotEmpty ? _exercises[0] : null;

      // Debug log to verify adjustments
      for (var exercise in _exercises) {
        print(
            'Exercise ${exercise.name}: ${exercise.duration}s (adjusted for ${widget.mood} mood)');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadExercises();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _playCountdownSound(int remainingSeconds) async {
    if (remainingSeconds == 0) {
      // Play completion sound only at zero
      await _audioPlayer.play(AssetSource('audio/complete.mp3'));
    } else if (remainingSeconds <= 3 && remainingSeconds > 0) {
      // Play beep for last 3 seconds
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
    }
  }

  void _startBreakTimer() {
    _breakTimer?.cancel();
    int breakSecondsRemaining = _breakDuration;

    // Don't play audio if a video is currently being shown
    if (_isShowingVideo) {
      return;
    }

    // Cancel any pending audio first
    _cancelPendingAudio();

    // Play complete sound when starting a break
    _audioPlayer.play(AssetSource('audio/complete.mp3'));

    // Schedule beeps for the last 3 seconds of the break
    if (breakSecondsRemaining > 3) {
      for (int i = 3; i > 0; i--) {
        var beepTask =
            Future.delayed(Duration(seconds: breakSecondsRemaining - i), () {
          if (mounted && _isBreakTime && !_isShowingVideo) {
            _audioPlayer.play(AssetSource('audio/beep.mp3'));
            print(
                "Playing break beep at ${breakSecondsRemaining - i} seconds (${i} seconds remaining)");
          }
        });
        _pendingAudioTasks.add(beepTask);
      }
    }

    // Schedule countdown sound to play when break ends
    var countdownTask =
        Future.delayed(Duration(seconds: breakSecondsRemaining), () {
      if (mounted && !_isShowingVideo) {
        _audioPlayer.play(AssetSource('audio/countdown.mp3'));
      }
    });
    _pendingAudioTasks.add(countdownTask);

    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          breakSecondsRemaining--;
          _totalBreakTime++;

          // Recalculate progress every 5 seconds
          if (_totalBreakTime % 5 == 0) {
            _recalculateProgress();
          }
        });
      }

      if (breakSecondsRemaining == 0) {
        // Cancel the timer when break ends
        timer.cancel();
        if (mounted) {
          _moveToNextExercise();
        }
      }
    });
  }

  @override
  void dispose() {
    _totalTimer?.cancel();
    _breakTimer?.cancel();
    _countdownSoundTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _cancelPendingAudio();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = prefs.getStringList('exercise_history') ?? [];
      if (historyData.isEmpty) {
        debugPrint('No history found');
      }

      setState(() {
        _history = historyData
            .map((json) => ExerciseSession.fromMap(jsonDecode(json)))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData =
          _history.map((session) => jsonEncode(session.toMap())).toList();
      await prefs.setStringList('exercise_history', historyData);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  int _getAdjustedDuration(int baseDuration) {
    // Define mood-based multipliers for different aspects
    final Map<String, Map<String, double>> moodAdjustments = {
      'Energetic': {
        'exercise': 1.2, // 20% longer exercises
        'break': 0.8, // 20% shorter breaks
      },
      'Motivated': {
        'exercise': 1.1, // 10% longer exercises
        'break': 0.9, // 10% shorter breaks
      },
      'Neutral': {
        'exercise': 1.0, // Normal duration
        'break': 1.0, // Normal duration
      },
      'Tired': {
        'exercise': 0.8, // 20% shorter exercises
        'break': 1.2, // 20% longer breaks
      },
      'Exhausted': {
        'exercise': 0.6, // 40% shorter exercises
        'break': 1.4, // 40% longer breaks
      },
    };

    // Get the appropriate multiplier based on whether it's a break or exercise
    final multiplier = moodAdjustments[widget.mood]
            ?[_isBreakTime ? 'break' : 'exercise'] ??
        1.0;

    // Calculate the adjusted duration
    final adjustedDuration = (baseDuration * multiplier).round();

    // Ensure minimum durations
    if (_isBreakTime) {
      return adjustedDuration.clamp(10, 30); // Breaks between 10-30 seconds
    } else {
      return adjustedDuration.clamp(20, 90); // Exercises between 20-90 seconds
    }
  }

  void _onExerciseComplete() {
    // Cancel any pending audio tasks
    _cancelPendingAudio();

    // Don't play audio if a video is currently being shown
    if (!_isShowingVideo) {
      // Play completion sound
      _audioPlayer.play(AssetSource('audio/complete.mp3'));
    }

    if (_currentExerciseIndex < _exercises.length - 1) {
      // Reset exercise time when moving to break
      setState(() {
        _totalExerciseTime = 0; // Reset for the next exercise
      });
      _startBreak();
    } else {
      _onSessionComplete();
    }
  }

  void _startBreak() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _isBreakTime = true;
        _totalBreakTime = 0; // Reset break time counter
      });
      _startBreakTimer();
    }
  }

  void _showExerciseVideo() {
    if (_currentExercise != null) {
      // Stop any ongoing sounds before showing video
      _cancelPendingAudio();

      // Set flag to indicate video is being shown
      setState(() {
        _isShowingVideo = true;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseVideoPreviewScreen(
            exercise: _currentExercise!,
            onStartExercise: () {
              Navigator.pop(context); // Return to exercise page
              if (mounted) {
                setState(() {
                  _isStarted = true;
                  _isExerciseInProgress = true;
                  _isShowingVideo = false; // Reset video flag
                  // Reset exercise time counters when starting after video
                  _totalExerciseTime = 0;
                  _totalBreakTime = 0;
                });

                // Start the timer for the current exercise
                final exercise = _exercises[_currentExerciseIndex];
                final duration = _getAdjustedDuration(exercise.duration);

                // Play countdown sound when starting exercise
                _startExerciseAudio(duration);

                // Start the countdown timer
                _controller.restart(duration: duration);

                // Start tracking total time
                _totalTimer?.cancel();
                _totalTimer =
                    Timer.periodic(const Duration(seconds: 1), (timer) {
                  if (mounted) {
                    setState(() {
                      if (!_isBreakTime) {
                        _totalExerciseTime++;
                        // Recalculate progress every 5 seconds
                        if (_totalExerciseTime % 5 == 0) {
                          _recalculateProgress();
                        }
                      }
                    });
                  }
                });
              }
            },
          ),
        ),
      ).then((_) {
        // If user presses back without starting exercise
        if (mounted && _isShowingVideo) {
          setState(() {
            _isShowingVideo = false;
          });
        }
      });
    }
  }

  // Method to cancel all pending audio tasks
  void _cancelPendingAudio() {
    // Stop current playback
    _audioPlayer.stop();

    // Clear the pending tasks list
    _pendingAudioTasks = [];
  }

  // New method to handle exercise audio based on duration
  void _startExerciseAudio(int exerciseDurationSeconds) {
    // Don't play audio if a video is currently being shown
    if (_isShowingVideo) {
      print("Skipping audio playback because video is being shown");
      return;
    }

    // Clear any pending audio first
    _cancelPendingAudio();

    // Play the initial countdown sound for all exercises
    _audioPlayer.play(AssetSource('audio/countdown.mp3'));

    // Calculate how many complete minutes the exercise has (at least 1)
    int completeMinutes = (exerciseDurationSeconds / 60).ceil();

    // For exercises that span multiple minutes, schedule additional playbacks
    if (completeMinutes > 1) {
      for (int i = 1; i < completeMinutes; i++) {
        // Schedule audio to play at the start of each minute (except the first which already started)
        var audioTask = Future.delayed(Duration(seconds: i * 60), () {
          // Only play if we're still in the exercise (not completed or in break) and not showing video
          if (mounted &&
              _isExerciseInProgress &&
              !_isBreakTime &&
              !_isShowingVideo) {
            _audioPlayer.play(AssetSource('audio/countdown.mp3'));
          }
        });

        // Store the task so we can cancel it if needed
        _pendingAudioTasks.add(audioTask);
      }
    }

    // Add beep sounds for the final countdown (last 3 seconds)
    if (exerciseDurationSeconds > 3) {
      // Schedule beeps for seconds 3, 2, and 1 before end
      for (int i = 3; i > 0; i--) {
        var beepTask =
            Future.delayed(Duration(seconds: exerciseDurationSeconds - i), () {
          if (mounted &&
              _isExerciseInProgress &&
              !_isBreakTime &&
              !_isShowingVideo) {
            _audioPlayer.play(AssetSource('audio/beep.mp3'));
            print(
                "Playing beep at ${exerciseDurationSeconds - i} seconds (${i} seconds remaining)");
          }
        });
        _pendingAudioTasks.add(beepTask);
      }
    }
  }

  void _startSession() {
    setState(() {
      _currentExerciseIndex = 0;
      _currentExercise = _exercises[0];
      _isCompleted = false;
      _isBreakTime = false;
      _totalExerciseTime = 0;
      _totalBreakTime = 0;
      _isExerciseInProgress = false;

      // Cancel any existing timers
      _totalTimer?.cancel();
      _totalTimer = null;
      _breakTimer?.cancel();
      _breakTimer = null;
      _countdownSoundTimer?.cancel();
      _countdownSoundTimer = null;
    });

    // Show video for the first exercise
    _showExerciseVideo();
  }

  void _startCurrentExercise() {
    if (_exercises.isEmpty ||
        _currentExerciseIndex >= _exercises.length ||
        !mounted) {
      return;
    }

    final exercise = _exercises[_currentExerciseIndex];
    final duration = _getAdjustedDuration(exercise.duration);

    setState(() {
      _isExerciseInProgress = true;
      _currentExercise = exercise;
      // Reset exercise time tracking for the new exercise
      if (_currentExerciseIndex > 0) {
        _totalExerciseTime = 0;
      }
    });

    // Show video preview for all exercises
    _showExerciseVideo();
    return; // The video completion will handle the rest

    // The code below will only run after the video completes and user presses "Start Exercise"
  }

  void _playStartBeep() async {
    for (int i = 0; i < 3; i++) {
      await _audioPlayer.play(AssetSource('audio/beep.mp3'));
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _startCountdownSound() {
    _countdownSoundTimer?.cancel();
    int secondsRemaining = _currentExercise?.duration ?? 30;

    // Don't start countdown sounds if we just played a video
    // This will be handled by the video completion callback
    if (_isExerciseInProgress) {
      return;
    }

    _countdownSoundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining--;
      if (secondsRemaining <= 5 && secondsRemaining > 0) {
        // Play countdown beep for last 5 seconds
        _audioPlayer.play(AssetSource('audio/beep.mp3'));
      } else if (secondsRemaining == 0) {
        // Play completion sound
        _audioPlayer.play(AssetSource('audio/complete.mp3'));
        timer.cancel();
      }
    });
  }

  void _pauseExercise() {
    _controller.pause();
    _countdownSoundTimer?.cancel();
    setState(() {
      _isExerciseInProgress = false;
    });
  }

  void _resumeExercise() {
    _controller.resume();
    _startCountdownSound();
    setState(() {
      _isExerciseInProgress = true;
    });
  }

  void _completeSession() async {
    _totalTimer?.cancel();

    final session = ExerciseSession(
      date: DateTime.now(),
      duration: _totalExerciseTime,
      category: widget.exerciseType,
    );

    setState(() {
      _history.insert(0, session);
      _isCompleted = true;
      _isStarted = false;
    });

    await _saveHistory();

    // Calculate total calories burned (approximate)
    final totalCaloriesBurned = (_totalExerciseTime / 60 * 5 * 70 / 60).round();

    // Navigate to completion screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ExerciseCompletionScreen(
            category: widget.exerciseType,
            completedExercises: _exercises.length,
            totalCaloriesBurned: totalCaloriesBurned,
            totalMinutes: (_totalExerciseTime / 60).round(),
            currentExercise: _currentExercise!,
          ),
        ),
      );
    }
  }

  void _skipBreak() {
    _breakTimer?.cancel();
    _cancelPendingAudio(); // Cancel any pending audio before moving to the next exercise
    _moveToNextExercise();
  }

  Future<void> _completeExercise() async {
    if (!mounted || _currentExercise == null) return;

    setState(() {
      _isCompleted = true;
    });

    // Save progress
    final progress = ExerciseProgress(
      id: _uuid.v4(),
      userId: widget.userId,
      exerciseId: _currentExercise!.id,
      exerciseName: _currentExercise!.name,
      completedReps: _currentExercise!.reps,
      targetReps: _currentExercise!.reps,
      completedDuration: Duration(seconds: _currentExercise!.duration),
      targetDuration: Duration(seconds: _currentExercise!.duration),
      date: DateTime.now(),
      mood: widget.mood,
      isCompleted: true,
      notes: {
        'exerciseType': widget.exerciseType,
        'healthCondition': widget.healthCondition,
      },
    );

    try {
      await _progressService.saveProgress(progress);

      // Navigate to completion screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ExerciseCompletionScreen(
              category: widget.exerciseType,
              completedExercises: _exercises.length,
              totalCaloriesBurned:
                  (_totalExerciseTime / 60 * 5 * 70 / 60).round(),
              totalMinutes: (_totalExerciseTime / 60).round(),
              currentExercise: _currentExercise!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      // Stop any ongoing sounds
      _audioPlayer.stop();

      setState(() {
        _currentExerciseIndex++;
        _isBreakTime = false;
        _isExerciseInProgress = false;
        _currentExercise =
            _exercises[_currentExerciseIndex]; // Set current exercise

        // When moving to next exercise, update progress
        _recalculateProgress();

        print("Moving to next exercise: ${_currentExercise?.name}");
      });
      _startCurrentExercise();
    } else {
      _completeWorkout();
    }
  }

  void _onSessionComplete() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ExerciseCompletionScreen(
          currentExercise: _currentExercise!,
          completedExercises: _currentExerciseIndex + 1,
          totalMinutes: _calculateTotalMinutes(),
          category: _currentExercise!.category,
          totalCaloriesBurned: _calculateTotalMinutes() *
              5, // Rough estimate of calories burned per minute
        ),
      ),
    );
  }

  int _calculateTotalMinutes() {
    return _exercises
        .take(_currentExerciseIndex + 1)
        .fold(0, (sum, exercise) => sum + exercise.duration);
  }

  void _onBreakComplete() {
    _breakTimer?.cancel();

    // Reset break time counter when break is complete
    setState(() {
      _totalBreakTime = 0;
    });

    _moveToNextExercise();
  }

  void _completeWorkout() {
    _totalTimer?.cancel();
    _breakTimer?.cancel();
    _controller.pause();

    // Play completion sound if not showing video
    if (!_isShowingVideo) {
      _audioPlayer.play(AssetSource('audio/complete.mp3'));
    }

    setState(() {
      _isCompleted = true;
      _isExerciseInProgress = false;
    });

    // Calculate total minutes and calories
    final totalMinutes = (_totalExerciseTime / 60).ceil();
    final totalCaloriesBurned =
        (totalMinutes * 5).ceil(); // Rough estimate: 5 calories per minute

    // Navigate to completion screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseCompletionScreen(
          category: widget.exerciseType,
          completedExercises: _exercises.length,
          totalCaloriesBurned: totalCaloriesBurned,
          totalMinutes: totalMinutes,
          currentExercise: _exercises[_exercises.length - 1],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise: ${_currentExercise?.name ?? ""}'),
        actions: [
          if (!_isStarted)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _startSession,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _isStarted ? _buildExerciseView() : _buildStartView(),
                if (!_isStarted && _exercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startSession,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Start Session',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildExerciseList(),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 30),
            _buildHistory(),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    // Calculate total times
    final int totalOriginalDuration = _calculateTotalOriginalDuration();
    final int totalAdjustedDuration = _calculateTotalAdjustedDuration();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show total exercise time based on mood
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercise Session for ${widget.mood} Mood',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Total Time: ${_formatTime(totalAdjustedDuration)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Original time: ${_formatTime(totalOriginalDuration)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Adjusted based on your ${widget.mood} mood',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Exercise list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _exercises.length,
          itemBuilder: (context, index) {
            final exercise = _exercises[index];
            final originalDuration =
                _exercisesByPain[widget.exerciseType]![index].duration;
            final adjustedDuration = exercise.duration;
            final intensityMultiplier = adjustedDuration / originalDuration;

            // Determine intensity level and color
            final intensityLevel = intensityMultiplier > 1.1
                ? 'High Intensity'
                : intensityMultiplier < 0.9
                    ? 'Low Intensity'
                    : 'Normal Intensity';

            final intensityColor = intensityMultiplier > 1.1
                ? Colors.green
                : intensityMultiplier < 0.9
                    ? Colors.orange
                    : Colors.red;

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentExercise = exercise;
                    _currentExerciseIndex = index;
                  });
                  _startSession();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A80F0).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getExerciseIcon(exercise.name),
                              color: const Color(0xFF4A80F0),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exercise.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            color: const Color(0xFF4A80F0),
                            onPressed: () {
                              setState(() {
                                _currentExercise = exercise;
                                _currentExerciseIndex = index;
                              });
                              _startSession();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoChip(
                            icon: Icons.timer,
                            label: '${exercise.duration}s',
                          ),
                          // Show original duration if different
                          if (exercise.duration != originalDuration)
                            Text(
                              '(${originalDuration}s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          _buildInfoChip(
                            icon: Icons.repeat,
                            label: '${exercise.reps} reps',
                          ),
                          _buildInfoChip(
                            icon: Icons.fitness_center,
                            label: exercise.difficulty == 1
                                ? 'Easy'
                                : exercise.difficulty == 2
                                    ? 'Medium'
                                    : 'Hard',
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: intensityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              intensityLevel,
                              style: TextStyle(
                                fontSize: 12,
                                color: intensityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('stretch')) return Icons.accessibility_new;
    if (name.contains('rotation')) return Icons.rotate_right;
    if (name.contains('pose')) return Icons.self_improvement;
    if (name.contains('circles')) return Icons.circle;
    if (name.contains('flexion') || name.contains('extension')) {
      return Icons.straighten;
    }
    if (name.contains('twist')) return Icons.sync;
    if (name.contains('raise')) return Icons.arrow_upward;
    return Icons.fitness_center;
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sessions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final session = _history[index];
              return Card(
                margin: const EdgeInsets.only(right: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${session.duration ~/ 60}:${(session.duration % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.category,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${session.date.day}/${session.date.month}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseView() {
    if (_exercises.isEmpty) {
      return Center(
        child: Text(
          'No exercises available for ${widget.exerciseType}.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      );
    }

    final exercise = _exercises[_currentExerciseIndex];
    final int currentDuration =
        _isBreakTime ? _breakDuration : exercise.duration;

    // Calculate progress and total duration
    int totalDuration = 0;
    int completedDuration = 0;

    for (int i = 0; i < _exercises.length; i++) {
      int exerciseDuration = _getAdjustedDuration(_exercises[i].duration);
      totalDuration += exerciseDuration;

      if (i < _currentExerciseIndex) {
        // Past exercises are fully completed
        completedDuration += exerciseDuration;
      } else if (i == _currentExerciseIndex && !_isBreakTime) {
        // Current exercise - calculate elapsed time
        int elapsedTime = _totalExerciseTime;
        // Cap at maximum exercise duration
        elapsedTime = elapsedTime.clamp(0, exerciseDuration);
        completedDuration += elapsedTime;
      }
    }

    // Ensure values are valid
    completedDuration = completedDuration.clamp(0, totalDuration);
    double progressValue =
        totalDuration > 0 ? completedDuration / totalDuration : 0;

    // For debugging
    print(
        'Current exercise: ${exercise.name}, Time: $_totalExerciseTime/${_getAdjustedDuration(exercise.duration)}');
    print(
        'Total Progress: ${_formatTime(completedDuration)} / ${_formatTime(totalDuration)}');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isBreakTime ? 'Break Time!' : exercise.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (!_isBreakTime)
          Text(
            exercise.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 20),

        // Exercise number indicator
        Text(
          'Exercise ${_currentExerciseIndex + 1} of ${_exercises.length}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),

        // Only show progress during exercises, not during breaks
        if (!_isBreakTime) ...[
          // Total time progress
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total Progress: ${_formatTime(completedDuration)} / ${_formatTime(totalDuration)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[300],
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ],

        const SizedBox(height: 30),
        Center(
          child: CircularCountDownTimer(
            duration: _getAdjustedDuration(currentDuration),
            controller: _controller,
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.width * 0.3,
            ringColor: Colors.grey[300]!,
            fillColor:
                _isBreakTime ? Colors.orange : Theme.of(context).primaryColor,
            backgroundColor: Colors.white,
            strokeWidth: 20.0,
            isReverse: true,
            autoStart: true,
            timeFormatterFunction: (defaultFormattedTime, duration) {
              final minutes = duration.inSeconds ~/ 60;
              final seconds = duration.inSeconds % 60;
              return '$minutes:${seconds.toString().padLeft(2, '0')}';
            },
            onComplete: () =>
                _isBreakTime ? _onBreakComplete() : _onExerciseComplete(),
            onChange: (timeStamp) {
              try {
                // Calculate the actual remaining seconds
                final seconds = _getAdjustedDuration(currentDuration) -
                    int.parse(timeStamp);

                // Update progress only during exercise, not during break
                if (!_isBreakTime && mounted) {
                  setState(() {}); // Force UI refresh to update progress
                }

                // Only play sound during exercise, not during break
                if (!_isBreakTime && seconds > 0) {
                  _playCountdownSound(seconds);
                }
              } catch (e) {
                print('Error parsing timeStamp: $e');
              }
            },
            textStyle: const TextStyle(
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (_isBreakTime) ...[
          if (_currentExerciseIndex < _exercises.length - 1)
            Text(
              'Next Exercise: ${_exercises[_currentExerciseIndex + 1].name}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _skipBreak,
            child: const Text('Skip Break'),
          ),
        ] else ...[
          Text(
            'Instructions:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            exercise.instructions,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildBreakTimer() {
    return Container(
      color: Colors.black.withAlpha(128),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Break Time!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CircularCountDownTimer(
              duration: _breakDuration,
              controller: _breakTimerController,
              width: 100,
              height: 100,
              ringColor: Colors.grey[300]!,
              fillColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.white,
              strokeWidth: 10.0,
              strokeCap: StrokeCap.round,
              textStyle: const TextStyle(
                fontSize: 24.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              isReverse: true,
              isReverseAnimation: true,
              autoStart: true,
              timeFormatterFunction: (defaultFormattedTime, duration) {
                final minutes = duration.inSeconds ~/ 60;
                final seconds = duration.inSeconds % 60;
                return '$minutes:${seconds.toString().padLeft(2, '0')}';
              },
              onComplete: () {
                if (mounted) {
                  _moveToNextExercise();
                }
              },
            ),
            const SizedBox(height: 16),
            if (_currentExerciseIndex < _exercises.length - 1)
              Text(
                'Next: ${_exercises[_currentExerciseIndex + 1].name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ElevatedButton(
              onPressed: _skipBreak,
              child: const Text('Skip Break'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseInProgress() {
    return Container(
      color: Colors.black.withAlpha(128),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentExercise?.name ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AudioCountdownTimer(
              duration: _currentExercise?.duration ?? 30,
              controller: _controller,
              onComplete: _onExerciseComplete,
            ),
          ],
        ),
      ),
    );
  }

  // Add a helper method to format time
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Calculate total duration of all exercises adjusted for mood
  int _calculateTotalAdjustedDuration() {
    int totalDuration = 0;
    for (var exercise in _exercises) {
      totalDuration += _getAdjustedDuration(exercise.duration);
    }
    return totalDuration;
  }

  // Calculate total duration without mood adjustments
  int _calculateTotalOriginalDuration() {
    int totalDuration = 0;
    for (var exercise in _exercises) {
      totalDuration += exercise.duration;
    }
    return totalDuration;
  }

  // Recalculate and update the exercise timing based on current state
  void _recalculateProgress() {
    int totalDuration = 0;
    int completedDuration = 0;

    // Calculate total and completed time accurately
    for (int i = 0; i < _exercises.length; i++) {
      final exerciseDuration = _getAdjustedDuration(_exercises[i].duration);
      totalDuration += exerciseDuration;

      if (i < _currentExerciseIndex) {
        // Exercise is completed
        completedDuration += exerciseDuration;
      } else if (i == _currentExerciseIndex && !_isBreakTime) {
        // Current exercise - add elapsed time
        int currentElapsed = _totalExerciseTime - _totalBreakTime;
        currentElapsed = currentElapsed.clamp(0, exerciseDuration);
        completedDuration += currentElapsed;
      }
    }

    // Debug output
    print(
        'Progress: ${_formatTime(completedDuration)} / ${_formatTime(totalDuration)}');
    print(
        'Current exercise: ${_currentExerciseIndex + 1} of ${_exercises.length}');
    print(
        'Total exercise time: ${_totalExerciseTime}s, Break time: ${_totalBreakTime}s');
  }
}
