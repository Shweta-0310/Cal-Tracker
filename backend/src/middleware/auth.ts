import { Request, Response, NextFunction } from 'express'

declare global {
  namespace Express {
    interface Request {
      userId: string
      userEmail: string
    }
  }
}

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const userId = req.headers['x-user-id'] as string | undefined
  if (!userId) {
    return res.status(401).json({ error: 'Missing X-User-ID header' })
  }
  req.userId = userId
  req.userEmail = ''
  next()
}
