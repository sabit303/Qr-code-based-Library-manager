import axios from "axios";

const API_KEY = process.env.MAILGUN_API_KEY || "";
const DOMAIN = process.env.MAILGUN_DOMAIN || "";
const FROM_EMAIL = process.env.MAILGUN_FROM_EMAIL || "noreply@librarymanager.com";

const mailgunBaseUrl = `https://api.mailgun.net/v3/${DOMAIN}`;

export class EmailService {
    private from: string;

    constructor() {
        this.from = FROM_EMAIL;
    }

    private async send(to: string, subject: string, text: string): Promise<void> {
        try {
            const params = new URLSearchParams();
            params.set("from", this.from);
            params.set("to", to);
            params.set("subject", subject);
            params.set("text", text);

            await axios.post(
                `${mailgunBaseUrl}/messages`,
                params.toString(),
                {
                    auth: {
                        username: "api",
                        password: API_KEY
                    },
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded"
                    }
                }
            );
            console.log(`Email sent to ${to}: ${subject}`);
        } catch (error) {
            console.error("Failed to send email:", error);
        }
    }

    async sendDueReminder(email: string, bookTitle: string, dueDate: string): Promise<void> {
        const subject = `Reminder: "${bookTitle}" is due in 2 days`;
        const text = `Hello,\n\nThis is a reminder that the book "${bookTitle}" is due on ${dueDate}.\n\nPlease return it on time to avoid any overdue fees.\n\nThank you,\nLibrary Manager`;
        await this.send(email, subject, text);
    }

    async sendOverdueReminder(email: string, bookTitle: string, dueDate: string): Promise<void> {
        const subject = `Overdue: "${bookTitle}" was due on ${dueDate}`;
        const text = `Hello,\n\nThe book "${bookTitle}" was due on ${dueDate} and is now overdue.\n\nPlease return it as soon as possible to avoid further penalties.\n\nThank you,\nLibrary Manager`;
        await this.send(email, subject, text);
    }
}

export const emailService = new EmailService();