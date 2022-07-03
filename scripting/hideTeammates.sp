#pragma newdecls required;
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>
#include <clientprefs>

public Plugin myinfo =
{
	name    = "Hide Teammates",
	author  = "Happy",
	version = "0.0.1",
	url     = "https://hxppy.xyz/"
};

bool g_bDisableSound[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_bHideTeammates[MAXPLAYERS + 1];

Handle g_hHideTeammates;

public void OnPluginStart()
{
	RegConsoleCmd("sm_hide", Command_Hide);
	
	g_hHideTeammates = RegClientCookie("hide_teammates", "hide_teammates", CookieAccess_Protected);

	for (int i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientCookiesCached(i);
			OnClientPutInServer(i);
		}
	}

	AddNormalSoundHook(OnNormalSoundPlayed);
}

public Action Command_Hide(int client, int args)
{
	g_bHideTeammates[client] = !g_bHideTeammates[client];

	if (g_bHideTeammates[client] == true)
	{
		SetClientCookie(client, g_hHideTeammates, "1");
		ReplyToCommand(client, "[SM] Teammates are now hidden.");
	}
	else if (g_bHideTeammates[client] == false)
	{
		SetClientCookie(client, g_hHideTeammates, "0");
		ReplyToCommand(client, "[SM] Teammates are now shown.");
	}

	return Plugin_Handled;
}

public void OnClientCookiesCached(int client)
{
	char sCookie[32];
	
	GetClientCookie(client, g_hHideTeammates, sCookie, sizeof(sCookie));
	
	if(sCookie[0] == '\0')
	{
		SetClientCookie(client, g_hHideTeammates, "0");
	}

	g_bHideTeammates[client] = view_as<bool>(StringToInt(sCookie));
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
}

public Action OnTransmit(int entity, int client)
{
	if(!IsValidClient(client, true))
		return Plugin_Continue;

	if(g_bHideTeammates[client])
	{
		if (entity != client && 0 < entity <= MaxClients)
		{
			if (GetClientTeam(client) == GetClientTeam(entity))
			{
				g_bDisableSound[client][entity] = true;
				return Plugin_Handled;
			}
			else
			{
				g_bDisableSound[client][entity] = false;
			}
		}
	}
	else
	{
		g_bDisableSound[client][entity] = false;
	}

	return Plugin_Continue;
}

public Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (StrContains(sample, "physics/") != -1 || StrContains(sample, "weapons/") != -1 || StrContains(sample, "player/") != -1 || StrContains(sample, "items/") != -1)
	{
		int i, j;

		if(!IsValidClient(entity))
			return Plugin_Continue;

		for (i = 0; i < numClients; i++)
		{
			if(IsValidClient(clients[i]))
			{
				if (g_bDisableSound[clients[i]][entity] && IsPlayerAlive(clients[i]))
				{
					for (j = i; j < numClients - 1; j++)
					{
						clients[j] = clients[j + 1];
					}

					numClients--;
					i--;
				}
			}
		}

		return (numClients > 0) ? Plugin_Changed : Plugin_Stop;
	}

	return Plugin_Continue;
}

bool IsValidClient(int client, bool alive = false)
{
	if (0 < client && client <= MaxClients && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
}