export interface CreateStudentDTO {
  Roll: string;
  Registration: string;
  Name: string;
  Department?: string;
  Session?: string;
  ContactNumber?: string;
  Address?: string;
  Email?: string;
  Password?: string;
  PhotoUrl?: string;
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
  PhotoUrl?: string;
}
