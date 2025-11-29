export interface AddNewBookDTO{
    Id?: String;
    Name: String;
    AuthorName: String;
    Edition?: String;
    Genre?: String;
    TotalCopies: Number;
    AvailableCopies: Number
}