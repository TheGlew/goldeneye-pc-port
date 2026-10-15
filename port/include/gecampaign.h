#ifndef PORT_GECAMPAIGN_H
#define PORT_GECAMPAIGN_H

/*
 * Continuous campaign (PC port only).
 *
 * With Campaign.Continuous on, a completed solo mission rolls straight into
 * the next one: no mission-complete dossier, no briefing screen in between.
 * Bond keeps his guns, ammo, health and body armour from one mission to the
 * next, and dying puts him straight back at the start of the mission instead
 * of showing the failure dossier.
 *
 * Only solo play is touched, and nothing runs while Campaign.Continuous is off.
 * This is a deliberate game-flow change for the local fork, not a fidelity
 * fix: it does not belong upstream.
 */

/* ge007.ini [Campaign] */
extern int g_GeCampaignContinuous;
extern int g_GeCampaignCarryInventory;
extern int g_GeCampaignCarryHealth;
extern int g_GeCampaignRetryOnDeath;
extern int g_GeCampaignDifficulty;
extern int g_GeCampaignExitWhenComplete;

/* ge007.ini [Debug] - soak scaffolding, never on by default */
extern int g_GeCampaignDebugAutoComplete;
extern int g_GeCampaignDebugAutoDie;

/* lvlStageLoad(LEVELID_TITLE): --campaign boots straight into Dam. */
void geCampaignBootMenu(void);
/* bossReturnTitleStage: the level is ending, remember what Bond holds. */
void geCampaignOnLevelExit(void);
/* lvlStageLoad(LEVELID_TITLE) after a solo mission: the game has queued the
 * mission dossier (menu_update == MENU_MISSION_FAILED); the campaign replaces
 * it with the next stage, or a retry. */
void geCampaignAfterStage(void);
/* front.c cast display after Cuba: returns 1 when the campaign moves on to Aztec. */
int  geCampaignAfterCast(void);
/* bondviewLoadSetupIntroSection, after the intro items: carry the loadout in. */
void geCampaignOnPlayerReset(void);
/* lvlMainloop: per-frame (debug soak triggers). */
void geCampaignTick(void);

#endif /* PORT_GECAMPAIGN_H */
