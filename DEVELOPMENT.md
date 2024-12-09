# Development Guide

## Development Environment Setup

### Prerequisites

1. Install Node.js and npm:
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

2. Install development tools:
```bash
sudo apt install -y git build-essential
```

3. Install Docker:
```bash
curl -fsSL https://get.docker.com | sudo bash
sudo apt install -y docker-compose
```

### Project Setup

1. Clone repository:
```bash
git clone https://github.com/DimitriGeelen/event_management_app.git
cd event_management_app
```

2. Install dependencies:
```bash
# Backend dependencies
npm install

# Frontend dependencies
cd frontend
npm install
```

3. Set up environment:
```bash
cp .env.example .env
# Edit .env with your settings
```

## Development Workflow

### Running in Development Mode

1. Start backend:
```bash
npm run dev
```

2. Start frontend:
```bash
cd frontend
npm start
```

### Code Style

We use ESLint and Prettier for code formatting. Configuration files are included in the repository.

- Check style: `npm run lint`
- Fix style issues: `npm run lint:fix`

### Testing

```bash
# Run backend tests
npm test

# Run frontend tests
cd frontend && npm test

# Run with coverage
npm run test:coverage
```

## Project Structure

```
.
├── backend/
│   ├── models/        # Database models
│   ├── routes/        # API routes
│   ├── middleware/    # Custom middleware
│   └── tests/         # Backend tests
├── frontend/
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── context/     # Context providers
│   │   ├── hooks/       # Custom hooks
│   │   └── tests/       # Frontend tests
│   └── public/        # Static files
└── docs/             # Documentation
```

## Database

### Models

1. Event Model:
```javascript
{
  title: String,
  description: String,
  location: {
    name: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  startDateTime: Date,
  endDateTime: Date,
  tags: [ObjectId],
  files: [{
    filename: String,
    path: String
  }]
}
```

2. User Model:
```javascript
{
  username: String,
  email: String,
  password: String,
  role: String
}
```

### Migration Scripts

Located in `backend/migrations/`:
```bash
node backend/migrations/migrate.js
```

## API Documentation

### Authentication

```bash
# Login
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password"
}

# Register
POST /api/auth/register
{
  "username": "user",
  "email": "user@example.com",
  "password": "password"
}
```

### Events

```bash
# Create event
POST /api/events

# Get events
GET /api/events

# Update event
PUT /api/events/:id

# Delete event
DELETE /api/events/:id
```

## Component Development

### Creating New Components

1. Create component file:
```bash
touch frontend/src/components/NewComponent.jsx
```

2. Create test file:
```bash
touch frontend/src/components/__tests__/NewComponent.test.jsx
```

3. Template:
```jsx
import React from 'react';

function NewComponent() {
  return (
    <div>
      <h1>New Component</h1>
    </div>
  );
}

export default NewComponent;
```

### Styling

We use Tailwind CSS for styling:

```jsx
<div className="flex items-center justify-between p-4">
  <h1 className="text-xl font-bold">Title</h1>
</div>
```

## Docker Development

### Development Containers

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose logs -f

# Stop environment
docker-compose down
```

### Building for Production

```bash
# Build production images
docker-compose -f docker-compose.prod.yml build

# Run production stack
docker-compose -f docker-compose.prod.yml up -d
```

## Contributing

1. Fork the repository
2. Create a feature branch:
```bash
git checkout -b feature/new-feature
```

3. Make changes and commit:
```bash
git add .
git commit -m "feat: add new feature"
```

4. Push changes:
```bash
git push origin feature/new-feature
```

5. Create Pull Request

### Commit Message Format

Follow conventional commits:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Formatting
- refactor: Code restructuring
- test: Adding tests
- chore: Maintenance

## Debugging

### Backend

1. Using Node.js debugger:
```bash
node --inspect backend/server.js
```

2. VS Code configuration:
```json
{
  "type": "node",
  "request": "launch",
  "name": "Debug Backend",
  "program": "${workspaceFolder}/backend/server.js"
}
```

### Frontend

1. React Developer Tools
2. Redux DevTools (if using Redux)
3. Browser debugging:
```javascript
debugger;
// Your code here
```

## Deployment

### Staging

```bash
./scripts/deploy-staging.sh
```

### Production

```bash
./scripts/deploy-production.sh
```

## Additional Resources

- [React Documentation](https://reactjs.org/)
- [Node.js Documentation](https://nodejs.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Tailwind CSS Documentation](https://tailwindcss.com/)