# Travelogue

A personal travel tracking web application that lets you record and visualize the places you've visited on an interactive map.

## Overview

Travelogue provides an intuitive way to document your travels. Click anywhere on the map to add a visit, attach dates and notes, and build your personal travel history. The app uses a passwordless authentication system—simply enter your email and receive a one-time code to sign in.

## Features

- **Interactive Map** – View all your visits on a Leaflet-powered world map
- **Quick Visit Logging** – Click to add a new visit with optional date and notes
- **Edit & Delete** – Update visit details or remove entries (right-click to delete)
- **Passwordless Auth** – Secure email-based login with one-time codes
- **Export** – Download your travel data
- **Mobile-Friendly** – Responsive design with Tailwind CSS

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Ruby on Rails 8.0 |
| Ruby | 3.4.6 |
| Database | SQLite 3 |
| Frontend | Hotwire (Turbo + Stimulus) |
| Styling | Tailwind CSS |
| Maps | Leaflet.js |
| Asset Pipeline | Propshaft + Importmap |
| Background Jobs | Solid Queue |
| Caching | Solid Cache |

## Prerequisites

- **Ruby 3.4.6** (recommend using [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/))
- **Bundler** (`gem install bundler`)
- **Node.js** (for Tailwind CSS build, optional if using pre-built assets)
- **SQLite 3** development headers

On Debian/Ubuntu:

```bash
sudo apt-get install libsqlite3-dev
```

On macOS:

```bash
brew install sqlite3
```

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd travelogue
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Configure Environment Variables

Create a `.env` file in the project root (see `.env.example` if available):

```bash
# Required for seeding a test user
TEST_USER_EMAIL=you@example.com

# Optional: email delivery settings for one-time codes in development
# ACTION_MAILER_SMTP_ADDRESS=...
# ACTION_MAILER_SMTP_PORT=...
```

### 4. Set Up the Database

```bash
bin/rails db:setup
```

This will create the database, run migrations, and seed initial data (a test user and sample visit).

## Running the Application

### Development Server

The recommended way to start the app in development is with the included Procfile:

```bash
bin/dev
```

This runs both the Rails server and the Tailwind CSS watcher concurrently.

Alternatively, start components manually:

```bash
# Terminal 1 – Rails server
bin/rails server

# Terminal 2 – Tailwind CSS watcher
bin/rails tailwindcss:watch
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Production Build

Compile assets for production:

```bash
bin/rails assets:precompile
```

Run with:

```bash
RAILS_ENV=production bin/rails server
```

## Running the Test Suite

Execute all tests:

```bash
bin/rails test
```

Run system tests (requires a browser driver):

```bash
bin/rails test:system
```

## Linting & Static Analysis

Check Ruby style:

```bash
bundle exec rubocop
```

Scan for security vulnerabilities:

```bash
bundle exec brakeman
```

## Deployment

The repository includes a `Dockerfile` for containerized deployments and supports [Kamal](https://kamal-deploy.org/) for simple Docker-based deployment.

```bash
# Build Docker image
docker build -t travelogue .

# Run container
docker run -p 3000:3000 travelogue
```

## Project Structure

```
app/
├── controllers/      # Request handlers (sessions, visits, etc.)
├── javascript/       # Stimulus controllers (map interactions)
├── models/           # ActiveRecord models (User, Place, Visit, etc.)
└── views/            # ERB templates

db/
├── migrate/          # Database migrations
├── schema.rb         # Current database schema
└── seeds.rb          # Sample data for development

config/
└── routes.rb         # Application routes
```

## Key Models

| Model | Description |
|-------|-------------|
| `User` | Account identified by email address |
| `Place` | Geographic location (city, landmark, etc.) |
| `Visit` | A user's recorded visit to a place |
| `OneTimeCode` | Passwordless auth codes |
| `Session` | Active user sessions |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes with clear messages
4. Push to your branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure tests pass and code follows the project's style guidelines before submitting.

## License

This project is private. All rights reserved.
