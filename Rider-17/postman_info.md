# Registration Endpoint for Postman

## Endpoint URL
```
https://masark-sa.com/api/register
```

## HTTP Method
```
POST
```

## Headers
```
Content-Type: application/json; charset=utf-8
Cache-Control: no-cache
Accept: application/json; charset=utf-8
Access-Control-Allow-Headers: *
Access-Control-Allow-Origin: *
User-Agent: MightyTaxiRiderApp
```

## Request Body
```json
{
  "first_name": "Test",
  "last_name": "User",
  "username": "testuser123",
  "email": "test@example.com",
  "user_type": "rider",
  "contact_number": "1234567890",
  "country_code": "+1",
  "password": "12345678",
  "player_id": ""
}
```

## Important Notes
1. Make sure to set the User-Agent header to "MightyTaxiRiderApp" to bypass Imunify360 bot protection.
2. Change the username and email for each test to ensure uniqueness.
3. A successful response will look like:
```json
{
  "message": "Rider has been save successfully",
  "data": {
    "first_name": "Test",
    "last_name": "User",
    "username": "testuser123",
    "email": "test@example.com",
    "user_type": "rider",
    "contact_number": "1234567890",
    "country_code": "+1",
    "player_id": null,
    "display_name": "Test User",
    "last_actived_at": "2025-05-04T15:05:33.268556Z",
    "updated_at": "2025-05-04T15:05:33.000000Z",
    "created_at": "2025-05-04T15:05:33.000000Z",
    "id": 4,
    "api_token": "1|THXMS4BC96GjybusBefYAMhBhU2iunAvhJrgyL2s",
    "profile_image": "https://masark-sa.com/images/user/1.jpg",
    "roles": [
      {
        "id": 2,
        "name": "rider",
        "guard_name": "web",
        "status": "1",
        "created_at": "2025-01-26T12:35:29.000000Z",
        "updated_at": null,
        "pivot": {
          "model_id": "4",
          "role_id": "2",
          "model_type": "App\\Models\\User"
        }
      }
    ],
    "media": []
  }
}
``` 