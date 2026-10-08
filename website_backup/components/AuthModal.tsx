'use client';

import React, { useState, useEffect, useRef } from 'react';
import { 
  X, 
  ChevronLeft, 
  ShieldCheck, 
  ArrowRight, 
  Edit2,
  Loader2
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Logo } from './Logo';
import { supabase } from '../lib/supabase/client';

export const AuthModal: React.FC = () => {
  const { isAuthOpen, setIsAuthOpen, setUser } = useApp();
  
  const [authStep, setAuthStep] = useState<'phone' | 'otp'>('phone');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otpDigits, setOtpDigits] = useState(['', '', '', '', '', '']);
  const [timer, setTimer] = useState(30);
  const [isLoading, setIsLoading] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [error, setError] = useState('');

  const phoneInputRef = useRef<HTMLInputElement>(null);
  const digitRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    let interval: ReturnType<typeof setInterval>;
    if (authStep === 'otp' && timer > 0) {
      interval = setInterval(() => setTimer(t => t - 1), 1000);
    }
    return () => clearInterval(interval);
  }, [authStep, timer]);

  // Focus phone input when modal opens
  useEffect(() => {
    if (isAuthOpen && authStep === 'phone') {
      setTimeout(() => phoneInputRef.current?.focus(), 100);
    }
  }, [isAuthOpen, authStep]);

  if (!isAuthOpen) return null;

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    const digits = phoneNumber.replace(/\D/g, '');
    if (digits.length !== 10) {
      setError('Please enter a valid 10-digit mobile number.');
      return;
    }

    setIsLoading(true);
    try {
      const normalized = `+91${digits}`;
      const { error: sendError } = await supabase.auth.signInWithOtp({ phone: normalized });
      if (sendError) {
        console.warn('[AuthModal] sendOtp:', sendError.message);
      }
    } catch (err: any) {
      console.warn('[AuthModal] sendOtp exception:', err?.message);
    } finally {
      setIsLoading(false);
    }

    setAuthStep('otp');
    setTimer(30);
    setOtpDigits(['', '', '', '', '', '']);
    setTimeout(() => digitRefs.current[0]?.focus(), 100);
  };

  const handleOtpChange = (index: number, val: string) => {
    const numeric = val.replace(/\D/g, '');
    if (!numeric && val !== '') return;

    const newDigits = [...otpDigits];

    // Handle paste
    if (numeric.length > 1) {
      const pasted = numeric.slice(0, 6).split('');
      for (let i = 0; i < 6; i++) newDigits[i] = pasted[i] || '';
      setOtpDigits(newDigits);
      digitRefs.current[Math.min(pasted.length, 5)]?.focus();
      return;
    }

    newDigits[index] = numeric.slice(-1);
    setOtpDigits(newDigits);
    if (numeric && index < 5) {
      digitRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otpDigits[index] && index > 0) {
      digitRefs.current[index - 1]?.focus();
    }
  };

  const handleVerifyOtp = async () => {
    const enteredOtp = otpDigits.join('');
    if (enteredOtp.length !== 6) {
      setError('Please enter the complete 6-digit code.');
      return;
    }

    setIsVerifying(true);
    setError('');

    try {
      const normalized = `+91${phoneNumber.replace(/\D/g, '')}`;
      const { data, error: verifyError } = await supabase.auth.verifyOtp({
        phone: normalized,
        token: enteredOtp,
        type: 'sms',
      });

      if (verifyError) {
        setError(
          verifyError.message.includes('expired')
            ? 'OTP expired. Please request a new one.'
            : verifyError.message.includes('Invalid') || verifyError.message.includes('invalid')
            ? 'Incorrect OTP. Please try again.'
            : `Verification failed: ${verifyError.message}`
        );
        setIsVerifying(false);
        return;
      }

      // Success — AppContext's onAuthStateChange fires syncCustomerProfile automatically
      if (data?.user) {
        setUser(prev => ({
          ...prev,
          phone: `+91${phoneNumber.replace(/\D/g, '')}`,
          isVerified: true,
        }));
      }

      setIsVerifying(false);
      setIsAuthOpen(false);
      setAuthStep('phone');
      setPhoneNumber('');
      setOtpDigits(['', '', '', '', '', '']);
    } catch (err: any) {
      setError('Something went wrong. Please try again.');
      setIsVerifying(false);
    }
  };

  const handleResendOtp = async () => {
    setError('');
    try {
      const normalized = `+91${phoneNumber.replace(/\D/g, '')}`;
      await supabase.auth.signInWithOtp({ phone: normalized });
    } catch { /* ignore */ }
    setOtpDigits(['', '', '', '', '', '']);
    setTimer(30);
    setTimeout(() => digitRefs.current[0]?.focus(), 100);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 animate-fadeIn">
      <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden border border-gray-100 relative my-6 text-left animate-modal-in">
        
        {/* Top Header */}
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-white">
          {authStep === 'otp' ? (
            <button
              onClick={() => setAuthStep('phone')}
              className="flex items-center gap-1 text-xs font-bold text-gray-700 hover:text-[#0A2540] cursor-pointer"
            >
              <ChevronLeft className="w-4 h-4" />
              <span>Back</span>
            </button>
          ) : (
            <div />
          )}

          <button
            onClick={() => setIsAuthOpen(false)}
            className="w-8 h-8 rounded-full hover:bg-gray-100 text-gray-500 flex items-center justify-center cursor-pointer transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Content */}
        <div className="p-6 sm:p-8 space-y-6">
          <div className="text-center">
            <Logo size="lg" className="mx-auto" />
          </div>

          {authStep === 'phone' ? (
            <div className="space-y-5">
              <div className="text-center">
                <h2 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight">
                  Welcome to <span className="text-[#E11A22]">K MART</span>
                </h2>
                <p className="text-xs text-gray-500 mt-1">
                  Daily groceries. Branded essentials. Happier homes.
                </p>
              </div>

              <div className="grid grid-cols-3 gap-2 text-center text-[10px] text-gray-600 bg-gray-50 p-2.5 rounded-xl border border-gray-100">
                <div>
                  <span className="text-lg block">🛒</span>
                  <span className="font-semibold">Top Brands</span>
                </div>
                <div>
                  <span className="text-lg block">🏷️</span>
                  <span className="font-semibold">Great Deals</span>
                </div>
                <div>
                  <span className="text-lg block">🚚</span>
                  <span className="font-semibold">Delivery on time</span>
                </div>
              </div>

              <form onSubmit={handleSendOtp} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-gray-800 mb-1">
                    Enter your mobile number
                  </label>
                  <p className="text-[11px] text-gray-400 mb-2">
                    We will send you a One Time Password (OTP)
                  </p>

                  <div className="flex rounded-xl border border-gray-300 focus-within:border-[#E11A22] focus-within:ring-2 focus-within:ring-red-100 overflow-hidden bg-white shadow-2xs">
                    <div className="bg-gray-50 px-3.5 flex items-center gap-1 border-r border-gray-200 text-xs font-bold text-gray-700">
                      <span>+91</span>
                    </div>
                    <input
                      ref={phoneInputRef}
                      type="tel"
                      required
                      maxLength={10}
                      placeholder="Enter mobile number"
                      value={phoneNumber}
                      onChange={(e) => setPhoneNumber(e.target.value.replace(/\D/g, ''))}
                      className="flex-1 px-3 py-3 text-xs sm:text-sm font-semibold text-gray-800 focus:outline-none"
                    />
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
                  disabled={isLoading || phoneNumber.replace(/\D/g, '').length < 10}
                  className="w-full bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer text-sm disabled:opacity-50"
                >
                  {isLoading ? (
                    <div className="flex items-center gap-2">
                      <Loader2 className="w-4 h-4 animate-spin" />
                      <span>Sending OTP...</span>
                    </div>
                  ) : (
                    <>
                      <span>Continue</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </form>
            </div>
          ) : (
            <div className="space-y-5">
              <div className="text-center">
                <h2 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight">
                  Verify Your Number
                </h2>
                <p className="text-xs text-gray-500 mt-1">
                  We have sent a 6-digit OTP via SMS to
                </p>
                <div className="flex items-center justify-center gap-2 mt-1">
                  <span className="font-bold text-xs text-gray-800">+91 {phoneNumber}</span>
                  <button
                    onClick={() => setAuthStep('phone')}
                    className="text-xs text-[#E11A22] font-semibold flex items-center gap-0.5 hover:underline cursor-pointer"
                  >
                    <Edit2 className="w-3 h-3" />
                    <span>Edit</span>
                  </button>
                </div>
              </div>

              {/* 6 Digit Inputs */}
              <div className="flex items-center justify-center gap-2">
                {otpDigits.map((digit, index) => (
                  <input
                    key={index}
                    ref={(el) => { digitRefs.current[index] = el; }}
                    type="text"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleOtpChange(index, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(index, e)}
                    className={`w-11 h-12 text-center font-black text-lg border-2 rounded-xl focus:outline-none transition-all ${
                      digit ? "border-[#E11A22] bg-red-50/40 text-[#0A2540]" : "border-gray-200 bg-gray-50/50 text-gray-800 focus:border-[#E11A22] focus:ring-2 focus:ring-red-100"
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

              <div className="flex items-center justify-between text-xs text-gray-500 px-1">
                <span>Did not receive OTP?</span>
                {timer > 0 ? (
                  <span className="font-semibold text-gray-600">
                    Resend in 00:{timer < 10 ? `0${timer}` : timer}
                  </span>
                ) : (
                  <button
                    onClick={handleResendOtp}
                    className="font-bold text-[#E11A22] hover:underline cursor-pointer"
                  >
                    Resend OTP
                  </button>
                )}
              </div>

              <button
                disabled={isVerifying || otpDigits.join('').length < 6}
                onClick={handleVerifyOtp}
                className="w-full bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer text-sm disabled:opacity-50"
              >
                {isVerifying ? (
                  <div className="flex items-center gap-2">
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Verifying OTP...</span>
                  </div>
                ) : (
                  <>
                    <span>Verify & Continue</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>

              <div className="p-3 bg-blue-50/80 border border-blue-100 rounded-xl flex items-center gap-2.5 text-xs text-blue-950">
                <ShieldCheck className="w-4 h-4 text-blue-600 shrink-0" />
                <span>Your information is safe and encrypted.</span>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
};
