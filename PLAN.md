# Cal Tracker — Complete Project Record

> This document is the exhaustive record of everything built, every decision made, and the full current state of the Cal Tracker project. Use this to resume work in any new location.

---

## Project Overview

**Cal Tracker** is a mobile-first calorie tracking app. Users photograph their meals, Gemini Vision AI detects the food and extracts macros, and data is stored in Supabase. The iOS app shows a daily dashboard with a donut chart and macro progress bars.

**Stack:**
| Layer | Technology |
|---|---|
| iOS App | SwiftUI (iOS 17+) |
| Backend API | Express.js + TypeScript |
| Database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| AI / Vision | Google Gemini 2.0 Flash |
| Storage | ~~Supabase Storage~~ — **eliminated** (see Architectural Decision below) |

---

## Architecture

```
┌─────────────────────────────────────────┐
│              iOS App (SwiftUI)          │
│                                         │
│  LoginView / RegisterView               │
│       ↓ (first login only)              │
│  WelcomeView → AddMealView              │
│       ↓ (after first meal)              │
│  DashboardView ←→ MealDetailView        │
└──────────────┬──────────────────────────┘
               │ HTTPS + Bearer JWT
               ▼
┌─────────────────────────────────────────┐
│          Express.js Backend             │
│          (localhost:3001 / deploy)      │
│                                         │
│  authMiddleware (validates Supabase JWT)│
│  POST /api/meals   → mealController     │
│  GET  /api/meals   → mealController     │
│  DELETE /api/meals/:id → mealController │
│  GET /api/analytics/daily → analytics  │
└──────┬──────────────────────┬───────────┘
       │                      │
       ▼                      ▼
┌──────────────┐    ┌─────────────────────┐
│ Supabase DB  │    │  Gemini 2.0 Flash   │
│ (PostgreSQL) │    │  Vision API         │
│              │    │  (analyzes base64   │
│ meals table  │    │   image inline)     │
│ auth.users   │    └─────────────────────┘
└──────────────┘
```

**Key data flow for meal logging:**
```
iOS picks image → compresses to JPEG → base64 encodes
→ POST /api/meals { imageData, mimeType }
→ Backend passes base64 inline to Gemini
→ Gemini returns { mealName, calories, protein, carbs, fats, fiber, sugar }
→ Backend saves to meals table (no image stored)
→ iOS shows result card → user confirms → DashboardView refreshes
```

---

## Key UI Decisions

| Decision | Choice |
|---|---|
| Ring chart | Single segmented donut — macro arcs, meal count in center |
| Macros tracked | Calories, Protein, Fats, Carbs + **Others (Fiber + Sugar)** |
| Period navigation | Daily only — `< Today >` arrows, disabled on today |
| Welcome screen | Shown **once** after first login (AppStorage flag) |
| Motivational quote | Static, same quote always |
| Background image | Static bundled food photo (`welcome_bg.jpg`) |
| App navigation | Single screen flow — no tab bar |
| Meal images | **Not stored** — only nutrition data is persisted |

---

## Key Architectural Decision: No Image Storage

**Decision made:** Skip Supabase Storage entirely. Send image as base64 directly from iOS to backend, which passes it inline to Gemini.

**Why:**
- Original flow (iOS → upload to Supabase Storage → URL → backend re-downloads → Gemini) was wasteful
- Double transfer, storage costs, extra bucket dependency
- Gemini supports inline base64 data natively

**New flow:**
```
iOS → base64 JPEG in POST body → Backend → Gemini (inlineData) → DB (nutrition only, image_url = null)
```

**SQL change required (already applied):**
```sql
ALTER TABLE public.meals ALTER COLUMN image_url DROP NOT NULL;
```

**Files affected by this decision:**
- `backend/src/services/geminiService.ts` — accepts `(imageData, mimeType)` not a URL
- `backend/src/controllers/mealController.ts` — reads `imageData`+`mimeType` from body
- `ios/CalTracker/Services/APIService.swift` — sends base64 encoded Data
- `ios/CalTracker/Views/AddMealView.swift` — skips StorageService, sends JPEG data directly
- `ios/CalTracker/Models.swift` — `imageUrl` is `String?` (optional)
- `ios/CalTracker/Views/MealCardView.swift` — uses `fork.knife.circle.fill` icon (no AsyncImage)
- `ios/CalTracker/Views/MealDetailView.swift` — uses `fork.knife.circle.fill` icon (no AsyncImage)
- `ios/CalTracker/Services/StorageService.swift` — **deleted** (no longer needed)

---

# PHASE 0 — Setup

## Step 0.1 — Supabase Project
1. supabase.com → New Project → name: `cal-tracker`
2. Settings → API → copy:
   - `Project URL` → `SUPABASE_URL`
   - `anon public` key → `SUPABASE_ANON_KEY` (iOS only)
   - `service_role secret` key → `SUPABASE_SERVICE_ROLE_KEY` (backend only, never expose)
3. Authentication → Settings → disable "Confirm email" (for dev)

## Step 0.2 — Gemini API Key
1. aistudio.google.com → Get API Key → Create API Key
2. Copy → `GEMINI_API_KEY`

## Step 0.3 — Folder Structure
```
Cal Tracker/
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── services/
│   │   └── middleware/
│   ├── .env
│   ├── .env.example
│   ├── package.json
│   └── tsconfig.json
├── ios/
│   └── CalTracker/          ← Xcode project
│       ├── Config.swift
│       ├── Models.swift
│       ├── CalTrackerApp.swift
│       ├── SupabaseManager.swift
│       ├── Services/
│       │   └── APIService.swift
│       ├── ViewModels/
│       │   ├── AuthViewModel.swift
│       │   └── DashboardViewModel.swift
│       └── Views/
│           ├── LoginView.swift
│           ├── RegisterView.swift
│           ├── WelcomeView.swift
│           ├── DashboardView.swift
│           ├── AddMealView.swift
│           ├── MealCardView.swift
│           ├── MealDetailView.swift
│           └── Components/
│               ├── SegmentedDonutView.swift
│               └── MacroProgressRow.swift
├── web/                      ← empty, future Next.js dashboard
├── PLAN.md
├── SETUP.md
└── .gitignore
```

---

# PHASE 1 — Supabase Database Setup

## Step 1.1 — Run SQL Schema

Supabase Dashboard → SQL Editor → New Query:

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE public.meals (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url   TEXT,                          -- nullable (no image stored)
  meal_name   TEXT,
  calories    FLOAT       NOT NULL DEFAULT 0,
  protein     FLOAT       NOT NULL DEFAULT 0,  -- grams
  carbs       FLOAT       NOT NULL DEFAULT 0,  -- grams
  fats        FLOAT       NOT NULL DEFAULT 0,  -- grams
  fiber       FLOAT       NOT NULL DEFAULT 0,  -- grams (part of "Others")
  sugar       FLOAT       NOT NULL DEFAULT 0,  -- grams (part of "Others")
  logged_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_meals_user_logged ON public.meals (user_id, logged_at DESC);
```

**Note:** `image_url` is nullable. If you ran the original schema (NOT NULL), run:
```sql
ALTER TABLE public.meals ALTER COLUMN image_url DROP NOT NULL;
```

## Step 1.2 — Row Level Security

```sql
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_own_meals" ON public.meals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "insert_own_meals" ON public.meals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "update_own_meals" ON public.meals
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "delete_own_meals" ON public.meals
  FOR DELETE USING (auth.uid() = user_id);
```

## Step 1.3 — Storage Bucket

**NOT NEEDED** — image storage was eliminated (see Architectural Decision). No bucket required.

---

# PHASE 2 — Backend (Express.js + TypeScript)

## Configuration

**`backend/.env`** (create this file, never commit):
```
SUPABASE_URL=https://ciguzriqiphqfoimyxnj.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your service role key>
GEMINI_API_KEY=<your gemini api key>
PORT=3001
```

**`backend/.env.example`** (commit this):
```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
GEMINI_API_KEY=
PORT=3001
```

**`backend/package.json`:**
```json
{
  "name": "cal-tracker-backend",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon --exec ts-node src/app.ts",
    "build": "tsc",
    "start": "node dist/app.js"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.x",
    "@google/generative-ai": "^0.x",
    "cors": "^2.x",
    "date-fns": "^3.x",
    "express": "^4.x",
    "zod": "^3.x"
  },
  "devDependencies": {
    "@types/cors": "^2.x",
    "@types/express": "^4.x",
    "@types/node": "^20.x",
    "nodemon": "^3.x",
    "ts-node": "^10.x",
    "typescript": "^5.x"
  }
}
```

**`backend/tsconfig.json`:**
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

---

## Backend File: `src/app.ts`

```typescript
import express from 'express'
import cors from 'cors'
import mealsRouter from './routes/meals'
import analyticsRouter from './routes/analytics'

const app = express()
app.use(cors())
app.use(express.json({ limit: '20mb' }))  // large enough for base64 images

app.get('/health', (_, res) => res.json({ status: 'ok' }))
app.use('/api/meals', mealsRouter)
app.use('/api/analytics', analyticsRouter)

app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err)
  res.status(500).json({ error: err.message })
})

const PORT = process.env.PORT || 3001
app.listen(PORT, () => console.log(`Server running on port ${PORT}`))

export default app
```

---

## Backend File: `src/middleware/auth.ts`

```typescript
import { Request, Response, NextFunction } from 'express'
import { supabase } from '../services/supabaseClient'

declare global {
  namespace Express {
    interface Request {
      userId: string
      userEmail: string
    }
  }
}

export async function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing token' })
  }
  const token = authHeader.split(' ')[1]
  const { data, error } = await supabase.auth.getUser(token)
  if (error || !data.user) {
    return res.status(401).json({ error: 'Invalid token' })
  }
  req.userId = data.user.id
  req.userEmail = data.user.email ?? ''
  next()
}
```

---

## Backend File: `src/services/supabaseClient.ts`

```typescript
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)
```

---

## Backend File: `src/services/geminiService.ts`

Accepts base64 image data inline (no URL fetching).

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai'

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!)

export interface NutritionResult {
  mealName: string
  calories: number
  protein: number
  carbs: number
  fats: number
  fiber: number
  sugar: number
  confidence: number
}

export async function analyzeFood(imageData: string, mimeType: string): Promise<NutritionResult> {
  const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' })

  const prompt = `Analyze this food image and return ONLY valid JSON with these exact fields:
{
  "mealName": "string",
  "calories": number,
  "protein": number,
  "carbs": number,
  "fats": number,
  "fiber": number,
  "sugar": number,
  "confidence": number (0-1)
}
All numeric values are per serving shown. If no food is detected, return { "error": "no_food" }.`

  const result = await model.generateContent([
    { inlineData: { mimeType, data: imageData } },
    prompt
  ])

  const text = result.response.text().trim()
  const jsonMatch = text.match(/\{[\s\S]*\}/)
  if (!jsonMatch) throw new Error('No JSON in Gemini response')

  const parsed = JSON.parse(jsonMatch[0])
  if (parsed.error === 'no_food') throw new Error('NO_FOOD_DETECTED')

  return parsed as NutritionResult
}
```

---

## Backend File: `src/routes/meals.ts`

```typescript
import { Router } from 'express'
import { authMiddleware } from '../middleware/auth'
import * as mealController from '../controllers/mealController'

const router = Router()
router.use(authMiddleware)

router.post('/', mealController.createMeal)
router.get('/', mealController.getMeals)
router.get('/:id', mealController.getMeal)
router.put('/:id', mealController.updateMeal)
router.delete('/:id', mealController.deleteMeal)

export default router
```

---

## Backend File: `src/routes/analytics.ts`

```typescript
import { Router } from 'express'
import { authMiddleware } from '../middleware/auth'
import * as analyticsController from '../controllers/analyticsController'

const router = Router()
router.use(authMiddleware)
router.get('/daily', analyticsController.getDailyAnalytics)

export default router
```

---

## Backend File: `src/controllers/mealController.ts`

```typescript
import { Request, Response } from 'express'
import { z } from 'zod'
import { supabase } from '../services/supabaseClient'
import { analyzeFood } from '../services/geminiService'

export async function createMeal(req: Request, res: Response) {
  try {
    const { imageData, mimeType } = z.object({
      imageData: z.string(),
      mimeType: z.string().default('image/jpeg')
    }).parse(req.body)

    let nutrition
    try {
      nutrition = await analyzeFood(imageData, mimeType)
    } catch (e: any) {
      if (e.message === 'NO_FOOD_DETECTED') {
        return res.status(422).json({ error: 'No food detected in image' })
      }
      throw e
    }

    const { data, error } = await supabase
      .from('meals')
      .insert({
        user_id: req.userId,
        image_url: null,
        meal_name: nutrition.mealName,
        calories: nutrition.calories,
        protein: nutrition.protein,
        carbs: nutrition.carbs,
        fats: nutrition.fats,
        fiber: nutrition.fiber,
        sugar: nutrition.sugar,
        logged_at: new Date().toISOString()
      })
      .select()
      .single()

    if (error) throw error
    return res.status(201).json(data)
  } catch (e: any) {
    return res.status(500).json({ error: e.message })
  }
}

export async function getMeals(req: Request, res: Response) {
  const date = req.query.date as string | undefined
  let query = supabase
    .from('meals')
    .select('*')
    .eq('user_id', req.userId)
    .order('logged_at', { ascending: false })

  if (date) {
    query = query
      .gte('logged_at', `${date}T00:00:00.000Z`)
      .lt('logged_at', `${date}T23:59:59.999Z`)
  }

  const { data, error } = await query
  if (error) return res.status(500).json({ error: error.message })
  return res.json({ meals: data })
}

export async function getMeal(req: Request, res: Response) {
  const { data, error } = await supabase
    .from('meals')
    .select('*')
    .eq('id', req.params.id)
    .eq('user_id', req.userId)
    .single()

  if (error) return res.status(404).json({ error: 'Not found' })
  return res.json(data)
}

export async function updateMeal(req: Request, res: Response) {
  const body = z.object({
    meal_name: z.string().optional(),
    calories: z.number().optional(),
    protein: z.number().optional(),
    carbs: z.number().optional(),
    fats: z.number().optional(),
    fiber: z.number().optional(),
    sugar: z.number().optional()
  }).parse(req.body)

  const { data, error } = await supabase
    .from('meals')
    .update(body)
    .eq('id', req.params.id)
    .eq('user_id', req.userId)
    .select()
    .single()

  if (error) return res.status(404).json({ error: 'Not found' })
  return res.json(data)
}

export async function deleteMeal(req: Request, res: Response) {
  const { error } = await supabase
    .from('meals')
    .delete()
    .eq('id', req.params.id)
    .eq('user_id', req.userId)

  if (error) return res.status(500).json({ error: error.message })
  return res.status(204).send()
}
```

---

## Backend File: `src/controllers/analyticsController.ts`

```typescript
import { Request, Response } from 'express'
import { supabase } from '../services/supabaseClient'

export async function getDailyAnalytics(req: Request, res: Response) {
  const date = (req.query.date as string) || new Date().toISOString().split('T')[0]

  const { data, error } = await supabase
    .from('meals')
    .select('*')
    .eq('user_id', req.userId)
    .gte('logged_at', `${date}T00:00:00.000Z`)
    .lt('logged_at', `${date}T23:59:59.999Z`)
    .order('logged_at', { ascending: true })

  if (error) return res.status(500).json({ error: error.message })

  const meals = data ?? []
  const totals = meals.reduce(
    (acc, m) => ({
      calories: acc.calories + (m.calories ?? 0),
      protein: acc.protein + (m.protein ?? 0),
      carbs: acc.carbs + (m.carbs ?? 0),
      fats: acc.fats + (m.fats ?? 0),
      fiber: acc.fiber + (m.fiber ?? 0),
      sugar: acc.sugar + (m.sugar ?? 0)
    }),
    { calories: 0, protein: 0, carbs: 0, fats: 0, fiber: 0, sugar: 0 }
  )

  return res.json({ date, mealCount: meals.length, totals, meals })
}
```

---

# PHASE 3 — iOS App (SwiftUI)

## Xcode Setup
1. Xcode 15+ required
2. Create new project: App → SwiftUI, iOS 17 deployment target
3. Add Supabase Swift SDK via Swift Package Manager:
   - URL: `https://github.com/supabase/supabase-swift`
   - Add products: `Supabase`, `Auth`, `PostgREST`
4. Add `welcome_bg.jpg` to Assets.xcassets (any food/meal photo)

---

## iOS File: `Config.swift`

```swift
enum Config {
    static let supabaseURL = URL(string: "https://ciguzriqiphqfoimyxnj.supabase.co")!
    static let supabaseAnonKey = "<your anon key>"
    static let apiBaseURL = "http://localhost:3001/api"   // change for production
}
```

---

## iOS File: `SupabaseManager.swift`

```swift
import Supabase

class SupabaseManager {
    static let shared = SupabaseClient(
        supabaseURL: Config.supabaseURL,
        supabaseKey: Config.supabaseAnonKey
    )
}
```

---

## iOS File: `Models.swift`

```swift
import Foundation

struct Meal: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let imageUrl: String?      // nullable — no image stored
    let mealName: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    let fiber: Double
    let sugar: Double
    let loggedAt: Date
    let createdAt: Date

    var others: Double { fiber + sugar }

    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", imageUrl = "image_url",
             mealName = "meal_name", calories, protein, carbs, fats,
             fiber, sugar, loggedAt = "logged_at", createdAt = "created_at"
    }
}

struct NutritionTotals {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var fiber: Double
    var sugar: Double

    var others: Double { fiber + sugar }
}

struct TotalsResponse: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    let fiber: Double
    let sugar: Double
}

struct DailyAnalytics: Codable {
    let date: String
    let mealCount: Int
    let totals: TotalsResponse
    let meals: [Meal]

    enum CodingKeys: String, CodingKey {
        case date, mealCount = "meal_count", totals, meals
    }

    var nutritionTotals: NutritionTotals {
        NutritionTotals(
            calories: totals.calories, protein: totals.protein,
            carbs: totals.carbs, fats: totals.fats,
            fiber: totals.fiber, sugar: totals.sugar
        )
    }
}
```

---

## iOS File: `Services/APIService.swift`

```swift
import Foundation

class APIService {
    static let shared = APIService()

    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: Config.apiBaseURL + path) else {
            throw URLError(.badURL)
        }

        let session = SupabaseManager.shared.auth.currentSession
        guard let token = session?.accessToken else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    func createMeal(imageData: Data, mimeType: String = "image/jpeg") async throws -> Meal {
        let body: [String: Any] = [
            "imageData": imageData.base64EncodedString(),
            "mimeType": mimeType
        ]
        let data = try await request("/meals", method: "POST", body: body)
        return try APIService.iso.decode(Meal.self, from: data)
    }

    func getDailyAnalytics(date: Date = Date()) async throws -> DailyAnalytics {
        let dateString = APIService.dateFormatter.string(from: date)
        let data = try await request("/analytics/daily?date=\(dateString)")
        return try APIService.iso.decode(DailyAnalytics.self, from: data)
    }

    func deleteMeal(id: UUID) async throws {
        _ = try await request("/meals/\(id.uuidString)", method: "DELETE")
    }
}
```

---

## iOS File: `ViewModels/AuthViewModel.swift`

```swift
import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func checkSession() async {
        let session = try? await SupabaseManager.shared.auth.session
        isAuthenticated = session != nil
        if let meta = session?.user.userMetadata,
           case .string(let name) = meta["name"] {
            userName = name
        }
    }

    func signUp(email: String, password: String, name: String) async {
        isLoading = true; errorMessage = nil
        do {
            let result = try await SupabaseManager.shared.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            userName = name
            isAuthenticated = result.user != nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let session = try await SupabaseManager.shared.auth.signIn(
                email: email, password: password
            )
            if case .string(let name) = session.user.userMetadata["name"] {
                userName = name
            }
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        try? await SupabaseManager.shared.auth.signOut()
        isAuthenticated = false
        userName = ""
    }
}
```

---

## iOS File: `ViewModels/DashboardViewModel.swift`

```swift
import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var analytics: DailyAnalytics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentDate = Date()

    // Hardcoded daily goals
    let goals = NutritionTotals(
        calories: 2000, protein: 150, carbs: 250, fats: 65, fiber: 25, sugar: 50
    )

    var totals: NutritionTotals { analytics?.nutritionTotals ?? NutritionTotals(calories:0,protein:0,carbs:0,fats:0,fiber:0,sugar:0) }
    var mealCount: Int { analytics?.mealCount ?? 0 }
    var meals: [Meal] { analytics?.meals ?? [] }

    var isToday: Bool { Calendar.current.isDateInToday(currentDate) }

    var dateLabel: String {
        if isToday { return "Today" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: currentDate)
    }

    func load() async {
        isLoading = true
        do { analytics = try await APIService.shared.getDailyAnalytics(date: currentDate) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func goToPreviousDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    }

    func goToNextDay() {
        guard !isToday else { return }
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
    }
}
```

---

## iOS File: `CalTrackerApp.swift`

```swift
import SwiftUI

@main
struct CalTrackerApp: App {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("hasLoggedFirstMeal") private var hasLoggedFirstMeal = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !authVM.isAuthenticated {
                    LoginView()
                } else if !hasLoggedFirstMeal {
                    WelcomeView()
                } else {
                    DashboardView()
                }
            }
            .environmentObject(authVM)
            .task { await authVM.checkSession() }
        }
    }
}
```

---

## iOS File: `Views/LoginView.swift`

```swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Cal Tracker").font(.largeTitle.bold())
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let err = authVM.errorMessage {
                    Text(err).foregroundStyle(.red).font(.caption)
                }

                Button {
                    Task { await authVM.signIn(email: email, password: password) }
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(authVM.isLoading)

                Button("Create Account") { showRegister = true }
            }
            .padding()
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}
```

---

## iOS File: `Views/RegisterView.swift`

```swift
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Create Account").font(.title.bold())
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            SecureField("Password (6+ chars)", text: $password)
                .textFieldStyle(.roundedBorder)

            if let err = authVM.errorMessage {
                Text(err).foregroundStyle(.red).font(.caption)
            }

            Button {
                guard password.count >= 6, !name.isEmpty, !email.isEmpty else { return }
                Task { await authVM.signUp(email: email, password: password, name: name) }
            } label: {
                if authVM.isLoading { ProgressView() }
                else { Text("Create Account").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(authVM.isLoading)

            Button("Back to Login") { dismiss() }
        }
        .padding()
    }
}
```

---

## iOS File: `Views/WelcomeView.swift`

Shown once after first login. Background: static bundled food image (`welcome_bg.jpg`).

```swift
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showAddMeal = false

    var body: some View {
        ZStack {
            Image("welcome_bg")
                .resizable().scaledToFill()
                .ignoresSafeArea()
            LinearGradient(
                colors: [.black.opacity(0.5), .black.opacity(0.1)],
                startPoint: .bottom, endPoint: .top
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                Text("Hello, \(authVM.userName)!")
                    .font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Track your first meal to get started.")
                    .foregroundStyle(.white.opacity(0.85))
                Text(""Eat well, feel well."")
                    .italic().foregroundStyle(.white.opacity(0.7))
                Button("Upload Meal Photo") { showAddMeal = true }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .sheet(isPresented: $showAddMeal) {
            AddMealView()
        }
    }
}
```

---

## iOS File: `Views/DashboardView.swift`

```swift
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = DashboardViewModel()
    @State private var showAddMeal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date navigator
                    HStack {
                        Button { vm.goToPreviousDay() } label: {
                            Image(systemName: "chevron.left")
                        }
                        Text(vm.dateLabel).font(.headline)
                        Button { vm.goToNextDay() } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(vm.isToday)
                    }

                    // Donut chart
                    SegmentedDonutView(totals: vm.totals, mealCount: vm.mealCount)
                        .frame(width: 200, height: 200)

                    // Macro progress rows
                    VStack(spacing: 8) {
                        MacroProgressRow(label: "Calories", value: vm.totals.calories, goal: vm.goals.calories, color: .orange)
                        MacroProgressRow(label: "Protein",  value: vm.totals.protein,  goal: vm.goals.protein,  color: .blue)
                        MacroProgressRow(label: "Fats",     value: vm.totals.fats,     goal: vm.goals.fats,     color: .pink)
                        MacroProgressRow(label: "Carbs",    value: vm.totals.carbs,    goal: vm.goals.carbs,    color: Color(hex: "#FFBF69"))
                        MacroProgressRow(label: "Others",   value: vm.totals.others,   goal: vm.goals.others,   color: .purple)
                    }.padding(.horizontal)

                    // Meal list
                    ForEach(vm.meals) { meal in
                        NavigationLink {
                            MealDetailView(meal: meal) { await vm.load() }
                        } label: {
                            MealCardView(meal: meal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Cal Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") { Task { await authVM.signOut() } }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Upload Meal Photo") { showAddMeal = true }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView { await vm.load() }
            }
            .task { await vm.load() }
            .onChange(of: vm.currentDate) { _, _ in Task { await vm.load() } }
        }
    }
}
```

---

## iOS File: `Views/AddMealView.swift`

No Supabase Storage calls — sends JPEG data as base64 directly.

```swift
import SwiftUI
import PhotosUI

struct AddMealView: View {
    var onConfirm: (() async -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @AppStorage("hasLoggedFirstMeal") private var hasLoggedFirstMeal = false

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var result: Meal?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable().scaledToFit().frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(Image(systemName: "photo").font(.largeTitle))
                }
            }
            .onChange(of: selectedItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        selectedImage = UIImage(data: data)
                        result = nil
                    }
                }
            }

            if let result {
                // Result card
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.mealName ?? "Meal").font(.headline)
                    HStack {
                        Text("Calories"); Spacer(); Text("\(Int(result.calories)) kcal")
                    }
                    HStack {
                        Text("Protein"); Spacer(); Text("\(Int(result.protein))g")
                    }
                    HStack {
                        Text("Carbs"); Spacer(); Text("\(Int(result.carbs))g")
                    }
                    HStack {
                        Text("Fats"); Spacer(); Text("\(Int(result.fats))g")
                    }
                    HStack {
                        Text("Others"); Spacer(); Text("\(Int(result.others))g")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Confirm & Save") {
                    hasLoggedFirstMeal = true
                    Task {
                        await onConfirm?()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }

            if selectedImage != nil && result == nil {
                Button {
                    Task { await analyze() }
                } label: {
                    if isAnalyzing { ProgressView() }
                    else { Text("Analyze Meal").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing)
            }
        }
        .padding()
    }

    private func analyze() async {
        guard let image = selectedImage,
              let jpeg = image.jpegData(compressionQuality: 0.7) else { return }
        isAnalyzing = true
        errorMessage = nil
        do {
            result = try await APIService.shared.createMeal(imageData: jpeg, mimeType: "image/jpeg")
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }
}
```

---

## iOS File: `Views/MealCardView.swift`

Uses icon placeholder (no image stored).

```swift
import SwiftUI

struct MealCardView: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .resizable().scaledToFill()
                .frame(width: 56, height: 56)
                .foregroundStyle(.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.mealName ?? "Meal").font(.headline)
                Text("\(Int(meal.calories)) kcal")
                Text("P: \(Int(meal.protein))g  C: \(Int(meal.carbs))g  F: \(Int(meal.fats))g")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## iOS File: `Views/MealDetailView.swift`

```swift
import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    var onDelete: (() async -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text(meal.mealName ?? "Meal").font(.title.bold())

                let f = DateFormatter()
                let _ = { f.dateStyle = .medium; f.timeStyle = .short }()
                Text(f.string(from: meal.loggedAt))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    nutriRow("Calories", "\(Int(meal.calories)) kcal")
                    nutriRow("Protein",  "\(Int(meal.protein))g")
                    nutriRow("Carbs",    "\(Int(meal.carbs))g")
                    nutriRow("Fats",     "\(Int(meal.fats))g")
                    nutriRow("Others",   "\(Int(meal.others))g")
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button("Delete Meal", role: .destructive) { showDeleteConfirm = true }
            }
            .padding()
        }
        .navigationTitle("Meal Detail")
        .alert("Delete Meal?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await APIService.shared.deleteMeal(id: meal.id)
                    await onDelete?()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func nutriRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
```

---

## iOS File: `Views/Components/SegmentedDonutView.swift`

```swift
import SwiftUI

struct SegmentedDonutView: View {
    let totals: NutritionTotals
    let mealCount: Int

    var body: some View {
        ZStack {
            // Arcs for each macro (by grams, not calories)
            let segments: [(Double, Color)] = [
                (totals.protein, .blue),
                (totals.fats,    Color(hex: "#FF6B8A")),
                (totals.carbs,   Color(hex: "#FFBF69")),
                (totals.others,  .purple)
            ]
            let total = segments.reduce(0.0) { $0 + $1.0 }
            let gap = 0.02
            var startAngle = -90.0

            ForEach(0..<segments.count, id: \.self) { i in
                let (value, color) = segments[i]
                let fraction = total > 0 ? value / total : 0.25
                let sweep = (fraction * (1 - Double(segments.count) * gap)) * 360
                Arc(startAngle: startAngle, endAngle: startAngle + sweep)
                    .stroke(color, lineWidth: 24)
                let _ = { startAngle += sweep + gap * 360 }()
            }

            VStack {
                Text("\(mealCount)").font(.title.bold())
                Text("Total Meal").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct Arc: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return p
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

---

## iOS File: `Views/Components/MacroProgressRow.swift`

```swift
import SwiftUI

struct MacroProgressRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color

    private let segments = 20

    var body: some View {
        let progress = min(value / max(goal, 1), 1.0)
        let filled = Int(progress * Double(segments))

        HStack(spacing: 8) {
            Text(label).frame(width: 70, alignment: .leading).font(.subheadline)

            HStack(spacing: 3) {
                ForEach(0..<segments, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 8, height: 16)
                        .foregroundStyle(i < filled ? color : color.opacity(0.15))
                }
            }

            Text("\(Int(progress * 100))%")
                .font(.caption).frame(width: 36, alignment: .trailing)
        }
    }
}
```

---

# API Contract (Complete)

## Health
```
GET /health
→ 200: { "status": "ok" }
```

## Meals (all require Authorization: Bearer <token>)

```
POST /api/meals
Content-Type: application/json
Body: {
  "imageData": "<base64 encoded JPEG>",
  "mimeType": "image/jpeg"
}
→ 201: Meal object
→ 422: { "error": "No food detected in image" }
→ 500: { "error": "..." }

GET /api/meals?date=YYYY-MM-DD
→ 200: { "meals": [Meal, ...] }

GET /api/meals/:id
→ 200: Meal
→ 404: { "error": "Not found" }

PUT /api/meals/:id
Body: { meal_name?, calories?, protein?, carbs?, fats?, fiber?, sugar? }
→ 200: Updated Meal
→ 404: { "error": "Not found" }

DELETE /api/meals/:id
→ 204: (no body)
→ 500: { "error": "..." }
```

## Analytics

```
GET /api/analytics/daily?date=YYYY-MM-DD
→ 200: {
  "date": "2024-03-18",
  "mealCount": 3,
  "totals": {
    "calories": 2150,
    "protein": 120,
    "carbs": 280,
    "fats": 60,
    "fiber": 20,
    "sugar": 45
  },
  "meals": [Meal, ...]
}
```

**Meal object shape:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "image_url": null,
  "meal_name": "Caesar Salad",
  "calories": 350,
  "protein": 12,
  "carbs": 20,
  "fats": 25,
  "fiber": 3,
  "sugar": 5,
  "logged_at": "2024-03-18T12:30:00Z",
  "created_at": "2024-03-18T12:30:00Z"
}
```

---

# Credentials & Configuration Reference

| Item | Location | Value type |
|---|---|---|
| Supabase URL | `backend/.env` + `ios/Config.swift` | Public URL |
| Supabase anon key | `ios/Config.swift` | Public (safe in iOS) |
| Supabase service role key | `backend/.env` ONLY | Secret — never expose |
| Gemini API key | `backend/.env` ONLY | Secret — never expose |
| Backend API base URL | `ios/Config.swift` | `http://localhost:3001/api` (dev) |

---

# Running the Project

## Backend

```bash
cd backend
cp .env.example .env     # fill in real values
npm install
npm run dev              # starts on http://localhost:3001
```

Test:
```bash
curl http://localhost:3001/health
# → {"status":"ok"}
```

## iOS

1. Open `ios/CalTracker.xcodeproj` in Xcode 15+
2. Add Supabase Swift SDK via File → Add Package Dependencies
   - URL: `https://github.com/supabase/supabase-swift`
3. Update `Config.swift` with your Supabase URL and anon key
4. Add `welcome_bg.jpg` to `Assets.xcassets`
5. Select iPhone simulator → Run (⌘R)
6. Make sure backend is running at `localhost:3001`

---

# Current Project State

## Done
- [x] Supabase project + DB schema + RLS policies
- [x] Full Express.js backend (all endpoints)
- [x] Gemini Vision integration (base64 inline)
- [x] iOS authentication (login, register, session restore)
- [x] WelcomeView (one-time onboarding, random rotating quotes)
- [x] AddMealView (photo picker → analyze → confirm)
- [x] DashboardView (date navigation, donut chart, macro progress)
- [x] MealCardView + MealDetailView (tap to view, edit, delete)
- [x] EditMealView (edit AI-detected values manually)
- [x] SegmentedDonutView component
- [x] MacroProgressRow component
- [x] Eliminated Supabase Storage (direct base64 flow)
- [x] GoalsStore + SettingsView (persisted, user-editable daily goals)
- [x] Weekly analytics — `GET /api/analytics/weekly` + WeeklySummaryView (bar chart + 7-day totals)

## Not Done / Incomplete
- [ ] Web dashboard (`web/` folder is empty — placeholder for Next.js)
- [ ] No push notifications / reminders
- [ ] No export / sharing
- [ ] Production deployment (backend is localhost only)

---

# Known Limitations

1. **Hardcoded goals:** 2000 kcal, 150g protein, 250g carbs, 65g fat, 25g fiber, 50g sugar
2. **No meal editing:** Users can delete meals but not correct AI-detected values
3. **Static quote:** Same quote on every WelcomeView
4. **No image persistence:** `image_url` is always null — only nutrition data saved
5. **Single day view:** No weekly/monthly summary
6. **localhost backend:** iOS needs backend on same network or deployed
