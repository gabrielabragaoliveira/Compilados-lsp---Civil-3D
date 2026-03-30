 Resumo do seu Kit de LISPs
 
POINTPARTY (c:pointparty)

Funcionalidade: Conecta COGO Points criando polilinhas de forma automatizada com três modos de "festa":

Ordem: Liga os pontos seguindo a ordem numérica deles


GALERA (c:galera)

Funcionalidade: Um selecionador inteligente. Você clica em um COGO Point de referência (o "líder"), e a rotina varre o desenho inteiro selecionando todos os outros pontos que tenham exatamente a mesma descrição (RawDescription).

PIQUENIQUE (c:piquenique)

Funcionalidade: Insere um rótulo de texto no centro de um grupo de COGO Points, usando um sistema de auto-escala. Ele calcula a "caixa" virtual formada pelos pontos na tela e ajusta a altura matemática do texto para que ele caiba perfeitamente dentro desse limite, sem vazar.

STALKER (c:stalker)

Funcionalidade: Insere uma lista de textos (que você digita separados por ponto e vírgula) em pontos do AutoCAD. O grande diferencial é que ele é cego para o sistema de coordenadas global e focado na sua tela (DCS). Ele insere os textos seguindo a ordem visual que você escolher (Esquerda para Direita, Cima para Baixo, etc.), ficando totalmente imune a vistas rotacionadas.

FIND2ME (c:find2me)

Funcionalidade: Um "radar de textos" interativo. Você digita uma palavra, e ele escaneia todos os TEXT e MTEXT do desenho. Depois, ele cria um sistema de navegação (dando Zoom no alvo e acendendo uma luz nele) para você pular entre os resultados usando opções de "Próximo" ou "Voltar".

TEXT2MLD (c:txt2mld)

Funcionalidade: Converte textos soltos em Multileaders (MLD). Ele calcula o centro exato da palavra, desenha a seta, transfere a cor original do texto para a nova MLD, garante que ela nasça alinhada com a tela atual (UCS) e, por fim, apaga o texto antigo.

POINT2MLD (c:point2mld)

Funcionalidade: Extrai metadados de COGO Points e cria Multileaders apontando para eles. Você pode escolher extrair:

Cota (Elevação).

Descrição.

Coordenadas UTM.


AREATIN (c:areatin)

Funcionalidade: Extrai instantaneamente as áreas 2D e 3D de uma Superfície TIN (TIN Surface) do Civil 3D. Ele formata os números para o padrão brasileiro (com vírgula e duas casas decimais) e insere as informações como um MTEXT no local onde você clicar.

+MLD (c:+mld)

Funcionalidade: Cria uma super Multileader com várias setas ligadas a uma única caixa de texto. Você pode ancorar as setas selecionando objetos (ele acha o centro de polilinhas ou usa a inserção de pontos) ou simplesmente clicando livremente pela tela.
