# Codebase Summary

## High-Level Overview

This is a modern full-stack web application starter kit that combines Ruby on Rails 8.1 (backend) with Svelte 5 (frontend), connected via Inertia.js. The project eliminates the need for a separate REST or GraphQL API by using Inertia.js as a bridge, allowing developers to build single-page applications (SPAs) while maintaining traditional server-side routing and controllers.

**Technology Stack:**
- **Backend:** Rails 8.1.1, Ruby 3.3+
- **Frontend:** Svelte 5, TypeScript, TailwindCSS 4
- **Bridge:** Inertia.js 3.10+
- **Build Tool:** Vite 7+ with Rails integration
- **Database:** SQLite3 (dev), configurable for production
- **Deployment:** Docker + Kamal
- **Testing:** RSpec + Capybara

## Directory Structure

```
.
├── app/                    # Application code
│   ├── controllers/        # Rails controllers (return Inertia responses)
│   ├── frontend/          # Svelte frontend (components, pages, etc.)
│   ├── helpers/           # Rails view helpers
│   ├── jobs/              # Background jobs (Solid Queue)
│   ├── mailers/           # Email handling
│   ├── models/            # ActiveRecord models (currently minimal)
│   └── views/             # ERB templates (layouts, mailers, PWA)
├── bin/                   # Executable scripts
├── config/                # Rails and application configuration
├── db/                    # Database schema and migrations
├── docs/                  # Project documentation
├── lib/                   # Custom libraries and Rake tasks
├── public/                # Static files (error pages, icons, robots.txt)
├── spec/                  # RSpec tests
├── storage/               # Active Storage files
└── tmp/                   # Temporary files
```

## Key Directories Explained

### `/app/controllers/`
Rails controllers that handle HTTP requests and return Inertia responses instead of traditional HTML views.

**Key Files (4 files):**
- `application_controller.rb`: Base controller with authentication hooks, request tracking (user_agent, ip_address)
- `inertia_controller.rb`: Base for Inertia-specific controllers, shares auth/flash globally
- `home_controller.rb`: Currently redirects root to kitchen_sink_path
- `kitchen_sink_controller.rb`: Component showcase/demo controller with ThemeSwitcher and Section components

**Pattern:**
```ruby
class KitchenSinkController < InertiaController
  def index
    render inertia: {} # => Renders app/frontend/pages/kitchen_sink/index.svelte
  end
end
```

### `/app/frontend/`
All frontend Svelte code, organized by purpose.

#### Structure:
```
frontend/
├── components/            # Reusable UI components
│   ├── charts/           # Chart components
│   │   ├── FunnelChart.svelte           # Conversion funnel visualization
│   │   ├── RetentionJourney.svelte      # Timeline showing user lifecycle
│   │   ├── RetentionSankeyChart.svelte  # Sankey flow diagram for state transitions
│   │   ├── insights/                    # Shared insights system
│   │   │   ├── insights-config.ts       # Config builders & evaluators
│   │   │   ├── InsightsBanner.svelte    # Health status banner component
│   │   │   └── MetricsGrid.svelte       # Metrics grid display component
│   │   ├── types.ts                     # Chart type definitions
│   │   └── __tests__/                   # Chart integration tests
│   │       └── insights-integration.spec.ts  # Insights system tests
│   └── ui/                # UI components (shadcn/svelte based)
│       └── mobile/                # Mobile-specific components
│           ├── SettingsItem.svelte        # Settings list item (toggle/chevron/value/custom)
│           └── SettingsSection.svelte     # Settings section with title and card container
├── entrypoints/          # Vite entry points
│   ├── inertia.ts        # Main Inertia.js setup
│   ├── application.css   # Global styles + TailwindCSS + theme imports (1512 lines)
│   └── mobile.css        # Mobile-specific utilities (safe areas, touch actions, DeviceFrame)
├── layouts/              # Page layout wrappers
│   └── persistent-layout.svelte  # Default layout with Toaster
├── pages/                # Inertia page components (map to Rails controllers)
│   ├── kitchen_sink/
│   │   ├── index.svelte  # Component showcase/demo page
│   │   └── sections/
│   │       └── ThemeSwitcher.svelte  # Theme switching component
│   └── kitchen_sink/
│       └── shared/
│           └── Section.svelte  # Reusable section component
├── routes/               # Auto-generated Rails routes for JS (js-routes gem)
│   ├── index.js          # Route definitions
│   └── index.d.ts        # TypeScript types
├── runes/                # Svelte 5 reactive utilities
│   ├── is-mobile.svelte.ts              # Responsive detection
│   ├── toast.svelte.ts                  # Toast notification system
│   ├── use-appearance.svelte.ts         # Theme management (light/dark/system)
│   ├── use-flash.svelte.ts              # Flash notification handler
│   └── use-initials.ts                  # Name initials utility
├── ssr/                  # Server-side rendering setup (optional)
│   └── ssr.ts
├── types/                # TypeScript type definitions (3 files)
│   ├── globals.d.ts      # Inertia PageProps augmentation
│   ├── index.d.ts        # Auth, User, Session, Flash, AppPageProps, NavItem interfaces
│   └── vite-env.d.ts     # Vite client types
└── utils.ts              # Utility functions (e.g., cn for class merging)
```

### `/config/`
Application configuration files.

**Important Files:**
- `routes.rb`: Rails routing (currently just root path and health check)
- `application.rb`: Main application config (module: `MoonCalendar`)
- `database.yml`: Database configuration
- `deploy.yml`: Kamal deployment config
- `vite.json`: Vite-Rails integration config
- `initializers/inertia_rails.rb`: Inertia.js configuration
- `initializers/js_routes.rb`: JS routes generation config

### `/db/`
Database-related files.

**Files:**
- `schema.rb`: Current database schema (empty, version 0)
- `seeds.rb`: Seed data
- `cache_schema.rb`: Solid Cache schema
- `queue_schema.rb`: Solid Queue schema
- `cable_schema.rb`: Solid Cable schema
- `migrate/`: Database migrations (currently empty)

**Note:** No migrations yet - database structure is minimal.

### `/lib/`
Custom libraries and modules.

**Key Modules:**
- `EmailTheme` - Theme-aware color palette system for email templates. Parses CSS theme files (OKLCH/HEX colors), converts to email-client-compatible HEX format, and caches palettes. Supports 4 themes (default, claude, blackpink, myfoodlink) × 2 modes (light/dark) = 8 cached palettes.
  - `CssParser` - Extracts CSS custom properties from theme files and application.css
  - `OklchConverter` - Converts OKLCH color values to HEX via OKLab and sRGB with gamma correction

### `/spec/`
RSpec test suite.

**Structure:**
```
spec/
├── factories/            # FactoryBot factories
│   └── users.rb
├── mailers/
├── requests/            # Request specs (integration tests)
│   ├── identity/
│   ├── settings/
│   ├── sessions_spec.rb
│   └── users_spec.rb
├── support/
│   └── authentication_helpers.rb
├── rails_helper.rb
└── spec_helper.rb
```

**Note:** Tests reference user authentication system (likely from authentication-zero gem), but implementation not yet in codebase.

### `/bin/`
Executable scripts for development and deployment.

**Key Scripts:**
- `setup`: Initialize project (install deps, setup DB)
- `dev`: Start development servers (Rails + Vite)
- `ci`: Run CI checks locally
- `rails`, `rake`, `rspec`: Standard Rails executables
- `rubocop`, `brakeman`, `bundler-audit`: Code quality tools
- `kamal`: Deployment tool
- `vite`: Vite development server

### `/public/`
Static assets served directly by web server.

**Contents:**
- Error pages: `400.html`, `404.html`, `406-unsupported-browser.html`, `422.html`, `500.html`
- `icon.png`, `icon.svg`: App icons
- `robots.txt`: Search engine directives

## Entry Points

### Backend Entry Point
**File:** `config.ru`
```ruby
require_relative "config/environment"
run Rails.application
```
- Loads Rails environment
- Starts Rack application

### Frontend Entry Point
**File:** `app/frontend/entrypoints/inertia.ts`
- Initializes Inertia.js
- Sets up page component resolution
- Configures SSR (optional)
- Initializes theme
- Loads from Rails via: `<%= vite_typescript_tag "inertia" %>`

### Root Page
**Route:** `GET /` → `HomeController#index`
**Component:** `app/frontend/pages/home/index.svelte`
- Displays welcome page with project information
- Links to Inertia.js documentation

## Build & Run Commands

### Development
```bash
# Setup (first time)
bin/setup                   # Install deps, setup DB

# Start development server
bin/dev                     # Starts Rails + Vite with HMR

# Individual servers
bin/rails server            # Rails only (port 3000)
bin/vite dev               # Vite only (port 5173)
```

### Testing
```bash
# Backend tests
bin/rspec                  # Run all specs
bin/rspec spec/requests    # Run request specs only

# CI (runs all checks)
bin/ci                     # Lint, security scan, tests
```

### Linting & Formatting
```bash
# JavaScript/TypeScript
pnpm lint:js               # ESLint check
pnpm fix:js                # ESLint auto-fix
pnpm format                # Prettier check
pnpm format:fix            # Prettier auto-format
pnpm check                 # TypeScript type checking

# Ruby
bin/rubocop                # RuboCop check
bin/rubocop -a             # RuboCop auto-correct

# Security
bin/brakeman               # Static security analysis
bin/bundler-audit          # Gem vulnerability check
```

### Production
```bash
# Build for production
bin/rails assets:precompile

# Deploy with Kamal
bin/kamal deploy

# Docker build
docker build -f Dockerfile -t app .
docker build -f Dockerfile-ssr -t app-ssr .  # With SSR
```

## Configuration Files

### JavaScript/TypeScript
- `package.json`: Node.js dependencies and scripts
- `pnpm-workspace.yaml`: pnpm workspace config
- `tsconfig.json`: TypeScript config for frontend
- `tsconfig.node.json`: TypeScript config for Node.js files
- `vite.config.ts`: Vite build configuration
- `eslint.config.js`: ESLint rules
- `.prettierrc`: Prettier formatting rules
- `svelte.config.js`: Svelte compiler options
- `components.json`: shadcn-svelte component config

### Ruby/Rails
- `Gemfile`: Ruby gem dependencies
- `.ruby-version`: Ruby version (3.3)
- `.rubocop.yml`: RuboCop linting rules
- `.rspec`: RSpec configuration
- `Rakefile`: Rake task definitions

### Deployment
- `Dockerfile`: Production Docker image
- `Dockerfile-ssr`: SSR-enabled Docker image
- `config/deploy.yml`: Kamal deployment config
- `.dockerignore`: Files excluded from Docker build
- `Procfile.dev`: Development process definitions

### CI/CD
- `.github/workflows/ci.yml`: Continuous Integration
- `.github/workflows/deploy.yml`: Deployment workflow
- `.github/dependabot.yml`: Dependency update automation

## Important Patterns & Conventions

### Inertia.js Flow
1. User navigates to route (e.g., `/`)
2. Rails controller action called (`HomeController#index`)
3. Controller returns Inertia response: `render inertia: { users: User.all.as_json(...) }`
4. Inertia.js intercepts response
5. Loads Svelte component from `app/frontend/pages/home/index.svelte`
6. Mounts component with props from Rails
7. Subsequent navigation happens via XHR (no full page reload)

### Component Resolution
```javascript
// In app/frontend/entrypoints/inertia.ts
resolve: (name) => {
  const pages = import.meta.glob('../pages/**/*.svelte', { eager: true })
  const page = pages[`../pages/${name}.svelte`]
  return {
    default: page.default,
    layout: page.layout ?? PersistentLayout  // Default layout for all pages
  }
}
```

### Route Generation
Rails routes are automatically available in JavaScript:
```typescript
import routes from '@/routes'  // Auto-generated by js-routes gem

// Usage
routes.root_path()           // => "/"
routes.users_path()          // => "/users"
routes.user_path(1)          // => "/users/1"
```

### Svelte 5 Runes
This project uses Svelte 5's new runes system:
```svelte
<script lang="ts">
  let count = $state(0)          // Reactive state
  let doubled = $derived(count * 2)  // Computed value

  $effect(() => {                // Side effect
    console.log('Count:', count)
  })
</script>
```

### Theme Management
Dark/light mode handled by `use-appearance.svelte.ts`:
```typescript
import { initializeTheme } from '@/runes/use-appearance.svelte'
initializeTheme()  // Called in inertia.ts
```

## Database Schema

**Current State:** Empty (no migrations)
```ruby
ActiveRecord::Schema[8.1].define(version: 0) do
end
```

**Solid* Suite Schemas:**
- Solid Cache: Database-backed caching
- Solid Queue: Database-backed job queue
- Solid Cable: Database-backed WebSockets

These have separate schema files but are managed independently.

## Dependencies

### Key Backend Gems
- `rails` (8.1.1): Web framework
- `inertia_rails` (3.10+): Inertia.js adapter
- `vite_rails` (3.0+): Vite integration
- `js-routes`: Rails routes in JavaScript
- `authentication-zero`: Auth scaffolding
- `solid_cache`, `solid_queue`, `solid_cable`: Database-backed infrastructure
- `propshaft`: Asset pipeline
- `puma`: Web server
- `kamal`: Deployment tool
- `bcrypt`: Password hashing

### Key Frontend Packages
- `svelte` (5.37+): Frontend framework
- `@inertiajs/svelte` (2.0+): Inertia.js Svelte adapter
- `@sveltejs/vite-plugin-svelte` (6.1+): Vite plugin
- `vite` (7.0+): Build tool
- `vite-plugin-rails`: Vite-Rails bridge
- `tailwindcss` (4.1+): CSS framework
- `@tailwindcss/vite`: Tailwind Vite plugin
- `typescript` (5.8+): Type checking
- `@lucide/svelte`: Icon library
- `clsx`, `tailwind-merge`: CSS utility helpers

### Development Tools
- **Testing:** `rspec-rails`, `factory_bot_rails`, `capybara`, `selenium-webdriver`
- **Linting:** `eslint`, `rubocop-rails-omakase`
- **Formatting:** `prettier`, `prettier-plugin-svelte`
- **Security:** `brakeman`, `bundler-audit`
- **Type Checking:** `svelte-check`, `typescript`

## Current State & Next Steps

### What's Complete
✅ Rails + Svelte + Inertia.js integration
✅ Vite build configuration with HMR
✅ TailwindCSS styling setup with comprehensive component library (1371 lines)
✅ Development environment (bin/setup, bin/dev)
✅ CI/CD pipeline (GitHub Actions)
✅ Deployment configuration (Kamal + Docker)
✅ Linting and formatting tools
✅ Testing infrastructure (RSpec, Capybara)
✅ Theme switching (dark/light mode with use-appearance rune)
✅ Request context tracking (user_agent, ip_address via Current model)
✅ Kitchen sink demo page with component showcase
✅ Svelte 5 runes system
✅ EmailTheme system (OKLCH to HEX color conversion for email templates)
✅ Basic authentication session model and sign-in/sign-out flow

### What's Missing/Incomplete
⏳ Email verification flows
⏳ Password reset functionality
⏳ Session management UI
⏳ Additional frontend pages beyond kitchen sink demo
⏳ Frontend unit/integration tests (no test files in app/frontend)
⏳ Production deployment documentation
⏳ SSR enablement guide (currently disabled by default)

### Quick Start for New Developers
1. Clone repository
2. Run `bin/setup` (installs dependencies, sets up database)
3. Run `bin/dev` (starts Rails + Vite)
4. Visit `http://localhost:8888`
5. Edit Svelte files in `app/frontend/pages/` - changes reflect immediately
6. Edit Rails controllers in `app/controllers/` - refresh required

**API Consistency:**
- Prop naming standardized: `open`, `disabled`, `required` (no `isOpen`, `isDisabled`, `isRequired`)
- CSS classes use `class` prop (not `className`)
- All Boolean props consistently named
- Variant systems use identical object lookup pattern

## Mobile Components (Phase 02)

### SettingsItem (143 lines)
Individual settings list item component supporting multiple action types and icon customization.

**Features:**
- Four action modes: `toggle` (Switch control), `chevron` (navigation), `value` (display value), `custom` (slot-based action)
- Customizable icon colors via `iconColor` and `iconBgColor` props
- Description text support for secondary information
- Clickable variants (auto-detects based on action type)
- Full Svelte 5 runes support with `$bindable()` for toggle state
- Uses existing Switch component for toggle mode

**Props:**
- `icon: Component<IconProps>` - Lucide icon component
- `iconColor?: string` - Icon text color (e.g., "text-blue-500", default: "text-muted-foreground")
- `iconBgColor?: string` - Icon background color (e.g., "bg-blue-500/10", default: "bg-muted")
- `label: string` - Primary label text
- `description?: string` - Secondary description
- `action?: "toggle" | "chevron" | "value" | "custom"` - Action type (default: "chevron")
- `checked?: boolean` - Toggle state (bindable with `bind:checked`)
- `value?: string` - Value text (for value action)
- `onclick?: () => void` - Click handler
- `actionSlot?: Snippet` - Custom action content
- `class?: string` - Additional CSS classes

**Styled via:** `.settings-item` (non-clickable toggle) and `.settings-item-button` (clickable actions) from `mobile.css`

### SettingsSection (39 lines)
Container component for grouping related settings items with title and card styling.

**Features:**
- Section title display
- Card container with rounded corners and shadow
- Snippet-based children pattern for flexible item composition
- Handles dividers between items (manual in child content)
- Uses Svelte 5 runes pattern

**Props:**
- `title: string` - Section title
- `children: Snippet` - Children content (typically SettingsItem components)
- `class?: string` - Additional CSS classes

**Styled via:** `.settings-section` from `mobile.css`

**Usage Pattern:**
```svelte
<SettingsSection title="Account">
  {#snippet children()}
    <SettingsItem icon={User} label="Profile" action="chevron" />
    <div class="border-t"></div>
    <SettingsItem icon={Lock} label="Password" action="chevron" />
  {/snippet}
</SettingsSection>
```

**Exported Types (16 total):**
- BreadcrumbItem, SidebarItem, SidebarSubmenu, SidebarGroup, SidebarSeparator, SidebarMenu
- AccordionType, ComboboxOption, ComboboxOptionGroup
- CommandItem, CommandGroup, CommandSeparator, CommandItems
- Column<T> (generic table column)
- SelectOption, SelectOptionGroup

**Component Categories:**
- Form Components: Input, InputGroup, Textarea, Checkbox, Radio, Select, Combobox
- Display Components: Button, Badge, Alert, Card, Spinner, Avatar, Empty
- Layout Components: Tabs, Accordion, Dialog, Sidebar, Table, Breadcrumb
- Navigation Components: Command Palette
- Utility Components: Tooltip, Toast (via rune)

## Charts & Insights System

### Overview
Unified insights system shared across chart components. Provides configurable threshold-based health evaluation with visual indicators.

**Insight-Capable Charts:**
- FunnelChart - Conversion analysis
- RetentionJourney - Customer lifecycle insights
- RetentionSankeyChart - Flow health metrics
- HistogramChart - Distribution statistics (mean, median, std dev, CV)
- GaugeChart - Threshold zone status

**Complete Chart Library (12 Components):**
- AreaChart, BarChart, CalendarChart, FunnelChart, GaugeChart, HistogramChart
- LineChart, PieChart, RadialProgressChart, RetentionJourney, RetentionSankeyChart, TreemapChart

### Architecture

**Components:**
- `InsightsBanner.svelte` - Health status header with icon/color/message
- `MetricsGrid.svelte` - 2-4 column metric grid with optional colors/trends

**Configuration System:**
- `insights-config.ts` - Config builders, rule evaluators, health states
- `FUNNEL_INSIGHTS_CONFIG` - Default thresholds for funnel metrics
- `RETENTION_INSIGHTS_CONFIG` - Default thresholds for retention metrics
- `DEFAULT_HISTOGRAM_THRESHOLDS` - Default thresholds for distribution analysis
- `createInsightsConfig()` - Custom config builder
- `createRule()` - Individual rule builder (metric, operator, threshold, status)
- `evaluateInsights()` - Core evaluation logic (rule matching, priority ordering)

**Health Status:**
Four standardized states with colors and icons:
- `critical` - Red (#ef4444), priority 0 (highest)
- `warning` - Amber (#f59e0b), priority 1
- `info` - Blue (#3b82f6), priority 2
- `healthy` - Green (#10b981), priority 3 (lowest)

### Usage Pattern

**FunnelChart Example:**
```svelte
<FunnelChart
  data={funnelData}
  showInsights={true}
  insightsConfig={customConfig}
/>
```

**Custom Config Example:**
```typescript
const config = createInsightsConfig([
  createRule("conversionRate", ">", 40, "healthy"),
  createRule("conversionRate", ">", 20, "warning"),
])
```

### Integration Details

Each chart component:
1. Computes relevant metrics (conversion rate, churn rate, etc.)
2. Evaluates health status via `evaluateInsights(metrics, config)`
3. Renders `InsightsBanner` with health status + action message
4. Renders `MetricsGrid` with formatted metric items
5. Accepts optional `insightsConfig` prop (defaults to chart-specific config)

**Props:**
- `showInsights?: boolean` - Toggle insights panel visibility
- `insightsConfig?: InsightsConfig` - Custom threshold configuration

### Testing
`insights-integration.spec.ts` covers:
- Component imports and exports
- InsightsBanner rendering (3 states, custom labels, styling)
- MetricsGrid rendering (metrics, secondary values, grid layout, colors)
- evaluateInsights function (rule evaluation, operator precedence)
- Custom config creation and evaluation
- Chart integration with insights (all 12 charts)

### Maintenance Checklist
- Monitor new component additions for code quality compliance
- Maintain Props interface documentation
- Keep @example blocks updated with usage patterns
- Verify type guard usage for new chart features
- Run `pnpm check` before committing chart changes

## Skills Activation & Workflows

Based on CLAUDE.md, developers should activate appropriate skills for task types (20 skills total):

### Backend (2 skills)
- `backend-development` - Rails controllers, API design, authentication
- `databases` - Schema, migrations, query optimization

### Frontend / Svelte 5 (5 skills)
- `ui-styling` - Svelte components, TailwindCSS, responsive design
- `ui-ux-pro-max` - Premium UI/UX design, design systems
- `frontend-design` - Distinctive interfaces, bold aesthetics
- `frontend-design-pro` - Production-grade UI with real photos/prompts
- `aesthetic` - Beautiful interfaces, design principles

### Quality & Process (5 skills)
- `planning` - Feature planning, architecture decisions
- `debugging` - Bug investigation, root cause analysis
- `code-review` - Code quality review, before merge
- `sequential-thinking` - Complex multi-step reasoning
- `problem-solving` - Problem decomposition, stuck resolution

### Media & Assets (3 skills)
- `ai-multimodal` - Image/video/audio analysis, generation
- `media-processing` - Image editing, format conversion, backgrounds
- `chrome-devtools` - Browser automation, screenshots, performance

### Research & Docs (3 skills)
- `docs-seeker` - Package/library documentation lookup
- `repomix` - Codebase packaging for AI analysis
- `research` - Technical research, solution exploration

### Infrastructure (2 skills)
- `devops` - Docker, deployment, cloud infrastructure
- `payment-integration` - Payment integrations (Stripe, Polar, SePay)

## Recommended Workflows

**Frontend UI Development:**
1. Design (aesthetic/frontend-design) → Extract design guidelines
2. Generate Assets (ai-multimodal) → Generate images
3. Edit Assets (media-processing) → Edit/format images
4. Implement (ui-styling/ui-ux-pro-max) → Build Svelte components
5. Verify (chrome-devtools) → Screenshot → ai-multimodal → Compare to design

**Feature Development:**
planning → backend-development + databases + ui-styling → code-review

**Bug Fix:**
debugging (root cause) → fix → code-review

### Architecture Overview
```
Browser Request
     ↓
Rails Router (config/routes.rb)
     ↓
Rails Controller (app/controllers/)
     ↓
Inertia Response (render inertia: {...})
     ↓
Inertia.js (app/frontend/entrypoints/inertia.ts)
     ↓
Svelte Page Component (app/frontend/pages/page_name.svelte)
     ↓
Rendered in Layout (app/frontend/layouts/persistent-layout.svelte)
```
