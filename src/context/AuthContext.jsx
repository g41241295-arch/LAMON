import React, { createContext, useContext, useState } from 'react';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  // Pre-registered users: email (lowercase) -> { name, password }
  const [registeredUsers, setRegisteredUsers] = useState({
    'hanabi00@gmail.com': {
      name: 'Hanabi',
      password: 'password123',
    },
    'user@gmail.com': {
      name: 'User Lamon',
      password: 'password123',
    },
  });

  // Default user matches the Figma design ("Hanabi")
  const [currentUser, setCurrentUser] = useState({
    name: 'Hanabi',
    email: 'Hanabi00@gmail.com',
    avatar: null,
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

    setCurrentUser({
      name: displayName,
      email: email.trim(),
    });
    setIsAuthenticated(true);
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
      },
    }));

    setCurrentUser({
      name: displayName,
      email: email.trim(),
    });
    setIsAuthenticated(true);
  };

  const loginWithGoogle = (account) => {
    const email = account.email || 'Hanabi00@gmail.com';
    const normalized = email.trim().toLowerCase();
    const name = account.name || 'Hanabi';

    setRegisteredUsers((prev) => ({
      ...prev,
      [normalized]: {
        name: name,
        password: '',
      },
    }));

    setCurrentUser({
      name: name,
      email: email,
    });
    setIsAuthenticated(true);
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
