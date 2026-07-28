import { ResultSetHeader, RowDataPacket } from "mysql2";
import pool from "../config/database.js";
import { INotificationRepository } from "../Interfaces/INotificationRepository.js";
import { Notification } from "../Entities/Notification.js";

export class MySQLNotificationRepository implements INotificationRepository {
    async findByTransactionAndType(transactionId: number, type: "due_reminder" | "overdue_reminder"): Promise<Notification | null> {
        try {
            const [rows] = await pool.execute<RowDataPacket[]>(
                "SELECT * FROM notifications WHERE transactionId = ? AND type = ? LIMIT 1",
                [transactionId, type]
            );
            if (rows.length === 0) {
                return null;
            }
            return new Notification({
                id: rows[0].id,
                transactionId: rows[0].transactionId,
                type: rows[0].type,
                sentAt: rows[0].sentAt
            });
        } catch (error) {
            console.log("Error finding notification:", error);
            return null;
        }
    }

    async upsert(transactionId: number, type: "due_reminder" | "overdue_reminder"): Promise<void> {
        try {
            await pool.execute<ResultSetHeader>(
                "INSERT INTO notifications (transactionId, type) VALUES (?, ?) ON DUPLICATE KEY UPDATE sentAt = NOW()",
                [transactionId, type]
            );
        } catch (error) {
            console.log("Error upserting notification:", error);
        }
    }
}