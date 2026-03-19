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

  return res.json({ date, meal_count: meals.length, totals, meals })
}

export async function getWeeklyAnalytics(req: Request, res: Response) {
  const endDateStr = (req.query.date as string) || new Date().toISOString().split('T')[0]

  const endDate = new Date(`${endDateStr}T23:59:59.999Z`)
  const startDate = new Date(endDate)
  startDate.setUTCDate(startDate.getUTCDate() - 6)
  startDate.setUTCHours(0, 0, 0, 0)

  const { data, error } = await supabase
    .from('meals')
    .select('*')
    .eq('user_id', req.userId)
    .gte('logged_at', startDate.toISOString())
    .lte('logged_at', endDate.toISOString())
    .order('logged_at', { ascending: true })

  if (error) return res.status(500).json({ error: error.message })

  const meals = data ?? []

  // Group meals by day
  const dailyMap: Record<string, typeof meals> = {}
  for (const meal of meals) {
    const day = (meal.logged_at as string).split('T')[0]
    if (!dailyMap[day]) dailyMap[day] = []
    dailyMap[day].push(meal)
  }

  // Build 7-day array from oldest to newest
  const days = []
  for (let i = 6; i >= 0; i--) {
    const d = new Date(endDate)
    d.setUTCDate(d.getUTCDate() - i)
    const dayStr = d.toISOString().split('T')[0]
    const dayMeals = dailyMap[dayStr] ?? []
    const totals = dayMeals.reduce(
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
    days.push({ date: dayStr, meal_count: dayMeals.length, totals })
  }

  const weekTotals = meals.reduce(
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

  return res.json({
    start_date: startDate.toISOString().split('T')[0],
    end_date: endDateStr,
    total_meals: meals.length,
    week_totals: weekTotals,
    days
  })
}
