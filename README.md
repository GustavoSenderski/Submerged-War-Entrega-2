# SUBMERGED WAR

**Protótipo Alpha Técnico --- Entrega 2**\
**XP6 --- Trilha de Programação**\
**Engine:** Godot Engine 4.7.2\
**Plataforma da build:** Windows 64 bits

## 1. Sobre o projeto

**Submerged War** é um protótipo de jogo 3D de ação e estratégia naval
desenvolvido em Godot.

O jogador controla um submarino em um ambiente marítimo, devendo navegar
pelo cenário, controlar sua profundidade, evitar obstáculos e ameaças,
enfrentar navios e submarinos inimigos e alcançar o objetivo da missão.

A Entrega 2 apresenta um **Alpha Técnico funcional**, desenvolvido a
partir dos sistemas e conceitos definidos na Entrega 1.

## 2. Requisitos

### Para abrir e editar o projeto

-   Godot Engine 4.7.2;
-   Renderer Forward Plus;
-   Sistema operacional compatível com Godot 4.

### Para executar a versão compilada

-   Windows 64 bits;
-   Teclado ou controle compatível.

## 3. Como abrir e executar o projeto

1.  Abra o Godot Engine 4.7.2.
2.  Selecione **Importar**.
3.  Localize a pasta do projeto.
4.  Selecione o arquivo `project.godot`.
5.  Importe e abra o projeto.
6.  Pressione **F5** para executar o projeto completo a partir do menu
	principal.
7.  **F6** pode ser utilizado para executar somente a cena atualmente
	aberta durante os testes.

A cena inicial apresenta o menu principal com as opções **JOGAR** e
**SAIR**.

## 4. Versão jogável

A versão executável para Windows é disponibilizada separadamente do
código-fonte.

**Arquivo da build:** `Submerged_War_Protótipo_Alpha_Técnico.exe`

Para executar a versão compilada, basta abrir o arquivo `.exe`. Não é
necessária a instalação do Godot.

## 5. Controles

### Gameplay

  Ação                Teclado      Controle
  ------------------- ------------ ----------------------------
  Avançar             **W**        Analógico esquerdo ↑
  Recuar              **S**        Analógico esquerdo ↓
  Virar à esquerda    **A**        Analógico esquerdo ←
  Virar à direita     **D**        Analógico esquerdo →
  Subir               **↑**        Analógico direito ↑
  Descer              **↓**        Analógico direito ↓
  Disparar torpedo    **Espaço**   **RT / R2**
  Boost               **Shift**    **LB / L1** ou **LT / L2**
  Visão estratégica   **V**        **Back / Select**

### Menu principal

  Ação                    Controle
  ----------------------- --------------------------------
  Selecionar para cima    Analógico esquerdo ↑
  Selecionar para baixo   Analógico esquerdo ↓
  Confirmar               **A (Xbox) / X (PlayStation)**

Os botões do menu também podem ser utilizados diretamente com mouse.

## 6. Sistemas implementados

A versão Alpha apresenta os seguintes sistemas funcionais:

-   movimentação 3D do submarino;
-   controle de profundidade;
-   sistema de boost;
-   limites da área jogável;
-   colisão com os continentes;
-   disparo de torpedos;
-   sistema de vida e dano;
-   navios inimigos;
-   submarinos inimigos;
-   comportamentos de IA;
-   torpedos inimigos;
-   minas inimigas;
-   minas temporizadas;
-   geração e posicionamento de inimigos;
-   objetivo de missão;
-   posicionamento aleatório do jogador e do objetivo;
-   sistema de vitória;
-   sistema de derrota;
-   reinício da missão;
-   HUD;
-   sonar;
-   visão estratégica;
-   menu inicial;
-   suporte a controle na interface;
-   shaders para água, fundo do mar e mapa.

## 7. Evolução desde a Entrega 1

A Entrega 1 definiu os conceitos e sistemas principais de **Submerged
War**.

Na Entrega 2, o foco foi transformar esse planejamento em um núcleo
jogável, integrado e estável.

Principais evoluções:

-   navegação básica → movimentação, rotação, profundidade e boost;
-   combate planejado → torpedos, vida e dano;
-   inimigos marítimos → navios e submarinos com IA;
-   perigos submarinos → minas e torpedos inimigos;
-   exploração → cenário 3D com continentes e colisões;
-   orientação → sonar e visão estratégica;
-   objetivo conceitual → objetivo funcional com condição de vitória;
-   condição de derrota → destruição do submarino, tela de derrota e reinício.

Durante o desenvolvimento, algumas decisões foram ajustadas para manter
o escopo adequado ao Alpha e priorizar estabilidade, integração e
funcionamento dos sistemas principais.
## Evolução do Protótipo

A imagem abaixo apresenta a evolução do planejamento da Entrega 1 para o Alpha funcional da Entrega 2.

![Evolução do Submerged War](Evolução%20Projeto%20_V@.png)

## 8. Organização do projeto

``` text
Submerged-War-Entrega-2/
├── assets/
├── Scenes/
├── screenshots/
├── scripts/
├── Shaders/
├── export_presets.cfg
├── icon.svg
├── project.godot
└── README.md
```

-   `assets/` --- recursos utilizados pelo projeto;
-   `Scenes/` --- cenas do jogo;
-   `scripts/` --- scripts GDScript;
-   `Shaders/` --- shaders utilizados nos elementos visuais;
-   `screenshots/` --- capturas do protótipo;
-   `project.godot` --- configuração principal do projeto;
-   `export_presets.cfg` --- configuração utilizada para exportação.

## 9. Recursos e uso de Inteligência Artificial

Os elementos utilizados no protótipo **Submerged War** foram
desenvolvidos pelo grupo durante a produção do projeto, com auxílio de
ferramentas de Inteligência Artificial em diferentes etapas do
desenvolvimento.

A Inteligência Artificial foi utilizada como ferramenta de apoio para: 
	- revisão e organização de código; 
	- apoio na criação de elementos visuais;
	- auxilio na geração e desenvolvimento de ideias; 
	- auxílio na identificação e resolução de problemas técnicos; 
	- revisão e organização dos sistemas implementados.

As soluções utilizadas foram analisadas, adaptadas, integradas e
testadas pelos integrantes responsáveis por cada área.

O uso de Inteligência Artificial ocorreu como **ferramenta de suporte ao
processo de desenvolvimento**, não substituindo as etapas de
implementação, integração, testes e tomada de decisões realizadas pela
equipe.

## 10. Estado do Alpha

A versão apresentada na Entrega 2 possui o núcleo de gameplay integrado
e funcional.

Os principais sistemas, scripts GDScript e shaders foram revisados e
testados durante o desenvolvimento.

No fechamento da versão Alpha, o projeto foi executado no Godot sem
erros ou alertas no depurador, e a versão compilada para Windows foi
testada separadamente do editor.

## 11. Informações acadêmicas

**Projeto:** Submerged War\
**Entrega:** Protótipo Alpha Técnico --- Entrega 2\
**Disciplina/Projeto:** XP6 --- Trilha de Programação\
**Engine:** Godot Engine 4.7.2\
**Tipo:** Projeto acadêmico
