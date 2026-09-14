import React, { useState } from 'react';
import { Eye, EyeOff, Mail, Lock } from 'lucide-react';

export default function InputField({
  label,
  type = 'text',
  name,
  value,
  onChange,
  placeholder,
  error,
  autoComplete,
  inputMode,
  onKeyDown,
  required = false,
  className = '',
}) {
  const [showPassword, setShowPassword] = useState(false);
  const isPasswordField = type === 'password';
  const effectiveType = isPasswordField ? (showPassword ? 'text' : 'password') : type;

  // Icon selection based on field name or type
  const renderIcon = () => {
    if (type === 'email' || name === 'email') {
      return <Mail className="w-5 h-5 text-[#8EAAB9]" strokeWidth={1.8} />;
    }
    if (isPasswordField || name?.includes('password') || name?.includes('sandi')) {
      return <Lock className="w-5 h-5 text-[#8EAAB9]" strokeWidth={1.8} />;
    }
    return null;
  };

  return (
    <div className={`w-full text-left ${className}`}>
      {label && (
        <label className="block text-lg font-bold text-[#1C4E68] mb-1 leading-tight">
          {label}
        </label>
      )}

      <div className="relative flex items-center">
        <div className="absolute left-4 pointer-events-none flex items-center justify-center">
          {renderIcon()}
        </div>

        <input
          type={effectiveType}
          name={name}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          autoComplete={autoComplete}
          inputMode={inputMode}
          autoCapitalize="none"
          autoCorrect="off"
          spellCheck={false}
          onKeyDown={onKeyDown}
          required={required}
          className={`w-full bg-[#FFFBEA] text-[#1C4E68] placeholder-[#9CB3C2] text-lg font-medium pl-12 pr-12 py-3 rounded-2xl border transition-all duration-200 outline-none
            ${
              error
                ? 'border-red-500 ring-2 ring-red-200'
                : 'border-[#E7DEC3] hover:border-[#D0C29E] focus:border-[#2D7A9E] focus:ring-2 focus:ring-[#2D7A9E]/20'
            }`}
        />

        {isPasswordField && (
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            tabIndex={-1}
            aria-label={showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
            className="absolute right-4 text-[#8EAAB9] hover:text-[#2D7A9E] transition-colors focus:outline-none p-1"
          >
            {showPassword ? (
              <EyeOff className="w-5 h-5" strokeWidth={1.8} />
            ) : (
              <Eye className="w-5 h-5" strokeWidth={1.8} />
            )}
          </button>
        )}
      </div>

      {error && (
        <p className="mt-1 text-sm font-semibold text-red-500 pl-2 leading-tight animate-fadeIn">
          {error}
        </p>
      )}
    </div>
  );
}
