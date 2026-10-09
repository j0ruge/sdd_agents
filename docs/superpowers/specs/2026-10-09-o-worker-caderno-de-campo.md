# O worker — caderno de campo (aberto em 2026-10-09)

> Companheiro de [`2026-09-22-o-worker-roadmap-design.md`](2026-09-22-o-worker-roadmap-design.md)
> (frente F6 da [gaveta](2026-09-23-a-gaveta-do-kit.md)). O roadmap está **estacionado** até "os
> fluxos atuais rodarem até o fim sem problemas"; este caderno é a medição desse "até". A partir de
> 2026-10-09 o humano resolve as issues do `sales_quote` com o kit (uma missão por lote de issues,
> planejada com `/sdd-plan`), e cada missão deixa aqui o que um worker noturno precisaria saber.
>
> **Regra do caderno:** o que o ledger e o journal já sabem (custo, sessões, escaladas, tempos)
> **não** se copia para cá — sai dos comandos da §7 da linha de base. Aqui entra só o que nenhum
> instrumento registra: tempo humano de PLAN, passos de ambiente feitos à mão, o que o humano fez
> entre dois lançamentos, e o que o worker teria feito em cada parada.

## 1. A linha de base (21 missões do `sales_quote`, 2026-08-14 → 2026-10-06)

Medida só por leitura, com método e comandos reprodutíveis em
[`2026-10-09-o-worker-linha-de-base.md`](2026-10-09-o-worker-linha-de-base.md):

- **US$ 1 636 no runner**; por missão, mediana US$ 52,94 e p90 US$ 159,38 (desde 2026-09-24 a
  mediana caiu para US$ 35). EXEC 43 %, REVIEW 27 %, QA 19 % do custo.
- **Só 4 de 21 (19 %) foram do TICKET ao PR sem toque humano.** 46 relançamentos antes do PR,
  mediana de 10 min entre parar e relançar — o humano estava olhando.
- **25 escaladas rc 3** (12 de kit, 9 de decisão humana, 4 de ambiente) e **27 paradas sem
  escalada** (14 de operador, 7 de ambiente). `app-down` e `session-died` nunca dispararam.
- **Contrafactual:** com W2, W4 e W6 prontos e o kit de hoje, ≈ 12 de 21 (57 %) teriam chegado ao
  PR sozinhas. Supõe que nenhum defeito novo de kit apareceria — e apareceu um a cada 3–4 missões.

## 2. O que a medição acrescenta ao roadmap

Cada linha é um fato medido e o degrau que ele mexe. **Nenhuma é decisão**: as decisões voltam ao
humano quando o roadmap sair do estacionamento.

| # | Fato medido | Evidência | Degrau |
|---|---|---|---|
| C1 | **O worker precisa de um kit fixo.** 6 das 25 escaladas foram `kit-touched`: a guarda compara o checkout do kit para onde o `sdd` do PATH aponta, e o clone dedicado do alvo (D3) não muda isso. Nenhum degrau W1–W7 nomeia o kit que o worker executa. | linha de base §4.1 | novo, perto do W2 |
| C2 | **No `sales_quote` a QA é por projeto, não por missão.** Com `APP_URL` e `E2E_CMD` configurados, toda missão roda as três sessões de QA e o `gate_QA` roda a e2e (`bin/sdd:1633`, `bin/sdd:2678`) — inclusive um lote só de backend. Sem stack no ar à noite, a QA para em `app-down`. | config do alvo; triagem | W4 deixa de ser opcional neste repo |
| C3 | **O regime do timer já matou um `sdd run`.** O único lançado por `systemd-run` morreu com rc 127: o npm do nvm fora do PATH. Houve também node errado, OAuth expirado e mortes por memória — daí os 14 `--max-phases 1` do humano. | linha de base §2.1, §4.2 | W6 |
| C4 | **Clone novo tem passo escondido.** Um worktree novo do `sales_quote` reprova 55 arquivos de teste do backend com `Cannot find module '.prisma/client/default'` até alguém rodar `npm run db:generate`; o `npm ci` não o roda. | faxina de 2026-10-09 | W2 ("clone novo sem passo manual escondido") |
| C5 | **Nenhuma escalada chega a um pager.** `ON_ESCALATION_CMD=""` no `sales_quote`; 9 das 21 missões pararam por decisão humana ou teto. | `.sdd/config.sh` do alvo | W6 deve exigir o pager |
| C6 | **Bots do PR:** o Codex revisou 12 de 21 PRs (achou algo em 10, 6 P1), sempre numa leva só; um achado chegou em 51 min. Copilot 0 de 21 (cota), CodeRabbit ausente. 10 de 21 PRs ganharam commit de conserto depois de abertos. "Cota/limite" tem de ler como **não revisou**, nunca como limpo. | linha de base §3.4 | W7: espera ≥ 60 min |
| C7 | **O squash merge quebra o ciclo do `RESOLVED by`.** Os PRs de missão #405 e #406 entraram por squash; o hash do branch nunca vira ancestral da base e quatro itens ficaram presos no `TODO.md`. Decisão do humano em 2026-10-09: PR de missão do `sales_quote` entra por **merge commit**. O template do kit segue sem caminho para quem faz squash. | `git cat-file -p` dos merges | W3 e W7 (o aviso de pronto para merge) |
| C8 | **O espelho de issues é a fila do D6, e estava parado.** Sem re-sincronizar desde 2026-09-24: 8 issues órfãs, 40 itens sem issue, e o script recusa o `TODO.md` com 206 violações da ADR 0015 §2 (âncora sem símbolo) — o arquivo é anterior à regra. Com `TRACKER=github`, um worker que lê prioridade do rastreador leria uma fila falsa. | `todo_issues.py --audit` | W3, W5 |
| C9 | **Admissão: nem toda issue é material de worker.** Triagem das 194 abertas: 69 sim, 31 talvez, 66 não; os quatro traços do "sim" são verificável por `TEST_CMD`, sem decisão de produto, sem acesso externo e sem QA de interface — e o C2 tira o último no `sales_quote`. | triagem de 2026-10-09 | W5 (o "porque Z" do dry-run) |

## 3. Registro por missão (de 2026-10-09 em diante)

Uma linha por missão, escrita depois do merge. Colunas que só um humano preenche:

- **PLAN** — minutos de humano no `/sdd-plan` até o `sdd approve` (o gargalo do worker é a vazão
  de planejamento: ele só consome missão aprovada);
- **worker?** — o planner, com o humano, diria que a missão é material de worker (sim/talvez/não, e
  por quê);
- **ambiente à mão** — o que o humano subiu, consertou ou reautenticou para a corrida andar;
- **toques depois da aprovação** — cada relançamento, retry, `--phase`, conserto à mão, com o motivo;
- **o worker teria** — para cada toque: seguido sozinho, parado e chamado, ou precisado de qual degrau.

| missão | issues | PLAN | worker? | ambiente à mão | toques depois da aprovação | o worker teria | PR |
|---|---|---|---|---|---|---|---|
| L1 — backend: o que some calado | #251 #254 #270 #273 #274 | — | — | — | — | — | — |

## 4. Perguntas que voltam ao humano com o roadmap

- O D1 ("o worker nunca planeja") continua de pé? O pedido de 2026-10-09 ("à noite tratar as
  issues de maneira não assistida") cabe nele: de dia o humano planeja e aprova, à noite o worker
  executa. Se a intenção for o worker planejar issue pequena, é a alternativa recusada no D1 e pede
  decisão nova.
- O kit fixo (C1) é degrau próprio ou parte do W2?
- Missão sem jornada de interface num repo com interface (C2): declaração por missão no
  `00-missao.md`, ou o W4 sobe o stack sempre?
