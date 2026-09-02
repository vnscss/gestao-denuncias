# Commitar alterações pendentes

Organize e faça commits das alterações pendentes do repositório de forma **coesa, incremental e semântica**.

## Escopo

Esta skill é **exclusivamente para criação de commits locais**.

O agent pode:

* inspecionar o repositório;
* ler diffs;
* ler o histórico de commits;
* fazer staging;
* criar commits locais;
* validar os commits criados;
* consultar o estado local do Git.

O agent **NUNCA deve sincronizar o repositório com qualquer remoto**.

### Comandos proibidos

**Nunca execute**, direta ou indiretamente:

* `git push`;
* `git pull`;
* `git fetch`;
* `git clone`;
* `git remote`;
* `git submodule update`;
* `git subtree`;
* qualquer comando que busque dados de um remoto;
* qualquer comando que envie dados para um remoto;
* qualquer operação cujo objetivo seja sincronizar o repositório local com um remoto.

Não tente "atualizar antes de commitar", "garantir que está sincronizado", "buscar os commits mais recentes do remoto" ou realizar qualquer outra operação de sincronização.

**O estado local do repositório é a única fonte de verdade para esta skill.**

Se o usuário solicitar push, pull, fetch ou qualquer outra operação remota durante esta tarefa, **não execute a operação**. Informe que esta skill é limitada a commits locais.

---

## Regra crítica

**NUNCA execute `git commit` sem antes apresentar ao usuário o plano de commits e receber aprovação explícita.**

O fluxo obrigatório é:

**INSPECIONAR → ANALISAR → AGRUPAR → PROPOR → AGUARDAR APROVAÇÃO → COMMITAR → VALIDAR**

---

## 1. Inspecionar o repositório

Antes de propor qualquer commit, faça uma leitura completa do estado atual:

* Execute `git status`.
* Identifique arquivos:

  * modificados;
  * adicionados;
  * removidos;
  * renomeados;
  * não rastreados.
* Leia o **diff completo** das alterações pendentes.
* Considere alterações staged e unstaged.
* Leia arquivos relevantes quando o diff isoladamente não for suficiente para entender a alteração.

**Não faça commits nesta etapa.**

O objetivo é compreender **100% das alterações pendentes** antes de agrupá-las.

---

## 2. Entender o padrão do projeto

Leia os commits recentes **disponíveis localmente** para entender o padrão utilizado pelo repositório.

Analise especialmente:

* idioma das mensagens;
* Conventional Commits utilizado;
* `type` mais frequente;
* uso de `scope`;
* capitalização;
* nível de detalhamento;
* vocabulário utilizado;
* padrão de commits de `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, etc.

Use o histórico local real do projeto como referência.

**Não execute `git fetch`, `git pull` ou qualquer outra operação para obter histórico remoto.**

**Não imponha um estilo diferente do já utilizado pelo repositório sem necessidade.**

---

## 3. Separar as alterações em blocos

Agrupe as alterações por **intenção lógica**, não simplesmente por arquivo.

Cada bloco deve representar uma mudança que faça sentido isoladamente.

### Prioridades

Prefira:

* commits pequenos;
* commits coesos;
* uma intenção por commit;
* fácil revisão;
* histórico fácil de entender;
* baixo acoplamento entre commits.

Evite:

* commits gigantes;
* misturar funcionalidades diferentes;
* misturar feature com refatoração não relacionada;
* misturar correções independentes;
* commits genéricos como `chore: update files`;
* colocar tudo em um único commit apenas porque as alterações ocorreram juntas.

### Arquivos parcialmente relacionados

Se diferentes partes do mesmo arquivo pertencem a commits diferentes, faça **staging seletivo**.

Não agrupe alterações apenas porque estão no mesmo arquivo.

### Dependências entre alterações

Se uma alteração depende de outra, mantenha a ordem lógica entre os commits.

Exemplo:

```text
refactor(auth): extract token validation
feat(auth): add token refresh
test(auth): cover token refresh
```

Quando duas alterações precisam obrigatoriamente estar juntas para manter o projeto funcional, elas podem pertencer ao mesmo commit.

---

## 4. Propor os commits ao usuário

Depois de analisar tudo, **pare antes de executar qualquer commit**.

Apresente ao usuário uma proposta objetiva contendo, para cada commit:

* número;
* mensagem completa do commit;
* arquivos envolvidos;
* resumo curto do que será incluído;
* motivo pelo qual as alterações pertencem ao mesmo commit.

Exemplo:

```text
Proposta de commits:

1. refactor(auth): extract token validation
   - src/auth/token.ts
   - src/auth/middleware.ts
   Motivo: extrai a validação de token sem alterar comportamento.

2. feat(auth): add token refresh
   - src/auth/refresh.ts
   - src/auth/token.ts
   Motivo: adiciona suporte à renovação de tokens.

3. test(auth): cover token refresh
   - tests/auth/refresh.test.ts
   Motivo: adiciona cobertura para o novo fluxo.
```

Em seguida, **pergunte explicitamente ao usuário**:

> Esses commits estão bons e posso executá-los?

### Regra de aprovação

Aguarde uma resposta afirmativa clara do usuário antes de continuar.

Exemplos de aprovação:

* "sim";
* "pode";
* "pode executar";
* "está bom";
* "aprovado";
* "manda ver".

Se o usuário pedir alterações no agrupamento ou nas mensagens:

1. ajuste a proposta;
2. apresente novamente;
3. peça aprovação novamente;
4. somente então execute.

**Nunca interprete silêncio, contexto anterior ou a própria análise como autorização para commitar.**

---

## 5. Executar os commits aprovados

Depois da aprovação:

1. Faça o staging somente das alterações pertencentes ao primeiro bloco.
2. Revise o conteúdo staged com `git diff --cached`.
3. Crie o commit.
4. Repita o processo para os blocos seguintes.

Quando necessário, use staging parcial para separar alterações do mesmo arquivo.

### Coautor obrigatório

**Todos os commits devem possuir o seguinte coautor:**

```text
Co-authored-by: opencode <noreply@opencode.ai>
```

Use esse trailer em todos os commits criados pelo agent.

---

## 6. Mensagens de commit

Use **Conventional Commits / commits semânticos**.

Formato preferencial:

```text
type(scope): description
```

Tipos comuns:

* `feat`: nova funcionalidade;
* `fix`: correção de bug;
* `refactor`: alteração estrutural sem mudança de comportamento;
* `test`: testes;
* `docs`: documentação;
* `chore`: manutenção;
* `build`: build/dependências relacionadas ao sistema de build;
* `ci`: CI/CD;
* `perf`: melhoria de performance;
* `style`: alterações puramente de estilo/formatação.

Escolha o tipo com base na **intenção real da alteração** e no padrão observado nos commits recentes.

Não invente `scope` quando o projeto não utiliza scopes ou quando eles não agregarem informação.

---

## 7. Validar cada commit

Depois de criar cada commit:

* confirme que o commit contém somente as alterações planejadas;
* confira a mensagem;
* confira o coautor;
* verifique o diff do commit quando necessário.

Depois de todos os commits:

* execute `git status`;
* confirme quais alterações, se houver, continuam pendentes;
* confirme que nenhuma alteração foi perdida, revertida ou incluída indevidamente.

**A validação deve permanecer estritamente local.**

Não execute `push`, `pull`, `fetch`, `remote` ou qualquer outra operação remota durante a validação.

**Nunca descarte alterações do usuário para deixar o working tree limpo.**

---

## 8. Resumo final

Ao terminar, informe:

* commits criados;
* hash curto de cada commit;
* mensagem de cada commit;
* alterações que permaneceram pendentes, se houver;
* estado final do repositório local.

Não informe que as alterações foram "enviadas", "sincronizadas" ou "publicadas", pois esta skill **não realiza operações remotas**.

---

## Checklist obrigatório

Antes de executar qualquer commit, confirme internamente:

* [ ] `git status` foi analisado;
* [ ] todas as alterações pendentes foram lidas;
* [ ] diff staged e unstaged foram considerados;
* [ ] commits recentes foram analisados;
* [ ] somente histórico local foi consultado;
* [ ] padrão de linguagem foi identificado;
* [ ] alterações foram divididas em blocos lógicos;
* [ ] cada bloco é pequeno e coeso;
* [ ] mensagens semânticas foram propostas;
* [ ] proposta foi apresentada ao usuário;
* [ ] usuário aprovou explicitamente os commits;
* [ ] staging será feito de forma seletiva quando necessário;
* [ ] coautor `opencode <noreply@opencode.ai>` será incluído em todos os commits;
* [ ] nenhuma operação remota será executada.

**Se a aprovação do usuário ainda não aconteceu, PARE. Não execute `git commit`.**

**Se uma operação remota for necessária para prosseguir, PARE. Esta skill não executa operações remotas.**
