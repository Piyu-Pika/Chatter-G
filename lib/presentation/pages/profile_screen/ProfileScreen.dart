import 'package:chatterg/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/datasources/remote/api_value.dart';
// import '../../../data/models/user_model.dart' as AppUser;
import '../../../data/models/user_model.dart';
import '../home_screen/home_provider.dart';
import 'profileScreenProvider.dart';
import 'package:dev_log/dev_log.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _apiClient = ApiClient();
  // final _cockroachdbDataSource = MongoDBDataSource();
  late Future<AppUser> _userDataFuture;
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  String _selectedGender = '';

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Fetch user data and initialize the future
  Future<void> _initializeUserData() async {
    final authProvider = ref.read(authServiceProvider);
    final userId = await authProvider.getUid();
    setState(() {
      _userDataFuture = _apiClient.getUserByUUID(uuid: userId).then((userData) {
        L.i('User Data: $userData');
        return AppUser(
          uuid: userData['uuid'] ?? '',
          name: userData['name'] ?? '',
          surname: userData['surname'] ?? '',
          email: userData['email'] ?? '',
          createdAt: DateTime.parse(
              userData['created_at'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(
              userData['updated_at'] ?? DateTime.now().toIso8601String()),
          username: userData['username'] ?? '',
          bio: userData['bio'] ?? '',
          dateOfBirth: userData['date_of_birth'] ?? '',
          gender: userData['gender'] ?? '',
          phoneNumber: userData['phone_number'] ?? '',
          profilePic: userData['profile_pic'] ?? '',
          lastSeen: DateTime.parse(
              userData['last_seen'] ?? DateTime.now().toIso8601String()),
        );
      });
    });
  }

  // Save changes to the database
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileState = ref.read(profileScreenProvider);

    try {
      await profileState.updateUserProfile(
        uuid: _controllers['uuid']?.text ?? '',
        name: _controllers['name']?.text ?? '',
        username: _controllers['username']?.text ?? '',
        bio: _controllers['bio']?.text ?? '',
        dateOfBirth: _controllers['dateOfBirth']?.text ?? '',
        gender: _selectedGender,
        phoneNumber: _controllers['phoneNumber']?.text ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: _buildAppBar(isDarkMode, primaryColor),
      body: FutureBuilder<AppUser>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error, isDarkMode);
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            _initializeControllers(user);
            _selectedGender = user.gender!;
            return _buildProfileForm(isDarkMode, primaryColor);
          } else {
            return Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveChanges,
        backgroundColor: primaryColor,
        child: const Icon(Icons.save),
      ),
    );
  }

  // Build the app bar
  AppBar _buildAppBar(bool isDarkMode, Color primaryColor) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.of(context).pop(),
        color: primaryColor,
      ),
    );
  }

  // Build the error widget
  Widget _buildErrorWidget(Object? error, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeUserData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Build the profile form
  Widget _buildProfileForm(bool isDarkMode, Color primaryColor) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeader(isDarkMode, primaryColor),
            const SizedBox(height: 30),
            _buildSection('Personal Information', [
              _buildEditableField('Name', 'name', Icons.person, isDarkMode,
                  required: true),
              _buildNonEditableField('Email', 'email', Icons.email, isDarkMode),
              _buildEditableField(
                  'Username', 'username', Icons.alternate_email, isDarkMode,
                  required: true),
            ]),
            const SizedBox(height: 20),
            _buildSection('Contact Details', [
              _buildPhoneNumberField(isDarkMode),
              _buildDateOfBirthField(isDarkMode, primaryColor),
              _buildGenderSelector(isDarkMode, primaryColor),
            ]),
            const SizedBox(height: 20),
            _buildSection('About You', [
              _buildBioField(isDarkMode),
            ]),
            const SizedBox(height: 20),
            _buildSection('Account Information', [
              _buildNonEditableField(
                  'UUID', 'uuid', Icons.fingerprint, isDarkMode),
              _buildNonEditableField(
                  'Created At', 'createdAt', Icons.calendar_today, isDarkMode),
              _buildNonEditableField(
                  'Updated At', 'updatedAt', Icons.update, isDarkMode),
            ]),
            _buildSection('Logout', [
              _buildlogoutButton(context),
            ]),
            const SizedBox(height: 80), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode, Color primaryColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor:
                    isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: Text(
                  _controllers['name']?.text.isNotEmpty == true
                      ? _controllers['name']!.text.substring(0, 1).toUpperCase()
                      : "?",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 18),
                color: Colors.white,
                onPressed: () {
                  // Image picker functionality would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Profile picture upload not implemented yet')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _controllers['name']?.text ?? '',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          '@${_controllers['username']?.text ?? ''}',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  // Initialize text controllers with user data
  void _initializeControllers(AppUser user) {
    _controllers['uuid'] = TextEditingController(text: user.uuid);
    _controllers['name'] = TextEditingController(text: user.name);
    _controllers['email'] = TextEditingController(text: user.email);
    _controllers['createdAt'] = TextEditingController(
      text: _formatDateTime(user.createdAt.toIso8601String()),
    );
    // _controllers['updatedAt'] = TextEditingController(
    //   text: _formatDateTime(user.updatedAt.toIso8601String()),
    // );
    // _controllers['deletedAt'] = TextEditingController(text: user.deletedAt);
    _controllers['username'] = TextEditingController(text: user.username);
    _controllers['bio'] = TextEditingController(text: user.bio);
    _controllers['dateOfBirth'] = TextEditingController(
      text: _formatDateTime(user.dateOfBirth),
    );
    _controllers['phoneNumber'] = TextEditingController(text: user.phoneNumber);
  }

  String _formatDateTime(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Non editable field for displaying user data
  Widget _buildNonEditableField(
    String label,
    String key,
    IconData icon,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                Text(
                  (_controllers[key]?.text.length ?? 0) > 30
                      ? '${_controllers[key]?.text.substring(0, 30)}...'
                      : _controllers[key]?.text ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build an editable field for user data
  Widget _buildEditableField(
      String label, String key, IconData icon, bool isDarkMode,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _controllers[key],
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white30 : Colors.black12,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              validator: required
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return '$label is required';
                      }
                      return null;
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // Build bio field with multiline support
  Widget _buildBioField(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers['bio'],
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us about yourself...',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white30 : Colors.black26,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.black12 : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build phone number field with validation
  Widget _buildPhoneNumberField(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.phone,
            size: 22,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _controllers['phoneNumber'],
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white30 : Colors.black12,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                helperText: '10 digits required',
                helperStyle: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 10) {
                  return 'Phone number must be 10 digits';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build date of birth field with date picker
  Widget _buildDateOfBirthField(bool isDarkMode, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.cake,
            size: 22,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _controllers['dateOfBirth'],
              readOnly: true,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.white30 : Colors.black12,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                suffixIcon: Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: primaryColor,
                ),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _parseDateOrDefault(_controllers['dateOfBirth']?.text),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: primaryColor,
                          onPrimary: Colors.white,
                          surface: isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          onSurface: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        dialogTheme: DialogThemeData(
                            backgroundColor: isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.white),
                      ),
                      child: child!,
                    );
                  },
                );

                if (date != null) {
                  setState(() {
                    _controllers['dateOfBirth']?.text =
                        DateFormat('MMM dd, yyyy').format(date);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Parse date string or return default date
  DateTime _parseDateOrDefault(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now()
          .subtract(const Duration(days: 365 * 18)); // Default to 18 years ago
    }

    try {
      return DateFormat('MMM dd, yyyy').parse(dateString);
    } catch (e) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return DateTime.now().subtract(const Duration(days: 365 * 18));
      }
    }
  }

  // Build gender selector with radio buttons
  Widget _buildGenderSelector(bool isDarkMode, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 22,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 16),
              Text(
                'Gender',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Row(
              children: [
                _buildGenderOption('Male', 'Male', isDarkMode, primaryColor),
                const SizedBox(width: 16),
                _buildGenderOption(
                    'Female', 'Female', isDarkMode, primaryColor),
                const SizedBox(width: 16),
                _buildGenderOption('Other', 'Other', isDarkMode, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build individual gender option
  Widget _buildGenderOption(
      String label, String value, bool isDarkMode, Color primaryColor) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedGender == value
              ? primaryColor
              : isDarkMode
                  ? Colors.black12
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedGender == value
                ? primaryColor
                : isDarkMode
                    ? Colors.white24
                    : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedGender == value
                ? Colors.white
                : isDarkMode
                    ? Colors.white
                    : Colors.black87,
            fontWeight:
                _selectedGender == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildlogoutButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Logout'),
        onPressed: () async {
          if (mounted) {
            await ref.read(homeScreenProvider.notifier).signOut(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
