# Enhanced Notification System

## Overview

The enhanced notification system provides intelligent, tag-based notifications with FCM (Firebase Cloud Messaging) integration and random interval scheduling to improve user engagement while avoiding notification fatigue.

## Features

### 🎯 Tag-Based Filtering
- Users can select specific tags for notifications
- Notifications are sent only for exams matching user's selected tags
- Granular control over notification types (exam reminders, job alerts, new postings, result updates)

### ⏰ Smart Scheduling
- Random intervals between 1-3 hours (configurable)
- User-defined preferred time windows (e.g., 9 AM - 6 PM)
- Multiple reminder intervals (e.g., 30 days, 7 days, 3 days, 1 day before exam)

### 📱 FCM Integration
- Push notifications to mobile devices
- Bulk notification support (up to 1000 tokens per batch)
- Automatic retry and error handling
- Token validation and cleanup

### 📊 Analytics & Insights
- Notification delivery statistics
- User engagement metrics
- Performance monitoring

## Database Schema

### Notification Model
```go
type Notification struct {
    ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
    Title        string            `json:"title" bson:"title"`
    Message      string            `json:"message" bson:"message"`
    CreatedAt    time.Time         `json:"createdAt" bson:"createdAt"`
    Type         NotificationType  `json:"type" bson:"type"`
    IsRead       bool              `json:"isRead" bson:"isRead"`
    ExamID       *string           `json:"examId,omitempty" bson:"examId,omitempty"`
    UserID       string            `json:"userId" bson:"userId"`
    Tags         []string          `json:"tags,omitempty" bson:"tags,omitempty"`
    Priority     int               `json:"priority" bson:"priority"`
    ScheduledFor *time.Time        `json:"scheduledFor,omitempty" bson:"scheduledFor,omitempty"`
    SentAt       *time.Time        `json:"sentAt,omitempty" bson:"sentAt,omitempty"`
    FCMSent      bool              `json:"fcmSent" bson:"fcmSent"`
}
```

### Notification Preferences Model
```go
type NotificationPreference struct {
    ID                 primitive.ObjectID `json:"id" bson:"_id,omitempty"`
    UserID             string            `json:"userId" bson:"userId"`
    Tags               []string          `json:"tags" bson:"tags"`
    ExamReminders      bool              `json:"examReminders" bson:"examReminders"`
    JobAlerts          bool              `json:"jobAlerts" bson:"jobAlerts"`
    NewPostings        bool              `json:"newPostings" bson:"newPostings"`
    ResultUpdates      bool              `json:"resultUpdates" bson:"resultUpdates"`
    DaysBefore         []int             `json:"daysBefore" bson:"daysBefore"`
    PreferredTimeStart int               `json:"preferredTimeStart" bson:"preferredTimeStart"`
    PreferredTimeEnd   int               `json:"preferredTimeEnd" bson:"preferredTimeEnd"`
    MinInterval        int               `json:"minInterval" bson:"minInterval"`
    MaxInterval        int               `json:"maxInterval" bson:"maxInterval"`
    IsActive           bool              `json:"isActive" bson:"isActive"`
    CreatedAt          time.Time         `json:"createdAt" bson:"createdAt"`
    UpdatedAt          time.Time         `json:"updatedAt" bson:"updatedAt"`
}
```

## API Endpoints

### Notification Preferences
- `GET /api/v1/user/notification-preferences` - Get user's notification preferences
- `PUT /api/v1/user/notification-preferences` - Update notification preferences

### Notifications
- `GET /api/v1/user/notifications` - Get user's notifications (with pagination and filtering)
- `PUT /api/v1/user/notifications/:id/read` - Mark notification as read
- `POST /api/v1/user/notifications/bulk` - Bulk operations (mark read/unread, delete, archive)
- `GET /api/v1/user/notifications/stats` - Get notification statistics
- `POST /api/v1/user/notifications/test` - Send test notification (development only)

### FCM Token Management
- `PUT /api/v1/user/fcm-token` - Update user's FCM token

## Configuration

### Environment Variables
```bash
# Firebase Cloud Messaging
FCM_SERVER_KEY=your-fcm-server-key-here
FCM_PROJECT_ID=your-project-id

# Notification Settings (optional)
NOTIFICATION_MIN_INTERVAL=60    # Minutes (default: 60)
NOTIFICATION_MAX_INTERVAL=180   # Minutes (default: 180)
```

## Usage Examples

### 1. Setting Up Notification Preferences
```bash
curl -X PUT http://localhost:8080/api/v1/user/notification-preferences \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tags": ["engineering", "gate", "government"],
    "examReminders": true,
    "jobAlerts": true,
    "newPostings": true,
    "resultUpdates": false,
    "daysBefore": [30, 7, 3, 1],
    "preferredTimeStart": 9,
    "preferredTimeEnd": 18,
    "minInterval": 60,
    "maxInterval": 180,
    "isActive": true
  }'
```

### 2. Getting Notifications
```bash
curl -X GET "http://localhost:8080/api/v1/user/notifications?page=1&limit=20&type=exam&unread=true" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. Updating FCM Token
```bash
curl -X PUT http://localhost:8080/api/v1/user/fcm-token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "your-fcm-token-here"
  }'
```

## Notification Types

1. **Exam Reminders** (`exam`) - Scheduled reminders for upcoming exams
2. **Job Alerts** (`reminder`) - New job postings matching user interests
3. **New Postings** (`exam`) - Immediate notifications for new exam announcements
4. **System Notifications** (`system`) - Important system updates
5. **Achievements** (`achievement`) - User milestone celebrations

## Scheduling Logic

### Random Interval Calculation
```go
// Random interval between min and max (default 1-3 hours)
randomInterval := rand.Intn(maxInterval-minInterval+1) + minInterval

// Random time within preferred hours
randomHour := rand.Intn(endHour-startHour+1) + startHour

// Final scheduled time
scheduledTime := baseDate.Add(time.Duration(randomInterval) * time.Minute)
```

### Priority System
- Priority 10: 1 day before exam (highest)
- Priority 8: 3 days before exam
- Priority 6: 7 days before exam
- Priority 4: 15 days before exam
- Priority 2: 30 days before exam
- Priority 1: Default/lowest

## Testing

Run the notification system test:
```bash
go run scripts/test_notifications.go
```

This will:
1. Create a test user with notification preferences
2. Create a test exam
3. Schedule notifications
4. Test FCM service
5. Display results

## Monitoring & Analytics

### Notification Statistics
- Total notifications sent
- Delivery success rate
- User engagement metrics
- FCM token health
- Performance metrics

### Health Checks
- Database connectivity
- FCM service status
- Scheduler health
- Queue processing status

## Best Practices

1. **Rate Limiting**: Respect user preferences for notification frequency
2. **Personalization**: Use tags and preferences for relevant notifications
3. **Timing**: Send notifications during user's preferred hours
4. **Content**: Keep messages concise and actionable
5. **Fallback**: Always store notifications in database even if FCM fails
6. **Analytics**: Track delivery and engagement metrics
7. **Cleanup**: Regularly clean up old notifications and invalid tokens

## Troubleshooting

### Common Issues

1. **FCM Notifications Not Received**
   - Check FCM_SERVER_KEY configuration
   - Verify user's FCM token is valid
   - Check FCM service logs

2. **Notifications Not Scheduled**
   - Verify user has active notification preferences
   - Check if exam tags match user's selected tags
   - Ensure exam date is in the future

3. **High Notification Volume**
   - Review user's tag selections
   - Adjust min/max intervals
   - Check notification preferences

### Debug Commands
```bash
# Check notification preferences
curl -X GET http://localhost:8080/api/v1/user/notification-preferences \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get notification stats
curl -X GET http://localhost:8080/api/v1/user/notifications/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Send test notification
curl -X POST http://localhost:8080/api/v1/user/notifications/test \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "message": "Test notification", "type": "system"}'
```

## Future Enhancements

1. **Machine Learning**: Personalized notification timing based on user behavior
2. **Rich Notifications**: Support for images, actions, and rich content
3. **Multi-channel**: Email, SMS, and in-app notifications
4. **A/B Testing**: Test different notification strategies
5. **Advanced Analytics**: Detailed user engagement insights
6. **Smart Batching**: Intelligent notification grouping
7. **Timezone Support**: Automatic timezone detection and conversion