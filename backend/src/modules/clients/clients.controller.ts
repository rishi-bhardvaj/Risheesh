import { Request, Response, NextFunction } from 'express';
import { clientsRepository } from './clients.repository';
import { NotFoundError } from '../../utils/errors';
import { queryClientsSchema, createClientSchema, updateClientSchema } from './clients.schema';

export class ClientsController {
  async getClients(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queryParams = queryClientsSchema.parse(req.query);
      const result = await clientsRepository.findMany(queryParams);
      res.status(200).json({
        success: true,
        data: result.items,
        pagination: result.pagination,
      });
    } catch (err) {
      next(err);
    }
  }

  async getClient(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const client = await clientsRepository.findById(id);
      if (!client) {
        throw new NotFoundError(`Client with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: client,
      });
    } catch (err) {
      next(err);
    }
  }

  async createClient(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = createClientSchema.parse(req.body);
      const created = await clientsRepository.create(input);
      res.status(201).json({
        success: true,
        data: created,
      });
    } catch (err) {
      next(err);
    }
  }

  async updateClient(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const input = updateClientSchema.parse(req.body);
      const updated = await clientsRepository.update(id, input);
      if (!updated) {
        throw new NotFoundError(`Client with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async deleteClient(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const deleted = await clientsRepository.delete(id);
      if (!deleted) {
        throw new NotFoundError(`Client with id ${id} not found`);
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

export const clientsController = new ClientsController();
