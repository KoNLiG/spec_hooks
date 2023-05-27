/*
 *  • Registeration of all natives and forwards.
 *  • Registeration of the plugin library.
 */

#if !defined COMPILING_FROM_MAIN
#error "Attemped to compile from the wrong file"
#endif

// Global forward handles.
GlobalForward g_OnObserverTargetChange;
GlobalForward g_OnObserverTargetChangePost;
GlobalForward g_OnObserverModeChange;
GlobalForward g_OnObserverModeChangePost;

void InitializeAPI()
{
    CreateNatives();
    CreateForwards();

    RegPluginLibrary(SPEC_HOOKS_LIB_NAME);
}

// Natives
void CreateNatives()
{
    // bool SpecHooks_SetObserverTarget(int client, int target)
    CreateNative("SpecHooks_SetObserverTarget", Native_SetObserverTarget);

    // int SpecHooks_GetObserverTarget(int client)
    CreateNative("SpecHooks_GetObserverTarget", Native_GetObserverTarget);

    // bool SpecHooks_SetObserverMode(int client, int mode)
    CreateNative("SpecHooks_SetObserverMode", Native_SetObserverMode);

    // int SpecHooks_GetObserverMode(int client)
    CreateNative("SpecHooks_GetObserverMode", Native_GetObserverMode);

    // bool SpecHooks_IsValidObserverTarget(int client, int target)
    CreateNative("SpecHooks_IsValidObserverTarget", Native_IsValidObserverTarget);
}

any Native_SetObserverTarget(Handle plugin, int numParams)
{
    // Param 1: 'client'
    int client = GetNativeCell(1);

    // Param 2: 'client'
    int target = GetNativeCell(2);

    return SDK_SetObserverTarget(client, target);
}

any Native_GetObserverTarget(Handle plugin, int numParams)
{
    // Param 1: 'client'
    int client = GetNativeCell(1);

    if (!(1 <= client <= MaxClients))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    if (!IsClientInGame(client))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in-game", client);
    }

    return SDK_GetObserverTarget(client);
}

any Native_SetObserverMode(Handle plugin, int numParams)
{
    // Param 1: 'client'
    int client = GetNativeCell(1);

    // Param 2: 'client'
    int mode = GetNativeCell(2);
    if (!(OBS_MODE_NONE <= mode < NUM_OBSERVER_MODES))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid spectate mode specified. (%d)", mode);
    }

    return SDK_SetObserverMode(client, mode);
}

any Native_GetObserverMode(Handle plugin, int numParams)
{
    // Param 1: 'client'
    int client = GetNativeCell(1);

    if (!(1 <= client <= MaxClients))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    }

    if (!IsClientInGame(client))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in-game", client);
    }

    return SDK_GetObserverMode(client);
}

any Native_IsValidObserverTarget(Handle plugin, int numParams)
{
    // Param 1: 'client'
    int client = GetNativeCell(1);

    // Param 2: 'client'
    int target = GetNativeCell(2);

    return SDK_IsValidObserverTarget(client, target);
}

// Forwards.
void CreateForwards()
{
    g_OnObserverTargetChange = new GlobalForward(
        "SpecHooks_OnObserverTargetChange",
        ET_Hook,  // Mid-stops allowed.
        Param_Cell,  // int client
        Param_CellByRef,  // int &target
        Param_Cell // int last_target
        );

    g_OnObserverTargetChangePost = new GlobalForward(
        "SpecHooks_OnObserverTargetChangePost",
        ET_Ignore,  // Always return 0.
        Param_Cell,  // int client
        Param_Cell,  // int target
        Param_Cell // int last_target
        );

    g_OnObserverModeChange = new GlobalForward(
        "SpecHooks_OnObserverModeChange",
        ET_Hook,  // Mid-stops allowed.
        Param_Cell,  // int client
        Param_CellByRef,  // int &mode
        Param_Cell // int last_mode
        );

    g_OnObserverModeChangePost = new GlobalForward(
        "SpecHooks_OnObserverModeChangePost",
        ET_Ignore,  // Always return 0.
        Param_Cell,  // int client
        Param_Cell,  // int mode
        Param_Cell // int last_mode
        );
}

Action Call_OnObserverTargetChange(int client, int &target, int last_target)
{
    Action result;

    Call_StartForward(g_OnObserverTargetChange);
    Call_PushCell(client);
    Call_PushCellRef(target);
    Call_PushCell(last_target);
    Call_Finish(result);

    return result;
}

void Call_OnObserverTargetChangePost(int client, int target, int last_target)
{
    Call_StartForward(g_OnObserverTargetChangePost);
    Call_PushCell(client);
    Call_PushCell(target);
    Call_PushCell(last_target);
    Call_Finish();
}

Action Call_OnObserverModeChange(int client, int &mode, int last_mode)
{
    Action result;

    Call_StartForward(g_OnObserverModeChange);
    Call_PushCell(client);
    Call_PushCellRef(mode);
    Call_PushCell(last_mode);
    Call_Finish(result);

    return result;
}

void Call_OnObserverModeChangePost(int client, int mode, int last_mode)
{
    Call_StartForward(g_OnObserverModeChangePost);
    Call_PushCell(client);
    Call_PushCell(mode);
    Call_PushCell(last_mode);
    Call_Finish();
}