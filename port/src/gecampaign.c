/*
 * Continuous campaign for the GoldenEye 007 PC port. See gecampaign.h.
 *
 * The chain reuses the front end's own direct-to-stage route: the same
 * frontChangeMenu(MENU_RUN_STAGE, 1) that the mission-complete dossier makes
 * when it sends Cradle on to Cuba.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "platform.h"
#include "system.h"
#include "config.h"
#include "gecampaign.h"

#include "bondtypes.h"
#include "bondconstants.h"
#include "boss.h"
#include "bondview.h"
#include "bondview_r.h"
#include "bondinv.h"
#include "gun.h"
#include "player.h"
#include "front.h"
#include "file2.h"

int g_GeCampaignContinuous = 0;
int g_GeCampaignCarryInventory = 1;
int g_GeCampaignCarryHealth = 1;
int g_GeCampaignRetryOnDeath = 1;
int g_GeCampaignDifficulty = 0;
int g_GeCampaignDebugAutoComplete = 0;
int g_GeCampaignDebugAutoDie = 0;

PD_CONSTRUCTOR static void geCampaignConfigInit(void)
{
    configRegisterInt("Campaign.Continuous", &g_GeCampaignContinuous, 0, 1);
    configRegisterInt("Campaign.CarryInventory", &g_GeCampaignCarryInventory, 0, 1);
    configRegisterInt("Campaign.CarryHealth", &g_GeCampaignCarryHealth, 0, 1);
    configRegisterInt("Campaign.RetryOnDeath", &g_GeCampaignRetryOnDeath, 0, 1);
    configRegisterInt("Campaign.Difficulty", &g_GeCampaignDifficulty, 0, 2);
    configRegisterInt("Debug.CampaignAutoComplete", &g_GeCampaignDebugAutoComplete, 0, 3600);
    configRegisterInt("Debug.CampaignAutoDie", &g_GeCampaignDebugAutoDie, 0, 3600);
}

/* not exported through their headers */
extern s32 frontCompleteAllObjectivesAliveSuccess(void);          /* front.c */
extern s32 get_ammo_type_for_weapon(ITEM_IDS weapon);              /* gunfire.c */
extern void bondviewKillCurrentPlayer(void);                       /* bondview2.c */
extern int bondinvHasInvItem(ITEM_IDS item);                       /* bondinv.c */
extern bool bondinvHasDualWeapon(ITEM_IDS right, ITEM_IDS left);   /* bondinv.c */
extern void load_briefing_text_for_stage(void);                    /* front.c */

#define CAMPAIGN_MAX_WEAPONS 40
#define CAMPAIGN_NUM_AMMOTYPES 30   /* struct player ammoheldarr[30] */
#define CAMPAIGN_MIN_HEALTH 0.25f
#define CAMPAIGN_FIRST_PAGE 1       /* mission_folder_setup_entries[1] = Dam */

struct geloadout {
    int valid;
    int numweapons;
    int weapon_right[CAMPAIGN_MAX_WEAPONS];
    int weapon_left[CAMPAIGN_MAX_WEAPONS];   /* -1 when single */
    int ammo[CAMPAIGN_NUM_AMMOTYPES];
    float health;
    float armour;
};

static struct geloadout s_Carry;       /* applies to the next stage start */
static struct geloadout s_StageStart;  /* what the current stage started with */
static struct geloadout s_LastExit;    /* snapshot taken as the level ended */
static int s_RestorePending = 0;
static int s_InMission = 0;            /* a campaign stage started and has not been routed yet */
static int s_ForceComplete = 0;
static int s_DebugCompleteFired = 0;
static int s_DebugDieFired = 0;
static int s_Booted = 0;

/* Guns and throwables only: gadgets, keys and mission props come from each stage. */
static int geCampaignItemCarries(int item)
{
    return item >= ITEM_KNIFE && item <= ITEM_REMOTEMINE;
}

static int geCampaignActive(void)
{
    return g_GeCampaignContinuous && gamemode == GAMEMODE_SOLO && getPlayerCount() == 1;
}

static int geCampaignAmmoTotal(int ammotype)
{
    int total = g_CurrentPlayer->ammoheldarr[ammotype];
    int h;

    for (h = 0; h < 2; h++) {
        int weapon = g_CurrentPlayer->hands[h].weaponnum;

        if (weapon > ITEM_UNARMED && get_ammo_type_for_weapon(weapon) == ammotype) {
            total += g_CurrentPlayer->hands[h].weapon_ammo_in_magazine;
        }
    }

    return total;
}

static void geCampaignSnapshot(struct geloadout *out)
{
    int count = bondinvCountTotalItemsInInv();
    int i;

    memset(out, 0, sizeof(*out));
    out->valid = 1;

    for (i = 0; i < count && out->numweapons < CAMPAIGN_MAX_WEAPONS; i++) {
        InvItem *item = bondinvGetItemByIndex(i);

        if (item == NULL) {
            continue;
        }

        if (item->type == INV_ITEM_WEAPON && geCampaignItemCarries(item->type_inv_item.type_weap.weapon)) {
            out->weapon_right[out->numweapons] = item->type_inv_item.type_weap.weapon;
            out->weapon_left[out->numweapons] = -1;
            out->numweapons++;
        } else if (item->type == INV_ITEM_DUAL && geCampaignItemCarries(item->type_inv_item.type_dual.weapon_right)) {
            out->weapon_right[out->numweapons] = item->type_inv_item.type_dual.weapon_right;
            out->weapon_left[out->numweapons] = item->type_inv_item.type_dual.weapon_left;
            out->numweapons++;
        }
    }

    for (i = 1; i < CAMPAIGN_NUM_AMMOTYPES; i++) {
        out->ammo[i] = geCampaignAmmoTotal(i);
    }

    out->health = g_CurrentPlayer->bondhealth;
    out->armour = g_CurrentPlayer->bondarmour;
}

static void geCampaignLog(const char *what, const struct geloadout *l)
{
    char buf[512];
    int len = 0;
    int i;

    buf[0] = '\0';

    for (i = 0; i < l->numweapons && len < (int)sizeof(buf) - 24; i++) {
        if (l->weapon_left[i] >= 0) {
            len += snprintf(buf + len, sizeof(buf) - len, " %d+%d", l->weapon_right[i], l->weapon_left[i]);
        } else {
            len += snprintf(buf + len, sizeof(buf) - len, " %d", l->weapon_right[i]);
        }
    }

    sysLogPrintf(LOG_NOTE, "campaign: %s: health %.2f armour %.2f weapons[%d]%s",
                 what, l->health, l->armour, l->numweapons, buf);

    buf[0] = '\0';
    len = 0;

    for (i = 1; i < CAMPAIGN_NUM_AMMOTYPES && len < (int)sizeof(buf) - 16; i++) {
        if (l->ammo[i] > 0) {
            len += snprintf(buf + len, sizeof(buf) - len, " %d=%d", i, l->ammo[i]);
        }
    }

    sysLogPrintf(LOG_NOTE, "campaign: %s: ammo%s", what, buf);
}

/* Added on top of the stage's own intro items; nothing is ever taken away. */
static void geCampaignRestore(const struct geloadout *l)
{
    int i;

    if (g_GeCampaignCarryInventory) {
        for (i = 0; i < l->numweapons; i++) {
            int right = l->weapon_right[i];
            int left = l->weapon_left[i];

            if (left >= 0) {
                if (!bondinvHasDualWeapon(right, left)) {
                    weaponLoadProjectileModels(right);
                    weaponLoadProjectileModels(left);
                    bondinvAddDoublesInvItem(right, left);
                }
            } else if (!bondinvHasInvItem(right)) {
                weaponLoadProjectileModels(right);
                bondinvAddInvItem(right);
            }
        }

        for (i = 1; i < CAMPAIGN_NUM_AMMOTYPES; i++) {
            if (l->ammo[i] > g_CurrentPlayer->ammoheldarr[i]) {
                give_cur_player_ammo(i, l->ammo[i]);
            }
        }
    }

    if (g_GeCampaignCarryHealth) {
        float health = l->health;

        if (health < CAMPAIGN_MIN_HEALTH) {
            health = CAMPAIGN_MIN_HEALTH;
        }

        if (health < g_CurrentPlayer->bondhealth) {
            g_CurrentPlayer->bondhealth = health;
            g_CurrentPlayer->oldhealth = health;
            g_CurrentPlayer->apparenthealth = health;
        }

        if (l->armour > g_CurrentPlayer->bondarmour) {
            g_CurrentPlayer->bondarmour = l->armour;
            g_CurrentPlayer->oldarmour = l->armour;
            g_CurrentPlayer->apparentarmour = l->armour;
        }
    }
}

/* The mission_folder_setup_entries row for a solo level, or -1. */
static int geCampaignPageForMission(int mission_num)
{
    int i;

    for (i = 0; mission_folder_setup_entries[i].folder_text_preset; i++) {
        if (mission_folder_setup_entries[i].type == MISSION_PART
            && mission_folder_setup_entries[i].mission_num == mission_num) {
            return i;
        }
    }

    return -1;
}

static int geCampaignNextPage(int page)
{
    int entry = page + 1;

    while (mission_folder_setup_entries[entry].folder_text_preset) {
        if (mission_folder_setup_entries[entry].stage_id >= 0) {
            return entry;
        }

        entry++;
    }

    return -1;
}

static void geCampaignRunPage(int page)
{
    briefingpage = page;
    selected_stage = mission_folder_setup_entries[page].stage_id;
    frontChangeMenu(MENU_RUN_STAGE, 1);
}

void geCampaignBootMenu(void)
{
    if (s_Booted || !sysArgCheck("--campaign")) {
        return;
    }

    s_Booted = 1;
    g_GeCampaignContinuous = 1;

    /* saves[] is only populated by the legal screen's init; see Game.SkipIntro (D3xx) */
    fileValidateSaves();
    is_first_time_on_main_menu = FALSE;

    gamemode = GAMEMODE_SOLO;
    selected_difficulty = (DIFFICULTY)g_GeCampaignDifficulty;
    /* prev_keypresses stays FALSE: init_menus_or_reset turns it into a jump
     * to file select on every title load, which would eat the post-mission
     * return this module relies on */
    maybe_is_in_menu = TRUE;
    briefingpage = CAMPAIGN_FIRST_PAGE;
    {
        /* soak aid: GE_CAMPAIGN_PAGE=<row of mission_folder_setup_entries> starts later in the chain */
        const char *pg = getenv("GE_CAMPAIGN_PAGE");

        if (pg && *pg) {
            int page = (int)strtol(pg, NULL, 0);

            if (page >= CAMPAIGN_FIRST_PAGE && mission_folder_setup_entries[page].folder_text_preset
                && mission_folder_setup_entries[page].stage_id >= 0) {
                briefingpage = page;
            }
        }
    }
    selected_stage = mission_folder_setup_entries[briefingpage].stage_id;
    menu_update = MENU_RUN_STAGE;

    sysLogPrintf(LOG_NOTE, "campaign: continuous on, booting into stage %d (page %d) at difficulty %d; carry inventory %d health %d, retry on death %d",
                 selected_stage, briefingpage, (int)selected_difficulty, g_GeCampaignCarryInventory,
                 g_GeCampaignCarryHealth, g_GeCampaignRetryOnDeath);
}

void geCampaignOnLevelExit(void)
{
    if (!geCampaignActive() || bossGetStageNum() == LEVELID_TITLE || bossGetStageNum() == LEVELID_CUBA) {
        return;
    }

    geCampaignSnapshot(&s_LastExit);
    geCampaignLog("level exit", &s_LastExit);
}

/*
 * The front end decides the post-mission screen when the stage is LAUNCHED:
 * menu_init's MENU_RUN_STAGE case queues MENU_MISSION_FAILED (the dossier that
 * shows either outcome), the stage runs, and the queued menu takes effect when
 * the title stage loads again. That reload is where this runs, so the queued
 * dossier can be swapped for the next stage before any menu is drawn.
 */
void geCampaignAfterStage(void)
{
    int page = briefingpage;
    int mission;
    int success;

    if (!s_InMission || !geCampaignActive() || page < CAMPAIGN_FIRST_PAGE) {
        return;
    }

    s_InMission = 0;

    if (selected_stage == LEVELID_CUBA) {
        return;
    }

    if (menu_update != MENU_MISSION_FAILED) {
        sysLogPrintf(LOG_NOTE, "campaign: back from stage %d with menu 0x%x queued instead of the dossier", selected_stage, (int)menu_update);
    }

    if (mission_failed_or_aborted) {
        /* The player chose to leave: the normal dossier and menus take over */
        sysLogPrintf(LOG_NOTE, "campaign: mission aborted, handing back to the menus");
        return;
    }

    /* the dossier's own init would load this; the success check reads it */
    load_briefing_text_for_stage();

    mission = mission_folder_setup_entries[page].mission_num;
    success = s_ForceComplete || frontCompleteAllObjectivesAliveSuccess();
    s_ForceComplete = 0;

    if (success) {
        struct geloadout *carry = s_LastExit.valid ? &s_LastExit : &s_StageStart;

        s_Carry = *carry;
        geCampaignLog("carrying forward", &s_Carry);

        if (mission == SP_LEVEL_CRADLE) {
            /* The story ending plays as its own stage; the cast display follows it */
            sysLogPrintf(LOG_NOTE, "campaign: Cradle complete -> Cuba (ending)");
            s_RestorePending = 0;
            selected_stage = LEVELID_CUBA;
            frontChangeMenu(MENU_RUN_STAGE, 1);
            return;
        }

        if (mission == SP_LEVEL_EGYPT) {
            sysLogPrintf(LOG_NOTE, "campaign: Egyptian complete -> campaign complete");
            s_RestorePending = 0;
            return; /* the normal mission-complete dossier for the last one */
        }

        {
            int next = geCampaignNextPage(page);

            if (next < 0) {
                return;
            }

            sysLogPrintf(LOG_NOTE, "campaign: stage %d (page %d) complete -> stage %d (page %d)",
                         selected_stage, page, mission_folder_setup_entries[next].stage_id, next);
            s_RestorePending = 1;
            geCampaignRunPage(next);
            return;
        }
    }

    if (!g_GeCampaignRetryOnDeath) {
        return;
    }

    sysLogPrintf(LOG_NOTE, "campaign: stage %d (page %d) failed (%s) -> retry",
                 selected_stage, page, g_isBondKIA ? "dead" : "objectives");
    s_Carry = s_StageStart;
    s_RestorePending = s_StageStart.valid;
    geCampaignRunPage(page);
}

int geCampaignAfterCast(void)
{
    int aztec;

    if (!geCampaignActive()) {
        return 0;
    }

    aztec = geCampaignPageForMission(SP_LEVEL_AZTEC);

    if (aztec < 0) {
        return 0;
    }

    sysLogPrintf(LOG_NOTE, "campaign: ending shown -> Aztec (page %d)", aztec);
    s_RestorePending = 1;
    geCampaignRunPage(aztec);
    return 1;
}

void geCampaignOnPlayerReset(void)
{
    s_DebugCompleteFired = 0;
    s_ForceComplete = 0;
    s_LastExit.valid = 0;

    if (!geCampaignActive() || bossGetStageNum() == LEVELID_TITLE || bossGetStageNum() == LEVELID_CUBA) {
        s_RestorePending = 0;
        return;
    }

    if (s_RestorePending && s_Carry.valid) {
        geCampaignRestore(&s_Carry);
        geCampaignLog("restored", &s_Carry);
    }

    s_RestorePending = 0;
    s_InMission = 1;

    geCampaignSnapshot(&s_StageStart);
    geCampaignLog("stage start", &s_StageStart);
    sysLogPrintf(LOG_NOTE, "campaign: stage %d (page %d) started at difficulty %d",
                 bossGetStageNum(), briefingpage, (int)selected_difficulty);
}

extern u32 *g_LangBanks[45];

/*
 * A stage's text bank lives in the stage pool, which is gone when the stage
 * unloads, but the game only clears a bank from the briefing screen, which the
 * campaign never shows. The Cuba credits read bank 12 (Depot's slot) with text
 * ids the port never resolves, and a chain that had passed through Depot
 * faulted on the stale pointer. Every stage bank is cleared at each stage load;
 * the stage about to load fills its own bank afterwards, and the permanent
 * banks (guns, titles, menus) are untouched.
 */
void geLangClearStageBanks(void)
{
    int i;

    for (i = LAME; i <= LWAX; i++) {
        g_LangBanks[i] = NULL;
    }
}

/*
 * Diagnostic for the Cuba credits: the campaign's Cradle -> Cuba hand-over
 * crashed in textMeasure on a garbage string pointer. Logs the first entries'
 * text ids, their bank slots and the resolved pointer; refuses an implausible
 * pointer so the level can finish instead of faulting.
 */

int geCreditsTextGuard(int textid, u8 *text)
{
    static int logged = 0;
    int bank = (textid >> 10) & 0x3f;
    int bad = text == NULL || (uintptr_t)text < 0x10000 || (uintptr_t)text >= 0x400000000ULL;

    if (logged < 12 || bad) {
        if (logged < 40) {
            sysLogPrintf(LOG_NOTE, "credits: id 0x%04x bank %d bankptr %p text %p%s",
                         textid, bank, (bank < 45) ? (void *)g_LangBanks[bank] : NULL, (void *)text,
                         bad ? " (skipped)" : "");
            logged++;
        }
    }

    return bad;
}

void geCampaignTick(void)
{
    int elapsed;

    if (!geCampaignActive() || bossGetStageNum() == LEVELID_TITLE || bossGetStageNum() == LEVELID_CUBA) {
        return;
    }

    if (g_CurrentPlayer == NULL || g_CurrentPlayer->bonddead) {
        return;
    }

    elapsed = getMissiontimer();

    if (g_GeCampaignDebugAutoDie > 0 && !s_DebugDieFired && elapsed >= g_GeCampaignDebugAutoDie * 60) {
        s_DebugDieFired = 1;
        sysLogPrintf(LOG_NOTE, "campaign: debug: killing Bond after %d seconds", g_GeCampaignDebugAutoDie);
        bondviewKillCurrentPlayer();
        return;
    }

    if (g_GeCampaignDebugAutoComplete > 0 && !s_DebugCompleteFired && elapsed >= g_GeCampaignDebugAutoComplete * 60) {
        s_DebugCompleteFired = 1;
        s_ForceComplete = 1;
        sysLogPrintf(LOG_NOTE, "campaign: debug: forcing stage %d complete after %d seconds",
                     bossGetStageNum(), g_GeCampaignDebugAutoComplete);
        bossReturnTitleStage();
    }
}
