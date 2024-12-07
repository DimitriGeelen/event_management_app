import React from 'react';
import { AlertTriangle, Info, HelpCircle, AlertCircle } from 'lucide-react';
import { useModal } from './ModalSystem';

export const useConfirmation = () => {
  const { openModal, closeModal } = useModal();

  const confirm = ({
    title = 'Confirm Action',
    message,
    type = 'info',
    confirmText = 'Confirm',
    cancelText = 'Cancel',
    confirmVariant = 'primary',
    onConfirm,
    onCancel
  }) => {
    const id = openModal({
      title,
      content: (
        <div className="flex items-start">
          <div className="flex-shrink-0 mr-4">
            {type === 'warning' ? (
              <AlertTriangle className="w-6 h-6 text-yellow-500" />
            ) : type === 'danger' ? (
              <AlertCircle className="w-6 h-6 text-red-500" />
            ) : type === 'info' ? (
              <Info className="w-6 h-6 text-blue-500" />
            ) : (
              <HelpCircle className="w-6 h-6 text-gray-500" />
            )}
          </div>
          <div>
            <p className="text-gray-700">{message}</p>
          </div>
        </div>
      ),
      footer: ({ close }) => (
        <>
          <button
            onClick={() => {
              close();
              onCancel?.();
            }}
            className="px-4 py-2 text-gray-700 bg-white border rounded-md hover:bg-gray-50"
          >
            {cancelText}
          </button>
          <button
            onClick={() => {
              close();
              onConfirm?.();
            }}
            className={`px-4 py-2 text-white rounded-md
              ${confirmVariant === 'danger' ? 'bg-red-600 hover:bg-red-700' :
                confirmVariant === 'warning' ? 'bg-yellow-600 hover:bg-yellow-700' :
                'bg-blue-600 hover:bg-blue-700'}`}
          >
            {confirmText}
          </button>
        </>
      ),
      size: 'sm',
      persistent: true
    });

    return () => closeModal(id);
  };

  return { confirm };
};