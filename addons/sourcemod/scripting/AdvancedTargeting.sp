#pragma semicolon 1

#pragma dynamic 128*1024

#include <sourcemod>
#include <sdktools>
#include <SteamWorks>
#include <cstrike>
#include <AdvancedTargeting>
#include <multicolors>
#include <utilshelper>
#tryinclude <vip_core>
#tryinclude <zombiereloaded>
#tryinclude <PlayerManager>

#undef REQUIRE_EXTENSIONS
#tryinclude <Voice>
#define REQUIRE_EXTENSIONS

#pragma newdecls required

Handle g_FriendsArray[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
bool g_bLateLoad = false;

public Plugin myinfo =
{
	name = "Advanced Targeting Extended",
	author = "BotoX, Obus, inGame, maxime1907",
	description = "Adds extra targeting methods",
	version = "1.3",
	url = ""
}

public void OnPluginStart()
{
#if defined _Voice_included
	AddMultiTargetFilter("@talking", Filter_Talking, "Talking", false);
#endif
	AddMultiTargetFilter("@admins", Filter_Admin, "Admins", false);
	AddMultiTargetFilter("@!admins", Filter_NotAdmin, "Not Admins", false);
	AddMultiTargetFilter("@friends", Filter_Friends, "Steam Friends", false);
	AddMultiTargetFilter("@!friends", Filter_NotFriends, "Not Steam Friends", false);
	AddMultiTargetFilter("@random", Filter_Random, "a Random Player", false);
	AddMultiTargetFilter("@randomct", Filter_RandomCT, "a Random CT", false);
	AddMultiTargetFilter("@randomt", Filter_RandomT, "a Random T", false);
	AddMultiTargetFilter("@vips", Filter_VIP, "VIPs", false);
	AddMultiTargetFilter("@!vips", Filter_NotVIP, "VIPs", false);
#if defined _zr_included
	AddMultiTargetFilter("@mzombies", Filter_MotherZombie, "Mother Zombies", false);
	AddMultiTargetFilter("@!mzombies", Filter_NotMotherZombie, "Not Mother Zombies", false);
#endif

#if defined _PlayerManager_included
	if (GetEngineVersion() != Engine_CSGO)
	{
		AddMultiTargetFilter("@steam", Filter_Steam, "Steam Players", false);
		AddMultiTargetFilter("@nosteam", Filter_NoSteam, "No-Steam Players", false);

		RegConsoleCmd("sm_steam", Command_Steam, "Currently online No-Steam players");
		RegConsoleCmd("sm_nosteam", Command_NoSteam, "Currently online No-Steam players");
	}
#endif

	RegConsoleCmd("sm_admins", Command_Admins, "Currently online admins.");
	RegConsoleCmd("sm_friends", Command_Friends, "Currently online friends.");
	RegConsoleCmd("sm_vips", Command_VIPs, "Currently online vips.");
#if defined _zr_included
	RegConsoleCmd("sm_mzombies", Command_MotherZombies, "Currently online mother zombies.");
#endif

	if(g_bLateLoad)
	{
		char sSteam32ID[32];
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i) &&
				GetClientAuthId(i, AuthId_Steam2, sSteam32ID, sizeof(sSteam32ID)))
			{
				OnClientAuthorized(i, sSteam32ID);
			}
		}
	}
}

public void OnPluginEnd()
{
#if defined _Voice_included
	RemoveMultiTargetFilter("@talking", Filter_Talking);
#endif

	RemoveMultiTargetFilter("@admins", Filter_Admin);
	RemoveMultiTargetFilter("@!admins", Filter_NotAdmin);
	RemoveMultiTargetFilter("@friends", Filter_Friends);
	RemoveMultiTargetFilter("@!friends", Filter_NotFriends);
	RemoveMultiTargetFilter("@random", Filter_Random);
	RemoveMultiTargetFilter("@randomct", Filter_RandomCT);
	RemoveMultiTargetFilter("@randomt", Filter_RandomT);
	RemoveMultiTargetFilter("@vips", Filter_VIP);
	RemoveMultiTargetFilter("@!vips", Filter_NotVIP);

#if defined _zr_included
	RemoveMultiTargetFilter("@mzombies", Filter_MotherZombie);
	RemoveMultiTargetFilter("@!mzombies", Filter_NotMotherZombie);
#endif

#if defined _PlayerManager_included
	if (GetEngineVersion() != Engine_CSGO)
	{
		RemoveMultiTargetFilter("@steam", Filter_Steam);
		RemoveMultiTargetFilter("@nosteam", Filter_NoSteam);
	}
#endif
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsClientFriend", Native_IsClientFriend);
	CreateNative("ReadClientFriends", Native_ReadClientFriends);
	RegPluginLibrary("AdvancedTargeting");

	g_bLateLoad = late;
	return APLRes_Success;
}

public Action Command_Admins(int client, int args)
{
	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Generic))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		CReplyToCommand(client, "[SM] Admins currently online: {green}%s", aBuf);
	}
	else
		CReplyToCommand(client, "[SM] Admins currently online: {green}none");

	return Plugin_Handled;
}

public Action Command_VIPs(int client, int args)
{
	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Custom1) && !GetAdminFlag(GetUserAdmin(i), Admin_Cheats))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		CReplyToCommand(client, "[SM] VIPs currently online: {pink}%s", aBuf);
	}
	else
		CReplyToCommand(client, "[SM] VIPs currently online: {pink}none");

	return Plugin_Handled;
}

public Action Command_MotherZombies(int client, int args)
{
	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i) && ZR_IsClientMotherZombie(i))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		CReplyToCommand(client, "[SM] Mother Zombies currently alive: {darkred}%s", aBuf);
	}
	else
		CReplyToCommand(client, "[SM] Mother Zombies currently alive: {pink}none");

	return Plugin_Handled;
}

public Action Command_Friends(int client, int args)
{
	if(!client)
		return Plugin_Handled;

	if(g_FriendsArray[client] == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Could not read your friendslist, your profile must be set to public!");
		return Plugin_Handled;
	}

	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			int Steam3ID = GetSteamAccountID(i);

			if(FindValueInArray(g_FriendsArray[client], Steam3ID) != -1)
			{
				GetClientName(i, aBuf2, sizeof(aBuf2));
				StrCat(aBuf, sizeof(aBuf), aBuf2);
				StrCat(aBuf, sizeof(aBuf), ", ");
			}
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		PrintToChat(client, "[SM] Friends currently online: {lightblue}%s", aBuf);
	}
	else
		PrintToChat(client, "[SM] Friends currently online: {pink}none");

	return Plugin_Handled;
}

public Action Command_Steam(int client, int args)
{
	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && PM_IsPlayerSteam(i))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		CReplyToCommand(client, "[SM] Steam clients online: {lightblue}%s", aBuf);
	}
	else
		CReplyToCommand(client, "[SM] Steam clients online: {pink}none");

	return Plugin_Handled;
}

public Action Command_NoSteam(int client, int args)
{
	char aBuf[1024];
	char aBuf2[MAX_NAME_LENGTH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !PM_IsPlayerSteam(i))
		{
			GetClientName(i, aBuf2, sizeof(aBuf2));
			StrCat(aBuf, sizeof(aBuf), aBuf2);
			StrCat(aBuf, sizeof(aBuf), ", ");
		}
	}

	if(strlen(aBuf))
	{
		aBuf[strlen(aBuf) - 2] = 0;
		CReplyToCommand(client, "[SM] No-Steam clients online: {lightblue}%s", aBuf);
	}
	else
		CReplyToCommand(client, "[SM] No-Steam clients online: {pink}none");

	return Plugin_Handled;
}

public bool Filter_Steam(const char[] sPattern, Handle hClients)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && PM_IsPlayerSteam(i))
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

public bool Filter_NoSteam(const char[] sPattern, Handle hClients)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && !PM_IsPlayerSteam(i))
		{
			PushArrayCell(hClients, i);
		}
	}
	return true;
}

#if defined _Voice_included
public bool Filter_Talking(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && IsClientTalking(i))
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}
#endif

public bool Filter_Admin(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Generic))
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_NotAdmin(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !GetAdminFlag(GetUserAdmin(i), Admin_Generic))
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_MotherZombie(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && ZR_IsClientMotherZombie(i))
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_NotMotherZombie(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && !ZR_IsClientMotherZombie(i) && ZR_IsClientZombie(i))
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_VIP(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
#if defined _vip_core_included
		if(IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i))
#else
		if(IsClientInGame(i) && !IsFakeClient(i) && GetAdminFlag(GetUserAdmin(i), Admin_Custom1))
#endif
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_NotVIP(const char[] sPattern, Handle hClients, int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
#if defined _vip_core_included
		if(IsClientInGame(i) && !IsFakeClient(i) && !VIP_IsClientVIP(i))
#else
		if(IsClientInGame(i) && !IsFakeClient(i) && !GetAdminFlag(GetUserAdmin(i), Admin_Custom1))
#endif
		{
			PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_Friends(const char[] sPattern, Handle hClients, int client)
{
	if(g_FriendsArray[client] == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Could not read your friendslist, your profile must be set to public!");
		return false;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			int Steam3ID = GetSteamAccountID(i);

			if(FindValueInArray(g_FriendsArray[client], Steam3ID) != -1)
				PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_NotFriends(const char[] sPattern, Handle hClients, int client)
{
	if(g_FriendsArray[client] == INVALID_HANDLE)
	{
		PrintToChat(client, "[SM] Could not read your friendslist, your profile must be set to public!");
		return false;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i))
		{
			int Steam3ID = GetSteamAccountID(i);

			if(FindValueInArray(g_FriendsArray[client], Steam3ID) == -1)
				PushArrayCell(hClients, i);
		}
	}

	return true;
}

public bool Filter_Random(const char[] sPattern, Handle hClients, int client)
{
	int iRand = GetRandomInt(1, MaxClients);

	if(IsClientInGame(iRand) && IsPlayerAlive(iRand))
		PushArrayCell(hClients, iRand);
	else
		Filter_Random(sPattern, hClients, client);

	return true;
}

public bool Filter_RandomCT(const char[] sPattern, Handle hClients, int client)
{
	int iCTCount = GetTeamClientCount(CS_TEAM_CT);

	if(!iCTCount)
		return false;

	int[] iCTs = new int[iCTCount];

	int iCurIndex;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != CS_TEAM_CT)
			continue;

		if(!IsPlayerAlive(i))
		{
			iCTCount--;
			continue;
		}

		iCTs[iCurIndex] = i;
		iCurIndex++;
	}

	PushArrayCell(hClients, iCTs[GetRandomInt(0, iCTCount-1)]);

	return true;
}

public bool Filter_RandomT(const char[] sPattern, Handle hClients, int client)
{
	int iTCount = GetTeamClientCount(CS_TEAM_T);

	if(!iTCount)
		return false;

	int[] iTs = new int[iTCount];

	int iCurIndex;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || GetClientTeam(i) != CS_TEAM_T)
			continue;

		if(!IsPlayerAlive(i))
		{
			iTCount--;
			continue;
		}

		iTs[iCurIndex] = i;
		iCurIndex++;
	}

	PushArrayCell(hClients, iTs[GetRandomInt(0, iTCount-1)]);

	return true;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if(IsFakeClient(client))
		return;

	char sSteam64ID[32];
	Steam32IDtoSteam64ID(auth, sSteam64ID, sizeof(sSteam64ID));

	char sSteamAPIKey[64];
	GetSteamAPIKey(sSteamAPIKey, sizeof(sSteamAPIKey));

	static char sRequest[256];
	FormatEx(sRequest, sizeof(sRequest), "http://api.steampowered.com/ISteamUser/GetFriendList/v0001/?key=%s&steamid=%s&relationship=friend&format=vdf", sSteamAPIKey, sSteam64ID);

	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sRequest);
	if (!hRequest ||
		!SteamWorks_SetHTTPRequestContextValue(hRequest, client) ||
		!SteamWorks_SetHTTPCallbacks(hRequest, OnTransferComplete) ||
		!SteamWorks_SendHTTPRequest(hRequest))
	{
		CloseHandle(hRequest);
	}
}

public void OnClientDisconnect(int client)
{
	if(g_FriendsArray[client] != INVALID_HANDLE)
		CloseHandle(g_FriendsArray[client]);

	g_FriendsArray[client] = INVALID_HANDLE;
}

public int OnTransferComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if(bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		// Private profile or maybe steam down?
		//LogError("SteamAPI HTTP Response failed: %d", eStatusCode);
		CloseHandle(hRequest);
		return;
	}

	int Length;
	SteamWorks_GetHTTPResponseBodySize(hRequest, Length);

	char[] sData = new char[Length];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sData, Length);
	//SteamWorks_GetHTTPResponseBodyCallback(hRequest, APIWebResponse, client);

	CloseHandle(hRequest);

	APIWebResponse(sData, client);
}

public void APIWebResponse(const char[] sData, int client)
{
	KeyValues Response = new KeyValues("SteamAPIResponse");
	if(!Response.ImportFromString(sData, "SteamAPIResponse"))
	{
		LogError("ImportFromString(sData, \"SteamAPIResponse\") failed.");
		delete Response;
		return;
	}

	if(!Response.JumpToKey("friends"))
	{
		LogError("JumpToKey(\"friends\") failed.");
		delete Response;
		return;
	}

	// No friends?
	if(!Response.GotoFirstSubKey())
	{
		//LogError("GotoFirstSubKey() failed.");
		delete Response;
		return;
	}

	if(g_FriendsArray[client] != INVALID_HANDLE)
		CloseHandle(g_FriendsArray[client]);

	g_FriendsArray[client] = CreateArray();

	char sCommunityID[32];
	do
	{
		Response.GetString("steamid", sCommunityID, sizeof(sCommunityID));

		PushArrayCell(g_FriendsArray[client], Steam64toSteam3(sCommunityID));
	}
	while(Response.GotoNextKey());

	delete Response;
}

public int Native_IsClientFriend(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int friend = GetNativeCell(2);

	if(client > MaxClients || client <= 0 || friend > MaxClients || friend <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not valid.");
		return -1;
	}

	if(!IsClientInGame(client) || !IsClientInGame(friend))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not in-game.");
		return -1;
	}

	if(IsFakeClient(client) || IsFakeClient(friend))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is fake-client.");
		return -1;
	}

	if(g_FriendsArray[client] == INVALID_HANDLE)
		return -1;

	if(IsClientAuthorized(friend))
	{
		int Steam3ID = GetSteamAccountID(friend);

		if(FindValueInArray(g_FriendsArray[client], Steam3ID) != -1)
			return 1;
	}

	return 0;
}

public int Native_ReadClientFriends(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if(client > MaxClients || client <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not valid.");
		return -1;
	}

	if(g_FriendsArray[client] != INVALID_HANDLE)
		return 1;

	return 0;
}