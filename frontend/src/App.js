import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

function App() {
  return (
    <Router>
      <div className="App">
        <header className="App-header">
          <h1>Event Management System</h1>
        </header>
        <main>
          <Routes>
            <Route path="/" element={<h2>Welcome to Event Management</h2>} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;