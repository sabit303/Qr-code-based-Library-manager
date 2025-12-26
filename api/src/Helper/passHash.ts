import bcrypt from 'bcryptjs';

export class PasswordHasher {
  private readonly SALT_ROUNDS = 10;


   async hashPassword(password: string): Promise<string> {
    return await bcrypt.hash(password, this.SALT_ROUNDS);
  }

   async verifyPassword(password: string, storedHash: string): Promise<boolean> {
    try {
      return await bcrypt.compare(password, storedHash);
    } catch (error) {
      return false;
    }
  }
}
