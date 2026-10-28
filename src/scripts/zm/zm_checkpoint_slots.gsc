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

zmcp_solo_publish( slot, checkpoint )
{
    has = zmcp_solo_has_dvar( slot );
    round_dvar = zmcp_solo_round_dvar( slot );
    prefix = zmcp_solo_meta_prefix( slot );
    if ( !isdefined( checkpoint ) )
    {
        cmdexec( "seta " + prefix + "preview 0" );
        cmdexec( "seta " + has + " 0" );
        cmdexec( "seta " + round_dvar + " 0" );
        cmdexec( "seta " + prefix + "settings 0" );
        return;
    }
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
        name = checkpoint.weapons[i]["name"];
        if ( zmcp_coop_token( name ) )
            cmdexec( "seta " + prefix + "weapon" + i + " " + name );
        else
            cmdexec( "seta " + prefix + "weapon" + i + " unknown" );
    }
    count = checkpoint.perks.size;
    if ( count > 12 ) count = 12;
    cmdexec( "seta " + prefix + "perks " + count );
    for ( i = 0; i < count; i++ )
    {
        name = checkpoint.perks[i];
        if ( zmcp_coop_token( name ) )
            cmdexec( "seta " + prefix + "perk" + i + " " + name );
        else
            cmdexec( "seta " + prefix + "perk" + i + " unknown" );
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
