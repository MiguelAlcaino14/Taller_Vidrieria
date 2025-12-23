import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import { AuthProvider } from './contexts/AuthContext';
import './index.css';

const rootElement = document.getElementById('root');

if (!rootElement) {
  document.body.innerHTML = '<div style="padding: 20px; color: red;">Error: No se encontró el elemento root</div>';
} else {
  try {
    createRoot(rootElement).render(
      <StrictMode>
        <AuthProvider>
          <App />
        </AuthProvider>
      </StrictMode>
    );
  } catch (error) {
    console.error('Error al iniciar la aplicación:', error);
    rootElement.innerHTML = `<div style="padding: 20px; background: #fee; color: #c00;">
      <h2>Error al iniciar la aplicación</h2>
      <p>${error instanceof Error ? error.message : 'Error desconocido'}</p>
      <p>Por favor abre la consola del navegador para más detalles.</p>
    </div>`;
  }
}
