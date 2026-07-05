# MVP do Storyfy

## Promessa

Em menos de cinco minutos de revisão, transformar as fotos do mês anterior em um carrossel de até 15 imagens, com uma legenda editável e pronto para compartilhar.

## Público e plataforma

O primeiro produto é exclusivo para iPhone. iPad, livro anual, Apple Health, Calendar e publicação automática não fazem parte deste ciclo.

## Jornada

1. O usuário entende que os originais permanecem no dispositivo.
2. Autoriza o acesso ao Apple Photos.
3. O app encontra imagens do mês anterior e descarta screenshots.
4. Uma heurística local prioriza favoritos, boa resolução e variedade temporal.
5. O usuário revisa, remove e reordena até 15 imagens.
6. O app cria uma legenda inicial, sempre editável.
7. Após aprovação, cria um álbum no Fotos e abre o Share Sheet.

## Telas

1. **Boas-vindas:** posicionamento e entrada.
2. **Privacidade:** explica o processamento local antes de solicitar acesso.
3. **Início:** mostra o mês alvo e inicia a criação.
4. **Processamento:** progresso e mensagens compreensíveis.
5. **Revisão:** grade, remoção, reordenação e contagem.
6. **Legenda:** texto editável e alternativa gerada localmente.
7. **Conclusão:** criação do álbum e compartilhamento.

## Regras da curadoria v1

- ignorar vídeos e screenshots;
- usar apenas o intervalo completo do mês anterior;
- favorecer favoritos e imagens com mais pixels;
- limitar o resultado a 15 imagens;
- distribuir escolhas ao longo do mês, evitando que só os últimos dias dominem;
- nunca apagar nem modificar os originais.

Essa heurística é intencionalmente simples e determinística. Vision, detecção de borrão, similaridade perceptual e agrupamento por evento são melhorias posteriores.

## Privacidade

- nenhuma foto é enviada a um servidor nesta versão;
- o usuário pode conceder acesso limitado;
- apenas identificadores locais do PhotoKit vivem no estado da sessão;
- o álbum só é criado por uma ação explícita;
- o compartilhamento só ocorre pelo painel nativo do iOS.

## Critérios de aceite

- o app lida com acesso completo, limitado, negado e biblioteca vazia;
- o mês alvo é calculado corretamente na virada de ano;
- a seleção nunca excede 15 imagens;
- o usuário consegue remover e mover fotos;
- a legenda continua editável após ser regenerada;
- falhas do Photos aparecem em linguagem clara;
- o projeto usa “Storyfy” de forma consistente em nomes, textos e identificadores.
