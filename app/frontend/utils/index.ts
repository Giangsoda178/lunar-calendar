/**
 * Utility barrel export.
 * Re-exports all utilities from modular files for convenient imports.
 *
 * @example Import from barrel
 * import { cn, analyzeLink, sanitizeHref } from "@/utils"
 *
 * @example Import from specific module (for tree-shaking)
 * import { cn } from "@/utils/classname-utils"
 * import { analyzeLink } from "@/utils/link-utils"
 */

// Class name utilities
export { cn } from "./classname-utils"

// Link validation and analysis
export {
  type LinkAnalysis,
  type LinkAnalysisOptions,
  analyzeLink,
  isAnchorUrl,
  isExternalUrl,
  sanitizeHref,
} from "./link-utils"

// Inertia.js integration (safe to import even without Inertia)
export {
  inertiaAction,
  page as inertiaPage,
  router as inertiaRouter,
} from "./inertia"

// Lunar calendar utilities
export {
  type CalendarCell,
  MONTH_NAMES,
  WEEKDAY_NAMES,
  buildCalendarGrid,
  dateToISO,
  daysInMonth,
  formatShortDate,
  getLunarDayMonth,
  isoToDate,
} from "./lunar-calendar"
