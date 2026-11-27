# Testes Funcionais

Suite de autoverificacao do template. Ela instancia as cenas de exemplo,
exercita cada componente e valida as integracoes entre eles.

## Executar

Na pasta raiz do projeto:

```bash
godot --headless --path . res://tests/functional_test.tscn
```

No editor: abra `tests/functional_test.tscn` e pressione **F6**.

O processo termina com codigo de saida `0` quando todas as verificacoes
passam e com codigo `1` quando pelo menos uma falha.

## O que e verificado

| Area | Verificacoes |
|------|--------------|
| Autoload / Managers | `GameManager` cria e expoe todos os managers |
| Player | grupo, componentes, colisao, resolucao da camera |
| Interacao | raycast, prompt, `interaction_distance`, highlight, eco de teclado, alvo liberado |
| Interativos | porta (abrir/fechar), nota (coleta e registro) |
| Inventario | add/remove, contagem, copia independente, serializacao |
| Save / Load | gravacao, restauracao de inventario/sanidade/notas, API dos slots |
| Sanidade | dreno, recuperacao, limiares com disparo unico |
| Lanterna | liga/desliga, bateria, flicker, apagamento no esgotamento |
| Audio / Fade | tolerancia a nulos, camada do fade acima da HUD |
| Movimento | direcao planar mesmo com a camera inclinada |

## Adicionando verificacoes

Use o helper `check(condicao, "descricao")`. O helper imprime o resultado e
registra a falha para o resumo final:

```gdscript
check(minha_componente.faz_algo(), "Minha componente faz algo")
```

## Nota

O teste usa `user://saves/` para gravar e apagar um slot temporario
(`test_slot`). Nao ha residuo em disco ao final da execucao.
