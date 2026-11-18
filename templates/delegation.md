---
campaign: <YYYYMMDD>-<slug — o id da campanha, igual ao campaign: do campaign.md ao lado>
level: <assisted | pr | plan | merge | full>
lots: <all, ou L1 L2 … separados por espaço>
expires: <YYYY-MM-DD HH:MM, hora local>
budget_mission_usd: <número — o teto de cada missão, passado ao sdd run como BUDGET_MISSION_USD, se o .sdd/config.sh não fixar essa chave acima dele>
budget_campaign_usd: <número — o teto da campanha inteira, somado do ledger>
signed:
---

# Delegação — <título da campanha>

> **Só o frontmatter acima é lido.** Esta prosa é para o dono, e nenhum verbo a lê. O
> `bin/sdd-worker` relê este arquivo a cada passo, e é ele, não uma palavra dita numa sessão, que
> decide o que o worker faz sozinho.
>
> O valor de uma chave é o texto depois do primeiro `: `, sem os espaços do fim e sem aspas.
> Enquanto um valor for um placeholder `<…>`, a delegação é **ilegível** e vale `assisted`.
> Ilegível também: um `campaign:` (o daqui ou o do `campaign.md` ao lado) que não é o nome do
> diretório, e um `expires:` que o relógio não tem (`2026-11-31 10:00`, `2026-11-18 99:99`).

## Os cinco níveis, cumulativos

| Nível | O que o worker faz sem perguntar |
|---|---|
| `assisted` | nada: propõe cada ato e espera o sim do dono |
| `pr` | roda a missão, abre o PR e trata os bots |
| `plan` | o de `pr`, e planeja a missão seguinte |
| `merge` | o de `plan`, e mergeia e faz o pós-merge |
| `full` | o de `merge`, e aprova o plano (`sdd approve`) |

Delegação ausente, ilegível, sem assinatura, editada depois de assinada ou vencida vale `assisted`.
Acima de `assisted`, um `ON_ESCALATION_CMD` vazio no `.sdd/config.sh` de qualquer checkout do repo
também vale `assisted`, nomeando o arquivo: o da campanha e o de cada worktree ligado, porque o
`sdd run` de uma missão roda no worktree dela e avisa pelo config de lá. Uma noite sem ninguém
olhando precisa de um aviso que chegue. Pager fora do commit é escrito também em cada worktree.

## O teto por missão

O worker passa o `budget_mission_usd:` ao `sdd run` como `BUDGET_MISSION_USD`, no ambiente, e o
runner lê o `.sdd/config.sh` do checkout em que roda **por cima** do ambiente: uma linha que atribui
essa chave vence o teto assinado, e o `config/starter.conf` que o `sdd install` semeia atribui
`150`. O checkout em que o `sdd run` roda é o worktree da missão, não o da campanha, e um worktree
cortado de um commit que ainda tem a linha a carrega mesmo depois de ela ser apagada aqui. Por isso
o `bin/sdd-worker budget` lê o arquivo de todo checkout do repo (o da campanha e cada worktree
ligado) e sai com rc 1 numa linha `no mission cap — …`, que nomeia o arquivo e o valor, quando um
deles fixa a chave acima do teto assinado, em `0` (sem teto), vazia ou num valor que não é número.
Um valor menor ou igual ao assinado é o teto mais estrito, e vale. Um `budget_mission_usd: 0`
assinado também é sem teto para o runner, e o `budget` para antes de ler qualquer arquivo, nomeando
esta delegação. Antes de assinar, apague a linha
do `.sdd/config.sh` e commite a remoção antes de cortar os worktrees das missões, ou deixe-a no teto
assinado, ou abaixo dele.

## Como assinar

1. Preencha as seis primeiras chaves e deixe `signed:` vazio.
2. Num terminal, rode `bin/sdd-worker delegate <diretório desta campanha>`: ele mostra o que está
   sendo concedido (as seis chaves e uma linha `ceiling <lote>: <teto>` por lote da tabela do
   `campaign.md` ao lado) e pergunta. Só `y` assina.
3. A assinatura grava `signed: <YYYY-MM-DD HH:MM> <digest>`, e o digest cobre as seis chaves e o
   `Lot` e o `Ceiling` de cada linha da tabela de lotes do `campaign.md`. Mudar uma das seis chaves,
   subir ou baixar um teto, ou pôr ou tirar um lote da tabela depois disso invalida o digest, e a
   delegação volta a valer `assisted` até ser assinada de novo. Riscar itens e reescrever o título
   ou a contagem de um lote não invalida: a campanha faz isso enquanto anda.
4. Commite o arquivo: a delegação é versionada no repo-alvo, e o commit é a trilha.
