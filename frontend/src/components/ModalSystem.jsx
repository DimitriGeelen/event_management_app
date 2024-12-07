import React, { createContext, useContext, useState, useCallback } from 'react';
import { X } from 'lucide-react';

export const ModalContext = createContext(null);

export const ModalProvider = ({ children }) => {
  const [modals, setModals] = useState([]);

  const openModal = useCallback((modal) => {
    const id = Math.random().toString(36).substr(2, 9);
    setModals(prev => [...prev, { ...modal, id }]);
    return id;
  }, []);

  const closeModal = useCallback((id) => {
    setModals(prev => prev.filter(modal => modal.id !== id));
  }, []);

  return (
    <ModalContext.Provider value={{ openModal, closeModal }}>
      {children}
      {modals.map(modal => (
        <div
          key={modal.id}
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          <div
            className="absolute inset-0 bg-black bg-opacity-50"
            onClick={() => !modal.persistent && closeModal(modal.id)}
          />
          
          <div className={`relative bg-white rounded-lg shadow-xl w-full 
            ${modal.size === 'sm' ? 'max-w-md' :
              modal.size === 'lg' ? 'max-w-4xl' :
              'max-w-2xl'}`}
          >
            {/* Header */}
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-lg font-medium">{modal.title}</h3>
              {!modal.hideClose && (
                <button
                  onClick={() => closeModal(modal.id)}
                  className="p-1 hover:bg-gray-100 rounded-full"
                >
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>

            {/* Content */}
            <div className="p-6">
              {typeof modal.content === 'function'
                ? modal.content({ close: () => closeModal(modal.id) })
                : modal.content}
            </div>

            {/* Footer */}
            {modal.footer && (
              <div className="flex justify-end gap-3 p-4 border-t bg-gray-50">
                {modal.footer({ close: () => closeModal(modal.id) })}
              </div>
            )}
          </div>
        </div>
      ))}
    </ModalContext.Provider>
  );
};

export const useModal = () => {
  const context = useContext(ModalContext);
  if (!context) {
    throw new Error('useModal must be used within a ModalProvider');
  }
  return context;
};