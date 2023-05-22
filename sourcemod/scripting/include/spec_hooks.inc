#if defined _spec_hooks_included
 #endinput
#endif
#define _spec_hooks_included

#define SPEC_HOOKS_LIB_NAME "spec_hooks"

// https://github.com/perilouswithadollarsign/cstrike15_src/blob/master/game/shared/shareddefs.h#L519-L531
// Spectator Movement modes
enum
{
    OBS_MODE_NONE = 0,  // not in spectator mode
    OBS_MODE_DEATHCAM,  // special mode for death cam animation
    OBS_MODE_FREEZECAM, // zooms to a target, and freeze-frames on them
    OBS_MODE_FIXED,     // view from a fixed camera position
    OBS_MODE_IN_EYE,    // follow a player in first person view
    OBS_MODE_CHASE,     // follow a player in third person view
    OBS_MODE_ROAMING,   // free roaming

    NUM_OBSERVER_MODES,
};

/**
 * Sets the target for an observer.
 *
 * @param client            Observer client index.
 * @param target            Target client index.
 *
 * @return                	True on success, false otherwise.
 * @error                   Invalid client/target index, or client/target is not in-game.
 */
native bool SpecHooks_SetObserverTarget(int client, int target);

/**
 * Retrieves the current target of an observer.
 *
 * @param client            Observer client index.
 *
 * @return                	Target client index, or -1 if the client is not an observer.
 * @error                   Invalid client index, or client is not in-game.
 */
native int SpecHooks_GetObserverTarget(int client);

/**
 * Sets the view mode for an observer.
 *
 * @param client            Observer client index.
 * @param mode            	Desired spectate mode. See the enum above.
 *
 * @return                	True on success, false otherwise.
 * @error                   Invalid client index, client is not in-game, or an invalid spectate mode was specified.
 */
native bool SpecHooks_SetObserverMode(int client, int mode);

/**
 * Retrieves the view mode of an observer.
 *
 * @param client            Observer client index.
 *
 * @return                	Spectate mode. See the enum above.
 * @error                   Invalid client index or client is not in-game.
 */
native int SpecHooks_GetObserverMode(int client);

/**
 * Retrieves whether an observer target is valid for the specified client.
 *
 * @param client            Observer client index.
 * @param target            Target client index.
 *
 * @return                	True if the target is valid for client to spectate, false otherwise.
 * @error                   Invalid client/target index, or client/target is not in-game.
 */
native bool SpecHooks_IsValidObserverTarget(int client, int target);

/**
 * Called when the game is performing validation checks between an observer and target.
 *
 * Note: this forward is called for each and every frame, therefore you should avoid
 * doing expensive computations or declaring large local arrays.
 *
 * @param client            Observer client index.
 * @param target            Target to perform checks on.
 *
 * @return             	 	An Action value. Returning Plugin_Handled bypasses the game function call.
 */
forward Action SpecHooks_OnValidObserverTarget(int client, int target);

/**
 * Called after a client has changed their 'm_hObserverTarget' value. (CBasePlayer::SetObserverTarget)
 *
 * Note: To filter out certain targets from being spectateable, use 'SpecHooks_OnValidObserverTarget'.
 *
 * @param client            Observer client index.
 * @param target            New target that we're currently spectating.
 * @param last_target       Old target that we were spectating.
 */
forward void SpecHooks_OnObserverTargetChange(int client, int target, int last_target);

/**
 * Called before a client has changed their 'm_hObserverMode' value. (CBasePlayer::SetObserverMode)
 *
 * @param client            Observer client index.
 * @param mode              New target mode that we're currently using (By reference). See the enum above.
 * @param last_mode         Old target mode that was used. See the enum above.
 *
 * @return                  An Action value.
 *                          Returning Plugin_Handled bypasses the game function call.
 *                          Returning Plugin_Stop bypasses the post hook as well as the game function.
 *                          Returning Plugin_Changed overrides 'mode' with the given value.
 */
forward Action SpecHooks_OnObserverModeChange(int client, int &mode, int last_mode);

/**
 * Called after a client has changed their 'm_hObserverMode' value. (CBasePlayer::SetObserverMode)
 *
 * Note: To block this action, use 'SpecHooks_OnObserverModeChange'.
 *
 * @param client            Observer client index.
 * @param mode              New target mode that we're currently using. See the enum above.
 * @param last_mode         Old target mode that was used. See the enum above.
 */
forward void SpecHooks_OnObserverModeChangePost(int client, int mode, int last_mode);

#if !defined REQUIRE_PLUGIN
public __pl_spec_hooks_SetNTVOptional()
{
    MarkNativeAsOptional("SpecHooks_SetObserverTarget");
    MarkNativeAsOptional("SpecHooks_GetObserverTarget");
    MarkNativeAsOptional("SpecHooks_SetObserverMode");
    MarkNativeAsOptional("SpecHooks_GetObserverMode");
    MarkNativeAsOptional("SpecHooks_IsValidObserverTarget");
}
#endif

public SharedPlugin __pl_spec_hooks =
{
    name = SPEC_HOOKS_LIB_NAME,
    file = "spec_hooks.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};