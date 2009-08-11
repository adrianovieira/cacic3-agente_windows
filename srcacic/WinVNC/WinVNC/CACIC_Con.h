/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe para envio de requisi��es html ao gerente web.
 * API das fun��es wininet:
 * http://msdn.microsoft.com/en-us/library/aa385473(VS.85).aspx
 */

#ifndef _CACIC_CON_
#define _CACIC_CON_

#include <string>
using namespace std;

#include <windows.h>
#include <wininet.h>

#include "CACIC_Exception.h"
#include "CACIC_Utils.h"

#define HTTP_POST "POST"
#define HTTP_GET "GET"

class CACIC_Con {

private:

	/** Header padr�o das requisi��es. */
	static const TCHAR DEFAULT_HEADER[];

	/** Handler da sess�o. */
	HINTERNET m_hSession;
	/** Handler da conexao. */
	HINTERNET m_hConnect;
	/** Handler da resposta da requisi��o. */
	HINTERNET m_hRequest;

	/** N�mero de bytes lidos na �ltima requisi��o. */
	unsigned long m_lBytesRead;
	/** Nome do servidor que sofrer� a a��o. */
	LPCSTR m_server;

public:

	CACIC_Con() {}

	/**
	 * Destrutor da classe.
	 * Libera os handlers que estiverem abertos.
	 */
	virtual ~CACIC_Con()
	{
		if(m_hSession != NULL) InternetCloseHandle(m_hSession);
		if(m_hConnect != NULL) InternetCloseHandle(m_hConnect);
		if(m_hRequest != NULL) InternetCloseHandle(m_hRequest);
	}

	/**
	 * Altera o servidor.
	 * @param server String com o nome do servidor.
	 */
	void setServer(LPCSTR server){m_server = server;}

	/**
	 * Retorna o nome do servidor.
	 * @return String com o nome do servidor.
	 */
	LPCSTR getServer(){return m_server;}

	/**
	 * Efetua a conex�o com o servidor.
	 */
	void conecta();

	/**
	 * Envia uma requisi��o ao servidor.
	 * @param metodo String com o tipo da requisi��o. (GET/POST)
	 * @param script String com o nome do script que ser� acessado.
	 * @param frmdata String com os dados que ir�o ser passados como par�metro ao script.
	 */
	void sendRequest(LPCTSTR metodo, LPCTSTR script, TCHAR frmdata[]);

	/**
	 * Retorna a resposta gerada pelo servidor que recebeu a requisi��o.
	 * @param buff Buffer para armazenar o resultado da requisi��o.
	 * @param sz Tamanho do buffer.
	 * @return bool Boleano com o estado da requisi��o.
	 */
	bool getResponse(char buff[], unsigned long sz);

	/**
	 * M�todo est�tico que faz uma requisi��o ao servidor passado e
	 * j� retorna a resposta atrav�s do buffer "resposta".
	 * @param servidor String com o nome do servidor.
	 * @param script String com o nome do script.
	 * @param post String com os par�metros a serem passados ao script.
	 * @param resposta Buffer de resposta da requisi��o.
	 * @param sz Tamanho da resposta.
	 */
	static void sendHtppPost(const string &servidor, const string &script, string &post,
							 char resposta[], unsigned long sz);

};

#endif
