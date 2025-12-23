export interface CreateStudentDTO {
  Name: string;
  Roll: string;
  Registration: string;
  Department: string;
  Session: string;
  ContactNumber: string;
  Address: string;
  Email: string;
  Password: string;
}

export interface UpdateStudentDTO {
  Name?: string;
  Roll?: string;
  Registration?: string;
  Department?: string;
  Session?: string;
  ContactNumber?: string;
  Address?: string;
  Email?: string;
  Password?: string;
}
