import { Request, Response, NextFunction } from 'express';
import { projectsRepository } from './projects.repository';
import { NotFoundError } from '../../utils/errors';
import { queryProjectsSchema, createProjectSchema, updateProjectSchema } from './projects.schema';

export class ProjectsController {
  async getProjects(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const queryParams = queryProjectsSchema.parse(req.query);
      const result = await projectsRepository.findMany(queryParams);
      res.status(200).json({
        success: true,
        data: result.items,
        pagination: result.pagination,
      });
    } catch (err) {
      next(err);
    }
  }

  async getProject(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const project = await projectsRepository.findById(id);
      if (!project) {
        throw new NotFoundError(`Project with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: project,
      });
    } catch (err) {
      next(err);
    }
  }

  async createProject(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = createProjectSchema.parse(req.body);
      const created = await projectsRepository.create(input);
      res.status(201).json({
        success: true,
        data: created,
      });
    } catch (err) {
      next(err);
    }
  }

  async updateProject(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const input = updateProjectSchema.parse(req.body);
      const updated = await projectsRepository.update(id, input);
      if (!updated) {
        throw new NotFoundError(`Project with id ${id} not found`);
      }
      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (err) {
      next(err);
    }
  }

  async deleteProject(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const deleted = await projectsRepository.delete(id);
      if (!deleted) {
        throw new NotFoundError(`Project with id ${id} not found`);
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

export const projectsController = new ProjectsController();
