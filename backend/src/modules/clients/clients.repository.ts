import { query } from '../../db';
import { v4 as uuidv4 } from 'uuid';
import { CreateClientInput, UpdateClientInput, QueryClientsInput } from './clients.schema';

export class ClientsRepository {
  async findMany(params: QueryClientsInput) {
    const { page = 1, limit = 50, search, status, sort = 'name' } = params;
    const offset = (page - 1) * limit;
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (search) {
      conditions.push(`(name ILIKE $${idx} OR contact_name ILIKE $${idx} OR email ILIKE $${idx} OR notes ILIKE $${idx})`);
      values.push(`%${search}%`);
      idx++;
    }

    if (status) {
      conditions.push(`status = $${idx}`);
      values.push(status);
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    let orderBy = 'name ASC';
    if (sort === 'newest') orderBy = 'created_at DESC';
    else if (sort === 'oldest') orderBy = 'created_at ASC';

    const countSql = `SELECT COUNT(*) as total FROM clients ${whereClause}`;
    const countRes = await query(countSql, values);
    const total = parseInt(countRes.rows[0].total, 10);

    const dataSql = `SELECT * FROM clients ${whereClause} ORDER BY ${orderBy} LIMIT $${idx} OFFSET $${idx + 1}`;
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
    const res = await query('SELECT * FROM clients WHERE id = $1', [id]);
    return res.rows[0] || null;
  }

  async create(data: CreateClientInput) {
    const id = uuidv4();
    const metadataJson = JSON.stringify(data.metadata || {});

    const res = await query(
      `INSERT INTO clients (
        id, name, contact_name, email, phone, platform, location,
        status, notes, metadata, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10::jsonb, NOW(), NOW()
      ) RETURNING *`,
      [
        id,
        data.name.trim(),
        data.contact_name?.trim() || null,
        data.email?.trim() || null,
        data.phone?.trim() || null,
        data.platform?.trim() || null,
        data.location?.trim() || null,
        data.status || 'PROSPECT',
        data.notes || null,
        metadataJson,
      ]
    );

    return res.rows[0];
  }

  async update(id: string, data: UpdateClientInput) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    for (const [key, val] of Object.entries(data)) {
      if (val === undefined) continue;

      if (key === 'metadata') {
        fields.push(`metadata = $${idx}::jsonb`);
        values.push(JSON.stringify(val));
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

    const sql = `UPDATE clients SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`;
    const res = await query(sql, values);
    return res.rows[0] || null;
  }

  async delete(id: string) {
    const res = await query('DELETE FROM clients WHERE id = $1 RETURNING id', [id]);
    return (res.rowCount ?? 0) > 0;
  }
}

export const clientsRepository = new ClientsRepository();
