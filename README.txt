SMART GEO-TAGGED LANDMARKS - CSE 489 Lab Exam (v5)
Student ID: 24341248

PROJECT OVERVIEW

Smart Geo-Tagged Landmarks is a Flutter Android app that lets users discover,
visit, and manage location-based landmarks pulled from a faculty-provided REST API. 
It displays landmarks on an interactive map and in a sortable/filterable list, 
supports asynchronous visit tracking with background job polling via WorkManager, 
and works fully offline through local SQLite caching and a queued-sync mechanism 
that resumes once connectivity returns.

FEATURES IMPLEMENTED

- Landmarks fetched from the faculty API and displayed with title, image, score
- Map view (OpenStreetMap) centered on Bangladesh, markers colored by score
- Visit flow: GPS capture -> visit_landmark -> job_id -> background polling
  via WorkManager -> distance shown once done
- Landmarks list with sort-by-score and minimum-score filter
- Activity screen showing visit history with status (queued/pending/done/failed)
- Add Landmark with GPS auto-fill and image upload (multipart/form-data)
- Soft delete / restore support
- Offline support: SQLite cache for landmarks, offline visit queue that
  syncs automatically when connectivity returns
- Bottom navigation with Map / Landmarks / Activity / Add-View tabs

API USAGE

Base: https://labs.anontech.info/cse489/exm3/api.php
Every request includes ?key=24341248
Endpoints used: get_landmarks, visit_landmark, get_job_status,
create_landmark (multipart), delete_landmark, restore_landmark

OFFLINE STRATEGY

SQLite (sqflite) is the single source of truth for landmarks. On every
successful fetch the cache is replaced; the UI always reads from the
cache first so it works with no network. Visits made while offline are
inserted into a local "queued" state and drained by a WorkManager task
once connectivity returns (see architecture below).

ARCHITECTURE USED

Repository pattern: LandmarkRepository is the only class the UI talks to.
It decides network-vs-cache and hides that decision from the screens.
WorkManager runs a periodic task (15 min, Android's minimum) that drains
the offline queue and re-checks any pending jobs, plus fast chained
one-off tasks (~5-8s) for near-real-time polling right after a visit is
submitted. This satisfies Requirement 10 with a single background-work
mechanism reused for both polling and offline sync.

CHALLENGES FACED

Image upload format: The API silently fails to receive images ($_FILES empty) 
if uploaded as raw JSON; had to switch to multipart/form-data requests specifically 
for the create-landmark flow.
Offline-first data flow: Making the app show cached data instantly while refreshing 
from the network in the background, and correctly queuing visit requests made offline 
for later sync, without duplicate or lost entries.
Soft-delete consistency: Ensuring deleted landmarks disappeared from the local cache 
without extra tracking logic, since the API's get_landmarks endpoint only returns active 
records.
