-- Tabela para profissionais (psicólogos/terapeutas)
CREATE TABLE public.profissionais (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  senha TEXT NOT NULL,
  nome TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('psicologo', 'terapeuta')),
  ativo BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profissionais ENABLE ROW LEVEL SECURITY;

-- Policy para permitir login
CREATE POLICY "Profissionais podem fazer login" 
ON public.profissionais 
FOR SELECT 
USING (ativo = true);

-- Inserir dados de exemplo para profissionais
INSERT INTO public.profissionais (email, senha, nome, tipo) VALUES
('psicologo@emoteen.com', '123456', 'Dr. João Psicólogo', 'psicologo'),
('terapeuta@emoteen.com', '123456', 'Dra. Ana Psicóloga', 'psicologo');
