import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedFitnessLevel = 'Beginner';
  List<String> _selectedHealthConditions = [];
  List<String> _selectedFitnessGoals = [];
  
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _healthConditions = [
    'None', 
    'Back Pain', 
    'Knee Pain', 
    'Shoulder Pain', 
    'Neck Pain',
    'Arthritis',
    'Diabetes',
    'Heart Condition',
    'High Blood Pressure'
  ];
  final List<String> _fitnessGoals = [
    'Weight Loss',
    'Muscle Gain',
    'Improve Flexibility',
    'Increase Endurance',
    'Reduce Stress',
    'Better Sleep',
    'Improve Posture',
    'Rehabilitation'
  ];

  bool _isSaving = false;

  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;

        if (user != null) {
          // Create profile data
          final profileData = {
            'personalInfo': {
              'name': _nameController.text,
              'email': _emailController.text,
              'age': _ageController.text,
              'height': _heightController.text,
              'weight': _weightController.text,
              'gender': _selectedGender,
            },
            'fitnessProfile': {
              'level': _selectedFitnessLevel,
              'healthConditions': _selectedHealthConditions,
              'goals': _selectedFitnessGoals,
            },
            'profileCompleted': true,
            'lastUpdated': FieldValue.serverTimestamp(),
          };

          // Save to Firestore using set with merge
          print('Saving profile data to Firestore...');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(profileData, SetOptions(merge: true));
          print('Profile data saved successfully');

          // Navigate to home screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
        } else {
          throw Exception('No user found');
        }
      } catch (e) {
        print('Error saving profile data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4A80F0).withOpacity(0.8),
              const Color(0xFF1A3FA8),
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        "Create Your Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A80F0),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Personal Information Section
                          _buildSectionHeader("Personal Information"),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: "Full Name",
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: "Email Address",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Gender Selection
                          _buildSectionHeader("Gender"),
                          const SizedBox(height: 16),
                          _buildGenderSelector(),
                          const SizedBox(height: 24),
                          
                          // Body Metrics Section
                          _buildSectionHeader("Body Metrics"),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _ageController,
                                  label: "Age",
                                  icon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid age';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _heightController,
                                  label: "Height (cm)",
                                  icon: Icons.height_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid height';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _weightController,
                                  label: "Weight (kg)",
                                  icon: Icons.monitor_weight_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid weight';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Fitness Level Section
                          _buildSectionHeader("Fitness Level"),
                          const SizedBox(height: 16),
                          _buildFitnessLevelSelector(),
                          const SizedBox(height: 24),
                          
                          // Health Conditions Section
                          _buildSectionHeader("Health Conditions"),
                          const SizedBox(height: 8),
                          const Text(
                            "Select any health conditions that apply to you",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildHealthConditionsSelector(),
                          const SizedBox(height: 24),
                          
                          // Fitness Goals Section
                          _buildSectionHeader("Fitness Goals"),
                          const SizedBox(height: 8),
                          const Text(
                            "What do you want to achieve?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFitnessGoalsSelector(),
                          const SizedBox(height: 32),
                          
                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfileData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A80F0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Complete Profile Setup',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
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
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A80F0),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A80F0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A80F0), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
  
  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: _genders.map((gender) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = gender;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedGender == gender
                      ? const Color(0xFF4A80F0).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedGender == gender
                      ? Border.all(color: const Color(0xFF4A80F0))
                      : null,
                ),
                child: Center(
                  child: Text(
                    gender,
                    style: TextStyle(
                      color: _selectedGender == gender
                          ? const Color(0xFF4A80F0)
                          : Colors.grey.shade700,
                      fontWeight: _selectedGender == gender
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildFitnessLevelSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _fitnessLevels.map((level) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFitnessLevel = level;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: _selectedFitnessLevel == level
                    ? const Color(0xFF4A80F0).withOpacity(0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: level != _fitnessLevels.last
                        ? Colors.grey.shade300
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedFitnessLevel == level
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _selectedFitnessLevel == level
                        ? const Color(0xFF4A80F0)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    level,
                    style: TextStyle(
                      color: _selectedFitnessLevel == level
                          ? const Color(0xFF4A80F0)
                          : Colors.grey.shade700,
                      fontWeight: _selectedFitnessLevel == level
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getLevelIcon(level),
                    color: _selectedFitnessLevel == level
                        ? const Color(0xFF4A80F0)
                        : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Beginner':
        return Icons.directions_walk;
      case 'Intermediate':
        return Icons.directions_run;
      case 'Advanced':
        return Icons.sports_gymnastics;
      default:
        return Icons.fitness_center;
    }
  }
  
  Widget _buildHealthConditionsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _healthConditions.map((condition) {
        final isSelected = _selectedHealthConditions.contains(condition);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (condition == 'None') {
                _selectedHealthConditions = isSelected ? [] : ['None'];
              } else {
                if (isSelected) {
                  _selectedHealthConditions.remove(condition);
                } else {
                  _selectedHealthConditions.add(condition);
                  _selectedHealthConditions.remove('None');
                }
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A80F0).withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4A80F0)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              condition,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF4A80F0)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildFitnessGoalsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fitnessGoals.map((goal) {
        final isSelected = _selectedFitnessGoals.contains(goal);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFitnessGoals.remove(goal);
              } else {
                _selectedFitnessGoals.add(goal);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A80F0).withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4A80F0)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              goal,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF4A80F0)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
