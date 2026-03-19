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
