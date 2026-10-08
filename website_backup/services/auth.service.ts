import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

function normalizeIndianPhone(phone: string) {
  const digits = phone.replace(/\D/g, "");

  if (digits.length === 10) {
    return `+91${digits}`;
  }

  if (digits.length === 12 && digits.startsWith("91")) {
    return `+${digits}`;
  }

  return phone;
}

export const authService = {
  async sendOtp(phone: string) {
    const supabase = createSupabaseBrowserClient();

    return supabase.auth.signInWithOtp({
      phone: normalizeIndianPhone(phone),
    });
  },

  async verifyOtp(phone: string, otp: string) {
    const supabase = createSupabaseBrowserClient();

    return supabase.auth.verifyOtp({
      phone: normalizeIndianPhone(phone),
      token: otp,
      type: "sms",
    });
  },

  async getCurrentUser() {
    const supabase = createSupabaseBrowserClient();

    return supabase.auth.getUser();
  },

  async signOut() {
    const supabase = createSupabaseBrowserClient();
    await supabase.auth.signOut();
    try {
      await fetch("/api/auth/logout", {
        method: "POST",
      });
    } catch {
      // Server route fallback
    }
  },
};
