import React, { createContext, useContext, useState } from 'react';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  // Default user matches the Figma design ("Hanabi")
  const [currentUser, setCurrentUser] = useState({
    name: 'Hanabi',
    email: 'Hanabi00@gmail.com',
    avatar: null,
  });

  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const loginWithEmail = (email, password) => {
    // Extract name from email if not provided
    const nameFromEmail = email.split('@')[0];
    const capitalized = nameFromEmail.charAt(0).toUpperCase() + nameFromEmail.slice(1);
    setCurrentUser({
      name: capitalized || 'Hanabi',
      email: email,
    });
    setIsAuthenticated(true);
  };

  const registerWithEmail = (email, password) => {
    const nameFromEmail = email.split('@')[0];
    const capitalized = nameFromEmail.charAt(0).toUpperCase() + nameFromEmail.slice(1);
    setCurrentUser({
      name: capitalized || 'Hanabi',
      email: email,
    });
    setIsAuthenticated(true);
  };

  const loginWithGoogle = (account) => {
    setCurrentUser({
      name: account.name || 'Hanabi',
      email: account.email || 'Hanabi00@gmail.com',
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
