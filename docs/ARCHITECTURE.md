# Arquitetura

## Princípios

- **Local-first:** PhotoKit é a fonte; originais não saem do aparelho.
- **Humano no controle:** seleção, legenda e compartilhamento exigem revisão.
- **Progressivo:** o MVP funciona sem conta, backend ou chave de API.
- **Substituível:** serviços são protocolos para permitir Vision e IA no futuro.

## Camadas

- `App`: ciclo de vida e composição de dependências.
- `Models`: estado e tipos do domínio.
- `Services`: fronteiras para Photos, curadoria e legenda.
- `Views`: fluxo SwiftUI orientado pelo `AppModel`.

## Evolução planejada

1. Adicionar Vision para nitidez, rostos e feature prints.
2. Agrupar fotos por proximidade de data, localização e similaridade.
3. Enviar somente thumbnails das finalistas para análise semântica opcional.
4. Registrar aceitar, rejeitar, trocar capa e reordenar para personalização.
5. Introduzir tarefas de background como otimização, nunca como requisito.
6. Adaptar a mesma base SwiftUI ao iPad.

Publicação automática via API do Instagram fica fora do núcleo: o Share Sheet é o caminho confiável para contas pessoais.
