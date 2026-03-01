-- Criar tabela de séries
CREATE TABLE public.series (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  escola_id UUID NOT NULL REFERENCES public.escolas(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  ativa BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Adicionar série na tabela de respostas_quiz
ALTER TABLE public.respostas_quiz 
ADD COLUMN serie_id UUID REFERENCES public.series(id);

-- Habilitar RLS na tabela séries
ALTER TABLE public.series ENABLE ROW LEVEL SECURITY;

-- Policy para séries - qualquer um pode visualizar séries ativas
CREATE POLICY "Séries ativas podem ser visualizadas por todos" 
ON public.series 
FOR SELECT 
USING (ativa = true);

-- Policy para inserir/atualizar séries (apenas para demo, em produção seria mais restritiva)
CREATE POLICY "Administradores podem gerenciar séries" 
ON public.series 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- Inserir séries exemplo para a escola de demonstração
INSERT INTO public.series (escola_id, nome, ativa) 
SELECT id, '1º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '2º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '3º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '4º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '5º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '6º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '7º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '8º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '9º Ano', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '1º Médio', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '2º Médio', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123'
UNION ALL
SELECT id, '3º Médio', true FROM public.escolas WHERE codigo_acesso = 'ESCOLA123';

-- Criar índices para performance
CREATE INDEX idx_series_escola_id ON public.series(escola_id);
CREATE INDEX idx_respostas_quiz_serie_id ON public.respostas_quiz(serie_id);
