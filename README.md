# Chatter G - Chat App with AI and Video Calls

Welcome to Godzilla! This is a powerful Flutter application with a Golang backend, designed to deliver real-time chat functionality, AI-powered features, and audio/video calls using WebRTC. The app integrates MongoDB and CockroachDB for data storage, Firebase Auth for user authentication, and WebSockets for real-time communication..

## Table of Contents
- [Project Overview](#project-overview)
- [File Structure](#file-structure)
- [Requirements](#requirements)
- [How to Clone the Repository](#how-to-clone-the-repository)
- [How to Run](#how-to-run)
- [Contributing](#contributing)
- [License](#license)

## Project Overview
This project is a college assignment aimed at learning and showcasing advanced mobile and backend development skills. Key features include:
- Real-time text messaging using WebSockets.
- Audio and video calls using WebRTC.
- AI-powered chat assistance (integrated via xAI API).
- User authentication with Firebase.
- Data management with MongoDB and CockroachDB.

## File Structure
```
lib/
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── local_data_source.dart
│   │   ├── remote/
│   │   │   ├── mongodb_data_source.dart
│   │   │   ├── cockroachdb_data_source.dart
│   │   │   ├── websocket_data_source.dart
│   │   │   ├── ai_data_source.dart
│   │   │   └── webrtc_data_source.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── message_model.dart
│   │   ├── ai_response_model.dart
│   │   └── call_model.dart
│   ├── repositories/
│   │   ├── auth_repository_impl.dart
│   │   ├── data_repository_impl.dart
│   │   ├── websocket_repository_impl.dart
│   │   ├── ai_repository_impl.dart
│   │   └── webrtc_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── user_entity.dart
│   │   ├── message_entity.dart
│   │   ├── ai_response_entity.dart
│   │   └── call_entity.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── data_repository.dart
│   │   ├── websocket_repository.dart
│   │   ├── ai_repository.dart
│   │   └── webrtc_repository.dart
│   ├── usecases/
│   │   ├── login_use_case.dart
│   │   ├── fetch_data_use_case.dart
│   │   ├── send_message_use_case.dart
│   │   ├── get_ai_response_use_case.dart
│   │   └── manage_call_use_case.dart
├── presentation/
│   ├── pages/
│   │   ├── home_screen/
│   │   │   ├── home_screen.dart
│   │   │   └── home_provider.dart
│   │   ├── login_page/
│   │   │   ├── login_page.dart
│   │   │   └── login_provider.dart
│   │   ├── chat_screen/
│   │   │   ├── chat_screen.dart
│   │   │   └── chat_provider.dart
│   │   ├── ai_screen/
│   │   │   ├── ai_screen.dart
│   │   │   └── ai_provider.dart
│   │   ├── call_screen/
│   │   │   ├── call_screen.dart
│   │   │   └── call_provider.dart
│   │   └── splashscreen/
│   │       ├── splashscreen.dart
│   │       └── splash_provider.dart
│   ├── widgets/
│   │   ├── message_box.dart
│   │   ├── custom_button.dart
│   │   └── video_view.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── data_provider.dart
│   │   ├── websocket_provider.dart
│   │   ├── ai_provider.dart
│   │   └── webrtc_provider.dart
├── core/
│   ├── utils/
│   │   ├── network_helper.dart
│   │   └── constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   └── errors/
│       ├── exceptions.dart
│       └── failures.dart
├── app.dart
└── main.dart

backend/
├── cmd/
│   └── main.go
├── internal/
│   ├── handlers/
│   │   ├── auth_handler.go
│   │   ├── data_handler.go
│   │   ├── websocket_handler.go
│   │   ├── ai_handler.go
│   │   └── webrtc_handler.go
│   ├── services/
│   │   ├── auth_service.go
│   │   ├── data_service.go
│   │   ├── websocket_service.go
│   │   ├── ai_service.go
│   │   └── webrtc_service.go
│   ├── repositories/
│   │   ├── mongodb_repo.go
│   │   ├── cockroachdb_repo.go
│   │   └── webrtc_repo.go
│   └── models/
│       ├── user.go
│       ├── message.go
│       ├── ai_response.go
│       └── call.go
├── config/
│   └── config.go
└── go.mod
```


## Requirements
To run Godzilla, you will need the following:

- **Flutter SDK** (version [insert version, e.g., 3.19.0])
- **Dart** (included with Flutter)
- **Go** (version [insert version, e.g., 1.22])
- **Node.js** and **npm** (for WebRTC signaling, if needed)
- **MongoDB** (installed and running)
- **CockroachDB** (installed and running)
- **Firebase Account** (for authentication setup))
- **Android/iOS Simulator or Device** (for testing)
- **IDE** (e.g., Visual Studio Code or Android Studio)
- **Dependencies**:
  - Flutter packages: `flutter_riverpod`, `http`, `web_socket_channel`, `flutter_webrtc`, `firebase_auth`
  - Go packages: [list Go dependencies, e.g., `github.com/gorilla/websocket`]

Please install the above and configure them as per the official documentation. Detailed setup instructions will be added here.

## How to Clone the Repository
1. Open your terminal or command prompt.
2. Navigate to the directory where you want to store Godzilla.
3. Run the following command to clone the repository:## How to Clone the Repository
1. Open your terminal or command prompt.
2. Navigate to the directory where you want to store the project.
3. Run the following command to clone the repository:
   ```
   git clone https://github.com/your-username/chat-app.git
   ```
   (Replace `https://github.com/your-username/chat-app.git` with your actual repository URL.)
4. Change into the project directory:
   ```
   cd chat-app
   ```

## How to Run
### Frontend (Flutter)
1. Ensure all requirements are installed and configured.
2. Navigate to the `lib` directory:
   ```
   cd lib
   ```
3. Install Flutter dependencies:
   ```
   flutter pub get
   ```
4. Configure Firebase and xAI API keys in `lib/core/constants.dart`.
5. Run the app on a connected device or emulator:
   ```
   flutter run
   ```

### Backend (Go)
1. Navigate to the `backend` directory:
   ```
   cd backend
   ```
2. Install Go dependencies:
   ```
   go mod tidy
   ```
3. Configure database connections and API keys in `backend/config/config.go`.
4. Start the Go server:
   ```
   go run cmd/main.go
   ```
5. Ensure MongoDB, CockroachDB, and WebSocket servers are running.

### Notes
- Ensure the backend server is running before starting the Flutter app.
- For WebRTC, additional signaling server setup may be required (details to be added).

## Contributing
Contributions are welcome! Please fork the repository and submit a pull request with your changes. Follow the existing code style and add tests where applicable.

## License
This project is licensed under the [MIT License](LICENSE). See the `LICENSE` file for details.
