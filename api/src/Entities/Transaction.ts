export class Transaction {
    id?: string;
    studentReg: string;
    bookId: string;
    librarianId?: string;
    borrowedDate: Date;
    dueDate: Date;
    returnDate?: Date;
    CreatedAt?: Date;
    status: 'ISSUED' | 'RETURNED' | 'OVERDUE' | 'REQUESTED';
    lateFee?: number;
    studentName?: string;
    bookTitle?: string;
    bookAuthor?: string;

    constructor(data: Partial<Transaction>) {
        this.id = data.id;
        this.studentReg = data.studentReg || "";
        this.bookId = data.bookId || "";
        this.librarianId = data.librarianId;
        this.borrowedDate = data.borrowedDate ? new Date(data.borrowedDate) : new Date();
        this.dueDate = data.dueDate ? new Date(data.dueDate) : new Date();
        this.returnDate = data.returnDate ? new Date(data.returnDate) : undefined;
        this.CreatedAt = data.CreatedAt ? new Date(data.CreatedAt) : new Date();
        this.status = data.status || 'REQUESTED';
        this.lateFee = data.lateFee || 0;
        this.studentName = data.studentName;
        this.bookTitle = data.bookTitle;
        this.bookAuthor = data.bookAuthor;
    }
} 