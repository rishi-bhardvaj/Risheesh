import { Request, Response, NextFunction } from 'express';
import { applicationsRepository } from './applications.repository';
import { NotFoundError } from '../../utils/errors';
import { queryApplicationsSchema, createApplicationSchema, updateApplicationSchema } from './applications.schema';

export class ApplicationsController {
  async getApplications(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queryParams = queryApplicationsSchema.parse(req.query);
      const result = await applicationsRepository.findMany(queryParams);
      res.status(200).json({
        success: true,
        data: result.items,
        pagination: result.pagination,
      });
    } catch (err) {
      next(err);
    }
  }

  async getApplication(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const app = await applicationsRepository.findById(id);
      if (!app) {
        throw new NotFoundError(`Job application with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: app,
      });
    } catch (err) {
      next(err);
    }
  }

  async createApplication(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = createApplicationSchema.parse(req.body);
      const created = await applicationsRepository.create(input);
      res.status(201).json({
        success: true,
        data: created,
      });
    } catch (err) {
      next(err);
    }
  }

  async updateApplication(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const input = updateApplicationSchema.parse(req.body);
      const updated = await applicationsRepository.update(id, input);
      if (!updated) {
        throw new NotFoundError(`Job application with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async deleteApplication(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const deleted = await applicationsRepository.delete(id);
      if (!deleted) {
        throw new NotFoundError(`Job application with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: { id, deleted: true },
      });
    } catch (err) {
      next(err);
    }
  }
}

export const applicationsController = new ApplicationsController();
