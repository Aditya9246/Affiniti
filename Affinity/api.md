# Affiniti API Endpoints

**Base URL:** `https://scoreless-mowing-feisty.ngrok-free.dev`

All requests include:
- `Content-Type: application/json`
- `Authorization: Bearer <JWT token>`
- Timeout: 15 seconds

**Error Handling:**
- `401` → Unauthorized (session expired)
- Other non-2xx → Server error
- Network failure → Network error
- JSON decode failure → Decoding error

---

## 1. GET /users/me

Get the current user's profile.

**Request:** No body.

**Response (200):**
```json
{
  "id": "string",
  "name": "string",
  "photo_url": "string | null",
  "bio": "string | null",
  "interests": ["string"],
  "hobbies": "string | null",
  "skills": ["string"],
  "projects_built": "string | null",
  "looking_to_learn": "string | null",
  "github_url": "string | null",
  "linkedin_url": "string | null"
}
```

---

## 2. POST /users/profile

Create a new user profile (called during onboarding).

**Request Body:**
```json
{
  "id": "string",
  "name": "string",
  "photo_url": null,
  "bio": "string | null",
  "interests": ["string"],
  "hobbies": "string | null",
  "skills": ["string"],
  "projects_built": "string | null",
  "looking_to_learn": "string | null",
  "github_url": "string | null",
  "linkedin_url": "string | null"
}
```

> Note: `id` is sent as `""` from onboarding. `photo_url` is always `null` (photo upload not yet implemented).

**Response (200):** Same `UserProfile` JSON structure as above.

---

## 3. GET /events

List all events.

**Request:** No body.

**Response (200):**
```json
[
  {
    "id": "string",
    "name": "string",
    "date": "2024-01-15T10:00:00Z",
    "location": "string",
    "description": "string",
    "cover_image_url": "string | null",
    "host_name": "string",
    "host_avatar_url": "string | null",
    "rsvp_count": 0,
    "is_rsvped": true
  }
]
```

> `date` must be ISO 8601 format.

---

## 4. GET /events/{id}

Get a single event by ID.

**Request:** No body.

**Response (200):** Single `Event` object (same shape as above).

---

## 5. POST /events

Create a new event.

**Request Body:**
```json
{
  "name": "string",
  "date": "2024-01-15T10:00:00Z",
  "location": "string",
  "description": "string",
  "cover_image_base64": "string | null"
}
```

**Response (200):** Single `Event` object.

---

## 6. POST /events/{id}/rsvp

RSVP to an event with opted-in profile fields.

**Request Body:**
```json
{
  "opted_in_fields": ["name", "bio", "skills"]
}
```

**Response:** 2xx (no body expected).

---

## 7. GET /events/{id}/feed

Get the discovery feed (ranked attendees) for an event.

**Request:** No body.

**Response (200):**
```json
[
  {
    "id": "string",
    "name": "string",
    "photo_url": "string | null",
    "bio": "string | null",
    "interests": ["string"],
    "hobbies": "string | null",
    "skills": ["string"],
    "projects_built": "string | null",
    "looking_to_learn": "string | null",
    "github_url": "string | null",
    "linkedin_url": "string | null",
    "shared_interests": ["string"],
    "status": "string | null",
    "is_bookmarked": true
  }
]
```

---

## 8. GET /events/{id}/matches

Get AI-generated matches for the current user at an event.

**Request:** No body.

**Response (200):**
```json
[
  {
    "id": "string",
    "name": "string",
    "photo_url": "string | null",
    "bio": "string | null",
    "interests": ["string"],
    "skills": ["string"],
    "shared_interests": ["string"],
    "icebreaker": "string | null",
    "is_bookmarked": true,
    "status": "string | null"
  }
]
```

---

## 9. POST /events/{id}/intent

Set the user's networking intent for an event.

**Request Body:**
```json
{
  "intent_text": "string"
}
```

> Max 280 characters.

**Response:** 2xx (no body expected).

---

## 10. POST /events/{id}/status

Set the user's real-time status at an event.

**Request Body:**
```json
{
  "status": "Open to Chat"
}
```

Valid values:
- `"Open to Chat"`
- `"Looking for Group"`
- `"Deep in Work"`
- `"Taking a Break"`

**Response:** 2xx (no body expected).

---

## 11. GET /events/{id}/bookmarks

Get the user's bookmarked attendees for an event.

**Request:** No body.

**Response (200):** Array of `Attendee` objects (same structure as feed response, endpoint 7).

---

## 12. POST /events/{id}/bookmarks/{userId}

Bookmark an attendee.

**Request:** No body.

**Response:** 2xx (no body expected).

---

## 13. DELETE /events/{id}/bookmarks/{userId}

Remove a bookmark.

**Request:** No body.

**Response:** 2xx (no body expected).

---

## JSON Key Convention

All JSON keys use **snake_case**. The Swift models map from camelCase properties to snake_case JSON keys via `CodingKeys` enums.

| Swift Property   | JSON Key           |
|------------------|--------------------|
| photoURL         | photo_url          |
| projectsBuilt    | projects_built     |
| lookingToLearn   | looking_to_learn   |
| githubURL        | github_url         |
| linkedinURL      | linkedin_url       |
| coverImageURL    | cover_image_url    |
| hostName         | host_name          |
| hostAvatarURL    | host_avatar_url    |
| rsvpCount        | rsvp_count         |
| isRsvped         | is_rsvped          |
| sharedInterests  | shared_interests   |
| isBookmarked     | is_bookmarked      |
| coverImageBase64 | cover_image_base64 |
| optedInFields    | opted_in_fields    |
| intentText       | intent_text        |
