# Roteiro de testes — bases

Status: pendente de execução pelo usuário. O assistente não inicia nem encerra Play.

## 1. Entrada individual

Iniciar Play. Resultado esperado: aparecer no Spawn de uma das seis bases, com placa identificando seu nome. No lado do servidor, o Player deve ter BaseStatus=Assigned e BaseName igual à base recebida; o Model dessa base deve ter Occupied=true e OwnerUserId igual ao UserId do jogador. Bases vazias ficam com Occupied=false.

No Output do servidor deve aparecer a mensagem de BaseService com seis bases registradas, sem erros.

## 2. Morte e respawn

Anotar a base atribuída e usar Reset Character. Resultado esperado: após o intervalo de Players.RespawnTime e o carregamento do avatar, voltar para a mesma base. Repetir algumas vezes e confirmar que não aparecem personagens duplicados nem há troca de dono.

## 3. Exclusividade com dois jogadores

Usar o modo de servidor local com dois jogadores. Resultado esperado: bases diferentes, placas correspondentes e respawn independente. Verificar tanto a perspectiva do dono quanto a do outro jogador.

## 4. Saída e liberação

Com dois jogadores, sair de um cliente sem encerrar o servidor. Resultado esperado: sua base fica disponível e o outro jogador mantém sua própria base. Ao entrar um novo jogador, ele recebe uma base livre.

## 5. Capacidade e fila — opcional nesta primeira rodada

Com sete jogadores no mesmo servidor local, seis recebem bases distintas e o sétimo aparece no ponto de espera, com BaseStatus=Waiting e BaseName vazio. Ao sair um dos seis donos, o jogador em espera recebe a base liberada e é levado para o Spawn dela.

Com dois jogadores esperando, a ordem de atendimento deve seguir a ordem de chegada. Um jogador em espera que sair não pode continuar ocupando a fila.

Se o jogo permitir tanto avatares R6 quanto R15, repetir entrada e respawn nos dois tipos e confirmar que os pés ficam acima do piso.

## 6. Saída durante carregamento ou respawn — após a rodada básica

Sair de um cliente enquanto ele carrega o personagem ou aguarda o respawn. Resultado esperado: a base fica livre e tarefas atrasadas não mudam o dono nem levam outro jogador para ela.

## O que reportar se falhar

Enviar a mensagem completa do Output do servidor e do cliente, informar qual cenário falhou, o número de jogadores, a base recebida e o que ocorreu. Se o problema for de posicionamento ou placa, incluir uma captura de tela.

## Slots — funcionamento aprovado pelo usuário em 25/10/2026
Entrada e Reset das bases foram confirmados pelo usuário. Após o roteiro abaixo, ele informou que tudo está funcionando e enviou o Output com 48 slots e seis bases registrados. A aprovação corresponde ao relato geral; multiplayer, limpeza ao sair e as duas fileiras não foram confirmados individualmente e seguem pendentes. Nenhum teste foi executado pelo assistente.

1. Em Play, conferir Espada, Dragon Slayer e três chaves na mochila.
2. Equipar item e segurar E perto de um pedestal próprio: sai da mochila e aparece no slot.
3. E no slot ocupado: volta uma única vez à mochila. Repetir com arma/chave.
4. Deixar itens na mochila e nos slots; Reset deve preservar a separação, sem novo kit.
5. Conferir modelos na outra fileira e rejeição em base alheia com dois jogadores. Ao sair, os slots devem ser limpos.

Se falhar, informar item, slot, ação e Output completo. Renda implementada na etapa seguinte, com roteiro abaixo. Sorte e dano ainda não estão implementados.

## Renda e coleta manual — funcionamento aprovado pelo usuário em 25/10/2026
Aprovação por relato geral; multiplayer e gamepass não foram confirmados.
1. Iniciar Play e colocar Espada em um slot. Deve aparecer o bloco de coleta à frente, para dentro da base. A produção mostra $5/s e A coletar aumenta; a carteira fica parada enquanto estiver longe do bloco.
2. Pisar no bloco: o acumulado daquele slot entra na carteira uma única vez. Permanecer em cima continua recolhendo; sair dele volta a acumular. Repetir com Dragon Slayer ($15/s), incluindo a outra linha de slots.
3. Acumular e retirar a arma sem pisar no bloco: a produção para e o valor fica disponível para coleta. Trocar por chave não gera dinheiro. Sem arma e sem moedas inteiras pendentes, o bloco desaparece.
4. Deixar saldo na carteira e pendências no slot; usar Reset Character: ambos permanecem. Repetir colocar/retirar/coletar rapidamente não deve criar dinheiro extra.
5. Com dois jogadores, pisar no bloco alheio não coleta nem altera o saldo dos jogadores. Ao sair e reutilizar a base, não pode sobrar dinheiro do dono anterior.

Gamepass: desativada com ID 0, conforme confirmado pelo usuário. Após criar/configurar o ID, testar um proprietário coletando à distância e outro sem o passe acumulando normalmente; confirmar benefício após compra válida e ausência dele ao cancelar/falhar.

Se falhar, enviar Output completo, base/slot, ação, saldo e valor pendente observados. Ao encerrar Play e abrir outra sessão, os valores zeram porque não há salvamento ainda.

## Placas BaseOwnerName — pendente do usuário
1. No Edit, conferir texto Disponível na placa de cada base, voltado para o corredor.
2. Em Play, a placa da própria base deve mostrar seu nome e @usuário; bases vagas devem mostrar Disponível. Não deve haver identificação flutuando sobre o Spawn.
3. Quando testar com dois jogadores, sair de um cliente mantendo o servidor: a placa da base liberada deve voltar a Disponível ou mostrar o novo dono se houver alguém esperando.

Se falhar, informar a base, qual lado da placa foi observado e enviar o Output. A alteração visual não conclui o teste da renda.

## Esteira de chaves — funcionamento aprovado pelo usuário, registrado em 26/10/2026
Aprovação por relato geral; disputa multiplayer e cada cenário de falha não foram confirmados separadamente.
1. Iniciar Play: chaves devem surgir e atravessar a faixa central, com nome/preço; uma nova oferta aproximadamente a cada 6 segundos. Uma chave que ninguém compra desaparece após cerca de 36 segundos de percurso.
2. Antes de coletar dinheiro, tentar comprar uma chave: mensagem de saldo insuficiente, sem desconto/entrega; a oferta continua passando.
3. Colocar armas e coletar pelo menos $100. Aproximar-se de uma chave comum e segurar E: desconta exatamente $100, entrega uma única chave na mochila e remove aquela oferta. Preços atuais: prata $400, ouro $1500.
4. Colocar/retirar a chave comprada em um slot e usar Reset: o item deve permanecer sem duplicar. Comprar de muito longe ou morto não deve funcionar.
5. Quando testar com dois jogadores, disputar a mesma oferta: apenas um recebe a chave e é cobrado. Os saldos/inventários dos dois devem permanecer independentes.

Se falhar, enviar Output completo, chave/preço, saldo antes/depois e o que ocorreu. A frequência das raridades é aleatória; ainda não há abertura de baús nem salvamento entre sessões.

## Preparação de mutações — regressão pendente do usuário, 26/10/2026
1. Comprar uma chave normal na esteira: deve descontar o mesmo preço e entregar um único item normal.
2. Colocar e retirar essa chave de um slot; usar Reset: o item deve continuar disponível sem duplicar ou causar erros.
3. Se inspecionar os atributos da Tool/display/slot no servidor: ItemMetadataVersion=1, MutationIds=[] e sem OriginEventId nas ofertas atuais. Isso é apenas projeção dos dados privados.

Nenhuma mutação deve aparecer espontaneamente. Testes de dados com Shine/Double, seus efeitos e eventos ficam para a futura ativação. Se o fluxo normal falhar, enviar o Output completo e a ação/item usados.

## Esteira reconstruída — funcionamento confirmado em 26/10/2026
O usuário relatou funcionamento, com pequenos saltos no movimento; a suavização está na etapa abaixo.
Iniciar Play e conferir se as chaves surgem perto de uma ponta de Workspace.treadmill.treadmill, seguem pelo centro e desaparecem na outra ponta. O percurso dura cerca de 36 segundos. Aproximar-se e comprar uma chave deve continuar entregando um único item e descontando o preço mostrado.

Se aparecerem fora da esteira, numa altura inadequada ou ocorrer erro, informar o ponto do percurso e enviar o Output.

## Movimento suave e animação — pendente do usuário, 26/10/2026
1. Iniciar Play e observar as chaves andando pela esteira: devem avançar continuamente, flutuar levemente e girar devagar.
2. Comprar uma chave em movimento: deve sumir por completo, descontar uma vez e entregar um item. Uma chave não comprada deve desaparecer no final, sem cópia parada.
3. Afastar-se e voltar à esteira; usar Reset: os visuais devem reaparecer na posição atual, sem duplicar modelos, placas ou prompts.

Se persistirem saltos ou houver falha de compra/visual, enviar Output e descrever quando acontece (sempre, ao aproximar, ao comprar ou após Reset).

## Compra de baús — pendente do usuário, 26/10/2026

1. No Play, vá aos três espaços do balcão da sua base: devem mostrar Baú comum / $50 e interação E (X/toque também). Com carteira abaixo de $50, tentar comprar deve avisar saldo insuficiente, sem criar baú nem alterar o dinheiro.
2. Coloque uma arma em um slot, espere acumular e pise no bloco para coletar pelo menos $50. Compre em um espaço: desconta exatamente $50 e aparece um baú apoiado no balcão, com fechadura voltada para você. O aviso de compra deve aparecer.
3. O espaço ocupado não deve oferecer outra compra nem descontar mais ao pressionar E. Os outros dois espaços continuam compráveis, respeitando o saldo. Baús ainda não abrem nem recebem upgrades nesta etapa.
4. Use Reset: baús e carteira devem permanecer. Afaste-se e volte ao balcão: sem cópias, placas ou prompts duplicados. Confira a orientação também numa base da outra fileira quando possível.
5. Multiplayer, quando disponível: ninguém compra no balcão alheio; ao sair, baús do dono desaparecem e a próxima pessoa recebe os espaços vazios. Esses cenários ainda não foram executados.

Esperado no Output: [ChestService] Pronto: 18 espaços de baús registrados. Informe qualquer erro completo e qual base/espaço estava usando. O assistente conferiu apenas código/sintaxe; não iniciou Play nem executou testes.

## Upgrades de baús — pendente do usuário, 26/10/2026

1. Compre um baú comum por $50. Deve oferecer F (Y/toque) para melhorar para prata por $150. A compra com E fica indisponível nesse espaço.
2. Com menos de $150 coletados na carteira, tente melhorar: avisa saldo insuficiente e mantém baú comum/dinheiro. Colete o suficiente e segure F: desconta só $150, troca para o modelo prata e passa a oferecer ouro por $550.
3. Melhore prata para ouro: desconta só $550. A placa mostra Raridade máxima; pressionar F novamente não cobra nem cria outro baú. Compra e duas melhorias somam $750.
4. Reset conserva raridade, modelo e saldo. Confira a posição do baú no balcão, inclusive na outra fileira quando possível. Ao se afastar e voltar, sem modelos/prompts duplicados.
5. Multiplayer pendente: outro jogador não melhora seu baú nem gasta seu saldo; sair limpa também baús melhorados antes de a base ser reatribuída.

O usuário aprovou o funcionamento da compra na etapa anterior, sem confirmação individual dos cenários multiplayer. Abertura ainda não está implementada. Se houver falha, envie Output completo, base, raridade e saldo antes/depois.

## Retomada após falha de Base1 — pendente do usuário, 27/10/2026

O erro vinha de Base1 estar como Folder, embora os slots existissem. As seis bases agora estão como Models; o script diferencia tipo incorreto de pasta ausente.

Inicie Play e confira base atribuída, colocação de arma/coleta, chaves na esteira e interação dos baús. Esperado: serviços inicializados, sem falha do Bootstrap; SlotService registra 48 slots e BaseService seis bases. Se parar novamente, envie o primeiro erro completo do Output. O assistente encerrou o Play anterior com autorização, mas não iniciou outra sessão nem executou esse teste.
