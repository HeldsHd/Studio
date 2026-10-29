# Código do jogo

Bases, slots, inventário da sessão, renda das armas e saldo na tela estão implementados. Coleta manual, esteira e compra de chaves foram aprovadas pelo usuário em relatos de funcionamento. Compra e colocação de baús comuns aprovadas pelo usuário. Upgrades de raridade implementados, aguardando teste. Abertura e salvamento continuam pendentes.

## Organização

| Fonte local | Objeto no Studio | Responsabilidade |
| --- | --- | --- |
| src/server/Bootstrap.server.luau | ServerScriptService.Bootstrap (Script) | Inicialização dos sistemas. |
| src/server/Config/BaseConfig.luau | ServerScriptService.Config.BaseConfig (ModuleScript) | Configuração privada do sistema de bases. |
| src/server/Services/BaseService.luau | ServerScriptService.Services.BaseService (ModuleScript) | Propriedade exclusiva, disponibilidade e fila de espera. |
| src/server/Services/CharacterService.luau | ServerScriptService.Services.CharacterService (ModuleScript) | Carregamento de personagens, posicionamento e respawn. |

A pasta src contém as fontes locais para manutenção. Os mesmos conteúdos são instalados no Studio pelo assistente. Não existe sincronização automática: antes de editar, comparar com os scripts atuais do Studio e incorporar qualquer alteração feita lá. Não iniciar um servidor Rojo sem combinar o fluxo de trabalho.

Os modelos de construção e os recursos artísticos continuam nos locais preparados pelo usuário. Esta etapa não move nem reorganiza chaves, armas e baús.

## Contrato do mapa

- Workspace.Bases é uma Folder.
- Cada filho é um Model chamado Base1, Base2, etc., com identificador numérico único e positivo.
- Cada base tem um SpawnLocation chamado Spawn, como filho direto.
- As seis bases atuais estão em duas fileiras, com oito slots construídos cada uma.
- A estrutura interna de slots, balcão, baús e barreiras permanece sob responsabilidade de seus futuros sistemas.

Cada base identifica seu dono na peça BaseOwnerName.Name, com SurfaceGui BaseOwnerSign e TextLabel OwnerName. A placa mostra nome e @usuário, ou Disponível quando não há dono; não há BillboardGui nos Spawns das bases. O servidor cria Workspace.GameRuntime.WaitingSpawn com seu próprio rótulo de espera, configurado em BaseConfig.

## Comportamento

- Uma base livre é sorteada para cada jogador.
- A reserva é feita sem esperas antes de iniciar o carregamento do personagem.
- A base permanece atribuída durante mortes e respawns, até o jogador sair do servidor.
- Todos os carregamentos de personagem passam pelo CharacterService; Players.CharacterAutoLoads fica false durante o jogo.
- O intervalo de respawn usa Players.RespawnTime, atualmente 3 segundos no Studio.
- Se todas as bases estiverem ocupadas, novos jogadores aparecem no ponto de espera e entram numa fila por ordem de chegada.
- Uma base liberada é atribuída automaticamente ao primeiro jogador presente na fila.
- A configuração atual de capacidade do Roblox é de 60 jogadores, embora existam apenas seis bases. Ajustar a capacidade pública em Game Settings quando o usuário decidir o limite; esta etapa não altera essa configuração.
- Nenhuma informação desta etapa é salva entre servidores ou sessões.

## Integração com outros sistemas

Outros módulos do servidor devem usar BaseService.GetBase(player), BaseService.GetOwner(base) e BaseService.IsOwner(player, base). Não alterar as tabelas internas nem atribuir bases pelo cliente.

Os atributos BaseId, OwnerUserId, OwnerName e Occupied nos Models e BaseName/BaseStatus nos jogadores são apenas informações replicadas para exibição. BaseStatus usa Assigned, Waiting e Leaving. Bases vazias usam OwnerUserId=0; isso não substitui a consulta ao serviço, inclusive nos testes locais com UserIds negativos.

Novos sistemas devem adicionar seus próprios módulos em Services e configurações em Config, sendo inicializados explicitamente pelo Bootstrap. Configurações que o cliente precisar conhecer poderão ir para ReplicatedStorage.Shared quando houver um consumidor real. Remotes e controladores de cliente serão criados quando necessários.

O servidor continuará responsável por toda alteração de dinheiro, inventário, sorte, baús, propriedade e progressão. Os valores de balanceamento ficarão em tabelas específicas, sem espalhar números pelos serviços.

## Validação

Consulte TESTING.md. Não foi executado Play, teste de gameplay, teste automatizado ou simulação nesta implementação. A revisão de código e a conferência de sintaxe não substituem os testes do usuário.

## Referências

- https://create.roblox.com/docs/reference/engine/classes/Player#LoadCharacterAsync
- https://create.roblox.com/docs/reference/engine/classes/Player#RespawnLocation
- https://create.roblox.com/docs/reference/engine/classes/Players#CharacterAutoLoads
- https://create.roblox.com/docs/reference/engine/classes/SpawnLocation#Enabled
- https://create.roblox.com/docs/reference/engine/classes/Humanoid#HipHeight

## Slots e inventário
Config/ItemConfig define o catálogo; Config/SlotConfig define a interação. Services/ItemVisuals cria Models/Tools, InventoryService controla os itens da sessão e SlotService controla pedestais. src/client/SlotController.client.luau corresponde a StarterPlayerScripts.SlotController.

ServerStorage.ItemTemplates guarda cópias dos cinco modelos. Equipar item + E coloca; E no slot ocupado retira. X/toque usam o prompt padrão. Só o dono pode interagir.

CharacterService.CharacterReady restaura a mochila após LoadCharacterAsync. InventoryService.Grant(player, itemId) será usado pelas compras/recompensas. O kit de cinco itens é exclusivo do Studio, concedido uma vez por sessão. Itens persistem em respawns, mas não entre sessões. A renda das armas está conectada; sorte ainda não está implementada.

## Renda e coleta
EconomyConfig define saldo inicial, intervalo, limite técnico e AutoCollectGamePassId. ItemConfig.Items[itemId].IncomePerSecond define a produção: Espada 5/s, Dragon Slayer 15/s, chaves 0/s, valores de protótipo.

SlotIncomeService acumula dinheiro por slot com um relógio no servidor. CollectionPadVisuals usa ServerStorage.CollectionPadTemplate, copiado do modelo PlotMoneyCollect, para mostrar o bloco e o valor pendente. O dono coleta pisando sobre o bloco; toque e posição são validados no servidor. Retirar a arma para a produção e mantém o acumulado para coleta.

EconomyService controla a carteira, sem pagamentos automáticos. Credit(player, amount) retorna quanto foi realmente creditado, para debitar o acumulado sem duplicação ou descarte de excedentes. Money, IncomePerSecond, PendingMoney e StoredMoney são projeções para exibição.

GamePassService consulta a propriedade do passe no servidor. AutoCollectGamePassId=0 mantém o benefício desligado; o usuário ainda vai criar a gamepass. Depois de informar o ID real, iniciar nova sessão. Não foi criado botão de compra. Referência: https://create.roblox.com/docs/production/monetization/passes.

EconomyController mostra saldo, Produção/s e A coletar. Dinheiro e acumulados permanecem no respawn, mas são descartados ao sair; não há DataStore nem renda offline. Validação funcional e visual pendente do usuário.

## Esteira de chaves
Workspace.treadmill.treadmill é a esteira atual, com as três peças ancoradas; Attachments Start e Finish definem o percurso de 288 studs. ConveyorConfig configura velocidade, frequência, limite de ofertas, distância, preços e pesos por chave. O usuário confirmou o funcionamento na esteira reconstruída; o novo movimento suave e a animação aguardam teste em Play.

ConveyorService cria cópias dos modelos das chaves em GameRuntime.ConveyorKeys e controla posição, disponibilidade e expiração no servidor. E/X/toque compra uma oferta ainda disponível: confere base, vida, distância e saldo, bloqueia a oferta e entrega a Tool registrada. O cliente recebe somente o resultado via Remotes.ConveyorPurchaseResult e mostra uma mensagem.

EconomyService.TrySpend e InventoryService.TryPurchase concluem débito/entrega sem yield, preparando o modelo antes da cobrança e reembolsando falhas de entrega. Dinheiro pendente dos slots precisa ser coletado antes de comprar. Não há salvamento entre sessões nem abertura de baús nesta etapa.

Valores de protótipo: comum $100 (70%), prata $400 (25%), ouro $1500 (5%); uma oferta a cada 6 s, 8 studs/s, máximo 8 simultâneas. Todos precisam ser calibrados junto dos baús. Coleta manual e esteira aprovadas pelo usuário; multiplayer e balanceamento final continuam pendentes.

## Dados para eventos e mutações futuras
ItemMetadata define dados por exemplar: schemaVersion, mutationIds e originEventId opcional. A lista é validada, ordenada e copiada para tabelas congeladas. MutationConfig reserva Shine e Double apenas como cadastro; nenhum bônus, sorteio ou evento está ativo.

InventoryService.Grant e TryPurchase recebem metadados opcionais como último argumento. O servidor guarda os dados no item registrado e os preserva nas Tools, nos slots e no respawn. ConveyorConfig.Offers[].Metadata permite definir dados da oferta antes de sua criação; atualmente todas as ofertas têm Metadata vazio. O evento de origem permanece no exemplar e não equivale a um evento ativo.

ItemMetadataVersion, MutationIds e OriginEventId são atributos de inspeção/exibição, nunca a autoridade para efeitos ou recompensas. Não há salvamento entre sessões. Futuras transferências e abertura de baús devem usar o registro do inventário, preservando UID/metadados. Efeitos, chances e regras de combinação serão implementados depois.

## Animação da esteira
ConveyorAnimationController cria a apresentação local das chaves e atualiza percurso, flutuação e giro em PreRender usando GetServerTimeNow. Os offsets das peças publicados na criação evitam depender das posições recebidas em pacotes separados.

ConveyorService preserva o modelo e o prompt autoritativos; compras continuam no servidor. Ofertas usam streaming Atomic e as cópias locais são limpas ao comprar, expirar ou sair da região carregada. No cliente, a geometria original fica oculta e a placa de preço acompanha o visual.

Ajustes em ConveyorConfig: FloatAmplitude=0.35, FloatPeriod=2.5 e SpinDegreesPerSecond=45. A fluidez e aparência da animação aguardam teste no Play.

## Compra de baús

Config/ChestConfig concentra o preço provisório ($50), chave correspondente, modelo, escala e interação. Services/ChestVisuals clona DefaultChestM; Services/ChestService controla compra e exemplares privados. src/client/ChestController.client.luau corresponde a StarterPlayerScripts.ChestController, que apresenta os prompts/placas apenas ao dono, inclusive após streaming.

Os três marcadores Balconi.ChestPosition (Chest1Middle, Chest2Left e Chest3Right) recebem prompts E/X/toque durante o jogo. O dono compra um baú comum diretamente no espaço livre; a carteira precisa ter dinheiro já coletado. Cada espaço admite um baú. O servidor valida dono, vida, distância, saldo e disponibilidade, prepara o modelo antes de cobrar e reembolsa falha de entrega.

ChestDisplays guarda as cópias visuais em cada base. UID, dono, tipo e metadados permanecem em registros privados do servidor; atributos são projeções. Reset conserva o baú; sair descarta os baús antes de liberar a base. Não há DataStore, abertura, upgrades nem sorte nesta etapa.

Bootstrap inicia ChestService antes de BaseService. ConveyorController compartilha o toast PurchaseNotifications entre os eventos ConveyorPurchaseResult e ChestPurchaseResult; não envia pedidos de compra por RemoteEvent.

Fontes instaladas e sintaxe conferida sem executar o jogo. Compra, aparência e multiplayer aguardam teste do usuário; roteiro em TESTING.md.

## Upgrades de baús

ChestConfig define NextChestId e UpgradePrice: Comum -> Prata ($150) -> Ouro ($550). Somando a compra inicial de $50, cada baú custa $50/$200/$750 conforme a raridade final. Preços provisórios, ainda dependentes do balanceamento das recompensas.

F/Y/toque melhora uma raridade por acionamento; o prompt informa o destino e custo. Em ouro, a placa indica o máximo atual e o upgrade fica indisponível. Compra permanece E/X/toque. ChestController usa ActionAvailable para ocultar ações indisponíveis ou de outras bases.

ChestService valida e cobra no servidor, preservando UID/dono/metadados. Prepara o novo visual antes de debitar e conserva o antigo até concluir; falha reverte e reembolsa. Prompts separados por passagem rejeitam eventos atrasados de outra raridade. Reset preserva a melhoria; sair descarta os baús da sessão.

Sintaxe e fontes conferidas; funcionamento dos upgrades aguarda teste. Abertura, sorte e salvamento seguem pendentes.
