import { query } from '../../db';
import { v4 as uuidv4 } from 'uuid';
import { CreateApplicationInput, UpdateApplicationInput, QueryApplicationsInput } from './applications.schema';

export class ApplicationsRepository {
  async findMany(params: QueryApplicationsInput) {
    const { page = 1, limit = 50, search, status, job_id, sort = 'newest' } = params;
    const offset = (page - 1) * limit;
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (search) {
      conditions.push(`(company ILIKE $${idx} OR role ILIKE $${idx} OR recruiter_name ILIKE $${idx} OR notes ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }

    if (status && status.toLowerCase() !== 'all') {
      conditions.push(`LOWER(status) = LOWER($${idx})`);
      values.push(status);
      idx++;
    }

    if (job_id) {
      conditions.push(`job_id = $${idx}`);
      values.push(job_id);
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    let orderBy = 'updated_at DESC';
    if (sort === 'oldest') orderBy = 'created_at ASC';
    else if (sort === 'applied') orderBy = 'applied_at DESC NULLS LAST';
    else if (sort === 'company') orderBy = 'company ASC';

    const countSql = `SELECT COUNT(*) as total FROM job_applications ${whereClause}`;
    const countRes = await query(countSql, values);
    const total = parseInt(countRes.rows[0].total, 10);

    const dataSql = `SELECT * FROM job_applications ${whereClause} ORDER BY ${orderBy} LIMIT $${idx} OFFSET $${idx + 1}`;
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
    const res = await query('SELECT * FROM job_applications WHERE id = $1', [id]);
    return res.rows[0] || null;
  }

  async findByJobId(jobId: string) {
    const res = await query('SELECT * FROM job_applications WHERE job_id = $1 LIMIT 1', [jobId]);
    return res.rows[0] || null;
  }

  async create(data: CreateApplicationInput) {
    const id = uuidv4();
    const res = await query(
      `INSERT INTO job_applications (
        id, job_id, company, role, salary, location, url,
        status, applied_at, follow_up_date, interview_date, interview_stage,
        recruiter_name, recruiter_contact, resume_id, resume_used,
        cover_letter_reference, next_action, notes, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10, $11, $12,
        $13, $14, $15, $16,
        $17, $18, $19, NOW(), NOW()
      ) RETURNING *`,
      [
        id,
        data.job_id || null,
        data.company,
        data.role,
        data.salary || null,
        data.location || null,
        data.url || null,
        data.status || 'applied',
        data.applied_at ? new Date(data.applied_at) : new Date(),
        data.follow_up_date ? new Date(data.follow_up_date) : null,
        data.interview_date ? new Date(data.interview_date) : null,
        data.interview_stage || null,
        data.recruiter_name || null,
        data.recruiter_contact || null,
        data.resume_id || null,
        data.resume_used || null,
        data.cover_letter_reference || null,
        data.next_action || null,
        data.notes || null,
      ]
    );

    return res.rows[0];
  }

  async update(id: string, data: UpdateApplicationInput) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    for (const [key, val] of Object.entries(data)) {
      if (val === undefined) continue;

      if (key === 'applied_at' || key === 'follow_up_date' || key === 'interview_date') {
        fields.push(`${key} = $${idx}`);
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

    const sql = `UPDATE job_applications SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`;
    const res = await query(sql, values);
    return res.rows[0] || null;
  }

  async delete(id: string) {
    const res = await query('DELETE FROM job_applications WHERE id = $1 RETURNING id', [id]);
    return (res.rowCount ?? 0) > 0;
  }
}

export const applicationsRepository = new ApplicationsRepository();
