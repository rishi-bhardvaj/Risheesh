export interface OutboxItem {
  id: string; // Idempotency key
  url: string;
  payload: Record<string, unknown>;
  attempts: number;
  createdAt: number;
}

export class OutboxQueue {
  private items: OutboxItem[] = [];

  enqueue(item: OutboxItem): void {
    this.items.push(item);
  }

  getPending(): OutboxItem[] {
    return [...this.items];
  }

  acknowledge(id: string): void {
    this.items = this.items.filter((i) => i.id !== id);
  }

  get length(): number {
    return this.items.length;
  }
}
