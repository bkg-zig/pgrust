-- bkg-supafleet: Create extensions and schemas for Supabase compatibility
-- Run as postgres superuser on cluster initialization

-- 1. Create extensions schema and install core extensions
CREATE SCHEMA IF NOT EXISTS extensions AUTHORIZATION postgres;

-- Core extensions available in postgres:18 base image
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA extensions;

-- Extensions from PGDG packages
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA extensions;     -- pgvector
CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA pg_catalog;   -- pg_cron (must be in pg_catalog)

-- pgjwt installed from source (no CREATE EXTENSION, it's a SQL file)
-- Load pgjwt functions into extensions schema
CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA extensions;

-- 2. Create Supabase service schemas
CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION supabase_auth_admin;
CREATE SCHEMA IF NOT EXISTS storage AUTHORIZATION supabase_storage_admin;
CREATE SCHEMA IF NOT EXISTS graphql_public AUTHORIZATION supabase_admin;
CREATE SCHEMA IF NOT EXISTS _realtime AUTHORIZATION supabase_admin;
CREATE SCHEMA IF NOT EXISTS supabase_functions AUTHORIZATION supabase_functions_admin;
CREATE SCHEMA IF NOT EXISTS pgbouncer AUTHORIZATION supabase_admin;

-- 3. Grant usage on extensions schema to service roles
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role,
  supabase_auth_admin, supabase_storage_admin, supabase_functions_admin, authenticator;

-- 4. Configure pg_cron
-- pg_cron runs in the postgres database by default
-- Tenant databases can enable it per-database if needed

-- 5. Set default search paths for service roles
ALTER ROLE supabase_auth_admin   SET search_path TO auth, public, extensions;
ALTER ROLE supabase_storage_admin SET search_path TO storage, public, extensions;
ALTER ROLE supabase_functions_admin SET search_path TO supabase_functions, public, extensions;
ALTER ROLE authenticator         SET search_path TO public, extensions;

-- 6. Pooler auth helper (for future pgbouncer/Supavisor integration)
CREATE OR REPLACE FUNCTION pgbouncer.get_auth(p_usename text)
RETURNS TABLE(username text, password text) AS
$$
  SELECT usename::text, passwd::text
  FROM pg_catalog.pg_shadow
  WHERE usename = p_usename;
$$ LANGUAGE sql SECURITY DEFINER;
ALTER FUNCTION pgbouncer.get_auth(text) OWNER TO supabase_admin;
GRANT EXECUTE ON FUNCTION pgbouncer.get_auth(text) TO supabase_admin;