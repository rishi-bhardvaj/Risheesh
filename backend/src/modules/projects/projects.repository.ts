import { query } from '../../db';
import { v4 as uuidv4 } from 'uuid';
import { CreateProjectInput, UpdateProjectInput, QueryProjectsInput } from './projects.schema';

export class ProjectsRepository {
  async findMany(params: QueryProjectsInput) {
    const { page = 1, limit = 50, search, status, client_id, is_freelance, sort = 'newest' } = params;
    const offset = (page - 1) * limit;
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (search) {
      conditions.push(`(name ILIKE $${idx} OR description ILIKE $${idx} OR tech_stack ILIKE $${idx} OR notes ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }

    if (status) {
      conditions.push(`status = $${idx}`);
      values.push(status);
      idx++;
    }

    if (client_id) {
      conditions.push(`client_id = $${idx}`);
      values.push(client_id);
      idx++;
    }

    if (is_freelance !== undefined) {
      conditions.push(`is_freelance = $${idx}`);
      values.push(is_freelance === 'true');
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    let orderBy = 'created_at DESC';
    if (sort === 'oldest') orderBy = 'created_at ASC';
    else if (sort === 'name') orderBy = 'name ASC';
    else if (sort === 'progress') orderBy = 'progress DESC';

    const countSql = `SELECT COUNT(*) as total FROM projects ${whereClause}`;
    const countRes = await query(countSql, values);
    const total = parseInt(countRes.rows[0].total, 10);

    const dataSql = `SELECT * FROM projects ${whereClause} ORDER BY ${orderBy} LIMIT $${idx} OFFSET $${idx + 1}`;
    values.push(limit, offset);
    const dataRes = await query(dataSql, values);

    return {
      items: dataRes.rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findById(id: string) {
    const res = await query('SELECT * FROM projects WHERE id = $1', [id]);
    return res.rows[0] || null;
  }

  async create(data: CreateProjectInput) {
    const id = uuidv4();
    const metadataJson = JSON.stringify(data.metadata || {});

    const res = await query(
      `INSERT INTO projects (
        id, name, description, status, progress, tech_stack,
        github_url, live_url, deadline, notes, client_id, lead_id,
        is_freelance, metadata, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6,
        $7, $8, $9, $10, $11, $12,
        $13, $14::jsonb, NOW(), NOW()
      ) RETURNING *`,
      [
        id,
        data.name.trim(),
        data.description?.trim() || null,
        data.status || 'in_progress',
        data.progress ?? 0.0,
        data.tech_stack?.trim() || null,
        data.github_url?.trim() || null,
        data.live_url?.trim() || null,
        data.deadline ? new Date(data.deadline) : null,
        data.notes || null,
        data.client_id || null,
        data.lead_id || null,
        data.is_freelance ?? false,
        metadataJson,
      ]
    );

    return res.rows[0];
  }

  async update(id: string, data: UpdateProjectInput) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    for (const [key, val] of Object.entries(data)) {
      if (val === undefined) continue;

      if (key === 'metadata') {
        fields.push(`metadata = $${idx}::jsonb`);
        values.push(JSON.stringify(val));
      } else if (key === 'deadline') {
        fields.push(`deadline = $${idx}`);
        values.push(val ? new Date(val as string) : null);
      } else {
        fields.push(`${key} = $${idx}`);
        values.push(val);
      }
      idx++;
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    fields.push('updated_at = NOW()');
    values.push(id);

    const sql = `UPDATE projects SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`;
    const res = await query(sql, values);
    return res.rows[0] || null;
  }

  async delete(id: string) {
    const res = await query('DELETE FROM projects WHERE id = $1 RETURNING id', [id]);
    return (res.rowCount ?? 0) > 0;
  }
}

export const projectsRepository = new ProjectsRepository();
