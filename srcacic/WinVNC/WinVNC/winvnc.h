//  Copyright (C) 1999 AT&T Laboratories Cambridge. All Rights Reserved.
//
//  This file is part of the VNC system.
//
//  The VNC system is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
//  USA.
//
// If the source code for the VNC system is not available from the place 
// whence you received this file, check http://www.uk.research.att.com/vnc or contact
// the authors on vnc@uk.research.att.com for information on obtaining it.


// WinVNC header file

#include "stdhdrs.h"
#include "resource.h"
#include "vncPassDlg.h"

///////////Declarações srCACIC//////////
#include "CACIC_Auth.h"
#include <sstream>
#include <fstream>
using namespace std;

#include "mmsystem.h"

// Application specific messages

// Message used for system tray notifications
#define WM_TRAYNOTIFY				WM_USER+1

// Messages used for the server object to notify windows of things
#define WM_SRV_CLIENT_CONNECT		WM_USER+2
#define WM_SRV_CLIENT_AUTHENTICATED	WM_USER+3
#define WM_SRV_CLIENT_DISCONNECT	WM_USER+4

// Export the application details
extern HINSTANCE	hAppInstance;
extern const char	*szAppName;
extern DWORD		mainthreadId;

// Main VNC server routine

extern int WinVNCAppMain();

// Standard command-line flag definitions
const char winvncRunService[]		= "-service_run";
const char winvncStartService[]		= "-service";
const char winvncRunAsUserApp[]		= "-run";
const char winvncConnect[]		= "-connect";
const char winvncAutoReconnect[]	= "-autoreconnect";
const char winvncAutoReconnectId[]	= "id:";

const char winvncSettingshelper[]		= "-settingshelper";
const char winvncSettings[]				= "-settings";
const char winvncStopserviceHelper[]	= "-stopservicehelper";
const char winvncStopservice[]			= "-stopservice";
const char winvncStartserviceHelper[]	= "-startservicehelper";
const char winvncStartservice[]			= "-startservice";

const char winvncInstallService[]		= "-install";
const char winvncUnInstallService[]		= "-uninstall";
const char winvncInstallServiceHelper[]		= "-installhelper";
const char winvncUnInstallServiceHelper[]	= "-uninstallhelper";
const char winvncSecurityEditorHelper[]		= "-securityeditorhelper";
const char winvncSecurityEditor[]			= "-securityeditor";
const char winvncKill[]						= "-kill";
const char winvncStart[]					= "-start";
static string filePathGlobal				= "";

// Usage string
const char winvncUsageText[]		= "winvnc [-run] [-autoreconnect[ ID:????]] [-connect host[:display]] [-connect host[::port]] \n";

void CALLBACK atualizaSessao(UINT uID, UINT uMsg, DWORD dwUser, DWORD dw1, DWORD dw2);
void iniciaTimer();
void paraTimer();
string getPalavraChave();
