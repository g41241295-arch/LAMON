import React, { createContext, useContext, useState } from 'react';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  // Pre-registered users: email (lowercase) -> { name, password, hasCompletedScreening, screeningData }
  const [registeredUsers, setRegisteredUsers] = useState({
    'hanabi00@gmail.com': {
      name: 'Hanabi',
      password: 'password123',
      hasCompletedScreening: true,
      screeningData: null,
    },
    'user@gmail.com': {
      name: 'User Lamon',
      password: 'password123',
      hasCompletedScreening: true,
      screeningData: null,
    },
  });

  // Default user matches the Figma design ("Hanabi")
  const [currentUser, setCurrentUser] = useState({
    name: 'Hanabi',
    email: 'Hanabi00@gmail.com',
    avatar: null,
    hasCompletedScreening: true,
    screeningData: null,
  });

  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const isEmailRegistered = (email) => {
    const normalized = email.trim().toLowerCase();
    return Boolean(registeredUsers[normalized]);
  };

  const verifyPassword = (email, password) => {
    const normalized = email.trim().toLowerCase();
    const user = registeredUsers[normalized];
    if (!user) return false;
    return user.password === password;
  };

  const loginWithEmail = (email, password) => {
    const normalized = email.trim().toLowerCase();
    const existing = registeredUsers[normalized];
    const nameFromEmail = email.split('@')[0];
    const capitalized = nameFromEmail.charAt(0).toUpperCase() + nameFromEmail.slice(1);
    const displayName = existing?.name || capitalized || 'Hanabi';
    const hasScreening = existing?.hasCompletedScreening ?? false;
    const screeningData = existing?.screeningData || null;

    setCurrentUser({
      name: displayName,
      email: email.trim(),
      hasCompletedScreening: hasScreening,
      screeningData,
    });
    setIsAuthenticated(true);
    return { hasCompletedScreening: hasScreening };
  };

  const registerWithEmail = (email, password, name) => {
    const normalized = email.trim().toLowerCase();
    const nameFromEmail = email.split('@')[0];
    const capitalized = nameFromEmail.charAt(0).toUpperCase() + nameFromEmail.slice(1);
    const displayName = name || capitalized || 'Hanabi';

    setRegisteredUsers((prev) => ({
      ...prev,
      [normalized]: {
        name: displayName,
        password: password,
        hasCompletedScreening: false,
        screeningData: null,
      },
    }));

    setCurrentUser({
      name: displayName,
      email: email.trim(),
      hasCompletedScreening: false,
      screeningData: null,
    });
    setIsAuthenticated(true);
  };

  const completeScreening = (data) => {
    const normalized = currentUser.email.trim().toLowerCase();
    setRegisteredUsers((prev) => ({
      ...prev,
      [normalized]: {
        ...(prev[normalized] || { name: currentUser.name, password: '' }),
        hasCompletedScreening: true,
        screeningData: data,
      },
    }));

    setCurrentUser((prev) => ({
      ...prev,
      hasCompletedScreening: true,
      screeningData: data,
    }));
  };

  const loginWithGoogle = (account) => {
    const email = account.email || 'Hanabi00@gmail.com';
    const normalized = email.trim().toLowerCase();
    const name = account.name || 'Hanabi';
    const existing = registeredUsers[normalized];
    const hasScreening = existing ? (existing.hasCompletedScreening ?? false) : false;

    if (!existing) {
      setRegisteredUsers((prev) => ({
        ...prev,
        [normalized]: {
          name: name,
          password: '',
          hasCompletedScreening: false,
          screeningData: null,
        },
      }));
    }

    setCurrentUser({
      name: name,
      email: email,
      hasCompletedScreening: hasScreening,
      screeningData: existing?.screeningData || null,
    });
    setIsAuthenticated(true);
    return { hasCompletedScreening: hasScreening };
  };

  const logout = () => {
    setIsAuthenticated(false);
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        setCurrentUser,
        isAuthenticated,
        isEmailRegistered,
        verifyPassword,
        loginWithEmail,
        registerWithEmail,
        loginWithGoogle,
        completeScreening,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
