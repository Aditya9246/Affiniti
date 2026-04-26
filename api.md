# Affiniti API Reference

All endpoints require `Authorization: Bearer <token>` except `GET /health`.

---

## GET /health

No auth required.

**Response 200**
```json
{ "status": "ok" }
```

---

## GET /users/me

Returns the current user's profile.

**Response 200**
```json
{
  "id": "17913468-d745-4c76-b6a1-980e96cd340a",
  "name": "Nipun Saini",
  "photo_url": "https://example.com/photo.jpg",
  "bio": "I build full-stack software.",
  "interests": ["Python", "AI"],
  "skills": ["Python", "JavaScript"],
  "generalized_summary": "A software engineer passionate about AI and building products."
}
```

---

## POST /users/profile

Creates or updates the current user's profile. Triggers background embedding generation.

**Request body**
```json
{
  "name": "Nipun Saini",
  "photo_url": "https://example.com/photo.jpg",
  "bio": "I build full-stack software.",
  "interests": ["Python", "AI"],
  "hobbies": "Reading, hiking",
  "projects": "Affiniti — networking app for events",
  "skills": ["Python", "JavaScript"],
  "want_to_learn": "Distributed systems",
  "github_url": "https://github.com/nipunsaini",
  "linkedin_url": "https://linkedin.com/in/nipunsaini"
}
```

**Response 202**
```json
{ "status": "profile_saved", "embedding_status": "processing" }
```

---

## GET /events

Returns all events.

**Response 200**
```json
[
  {
    "id": "4f51c2e7-61a1-4cc4-abd3-1eb80995f89d",
    "name": "Hack Night",
    "date": "2026-04-26T18:00:00Z",
    "location": "San Francisco, CA",
    "description": "Come build something cool.",
    "cover_image_url": null,
    "host": {
      "id": "17913468-d745-4c76-b6a1-980e96cd340a",
      "name": "Nipun Saini",
      "photo_url": null
    },
    "rsvp_count": 12,
    "user_rsvped": true
  }
]
```

---

## POST /events

Creates a new event. The creator is automatically RSVP'd.

**Request body**
```json
{
  "name": "Hack Night",
  "date": "2026-04-26T18:00:00Z",
  "location": "San Francisco, CA",
  "description": "Come build something cool.",
  "cover_image_url": null
}
```

**Response 201**
```json
{
  "id": "4f51c2e7-61a1-4cc4-abd3-1eb80995f89d",
  "name": "Hack Night",
  "date": "2026-04-26T18:00:00Z",
  "location": "San Francisco, CA",
  "description": "Come build something cool.",
  "cover_image_url": null,
  "host": {
    "id": "17913468-d745-4c76-b6a1-980e96cd340a",
    "name": "Nipun Saini",
    "photo_url": null
  },
  "rsvp_count": 1,
  "user_rsvped": true
}
```

---

## GET /events/{event_id}

Returns a single event.

**Response 200** — same shape as the event object above.

**Response 404**
```json
{ "detail": "Event not found" }
```

---

## POST /events/{event_id}/rsvp

Creates or updates the current user's RSVP. Triggers background match computation.

**Request body**
```json
{
  "opted_in_fields": ["photo", "bio", "interests", "skills"]
}
```

Valid field names: `photo`, `bio`, `interests`, `hobbies`, `skills`, `projects`, `want_to_learn`, `github_url`, `linkedin_url`

**Response 202**
```json
{ "status": "rsvped" }
```

---

## POST /events/{event_id}/intent

Stores the current user's networking intent and triggers match recomputation. Requires an existing RSVP.

**Request body**
```json
{
  "intent_text": "I want to meet ML engineers working on LLMs."
}
```

**Response 202**
```json
{ "status": "intent_set", "matching": "processing" }
```

**Response 403**
```json
{ "detail": "User not RSVPed to event" }
```

---

## DELETE /events/{event_id}/intent

Clears the current user's intent and triggers match recomputation. Requires an existing RSVP.

**Response 200**
```json
{ "status": "intent_cleared" }
```

---

## GET /events/{event_id}/feed

Returns other RSVP'd attendees ranked by similarity. Requires an existing RSVP and a profile embedding.

**Response 200**
```json
[
  {
    "user_id": "1a84f4b7-afe6-4660-b210-ab3e313f7be0",
    "name": "Aditya",
    "photo_url": null,
    "headline": "I build full-stack software and like meeting other builders.",
    "shared_tags": ["Python", "JavaScript"],
    "status": "open_to_chat",
    "looking_to_meet": true,
    "bookmarked": false,
    "similarity_score": 0.87
  }
]
```

Fields not opted into by the attendee are returned as `null` (scalars) or `[]` (lists).

**Response 422**
```json
{ "detail": "Profile not yet embedded — retry in a moment" }
```

---

## GET /events/{event_id}/matches

Returns stored matches for the current user at the event, sorted by score descending.

**Response 200**
```json
[
  {
    "matched_user_id": "1a84f4b7-afe6-4660-b210-ab3e313f7be0",
    "name": "Aditya",
    "photo_url": null,
    "headline": "I build full-stack software and like meeting other builders.",
    "shared_tags": ["Python", "JavaScript"],
    "icebreaker_text": "What are you most excited to build right now?",
    "score": 0.91
  }
]
```

---

## POST /events/{event_id}/status

Sets the current user's temporary availability status for an event.

**Request body**
```json
{
  "status": "open_to_chat"
}
```

Valid values: `open_to_chat`, `looking_for_group`, `deep_in_work`, `taking_a_break`

**Response 200**
```json
{
  "status": "open_to_chat",
  "expires_at": "2026-04-26T19:00:00Z"
}
```

**Response 422**
```json
{ "detail": "status must be one of ['deep_in_work', 'looking_for_group', 'open_to_chat', 'taking_a_break']" }
```

---

## GET /events/{event_id}/bookmarks

Returns the current user's bookmarked attendees for the event. Returns `[]` for events older than the retention cutoff.

**Response 200**
```json
[
  {
    "user_id": "1a84f4b7-afe6-4660-b210-ab3e313f7be0",
    "name": "Aditya",
    "photo_url": null
  }
]
```

---

## POST /events/{event_id}/bookmarks

Bookmarks another attendee. Idempotent — does nothing if already bookmarked.

**Request body**
```json
{
  "bookmarked_user_id": "1a84f4b7-afe6-4660-b210-ab3e313f7be0"
}
```

**Response 201**
```json
{ "status": "bookmarked" }
```

If already bookmarked, returns `200`:
```json
{ "status": "already_bookmarked" }
```

---

## DELETE /events/{event_id}/bookmarks/{bookmarked_user_id}

Removes a bookmark.

**Response 200**
```json
{ "status": "removed" }
```

**Response 404**
```json
{ "detail": "Bookmark not found" }
```
