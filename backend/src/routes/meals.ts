import { Router } from 'express'
import { authMiddleware } from '../middleware/auth'
import * as mealController from '../controllers/mealController'

const router = Router()
router.use(authMiddleware)

router.post('/analyze', mealController.analyzeMeal)
router.post('/', mealController.createMeal)
router.get('/', mealController.getMeals)
router.get('/:id', mealController.getMeal)
router.put('/:id', mealController.updateMeal)
router.delete('/:id', mealController.deleteMeal)

export default router
