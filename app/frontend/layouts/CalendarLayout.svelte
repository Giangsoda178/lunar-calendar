<script lang="ts">
  import { CalendarDays, UserCog } from "@lucide/svelte"
  import MoonLogo from "@/assets/images/moon-logo.png"
  import type { Snippet } from "svelte"
  import SidebarLayout from "@/layouts/SidebarLayout.svelte"
  import { rootPath, calendarIndexPath } from "@/routes"

  type Props = {
    /** Page title (shown as header) */
    title?: string
    /** Page description */
    description?: string
    /** CSS class for content area */
    contentClass?: string
    /** Main content */
    children: Snippet
  }

  let {
    title,
    description,
    contentClass = "p-4 md:p-6",
    children,
  }: Props = $props()

  const sidebarMenu = [
    {
      type: "group",
      label: "Navigation",
      items: [
        {
          label: "Calendar",
          icon: CalendarDays,
          url: calendarIndexPath(),
        },
        {
          label: "Profile",
          icon: UserCog,
          url: "/calendar/settings",
        },
      ],
    },
  ]
</script>

<SidebarLayout
  sideBarId="calendar-sidebar"
  {sidebarMenu}
  sidebarClass="border-r"
  showThemeVariants
  showDarkModeToggle
  {contentClass}
>
  {#snippet sidebarHeader()}
    <a
      href={rootPath()}
      class="btn-ghost flex h-12 w-full items-center justify-start gap-2 p-2"
    >
      <div
        class="logo-container bg-sidebar-primary text-sidebar-primary-foreground flex size-10 items-center justify-center rounded-lg p-1"
      >
        <img src={MoonLogo} alt="Moon Logo" />
      </div>
      <div class="p-2 text-lg font-bold">Lunar Calendar</div>
    </a>
  {/snippet}

  <div class="space-y-6">
    {#if title}
      <header>
        <h1 class="text-3xl font-bold">{title}</h1>
        {#if description}
          <p class="text-muted-foreground mt-1">{description}</p>
        {/if}
      </header>
    {/if}

    {@render children()}
  </div>
</SidebarLayout>
