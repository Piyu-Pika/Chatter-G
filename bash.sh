#!/bin/bash

# Create main directories
mkdir -p lib/data/datasources/local
mkdir -p lib/data/datasources/remote
mkdir -p lib/data/models
mkdir -p lib/data/repositories
mkdir -p lib/domain/entities
mkdir -p lib/domain/repositories
mkdir -p lib/domain/usecases
mkdir -p lib/presentation/pages/home_screen
mkdir -p lib/presentation/pages/login_page
mkdir -p lib/presentation/pages/chat_screen
mkdir -p lib/presentation/pages/ai_screen
mkdir -p lib/presentation/pages/call_screen
mkdir -p lib/presentation/pages/splashscreen
mkdir -p lib/presentation/widgets
mkdir -p lib/presentation/providers
mkdir -p lib/core/utils
mkdir -p lib/core/theme
mkdir -p lib/core/errors

# Create data layer files
touch lib/data/datasources/local/local_data_source.dart
touch lib/data/datasources/remote/mongodb_data_source.dart
touch lib/data/datasources/remote/cockroachdb_data_source.dart
touch lib/data/datasources/remote/websocket_data_source.dart
touch lib/data/datasources/remote/ai_data_source.dart
touch lib/data/datasources/webrtc_data_source.dart

touch lib/data/models/user_model.dart
touch lib/data/models/message_model.dart
touch lib/data/models/ai_response_model.dart
touch lib/data/models/call_model.dart

touch lib/data/repositories/auth_repository_impl.dart
touch lib/data/repositories/data_repository_impl.dart
touch lib/data/repositories/websocket_repository_impl.dart
touch lib/data/repositories/ai_repository_impl.dart
touch lib/data/repositories/webrtc_repository_impl.dart

# Create domain layer files
touch lib/domain/entities/user_entity.dart
touch lib/domain/entities/message_entity.dart
touch lib/domain/entities/ai_response_entity.dart
touch lib/domain/entities/call_entity.dart

touch lib/domain/repositories/auth_repository.dart
touch lib/domain/repositories/data_repository.dart
touch lib/domain/repositories/websocket_repository.dart
touch lib/domain/repositories/ai_repository.dart
touch lib/domain/repositories/webrtc_repository.dart

touch lib/domain/usecases/login_use_case.dart
touch lib/domain/usecases/fetch_data_use_case.dart
touch lib/domain/usecases/send_message_use_case.dart
touch lib/domain/usecases/get_ai_response_use_case.dart
touch lib/domain/usecases/manage_call_use_case.dart

# Create presentation layer files
touch lib/presentation/pages/home_screen/home_screen.dart
touch lib/presentation/pages/home_screen/home_provider.dart

touch lib/presentation/pages/login_page/login_page.dart
touch lib/presentation/pages/login_page/login_provider.dart

touch lib/presentation/pages/chat_screen/chat_screen.dart
touch lib/presentation/pages/chat_screen/chat_provider.dart

touch lib/presentation/pages/ai_screen/ai_screen.dart
touch lib/presentation/pages/ai_screen/ai_provider.dart

touch lib/presentation/pages/call_screen/call_screen.dart
touch lib/presentation/pages/call_screen/call_provider.dart

touch lib/presentation/pages/splashscreen/splashscreen.dart
touch lib/presentation/pages/splashscreen/splash_provider.dart

touch lib/presentation/widgets/message_box.dart
touch lib/presentation/widgets/custom_button.dart
touch lib/presentation/widgets/video_view.dart

touch lib/presentation/providers/auth_provider.dart
touch lib/presentation/providers/data_provider.dart
touch lib/presentation/providers/websocket_provider.dart
touch lib/presentation/providers/ai_provider.dart
touch lib/presentation/providers/webrtc_provider.dart

# Create core layer files
touch lib/core/utils/network_helper.dart
touch lib/core/utils/constants.dart
touch lib/core/theme/app_theme.dart
touch lib/core/errors/exceptions.dart
touch lib/core/errors/failures.dart

# Create app files
touch lib/app.dart
touch lib/main.dart

echo "File structure created successfully!"