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
}

// Use the pre call of 'CCSPlayer::SetObserverTarget' in order to store
// the last observer target of the observer.
MRESReturn Detour_OnSetObserverTargetPre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    if (!g_Players[pThis].initialized)
    {
        return MRES_Ignored;
    }

    g_Players[pThis].UpdateObserverTarget();

    // *CBaseEntity is null.
    if (hParams.IsNull(1))
    {
        return MRES_Ignored;
    }

    int target = hParams.Get(1);
    if (target == -1)
    {
        // Couldn't get the target CBaseEntity index.
        return MRES_Ignored;
    }

    // Stop an infinite loop! (Frame_OverrideObserverTarget)
    if (g_Players[pThis].queued_observer_target == target)
    {
        g_Players[pThis].queued_observer_target = 0;
        return MRES_Ignored;
    }

    // The client hasn't changed their actual observer target, but rather their observer mode.
    if (target == g_Players[pThis].last_observer_target)
    {
        return MRES_Ignored;
    }

    int override_target = target;
    if (Call_OnObserverTargetChange(pThis, override_target, g_Players[pThis].last_observer_target) >= Plugin_Handled)
    {
        // Block the function according to the forward return.
        hReturn.Value = false;
        return MRES_Supercede;
    }

    if (override_target != target)
    {
        g_Players[pThis].queued_observer_target = override_target;

        DataPack dp = new DataPack();
        dp.WriteCell(g_Players[pThis].userid);
        dp.WriteCell(g_Players[override_target].userid);
        RequestFrame(Frame_OverrideObserverTarget, dp);

        hReturn.Value = false;
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

void Frame_OverrideObserverTarget(DataPack dp)
{
    dp.Reset();

    int observer_userid = dp.ReadCell(), observer_target_userid = dp.ReadCell();
    dp.Close();

    int observer = GetClientOfUserId(observer_userid);
    if (!observer)
    {
        return;
    }

    int observer_target = GetClientOfUserId(observer_target_userid);
    if (!observer_target)
    {
        return;
    }

    SDK_SetObserverTarget(observer, observer_target);
}

MRESReturn Detour_OnSetObserverTargetPost(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    if (!g_Players[pThis].initialized)
    {
        return MRES_Ignored;
    }

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

    Call_OnObserverTargetChangePost(pThis, target, g_Players[pThis].last_observer_target);
    return MRES_Ignored;
}

MRESReturn Detour_OnSetObserverModePre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    if (!g_Players[pThis].initialized)
    {
        return MRES_Ignored;
    }

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
    if (!g_Players[pThis].initialized)
    {
        return MRES_Ignored;
    }

    Call_OnObserverModeChangePost(pThis, hParams.Get(1), SDK_GetObserverMode(pThis));
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