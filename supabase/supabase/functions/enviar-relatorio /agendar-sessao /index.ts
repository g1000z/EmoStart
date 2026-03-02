import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { Resend } from "npm:resend@2.0.0";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface AgendarSessaoRequest {
  alunoNome: string;
  escolaNome: string;
  resultado: string;
  pontuacao: number;
  dataEnvio: string;
}

const handler = async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { alunoNome, escolaNome, resultado, pontuacao, dataEnvio }: AgendarSessaoRequest = await req.json();

    console.log("Agendando sessão para:", { alunoNome, escolaNome, resultado });

    const emailResponse = await resend.emails.send({
      from: "EmoTeen <onboarding@resend.dev>",
      to: ["emoteen-contato@outlook.com.br"],
      subject: `Solicitação de Sessão - ${alunoNome} (${escolaNome})`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #8B5CF6; text-align: center;">EmoTeen - Solicitação de Sessão</h1>
          
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h2 style="color: #333; margin-top: 0;">Informações do Aluno</h2>
            <p><strong>Nome:</strong> ${alunoNome}</p>
            <p><strong>Escola:</strong> ${escolaNome}</p>
            <p><strong>Data da Avaliação:</strong> ${new Date(dataEnvio).toLocaleDateString('pt-BR')}</p>
          </div>

          <div style="background-color: ${resultado === 'vermelho' ? '#fee2e2' : resultado === 'amarelo' ? '#fef3c7' : '#d1fae5'}; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h2 style="color: #333; margin-top: 0;">Resultado da Avaliação</h2>
            <p><strong>Classificação:</strong> <span style="color: ${resultado === 'vermelho' ? '#dc2626' : resultado === 'amarelo' ? '#d97706' : '#059669'}; text-transform: uppercase; font-weight: bold;">${resultado}</span></p>
            <p><strong>Pontuação:</strong> ${pontuacao} pontos</p>
          </div>

          <div style="background-color: #e0e7ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #333; margin-top: 0;">Próximos Passos</h3>
            <p>A escola solicitou o agendamento de uma sessão para este aluno. Por favor, entre em contato com a escola para coordenar o atendimento.</p>
          </div>

          <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb;">
            <p style="color: #6b7280; font-size: 14px;">Este e-mail foi enviado automaticamente pelo sistema EmoTeen</p>
          </div>
        </div>
      `,
    });

    console.log("Email enviado com sucesso:", emailResponse);

    return new Response(JSON.stringify({ success: true, data: emailResponse }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    });
  } catch (error: any) {
    console.error("Erro ao enviar e-mail:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
};

serve(handler);
