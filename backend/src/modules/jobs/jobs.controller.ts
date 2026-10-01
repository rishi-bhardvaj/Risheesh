import { Request, Response, NextFunction } from 'express';
import { jobsRepository } from './jobs.repository';
import { NotFoundError } from '../../utils/errors';
import { queryJobsSchema, createJobSchema, updateJobSchema } from './jobs.schema';

export class JobsController {
  async getJobs(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queryParams = queryJobsSchema.parse(req.query);
      const result = await jobsRepository.findMany(queryParams);
      res.status(200).json({
        success: true,
        data: result.items,
        pagination: result.pagination,
      });
    } catch (err) {
      next(err);
    }
  }

  async getJob(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const job = await jobsRepository.findById(id);
      if (!job) {
        throw new NotFoundError(`Job with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: job,
      });
    } catch (err) {
      next(err);
    }
  }

  async createJob(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = createJobSchema.parse(req.body);
      const created = await jobsRepository.create(input);
      res.status(201).json({
        success: true,
        data: created,
      });
    } catch (err) {
      next(err);
    }
  }

  async updateJob(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const input = updateJobSchema.parse(req.body);
      const updated = await jobsRepository.update(id, input);
      if (!updated) {
        throw new NotFoundError(`Job with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async deleteJob(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const deleted = await jobsRepository.delete(id);
      if (!deleted) {
        throw new NotFoundError(`Job with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: { id, deleted: true },
      });
    } catch (err) {
      next(err);
    }
  }

  async saveJob(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const updated = await jobsRepository.setSaved(id, true);
      if (!updated) {
        throw new NotFoundError(`Job with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async unsaveJob(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const updated = await jobsRepository.setSaved(id, false);
      if (!updated) {
        throw new NotFoundError(`Job with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }
}

export const jobsController = new JobsController();
