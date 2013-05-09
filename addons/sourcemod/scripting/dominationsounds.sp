#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>

#define VERSION "1.0"

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

public Plugin:myinfo = 
{
	name = "Domination Sounds",
	author = "Powerlord",
	description = "For a player to play one of their domination sounds",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=215449"
}

public OnPluginStart()
{
	CreateConVar("dominationsounds_version", VERSION, "Domination Sounds version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_Log = CreateConVar("dominationsounds_log", "1", "Log when a command forces a player to play a domination sound", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	LoadTranslations("common.phrases");
	RegAdminCmd("domsound", Cmd_DomSound, ADMFLAG_GENERIC, "Force a player to play a domination sound.");
	RegAdminCmd("revengesound", Cmd_RevengeSound, ADMFLAG_GENERIC, "Force a player to play a revenge sound.");
	AutoExecConfig(true, "dominationsounds");
}

public Action:Cmd_DomSound(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Format: /domsound <target> [class]");
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
			ReplyToCommand(client, "[DS] %t", "No matching client")
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_ALIVE:
		{
			ReplyToCommand(client, "[DS] %t", "Target must be alive");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_IN_GAME:
		{
			ReplyToCommand(client, "[DS] %t", "Target is not in game");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_EMPTY_FILTER:
		{
			ReplyToCommand(client, "[DS] %t", "No matching clients");
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
		targetClass = TF2_GetClass(classString);
	}
	
	for (new i = 0; i < targetCount; ++i)
	{
		new TFClassType:class = targetClass;
		if (class == TFClass_Unknown)
		{
			class = TFClassType:GetRandomInt(1, 9);
		}
		
		new String:classContext[64];
		Format(classContext, sizeof(classContext), "victimclass:%s", g_ClassNames[class]);
		
		SetVariantString("domination:dominated");
		AcceptEntityInput(i, "AddContext");
		
		SetVariantString(classContext);
		AcceptEntityInput(i, "AddContext");
		
		SetVariantString("TLK_KILLED_PLAYER");
		AcceptEntityInput(i, "SpeakResponseConcept");
		
		AcceptEntityInput(i, "ClearContext");
	}
	
	if (GetConVarBool(g_Cvar_Log))
	{
		if (tn_is_ml)
		{
			ShowActivity2(client, "[DS] ", "Forced %t to play domination sound", targetName);
		}
		else
		{
			ShowActivity2(client, "[DS] ", "Forced %s to play domination sound", targetName);
		}
	}
	
	return Plugin_Handled;
}

public Action:Cmd_RevengeSound(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Format: /revengesound <target>");
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
			ReplyToCommand(client, "[DS] %t", "No matching client")
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_ALIVE:
		{
			ReplyToCommand(client, "[DS] %t", "Target must be alive");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_NOT_IN_GAME:
		{
			ReplyToCommand(client, "[DS] %t", "Target is not in game");
			return Plugin_Handled;
		}
		
		case COMMAND_TARGET_EMPTY_FILTER:
		{
			ReplyToCommand(client, "[DS] %t", "No matching clients");
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
		SetVariantString("domination:revenge");
		AcceptEntityInput(i, "AddContext");
		
		SetVariantString("TLK_KILLED_PLAYER");
		AcceptEntityInput(i, "SpeakResponseConcept");
		
		AcceptEntityInput(i, "ClearContext");
	}
	
	if (GetConVarBool(g_Cvar_Log))
	{
		if (tn_is_ml)
		{
			ShowActivity2(client, "[DS] ", "Forced %t to play revenge sound", targetName);
		}
		else
		{
			ShowActivity2(client, "[DS] ", "Forced %s to play revenge sound", targetName);
		}
	}
	
	return Plugin_Handled;
}
