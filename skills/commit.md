# Commitar alterações pendentes

Esta skill serve exclusivamente para **organizar e criar commits locais**.

Não execute operações remotas.

## Operações permitidas

Use normalmente comandos Git necessários para:

* inspecionar o estado local;
* ler alterações;
* consultar histórico local;
* fazer staging;
* criar commits;
* validar commits locais.

Operações como `git status`, `git diff`, `git log`, `git add`, `git reset` e `git commit` são permitidas quando necessárias.

## Operações proibidas

Nunca execute:

* `git push`
* `git pull`
* `git fetch`
* `git clone`
* `git remote`
* operações de sincronização com remotos
* qualquer comando que envie dados para um remoto;
* qualquer comando que busque dados de um remoto.

Esta skill trabalha somente com o estado **local** do repositório.

---

## Fluxo

Siga esta ordem:

1. analisar;
2. propor os commits;
3. pedir aprovação;
4. executar os commits aprovados;
5. validar o resultado.

### 1. Analisar

Primeiro, examine todas as alterações pendentes.

Use:

```bash
git status
git diff
git diff --cached
```

Considere:

* arquivos modificados;
* arquivos novos;
* arquivos removidos;
* arquivos renomeados;
* alterações staged;
* alterações unstaged;
* arquivos não rastreados.

Leia o diff completo antes de decidir como dividir os commits.

Quando necessário, leia os arquivos envolvidos para entender o contexto da alteração.

### 2. Analisar o histórico

Leia os commits locais mais recentes para identificar o padrão do projeto.

Use, por exemplo:

```bash
git log -n 10 --oneline
git log -n 10 --format=fuller
```

Observe:

* idioma;
* estilo;
* `type`;
* `scope`;
* Conventional Commits;
* capitalização;
* nível de detalhamento.

Siga o padrão encontrado no próprio repositório.

Não faça `fetch`, `pull` ou qualquer operação remota para obter histórico.

### 3. Dividir em commits

Agrupe as alterações por **intenção lógica**.

Prefira commits:

* pequenos;
* coesos;
* fáceis de revisar;
* com uma única responsabilidade;
* independentes quando possível.

Evite colocar alterações não relacionadas no mesmo commit.

Não agrupe alterações somente porque pertencem ao mesmo arquivo.

Se partes diferentes de um arquivo pertencem a commits diferentes, use staging seletivo.

Se uma alteração depende de outra, organize os commits na ordem correta.

Não crie commits artificiais apenas para reduzir o tamanho. Cada commit deve representar uma mudança real e coerente.

### 4. Criar a proposta

Antes de criar qualquer commit, mostre ao usuário o plano.

Para cada commit, informe:

```text
1. type(scope): descrição
   Arquivos:
   - arquivo-a
   - arquivo-b

   Alteração:
   breve descrição da mudança
```

A proposta deve conter todos os commits que serão criados e explicar brevemente a separação.

Depois pergunte:

**"Os commits propostos estão bons e posso executá-los?"**

Aguarde a resposta do usuário.

Se o usuário pedir alterações, ajuste a proposta e peça aprovação novamente.

**Somente após uma aprovação explícita execute os commits.**

### 5. Executar os commits

Após a aprovação, execute os commits exatamente conforme a proposta aprovada.

Para cada commit:

1. faça staging somente das alterações daquele commit;
2. confira o conteúdo staged;
3. execute `git commit`;
4. confirme o commit criado.

Quando houver alterações diferentes no mesmo arquivo, faça staging por partes.

Não inclua alterações que não façam parte do commit aprovado.

### 6. Coautor

Todos os commits criados por esta skill devem incluir:

```text
Co-authored-by: opencode <noreply@opencode.ai>
```

Exemplo:

```bash
git commit -m "feat(core): add request collector" \
  --trailer "Co-authored-by: opencode <noreply@opencode.ai>"
```

Use a sintaxe de trailer suportada pelo Git para garantir que o coautor apareça corretamente no commit.

### 7. Mensagens

Use Conventional Commits:

```text
type(scope): description
```

Tipos comuns:

* `feat`
* `fix`
* `refactor`
* `test`
* `docs`
* `chore`
* `build`
* `ci`
* `perf`
* `style`

Escolha o tipo de acordo com a intenção da alteração.

Use `scope` quando isso for consistente com o padrão do projeto.

A mensagem deve seguir o idioma e o estilo observados no histórico recente.

### 8. Validação

Depois de criar os commits:

```bash
git status
git log -n <quantidade> --oneline
```

Confirme:

* quais commits foram criados;
* que cada commit contém somente as alterações esperadas;
* que o coautor está presente;
* se existem alterações ainda não commitadas.

A validação deve ser exclusivamente local.

Não execute `push`, `pull`, `fetch` ou outras operações remotas.

## Regra de aprovação

A aprovação do usuário é necessária **somente antes da execução dos commits**.

Depois que o usuário aprovar a proposta, execute os commits aprovados normalmente.

Não peça uma nova aprovação para cada commit individual, a menos que a proposta tenha sido alterada.

## Regra de escopo

Esta skill **não publica, sincroniza ou atualiza o repositório remoto**.

Seu objetivo termina após a criação e validação dos commits locais.
