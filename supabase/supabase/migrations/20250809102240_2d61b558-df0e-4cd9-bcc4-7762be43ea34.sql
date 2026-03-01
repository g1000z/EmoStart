-- Fix linter warnings: set search_path on existing functions
ALTER FUNCTION public.hash_sensitive_data(data text) SET search_path = public;
ALTER FUNCTION public.log_action(p_user_id uuid, p_escola_id uuid, p_acao text, p_detalhes jsonb, p_ip_address text, p_user_agent text) SET search_path = public;

-- Secure login helper: validates escola credentials server-side
CREATE OR REPLACE FUNCTION public.validate_escola_login(p_email text, p_senha text)
RETURNS public.escolas
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  select e.*
  from public.escolas e
  where e.email_admin = p_email
    and (
      e.senha_admin = public.hash_sensitive_data(p_senha)
      OR e.senha_admin = p_senha
    )
  limit 1;
$$;

-- Seed: add Colégio Ensino (password is hashed via sha256)
INSERT INTO public.escolas (codigo_acesso, nome, senha_admin, email_admin)
VALUES (
  'ENSINO-' || substring(replace(gen_random_uuid()::text,'-',''),1,8),
  'Colégio Ensino',
  public.hash_sensitive_data('S3cUr0!A9zTX#1'),
  'contato@colegioensino.com.br'
);
