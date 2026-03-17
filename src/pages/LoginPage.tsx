import { useState, type FormEvent } from "react";
import { useAuth } from "../providers/AuthProvider";

export function LoginPage() {
  const { signIn, resetPassword } = useAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [resetSent, setResetSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setError("Please enter your email address.");
      return;
    }
    if (!password) {
      setError("Please enter your password.");
      return;
    }

    setLoading(true);
    try {
      const { error: signInError } = await signIn(trimmedEmail, password);
      if (signInError) {
        setError(signInError.message || "Invalid email or password.");
      }
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  async function handleForgotPassword() {
    setError(null);
    setResetSent(false);

    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setError("Enter your email above, then tap Forgot password.");
      return;
    }

    setLoading(true);
    try {
      const { error: resetError } = await resetPassword(trimmedEmail);
      if (resetError) {
        setError(resetError.message || "Could not send reset email.");
      } else {
        setResetSent(true);
      }
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div
      style={{
        background: "var(--charcoal)",
        minHeight: "100dvh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "24px 20px",
        paddingTop: "calc(env(safe-area-inset-top, 0px) + 24px)",
        paddingBottom: "calc(env(safe-area-inset-bottom, 0px) + 24px)",
      }}
    >
      {/* Branding */}
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          marginBottom: 40,
        }}
      >
        {/* Gold BC circle */}
        <div
          style={{
            width: 72,
            height: 72,
            borderRadius: "50%",
            background: "var(--gold)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            marginBottom: 16,
            boxShadow: "0 4px 24px rgba(184, 134, 11, 0.3)",
          }}
        >
          <span
            className="font-serif"
            style={{
              color: "var(--white)",
              fontSize: 28,
              fontWeight: 400,
              letterSpacing: 1,
              lineHeight: 1,
            }}
          >
            BC
          </span>
        </div>

        {/* Title */}
        <h1
          className="font-serif"
          style={{
            color: "var(--ivory)",
            fontSize: 26,
            fontWeight: 400,
            letterSpacing: 0.5,
            margin: 0,
          }}
        >
          Braccia Capital
        </h1>

        <p
          style={{
            color: "var(--text-muted)",
            fontSize: 14,
            marginTop: 6,
            letterSpacing: 0.3,
          }}
        >
          Deal Management
        </p>
      </div>

      {/* Form card */}
      <form
        onSubmit={handleSubmit}
        style={{
          width: "100%",
          maxWidth: 380,
          display: "flex",
          flexDirection: "column",
          gap: 16,
        }}
        noValidate
      >
        {/* Error message */}
        {error && (
          <div
            role="alert"
            style={{
              background: "rgba(230, 57, 70, 0.12)",
              border: "1px solid rgba(230, 57, 70, 0.3)",
              borderRadius: "var(--radius-md)",
              padding: "12px 14px",
              display: "flex",
              alignItems: "flex-start",
              gap: 10,
            }}
          >
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="var(--danger)"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              style={{ flexShrink: 0, marginTop: 1 }}
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <span style={{ color: "#f0a0a8", fontSize: 14, lineHeight: 1.4 }}>
              {error}
            </span>
          </div>
        )}

        {/* Reset success message */}
        {resetSent && (
          <div
            role="status"
            style={{
              background: "rgba(42, 157, 143, 0.12)",
              border: "1px solid rgba(42, 157, 143, 0.3)",
              borderRadius: "var(--radius-md)",
              padding: "12px 14px",
              display: "flex",
              alignItems: "flex-start",
              gap: 10,
            }}
          >
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="var(--success)"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              style={{ flexShrink: 0, marginTop: 1 }}
            >
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            <span style={{ color: "#8fd8cf", fontSize: 14, lineHeight: 1.4 }}>
              Password reset email sent. Check your inbox.
            </span>
          </div>
        )}

        {/* Email input */}
        <div>
          <label
            htmlFor="login-email"
            style={{
              display: "block",
              color: "var(--text-muted)",
              fontSize: 13,
              fontWeight: 500,
              marginBottom: 6,
              letterSpacing: 0.3,
              textTransform: "uppercase",
            }}
          >
            Email
          </label>
          <input
            id="login-email"
            type="email"
            inputMode="email"
            autoComplete="email"
            autoCapitalize="off"
            autoCorrect="off"
            spellCheck={false}
            placeholder="you@company.com"
            value={email}
            onChange={(e) => {
              setEmail(e.target.value);
              if (error) setError(null);
              if (resetSent) setResetSent(false);
            }}
            disabled={loading}
            style={{
              width: "100%",
              height: 52,
              padding: "0 16px",
              background: "var(--charcoal-light)",
              border: "1px solid rgba(255,255,255,0.1)",
              borderRadius: "var(--radius-md)",
              color: "var(--ivory)",
              fontSize: 16,
              outline: "none",
              WebkitAppearance: "none",
              transition: "border-color 0.2s",
            }}
            onFocus={(e) => {
              e.currentTarget.style.borderColor = "var(--gold)";
            }}
            onBlur={(e) => {
              e.currentTarget.style.borderColor = "rgba(255,255,255,0.1)";
            }}
          />
        </div>

        {/* Password input */}
        <div>
          <label
            htmlFor="login-password"
            style={{
              display: "block",
              color: "var(--text-muted)",
              fontSize: 13,
              fontWeight: 500,
              marginBottom: 6,
              letterSpacing: 0.3,
              textTransform: "uppercase",
            }}
          >
            Password
          </label>
          <div style={{ position: "relative" }}>
            <input
              id="login-password"
              type={showPassword ? "text" : "password"}
              autoComplete="current-password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                if (error) setError(null);
              }}
              disabled={loading}
              style={{
                width: "100%",
                height: 52,
                padding: "0 48px 0 16px",
                background: "var(--charcoal-light)",
                border: "1px solid rgba(255,255,255,0.1)",
                borderRadius: "var(--radius-md)",
                color: "var(--ivory)",
                fontSize: 16,
                outline: "none",
                WebkitAppearance: "none",
                transition: "border-color 0.2s",
              }}
              onFocus={(e) => {
                e.currentTarget.style.borderColor = "var(--gold)";
              }}
              onBlur={(e) => {
                e.currentTarget.style.borderColor = "rgba(255,255,255,0.1)";
              }}
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              tabIndex={-1}
              aria-label={showPassword ? "Hide password" : "Show password"}
              style={{
                position: "absolute",
                right: 4,
                top: "50%",
                transform: "translateY(-50%)",
                width: 44,
                height: 44,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: "transparent",
                border: "none",
                cursor: "pointer",
                padding: 0,
              }}
            >
              {showPassword ? (
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="var(--text-muted)"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
                  <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
                  <line x1="1" y1="1" x2="23" y2="23" />
                  <path d="M14.12 14.12a3 3 0 1 1-4.24-4.24" />
                </svg>
              ) : (
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="var(--text-muted)"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                  <circle cx="12" cy="12" r="3" />
                </svg>
              )}
            </button>
          </div>
        </div>

        {/* Sign In button */}
        <button
          type="submit"
          disabled={loading}
          style={{
            width: "100%",
            height: 52,
            marginTop: 8,
            background: loading ? "var(--gold-dim)" : "var(--gold)",
            color: "var(--white)",
            border: "none",
            borderRadius: "var(--radius-md)",
            fontSize: 16,
            fontWeight: 600,
            letterSpacing: 0.3,
            cursor: loading ? "not-allowed" : "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 10,
            transition: "background 0.2s, opacity 0.2s",
            opacity: loading ? 0.85 : 1,
            boxShadow: "0 2px 12px rgba(184, 134, 11, 0.25)",
          }}
        >
          {loading && (
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              style={{
                animation: "spin 0.8s linear infinite",
              }}
            >
              <circle
                cx="12"
                cy="12"
                r="10"
                stroke="rgba(255,255,255,0.3)"
                strokeWidth="3"
              />
              <path
                d="M12 2a10 10 0 0 1 10 10"
                stroke="white"
                strokeWidth="3"
                strokeLinecap="round"
              />
            </svg>
          )}
          {loading ? "Signing in..." : "Sign In"}
        </button>

        {/* Forgot password */}
        <div style={{ textAlign: "center", marginTop: 4 }}>
          <button
            type="button"
            onClick={handleForgotPassword}
            disabled={loading}
            style={{
              background: "none",
              border: "none",
              color: "var(--gold-light)",
              fontSize: 14,
              cursor: loading ? "not-allowed" : "pointer",
              padding: "12px 16px",
              minHeight: 48,
              opacity: loading ? 0.6 : 1,
              transition: "opacity 0.2s",
            }}
          >
            Forgot password?
          </button>
        </div>
      </form>

      {/* Footer */}
      <p
        style={{
          position: "fixed",
          bottom: "calc(env(safe-area-inset-bottom, 0px) + 20px)",
          left: 0,
          right: 0,
          textAlign: "center",
          color: "rgba(255,255,255,0.2)",
          fontSize: 12,
          letterSpacing: 0.5,
          pointerEvents: "none",
        }}
      >
        Braccia Capital &middot; Confidential
      </p>

      {/* Inline keyframes for spinner */}
      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        input::placeholder {
          color: rgba(255,255,255,0.25);
        }
        input:disabled {
          opacity: 0.6;
        }
      `}</style>
    </div>
  );
}
