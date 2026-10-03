import { query } from '../../db';
import { v4 as uuidv4 } from 'uuid';
import { CreateJobInput, UpdateJobInput, QueryJobsInput } from './jobs.schema';
import { normalizeUrl } from '../../utils/normalizer';

// raw_data is import bookkeeping and can be large; it is never sent to clients.
const JOB_COLUMNS = `id, external_id, title, company, location, salary, employment_type, experience_requirement,
  url, source, description, skills, posted_date, discovered_at, match_score, match_reason, is_saved, notes,
  metadata, status, last_seen_at, created_at, updated_at`;

export class JobsRepository {
  async findMany(params: QueryJobsInput) {
    const {
      page = 1,
      limit = 25,
      search,
      company,
      location,
      remote,
      employment_type,
      source,
      saved,
      status = 'OPEN',
      min_score,
      posted_after,
      sort = 'relevance',
    } = params;

    const offset = (page - 1) * limit;
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (search) {
      conditions.push(`(title ILIKE $${idx} OR company ILIKE $${idx} OR description ILIKE $${idx} OR skills::text ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }

    if (company) {
      conditions.push(`company ILIKE $${idx}`);
      values.push(`%${company}%`);
      idx++;
    }

    if (location) {
      conditions.push(`location ILIKE $${idx}`);
      values.push(`%${location}%`);
      idx++;
    }

    if (remote !== undefined) {
      if (remote === 'true') {
        conditions.push(`(location ILIKE '%remote%' OR employment_type ILIKE '%remote%')`);
      } else {
        conditions.push(`(location NOT ILIKE '%remote%' AND employment_type NOT ILIKE '%remote%')`);
      }
    }

    if (employment_type) {
      conditions.push(`employment_type ILIKE $${idx}`);
      values.push(`%${employment_type}%`);
      idx++;
    }

    if (source) {
      conditions.push(`source ILIKE $${idx}`);
      values.push(`%${source}%`);
      idx++;
    }

    if (saved !== undefined) {
      conditions.push(`is_saved = $${idx}`);
      values.push(saved === 'true');
      idx++;
    }

    if (status !== 'ALL') {
      conditions.push(`status = $${idx}`);
      values.push(status);
      idx++;
    }

    if (min_score !== undefined) {
      conditions.push(`match_score >= $${idx}`);
      values.push(min_score);
      idx++;
    }

    if (posted_after) {
      conditions.push(`COALESCE(posted_date, discovered_at) >= $${idx}`);
      values.push(new Date(posted_after));
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    // Default: most relevant first, then freshest. id keeps pagination stable across ties.
    let orderBy = 'match_score DESC NULLS LAST, COALESCE(posted_date, discovered_at) DESC, id';
    if (sort === 'newest') orderBy = 'created_at DESC, id';
    else if (sort === 'oldest') orderBy = 'created_at ASC';
    else if (sort === 'company') orderBy = 'company ASC';
    else if (sort === 'title') orderBy = 'title ASC';

    const countSql = `SELECT COUNT(*) as total FROM jobs ${whereClause}`;
    const countRes = await query(countSql, values);
    const total = parseInt(countRes.rows[0].total, 10);

    const dataSql = `SELECT ${JOB_COLUMNS} FROM jobs ${whereClause} ORDER BY ${orderBy} LIMIT $${idx} OFFSET $${idx + 1}`;
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
    const res = await query(`SELECT ${JOB_COLUMNS} FROM jobs WHERE id = $1`, [id]);
    return res.rows[0] || null;
  }

  async create(data: CreateJobInput) {
    const id = uuidv4();
    const skillsJson = JSON.stringify(data.skills || []);
    const metadataJson = JSON.stringify(data.metadata || {});
    const normUrl = normalizeUrl(data.url);

    const res = await query(
      `INSERT INTO jobs (
        id, external_id, title, company, location, salary, employment_type,
        experience_requirement, url, source, description, skills,
        posted_date, match_score, match_reason, is_saved, notes,
        metadata, raw_data, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10, $11, $12::jsonb,
        $13, $14, $15, $16, $17,
        $18::jsonb, '{}'::jsonb, NOW(), NOW()
      ) RETURNING ${JOB_COLUMNS}`,
      [
        id,
        data.external_id || null,
        data.title,
        data.company,
        data.location || null,
        data.salary || null,
        data.employment_type || null,
        data.experience_requirement || null,
        normUrl,
        data.source || 'Manual',
        data.description || null,
        skillsJson,
        data.posted_date ? new Date(data.posted_date) : null,
        data.match_score ?? null,
        data.match_reason || null,
        data.is_saved ?? false,
        data.notes || null,
        metadataJson,
      ]
    );

    return res.rows[0];
  }

  async update(id: string, data: UpdateJobInput) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    for (const [key, val] of Object.entries(data)) {
      if (val === undefined) continue;

      if (key === 'skills') {
        fields.push(`skills = $${idx}::jsonb`);
        values.push(JSON.stringify(val));
      } else if (key === 'metadata') {
        fields.push(`metadata = $${idx}::jsonb`);
        values.push(JSON.stringify(val));
      } else if (key === 'posted_date') {
        fields.push(`posted_date = $${idx}`);
        values.push(val ? new Date(val as string) : null);
      } else if (key === 'url') {
        fields.push(`url = $${idx}`);
        values.push(normalizeUrl(val as string));
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

    const sql = `UPDATE jobs SET ${fields.join(', ')} WHERE id = $${idx} RETURNING ${JOB_COLUMNS}`;
    const res = await query(sql, values);
    return res.rows[0] || null;
  }

  async delete(id: string) {
    const res = await query('DELETE FROM jobs WHERE id = $1 RETURNING id', [id]);
    return (res.rowCount ?? 0) > 0;
  }

  async setSaved(id: string, isSaved: boolean) {
    const res = await query(
      `UPDATE jobs SET is_saved = $1, updated_at = NOW() WHERE id = $2 RETURNING ${JOB_COLUMNS}`,
      [isSaved, id]
    );
    return res.rows[0] || null;
  }
}

export const jobsRepository = new JobsRepository();
