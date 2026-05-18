<script lang="ts">
  import type { Snippet } from "svelte"

  import Toaster from "@/components/ui/Toaster.svelte"
  import { useFlashSvelte } from "@/runes/use-flash.svelte"
  import { useNotifications } from "@/runes/use-notifications.svelte"

  interface Props {
    children: Snippet
  }

  let { children }: Props = $props()

  useFlashSvelte()
  const notifications = useNotifications()

  $effect(() => {
    notifications.subscribe()
    return () => notifications.unsubscribe()
  })
</script>

{@render children()}
<Toaster />
