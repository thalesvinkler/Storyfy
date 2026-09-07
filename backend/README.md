# Storyfy Caption API

Backend mínimo para gerar legendas sem expor a chave da OpenAI no aplicativo.

## Executar

```bash
OPENAI_API_KEY=... npm start
```

Configure `StoryfyCaptionAPIURL` no build do app com a URL pública do backend, sem incluir `/caption`. Sem essa configuração, o Storyfy usa automaticamente as legendas locais.

Variáveis opcionais:

- `PORT`: porta HTTP, padrão `8787`.
- `OPENAI_MODEL`: modelo usado, padrão `gpt-5.4-mini`.

## Instagram

Configure no ambiente do servidor:

```bash
INSTAGRAM_APP_ID=1372485041694551
INSTAGRAM_APP_SECRET=...
PUBLIC_BASE_URL=https://api-storyfy.taurasystems.com.br
```

Cadastre na Meta exatamente esta URL de redirecionamento OAuth:

```text
https://api-storyfy.taurasystems.com.br/instagram/callback
```

Para produção, substitua os mapas em memória por armazenamento criptografado e persistente dos tokens.
