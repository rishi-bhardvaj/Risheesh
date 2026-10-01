import { Request, Response, NextFunction } from 'express';
import { importService } from './import.service';

export class ImportController {
  async importJobs(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await importService.importJobs(req.body);
      res.status(200).json({
        success: true,
        data: stats,
      });
    } catch (err) {
      next(err);
    }
  }

  async importFreelance(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await importService.importFreelance(req.body);
      res.status(200).json({
        success: true,
        data: stats,
      });
    } catch (err) {
      next(err);
    }
  }

  async getImportRuns(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const limit = parseInt(req.query.limit as string, 10) || 20;
      const runs = await importService.getImportRuns(limit);
      res.status(200).json({
        success: true,
        data: runs,
      });
    } catch (err) {
      next(err);
    }
  }
}

export const importController = new ImportController();
