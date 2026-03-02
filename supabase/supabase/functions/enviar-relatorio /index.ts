import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { Resend } from "npm:resend@2.0.0";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface EnviarRelatorioRequest {
  alunoNome: string;
  escolaNome: string;
  progressoAluno: string;
  dataRealizacao: string;
}

const handler = async (req: Request): Promise<Response> => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { alunoNome, escolaNome, progressoAluno, dataRealizacao }: EnviarRelatorioRequest = await req.json();

    console.log("Enviando relatório para:", { alunoNome, escolaNome });

    const emailResponse = await resend.emails.send({
      from: "EmoTeen <onboarding@resend.dev>",
      to: ["emoteen-contato@outlook.com.br"],
      subject: `Relatório de Sessão - ${alunoNome} (${escolaNome})`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #8B5CF6; text-align: center;">EmoTeen - Relatório de Sessão</h1>
          
          <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h2 style="color: #333; margin-top: 0;">Informações da Sessão</h2>
            <p><strong>Aluno:</strong> ${alunoNome}</p>
            <p><strong>Escola:</strong> ${escolaNome}</p>
            <p><strong>Psicólogo:</strong> Psicólogo EmoTeen</p>
            <p><strong>Data da Sessão:</strong> ${new Date(dataRealizacao).toLocaleDateString('pt-BR')}</p>
          </div>

          <div style="background-color: #e0e7ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h2 style="color: #333; margin-top: 0;">Progresso do Aluno na Avaliação</h2>
            <div style="background-color: white; padding: 15px; border-radius: 6px; margin-top: 10px;">
              <p style="white-space: pre-line; line-height: 1.5;">${progressoAluno}</p>
            </div>
          </div>

          <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #e5e7eb;">
            <p style="color: #6b7280; font-size: 14px;">Este relatório foi enviado automaticamente pelo sistema EmoTeen</p>
          </div>
        </div>
      `,
    });

    console.log("Relatório enviado com sucesso:", emailResponse);

    // Enviar também para Web3Forms
    try {
      const web3FormsResponse = await fetch("https://api.web3forms.com/submit", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          access_key: "7d88b37b-4884-4665-92dc-5c113e5a54bb",
          subject: `Relatório de Sessão - ${alunoNome} (${escolaNome})`,
          from_name: "EmoTeen - Sistema de Relatórios",
          message: `Relatório de sessão realizada em ${new Date(dataRealizacao).toLocaleDateString('pt-BR')}:\n\nAluno: ${alunoNome}\nEscola: ${escolaNome}\n\nProgresso do Aluno na Avaliação:\n${progressoAluno}`,
        }),
      });

      const web3FormsResult = await web3FormsResponse.json();
      console.log("Relatório enviado para Web3Forms:", web3FormsResult);
    } catch (web3Error) {
      console.error("Erro ao enviar para Web3Forms (não crítico):", web3Error);
      // Não falha a operação se Web3Forms der erro
    }

    return new Response(JSON.stringify({ success: true, data: emailResponse }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    });
  } catch (error: any) {
    console.error("Erro ao enviar relatório:", error);
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
