# Lunar Calendar

A modern full-stack starter application combining **Ruby on Rails 8.1** backend with **Svelte 5** frontend using **Inertia.js**.

<a href="https://imtbn.com/">
<img src="https://imtbn.com/wp-content/uploads/2023/01/Logo.png" alt="Maintained by IMTBN DEV" width="520" height="200">
</a>

## What's Inside

- **Backend:** Rails 8.1.1 with Rails + Inertia
- **Frontend:** Svelte 5 with TypeScript
- **Styling:** TailwindCSS 4 with dark mode support
- **Authentication:** Authentication Zero scaffolding
- **Deployment:** Kamal for zero-downtime Docker deployments
- **Infrastructure:** Solid Queue/Cache/Cable (database-backed, no Redis required)
- **Optional SSR:** Server-side rendering support

## Tech Stack

### Backend
- Ruby on Rails 8.1.1
- Inertia Rails 3.10+
- Vite Rails 3.0+
- Puma web server
- SQLite3 (development), PostgreSQL (production recommended)
- Solid Queue (background jobs)
- Solid Cache (caching)
- Solid Cable (WebSockets)

### Frontend
- Svelte 5.37+ with TypeScript
- Vite 7.0+ with HMR
- TailwindCSS 4.1+
- Inertia.js 2.0+
- Lucide icons
- Svelte Sonner (notifications)
- Mode Watcher (theme management)

### Development Tools
- RSpec + Capybara (testing)
- ESLint + Prettier (code quality)
- RuboCop (Ruby linting)
- Brakeman + Bundler Audit (security)
- GitHub Actions (CI/CD)
- run-pty (process management)

## Quick Start

### Prerequisites
- Ruby 3.3+ (see [.ruby-version](./.ruby-version))
- Node.js 20.9+ or 22+ (see [.node-version](./.node-version))
- pnpm (installed automatically)
- SQLite3

### Setup

1. **Clone and setup:**
   ```bash
   git clone <your-repo>
   cd moon-calendar
   bin/setup
   ```

2. **Start development server:**
   ```bash
   bin/dev
   ```

3. **Open in browser:**
   ```
   http://localhost:8888
   ```

That's it! The application is now running with hot module replacement enabled.

## Development

### Running the Application

```bash
bin/dev              # Start Rails + Vite with HMR
bin/rails server     # Rails only (port 3000)
bin/vite dev        # Vite only (port 5173)
```

### Code Quality

```bash
# JavaScript/TypeScript
pnpm lint:js         # ESLint check
pnpm fix:js          # Auto-fix linting errors
pnpm format          # Check Prettier formatting
pnpm format:fix      # Auto-format code
pnpm check           # TypeScript type checking

# Ruby
bin/rubocop          # RuboCop linting
bin/rubocop -a       # Auto-correct issues

# Security
bin/brakeman         # Static security analysis
bin/bundler-audit    # Dependency vulnerabilities

# All checks (CI)
bin/ci               # Run all CI checks locally
```

### Testing

```bash
bin/rspec                    # Run all tests
bin/rspec spec/requests      # Run request specs only
bin/rails db:test:prepare    # Prepare test database
```

### Generating Routes for JavaScript

```bash
rake js:routes               # Regenerate JavaScript routes
```

Import in frontend code:
```typescript
import routes from '@/routes'
routes.root_path()           // => "/"
```

## Project Structure

```
.
├── app/
│   ├── controllers/         # Rails controllers (Inertia responses)
│   ├── frontend/           # Svelte application
│   │   ├── components/     # Reusable Svelte components
│   │   ├── entrypoints/    # Vite entry points
│   │   ├── layouts/        # Page layouts
│   │   ├── pages/          # Inertia page components
│   │   ├── runes/          # Svelte 5 runes (composables)
│   │   └── types/          # TypeScript definitions
│   ├── models/             # ActiveRecord models
│   ├── jobs/               # Background jobs
│   └── views/              # ERB templates (layouts, mailers)
├── bin/                    # Executable scripts
├── config/                 # Application configuration
├── db/                     # Database schema and migrations
├── docs/                   # Project documentation
├── public/                 # Static files
└── spec/                   # RSpec tests
```

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Project Overview & PDR](./docs/project-overview-pdr.md)** - Project goals, features, and requirements
- **[Code Standards](./docs/code-standards.md)** - Coding conventions and best practices
- **[Codebase Summary](./docs/codebase-summary.md)** - High-level overview and directory structure
- **[System Architecture](./docs/system-architecture.md)** - Technical architecture and design decisions

## Enabling SSR (Optional)

This starter kit supports server-side rendering. To enable it:

### 1. Update Frontend Entry Point

Uncomment the SSR hydration code in `app/frontend/entrypoints/inertia.ts`:

```typescript
// Uncomment to enable SSR hydration:
if (el.dataset.serverRendered === 'true') {
  hydrate(App, {target: el, props})
  return
}
```

### 2. Update Deployment Configuration

Uncomment SSR-related sections in `config/deploy.yml`:

```yaml
servers:
  # Uncomment to enable SSR:
  vite_ssr:
    hosts:
      - 192.168.0.1
    cmd: bundle exec vite ssr
    options:
      network-alias: vite_ssr

env:
  clear:
    # Uncomment to enable SSR:
    INERTIA_SSR_ENABLED: true
    INERTIA_SSR_URL: "http://vite_ssr:13714"

builder:
  # Uncomment to enable SSR:
  dockerfile: Dockerfile-ssr
```

That's it! SSR is now enabled with zero additional configuration.

## Deployment

### With Kamal (Recommended)

1. **Configure deployment:**
   ```bash
   # Edit config/deploy.yml with your server details
   vim config/deploy.yml
   ```

2. **Set secrets:**
   ```bash
   # Set registry password and Rails master key
   export KAMAL_REGISTRY_PASSWORD=<your-password>
   export RAILS_MASTER_KEY=<your-master-key>
   ```

3. **Deploy:**
   ```bash
   bin/kamal deploy
   ```

### With Docker

```bash
# Build production image
docker build -f Dockerfile -t mfl-app .

# Or with SSR
docker build -f Dockerfile-ssr -t mfl-app-ssr .

# Run container
docker run -p 3000:3000 mfl-app
```

## Environment Variables

### Development
- `RAILS_ENV=development` (default)
- `NODE_ENV=development` (default)

### Production
- `RAILS_MASTER_KEY` - Required for encrypted credentials
- `DATABASE_URL` - PostgreSQL connection string
- `INERTIA_SSR_ENABLED` - Enable SSR (optional)
- `INERTIA_SSR_URL` - SSR server URL (if enabled)

## Key Features

### Current
- ✅ Rails + Svelte + Inertia.js integration
- ✅ Vite with HMR for instant feedback
- ✅ TypeScript support
- ✅ TailwindCSS 4 with dark mode
- ✅ Development environment setup
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Deployment ready (Kamal + Docker)
- ✅ Code quality tools (linting, formatting, security)
- ✅ Testing infrastructure (RSpec, Capybara)

### Planned
- ⏳ Complete user authentication system
- ⏳ Email verification and password reset
- ⏳ Component library integration
- ⏳ Production deployment guide
- ⏳ Monitoring and logging setup

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

All PRs must pass:
- ESLint and Prettier checks
- RuboCop linting
- Security scans (Brakeman, Bundler Audit)
- Test suite

## Runtime Versions

- **Ruby:** See [.ruby-version](./.ruby-version) (3.3+)
- **Node.js:** See [.node-version](./.node-version) (20.9+ or 22+)

## License

This project is available as open source.

## Resources

- [Inertia Rails Documentation](https://inertia-rails.dev)
- [Vite Ruby Documentation](https://vite-ruby.netlify.app)
- [Svelte Documentation](https://svelte.dev)
- [shadcn-svelte](https://shadcn-svelte.com)
- [Kamal Deploy](https://kamal-deploy.org)
- [Authentication Zero](https://github.com/lazaronixon/authentication-zero)

## Support

For issues and questions:
- Open an issue on GitHub
- Check the [documentation](./docs/)
- Review closed issues for solutions

## Acknowledgments

- [Inertia.js](https://inertiajs.com) for the amazing bridge between backend and frontend
- [Vite](https://vitejs.dev) for the fast build tool
- [Svelte](https://svelte.dev) for the elegant reactive framework
- [Rails](https://rubyonrails.org) for the solid foundation
- [IMTBN DEV](https://imtbn.com) for maintenance and support
