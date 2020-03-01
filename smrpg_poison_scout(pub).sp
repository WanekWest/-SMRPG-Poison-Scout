#pragma newdecls required
#pragma semicolon 1
#include <smrpg>
#include <sdkhooks>
#include <sdktools>

#define UPGRADE_SHORTNAME "pscout"
#define UPGRADE_SHORTNAME_fp "firepistol"
#define PLUGIN_VERSION "1.3.2"

float g_hDamageValue, g_hDelay,g_HDedValue,G_hTieRel,g_HNewPause;

int counter =0;

bool bRoundEnd;

public Plugin myinfo = 
{
	name = "SM:RPG Upgrade > Poison Scout",
	author = "WanekWest",
	description = "Poision Scout",
	version = PLUGIN_VERSION,
	url = "https://vk.com/wanek_west"
}

public void OnPluginStart()
{
	HookEvent("round_start", EventRoundStart);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("bomb_exploded", EventRoundStart);

	LoadTranslations("smrpg_stock_upgrades.phrases");
}

void EventRoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	bRoundEnd = true;
	CreateTimer(g_HNewPause, Timer_Reload, _, TIMER_FLAG_NO_MAPCHANGE);
}

void EventRoundEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	bRoundEnd = true;
}

void EventPlayerHurt(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int userid = hEvent.GetInt("userid"), attacker = hEvent.GetInt("attacker");
	int iLevel = SMRPG_GetClientUpgradeLevel(GetClientOfUserId(attacker), UPGRADE_SHORTNAME);
		
	if(userid != attacker && counter < iLevel && IsClientInGame(GetClientOfUserId(userid)) && IsClientInGame(GetClientOfUserId(attacker)) && IsPlayerAlive(GetClientOfUserId(userid)) && !SMRPG_IsUpgradeActiveOnClient(GetClientOfUserId(userid), UPGRADE_SHORTNAME_fp))
	{
		char sBuf[32];
		
		hEvent.GetString("weapon", sBuf, sizeof sBuf);
		
		if(strcmp(sBuf, "ssg08") == 0)
		{
			float dam = g_hDamageValue * iLevel;
			
			if(iLevel && counter >= 0)
			{
				DataPack hPack;

				CreateDataTimer(g_hDelay, TimerHurt, hPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				hPack.WriteCell(userid);
				hPack.WriteCell(attacker);
				hPack.WriteCell(iLevel);
				hPack.WriteCell(dam);
			}
		}
	}
	else
	{
		if(IsClientInGame(GetClientOfUserId(userid))  && IsPlayerAlive(GetClientOfUserId(userid)))
		{
			SetEntityRenderMode(GetClientOfUserId(userid), RENDER_TRANSCOLOR);
			SetEntityRenderColor(GetClientOfUserId(userid), 255, 255, 255, 255);
		}
		CreateTimer(G_hTieRel, Timer_Reload, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_Reload(Handle hTimer, any UserId)
{
	if(UserId && IsClientInGame(UserId) && IsPlayerAlive(UserId))
	{
		SetEntityRenderMode(UserId, RENDER_TRANSCOLOR);
		SetEntityRenderColor(UserId, 255, 255, 255, 255);
	}
	bRoundEnd = false;
	counter =0;
    return Plugin_Stop;
}

public void OnPluginEnd()
{
	if(SMRPG_UpgradeExists(UPGRADE_SHORTNAME))
	{
		SMRPG_UnregisterUpgradeType(UPGRADE_SHORTNAME);
	}
}

public void OnAllPluginsLoaded()
{
	OnLibraryAdded("smrpg");
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "smrpg"))
	{
		SMRPG_RegisterUpgradeType("pscout", UPGRADE_SHORTNAME, "Poison effect after shoot", 10, true, 5, 15, 10);
		SMRPG_SetUpgradeTranslationCallback(UPGRADE_SHORTNAME, SMRPG_TranslateUpgrade);

		ConVar hDamageValue = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_posion_damage", "10.0", "Add a damage for every new level(Level*value)", _, true, 0.0);
		hDamageValue.AddChangeHook(OnDMGChange);
		g_hDamageValue = hDamageValue.FloatValue;

		ConVar hDelay = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_poison_time", "2.0", "Delay between poison effect", _, true, 0.0);
		hDelay.AddChangeHook(OnDelayChange);
		g_hDelay = hDelay.FloatValue;

		ConVar hDedValue = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_damage_lower", "1.0", "How many damage will be deducated from next tick(Level*Value)", _, true, 0.0);
		hDedValue.AddChangeHook(OnDedChange);
		g_HDedValue = hDedValue.FloatValue;

		ConVar htimerel = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_skill_reload", "5.0", "How many time need for skill reload(in sec. Better to put 2+ sec)?", _, true, 0.0);
		htimerel.AddChangeHook(OnRelChange);
		G_hTieRel = htimerel.FloatValue;

		ConVar HNewPause = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_newround_save", "10.0", "How many time need for save in new round(8+ sec)?", _, true, 0.0);
		HNewPause.AddChangeHook(OnPauseChange);
		g_HNewPause = HNewPause.FloatValue;
	}
}

public void OnDMGChange(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_hDamageValue = hCvar.FloatValue;
}

public void OnDelayChange(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_hDelay = hCvar.FloatValue;
}

public void OnDedChange(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_HDedValue = hCvar.FloatValue;
}

public void OnRelChange(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	G_hTieRel = hCvar.FloatValue;
}

public void OnPauseChange(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_HNewPause = hCvar.FloatValue;
}

public bool SMRPG_ActiveQuery(int client)
{
	int upgrade[UpgradeInfo];
	SMRPG_GetUpgradeInfo(UPGRADE_SHORTNAME, upgrade);
	return SMRPG_IsEnabled() && upgrade[UI_enabled] && SMRPG_GetClientUpgradeLevel(client, UPGRADE_SHORTNAME) > 0;
}

public void SMRPG_TranslateUpgrade(int client, const char[] shortname, TranslationType type, char[] translation, int maxlen)
{
	if(type == TranslationType_Name)
		Format(translation, maxlen, "%T", UPGRADE_SHORTNAME, client);
	else if(type == TranslationType_Description)
	{
		char sDescriptionKey[MAX_UPGRADE_SHORTNAME_LENGTH+12] = UPGRADE_SHORTNAME;
		StrCat(sDescriptionKey, sizeof(sDescriptionKey), " description");
		Format(translation, maxlen, "%T", sDescriptionKey, client);
	}
}

Action TimerHurt(Handle hTimer, DataPack hPack)
{
	hPack.Reset();
		
	int userid = hPack.ReadCell();
	int attacker = hPack.ReadCell();
	int iCount = hPack.ReadCell();
	float damage = hPack.ReadCell();
	int iClient = GetClientOfUserId(userid);
	int iAttacker = GetClientOfUserId(attacker);
	int kos = iCount+1;

	if(!bRoundEnd)
	{		
		if(iClient && iAttacker && IsClientInGame(iClient) && IsClientInGame(iAttacker) && IsPlayerAlive(iClient))
		{
			float maindamage = damage - (iCount * g_HDedValue * counter);
			if(maindamage < 0.0)
			{
				maindamage = 1.0;
			}
			++counter;
			if(counter < kos)
			{
				SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iClient, 20, 255, 20, 255);
				SDKHooks_TakeDamage(iClient, iAttacker, iAttacker, maindamage, DMG_NEVERGIB, 0);

				CreateDataTimer(g_hDelay, TimerHurt, hPack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				hPack.WriteCell(userid);
				hPack.WriteCell(attacker);
				hPack.WriteCell(iCount);
				hPack.WriteCell(maindamage);
				return Plugin_Stop;	
			}
			else
			{
				SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
				SetEntityRenderColor(iClient, 255, 255, 255, 255);
				bRoundEnd = true;
			}
		}
	}
	CreateTimer(G_hTieRel, Timer_Reload, iClient, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}
