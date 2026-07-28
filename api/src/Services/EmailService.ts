import axios from "axios";

const API_KEY = process.env.MAILGUN_API_KEY || "";
const DOMAIN = process.env.MAILGUN_DOMAIN || "";
const FROM_EMAIL = process.env.MAILGUN_FROM_EMAIL || "noreply@arksabit.tech";

const mailgunBaseUrl = `https://api.mailgun.net/v3/${DOMAIN}`;

/**
 * Reusable HTML Layout Wrapper
 */
function renderEmailTemplate({
    title,
    badgeColor,
    badgeText,
    contentHtml,
}: {
    title: string;
    badgeColor: string;
    badgeText: string;
    contentHtml: string;
}): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f1f5f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #f1f5f9; padding: 40px 0;">
        <tr>
            <td align="center">
                <!-- Outer Container -->
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width: 560px; background-color: #ffffff; border-radius: 12px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05);">
                    
                    <!-- Header -->
                    <tr>
                        <td style="padding: 32px 32px 24px 32px; border-bottom: 1px solid #f1f5f9;">
                            <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td>
                                        <span style="font-size: 18px; font-weight: 700; color: #0f172a; letter-spacing: -0.02em; display: inline-block;">
                                            📚 Library Manager
                                        </span>
                                    </td>
                                    <td align="right">
                                        <span style="display: inline-block; background-color: ${badgeColor}15; color: ${badgeColor}; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">
                                            ${badgeText}
                                        </span>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <!-- Body Content -->
                    <tr>
                        <td style="padding: 32px;">
                            ${contentHtml}
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8fafc; padding: 24px 32px; text-align: center; border-top: 1px solid #f1f5f9;">
                            <p style="margin: 0 0 6px 0; color: #64748b; font-size: 13px; font-weight: 500;">
                                Questions? Visit your library/dashboard.
                            </p>
                            <p style="margin: 0; color: #94a3b8; font-size: 12px;">
                                &copy; ${new Date().getFullYear()} Library Management System. All rights reserved.
                            </p>
                        </td>
                    </tr>

                </table>
            </td>
        </tr>
    </table>
</body>
</html>`;
}

export class EmailService {
    private from: string;

    constructor() {
        this.from = FROM_EMAIL;
    }

    private async send(to: string, subject: string, text: string, html?: string): Promise<void> {
        try {
            const params = new URLSearchParams();
            params.set("from", this.from);
            params.set("to", to);
            params.set("subject", subject);
            params.set("text", text);
            if (html) {
                params.set("html", html);
            }

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

    async sendDueReminder(email: string, studentName: string, bookTitle: string, dueDate: string): Promise<void> {
        const subject = `Reminder: "${bookTitle}" is due soon`;
        const text = `Hello ${studentName},\n\nThis is a reminder that the book "${bookTitle}" is due on ${dueDate}.\n\nPlease return it on time to avoid any overdue fees.\n\nThank you,\nLibrary Manager`;

        const contentHtml = `
            <h1 style="margin: 0 0 16px 0; font-size: 20px; font-weight: 700; color: #0f172a; line-height: 1.3;">
                Upcoming Due Date
            </h1>
            <p style="margin: 0 0 24px 0; font-size: 15px; color: #475569; line-height: 1.6;">
                Hi <strong>${studentName}</strong>, this is a quick reminder that your borrowed item is due in <strong>2 days</strong>.
            </p>

            <!-- Book Card -->
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; margin-bottom: 24px;">
                <tr>
                    <td>
                        <div style="font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 4px;">Book Title</div>
                        <div style="font-size: 16px; font-weight: 600; color: #0f172a; margin-bottom: 12px;">"${bookTitle}"</div>
                        <div style="font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 4px;">Due Date</div>
                        <div style="font-size: 15px; font-weight: 600; color: #2563eb;">${dueDate}</div>
                    </td>
                </tr>
            </table>

            <!-- Warning Callout -->
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #fefce8; border-left: 4px solid #eab308; border-radius: 4px; padding: 12px 16px; margin-bottom: 24px;">
                <tr>
                    <td style="color: #854d0e; font-size: 14px; line-height: 1.5;">
                        ⚠️ Please return or renew this book on or before the due date to prevent any late fees.
                    </td>
                </tr>
            </table>
        `;

        const html = renderEmailTemplate({
            title: subject,
            badgeColor: "#d97706",
            badgeText: "Due Soon",
            contentHtml,
        });

        await this.send(email, subject, text, html);
    }

    async sendOverdueReminder(email: string, studentName: string, bookTitle: string, dueDate: string): Promise<void> {
        const subject = `Overdue Notice: "${bookTitle}" was due on ${dueDate}`;
        const text = `Hello ${studentName},\n\nThe book "${bookTitle}" was due on ${dueDate} and is now overdue.\n\nPlease return it as soon as possible to avoid further penalties.\n\nThank you,\nLibrary Manager`;

        const contentHtml = `
            <h1 style="margin: 0 0 16px 0; font-size: 20px; font-weight: 700; color: #0f172a; line-height: 1.3;">
                Item Overdue
            </h1>
            <p style="margin: 0 0 24px 0; font-size: 15px; color: #475569; line-height: 1.6;">
                Hi <strong>${studentName}</strong>, our records show that a book checked out to your account has passed its return date.
            </p>

            <!-- Book Card -->
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; margin-bottom: 24px;">
                <tr>
                    <td>
                        <div style="font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 4px;">Book Title</div>
                        <div style="font-size: 16px; font-weight: 600; color: #0f172a; margin-bottom: 12px;">"${bookTitle}"</div>
                        <div style="font-size: 11px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 4px;">Was Due On</div>
                        <div style="font-size: 15px; font-weight: 600; color: #dc2626;">${dueDate}</div>
                    </td>
                </tr>
            </table>

            <!-- Critical Callout -->
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color: #fef2f2; border-left: 4px solid #dc2626; border-radius: 4px; padding: 12px 16px; margin-bottom: 24px;">
                <tr>
                    <td style="color: #991b1b; font-size: 14px; line-height: 1.5;">
                        🚨 Overdue items may accumulate daily late fees. Please return this item to the circulation desk immediately.
                    </td>
                </tr>
            </table>
        `;

        const html = renderEmailTemplate({
            title: subject,
            badgeColor: "#dc2626",
            badgeText: "Overdue",
            contentHtml,
        });

        await this.send(email, subject, text, html);
    }
}

export const emailService = new EmailService();