import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import EventList from './components/EventList';
import EventForm from './components/EventForm';
import TagManagement from './components/TagManagement';
import { AuthProvider } from './context/AuthContext';
import { NotificationProvider } from './components/NotificationSystem';
import { ModalProvider } from './components/ModalSystem';
import ProtectedRoute from './components/ProtectedRoute';

const App = () => {
  return (
    <AuthProvider>
      <NotificationProvider>
        <ModalProvider>
          <Router>
            <Layout>
              <Routes>
                <Route path="/" element={<EventList />} />
                <Route path="/events" element={<EventList />} />
                <Route 
                  path="/events/new" 
                  element={
                    <ProtectedRoute>
                      <EventForm />
                    </ProtectedRoute>
                  } 
                />
                <Route 
                  path="/events/:id/edit" 
                  element={
                    <ProtectedRoute>
                      <EventForm />
                    </ProtectedRoute>
                  } 
                />
                <Route 
                  path="/admin/tags" 
                  element={
                    <ProtectedRoute adminOnly>
                      <TagManagement />
                    </ProtectedRoute>
                  } 
                />
              </Routes>
            </Layout>
          </Router>
        </ModalProvider>
      </NotificationProvider>
    </AuthProvider>
  );
};

export default App;