import { MySQLTransactionRepository } from "../Repositories/MySQLBorrowRepository.js";
import { MySQLNotificationRepository } from "../Repositories/MySQLNotificationRepository.js";
import { emailService } from "../Services/EmailService.js";

const repository = new MySQLTransactionRepository();
const notificationRepo = new MySQLNotificationRepository();

const CHECK_INTERVAL_MS = 60 * 60 * 1000;

function getToday(): string {
    return new Date().toISOString().split("T")[0];
}

async function checkDueReminders(): Promise<void> {
    try {
        const today = getToday();
        const twoDaysFromNow = new Date();
        twoDaysFromNow.setDate(twoDaysFromNow.getDate() + 2);
        const twoDaysStr = twoDaysFromNow.toISOString().split("T")[0];

        const transactions = await repository.GetAllTransactionsByStatus("ISSUED");

        for (const txn of transactions) {
            if (!txn.dueDate || !txn.studentEmail || !txn.id) continue;

            const dueDateStr = new Date(txn.dueDate).toISOString().split("T")[0];

            if (dueDateStr >= today && dueDateStr <= twoDaysStr) {
                const existing = await notificationRepo.findByTransactionAndType(Number(txn.id), "due_reminder");
                if (existing) continue;

                await emailService.sendDueReminder(
                    txn.studentEmail,
                    txn.bookTitle || "a borrowed book",
                    dueDateStr
                );
                await notificationRepo.upsert(Number(txn.id), "due_reminder");
            }
        }
    } catch (error) {
        console.error("Error checking due reminders:", error);
    }
}

async function checkOverdueReminders(): Promise<void> {
    try {
        const today = getToday();
        const transactions = await repository.GetAllTransactionsByStatus("ISSUED");

        for (const txn of transactions) {
            if (!txn.dueDate || !txn.studentEmail || !txn.id) continue;

            const dueDateStr = new Date(txn.dueDate).toISOString().split("T")[0];

            if (dueDateStr < today) {
                const existing = await notificationRepo.findByTransactionAndType(Number(txn.id), "overdue_reminder");
                if (existing) continue;

                await emailService.sendOverdueReminder(
                    txn.studentEmail,
                    txn.bookTitle || "a borrowed book",
                    dueDateStr
                );
                await notificationRepo.upsert(Number(txn.id), "overdue_reminder");
            }
        }
    } catch (error) {
        console.error("Error checking overdue reminders:", error);
    }
}

async function runCheck(): Promise<void> {
    console.log("[EmailScheduler] Running scheduled email check...");
    await checkDueReminders();
    await checkOverdueReminders();
}

export function startEmailScheduler(): void {
    console.log("[EmailScheduler] Starting email notification scheduler...");
    runCheck();
    setInterval(runCheck, CHECK_INTERVAL_MS);
}