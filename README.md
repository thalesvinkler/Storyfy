# Storyfy

O Storyfy transforma as melhores fotos de cada mês em uma história pronta para recordar e compartilhar.

Este repositório contém o MVP nativo para iPhone, reconstruído a partir da conversa original do produto. O app é local-first: lê o Apple Photos com autorização explícita, faz uma curadoria inicial no dispositivo e só compartilha algo após revisão do usuário.

## O que já está implementado

- onboarding e explicação de privacidade;
- autorização do Apple Photos via PhotoKit;
- busca das fotos do mês anterior;
- exclusão de screenshots e ordenação por uma heurística local;
- seleção de até 15 imagens;
- remoção e reordenação do carrossel;
- geração local de uma legenda editável;
- criação de álbum mensal no Apple Photos;
- compartilhamento pelo Share Sheet do iOS.

## Abrir no Xcode

Requisitos: macOS, Xcode 16+ e [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd ios
xcodegen generate
open Storyfy.xcodeproj
```

Escolha um iPhone físico para validar PhotoKit e o compartilhamento. O projeto usa iOS 17 como versão mínima.

## Estrutura

- `ios/Storyfy`: aplicação SwiftUI;
- `ios/StoryfyTests`: testes do domínio que não dependem do Photos;
- `docs/MVP.md`: decisões, escopo e critérios de aceite;
- `docs/ARCHITECTURE.md`: arquitetura e evolução prevista.

## Limite conhecido

O iOS não garante processamento pesado em uma data exata em segundo plano. Neste MVP, o app convida o usuário a iniciar a retrospectiva e processa a biblioteca após a abertura. Agendamento, Vision/Core ML e geração remota de legenda entram nas próximas etapas.
