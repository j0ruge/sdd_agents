---
campaign: 20261117-zerar-as-issues
level: pr
lots: L1
expires: 2026-11-26 18:00
budget_mission_usd: 60
budget_campaign_usd: 100
signed: 2026-11-19 15:15 1eba9b42efa5
---

# Delegação — Zerar as issues do kit

> **Só o frontmatter acima é lido.** Esta prosa é para o dono, e nenhum verbo a lê. O
> `bin/sdd-worker` relê este arquivo a cada passo, e é ele, não uma palavra dita numa sessão, que
> decide o que o worker faz sozinho.
>
> O valor de uma chave é o texto depois do primeiro `: `, sem os espaços do fim e sem aspas.
> Enquanto um valor for um placeholder `<…>`, a delegação é **ilegível** e vale `assisted`.
> Ilegível também: um `campaign:` (o daqui ou o do `campaign.md` ao lado) que não é o nome do
> diretório, um `lots:` que não é `all` nem uma lista de lotes da tabela do `campaign.md` (o
> placeholder acima incluso: `<all,` não é lote), e um `expires:` que o relógio não tem
> (`2026-11-31 10:00`, `2026-11-18 99:99`).

## O estado em que ela nasce

Escrita pela missão `20261117-o-worker-orquestrador` (I11) **sem assinatura**, e de propósito
ilegível: o prazo e os dois tetos são do dono, e nenhuma sessão os inventa. Hoje
`bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues` responde
`level assisted — illegible`. O `level: assisted` é só o ponto de partida: o dono escolhe o nível
ao preencher.

Para o worker agir sozinho, depois do merge da missão que o construiu:

1. configurar o `ON_ESCALATION_CMD` no checkout da campanha e em cada worktree que guarda uma missão
   dela: o `level` lê o `.sdd/config.sh` desses checkouts, e de nenhum outro (o conjunto estreito,
   escolha do dono na r5 da missão `20261117-o-worker-orquestrador`), e um vazio em qualquer deles
   faz todo nível acima de `assisted` valer `assisted`, nomeando o arquivo. Commitada, a linha só
   chega aos worktrees cortados depois do commit; fora do commit, ela vai em cada worktree de
   missão. Um worktree cuja branch traz uma cópia mergeada de missão da campanha também guarda uma,
   e também é lido;
2. preencher `level`, `expires` e os dois tetos abaixo, e assinar (seção "Como assinar").

## Os cinco níveis, cumulativos

| Nível | O que o worker faz sem perguntar |
|---|---|
| `assisted` | nada: propõe cada ato e espera o sim do dono |
| `pr` | roda a missão, abre o PR e trata os bots |
| `plan` | o de `pr`, e planeja a missão seguinte |
| `merge` | o de `plan`, e mergeia e faz o pós-merge |
| `full` | o de `merge`, e aprova o plano (`sdd approve`) |

Delegação ausente, ilegível, sem assinatura, editada depois de assinada ou vencida vale `assisted`.
Acima de `assisted`, um `ON_ESCALATION_CMD` vazio no `.sdd/config.sh` do checkout da campanha ou de
um worktree que guarda missão dela (onde o `sdd run` da missão roda e avisa) também vale
`assisted`: uma noite sem ninguém olhando precisa de um aviso que chegue. Os L6a a L6k desta
campanha têm teto `plan` no `campaign.md`: neles o nível efetivo nunca passa de `plan`, qualquer que
seja o assinado.

## Como assinar

1. Preencha as seis primeiras chaves e deixe `signed:` vazio.
2. Num terminal, rode `bin/sdd-worker delegate docs/superpowers/campaigns/20261117-zerar-as-issues`:
   ele mostra o que está sendo concedido (as seis chaves e uma linha `ceiling <lote>: <teto>` por
   lote da tabela do `campaign.md` ao lado) e pergunta. Só `y` assina.
3. A assinatura grava `signed: <YYYY-MM-DD HH:MM> <digest>`, e o digest cobre as seis chaves e o
   `Lot` e o `Ceiling` de cada linha da tabela de lotes do `campaign.md`. Mudar uma das seis chaves,
   subir ou baixar um teto (o `plan` do L6a, por exemplo), ou pôr ou tirar um lote da tabela depois
   disso invalida o digest, e a delegação volta a valer `assisted` até ser assinada de novo. Riscar
   itens e reescrever o título ou a contagem de um lote não invalida: a campanha faz isso enquanto
   anda.
4. Commite o arquivo: a delegação é versionada no repo-alvo, e o commit é a trilha.
