export interface AddNewBookDTO {
    Name: string;
    AuthorName: string;
    Edition?: string;
    Genre?: string;
    TotalCopies: number;
    AvailableCopies?: number;
    CoverUrl?: string;
}

export interface UpdateBookDTO {
    Name?: string;
    AuthorName?: string;
    Edition?: string;
    Genre?: string;
    TotalCopies?: number;
    AvailableCopies?: number;
    CoverUrl?: string;
}

export interface RequestNewBookDTO {
    bookID: string,
    StudentReg: string,
    returnDate?: string
}