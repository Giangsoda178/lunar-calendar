<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core"
  import { Form, page } from "@inertiajs/svelte"

  import Button from "@/components/ui/Button.svelte"
  import Card from "@/components/ui/Card.svelte"
  import Checkbox from "@/components/ui/Checkbox.svelte"
  import Field from "@/components/ui/Field.svelte"
  import Input from "@/components/ui/Input.svelte"
  import Label from "@/components/ui/Label.svelte"
  import { signInPath } from "@/routes"

  type FormData = {
    email: string | null
    password: string | null
    remember_me: boolean
  }

  type Props = {
    form: FormData
  }

  let { form }: Props = $props()

  let errors = $derived($page.props.errors || {})
  let flash = $derived($page.props.flash || {})
</script>

<main class="bg-muted/30 flex min-h-screen items-center px-4 py-12">
  <div class="mx-auto w-full max-w-sm">
    <div class="mb-8 text-center">
      <h1 class="text-3xl font-semibold tracking-tight">Welcome back</h1>
      <p class="text-muted-foreground mt-2 text-sm">
        Sign in to manage your calendar and reminders.
      </p>
    </div>

    <Form action={signInPath()} method="post">
      {#snippet children({ processing }: FormComponentSlotProps)}
        <Card title="Sign In" description="Enter your account details">
          <div class="grid gap-4">
            {#if flash.alert}
              <div class="bg-destructive/10 text-destructive rounded-md px-3 py-2 text-sm">
                {flash.alert}
              </div>
            {/if}

            <Field label="Email" name="email" error={errors.email} required>
              <Input
                id="field-email"
                name="email"
                type="email"
                placeholder="you@example.com"
                defaultValue={form.email ?? ""}
                invalid={!!errors.email}
                autocomplete="email"
              />
            </Field>

            <Field label="Password" name="password" error={errors.password} required>
              <Input
                id="field-password"
                name="password"
                type="password"
                placeholder="Your password"
                defaultValue={form.password ?? ""}
                invalid={!!errors.password}
                autocomplete="current-password"
              />
            </Field>

            <Label class="cursor-pointer items-center gap-2">
              <Checkbox
                name="remember_me"
                value="1"
                defaultChecked={form.remember_me}
              />
              Remember me
            </Label>
          </div>

          {#snippet footer()}
            <Button type="submit" class="w-full" disabled={processing}>
              {processing ? "Signing in..." : "Sign In"}
            </Button>
          {/snippet}
        </Card>
      {/snippet}
    </Form>
  </div>
</main>
