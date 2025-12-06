export interface AddNewBookDTO {
    Name: string;
    AuthorName: string;
    Edition?: string;
    Genre?: string;
    TotalCopies: number;
    AvailableCopies?: number;
}

export interface UpdateBookDTO {
    Name?: string;
    AuthorName?: string;
    Edition?: string;
    Genre?: string;
    TotalCopies?: number;
    AvailableCopies?: number;
}