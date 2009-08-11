/* 
 * Classe que trata os eventos da janela de autentica��o.
 */

#ifndef _WINVNC_VNCPASSDIALOG
#define _WINVNC_VNCPASSDIALOG

#include "stdhdrs.h"
#include "resource.h"

#include "vncPasswd.h"

#include <vector>
using namespace std;
#include <string>
using namespace std;

#include "CACIC_Utils.h"

//extern int MAX_VNC_CLIENTS;

#define ATT_MSG "ATEN��O: Esta autentica��o, que precede a abertura de sess�o para suporte remoto, atribui ao usu�rio a total responsabilidade por todo e qualquer tipo de dano l�gico � esta��o que porventura seja causado por acesso externo indevido."

#pragma once

/**
 * Struct referente a um dom�nio de autentica��o.
 */
struct Dominio {
	Dominio(string p_id, string p_nome) : id(p_id), nome(p_nome) {}
	Dominio() : id(""), nome("") {}

	string id;
	string nome;
};

class vncPassDlg {

public:
	static enum EAuthCode { AUTENTICADO = 1, // usuario autenticado
							FALHA_AUTENTICACAO = 2, // falha ao autenticar, ex: usu�rio e/ou senha inv�lidos
							ESPERANDO_AUTENTICACAO = 3,  // autentica��o ainda n�o efetuada
							SEM_AUTENTICACAO = 4 }; // n�o necessita de autentica��o

	vncPassDlg(vector<Dominio> &listaDominios);
	virtual ~vncPassDlg();

	char m_usuario[33]; // nome de usu�rio
	char m_senha[33]; // senha de usu�rio
	char m_dominio[17]; // id do dom�nio selecionado

	vector<Dominio> m_listaDominios;

	EAuthCode m_authStat;
	string m_msgInfo;

	BOOL DoDialog();

private:
	static BOOL CALLBACK vncAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static BOOL CALLBACK vncNoAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);

	UINT m_indiceDominio; // �ndice selecionado no combobox de dom�nios
};

#endif
