# DIGITAL HOARDING SYSTEM
# IMPLEMENTATION_PLAN.md

> This document is the authoritative implementation plan for Claude Code.
>
> **IMPORTANT:** Follow the architecture, technology choices, database design, API contracts, and development phases defined here. Do not replace technologies or redesign the architecture unless explicitly instructed by the project owner.

---

# 1. PROJECT OBJECTIVE

Build a personal digital content management system focused on **digital hoarding research**.

The system allows users to:

1. Save URLs from mobile and PC.
2. Automatically extract metadata.
3. Generate an AI summary.
4. Automatically classify content into a hierarchical 3-level category tree.
5. Store URLs and metadata without downloading the actual video/audio.
6. Track user interactions with saved content.
7. Identify recently interacted and forgotten content.
8. Display content through embedded/oEmbed views.
9. Collect behavioral data that can later be used for digital hoarding research.

The core loop is:

```text
SAVE
  ↓
PROCESS
  ↓
CLASSIFY
  ↓
STORE
  ↓
OPEN
  ↓
TRACK INTERACTION
  ↓
IDENTIFY FORGOTTEN CONTENT
```

---

# 2. NON-GOALS

The initial system MUST NOT:

- Download videos.
- Download audio.
- Store large media files.
- Build a recommendation algorithm.
- Use MongoDB.
- Use Redis unless a concrete requirement appears.
- Use React for the initial frontend.
- Build a mobile native application.
- Build a complex event-driven microservice architecture.
- Automatically delete old user content.
- Automatically merge categories without validation.

---

# 3. TECHNOLOGY STACK

## 3.1 Main Backend

```text
Java 21
Spring Boot
Spring Security
Spring Data JPA
Maven
```

Spring Boot is the primary backend and business-logic layer.

---

## 3.2 Processing Service

```text
Python 3.x
FastAPI
yt-dlp
LLM API
```

FastAPI is responsible only for Python-specific processing.

It must NOT become the main application backend.

---

## 3.3 Database

```text
Supabase PostgreSQL
```

Use PostgreSQL as the single source of truth.

Do NOT introduce MongoDB.

---

## 3.4 Authentication

```text
Supabase Auth
JWT
Spring Security
```

Supabase handles authentication.

Spring Boot validates the JWT and applies application authorization.

---

## 3.5 Frontend

Initial frontend:

```text
HTML
CSS
Vanilla JavaScript
```

Do not introduce React/Vue/Angular for the initial version.

---

## 3.6 Mobile Input

```text
PWA
Web Share Target API
```

---

## 3.7 PC Input

```text
Chrome Extension
Manifest V3
JavaScript
```

---

## 3.8 Deployment

Target:

```text
Google Cloud Run
Supabase
Google Cloud Scheduler
```

Deployment should happen only after the local MVP is stable.

---

# 4. HIGH-LEVEL ARCHITECTURE

```text
                    ┌─────────────────┐
                    │     MOBILE      │
                    │       PWA       │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │       PC        │
                    │ Chrome Extension│
                    └────────┬────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │    SPRING BOOT     │
                  │                     │
                  │ Authentication      │
                  │ Video API            │
                  │ Category API         │
                  │ Interaction API      │
                  │ Business Logic       │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │      FASTAPI        │
                  │                     │
                  │ Metadata Extraction │
                  │ AI Processing       │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ SUPABASE POSTGRESQL │
                  │                     │
                  │ users               │
                  │ videos              │
                  │ categories          │
                  │ interactions        │
                  └─────────────────────┘
```

---

# 5. CORE ARCHITECTURAL RULES

## Rule 1 — Spring Boot is the main backend

All public application APIs must go through Spring Boot.

Frontend must NOT directly manipulate database tables.

Preferred:

```text
Frontend
   ↓
Spring Boot
   ↓
PostgreSQL
```

Not:

```text
Frontend
   ↓
Supabase database
```

The frontend may use Supabase Auth for authentication if necessary, but business data access must remain behind Spring Boot.

---

## Rule 2 — FastAPI is a processing service

FastAPI handles:

```text
URL
 ↓
metadata extraction
 ↓
AI classification
```

It must not contain the main user/business authorization logic.

---

## Rule 3 — PostgreSQL is the source of truth

Do not duplicate important application state between databases.

---

## Rule 4 — Do not download media

Only retrieve metadata.

Allowed:

```text
title
description
hashtags
thumbnail URL
platform
```

Not allowed:

```text
video file
audio file
```

---

## Rule 5 — Keep research history

Interaction records should be treated as historical data.

Do not overwrite interaction history.

---

# 6. DATABASE DESIGN

## 6.1 Users

Authentication is managed by Supabase Auth.

Application tables reference:

```text
auth.users.id
```

Do not create a second password/authentication system.

---

# 6.2 videos

```sql
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    url TEXT NOT NULL,

    platform VARCHAR(50),

    title TEXT,

    description TEXT,

    summary TEXT,

    category_id UUID,

    status VARCHAR(30) NOT NULL DEFAULT 'PROCESSING',

    saved_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    first_opened_at TIMESTAMP WITH TIME ZONE,

    last_opened_at TIMESTAMP WITH TIME ZONE,

    deleted_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

---

# 6.3 categories

Categories are hierarchical.

```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(255) NOT NULL,

    parent_id UUID,

    level INTEGER NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_id)
        REFERENCES categories(id)
);
```

Rules:

```text
level 1 → parent_id = NULL

level 2 → parent_id points to level 1

level 3 → parent_id points to level 2
```

Maximum initial depth:

```text
3 levels
```

Do not create arbitrary depth unless explicitly required later.

---

# 6.4 video_interactions

```sql
CREATE TABLE video_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL,

    video_id UUID NOT NULL,

    action VARCHAR(50) NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_interaction_video
        FOREIGN KEY (video_id)
        REFERENCES videos(id)
);
```

Initial actions:

```text
SAVED
OPENED
REOPENED
DELETED
```

---

# 7. DATABASE INDEXES

Create indexes for frequently queried fields.

Required:

```sql
CREATE INDEX idx_videos_user_id
ON videos(user_id);

CREATE INDEX idx_videos_category_id
ON videos(category_id);

CREATE INDEX idx_videos_last_opened_at
ON videos(last_opened_at);

CREATE INDEX idx_videos_saved_at
ON videos(saved_at);

CREATE INDEX idx_interactions_video_id
ON video_interactions(video_id);

CREATE INDEX idx_interactions_user_id
ON video_interactions(user_id);

CREATE INDEX idx_categories_parent_id
ON categories(parent_id);
```

---

# 8. VIDEO STATUS

Video processing state:

```text
PROCESSING
COMPLETED
FAILED
```

Flow:

```text
POST /api/videos
        ↓
PROCESSING
        ↓
FastAPI
        ↓
success
        ↓
COMPLETED
```

Failure:

```text
PROCESSING
        ↓
FAILED
```

Do not silently leave records stuck in `PROCESSING`.

---

# 9. SPRING BOOT PACKAGE STRUCTURE

```text
src/main/java/<base-package>/

├── auth/
│   ├── controller/
│   ├── service/
│   ├── security/
│   └── dto/
│
├── video/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── category/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
├── interaction/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── entity/
│   └── dto/
│
└── common/
    ├── exception/
    ├── config/
    └── response/
```

Do not put all classes into one package.

---

# 10. ENTITY RELATIONSHIPS

## Video

```text
Video
 ├── userId
 └── category
```

## Category

```text
Category
 ├── parent
 └── children
```

This is a self-referencing relationship.

Example:

```java
@ManyToOne
@JoinColumn(name = "parent_id")
private Category parent;

@OneToMany(mappedBy = "parent")
private List<Category> children;
```

Do not blindly expose the entire entity graph through JSON.

Use DTOs.

---

# 11. DTO RULE

Do not return JPA entities directly from controllers.

Use:

```text
Request DTO
Response DTO
```

Example:

```text
CreateVideoRequest
VideoResponse
CategoryResponse
CategoryTreeResponse
InteractionResponse
```

---

# 12. API CONTRACT

## 12.1 Create video

```http
POST /api/videos
Authorization: Bearer <JWT>
Content-Type: application/json
```

Request:

```json
{
  "url": "https://www.youtube.com/watch?v=..."
}
```

Response:

```json
{
  "id": "...",
  "url": "...",
  "status": "PROCESSING"
}
```

---

# 13. GET VIDEOS

```http
GET /api/videos
Authorization: Bearer <JWT>
```

Return only the current user's non-deleted videos.

---

# 14. GET VIDEO

```http
GET /api/videos/{id}
Authorization: Bearer <JWT>
```

Must verify ownership.

---

# 15. DELETE VIDEO

```http
DELETE /api/videos/{id}
Authorization: Bearer <JWT>
```

Use soft delete:

```text
deleted_at = NOW()
```

Do not physically delete the record.

---

# 16. OPEN VIDEO

```http
POST /api/videos/{id}/open
Authorization: Bearer <JWT>
```

Transaction:

```text
1. Verify ownership.
2. Verify video is not deleted.
3. If first open:
      first_opened_at = NOW()
4. last_opened_at = NOW()
5. Create interaction record.
6. Return updated video.
```

First action:

```text
SAVED
```

First open:

```text
OPENED
```

Subsequent opens:

```text
REOPENED
```

---

# 17. CATEGORY API

## Get all categories

```http
GET /api/categories
```

---

## Get category tree

```http
GET /api/categories/tree
```

Response example:

```json
[
  {
    "id": "...",
    "name": "Học tập",
    "level": 1,
    "children": [
      {
        "id": "...",
        "name": "IELTS",
        "level": 2,
        "children": [
          {
            "id": "...",
            "name": "Speaking",
            "level": 3,
            "children": []
          }
        ]
      }
    ]
  }
]
```

---

# 18. CATEGORY VIDEO API

```http
GET /api/categories/{id}/videos
```

Return videos belonging to that category.

Optional future parameter:

```text
includeDescendants=true
```

Example:

```text
IELTS
 ↓
Speaking
Vocabulary
```

If:

```text
includeDescendants=true
```

return videos from all descendants.

---

# 19. RECENTLY INTERACTED API

```http
GET /api/videos/recent
```

Sort:

```text
last_opened_at DESC
```

---

# 20. FORGOTTEN API

```http
GET /api/videos/forgotten
```

Initial definition:

```text
last_opened_at older than 30 days
```

Also include:

```text
never opened
```

Never-opened videos should be handled explicitly.

Do not treat:

```text
last_opened_at = NULL
```

as a normal timestamp.

---

# 21. FASTAPI API

Internal service endpoint:

```http
POST /process
```

Request:

```json
{
  "video_id": "...",
  "url": "..."
}
```

Response:

```json
{
  "video_id": "...",
  "title": "...",
  "description": "...",
  "hashtags": [],
  "summary": "...",
  "level1": "...",
  "level2": "...",
  "level3": "..."
}
```

FastAPI should not decide which user owns the video.

Spring Boot remains responsible for authorization.

---

# 22. METADATA EXTRACTION

Use:

```text
yt-dlp
```

Extract only metadata.

Expected fields:

```text
title
description
hashtags
platform
thumbnail_url
```

If metadata extraction fails:

```text
status = FAILED
```

Return a meaningful error.

Do not expose stack traces to users.

---

# 23. AI CLASSIFICATION

LLM output must follow strict JSON.

Required:

```json
{
  "summary": "string",
  "level1": "string",
  "level2": "string",
  "level3": "string"
}
```

Prompt must instruct the model:

```text
Return JSON only.
Do not include markdown.
Do not include explanations outside JSON.
```

Validate the returned JSON before saving.

---

# 24. CATEGORY RESOLUTION

AI output:

```text
level1 = Học tập
level2 = IELTS
level3 = Speaking
```

Backend performs:

```text
Find/create Level 1
        ↓
Find/create Level 2 under Level 1
        ↓
Find/create Level 3 under Level 2
```

Important:

Category names alone are NOT enough.

This is incorrect:

```text
find category where name = "Speaking"
```

Correct:

```text
find Speaking
WHERE parent_id = IELTS_ID
```

This prevents unrelated branches from being merged.

---

# 25. CATEGORY NORMALIZATION

Do not run normalization on every request.

Run periodically.

Initial strategy:

```text
Cloud Scheduler
       ↓
normalization endpoint
       ↓
find suspicious duplicates
       ↓
LLM suggests merge
       ↓
validate
       ↓
merge
```

Automatic merging must be conservative.

Do not allow the LLM to directly modify the database.

Preferred:

```text
LLM
 ↓
suggestion
 ↓
backend validation
 ↓
database update
```

---

# 26. AUTHENTICATION

Authentication flow:

```text
Frontend
    ↓
Supabase Auth
    ↓
JWT
    ↓
Spring Boot
    ↓
Spring Security
    ↓
extract user ID
    ↓
business logic
```

Never trust:

```json
{
  "user_id": "someone-else"
}
```

from frontend requests.

The authenticated user ID must come from the validated JWT.

---

# 27. AUTHORIZATION

Every user-owned endpoint must verify:

```text
resource.user_id == authenticatedUserId
```

Example:

```text
User A requests Video B

Video B belongs to User B

→ 403 / 404 according to API security policy
```

Do not expose another user's data.

---

# 28. RLS

Supabase PostgreSQL should have RLS enabled for user-owned data.

At minimum:

```text
videos
video_interactions
```

must be protected.

Category access should be designed carefully because categories may be:

```text
global
or
user-specific
```

Initial recommendation:

```text
categories = user-scoped
```

unless the research design later requires globally shared categories.

---

# 29. FRONTEND STRUCTURE

```text
frontend/

├── index.html
├── login.html
├── video.html
│
├── css/
│   ├── global.css
│   ├── dashboard.css
│   └── video.css
│
├── js/
│   ├── api.js
│   ├── auth.js
│   ├── dashboard.js
│   ├── category-tree.js
│   └── video.js
│
└── manifest.json
```

---

# 30. DASHBOARD

Main layout:

```text
┌─────────────────────────────────────────┐
│              Digital Hoarding           │
├─────────────────────────────────────────┤
│ Recently Interacted                     │
│                                         │
│ [content] [content] [content]           │
├─────────────────────────────────────────┤
│ Forgotten Content                       │
│                                         │
│ [content] [content] [content]           │
├─────────────────────────────────────────┤
│ All Categories                          │
│                                         │
│ ▼ Học tập                               │
│    ▼ IELTS                              │
│       ├── Speaking                      │
│       └── Vocabulary                    │
│    ▼ Toán                               │
└─────────────────────────────────────────┘
```

---

# 31. CATEGORY TREE RENDERING

Use recursive JavaScript.

Concept:

```text
renderCategory(category)
    ↓
render category name
    ↓
for each child
    ↓
renderCategory(child)
```

Do not hard-code:

```text
IELTS
Speaking
Vocabulary
```

The UI must be generated from API data.

---

# 32. VIDEO VIEW PAGE

Layout:

```text
┌─────────────────────────────┐
│ Embedded Content            │
│                             │
│                             │
└─────────────────────────────┘

Học tập › IELTS › Speaking

Summary:
...

Related content:

[content]
[content]
[content]
```

---

# 33. OEmbed

Supported platforms initially:

```text
YouTube
TikTok
```

Do not download media.

The frontend/backend should use official embedding/oEmbed mechanisms where available.

---

# 34. INTERACTION MODEL

Every meaningful interaction should be recorded.

Initial:

```text
SAVE
OPENED
REOPENED
DELETED
```

Example:

```text
User saves video
→ SAVED

User opens for first time
→ OPENED

User opens again
→ REOPENED
```

Do not update the old interaction record.

Create a new record.

---

# 35. RESEARCH METRICS

Store raw events first.

Calculate metrics later.

Potential metrics:

```text
total_saved
total_opened
never_opened
forgotten
reopened
average_time_to_first_open
average_reopen_count
```

Do not store derived metrics as primary truth unless necessary.

Raw interaction data is more valuable.

---

# 36. PHASE 0 — PROJECT SETUP

Tasks:

- Create repository.
- Create Spring Boot project.
- Create FastAPI project.
- Create frontend directory.
- Configure Git.
- Create `.gitignore`.
- Create `.env.example`.
- Configure local PostgreSQL/Supabase connection.
- Document environment variables.

Expected structure:

```text
project-root/

├── backend/
├── processing-service/
├── frontend/
├── chrome-extension/
├── database/
├── docs/
└── IMPLEMENTATION_PLAN.md
```

---

# 37. PHASE 1 — DATABASE

Implement:

```text
videos
categories
video_interactions
```

Tasks:

- Create SQL migrations.
- Add foreign keys.
- Add indexes.
- Add constraints.
- Test category self-reference.
- Test video/category relationship.
- Test interaction/video relationship.

Deliverable:

```text
Database schema works independently.
```

---

# 38. PHASE 2 — SPRING BOOT FOUNDATION

Implement:

```text
Video entity
Category entity
VideoInteraction entity
```

Implement:

```text
Repository
Service
Controller
DTO
Exception handling
```

Create:

```text
GET /api/videos
POST /api/videos
GET /api/videos/{id}
DELETE /api/videos/{id}
```

At this phase AI is NOT required.

Use mocked processing state if necessary.

---

# 39. PHASE 3 — AUTHENTICATION

Implement:

```text
Supabase Auth
JWT validation
Spring Security
```

Tasks:

- Validate JWT.
- Extract user ID.
- Create authenticated principal.
- Protect APIs.
- Remove client-provided ownership assumptions.
- Test two different users.

Acceptance test:

```text
User A cannot access User B's videos.
```

---

# 40. PHASE 4 — CATEGORY SYSTEM

Implement:

```text
CategoryService
CategoryController
CategoryRepository
```

Features:

```text
create category
find category
find children
build tree
find/create category path
```

Acceptance test:

```text
Học tập
└── IELTS
    └── Speaking
```

must be represented correctly.

---

# 41. PHASE 5 — FASTAPI

Implement:

```text
POST /process
```

Implement metadata extraction.

Test URLs from supported platforms.

Acceptance:

```text
URL
 ↓
title
description
hashtags
platform
```

No video/audio download.

---

# 42. PHASE 6 — AI

Implement AI service.

Tasks:

- Create prompt.
- Force JSON output.
- Validate response.
- Handle malformed response.
- Handle API timeout.
- Handle rate limits.
- Handle empty metadata.

Acceptance:

```text
URL
 ↓
metadata
 ↓
summary
 ↓
level1
level2
level3
```

---

# 43. PHASE 7 — SPRING BOOT ↔ FASTAPI

Connect the services.

Flow:

```text
POST /api/videos
        ↓
Spring Boot
        ↓
Create PROCESSING video
        ↓
FastAPI
        ↓
Metadata + AI
        ↓
Spring Boot/database update
        ↓
COMPLETED
```

Do not expose FastAPI directly to the frontend.

---

# 44. PHASE 8 — INTERACTION TRACKING

Implement:

```text
POST /api/videos/{id}/open
```

Track:

```text
SAVED
OPENED
REOPENED
```

Implement:

```text
first_opened_at
last_opened_at
```

Acceptance:

```text
Save
→ SAVED

First open
→ OPENED

Second open
→ REOPENED
```

---

# 45. PHASE 9 — FORGOTTEN CONTENT

Implement:

```text
GET /api/videos/recent
GET /api/videos/forgotten
```

Initial forgotten definition:

```text
never opened
OR
last opened >= 30 days ago
```

Keep threshold configurable.

Do not hard-code `30` in multiple places.

---

# 46. PHASE 10 — FRONTEND

Implement:

```text
Login
Dashboard
Category tree
Recent content
Forgotten content
Video detail
```

Frontend communicates with Spring Boot API.

---

# 47. PHASE 11 — OEmbed

Implement content display.

Supported:

```text
YouTube
TikTok
```

Handle unsupported URLs gracefully.

---

# 48. PHASE 12 — PWA

Add:

```text
manifest.json
service worker
Web Share Target
```

Implement:

```text
Share
 ↓
PWA
 ↓
URL
 ↓
Spring Boot
```

Test on mobile.

---

# 49. PHASE 13 — CHROME EXTENSION

Manifest V3.

Features:

```text
Click extension
 ↓
Get active tab URL
 ↓
Send to backend
```

Do not implement unnecessary browser permissions.

Only request permissions that are actually required.

---

# 50. PHASE 14 — CLOUD DEPLOYMENT

Deploy:

```text
Spring Boot → Cloud Run
FastAPI → Cloud Run
Database → Supabase
Frontend → suitable static hosting
```

Configure:

```text
CORS
HTTPS
environment variables
JWT configuration
FastAPI service URL
Supabase credentials
LLM credentials
```

Never commit secrets.

---

# 51. ENVIRONMENT VARIABLES

Example:

```text
SPRING_DATASOURCE_URL=
SPRING_DATASOURCE_USERNAME=
SPRING_DATASOURCE_PASSWORD=

SUPABASE_URL=
SUPABASE_JWT_SECRET=

FASTAPI_BASE_URL=

LLM_API_KEY=

CORS_ALLOWED_ORIGINS=
```

`.env` must never be committed.

Provide:

```text
.env.example
```

with empty/example values.

---

# 52. SECRET MANAGEMENT

Never hard-code:

```text
JWT secret
Supabase secret
LLM API key
database password
```

Never place secrets in:

```text
Git
frontend JavaScript
Chrome Extension source
README
```

Use environment variables or cloud secret management.

---

# 53. PHASE 15 — CATEGORY NORMALIZATION

Implement only after the core system works.

Flow:

```text
Scheduler
 ↓
Find possible duplicate categories
 ↓
LLM analyzes candidates
 ↓
LLM returns suggestion
 ↓
Backend validates hierarchy
 ↓
Merge
```

Never allow arbitrary LLM-generated SQL.

---

# 54. PHASE 16 — RESEARCH DASHBOARD

Implement:

```text
Total saved
Never opened
Opened
Reopened
Forgotten
Average time to first open
Category distribution
```

Example:

```text
Total saved: 250

Never opened: 80

Opened: 170

Forgotten: 65

Average time to first open: 4.3 days
```

These are descriptive statistics, not diagnoses.

---

# 55. TESTING STRATEGY

## Unit Tests

Spring Boot:

```text
VideoService
CategoryService
InteractionService
```

FastAPI:

```text
metadata extraction
AI response parsing
category response validation
```

---

## Integration Tests

Test:

```text
Controller
 ↓
Service
 ↓
Repository
```

and:

```text
Spring Boot
 ↓
FastAPI
```

---

## Security Tests

Must test:

```text
User A → own video → allowed

User A → User B video → denied

Unauthenticated → protected endpoint → denied
```

---

# 56. ACCEPTANCE TEST — COMPLETE FLOW

The project is considered functionally complete when this works:

```text
1. User logs in.

2. User submits a YouTube/TikTok URL.

3. Spring Boot creates a PROCESSING record.

4. FastAPI extracts metadata.

5. LLM generates:
   - summary
   - level1
   - level2
   - level3

6. Backend resolves/creates category tree.

7. Video becomes COMPLETED.

8. Dashboard displays the video.

9. User opens the video.

10. Interaction is recorded.

11. last_opened_at is updated.

12. User opens it again.

13. REOPENED interaction is recorded.

14. After the configured threshold,
    the video can appear in Forgotten Content.

15. User A cannot access User B's content.
```

---

# 57. DEVELOPMENT ORDER

Follow this order unless the project owner explicitly changes it:

```text
PHASE 0
Project setup
        ↓
PHASE 1
Database
        ↓
PHASE 2
Spring Boot CRUD
        ↓
PHASE 3
Authentication
        ↓
PHASE 4
Categories
        ↓
PHASE 5
FastAPI metadata
        ↓
PHASE 6
AI
        ↓
PHASE 7
Spring Boot ↔ FastAPI
        ↓
PHASE 8
Interaction tracking
        ↓
PHASE 9
Forgotten content
        ↓
PHASE 10
Frontend
        ↓
PHASE 11
oEmbed
        ↓
PHASE 12
PWA
        ↓
PHASE 13
Chrome Extension
        ↓
PHASE 14
Deployment
        ↓
PHASE 15
Category normalization
        ↓
PHASE 16
Research dashboard
```

---

# 58. CLAUDE CODE WORKING RULES

Claude Code MUST:

1. Read this file before implementing.
2. Follow the existing architecture.
3. Inspect the current project before creating files.
4. Reuse existing code where appropriate.
5. Avoid unnecessary dependencies.
6. Avoid changing the technology stack.
7. Avoid creating duplicate services.
8. Avoid implementing future phases prematurely.
9. Explain architectural changes before making them.
10. Run tests after significant changes.
11. Never hard-code secrets.
12. Never commit `.env`.
13. Never silently modify database schema.
14. Never delete existing user data during development.
15. Never introduce MongoDB/Redis without explicit approval.
16. Never replace Spring Boot with FastAPI.
17. Never replace PostgreSQL with another database.
18. Never replace Vanilla JavaScript with React unless explicitly requested.

---

# 59. IMPLEMENTATION STYLE

When implementing each phase:

```text
Step 1
Inspect current code.

Step 2
Identify required changes.

Step 3
Implement the smallest complete change.

Step 4
Compile.

Step 5
Run tests.

Step 6
Fix errors.

Step 7
Report what changed.

Step 8
Wait for approval before moving to a major new phase.
```

Do not implement the entire project in one uncontrolled operation.

---

# 60. DEFINITION OF DONE

A phase is DONE only when:

```text
✓ Code implemented
✓ Project compiles
✓ Relevant tests pass
✓ No obvious security issue
✓ No secrets committed
✓ API behavior matches this document
✓ Database schema matches this document
✓ Existing functionality still works
```

---

# 61. PRIORITY RULE

When there is a conflict between:

```text
Feature quantity
```

and:

```text
System correctness
```

choose:

```text
System correctness.
```

A small working system is preferred over a large unfinished system.

---

# 62. FINAL SYSTEM

The final target architecture is:

```text
             MOBILE
                │
                ▼
               PWA
                │
                │
PC ── Chrome Extension
                │
                ▼
        ┌───────────────┐
        │  SPRING BOOT  │
        │               │
        │ Auth          │
        │ Video API     │
        │ Category API  │
        │ Interaction   │
        └───────┬───────┘
                │
                ▼
           ┌─────────┐
           │ FastAPI │
           │         │
           │ yt-dlp  │
           │ AI      │
           └────┬────┘
                │
                ▼
       ┌──────────────────┐
       │ Supabase         │
       │ PostgreSQL       │
       │                  │
       │ videos           │
       │ categories       │
       │ interactions     │
       └──────────────────┘
                │
                ▼
             FRONTEND
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
    Recent  Forgotten  Category
                       Tree
```

The most important research data is:

```text
saved_at
first_opened_at
last_opened_at
interaction history
category hierarchy
```

The most important application loop is:

```text
SAVE
 ↓
PROCESS
 ↓
CLASSIFY
 ↓
STORE
 ↓
OPEN
 ↓
TRACK
 ↓
FORGET / REVISIT
```

This loop must work reliably before optional features are prioritized.