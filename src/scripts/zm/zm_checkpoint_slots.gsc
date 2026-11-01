// Appended by Build.ps1. Solo slot 1 retains the original format-3 filename.
// Slots 2-4 are separate files; all are consumed independently after Resume.
zmcp_solo_slot( value )
{
    if ( value < 1 || value > 4 )
        return 1;
    return value;
}

zmcp_solo_path( slot )
{
    path = "zm_checkpoint_" + level.zmcp_map;
    if ( slot > 1 )
        path += "_slot" + slot;
    return path + ".sav";
}

// One backup per solo slot: the save that was in the slot before the newest
// Save is copied to <slot file>_backup.sav (zm_checkpoint_<map>_backup.sav for
// slot 1). Only a complete checkpoint is copied. If the new write fails
// validation the previous save is put back; otherwise the backup can be copied
// over the slot file by hand to return to the earlier save.
zmcp_solo_backup_path( slot )
{
    path = zmcp_solo_path( slot );
    return getsubstr( path, 0, path.size - 4 ) + "_backup.sav";
}

// Autosave keeps the save it is about to replace here, so a failed autosave
// write can be undone. One file per slot, rewritten by every autosave.
zmcp_solo_prev_path( slot )
{
    path = zmcp_solo_path( slot );
    return getsubstr( path, 0, path.size - 4 ) + "_prev.sav";
}

// AUTOSAVE (lobby dvar zmcp_autosave: 0 = off, 1-4 = the solo slot to use).
// When a round ends and the next round number is set, the checkpoint is written
// to that slot with the normal save routine (zmcp_save_checkpoint, auto = 1), so
// Resume restores the start of the next round. Solo only; skipped while down,
// while another save is running, and in co-op.
zmcp_autosave_loop()
{
    level endon( "end_game" );

    slot = getdvarint( "zmcp_autosave" );
    if ( slot < 1 || slot > 4 )
        return;

    println( "ZMCP: autosave on, slot " + slot );

    for ( ;; )
    {
        level waittill( "end_of_round" );
        before = level.round_number;
        waited = 0;

        // The stock round loop raises the round number right after end_of_round.
        while ( level.round_number <= before && waited < 5 )
        {
            wait 0.25;
            waited += 0.25;
        }

        if ( level.round_number <= before )
            continue;

        wait 0.5;
        players = get_players();
        if ( players.size != 1 )
            continue;

        zmcp_save_checkpoint( players[0], 0, 1 );
    }
}

zmcp_copy_save( from, to )
{
    if ( !fs_testfile( from ) )
        return 0;

    source = fs_fopen( from, "read" );
    if ( !isdefined( source ) )
        return 0;

    lines = [];
    complete = 0;
    for ( i = 0; i < 2048; i++ )
    {
        line = fs_readline( source );
        if ( !isdefined( line ) )
            break;

        lines[lines.size] = line;
        fields = strtok( line, "," );
        if ( fields.size > 0 && fields[0] == "END" )
            complete = 1;
    }
    fs_fclose( source );

    if ( !complete )
        return 0;

    target = fs_fopen( to, "write" );
    if ( !isdefined( target ) )
        return 0;

    for ( i = 0; i < lines.size; i++ )
        fs_writeline( target, lines[i] );
    fs_fclose( target );
    return 1;
}

zmcp_solo_has_dvar( slot )
{
    name = "zmcp_has_" + level.zmcp_map;
    if ( slot > 1 )
        name += "_slot" + slot;
    return name;
}

zmcp_solo_round_dvar( slot )
{
    name = "zmcp_round_" + level.zmcp_map;
    if ( slot > 1 )
        name += "_slot" + slot;
    return name;
}

zmcp_solo_meta_prefix( slot )
{
    return "zmcp_solo_" + level.zmcp_map + "_slot" + slot + "_";
}

// The lobby cannot delete files, so SOLO RESUME's DELETE sets an archived
// zmcp_del_<map>_slotN tombstone and hides the slot. The next load of that map
// overwrites the file with EMPTY before any checkpoint is read or republished.
// If the write fails, the tombstone stays and the slot remains hidden.
zmcp_apply_solo_deletes()
{
    for ( slot = 1; slot <= 4; slot++ )
    {
        tombstone = "zmcp_del_" + level.zmcp_map + "_slot" + slot;
        if ( !getdvarint( tombstone ) )
            continue;

        file = fs_fopen( zmcp_solo_path( slot ), "write" );
        if ( !isdefined( file ) )
        {
            println( "ZMCP SOLO: could not delete slot " + slot + "; it stays hidden until the next map load." );
            continue;
        }

        fs_writeline( file, "EMPTY" );
        fs_fclose( file );

        // A deleted slot keeps no backup either.
        backup = fs_fopen( zmcp_solo_backup_path( slot ), "write" );
        if ( isdefined( backup ) )
        {
            fs_writeline( backup, "EMPTY" );
            fs_fclose( backup );
        }

        backup = fs_fopen( zmcp_solo_prev_path( slot ), "write" );
        if ( isdefined( backup ) )
        {
            fs_writeline( backup, "EMPTY" );
            fs_fclose( backup );
        }

        cmdexec( "seta " + tombstone + " 0" );
        println( "ZMCP SOLO: deleted slot " + slot + " as requested from SOLO RESUME." );
    }
}

zmcp_solo_override_prefix( slot )
{
    return "zmcp_ovr_" + level.zmcp_map + "_slot" + slot + "_";
}

// SOLO RESUME > OPTIONS stores per-slot setting changes in archived dvars instead
// of editing the save file, so the checkpoint itself is never rewritten. They are
// applied to the in-memory checkpoint every time it is read, and dropped when the
// slot is saved over, consumed, cleared or deleted.
zmcp_solo_clear_overrides( slot )
{
    prefix = zmcp_solo_override_prefix( slot );
    // cmdexec runs later; setdvar makes the change visible to the very next read.
    setdvar( prefix + "set", "0" );
    setdvar( prefix + "perks", "-1" );
    cmdexec( "seta " + prefix + "set 0" );
    cmdexec( "seta " + prefix + "perks -1" );
}

zmcp_solo_override_flag( name )
{
    value = getdvar( name );
    if ( value == "0" )
        return 0;
    if ( value == "1" )
        return 1;
    return -1;
}

zmcp_apply_solo_overrides( slot, checkpoint )
{
    if ( !isdefined( checkpoint ) || !isdefined( checkpoint.settings ) )
        return;

    prefix = zmcp_solo_override_prefix( slot );
    if ( getdvar( prefix + "set" ) != "1" )
        return;

    difficulty = zmcp_solo_override_flag( prefix + "difficulty" );
    magic = zmcp_solo_override_flag( prefix + "magic" );
    headshots = zmcp_solo_override_flag( prefix + "headshots" );
    assist = zmcp_solo_override_flag( prefix + "assist" );
    cheats = zmcp_solo_override_flag( prefix + "cheats" );

    // Ignore a damaged override as a whole and keep the saved values.
    if ( difficulty < 0 || magic < 0 || headshots < 0 || assist < 0 || cheats < 0 )
    {
        println( "ZMCP SOLO: ignored invalid settings override for slot " + slot );
        return;
    }

    checkpoint.settings.difficulty = difficulty;
    checkpoint.settings.magic = magic;
    checkpoint.settings.headshots = headshots;
    checkpoint.settings.assist = assist;
    checkpoint.settings.cheats = cheats;
}

zmcp_solo_publish( slot, checkpoint )
{
    has = zmcp_solo_has_dvar( slot );
    round_dvar = zmcp_solo_round_dvar( slot );
    prefix = zmcp_solo_meta_prefix( slot );
    if ( !isdefined( checkpoint ) )
    {
        zmcp_solo_clear_overrides( slot );
        cmdexec( "seta " + prefix + "preview 0" );
        cmdexec( "seta " + has + " 0" );
        cmdexec( "seta " + round_dvar + " 0" );
        cmdexec( "seta " + prefix + "settings 0" );
        return;
    }
    zmcp_apply_solo_overrides( slot, checkpoint );
    cmdexec( "seta " + has + " 1" );
    cmdexec( "seta " + round_dvar + " " + checkpoint.round );
    // Publish compact lobby metadata from the validated checkpoint, without
    // changing the on-disk format or exposing arbitrary checkpoint text to cmdexec.
    cmdexec( "seta " + prefix + "preview 0" );
    cmdexec( "seta " + prefix + "score " + checkpoint.score );
    count = checkpoint.weapons.size;
    if ( count > 4 ) count = 4;
    cmdexec( "seta " + prefix + "weapons " + count );
    for ( i = 0; i < count; i++ )
    {
        // Attachments after '+' are dropped so the preview can name the weapon.
        cmdexec( "seta " + prefix + "weapon" + i + " " + zmcp_display_token( checkpoint.weapons[i]["name"] ) );
    }
    count = checkpoint.perks.size;
    if ( count > 12 ) count = 12;
    cmdexec( "seta " + prefix + "perks " + count );
    for ( i = 0; i < count; i++ )
    {
        cmdexec( "seta " + prefix + "perk" + i + " " + zmcp_display_token( checkpoint.perks[i] ) );
    }
    cmdexec( "seta " + prefix + "preview 1" );
    if ( !isdefined( checkpoint.settings ) )
    {
        cmdexec( "seta " + prefix + "settings 0" );
        return;
    }
    s = checkpoint.settings;
    cmdexec( "seta " + prefix + "difficulty " + s.difficulty );
    cmdexec( "seta " + prefix + "magic " + s.magic );
    cmdexec( "seta " + prefix + "headshots " + s.headshots );
    cmdexec( "seta " + prefix + "assist " + s.assist );
    cmdexec( "seta " + prefix + "cheats " + s.cheats );
    cmdexec( "seta " + prefix + "mode " + s.mode );
    cmdexec( "seta " + prefix + "group " + s.group );
    cmdexec( "seta " + prefix + "location " + s.location );
    cmdexec( "seta " + prefix + "settings 1" );
}

zmcp_solo_write_settings( file )
{
    difficulty = getgametypesetting( "zmDifficulty" );
    magic = getgametypesetting( "magic" );
    headshots = getgametypesetting( "headshotsonly" );
    assist = getdvarint( "sv_allowAimAssist" );
    cheats = getdvarint( "sv_cheats" );
    mode = zmcp_coop_value( getdvar( "g_gametype" ) );
    group = zmcp_coop_value( getdvar( "ui_zm_gamemodegroup" ) );
    location = zmcp_coop_value( getdvar( "ui_zm_mapstartlocation" ) );
    fs_writeline( file, "SETTINGS,1," + difficulty + "," + magic + "," + headshots + "," + assist + "," + cheats + "," + mode + "," + group + "," + location );
}

zmcp_solo_settings_match( s )
{
    return s.difficulty == getgametypesetting( "zmDifficulty" ) &&
        s.magic == getgametypesetting( "magic" ) &&
        s.headshots == getgametypesetting( "headshotsonly" ) &&
        s.assist == getdvarint( "sv_allowAimAssist" ) &&
        s.cheats == getdvarint( "sv_cheats" ) &&
        s.mode == zmcp_coop_value( getdvar( "g_gametype" ) ) &&
        s.group == zmcp_coop_value( getdvar( "ui_zm_gamemodegroup" ) ) &&
        s.location == zmcp_coop_value( getdvar( "ui_zm_mapstartlocation" ) );
}

zmcp_solo_reject_settings()
{
    println( "ZMCP SOLO: Resume cancelled; saved lobby settings did not reach the match. Checkpoint retained." );
    iprintlnbold( "^1Resume cancelled: saved lobby settings did not apply" );
    wait 2;
    exitlevel( 0 );
}

zmcp_solo_read_settings( checkpoint, fields )
{
    if ( isdefined( checkpoint.settings_seen ) || fields.size != 10 || int( fields[1] ) != 1 )
    {
        checkpoint.settings_invalid = 1;
        return;
    }
    checkpoint.settings_seen = 1;
    for ( i = 2; i <= 6; i++ )
    {
        value = int( fields[i] );
        if ( value < 0 || value > 1 || fields[i] != "" + value )
        {
            checkpoint.settings_invalid = 1;
            return;
        }
    }
    for ( i = 7; i <= 9; i++ )
    {
        if ( !zmcp_coop_token( fields[i] ) )
        {
            checkpoint.settings_invalid = 1;
            return;
        }
    }
    checkpoint.settings = spawnstruct();
    checkpoint.settings.difficulty = int( fields[2] );
    checkpoint.settings.magic = int( fields[3] );
    checkpoint.settings.headshots = int( fields[4] );
    checkpoint.settings.assist = int( fields[5] );
    checkpoint.settings.cheats = int( fields[6] );
    checkpoint.settings.mode = fields[7];
    checkpoint.settings.group = fields[8];
    checkpoint.settings.location = fields[9];
}

// CUSTOM STARTING ROUND (lobby dvar zmcp_start_round, whole numbers 1-255). The
// lobby row exists only in Survival, so other modes keep the stock setting. The
// stock gametype setting is untouched, exactly like a resumed checkpoint.
zmcp_custom_round_value()
{
    if ( getdvar( "g_gametype" ) != "zstandard" )
        return 0;

    value = getdvar( "zmcp_start_round" );
    if ( value == "" || value.size > 3 )
        return 0;

    for ( i = 0; i < value.size; i++ )
    {
        if ( !issubstr( "0123456789", value[i] ) )
            return 0;
    }

    round = int( value );
    if ( round < 1 || round > 255 )
        return 0;

    return round;
}

// STARTING POINTS (lobby dvar zmcp_start_points, 0 = the normal amount). Applied
// last, so it also overrides the points a custom starting round would give.
zmcp_apply_custom_start_round()
{
    round = zmcp_custom_round_value();
    points = getdvarint( "zmcp_start_points" );
    if ( points < 1 || points > 1000000 )
        points = 0;

    if ( round < 1 && points < 1 )
        return;

    if ( round > 0 )
        level.zmcp_custom_round = round;

    if ( points > 0 )
        level.zmcp_custom_points = points;

    replacefunc( getfunction( "maps/mp/zombies/_zm", "init_levelvars" ), ::zmcp_custom_levelvars_override, -1 );
    println( "ZMCP: custom start round=" + round + " points=" + points );
}

zmcp_custom_levelvars_override()
{
    original = getfunction( "maps/mp/zombies/_zm", "init_levelvars" );
    disabledetouronce( original );
    [[ original ]]();

    if ( isdefined( level.zmcp_custom_round ) )
    {
        level.start_round = level.zmcp_custom_round;
        level.round_number = level.zmcp_custom_round;
        // Same rule as the stock init_levelvars for a higher starting round.
        level.player_starting_points = level.round_number * 500;
    }

    if ( isdefined( level.zmcp_custom_points ) )
        level.player_starting_points = level.zmcp_custom_points;
}

// ZOMBIE HEALTH CAP (lobby dvar zmcp_health_cap, 0 = off, 1-255 = round). The
// stock ai_calculate_health sets level.zombie_health from the round number. With
// a cap, any round above it is treated as the cap round for health only, so
// zombies stop getting tougher while rounds and zombie counts keep growing. It
// applies to new matches and resumed checkpoints alike (health is recalculated
// at the start of every round).
zmcp_apply_health_cap()
{
    cap = getdvarint( "zmcp_health_cap" );
    if ( cap < 1 || cap > 255 )
        return;

    level.zmcp_health_cap = cap;
    replacefunc( getfunction( "maps/mp/zombies/_zm", "ai_calculate_health" ), ::zmcp_ai_calculate_health, -1 );
    println( "ZMCP: zombie health capped at round " + cap );
}

// Same formula as the stock function, evaluated for at most the cap round.
zmcp_ai_calculate_health( round_number )
{
    if ( isdefined( level.zmcp_health_cap ) && round_number > level.zmcp_health_cap )
        round_number = level.zmcp_health_cap;

    level.zombie_health = level.zombie_vars["zombie_health_start"];

    for ( i = 2; i <= round_number; i++ )
    {
        if ( i >= 10 )
        {
            old_health = level.zombie_health;
            level.zombie_health += int( level.zombie_health * level.zombie_vars["zombie_health_increase_multiplier"] );

            if ( level.zombie_health < old_health )
            {
                level.zombie_health = old_health;
                return;
            }
        }
        else
            level.zombie_health = int( level.zombie_health + level.zombie_vars["zombie_health_increase"] );
    }
}

// OPENING (lobby dvar zmcp_start_world: 1 = power on, 2 = doors and debris open,
// 3 = both). Fresh matches only, applied right after the opening black screen.
zmcp_starting_world()
{
    level endon( "end_game" );

    world = getdvarint( "zmcp_start_world" );
    if ( world < 1 || world > 3 )
        return;

    flag_wait( "initial_blackscreen_passed" );
    wait 1;

    if ( world == 1 || world == 3 )
    {
        if ( flag_exists( "power_on" ) )
            flag_set( "power_on" );

        // Powered doors and debris only start listening for a purchase after the
        // power flag wakes them, so give them a moment before they are triggered.
        wait 1;
    }

    if ( world == 2 || world == 3 )
        zmcp_open_all_doors();

    println( "ZMCP: opening applied mode=" + world );
}

// Doors take the stock "force" flag (third notify argument) and are free, but a
// forced debris purchase still charges its cost (Nuketown's custom debris handler
// does the same). The stock unlock-all dvar, which the open_sesame debug command
// also raises, makes both free, so it is held on while the triggers are sent and
// restored afterwards. A few passes catch triggers that were not listening yet.
zmcp_open_all_doors()
{
    previous = getdvarint( "zombie_unlock_all" );
    setdvar( "zombie_unlock_all", 1 );
    level thread zmcp_unlock_all_restore( previous );
    names = array( "zombie_door", "zombie_debris" );

    for ( pass = 0; pass < 3; pass++ )
    {
        players = get_players();
        if ( players.size < 1 )
            break;

        who = players[0];

        for ( n = 0; n < names.size; n++ )
        {
            entities = getentarray( names[n], "targetname" );

            for ( i = 0; i < entities.size; i++ )
            {
                if ( !isdefined( entities[i] ) )
                    continue;

                entities[i] notify( "trigger", who, 1 );

                if ( is_true( entities[i].power_door_ignore_flag_wait ) )
                    entities[i] notify( "power_on" );

                wait 0.05;
            }
        }

        wait 1;
    }

    level notify( "zmcp_opening_done" );
}

zmcp_unlock_all_restore( previous )
{
    level waittill_any( "zmcp_opening_done", "end_game" );
    setdvar( "zombie_unlock_all", previous );
}

// STARTING LOADOUT (lobby dvars zmcp_start_weapons = 0-2 random weapons and
// zmcp_start_perks = 0-1 random perk). Only a fresh match uses it; a resumed
// checkpoint restores its own state. The weapon pool is curated per map (normal
// wall-buy and Mystery Box guns) and every entry is checked against the map's
// own weapon list before it can be given.
zmcp_loadout_add( list, names )
{
    for ( i = 0; i < names.size; i++ )
        list[list.size] = names[i] + "_zm";

    return list;
}

zmcp_loadout_pool()
{
    core = [];
    core[core.size] = "python";
    core[core.size] = "judge";
    core[core.size] = "kard";
    core[core.size] = "fiveseven";
    core[core.size] = "beretta93r";
    core[core.size] = "fivesevendw";
    core[core.size] = "ak74u";
    core[core.size] = "mp5k";
    core[core.size] = "qcw05";
    core[core.size] = "870mcs";
    core[core.size] = "rottweil72";
    core[core.size] = "saiga12";
    core[core.size] = "srm1216";
    core[core.size] = "m14";
    core[core.size] = "saritch";
    core[core.size] = "m16";
    core[core.size] = "galil";
    core[core.size] = "fnfal";
    core[core.size] = "dsr50";
    core[core.size] = "barretm82";
    core[core.size] = "hamr";
    core[core.size] = "usrpg";
    core[core.size] = "m32";
    core[core.size] = "ray_gun";
    core[core.size] = "raygun_mark2";

    extra = [];
    pool = [];

    switch ( level.zmcp_map )
    {
        case "zm_nuked":
            extra = array( "xm8", "type95", "tar21", "rpd", "hk416", "lsat" );
            pool = zmcp_loadout_add( pool, core );
            return zmcp_loadout_add( pool, extra );
        case "zm_transit":
            extra = array( "xm8", "type95", "tar21", "rpd" );
            pool = zmcp_loadout_add( pool, core );
            return zmcp_loadout_add( pool, extra );
        case "zm_highrise":
            extra = array( "xm8", "type95", "tar21", "rpd", "svu", "pdw57", "an94" );
            pool = zmcp_loadout_add( pool, core );
            return zmcp_loadout_add( pool, extra );
        case "zm_buried":
            extra = array( "tar21", "rnma", "svu", "lsat", "pdw57", "an94" );
            pool = zmcp_loadout_add( pool, core );
            return zmcp_loadout_add( pool, extra );
        case "zm_prison":
            pool = array( "judge_zm", "beretta93r_zm", "fivesevendw_zm", "uzi_zm", "thompson_zm", "870mcs_zm", "mp5k_zm", "pdw57_zm", "saiga12_zm", "rottweil72_zm", "m14_zm", "ak47_zm", "tar21_zm", "galil_zm", "fnfal_zm", "dsr50_zm", "barretm82_zm", "lsat_zm", "usrpg_zm", "ray_gun_zm", "raygun_mark2_zm", "blundergat_zm" );
            return pool;
        case "zm_tomb":
            pool = array( "hamr_zm", "mg08_zm", "type95_zm", "galil_zm", "fnfal_zm", "m14_zm", "mp44_zm", "scar_zm", "870mcs_zm", "ksg_zm", "srm1216_zm", "ak74u_zm", "ak74u_extclip_zm", "pdw57_zm", "thompson_zm", "qcw05_zm", "mp40_zm", "mp40_stalker_zm", "evoskorpion_zm", "ballista_zm", "dsr50_zm", "beretta93r_zm", "beretta93r_extclip_zm", "kard_zm", "fiveseven_zm", "python_zm", "c96_zm", "fivesevendw_zm", "m32_zm", "ray_gun_zm", "raygun_mark2_zm" );
            return pool;
    }

    return [];
}

zmcp_starting_loadout()
{
    level endon( "end_game" );

    weapons = getdvarint( "zmcp_start_weapons" );
    if ( weapons < 0 )
        weapons = 0;
    if ( weapons > 4 )
        weapons = 4;

    perks = getdvarint( "zmcp_start_perks" );
    if ( perks < 0 )
        perks = 0;
    if ( perks > 1 )
        perks = 1;

    if ( weapons < 1 && perks < 1 )
        return;

    // Values 3 and 4 give one or two Pack-a-Punched weapons.
    packed = 0;
    if ( weapons > 2 )
    {
        packed = 1;
        weapons -= 2;
    }

    // The map has registered its weapons and perk machines by this point.
    flag_wait( "initial_blackscreen_passed" );
    wait 1;

    pool = [];
    candidates = zmcp_loadout_pool();
    for ( i = 0; i < candidates.size; i++ )
    {
        if ( is_weapon_included( candidates[i] ) )
            pool[pool.size] = candidates[i];
    }

    if ( weapons > 0 && pool.size < 1 )
        println( "ZMCP: no starting weapons are available on this map" );

    players = get_players();
    for ( i = 0; i < players.size; i++ )
        players[i] thread zmcp_give_starting_loadout( pool, weapons, perks, packed );
}

zmcp_give_starting_loadout( pool, weapons, perks, packed )
{
    self endon( "disconnect" );
    level endon( "end_game" );

    while ( self.sessionstate != "playing" || !isalive( self ) )
        wait 0.1;

    // Each player rolls their own weapons from the map's pool.
    picks = [];
    shuffled = array_randomize( pool );
    for ( i = 0; i < shuffled.size && picks.size < weapons; i++ )
    {
        if ( !self hasweapon( shuffled[i] ) )
            picks[picks.size] = shuffled[i];
    }

    given = "";
    // Two weapons fill both primary slots, so the starting pistol makes room.
    if ( picks.size > 1 && isdefined( level.start_weapon ) && self hasweapon( level.start_weapon ) )
        self takeweapon( level.start_weapon );

    for ( i = 0; i < picks.size; i++ )
    {
        pick = picks[i];
        upgraded = 0;
        if ( packed && maps\mp\zombies\_zm_weapons::can_upgrade_weapon( pick ) )
        {
            upgrade = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( pick );
            if ( isdefined( upgrade ) && upgrade != pick && !self hasweapon( upgrade ) )
            {
                pick = upgrade;
                upgraded = 1;
            }
        }

        self maps\mp\zombies\_zm_weapons::weapon_give( pick, upgraded, 0, 1 );
        given += pick + " ";
        wait 0.2;
    }

    count = 0;
    if ( perks > 0 )
    {
        perk = zmcp_random_start_perk();
        if ( isdefined( perk ) )
        {
            self maps\mp\zombies\_zm_perks::give_perk( perk, 0 );
            count = 1;
        }
    }

    println( "ZMCP: starting loadout weapons=[" + given + "] perks=" + count );
    if ( picks.size > 0 || count > 0 )
        self iprintln( "^2Starting loadout applied" );
}

// Same pool as the stock random-perk reward: this map's perk machines.
zmcp_random_start_perk()
{
    vending = getentarray( "zombie_vending", "targetname" );
    pool = [];

    for ( i = 0; i < vending.size; i++ )
    {
        perk = vending[i].script_noteworthy;
        if ( !isdefined( perk ) || perk == "specialty_weapupgrade" )
            continue;
        if ( self hasperk( perk ) )
            continue;
        duplicate = 0;
        for ( j = 0; j < pool.size; j++ )
        {
            if ( pool[j] == perk )
                duplicate = 1;
        }
        if ( !duplicate )
            pool[pool.size] = perk;
    }

    if ( pool.size < 1 )
        return undefined;

    pool = array_randomize( pool );
    return pool[0];
}
