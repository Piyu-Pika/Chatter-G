import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/datasources/remote/api_value.dart';
// import '../../../data/models/user_model.dart' as AppUser;
import '../../../data/models/user_model.dart';
// import 'profileScreenProvider.dart';

class ReciverProfileScreen extends ConsumerStatefulWidget {
  const ReciverProfileScreen({super.key,required this.uuid});
  final String uuid;

  @override
  ConsumerState<ReciverProfileScreen> createState() => _ReciverProfileScreenState();
}

class _ReciverProfileScreenState extends ConsumerState<ReciverProfileScreen> {
  final _apiClient = ApiClient();
  // final _cockroachdbDataSource = MongoDBDataSource();
  late Future<AppUser> _userDataFuture;
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  String _selectedGender = '';

  @override
  void initState() {
    super.initState();
    _initializeUserData(widget.uuid);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Fetch user data and initialize the future
  Future<void> _initializeUserData(userId) async {
    // final authProvider = ref.read(authServiceProvider);
    // final userId = await authProvider.getUid();
    setState(() {
      _userDataFuture = _apiClient.getUserByUUID(uuid: userId).then((userData) {
        print('User Data: $userData');
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
    );
  }

  // Build the app bar
  AppBar _buildAppBar(bool isDarkMode, Color primaryColor) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Profile',
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
              onPressed: () => _initializeUserData(widget.uuid),
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
              _buildNonEditableField('Name', 'name', Icons.person, isDarkMode,
                ),
              _buildNonEditableField('Email', 'email', Icons.email, isDarkMode),
              _buildNonEditableField(
                  'Username', 'username', Icons.alternate_email, isDarkMode,
                  ),
            ]),
            const SizedBox(height: 20),
            _buildSection('Contact Details', [
              _buildPhoneNumberField(isDarkMode),
              _buildDateOfBirthField(isDarkMode, primaryColor),
              // _buildGenderSelector(isDarkMode, primaryColor),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black12 : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _controllers['bio']?.text ?? '',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                Text(
                  _controllers['phoneNumber']?.text ?? '',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                Text(
                  _controllers['dateOfBirth']?.text ?? '',
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


  // Build individual gender option
}