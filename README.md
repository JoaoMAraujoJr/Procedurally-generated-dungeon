# Dungeon Procedural

Este projeto da primeira unidade visa implementar um sistema de geração procedural de masmorras utilizando algoritmos de caminhada aleatória, análise de adjacência para estruturas arquitetônicas e um agente inteligente capaz de validar a jogabilidade do mapa antes do início da partida.

## Técnicas de Geração Procedural

A masmorra é gerada seguindo um pipeline de restrições para garantir que o mapa seja orgânico, mas funcional:

1.  **Carving de Corredores (Random Points):** O algoritmo seleciona pontos aleatórios na matriz e utiliza um sistema de "escavação" (*carving*) horizontal e vertical para conectá-los, garantindo que não existam áreas isoladas.
2.  **Identificação de Gargalos (Gate Placement):** Diferente de itens comuns, os **Portões (Gates)** são posicionados através de análise de vizinhança. O sistema busca por tiles de caminho que possuam paredes em eixos opostos (Cima/Baixo ou Esquerda/Direita), garantindo que portões só apareçam em corredores de 1 bloco de largura.
3.  **Distribuição de Entidades:** Itens como **Chaves (Keys)**, Inimigos e Tesouros são espalhados utilizando amostragem aleatória sobre os caminhos remanescentes. O sistema garante a paridade entre o número de chaves e portões.

## Processo de Geração da Dungeon

O fluxo de criação segue uma política de **"Gere até ser Válido"**:

* **Fase 1: Estrutura:** Criação da malha de paredes e caminhos base.
* **Fase 2: Portões Estratégicos:** Posicionamento de portões apenas em corredores validados.
* **Fase 3: Entidades:** Distribuição de chaves, itens e inimigos nos espaços restantes.
* **Fase 4: Spawn do Agente:** O agente é posicionado no local de maior custo de caminho em relação à saída, incentivando a exploração total.
* **Fase 5: Validação (Simulação):** Antes da renderização visual, um agente virtual executa uma simulação completa. Se o agente morrer ou ficar preso por falta de acesso a uma chave, o mapa é descartado e um novo é gerado.

## Comportamento do Agente (IA de Simulação)

O comportamento do agente é regido por uma **Máquina de Estados de Prioridade** combinada com o algoritmo de busca **A* (A-Star)**:

### Tomada de Decisão
O agente avalia o estado do ambiente em tempo real e prioriza objetivos nesta ordem:
1.  **Sobrevivência:** Se o HP estiver crítico, busca a poção mais próxima.
2.  **Coleta de Recursos:** Busca chaves acessíveis para expandir suas rotas.
3.  **Exploração/Combate:** Elimina inimigos e coleta tesouros.
4.  **Progressão:** Utiliza chaves para abrir portões se não houver outros objetivos no setor atual.
5.  **Conclusão:** Dirige-se à saída após cumprir os requisitos.

### Otimização do Pathfinding
Para que a simulação seja fidedigna, o algoritmo **A*** possui pesos dinâmicos:
* **Portões** são tratados como obstáculos intransponíveis (`WALL`) por padrão.
* Um portão só se torna um nó navegável se for o **objetivo atual** de movimento do agente e se houver uma chave disponível no inventário da simulação.

---

## Tecnologias
* **Godot Engine 4.x**
* **GDScript** (Lógica de matrizes e algoritmos de busca)
* **A* para Pathfinding** customizado 

---

### Exemplo de Representação na Matriz
```text
# # # # # # # # # #
# 0 . . # . . + # #  (0 = Agente, + = Chave)
# # # . # . # # # #
# . . . H . . . X #  (H = Portão, X = Saída)
# # # # # # # # # #
```
## Screenshots:
![Preview da Dungeon](screenshot_1.png)
![Preview da Dungeon](screenshot_2.png)
![Preview da Dungeon](screenshot_3.png)
