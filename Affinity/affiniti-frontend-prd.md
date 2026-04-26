# Affiniti — Frontend PRD
**Platform**: iOS (Swift / SwiftUI)
**Version**: 1.0 — Hackathon MVP
**Last Updated**: 2026-04-25

---

## 1. Overview

Affiniti is an iOS networking app for events and hackathons. This document defines the frontend product requirements: screens, interactions, data dependencies, and acceptance criteria. The frontend communicates with a local FastAPI backend exposed via ngrok or localtunnel.

---

## 2. Goals

- Let users authenticate, build a global profile, and RSVP to events with granular privacy controls
- Surface AI-generated match recommendations and icebreakers inside each event
- Allow real-time status broadcasting and per-event bookmarking
- Deliver a demo-ready, two-phone experience for a hackathon setting

---

## 3. Tech Stack

| Layer | Choice |
|---|---|
| UI Framework | SwiftUI |
| Auth | Auth0 iOS SDK (Universal Login, JWT) |
| Networking | URLSession (async/await) |
| State Management | `@StateObject` / `@EnvironmentObject` / `ObservableObject` |
| Image Loading | AsyncImage (native) |
| Backend URL | Hardcoded ngrok URL or runtime settings screen |

---

## 4. Screens & User Flows

### 4.1 Auth Flow

**Screens**: Splash → Auth0 Universal Login → (first-time) Onboarding → Home

**Splash Screen**
- Show Affiniti wordmark and logo
- Check for a stored JWT in Keychain
  - Valid token → navigate to Home
  - No token or expired → navigate to Auth0 login

**Auth0 Login**
- Launch Auth0 Universal Login via SDK
- On success, store JWT in Keychain and decode user ID
- On first login (no profile record found via `GET /users/me`), navigate to Onboarding
- On returning login, navigate to Home

**Acceptance criteria**:
- Token is stored in Keychain, never in UserDefaults
- Auth0 logout clears the token and returns user to Splash

---

### 4.2 Onboarding — Global Profile Setup

**Screen**: Multi-step form, one field group per step

**Steps**:

| Step | Fields |
|---|---|
| 1 — Basics | Name (required), Photo (camera or library), Bio (multi-line, 300 char max) |
| 2 — Interests & Hobbies | Interests (tag picker, free-add), Hobbies (free text) |
| 3 — Work | Skills / Tech Stack (tag picker), Projects Built (multi-line free text) |
| 4 — Goals | "What I'm looking to learn" (multi-line free text) |
| 5 — Social | GitHub URL, LinkedIn URL (both optional) |

**Behavior**:
- Progress indicator across top (step N of 5)
- "Continue" advances; "Back" goes to previous step
- Step 1 is the only required step — all others can be skipped
- On final step submit, `POST /users/profile` is called with all collected fields
- A non-blocking banner appears: "Affiniti is personalizing your profile in the background" (Gemma4 is running server-side — no spinner gate)
- Navigate to Home immediately after submit

**Acceptance criteria**:
- Photo upload works (multipart or base64 depending on API)
- Partial profiles (skipped steps) are accepted by the API
- User cannot reach Home until Step 1 (name) is submitted

---

### 4.3 Home — Event List

**Screen**: Scrollable list of events

**Sections**:
1. **Your Events** — events the user has RSVPed to (horizontal scroll card strip)
2. **Open Events** — all browsable events (vertical list)

**Event Card (list)**:
- Cover image, event name, date, location, RSVP count

**Behavior**:
- Tap a card → Event Detail screen
- FAB (floating action button) → Create Event sheet
- Pull-to-refresh re-fetches events

**Acceptance criteria**:
- Events load via `GET /events`
- "Your Events" strip only shows events where `rsvps.user_id = current_user`

---

### 4.4 Event Detail

**Screen**: Event header + action area

**Contents**:
- Cover image (hero, top)
- Event name, date, time, location
- Host name + avatar
- Description
- Attendee count
- "Join Event" button (if not RSVPed) or "View Event" button (if RSVPed)

**Behavior**:
- "Join Event" → opens Privacy Opt-In sheet (see 4.5)
- "View Event" → navigates to Event Hub (see 4.6)

**Acceptance criteria**:
- Data loaded via `GET /events/{event_id}`
- RSVP state reflected accurately without manual refresh

---

### 4.5 Privacy Opt-In Sheet (Modal)

**Trigger**: Tapping "Join Event" on Event Detail

**Contents**:
- Header: "Choose what to share with attendees at [Event Name]"
- Toggle list of profile fields:
  - Photo (default ON)
  - Bio (default ON)
  - Interests (default ON)
  - Hobbies (default ON)
  - Projects Built (default OFF)
  - Skills / Tech Stack (default ON)
  - "What I'm looking to learn" (default ON)
  - GitHub / LinkedIn links (default OFF)
- "Confirm & Join" button

**Behavior**:
- On confirm, `POST /events/{event_id}/rsvp` with opted-in field list
- Sheet dismisses; Event Detail transitions to "View Event" state

**Acceptance criteria**:
- Opted-in fields are serialized as a JSON list in the request body
- Toggle state is preserved if user returns to the sheet before confirming

---

### 4.6 Event Hub

**Screen**: Tab-based view scoped to a single event

**Tabs**:

| Tab | Description |
|---|---|
| Feed | Ranked attendee discovery feed |
| Matches | AI-matched top 4 recommendations |
| To Meet | Bookmarked attendees |
| My Status | Current availability status controls |

---

### 4.7 Discovery Feed Tab

**Contents**: Vertically scrollable list of attendee cards

**Attendee Card**:
- Avatar, name, headline (first skill or bio excerpt)
- Top 3 shared interest tags (highlighted)
- Live availability status badge
- "Save" button (bookmark)

**Ranking**: Determined server-side (vector similarity + intent boost). Frontend renders in received order.

**Intent Banner** (sticky, top of feed):
- "What do you want to learn today?" prompt
- Tap → Intent Input sheet (see 4.9)
- If intent is set: shows current intent text with an edit icon and "Clear" button

**Behavior**:
- Tap a card → Attendee Profile sheet (see 4.10)
- Pull-to-refresh re-fetches ranked feed via `GET /events/{event_id}/feed`

**Acceptance criteria**:
- Feed re-fetches and re-ranks when intent is set or cleared
- "Save" toggles bookmark state optimistically and confirms via API

---

### 4.8 Matches Tab

**Contents**: Up to 4 AI-match cards (hard cap)

**Match Card** (larger than feed card):
- Avatar, name, headline
- Shared tags
- AI-generated icebreaker text (displayed as a quote block)
- "View Profile" button

**Behavior**:
- Data fetched from `GET /events/{event_id}/matches`
- Matches re-fetch on pull-to-refresh or when intent changes

**Empty state**: "Your matches will appear once more people RSVP to this event."

**Acceptance criteria**:
- Icebreaker text is displayed exactly as returned by the API (no truncation)
- Hard cap of 4 cards enforced on the frontend as a guard

---

### 4.9 Intent Input Sheet (Modal)

**Trigger**: Tapping the intent banner on the Feed tab

**Contents**:
- Large multi-line text field: "What do you want to learn or find today?"
- Placeholder examples: "I want to learn about RAG pipelines" / "Looking for someone who knows circuit design"
- Character limit: 280 characters
- "Set Intent" button

**Behavior**:
- On submit: `POST /events/{event_id}/intent` with `{ "intent_text": "..." }`
- Sheet dismisses; Feed and Matches tabs re-fetch in the background
- Intent persists for the duration of the event (cleared server-side on event end)

**Acceptance criteria**:
- Submit is disabled if text field is empty
- Success triggers background re-fetch of feed and matches without blocking UI

---

### 4.10 Attendee Profile Sheet (Modal)

**Trigger**: Tapping any attendee card in Feed or Matches

**Contents**:
- Avatar (large), name, availability status
- Bio
- Shared interest tags (highlighted) + all other opted-in tags
- Icebreaker message (if coming from Matches tab)
- Projects, skills, "what I want to learn" (if user opted in)
- GitHub / LinkedIn link buttons (if opted in)
- Bookmark button in nav bar

**Acceptance criteria**:
- Only fields the attendee opted into sharing for this event are shown
- Icebreaker shown only if navigating from Matches; hidden otherwise

---

### 4.11 My Status Tab

**Contents**: Status picker

**Status options**:
- Open to Chat
- Looking for Group
- Deep in Work
- Taking a Break

**UI**: Large segmented control or card-based single-select

**Behavior**:
- Selecting a status immediately calls `POST /events/{event_id}/status` with `{ "status": "..." }`
- Current status highlighted; last-updated timestamp shown below
- Status auto-reverts server-side (TTL managed by backend); frontend shows a countdown if TTL is returned in the API response

**Acceptance criteria**:
- Status update is reflected immediately (optimistic update)
- If API call fails, status reverts to previous selection with an error toast

---

### 4.12 To Meet Tab

**Contents**: Bookmarked attendee cards for this event

**Card**: Same as Feed card, with a "Remove" swipe action

**Empty state**: "Tap the bookmark icon on any attendee card to save them here."

**Behavior**:
- Data from `GET /events/{event_id}/bookmarks`
- Swipe-to-delete calls `DELETE /events/{event_id}/bookmarks/{user_id}`

**Acceptance criteria**:
- Bookmark state is consistent across Feed, Matches, and To Meet tabs
- List is empty after event ends + 7 days (server enforced; frontend shows empty state)

---

### 4.13 Create Event Sheet (Modal)

**Trigger**: FAB on Home screen

**Fields**:
- Event name (required)
- Date & time (date picker)
- Location (text field)
- Description (multi-line)
- Cover image (camera or library, optional)

**Behavior**:
- Submit calls `POST /events`
- On success, sheet dismisses and Home list refreshes

**Acceptance criteria**:
- Name is required; form does not submit without it
- Created event appears immediately in "Your Events" strip

---

### 4.14 Settings Screen

**Access**: Profile/avatar tap from Home nav bar

**Contents**:
- Edit Global Profile (navigates back to Onboarding flow in edit mode)
- Backend URL override (for demo: text field to paste ngrok URL)
- Logout (clears Keychain token, returns to Splash)

---

## 5. Navigation Architecture

```
Splash
  └── Auth0 Login
        ├── Onboarding (first-time only)
        └── Home (TabView or NavigationStack)
              ├── Event List
              │     ├── Event Detail
              │     │     └── Privacy Opt-In Sheet (modal)
              │     └── Create Event Sheet (modal)
              └── [Per-event] Event Hub (TabView)
                    ├── Feed Tab
                    │     ├── Intent Input Sheet (modal)
                    │     └── Attendee Profile Sheet (modal)
                    ├── Matches Tab
                    │     └── Attendee Profile Sheet (modal)
                    ├── To Meet Tab
                    └── My Status Tab
```

---

## 6. Networking

**Base URL**: Configured at runtime (hardcoded ngrok URL or Settings screen override)

**Auth header**: All requests include `Authorization: Bearer <JWT>`

**Error handling**:
- 401 → clear token, redirect to Splash
- 5xx → show error toast; do not crash
- Network timeout → show retry prompt

**Request pattern**: All network calls use async/await with `URLSession.shared.data(for:)`

---

## 7. State Management

| Scope | Mechanism |
|---|---|
| Auth token | Keychain |
| Current user profile | `@EnvironmentObject UserSession` |
| Event list | `@StateObject EventListViewModel` |
| Per-event state (feed, matches, status, bookmarks) | `@StateObject EventHubViewModel` |
| Transient UI state (sheet open, loading) | `@State` local to view |

---

## 8. Offline & Edge Cases

- No offline mode in MVP; all data is live from API
- If backend tunnel is down: show a persistent banner "Can't reach Affiniti server — check your connection"
- Empty states required for: Feed (no attendees), Matches (too few RSVPs), To Meet (no bookmarks)

---

## 9. Accessibility

- All interactive elements have `.accessibilityLabel`
- Dynamic Type supported on all text elements
- Minimum tap target: 44x44pt
- VoiceOver traversal order follows visual layout

---

## 10. Demo Constraints (Hackathon MVP)

- Backend URL is hardcoded or set via Settings screen — no service discovery
- Two physical phones required for the full demo flow
- Auth0 tenant is shared; both demo accounts must be pre-created
- Gemma4 profile generalization runs asynchronously — the app does not wait for it before navigating forward
- No push notifications; feed refresh is pull-to-refresh only
