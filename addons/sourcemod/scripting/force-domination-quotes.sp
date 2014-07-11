/**
 * vim: set ts=4 :
 * =============================================================================
 * Force Domination Quotes
 * Force a player to play one of their domination or revenge quotes
 *
 * Force Domination Quotes (C)2013-2014 Powerlord (Ross Bemrose).
 * All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: 1.4
 */
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>

#define VERSION "1.4"

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

new Handle:g_Cvar_Enabled;
new Handle:g_Cvar_Log;
new Handle:g_Cvar_Disguised;
new Handle:g_Cvar_Cloaked;

public Plugin:myinfo = 
{
	name = "Force Domination Quotes",
	author = "Powerlord",
	description = "Force a player to play one of their domination or revenge quotes",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=215627"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("force-domination-quotes.phrases");
	CreateConVar("forcedominationquotes_version", VERSION, "Force Domination Quotes version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("forcedominationquotes_enabled", "1", "Enable Force Domination Quotes?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Log = CreateConVar("forcedominationquotes_log", "1", "Log when a command forces a player to play a domination quote", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Disguised = CreateConVar("forcedominationquotes_disguised", "0", "Play domination/revenge quotes while disguised?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_Cloaked = CreateConVar("forcedominationquotes_cloaked", "0", "Play domination/revenge quotes while cloaked?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegAdminCmd("dominationquote", Cmd_DomSound, ADMFLAG_GENERIC, "Force a player to play a domination quote.");
	RegAdminCmd("revengequote", Cmd_RevengeSound, ADMFLAG_GENERIC, "Force a player to play a revenge quote.");
	AutoExecConfig(true, "dominationquotes");
}

public Action:Cmd_DomSound(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "%t", "DominationQuote Usage");
		return Plugin_Handled;
	}
	
	new targets[MaxClients];
	new targetCount = 0;
	new String:targetName[128];
	new bool:tn_is_ml;
	
	new String:target[128];
	GetCmdArg(1, target, sizeof(target));
	
	targetCount = ProcessTargetString(target, client, targets, MaxClients, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, targetName, sizeof(targetName), tn_is_ml);
	
	if (targetCount <= 0)
	{
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
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
			strcopy(phrase, sizeof(phrase), "DominationQuote Activity Translation");
		}
		else
		{
			strcopy(phrase, sizeof(phrase), "DominationQuote Activity String");
		}
		
		ShowActivity2(client, "[FDQ] ", "%t", phrase, targetName);
	}
	
	return Plugin_Handled;
}

public Action:Cmd_RevengeSound(client, args)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		ReplyToCommand(client, "%t", "RevengeQuote Usage");
		return Plugin_Handled;
	}
	
	new targets[MaxClients];
	new targetCount = 0;
	new String:targetName[128];
	new bool:tn_is_ml;
	
	new String:target[128];
	GetCmdArg(1, target, sizeof(target));
	
	targetCount = ProcessTargetString(target, client, targets, MaxClients, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, targetName, sizeof(targetName), tn_is_ml);
	
	if (targetCount <= 0)
	{
		ReplyToTargetError(client, targetCount);
		return Plugin_Handled;
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
			strcopy(phrase, sizeof(phrase), "RevengeQuote Activity Translation");
		}
		else
		{
			strcopy(phrase, sizeof(phrase), "RevengeQuote Activity String");
		}
		
		ShowActivity2(client, "[FDQ] ", "%t", phrase, targetName);
	}
	
	return Plugin_Handled;
}
