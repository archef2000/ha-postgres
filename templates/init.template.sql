select * from pg_shadow;

CREATE USER ${PGBOUNCER_AUTH_USER} with password '${PGBOUNCER_AUTH_PASS}';

select * from pg_shadow;

CREATE FUNCTION public.lookup (
	INOUT p_user     name,
	OUT   p_password text
) RETURNS record
LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog AS
$$${d}SELECT usename, passwd FROM pg_shadow WHERE usename = p_user$$;
