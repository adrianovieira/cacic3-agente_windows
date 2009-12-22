/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns m�todos utilit�rios.
 */

#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

#include <string>
using namespace std;

#include "windows.h"

/**
 * Struct referente a um usu�rio cliente.
 */
struct ClienteSRC {
	short vncCID;
	string peerName;
	string id_usuario_visitante; 
	string id_usuario_cli; 
	string id_conexao; 
	string nm_usuario_completo; 
	string te_node_address_visitante; 
	string te_node_address_cli; 
	string te_documento_referencial; 
	string te_motivo_conexao; 
	string te_so_visitante; 
	string te_so_cli; 
	string dt_hr_inicio_sessao; 
};

/**
 * Struct referente a um dom�nio de autentica��o.
 */
struct Dominio {
	Dominio(string p_id, string p_nome) : id(p_id), nome(p_nome) {}
	Dominio() : id(""), nome("") {}
	Dominio(const Dominio& d) : id(d.id), nome(d.nome) {}
	string id;
	string nome;
};

class CACIC_Utils {

public:

	/** Fonte padr�o usado nos di�logos. */
	static const string F_SANS_SERIF;

	/**
	 * M�todo bruto para ler uma tag espec�fica de um arquivo xml.
	 * @param xml String no formato de arquivo xml.
	 * @param tagname String com o nome da tag a ser pesquisada.
	 * @param conteudo String com o conte�do da tag pesquisada.
	 * @trows CACIC_Exception caso a tag n�o seja encontrada.
	 */
	static void leTag(char xml[], char tagname[], string &conteudo);

	/**
	 * Troca caracteres espec�ficos de uma string.
	 * @param str String a ser modificada.
	 * @param key String com o caractere ou conjunto de caracteres que ser�o substitu�dos.
	 * @param newKey String com o caractere ou conjunto de caracteres que ir�o substituir.
	 */
	static void replaceAll(string &str, string key, string newkey);

	/**
	 * Codifica a string, removendo os caracteres especiais por %c�digo dos mesmos.
	 * @param decoded String que ser� codificada.
	 */
	static void urlEncode(string &decoded);

	/**
	 * Decodifica a string, retornando os c�digos dos caracteres pelos pr�prios caracteres.
	 * @param encoded String que ser� decodificada.
	 */
	static void urlDecode(string &encoded);

	/**
	 * Mesma fun��o do urlEncode, por�m os caracteres ser�o substitu�dos
	 * por tags espec�ficas, e n�o pelo c�digo.
	 * @param entrada String que ser� codificada.
	 */
	static void simpleUrlEncode(string &entrada);

	/**
	 * Faz o inverso do simpleUrlEncode, trocando as tags espec�ficas pelos
	 * respectivos caracteres.
	 * @param entrada String que ser� codificada.
	 */
	static void simpleUrlDecode(string &entrada);

	/**
	 * Transforma o byte em codigo ascii, retornando o char correspondente.
	 * @param first Primeiro hexa do caractere.
	 * @param second Segundo hexa do caractere.
	 * @return Char correspondente ao c�digo ascci encontrado.
	 */
	static char hexToAscii(char first, char second);

	/**
	 * Retira os espa�os em branco do come�o e fim da string.
	 * @param str String a ser modificada.
	 */
	static void trim(string &str);

	/**
	 * M�todo para alterar a fonte de um determinado elemento de um di�logo.
	 * @param dlgHandle Handler do di�logo.
	 * @param dlgItem Item do di�logo que ter� a fonte trocada.
	 * @param fontSize Tamanho da fonte.
	 * @param fontName Nome da fonte.
	 * @param fontIsBold Define o peso da fonte: true = bold, false = normal.
	 */
	static void changeFont(HWND dlgHandle, int dlgItem, 
						   int fontSize, string fontName, 
						   bool fontIsBold = false);

	/**
	 * M�todo para separar a string em partes delimitadas por um, ou um conjunto,
	 * de caracteres.
	 * @param str String a ser tokenizada.
	 * @param tokens Vetor de sa�da dos tokens gerados.
	 * @param delimiters Delimitadores que ser�o usados para separar a string.
	 * @note http://www.linuxselfhelp.com/HOWTO/C++Programming-HOWTO-7.html
	 */
	//static void tokenize(const string &str, vector<string> &tokens, const string &delimiters = " ");

	/**
	 * Obt�m o MAC Address da placa de rede.<br />
	 * TODO: Quando houver mais de uma placa de rede no pc, verificar qual
	 * est� se comunicando com o servidor para enviar o MAC certo.
	 */
	static string getMACAddress();

	/**
	 * Obt�m a identifica��o do sistema operacional.<br />
	 * Artigo sobre SOID:<br />
	 * http://www.codeguru.com/cpp/w-p/system/systeminformation/article.php/c8973__2/
	 */
	static string getSOID();

private:

	/**	
	 * Este m�todo virtual puro � um truque para que a classe
	 * se torne abstrata e n�o possa ser instanciada.
	 */
	virtual void cutils() = 0;

};

#endif