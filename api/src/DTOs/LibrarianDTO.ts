export interface CreateLibrarianDTO {
  name: string;
  contact?: string;
  email: string;
  password: string;
}

export interface UpdateLibrarianDTO {
  name?: string;
  contact?: string;
  email?: string;
  password?: string;
}
