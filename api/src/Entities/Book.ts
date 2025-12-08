

export class Book{
    Id?: String;
    Name: String;
    AuthorName: String;
    Edition?: String;
    Genre?: String;
    TotalCopies: Number;
    AvailableCopies: Number

    constructor(data: Partial<Book>) {
        this.Id = data.Id 
        this.Name = data.Name || "";
        this.AuthorName = data.AuthorName || "";
        this.Edition = data.Edition||"";
        this.Genre = data.Genre||"";
        this.TotalCopies = data.TotalCopies || 0;
        this.AvailableCopies = data.AvailableCopies ?? data.TotalCopies ?? 0;
     
    }
}