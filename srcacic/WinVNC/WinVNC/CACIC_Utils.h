/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns m�todos utilit�rios.
 */

#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

#include <string>
using namespace std;
#include <sstream>
#include <iostream>

#include "CACIC_Exception.h"

class CACIC_Utils {

public:

	/** Fonte padr�o usado nos di�logos. */
	static const string F_SANS_SERIF;

	/**
	 * M�todo bruto para ler uma tag espec�fica de um arquivo xml.
	 * @param xml String no formato de arquivo xml.
	 * @param tagname String com o nome da tag a ser pesquisada.
	 * @return String com o conte�do da tag pesquisada.
	 * @trows CACIC_Exception caso a tag n�o seja encontrada.
	 */
	static string leTag(char xml[], char tagname[]);

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

private:

	/**	
	 * Este m�todo virtual puro � um truque para que a classe
	 * se torne abstrata e n�o possa ser instanciada.
	 */
	virtual void cutils() = 0;

};

#endif