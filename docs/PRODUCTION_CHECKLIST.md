# Storyfy - Checklist de Producao

Este checklist acompanha a subida do MVP para uma primeira versao publica.

## 1. Escopo V1

- [x] Selecionar mes e ano da historia.
- [x] Curadoria inicial de fotos no iPhone.
- [x] Revisao e troca de fotos.
- [x] Geracao de legenda com fallback local.
- [x] Aviso quando a legenda usa fallback.
- [x] Conexao com Instagram para importar exemplos de legendas.
- [x] Uso opcional do calendario para contexto.
- [x] Notificacao mensal no dia 1.
- [ ] Revisao final de textos e microcopy.
- [ ] Teste com meses com poucas fotos.
- [ ] Teste com meses com muitas fotos.

## 2. iOS / App Store

- [x] Bundle ID definido: `br.com.thalesvinkler.storyfy`.
- [x] Team de desenvolvimento configurado.
- [x] Dark mode validado nas telas principais.
- [x] Permissoes de Fotos e Calendario declaradas.
- [x] URL scheme `storyfy://` configurado para retorno do Instagram.
- [x] App Privacy Manifest incluido com usuario do Instagram e legendas importadas.
- [ ] Remover projeto duplicado `ios/Storyfy 2.xcodeproj` antes de fechar release.
- [ ] Criar screenshots finais para App Store.
- [ ] Criar URL publica de politica de privacidade.
- [ ] Criar URL publica de suporte.
- [ ] Conferir App Privacy no App Store Connect.
- [ ] Gerar Archive em Release.
- [ ] Enviar build para TestFlight.

## 3. Backend / Supabase

- [x] Supabase project configurado.
- [x] Edge Function de legenda publicada.
- [x] Edge Function de OAuth Instagram publicada.
- [x] Secrets adicionadas no Supabase.
- [x] Limite mensal de geracao de legenda por usuario/plano configurado no backend.
- [x] Criar paywall e base StoreKit para planos Plus/Creator.
- [x] Sincronizar compra StoreKit com entitlement `free | plus | creator` no Supabase.
- [x] Registrar eventos de compra StoreKit em `billing_events`.
- [ ] Endurecer validacao server-side da transacao Apple antes da App Store publica.
- [ ] Criar produtos no App Store Connect: Plus mensal/anual e Creator mensal/anual.
- [ ] Conferir logs das Edge Functions apos testes reais.
- [ ] Validar limites de uso/custo da OpenAI.
- [x] Definir politica de retencao dos dados do Instagram.
- [x] Criar rotina/manual para desconectar usuario e apagar dados.
- [ ] Revisar seguranca das tabelas e policies.

## 4. Instagram / Meta

- [x] App `Storyfy-IG` criado.
- [x] Redirect URL configurada.
- [x] Login testado com conta administradora/testadora.
- [ ] Confirmar se o caso de uso esta pronto para usuarios fora dos testers.
- [ ] Preparar justificativa das permissoes para App Review da Meta, se necessario.
- [ ] Colocar app em modo Live somente depois do TestFlight validado.

## 5. Testes Antes Do TestFlight

- [ ] Primeira abertura limpa.
- [ ] Permissao de fotos negada.
- [ ] Permissao de fotos limitada.
- [ ] Permissao de calendario negada.
- [ ] Instagram conectado.
- [ ] Instagram desconectado.
- [ ] Sem internet durante legenda.
- [ ] Falha da API de legenda.
- [ ] Toque na notificacao mensal abre o app.
- [ ] Exportacao/salvamento do resultado.

## 6. Criterio De Go/No-Go

Publicar no TestFlight quando:

- [ ] Nenhum travamento conhecido no fluxo principal.
- [ ] Erros de API aparecem como mensagens compreensiveis.
- [ ] A historia pode ser criada sem Instagram e sem Calendario.
- [ ] Build Release compila sem warnings relevantes.
- [ ] Politica de privacidade esta publicada.
