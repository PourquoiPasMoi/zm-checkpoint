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
zmcp_apply_custom_start_round()
{
    if ( getdvar( "g_gametype" ) != "zstandard" )
        return;

    value = getdvar( "zmcp_start_round" );
    if ( value == "" || value.size > 3 )
        return;

    for ( i = 0; i < value.size; i++ )
    {
        if ( !issubstr( "0123456789", value[i] ) )
            return;
    }

    round = int( value );
    if ( round < 1 || round > 255 )
        return;

    level.zmcp_custom_round = round;
    replacefunc( getfunction( "maps/mp/zombies/_zm", "init_levelvars" ), ::zmcp_custom_levelvars_override, -1 );
    println( "ZMCP: custom starting round " + round );
}

zmcp_custom_levelvars_override()
{
    original = getfunction( "maps/mp/zombies/_zm", "init_levelvars" );
    disabledetouronce( original );
    [[ original ]]();

    if ( !isdefined( level.zmcp_custom_round ) )
        return;

    level.start_round = level.zmcp_custom_round;
    level.round_number = level.zmcp_custom_round;
    // Same rule as the stock init_levelvars for a higher starting round.
    level.player_starting_points = level.round_number * 500;
}

// STARTING LOADOUT (lobby dvars zmcp_start_weapon1/2 and zmcp_start_perks). Only
// a fresh match uses it; a resumed checkpoint restores its own state. Every
// weapon is re-validated against this map's own weapon list.
zmcp_loadout_weapon( dvar )
{
    value = getdvar( dvar );
    if ( value == "" || value == "none" )
        return "";

    if ( !zmcp_coop_token( value ) || value.size < 5 || getsubstr( value, value.size - 3 ) != "_zm" || issubstr( value, "upgraded" ) )
    {
        println( "ZMCP: ignored invalid starting weapon " + dvar );
        return "";
    }

    if ( !is_weapon_included( value ) )
    {
        println( "ZMCP: starting weapon " + value + " is not on this map" );
        return "";
    }

    return value;
}

zmcp_starting_loadout()
{
    level endon( "end_game" );

    perks = getdvarint( "zmcp_start_perks" );
    if ( perks < 0 )
        perks = 0;
    if ( perks > 4 )
        perks = 4;

    if ( getdvar( "zmcp_start_weapon1" ) == "none" && getdvar( "zmcp_start_weapon2" ) == "none" && perks < 1 )
        return;

    // The map has registered its weapons and perk machines by this point.
    flag_wait( "initial_blackscreen_passed" );
    wait 1;

    first = zmcp_loadout_weapon( "zmcp_start_weapon1" );
    second = zmcp_loadout_weapon( "zmcp_start_weapon2" );
    if ( first == second )
        second = "";
    if ( first == "" )
    {
        first = second;
        second = "";
    }
    if ( first == "" && perks < 1 )
        return;

    players = get_players();
    for ( i = 0; i < players.size; i++ )
        players[i] thread zmcp_give_starting_loadout( first, second, perks );
}

zmcp_give_starting_loadout( first, second, perks )
{
    self endon( "disconnect" );
    level endon( "end_game" );

    while ( self.sessionstate != "playing" || !isalive( self ) )
        wait 0.1;

    given = "";
    // Two weapons fill both primary slots, so the starting pistol makes room.
    if ( second != "" && isdefined( level.start_weapon ) && self hasweapon( level.start_weapon ) )
        self takeweapon( level.start_weapon );

    if ( first != "" )
    {
        self maps\mp\zombies\_zm_weapons::weapon_give( first, 0, 0, 1 );
        given += first;
        wait 0.2;
    }

    if ( second != "" )
    {
        self maps\mp\zombies\_zm_weapons::weapon_give( second, 0, 0, 1 );
        given += " " + second;
        wait 0.2;
    }

    count = 0;
    for ( i = 0; i < perks; i++ )
    {
        perk = zmcp_random_start_perk();
        if ( !isdefined( perk ) )
            break;
        self maps\mp\zombies\_zm_perks::give_perk( perk, 0 );
        count++;
        wait 0.2;
    }

    println( "ZMCP: starting loadout weapons=[" + given + "] perks=" + count );
    if ( given != "" || count > 0 )
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
