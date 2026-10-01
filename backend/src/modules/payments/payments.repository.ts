import { query } from '../../db';
import { v4 as uuidv4 } from 'uuid';
import { CreatePaymentInput, UpdatePaymentInput, QueryPaymentsInput } from './payments.schema';

export class PaymentsRepository {
  async findMany(params: QueryPaymentsInput) {
    const { page = 1, limit = 50, client_id, project_id, status, sort = 'newest' } = params;
    const offset = (page - 1) * limit;
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (client_id) {
      conditions.push(`client_id = $${idx}`);
      values.push(client_id);
      idx++;
    }

    if (project_id) {
      conditions.push(`project_id = $${idx}`);
      values.push(project_id);
      idx++;
    }

    if (status) {
      conditions.push(`status = $${idx}`);
      values.push(status);
      idx++;
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    let orderBy = 'payment_date DESC';
    if (sort === 'oldest') orderBy = 'payment_date ASC';
    else if (sort === 'amount') orderBy = 'amount DESC';

    const countSql = `SELECT COUNT(*) as total FROM freelance_payments ${whereClause}`;
    const countRes = await query(countSql, values);
    const total = parseInt(countRes.rows[0].total, 10);

    const dataSql = `SELECT * FROM freelance_payments ${whereClause} ORDER BY ${orderBy} LIMIT $${idx} OFFSET $${idx + 1}`;
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
    const res = await query('SELECT * FROM freelance_payments WHERE id = $1', [id]);
    return res.rows[0] || null;
  }

  async create(data: CreatePaymentInput) {
    const id = uuidv4();
    const res = await query(
      `INSERT INTO freelance_payments (
        id, client_id, project_id, amount, currency, payment_date,
        status, description, notes, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6,
        $7, $8, $9, NOW(), NOW()
      ) RETURNING *`,
      [
        id,
        data.client_id,
        data.project_id || null,
        data.amount,
        data.currency || 'USD',
        data.payment_date ? new Date(data.payment_date) : new Date(),
        data.status || 'EXPECTED',
        data.description?.trim() || null,
        data.notes || null,
      ]
    );

    return res.rows[0];
  }

  async update(id: string, data: UpdatePaymentInput) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    for (const [key, val] of Object.entries(data)) {
      if (val === undefined) continue;

      if (key === 'payment_date') {
        fields.push(`payment_date = $${idx}`);
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

    const sql = `UPDATE freelance_payments SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`;
    const res = await query(sql, values);
    return res.rows[0] || null;
  }

  async delete(id: string) {
    const res = await query('DELETE FROM freelance_payments WHERE id = $1 RETURNING id', [id]);
    return (res.rowCount ?? 0) > 0;
  }
}

export const paymentsRepository = new PaymentsRepository();
