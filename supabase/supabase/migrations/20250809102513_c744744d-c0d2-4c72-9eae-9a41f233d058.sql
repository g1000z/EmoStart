-- Fix linter warnings: set search_path on existing functions
ALTER FUNCTION public.hash_sensitive_data(data text) SET search_path = public;
ALTER FUNCTION public.log_action(p_user_id uuid, p_escola_id uuid, p_acao text, p_detalhes jsonb, p_ip_address text, p_user_agent text) SET search_path = public;

-- Seed Colégio Ensino (plaintext password for now)
INSERT INTO public.escolas (codigo_acesso, nome, senha_admin, email_admin)
VALUES (
  'ENSINO-' || substring(replace(gen_random_uuid()::text,'-',''),1,8),
  'Colégio Ensino',
  'S3cUr0!A9zTX#1',
  'contato@colegioensino.com.br'
);
