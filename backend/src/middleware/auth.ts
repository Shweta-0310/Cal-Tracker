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
  // Accept X-User-ID header from iOS client (device-based identity)
  const headerUserId = req.headers['x-user-id'] as string | undefined
  if (headerUserId) {
    req.userId = headerUserId
    req.userEmail = ''
    return next()
  }

  // Fall back to Supabase Bearer token
  const token = req.headers.authorization?.split(' ')[1]
  if (!token) {
    return res.status(401).json({ error: 'Missing authorization token' })
  }

  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error || !user) {
    return res.status(401).json({ error: 'Invalid or expired token' })
  }

  req.userId = user.id
  req.userEmail = user.email ?? ''
  next()
}
