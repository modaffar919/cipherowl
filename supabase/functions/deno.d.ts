/**
 * Minimal Deno type declarations for Supabase Edge Functions.
 * Allows VS Code's TypeScript compiler to understand Deno APIs
 * without requiring the Deno extension.
 */

declare namespace Deno {
  interface Env {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    delete(key: string): void;
    has(key: string): boolean;
    toObject(): Record<string, string>;
  }

  const env: Env;

  function serve(
    handler: (request: Request) => Response | Promise<Response>,
  ): void;
}

// ESM URL module declarations for Supabase client
declare module 'https://esm.sh/@supabase/supabase-js@2' {
  export * from '@supabase/supabase-js';
  export { createClient } from '@supabase/supabase-js';
}
