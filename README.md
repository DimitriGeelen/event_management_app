# Event Management Application

A modern event management application with location-based features, file uploads, and filtering capabilities.

## Quick Start

### Automatic Installation (Ubuntu 24.04)

```bash
curl -O https://raw.githubusercontent.com/DimitriGeelen/event_management_app/main/install_lan.sh
chmod +x install_lan.sh
sudo ./install_lan.sh
```

For detailed installation instructions, see [INSTALLATION.md](INSTALLATION.md)

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

## Documentation

- [Installation Guide](INSTALLATION.md) - Detailed installation instructions
- [Development Guide](DEVELOPMENT.md) - Guide for developers
- [API Documentation](docs/API.md) - API endpoints and usage
- [Contributing Guide](CONTRIBUTING.md) - How to contribute

## System Requirements

- Ubuntu 24.04 LTS
- 4GB RAM minimum
- 20GB disk space
- Internet connection

## Tech Stack

### Frontend
- React.js
- React Router for routing
- Tailwind CSS for styling
- Lucide React for icons

### Backend
- Node.js
- Express.js
- MongoDB
- JWT for authentication

### Infrastructure
- Docker
- Nginx
- PM2 Process Manager

### Monitoring
- Prometheus
- Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)

## Development Setup

1. Clone the repository:
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

3. Create environment file:
```bash
cp .env.example .env
# Edit .env with your settings
```

4. Start development servers:
```bash
# Backend
npm run dev

# Frontend (in another terminal)
cd frontend
npm start
```

## Production Deployment

1. Build frontend:
```bash
cd frontend
npm run build
```

2. Start production services:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Contributing

1. Fork the repository
2. Create your feature branch
```bash
git checkout -b feature/amazing-feature
```

3. Commit your changes
```bash
git commit -m 'Add some amazing feature'
```

4. Push to the branch
```bash
git push origin feature/amazing-feature
```

5. Open a Pull Request

## Monitoring & Logs

### Monitoring Dashboard
- Grafana: `http://your-server/grafana`
- Default credentials in installation logs

### Log Access
- Application logs: `/var/log/event_management`
- Nginx logs: `/var/log/nginx`
- Docker logs: `docker-compose logs`
- Kibana dashboard: `http://your-server/kibana`

## Backup

Automatic daily backups are configured for:
- MongoDB database
- Uploaded files
- Application configurations

Backups are stored in `/backup/event_management`

## Security

- JWT authentication
- Role-based access control
- File upload validation
- SQL injection protection
- XSS protection
- CORS configured
- Rate limiting

## Support

- GitHub Issues: Create an issue in the repository
- Documentation: Check the `/docs` directory
- Logs: Check `/var/log` directory

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all contributors
- Built with open source software
- Icons by Lucide
- UI components by shadcn/ui