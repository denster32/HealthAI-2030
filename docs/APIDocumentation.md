# HealthAI 2030 API Documentation

## Overview

The HealthAI 2030 API provides comprehensive health data management, analytics, and AI-powered insights. This RESTful API is designed for iOS 18+ and macOS 15+ applications, with support for real-time data streaming and batch processing.

## Base URL

```
Production: https://api.healthai2030.com/v1
Staging: https://staging-api.healthai2030.com/v1
Development: https://dev-api.healthai2030.com/v1
```

## Authentication

### OAuth 2.0 Flow

All API requests require authentication using OAuth 2.0 with JWT tokens.

```http
Authorization: Bearer <access_token>
```

### Token Endpoints

#### Get Access Token
```http
POST /auth/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&username=<email>&password=<password>&client_id=<client_id>
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "health:read health:write analytics:read"
}
```

#### Refresh Token
```http
POST /auth/refresh
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<refresh_token>
```

## Health Data Management

### Upload Health Data

#### Single Data Point
```http
POST /health/data
Content-Type: application/json

{
  "timestamp": "2024-01-15T10:30:00Z",
  "type": "heart_rate",
  "value": 75,
  "unit": "bpm",
  "source": "apple_watch",
  "metadata": {
    "device_id": "watch_123",
    "location": "home"
  }
}
```

#### Batch Upload
```http
POST /health/data/batch
Content-Type: application/json

{
  "data_points": [
    {
      "timestamp": "2024-01-15T10:30:00Z",
      "type": "heart_rate",
      "value": 75,
      "unit": "bpm"
    },
    {
      "timestamp": "2024-01-15T10:35:00Z",
      "type": "steps",
      "value": 1250,
      "unit": "count"
    }
  ]
}
```

### Retrieve Health Data

#### Get Data by Type
```http
GET /health/data?type=heart_rate&start_date=2024-01-01&end_date=2024-01-15
```

**Response:**
```json
{
  "data": [
    {
      "id": "data_123",
      "timestamp": "2024-01-15T10:30:00Z",
      "type": "heart_rate",
      "value": 75,
      "unit": "bpm",
      "source": "apple_watch",
      "created_at": "2024-01-15T10:30:05Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 100,
    "total": 1500,
    "total_pages": 15
  }
}
```

#### Get Data Summary
```http
GET /health/data/summary?start_date=2024-01-01&end_date=2024-01-15
```

**Response:**
```json
{
  "summary": {
    "heart_rate": {
      "average": 72.5,
      "min": 58,
      "max": 95,
      "count": 1440
    },
    "steps": {
      "total": 125000,
      "average_daily": 8333,
      "count": 15
    },
    "sleep": {
      "average_hours": 7.5,
      "total_nights": 15,
      "quality_score": 8.2
    }
  }
}
```

## Analytics & Insights

### Generate Health Insights

#### Get Insights
```http
GET /analytics/insights?timeframe=7d&categories=activity,sleep,heart
```

**Response:**
```json
{
  "insights": [
    {
      "id": "insight_123",
      "title": "Improved Sleep Pattern",
      "description": "Your sleep quality has improved by 15% over the last week",
      "category": "sleep",
      "severity": "positive",
      "confidence": 0.92,
      "actionable": true,
      "recommendations": [
        "Continue your current sleep routine",
        "Consider adding 30 minutes of exercise"
      ],
      "timestamp": "2024-01-15T10:30:00Z"
    }
  ],
  "summary": {
    "total_insights": 5,
    "positive_insights": 3,
    "negative_insights": 1,
    "neutral_insights": 1
  }
}
```

#### Get Trends
```http
GET /analytics/trends?metric=heart_rate&period=30d
```

**Response:**
```json
{
  "trends": [
    {
      "metric": "heart_rate",
      "direction": "decreasing",
      "change_percentage": -5.2,
      "confidence": 0.88,
      "data_points": [
        {"date": "2024-01-01", "value": 75.2},
        {"date": "2024-01-15", "value": 71.3}
      ]
    }
  ]
}
```

### Anomaly Detection

#### Get Anomalies
```http
GET /analytics/anomalies?severity=high&timeframe=24h
```

**Response:**
```json
{
  "anomalies": [
    {
      "id": "anomaly_123",
      "metric": "heart_rate",
      "value": 120,
      "expected_range": [60, 100],
      "severity": "high",
      "timestamp": "2024-01-15T10:30:00Z",
      "description": "Unusually high heart rate detected",
      "recommendations": [
        "Check if you're experiencing stress",
        "Consider consulting a healthcare provider"
      ]
    }
  ]
}
```

## Predictions & Forecasting

### Health Predictions

#### Get Predictions
```http
GET /predictions?type=heart_rate&horizon=7d
```

**Response:**
```json
{
  "predictions": [
    {
      "type": "heart_rate",
      "predicted_value": 73.5,
      "confidence": 0.85,
      "horizon": "7d",
      "timestamp": "2024-01-22T10:30:00Z",
      "factors": [
        "recent_trend": -2.1,
        "seasonal_pattern": 0.5,
        "activity_level": -1.2
      ]
    }
  ]
}
```

#### Get Health Risk Assessment
```http
GET /predictions/risk-assessment
```

**Response:**
```json
{
  "risk_assessment": {
    "overall_risk": "low",
    "risk_score": 0.15,
    "factors": [
      {
        "factor": "blood_pressure",
        "risk_level": "low",
        "contribution": 0.05
      },
      {
        "factor": "sleep_quality",
        "risk_level": "medium",
        "contribution": 0.10
      }
    ],
    "recommendations": [
      "Maintain current sleep schedule",
      "Continue regular exercise routine"
    ]
  }
}
```

## Recommendations

### Get Personalized Recommendations

#### Health Recommendations
```http
GET /recommendations?categories=exercise,nutrition,sleep
```

**Response:**
```json
{
  "recommendations": [
    {
      "id": "rec_123",
      "title": "Increase Daily Steps",
      "description": "Aim for 10,000 steps daily to improve cardiovascular health",
      "category": "exercise",
      "priority": "high",
      "estimated_impact": 0.25,
      "actionable": true,
      "actions": [
        {
          "type": "goal_setting",
          "target": 10000,
          "unit": "steps",
          "timeframe": "daily"
        }
      ]
    }
  ]
}
```

#### Goal Setting
```http
POST /recommendations/goals
Content-Type: application/json

{
  "type": "steps",
  "target": 10000,
  "unit": "count",
  "timeframe": "daily",
  "start_date": "2024-01-15"
}
```

## User Management

### User Profile

#### Get Profile
```http
GET /user/profile
```

**Response:**
```json
{
  "profile": {
    "id": "user_123",
    "email": "user@example.com",
    "name": "John Doe",
    "age": 35,
    "gender": "male",
    "height": 175,
    "weight": 70,
    "preferences": {
      "notifications": true,
      "data_sharing": false,
      "goal_reminders": true
    },
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

#### Update Profile
```http
PUT /user/profile
Content-Type: application/json

{
  "name": "John Smith",
  "weight": 68,
  "preferences": {
    "notifications": true,
    "data_sharing": true
  }
}
```

### Device Management

#### Get Devices
```http
GET /user/devices
```

**Response:**
```json
{
  "devices": [
    {
      "id": "device_123",
      "name": "Apple Watch Series 9",
      "type": "apple_watch",
      "model": "Series 9",
      "connected": true,
      "last_sync": "2024-01-15T10:30:00Z",
      "capabilities": ["heart_rate", "steps", "sleep"]
    }
  ]
}
```

#### Connect Device
```http
POST /user/devices
Content-Type: application/json

{
  "device_id": "device_456",
  "device_type": "apple_watch",
  "capabilities": ["heart_rate", "steps"]
}
```

## Notifications

### Get Notifications
```http
GET /notifications?unread_only=true
```

**Response:**
```json
{
  "notifications": [
    {
      "id": "notif_123",
      "title": "Health Goal Achieved",
      "message": "Congratulations! You've reached your daily step goal.",
      "type": "achievement",
      "read": false,
      "timestamp": "2024-01-15T10:30:00Z",
      "action_url": "/goals/123"
    }
  ]
}
```

### Mark as Read
```http
PUT /notifications/notif_123/read
```

## Error Handling

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid data format",
    "details": {
      "field": "heart_rate",
      "issue": "Value must be between 30 and 200"
    },
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_123"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTHENTICATION_ERROR` | 401 | Invalid or expired token |
| `AUTHORIZATION_ERROR` | 403 | Insufficient permissions |
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `RESOURCE_NOT_FOUND` | 404 | Requested resource not found |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_SERVER_ERROR` | 500 | Server error |

## Rate Limiting

### Limits
- **Authenticated requests**: 1000 requests per hour
- **Data upload**: 100 requests per minute
- **Analytics queries**: 100 requests per hour
- **Batch operations**: 10 requests per minute

### Headers
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642233600
```

## Webhooks

### Configure Webhook
```http
POST /webhooks
Content-Type: application/json

{
  "url": "https://your-app.com/webhook",
  "events": ["health_data_updated", "insight_generated"],
  "secret": "webhook_secret_123"
}
```

### Webhook Events

#### Health Data Updated
```json
{
  "event": "health_data_updated",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "user_id": "user_123",
    "data_type": "heart_rate",
    "value": 75
  }
}
```

#### Insight Generated
```json
{
  "event": "insight_generated",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "user_id": "user_123",
    "insight_id": "insight_123",
    "title": "Improved Sleep Pattern",
    "category": "sleep"
  }
}
```

## SDK Integration

### Swift SDK

```swift
import HealthAI2030SDK

let client = HealthAIClient(apiKey: "your_api_key")

// Upload health data
let healthData = HealthData(
    type: .heartRate,
    value: 75,
    timestamp: Date()
)

try await client.uploadHealthData(healthData)

// Get insights
let insights = try await client.getInsights(timeframe: .week)
```

### JavaScript SDK

```javascript
import { HealthAIClient } from '@healthai2030/sdk';

const client = new HealthAIClient('your_api_key');

// Upload health data
await client.uploadHealthData({
  type: 'heart_rate',
  value: 75,
  timestamp: new Date()
});

// Get insights
const insights = await client.getInsights({ timeframe: 'week' });
```

## Versioning

### API Versioning
- **Current Version**: v1
- **Version Header**: `X-API-Version: 1`
- **Deprecation Policy**: 12 months notice for breaking changes
- **Backward Compatibility**: Maintained for 24 months

### Version History
- **v1.0**: Initial release (January 2024)
- **v1.1**: Added anomaly detection (March 2024)
- **v1.2**: Added predictions API (June 2024)

## Support

### Documentation
- **API Reference**: https://docs.healthai2030.com/api
- **SDK Documentation**: https://docs.healthai2030.com/sdk
- **Examples**: https://docs.healthai2030.com/examples

### Support Channels
- **Email**: api-support@healthai2030.com
- **Slack**: #api-support
- **Status Page**: https://status.healthai2030.com

### Rate Limits & Quotas
- **Free Tier**: 1,000 requests/month
- **Pro Tier**: 100,000 requests/month
- **Enterprise**: Custom limits

### SLA
- **Uptime**: 99.9%
- **Response Time**: < 200ms (95th percentile)
- **Support Response**: < 4 hours 