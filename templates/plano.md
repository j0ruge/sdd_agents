---
missao: <YYYYMMDD>-<slug>
data: <YYYY-MM-DD>
---

# Plano — <título da missão>

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

<Fatos do repo confirmados durante o planejamento: caminhos, comandos que funcionam, versões,
pitfalls conhecidos. Cada linha economiza uma exploração cara em sessão headless.>

- <fato> — `arquivo:linha` / saída do comando

## Arquitetura da mudança

<Como a solução se encaixa no que já existe: arquivos tocados, contratos, fluxo de dados.
Diagrama só se ele explicar algo que o texto não explica.>

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### <ID> — <título do incremento>

**O quê:** <a mudança, concreta>
**Onde:** `<arquivos>`
**Como (TDD):** <o teste que vem primeiro, e o que ele deve falhar antes de passar>
**Check:** `<comando>` → `<resultado esperado>`
**Sensor durável:** <teste/spec/lint que fica no CI provando isto para sempre — ou justificativa
de por que só cabe checagem manual efêmera aqui>
**Reversível por:** <como desfazer, se for a única fatia revertida>

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| <o quê> | <alta/média/baixa> | <o que fazemos se acontecer> |

## Verificação end-to-end

<O que provar quando todos os incrementos estiverem `done` — o comando e o resultado que
demonstram a métrica do `00-missao.md`.>
