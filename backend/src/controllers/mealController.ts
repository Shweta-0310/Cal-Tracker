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
