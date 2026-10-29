# Projeto Roblox — esteira de chaves, baús e armas de anime

## Objetivo deste documento
Guia de contexto e trabalho para o assistente. Este é um projeto novo, começando do zero. As regras e o estado de implementação do antigo jogo Loja de Poções não se aplicam. O nome do novo jogo ainda não foi definido.

## Como trabalhamos
- Conversar e escrever a documentação em português.
- Priorizar agilidade nos sistemas simples: conferência essencial e roteiro curto; aprofundar em economia, salvamento, roubo ou falhas concretas.
- O usuário desenvolve o jogo no Roblox Studio; o assistente ajuda a definir os sistemas e escreve ou ajusta código em Luau.
- Trabalhar em um sistema por vez. Aguardar o retorno do usuário sobre os testes antes de avançar para outro sistema, salvo orientação dele.
- Os testes ficam com o usuário. Não iniciar ou encerrar Play, executar testes ou simulações sem pedido explícito.
- Antes de programar, inspecionar os scripts e a hierarquia acessíveis no Studio conectado. Não presumir que o projeto esteja vazio nem reaproveitar sistemas do jogo antigo automaticamente.
- Ao investigar erros, consultar o script envolvido e a mensagem completa do Output. Inspecionar primeiro o que estiver acessível no Studio.
- Ao entregar uma alteração, fornecer um roteiro curto: ações de teste, resultado esperado e o que reportar se falhar.
- Distinguir revisão de código de testes executados. Registrar a validação como pendente até o retorno do usuário; não declarar testes multiplayer concluídos sem evidência.
- Atualizar este documento ao concluir cada etapa: decisões, alterações, verificações realmente realizadas e pendências.
- Distinguir regras confirmadas, sugestões e pontos em aberto. Não transformar uma sugestão do assistente em decisão do usuário.
- O servidor deve decidir e validar compras, dinheiro, inventário, sorte, resultados dos baús, upgrades, propriedade, combate, roubo e rebirth. O cliente apresenta a interface e envia solicitações.
- Manter a lógica de servidor centralizada no ServerScriptService, fora dos modelos das bases. Definir a organização concreta após inspecionar o projeto.

## Conceito confirmado
Jogo inspirado no estilo de Steal a Brainrot, com uma esteira passando pelo meio do mapa e transportando chaves compráveis. Cada jogador tem uma base com baús e slots para armas ou chaves. Armas de anime geram dinheiro nos slots e também podem ser usadas em combate para tentar roubar itens das bases alheias.

O diferencial é a disputa pelos slots e pelo uso das chaves: uma chave pode abrir um baú ou permanecer em um slot aumentando a sorte dos baús da base.

## Loop principal
1. Comprar chaves que passam na esteira usando o dinheiro obtido no jogo.
2. Comprar baús para a própria base.
3. Melhorar a raridade de um baú até a correspondente à chave que o jogador pretende usar.
4. Usar a chave para abrir o baú e receber uma arma de anime aleatória.
5. Colocar armas nos slots para gerar dinheiro, pisar nos blocos para coletar ou retirar as armas para combate.
6. Colocar chaves nos slots para aumentar a sorte ao abrir baús.
7. Tentar roubar itens dos slots de outros jogadores por meio de confronto.
8. Progredir até fazer rebirth, recomeçando com mais slots.

Esta sequência descreve o conceito; não obriga o jogador a executar todas as ações nessa ordem.

## Chaves, baús e sorte — regras confirmadas
- Cada chave abre um baú específico, de raridade correspondente.
- Baús podem receber upgrades de raridade para permitir o uso da chave desejada.
- A abertura consome a chave e o baú e entrega uma arma aleatória. Para abrir novamente, é necessário outro baú.
- Armas e chaves usam os slots da base.
- Armas nos slots acumulam dinheiro para coleta manual: o dono pisa no bloco à frente do slot. Coleta automática será benefício de gamepass; o usuário ainda não criou o passe.
- Chaves nos slots aumentam a sorte dos baús da base; quanto mais rara a chave, maior o bônus.
- Usar uma chave que estava em um slot significa abrir mão do bônus fornecido por ela.
- A sorte melhora a chance de conseguir armas melhores. Sua fórmula e a combinação de bônus ainda não foram definidas.
- Chaves da esteira e baús são comprados com dinheiro do jogo. A compra do baú comum ocorre por interação nos três espaços do balcão da própria base.

## Eventos e mutações — preparação para o futuro
- O usuário pediu que os scripts estejam preparados para itens originados de eventos e com mutações; efeitos e eventos ficam para uma etapa futura.
- Exemplos desejados: Shine aumentando a sorte da chave; Double permitindo obter dois itens com uma chave.
- Multiplicadores, probabilidades, combinações, regras dos sorteios e detalhes dos eventos ainda não foram definidos.
- Cada exemplar deve preservar UID e metadados nas compras, transferências, slots e respawns. Não reconstruir um item somente pelo itemId, descartando suas características.
- O servidor define mutações e origem. Atributos replicados são apenas projeções para inspeção/apresentação.

## Combate e roubo — conceito confirmado
- O jogador pode usar as armas obtidas para bater em outros jogadores e tentar roubar o que está nos slots deles.
- As regras concretas de combate, retirada de itens dos slots, transporte do item roubado, defesa e conclusão do roubo ainda precisam ser definidas.
- Não presumir escudos, tempos de proteção, perda ao morrer, limites de equipamento ou condições de roubo sem alinhar com o usuário.

## Rebirth — regras confirmadas
- Cada rebirth concede mais slots para a base.
- Os slots desbloqueados permanecem após os próximos rebirths.
- Cada rebirth torna o próximo mais difícil de conseguir.
- O jogador perde dinheiro, armas, chaves e baús, incluindo upgrades dos baús.
- O contador de rebirths permanece.
- Um pequeno bônus permanente de sorte foi considerado pelo usuário, mas continua opcional e sem confirmação final.
- Quantidade de slots ganhos, limites e requisitos de rebirth ainda não foram definidos.
- Exigências de armas específicas para rebirth foram apenas uma sugestão do assistente; não são uma regra aprovada.

## Balanceamento — responsabilidade confirmada
- O usuário pediu que o assistente também cuide do balanceamento para evitar uma economia ou progressão quebrada.
- Planejar renda, preços de chaves e baús, upgrades, probabilidades, sorte, slots e requisitos de rebirth em conjunto.
- Manter os valores e tabelas em configurações centralizadas para permitir ajustes sem reescrever a lógica dos sistemas.
- Definir metas de tempo para a primeira arma, as próximas melhorias e os rebirths. Os tempos e valores concretos ainda precisam ser definidos e validados pelo usuário.
- Calcular o custo total de cada abertura: chave, baú e upgrades necessários. Comparar esse custo com as probabilidades das armas, a renda esperada e o tempo de retorno do investimento.
- Comparar ocupar um slot com uma chave ou com uma arma. Preservar a utilidade das duas escolhas em diferentes momentos da progressão.
- Avaliar o acúmulo de sorte com muitas chaves, slots adicionais e eventual bônus de rebirth. Considerar limites ou retornos decrescentes se necessário; a fórmula ainda não está aprovada.
- Avaliar o efeito dos slots extras sobre a velocidade de progressão. O aumento dos requisitos deve sustentar a dificuldade crescente dos próximos rebirths sem tornar o recomeço inviável.
- Garantir uma forma de voltar a gerar renda no início, após rebirth e após perder itens. O mecanismo ainda será definido; evitar situações em que o jogador fique sem dinheiro e sem meios de continuar.
- Avaliar combate e roubo junto com a economia, incluindo a diferença entre novatos e veteranos e a possibilidade de concentração excessiva de recursos.
- Examinar os extremos além do caso médio: pouca sorte, muitos bônus de sorte, renda alta e vários rebirths. Apresentar hipóteses e cálculos; testes e simulações continuam sujeitos à autorização prevista neste guia.
- Tratar as primeiras tabelas como propostas de balanceamento. Só registrar o ritmo do jogo como validado após os testes e o retorno do usuário.

## Decisões pendentes
Resolver quando forem necessárias ao sistema em desenvolvimento, sem perguntar tudo de uma vez:
- Nome e direção visual do jogo.
- Raridades, tipos de chaves, baús e armas; tabelas de recompensas.
- Balanceamento final do dinheiro inicial, preços, renda das armas e custos dos upgrades. O protótipo usa saldo 0, Espada 5/s e Dragon Slayer 15/s.
- Balanceamento final dos custos e evolução dos baús. Compra comum aprovada pelo usuário; upgrades Comum -> Prata -> Ouro implementados, aguardando teste.
- Balanceamento final da frequência/preços da esteira. Protótipo implementado com ofertas a cada 6 s, 8 studs/s e compra exclusiva por ordem de aceitação no servidor.
- Slots iniciais, slots por rebirth, limite de slots e organização da base.
- Cálculo da sorte e combinação dos bônus das chaves.
- Efeito da colocação/retirada sobre renda e sorte. Interação por item equipado e ProximityPrompt já implementada e aprovada no teste do usuário.
- Mecânicas de combate, roubo e proteção de bases.
- Requisitos crescentes de rebirth e decisão final sobre o bônus de sorte.
- Salvamento, retorno de jogadores e eventual progresso offline.

## Implementação e validação — 25/10/2026
- O usuário decidiu encerrar o conceito da Loja de Poções e começar este projeto do zero.
- O AGENTS.md antigo foi removido a pedido do usuário; este documento substitui aquele contexto.
- Na etapa inicial de documentação, as regras foram organizadas a partir da conversa e ainda não havia código do novo jogo. As implementações posteriores estão registradas abaixo.
- A pasta local estava vazia antes da criação deste documento. A primeira inspeção do Studio está registrada na seção abaixo.
- Nenhum teste, simulação ou sessão de Play foi executado nesta etapa de documentação.
- Responsabilidade de balanceamento adicionada a pedido do usuário. Nenhuma tabela numérica, implementação ou teste de balanceamento foi realizado nesta etapa.
- Bases, ciclo de personagens, inventário da sessão e interação dos slots implementados. O usuário confirmou entrada/Reset e depois informou que os slots estão funcionando; multiplayer continua pendente.
- Coleta manual aprovada pelo usuário; gamepass continua desativada até receber ID. Compra e esteira reconstruída funcionando segundo o usuário; novo movimento suave com flutuação/giro aguarda teste. Multiplayer pendente. Estrutura para mutações futuras implementada, aguardando teste de regressão.

## Primeira inspeção da base no Studio — 25/10/2026
- Pedido do usuário: conectar ao Studio e conferir a estrutura de pastas da base construída por ele.
- Studio conectado: Roube um exército de anime, placeId 114249704844888. Esse é o título observado no Studio; não confirma uma decisão sobre o nome final do jogo.
- Inspeção somente de leitura, em modo Edit. Nenhum objeto do jogo foi criado, movido ou renomeado. Nenhum Play, teste ou simulação foi iniciado.
- Workspace.Bases é uma Folder e contém Base1, também uma Folder. Base1 ainda não possui atributos.
- Filhos diretos de Base1: Balconi, slots, floor, WallFlor1, Barrier, roof, Spawn e duas Parts distintas chamadas BlockBase.
- Base1 contém 182 BaseParts, todas ancoradas, e nenhum Script, LocalScript ou ModuleScript.
- Na primeira inspeção, Base1.slots continha oito Folders com a numeração Slot1, Slot2 e Slot4 até Slot9. A numeração foi corrigida para Slot1 até Slot8 na etapa abaixo. Cada slot contém uma Part chamada Part e outra chamada pedestal. A quantidade de slots construídos não confirma a quantidade de slots inicialmente liberados no jogo.
- Base1.Balconi.ChestPosition contém as Parts Chest1Middle, Chest2Left e Chest3Right, todas sem colisão.
- Base1.Spawn é um SpawnLocation ancorado, invisível, sem colisão, com Enabled e Neutral ativados. A propriedade do spawn por jogador ainda não foi implementada.
- Barrier contém laser e detail; sua presença visual não significa que exista um sistema de proteção implementado. O mesmo vale para as peças chamadas BlockBase.
- ServerScriptService, ReplicatedStorage e StarterGui estão vazios. StarterPlayer não contém scripts. O único código encontrado no Workspace foi Workspace.Rig.Animate, um LocalScript.
- ServerStorage contém PlotMoneyCollect, weapons (Sword e DragonSlayer) e Chests (DefaultChest, SilverChest e GoldChest). Esses agrupamentos são Folders; a preparação dos modelos para os sistemas ainda precisa ser avaliada.
- Workspace também contém Keys (DefaultKey, SilverKey e GoldKey), Chests e outros objetos de modelagem. Não mover ou excluir esses recursos sem necessidade e autorização de escopo.
- Recomendação restante: distinguir as duas peças BlockBase caso tenham funções diferentes; isso ainda não foi executado nem aprovado. Na inspeção posterior ao usuário duplicar as bases, Base1 a Base6 já eram Models. A correção da numeração dos slots foi solicitada pelo usuário e executada na etapa abaixo.
- Validação: apenas inspeção da hierarquia e leitura de propriedades; o funcionamento da base e dos recursos permanece pendente de implementação e testes do usuário.

## Etapa concluída — numeração dos slots (25/10/2026)
- A pedido do usuário, renomeadas as Folders em Workspace.Bases.Base1.slots: Slot4 para Slot3, Slot5 para Slot4, Slot6 para Slot5, Slot7 para Slot6, Slot8 para Slot7 e Slot9 para Slot8. Slot1 e Slot2 foram mantidos.
- Estado atual: oito slots com nomes únicos de Slot1 até Slot8, sem lacunas.
- Apenas os nomes foram alterados; posições, peças e organização interna foram preservadas.
- Verificação executada: releitura da hierarquia no Edit confirmou a quantidade e os oito nomes finais. Nenhum Play, teste de gameplay ou simulação foi executado.
- Conferência visual pendente do usuário: expandir Base1.slots no Explorer e confirmar Slot1 a Slot8; reportar qualquer nome ausente ou duplicado. Esta alteração não exige Play.

## Etapa concluída — alinhamento das seis bases (25/10/2026)
- O usuário construiu seis bases, três de cada lado do corredor central, e pediu para corrigir sua centralização. Também havia solicitado os scripts de atribuição após a duplicação; a alteração desta etapa ficou restrita ao alinhamento.
- Estado observado: Workspace.Bases contém os Models Base1 a Base6, cada um com 182 BaseParts. O usuário já converteu as bases para Model.
- Baseplate está centralizada em X=0, Z=0, com tamanho 300 por 300. A faixa central é uma Part de tamanho 297 por 12, centrada em X=0, Z=0.
- Antes da correção, as três colunas estavam em X=-89,5; -4,5; 80,5. As fileiras já tinham espaçamento igual e eram simétricas em Z.
- Aplicada translação de +4,5 studs em X aos seis Models com PivotTo. Nenhuma alteração em altura, orientação, escala, estrutura interna, peças externas às bases ou largura do corredor.
- Estado atual: Base1 e Base4 em X=-85; Base2 e Base5 em X=0; Base3 e Base6 em X=85, usando o Spawn como referência de alinhamento lateral.
- Spawns de Base1 a Base3 em Z=52,5 e de Base4 a Base6 em Z=-52,5. Distância entre colunas: 85 studs. As bases das duas fileiras permanecem frente a frente.
- Verificação executada em Edit: comparação das propriedades das 1.092 peças antes/depois confirmou a translação, rotações preservadas, tamanhos e Anchored preservados, com erro máximo de posição inferior a 0,000004 stud. Capturas de tela antes/depois foram inspecionadas.
- Nenhum Play, teste de gameplay ou simulação foi executado. Os scripts de atribuição ainda não haviam sido criados naquela etapa.
- Conferência visual pendente do usuário: olhar o mapa por cima e confirmar as três bases de cada lado, as duas bases centrais no meio do mapa e as distâncias iguais; reportar se desejava outro espaçamento ou se notar alguma peça deslocada.

## Etapa implementada — atribuição de bases e organização do código (25/10/2026)
- O usuário autorizou o assistente a escolher a organização de pastas/scripts e cuidar do código. Continuar trabalhando em um sistema por vez; perguntas de mecânica devem ser feitas quando necessárias, sem bloquear escolhas técnicas rotineiras.
- Implementados no Studio, em modo Edit:
  - ServerScriptService.Bootstrap (Script): ponto único de inicialização.
  - ServerScriptService.Config.BaseConfig (ModuleScript): parâmetros do sistema de bases, posicionamento de espera e placas.
  - ServerScriptService.Services.BaseService (ModuleScript): reserva exclusiva no servidor, sorteio uniforme entre bases livres, liberação ao sair e fila por ordem de chegada quando todas estão ocupadas.
  - ServerScriptService.Services.CharacterService (ModuleScript): carregamento inicial, posicionamento e respawn. Somente este serviço deve chamar LoadCharacterAsync.
- Fontes locais correspondentes em src/server, com as subpastas Config e Services. README.md documenta o mapeamento e TESTING.md contém o roteiro de testes. As cópias do Studio e da pasta local devem ser comparadas antes de futuras alterações; não há sincronização automática nem servidor Rojo iniciado pelo assistente.
- Não foram movidos ou renomeados recursos de construção, chaves, armas, baús ou slots. Nenhum script foi colocado dentro das bases. As seis bases continuam com 182 BaseParts cada, nas posições alinhadas anteriormente.
- A propriedade real é mantida em tabelas privadas do BaseService, com as consultas GetBase(player), GetOwner(base) e IsOwner(player, base) para futuros sistemas do servidor.
- Atributos de exibição nas bases, definidos quando o jogo inicia: BaseId, OwnerUserId, OwnerName e Occupied. Nos jogadores: BaseName e BaseStatus (Assigned, Waiting ou Leaving). Não confiar nesses atributos como autoridade de futuras compras ou interações.
- Cada jogador recebe automaticamente uma base livre antes do carregamento do personagem. O servidor define RespawnLocation explicitamente e mantém a mesma base em mortes e respawns. Não há seleção manual nem RemoteEvent nesta etapa.
- Bootstrap desativa CharacterAutoLoads durante o jogo. CharacterService respeita Players.RespawnTime, atualmente 3 segundos; impede carregamentos simultâneos e invalida tarefas antigas ao sair ou trocar de personagem. O cálculo de posicionamento considera a diferença de altura entre rigs R6 e R15.
- Quando todas as bases estão ocupadas, o jogador aparece em Workspace.GameRuntime.WaitingSpawn e entra na fila. Ao liberar uma base, o primeiro jogador presente na fila a recebe e é levado para seu Spawn, inclusive se o carregamento do avatar ainda estiver em andamento.
- GameRuntime, o Spawn de espera e as placas de identificação só são criados em tempo de execução. O ponto de espera provisório é configurado em CFrame.new(0, 0, 20), no corredor atual. Pode ser reposicionado em BaseConfig quando houver um lobby definitivo.
- A capacidade observada do Roblox é 60 jogadores, mas existem seis bases. Não alteramos a configuração pública de capacidade; a fila cobre jogadores excedentes. Definir o limite de publicação com o usuário antes de publicar.
- Placas simples mostram o número da base e o dono, ou a disponibilidade. Não foi criado um sistema de interface completo, proteção de base ou combate.
- Revisão por leitura realizada pelo assistente e por um agente revisor. Identificada e corrigida a diferença de altura de spawn do R6 antes da instalação.
- Verificações realmente realizadas: compilação sintática dos quatro arquivos com loadstring sem chamar as funções resultantes; leitura das fontes instaladas confirmou igualdade com as fontes locais; inspeção da hierarquia confirmou os quatro scripts, as seis bases preservadas e ausência de scripts dentro delas. Studio permaneceu em Edit, sem GameRuntime criado; código novo não foi requerido ou executado.
- Nenhum Play, teste automatizado, teste de gameplay, simulação ou teste multiplayer foi executado. A implementação não está validada em funcionamento.
- Testes pendentes do usuário: entrar e confirmar base/placa; Reset Character e retorno à mesma base; dois jogadores com bases distintas e respawn independente; saída liberando a base. Roteiro ampliado em TESTING.md cobre sete jogadores/fila, saída durante carregamento e R6/R15.
- Se falhar, solicitar a mensagem completa do Output do servidor e do cliente, o cenário, o número de jogadores e a base envolvida. Aguardar esse retorno antes de implementar a interação dos slots.
- Economia, inventário, abertura de baús, upgrades, sorte, combate, roubo, rebirth e salvamento continuam sem implementação nesta etapa. Nenhum valor de balanceamento desses sistemas foi definido como final.
- Referências oficiais consultadas: https://create.roblox.com/docs/reference/engine/classes/Player (LoadCharacterAsync e RespawnLocation), https://create.roblox.com/docs/reference/engine/classes/Players (CharacterAutoLoads e RespawnTime), https://create.roblox.com/docs/reference/engine/classes/SpawnLocation (Enabled e Neutral) e https://create.roblox.com/docs/reference/engine/classes/Humanoid (HipHeight).

## Retorno do primeiro Play do usuário — investigação do Output (25/10/2026)
- O usuário enviou o Output completo do trecho com BaseService pronto para seis bases, falha de ContentId rbxassetid://203785492 por tipo de asset incompatível e erro cloud_17171181036.MoonPlus.init:30 informando que Moon Animator 2 não foi carregado/instalado.
- Studio estava em Play aberto pelo usuário, com Server e Client disponíveis. O assistente apenas leu o Output e o estado da sessão existente; não iniciou, encerrou ou manipulou Play nem executou testes ou simulações.
- Observação do servidor: jogador BRbatata626 com BaseStatus=Assigned, BaseName=Base5 e RespawnLocation=Workspace.Bases.Base5.Spawn. Base5 estava ocupada pelo UserId correspondente; as outras cinco bases estavam livres. Isso confirma a inicialização e a atribuição observada nessa sessão, sem comprovar respawn, exclusividade multiplayer ou liberação ao sair.
- Busca nos scripts dos serviços do jogo e nas propriedades de conteúdo comuns, em Server e Client, não encontrou os IDs 17171181036/203785492 nem referências a MoonPlus/Moon Animator. O módulo de plugin citado no erro não foi localizado na hierarquia acessível do projeto.
- Consulta somente de leitura ao catálogo via MarketplaceService:GetProductInfoAsync identificou 17171181036 como o plugin MoonPlus. Sua descrição exige Moon Animator 2 instalado e informa que o plugin não está mais em desenvolvimento. Referência: https://create.roblox.com/store/asset/17171181036/MoonPlus.
- A mesma consulta identificou 203785492 como o áudio Pop Close Sound. O Output indica requisição incompatível com o tipo do asset, mas a propriedade/script exata que faz essa requisição ainda não foi identificada. Não atribuir essa segunda falha ao MoonPlus como fato confirmado.
- O erro do MoonPlus pertence à extensão do Studio, sem evidência de origem nos quatro scripts implementados. Orientação ao usuário: desativar MoonPlus no gerenciador de plugins e verificar se o erro desaparece; repetir a observação do ContentId para descobrir se também vinha da extensão.
- Nenhum código, asset, plugin ou configuração do jogo foi alterado nesta investigação. Não esconder o erro ou substituir IDs sem localizar o recurso responsável.
- Pendências: confirmação do usuário sobre spawn visual, Reset Character, testes com dois jogadores e liberação ao sair; confirmar desaparecimento dos erros após desativar a extensão. Interações dos slots continuam aguardando a validação das bases.

## Slots e inventário implementados — 25/10/2026
- O usuário confirmou entrada na base e Reset Character funcionando e autorizou os slots. Multiplayer, fila e liberação ao sair continuam pendentes.
- Preferência do usuário: priorizar agilidade nos sistemas simples, com conferência essencial e teste curto. Aprofundar revisão apenas em economia, salvamento, roubo ou falhas concretas.
- Adicionados Config.ItemConfig, Config.SlotConfig, Services.ItemVisuals, Services.InventoryService e Services.SlotService em ServerScriptService; SlotController em StarterPlayerScripts.
- CharacterService agora emite CharacterReady após carregar e posicionar o avatar; InventoryService restaura a mochila nesse evento. Bootstrap inicia inventário e slots antes das bases.
- ServerStorage.ItemTemplates contém cópias normalizadas de SwordM, DragonSlayerM e DefaultKey/SilverKey/GoldKey. Originais de modelagem preservados. Fontes locais em src/server e src/client.
- ProximityPrompt usa E, X ou toque: colocar o item equipado em um slot vazio e retirar o item de um slot ocupado. O servidor valida propriedade, distância de 9 studs, personagem vivo, intervalo de 0,4 segundo e a Tool registrada.
- Cada item possui UID privado do servidor e ocupa uma única localização. Atributos são somente para exibição. Transferências não cedem execução; os visuais são preparados antes da confirmação.
- Models ficam ancorados no pedestal; Tools usam Handle invisível com peças soldadas sem colisão. Não há dano, renda ou bônus de sorte nesta etapa.
- Os oito slots por base estão interativos no protótipo. Quantidade inicial e desbloqueios por rebirth continuam indefinidos.
- Somente no Studio, os cinco itens do catálogo são concedidos uma vez por jogador/sessão para permitir o teste antes das compras. Não há esse kit em servidores publicados.
- Mochila e slots persistem durante respawns da sessão, sem duplicar o kit. Ao sair, os itens são descartados e os pedestais limpos; DataStore ainda não existe.
- Conferida a sintaxe e a igualdade das fontes instaladas. Nenhum Play, teste automatizado ou simulação foi executado pelo assistente. O usuário retornou ao Edit durante a preparação.
- Retorno recebido: o usuário informou que tudo está funcionando após o roteiro dos slots. Cenários multiplayer, limpeza ao sair e inspeção de ambas as fileiras não foram confirmados separadamente e continuam pendentes.
- Teste dos slots aprovado pelo usuário; próxima etapa sugerida: renda das armas. Sorte, compras, baús, combate, roubo, rebirth e salvamento seguem pendentes.

## Retorno do usuário sobre os slots — 25/10/2026
- O usuário informou "tudo funcionando" e enviou o Output do teste. Aprovação registrada com base nesse relato, sem presumir execução de cenários multiplayer.
- Output: SlotService registrou 48 slots e BaseService registrou seis bases, sem erros desses serviços no trecho recebido.
- Persistem os avisos já investigados: MoonPlus requer Moon Animator 2; a requisição incompatível do asset de áudio 203785492 ainda não tem origem exata identificada. Não afirmar que o segundo aviso também é do MoonPlus.
- As mensagens Disconnect são compatíveis com o encerramento/desconexão da sessão e não mostram falha dos serviços implementados.
- Nesta atualização, somente a documentação foi alterada. O assistente não iniciou/encerrou Play, executou testes ou modificou código/plugins.
- Próxima etapa sugerida: implementar renda das armas colocadas, interrupção da renda ao retirar e saldo visível, com valores iniciais ajustáveis. Não há valores de balanceamento validados ainda.

## Renda das armas e saldo — versão inicial de 25/10/2026, substituída pela coleta manual abaixo
- O usuário autorizou a próxima etapa após aprovar os slots: renda automática das armas colocadas, interrupção ao retirar e saldo na tela.
- Criados ServerScriptService.Config.EconomyConfig, Services.EconomyService e StarterPlayerScripts.EconomyController. Fontes locais em src/server/Config, src/server/Services e src/client.
- ItemConfig agora centraliza IncomePerSecond: Espada 5, Dragon Slayer 15, chaves 0. São valores de protótipo; o balanceamento completo depende dos preços, probabilidades e progressão futuros.
- EconomyConfig define saldo inicial 0, atualização a cada 1 segundo e limite técnico de saldo de 1 trilhão. Não houve definição de dinheiro inicial final para a publicação.
- EconomyService mantém saldo, fração acumulada, taxa e horário em tabelas privadas do servidor. Um único relógio atualiza todos os jogadores pelo tempo real decorrido. Mudanças de taxa quitam o intervalo anterior; frações são preservadas para não perder/duplicar renda ao trocar itens rapidamente.
- SlotService recalcula a soma a partir dos slots privados do dono após colocar/retirar, incluindo apenas armas. A mochila não gera renda. Prompts ocupados mostram o nome e a taxa da arma.
- Bootstrap inicia EconomyService antes de inventário, slots e bases. Ao sair, a conta da sessão é descartada antes da liberação da base. Respawn mantém saldo e renda.
- Os atributos Money e IncomePerSecond no Player são apenas projeções para o HUD. Não há RemoteEvent de dinheiro nem pagamentos calculados pelo cliente. API atual do servidor: SetIncomeRate e GetBalance.
- HUD compacto no canto superior esquerdo mostra saldo e renda/s, atualiza por sinais dos atributos e permanece após Reset. Valores altos são abreviados na exibição.
- Instalação realizada em modo Edit. As seis fontes novas/alteradas compilaram via loadstring sem executar as funções resultantes; releitura confirmou fontes instaladas iguais às preparadas. Cópias locais atualizadas.
- Nenhum Play, simulação, teste de gameplay ou teste automatizado foi executado pelo assistente. Validação funcional e visual desta etapa pendente do usuário.
- Roteiro: iniciar com saldo/renda 0; colocar Espada para 5/s e Dragon Slayer para total 20/s; chaves não alteram renda; retirar armas reduz até 0 e para novos ganhos; Reset preserva saldo e renda. Multiplayer permanece pendente.
- Não há salvamento entre sessões, renda offline, bônus de sorte, compras ou gasto de dinheiro nesta etapa. Próximo passo: aguardar o teste do usuário antes de implementar outro sistema.

## Placa do dono no novo modelo — 25/10/2026
- O usuário alterou o modelo das seis bases e pediu a remoção das GUIs antigas, usando a placa da pasta BaseOwnerName para identificar o dono.
- Inspeção em Edit confirmou BaseOwnerName (Folder) e a Part filha Name nas seis bases; o acesso usa FindFirstChild("Name") para não confundir com a propriedade Name.
- BaseService deixou de criar BillboardGui sobre os Spawns das bases. A identificação agora é um SurfaceGui BaseOwnerSign na peça BaseOwnerName.Name, com TextLabel OwnerName.
- Criadas seis placas no Edit com texto Disponível. Face Front aponta para o corredor nas duas fileiras, conforme a rotação atual das peças. Os modelos e suas posições não foram alterados.
- Ao atribuir a base, reflectOwner mostra DisplayName e @Name; ao liberar, mostra Disponível. A propriedade continua nas tabelas privadas do BaseService.
- O serviço reutiliza as placas criadas no Edit, cria a UI se faltar e remove identificações antigas chamadas BaseOwnerLabel dos modelos. Se a peça da placa faltar, avisa no Output sem impedir a atribuição da base.
- BaseConfig agora separa OwnerSignFolderName/PartName/PixelsPerStud/MaxDistance e WaitingLabelSize/Offset/MaxDistance. O rótulo do ponto de espera continua fora das bases.
- Alterados somente BaseService, BaseConfig e as seis UIs das placas; HUD de dinheiro, slots, modelos e economia mantidos.
- Conferência realizada: sintaxe dos dois scripts, igualdade das fontes instaladas e leitura das seis placas em Front; nenhum BillboardGui restante em Workspace.Bases. Fontes locais e documentação atualizadas.
- Nenhum Play ou teste/simulação foi iniciado pelo assistente. Pendente: usuário entrar e conferir nome/@usuário na placa, ausência do rótulo flutuante e texto Disponível nas bases vagas. Liberação após saída requer confirmação multiplayer.
- A validação da renda da etapa anterior continua pendente: o pedido de alteração visual não confirma esse teste.

## Coleta manual por bloco e gamepass — 25/10/2026
- Mudança solicitada pelo usuário: armas acumulam dinheiro em cada slot; o dono precisa pisar no bloco à frente daquele slot para transferir o valor para a carteira. Coleta automática passa a ser benefício de gamepass.
- O usuário confirmou que ainda não criou a gamepass. EconomyConfig.AutoCollectGamePassId permanece 0: coleta automática desativada, sem consultas ao Marketplace e sem qualquer compra criada/disparada.
- Studio observado: Roube uma arma, mesmo placeId 114249704844888; sessão conectada d2dd71a3-fd44-4566-8798-578282089742, em Edit.
- Reutilizado o modelo artístico ServerStorage.PlotMoneyCollect: criado CollectionPadTemplate (Model) com cópias das duas peças normalizadas, chamadas CollectSurface e Border. Nenhuma peça do mapa foi movida.
- CollectionPadVisuals cria um bloco por slot durante o jogo, voltado para o espaço interno entre as duas linhas de pedestais, usando o Spawn como referência local. O bloco fica visível enquanto há produção ou moedas inteiras pendentes; SurfaceGui superior mostra COLETAR e o valor.
- SlotIncomeService mantém dono, taxa, acumulado e horário em tabelas privadas por slot. Um único relógio contabiliza tempo decorrido; mudanças de item quitam a taxa anterior para o acumulado, preservando frações.
- Coleta por toque validada no servidor: base do jogador, personagem vivo e raio para baixo confirmando que está sobre o bloco. O relógio também recolhe enquanto o dono permanece em cima, inclusive se o bloco aparecer sob ele.
- Retirar a arma interrompe a produção, mas preserva o acumulado no slot para coleta; trocar por chave não concede renda. Sobras menores que uma moeda permanecem no slot para a próxima produção. Ao sair da sessão, saldo e pendências são descartados, sem DataStore.
- EconomyService agora é a carteira, sem relógio de pagamentos automáticos. Credit devolve o valor efetivamente creditado; somente esse valor é retirado do acumulado, sem yield entre as operações e preservando excedentes caso a carteira alcance o limite.
- GamePassService consulta UserOwnsGamePassAsync no servidor quando houver ID válido; cache privado, tentativas limitadas em falhas e descarte de respostas de sessões encerradas. PromptGamePassPurchaseFinished do servidor reconhece compra concluída desse passe; atributo AutoCollectEnabled é apenas uma projeção.
- Para ativar a integração futuramente, informar o ID real em ServerScriptService.Config.EconomyConfig.AutoCollectGamePassId e iniciar nova sessão. Não foi criado botão/fluxo de compra nesta etapa.
- HUD mostra dinheiro disponível, Produção por segundo e A coletar. Money, IncomePerSecond, PendingMoney e StoredMoney são apenas informações replicadas, nunca autoridade de pagamentos.
- Bootstrap inicia EconomyService, GamePassService e SlotIncomeService antes de inventário, slots e bases; limpeza de contas, direitos e acumulados precede reutilização da base.
- Fontes novas: Services.GamePassService, Services.SlotIncomeService, Services.CollectionPadVisuals. Alteradas: EconomyService, SlotService, EconomyConfig, SlotConfig, Bootstrap e EconomyController. Nove fontes locais e no Studio conferidas.
- Verificação executada: leitura da hierarquia e scripts atuais, comparação com cópias locais, revisão estática da transferência/propriedade/limites, compilação sintática das nove fontes sem invocar as funções compiladas, releitura das fontes instaladas e inspeção do molde normalizado.
- Nenhum Play, teste automatizado, simulação ou teste de gameplay foi executado pelo assistente. Pendentes: posição/leitura dos blocos nas duas fileiras, coleta manual, preservação ao retirar/Reset, ausência de duplicação e exclusividade multiplayer. Gamepass aguarda criação, ID e teste com/sem benefício.
- Valores de produção mantidos como protótipo: Espada 5/s, Dragon Slayer 15/s, chaves 0/s. Não há validação de balanceamento, renda offline, sorte, compras de itens ou salvamento.
- Referência oficial consultada para a integração: https://create.roblox.com/docs/production/monetization/passes.
- Próxima etapa: aguardar o teste do usuário antes de avançar para outro sistema.

## Coleta aprovada e esteira de chaves implementada — 25/10/2026
- O usuário confirmou que a coleta manual funciona e autorizou avançar para a esteira. Aprovação registrada pelo relato; não presumir teste multiplayer, gamepass ou todos os cenários do roteiro.
- Inspeção do Studio em Edit encontrou a faixa central Workspace.Part (298,5 x 1 x 12 studs, posição -0,75; 0,5; 0), sem sistema de esteira existente. Ela estava desancorada.
- A faixa foi ancorada, renomeada para Belt e organizada em Workspace.KeyConveyor. CFrame, tamanho, cor e geometria preservados.
- Criados Attachments Belt.Start e Belt.Finish, com posições mundiais (-144; 2,5; 0) e (142,5; 2,5; 0). Percurso de 286,5 studs; o usuário pode editar os marcadores para ajustar o caminho.
- Novos scripts: Config.ConveyorConfig, Services.ConveyorService e StarterPlayerScripts.ConveyorController. Alterados EconomyService, InventoryService e Bootstrap. Seis fontes locais e no Studio conferidas.
- ConveyorConfig centraliza valores de protótipo: criação de uma oferta a cada 6 segundos, movimento a 8 studs/s, até 8 ofertas simultâneas, interação a 10 studs, E/X/toque com 0,25 s de espera.
- Ofertas: DefaultKey custa 100 e tem peso 70; SilverKey custa 400 e peso 25; GoldKey custa 1500 e peso 5. Pesos somam 100, portanto são chances de 70%, 25% e 5% por sorteio. Não são valores finais de balanceamento.
- Referência aritmética apenas: com Espada a 5/s, preços equivalem a 20/80/300 segundos de produção; com Espada + Dragon Slayer a 20/s, 5/20/75 segundos. Isso não inclui deslocamento, coleta, espera pela oferta, baú ou upgrades; o custo total do ciclo ainda não está balanceado.
- As chaves usam cópias dos modelos ItemTemplates e se movem ancoradas sobre a faixa. Um único Heartbeat atualiza as ofertas, com posição calculada pelo tempo decorrido; chaves não compradas são removidas ao final. Percurso atual dura cerca de 35,8 segundos.
- Runtime: Workspace.GameRuntime.ConveyorKeys. Cada oferta mostra nome/preço e ProximityPrompt. Dados públicos ItemId/Price são apenas exibição; preço, disponibilidade e tempo da oferta ficam em registros privados do servidor.
- Compra valida base atribuída, personagem vivo, distância até a posição autoritativa, validade da oferta e intervalo entre tentativas. Oferta é bloqueada durante a transação e removida após sucesso; o primeiro comprador aceito recebe a única chave.
- EconomyService.TrySpend confere e desconta saldo em operação sem yield. InventoryService.TryPurchase prepara a Tool antes de cobrar, entrega um único item registrado e devolve o dinheiro se a entrega falhar. Saldo insuficiente não cobra nem concede item, e a chave continua na esteira.
- ReplicatedStorage.Remotes.ConveyorPurchaseResult envia somente resultados do servidor para o cliente; não aceita pedidos de compra. ConveyorController exibe mensagem temporária de sucesso/erro sem decidir valores ou conceder itens.
- Bootstrap inicia ConveyorService depois das bases, com o GameRuntime já disponível. A compra usa o dinheiro coletado na carteira, não o acumulado nos slots.
- Verificações realizadas: inspeção do mapa/fontes; comparação Studio/local; leitura da transação sem yield; compilação sintática das seis fontes sem executar as funções compiladas; releitura das fontes instaladas; conferência dos marcadores e preservação da geometria da faixa.
- Nenhum Play, teste de gameplay, teste automatizado ou simulação foi executado pelo assistente. Pendentes: movimento/aparecimento/remoção, compra válida, saldo insuficiente, preservação da chave no respawn e disputa pela mesma oferta com dois jogadores.
- Compras ainda não abrem baús nem concedem sorte. Kit inicial continua exclusivo do Studio. Forma inicial de obter renda em servidores publicados, preços completos dos baús/upgrades e salvamento continuam pendentes.
- Retorno recebido: esteira funcionando segundo o usuário. Preparação de dados para mutações adicionada na etapa seguinte; compra, upgrade e abertura de baús continuam pendentes.

## Esteira aprovada e preparação para mutações — 26/10/2026
- Registrado o retorno anterior do usuário: tudo funcionando na esteira. Aprovação por relato geral; disputa multiplayer e cenários de falha não foram confirmados individualmente.
- A gravação anterior da aprovação havia sido recusada. O usuário esclareceu que recusou por engano e pediu a preparação para eventos/mutações; a documentação foi atualizada nesta retomada.
- O usuário pediu apenas preparar a estrutura. Shine (mais sorte na chave) e Double (dois itens com uma chave) ficam para implementação futura, sem valores, chances ou efeitos ativos.
- Studio inspecionado em Edit: Roube uma arma, placeId 114249704844888, sessão bb52192e-579a-4314-a35d-5500a6ab2625. A inspeção confirmou que o rascunho anterior ainda não estava instalado.
- Criados Config.MutationConfig e Services.ItemMetadata. MutationConfig registra somente os IDs/nomes Shine e Double; não define efeitos, probabilidades, cronogramas ou multiplicadores.
- ItemMetadata.Normalize aceita dados opcionais e devolve uma cópia congelada: schemaVersion=1, mutationIds (lista ordenada, sem duplicatas) e originEventId opcional. Valida versão, IDs registrados, lista contínua e formato do identificador de origem.
- originEventId registra a origem do exemplar; não representa um evento ativo nem determina duração/expiração. Um futuro gerador de eventos decidirá os dados antes de criar a oferta/recompensa.
- Cada Item privado do InventoryService agora inclui metadata. Grant(player, itemId, metadataInput?) e TryPurchase(player, itemId, price, metadataInput?) aceitam os dados do servidor; chamadas antigas continuam criando itens normais.
- A compra normaliza metadados antes de debitar; erro de dados não cobra nem entrega. Tools reconstruídas ao retirar do slot ou após respawn usam os metadados do mesmo item registrado.
- ItemVisuals.CreateTool/CreateDisplay recebem metadados opcionais. Tools, displays e pastas dos slots expõem ItemMetadataVersion, MutationIds em JSON e OriginEventId opcional, somente para exibição/inspeção. Nenhum sistema lê esses atributos para conceder características.
- ConveyorConfig.Offers admite Metadata. As três ofertas atuais usam Metadata vazio: não aparecem mutações. ConveyorService copia os dados ao criar a oferta e entrega os mesmos metadados ao comprador; a futura seleção por evento pode ser inserida antes de spawnOffer criar o exemplar.
- SlotService conserva os dados do item no display/slot e limpa a projeção quando o slot fica vazio. O inventário continua sendo a fonte de verdade.
- Alterados InventoryService, ItemVisuals, SlotService, ConveyorService e ConveyorConfig; somados aos dois módulos novos, sete fontes instaladas e salvas localmente. Nenhum novo serviço de inicialização ou RemoteEvent foi necessário.
- Verificações executadas: leitura do Studio/local, comparação das fontes antes da alteração, conferência do repasse de metadados, compilação sintática das sete fontes sem executar as funções compiladas e releitura das fontes instaladas. Nenhum Play, simulação ou teste automatizado/gameplay executado.
- Pendente do usuário: comprar chave normal, colocar/retirar do slot e usar Reset, verificando preservação do item e ausência de erros. Os dados não vazios e os efeitos serão validados quando as mutações forem ativadas futuramente.
- O sistema segue sem DataStore: metadados são preservados apenas na sessão. Sorte, recompensas duplas, visuais de mutação e eventos programados ainda não foram implementados.
- A estrutura ficou pronta para a futura integração dos baús; esta etapa não implementa compra/upgrade/abertura de baús.

## Adaptação à esteira reconstruída — 26/10/2026
- O usuário reconstruiu a esteira e pediu que os itens passem por ela.
- Inspeção em Edit encontrou Workspace.treadmill (Folder), com a Part treadmill (300 x 0,0990121 x 11 studs) e duas bordas em Detail. A antiga pasta KeyConveyor não existe mais.
- ConveyorConfig agora usa FolderName=treadmill e BeltName=treadmill. ConveyorService continua usando os marcadores configurados; apenas a mensagem de validação foi ajustada para mostrar os nomes atuais.
- As três peças estavam desancoradas e foram ancoradas. Posições, tamanhos, cores e nomes da construção preservados.
- Criados Start e Finish como Attachments na Part treadmill, com margem de 6 studs nas pontas e altura de 1,5 stud acima da superfície. Coordenadas mundiais aproximadas: Start (-144; 2,099006; 0), Finish (144; 2,099006; 0).
- Percurso atual de 288 studs, da esquerda para a direita no eixo X; a 8 studs/s dura 36 segundos. Preços, frequência, compras e preparação de metadados permanecem como antes.
- Verificações: leitura do mapa/fontes, comparação Studio/local, compilação sintática dos dois scripts sem executar as funções compiladas, releitura das fontes instaladas e conferência da geometria preservada e dos marcadores.
- Nenhum Play, teste ou simulação foi iniciado pelo assistente. Pendente do usuário: observar chaves percorrendo o centro da nova esteira, altura visual, desaparecimento no final e compra funcionando.
- Fontes locais, README e roteiro atualizados. A adaptação visual não confirma testes pendentes de metadados ou multiplayer.

## Movimento suave, flutuação e giro na esteira — 26/10/2026
- O usuário confirmou que a esteira reconstruída funciona, relatou pequenos saltos no movimento e pediu animação de flutuação/giro.
- Inspeção em Edit confirmou movimento por PivotTo no servidor a 30 Hz e Workspace.StreamingEnabled=true. As atualizações de posição replicadas eram a apresentação visível anterior.
- Adicionado StarterPlayerScripts.ConveyorAnimationController, com fonte src/client/ConveyorAnimationController.client.luau. ConveyorService e ConveyorConfig ajustados.
- Cada cliente cria uma cópia visual local da oferta e a anima em um único PreRender, usando o tempo sincronizado GetServerTimeNow e o percurso publicado pelo servidor. O visual deixa de depender das posições discretas recebidas pela rede.
- Os offsets ConveyorLocalCFrame das peças são definidos na criação da oferta; a cópia é reconstruída por esses offsets para não deformar a chave ao receber posições de instantes distintos.
- A geometria original fica oculta somente no cliente por LocalTransparencyModifier. Cópias locais ficam ancoradas, sem colisão, toque, query, scripts, prompts ou GUIs duplicados.
- O prompt original é mantido; apenas sua âncora recebe correção local na posição linear do percurso. A placa de preço aponta para a cópia visual. O servidor continua validando distância, saldo, disponibilidade e entrega pelas próprias tabelas.
- Configuração inicial: FloatAmplitude=0,35 stud, FloatPeriod=2,5 segundos e SpinDegreesPerSecond=45 (volta completa em 8 segundos). Fase inicial varia por oferta. Velocidade de avanço, preços e chances mantidos.
- Servidor e cliente usam GetServerTimeNow como referência temporal. O servidor continua atualizando o modelo autoritativo e publica os dados de animação antes de inseri-lo no Workspace.
- ModelStreamingMode.Atomic garante que a estrutura inicial da oferta entre junta. Controlador registra adição/remoção, prepara visuais quando os dados chegam, limpa na saída pelo streaming/compra e recria quando necessário.
- Ao expirar localmente, oculta o visual/prompt até chegar a remoção do servidor, evitando reaparecimento do modelo original. Conexões e cópias são limpas no encerramento do controlador.
- Verificações executadas: leitura do Studio/local, consulta às referências oficiais, conferência de arquitetura e ciclo de vida, compilação sintática das três fontes sem invocar as funções compiladas e releitura das fontes instaladas.
- Nenhum Play, teste de gameplay, simulação ou teste automatizado foi executado pelo assistente. Fluidez, aparência, compra em movimento e entrada/saída pelo streaming aguardam teste do usuário.
- Referências consultadas: https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow ; https://create.roblox.com/docs/reference/engine/classes/RunService#PreRender ; https://create.roblox.com/docs/reference/engine/classes/BasePart#LocalTransparencyModifier ; https://create.roblox.com/docs/workspace/streaming#atomic.

## Compra e colocação de baús — 26/10/2026
- O usuário autorizou a proposta de comprar um baú comum por interação nos três espaços vazios do balcão da própria base. Esta etapa implementa somente compra/colocação; upgrades, abertura, sorte e recompensas continuam para etapas posteriores.
- Antes de programar, inspecionados Studio em Edit, fontes atuais, seis bases e ServerStorage.Chests. As fontes existentes envolvidas foram comparadas com as cópias locais; estavam iguais, desconsiderando finais de linha.
- Cada base mantém Balconi.ChestPosition com Chest1Middle, Chest2Left e Chest3Right. São 18 posições previstas. Nenhum marcador, balcão ou recurso original foi movido/renomeado.
- Criados Config.ChestConfig, Services.ChestVisuals, Services.ChestService e StarterPlayerScripts.ChestController. Bootstrap inicia ChestService antes de BaseService, para registrar a limpeza antes da liberação/reatribuição de uma base.
- ConveyorController agora reaproveita a mesma notificação de compra para ConveyorPurchaseResult e ChestPurchaseResult; ScreenGui chama-se PurchaseNotifications. Ambos os remotes apenas enviam resultados do servidor ao cliente.
- Durante o jogo, ChestService cria BuyChest e ChestLabel nos marcadores e a pasta ChestDisplays em cada base. E/X/toque, segurando por 0,35 s, compra no espaço selecionado. Preço aparece na placa e no prompt antes da compra; cliente oculta placas/prompts de bases alheias e desativa a compra em espaço ocupado.
- Preço provisório centralizado do baú comum: $50. Com a renda atual, equivale a 10 s de uma Espada (5/s) ou 2,5 s de Espada + Dragon Slayer (20/s), sem contar deslocamento/coleta. Chave comum + baú somam $150, equivalentes a 30 s ou 7,5 s nessas mesmas condições. São contas diretas dos parâmetros, não simulações nem ritmo validado; retorno do investimento depende das recompensas ainda indefinidas.
- Servidor valida jogador presente, propriedade privada do BaseService, personagem vivo, distância de 9 studs, intervalo de 0,4 s, espaço vazio e saldo coletado. Dinheiro acumulado nos slots não pode ser gasto antes da coleta.
- Modelo e metadados são preparados antes do débito. Verificação, débito, registro e entrega não cedem execução; falha de entrega remove o registro/modelo e devolve o valor. Interações repetidas não compram outro baú no mesmo espaço.
- Cada baú tem UID, chestId, dono, metadados congelados e visual em registro privado do ChestService. Chests.DefaultChest.KeyId corresponde a DefaultKey, preparado para a abertura futura, sem implementar consumo/sorteio agora. Atributos ChestUid, ChestId, ChestOccupied, OwnerUserId e metadados servem somente à apresentação/inspeção.
- Modelo usado: ServerStorage.Chests.DefaultChest.DefaultChestM (73 peças, sem scripts/constraints), clonado em tempo de execução. Escala 0,30 e rotação local -90 graus; frente voltada ao jogador nas duas fileiras. O deslocamento SurfaceOffset=-1 considera o marcador 1 stud acima do balcão. Cópias ficam ancoradas, sem colisão/toque/query, com streaming Atomic; originais preservados.
- Baús permanecem após Reset na mesma sessão. PlayerRemoving limpa os registros e visuais antes de outra pessoa receber a base. Não há inventário transportável de baús, venda, salvamento entre sessões, rebirth ou abertura nesta etapa.
- Conferências realmente realizadas: inspeção de hierarquia/geometria/fontes; leitura do fluxo de compra, limpeza e propriedade; compilação sintática das seis fontes sem executar as funções resultantes; comparação das fontes instaladas e cópias locais. Não foram executados Play, testes de gameplay, testes automatizados ou simulações.
- Validação pendente do usuário: compra sem saldo; coleta e compra por $50; um baú por espaço e ausência de cobrança repetida; visual apoiado nas duas fileiras; Reset preservando baú. Multiplayer (compra apenas pelo dono e limpeza/reatribuição ao sair) pendente.
- O avanço autorizado não constitui confirmação específica do teste da animação da esteira nem dos casos multiplayer anteriores.
- Referências oficiais consultadas: https://create.roblox.com/docs/reference/engine/classes/Model#ScaleTo e https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt#Triggered.

## Upgrades de raridade dos baús — 26/10/2026
- O usuário informou "tudo certo pode seguir", aprovando o funcionamento da compra/colocação e autorizando a próxima etapa: upgrades. Esse relato não confirma separadamente os cenários multiplayer ou testes antigos da esteira.
- Inspeção em Edit e comparação Studio/local realizadas antes de alterar. DefaultChestM, SilverChestM e GoldChestM são Models com 73 peças cada, tamanho original 12 x 13 x 21, escala 1 e pivot no centro, sem scripts. Seis bases mantêm três marcadores cada; modelos e construção originais preservados.
- ChestConfig agora define a cadeia DefaultChest -> SilverChest -> GoldChest e suas chaves correspondentes. Valores provisórios: compra comum $50, Comum -> Prata $150, Prata -> Ouro $550. Ouro é o máximo do catálogo atual; não há compra direta dos níveis superiores.
- Custo acumulado do baú: $50/$200/$750. Somando chave comum/prata/ouro ($100/$400/$1500), os custos para as futuras aberturas são $150/$600/$2250. Crescimento de 4x e depois 3,75x; sem tabela de recompensas ainda não é possível validar retorno ou ritmo final. Contas diretas, sem simulações.
- Compra continua E/X/toque. Melhoria usa F/Y/toque, segurando por 0,6 s. Prompt mostra próxima raridade e custo; placa mostra raridade atual e custo da melhoria. Em ouro, mostra Raridade máxima e não oferece melhoria.
- Cada passagem tem seu próprio prompt fixo, habilitado somente na raridade de origem. Callback guarda fromId e compara com o registro privado; um evento atrasado da passagem Comum -> Prata não compra também Prata -> Ouro.
- Reaproveitada a validação de dono da base, vida, distância de 9 studs e intervalo de 0,4 s; upgrade confere também dono do exemplar, raridade atual e saldo coletado no servidor. Sem saldo, não cobra nem altera o baú.
- Novo visual preparado antes da cobrança com o mesmo UID, dono e metadados. O upgrade muda apenas chestId/model no mesmo registro. Origem/mutações futuras não são substituídas pelos padrões do próximo tipo.
- Transação não cede execução: debita, coloca novo visual e atualiza o registro/placa; só depois destrói o visual antigo. Se a confirmação falhar, restaura raridade/visual anteriores, destrói apenas o novo e devolve o dinheiro.
- Validação na inicialização cobre todos os modelos, chaves, custos, escala, ligações e ausência de ciclos na sequência. ChestVisuals já atende às três versões, mantendo escala 0,30 e orientação nas duas fileiras.
- Alterados somente ChestConfig, ChestService e ChestController. Prompts usam ActionAvailable para apresentação, em lugar de PurchaseAvailable; cliente reconhece BuyChest e UpgradeChest_*. Resultado de melhoria usa a notificação existente ChestPurchaseResult. Não há novo RemoteEvent de solicitação.
- Reset conserva upgrades na sessão. A limpeza ao sair continua registrada antes do BaseService liberar a base; não há salvamento entre sessões.
- Conferências realizadas: leitura da hierarquia/fontes e fluxo de cobrança/reversão, compilação sintática das três fontes sem executar as funções compiladas, comparação das fontes instaladas e salvas. Nenhum Play, teste automatizado/gameplay ou simulação executado pelo assistente.
- Pendente do usuário: custo/modelo em cada melhoria, falta de saldo sem perda, ouro sem nova cobrança, persistência no Reset e visual nas duas fileiras. Propriedade/limpeza multiplayer e preservação com metadados não vazios continuam pendentes.
- Abertura/consumo de chave e baú, recompensas e sorte ainda não implementados. Aguardar validação dos upgrades antes da próxima etapa.

## Falha de inicialização: tipo de Base1 — 27/10/2026
- O usuário relatou que tudo parou. Lidos Output completo, SlotService e hierarquia do servidor na sessão de Play já aberta pelo usuário.
- Erro observado: Bootstrap:30 / SlotService:108, "Base1: pasta slots ausente". A pasta slots existia com oito slots; a condição também verificava base:IsA("Model"). Base1 era Folder, enquanto Base2 a Base6 eram Models. Isso interrompeu a inicialização antes de ChestService, BaseService e ConveyorService.
- Os avisos de espera por Remotes e GameRuntime são compatíveis com essa interrupção. Os erros já conhecidos de MoonPlus e ContentId 203785492 não foram alterados nem considerados causa dessa falha.
- O usuário autorizou explicitamente "Pode encerrar o Play por mim"; o assistente encerrou somente a sessão existente para editar. Não iniciou outra sessão nem executou testes/simulações.
- Primeira inspeção em Edit ainda encontrou Base1 como Folder. Antes da tentativa de conversão, a estrutura mudou para Model; a checagem anterior à escrita interrompeu a operação sem alterar modelos ou peças. Não atribuir essa conversão ao assistente.
- Releitura confirmou Base1 a Base6 como Models, 48 slots com pedestais, seis Spawns e três posições de baús por base. Não foi necessário converter/reconstruir bases.
- SlotService agora separa a validação do tipo da base da existência da pasta slots. Uma base que não seja Model informa explicitamente o tipo encontrado, evitando a mensagem enganosa.
- Conferências realizadas: fontes do Studio/local iguais antes da alteração, leitura da hierarquia atual, compilação sintática sem chamar a função compilada e comparação da fonte instalada/salva. A correção do contrato de classe foi observada; retorno dos sistemas em Play ainda aguarda o usuário.
- Próximo teste: iniciar Play e conferir base atribuída, slots, coleta, chaves na esteira e baús/upgrades. Se falhar, enviar o primeiro erro completo do Output. Não avançar para abertura dos baús enquanto esta retomada não estiver confirmada.
