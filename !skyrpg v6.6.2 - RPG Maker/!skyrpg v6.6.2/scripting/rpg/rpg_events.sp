// Every single event in the events.cfg is called by this function, and then sent off to a specific function.
// This way a separate template isn't required for events that have different event names.
public Action:Event_Occurred(Handle:event, String:event_name[], bool:dontBroadcast) {

	//if (b_IsSurvivalIntermission) return Plugin_Handled;

	new a_Size						= 0;
	a_Size							= GetArraySize(a_Events);

	decl String:EventName[PLATFORM_MAX_PATH];
	new eventresult = 0;

	decl String:CurrMap[64];
	GetCurrentMap(CurrMap, sizeof(CurrMap));

	for (new i = 0; i < a_Size; i++) {

		EventSection						= GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:EventSection, 0, EventName, sizeof(EventName));

		if (StrEqual(EventName, event_name)) {

			//if (Call_Event(event, event_name, dontBroadcast, i) == -1) {

				/*if (StrEqual(EventName, "infected_hurt") || StrEqual(EventName, "player_hurt")) {

					

					//	Returns -1 when infected_hurt or player_hurt and the cause of the damage is not a common infected or a player
					//	or if the damage is "inferno" which can be discerned through the player_hurt event only; we have to resort to
					//	the prior for infected_hurt
					

					return Plugin_Handled;
				}*/
			//}
			eventresult = Call_Event(event, event_name, dontBroadcast, i);
			break;
		}
	}
	if (StrContains(EventName, "finale_radio_start", false) != -1) return Plugin_Continue;
	if (eventresult == -1 && b_IsActiveRound) return Plugin_Handled;
	return Plugin_Continue;
	//if (StrEqual(EventName, "infected_hurt") || StrEqual(EventName, "player_hurt")) return Plugin_Handled;
	//else return Plugin_Continue;
}

public SubmitEventHooks(value) {

	new size = GetArraySize(a_Events);
	decl String:text[64];

	for (new i = 0; i < size; i++) {

		HookSection = GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:HookSection, 0, text, sizeof(text));
		if (StrEqual(text, "player_hurt", false) ||
			StrEqual(text, "infected_hurt", false)) {

			if (value == 0) UnhookEvent(text, Event_Occurred, EventHookMode_Pre);
			else HookEvent(text, Event_Occurred, EventHookMode_Pre);
		}
		else {

			if (value == 0) UnhookEvent(text, Event_Occurred);
			else HookEvent(text, Event_Occurred);
		}
	}
}

stock String:FindPlayerWeapon(client) {

	decl String:weapon[64];
	Format(weapon, sizeof(weapon), "-1");

	new g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	new iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	if (IsValidEdict(iWeapon)) GetEdictClassname(iWeapon, weapon, sizeof(weapon));

	return weapon;
}

/*stock PrimeInfected(client) {

	CreateMyHealthPool(client, true);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	decl String:InfecttedSpeedBonusType[64];
	Format(InfecttedSpeedBonusType, sizeof(InfecttedSpeedBonusType), "(%d) infected speed bonus", FindZombieClass(client));
	new Float:SpeedBonus = GetConfigValueFloat(InfecttedSpeedBonusType) * (SurvivorLevels() * 1.0);
	SpeedMultiplierBase[client] = 1.0;
	SpeedMultiplier[client] = 1.0;
	SetSpeedMultiplierBase(client, 1.0 + SpeedBonus);
	b_IsImmune[client] = false;
	WipeDamageAward(client);
}*/

public Call_Event(Handle:event, String:event_name[], bool:dontBroadcast, pos) {

	/*if (StrEqual(event_name, "infected_hurt")) {

		return 0;

		//if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return -1;
	}*/

	CallKeys							= GetArrayCell(a_Events, pos, 0);
	CallValues							= GetArrayCell(a_Events, pos, 1);

	decl String:ThePerp[64];
	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "perpetrator?");

	new attacker = GetClientOfUserId(GetEventInt(event, ThePerp));

	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "victim?");
	new victim = GetClientOfUserId(GetEventInt(event, ThePerp));

	//decl String:EventName[PLATFORM_MAX_PATH];
	//FormatKeyValue(EventName, sizeof(EventName), CallKeys, CallValues, "event name?");
	//if (!IsWitch(victim) && !IsCommonInfected(victim)) victim = GetClientOfUserId(victim);

	//if (StrEqual(event_name, "player_hurt", false) && !IsLegitimateClient(attacker)) attacker = GetEventInt(event, "attackerentid");

	// in old versions, we unhooked players when the round ended.
	// now, we only do it when a client spawns for the first time - or is removed from the server.
	/*if (StrEqual(event_name, "round_end")) {

		//LogToFile(LogPathDirectory, "[ROUND OVER] Removing SDK Hooks from players.");

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				b_IsHooked[i] = false;
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}*/

	/*if (StrEqual(event_name, "player_spawn")) {

		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsHooked[attacker]) {

			//if (IsPlayerAlive(attacker)) SDKUnhook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);

			b_IsHooked[attacker] = true;
			SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}*/
	decl String:weapon[64];
	//decl String:key[64];
	if (StrEqual(event_name, "player_left_start_area") && IsLegitimateClient(attacker)) {

		if ((GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker))) {

			if (IsSurvivorBot(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsLoaded[attacker]) IsClientLoadedEx(attacker);

			if (b_IsInSaferoom[attacker] && RoundExperienceMultiplier[attacker] > 0.0) {

				b_IsInSaferoom[attacker] = false;
				//PrintToChat(attacker, "%T", "bonus container locked", attacker, orange, blue);
				decl String:saferoomName[64];
				GetClientName(attacker, saferoomName, sizeof(saferoomName));
				decl String:pct[4];
				Format(pct, sizeof(pct), "%");
				PrintToChatAll("%t", "round bonus multiplier", blue, saferoomName, white, orange, (1.0 + RoundExperienceMultiplier[attacker]) * 100.0, orange, pct, white);
			}
		}
	}
	if (IsLegitimateClientAlive(attacker)) {

		if (StrEqual(event_name, "player_entered_checkpoint")) bIsInCheckpoint[attacker] = true;
		if (StrEqual(event_name, "player_left_checkpoint")) bIsInCheckpoint[attacker] = false;
	}
	if (StrEqual(event_name, "player_hurt") || StrEqual(event_name, "infected_hurt")) {

		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsHooked[attacker]) ChangeHook(attacker, true);
		if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !b_IsHooked[victim]) ChangeHook(victim, true);
		
		if (IsSurvivorBot(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsLoaded[attacker]) IsClientLoadedEx(attacker);
		if (IsSurvivorBot(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !b_IsLoaded[victim]) IsClientLoadedEx(victim);

		
	}
	if (StrEqual(event_name, "weapon_reload")) {

		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			ConsecutiveHits[attacker] = 0;	// resets on reload.
		}
	}
	/*if (StrEqual(event_name, "player_hurt")) {

		if (IsLegitimateClientAlive(attacker) && (GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker)) && !b_IsHooked[attacker]) {

			b_IsHooked[attacker] = true;
			SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		if (IsLegitimateClientAlive(victim) && (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim)) && !b_IsHooked[victim]) {

			b_IsHooked[victim] = true;
			SDKHook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
		}

		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && !IsSurvivorBot(attacker) && !b_IsHooked[attacker]) {

			PrimeInfected(attacker);
		}
		if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_INFECTED && !IsSurvivorBot(victim) && !b_IsHooked[victim]) {

			PrimeInfected(victim);
		}

		//GetEventString(event, "weapon", weapon, sizeof(weapon));
		return -1;
		//if (StrEqual(weapon, "inferno") || damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return -1;
	}*/
	//new minimumlevel = iPlayerStartingLevel;
	//decl String:key[64];
	/*if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && PlayerLevel[attacker] < minimumlevel) {

		GetClientAuthString(attacker, key, sizeof(key));
		b_IsLoading[attacker] = true;
		ResetData(attacker);
		ClearAndLoad(key);
		return;
		if (!b_IsLoading[attacker] && !LoadDelay[attacker]) {

			CreateNewPlayer(attacker);
			return 0;
		}
	}
	if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && PlayerLevel[victim] < minimumlevel) {

		GetClientAuthString(victim, key, sizeof(key));
		b_IsLoading[victim] = true;
		ResetData(victim);
		ClearAndLoad(victim);
		return;
		if (!b_IsLoading[victim] && !LoadDelay[victim]) {

			CreateNewPlayer(victim);
			return 0;
		}
	}*/
	if (StrEqual(event_name, "player_spawn")) {

		if (IsLegitimateClient(attacker)) ClearArray(Handle:ActiveStatuses[attacker]);

		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker)) {

			ChangeHook(attacker, true);
			RefreshSurvivor(attacker);
			RaidInfectedBotLimit();
			//EquipBackpack(attacker);
		}
		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && (b_IsActiveRound || !IsFakeClient(attacker))) {

			PlayerSpawnAbilityTrigger(attacker);
		}
		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && !IsSurvivorBot(attacker) && (b_IsActiveRound || !IsFakeClient(attacker))) {

			ClearArray(Handle:PlayerAbilitiesCooldown[attacker]);
			//ClearArray(Handle:PlayerAbilitiesImmune[attacker]);
			ClearArray(Handle:InfectedHealth[attacker]);

			new aDbSize = GetArraySize(a_Database_Talents);

			//ResizeArray(Handle:a_Database_PlayerTalents_Bots, size);
			//ResizeArray(Handle:PlayerAbilitiesCooldown_Bots, size);
			//ResizeArray(Handle:PlayerAbilitiesImmune_Bots, size);

			ResizeArray(a_Database_PlayerTalents[attacker], aDbSize);
			ResizeArray(PlayerAbilitiesCooldown[attacker], aDbSize);
			ResizeArray(a_Database_PlayerTalents_Experience[attacker], aDbSize);
			//ResizeArray(Handle:PlayerAbilitiesImmune[client], aDbSize);


			ResizeArray(Handle:InfectedHealth[attacker], 1);	// infected player stores their actual health (from talents, abilities, etc.) locally...
			bHealthIsSet[attacker] = false;
			//IsCoveredInVomit(attacker, _, true);
			ISBILED[attacker] = false;
			if (!b_IsHooked[attacker]) {

				ChangeHook(attacker, true);
				CreateMyHealthPool(attacker, true);
			}
			if (FindZombieClass(attacker) == ZOMBIECLASS_TANK) {

				ClearArray(TankState_Array[attacker]);
				bHasTeleported[attacker] = false;
				//PrintToChatAll("Tank has spawned!");
				if (iTanksPreset == 1) {

					new iRand = GetRandomInt(1, 3);
					if (iRand == 1) ChangeTankState(attacker, "hulk");
					else if (iRand == 2) ChangeTankState(attacker, "death");
					else if (iRand == 3) ChangeTankState(attacker, "burn");
					//else if (iRand == 4) ChangeTankState(attacker, "teleporter");
					//else if (iRand == 5) ChangeTankState(attacker, "reflect");
				}
			}
		}
	}
	if (!b_IsActiveRound || IsSurvivorBot(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsLoaded[attacker]) return 0;		// don't track ANYTHING when it's not an active round.

	if (StrEqual(event_name, "player_ledge_grab") || StrEqual(event_name, "player_incapacitated")) {

		if (IsLegitimateClientAlive(victim) && StrContains(ActiveClass[victim], "death", false) == -1) GiveMaximumHealth(victim);
	}

	if (StrEqual(event_name, "revive_success") && IsLegitimateClient(victim) && (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim))) {

		GetAbilityStrengthByTrigger(victim, attacker, 'R', FindZombieClass(victim), 0);
		GetAbilityStrengthByTrigger(attacker, victim, 'r', FindZombieClass(attacker), 0);
		
		SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(attacker, Prop_Send, "m_reviveTarget", -1);
		new reviveOwner = GetEntPropEnt(victim, Prop_Send, "m_reviveOwner");
		if (IsLegitimateClient(reviveOwner)) {

			SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
		}
		GiveMaximumHealth(victim);
	}
	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "damage type?");
	new damagetype = GetEventInt(event, ThePerp);

	if (StrEqual(event_name, "finale_radio_start") && !b_IsFinaleActive) {

		// When the finale is active, players can earn experience whilst camping (not moving from a spot, re: farming)
		b_IsFinaleActive = true;
		if (GetInfectedCount(ZOMBIECLASS_TANK) < 1) b_IsFinaleTanks = true;
		if (iTankRush == 1) {

			PrintToChatAll("%t", "the zombies are coming", blue, orange, blue);
			ExecCheatCommand(FindAnyRandomClient(), "director_force_panic_event");
		}

		//PrintToChatAll("%t", "Farming Prevention Disabled", white, orange, white, orange, white, blue);
	}
	if (StrEqual(event_name, "finale_vehicle_ready")) {

		// When the vehicle arrives, the finale is no longer active, but no experience can be earned. This stops farming.
		if (b_IsFinaleActive) {

			b_RescueIsHere = true;

			b_IsFinaleActive = false;

			new TheInfectedLevel = HumanSurvivorLevels();

			new TheHumans = HumanPlayersInGame();
			new TheLiving = LivingSurvivorCount();

			//new RatingMult = GetConfigValueInt("rating level multiplier?");
			new InfectedLevelType = iBotLevelType;

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {
				
					if (InfectedLevelType == 0) Rating[i] += (RaidLevMult / TheLiving);
					else {

						if (!bIsSoloHandicap) Rating[i] += (TheInfectedLevel / TheHumans);
						else Rating[i] += RaidLevMult;
					}
					RoundExperienceMultiplier[i] += FinSurvBon;
				}
			}
		}

		//PrintToChatAll("%t", "Experience Gains Disabled", orange, white, orange, white, blue);
	}

	// Declare the values that can be defined by the event config, so we know whether to consider them.

	//new RPGMode						= iRPGMode;	// 1 experience 2 experience & points

	decl String:AbilityUsed[PLATFORM_MAX_PATH];
	decl String:abilities[PLATFORM_MAX_PATH];
	decl String:ActivatorAbility[PLATFORM_MAX_PATH];
	decl String:TargetAbility[PLATFORM_MAX_PATH];


	//new attacker = GetClientOfUserId(GetEventInt(event, GetKeyValue(CallKeys, CallValues, "perpetrator?")));
	//if (IsWitch(victim)) PrintToChatAll("Wiotch!!");
	//if (!IsWitch(victim) && !IsCommonInfected(victim) && IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) return 0;

	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "health?");
	new healthvalue = GetEventInt(event, ThePerp);

	//if (StrContains(event_name, "hurt", false) != -1) {

		//new theresult = RPG_OnTakeDamage(victim, attacker, attacker, healthvalue * 1.0, damagetype);
		//return theresult;
	//}

	new isdamageaward = GetKeyValueInt(CallKeys, CallValues, "damage award?");
	//new healing = GetKeyValueInt(CallKeys, CallValues, "healing?");

	//new deathaward = GetKeyValueInt(CallKeys, CallValues, "death award?");
	FormatKeyValue(abilities, sizeof(abilities), CallKeys, CallValues, "abilities?");
	new tagability = GetKeyValueInt(CallKeys, CallValues, "tag ability?");
	new tagexperience = GetKeyValueInt(CallKeys, CallValues, "tag experience?");
	new Float:tagpoints = GetKeyValueFloat(CallKeys, CallValues, "tag points?");
	new originvalue = GetKeyValueInt(CallKeys, CallValues, "origin?");
	new distancevalue = GetKeyValueInt(CallKeys, CallValues, "distance?");
	new Float:multiplierpts = GetKeyValueFloat(CallKeys, CallValues, "multiplier points?");
	new Float:multiplierexp = GetKeyValueFloat(CallKeys, CallValues, "multiplier exp?");
	new isshoved = GetKeyValueInt(CallKeys, CallValues, "shoved?");
	new bulletimpact = GetKeyValueInt(CallKeys, CallValues, "bulletimpact?");
	new isinsaferoom = GetKeyValueInt(CallKeys, CallValues, "entered saferoom?");
	//new isEntityPos = -1;
	//new isArraySize = -1;

	FormatKeyValue(ActivatorAbility, sizeof(ActivatorAbility), CallKeys, CallValues, "activator ability?");
	FormatKeyValue(TargetAbility, sizeof(TargetAbility), CallKeys, CallValues, "target ability?");

	//if ((IsLegitimateClient(attacker) && !IsFakeClient(attacker) && b_IsLoading[attacker]) || (IsLegitimateClient(victim) && !IsFakeClient(victim) && b_IsLoading[victim])) return;
	/*if (attacker > 0 && IsLegitimateClient(attacker) && !IsFakeClient(attacker) && PlayerLevel[attacker] == 0 && !b_IsLoading[attacker]) {

		GetClientAuthString(attacker, key, sizeof(key));
		b_IsLoading[attacker] = true;
		ResetData(attacker);
		ClearAndLoad(key);
		return;
	}
	if (victim > 0 && IsLegitimateClient(victim) && !IsFakeClient(victim) && PlayerLevel[victim] == 0 && !b_IsLoading[victim]) {

		GetClientAuthString(victim, key, sizeof(key));
		b_IsLoading[victim] = true;
		ResetData(victim);
		ClearAndLoad(key);
		return;
	}*/
	if (IsLegitimateClient(victim) && !StrEqual(TargetAbility, "-1", false)) {

		for (new i = 0; i <= strlen(TargetAbility); i++) {

			GetAbilityStrengthByTrigger(victim, attacker, TargetAbility[i], FindZombieClass(victim), 0);
		}
	}
	if (IsLegitimateClient(attacker) && !StrEqual(ActivatorAbility, "-1", false)) {

		for (new i = 0; i <= strlen(ActivatorAbility); i++) {

			GetAbilityStrengthByTrigger(attacker, victim, ActivatorAbility[i], FindZombieClass(attacker), 0);
		}
	}
	if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

		//LogToFile(LogPathDirectory, "%N health set to 40000", victim);
		//if (FindZombieClass(victim) == ZOMBIECLASS_TANK) ExtinguishEntity(victim);
		SetEntityHealth(victim, 400000);
	}
	if (tagability == 1 && IsLegitimateClient(victim)) ISBILED[victim] = true;
	if (tagability == 2 && IsLegitimateClient(attacker)) ISBILED[attacker] = false;
	
	if (isdamageaward == 1) {

		if (IsLegitimateClient(attacker) && IsLegitimateClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim)) {

			if (!(damagetype & DMG_BURN) && !StrEqual(weapon, "inferno")) {

				// damage-based triggers now only occur under the circumstances in the code above. No longer do we have triggers for same-team damaging. Maybe at a later date, but it will not be the same ability trigger.
				GetAbilityStrengthByTrigger(attacker, victim, 'd', FindZombieClass(attacker), healthvalue);
				GetAbilityStrengthByTrigger(victim, attacker, 'l', FindZombieClass(victim), healthvalue);
			}
			else {

				ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 1, 0);
			}
		}
		if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

			/*

				Because all health pools are instanced, actual health pools should never decrease, so we keep them always topped-off.
			*/
			//LogToFile(LogPathDirectory, "%N health set to 40000", victim);
			//if (FindZombieClass(victim) == ZOMBIECLASS_TANK) ExtinguishEntity(victim);
			SetEntityHealth(victim, 40000);
		}
		/*if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			if (IsWitch(victim)) {
				
				Format(weapon, sizeof(weapon), "%s", FindPlayerWeapon(attacker));
				if (StrEqual(weapon, "melee", false) || !bIsMeleeCooldown[attacker]) {

					if (StrContains(weapon, "shotgun", false) != -1) {

						bIsMeleeCooldown[attacker] = true;				
						CreateTimer(0.3, Timer_IsMeleeCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
					}
					AddWitchDamage(attacker, victim, healthvalue);


					if (StringToInt(GetConfigValue("display health bars?")) == 1) {

						if (damagetype != 8 && damagetype != 268435464 && !StrEqual(weapon, "inferno")) {

							DisplayInfectedHealthBars(attacker, victim);
						}
					}
					if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
						CheckTeammateDamages(victim, attacker, true) >= 1.0 ||
						CheckTeammateDamages(victim, attacker) < 0.0 ||
						CheckTeammateDamages(victim, attacker, true) < 0.0) {

						OnWitchCreated(victim, true);
					}
				}
			}
		}*/
		if (attacker > 0 && IsLegitimateClient(attacker)) {

			if ((GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker)) && isinsaferoom == 1) b_IsInSaferoom[attacker] = true;
		}
		/*if (!IsLegitimateClient(attacker) && StrEqual(EventName, "player_hurt")) {


		}*/
	}
	if (isshoved == 1 && IsLegitimateClientAlive(victim) && IsLegitimateClientAlive(attacker) && GetClientTeam(victim) != GetClientTeam(attacker)) {

		if (GetClientTeam(victim) == TEAM_INFECTED) SetEntityHealth(victim, GetClientHealth(victim) + healthvalue);

		GetAbilityStrengthByTrigger(victim, attacker, 'H', FindZombieClass(victim), 0);
	}
	if (bulletimpact == 1) {

		if (IsLegitimateClientAlive(attacker) && (GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker))) {

			new Float:Coords[3];
			Coords[0] = GetEventFloat(event, "x");
			Coords[1] = GetEventFloat(event, "y");
			Coords[2] = GetEventFloat(event, "z");

			LastWeaponDamage[attacker] = GetBaseWeaponDamage(attacker, -1, Coords[0], Coords[1], Coords[2], damagetype);

			/*if (GetConfigValueInt("special ammo requires target?") == 0 && HasSpecialAmmo(attacker) && IsSpecialAmmoEnabled[attacker][0] == 1.0 && LastWeaponDamage[attacker] > 0) {

 				new StaminaCost = RoundToCeil(GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker], 2));
 				if (SurvivorStamina[attacker] >= StaminaCost) {

 					//if (CheckActiveAmmoCooldown(attacker, ActiveSpecialAmmo[attacker]) == 1) {
 					if (!IsAmmoActive(attacker, ActiveSpecialAmmo[attacker])) {
	 				//if (CreateActiveTime(attacker, ActiveSpecialAmmo[attacker], GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker])) == 1) {

	 					if (TriggerSpecialAmmo(attacker, -1, LastWeaponDamage[attacker], GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker]), GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker], 4), Coords[0], Coords[1], Coords[2])) {
	 					
		 					SurvivorStamina[attacker] -= StaminaCost;
							if (SurvivorStamina[attacker] <= 0) {

								bIsSurvivorFatigue[attacker] = true;
								IsSpecialAmmoEnabled[attacker][0] = 0.0;
							}
						}
	 				}
	 			}
 			}*/

			if (iIsBulletTrails[attacker] == 1) {

				new Float:EyeCoords[3];
				GetClientEyePosition(attacker, EyeCoords);
				// Adjust the coords so they line up with the gun
				EyeCoords[2] -= 10.0;

				new TrailsColours[4];
				TrailsColours[3] = 200;

				decl String:ClientModel[64];
				decl String:TargetModel[64];
				GetClientModel(attacker, ClientModel, sizeof(ClientModel));

				new bulletsize		= GetArraySize(a_Trails);
				for (new i = 0; i < bulletsize; i++) {

					TrailsKeys[attacker] = GetArrayCell(a_Trails, i, 0);
					TrailsValues[attacker] = GetArrayCell(a_Trails, i, 1);

					FormatKeyValue(TargetModel, sizeof(TargetModel), TrailsKeys[attacker], TrailsValues[attacker], "model affected?");

					if (StrEqual(TargetModel, ClientModel)) {

						TrailsColours[0]		= GetKeyValueInt(TrailsKeys[attacker], TrailsValues[attacker], "red?");
						TrailsColours[1]		= GetKeyValueInt(TrailsKeys[attacker], TrailsValues[attacker], "green?");
						TrailsColours[2]		= GetKeyValueInt(TrailsKeys[attacker], TrailsValues[attacker], "blue?");
						break;
					}
				}

				for (new i = 1; i <= MaxClients; i++) {

					if (IsLegitimateClient(i) && !IsFakeClient(i)) {

						TE_SetupBeamPoints(EyeCoords, Coords, g_iSprite, 0, 0, 0, 0.06, 0.09, 0.09, 1, 0.0, TrailsColours, 0);
						TE_SendToClient(i);
					}
				}
			}
		}
	}
	/*if (StrEqual(EventName, "player_team")) {

		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker)) CreateTimer(1.0, Timer_SwitchTeams, attacker, TIMER_FLAG_NO_MAPCHANGE);
	}*/
	if (StrEqual(event_name, "player_spawn") && IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

		if (IsFakeClient(attacker)) {

			new changeClassId = 0;
			new myzombieclass = FindZombieClass(attacker);

			if (iSpecialsAllowed == 0 && myzombieclass != ZOMBIECLASS_TANK) {

				ForcePlayerSuicide(attacker);
			}
			if (iSpecialsAllowed == 1 && !StrEqual(sSpecialsAllowed, "-1")) {

				decl String:myClass[5];
				Format(myClass, sizeof(myClass), "%d", myzombieclass);

				if (StrContains(sSpecialsAllowed, myClass) == -1) {

					while (StrContains(sSpecialsAllowed, myClass) == -1) {

						changeClassId = GetRandomInt(1,6);
						Format(myClass, sizeof(myClass), "%d", changeClassId);
					}
					ChangeInfectedClass(attacker, changeClassId);
				}
			}

			// In solo games, we restrict the number of ensnarement infected.
			IsAirborne[attacker] = false;
			b_GroundRequired[attacker] = false;
			HasSeenCombat[attacker] = false;
			MyBirthday[attacker] = GetTime();

			new iTankCount = GetInfectedCount(ZOMBIECLASS_TANK);
			new iTankLimit = DirectorTankLimit();
			new theClient = FindAnyRandomClient();
			new iSurvivors = TotalHumanSurvivors();
			new iSurvivorBots = TotalSurvivors() - iSurvivors;
			new iLivSurvs = LivingSurvivorCount();
			if (iSurvivorBots >= 2) iSurvivorBots /= 2;

			if (myzombieclass == ZOMBIECLASS_TANK) {

				if (b_IsFinaleActive && b_IsFinaleTanks) {

					b_IsFinaleTanks = false;
					for (new i = 0; i + iTankCount < iTankLimit; i++) {

						ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
					}
				}
				else {

					if (iTankCount > iTankLimit || f_TankCooldown != -1.0) {

						//PrintToChatAll("killing tank.");
						//ForcePlayerSuicide(attacker);
					}
				}
			}

			if (iTankRush == 1) {

				if (myzombieclass != ZOMBIECLASS_TANK) {

					//if (!IsEnrageActive())
					ForcePlayerSuicide(attacker);
					if (!b_IsFinaleActive && iSurvivors >= 1 && iTankCount < iTankLimit) {

						if (IsLegitimateClientAlive(theClient)) ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
					}
				}
			}
			else if (myzombieclass != ZOMBIECLASS_TANK) {

				new iEnsnaredCount = EnsnaredInfected();
				if (IsEnsnarer(attacker)) {

					if (iInfectedLimit == -1 || iInfectedLimit > 0 && iEnsnaredCount >= iInfectedLimit || iIsLifelink > 1 && iLivSurvs < iIsLifelink && iLivSurvs < iMinSurvivors) {

						while (IsEnsnarer(attacker, changeClassId)) {

							changeClassId = GetRandomInt(1,6);
						}
						ChangeInfectedClass(attacker, changeClassId);
					}
				}
			}
		}
		else {

			new t_InfectedHealth = 0;
			new myzombieclass = FindZombieClass(attacker);

			if (myzombieclass == ZOMBIECLASS_TANK)  t_InfectedHealth = 4000;
			else if (myzombieclass == ZOMBIECLASS_HUNTER || myzombieclass == ZOMBIECLASS_SMOKER) t_InfectedHealth = 200;
			else if (myzombieclass == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
			else if (myzombieclass == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
			else if (myzombieclass == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
			else if (myzombieclass == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 300;

			OriginalHealth[attacker] = t_InfectedHealth;
			GetAbilityStrengthByTrigger(attacker, _, 'a', myzombieclass, 0);

			if (DefaultHealth[attacker] < OriginalHealth[attacker]) DefaultHealth[attacker] = OriginalHealth[attacker];
		}
	}
	if (StrEqual(event_name, "ability_use")) {

		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

			GetEventString(event, "ability", AbilityUsed, sizeof(AbilityUsed));
			if (StrContains(AbilityUsed, "ability_throw") != -1) {

				if (!(GetEntityFlags(attacker) & FL_ONFIRE) && !SurvivorsInRange(attacker, 128.0)) ChangeTankState(attacker, "burn");
				else {

					ChangeTankState(attacker, "hulk");
					if (!SurvivorsInRange(attacker, 128.0)) ForceClientJump(attacker, 1000.0);
				}
			}
			/*if (StrContains(AbilityUsed, abilities, false) != -1) {

				if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER) PrintToChatAll("Pouncing!");

				// check for any abilities that are based on abilityused.
				GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
				//GetAbilityStrengthByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
				GetAbilityStrengthByTrigger(attacker, _, 'A', FindZombieClass(attacker), healthvalue);	// activator, target, trigger ability, effects, zombieclass, damage
			}*/
		}
	}

	if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

		new Float:Distance = 0.0;
		new Float:fTalentStrength = 0.0;

		if (originvalue > 0 || distancevalue > 0) {

			if (originvalue == 1 || distancevalue == 1) {

				GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
				if (FindZombieClass(attacker) != ZOMBIECLASS_HUNTER &&
					FindZombieClass(attacker) != ZOMBIECLASS_SPITTER) {

					fTalentStrength = GetAbilityStrengthByTrigger(attacker, _, 'Q', FindZombieClass(attacker), 0);
				}
				if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER) {

					// check for any abilities that are based on abilityused.
					GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
					//GetAbilityStrengthByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
					GetAbilityStrengthByTrigger(attacker, _, 'A', FindZombieClass(attacker), healthvalue);
				}
				if (FindZombieClass(attacker) == ZOMBIECLASS_CHARGER) {

					CreateTimer(0.1, Timer_ChargerJumpCheck, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			if (originvalue == 2 || distancevalue == 2) {

				fTalentStrength = GetAbilityStrengthByTrigger(attacker, _, 'q', FindZombieClass(attacker), 0);
				if (CheckActiveStatuses(attacker, "lunge", false, true) == 0) {

					SetEntityRenderMode(attacker, RENDER_NORMAL);
					SetEntityRenderColor(attacker, 255, 255, 255, 255);

					fTalentStrength += GetAbilityStrengthByTrigger(attacker, _, 'A', FindZombieClass(attacker), 0);
				}

				GetClientAbsOrigin(attacker, Float:f_OriginEnd[attacker]);

				if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {

					Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					if (fTalentStrength > 0.0) Distance += (Distance * fTalentStrength);

					//SetClientTotalHealth(victim, RoundToCeil(Distance), _, true);
				}
			}

			if (FindZombieClass(attacker) == ZOMBIECLASS_JOCKEY || (distancevalue == 2 && t_Distance[attacker] > 0)) {

				if (distancevalue == 1) t_Distance[attacker] = GetTime();
				if (distancevalue == 2) {

					t_Distance[attacker] = GetTime() - t_Distance[attacker];
					multiplierexp *= t_Distance[attacker];
					multiplierpts *= t_Distance[attacker];
					t_Distance[attacker] = 0;

				}
			}
			else {

				if (distancevalue == 3 && IsLegitimateClientAlive(victim)) GetClientAbsOrigin(victim, Float:f_OriginStart[attacker]);
				if (distancevalue == 2 || originvalue == 2 || distancevalue == 4 && IsLegitimateClientAlive(victim)) {

					if (distancevalue == 4) GetClientAbsOrigin(victim, Float:f_OriginEnd[attacker]);

					//new Float:Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					multiplierexp *= Distance;
					multiplierpts *= Distance;
				}
			}
			if (originvalue == 2 || distancevalue == 2 || distancevalue == 4) {

				if (iRPGMode >= 1 && multiplierexp > 0.0) {

					ExperienceLevel[attacker] += RoundToCeil(multiplierexp);
					ExperienceOverall[attacker] += RoundToCeil(multiplierexp);
					ConfirmExperienceAction(attacker);

					if (iAwardBroadcast > 0 && !IsFakeClient(attacker)) PrintToChat(attacker, "%T", "distance experience", attacker, white, green, RoundToCeil(multiplierexp), white);
				}
				if (iRPGMode != 1 && multiplierpts > 0.0) {

					Points[attacker] += multiplierpts;
					if (iAwardBroadcast > 0 && !IsFakeClient(attacker)) PrintToChat(attacker, "%T", "distance points", attacker, white, green, multiplierpts, white);
				}
			}
		}
	}
	return 0;
}



stock bool:AnyBiledSurvivors() {

	new size = GetArraySize(Handle:CoveredInVomit);
	decl String:text[512];
	decl String:result[2][64];
	//new client = -1;

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CoveredInVomit, i, text, sizeof(text));
		ExplodeString(text, "}", result, 2, 64);
		//client = FindClientWithAuthString(result[0]);
		if (IsLegitimateClientAlive(i)) return true;
	}
	return false;
}

stock bool:IsCoveredInVomit(client, owner = -1, bool:IsDestroy = false) {

	if (!IsLegitimateClient(client)) return false;

	//new size = GetArraySize(Handle:CoveredInVomit);
	decl String:text[512];
	decl String:result[2][64];
	decl String:key[512];
	decl String:TheName[64];
	if (IsFakeClient(client)) {

		GetSurvivorBotName(client, TheName, sizeof(TheName));
		Format(key, sizeof(key), "%s%s", sBotTeam, TheName);
	}
	else GetClientAuthString(client, key, sizeof(key));
	for (new i = 0; i < GetArraySize(Handle:CoveredInVomit); i++) {

		GetArrayString(Handle:CoveredInVomit, i, text, sizeof(text));
		ExplodeString(text, "}", result, 2, 64);
		if (StrEqual(result[0], key, false)) {

			if (!IsDestroy && owner == -1) return true;
			else if (IsDestroy) {

				RemoveFromArray(Handle:CoveredInVomit, i);
				if (i > 0) i--;
			}
			continue;
		}
	}
	if (owner > 0 && !IsDestroy) {

		/*

			If we just want to find out whether the player is biled on, say for status effects
			then we don't want to push if the owner IS the client.
			This way, if the client exists, it'll return true, but if they don't, it'll return false
			without adding them.
		*/
		Format(text, sizeof(text), "%s}%d", key, owner);
		PushArrayString(Handle:CoveredInVomit, text);

		return true;
	}
	return false;		// this ONLY occurs if no owner is specified, ie it clears the client everywhere in the array.
}

stock String:StoreItemName(client, pos) {

	decl String:Name[64];
	StoreItemNameSection[client]					= GetArrayCell(a_Store, pos, 2);

	GetArrayString(StoreItemNameSection[client], 0, Name, sizeof(Name));

	return Name;
}

stock bool:IsStoreItem(client, String:EName[], bool:b_IsAwarding = true) {

	decl String:Name[64];
	new size				= GetArraySize(a_Store);

	for (new i = 0; i < size; i++) {

		StoreItemSection[client]				= GetArrayCell(a_Store, i, 2);
		GetArrayString(StoreItemSection[client], 0, Name, sizeof(Name));

		if (StrEqual(Name, EName)) {

			if (b_IsAwarding) GiveClientStoreItem(client, i);
			return true;
		}
	}
	return false;
}

public Action:Timer_ChargerJumpCheck(Handle:timer, any:client) {

	if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED) {

		if (FindZombieClass(client) != ZOMBIECLASS_CHARGER || !IsPlayerAlive(client)) return Plugin_Stop;
		new victim = L4D2_GetSurvivorVictim(client);
		if (victim == -1) return Plugin_Continue;
		if ((GetEntityFlags(client) & FL_ONGROUND)) {

			GetAbilityStrengthByTrigger(client, victim, 'v', FindZombieClass(client), 0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

stock bool:PlayerCastSpell(client) {

	new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(CurrentEntity) || CurrentEntity < 1) return Plugin_Handled;
	decl String:EntityName[64];


	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));

	new Entity					=	CreateEntityByName(EntityName);
	DispatchSpawn(Entity);

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);

	Origin[2] += 64.0;

	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);

	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	AcceptEntityInput(CurrentEntity, "Kill");

	return Plugin_Handled;
}

stock CreateGravityAmmo(client, Float:Force, Float:Range, bool:UseTheForceLuke=false) {

	new entity		= CreateEntityByName("point_push");
	if (!IsValidEntity(entity)) return -1;
	decl String:value[64];

	new Float:Origin[3];
	new Float:Angles[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
	GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
	Angles[0] += -90.0;

	DispatchKeyValueVector(entity, "origin", Origin);
	DispatchKeyValueVector(entity, "angles", Angles);
	Format(value, sizeof(value), "%d", RoundToCeil(Range / 2));
	DispatchKeyValue(entity, "radius", value);
	if (!UseTheForceLuke) DispatchKeyValueFloat(entity, "magnitude", Force * -1.0);
	else DispatchKeyValueFloat(entity, "magnitude", Force);
	DispatchKeyValue(entity, "spawnflags", "8");
	AcceptEntityInput(entity, "Enable");
	return entity;
}

/*

	Need to determine if the player has special ammo or not.
*/
stock bool:HasSpecialAmmo(client, String:TalentNameEx[] = "none") {

	decl String:TalentName[64];
	new ArraySize = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < ArraySize; i++) {

		SpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		SpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
		if (!StrEqual(TalentNameEx, "none", false) && !StrEqual(TalentName, TalentNameEx, false)) continue;

		if (GetKeyValueInt(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?") == 0) continue;
		if ((GetTalentStrength(client, TalentName) * 1.0) <= 0.0) continue;

		return true;
	}
	return false;
}

stock bool:GetActiveSpecialAmmoType(client, effect) {

	decl String:EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", effect);
	decl String:TheAmmoEffect[10];
	GetSpecialAmmoEffect(TheAmmoEffect, sizeof(TheAmmoEffect), client, ActiveSpecialAmmo[client]);

	if (StrContains(TheAmmoEffect, EffectT, true) != -1) return true;
	return false;
}

/*

	Checks whether a player is within range of a special ammo, and if they are, how affected they are.
	GetStatusOnly is so we know whether to start the revive bar for revive ammo, without triggering the actual effect, we just want to know IF they're affected, for example.
	If ammoposition is >= 0 AND GetStatus is enabled, it will return only for the ammo in question.
*/

stock Float:IsClientInRangeSpecialAmmo(client, String:EffectT[], bool:GetStatusOnly=true, AmmoPosition=-1, Float:baseeffectvalue=0.0, realowner=0) {

	static String:text[512];
	static String:result[6][512];
	static String:t_pos[3][512];
	static Float:EntityPos[3];
	decl String:TalentInfo[4][512];
	static owner = 0;
	static pos = -1;
	//decl String:newvalue[10];

	static String:value[10];
	//new Float:f_Strength = 0.0;
	//decl String:t_effect[4];

	new Float:EffectStrength = 0.0;
	new Float:EffectStrengthBonus = 0.0;
	new bool:IsInfected = false;
	new bool:IsSameteam = false;

	static Float:ClientPos[3];
	//decl String:EffectT[4];
	if (!IsLegitimateClient(client) || !IsPlayerAlive(client)) return EffectStrength;
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
	else if (IsCommonInfected(client) || IsWitch(client)) {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
		IsInfected = true;
	}

	new Float:EffectStrengthValue = 0.0;
	new Float:EffectMultiplierValue = 0.0;

	static Float:t_Range	= 0.0;
	new baseeffectbonus = 0;

	if (GetArraySize(SpecialAmmoData) < 1) return 0.0;

	//Format(EffectT, sizeof(EffectT), "%c", effect);
	for (new i = AmmoPosition; i < GetArraySize(SpecialAmmoData); i++) {

		if (i < 0) i = 0;
		if (AmmoPosition != -1 && i != AmmoPosition) continue;

		GetArrayString(Handle:SpecialAmmoData, i, text, sizeof(text));
		ExplodeString(text, "}", result, 6, 512);

		ExplodeString(result[0], " ", t_pos, 5, 512);
		EntityPos[0] = StringToFloat(t_pos[0]);
		EntityPos[1] = StringToFloat(t_pos[1]);
		EntityPos[2] = StringToFloat(t_pos[2]);
		ExplodeString(result[1], "{", TalentInfo, 4, 512);
		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval
		owner = FindClientWithAuthString(result[2]);
		//if (AmmoPosition == -1 && StringToFloat(TalentInfo[3]) > 0.0) continue;
		//if (StringToFloat(TalentInfo[3]) > 0.0) continue;
		if (!IsLegitimateClientAlive(owner) || GetClientTeam(owner) != TEAM_SURVIVOR || StringToFloat(TalentInfo[3]) <= 0.0) continue;
		if (IsPvP[owner] != 0 && client != owner) continue;

		pos			= GetMenuPosition(owner, TalentInfo[0]);
		IsClientInRangeSAKeys[owner]				= GetArrayCell(a_Menu_Talents, pos, 0);
		IsClientInRangeSAValues[owner]				= GetArrayCell(a_Menu_Talents, pos, 1);
		FormatKeyValue(value, sizeof(value), IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "ammo effect?");
		//Format(value, sizeof(value), "%s", GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "ammo effect?"));
		if (!StrEqual(value, EffectT, true)) continue;
		if (GetSpecialAmmoStrength(owner, TalentInfo[0], 3) == -1.0) continue;
		t_Range		= GetSpecialAmmoStrength(owner, TalentInfo[0], 3);
		t_Range = GetClassMultiplier(client, t_Range, "aamRNG");
		if (GetVectorDistance(ClientPos, EntityPos) > (t_Range / 2)) continue;

		/*if (!IsCommonInfected(client) && !IsLegitimateClientAlive(client) && GetKeyValueInt(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "humanoid only?")) == 1) continue;
		if ((IsCommonInfected(client) || IsLegitimateClientAlive(client)) && GetKeyValueInt(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "inanimate only?")) == 1) continue;
		if (GetKeyValueInt(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "allow commons?")) == 0 && IsCommonInfected(client) ||
			GetKeyValueInt(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "allow specials?")) == 0 && IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED ||
			GetKeyValueInt(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "allow survivors?")) == 0 && IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) continue;*/
		if (GetStatusOnly) {

			//LogMessage("Entity %d in range of ammo %c", client, effect);
			return -2.0;		// -2.0 is a special designation.
		}

		if (realowner == 0 || realowner == owner) {

			EffectStrengthValue = GetKeyValueFloat(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect strength?");
			EffectMultiplierValue = GetKeyValueFloat(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect multiplier?");

			if (EffectStrengthBonus == 0.0) {

				EffectStrength += EffectStrengthValue;
				EffectStrengthBonus = EffectMultiplierValue;
			}
			else {

				EffectStrength += (EffectStrengthValue * EffectStrengthBonus);
				EffectStrengthBonus *= EffectMultiplierValue;
			}

			if (baseeffectvalue > 0.0 && owner != client) {

				/*

					Award the user who has buffed a player.
				*/

				if (!IsInfected && GetClientTeam(client) == GetClientTeam(owner)) IsSameteam = true;





				baseeffectbonus = RoundToCeil(baseeffectvalue + (baseeffectvalue * EffectStrengthValue));
				baseeffectbonus += RoundToCeil(baseeffectbonus * SurvivorExperienceMult);
				if (baseeffectbonus > 0) {

					if (IsSameteam) {

						if (StrEqual(EffectT, "H", true)) AwardExperience(owner, 1, baseeffectbonus);
						if (StrEqual(EffectT, "d", true) ||
							StrEqual(EffectT, "D", true) ||
							StrEqual(EffectT, "R", true) ||
							StrEqual(EffectT, "E", true) ||
							StrEqual(EffectT, "W", true) ||
							StrEqual(EffectT, "a", true)) AwardExperience(owner, 2, baseeffectbonus);
					}
					else {

						if ((StrEqual(EffectT, "F", true) || StrEqual(EffectT, "W", true) || StrEqual(EffectT, "x", true)) && IsLegitimateClient(client) && GetClientTeam(client) != GetClientTeam(owner) ||
							(StrEqual(EffectT, "F", true) || StrEqual(EffectT, "x", true)) && IsInfected) AwardExperience(owner, 3, baseeffectbonus);
					}
				}
			}
		}
		if (AmmoPosition != -1) break;
	}
	return EffectStrength;
}

public Action:Timer_AmmoTriggerCooldown(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) AmmoTriggerCooldown[client] = false;
	return Plugin_Stop;
}

stock AdvertiseAction(client, String:TalentName[], bool:isSpell = false) {

	decl String:TalentName_Temp[64];
	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;

		Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", TalentName, i);
		if (isSpell) PrintToChat(i, "%T", "player uses spell", i, blue, Name, orange, green, TalentName_Temp, orange);
		else PrintToChat(i, "%T", "player uses ability", i, blue, Name, orange, green, TalentName_Temp, orange);
	}
}

stock Float:GetSpellCooldown(client, String:TalentName[]) {

	new Float:SpellCooldown = GetAbilityValue(client, TalentName, "cooldown?");
	new Float:TheAbilityMultiplier = GetAbilityMultiplier(client, 'L');

	if (TheAbilityMultiplier != -1.0) {

		if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
		else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced

			SpellCooldown -= (SpellCooldown * TheAbilityMultiplier);
			if (SpellCooldown < 0.0) SpellCooldown = 0.0;
		}
	}
	return SpellCooldown;
}

stock bool:UseAbility(client, target = -1, String:TalentName[], Handle:Keys, Handle:Values, Float:TargetPos[3]) {

	if (!b_IsActiveRound || !IsLegitimateClass(client) || GetAmmoCooldownTime(client, TalentName, true) != -1.0 || IsAbilityActive(client, TalentName)) return false;
	if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, TargetPos);

	new Float:TheAbilityMultiplier = 0.0;

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);

	new MySecondary = GetPlayerWeaponSlot(client, 1);
	decl String:MyWeapon[64];

	decl String:Effects[64];
	//new Float:AbilityTime = GetAbilityValue(client, TalentName, "active time?");
	new Float:SpellCooldown = GetSpellCooldown(client, TalentName);

	new MyAttacker = L4D2_GetInfectedAttacker(client);
	new MyStamina = GetPlayerStamina(client);
	new MyBonus = 0;
	new MyMaxHealth = GetMaximumHealth(client);
	new iSkyLevelRequirement = GetKeyValueInt(Keys, Values, "sky level requirement?");
	if (iSkyLevelRequirement < 0) iSkyLevelRequirement = 0;

	if (SkyLevel[client] < iSkyLevelRequirement) return false;

	decl String:ClassRoles[64];
	GetMenuOfTalent(client, ActiveClass[client], ClassRoles, sizeof(ClassRoles));

	FormatKeyValue(Effects, sizeof(Effects), Keys, Values, "toggle effect?");
	if (StrContains(Effects, "r", true) != -1) {

		if (!IsPlayerAlive(client) && b_HasDeathLocation[client]) {

			MyRespawnTarget[client] = -1;
			CreateTimer(3.0, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, Timer_GiveMaximumHealth, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else return false;
	}
	if (StrContains(Effects, "P", true) != -1) {

		// Toggles between pistol / magnum
		if (IsValidEntity(MySecondary)) {

			GetEntityClassname(MySecondary, MyWeapon, sizeof(MyWeapon));
			if (StrContains(MyWeapon, "pistol", false) != -1) {

				// This ability only works if a melee weapon is not equipped.
				RemovePlayerItem(client, MySecondary);
				AcceptEntityInput(MySecondary, "Kill");
				if (StrContains(MyWeapon, "magnum", false) == -1) {

					// give them a magnum.
					ExecCheatCommand(client, "give", "pistol_magnum");
				}
				else {

					// make them dual wield.
					ExecCheatCommand(client, "give", "pistol");
					CreateTimer(0.5, Timer_GiveSecondPistol, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	if (StrContains(Effects, "T", true) != -1) {

		//if (GetClientStance(client, 1)) GetClientStance(client, 0, true);
		//else if (StrContains(ClassRoles, "Tank", false) != -1) GetClientStance(client, 1, true);
		if (StrContains(ClassRoles, "Tank", false) != -1) GetClientStance(client, GetAmmoCooldownTime(client, TalentName, true));
	}
	if (StrContains(Effects, "S", true) != -1) {

		decl String:clientname[64];
		if (IsLegitimateClientAlive(MyAttacker)) {

			//L4D_StaggerPlayer(MyAttacker, client, NULL_VECTOR);
			GetClientName(MyAttacker, clientname, sizeof(clientname));
			ExecCheatCommand(-1, "sm_slap", clientname);
		}
		//L4D_StaggerPlayer(client, client, NULL_VECTOR);
		GetClientName(client, clientname, sizeof(clientname));
		ExecCheatCommand(-1, "sm_slap", clientname);
	}
	FormatKeyValue(Effects, sizeof(Effects), Keys, Values, "active effect?");
	if (!StrEqual(Effects, "-1")) {

		//if (AbilityTime > 0.0) IsAbilityActive(client, TalentName, AbilityTime);
		//We check active time another way now

		if (StrContains(Effects, "A", true) != -1) { // restores stamina

			TheAbilityMultiplier = GetAbilityMultiplier(client, 'A', 1);
			MyBonus = RoundToCeil(MyStamina * TheAbilityMultiplier);
			if (SurvivorStamina[client] + MyBonus > MyStamina) {

				SurvivorStamina[client] = MyStamina;
			}
			else SurvivorStamina[client] += MyBonus;
		}
		if (StrContains(Effects, "H", true) != -1) {	// heals the individual

			if (L4D2_GetInfectedAttacker(client) == -1) {

				TheAbilityMultiplier = GetAbilityMultiplier(client, 'H', 1);
				//HealPlayer(client, client, (MyMaxHealth * TheAbilityMultiplier), 'h', true);
				HealPlayer(client, client, TheAbilityMultiplier, 'h');
			}
			else return false;
		}
		if (StrContains(Effects, "t", true) != -1) {	// instantly lowers threat by a percentage

			TheAbilityMultiplier = GetAbilityMultiplier(client, 't', 1);
			iThreatLevel[client] -= RoundToFloor(iThreatLevel[client] * TheAbilityMultiplier);
		}
	}

	//if (menupos >= 0) CheckActiveAbility(client, menupos, _, _, true, true);
	AdvertiseAction(client, TalentName, false);
	IsAmmoActive(client, TalentName, SpellCooldown, true);
	return true;
}

public Action:Timer_GiveSecondPistol(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		ExecCheatCommand(client, "give", "pistol");
	}
	return Plugin_Stop;
}

stock bool:CastSpell(client, target = -1, String:TalentName[], Float:TargetPos[3]) {

	if (!b_IsActiveRound || !IsLegitimateClientAlive(client) || L4D2_GetInfectedAttacker(client) != -1 || !IsLegitimateClass(client) || GetAmmoCooldownTime(client, TalentName) != -1.0) return false;
	if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, TargetPos);	// if the target is -1 / not alive, TargetPos will have been sent through.

	if (bIsSurvivorFatigue[client]) return false;

	new StaminaCost = RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2));
 	if (SurvivorStamina[client] < StaminaCost) return false;
 	SurvivorStamina[client] -= StaminaCost;
	if (SurvivorStamina[client] <= 0) {

		bIsSurvivorFatigue[client] = true;
		IsSpecialAmmoEnabled[client][0] = 0.0;
	}

	//IsAbilityActive(client, TalentName, AbilityTime);

	AdvertiseAction(client, TalentName, true);

	//new Float:SpellCooldown = GetSpecialAmmoStrength(client, TalentName, 1);
	//IsAmmoActive(client, TalentName, SpellCooldown);	// place it on cooldown for the lifetime (not the interval, even if it's greater)

	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	new ClientMenuPosition = GetMenuPosition(client, TalentName);

	new Float:f_TotalTime = GetSpecialAmmoStrength(client, TalentName);
	new Float:SpellCooldown = f_TotalTime + GetSpecialAmmoStrength(client, TalentName, 1);
	
	// It's going to be a headache re-structuring this, so i am doing it in a sequence. to make it easier interval will just clone totaltime for now.
	new Float:f_Interval = f_TotalTime; //GetSpecialAmmoStrength(client, TalentName, 4);

	//if (f_Interval > f_TotalTime) f_Interval = f_TotalTime;
	IsAmmoActive(client, TalentName, SpellCooldown);

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i)) DrawSpecialAmmoTarget(i, _, _, ClientMenuPosition, TargetPos[0], TargetPos[1], TargetPos[2], f_Interval, client, TalentName, target);
	}

	new bulletStrength = RoundToCeil(GetBaseWeaponDamage(client, -1, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET) * 0.1);
	bulletStrength = RoundToCeil(GetAbilityStrengthByTrigger(client, -2, 'D', _, bulletStrength, _, _, "D", 1));
	new Float:amSTR = GetSpecialAmmoStrength(client, TalentName, 5);
	if (amSTR > 0.0) bulletStrength = RoundToCeil(bulletStrength * amSTR);

	if (fSpellBulletStrength > 0.0) {

		if (StrContains(ActiveClass[client], "healer", false) == -1) bulletStrength = RoundToCeil(bulletStrength * fSpellBulletStrength);
		bulletStrength += RoundToCeil(bulletStrength * (GetTalentStrength(client, "endurance") * fSpellEnduranceMultiplier));
	}
	decl String:SpecialAmmoData_s[512];
	//Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", TargetPos[0], TargetPos[1], TargetPos[2], TalentName, GetTalentStrength(client, TalentName), GetBaseWeaponDamage(client, -1, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET), f_Interval, key, SpellCooldown, -1, GetSpecialAmmoStrength(client, TalentName, 1), target);
	Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", TargetPos[0], TargetPos[1], TargetPos[2], TalentName, GetTalentStrength(client, TalentName), bulletStrength, f_Interval, key, f_TotalTime, -1, GetSpecialAmmoStrength(client, TalentName, 1), target);
	PushArrayString(Handle:SpecialAmmoData, SpecialAmmoData_s);
	return true;
}

/*

	When special ammo conditions are met, call the trigger.
*/
/*stock bool:TriggerSpecialAmmo(client, target, TotalDamage, Float:f_ActiveTime, Float:f_Interval, Float:PosX=0.0, Float:PosY=0.0, Float:PosZ=0.0) {

	if (!b_IsActiveRound || !IsLegitimateClass(client)) return false;
	//if (f_Interval < 0.0) return false;
	if (IsAmmoActive(client, ActiveSpecialAmmo[client])) return false;
	if (AmmoTriggerCooldown[client]) return false;
	//if (IsPlayerUsingShotgun(client)) {

	AmmoTriggerCooldown[client] = true;
	decl String:Name[MAX_NAME_LENGTH];
	CreateTimer(0.5, Timer_AmmoTriggerCooldown, client, TIMER_FLAG_NO_MAPCHANGE);
	//}

	//	For special ammos that have an active time, create a new position in dynamic array, insert the targets position and the active time.
	//	When the engine time is >= the active time, we remove the item from the list and players are no longer affected by it.
	//	This seems better than creating actual entities. Remember we only got here if the ammo wasn't on cooldown and it was a legitimate target so we make it here.
	new Float:TargetPos[3];
	new targetClientId = -1;
	if (!IsLegitimateClientAlive(target) && !IsCommonInfected(target) && !IsWitch(target)) target = -1;
	else {	// If the target exists (only when a talent calls it) we want to spawn it on their position.

		if (IsCommonInfected(target) || IsWitch(target)) GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);
		else GetClientAbsOrigin(target, TargetPos);

		PosX = TargetPos[0] - 10.0;
		PosY = TargetPos[1] - 10.0;
		PosZ = TargetPos[2] - 10.0;
		if (IsLegitimateClientAlive(target)) {

			if (!IsSurvivorBot(target)) GetClientName(target, Name, sizeof(Name));
			else GetSurvivorBotName(target, Name, sizeof(Name));
			PrintToChat(client, "%T", "special ammo target selected", client, orange, green, Name);

			if (!IsFakeClient(target)) {

				GetClientName(client, Name, sizeof(Name));
				PrintToChat(target, "%T", "special ammo targeted", target, orange, green, Name);
			}
		}
	}

	if (IsLegitimateClientAlive(LastTarget[client])) targetClientId = LastTarget[client];

	if (!IsAmmoActive(client, ActiveSpecialAmmo[client])) IsAmmoActive(client, ActiveSpecialAmmo[client], f_Interval);

	new WorldEnt = -1;
	decl String:TheAmmoEffect[10];
	GetSpecialAmmoEffect(TheAmmoEffect, sizeof(TheAmmoEffect), client, ActiveSpecialAmmo[client]);

	if (StrContains(TheAmmoEffect, "g", true) != -1) {

		WorldEnt = CreateGravityAmmo(client, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 5), GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 3));
	}

	// Because client ids change, we store steamid of owner.
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	//LogMessage(SpecialAmmoData_s);
	//CheckActiveAmmoCooldown(client, ActiveSpecialAmmo[client], true);
	//LogMessage("Storing ammo point info : %s", SpecialAmmoData_s);

	decl String:TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", ActiveSpecialAmmo[client]);
	new ClientMenuPosition = GetMenuPosition(client, TalentName);

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i)) DrawSpecialAmmoTarget(i, _, _, ClientMenuPosition, PosX, PosY, PosZ, f_Interval, client, ActiveSpecialAmmo[client]);
	}
	//if (IsLegitimateClientAlive(targetClientId) && !IsFakeClient(targetClientId)) DrawSpecialAmmoTarget(client, _, _, ClientMenuPosition, PosX, PosY, PosZ, f_Interval, client, ActiveSpecialAmmo[client]);

	decl String:SpecialAmmoData_s[512];
	Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", PosX, PosY, PosZ, ActiveSpecialAmmo[client], GetTalentStrength(client, ActiveSpecialAmmo[client]), TotalDamage, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 4), key, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client]), WorldEnt, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 1), targetClientId);

	PushArrayString(Handle:SpecialAmmoData, SpecialAmmoData_s);
	return true;
}*/

public Action:Timer_SpecialAmmoData(Handle:timer) {

	if (!b_IsActiveRound) {

		ClearArray(Handle:SpecialAmmoData);
		return Plugin_Stop;
	}

	static String:text[512];
	static String:result[7][512];
	static String:t_pos[3][512];
	static Float:EntityPos[3];
	//new Float:TargetPos[3];
	static String:TalentInfo[4][512];
	static client = 0;
	static Float:f_TimeRemaining = 0.0;
	//static Float:f_Interval = 0.0;
	//static Float:f_Cooldown = 0.0;
	//new size = GetArraySize(SpecialAmmoData);
	static WorldEnt = -1;
	static ent = -1;
	static drawtarget = -1;
	//new ammotarget = -1;
	static String:DataAmmoEffect[10];
	//LogMessage("Ammo size: %d", size);

	static Float:AmmoStrength = 0.0;
	//static ThePosition = -1;
	//static Float:TheStrength = -1.0;
	//static bool:hastargetfound = false;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i)) CheckActiveAbility(i, -1, _, _, true);	// draws effects for any active ability.
	}

	for (new i = 0; i < GetArraySize(Handle:SpecialAmmoData); i++) {

		AmmoStrength = 0.0;

		Format(DataAmmoEffect, sizeof(DataAmmoEffect), "0");	// reset it after each go.

		//hastargetfound = false;

		GetArrayString(Handle:SpecialAmmoData, i, text, sizeof(text));
		//LogMessage("Original: %s", text);
		ExplodeString(text, "}", result, 7, 512);

		WorldEnt = StringToInt(result[4]);

		client = FindClientWithAuthString(result[2]);
		//f_Interval -= 0.01;

		if (!IsLegitimateClientAlive(client) || GetClientTeam(client) != TEAM_SURVIVOR) {

			RemoveFromArray(Handle:SpecialAmmoData, i);
			//if (i > 0) i--;
			//size = GetArraySize(SpecialAmmoData);
			//if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) CheckActiveAmmoCooldown(client, TalentInfo[0], true);// should the cooldown start when the first bullet expires, or when the first bullets first cooldown(interval) occurs? need to calculate. is it too spammy?
			if (IsValidEntity(WorldEnt)) AcceptEntityInput(WorldEnt, "Kill");
			continue;
		}

		ExplodeString(result[0], " ", t_pos, 3, 512);
		EntityPos[0] = StringToFloat(t_pos[0]);
		EntityPos[1] = StringToFloat(t_pos[1]);
		EntityPos[2] = StringToFloat(t_pos[2]);

		ExplodeString(result[1], "{", TalentInfo, 4, 512);
		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval

		//f_Interval = StringToFloat(TalentInfo[3]);

		f_TimeRemaining = StringToFloat(result[3]) - 0.2;
		//f_TimeRemaining -= 0.01;

		//f_Cooldown = StringToFloat(result[5]);
		drawtarget = StringToInt(result[6]);
		GetSpecialAmmoEffect(DataAmmoEffect, sizeof(DataAmmoEffect), client, TalentInfo[0]);
		//Format(DataAmmoEffect, sizeof(DataAmmoEffect), "%s", GetSpecialAmmoEffect(client, TalentInfo[0]));

		//f_Interval = f_TimeRemaining;
		//if (f_Interval > f_TimeRemaining) f_Interval = f_TimeRemaining;
		if (f_TimeRemaining > 0.0) {

			//ThePosition = GetTalentPosition(client, TalentInfo[0]);
			//TheStrength = GetSpecialAmmoStrength(client, TalentInfo[0], 1);
			
			if (IsClientInRangeSpecialAmmo(client, DataAmmoEffect, _, i) == -2.0) {

				AmmoStrength			= (IsClientInRangeSpecialAmmo(client, DataAmmoEffect, false, _, StringToInt(TalentInfo[2]) * 1.0));
				AmmoStrength			*= StringToInt(TalentInfo[2]);
				if (AmmoStrength > 0.0) {

					//if (StrContains(DataAmmoEffect, "b", true) == -1) AmmoStrength *= StringToInt(TalentInfo[2]);
					//CreateCooldown(client, ThePosition, TheStrength);

					if (StrContains(DataAmmoEffect, "b", true) != -1) BeanBagAmmo(client, AmmoStrength, client);
					else if (StrContains(DataAmmoEffect, "a", true) != -1 && !HasAdrenaline(client)) SetAdrenalineState(client, f_TimeRemaining);
					else if (StrContains(DataAmmoEffect, "x", true) != -1) ExplosiveAmmo(client, RoundToCeil(AmmoStrength), client);
					else if (StrContains(DataAmmoEffect, "H", true) != -1) {

						//LogToFile(LogPathDirectory, "Healing ammo %N for %3.3f (%d)", client, AmmoStrength, GetMaximumHealth(client));

						HealingAmmo(client, RoundToCeil(AmmoStrength), client);
					}
					else if (StrContains(DataAmmoEffect, "F", true) != -1) {

						if (ISEXPLODE[client] == INVALID_HANDLE) CreateAndAttachFlame(client, RoundToCeil(AmmoStrength), f_TimeRemaining, f_TimeRemaining);
	 					else if (ISEXPLODE[client] != INVALID_HANDLE) CreateAndAttachFlame(client, RoundToCeil(AmmoStrength * TheScorchMult), f_TimeRemaining, f_TimeRemaining);
					}
					else if (StrContains(DataAmmoEffect, "B", true) != -1 && !ISBILED[client]) {

						SDKCall(g_hCallVomitOnPlayer, client, client, true);
						//IsCoveredInVomit(client, client);
						ISBILED[client] = true;
					}
				}
			}
			for (new ammotarget = 1; ammotarget <= MaxClients; ammotarget++) {

				if (ammotarget != client && IsLegitimateClientAlive(ammotarget) && IsClientInRangeSpecialAmmo(ammotarget, DataAmmoEffect, _, i) == -2.0) {

					AmmoStrength			= (IsClientInRangeSpecialAmmo(ammotarget, DataAmmoEffect, false, _, StringToInt(TalentInfo[2]) * 1.0));
					AmmoStrength			*= StringToInt(TalentInfo[2]);

					if (AmmoStrength <= 0.0) continue;

					//CreateCooldown(ammotarget, ThePosition, TheStrength);
					//if (StrContains(DataAmmoEffect, "b", true) == -1 && StrContains(DataAmmoEffect, "W", true) == -1) AmmoStrength *= StringToInt(TalentInfo[2]);

					if (StrContains(DataAmmoEffect, "b", true) != -1) BeanBagAmmo(ammotarget, AmmoStrength, client);
					else if ((GetClientTeam(ammotarget) == TEAM_SURVIVOR || IsSurvivorBot(ammotarget)) && StrContains(DataAmmoEffect, "a", true) != -1 && !HasAdrenaline(ammotarget)) SetAdrenalineState(ammotarget, f_TimeRemaining);
					else if (GetClientTeam(ammotarget) == TEAM_INFECTED && StrContains(DataAmmoEffect, "x", true) != -1) ExplosiveAmmo(ammotarget, RoundToCeil(AmmoStrength), client);
					else if ((GetClientTeam(ammotarget) == TEAM_SURVIVOR || IsSurvivorBot(ammotarget)) && StrContains(DataAmmoEffect, "H", true) != -1) HealingAmmo(ammotarget, RoundToCeil(AmmoStrength), client);
					else if (GetClientTeam(ammotarget) == TEAM_INFECTED && StrContains(DataAmmoEffect, "h", true) != -1) LeechAmmo(ammotarget, RoundToCeil(AmmoStrength), client);
					else if (StrContains(DataAmmoEffect, "F", true) != -1) {

						DoBurn(client, ammotarget, RoundToCeil(AmmoStrength));
					}
					else if (StrContains(DataAmmoEffect, "B", true) != -1 && !ISBILED[ammotarget]) {

						SDKCall(g_hCallVomitOnPlayer, ammotarget, client, true);
						//IsCoveredInVomit(ammotarget, client);
						ISBILED[ammotarget] = true;
					}
					else if (StrContains(DataAmmoEffect, "C", true) != -1 && AmmoStrength <= 0.0) {
				
						if (IsClientStatusEffect(ammotarget, Handle:EntityOnFire)) {

							TransferStatusEffect(ammotarget, Handle:EntityOnFire, client);
						}
					}
					//hastargetfound = true;
					//break;
				}
			}
			if (StrContains(DataAmmoEffect, "x", true) != -1) {

				CreateAmmoExplosion(client, EntityPos[0], EntityPos[1], EntityPos[2]);
				//continue;
			}
			if (StrContains(DataAmmoEffect, "x", true) != -1 ||
				StrContains(DataAmmoEffect, "h", true) != -1 ||
				StrContains(DataAmmoEffect, "F", true) != -1) {

				for (new zombie = 0; zombie < GetArraySize(Handle:CommonInfected); zombie++) {

					ent = GetArrayCell(Handle:CommonInfected, zombie);
					//if (!IsSpecialCommon(ent)) continue;
					if (!IsCommonInfected(ent)) continue;	// || IsClientInRangeSpecialAmmo(ent, DataAmmoEffect, _, i) != -2.0) continue;
					if (IsClientInRangeSpecialAmmo(ent, DataAmmoEffect, _, i) == -2.0) AmmoStrength			= (IsClientInRangeSpecialAmmo(ent, DataAmmoEffect, false, _, StringToInt(TalentInfo[2]) * 1.0)) * StringToInt(TalentInfo[2]);
					else continue;
					AmmoStrength			*= StringToInt(TalentInfo[2]);
					if (AmmoStrength <= 0.0) continue;

					if (StrContains(DataAmmoEffect, "x", true) != -1) {

						ExplosiveAmmo(ent, RoundToCeil(AmmoStrength), client);
						//break;
					}
					if (StrContains(DataAmmoEffect, "h", true) != -1) {

						LeechAmmo(ent, RoundToCeil(AmmoStrength), client);
						//break;
					}
					if (StrContains(DataAmmoEffect, "F", true) != -1) {

						DoBurn(client, ent, RoundToCeil(AmmoStrength));

						//CreateAndAttachFlame(ent, RoundToCeil(AmmoStrength), f_TimeRemaining, f_Interval);
						//break;
					}
				}
			}
		}
		else {

			RemoveFromArray(Handle:SpecialAmmoData, i);
			if (IsValidEntity(WorldEnt)) AcceptEntityInput(WorldEnt, "Kill");
			continue;
		}

		for (new ii = 1; ii <= MaxClients; ii++) {

			if (IsLegitimateClientAlive(ii) && strlen(MyAmmoEffects[ii]) > 0) Format(MyAmmoEffects[ii], sizeof(MyAmmoEffects[]), "");
		}

		//Format(text, sizeof(text), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", EntityPos[0], EntityPos[1], EntityPos[2], TalentInfo[0], GetTalentStrength(client, TalentInfo[0]), StringToInt(TalentInfo[2]), f_Interval, result[2], f_TimeRemaining, WorldEnt, f_Cooldown, drawtarget);
		Format(text, sizeof(text), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", EntityPos[0], EntityPos[1], EntityPos[2], TalentInfo[0], GetTalentStrength(client, TalentInfo[0]), StringToInt(TalentInfo[2]), f_TimeRemaining, result[2], f_TimeRemaining, WorldEnt, f_TimeRemaining, drawtarget);
		SetArrayString(Handle:SpecialAmmoData, i, text);
		//LogMessage(text);
		//size = GetArraySize(Handle:SpecialAmmoData);
	}
	return Plugin_Continue;
}

stock DoBurn(attacker, victim, baseWeaponDamage) {

	//if (iTankRush == 1 && FindZombieClass(victim) == ZOMBIECLASS_TANK) return;

	if (IsLegitimateClientAlive(victim)) {

		bIsBurnCooldown[victim] = true;
		CreateTimer(1.0, Timer_ResetBurnImmunity, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
 	new hAttacker = attacker;
 	if (!IsLegitimateClient(hAttacker)) hAttacker = -1;

 	if (IsCommonInfected(victim) || IsWitch(victim)) {

		if (IsCommonInfected(victim)) {

			if (!IsSpecialCommon(victim)) OnCommonInfectedCreated(victim, true);
			else AddSpecialCommonDamage(attacker, victim, baseWeaponDamage, true);
		}
		else if (IsWitch(victim) && !(GetEntityFlags(victim) & FL_ONFIRE)) {

			IgniteEntity(victim, 10.0);
			AddWitchDamage(attacker, victim, baseWeaponDamage, true);
		}
	}
 	if (IsLegitimateClientAlive(victim) && GetClientStatusEffect(victim, Handle:EntityOnFire, "burn") < iDebuffLimit) {

		if (ISEXPLODE[victim] == INVALID_HANDLE) CreateAndAttachFlame(victim, RoundToCeil(baseWeaponDamage * TheInfernoMult), 1.0, 0.1, hAttacker, "burn");
		else CreateAndAttachFlame(victim, RoundToCeil((baseWeaponDamage * TheInfernoMult) * TheScorchMult), 1.0, 0.1, hAttacker, "burn");
 	}
}

stock BeanBagAmmo(client, Float:force, TalentClient) {

	if (!IsCommonInfected(client) && !IsLegitimateClientAlive(client)) return;
	if (!IsLegitimateClientAlive(TalentClient)) return;

	new Float:Velocity[3];
	
	Velocity[0]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[0]");
	Velocity[1]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[1]");
	Velocity[2]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[2]");

	new Float:Vec_Pull;
	new Float:Vec_Lunge;
	if (client != TalentClient) {

		//new CartXP = RoundToCeil(GetClassMultiplier(TalentClient, force, "enX", true));
		AddTalentExperience(TalentClient, "endurance", RoundToCeil(force));
	}

	Vec_Pull	=	GetRandomFloat(force * -1.0, force);
	Vec_Lunge	=	GetRandomFloat(force * -1.0, force);
	Velocity[2]	+=	force;

	if (Vec_Pull < 0.0 && Velocity[0] > 0.0) Velocity[0] *= -1.0;
	Velocity[0] += Vec_Pull;

	if (Vec_Lunge < 0.0 && Velocity[1] > 0.0) Velocity[1] *= -1.0;
	Velocity[1] += Vec_Lunge;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
}

/*

	When a client who has special ammo enabled has an eligible target highlighted, we want to draw an aura around that target (just for the client)
	This aura will cycle appropriately as a player cycles their active ammo.

	I have consciously made the decision (ahead of time, having this foresight) to design it so special ammos cannot be used on self. If a client
	wants to use a defensive ammo, for example, on themselves, they would need to shoot an applicable target (enemy, teammate, vehicle... lol) and then step
	into the range.
*/

// no one sees my special ammo because it should be drawing it based on MY size not theirs but it's drawing it based on theirs and if they have zero points in the talent then they can't see it.
stock DrawSpecialAmmoTarget(TargetClient, bool:IsDebugMode=false, bool:IsValidTarget=false, CurrentPosEx=-1, Float:PosX=0.0, Float:PosY=0.0, Float:PosZ=0.0, Float:f_ActiveTime=0.0, owner=0, String:TalentName[]="none", Target = -1) {		// If we aren't actually drawing..? Stoned idea lost in thought but expanded somewhat not on the original path

	new client = TargetClient;
	if (owner != 0) client = owner;

	if (iRPGMode <= 0) {

		return -1;
	}

	new CurrentPos	= GetMenuPosition(client, TalentName);
	new bool:i_IsDebugMode = false;

	DrawSpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, CurrentPos, 0);
	DrawSpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, CurrentPos, 1);

	if (CurrentPosEx == -1) {

		if (GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "humanoid only?") == 1) {

			//Humanoid Only could apply to a wide-range so we break it down here.
			if (!IsCommonInfected(Target) && !IsLegitimateClientAlive(Target)) i_IsDebugMode = true;
		}
		if (GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "inanimate only?") == 1) {

			//This is things like vehicles, dumpsters, and other objects that can one-shot your teammates.
			if (IsCommonInfected(Target) || IsLegitimateClientAlive(Target)) i_IsDebugMode = true;
		}
		if (GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow commons?") == 0 && IsCommonInfected(Target) ||
			GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow specials?") == 0 && IsLegitimateClientAlive(Target) && GetClientTeam(Target) == TEAM_INFECTED ||
			GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow survivors?") == 0 && IsLegitimateClientAlive(Target) && (GetClientTeam(Target) == TEAM_SURVIVOR || IsSurvivorBot(Target))) i_IsDebugMode = true;

		if (i_IsDebugMode && !IsDebugMode) return 0;		// ie if an invalid target is highlighted and debug mode is disabled we don't draw and we don't tell the player anything.
		if (IsValidTarget) {

			if (i_IsDebugMode) return 0;
			else return 1;
		}
	}
	new Float:AfxRange			= GetSpecialAmmoStrength(client, TalentName, 3);

	decl String:AfxDrawPos[64];
	decl String:AfxDrawColour[64];
	FormatKeyValue(AfxDrawPos, sizeof(AfxDrawPos), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw pos?");
	if (IsDebugMode) FormatKeyValue(AfxDrawColour, sizeof(AfxDrawColour), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "invalid target colour?");
	else FormatKeyValue(AfxDrawColour, sizeof(AfxDrawColour), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "valid target colour?");
	// If the above two fields return -1 (meaning they are omitted) we assume it is a single-target-only ability.

	if (StrEqual(AfxDrawColour, "-1", false)) return -1;		// if there's no colour, we return otherwise you'll get errors like this: TE_Send Exception reported: No TempEntity call is in progress (return 0 here would cause endless loop set to -1 as it is ignored i broke the golden rule lul)
	
	AfxRange = GetClassMultiplier(TargetClient, AfxRange, "aamRNG");
	new Float:HighlightTime = fAmmoHighlightTime;

	if (CurrentPosEx != -1) {

		CreateRingSolo(-1, AfxRange, AfxDrawColour, AfxDrawPos, false, f_ActiveTime, TargetClient, PosX, PosY, PosZ);
	}
	else {

		CreateRingSolo(Target, AfxRange, AfxDrawColour, AfxDrawPos, false, HighlightTime, TargetClient);
		IsSpecialAmmoEnabled[client][3] = Target * 1.0;
	}
	return 2;
}

// < 0 is no entity. 0 is invalid entity. we only draw invalid entities (red rings) if debug mode is enabled.
//if (DrawSpecialAmmoTarget(client) == 0 && IsPlayerDebugMode[client] == 1) DrawSpecialAmmoTarget(client, true);

/*

	Using the position of the current special ammo, we find out what the previous or next slot in the array is that contains a special ammo
	depending on what direction the player is going.
*/
stock CycleSpecialAmmo(client, bool:IsMoveForward=true, bool:GetCurrentPos=false) {

	new CurrentPos = -1;
	new firstPosition = -1;
	decl String:TalentName[64];
	new ArraySize = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < ArraySize; i++) {

		SpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		SpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		if (GetKeyValueInt(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?") != 1) continue;
		GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
		if (GetTalentStrength(client, TalentName) < 1 || IsAbilityCooldown(client, TalentName)) continue;					// necessary in case a player has the ammo equipped and then respecs into a different ammo. have to make sure any current ammo has talent points.
		if (firstPosition == -1) firstPosition = i;

		if (GetActiveSpecialAmmo(client, TalentName)) {

			CurrentPos = i;
			break;
		}
	}
	if (CurrentPos == -1) CurrentPos = firstPosition;

	if (GetCurrentPos) return CurrentPos;

	firstPosition = -1;
	new lastPosition = -1;
	for (new i = 0; i < ArraySize; i++) {

		SpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		SpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		if (GetKeyValueInt(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?") != 1) continue;
		GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
		if (GetTalentStrength(client, TalentName) < 1 || IsAbilityCooldown(client, TalentName)) continue;

		if (firstPosition == -1) {

			firstPosition = i;
			if (CurrentPos == -1) return firstPosition;								// If the player doesn't have a selected active talent, we default to the first one they have available.
		}
		if (!IsMoveForward && CurrentPos == firstPosition) lastPosition = i;		// Keep incrementing the last position and return whatever it ends up being if the current position is the first because we need the last.
		else {																		// But if we're moving forward or the last position is the current position, this is how we do it.

			if (!IsMoveForward && CurrentPos == i) break;							// If we're trying to get the previous ammo, and the current isn't the first, then it's obviously the last recorded, and we break out!
			if (IsMoveForward && CurrentPos == lastPosition && lastPosition != i) {
				
				lastPosition = i;													// Looking at the code may seem odd, but this saves us having to create an extra variable/statement.
				break;
			}
			lastPosition = i;

		}
	}
	if (IsMoveForward && CurrentPos == lastPosition && firstPosition != -1) SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, firstPosition, 2);
	else if (lastPosition != -1) SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, lastPosition, 2);

	if (firstPosition != -1) GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
	else Format(TalentName, sizeof(TalentName), "none");
	Format(ActiveSpecialAmmo[client], sizeof(ActiveSpecialAmmo[]), "%s", TalentName);

	return 0;
}

/*

	We need to get the talent name of the active special ammo.
	This way when an ammo activate triggers it only goes through if that ammo is the type the player currently has selected.
*/
stock bool:GetActiveSpecialAmmo(client, String:TalentName[]) {

	if (!StrEqual(TalentName, ActiveSpecialAmmo[client], false)) return false;
	// So if the talent is the one equipped...
	return true;
}

stock CreateProgressBar(client, Float:TheTime, bool:NahDestroyItInstead=false, bool:NoAdrenaline=false) {

	if (TheTime >= 1.0) {

		if (StrContains(ActiveClass[client], "healer", false) != -1) TheTime *= 0.5;
	}

	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	if (NahDestroyItInstead) SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	else {

		new Float:TheRealTime = TheTime;
		if (!NoAdrenaline && HasAdrenaline(client)) TheRealTime *= fAdrenProgressMult;

		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheRealTime);
		UseItemTime[client] = TheRealTime + GetEngineTime();
	}
}

stock AdjustProgressBar(client, Float:TheTime) { SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheTime); }

stock bool:ActiveProgressBar(client) {

	if (GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") <= 0.0) return false;
	return true;
}

public Action:Timer_ImmunityExpiration(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) RespawnImmunity[client] = false;
	return Plugin_Stop;
}

stock Defibrillator(client, target = 0, bool:IgnoreDistance = false) {

	if (target > 0 && IsLegitimateClientAlive(target)) return;


	// respawn people near the player.
	new respawntarget = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

			respawntarget = i;
			break;
		}
	}
	new Float:Origin[3];
	if (client > 0) GetClientAbsOrigin(client, Origin);

	// target defaults to 0.
	for (new i = target; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsPlayerAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && (i != client || target == 0) && i != target) {

			if (target > 0 && i != target) continue;

			if (target == 0 && b_HasDeathLocation[i] && (IgnoreDistance || GetVectorDistance(Origin, DeathLocation[i]) < 256.0)) {

				PrintToChatAll("%t", "rise again", white, orange, white);
				RespawnImmunity[i] = true;
				MyRespawnTarget[i] = i;
				SDKCall(hRoundRespawn, i);
				CreateTimer(0.1, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_ImmunityExpiration, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (target == 0 && !b_HasDeathLocation[i] && IsLegitimateClientAlive(respawntarget)) {

				SDKCall(hRoundRespawn, i);
				RespawnImmunity[i] = true;
				MyRespawnTarget[i] = respawntarget;
				CreateTimer(0.1, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_ImmunityExpiration, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			//SDKCall(hRoundRespawn, i);
			//if (client > 0) LastDeathTime[i] = GetEngineTime() + StringToFloat(GetConfigValue("death weakness time?"));
			//b_HasDeathLocation[i] = false;
		}
	}
}

/*public Action:Timer_BeaconCorpses(Handle:timer) {

	new CurrentEntity			=	-1;
	decl String:EntityName[64];
	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsIncapacitated(i)) continue;

		BeaconCorpsesCounter[i] += 0.01;
		if (BeaconCorpsesCounter[i] < 0.25) continue;

		CurrentEntity										= GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");
		if (IsValidEntity(CurrentEntity)) GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));
		if (StrContains(EntityName, "defib", false) == -1) continue;

		BeaconCorpsesCounter[i] = 0.0;
		BeaconCorpsesInRange(i);
	}
	return Plugin_Continue;
}*/

stock InventoryItem(client, String:EntityName[] = "none", bool:bIsPickup = false, entity = -1) {

	decl String:ItemName[64];

	new ExplodeCount = GetDelimiterCount(EntityName, ":");
	decl String:Classname[ExplodeCount][64];
	ExplodeString(EntityName, ":", Classname, ExplodeCount, 64);

	if (bIsPickup) {	// Picking up the entity. We store it in the users inventory.

		GetEntityClassname(entity, Classname[0], sizeof(Classname[]));
		GetEntPropString(entity, Prop_Data, "m_iName", ItemName, sizeof(ItemName));
	}
	else {		// Creating the entity. Defaults to -1

		entity	= CreateEntityByName(Classname[0]);
		DispatchKeyValue(entity, "targetname", Classname[1]);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "spawnflags", "0");
		DispatchSpawn(entity);
		TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	}
}

//stock bool:IsClientActiveBuff(client, effect, Float:Power=0.0)

public Action:OnPlayerRunCmd(client, &buttons) {

	new Float:TheTime = GetEngineTime();

	if ((buttons & IN_SPEED)) {

		bIsSprinting[client] = true;
	}
	else bIsSprinting[client] = false;

	//if (IsFakeClient(client)) return Plugin_Continue;

	if ((buttons & IN_USE) && b_IsRoundIsOver) {

		if (ReadyUpGameMode == 3) {

			decl String:EName[64];
			new entity = GetClientAimTarget(client, false);

			if (entity != -1) {

				//GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));
				GetEntityClassname(entity, EName, sizeof(EName));
				//PrintToChat(client, "Name: %s", EName);

				//PrintToChat(client, "ENTITY: %s", EName);
				//if (StrEqual(EName, "survival_alarm_button", false) ||
				//	StrEqual(EName, "escape_gate_button_survival", false)) {
				if (StrContains(EName, "weapon", false) != -1 || StrContains(EName, "physics", false) != -1) {

					//buttons &= ~IN_USE;
					return Plugin_Continue;
				}
				//if (StrContains(EName, "radio", false) != -1) return Plugin_Handled;
			}
			buttons &= ~IN_USE;
			return Plugin_Changed;
		}
	}
	if (ReadyUpGameMode == 3 && !b_IsCheckpointDoorStartOpened && IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

		if (buttons & IN_SPEED && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && (GetEntityFlags(client) & FL_ONGROUND)) {

			MovementSpeed[client] = fSprintSpeed;
			if (StrContains(ActiveClass[client], "zora", false) != -1 && (GetEntityFlags(client) & FL_INWATER)) MovementSpeed[client] *= 2.0;
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
			buttons &= ~IN_SPEED;
			return Plugin_Changed;
		}
		else {

			MovementSpeed[client] = 1.0;
			if (StrContains(ActiveClass[client], "zora", false) != -1 && (GetEntityFlags(client) & FL_INWATER)) MovementSpeed[client] *= 2.0;
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
		}
	}

	if (IsLegitimateClientAlive(client) && b_IsActiveRound) {

		if (!IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

			if (MyBirthday[client] == 0) MyBirthday[client] = GetTime();

			if (bRushingNotified[client] && IsPlayerRushing(client, 2048.0)) {

				//IncapacitateOrKill(client, _, _, true, true);
				FindRandomSurvivorClient(client, _, false);
				//bRushingNotified[client] = false;
			}
			else if (!bRushingNotified[client] && IsPlayerRushing(client, 1536.0)) {

				//FindRandomSurvivorClient(client);
				bRushingNotified[client] = true;
				PrintToChat(client, "%T", "Rushing Return To Team", client, orange, blue, orange);
			}
		}

		if (GetClientTeam(client) == TEAM_INFECTED && FindZombieClass(client) == ZOMBIECLASS_TANK) {

			if (!IsAirborne[client] && !(GetEntityFlags(client) & FL_ONGROUND)) {

				IsAirborne[client] = true;	// when the tank lands, aoe explosion!
			}
			else if (IsAirborne[client] && (GetEntityFlags(client) & FL_ONGROUND)) {

				IsAirborne[client] = false;	// the tank has landed; explosion;
				CreateExplosion(client, _, client, true);
			}
			new MyLifetime = GetTime() - MyBirthday[client];
			if (MyBirthday[client] > 0 && NearbySurvivors(client, 1536.0) < 1 && MyLifetime >= 30) {	// by this design, all tanks should ping-pong to the rushers.

				if (MyLifetime >= 90) {

					DeleteMeFromExistence(client);
				}
				else SetSpeedMultiplierBase(client, 2.0);

				// The tank is not near any players.
				/*new bool:IsTankPlayerFound = false;
				decl String:ClassRoles[64];
				for (new i = 1; i <= MaxClients; i++) {

					if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
					//if (SurvivorRushingMultiplier(i, true) != -2.0) continue;
					GetMenuOfTalent(i, ActiveClass[i], ClassRoles, sizeof(ClassRoles));
					if (StrContains(ClassRoles, "Tank") == -1) continue;

					IsTankPlayerFound = true;

					GetClientAbsOrigin(i, DeathLocation[i]);
					TeleportEntity(client, DeathLocation[i], NULL_VECTOR, NULL_VECTOR);
					break;
				}
				if (!IsTankPlayerFound) ForcePlayerSuicide(client);*/	// the tank is no-where near the survivors, so now it dies. but only if it has been alive for x amount of time (static for now)
			}
			//CheckTankSubroutine(client);
			/*if (IsSpecialCommonInRange(client, 'w') || IsClientInRangeSpecialAmmo(client, "W") == -2.0) {

				//ChangeTankState(client, "hulk", true);
				ChangeTankState(client, "death");
			}*/
			//else ChangeTankState(client, "death", true);
		}

		if (GetClientTeam(client) == TEAM_SURVIVOR) {

			CheckIfItemPickup(client);
			//CheckBombs(client);
			if (IsFakeClient(client) && IsSurvivorBot(client) && !bIsInCheckpoint[client]) {

				if (SurvivorsSaferoomWaiting() || !SurvivorsInRange(client, 1536.0, true)) SurvivorBotsRegroup(client);
			}
		}

		if (buttons & IN_JUMP) bJumpTime[client] = true;
		else {

			bJumpTime[client] = false;
			JumpTime[client] = 0.0;
		}
		//if ((buttons & IN_RELOAD) && TankRush == 1) ExecCheatCommand(client, "give ammo");

		new MyAttacker = L4D2_GetInfectedAttacker(client);
		if (!IsLegitimateClientAlive(MyAttacker)) StrugglePower[client] = 0;

		// no freebie saves
		/*if (IsLegitimateClientAlive(MyAttacker) && ((buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT)) && CheckActiveAbility(client, 19, _, true) == 1.0) {

			// player has knife, they're ensnared, and they are struggling.
			StrugglePower[client]++;
			new MyStruggle = GetRandomInt(1, 100);
			if (MyStruggle <= StrugglePower[client]) {

				StrugglePower[client] = 0;
				L4D_StaggerPlayer(MyAttacker, client, NULL_VECTOR);
				L4D_StaggerPlayer(client, client, NULL_VECTOR);
			}
		}*/

		/*if (GetClientTeam(client) == TEAM_SURVIVOR && GetEntProp(client, Prop_Send, "m_isFallingFromLedge") == 1) {

			SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
		}*/
		/*if (GetClientTeam(client) == TEAM_SURVIVOR && IsLedged(client)) {

			SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		}*/

		new bool:EnrageActivity = IsEnrageActive();

		if (CombatTime[client] <= TheTime && bIsInCombat[client] && !EnrageActivity && !b_IsFinaleActive) {

			bIsInCombat[client] = false;
			iThreatLevel[client] = 0;
			LastAttackTime[client] = 0.0;
			if (!IsSurvivalMode) AwardExperience(client);
		}
		else if (CombatTime[client] > TheTime || EnrageActivity || b_IsFinaleActive) {

			bIsInCombat[client] = true;
			if (!bIsHandicapLocked[client]) bIsHandicapLocked[client] = true;
		}
		//if (GetClientTeam(client) == TEAM_INFECTED) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) {

			if (IsSurvivorBot(client)) MovementSpeed[client] = 1.0;
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
		}

		if (ISDAZED[client] > TheTime) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") * fDazedDebuffEffect);
		else if (ISDAZED[client] <= TheTime && ISDAZED[client] != 0.0) {

			BlindPlayer(client, _, 0);	// wipe the dazed effect.
			ISDAZED[client] = 0.0;
		}

		if (IsPlayerAlive(client) && (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client))) {

			if (!(GetEntityFlags(client) & FL_ONGROUND) && !b_IsFloating[client]) {

				b_IsFloating[client] = true;
				GetClientAbsOrigin(client, JumpPosition[client][0]);
			}
			if (GetEntityFlags(client) & FL_ONGROUND) {

				if (b_IsFloating[client]) {

					GetClientAbsOrigin(client, JumpPosition[client][1]);
					new Float:Z1 = JumpPosition[client][0][2];
					new Float:Z2 = JumpPosition[client][1][2];

					//if (Z1 > Z2 && Z1 - Z2 >= StringToFloat(GetConfigValue("fall damage critical?"))) IncapacitateOrKill(client, _, _, true);
					if (Z1 > Z2) {

						Z1 -= Z2;
						//IsClientActiveBuff(client, 'Q', Z1);
					}
				}
				b_IsFloating[client] = false;	// in case it was bugged or something (just for safe reason)
			}

			new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

			decl String:EntityName[64];

			Format(EntityName, sizeof(EntityName), "}");
			if (IsValidEntity(CurrentEntity)) GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));

			if (StrContains(EntityName, "chainsaw", false) != -1 && (buttons & IN_RELOAD) && GetEntProp(CurrentEntity, Prop_Data, "m_iClip1") < 30 && HasCommandAccess(client, "z")) {

				//SetEntProp(CurrentEntity, Prop_Data, "m_iClip1", 30);
				buttons &= ~IN_RELOAD;
			}

			if (ActiveProgressBar(client) &&
				CurrentEntity != ProgressEntity[client] ||
				(!(GetEntityFlags(client) & FL_ONGROUND) && !IsIncapacitated(client)) ||
				L4D2_GetInfectedAttacker(client) != -1 ||
				!IsValidEntity(CurrentEntity) && !IsIncapacitated(client) ||
				((StrContains(EntityName, "pain_pills", false) == -1 &&
				StrContains(EntityName, "adrenaline", false) == -1  &&
				StrContains(EntityName, "first_aid", false) == -1 &&
				StrContains(EntityName, "defib", false) == -1) && !IsIncapacitated(client))) {

				CreateProgressBar(client, 0.0, true);
				UseItemTime[client] = 0.0;
				if (GetEntPropEnt(client, Prop_Send, "m_reviveOwner") == client) {

					SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
				}
			}

			if (IsIncapacitated(client) && L4D2_GetInfectedAttacker(client) == -1 || (L4D2_GetInfectedAttacker(client) == -1 && IsValidEntity(CurrentEntity) &&
				(StrContains(EntityName, "pain_pills", false) != -1 ||
				StrContains(EntityName, "adrenaline", false) != -1  ||
				StrContains(EntityName, "first_aid", false) != -1 ||
				StrContains(EntityName, "defib", false) != -1))) {

				//blocks the use of meds on people. will add an option in the menu later for now allowing.
				/*if ((buttons & IN_ATTACK2) && !IsIncapacitated(client)) {

					if (StrContains(EntityName, "first_aid", false) != -1) {

						buttons &= ~IN_ATTACK2;
						return Plugin_Changed;
					}
				}*/
				new reviveOwner = -1;
				if ((!(buttons & IN_ATTACK) && ActiveProgressBar(client) && !IsIncapacitated(client)) || (!(buttons & IN_USE) && ActiveProgressBar(client) && IsIncapacitated(client))) {

					CreateProgressBar(client, 0.0, true);
					UseItemTime[client] = 0.0;
					reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
					if (reviveOwner == client) {

						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
						SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
					}
					/*
					if (IsLegitimateClientAlive(reviveOwner) && GetClientTeam(reviveOwner) == TEAM_SURVIVOR) {

						SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					}*/
				}
				if (((buttons & IN_ATTACK) && !IsIncapacitated(client)) || ((buttons & IN_USE) && IsIncapacitated(client))) {

					if (!IsIncapacitated(client)) buttons &= ~IN_ATTACK;
					else buttons &= ~IN_USE;

					if (UseItemTime[client] < TheTime) {

						if (ActiveProgressBar(client)) {

							UseItemTime[client] = 0.0;
							CreateProgressBar(client, 0.0, true);
							if (!IsIncapacitated(client)) {

								if (StrContains(EntityName, "pain_pills", false) != -1) {

									HealPlayer(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), 'h', true);//SetTempHealth(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), false);		// pills add 10% of your total health in temporary health.
									AcceptEntityInput(CurrentEntity, "Kill");
								}
								else if (StrContains(EntityName, "adrenaline", false) != -1) {

									SetAdrenalineState(client);
									new StaminaBonus = RoundToCeil(GetPlayerStamina(client) * 0.25);
									if (SurvivorStamina[client] + StaminaBonus >= GetPlayerStamina(client)) {

										SurvivorStamina[client] = GetPlayerStamina(client);
										bIsSurvivorFatigue[client] = false;
									}
									else SurvivorStamina[client] += StaminaBonus;
									AcceptEntityInput(CurrentEntity, "Kill");
								}
								else if (StrContains(EntityName, "defib", false) != -1) {

									Defibrillator(client);
									if (StrContains(ActiveClass[client], "healer", false) == -1) AcceptEntityInput(CurrentEntity, "Kill");
								}
								else if (StrContains(EntityName, "first_aid", false) != -1) {

									GiveMaximumHealth(client);
									RefreshSurvivor(client);
									if (StrContains(ActiveClass[client], "healer", false) == -1) AcceptEntityInput(CurrentEntity, "Kill");
								}
								/*else if (IsIncapacitated(client)) {// && !IsLedged(client)) {

									//if (bAutoRevive[client]) bAutoRevive[client] = false;

									ReviveDownedSurvivor(client);
									OnPlayerRevived(client, client);
									reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
									if (IsLegitimateClientAlive(reviveOwner)) SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
									SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
								}*/
							}
							else {

								ReviveDownedSurvivor(client);
								OnPlayerRevived(client, client);
								reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
								if (IsLegitimateClientAlive(reviveOwner)) SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
								SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
							}
						}
						else {

							if (IsIncapacitated(client) && UseItemTime[client] < TheTime) {

								//if (!IsLedged(client)) {

								reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
								if (!IsLegitimateClientAlive(reviveOwner)) {

									SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
									ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
									CreateProgressBar(client, 5.0);	// you can pick yourself up for free but it takes a bit.
								}
								//}
							}
							if (StrContains(EntityName, "pain_pills", false) != -1 && UseItemTime[client] < TheTime && !IsIncapacitated(client)) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 2.0);
								//UseItemTime[client] = TheTime + 2;
							}
							else if (StrContains(EntityName, "adrenaline", false) != -1 && UseItemTime[client] < TheTime && !IsIncapacitated(client)) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 1.0);
								//UseItemTime[client] = TheTime + 1;
							}
							else if (StrContains(EntityName, "first_aid", false) != -1 && UseItemTime[client] < TheTime) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 5.0);
								//UseItemTime[client] = TheTime + 5;
							}
							else if (!IsIncapacitated(client) && (StrContains(EntityName, "defib", false) != -1 || StrContains(EntityName, "first_aid", false) != -1) && UseItemTime[client] < TheTime) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 5.0);
								//UseItemTime[client] = TheTime + 10;
							}
							if (ActiveProgressBar(client)) SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
						}
					}
					return Plugin_Changed;
				}
			}
			// For drawing special ammo.
			if (bIsSurvivorFatigue[client]) {

				IsSpecialAmmoEnabled[client][0] = 0.0;
				Format(ActiveSpecialAmmo[client], sizeof(ActiveSpecialAmmo[]), "none");
			}
			/*if (IsSpecialAmmoEnabled[client][2] <= TheTime || GetClientAimTarget(client, false) != IsSpecialAmmoEnabled[client][3] * 1.0) {

				if (IsSpecialAmmoEnabled[client][0] == 1.0 && DrawSpecialAmmoTarget(client) == 0 && IsPlayerDebugMode[client] == 1) DrawSpecialAmmoTarget(client, true);
				IsSpecialAmmoEnabled[client][2] = TheTime + fAmmoHighlightTime;
			} deprecated */

			if (!IsFakeClient(client)) {

				//new ConsumptionInt = iStamConsumptionInt;

				if ((ReadyUp_GetGameMode() != 3 || !b_IsSurvivalIntermission) && iRPGMode >= 1) {

					new bool:IsJetpackBroken = ISBILED[client];
					if (!IsJetpackBroken && StrContains(ActiveClass[client], "spacex", false) == -1) IsJetpackBroken = AnyTanksNearby(client);

					if (bJetpack[client] && (!(buttons & IN_JUMP) || IsJetpackBroken || L4D2_GetInfectedAttacker(client) != -1)) ToggleJetpack(client, true);
					//else if (!(GetEntityFlags(client) & FL_ONGROUND) && !bIsSurvivorFatigue[client] && !bJetpack[client] && (buttons & IN_JUMP)) ToggleJetpack(client);

					if ((bJetpack[client] || !bJetpack[client] && !(GetEntityFlags(client) & FL_ONGROUND)) ||
						((buttons & IN_JUMP) || ((buttons & IN_SPEED) && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT))) &&
						SurvivorStamina[client] >= ConsumptionInt && !bIsSurvivorFatigue[client] && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {

						if (L4D2_GetInfectedAttacker(client) == -1 && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {

							if (SurvivorConsumptionTime[client] <= TheTime && (buttons & IN_JUMP || buttons & IN_SPEED)) {

								if (StrContains(ActiveClass[client], "scout", false) == -1) SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval;
								else SurvivorConsumptionTime[client] = TheTime + fScoutBonus;
								SurvivorStamina[client] -= ConsumptionInt;
								AddTalentExperience(client, "endurance", ConsumptionInt);
								if (!(GetEntityFlags(client) & FL_ONGROUND) && StrContains(ActiveClass[client], "spacex", false) != -1) {

									SurvivorStamina[client] -= ConsumptionInt;
									AddTalentExperience(client, "endurance", ConsumptionInt);
								}
								if (SurvivorStamina[client] <= 0) {

									bIsSurvivorFatigue[client] = true;
									IsSpecialAmmoEnabled[client][0] = 0.0;
									SurvivorStamina[client] = 0;
									if (bJetpack[client]) ToggleJetpack(client, true);
								}
							}
							if (!bIsSurvivorFatigue[client] && !bJetpack[client] && ((buttons & IN_JUMP) && (JumpTime[client] >= 0.2)) && !IsJetpackBroken && JetpackRecoveryTime[client] <= GetEngineTime() && L4D2_GetInfectedAttacker(client) == -1) ToggleJetpack(client);
							if (!bJetpack[client]) MovementSpeed[client] = fSprintSpeed;
						}
						buttons &= ~IN_SPEED;
						return Plugin_Changed;
					}
					if (!(buttons & IN_SPEED) && !bJetpack[client]) {

						new PlayerMaxStamina = GetPlayerStamina(client);

						if (SurvivorStaminaTime[client] < TheTime && SurvivorStamina[client] < PlayerMaxStamina) {

							if (!HasAdrenaline(client)) SurvivorStaminaTime[client] = TheTime + fStamRegenTime;
							else SurvivorStaminaTime[client] = TheTime + fStamRegenTimeAdren;
							SurvivorStamina[client]++;
						}
						//if (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") != StringToFloat(GetConfigValue("base movement speed?"))) {

						if (!bIsSurvivorFatigue[client]) MovementSpeed[client] = fBaseMovementSpeed;
						else MovementSpeed[client] = fFatigueMovementSpeed;
						if (ISSLOW[client] != INVALID_HANDLE) MovementSpeed[client] *= fSlowSpeed[client];
						//}
						if (SurvivorStamina[client] >= PlayerMaxStamina) {

							bIsSurvivorFatigue[client] = false;
							SurvivorStamina[client] = PlayerMaxStamina;
						}
					}
				}
			}

			/*if (buttons & IN_JUMP) {

				if (L4D2_GetInfectedAttacker(client) == -1 && L4D2_GetSurvivorVictim(client) == -1 && (GetEntityFlags(client) & FL_ONGROUND)) {

					GetAbilityStrengthByTrigger(client, 0, 'j', FindZombieClass(client), 0);
				}
				if (L4D2_GetSurvivorVictim(client) != -1) {

					new victim = L4D2_GetSurvivorVictim(client);
					if ((GetEntityFlags(victim) & FL_ONGROUND)) GetAbilityStrengthByTrigger(client, victim, 'J', FindZombieClass(client), 0);
				}
			}
			else if (!(buttons & IN_JUMP) && b_IsJumping[client]) ModifyGravity(client);*/
		}
	}
	return Plugin_Continue;
}

stock ToggleJetpack(client, DisableJetpack = false) {

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	if (!DisableJetpack && !bJetpack[client]) {

		EmitSoundToAll(JETPACK_AUDIO, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, ClientPos, NULL_VECTOR, true, 0.0);
		SetEntityMoveType(client, MOVETYPE_FLY);
		bJetpack[client] = true;
	}
	else if (DisableJetpack && bJetpack[client]) {

		StopSound(client, SNDCHAN_WEAPON, JETPACK_AUDIO);
		//EmitSoundToAll(JETPACK_AUDIO, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, ClientPos, NULL_VECTOR, true, 0.0);
		SetEntityMoveType(client, MOVETYPE_WALK);
		bJetpack[client] = false;
	}
}

stock bool:IsEveryoneBoosterTime() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR && !HasBoosterTime(i)) return false;
	}
	return true;
}

stock bool:IsHealerClass(client) {

	if (StrContains(ActiveClass[client], "healer", false) != -1 ||
		StrContains(ActiveClass[client], "paladin", false) != -1 ||
		StrContains(ActiveClass[client], "priest", false) != -1 ||
		StrContains(ActiveClass[client], "shaman", false) != -1) return true;
	return false;
}

stock CreateDamageStatusEffect(client, type = 0, target = 0, damage = 0, owner = 0, Float:RangeOverride = 0.0) {

	if (!IsSpecialCommon(client)) return;
	new Float:AfxRange = GetCommonValueFloat(client, "range player level?");
	new Float:AfxStrengthLevel = GetCommonValueFloat(client, "level strength?");
	new Float:AfxRangeMax = GetCommonValueFloat(client, "range max?");
	new AfxMultiplication = GetCommonValueInt(client, "enemy multiplication?");
	new AfxStrength = GetCommonValueInt(client, "aura strength?");
	new Float:AfxStrengthTarget = GetCommonValueFloat(client, "strength target?");
	new Float:AfxRangeBase = GetCommonValueFloat(client, "range minimum?");
	new Float:OnFireBase = GetCommonValueFloat(client, "onfire base time?");
	new Float:OnFireLevel = GetCommonValueFloat(client, "onfire level?");
	new Float:OnFireMax = GetCommonValueFloat(client, "onfire max time?");
	new Float:OnFireInterval = GetCommonValueFloat(client, "onfire interval?");
	new AfxLevelReq = GetCommonValueInt(client, "level required?");

	new Float:ClientPosition[3];
	new Float:TargetPosition[3];

	new t_Strength = 0;
	new Float:t_Range = 0.0;
	//new ent = -1;

	new Float:t_OnFireRange = 0.0;

	if (damage > 0) AfxStrength = damage;	// if we want to base the damage on a specific value, we can override here.

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPosition);
	new NumLivingEntities = LivingEntitiesInRange(client, ClientPosition, AfxRangeMax);
	if (NumLivingEntities > 1) damage = (damage / NumLivingEntities);
	if (target == 0 || IsLegitimateClient(target)) {

		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i) || (target != 0 && i != target) || PlayerLevel[i] < AfxLevelReq) continue;		// if type is 1 and target is 0 acid is spread to all players nearby. but if target is not 0 it is spread to only the player the acid zombie hits. or whatever type uses it.
			GetClientAbsOrigin(i, TargetPosition);

			if (RangeOverride == 0.0) {

				if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
				else t_Range = AfxRangeMax;
				if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
				else t_Range += AfxRangeBase;
			}
			else t_Range = RangeOverride;
			if (GetVectorDistance(ClientPosition, TargetPosition) > (t_Range / 2)) continue;

			if (AfxMultiplication == 1) {

				if (AfxStrengthTarget < 0.0) t_Strength = AfxStrength * NumLivingEntities;
				else t_Strength = RoundToCeil(AfxStrength * (NumLivingEntities * AfxStrengthTarget));
			}
			else t_Strength = AfxStrength;
			if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * ((PlayerLevel[i] - AfxLevelReq) * AfxStrengthLevel));

			t_OnFireRange = OnFireLevel * (PlayerLevel[i] - AfxLevelReq);
			t_OnFireRange += OnFireBase;
			if (t_OnFireRange > OnFireMax) t_OnFireRange = OnFireMax;

			if (IsSpecialCommonInRange(client, 'b')) {

				t_Strength = GetSpecialCommonDamage(t_Strength, client, 'b', i);
			}

			//PrintToChatAll("Setting %N on fire for %d damage over %3.2f seconds", i, t_Strength, t_OnFireRange);
			if (type == 0) CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval, _, "burn");		// Static time for now.
			else if (type == 4) {

				CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval, _, "acid");
				break;	// to prevent buffer overflow only allow it on one client.
			}
		}
	}
	if (target == 0 || IsCommonInfected(target)) {

		new ent = -1;
		for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

			ent = GetArrayCell(Handle:CommonInfected, i);
			if (IsCommonInfected(ent)) {

				if (ent != client) {

					if (target == 0 || ent == target) {

						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
						if (GetVectorDistance(ClientPosition, TargetPosition) <= (AfxRangeMax / 2)) {

							if (!IsSpecialCommon(ent)) OnCommonInfectedCreated(ent, true, _, true); // will calculate xp rewards, unhook, and set on fire.
							else if (IsLegitimateClient(owner) && (GetClientTeam(owner) == TEAM_SURVIVOR || IsSurvivorBot(owner)) && IsSpecialCommon(ent)) AddSpecialCommonDamage(owner, ent, damage);
						}
					}
				}
			}
		}
	}
	//ClearSpecialCommon(client);
}

stock ExplosiveAmmo(client, damage, TalentClient) {

	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsCommonInfected(client)) AddCommonInfectedDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(client, damage);	// survivor teammates don't reward players with experience or damage bonus, but they'll take damage from it.
	}
	if (client != TalentClient && (!IsCommonInfected(client) || IsSpecialCommon(client)) && (IsLegitimateClientAlive(client) && GetClientTeam(client) != TEAM_SURVIVOR)) {

		//new CartXP = RoundToCeil(GetClassMultiplier(TalentClient, damage * 1.0, "agX", true));
		AddTalentExperience(TalentClient, "agility", damage);
	} 
}

stock HealingAmmo(client, healing, TalentClient, bool:IsCritical=false) {

	if (!IsLegitimateClientAlive(client) || !IsLegitimateClientAlive(TalentClient)) return;
	
	//healing = 
	HealPlayer(client, TalentClient, healing * 1.0, 'h', true);
	//if (client != TalentClient) {

	//if (healing > 0) {	// this prevents a player for receiving cartel on over-heals.

		//new CartXP = RoundToCeil(GetClassMultiplier(TalentClient, healing * 1.0, "enX", true));
		//AddTalentExperience(TalentClient, "endurance", CartXP);
	//}
	//}
	//SetTempHealth(TalentClient, client, healing * 1.0, false);
}

stock LeechAmmo(client, damage, TalentClient) {

	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsCommonInfected(client)) AddCommonInfectedDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(client, damage);
	}
	if (IsLegitimateClientAlive(TalentClient) && (GetClientTeam(TalentClient) == TEAM_SURVIVOR || IsSurvivorBot(TalentClient))) {

		//if (IsCritical || !IsCriticalHit(client, healing, TalentClient))	// maybe add this to leech? that would be cool.!
		HealPlayer(TalentClient, TalentClient, damage * 1.0, 'h', true);
	}
}

stock Float:CreateBomberExplosion(client, target, String:Effects[], basedamage = 0) {

	//if (IsLegitimateClient(target) && !IsPlayerAlive(target)) return;
	if (!IsCommonInfected(target) && !IsLegitimateClientAlive(target)) return;

	/*

		When a bomber dies, it explodes.
	*/
	new Float:AfxRange = GetCommonValueFloat(client, "range player level?");
	new Float:AfxStrengthLevel = GetCommonValueFloat(client, "level strength?");
	new Float:AfxRangeMax = GetCommonValueFloat(client, "range max?");
	new AfxMultiplication = GetCommonValueInt(client, "enemy multiplication?");
	new AfxStrength = GetCommonValueInt(client, "aura strength?");
	new AfxChain = GetCommonValueInt(client, "chain reaction?");
	new Float:AfxStrengthTarget = GetCommonValueFloat(client, "strength target?");
	new Float:AfxRangeBase = GetCommonValueFloat(client, "range minimum?");
	new AfxLevelReq = GetCommonValueInt(client, "level required?");


	if (IsSpecialCommon(client) && IsLegitimateClient(target) && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) && PlayerLevel[target] < AfxLevelReq) return;

	new Float:SourcLoc[3];
	new Float:TargetPosition[3];
	new t_Strength = 0;
	new Float:t_Range = 0.0;
	new ent = -1;

	if (target > 0) {

		if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, SourcLoc);
		else if (IsCommonInfected(target) || IsWitch(target)) GetEntPropVector(target, Prop_Send, "m_vecOrigin", SourcLoc);
		new NumLivingEntities = LivingEntitiesInRange(client, SourcLoc, AfxRangeMax);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", TargetPosition);

		if (AfxRange > 0.0 && IsLegitimateClientAlive(target)) t_Range = AfxRange * (PlayerLevel[target] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		if (IsLegitimateClientAlive(target) && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) && target != client) {

			if (PlayerLevel[target] < AfxLevelReq) return;
			if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2)) return;
		}

		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i) || PlayerLevel[i] < AfxLevelReq) continue;
			GetClientAbsOrigin(i, TargetPosition);

			if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
			else t_Range = AfxRangeMax;
			if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
			else t_Range += AfxRangeBase;
			if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2) || StrContains(GetStatusEffects(i), "[Fl]", false) != -1) continue;		// player not within blast radius, takes no damage. Or playing is floating.

			// Because range can fluctuate, we want to get the # of entities within range for EACH player individually.
			if (AfxMultiplication == 1) {

				if (AfxStrengthTarget < 0.0) t_Strength = basedamage + (AfxStrength * NumLivingEntities);
				else t_Strength = RoundToCeil(basedamage + (AfxStrength * (NumLivingEntities * AfxStrengthTarget)));
			}
			else t_Strength = (basedamage + AfxStrength);
			if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * ((PlayerLevel[i] - AfxLevelReq) * AfxStrengthLevel));

			//if (t_Strength > GetClientHealth(i)) IncapacitateOrKill(i);
			//else SetEntityHealth(i, GetClientHealth(i) - t_Strength);
			if (t_Strength > 0.0) SetClientTotalHealth(i, t_Strength);

			if (client == target) {

				// To prevent a never-ending chain reaction, we don't allow it to target the bomber that caused it.

				if ((GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && AfxChain == 1) CreateBomberExplosion(client, i, Effects);
			}
		}
		if (StrContains(Effects, "e", true) != -1) {

			CreateExplosion(target);	// boom boom audio and effect on the location.
			if (IsLegitimateClientAlive(target) && !IsFakeClient(target)) ScreenShake(target);
		}
		if (StrContains(Effects, "B", true) != -1) {

			if (IsLegitimateClientAlive(target)) {

				SDKCall(g_hCallVomitOnPlayer, target, client, true);
				//L4D_StaggerPlayer(target, client, NULL_VECTOR);
			}
		}
		if (StrContains(Effects, "a", true) != -1) {

			CreateDamageStatusEffect(client, 4, target, t_Strength);
		}

		ent = -1;
		if (client == target) CreateBomberExplosion(client, 0, Effects);
		/*if (client == target) {

			for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

				ent = GetArrayCell(Handle:CommonInfected, i);
				if (IsCommonInfected(ent)) {

					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
					if (GetVectorDistance(SourcLoc, TargetPosition) <= (t_Range / 2)) {

						CreateBomberExplosion(client, ent, Effects);
					}
				}
			}
			CreateBomberExplosion(client, 0, Effects);
		}*/
	}
	else {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", SourcLoc);

		/*

			The bomber target is 0, so we eliminate any common infected within range.
			Don't worry - this function will have called and executed for all players in range before it gets here
			thanks to the magic of single-threaded language.
		*/
		ent = -1;
		for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

			ent = GetArrayCell(Handle:CommonInfected, i);

			if (IsCommonInfected(ent)) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
				if (GetVectorDistance(SourcLoc, TargetPosition) <= (AfxRangeMax / 2)) {

					//AcceptEntityInput(ent, "Kill");
					
					//ent = FindListPositionByEntity(ent, Handle:CommonInfected);
					//if (ent >= 0) RemoveFromArray(Handle:CommonInfected, ent);
					//CalculateInfectedDamageAward(ent);
					if (StrContains(Effects, "e", true) != -1 && !IsSpecialCommon(ent)) {

						OnCommonInfectedCreated(ent, true);
						if (i > 0) i--;
					}
					//if (StrContains(Effects, "B", true) != -1) SDKCall(g_hCallVomitOnPlayer, ent, client, true);
				}
			}
		}
	}
}

stock CheckMinimumRate(client) {

	if (Rating[client] < 1) Rating[client] = 1;
}

stock CalculateInfectedDamageAward(client, killerblow = 0) {

	new ClientType = -1;
	if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_INFECTED && !IsSurvivorBot(client)) {

		ClientType = 0;
		if (FindZombieClass(client) != ZOMBIECLASS_TANK) SetArrayCell(Handle:RoundStatistics, 3, GetArrayCell(RoundStatistics, 3) + 1);
		else SetArrayCell(Handle:RoundStatistics, 4, GetArrayCell(RoundStatistics, 4) + 1);
	}
	else if (IsWitch(client)) {

		ClientType = 1;
		SetArrayCell(Handle:RoundStatistics, 2, GetArrayCell(RoundStatistics, 2) + 1);
	}
	else if (IsSpecialCommon(client)) {

		ClientType = 2;
		SetArrayCell(Handle:RoundStatistics, 1, GetArrayCell(RoundStatistics, 1) + 1);
	}
	else if (IsCommonInfected(client)) {

		ClientType = 3;
		SetArrayCell(Handle:RoundStatistics, 0, GetArrayCell(RoundStatistics, 0) + 1);
	}

	CreateItemRoll(client, killerblow);	// all infected types can generate an item roll

	new Float:SurvivorPoints = 0.0;
	new SurvivorExperience = 0;
	new Float:PointsMultiplier = fPointsMultiplier;
	new Float:ExperienceMultiplier = SurvivorExperienceMult;
	new Float:TankingMultiplier = SurvivorExperienceMultTank;
	new Float:HealingMultiplier = SurvivorExperienceMultHeal;
	new Float:RatingReductionMult = 0.0;
	new t_Contribution = 0;
	new h_Contribution = 0;
	new SurvivorDamage = 0;

	new Float:TheAbilityMultiplier = 0.0;

	if (IsLegitimateClientAlive(killerblow) && ClientType == 0 && (GetClientTeam(killerblow) == TEAM_SURVIVOR || IsSurvivorBot(killerblow))) {

		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, 'I');
		if (TheAbilityMultiplier > 0.0) { // heal because you dealt the killing blow

			HealPlayer(killerblow, killerblow, TheAbilityMultiplier * GetMaximumHealth(killerblow), 'h', true);
		}
		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, 'l');
		if (TheAbilityMultiplier > 0.0) {

			// Creates fire on the target and deals AOE explosion.
			CreateExplosion(client, RoundToCeil(DataScreenWeaponDamage(killerblow) * TheAbilityMultiplier), killerblow, true);
			CreateFireEx(client);
		}
	}
	//new owner = 0;
	//if (IsLegitimateClientAlive(commonkiller) && GetClientTeam(commonkiller) == TEAM_SURVIVOR) owner = commonkiller;
	if (ClientType == 0) SpecialsKilled++;
	new Float:i_DamageContribution = 0.0000;
	new Float:DamageContributionRequirement = (1.0 / LivingSurvivorCount());
	//LogMessage("Damage comtribution requirement: %3.3f", DamageContributionRequirement);
	if (DamageContributionRequirement > fDamageContribution) {

		DamageContributionRequirement = fDamageContribution;
	}

	// If it's a special common, we activate its death abilities.
	if (ClientType == 2) {

		decl String:TheEffect[10];
		GetCommonValue(TheEffect, sizeof(TheEffect), client, "aura effect?");
		CreateBomberExplosion(client, client, TheEffect);	// bomber aoe
	}

	new pos = -1;
	new RatingBonus = 0;
	new RatingTeamBonus = 0;
	new iLivingSurvivors = LivingSurvivors() - 1;
	//decl String:MyName[64];
	for (new i = 1; i <= MaxClients; i++) {

		RatingBonus = 0;
		SurvivorExperience = 0;
		SurvivorPoints = 0.0;
		i_DamageContribution = 0.0000;

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;

		if (ClientType == 0) pos = FindListPositionByEntity(client, Handle:InfectedHealth[i]);
		else if (ClientType == 1) pos = FindListPositionByEntity(client, Handle:WitchDamage[i]);
		else if (ClientType == 2) pos = FindListPositionByEntity(client, Handle:SpecialCommon[i]);
		else if (ClientType == 3) pos = FindListPositionByEntity(client, Handle:CommonInfectedDamage[i]);

		if (pos < 0) continue;

		if (LastAttackedUser[i] == client) LastAttackedUser[i] = -1;

		if (ClientType == 0) SurvivorDamage = GetArrayCell(Handle:InfectedHealth[i], pos, 2);
		else if (ClientType == 1) SurvivorDamage = GetArrayCell(Handle:WitchDamage[i], pos, 2);
		else if (ClientType == 2) SurvivorDamage = GetArrayCell(Handle:SpecialCommon[i], pos, 2);
		else if (ClientType == 3) SurvivorDamage = GetArrayCell(Handle:CommonInfectedDamage[i], pos, 2);

		RatingBonus = GetRatingReward(i, client);

		if (RatingBonus > 0) {

			if (!IsFakeClient(i) && (IsSpecialCommon(client) || !IsCommonInfected(client))) {

				if (iLivingSurvivors < 1) PrintToChat(i, "%T", "rating increase", i, white, blue, AddCommasToString(RatingBonus), orange);
				else {

					RatingTeamBonus = RoundToCeil(RatingBonus * (iLivingSurvivors * fTeamRatingBonus));
					Rating[i] += RatingTeamBonus;
					PrintToChat(i, "%T", "team rating increase", i, white, blue, AddCommasToString(RatingBonus), orange, white, green, blue, AddCommasToString(RatingTeamBonus), orange, white);
				}
			}
			CheckMinimumRate(i);
			Rating[i] += RatingBonus;
			RefuelAmmo(i);

			TheAbilityMultiplier = GetAbilityMultiplier(i, 'R');
			if (TheAbilityMultiplier > 0.0) { // heal because you dealt the killing blow

				HealPlayer(i, i, TheAbilityMultiplier * RatingBonus, 'h', true);
			}
		}

		if (SurvivorDamage > 0) {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}

		i_DamageContribution = CheckTeammateDamages(client, i, true);

		if (i_DamageContribution > 0.0) {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}

		t_Contribution = CheckTankingDamage(client, i);
		if (t_Contribution > 0) {

			/*RatingReductionMult = GetClassMultiplier(i, -1.0, "D");
			if (RatingReductionMult == -1.0) RatingReductionMult = 1.0;

			if (IsLegitimateClient(client)) t_Contribution = RoundToCeil(t_Contribution * RatingReductionMult);
			*/
			t_Contribution = RoundToCeil(t_Contribution * TankingMultiplier);
			SurvivorPoints += (t_Contribution * (PointsMultiplier * TankingMultiplier));
		}
		//h_Contribution = HealingContribution[i];
		//HealingContribution[i] = 0;
		//CreateLootItem(i, i_DamageContribution, CheckTankingDamage(client, i), RoundToCeil(h_Contribution * HealingMultiplier));
		if (h_Contribution > 0) {

			h_Contribution = RoundToCeil(h_Contribution * HealingMultiplier);
			SurvivorPoints += (h_Contribution * (PointsMultiplier * HealingMultiplier));
		}
		//if (!bIsInCombat[i]) ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution, Bu_Contribution, He_Contribution);
		
		
		HealingContribution[i] += h_Contribution;
		TankingContribution[i] += t_Contribution;
		PointsContribution[i] += SurvivorPoints;
		DamageContribution[i] += SurvivorExperience;
		
		if (ClientType == 0) RemoveFromArray(Handle:InfectedHealth[i], pos);
		else if (ClientType == 1) RemoveFromArray(Handle:WitchDamage[i], pos);
		else if (ClientType == 2) RemoveFromArray(Handle:SpecialCommon[i], pos);
		else if (ClientType == 3) RemoveFromArray(Handle:CommonInfectedDamage[i], pos);
	}
	if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED && !IsSurvivorBot(client)) {

		if (FindZombieClass(client) == ZOMBIECLASS_TANK) bIsDefenderTank[client] = false;

		if (iTankRush != 1 && FindZombieClass(client) == ZOMBIECLASS_TANK && DirectorTankCooldown > 0.0 && f_TankCooldown == -1.0) {

			f_TankCooldown				=	DirectorTankCooldown;

			CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		ClearArray(TankState_Array[client]);
		MyBirthday[client] = 0;
		CreateMyHealthPool(client, true);
		ChangeHook(client);
		//IsCoveredInVomit(client, _, true);
		ISBILED[client] = false;
		ForcePlayerSuicide(client);

		if (b_IsFinaleActive && GetInfectedCount(ZOMBIECLASS_TANK) < 1) {

			b_IsFinaleTanks = true;	// next time the event tank spawns, it will allow it to spawn multiple tanks.
		}
	}
}

stock ReceiveInfectedDamageAward(client, infected, e_reward, Float:p_reward, t_reward, h_reward , bu_reward, he_reward, bool:TheRoundHasEnded = false) {

	new RPGMode									= iRPGMode;

	if (RPGMode < 0) return;
	//new RPGBroadcast							= StringToInt(GetConfigValue("award broadcast?"));
	decl String:InfectedName[64];
	//decl String:InfectedTeam[64];

	if (infected > 0) {

		if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) GetClientName(infected, InfectedName, sizeof(InfectedName));
		else if (IsWitch(infected)) Format(InfectedName, sizeof(InfectedName), "Witch");
		else if (IsSpecialCommon(infected)) GetCommonValue(InfectedName, sizeof(InfectedName), infected, "name?");
		else if (IsCommonInfected(infected)) Format(InfectedName, sizeof(InfectedName), "Common");
		Format(InfectedName, sizeof(InfectedName), "%s %s", sDirectorTeam, InfectedName);
	}

	new Float:fRoundMultiplier = 1.0;
	if (RoundExperienceMultiplier[client] > 0.0) {

		fRoundMultiplier += RoundExperienceMultiplier[client];
		e_reward = RoundToCeil(e_reward * fRoundMultiplier);
		h_reward += RoundToCeil(h_reward * fRoundMultiplier);
		t_reward += RoundToCeil(t_reward * fRoundMultiplier);
		bu_reward += RoundToCeil(bu_reward * fRoundMultiplier);
		he_reward += RoundToCeil(he_reward * fRoundMultiplier);
	}

	new RestedAwardBonus = RoundToFloor(e_reward * fRestedExpMult);
	if (RestedAwardBonus >= RestedExperience[client]) {

		RestedAwardBonus = RestedExperience[client];
		RestedExperience[client] = 0;
	}
	else if (RestedAwardBonus < RestedExperience[client]) {

		RestedExperience[client] -= RestedAwardBonus;
	}
	new ExperienceBooster = RoundToFloor(e_reward * CheckExperienceBooster(client, e_reward));
	if (ExperienceBooster < 1) ExperienceBooster = 0;

	//new Float:TeammateBonus = 0.0;//(LivingSurvivors() - 1) * fSurvivorExpMult;
	new theCount = LivingSurvivorCount();
	if (theCount >= iSurvivorModifierRequired) {

		new Float:TeammateBonus = (theCount - (iSurvivorModifierRequired - 1)) * fSurvivorExpMult;
	
		e_reward += RoundToCeil(TeammateBonus * e_reward);
		h_reward += RoundToCeil(TeammateBonus * h_reward);
		t_reward += RoundToCeil(TeammateBonus * t_reward);
		bu_reward += RoundToCeil(TeammateBonus * bu_reward);
		he_reward += RoundToCeil(TeammateBonus * he_reward);
	}

	if (IsGroupMember[client]) {

		e_reward += RoundToCeil(GroupMemberBonus * e_reward);
		h_reward += RoundToCeil(GroupMemberBonus * h_reward);
		t_reward += RoundToCeil(GroupMemberBonus * t_reward);
		bu_reward += RoundToCeil(GroupMemberBonus * bu_reward);
		he_reward += RoundToCeil(GroupMemberBonus * he_reward);
	}

	if (e_reward < 1) e_reward = 0;
	if (h_reward < 1) h_reward = 0;
	if (t_reward < 1) t_reward = 0;
	if (bu_reward < 1) bu_reward = 0;
	if (he_reward < 1) he_reward = 0;

	h_reward = RoundToCeil(GetClassMultiplier(client, h_reward * 1.0, "hXP"));
	t_reward = RoundToCeil(GetClassMultiplier(client, t_reward * 1.0, "tXP"));

	//if (!TheRoundHasEnded) {
	// Previously, if a player completed a round without ever leaving combat, they would receive no bonus container.

	if (iIsLevelingPaused[client] == 0) {
		// players who pause their levels don't earn bonus containers.

		BonusContainer[client]	+= e_reward;
		BonusContainer[client]	+= h_reward;
		BonusContainer[client]	+= t_reward;
		BonusContainer[client]	+= bu_reward;
		BonusContainer[client]	+= he_reward;
	}
	else BonusContainer[client] = 0;	// if the player enables it mid-match, this ensures the bonus container is always 0 for paused levelers.
	//}

	
	//	0 = Points Only
	//	1 = RPG Only
	//	2 - RPG + Points
	
	if (RPGMode > 0) {

		if (DisplayType > 0 && (infected == 0 || (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected)))) {								// \x04Jockey \x01killed: \x04 \x03experience

			if (e_reward > 0 && infected > 0) PrintToChat(client, "%T", "base experience reward", client, orange, InfectedName, white, green, AddCommasToString(e_reward), blue);
			else if (e_reward > 0 && infected == 0) {

				PrintToChat(client, "%T", "damage experience reward", client, orange, green, white, green, AddCommasToString(e_reward), blue);
			}
			if (DisplayType == 2) {

				if (RestedAwardBonus > 0) PrintToChat(client, "%T", "rested experience reward", client, green, white, green, AddCommasToString(RestedAwardBonus), blue);
				if (ExperienceBooster > 0) PrintToChat(client, "%T", "booster experience reward", client, green, white, green, AddCommasToString(ExperienceBooster), blue);
			}
			if (t_reward > 0) PrintToChat(client, "%T", "tanking experience reward", client, green, white, green, AddCommasToString(t_reward), blue);
			if (h_reward > 0) PrintToChat(client, "%T", "healing experience reward", client, green, white, green, AddCommasToString(h_reward), blue);
			if (bu_reward > 0) PrintToChat(client, "%T", "buffing experience reward", client, green, white, green, AddCommasToString(bu_reward), blue);
			if (he_reward > 0) PrintToChat(client, "%T", "hexing experience reward", client, green, white, green, AddCommasToString(he_reward), blue);
		}
		new TotalExperienceEarned = (e_reward + RestedAwardBonus + ExperienceBooster + t_reward + h_reward + bu_reward + he_reward);

 		ExperienceLevel[client] += TotalExperienceEarned;
		ExperienceOverall[client] += TotalExperienceEarned;

		ConfirmExperienceAction(client, TheRoundHasEnded);
	}
	if (RPGMode >= 0 && RPGMode != 1 && p_reward > 0.0) {

		Points[client] += p_reward;

		if (DisplayType > 0 && (infected == 0 || (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected)))) PrintToChat(client, "%T", "points from damage reward", client, green, white, green, p_reward, blue);
	}
	if (!TheRoundHasEnded) CheckKillPositions(client, true);
}

// Curious RPG System option?
// Points earned from hurting players used to unlock abilities, while experienced earned to increase level determines which abilities a player has access to.
// This way, even if the level is different, everyone starts with the same footing.
// Optional RPG System. Maybe call it "buy rpg mode?"

stock bool:SameTeam_OnTakeDamage(healer, target, iHealerAmount, bool:IsDamageTalent = false, damagetype = -1) {

	if (iIsPvpServer == 1) return false;
	if (IsLegitimateClientAlive(target) && IsLegitimateClientAlive(healer) && GetClientTeam(target) == GetClientTeam(healer)) {

		if (!HealImmunity[target]) { // && !IsBeingRevived(target)) {

	 		new bool:TheBool = IsMeleeAttacker(healer);
	 		new Float:HealerAmount = (iHealerAmount * 1.0);
	 		if (!TheBool || !bIsMeleeCooldown[healer]) {

		 		//https://pastebin.com/tLLK9kZM
		 		if (!TheBool) HealerAmount = GetClassMultiplier(healer, HealerAmount, "hB", _, true);
		 		else HealerAmount = GetClassMultiplier(healer, HealerAmount, "hM", _, true);
		 		if ((GetClientTeam(healer) == TEAM_SURVIVOR || IsSurvivorBot(healer)) && HealerAmount > 0.0) {

		 			//HealerAmount *= 0.05;

		 			if (bIsInCombat[target]) {

		 				CombatTime[healer] = GetEngineTime() + fOutOfCombatTime;
		 				bIsInCombat[healer] = true;
		 			}

		 			if (TheBool) {

		 				bIsMeleeCooldown[healer] = true;				
						CreateTimer(0.5, Timer_IsMeleeCooldown, healer, TIMER_FLAG_NO_MAPCHANGE);
		 				//HealerAmount = GetClassMultiplier(attacker, baseWeaponDamage * 1.0, "hM", false, true);
		 			}
		 			HealImmunity[target] = true;
			 		CreateTimer(0.05, Timer_HealImmunity, target, TIMER_FLAG_NO_MAPCHANGE);
			 		HealPlayer(target, healer, HealerAmount, 'h', true);

			 		// To prevent endless loops, we only call damage talents when the function is called directly from OnTakeDamage()
			 		if (!IsDamageTalent) {

			 			GetAbilityStrengthByTrigger(healer, target, 'd', FindZombieClass(healer), RoundToCeil(HealerAmount));
				 		if (damagetype & DMG_CLUB) GetAbilityStrengthByTrigger(healer, target, 'U', FindZombieClass(healer), RoundToCeil(HealerAmount));
				 		if (damagetype & DMG_SLASH) GetAbilityStrengthByTrigger(healer, target, 'u', FindZombieClass(healer), RoundToCeil(HealerAmount));
				 	}

			 		//GetAbilityStrengthByTrigger(attacker, victim, 'd', FindZombieClass(attacker), baseWeaponDamage);
					//GetAbilityStrengthByTrigger(victim, attacker, 'l', FindZombieClass(victim), baseWeaponDamage);

					if (LastAttackedUser[healer] == target) ConsecutiveHits[healer]++;
					else {

						LastAttackedUser[healer] = target;
						ConsecutiveHits[healer] = 0;
					}
					if (!TheBool) RestoreHealBullet(healer);
		 		}
		 	}
		}
	 	return true;
	}
	return false;
}