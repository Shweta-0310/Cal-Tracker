import { Router } from 'express'
import { authMiddleware } from '../middleware/auth'
import * as analyticsController from '../controllers/analyticsController'

const router = Router()
router.use(authMiddleware)
router.get('/daily', analyticsController.getDailyAnalytics)
router.get('/weekly', analyticsController.getWeeklyAnalytics)

export default router
