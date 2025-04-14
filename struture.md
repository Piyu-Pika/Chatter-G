lib/
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── local_data_source.dart  # Local caching or offline storage
│   │   ├── remote/
│   │   │   ├── mongodb_data_source.dart  # MongoDB API integration
│   │   │   ├── cockroachdb_data_source.dart  # CockroachDB API integration
│   │   │   ├── websocket_data_source.dart  # WebSocket real-time data handling
│   │   │   └── ai_data_source.dart  # AI API integration (e.g., xAI API)
│   │   └── webrtc_data_source.dart  # WebRTC signaling and media handling
│   ├── models/
│   │   ├── user_model.dart  # DTO for user data
│   │   ├── message_model.dart  # DTO for WebSocket messages
│   │   ├── ai_response_model.dart  # DTO for AI responses
│   │   └── call_model.dart  # DTO for WebRTC call data
│   ├── repositories/
│   │   ├── auth_repository_impl.dart  # Firebase Auth implementation
│   │   ├── data_repository_impl.dart  # MongoDB/CockroachDB implementation
│   │   ├── websocket_repository_impl.dart  # WebSocket repository
│   │   ├── ai_repository_impl.dart  # AI repository implementation
│   │   └── webrtc_repository_impl.dart  # WebRTC repository implementation
├── domain/
│   ├── entities/
│   │   ├── user_entity.dart  # Business entity for user
│   │   ├── message_entity.dart  # Business entity for messages
│   │   ├── ai_response_entity.dart  # Business entity for AI responses
│   │   └── call_entity.dart  # Business entity for WebRTC calls
│   ├── repositories/
│   │   ├── auth_repository.dart  # Abstract auth repository
│   │   ├── data_repository.dart  # Abstract data repository
│   │   ├── websocket_repository.dart  # Abstract WebSocket repository
│   │   ├── ai_repository.dart  # Abstract AI repository
│   │   └── webrtc_repository.dart  # Abstract WebRTC repository
│   ├── usecases/
│   │   ├── login_use_case.dart  # Business logic for login with Firebase
│   │   ├── fetch_data_use_case.dart  # Fetch data from MongoDB/CockroachDB
│   │   ├── send_message_use_case.dart  # Send message via WebSocket
│   │   ├── get_ai_response_use_case.dart  # Get AI response
│   │   └── manage_call_use_case.dart  # Manage WebRTC calls
├── presentation/
│   ├── pages/
│   │   ├── home_screen/
│   │   │   ├── home_screen.dart  # UI for home screen
│   │   │   └── home_provider.dart  # Riverpod provider for home screen
│   │   ├── login_page/
│   │   │   ├── login_page.dart  # UI for login
│   │   │   └── login_provider.dart  # Riverpod provider for login
│   │   ├── chat_screen/
│   │   │   ├── chat_screen.dart  # UI for chat with WebSocket
│   │   │   └── chat_provider.dart  # Riverpod provider for chat
│   │   ├── ai_screen/
│   │   │   ├── ai_screen.dart  # UI for AI interaction
│   │   │   └── ai_provider.dart  # Riverpod provider for AI
│   │   ├── call_screen/
│   │   │   ├── call_screen.dart  # UI for WebRTC audio/video call
│   │   │   └── call_provider.dart  # Riverpod provider for WebRTC
│   │   └── splashscreen/
│   │       ├── splashscreen.dart  # Splash screen UI
│   │       └── splash_provider.dart  # Riverpod provider for splash
│   ├── widgets/
│   │   ├── message_box.dart  # Reusable widget for messages
│   │   ├── custom_button.dart  # Reusable custom button
│   │   └── video_view.dart  # Reusable widget for WebRTC video
│   ├── providers/
│   │   ├── auth_provider.dart  # Global Riverpod provider for Firebase Auth
│   │   ├── data_provider.dart  # Global Riverpod provider for data operations
│   │   ├── websocket_provider.dart  # Global Riverpod provider for WebSocket
│   │   ├── ai_provider.dart  # Global Riverpod provider for AI
│   │   └── webrtc_provider.dart  # Global Riverpod provider for WebRTC
├── core/
│   ├── utils/
│   │   ├── network_helper.dart  # Network utility functions
│   │   └── constants.dart  # App-wide constants
│   ├── theme/
│   │   ├── app_theme.dart  # Theme configuration
│   └── errors/
│       ├── exceptions.dart  # Custom exceptions
│       └── failures.dart  # Failure handling
├── app.dart  # App configuration and routing
└── main.dart  # Entry point