#include <amxmodx>
#include <reapi>

#define CUSTOM_MENU
#define TIME_CHANGE	15		// Segundos en cual puede cambiar equipo
#define PLAYER_DIFF	2
//#define MAX_CLIENTS	32

new Float:g_fLastTeamChange[MAX_CLIENTS+1];

#if !defined CUSTOM_MENU
new bool:g_VIPMap = false, g_MapName[32];
#endif

public plugin_init()
{
	register_plugin("[ReAPI] Elegir Equipo", "1.0", "JkDev");

	register_clcmd("chooseteam", "CMD_ChooseTeam");
	RegisterHookChain(RG_ShowVGUIMenu, 		"fwdShowVGUIMenu", false);
	RegisterHookChain(RG_HandleMenu_ChooseTeam, 	"fwdHandleMenu_ChooseTeam", false);

#if !defined CUSTOM_MENU
	get_mapname(g_MapName, charsmax(g_MapName));
	if(containi(g_MapName, "as_") != -1) g_VIPMap = true;
#endif
	set_task(1.2, "ChangeServerCvars");
}

public ChangeServerCvars()
	set_cvar_num("mp_limitteams", 0);

public CMD_ChooseTeam(id)
{
	if(is_user_connected(id))
		set_member(id, m_bTeamChanged, false);

	if(TIME_CHANGE && get_member(id, m_iTeam))
	{
		new Float:fNextChoose = g_fLastTeamChange[id] + TIME_CHANGE;
		new Float:fCurTime = get_gametime();

		if(fNextChoose > fCurTime)
		{
			client_print_color(id, 0, "^3%d ^4en segundos ^3puedes cambiar de equipo^1.", floatround(fNextChoose - fCurTime));
			return HC_SUPERCEDE;
		}
	}
	return HC_CONTINUE;
}

public fwdShowVGUIMenu(const id, VGUIMenu:menuType, const bitsSlots, szOldMenu[])
{
	if(menuType == VGUI_Menu_Team)
	{
		set_member(id, m_bForceShowMenu, true);
#if defined CUSTOM_MENU
		SetHookChainArg(3, ATYPE_INTEGER, MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_6);
		SetHookChainArg(4, ATYPE_STRING, "\yPRO Menu:^n^n\y1. \rEntrar en el juego^n\y6. \wSpectador^n^n\y0. \wSalir");
#else
		new iTeamTT, iTeamCT; CalculateTeamNum(iTeamTT, iTeamCT);
		new TeamName:team = get_member(id, m_iTeam);
		new szMenu[192], iKeys = MENU_KEY_0;
		new iLen = formatex(szMenu, charsmax(szMenu), "\yElige tu equipo:^n^n");
		if((iTeamTT - iTeamCT) >= PLAYER_DIFF || team == TEAM_TERRORIST)
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y1. \dTerrorista [\r%d\w]^n", iTeamTT);
		else
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y1. \wTerrorista [\r%d\w]^n", iTeamTT);
			iKeys |= MENU_KEY_1;
		}

		if((iTeamCT - iTeamTT) >= PLAYER_DIFF || team == TEAM_CT)
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y2. \dCounter Terrorist [\r%d\w]^n^n", iTeamCT);
		else
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y2. \wCounter Terrorist [\r%d\w]^n^n", iTeamCT);
			iKeys |= MENU_KEY_2;
		}
		if(g_VIPMap)
		{
			if(team != TEAM_CT) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y3. \dVIP^n^n");
			else
			{
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y3. \wVIP^n^n");
				iKeys |= MENU_KEY_3;
			}
		}
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y5. \yAuto Seleccionar^n");
		iKeys |= MENU_KEY_5;

		if(team == TEAM_SPECTATOR)
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y6. \rEspectador^n^n^n");
		else
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y6. \rEspectador^n^n^n");
			iKeys |= MENU_KEY_6;
		}

		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y0. \wSalir");

		SetHookChainArg(3, ATYPE_INTEGER, iKeys);
		SetHookChainArg(4, ATYPE_STRING, szMenu);
#endif
	}
	else if(menuType == VGUI_Menu_Class_T)
	{
		SetHookChainArg(3, ATYPE_INTEGER, MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5);
		SetHookChainArg(4, ATYPE_STRING, "\ySelecciona:^n^n\r1. \wPhoenix Connexion^n\r2. \wElite Crew^n\r3. \wArctic Avengers^n\r4. \wGuerilla Warface^n^n\r5. \yAuto Select^n^n^n\r0. \wSalir");
	}
	else if(menuType ==  VGUI_Menu_Class_CT)
	{
		SetHookChainArg(3, ATYPE_INTEGER, MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5);
		SetHookChainArg(4, ATYPE_STRING,"\ySelecciona:^n^n\r1. \wSeal Team 6^n\r2. \wGSG-9^n\r3. \wSAS^n\r4. \wGIGN^n^n\r5. \yAuto Select^n^n^n\r0. \wSalir");
	}
	return HC_CONTINUE;
}

public fwdHandleMenu_ChooseTeam(const id, const MenuChooseTeam:key)
{
	switch(key)
	{
#if defined CUSTOM_MENU
		case 1: SetHookChainArg(2, ATYPE_INTEGER, (rg_get_join_team_priority() == TEAM_TERRORIST) ? MenuChoose_T : MenuChoose_CT);
		case MenuChoose_Spec:	user_silentkill(id);
#else
		case MenuChoose_T: SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_T);
		case MenuChoose_CT: SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_CT);
		case MenuChoose_AutoSelect: SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_AutoSelect);
		case MenuChoose_Spec:	user_silentkill(id);
#endif
	}
	g_fLastTeamChange[id] = get_gametime();
	return HC_CONTINUE;
}

#if !defined CUSTOM_MENU
CalculateTeamNum(&iTeamTT, &iTeamCT)
{
	for(new id = 1; id <=  MAX_CLIENTS; id++)
	{
		if(!is_user_connected(id)) continue;

		switch(get_member(id, m_iTeam))
		{
			case TEAM_CT: iTeamCT++;
			case TEAM_TERRORIST: iTeamTT++;
		}
	}
}
#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1055\\ f0\\ fs16 \n\\ par }
*/
