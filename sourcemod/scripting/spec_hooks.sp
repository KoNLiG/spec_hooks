#include <sourcemod>
#include <dhooks>
#include <spec_hooks>

#pragma semicolon 1
#pragma newdecls required

enum struct Player
{
    // This player slot index.
    int index;

    // Last observer client index.
    int last_observer_target;
    // Last observer mode. See the enum in spec_hooks.inc
    int last_observer_mode;
    //================================//
    void Init(int client)
    {
        this.index = client;
        this.last_observer_target = -1;
    }

    void Close()
    {
        this.last_observer_target = 0;
        this.last_observer_mode = 0;
    }

    void UpdateObserverTarget()
    {
        this.last_observer_target = SDK_GetObserverTarget(this.index);
    }

    void UpdateObserverMode()
    {
        this.last_observer_target = SDK_GetObserverTarget(this.index);
    }
}

Player g_Players[MAXPLAYERS + 1];

// External file compilation protection.
#define COMPILING_FROM_MAIN
#include "spec_hooks/sdk.sp"
#include "spec_hooks/api.sp"
#undef COMPILING_FROM_MAIN

bool g_Lateload;

public Plugin myinfo =
{
    name = "[API] Spectator Hooks",
    author = "KoNLiG",
    description = "Provides an API to catch and manage spectator events.",
    version = "1.0.0",
    url = "https://steamcommunity.com/id/KoNLiG/ || KoNLiG#6417"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Lock the use of this plugin for CS:GO only.
    if (GetEngineVersion() != Engine_CSGO)
    {
        strcopy(error, err_max, "This plugin was made for use with CS:GO only.");
        return APLRes_Failure;
    }

    // Initialzie API stuff.
    InitializeAPI();

    g_Lateload = late;

    return APLRes_Success;
}

public void OnPluginStart()
{
    // Initialize all SDK stuff.
    InitializeSDK();

    if (g_Lateload)
    {
        Lateload();
    }
}

public void OnClientPutInServer(int client)
{
    g_Players[client].Init(client);
}

public void OnClientDisconnect(int client)
{
    g_Players[client].Close();
}

void Lateload()
{
    for (int current_client = 1; current_client <= MaxClients; current_client++)
    {
        if (IsClientInGame(current_client))
        {
            OnClientPutInServer(current_client);
        }
    }
}