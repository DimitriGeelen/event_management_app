#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
 fi

# Update package list
apt update

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt install -y nodejs

# Install development tools
echo "Installing development tools..."
apt install -y git curl wget build-essential

# Install MongoDB
echo "Installing MongoDB..."
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

apt update
apt install -y mongodb-org

# Start MongoDB
systemctl start mongod
systemctl enable mongod

# Install global npm packages
echo "Installing global npm packages..."
npm install -g nodemon
npm install -g npm-check-updates
npm install -g jest
npm install -g concurrently

# Install VS Code if not installed
if ! command -v code &> /dev/null; then
    echo "Installing Visual Studio Code..."
    snap install code --classic
fi

# Install VS Code extensions
echo "Installing VS Code extensions..."
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension ms-vscode.vscode-node-azure-pack
code --install-extension mongodb.mongodb-vscode
code --install-extension ms-azuretools.vscode-docker
code --install-extension christian-kohler.npm-intellisense
code --install-extension ms-vsliveshare.vsliveshare

# Create development directory structure
echo "Setting up development environment..."
mkdir -p ~/dev/event_management_app
cd ~/dev/event_management_app

# Clone repository
git clone https://github.com/DimitriGeelen/event_management_app.git .

# Install dependencies
echo "Installing project dependencies..."
npm install
cd frontend && npm install
cd ..

# Create development environment file
echo "Creating development environment file..."
cat > .env.development << EOL
MONGODB_URI=mongodb://localhost:27017/event_management_dev
JWT_SECRET=dev_secret_key
PORT=5000
NODE_ENV=development
EOL

# Set up Git hooks
echo "Setting up Git hooks..."
cat > .git/hooks/pre-commit << EOL
#!/bin/bash

# Run tests
npm test

# Run linter
npm run lint
EOL

chmod +x .git/hooks/pre-commit

# Create test environment file
echo "Creating test environment file..."
cat > .env.test << EOL
MONGODB_URI=mongodb://localhost:27017/event_management_test
JWT_SECRET=test_secret_key
PORT=5001
NODE_ENV=test
EOL

# Set proper permissions
chown -R $SUDO_USER:$SUDO_USER ~/dev/event_management_app

echo "Development environment setup completed!"
echo "You can now cd into ~/dev/event_management_app and start developing"