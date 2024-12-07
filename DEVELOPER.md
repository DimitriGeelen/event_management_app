# Developer Guide

## Development Environment Setup

### Prerequisites

- Ubuntu 24.04 LTS
- Sudo privileges

### Automatic Setup

Run the development environment setup script:

```bash
sudo ./scripts/setup-dev-environment.sh
```

### Manual Setup

1. Install prerequisites:
   ```bash
   sudo apt update
   sudo apt install git curl wget build-essential
   ```

2. Install Node.js:
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

3. Install MongoDB:
   ```bash
   # Add MongoDB repository
   curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
      sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
      --dearmor

   echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
      sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

   sudo apt update
   sudo apt install -y mongodb-org
   sudo systemctl start mongod
   sudo systemctl enable mongod
   ```

## Project Structure

```
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

## Development Workflow

### Starting the Development Servers

1. Start the backend server:
   ```bash
   npm run server
   ```

2. Start the frontend development server:
   ```bash
   cd frontend
   npm start
   ```

### Running Tests

```bash
# Run backend tests
npm test

# Run frontend tests
cd frontend && npm test

# Run all tests with coverage
npm run test:coverage
```

### Code Style and Linting

```bash
# Run ESLint
npm run lint

# Fix ESLint issues
npm run lint:fix

# Run Prettier
npm run format
```

## Debugging

### VS Code Debugging

This project includes VS Code launch configurations for debugging:

1. **Backend: Debug Server**
   - Launches the backend server with the debugger attached
   - Press F5 to start debugging

2. **Frontend: Debug Chrome**
   - Launches Chrome with the debugger attached
   - Set breakpoints in your React components

3. **Jest: Run Tests**
   - Debugs the test suite
   - Set breakpoints in test files

### Debug Logs

```bash
# View backend logs
PM2_DEBUG=true npm run server

# View frontend development server logs
DEBUG=true npm start
```

## Database Management

### MongoDB Commands

```bash
# Access MongoDB shell
mongosh

# View databases
show dbs

# Select database
use event_management_dev

# View collections
show collections
```

### Database Backup/Restore

```bash
# Backup
mongodump --db event_management_dev --out ./backup

# Restore
mongorestore --db event_management_dev ./backup/event_management_dev
```

## Deployment

### Production Build

```bash
# Build frontend
cd frontend && npm run build

# Start production server
NODE_ENV=production npm start
```

### Environment Variables

Create `.env` files for different environments:

- `.env.development` - Development settings
- `.env.test` - Test settings
- `.env.production` - Production settings

Required variables:
```env
MONGODB_URI=mongodb://localhost:27017/event_management
JWT_SECRET=your_jwt_secret
PORT=5000
NODE_ENV=development
```

## Contributing

### Git Workflow

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature
   ```

2. Make your changes and commit:
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

3. Push changes:
   ```bash
   git push origin feature/your-feature
   ```

4. Create a Pull Request

### Commit Message Format

Follow the Conventional Commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Formatting
- refactor: Code restructuring
- test: Tests
- chore: Maintenance

## Troubleshooting

### Common Issues

1. **MongoDB Connection Issues**
   ```bash
   sudo systemctl status mongod
   sudo systemctl restart mongod
   ```

2. **Port Already in Use**
   ```bash
   sudo lsof -i :5000
   sudo kill -9 <PID>
   ```

3. **Node Module Issues**
   ```bash
   rm -rf node_modules
   npm cache clean --force
   npm install
   ```

### Getting Help

1. Check the documentation in `/docs`
2. Review existing issues on GitHub
3. Contact the development team
4. Submit a new issue

## Tools and Extensions

### Recommended VS Code Extensions

- ESLint
- Prettier
- MongoDB for VS Code
- Docker
- npm Intellisense
- Live Share

### Development Tools

- Postman - API testing
- MongoDB Compass - Database management
- React Developer Tools - Chrome extension
- Redux DevTools - Chrome extension

## Security

### Development Security Practices

1. Never commit sensitive data
2. Use environment variables
3. Keep dependencies updated
4. Follow security best practices
5. Regular security audits

## Performance

### Optimization Tips

1. Use React.memo for expensive components
2. Implement proper indexing in MongoDB
3. Optimize images and assets
4. Use lazy loading
5. Implement caching strategies
