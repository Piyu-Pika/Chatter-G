import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/datasources/remote/api_value.dart';
import '../../../data/datasources/remote/cockroachdb_data_source.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

enum OnboardingStep {
  welcome,
  username,
  bio,
  dateOfBirth,
  gender,
  phoneNumber,
  profilePic,
  completed
}

class OnboardingMessage {
  final String content;
  final bool isBot;
  final DateTime timestamp;
  final OnboardingStep? step;

  OnboardingMessage({
    required this.content,
    required this.isBot,
    required this.timestamp,
    this.step,
  });
}

class OnboardingChatState {
  final List<OnboardingMessage> messages;
  final OnboardingStep currentStep;
  final TextEditingController textController;
  final ScrollController scrollController;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic> userData;
  final File? selectedImage;
  final int retryCount; // Add retry count to track attempts

  OnboardingChatState({
    required this.messages,
    required this.currentStep,
    required this.textController,
    required this.scrollController,
    required this.isLoading,
    this.errorMessage,
    required this.userData,
    this.selectedImage,
    this.retryCount = 0, // Initialize retry count
  });

  OnboardingChatState copyWith({
    List<OnboardingMessage>? messages,
    OnboardingStep? currentStep,
    TextEditingController? textController,
    ScrollController? scrollController,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? userData,
    File? selectedImage,
    int? retryCount,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return OnboardingChatState(
      messages: messages ?? this.messages,
      currentStep: currentStep ?? this.currentStep,
      textController: textController ?? this.textController,
      scrollController: scrollController ?? this.scrollController,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userData: userData ?? this.userData,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class OnboardingChatNotifier extends StateNotifier<OnboardingChatState> {
  final Ref ref;
  // final MongoDBDataSource _dataSource = MongoDBDataSource();
  final ApiClient _apiClient = ApiClient();

  static const int maxRetryAttempts = 3; // Maximum retry attempts

  OnboardingChatNotifier(this.ref)
      : super(OnboardingChatState(
          messages: [],
          currentStep: OnboardingStep.welcome,
          textController: TextEditingController(),
          scrollController: ScrollController(),
          isLoading: false,
          userData: {},
        )) {
    _initializeOnboarding();
  }

  void _initializeOnboarding() {
    _addBotMessage(
      "👋 Welcome to ChatterG! I'm here to help you set up your profile. Let's get to know each other better!",
      OnboardingStep.welcome,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotMessage(
        "First, what would you like your username to be? This will be how others find you on ChatterG.",
        OnboardingStep.username,
      );
      state = state.copyWith(currentStep: OnboardingStep.username);
    });
  }

  void _addBotMessage(String content, OnboardingStep? step) {
    final message = OnboardingMessage(
      content: content,
      isBot: true,
      timestamp: DateTime.now(),
      step: step,
    );
    state = state.copyWith(
      messages: [...state.messages, message],
    );
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    final message = OnboardingMessage(
      content: content,
      isBot: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, message],
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.scrollController.hasClients) {
        state.scrollController.animateTo(
          state.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void handleUserInput(String input) {
    if (input.trim().isEmpty) return;

    _addUserMessage(input);
    state.textController.clear();

    switch (state.currentStep) {
      case OnboardingStep.username:
        _handleUsername(input);
        break;
      case OnboardingStep.bio:
        _handleBio(input);
        break;
      case OnboardingStep.phoneNumber:
        _handlePhoneNumber(input);
        break;
      default:
        break;
    }
  }

  void _handleUsername(String username) {
    if (username.length < 3) {
      _addBotMessage(
        "Username should be at least 3 characters long. Please try again.",
        OnboardingStep.username,
      );
      return;
    }

    final updatedData = Map<String, dynamic>.from(state.userData);
    updatedData['username'] = username;
    state = state.copyWith(userData: updatedData);

    _addBotMessage(
      "Great choice! @$username sounds perfect. 🎉",
      null,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotMessage(
        "Now, tell me a little about yourself. What's your bio? This helps others know more about you.",
        OnboardingStep.bio,
      );
      state = state.copyWith(currentStep: OnboardingStep.bio);
    });
  }

  void _handleBio(String bio) {
    final updatedData = Map<String, dynamic>.from(state.userData);
    updatedData['bio'] = bio;
    state = state.copyWith(userData: updatedData);

    _addBotMessage(
      "Nice bio! That tells us a lot about you. 📝",
      null,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotMessage(
        "When is your birthday? Please tap the calendar button below to select your date of birth.",
        OnboardingStep.dateOfBirth,
      );
      state = state.copyWith(currentStep: OnboardingStep.dateOfBirth);
    });
  }

  void handleDateSelection(DateTime selectedDate) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final updatedData = Map<String, dynamic>.from(state.userData);
    updatedData['date_of_birth'] = formattedDate;
    state = state.copyWith(userData: updatedData);

    final readableDate = DateFormat('MMMM d, yyyy').format(selectedDate);
    _addUserMessage("My birthday is $readableDate");
    _addBotMessage(
      "Awesome! Birthday noted: $readableDate 🎂",
      null,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotMessage(
        "What's your gender? Please select from the options below.",
        OnboardingStep.gender,
      );
      state = state.copyWith(currentStep: OnboardingStep.gender);
    });
  }

  void handleGenderSelection(String gender) {
    final updatedData = Map<String, dynamic>.from(state.userData);
    updatedData['gender'] = gender;
    state = state.copyWith(userData: updatedData);

    _addUserMessage(gender);
    _addBotMessage(
      "Got it! Thanks for sharing. 👍",
      null,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotMessage(
        "What's your phone number? This helps with account security and recovery.",
        OnboardingStep.phoneNumber,
      );
      state = state.copyWith(currentStep: OnboardingStep.phoneNumber);
    });
  }

  void _handlePhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 10) {
      _addBotMessage(
        "Please enter a valid phone number with at least 10 digits.",
        OnboardingStep.phoneNumber,
      );
      return;
    }

    final updatedData = Map<String, dynamic>.from(state.userData);
    updatedData['phone_number'] = phoneNumber;
    state = state.copyWith(userData: updatedData);

    _addBotMessage(
      "Perfect! Phone number saved. 📱",
      null,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _addBotMessage(
        "Last step! Let's add a profile picture. Tap the camera button below to choose or take a photo.",
        OnboardingStep.profilePic,
      );
      state = state.copyWith(currentStep: OnboardingStep.profilePic);
    });
  }

  Future<void> handleImageSelection() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final List<int> imageBytes = await imageFile.readAsBytes();
        final String base64Image = base64Encode(imageBytes);

        final updatedData = Map<String, dynamic>.from(state.userData);
        updatedData['profile_pic'] = base64Image;

        state = state.copyWith(
          userData: updatedData,
          selectedImage: imageFile,
        );

        _addUserMessage("📸 Profile picture uploaded!");
        _addBotMessage(
          "Great photo! You look amazing! ✨",
          null,
        );

        Future.delayed(const Duration(milliseconds: 1000), () {
          _completeOnboarding();
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _addBotMessage(
        "Oops! There was an issue with the image. You can try again or skip this step.",
        OnboardingStep.profilePic,
      );
    }
  }

  Future<void> handleCameraSelection() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final List<int> imageBytes = await imageFile.readAsBytes();
        final String base64Image = base64Encode(imageBytes);

        final updatedData = Map<String, dynamic>.from(state.userData);
        updatedData['profile_pic'] = base64Image;

        state = state.copyWith(
          userData: updatedData,
          selectedImage: imageFile,
        );

        _addUserMessage("📸 Profile picture taken!");
        _addBotMessage(
          "Perfect shot! Looking good! 📷",
          null,
        );

        Future.delayed(const Duration(milliseconds: 1000), () {
          _completeOnboarding();
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      _addBotMessage(
        "Oops! There was an issue with the camera. You can try again or skip this step.",
        OnboardingStep.profilePic,
      );
    }
  }

  void skipProfilePicture() {
    _addUserMessage("I'll skip the profile picture for now");
    _addBotMessage(
      "No problem! You can always add one later from your profile settings. 👍",
      null,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      _completeOnboarding();
    });
  }

  void _completeOnboarding() {
    _addBotMessage(
      "🎉 Awesome! Your profile is all set up. Let me save everything for you...",
      null,
    );

    // Reset retry count when starting a new submission attempt
    state = state.copyWith(retryCount: 0);
    _submitUserData();
  }

  Future<void> _submitUserData() async {
    // Prevent infinite retries
    if (state.retryCount >= maxRetryAttempts) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save profile after multiple attempts',
      );

      _addBotMessage(
        "❌ I'm having trouble saving your profile right now. Please check your internet connection and try again later. You can restart the setup process if needed.",
        null,
      );

      // Optionally provide a retry button or manual retry option
      Future.delayed(const Duration(milliseconds: 2000), () {
        _addBotMessage(
          "Would you like me to try saving your profile one more time? You can also proceed to the main app and complete your profile later from settings.",
          OnboardingStep.completed,
        );
        state = state.copyWith(currentStep: OnboardingStep.completed);
      });

      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final authProvider = ref.read(authServiceProvider);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userData = Map<String, dynamic>.from(state.userData);
      userData['uuid'] = currentUser.uid;
      userData['name'] = currentUser.displayName ?? 'User';
      userData['email'] = currentUser.email ?? '';
      userData['created_at'] = DateTime.now().toIso8601String();
      userData['updated_at'] = DateTime.now().toIso8601String();
      userData['deleted_at'] = null; // Assuming no deletion for new users
      userData['username'] = userData['name'].split(' ').first;
      userData['bio'] = '';
      userData['date_of_birth'] = '';
      userData['gender'] = '';
      userData['phone_number'] = '';
      userData['profile_pic'] = '';

      print('Submitting user data: $userData');

      final response = await _apiClient.updateUser(
        uuid: userData['uuid'],
        name: userData['name'],
        username: userData['username'],
        bio: userData['bio'],
        dateOfBirth: userData['date_of_birth'],
        gender: userData['gender'],
        phoneNumber: userData['phone_number'],
        profilePic: userData['profile_pic'],
      );
      print('User data saved successfully: $response');

      _addBotMessage(
        "✅ Perfect! Your profile has been saved successfully. Welcome to ChatterG! You can now start chatting with other users.",
        OnboardingStep.completed,
      );

      state = state.copyWith(
        currentStep: OnboardingStep.completed,
        isLoading: false,
        retryCount: 0, // Reset retry count on success
      );

      // Navigate to main chat screen after a short delay
      Future.delayed(const Duration(milliseconds: 2000), () {
        // This should be handled by the UI to navigate
      });
    } catch (e) {
      print('Error saving user data: $e');

      // Increment retry count
      final newRetryCount = state.retryCount + 1;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save profile: $e',
        retryCount: newRetryCount,
      );

      if (newRetryCount < maxRetryAttempts) {
        _addBotMessage(
          "😅 Oops! There was an issue saving your profile. Don't worry, let me try again... (Attempt $newRetryCount of $maxRetryAttempts)",
          null,
        );

        // Retry after a short delay with exponential backoff
        final delaySeconds = 2 * newRetryCount; // 2, 4, 6 seconds
        Future.delayed(Duration(seconds: delaySeconds), () {
          if (mounted) {
            // Check if still mounted
            _submitUserData();
          }
        });
      }
      // If max retries reached, the check at the beginning of the method will handle it
    }
  }

  // Add a manual retry method for user-initiated retries
  void retrySubmission() {
    state = state.copyWith(retryCount: 0); // Reset retry count for manual retry
    _addBotMessage(
      "🔄 Trying to save your profile again...",
      null,
    );
    _submitUserData();
  }

  @override
  void dispose() {
    state.textController.dispose();
    state.scrollController.dispose();
    super.dispose();
  }
}

final onboardingChatProvider =
    StateNotifierProvider<OnboardingChatNotifier, OnboardingChatState>((ref) {
  return OnboardingChatNotifier(ref);
});
