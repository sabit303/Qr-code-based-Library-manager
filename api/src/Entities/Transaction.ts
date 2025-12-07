export class Transaction {
    id?: string;
    studentReg: string;
    bookId: string;
    librarianId?: string;
    borrowedDate: Date;
    dueDate: Date;
    returnDate?: Date;
    status: 'ISSUED' | 'RETURNED' | 'OVERDUE';
    lateFee?: number;

    constructor(data: Partial<Transaction>) {
        this.id = data.id;
        this.studentReg = data.studentReg || "";
        this.bookId = data.bookId || "";
        this.librarianId = data.librarianId;
        this.borrowedDate = data.borrowedDate || new Date();
        this.dueDate = data.dueDate || new Date();
        this.returnDate = data.returnDate;
        this.status = data.status || 'ISSUED';
        this.lateFee = data.lateFee || 0;
    }
} 