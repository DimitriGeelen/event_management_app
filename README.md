# Event Management Application

A modern event management application with location-based features, file uploads, and filtering capabilities.

## Features

- Create and manage events with detailed information
- Upload images and PDFs for events
- Location-based search and filtering
- Interactive map showing event locations
- Tag-based event categorization
- Date-based filtering
- Radius-based location search
- Admin tag management
- Modern, responsive UI
- Authentication and authorization
- Real-time notifications
- Confirmation dialogs
- File drag and drop support

## Tech Stack

### Frontend
- React.js
- React Router for routing
- Tailwind CSS for styling
- Lucide React for icons
- Context API for state management
- Custom hooks for reusable logic
- Responsive design

### Backend
- Node.js
- Express.js
- MongoDB with Mongoose
- JWT for authentication
- Multer for file uploads
- Express Validator for input validation

## Setup Instructions

### Prerequisites
- Node.js (v14 or higher)
- MongoDB
- npm or yarn

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
PORT=5000
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/event_management_app.git
cd event_management_app
```

2. Install backend dependencies:
```bash
npm install
```

3. Install frontend dependencies:
```bash
cd frontend
npm install
```

### Running the Application

1. Start the backend server:
```bash
# From the root directory
npm run server
```

2. Start the frontend development server:
```bash
# From the frontend directory
npm start
```

The application will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000

## Project Structure

```
event_management_app/
├── backend/
│   ├── models/          # Database models
│   ├── routes/          # API routes
│   ├── middleware/      # Custom middleware
│   └── server.js        # Server entry point
├── frontend/
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── context/     # Context providers
│   │   ├── hooks/       # Custom hooks
│   │   └── services/    # API services
│   ├── public/          # Static files
│   └── package.json     # Frontend dependencies
└── package.json         # Backend dependencies
```

## API Endpoints

### Events
- `GET /api/events` - Get all events with filtering
- `POST /api/events` - Create a new event
- `PUT /api/events/:id` - Update an event
- `DELETE /api/events/:id` - Delete an event

### Tags
- `GET /api/tags` - Get all tags
- `POST /api/tags` - Create a new tag (admin only)
- `PUT /api/tags/:id` - Update a tag (admin only)
- `DELETE /api/tags/:id` - Delete a tag (admin only)

### Authentication
- `POST /api/users/register` - Register a new user
- `POST /api/users/login` - Login user
- `GET /api/users/me` - Get current user
- `PUT /api/users/me` - Update user profile

## Components

### UI Components
- `Layout` - Main application layout with navigation
- `EventForm` - Form for creating/editing events
- `EventList` - List of events with filtering
- `TagManagement` - Admin interface for managing tags
- `FileUploadAdvanced` - File upload with drag and drop
- `NotificationSystem` - Toast notifications
- `ModalSystem` - Modal dialogs
- `ConfirmationDialog` - Confirmation dialogs

### Context Providers
- `AuthProvider` - Authentication state management
- `NotificationProvider` - Notification state management
- `ModalProvider` - Modal state management

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.