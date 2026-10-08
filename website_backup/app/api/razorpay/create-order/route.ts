import { NextResponse } from 'next/server';
import Razorpay from 'razorpay';

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { amount, currency = 'INR', receipt } = body;

    const keyId = process.env.RAZORPAY_KEY_ID || process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;

    // In paise (1 INR = 100 paise)
    const amountInPaise = Math.round(Number(amount) * 100);

    // If real credentials are provided, call Razorpay Orders API
    if (keyId && keySecret) {
      const razorpay = new Razorpay({
        key_id: keyId,
        key_secret: keySecret,
      });

      const order = await razorpay.orders.create({
        amount: amountInPaise,
        currency,
        receipt: receipt || `rcpt_${Date.now()}`,
        payment_capture: true,
      });

      return NextResponse.json({
        success: true,
        isMock: false,
        key: keyId,
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
      });
    }

    // Fallback: If Key Secret is missing, return mock order for development/demo mode
    const mockOrderId = `order_${Math.random().toString(36).substring(2, 12)}`;
    return NextResponse.json({
      success: true,
      isMock: true,
      key: keyId || '',
      orderId: mockOrderId,
      amount: amountInPaise,
      currency,
      message: 'Razorpay Key Secret not configured in .env.local; operating in simulation mode.',
    });
  } catch (error: any) {
    console.error('[Razorpay API create-order] Error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message || 'Failed to create Razorpay order',
      },
      { status: 500 }
    );
  }
}
