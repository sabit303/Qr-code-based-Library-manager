import { createCanvas } from 'canvas';
import QRCode from 'qrcode';

export class QRCodeService {
  async generate(data: string): Promise<string> {
    try {
      // Generate actual QR code as PNG buffer
      const qrImageBuffer = await QRCode.toBuffer(data, {
        errorCorrectionLevel: 'H',
        type: 'image/png',
        width: 300,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#FFFFFF',
        },
      });

      // Convert buffer to base64
      return qrImageBuffer.toString('base64');
    } catch (error) {
      console.error('QR code generation error:', error);
      // Fallback to simple string-based QR if actual generation fails
      const encoded = Buffer.from(data).toString('base64');
      return `QR-${encoded}-${Date.now()}`;
    }
  }

  async verify(qrCode: string): Promise<boolean> {
    // Verify QR code format
    return qrCode.startsWith('QR-') || this.isBase64(qrCode);
  }

  private isBase64(str: string): boolean {
    try {
      return Buffer.from(str, 'base64').toString('base64') === str;
    } catch (err) {
      return false;
    }
  }

  async decode(qrCode: string): Promise<string | null> {
    try {
      // Extract the base64 part from QR-{base64}-{timestamp}
      if (qrCode.startsWith('QR-')) {
        const parts = qrCode.split('-');
        if (parts.length < 2) return null;
        
        const decoded = Buffer.from(parts[1], 'base64').toString('utf-8');
        return decoded;
      }
      return null;
    } catch (error) {
      return null;
    }
  }
}
