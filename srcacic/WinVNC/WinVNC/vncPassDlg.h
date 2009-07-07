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

//extern int MAX_VNC_CLIENTS;

#define ATT_MSG "ATEN��O: Esta autentica��o, que precede a abertura de sess�o para suporte remoto, atribui ao usu�rio a total responsabilidade por todo e qualquer tipo de dano l�gico � esta��o que porventura seja causado por acesso externo indevido."

#pragma once

// struct referente a um dom�nio
struct Dominio {
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

	char m_usuario[32]; // nome de usu�rio
	char m_senha[32]; // senha de usu�rio
	char m_dominio[16]; // id do dom�nio selecionado

	vector<Dominio> m_listaDominios;

	EAuthCode m_authStat;

	BOOL DoDialog(EAuthCode authStat, string msgInfo);

private:
	static BOOL CALLBACK vncAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static BOOL CALLBACK vncNoAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static void changeFont(HWND hwndDlg, int dlgItem);

	string m_msgInfo;

	UINT m_indiceDominio; // �ndice selecionado no combobox de dom�nios
};

#endif
