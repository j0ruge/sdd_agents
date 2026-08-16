# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-08-16] A caixa `- [ ]` do TODO.md mente; o corpo é a verdade**
   Do instead: antes de planejar sobre um item do TODO.md, ler o corpo — itens com
   **RESOLVIDO por `<hash>`** já estão fechados mesmo desmarcados. Se o hash já está em
   `main` (`git merge-base --is-ancestor`), o item **se apaga**, não se arquiva; `- [x]`
   não existe mais no arquivo e o teto por item é 8 linhas (`tests/check-todo.sh`).
2. **[2026-08-15] Gate/sensor novo não entra sem mutação**
   Do instead: toda asserção nova de gate ganha entrada em `tests/check-mutation.sh`
   e o catálogo do `sdd health`; provar por sabotagem que a suíte morre.
3. **[2026-08-16] A suíte é `tests/run-all.sh` (~33s no default, mutação 30/30)**
   Do instead: rodar ela como TEST_CMD; o default já deriva `min(núcleos, 8)` com
   pool (`wait -n`) desde 2026-08-16 — mediana 54,13s → 32,87s nesta máquina de 20
   núcleos. Override explícito vence; lixo no env é recusado. Alvo <30s ainda
   estourado por ~3s — item vivo no TODO.md (subir o alvo ou aceitar).
4. **[2026-08-15] Fixture de veredito vem do real, nunca de memória**
   Do instead: o frontmatter dos fixtures de `05-verdict.md` no check-kaizen.sh
   é copiado do veredito real (`c2dd298`) com nota de proveniência; ao mudar o
   formato do veredito, re-copiar do artefato real, não editar de cabeça.

5. **[2026-08-16] Sensor sobre conteúdo em `OUTPUT_LANG` mede estrutura, não palavra**
   Do instead: regra de sensor sobre `TODO.md`/handoffs ancora em pontuação, crase,
   data `(YYYY-MM-DD)` — nunca em "descoberto por". Palavra em português quebra num
   repo-alvo `OUTPUT_LANG="en"` e ainda obriga a excluir o sensor do `check-lang`.

## Language & Contract
1. **[2026-08-15] Superfície do kit = inglês; artefato de missão = OUTPUT_LANG (pt-BR aqui)**
   Do instead: arquivo novo em `bin/ agents/ docs/ tests/ config/ README` nasce em inglês
   e entra na catraca de `tests/check-lang.sh`; `TODO.md`, `KAIZEN_LOG.md`, handoffs,
   `CONTEXT.md` e planos ficam em pt-BR.
2. **[2026-08-15] Contrato ainda tem 5 pontos PT-BR por herança**
   Do instead: usar `aprovacao`/`versao`/`titulo` e `00-missao.md`/`01-plano.md` como estão;
   renomear é missão própria (TODO.md).

## User Directives
1. **[2026-08-15] Fluxo de missão do kit: planejar no Fable, executar no Opus**
   Do instead: brainstorm + grill-with-docs + kaizen no Fable → plano autocontido em
   `~/.claude/plans/AAAA-MM-DD-<slug>.md` (padrão do I13.5) → humano troca para Opus e executa.
2. **[2026-08-15] Kaizen exige número**
   Do instead: toda melhoria proposta declara antes/depois medível; sem número vai como
   opinião, não como kaizen.
