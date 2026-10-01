import { Request, Response, NextFunction } from 'express';
import { paymentsRepository } from './payments.repository';
import { NotFoundError } from '../../utils/errors';
import { queryPaymentsSchema, createPaymentSchema, updatePaymentSchema } from './payments.schema';

export class PaymentsController {
  async getPayments(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queryParams = queryPaymentsSchema.parse(req.query);
      const result = await paymentsRepository.findMany(queryParams);
      res.status(200).json({
        success: true,
        data: result.items,
        pagination: result.pagination,
      });
    } catch (err) {
      next(err);
    }
  }

  async getPayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const payment = await paymentsRepository.findById(id);
      if (!payment) {
        throw new NotFoundError(`Payment with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: payment,
      });
    } catch (err) {
      next(err);
    }
  }

  async createPayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = createPaymentSchema.parse(req.body);
      const created = await paymentsRepository.create(input);
      res.status(201).json({
        success: true,
        data: created,
      });
    } catch (err) {
      next(err);
    }
  }

  async updatePayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const input = updatePaymentSchema.parse(req.body);
      const updated = await paymentsRepository.update(id, input);
      if (!updated) {
        throw new NotFoundError(`Payment with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async deletePayment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const deleted = await paymentsRepository.delete(id);
      if (!deleted) {
        throw new NotFoundError(`Payment with id ${id} not found`);
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

export const paymentsController = new PaymentsController();
