-- Criar tabela de escolas
CREATE TABLE public.escolas (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  codigo_acesso TEXT NOT NULL UNIQUE,
  email_admin TEXT NOT NULL,
  senha_admin TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Criar tabela de respostas do quiz
CREATE TABLE public.respostas_quiz (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_nome TEXT NOT NULL,
  escola_id UUID NOT NULL REFERENCES public.escolas(id) ON DELETE CASCADE,
  data_envio TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  respostas JSONB NOT NULL,
  resultado TEXT NOT NULL CHECK (resultado IN ('verde', 'amarelo', 'vermelho')),
  encaminhado BOOLEAN NOT NULL DEFAULT false,
  pontuacao INTEGER NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.escolas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.respostas_quiz ENABLE ROW LEVEL SECURITY;

-- Políticas para escolas (acesso público para validação de código)
CREATE POLICY "Escolas podem ser consultadas por código" 
ON public.escolas 
FOR SELECT 
USING (true);

-- Políticas para respostas_quiz
CREATE POLICY "Qualquer um pode inserir respostas de quiz" 
ON public.respostas_quiz 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Respostas podem ser visualizadas por todos" 
ON public.respostas_quiz 
FOR SELECT 
USING (true);

-- Inserir uma escola de exemplo para testes
INSERT INTO public.escolas (nome, codigo_acesso, email_admin, senha_admin) 
VALUES (
  'Escola Exemplo',
  'ESCOLA123',
  'admin@escolaexemplo.com',
  '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' -- password
);

-- Criar índices para melhor performance
CREATE INDEX idx_escolas_codigo_acesso ON public.escolas(codigo_acesso);
CREATE INDEX idx_respostas_quiz_escola_id ON public.respostas_quiz(escola_id);
CREATE INDEX idx_respostas_quiz_resultado ON public.respostas_quiz(resultado);
CREATE INDEX idx_respostas_quiz_data_envio ON public.respostas_quiz(data_envio);
