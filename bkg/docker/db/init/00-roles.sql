-- bkg-supafleet: Create Supabase-compatible roles
-- Run as postgres superuser on cluster initialization

-- Supabase service roles
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOINHERIT NOLOGIN NOREPLICATION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOINHERIT NOLOGIN NOREPLICATION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    -- BYPASSRLS: the service role is the admin role of the API layer. Without
    -- it the Storage API cannot write rows in its own RLS-protected tables
    -- (e.g. storage.buckets).
    CREATE ROLE service_role NOINHERIT NOLOGIN NOREPLICATION BYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator NOINHERIT LOGIN NOREPLICATION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
    CREATE ROLE supabase_storage_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_functions_admin') THEN
    CREATE ROLE supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION SUPERUSER;
  END IF;
END
$$;

-- Grant service roles to authenticator for JWT token switching
GRANT anon, authenticated, service_role TO authenticator;

-- Storage and Auth switch to the caller's role (SET ROLE service_role /
-- authenticated) while serving a request. Without this membership they fail
-- with "permission denied to set role".
GRANT anon, authenticated, service_role TO supabase_storage_admin;
GRANT anon, authenticated, service_role TO supabase_auth_admin;

-- Grant supabase_admin to postgres for admin operations
GRANT supabase_admin TO postgres;

-- Set passwords from environment (will be set by docker-entrypoint via POSTGRES_PASSWORD)
-- These are overridden by the entrypoint script using ALTER ROLE