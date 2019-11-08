//=========================================================================================\\
//  Contraponto Intervalos v0.1                                                            \\
//                                                                                         \\
//  Copyright (C)2018 Rogério Tavares Constante                                            \\
//                                                                                         \\
//  Este programa é um software livre: você pode redistribuir e/ou  modificar              \\
//  ele nos termos da GNU General Public License como publicada pela                       \\
//  Free Software Foundation, seja na versão 3 da licença, ou em qualquer outra posterior. \\
//                                                                                         \\
//  Este programa é distribuído com a intenção de que seja útil,                           \\
//  mas SEM NENHUMA GARANTIA; Veja a GNU para mais detalhes.                               \\
//                                                                                         \\
//  Uma cópia da GNU General Public License pode ser encontrada em                         \\
//  <http://www.gnu.org/licenses/>.                                                        \\
//                                                                                         \\
//=========================================================================================\\

import QtQuick 2.3
import QtQuick.Controls 1.3
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.1
import MuseScore 1.1

MuseScore {
      menuPath: "Plugins.Contraponto"
      description: "Contraponto Intervalos.\nPlugin para analisar e escrever os intervalos em exercícios de contraponto."
      version: "0.1ms232"

// ----------------------------------------------------------------------------------------------------------------
   MessageDialog {
      id: msgErros
      title: "Erros!"
      text: "-"
      property bool estado: false
      onAccepted: {
            msgErros.visible=false;
      }

      visible: false;
} // msgErros
// -----------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------
  // ---- variáveis globais ----
      property var vozes: [];
      property bool finaliza: false;

// ----------- funções ---------
function tpc2Int(st) { // converte intervalo tpc para intervalos
  console.log("tpc2Int recebeu", st );
  //if (st > 127) { return "erro"; };
  switch(st){
   case -7: return "Ud"
   case 0: return "UJ";
   case 7: return "Ua";
   case -12: return "2d";
   case -5: return "2m";
   case 2: return "2M";
   case 9: return "2a";
   case -10: return "3d";
   case -3: return "3m";
   case 4: return "3M";
   case 11: return "3a";
   case -8: return "4d";
   case -1: return "4J";
   case 6: return "4a";
   case -6: return "5d";
   case 1: return "5J";
   case 8: return "5a";
   case -11: return "6d";
   case -4: return "6m";
   case 3: return "6M";
   case 10: return "6a";
   case -9: return "7d";
   case -2: return "7m";
   case 5: return "7M";
   case 12: return "7a";
  };
}

function mostraIntervalos() {
 curScore.startCmd();
 var cursor = curScore.newCursor();
 var voz, vozA, intAnterior;

 for (var voz1=0;voz1<vozes[1].nota.length;voz1++) { // percorre vozes - 1
  for (var voz2=voz1+1;voz2<vozes[1].nota.length;voz2++) { // percorre vozes - 2
   for (var x=0;x<vozes.length;x++) {	// percorre acordes
       cursor.rewind(1);
  	if (!cursor.segment) { cursor.rewind(0) };

    if (vozes[x].duração[voz1] > vozes[x].duração[voz2]) { voz = 1; vozA = voz2 } else { voz = 0; vozA = voz1};
    if (vozes[x].ligadura[vozA]) { voz = 1 - voz; };
    if (voz == 0) { voz = voz1; } else { voz = voz2; };

  if (vozes[x].nota[voz1] == 1000 || vozes[x].nota[voz2] == 1000) { var int1 = "erro"; }
   else {
    	var int2 = vozes[x].nota[voz1]-vozes[x].nota[voz2];  // intervalo em semitons
      if (int2 < 0) { var int1 = tpc2Int(vozes[x].tonal[voz2]-vozes[x].tonal[voz1]); int2 = int2 * -1; }
             else { var int1 = tpc2Int(vozes[x].tonal[voz1]-vozes[x].tonal[voz2]); };// intervalo simples: classificação

    var intA = int1.slice(0,1); var intB = int1.slice(-1); // calcula intervalos compostos e indica qtd oitavas através de '. 12ªJ = 5'J; 17ªM = 3''M.
	  if (intA == "U") {
	    if (int2 > 2) {
        var oitavas = Math.floor(int2/12);
        var resto = int2%12;
        if (resto == 0) { oitavas--; };
         int1 = "8";
        for (var oit=0;oit<oitavas;oit++) {
         int1 = int1 + "'";
        };
      } else { int1 = intA;}
    } else if (int2 > 12) {
      if (int2 < 127) {
        var oitavas = Math.floor(int2/12);
         int1 = intA;
        for (var oit=0;oit<oitavas;oit++) {
         int1 = int1 + "'";
        };
      };
    } else { int1 = intA;};
    int1 = int1 + intB;
    // -------------------------------- fim do calculo intervalos compostos
   };

    if (x > 0 && int1 == intAnterior && vozes[x].nota[voz1] == vozes[x-1].nota[voz1]) { continue; } else { intAnterior = int1; };

    cursor.staffIdx = Math.floor(vozes[x].trilha[voz] / 4);    // posicionar cursor para encontrar x
    while (cursor.tick < vozes[x].posição[voz]) { cursor.next(); };
    cursor.staffIdx = Math.floor(vozes[x].trilha[voz1] / 4);    // reposicionar cursor para impressao no y
//console.log(cursor.tick);

    var extraY =  (2 * (voz2 - voz1) - 2) - 1; // offset para posição eixo y de apresentação dos intervalos

    if (x == 0) { var nome = newElement(Element.STAFF_TEXT); // indica entre quais vozes são os intervalos, antes do primeiro intervalo
                  nome.text = "(" + (voz1+1) + " e " + (voz2+1) + "):";
                  nome.pos.x = - 6;
                  nome.pos.y = 10.4 + extraY;
                  cursor.add(nome); };

    var myText = newElement(Element.STAFF_TEXT);
        if ((!int1 && int1 !== 0) || int1 == "erro") { myText.text = ""; } else {
           if (int1.slice(-1) == "M" || int1.slice(-1) == "m" || int1.slice(-1) == "J" )
                { myText.text = int1.slice(0,(int1.length-1)); } else {
                  myText.text = int1;};
                };
        myText.pos.y = 10.4 + extraY;
        cursor.add(myText);
    };
   };
  };
 curScore.endCmd();
}

function carregarNotas() {

  console.log("Contraponto .............................................. Rogério Tavares Constante - 2019(c)")

  if (typeof curScore == 'undefined' || curScore == null) { // verifica se há partitura
     console.log("nenhuma partitura encontrada");
     msgErros.text = "Erro! \n Nenhuma partitura encontrada!";
                       msgErros.visible=true; finaliza = true; return; };

  //procura por uma seleção

  var pautaInicial;
  var pautaFinal;
  var posFinal;
  var posInicial;
  var processaTudo = false;
  vozes = [];
  var cursor = curScore.newCursor();

  cursor.rewind(1);

    if (!cursor.segment) {
       // no selection
       console.log("nenhuma seleção: processando toda partitura");
       processaTudo = true;
       pautaInicial = 0;
       pautaFinal = curScore.nstaves;

     } else {
       pautaInicial = cursor.staffIdx;
       posInicial = cursor.tick;
       cursor.rewind(2);
       pautaFinal = cursor.staffIdx + 1;
       posFinal = cursor.tick;
          if(posFinal == 0) {  // se seleção vai até o final da partitura, a posição do fim da seleção (rewind(2)) é 0.
          							// para poder calcular o tamanho do segmento, pega a última posição da partitura (lastSegment.tick) e adiciona 1.
          posFinal = curScore.lastSegment.tick + 1;
          }
       cursor.rewind(1);
    };

  // ------------------ inicializa variáveis de dados

            var seg = 0;
            var carregou;
            var trilha;
            var trilhaInicial = pautaInicial * 4;
            var trilhaFinal = pautaFinal * 4;

          if (!processaTudo) {
            cursor.rewind(0);
            while (cursor.segment && cursor.segment.tick < posInicial) {
     	       if (cursor.measure != compassoAtual) {
           	   compasso++;
           	   compassoAtual = cursor.measure;
           	 };
           	 cursor.next();
            };
          };

            // lê as informações da seleção (ou do documento inteiro, caso não haja seleção)

            if(processaTudo) { // posiciona o cursor no início
                  cursor.rewind(0);
            } else {
                  cursor.rewind(1);
            };

            var segmento = cursor.segment;

            var pausa = false;

           while (segmento && (processaTudo || segmento.tick < posFinal)) {

           carregou = false;

             var voz = 0;

	          vozes[seg] = { nota: [], tonal: [], posição: [], duração: [], trilha: [], objeto: [], ligadura: []};

             // Passo 1: ler as notas e guardar em "vozes"
               for (trilha = trilhaInicial; trilha < trilhaFinal; trilha++) {
               	cursor.track = trilha;

            	  if (segmento.elementAt(trilha)) {
            	  	 if (segmento.elementAt(trilha).type == Element.REST) {
            	  	 	 if (seg == 0) { pausa = true;
                       vozes[seg].nota[voz] = 1000;
                       vozes[seg].tonal[voz] = 1000;
                       vozes[seg].trilha[voz] = trilha;
                       vozes[seg].posição[voz] = segmento.tick;
                       vozes[seg].duração[voz] = segmento.elementAt(trilha).duration.ticks;
                       vozes[seg].objeto[voz] = segmento.elementAt(trilha).rest;
                       vozes[seg].ligadura[voz] = true;
                       voz++;
                       carregou = true;
                       continue;
            	  	    } else {
                        vozes[seg].nota[voz] = vozes[seg-1].nota[voz];
                        vozes[seg].tonal[voz] = vozes[seg-1].tonal[voz];
                        vozes[seg].trilha[voz] = vozes[seg-1].trilha[voz];
                        vozes[seg].posição[voz] = segmento.tick;
                        vozes[seg].duração[voz] = segmento.elementAt(trilha).duration.ticks;
                        vozes[seg].objeto[voz] = segmento.elementAt(trilha).rest;
                        vozes[seg].ligadura[voz] = true;
                        voz++;
                        carregou = true;
            	  	      continue; };

            	  	 } else if (segmento.elementAt(trilha).type == Element.CHORD) {
                     var duração = segmento.elementAt(trilha).duration.ticks;
                     var notas = segmento.elementAt(trilha).notes;
                     for (var j=notas.length-1; j>=0;j--) {
                       vozes[seg].nota[voz] = notas[j].pitch;
                       vozes[seg].tonal[voz] = notas[j].tpc
                       vozes[seg].trilha[voz] = trilha;
                       vozes[seg].posição[voz] = segmento.tick;
                       vozes[seg].duração[voz] = duração;
                       vozes[seg].objeto[voz] = notas[j];
                       if (notas[j].tieBack) { vozes[seg].ligadura[voz] = true; } else { vozes[seg].ligadura[voz] = false; }

                       voz++;
                       carregou = true;

                     };
                   };
                 } else {

                   if (vozes[seg-1]) {

					     for (var y=0; y<vozes[seg-1].nota.length;y++) {
						    if (trilha == vozes[seg-1].trilha[y]) {
						    	if ((vozes[seg-1].duração[y] + vozes[seg-1].posição[y]) > segmento.tick) { var prolonga = true; } else { var prolonga = false; };
						    if (prolonga)  {
						        vozes[seg].nota[voz] = vozes[seg-1].nota[y];
	                  vozes[seg].tonal[voz] = vozes[seg-1].tonal[y];
	                  vozes[seg].trilha[voz] = vozes[seg-1].trilha[y];
	                  vozes[seg].posição[voz] = segmento.tick;
	                  vozes[seg].duração[voz] = vozes[seg-1].duração[y] - (segmento.tick - vozes[seg-1].posição[y]);
	                  vozes[seg].objeto[voz] = vozes[seg-1].objeto[y];
								    vozes[seg].ligadura[voz] = true;

						        voz++;
						        carregou = true;
							   };
							   break;
						    };
					     };
					  };
                };
              };

              if (carregou) {
                 var menorDura = 0;
                 for (var i=1;i<vozes[seg].nota.length;i++) {
                 	 if (vozes[seg].duração[i] < vozes[seg].duração[menorDura]) { menorDura =  i};
                 };

                 cursor.track = vozes[seg].trilha[menorDura];
                 console.log(seg, "-", "trilha", cursor.track, ":", vozes[seg].nota[0], "(", vozes[seg].duração[0], ")", vozes[seg].nota[1], "(", vozes[seg].duração[1], ")",
                              vozes[seg].nota[2], "(", vozes[seg].duração[2], ")", vozes[seg].nota[3], "(", vozes[seg].duração[3], ")" );
                 if (seg > 0) {
                   for (var i=0;i<vozes[seg].nota.length;i++) {
                     if (vozes[seg].nota[i] != vozes[seg-1].nota[i]) { seg++; break; };
                   };
                 } else { seg++; };
              };
        		  cursor.next(); segmento = cursor.segment;

           };
  //  if (pausa) { vozes.splice(0, 1); pausa = false; };

   if (seg == 0) { msgErros.text += "Nenhum acorde carregado!!\n";
                        msgErros.estado=true; Qt.quit(); };

}
// --------------------------------------

  onRun: {

     finaliza = false;
     msgErros.text = "";
     msgErros.estado = false;

     carregarNotas();
     if (finaliza) { Qt.quit(); };
     mostraIntervalos();

  } // fecha onRun
} // fecha função Musescore
