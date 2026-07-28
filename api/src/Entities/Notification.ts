export class Notification {
    id?: number;
    transactionId: number;
    type: 'due_reminder' | 'overdue_reminder';
    sentAt?: Date;

    constructor(data: Partial<Notification>) {
        this.id = data.id;
        this.transactionId = data.transactionId || 0;
        this.type = data.type || 'due_reminder';
        this.sentAt = data.sentAt ? new Date(data.sentAt) : undefined;
    }
}