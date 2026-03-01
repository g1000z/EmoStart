-- Tabela para sessões agendadas/encaminhadas pela escola
CREATE TABLE public.sessoes_agendadas (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  escola_id UUID NOT NULL,
  aluno_nome TEXT NOT NULL,
  escola_nome TEXT NOT NULL,
  data_encaminhamento TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  resultado TEXT NOT NULL CHECK (resultado IN ('verde', 'amarelo', 'vermelho')),
  pontuacao INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'agendada', 'realizada')),
  link_sessao TEXT,
  observacoes TEXT,
  data_agendada TIMESTAMP WITH TIME ZONE,
  data_realizacao TIMESTAMP WITH TIME ZONE,
  terapeuta_nome TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabela para relatórios das sessões
CREATE TABLE public.relatorios_sessao (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sessao_id UUID NOT NULL REFERENCES public.sessoes_agendadas(id) ON DELETE CASCADE,
  diagnostico TEXT NOT NULL,
  recomendacoes TEXT NOT NULL,
  proximos_passos TEXT,
  observacoes TEXT,
  status TEXT NOT NULL DEFAULT 'enviado' CHECK (status IN ('rascunho', 'enviado')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabela para avaliações pós-sessão dos alunos
CREATE TABLE public.avaliacoes_pos_sessao (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  sessao_id UUID NOT NULL REFERENCES public.sessoes_agendadas(id) ON DELETE CASCADE,
  aluno_nome TEXT NOT NULL,
  escola_nome TEXT NOT NULL,
  avaliacao TEXT NOT NULL CHECK (avaliacao IN ('bem', 'melhor', 'nada_bem')),
  comentarios TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.sessoes_agendadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relatorios_sessao ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes_pos_sessao ENABLE ROW LEVEL SECURITY;

-- Policies para sessoes_agendadas
CREATE POLICY "Escolas podem inserir sessões" 
ON public.sessoes_agendadas 
FOR INSERT 
WITH CHECK (EXISTS (
  SELECT 1 FROM public.escolas 
  WHERE escolas.id = sessoes_agendadas.escola_id
));

CREATE POLICY "Psicólogos podem ver todas as sessões" 
ON public.sessoes_agendadas 
FOR SELECT 
USING (true);

CREATE POLICY "Psicólogos podem atualizar sessões" 
ON public.sessoes_agendadas 
FOR UPDATE 
USING (true);

-- Policies para relatorios_sessao
CREATE POLICY "Psicólogos podem gerenciar relatórios" 
ON public.relatorios_sessao 
FOR ALL 
USING (true);

CREATE POLICY "Escolas podem ver relatórios de suas sessões" 
ON public.relatorios_sessao 
FOR SELECT 
USING (EXISTS (
  SELECT 1 FROM public.sessoes_agendadas sa
  JOIN public.escolas e ON e.id = sa.escola_id
  WHERE sa.id = relatorios_sessao.sessao_id
));

-- Policies para avaliacoes_pos_sessao
CREATE POLICY "Qualquer um pode inserir avaliações" 
ON public.avaliacoes_pos_sessao 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Psicólogos podem ver todas as avaliações" 
ON public.avaliacoes_pos_sessao 
FOR SELECT 
USING (true);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Triggers para atualizar updated_at
CREATE TRIGGER update_sessoes_agendadas_updated_at
  BEFORE UPDATE ON public.sessoes_agendadas
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_relatorios_sessao_updated_at
  BEFORE UPDATE ON public.relatorios_sessao
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
