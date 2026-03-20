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
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' })

  const prompt = `Analyze this food image and return ONLY a valid JSON object with these exact fields:
{
  "mealName": "descriptive name of the meal",
  "calories": <number in kcal>,
  "protein": <number in grams>,
  "carbs": <number in grams>,
  "fats": <number in grams>,
  "fiber": <number in grams>,
  "sugar": <number in grams>,
  "confidence": <number between 0 and 1>
}
Estimate values for one serving as shown in the image.
If the image does not contain food, return: { "error": "no_food" }`

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
