import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { config } from './config';
import routes from './routes';
import { errorHandler } from './middleware/errorHandler';

export function createApp() {
  const app = express();

  // Middleware
  app.use(cors({ origin: config.corsOrigins }));
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  if (config.nodeEnv !== 'test') {
    app.use(morgan('combined'));
  }

  // Mount API routes
  app.use(routes);

  // Global Error Handler
  app.use(errorHandler);

  return app;
}
