/*
 *  • Load server offsets and signatures from the GameData configuration file.
 *  • Help functions to implement SDKCall handles and replicate game functions.
 */

#if !defined COMPILING_FROM_MAIN
#error "Attemped to compile from the wrong file"
#endif

// Network/Data map properties offsets.
int m_hObserverTargetOffset;
int m_iObserverModeOffset;

// SDKCall handles.
Handle g_SetObserverTarget;
Handle g_SetObserverMode;
Handle g_IsValidObserverTarget;

// Dynamic Detour handles.
DynamicDetour g_SetObserverTargetDetour;
DynamicDetour g_SetObserverModeDetour;
DynamicDetour g_IsValidObserverTargetDetour;

void InitializeSDK()
{
    GetPropsOffsets();

    GameData gamedata = new GameData("spec_hooks.games");

    PrepSDKCalls(gamedata);

    CreateDetourHooks(gamedata);

    delete gamedata;
}

void GetPropsOffsets()
{
    if ((m_hObserverTargetOffset = FindSendPropInfo("CBasePlayer", "m_hObserverTarget")) <= 0)
    {
        SetFailState("Failed to find netprop offset 'CBasePlayer::m_hObserverTarget'");
    }

    if ((m_iObserverModeOffset = FindSendPropInfo("CBasePlayer", "m_iObserverMode")) <= 0)
    {
        SetFailState("Failed to find netprop offset 'CBasePlayer::m_iObserverMode'");
    }
}

void PrepSDKCalls(GameData gamedata)
{
    // SDKCalls
    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CCSPlayer::SetObserverTarget"))
    {
        SetFailState("Missing signature 'CCSPlayer::SetObserverTarget'");
    }

    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);

    if (!(g_SetObserverTarget = EndPrepSDKCall()))
    {
        SetFailState("Failed to setup 'CCSPlayer::SetObserverTarget'");
    }

    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBasePlayer::SetObserverMode"))
    {
        SetFailState("Missing signature 'CBasePlayer::SetObserverMode'");
    }

    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);

    if (!(g_SetObserverMode = EndPrepSDKCall()))
    {
        SetFailState("Failed to setup 'CBasePlayer::SetObserverMode'");
    }

    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CCSPlayer::IsValidObserverTarget"))
    {
        SetFailState("Missing signature 'CCSPlayer::IsValidObserverTarget'");
    }

    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);

    if (!(g_IsValidObserverTarget = EndPrepSDKCall()))
    {
        SetFailState("Failed to setup 'CCSPlayer::IsValidObserverTarget'");
    }
}

void CreateDetourHooks(GameData gamedata)
{
    // Hook CCSPlayer::SetObserverTarget.
    if (!(g_SetObserverTargetDetour = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity)))
    {
        SetFailState("Failed to setup detour for 'CCSPlayer::SetObserverTarget'");
    }

    if (!g_SetObserverTargetDetour.SetFromConf(gamedata, SDKConf_Signature, "CCSPlayer::SetObserverTarget"))
    {
        SetFailState("Failed to load 'CCSPlayer::SetObserverTarget' signature from gamedata");
    }

    // Add parameters
    g_SetObserverTargetDetour.AddParam(HookParamType_CBaseEntity); // CBaseEntity* target

    if (!g_SetObserverTargetDetour.Enable(Hook_Pre, Detour_OnSetObserverTargetPre))
    {
        SetFailState("Failed to detour 'CCSPlayer::SetObserverTarget' pre.");
    }

    if (!g_SetObserverTargetDetour.Enable(Hook_Post, Detour_OnSetObserverTargetPost))
    {
        SetFailState("Failed to detour 'CCSPlayer::SetObserverTarget' post.");
    }

    // Hook CBasePlayer::SetObserverMode.
    if (!(g_SetObserverModeDetour = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity)))
    {
        SetFailState("Failed to setup detour for 'CBasePlayer::SetObserverMode'");
    }

    if (!g_SetObserverModeDetour.SetFromConf(gamedata, SDKConf_Signature, "CBasePlayer::SetObserverMode"))
    {
        SetFailState("Failed to load 'CBasePlayer::SetObserverMode' signature from gamedata");
    }

    // Add parameters
    g_SetObserverModeDetour.AddParam(HookParamType_Int); // int mode

    if (!g_SetObserverModeDetour.Enable(Hook_Pre, Detour_OnSetObserverModePre))
    {
        SetFailState("Failed to detour 'CBasePlayer::SetObserverMode' pre.");
    }

    if (!g_SetObserverModeDetour.Enable(Hook_Post, Detour_OnSetObserverModePost))
    {
        SetFailState("Failed to detour 'CBasePlayer::SetObserverMode' post.");
    }

    // Hook CCSPlayer::IsValidObserverTarget.
    if (!(g_IsValidObserverTargetDetour = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity)))
    {
        SetFailState("Failed to setup detour for 'CCSPlayer::IsValidObserverTarget'");
    }

    if (!g_IsValidObserverTargetDetour.SetFromConf(gamedata, SDKConf_Signature, "CCSPlayer::IsValidObserverTarget"))
    {
        SetFailState("Failed to load 'CCSPlayer::IsValidObserverTarget' signature from gamedata");
    }

    // Add parameters
    g_IsValidObserverTargetDetour.AddParam(HookParamType_CBaseEntity); // CBaseEntity* target

    if (!g_IsValidObserverTargetDetour.Enable(Hook_Pre, Detour_OnIsValidObserverTarget))
    {
        SetFailState("Failed to detour 'CCSPlayer::IsValidObserverTarget'");
    }
}

// Use the pre call of 'CCSPlayer::SetObserverTarget' in order to store
// the last observer target of the observer.
MRESReturn Detour_OnSetObserverTargetPre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    g_Players[pThis].UpdateObserverTarget();
    return MRES_Ignored;
}

MRESReturn Detour_OnSetObserverTargetPost(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    // The specified observer target is invalid.
    if (!hReturn.Value)
    {
        return MRES_Ignored;
    }

    int target = hParams.Get(1);
    if (target == -1)
    {
        // Couldn't get the target CBaseEntity index.
        return MRES_Ignored;
    }

    // The client hasn't changed their actual observer target, but rather their observer mode.
    if (target == g_Players[pThis].last_observer_target)
    {
        return MRES_Ignored;
    }

    Call_OnObserverTargetChange(pThis, target, g_Players[pThis].last_observer_target);
    return MRES_Ignored;
}

MRESReturn Detour_OnSetObserverModePre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    int mode = hParams.Get(1);

    int last_mode = SDK_GetObserverMode(pThis);
    Action ret = Call_OnObserverModeChange(pThis, mode, last_mode);

    g_Players[pThis].last_observer_mode = last_mode;

    // Forward wants to stop this function from running.
    if (ret >= Plugin_Handled)
    {
        hReturn.Value = false;
        return ret == Plugin_Stop ? MRES_Supercede : MRES_Override;
    }
    // Forward changed 'mode', update it.
    else if (ret == Plugin_Changed)
    {
        hParams.Set(1, mode);
        return MRES_ChangedHandled;
    }

    // Forward did nothing.
    return MRES_Ignored;
}

MRESReturn Detour_OnSetObserverModePost(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    Call_OnObserverModeChangePost(pThis, hParams.Get(1), SDK_GetObserverMode(pThis));
    return MRES_Ignored;
}

MRESReturn Detour_OnIsValidObserverTarget(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    // Target 'CBaseEntity' pointer isn't available.
    if (hParams.IsNull(1))
    {
        return MRES_Ignored;
    }

    if (Call_OnValidObserverTarget(pThis, hParams.Get(1)) >= Plugin_Handled)
    {
        hReturn.Value = false;
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

int SDK_GetObserverTarget(int client)
{
    return GetEntDataEnt2(client, m_hObserverTargetOffset);
}

int SDK_GetObserverMode(int client)
{
    return GetEntData(client, m_iObserverModeOffset);
}

bool SDK_SetObserverTarget(int client, int target)
{
    return SDKCall(g_SetObserverTarget, client, target);
}

bool SDK_SetObserverMode(int client, int mode)
{
    return SDKCall(g_SetObserverMode, client, mode);
}

bool SDK_IsValidObserverTarget(int client, int target)
{
    return SDKCall(g_IsValidObserverTarget, client, target);
}