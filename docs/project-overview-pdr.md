# Project Overview & Product Development Requirements

## Project Information

**Project Name:** Moon Calendar

**Description:** A modern full-stack web application combining Ruby on Rails backend with Svelte 5 frontend, connected through Inertia.js. This project serves as a starter kit for building modern web applications with server-side rendering capabilities.

**Repository:** moon-calendar

**Created:** November 2025

## Purpose & Goals

### Primary Purpose
Provide a production-ready starter template for building modern full-stack web applications using:
- Ruby on Rails 8.1+ for backend API and business logic
- Svelte 5 for reactive frontend UI
- Inertia.js for seamless server-client communication without building a separate API
- Modern tooling (Vite, TypeScript, TailwindCSS)

### Key Objectives
1. Eliminate the complexity of building separate frontend/backend applications
2. Enable rapid development with hot module replacement and modern tooling
3. Provide optional SSR (Server-Side Rendering) support for better SEO and initial load performance
4. Include authentication scaffolding for common use cases
5. Support deployment via Docker and Kamal

## Target Users

### Developers
- Full-stack developers looking for a modern Rails + JavaScript framework starter
- Teams wanting to build SPAs without the complexity of separate API servers
- Developers familiar with Rails who want to use modern frontend frameworks
- Organizations needing production-ready deployable applications

## Key Features

### Current Features

#### Backend (Rails 8.1)
- **Framework:** Ruby on Rails 8.1.1
- **Database:** SQLite3 (development), configurable for production
- **Asset Pipeline:** Propshaft for asset management
- **Web Server:** Puma
- **Authentication:** Authentication Zero integration (scaffolding ready)
- **Background Jobs:** Solid Queue (database-backed)
- **Caching:** Solid Cache (database-backed)
- **WebSockets:** Solid Cable (database-backed)
- **Security:** Brakeman, Bundler Audit integration
- **API:** JSON building with Jbuilder
- **Request Context:** Current.rb for request-scoped data (session, user_agent, ip_address)

#### Frontend (Svelte 5)
- **Framework:** Svelte 5.37+ with TypeScript
- **Build Tool:** Vite 7+ with HMR
- **Routing:** Inertia.js for SPA-like navigation
- **Styling:** TailwindCSS 4+ with comprehensive component library (1371 lines)
  - Pre-built components: alerts, badges, buttons, cards, checkboxes, dialogs, forms, sidebar, tables, tabs, tooltips, toasts
  - Dark mode support included
  - Responsive design utilities
- **Component Library:** shadcn-svelte compatible setup
- **Icons:** Lucide Svelte icons
- **State Management:** Svelte 5 runes system with custom hooks
  - `use-appearance.svelte.ts`: Theme management (light/dark/system)
  - `use-flash.svelte.ts`: Flash notification handler
  - `is-mobile.svelte.ts`: Responsive detection
  - `use-initials.ts`: Name initials utility
- **Notifications:** Svelte Sonner for toast notifications
- **Theme:** Mode-watcher for dark/light mode support
- **Demo/Showcase:** Kitchen sink page with demo components and theme switcher

#### Development Tools
- **Linting:** ESLint 9 with TypeScript support
- **Code Formatting:** Prettier with Svelte and Tailwind plugins
- **Ruby Linting:** RuboCop with Rails Omakase configuration
- **Type Checking:** TypeScript with svelte-check
- **Testing:** RSpec for backend, Capybara for system tests
- **CI/CD:** GitHub Actions workflows for CI and deployment
- **Deployment:** Kamal for containerized deployment
- **Process Management:** run-pty for local development

### Optional Features
- **SSR Support:** Server-side rendering can be enabled (currently disabled by default)
- **PWA:** Progressive Web App manifest and service worker templates included

### Demonstrated Features
- Kitchen sink demo page showcasing all UI components
- Theme switcher component for dark/light mode toggling
- Section components for organized content display
- Request tracking with user_agent and IP address logging

### Planned Features
Based on the starter kit nature, planned features include:
- User authentication system completion
- Database migrations for user management
- Email verification workflows
- Password reset functionality
- Session management UI
- User settings/profile pages
- Additional demo pages beyond kitchen sink
- Form handling patterns documentation

## Product Development Requirements

### Functional Requirements

#### FR1: Frontend-Backend Integration
- **Priority:** Critical
- **Description:** Seamless page navigation using Inertia.js without full page reloads
- **Acceptance Criteria:**
  - Inertia.js configured and working
  - Page components load dynamically
  - Browser history works correctly
  - Progress indicators show during navigation

#### FR2: Development Environment
- **Priority:** Critical
- **Description:** Fast, reliable local development environment
- **Acceptance Criteria:**
  - `bin/setup` initializes project correctly
  - `bin/dev` starts all required services
  - Hot module replacement works for Svelte components
  - Live reload works for Rails controllers/routes

#### FR3: Type Safety
- **Priority:** High
- **Description:** TypeScript integration for frontend code
- **Acceptance Criteria:**
  - TypeScript compilation works without errors
  - Type definitions available for all dependencies
  - IDE autocomplete works for Rails routes (via js-routes)

#### FR4: Styling System
- **Priority:** High
- **Description:** Utility-first CSS with component library support
- **Acceptance Criteria:**
  - TailwindCSS classes compile correctly
  - Dark mode toggle works
  - Responsive design utilities available
  - Custom components can be created

#### FR5: Testing Infrastructure
- **Priority:** High
- **Description:** Automated testing for backend and frontend
- **Acceptance Criteria:**
  - RSpec tests run successfully
  - System tests work with Capybara
  - CI pipeline runs all tests
  - Test coverage can be measured

### Non-Functional Requirements

#### NFR1: Performance
- **Requirement:** Initial page load under 2 seconds on 3G
- **Target:** First Contentful Paint (FCP) under 1.5s
- **Measurement:** Lighthouse performance score above 85

#### NFR2: Developer Experience
- **Requirement:** Fast feedback loops
- **Target:** HMR updates under 100ms
- **Target:** Test suite runs in under 30 seconds

#### NFR3: Code Quality
- **Requirement:** Maintain high code standards
- **Enforcement:** All linters must pass in CI
- **Standards:** Follow Rails and TypeScript best practices

#### NFR4: Security
- **Requirement:** No known vulnerabilities
- **Enforcement:** Brakeman and Bundler Audit must pass
- **Practice:** Security headers configured via CSP

#### NFR5: Deployment
- **Requirement:** Containerized deployment ready
- **Target:** Deploy to production in under 10 minutes
- **Platform:** Docker with Kamal orchestration

### Technical Constraints

1. **Runtime Requirements:**
   - Ruby 3.3+ (specified in .ruby-version)
   - Node.js 20.9+ or 22+ (specified in .node-version)
   - Modern browser supporting ES2020+

2. **Package Management:**
   - pnpm for JavaScript dependencies
   - Bundler for Ruby gems

3. **Database:**
   - SQLite3 2.1+ for development
   - PostgreSQL recommended for production

4. **Deployment:**
   - Docker containerization required
   - Kamal 2.0+ for orchestration

### Dependencies & Integrations

#### Core Dependencies
- Rails 8.1.1
- Svelte 5.37+
- Vite 7.0+
- Inertia Rails 3.10+
- TailwindCSS 4.1+

#### Infrastructure
- Puma web server
- Solid Queue for jobs
- Solid Cache for caching
- Solid Cable for WebSockets

### Success Metrics

1. **Developer Onboarding:** New developer can run app locally within 15 minutes
2. **Build Performance:** Production build completes in under 5 minutes
3. **Test Coverage:** Maintain above 80% code coverage
4. **Zero Downtime Deployments:** Achieved via Kamal health checks
5. **Lighthouse Scores:** Performance, Accessibility, Best Practices above 90

## Architecture Decisions

### ADR-001: Inertia.js Over Traditional API
- **Decision:** Use Inertia.js instead of building separate REST/GraphQL API
- **Rationale:** Simpler architecture, less code duplication, better DX
- **Trade-offs:** Couples frontend to Rails, not suitable for mobile apps

### ADR-002: Svelte Over React/Vue
- **Decision:** Use Svelte 5 with runes
- **Rationale:** Less boilerplate, better performance, simpler reactivity
- **Trade-offs:** Smaller ecosystem than React

### ADR-003: Vite Over Webpacker
- **Decision:** Use Vite Rails plugin
- **Rationale:** Faster builds, better HMR, modern tooling
- **Trade-offs:** Newer technology, less Rails community examples

### ADR-004: Solid* Suite Over Redis
- **Decision:** Use Solid Queue/Cache/Cable (database-backed)
- **Rationale:** Simpler deployment, fewer dependencies
- **Trade-offs:** May need Redis for very high-scale deployments

### ADR-005: Kamal for Deployment
- **Decision:** Include Kamal configuration
- **Rationale:** Modern deployment tool, Docker-based, zero-downtime
- **Trade-offs:** Requires Docker knowledge

## Project Roadmap

### Phase 1: Foundation (Current)
- ✅ Rails + Svelte + Inertia integration
- ✅ Development environment setup
- ✅ CI/CD pipeline
- ✅ Linting and code quality tools
- ✅ Deployment configuration

### Phase 2: Authentication (Next)
- ✅ Basic password sign-in/sign-out with persisted sessions
- ✅ Email verification
- ⏳ Password reset flows
- ⏳ Session management UI

### Phase 3: Enhancement
- ⏳ SSR documentation and examples
- ⏳ Component library integration
- ⏳ Form handling patterns
- ⏳ Error handling best practices

### Phase 4: Production Ready
- ⏳ Production deployment guide
- ⏳ Monitoring and logging setup
- ⏳ Performance optimization
- ⏳ Security hardening guide

## Maintenance & Support

- **Dependency Updates:** Automated via Dependabot (weekly)
- **Security Patches:** Monitored via Brakeman and Bundler Audit
- **Breaking Changes:** Documented in release notes
- **Community Support:** GitHub issues and discussions
