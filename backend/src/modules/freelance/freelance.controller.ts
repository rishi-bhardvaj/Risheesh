import { Request, Response, NextFunction } from 'express';
import { freelanceRepository } from './freelance.repository';
import { NotFoundError } from '../../utils/errors';
import { queryLeadsSchema, createLeadSchema, updateLeadSchema } from './freelance.schema';

export class FreelanceController {
  async getLeads(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queryParams = queryLeadsSchema.parse(req.query);
      const result = await freelanceRepository.findMany(queryParams);
      res.status(200).json({
        success: true,
        data: result.items,
        pagination: result.pagination,
      });
    } catch (err) {
      next(err);
    }
  }

  async getLead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const lead = await freelanceRepository.findById(id);
      if (!lead) {
        throw new NotFoundError(`Freelance lead with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: lead,
      });
    } catch (err) {
      next(err);
    }
  }

  async createLead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = createLeadSchema.parse(req.body);
      const created = await freelanceRepository.create(input);
      res.status(201).json({
        success: true,
        data: created,
      });
    } catch (err) {
      next(err);
    }
  }

  async updateLead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const input = updateLeadSchema.parse(req.body);
      const updated = await freelanceRepository.update(id, input);
      if (!updated) {
        throw new NotFoundError(`Freelance lead with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async deleteLead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const deleted = await freelanceRepository.delete(id);
      if (!deleted) {
        throw new NotFoundError(`Freelance lead with id ${id} not found`);
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

export const freelanceController = new FreelanceController();
