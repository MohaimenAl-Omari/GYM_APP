# Exercise & Workout Logging API — contract for the Flutter app

All routes below are inside the existing `Route::prefix('api_v1')` group in
`routes/api.php`. Everything except the two `muscle-groups`/`exercises`
browse endpoints requires `auth:sanctum` (same `Authorization: Bearer <token>`
header the app already sends to `/user/me`).

## Browsing (read-only)

`GET /api_v1/muscle-groups`
Returns all muscle groups.
```json
[
  { "id": 1, "name_en": "Chest", "name_ar": "الصدر", "media": "muscle-groups/xyz.jpg" }
]
```
`media` is a relative storage path — the app builds the full URL as
`{APP_URL}/storage/{media}` (same as the admin panel's `Storage::url()`).

`GET /api_v1/muscle-groups/{id}/exercises` (auth required)
Exercises belonging to that muscle group — every official (admin-curated)
exercise, plus any the *current user* created themselves under this group
(never another user's — see "User-created exercises" below).
```json
[
  {
    "id": 10,
    "muscle_group_id": 1,
    "user_id": null,
    "name_en": "Bench Press",
    "name_ar": "بنش برس",
    "description_en": "...",
    "description_ar": "...",
    "media": "exercises/abc.jpg"
  }
]
```
`user_id: null` = official exercise. A real `user_id` = one of the current
user's own — the app treats that as the signal to show an edit/delete
option and a "custom" badge (it will always equal the logged-in user's own
id, since a user is never shown anyone else's).

`GET /api_v1/exercises/{id}`
Single exercise, same shape as above. 404s if it's a custom exercise
belonging to someone else.

## User-created exercises (auth required)

Lets a user add their own exercise — kept deliberately simple: one `name`
(stored into both `name_en`/`name_ar` — a personal exercise is usually a
proper noun or note that doesn't need separate translations), an optional
description, and an optional photo (no GIF — a user isn't going to have
one). Private to the user who created it; nobody else, including the admin
panel's exercise list, ever sees it.

`GET /api_v1/my-exercises`
Every exercise the current user created, across all muscle groups — powers
the "My Exercises" screen. Same shape as the browse endpoints above.

`POST /api_v1/exercises` — multipart form data
```
muscle_group_id   required, must be a real muscle group
name              required, string
description       optional, string
photo             optional, image file (max 5MB)
```
Returns the created exercise, 201.

`PUT /api_v1/exercises/{id}` — multipart form data, all fields optional
```
muscle_group_id, name, description, photo, remove_photo (bool)
```
403 if this isn't the current user's own exercise (including official
ones — those aren't user-editable at all). Because PHP doesn't populate
`$_FILES` on a real multipart PUT request, send this as a POST with a
spoofed `_method=PUT` field in the form data when a photo is attached
(standard Laravel convention) — the route accepts both.

`DELETE /api_v1/exercises/{id}`
403 if not the owner. 422 (not the equivalent of a generic 500) if the
exercise has already been logged in a workout — same reasoning as
everywhere else in this API: never silently break someone's history.

`GET /api_v1/exercises/{id}/last-performance` (auth required)
The current user's most recent completed set-log for this exercise, used to
pre-fill the logging screen. `null` fields / empty `sets` if they've never
logged it.
```json
{
  "session_date": "2026-07-28",
  "sets": [
    { "set_number": 1, "reps": 10, "weight": 60, "weight_unit": "kg" },
    { "set_number": 2, "reps": 8, "weight": 60, "weight_unit": "kg" }
  ]
}
```

## Workout sessions (auth required)

`GET /api_v1/workout-sessions`
History tab's list view — every session the current user has started, most
recent first. Summary only (no per-set data) so the list stays cheap to load.
```json
[
  {
    "id": 501,
    "date": "2026-08-03",
    "muscle_groups": [{ "id": 1, "name_en": "Chest", "name_ar": "الصدر" }],
    "exercise_count": 3,
    "total_sets": 12,
    "total_volume": 3400
  }
]
```

`GET /api_v1/workout-sessions/{session}`
Full breakdown for one past session — everything `index` returns, plus
`notes` and the exercises/sets actually logged.
```json
{
  "id": 501,
  "date": "2026-08-03",
  "muscle_groups": [{ "id": 1, "name_en": "Chest", "name_ar": "الصدر" }],
  "exercise_count": 3,
  "total_sets": 12,
  "total_volume": 3400,
  "notes": "felt strong today",
  "exercises": [
    {
      "session_exercise_id": 9001,
      "exercise_id": 10,
      "name_en": "Bench Press",
      "name_ar": "بنش برس",
      "gif_url": "exercises/bench-press.gif",
      "media": null,
      "order": 1,
      "sets": [
        { "id": 501, "set_number": 1, "reps": 10, "weight": 60, "weight_unit": "kg", "rest_time": 90 }
      ]
    }
  ]
}
```
Returns 403 if the session doesn't belong to the logged-in user (same
`authorizeSession` check every other session endpoint uses).

`POST /api_v1/workout-sessions`
Starts a session. Request:
```json
{ "muscle_group_ids": [1, 3], "exercise_ids": [10, 14, 22] }
```
`exercise_ids` order is preserved as the session's exercise order. Response
returns the created session with a `session_exercises` array mapping each
exercise to its own id (`session_exercise_id`) — the app uses that id when
logging sets, not the raw `exercise_id`:
```json
{
  "id": 501,
  "date": "2026-08-03",
  "session_exercises": [
    { "id": 9001, "exercise_id": 10, "order": 1 },
    { "id": 9002, "exercise_id": 14, "order": 2 }
  ]
}
```

`POST /api_v1/workout-sessions/{session}/exercises`
Adds an exercise mid-session (user adds one they didn't plan for).
```json
{ "exercise_id": 33 }
```
Response: `{ "id": 9003, "exercise_id": 33, "order": 3 }`

`POST /api_v1/workout-sessions/{session}/sets`
Logs one set immediately (called right when the user taps the checkmark —
no batching, so nothing is lost if the app closes mid-workout).
```json
{
  "session_exercise_id": 9001,
  "set_number": 1,
  "reps": 10,
  "weight": 60,
  "weight_unit": "kg",
  "rest_time": 90
}
```
Response: the created `sets` row, including its `id`.

`PUT /api_v1/workout-sessions/{session}/sets/{set}`
Edit a previously logged set (same body shape as above, partial updates ok).

`DELETE /api_v1/workout-sessions/{session}/sets/{set}`
Remove a logged set.

`PUT /api_v1/workout-sessions/{session}/finish`
Marks the session done. Optional body: `{ "notes": "felt strong today" }`.
Response includes a summary the app shows on the finish screen:
```json
{
  "id": 501,
  "duration_seconds": 2760,
  "total_sets": 14,
  "total_volume": 4200
}
```
`duration_seconds` = now minus the session's `created_at`.
`total_volume` = sum of `reps * weight` across all sets in the session.
Both are cheap to compute server-side from data you already have — the app
doesn't send them.

## Notes for the Laravel side
- `session_exercises.order` already exists in your migration — use it to
  return exercises in the order the user picked them.
- `weight_unit` per set already exists in the `sets` table, so a user who
  switches kg/lbs mid-session doesn't corrupt older sets.
- No new migrations needed — this contract maps onto your existing
  `muscle_groups`, `exercises`, `workout_sessions`, `session_muscle_groups`,
  `session_exercises`, `sets` tables as-is.


### Recoverable set saves (mobile client)

`POST /workout-sessions/{id}/sets` accepts optional `client_request_id`
(32 lowercase hexadecimal characters). The mobile client writes the complete
attempt to secure local storage before sending it. Retries reuse that ID and
payload. A unique index on `(session_exercise_id, client_request_id)` makes
concurrent retries return the same set without duplicating it. Legacy clients
without an ID retain their existing behavior. Session ownership is checked
before resolving a retry.

Run the new `2026_10_04_000000_add_client_request_id_to_sets` migration on the
backend before releasing the updated mobile client.

After an uncertain failure, the exercise displays a retry action and retains
its attempted values after reopening the session. A validation rejection
(422) clears the attempt so the user can correct it. Finishing is blocked on
the client while local attempts are pending. Recovery after an app restart
currently requires connectivity to reopen the server-backed session; this is
not a full offline workout queue. Unconfirmed drafts and edits/deletions of
previously saved sets are not queued.
