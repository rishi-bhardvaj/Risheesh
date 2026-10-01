import { query } from '../../db';
import { v4 as uuidv4 } from 'uuid';
import { CreateLeadInput, UpdateLeadInput, QueryLeadsInput } from './freelance.schema';
import { normalizeUrl } from '../../utils/normalizer';

export class FreelanceRepository {
  async findMany(params: QueryLeadsInput) {
    const {
      page = 1,
      limit = 25,
      search,
      platform,
      status,
      client_id,
      sort = 'newest',
    } = params;

    const offset = (page - 1) * limit;
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (search) {
      conditions.push(`(title ILIKE $${idx} OR client_name ILIKE $${idx} OR description ILIKE $${idx} OR skills::text ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }

    if (platform) {
      conditions.push(`platform ILIKE $${idx}`);
      values.push(`%${platform}%`);
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

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    let orderBy = 'created_at DESC';
    if (sort === 'oldest') orderBy = 'created_at ASC';
    else if (sort === 'budget') orderBy = 'budget DESC NULLS LAST';
    else if (sort === 'title') orderBy = 'title ASC';

    const countSql = `SELECT COUNT(*) as total FROM freelance_leads ${whereClause}`;
    const countRes = await query(countSql, values);
    const total = parseInt(countRes.rows[0].total, 10);

    const dataSql = `SELECT * FROM freelance_leads ${whereClause} ORDER BY ${orderBy} LIMIT $${idx} OFFSET $${idx + 1}`;
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
    const res = await query('SELECT * FROM freelance_leads WHERE id = $1', [id]);
    return res.rows[0] || null;
  }

  async create(data: CreateLeadInput) {
    const id = uuidv4();
    const skillsJson = JSON.stringify(data.skills || []);
    const metadataJson = JSON.stringify(data.metadata || {});
    const normUrl = normalizeUrl(data.url);

    const res = await query(
      `INSERT INTO freelance_leads (
        id, external_id, client_id, project_id, title, client_name,
        contact_name, contact_info, platform, description, skills,
        budget, currency, url, status, proposal, deadline,
        follow_up_date, follow_up_note, next_action, notes, lead_date,
        match_score, match_reason, metadata, raw_data, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6,
        $7, $8, $9, $10, $11::jsonb,
        $12, $13, $14, $15, $16, $17,
        $18, $19, $20, $21, $22,
        $23, $24, $25::jsonb, '{}'::jsonb, NOW(), NOW()
      ) RETURNING *`,
      [
        id,
        data.external_id || null,
        data.client_id || null,
        data.project_id || null,
        data.title,
        data.client_name || null,
        data.contact_name || null,
        data.contact_info || null,
        data.platform || 'Direct',
        data.description || null,
        skillsJson,
        data.budget ?? null,
        data.currency || 'USD',
        normUrl,
        data.status || 'NEW_LEAD',
        data.proposal || null,
        data.deadline ? new Date(data.deadline) : null,
        data.follow_up_date ? new Date(data.follow_up_date) : null,
        data.follow_up_note || null,
        data.next_action || null,
        data.notes || null,
        data.lead_date ? new Date(data.lead_date) : new Date(),
        data.match_score ?? null,
        data.match_reason || null,
        metadataJson,
      ]
    );

    return res.rows[0];
  }

  async update(id: string, data: UpdateLeadInput) {
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
      } else if (key === 'deadline' || key === 'follow_up_date' || key === 'lead_date') {
        fields.push(`${key} = $${idx}`);
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

    const sql = `UPDATE freelance_leads SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`;
    const res = await query(sql, values);
    return res.rows[0] || null;
  }

  async delete(id: string) {
    const res = await query('DELETE FROM freelance_leads WHERE id = $1 RETURNING id', [id]);
    return (res.rowCount ?? 0) > 0;
  }
}

export const freelanceRepository = new FreelanceRepository();
