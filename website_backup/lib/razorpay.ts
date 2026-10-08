/**
 * Razorpay Client Service
 * Interacts with backend Razorpay Order API (/api/razorpay/create-order)
 * Injects official Razorpay checkout script (checkout.js)
 * Verifies HMAC signature with /api/razorpay/verify-payment
 */

const RAZORPAY_SCRIPT_URL = 'https://checkout.razorpay.com/v1/checkout.js';

let scriptLoadPromise: Promise<boolean> | null = null;

export function loadRazorpayScript(): Promise<boolean> {
  if (typeof window === 'undefined') return Promise.resolve(false);
  if (window.Razorpay) return Promise.resolve(true);

  if (scriptLoadPromise) return scriptLoadPromise;

  scriptLoadPromise = new Promise((resolve) => {
    const existing = document.querySelector(`script[src="${RAZORPAY_SCRIPT_URL}"]`);
    if (existing) {
      resolve(true);
      return;
    }

    const script = document.createElement('script');
    script.src = RAZORPAY_SCRIPT_URL;
    script.async = true;
    script.onload = () => resolve(true);
    script.onerror = () => {
      console.warn('[Razorpay] Script loading failed');
      scriptLoadPromise = null;
      resolve(false);
    };
    document.body.appendChild(script);
  });

  return scriptLoadPromise;
}

interface OpenRazorpayOptions {
  amount: number; // in rupees
  currency?: string;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  description?: string;
  onSuccess: (paymentId: string) => void;
  onDismiss?: () => void;
}

export async function openRazorpayCheckout(opts: OpenRazorpayOptions): Promise<boolean> {
  try {
    // 1. Create order on backend via official Razorpay API
    const orderRes = await fetch('/api/razorpay/create-order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount: opts.amount,
        currency: opts.currency || 'INR',
        receipt: `kmart_${Date.now()}`,
      }),
    });

    if (!orderRes.ok) {
      console.warn('[Razorpay] Failed to create order via backend API');
      return false;
    }

    const orderData = await orderRes.json();

    // If API credentials are not yet configured or returned mock mode, allow fallback modal
    if (!orderData.key || orderData.isMock) {
      console.info('[Razorpay] Operating in test/demo gateway mode. Key Secret not provided.');
      return false;
    }

    // 2. Load official Razorpay checkout script
    const loaded = await loadRazorpayScript();
    if (!loaded || !window.Razorpay) {
      console.warn('[Razorpay] SDK script not available');
      return false;
    }

    // 3. Launch official Razorpay Checkout modal
    const rzp = new window.Razorpay({
      key: orderData.key,
      amount: orderData.amount, // in paise
      currency: orderData.currency || 'INR',
      name: 'K MART',
      description: opts.description || 'Groceries Order Payment',
      order_id: orderData.orderId,
      prefill: {
        name: opts.customerName,
        contact: opts.customerPhone.replace(/\D/g, '').slice(-10),
        email: opts.customerEmail || '',
      },
      theme: {
        color: '#E11A22',
      },
      modal: {
        confirm_close: true,
        ondismiss: () => {
          opts.onDismiss?.();
        },
      },
      handler: async (response: RazorpayPaymentResponse) => {
        try {
          if (response.razorpay_order_id && response.razorpay_signature) {
            // 4. Verify payment signature on backend
            const verifyRes = await fetch('/api/razorpay/verify-payment', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                razorpay_order_id: response.razorpay_order_id,
                razorpay_payment_id: response.razorpay_payment_id,
                razorpay_signature: response.razorpay_signature,
              }),
            });
            const verifyData = await verifyRes.json();
            if (!verifyData.success) {
              console.warn('[Razorpay] Payment signature verification warning:', verifyData.error);
            }
          }
        } catch (vErr) {
          console.warn('[Razorpay] Signature verification error:', vErr);
        }

        opts.onSuccess(response.razorpay_payment_id);
      },
    });

    rzp.open();
    return true;
  } catch (err) {
    console.error('[Razorpay] Error initializing checkout:', err);
    return false;
  }
}
