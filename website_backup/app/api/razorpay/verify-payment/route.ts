import { NextResponse } from 'next/server';
import crypto from 'crypto';

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = body;

    const keySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!keySecret) {
      // Development mode without secret key: accept payment
      return NextResponse.json({
        success: true,
        verified: true,
        isMock: true,
        message: 'Signature verified in test simulation mode',
      });
    }

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return NextResponse.json(
        { success: false, error: 'Missing required signature verification fields' },
        { status: 400 }
      );
    }

    // Verify HMAC SHA256 signature
    const text = `${razorpay_order_id}|${razorpay_payment_id}`;
    const generatedSignature = crypto
      .createHmac('sha256', keySecret)
      .update(text)
      .digest('hex');

    const isValid = generatedSignature === razorpay_signature;

    if (isValid) {
      return NextResponse.json({
        success: true,
        verified: true,
        paymentId: razorpay_payment_id,
        orderId: razorpay_order_id,
      });
    } else {
      console.warn('[Razorpay API verify-payment] Signature mismatch');
      return NextResponse.json(
        {
          success: false,
          verified: false,
          error: 'Invalid payment signature',
        },
        { status: 400 }
      );
    }
  } catch (error: any) {
    console.error('[Razorpay API verify-payment] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message || 'Signature verification failed',
      },
      { status: 500 }
    );
  }
}
