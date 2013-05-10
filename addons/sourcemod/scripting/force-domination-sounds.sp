#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>

#define VERSION "1.1"

#pragma semicolon 1

/*
	TFClass_Unknown = 0,
	TFClass_Scout,
	TFClass_Sniper,
	TFClass_Soldier,
	TFClass_DemoMan,
	TFClass_Medic,
	TFClass_Heavy,
	TFClass_Pyro,
	TFClass_Spy,
	TFClass_Engineer
	*/
new String:g_ClassNames[TFClassType][16] = { "Unknown", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

new Handle:g_Cvar_Log;
new Handle:g_Cvar_Disguised;
new Handle:g_Cvar_Cloaked;

public Plugin:myinfo = 
{
	name = "Force Domination Sounds",
	author = "Powerlord",
	description = "Force a player to play one of their domination or revenge sounds",
	version = VERSION,
	url = "URL"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("force-domination-sounds.phrases");
	CreateConVar("dominationsounds_version", VERSION, "Domination Sounds version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_Log = CreateConVar("dominationsounds_log", "1", "Log when a command forces a player to play a domination sound", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Disguised = CreateConVar("dominationsounds_disguised", "0", "Play domination/revenge sounds while disguised?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_Cloaked = CreateConVar("dominationsounds_cloaked", "0", "Play domination/revenge sounds while cloaked?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegAdminCmd("dominationsound", Cmd_DomSound, ADMFLAG_GENERIC, "Force a player to play a domination sound.");
	RegAdminCmd("revengesound", Cmd_RevengeSound, ADMFLAG_GENERIC, "Force a player to play a revenge sound.");
	AutoExecConfig(true, "dominationsounds");
}

public Action:Cmd_DomSound(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%t", "DominationSound Usage");
	}
	
	new targets[MaxClients];
	new targetCount = 0;
	new String:targetName[128];
	new bool:tn_is_ml;
	
	new String:target[128];
	GetCmdArg(1, target, sizeof(target));
	
	targetCount = ProcessTargetString(target, client, targets, MaxClients, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, targetName, sizeof(targetName), tn_is_ml);
	
	switch(targetCount)
	{
		case COMMAND_TARGET_NONE:
		{
			ReplyToCommand(client, "[FDS] %t", "No matching client");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_ALIVE:
		{
			ReplyToCommand(client, "[FDS] %t", "Target must be alive");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_IN_GAME:
		{
			ReplyToCommand(client, "[FDS] %t", "Target is not in game");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_EMPTY_FILTER:
		{
			ReplyToCommand(client, "[FDS] %t", "No matching clients");
			return Plugin_Handled;
		}
		
		default:
		{
			if (targetCount <= 0)
			{
				return Plugin_Handled;
			}
		}
	}
	
	new TFClassType:targetClass = TFClass_Unknown;
	if (args >= 2)
	{
		new String:classString[64];
		GetCmdArg(2, classString, sizeof(classString));
		
		if (StrContains(classString, "rand", false) == -1)
		{
			targetClass = TF2_GetClass(classString);
		}
	}
	
	for (new i = 0; i < targetCount; ++i)
	{
		
		if (!GetConVarBool(g_Cvar_Cloaked) && (TF2_IsPlayerInCondition(targets[i], TFCond_Cloaked) || TF2_IsPlayerInCondition(targets[i], TFCond_CloakFlicker)))
		{
			continue;
		}
		
		if (!GetConVarBool(g_Cvar_Disguised) && TF2_IsPlayerInCondition(targets[i], TFCond_Disguised))
		{
			continue;
		}
		
		new TFClassType:class = targetClass;
		if (class == TFClass_Unknown)
		{
			class = TFClassType:GetRandomInt(1, 9);
		}
		
		new String:classContext[64];
		Format(classContext, sizeof(classContext), "victimclass:%s", g_ClassNames[class]);
		
		SetVariantString("domination:dominated");
		AcceptEntityInput(targets[i], "AddContext");
		
		SetVariantString(classContext);
		AcceptEntityInput(targets[i], "AddContext");
		
		SetVariantString("TLK_KILLED_PLAYER");
		AcceptEntityInput(targets[i], "SpeakResponseConcept");
		
		AcceptEntityInput(targets[i], "ClearContext");
	}
	
	if (GetConVarBool(g_Cvar_Log))
	{
		new String:phrase[64];
		
		if (tn_is_ml)
		{
			strcopy(phrase, sizeof(phrase), "DominationSound Activity Translation");
		}
		else
		{
			strcopy(phrase, sizeof(phrase), "DominationSound Activity String");
		}
		
		ShowActivity2(client, "[FDS] ", "%t", phrase, targetName);
	}
	
	return Plugin_Handled;
}

public Action:Cmd_RevengeSound(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%t", "RevengeSound Usage");
	}
	
	new targets[MaxClients];
	new targetCount = 0;
	new String:targetName[128];
	new bool:tn_is_ml;
	
	new String:target[128];
	GetCmdArg(1, target, sizeof(target));
	
	targetCount = ProcessTargetString(target, client, targets, MaxClients, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, targetName, sizeof(targetName), tn_is_ml);
	
	switch(targetCount)
	{
		case COMMAND_TARGET_NONE:
		{
			ReplyToCommand(client, "[FDS] %t", "No matching client");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_ALIVE:
		{
			ReplyToCommand(client, "[FDS] %t", "Target must be alive");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_IN_GAME:
		{
			ReplyToCommand(client, "[FDS] %t", "Target is not in game");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_EMPTY_FILTER:
		{
			ReplyToCommand(client, "[FDS] %t", "No matching clients");
			return Plugin_Handled;
		}
		
		default:
		{
			if (targetCount <= 0)
			{
				return Plugin_Handled;
			}
		}
	}
	
	for (new i = 0; i < targetCount; ++i)
	{
		if (!GetConVarBool(g_Cvar_Cloaked) && (TF2_IsPlayerInCondition(targets[i], TFCond_Cloaked) || TF2_IsPlayerInCondition(targets[i], TFCond_CloakFlicker)))
		{
			continue;
		}
		
		if (!GetConVarBool(g_Cvar_Disguised) && TF2_IsPlayerInCondition(targets[i], TFCond_Disguised))
		{
			continue;
		}
		
		SetVariantString("domination:revenge");
		AcceptEntityInput(targets[i], "AddContext");
		
		SetVariantString("TLK_KILLED_PLAYER");
		AcceptEntityInput(targets[i], "SpeakResponseConcept");
		
		AcceptEntityInput(targets[i], "ClearContext");
	}
	
	if (GetConVarBool(g_Cvar_Log))
	{
		new String:phrase[64];
		
		if (tn_is_ml)
		{
			strcopy(phrase, sizeof(phrase), "RevengeSound Activity Translation");
		}
		else
		{
			strcopy(phrase, sizeof(phrase), "RevengeSound Activity String");
		}
		
		ShowActivity2(client, "[FDS] ", "%t", phrase, targetName);
	}
	
	return Plugin_Handled;
}
