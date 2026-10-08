"use client";

import { FormEvent, useState, useEffect, useRef } from "react";
import { ArrowRight, ArrowLeft, Loader2, ShieldCheck, Edit2, CheckCircle2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { authService } from "@/services/auth.service";
import { useApp } from "@/context/AppContext";

export default function LoginForm() {
  const router = useRouter();
  const { setUser } = useApp();

  const [step, setStep] = useState<"phone" | "otp">("phone");
  const [phone, setPhone] = useState("");
  const [otpDigits, setOtpDigits] = useState<string[]>(["", "", "", "", "", ""]);
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState("");
  const [seconds, setSeconds] = useState(30);

  const phoneInputRef = useRef<HTMLInputElement>(null);
  const digitRefs = useRef<(HTMLInputElement | null)[]>([]);

  // Focus phone input on mount
  useEffect(() => {
    phoneInputRef.current?.focus();
  }, []);

  // Timer countdown for OTP resend
  useEffect(() => {
    if (step !== "otp" || seconds <= 0) return;
    const timer = window.setInterval(() => {
      setSeconds((prev) => prev - 1);
    }, 1000);
    return () => window.clearInterval(timer);
  }, [step, seconds]);

  // Handle Send OTP
  async function handleSendOtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");

    const digits = phone.replace(/\D/g, "");
    if (digits.length !== 10) {
      setError("Please enter a valid 10-digit mobile number.");
      return;
    }

    setLoading(true);
    try {
      const { error: sendError } = await authService.sendOtp(phone);
      if (sendError) {
        // Supabase returns an error if phone auth is not enabled,
        // but we still proceed to OTP step for flow continuity
        console.warn("[LoginForm] sendOtp notice:", sendError.message);
        if (
          sendError.message.toLowerCase().includes("phone") &&
          sendError.message.toLowerCase().includes("not")
        ) {
          setError("SMS not configured. Please contact support.");
          setLoading(false);
          return;
        }
      }
    } catch (e: any) {
      console.warn("[LoginForm] sendOtp exception:", e?.message);
    } finally {
      setLoading(false);
    }

    // Move to OTP step
    setStep("otp");
    setSeconds(30);
    setOtpDigits(["", "", "", "", "", ""]);
    setTimeout(() => {
      digitRefs.current[0]?.focus();
    }, 100);
  }

  // Handle individual OTP digit change
  const handleDigitChange = (index: number, val: string) => {
    const numeric = val.replace(/\D/g, "");
    if (!numeric && val !== "") return;

    const newDigits = [...otpDigits];

    // Handle paste (6 digits at once)
    if (numeric.length > 1) {
      const pasted = numeric.slice(0, 6).split("");
      for (let i = 0; i < 6; i++) {
        newDigits[i] = pasted[i] || "";
      }
      setOtpDigits(newDigits);
      const nextIndex = Math.min(pasted.length, 5);
      digitRefs.current[nextIndex]?.focus();
      return;
    }

    newDigits[index] = numeric.slice(-1);
    setOtpDigits(newDigits);

    // Auto-advance to next box
    if (numeric && index < 5) {
      digitRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !otpDigits[index] && index > 0) {
      digitRefs.current[index - 1]?.focus();
    }
  };

  // Handle OTP verification (real Supabase verification)
  async function handleVerifyOtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const fullOtp = otpDigits.join("");

    if (fullOtp.length !== 6) {
      setError("Please enter the complete 6-digit code.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const { data, error: verifyError } = await authService.verifyOtp(phone, fullOtp);

      if (verifyError) {
        setError(
          verifyError.message.includes("Token has expired")
            ? "OTP expired. Please request a new one."
            : verifyError.message.includes("Invalid") || verifyError.message.includes("invalid")
            ? "Incorrect OTP. Please try again."
            : `Verification failed: ${verifyError.message}`
        );
        setLoading(false);
        return;
      }

      // Success — session is now set. AppContext's onAuthStateChange will fire
      // and call syncCustomerProfile automatically.
      // We just update the local user state for instant UI feedback.
      if (data?.user) {
        const supaPhone = data.user.phone || `+91${phone.replace(/\D/g, "")}`;
        setUser((prev) => ({
          ...prev,
          phone: supaPhone,
          isVerified: true,
        }));
      }

      router.push("/");
      router.refresh();
    } catch (e: any) {
      setError("Something went wrong. Please try again.");
      console.warn("[LoginForm] verifyOtp exception:", e?.message);
      setLoading(false);
    }
  }

  // Handle Resend OTP
  async function handleResendOtp() {
    if (seconds > 0 || !phone) return;
    setResending(true);
    setError("");
    try {
      await authService.sendOtp(phone);
    } catch {
      // ignore
    }
    setOtpDigits(["", "", "", "", "", ""]);
    setSeconds(30);
    setResending(false);
    digitRefs.current[0]?.focus();
  }

  const maskedPhone =
    phone.length >= 10
      ? `+91 ${phone.slice(0, 2)}••••••${phone.slice(-2)}`
      : phone;

  return (
    <div>
      {step === "phone" ? (
        /* ─── STEP 1: Phone Number ─── */
        <div>
          <div className="mb-6 text-left">
            <h2 className="text-2xl font-black text-[#0A2540] tracking-tight">
              Welcome to K MART
            </h2>
            <p className="mt-1.5 text-sm text-gray-500 font-medium leading-relaxed">
              Enter your 10-digit mobile number to receive a verification code via SMS.
            </p>
          </div>

          <form onSubmit={handleSendOtp} className="space-y-4">
            <div>
              <label
                htmlFor="phone"
                className="mb-1.5 block text-xs font-bold text-gray-700 uppercase tracking-wider text-left"
              >
                Mobile Number
              </label>

              <div className="flex items-center rounded-xl border-2 border-gray-200 bg-gray-50/50 transition-all focus-within:border-[#E11A22] focus-within:bg-white focus-within:ring-4 focus-within:ring-red-50">
                <div className="flex items-center gap-1.5 border-r border-gray-200 px-3.5 py-3.5 text-sm font-black text-[#0A2540] select-none shrink-0">
                  <span className="text-base leading-none">🇮🇳</span>
                  <span>+91</span>
                </div>

                <input
                  ref={phoneInputRef}
                  id="phone"
                  type="tel"
                  inputMode="numeric"
                  autoComplete="tel"
                  maxLength={10}
                  value={phone}
                  onChange={(e) => setPhone(e.target.value.replace(/\D/g, ""))}
                  placeholder="98765 43210"
                  className="w-full flex-1 border-0 bg-transparent px-3 py-3.5 text-base font-bold tracking-wider text-[#0A2540] placeholder:font-normal placeholder:tracking-normal placeholder:text-gray-400 outline-none"
                />

                {phone.length === 10 && (
                  <CheckCircle2 className="w-5 h-5 text-emerald-500 mr-3 shrink-0" />
                )}
              </div>
            </div>

            {error && (
              <div className="rounded-xl bg-red-50 border border-red-200 p-3 text-xs font-bold text-[#E11A22] flex items-center gap-2 text-left">
                <span>⚠️</span>
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading || phone.replace(/\D/g, "").length < 10}
              className="w-full flex items-center justify-center gap-2 rounded-xl bg-[#E11A22] hover:bg-[#c8141b] py-3.5 px-4 font-black text-sm text-white shadow-md hover:shadow-lg transition-all transform hover:-translate-y-0.5 disabled:opacity-50 disabled:pointer-events-none disabled:transform-none cursor-pointer"
            >
              {loading ? (
                <>
                  <Loader2 size={18} className="animate-spin" />
                  <span>Sending OTP...</span>
                </>
              ) : (
                <>
                  <span>Get OTP</span>
                  <ArrowRight size={18} />
                </>
              )}
            </button>
          </form>

          <p className="mt-5 text-center text-[11px] leading-relaxed text-gray-400 font-medium">
            By continuing, you agree to K MART's{" "}
            <span className="text-gray-600 font-bold underline cursor-pointer">Terms of Service</span>{" "}
            and{" "}
            <span className="text-gray-600 font-bold underline cursor-pointer">Privacy Policy</span>.
          </p>
        </div>
      ) : (
        /* ─── STEP 2: OTP Verification ─── */
        <div>
          {/* Top bar */}
          <div className="flex items-center justify-between mb-5 pb-3 border-b border-gray-100">
            <button
              type="button"
              onClick={() => {
                setStep("phone");
                setError("");
                setTimeout(() => phoneInputRef.current?.focus(), 100);
              }}
              className="flex items-center gap-1.5 text-xs font-bold text-gray-500 hover:text-[#E11A22] transition-colors cursor-pointer"
            >
              <ArrowLeft size={15} />
              <span>Change Number</span>
            </button>
            <span className="text-[11px] font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full flex items-center gap-1">
              <ShieldCheck className="w-3 h-3 text-emerald-600" />
              OTP Sent
            </span>
          </div>

          {/* Header */}
          <div className="mb-5 text-left">
            <h2 className="text-2xl font-black text-[#0A2540] tracking-tight">
              Verify Mobile
            </h2>
            <div className="mt-1.5 flex items-center gap-1.5 text-sm text-gray-600">
              <span>6-digit code sent to</span>
              <span className="font-mono font-black text-[#0A2540] bg-gray-100 px-1.5 py-0.5 rounded">
                {maskedPhone}
              </span>
              <button
                type="button"
                onClick={() => setStep("phone")}
                className="text-gray-400 hover:text-[#E11A22] p-1 cursor-pointer transition-colors"
                title="Edit Phone Number"
              >
                <Edit2 size={13} />
              </button>
            </div>
          </div>

          {/* 6-box OTP input */}
          <form onSubmit={handleVerifyOtp} className="space-y-4">
            <div className="flex items-center justify-between gap-2">
              {otpDigits.map((digit, index) => (
                <input
                  key={index}
                  ref={(el) => { digitRefs.current[index] = el; }}
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  value={digit}
                  onChange={(e) => handleDigitChange(index, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(index, e)}
                  className={`w-11 h-14 sm:w-12 sm:h-14 text-center text-xl font-black rounded-xl border-2 transition-all outline-none ${
                    digit
                      ? "border-[#E11A22] bg-red-50/40 text-[#0A2540]"
                      : "border-gray-200 bg-gray-50/50 text-gray-800 focus:border-[#E11A22] focus:bg-white focus:ring-4 focus:ring-red-50"
                  }`}
                />
              ))}
            </div>

            {error && (
              <div className="rounded-xl bg-red-50 border border-red-200 p-3 text-xs font-bold text-[#E11A22] flex items-center gap-2 text-left">
                <span>⚠️</span>
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading || otpDigits.join("").length < 6}
              className="w-full flex items-center justify-center gap-2 rounded-xl bg-[#E11A22] hover:bg-[#c8141b] py-3.5 px-4 font-black text-sm text-white shadow-md hover:shadow-lg transition-all transform hover:-translate-y-0.5 disabled:opacity-50 disabled:pointer-events-none disabled:transform-none cursor-pointer"
            >
              {loading ? (
                <>
                  <Loader2 size={18} className="animate-spin" />
                  <span>Verifying...</span>
                </>
              ) : (
                <span>Verify &amp; Login</span>
              )}
            </button>
          </form>

          {/* Resend */}
          <div className="mt-4 text-center text-xs">
            {seconds > 0 ? (
              <p className="text-gray-500 font-medium">
                Didn't receive code? Resend in{" "}
                <span className="font-mono font-black text-[#0A2540]">{seconds}s</span>
              </p>
            ) : (
              <button
                type="button"
                onClick={handleResendOtp}
                disabled={resending}
                className="font-bold text-[#E11A22] hover:text-[#c8141b] hover:underline cursor-pointer disabled:opacity-50"
              >
                {resending ? "Sending new code..." : "Resend OTP"}
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
