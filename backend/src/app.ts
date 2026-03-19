import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import mealsRouter from './routes/meals'
import analyticsRouter from './routes/analytics'

const app = express()
app.use(cors())
app.use(express.json({ limit: '20mb' }))

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
