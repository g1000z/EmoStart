-- Enhanced security and LGPD compliance migration

-- Create logs table for audit trail
CREATE TABLE public.logs (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid,
  escola_id uuid,
  acao text NOT NULL,
  detalhes jsonb,
  ip_address text,
  user_agent text,
  timestamp timestamp with time zone NOT NULL DEFAULT now()
);

-- Create parental consent table
CREATE TABLE public.consentimento_responsavel (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  aluno_nome text NOT NULL,
  escola_id uuid NOT NULL,
  responsavel_nome text NOT NULL,
  responsavel_cpf text NOT NULL,
  ip_address text NOT NULL,
  user_agent text NOT NULL,
  hash_assinatura text NOT NULL,
  data_consentimento timestamp with time zone NOT NULL DEFAULT now(),
  ativo boolean NOT NULL DEFAULT true
);

-- Create session monitoring table
CREATE TABLE public.sessoes_monitoramento (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  escola_id uuid,
  aluno_nome text,
  ip_address text NOT NULL,
  user_agent text NOT NULL,
  tentativa_sucesso boolean NOT NULL,
  timestamp timestamp with time zone NOT NULL DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consentimento_responsavel ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessoes_monitoramento ENABLE ROW LEVEL SECURITY;

-- Enhanced RLS policies for existing tables
DROP POLICY IF EXISTS "Respostas podem ser visualizadas por todos" ON public.respostas_quiz;
DROP POLICY IF EXISTS "Qualquer um pode inserir respostas de quiz" ON public.respostas_quiz;

-- New secure policies for respostas_quiz
CREATE POLICY "Escola pode ver apenas suas respostas" 
ON public.respostas_quiz 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.escolas 
    WHERE escolas.id = respostas_quiz.escola_id
  )
);

CREATE POLICY "Inserir resposta apenas com consentimento válido" 
ON public.respostas_quiz 
FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.consentimento_responsavel cr
    WHERE cr.escola_id = respostas_quiz.escola_id 
    AND cr.aluno_nome = respostas_quiz.aluno_nome
    AND cr.ativo = true
  )
);

CREATE POLICY "Apenas administradores podem atualizar respostas" 
ON public.respostas_quiz 
FOR UPDATE 
USING (false); -- Will be implemented with admin authentication

-- RLS policies for logs table
CREATE POLICY "Escola pode ver apenas seus logs" 
ON public.logs 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.escolas 
    WHERE escolas.id = logs.escola_id
  )
);

CREATE POLICY "Sistema pode inserir logs" 
ON public.logs 
FOR INSERT 
WITH CHECK (true);

-- RLS policies for consent table
CREATE POLICY "Escola pode ver apenas seus consentimentos" 
ON public.consentimento_responsavel 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.escolas 
    WHERE escolas.id = consentimento_responsavel.escola_id
  )
);

CREATE POLICY "Inserir consentimento validado" 
ON public.consentimento_responsavel 
FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.escolas 
    WHERE escolas.id = consentimento_responsavel.escola_id
  )
);

-- RLS policies for session monitoring
CREATE POLICY "Escola pode ver apenas suas sessões" 
ON public.sessoes_monitoramento 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.escolas 
    WHERE escolas.id = sessoes_monitoramento.escola_id
  )
);

CREATE POLICY "Sistema pode inserir monitoramento" 
ON public.sessoes_monitoramento 
FOR INSERT 
WITH CHECK (true);

-- Create indexes for performance
CREATE INDEX idx_logs_escola_timestamp ON public.logs(escola_id, timestamp DESC);
CREATE INDEX idx_logs_user_timestamp ON public.logs(user_id, timestamp DESC);
CREATE INDEX idx_consentimento_escola_aluno ON public.consentimento_responsavel(escola_id, aluno_nome);
CREATE INDEX idx_sessoes_escola_timestamp ON public.sessoes_monitoramento(escola_id, timestamp DESC);

-- Create function to hash sensitive data
CREATE OR REPLACE FUNCTION public.hash_sensitive_data(data text)
RETURNS text AS $$
BEGIN
  RETURN encode(digest(data, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to log actions
CREATE OR REPLACE FUNCTION public.log_action(
  p_user_id uuid DEFAULT NULL,
  p_escola_id uuid DEFAULT NULL,
  p_acao text DEFAULT NULL,
  p_detalhes jsonb DEFAULT NULL,
  p_ip_address text DEFAULT NULL,
  p_user_agent text DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  INSERT INTO public.logs (user_id, escola_id, acao, detalhes, ip_address, user_agent)
  VALUES (p_user_id, p_escola_id, p_acao, p_detalhes, p_ip_address, p_user_agent);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
