import { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '../utils/errors';
import { config } from '../config';

export function requireImportAuth(req: Request, _res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    throw new UnauthorizedError('Missing Authorization header. Expected Bearer <IMPORT_API_KEY>.');
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') {
    throw new UnauthorizedError('Invalid Authorization header format. Expected Bearer <IMPORT_API_KEY>.');
  }

  const token = parts[1];
  if (token !== config.importApiKey) {
    throw new UnauthorizedError('Invalid Import API Key.');
  }

  next();
}

export function optionalAuth(_req: Request, _res: Response, next: NextFunction): void {
  // Can be extended with JWT validation when users log in
  next();
}
