#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns m�todos utilit�rios.
 */

#include "stdhdrs.h"

#include <Iphlpapi.h>
#pragma comment(lib, "iphlpapi.lib")

#include <math.h>

#include <sstream>

#include "Rijndael.h"
#include "base64.h"

class CACIC_Utils {

public:

	/**
	 * Troca caracteres espec�ficos de uma string.
	 * @param str String a ser modificada.
	 * @param key String com o caractere ou conjunto de caracteres que ser�o substitu�dos.
	 * @param newKey String com o caractere ou conjunto de caracteres que ir�o substituir.
	 */
	static void replaceAll(string &str, string key, string newkey);

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
