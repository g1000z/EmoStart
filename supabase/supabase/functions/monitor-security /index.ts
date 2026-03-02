import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { Resend } from "npm:resend@2.0.0";

const resend = new Resend(Deno.env.get("RESEND_API_KEY"));

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface SecurityAlert {
  tipo: 'login_suspeito' | 'multiplas_tentativas' | 'acesso_negado';
  detalhes: any;
  escola_id?: string;
  ip_address: string;
}

const handler = async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Check for suspicious login attempts
    const { data: recentAttempts, error } = await supabase
      .from('sessoes_monitoramento')
      .select('*')
      .gte('timestamp', new Date(Date.now() - 15 * 60 * 1000).toISOString()) // Last 15 minutes
      .order('timestamp', { ascending: false });

    if (error) {
      throw error;
    }

    // Group by IP address
    const ipGroups: { [key: string]: any[] } = {};
    recentAttempts?.forEach(attempt => {
      if (!ipGroups[attempt.ip_address]) {
        ipGroups[attempt.ip_address] = [];
      }
      ipGroups[attempt.ip_address].push(attempt);
    });

    // Check for suspicious activity
    for (const [ip, attempts] of Object.entries(ipGroups)) {
      const failedAttempts = attempts.filter(a => !a.tentativa_sucesso);
      
      // Alert if more than 5 failed attempts from same IP
      if (failedAttempts.length >= 5) {
        await sendSecurityAlert({
          tipo: 'multiplas_tentativas',
          detalhes: {
            ip_address: ip,
            tentativas_falharam: failedAttempts.length,
            periodo: '15 minutos'
          },
          ip_address: ip
        });
      }

      // Alert if successful login after multiple failures
      const hasSuccessAfterFailures = attempts.some(a => a.tentativa_sucesso) && failedAttempts.length >= 3;
      if (hasSuccessAfterFailures) {
        await sendSecurityAlert({
          tipo: 'login_suspeito',
          detalhes: {
            ip_address: ip,
            tentativas_anteriores: failedAttempts.length,
            login_bem_sucedido: true
          },
          ip_address: ip
        });
      }
    }

    return new Response(
      JSON.stringify({ 
        message: "Security monitoring completed",
        alerts_checked: Object.keys(ipGroups).length 
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );

  } catch (error: any) {
    console.error("Error in security monitoring:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
};

async function sendSecurityAlert(alert: SecurityAlert) {
  try {
    const emailContent = generateAlertEmail(alert);
    
    const { error } = await resend.emails.send({
      from: "EmoTeen Security <security@emoteen.com.br>",
      to: ["admin@emoteen.com.br"], // Replace with actual admin emails
      subject: `🚨 Alerta de Segurança - ${alert.tipo}`,
      html: emailContent,
    });

    if (error) {
      console.error("Error sending security alert:", error);
    }
  } catch (error) {
    console.error("Error in sendSecurityAlert:", error);
  }
}

function generateAlertEmail(alert: SecurityAlert): string {
  const timestamp = new Date().toLocaleString('pt-BR');
  
  let content = `
    <h2>🚨 Alerta de Segurança EmoTeen</h2>
    <p><strong>Timestamp:</strong> ${timestamp}</p>
    <p><strong>Tipo:</strong> ${alert.tipo}</p>
    <p><strong>IP Address:</strong> ${alert.ip_address}</p>
    <h3>Detalhes:</h3>
    <pre>${JSON.stringify(alert.detalhes, null, 2)}</pre>
  `;

  switch (alert.tipo) {
    case 'multiplas_tentativas':
      content += `
        <h3>Ação Recomendada:</h3>
        <ul>
          <li>Considere bloquear temporariamente o IP ${alert.ip_address}</li>
          <li>Monitore tentativas futuras deste IP</li>
          <li>Verifique se há padrões de ataque</li>
        </ul>
      `;
      break;
    case 'login_suspeito':
      content += `
        <h3>Ação Recomendada:</h3>
        <ul>
          <li>Investigue a conta que fez login com sucesso</li>
          <li>Considere solicitar reautenticação</li>
          <li>Monitore atividades da sessão</li>
        </ul>
      `;
      break;
  }

  content += `
    <hr>
    <p><small>Este é um alerta automático do sistema de segurança EmoTeen.</small></p>
  `;

  return content;
}

serve(handler);
