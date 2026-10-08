'use client';

import React, { useState, useEffect } from "react";
import {
  X,
  ShieldCheck,
  QrCode,
  CreditCard,
  Building,
  Wallet,
  Lock,
  ChevronRight,
} from "lucide-react";

interface RazorpayPaymentModalProps {
  isOpen: boolean;
  amount: number;
  customerName: string;
  customerPhone: string;
  customerEmail?: string;
  onSuccess: (paymentId: string) => void;
  onClose: () => void;
}

type TabType = "upi" | "card" | "netbanking" | "wallet";

export const RazorpayPaymentModal: React.FC<RazorpayPaymentModalProps> = ({
  isOpen,
  amount,
  customerName,
  customerPhone,
  onSuccess,
  onClose,
}) => {
  const [activeTab, setActiveTab] = useState<TabType>("upi");
  const [upiOption, setUpiOption] = useState<"qr" | "id">("qr");
  const [upiId, setUpiId] = useState("");
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingStep, setProcessingStep] = useState<string>("");

  const [cardNumber, setCardNumber] = useState("");
  const [cardExpiry, setCardExpiry] = useState("");
  const [cardCvv, setCardCvv] = useState("");
  const [cardHolder, setCardHolder] = useState(customerName || "");
  const [selectedBank, setSelectedBank] = useState("HDFC");
  const [timerSeconds, setTimerSeconds] = useState(480);

  useEffect(() => {
    if (!isOpen) return;
    const interval = setInterval(() => {
      setTimerSeconds((prev) => (prev > 0 ? prev - 1 : 480));
    }, 1000);
    return () => clearInterval(interval);
  }, [isOpen]);

  if (!isOpen) return null;

  const formatTimer = (s: number) => {
    const mins = Math.floor(s / 60);
    const secs = s % 60;
    return `${mins}:${secs < 10 ? "0" : ""}${secs}`;
  };

  const handleAuthorize = () => {
    setIsProcessing(true);
    setProcessingStep("Connecting to payment gateway...");

    setTimeout(() => {
      setProcessingStep("Verifying with your bank...");
    }, 900);

    setTimeout(() => {
      setProcessingStep("Payment authorized! Finalizing order...");
    }, 1800);

    setTimeout(() => {
      setIsProcessing(false);
      const generatedId = "pay_" + Math.random().toString(36).substring(2, 11);
      onSuccess(generatedId);
    }, 2500);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-4 animate-fadeIn">
      <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden border border-gray-200 relative my-6 text-left flex flex-col animate-modal-in">
        
        {/* Razorpay Brand Header */}
        <div className="bg-[#0c2340] text-white p-4 sm:p-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-[#3395FF] flex items-center justify-center font-black text-white italic text-lg shadow-sm">
              ₹
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="font-extrabold text-sm sm:text-base tracking-tight">K MART</span>
                <span className="text-[10px] bg-white/20 px-1.5 py-0.2 rounded font-bold">VERIFIED</span>
              </div>
              <p className="text-[11px] text-gray-300">
                Order Total: <strong className="text-white text-xs">₹{amount}</strong>
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1 text-[11px] text-gray-300 bg-white/10 px-2.5 py-1 rounded-full">
              <Lock className="w-3 h-3 text-emerald-400" />
              <span>Razorpay Secured</span>
            </div>
            <button
              onClick={onClose}
              disabled={isProcessing}
              className="w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center transition-colors cursor-pointer disabled:opacity-50"
              aria-label="Close"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Demo Mode Banner */}
        <div className="bg-amber-50 border-b border-amber-200 px-4 py-2 flex items-center gap-2 text-[11px] text-amber-900 font-semibold">
          <span className="text-amber-500 text-sm">⚠️</span>
          <span>
            <strong>Demo Mode</strong> — Add <code className="bg-amber-100 px-1 py-0.5 rounded text-[10px]">NEXT_PUBLIC_RAZORPAY_KEY_ID</code> to <code className="bg-amber-100 px-1 py-0.5 rounded text-[10px]">.env.local</code> to activate the real Razorpay popup.
          </span>
        </div>

        {/* Processing Loading Overlay */}
        {isProcessing ? (
          <div className="p-10 flex flex-col items-center justify-center text-center space-y-4 min-h-[340px]">
            <div className="relative">
              <div className="w-16 h-16 rounded-full border-4 border-gray-100 border-t-[#3395FF] animate-spin flex items-center justify-center" />
              <div className="absolute inset-0 flex items-center justify-center font-bold text-xs text-[#0c2340]">
                ₹
              </div>
            </div>
            <div className="space-y-1">
              <h4 className="text-base font-bold text-gray-900">Processing Payment</h4>
              <p className="text-xs text-gray-500">{processingStep}</p>
            </div>
            <div className="flex items-center gap-2 text-[11px] text-gray-400 bg-gray-50 px-3 py-1.5 rounded-full border">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              <span>Do not press back or refresh the page</span>
            </div>
          </div>
        ) : (
          <div className="flex flex-col sm:flex-row divide-y sm:divide-y-0 sm:divide-x divide-gray-100 min-h-[360px]">
            {/* Left Nav Tabs */}
            <div className="w-full sm:w-44 bg-gray-50/70 p-2 sm:p-3 space-y-1 shrink-0">
              <button
                type="button"
                onClick={() => setActiveTab("upi")}
                className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-bold transition-all text-left cursor-pointer ${
                  activeTab === "upi"
                    ? "bg-white text-[#3395FF] shadow-xs border border-gray-200"
                    : "text-gray-600 hover:bg-gray-100"
                }`}
              >
                <QrCode className="w-4 h-4 text-[#3395FF]" />
                <div className="flex-1">
                  <span>UPI / QR</span>
                  <span className="block text-[9px] text-emerald-600 font-extrabold">Instant Pay</span>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setActiveTab("card")}
                className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-bold transition-all text-left cursor-pointer ${
                  activeTab === "card"
                    ? "bg-white text-[#3395FF] shadow-xs border border-gray-200"
                    : "text-gray-600 hover:bg-gray-100"
                }`}
              >
                <CreditCard className="w-4 h-4 text-blue-600" />
                <span>Card</span>
              </button>

              <button
                type="button"
                onClick={() => setActiveTab("netbanking")}
                className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-bold transition-all text-left cursor-pointer ${
                  activeTab === "netbanking"
                    ? "bg-white text-[#3395FF] shadow-xs border border-gray-200"
                    : "text-gray-600 hover:bg-gray-100"
                }`}
              >
                <Building className="w-4 h-4 text-purple-600" />
                <span>Netbanking</span>
              </button>

              <button
                type="button"
                onClick={() => setActiveTab("wallet")}
                className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-bold transition-all text-left cursor-pointer ${
                  activeTab === "wallet"
                    ? "bg-white text-[#3395FF] shadow-xs border border-gray-200"
                    : "text-gray-600 hover:bg-gray-100"
                }`}
              >
                <Wallet className="w-4 h-4 text-amber-600" />
                <span>Wallets</span>
              </button>

              <div className="pt-4 px-2 text-[10px] text-gray-400">
                <p>Paying as: <strong className="text-gray-700 block truncate">{customerName}</strong></p>
                <p className="mt-0.5">{customerPhone}</p>
              </div>
            </div>

            {/* Right Panel Details */}
            <div className="flex-1 p-4 sm:p-5 flex flex-col justify-between">
              {activeTab === "upi" && (
                <div className="space-y-4">
                  <div className="flex rounded-lg bg-gray-100 p-0.5 text-xs font-bold">
                    <button
                      type="button"
                      onClick={() => setUpiOption("qr")}
                      className={`flex-1 py-1.5 rounded-md transition-all ${
                        upiOption === "qr" ? "bg-white shadow-xs text-gray-900" : "text-gray-500 hover:text-gray-800"
                      }`}
                    >
                      Scan QR Code
                    </button>
                    <button
                      type="button"
                      onClick={() => setUpiOption("id")}
                      className={`flex-1 py-1.5 rounded-md transition-all ${
                        upiOption === "id" ? "bg-white shadow-xs text-gray-900" : "text-gray-500 hover:text-gray-800"
                      }`}
                    >
                      Enter UPI ID
                    </button>
                  </div>

                  {upiOption === "qr" ? (
                    <div className="flex flex-col items-center justify-center p-3 border border-gray-200 rounded-xl bg-gray-50/50 text-center">
                      <div className="p-2.5 bg-white rounded-xl shadow-xs border border-gray-200">
                        <svg className="w-32 h-32" viewBox="0 0 100 100" fill="currentColor">
                          <rect width="100" height="100" fill="white" />
                          <path d="M0,0 h30 v30 h-30 z M6,6 h18 v18 h-18 z M10,10 h10 v10 h-10 z" fill="#0c2340" />
                          <path d="M70,0 h30 v30 h-30 z M76,6 h18 v18 h-18 z M80,10 h10 v10 h-10 z" fill="#0c2340" />
                          <path d="M0,70 h30 v30 h-30 z M6,76 h18 v18 h-18 z M10,80 h10 v10 h-10 z" fill="#0c2340" />
                          <rect x="36" y="8" width="6" height="18" fill="#3395FF" />
                          <rect x="48" y="14" width="14" height="6" fill="#0c2340" />
                          <rect x="8" y="36" width="16" height="6" fill="#0c2340" />
                          <rect x="36" y="36" width="28" height="28" fill="#3395FF" />
                          <rect x="42" y="42" width="16" height="16" fill="white" />
                          <text x="50" y="54" fontFamily="sans-serif" fontSize="12" fontWeight="bold" textAnchor="middle" fill="#0c2340">₹</text>
                          <rect x="70" y="36" width="14" height="8" fill="#0c2340" />
                          <rect x="76" y="52" width="16" height="18" fill="#3395FF" />
                          <rect x="8" y="52" width="18" height="10" fill="#0c2340" />
                          <rect x="36" y="72" width="18" height="18" fill="#0c2340" />
                          <rect x="62" y="72" width="30" height="10" fill="#0c2340" />
                          <rect x="78" y="88" width="14" height="6" fill="#3395FF" />
                        </svg>
                      </div>

                      <div className="mt-2.5">
                        <p className="text-xs font-bold text-gray-800">
                          Scan & Pay with Any UPI App
                        </p>
                        <div className="flex items-center justify-center gap-2 mt-1.5 text-[10px] text-gray-500 font-semibold">
                          <span className="bg-white border px-1.5 py-0.5 rounded">GPay</span>
                          <span className="bg-white border px-1.5 py-0.5 rounded">PhonePe</span>
                          <span className="bg-white border px-1.5 py-0.5 rounded">Paytm</span>
                        </div>
                        <p className="text-[10px] text-gray-400 mt-2">
                          QR expires in <span className="font-mono font-bold text-red-600">{formatTimer(timerSeconds)}</span>
                        </p>
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      <div>
                        <label className="block text-xs font-bold text-gray-700 mb-1">
                          Enter VPA / UPI ID
                        </label>
                        <input
                          type="text"
                          value={upiId}
                          onChange={(e) => setUpiId(e.target.value)}
                          placeholder="e.g. user@okhdfcbank"
                          className="w-full rounded-xl border border-gray-300 px-3.5 py-2 text-xs outline-none focus:border-[#3395FF]"
                        />
                      </div>
                    </div>
                  )}
                </div>
              )}

              {activeTab === "card" && (
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">
                      Card Number
                    </label>
                    <input
                      type="text"
                      maxLength={19}
                      value={cardNumber}
                      onChange={(e) => {
                        const val = e.target.value.replace(/\D/g, "").replace(/(.{4})/g, "$1 ").trim();
                        setCardNumber(val);
                      }}
                      placeholder="4532 •••• •••• 8921"
                      className="w-full rounded-xl border border-gray-300 px-3.5 py-2 text-xs font-mono outline-none focus:border-[#3395FF]"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="block text-xs font-bold text-gray-700 mb-1">Expiry (MM/YY)</label>
                      <input
                        type="text"
                        maxLength={5}
                        value={cardExpiry}
                        onChange={(e) => setCardExpiry(e.target.value)}
                        placeholder="12/28"
                        className="w-full rounded-xl border border-gray-300 px-3.5 py-2 text-xs outline-none"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-gray-700 mb-1">CVV</label>
                      <input
                        type="password"
                        maxLength={4}
                        value={cardCvv}
                        onChange={(e) => setCardCvv(e.target.value)}
                        placeholder="•••"
                        className="w-full rounded-xl border border-gray-300 px-3.5 py-2 text-xs outline-none"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">Name on Card</label>
                    <input
                      type="text"
                      value={cardHolder}
                      onChange={(e) => setCardHolder(e.target.value)}
                      placeholder="Cardholder Name"
                      className="w-full rounded-xl border border-gray-300 px-3.5 py-2 text-xs outline-none"
                    />
                  </div>
                </div>
              )}

              {activeTab === "netbanking" && (
                <div className="space-y-3">
                  <label className="block text-xs font-bold text-gray-700">Select Bank</label>
                  <div className="grid grid-cols-2 gap-2">
                    {["HDFC", "SBI", "ICICI", "Axis"].map((b) => (
                      <button
                        key={b}
                        type="button"
                        onClick={() => setSelectedBank(b)}
                        className={`p-2 rounded-xl border text-xs font-bold text-left transition-all ${
                          selectedBank === b ? "border-[#3395FF] bg-blue-50/50 text-[#3395FF]" : "border-gray-200 text-gray-700"
                        }`}
                      >
                        {b} Bank
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {activeTab === "wallet" && (
                <div className="space-y-2">
                  {["Amazon Pay", "Paytm Wallet", "PhonePe Wallet"].map((w) => (
                    <label key={w} className="flex items-center gap-3 p-2.5 rounded-xl border border-gray-200 text-xs font-bold cursor-pointer">
                      <input type="radio" name="wallet" defaultChecked={w === "Amazon Pay"} className="text-[#3395FF]" />
                      <span>{w}</span>
                    </label>
                  ))}
                </div>
              )}

              {/* Bottom Pay CTA */}
              <div className="pt-4 mt-auto border-t border-gray-100">
                <button
                  type="button"
                  onClick={handleAuthorize}
                  className="w-full bg-[#3395FF] hover:bg-[#2575dc] text-white font-extrabold text-sm py-2.5 px-4 rounded-xl flex items-center justify-center gap-2 shadow-md transition-all cursor-pointer"
                >
                  <Lock className="w-4 h-4" />
                  <span>Authorize ₹{amount}</span>
                  <ChevronRight className="w-4 h-4" />
                </button>

                <div className="mt-2 flex items-center justify-between text-[10px] text-gray-400">
                  <span>Secured by Razorpay</span>
                  <span className="flex items-center gap-1">
                    <ShieldCheck className="w-3 h-3 text-emerald-600" />
                    256-bit SSL
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
};
