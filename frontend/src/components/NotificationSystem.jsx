import React, { useState, useEffect, createContext, useContext, useCallback } from 'react';
import { CheckCircle, XCircle, AlertCircle, Info, X } from 'lucide-react';

export const NotificationContext = createContext(null);

export const NotificationProvider = ({ children }) => {
  const [notifications, setNotifications] = useState([]);

  const addNotification = useCallback((notification) => {
    const id = Math.random().toString(36).substr(2, 9);
    setNotifications(prev => [...prev, { ...notification, id }]);
    
    // Auto dismiss after duration
    setTimeout(() => {
      setNotifications(prev => prev.filter(n => n.id !== id));
    }, notification.duration || 5000);
  }, []);

  const removeNotification = useCallback((id) => {
    setNotifications(prev => prev.filter(n => n.id !== id));
  }, []);

  return (
    <NotificationContext.Provider value={{ addNotification, removeNotification }}>
      {children}
      <div className="fixed top-4 right-4 z-50 space-y-2">
        {notifications.map(notification => (
          <div
            key={notification.id}
            className={`flex items-center p-4 rounded-lg shadow-lg text-white transform transition-all duration-300 ease-in-out
              ${notification.type === 'success' ? 'bg-green-600' :
                notification.type === 'error' ? 'bg-red-600' :
                notification.type === 'warning' ? 'bg-yellow-600' :
                'bg-blue-600'}`}
          >
            {notification.type === 'success' ? <CheckCircle className="w-5 h-5 mr-3" /> :
             notification.type === 'error' ? <XCircle className="w-5 h-5 mr-3" /> :
             notification.type === 'warning' ? <AlertCircle className="w-5 h-5 mr-3" /> :
             <Info className="w-5 h-5 mr-3" />}
            
            <div className="flex-1">
              {notification.title && (
                <h4 className="font-medium">{notification.title}</h4>
              )}
              <p className="text-sm">{notification.message}</p>
            </div>
            
            <button
              onClick={() => removeNotification(notification.id)}
              className="ml-4 hover:opacity-80"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        ))}
      </div>
    </NotificationContext.Provider>
  );
};

export const useNotification = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotification must be used within a NotificationProvider');
  }
  return context;
};