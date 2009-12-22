/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe singleton respons�vel pela autentica��o no gerente web.
 */

#ifndef _CACIC_AUTH_
#define _CACIC_AUTH_

#include <vector>
#include <string>
using namespace std;

#include "supInfoDlg.h"

class CACIC_Auth {

public:

	/**
	 * Nome do arquivo tempor�rio de trava.
	 * Utilizado para que o cacic impe�a a execu��o de coletas com o suporte ativo.
	 */
	static const string AGUARDE_FILENAME;

	/**
	 * Tempo m�ximo que o servidor pode ficar aberto sem conex�es. (mins)
	 */
	static const UINT TEMPO_IDLE;

	/** Lista de usu�rios cliente. */
	vector<ClienteSRC> m_listaClientes;

	/** �ltimo usu�rio cliente conectado. */
	ClienteSRC m_novoCliente;

	/**
	 * Janela com informa��es sobre o cliente conectado.
	 * Exibida enquanto h� suporte em andamento.
	 */
	supInfoDlg m_infoDlg;

	/**
	 * Vari�vel de decis�o sobre o logout do sistema ap�s o suporte.
	 */
	bool m_efetuarLogout;

	/** Singleton. */
	static CACIC_Auth* getInstance()
	{
		if (!m_instance) m_instance = new CACIC_Auth();
		return m_instance;
	}

	/* M�TODOS DE ENCAPSULAMENTO --> */
	void setServidorWeb(string newServidorWeb) {m_servidorWeb = newServidorWeb;}
	string getServidorWeb() {return m_servidorWeb;}
	void setScriptsPath(string newScriptsPath) {m_scriptsPath = newScriptsPath;}
	void setTempPath(string newTempPath) {m_tempPath = newTempPath;}
	void setSOVersion(char* newSOVersion) {m_soVersion = newSOVersion;}
	void setNodeAdress(char* newNodeAdress) {m_nodeAdress = newNodeAdress;}
	void setPalavraChave(char* newPalavraChave) {m_palavraChave = newPalavraChave;}
	void setPorta(UINT newPorta) {m_porta = newPorta;}
	UINT getPorta() {return m_porta;}
	void setTimeout(UINT newNuTimeout) {m_nuTimeout = newNuTimeout;}
	UINT getTimeout() {return m_nuTimeout;}
	/* <-- M�TODOS DE ENCAPSULAMENTO */

	/**
	 * Retorna os valores padr�o de post, usados na 
	 * comunica��o com o gerente web.
	 * te_so, te_node_address, te_palavra_chave
	 * @return String com o post padr�o formatado.
	 */
	string getPostComum();

	/**
	 * Remove o usu�rio cliente da lista.
	 * @param vncCID ID do cliente VNC, utilizado para
	 * diferenciar os clientes, caso haja mais de um.
	 */
	void removeCliente(short vncCID);

	/**
	 * Faz a comunica��o com o gerente web para validar a palavra chave
	 * e criar uma nova sess�o para o suporte remoto.
	 * @return bool Status da autentica��o.
	 */
	bool autentica();

	/**
	 * Se comunica com o gerente web para validar o usu�rio cliente.
	 * Se o usu�rio for v�lido, ele cria uma nova sess�o de conex�o.
	 * @param nm_usuario_cli String codificada contendo o nome de usu�rio.
	 * @param te_senha_cli String codificada contendo a senha do usu�rio.
	 * @param te_node_address_cli String codificada contendo o MAC address do cliente.
	 * @param te_documento_referencial String codificada contendo o Documento de Refer�ncia do suporte remoto.
	 * @param te_motivo_conexao String codificada contendo o motivo do suporte remoto.
	 * @param te_so_cli String codificada contendo a identifica��o do SO do cliente.
	 * @param vncCID ID do cliente VNC.
	 * @param peerName String contendo o endere�o ip do cliente.
	 */
	bool validaTecnico(char nm_usuario_cli[], char te_senha_cli[], char te_node_address_cli[],
					   char te_documento_referencial[], char te_motivo_conexao[], char te_so_cli[], 
					   const short vncCID, const char peerName[]);
	
	/**
	 * Se comunica com o gerente web para atualizar a sess�o de suporte.
	 */
	void atualizaSessao();

	/**
	 * Envia o log do chat para o gerente web durante o suporte remoto.
	 * @param te_mensagem Mensagem recebida/enviada.
	 * @param cs_origem Origem da mensagem, cliente/servidor.
	 */
	void sendChatText(char te_mensagem[], char cs_origem[]); 

	/** Fecha o servidor. */
	void finalizaServidor();

private:

	/** Singleton. */
	static CACIC_Auth* m_instance;

	CACIC_Auth() {
		m_idleTime = TEMPO_IDLE;
		m_efetuarLogout = true;
	}

	virtual ~CACIC_Auth() {}

	/** Endere�o do servidor web. */
	string m_servidorWeb;
	/** Caminho dos scripts no servidor web. */
	string m_scriptsPath;
	/** Caminho est�tico para a pasta temp do cacic. */
	string m_tempPath;

	/** Usu�rio host do suporte. */
	string m_usuario;
	/** ID da sess�o iniciada pelo usu�rio host. */
	string m_idSessao;

	/** Vers�o do sistema operacional do host. */
	string m_soVersion;
	/** MAC Address do host. */
	string m_nodeAdress;
	/** Palavra chave. Utilizada na comunica��o com o gerente web. */
	string m_palavraChave;

	/** Porta de escuta. */
	UINT m_porta;
	/** Tempo limite que o srcacic pode ficar ocioso antes de fechar-se. */
	UINT m_nuTimeout;
	/** Tempo que o servidor est� ocioso */
	UINT m_idleTime;

	/** Nome do script de configura��es do gerente web. */
	static const string GET_CONFIG_SCRIPT;
	/** Nome do script de sess�es do gerente web. */
	static const string SET_SESSION_SCRIPT;
	/** Nome do script de autentica��o do gerente web. */
	static const string AUTH_CLIENT_SCRIPT;
	/** Tamanho padr�o da resposta recebida pela requisi��o http. */
	static const unsigned int TAMANHO_RESPOSTA;
	/** Nome do arquivo tempor�rio de atualiza��o da palavra chave. */
	static const string COOKIE_FILENAME;

	/**
	 * Apresenta o di�logo de login do usu�rio host e
	 * valida os dados no gerente web.
	 * @param listaDominios Lista de dom�nios obtida na autentica��o.
	 */
	bool autenticaUsuario(vector<Dominio> &listaDominios);

	/**
	 * Verifica a autentica��o da chave no gerente web.
	 * @param resposta Resposta XML gerada na comunica��o com o gerente web.
	 * @param listaDominios Lista de dom�nios obtida na autentica��o.
	 */
	bool verificaAuthChave(char resposta[], vector<Dominio> &listaDominios);

	/**
	 * Verifica se a resposta da autentica��o do usu�rio host foi positiva.
	 * @param resposta Resposta XML gerada na comunica��o com o gerente web.
	 */
	bool verificaAuthDominio(char resposta[]);

	/**
	 * Verifica se a resposta da autentica��o do t�cnico foi positiva,
	 * armazena o novo cliente na lista e exibe a tela de informa��es do suporte.
	 * @param nm_usuario_cli String codificada contendo o nome de usu�rio.
	 * @param te_senha_cli String codificada contendo a senha do usu�rio.
	 * @param te_node_address_cli String codificada contendo o MAC address do cliente.
	 * @param te_documento_referencial String codificada contendo o Documento de Refer�ncia do suporte remoto.
	 * @param te_motivo_conexao String codificada contendo o motivo do suporte remoto.
	 * @param te_so_cli String codificada contendo a identifica��o do SO do cliente.
	 * @param vncCID ID do cliente VNC.
	 * @param peerName String contendo o endere�o ip do cliente.
	 */
	bool verificaAuthTecnico(char resposta[], char te_node_address_cli[], char te_documento_referencial[],
							 char te_motivo_conexao[], char te_so_cli[], 
							 const short vncCID, const char peerName[]);

	/**
	 * Verifica o valor de retorno STATUS que � enviado pelo gerente web
	 * ap�s cada comunica��o para confirmar a opera��o.
	 * <b>Valores retornados:</b><br />
	 * OK: A opera��o teve �xito.<br />ERRO: A opera��o falhou.
	 * @param resposta Resposta XML gerada na comunica��o com o gerente web.
	 */
	bool verificaStatus(char resposta[]);
};

#endif
