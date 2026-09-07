# Storyfy no Supabase

## Publicação

```bash
supabase login
supabase link --project-ref jxxzgnnpfoosvlgbucwx
supabase db push
supabase secrets set INSTAGRAM_APP_ID=1372485041694551
supabase secrets set INSTAGRAM_APP_SECRET=SUA_NOVA_CHAVE
supabase secrets set OPENAI_API_KEY=SUA_CHAVE
supabase secrets set OPENAI_MODEL=gpt-5.4-mini
supabase secrets set INSTAGRAM_PUBLIC_BASE_URL=https://jxxzgnnpfoosvlgbucwx.supabase.co/functions/v1/instagram-oauth
supabase secrets set STORYFY_KEEPALIVE_SECRET=SUA_SECRET_LONGA
supabase functions deploy instagram-oauth --no-verify-jwt
supabase functions deploy storyfy-caption
supabase functions deploy billing-entitlement
supabase functions deploy storyfy-keepalive --no-verify-jwt
```

Cadastre na Meta:

```text
https://jxxzgnnpfoosvlgbucwx.supabase.co/functions/v1/instagram-oauth/callback
```

O app deve usar como `StoryfyCaptionAPIURL`:

```text
https://jxxzgnnpfoosvlgbucwx.supabase.co/functions/v1/storyfy-caption
```

O token do Instagram fica inacessível para clientes por RLS. Antes de produção pública, adicione criptografia de aplicação ao campo `access_token`.

## Limite de custo e planos

A função `storyfy-caption` limita gerações por usuário anônimo autenticado, por mês em UTC:

- `free`: 2 legendas/mês.
- `plus`: 20 legendas/mês.
- `creator`: 150 legendas/mês.

Quando o limite é atingido, a Edge Function retorna `429` com `monthly_limit_reached`. O app usa a legenda local de fallback nesse caso.

Para liberar manualmente um usuário enquanto o StoreKit não está integrado, insira/atualize `public.user_entitlements` com `plan = 'plus'` ou `plan = 'creator'`.

## Planos no App Store Connect

Crie estes produtos de assinatura no App Store Connect:

```text
storyfy_plus_monthly
storyfy_plus_yearly
storyfy_creator_monthly
storyfy_creator_yearly
```

A funcao `billing-entitlement` recebe `product_id`, `transaction_id`, `original_transaction_id`, datas de compra/expiracao de uma transacao verificada localmente pelo StoreKit, grava `public.billing_events` e atualiza `public.user_entitlements`.
Antes de producao publica em escala, adicione validacao server-side da transacao Apple.

## Keep-alive do plano Free

Projetos Free do Supabase podem ser pausados depois de 1 semana com pouca atividade de banco. Para reduzir esse risco sem upgrade, publique `storyfy-keepalive`, configure `STORYFY_KEEPALIVE_SECRET` e chame a função diariamente por um cron externo.

Exemplo de chamada:

```bash
curl -H "x-storyfy-keepalive-secret: SUA_SECRET_LONGA" \
  https://jxxzgnnpfoosvlgbucwx.supabase.co/functions/v1/storyfy-keepalive
```

O endpoint faz uma consulta real em `caption_usage_events`, porque chamadas que não encostam no Postgres podem não contar como atividade suficiente.
