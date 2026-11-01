// Appended by Build.ps1. Solo format-3 files and guards remain independent.
// Co-op schema 1 uses two complete generation slots and a consumption receipt.
zmcp_command_player( players )
{
    if ( players.size == 1 )
        return players[0];
    for ( i = 0; i < players.size; i++ )
        if ( players[i] ishost() )
            return players[i];
    return undefined;
}

zmcp_coop_id( player )
{
    if ( !isdefined( player ) )
        return "";
    id = tolower( player getxuid() );
    if ( id.size > 2 && getsubstr( id, 0, 2 ) == "0x" )
        id = getsubstr( id, 2 );
    while ( id.size > 1 && id[0] == "0" )
        id = getsubstr( id, 1 );
    if ( !zmcp_coop_token( id ) || id == "0" || id.size > 16 )
        return "";
    for ( i = 0; i < id.size; i++ )
        if ( !issubstr( "0123456789abcdef", id[i] ) )
            return "";
    return id;
}

zmcp_coop_token( value )
{
    if ( !isdefined( value ) || value == "" || value.size > 128 )
        return 0;
    for ( i = 0; i < value.size; i++ )
        if ( !issubstr( "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_./-\\", value[i] ) )
            return 0;
    return 1;
}

zmcp_coop_value( value )
{
    if ( value == "" )
        return "-";
    return value;
}

zmcp_coop_settings()
{
    return "" + getgametypesetting( "zmDifficulty" ) + "/" + getgametypesetting( "magic" ) + "/" + getgametypesetting( "headshotsonly" );
}

zmcp_coop_slot_valid( slot )
{
    return slot >= 1 && slot <= 4;
}

// Session 1 keeps the original co-op filenames so existing saves stay valid.
zmcp_coop_base( slot )
{
    base = "zm_checkpoint_coop_" + level.zmcp_map;
    if ( slot > 1 )
        base += "_s" + slot;
    return base;
}

zmcp_coop_prefix( slot )
{
    return "zmcp_coop_" + level.zmcp_map + "_s" + slot + "_";
}

zmcp_coop_override_prefix( slot )
{
    return "zmcp_ovr_coop_" + level.zmcp_map + "_s" + slot + "_";
}

zmcp_coop_tombstone( slot )
{
    return "zmcp_del_coop_" + level.zmcp_map + "_s" + slot;
}

// The lobby cannot delete files. CO-OP RESUME's DEL sets an archived tombstone;
// the next map load overwrites only that session's two generation files with
// EMPTY. The consumption receipt is a counter, not a save, and is left alone.
zmcp_apply_coop_deletes()
{
    for ( slot = 1; slot <= 4; slot++ )
    {
        tombstone = zmcp_coop_tombstone( slot );
        if ( !getdvarint( tombstone ) )
            continue;
        done = 1;
        names = array( "_a.sav", "_b.sav" );
        for ( i = 0; i < names.size; i++ )
        {
            file = fs_fopen( zmcp_coop_base( slot ) + names[i], "write" );
            if ( !isdefined( file ) )
            {
                done = 0;
                continue;
            }
            fs_writeline( file, "EMPTY" );
            fs_fclose( file );
        }
        if ( !done )
        {
            println( "ZMCP COOP: could not delete session " + slot + "; it stays hidden until the next map load." );
            continue;
        }
        zmcp_coop_clear_overrides( slot );
        cmdexec( "seta " + tombstone + " 0" );
        println( "ZMCP COOP: deleted session " + slot + " as requested from CO-OP RESUME." );
    }
}

zmcp_coop_clear_overrides( slot )
{
    prefix = zmcp_coop_override_prefix( slot );
    setdvar( prefix + "set", "0" );
    setdvar( prefix + "perks", "-1" );
    cmdexec( "seta " + prefix + "set 0" );
    cmdexec( "seta " + prefix + "perks -1" );
}

// A valid override changes only the in-memory checkpoint. Any bad value ignores
// the whole override and keeps the saved settings. Cheats/assist are not part
// of co-op saves, so the lobby applies those at launch.
zmcp_coop_apply_overrides( slot, checkpoint )
{
    if ( !isdefined( checkpoint ) )
        return;
    prefix = zmcp_coop_override_prefix( slot );
    if ( getdvar( prefix + "set" ) != "1" )
        return;
    difficulty = getdvar( prefix + "difficulty" );
    magic = getdvar( prefix + "magic" );
    headshots = getdvar( prefix + "headshots" );
    if ( ( difficulty != "0" && difficulty != "1" && difficulty != "2" ) || ( magic != "0" && magic != "1" ) || ( headshots != "0" && headshots != "1" ) )
    {
        println( "ZMCP COOP: ignored invalid settings override for session " + slot );
        return;
    }
    checkpoint.settings = difficulty + "/" + magic + "/" + headshots;
}

zmcp_coop_init()
{
    level.zmcp_coop_slot = 0;
    zmcp_apply_coop_deletes();
    for ( slot = 1; slot <= 4; slot++ )
    {
        checkpoint = zmcp_coop_latest( slot );
        zmcp_coop_apply_overrides( slot, checkpoint );
        zmcp_coop_publish( slot, checkpoint );
    }
    if ( !getdvarint( "zmcp_coop_autoload" ) )
        return;
    selected = getdvarint( "zmcp_coop_slot" );
    setdvar( "zmcp_coop_autoload", "0" );
    setdvar( "zmcp_autoload", "0" );
    // An invalid request must fail closed, not start a fresh playable match.
    level.zmcp_coop_loading = 1;
    level.zmcp_loading = 1;
    level.zmcp_busy = 1;
    replacefunc( getfunction( "maps/mp/zombies/_zm", "round_think" ), ::zmcp_coop_round_gate, -1 );
    if ( zmcp_coop_slot_valid( selected ) )
    {
        level.zmcp_coop_slot = selected;
        level.zmcp_coop = zmcp_coop_latest( selected );
        zmcp_coop_apply_overrides( selected, level.zmcp_coop );
    }
    if ( isdefined( level.zmcp_coop ) && !zmcp_coop_used( level.zmcp_coop ) )
    {
        level.zmcp_pending = level.zmcp_coop;
        replacefunc( getfunction( "maps/mp/zombies/_zm", "init_levelvars" ), ::zmcp_init_levelvars_override, -1 );
        // ZMCP_NUKETOWN_ONLY_BEGIN
        replacefunc( getfunction( "maps/mp/zm_nuked_perks", "perks_from_the_sky" ), ::zmcp_perks_from_the_sky_override, -1 );
        // ZMCP_NUKETOWN_ONLY_END
    }
}

zmcp_coop_round_gate( restart )
{
    level endon( "end_game" );
    level.zmcp_coop_gate_entered = 1;
    while ( !level.zmcp_coop_ready )
        wait 0.05;
    original = getfunction( "maps/mp/zombies/_zm", "round_think" );
    disabledetouronce( original );
    if ( !isdefined( restart ) )
        restart = 0;
    [[ original ]]( restart );
}

zmcp_coop_latest( slot )
{
    a = zmcp_coop_read( zmcp_coop_base( slot ) + "_a.sav" );
    b = zmcp_coop_read( zmcp_coop_base( slot ) + "_b.sav" );
    latest = b;
    if ( isdefined( a ) && ( !isdefined( b ) || a.generation > b.generation ) )
        latest = a;
    if ( isdefined( latest ) )
        latest.slot = slot;
    return latest;
}

// Returns the consumed generation: 0 when there is no receipt, -1 when the
// receipt is damaged (uncertain, so callers must fail closed).
zmcp_coop_receipt( slot )
{
    path = zmcp_coop_base( slot ) + "_used.sav";
    if ( !fs_testfile( path ) )
        return 0;
    file = fs_fopen( path, "read" );
    if ( !isdefined( file ) )
        return -1;
    line = fs_readline( file );
    ending = fs_readline( file );
    fs_fclose( file );
    if ( !isdefined( line ) || !isdefined( ending ) || ending != "END" )
        return -1;
    fields = strtok( line, "," );
    if ( fields.size != 2 || fields[0] != "USED" )
        return -1;
    return int( fields[1] );
}

zmcp_coop_used( checkpoint )
{
    used = zmcp_coop_receipt( checkpoint.slot );
    if ( used < 0 )
        return 1;
    return used >= checkpoint.generation;
}

zmcp_coop_name( name )
{
    out = "";
    for ( i = 0; i < name.size && out.size < 16; i++ )
        if ( issubstr( "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", name[i] ) )
            out += name[i];
    return out;
}

// Console-safe display token: attachments after '+' are dropped, anything else
// outside the token set becomes "unknown".
zmcp_display_token( value )
{
    plus = 0;
    for ( i = 0; i < value.size; i++ )
    {
        if ( value[i] == "+" )
        {
            plus = i;
            break;
        }
    }
    if ( plus > 0 )
        value = getsubstr( value, 0, plus );
    if ( !zmcp_coop_token( value ) )
        return "unknown";
    return value;
}

zmcp_coop_publish_summary( prefix, checkpoint )
{
    ids = "";
    for ( i = 0; i < checkpoint.members.size; i++ )
    {
        if ( i > 0 )
            ids += "/";
        ids += checkpoint.members[i].id;
    }
    cmdexec( "seta " + prefix + "host " + checkpoint.host );
    cmdexec( "seta " + prefix + "ids " + ids );
    cmdexec( "seta " + prefix + "round " + checkpoint.round );
    cmdexec( "seta " + prefix + "mode " + checkpoint.mode );
    cmdexec( "seta " + prefix + "group " + checkpoint.group );
    cmdexec( "seta " + prefix + "location " + checkpoint.location );
    cmdexec( "seta " + prefix + "mod " + checkpoint.mod );
    cmdexec( "seta " + prefix + "settings " + checkpoint.settings );
}

zmcp_coop_publish( slot, checkpoint )
{
    prefix = zmcp_coop_prefix( slot );
    legacy = "zmcp_coop_" + level.zmcp_map + "_";
    cmdexec( "seta " + prefix + "has 0" );
    if ( slot == 1 )
        cmdexec( "seta " + legacy + "has 0" );
    if ( !isdefined( checkpoint ) || zmcp_coop_used( checkpoint ) )
    {
        zmcp_coop_clear_overrides( slot );
        return;
    }
    zmcp_coop_publish_summary( prefix, checkpoint );
    // Older UI packages read the pre-0.4.26 names for the first session.
    if ( slot == 1 )
        zmcp_coop_publish_summary( legacy, checkpoint );
    cmdexec( "seta " + prefix + "count " + checkpoint.members.size );
    for ( i = 0; i < checkpoint.members.size; i++ )
    {
        member = checkpoint.members[i];
        mp = prefix + "m" + i + "_";
        weapons = "";
        for ( w = 0; w < member.weapons.size && w < 4; w++ )
        {
            if ( w > 0 )
                weapons += ",";
            weapons += zmcp_display_token( member.weapons[w]["name"] );
        }
        perks = "";
        for ( p = 0; p < member.perks.size && p < 12; p++ )
        {
            if ( p > 0 )
                perks += ",";
            perks += zmcp_display_token( member.perks[p] );
        }
        if ( weapons == "" )
            weapons = "-";
        if ( perks == "" )
            perks = "-";
        cmdexec( "seta " + mp + "pts " + member.score );
        cmdexec( "seta " + mp + "w " + weapons );
        cmdexec( "seta " + mp + "p " + perks );
    }
    cmdexec( "seta " + prefix + "has 1" );
    if ( slot == 1 )
        cmdexec( "seta " + legacy + "has 1" );
}

// First slot with no usable files, then the first consumed one. A live session
// is never chosen, so Save & Exit cannot overwrite it.
zmcp_coop_free_slot()
{
    for ( pass = 0; pass < 2; pass++ )
    {
        for ( slot = 1; slot <= 4; slot++ )
        {
            checkpoint = zmcp_coop_latest( slot );
            if ( pass == 0 && !isdefined( checkpoint ) )
                return slot;
            if ( pass == 1 && isdefined( checkpoint ) && zmcp_coop_used( checkpoint ) )
                return slot;
        }
    }
    return 0;
}

zmcp_coop_context( checkpoint )
{
    return checkpoint.mode == getdvar( "g_gametype" ) && checkpoint.group == zmcp_coop_value( getdvar( "ui_zm_gamemodegroup" ) ) && checkpoint.location == zmcp_coop_value( getdvar( "ui_zm_mapstartlocation" ) ) && checkpoint.mod == zmcp_coop_value( getdvar( "fs_game" ) ) && checkpoint.settings == zmcp_coop_settings();
}

zmcp_coop_member( checkpoint, id )
{
    for ( i = 0; i < checkpoint.members.size; i++ )
        if ( checkpoint.members[i].id == id )
            return checkpoint.members[i];
    return undefined;
}

zmcp_coop_roster( checkpoint, ready )
{
    players = get_players();
    if ( players.size != checkpoint.members.size )
        return 0;
    seen = [];
    hosts = 0;
    for ( i = 0; i < players.size; i++ )
    {
        id = zmcp_coop_id( players[i] );
        if ( id == "" || isdefined( seen[id] ) || !isdefined( zmcp_coop_member( checkpoint, id ) ) )
            return 0;
        seen[id] = 1;
        if ( players[i] ishost() )
        {
            if ( id != checkpoint.host )
                return 0;
            hosts++;
        }
        if ( ready && !zmcp_coop_alive( players[i] ) )
            return 0;
    }
    return hosts == 1;
}

zmcp_coop_alive( player )
{
    return isdefined( player ) && isalive( player ) && player.sessionstate == "playing" && !( isdefined( player.laststand ) && player.laststand );
}

zmcp_coop_save( host, exit_after_save )
{
    if ( !isdefined( host ) || !( host ishost() ) )
    {
        if ( isdefined( host ) )
            host iprintlnbold( "^1Only the host can save the team" );
        return;
    }
    players = get_players();
    if ( players.size < 2 || players.size > 4 || ( getdvar( "g_gametype" ) != "zclassic" && getdvar( "g_gametype" ) != "zstandard" ) )
    {
        host iprintlnbold( "^1Co-op saves require 2-4 players in Classic or Survival" );
        return;
    }
    if ( isdefined( level.zmcp_coop_owner ) && zmcp_coop_id( host ) != level.zmcp_coop_owner )
    {
        host iprintlnbold( "^1The original checkpoint host is required" );
        return;
    }
    seen = [];
    for ( i = 0; i < players.size; i++ )
    {
        id = zmcp_coop_id( players[i] );
        if ( id == "" )
        {
            host iprintlnbold( "^1Team save blocked: a player has no valid account ID" );
            println( "ZMCP COOP: save blocked; invalid player XUID at index " + i );
            return;
        }
        if ( isdefined( seen[id] ) )
        {
            host iprintlnbold( "^1Team save blocked: duplicate player account ID" );
            println( "ZMCP COOP: save blocked; duplicate XUID " + id );
            return;
        }
        if ( !zmcp_coop_alive( players[i] ) )
        {
            host iprintlnbold( "^1Team save blocked: every player must be alive" );
            println( "ZMCP COOP: save blocked; player not alive/playing: " + id );
            return;
        }
        seen[id] = 1;
    }
    mode = getdvar( "g_gametype" );
    group = zmcp_coop_value( getdvar( "ui_zm_gamemodegroup" ) );
    location = zmcp_coop_value( getdvar( "ui_zm_mapstartlocation" ) );
    mod = zmcp_coop_value( getdvar( "fs_game" ) );
    if ( !zmcp_coop_token( group ) || !zmcp_coop_token( location ) || !zmcp_coop_token( mod ) )
    {
        host iprintlnbold( "^1Unsupported map or mod identifier" );
        return;
    }
    // A resumed session saves back into itself; a fresh match takes a free slot.
    slot = level.zmcp_coop_slot;
    if ( !zmcp_coop_slot_valid( slot ) )
        slot = zmcp_coop_free_slot();
    if ( !zmcp_coop_slot_valid( slot ) )
    {
        host iprintlnbold( "^1All 4 co-op sessions hold saves - delete one in CO-OP RESUME" );
        return;
    }
    receipt_generation = zmcp_coop_receipt( slot );
    if ( receipt_generation < 0 )
    {
        host iprintlnbold( "^1Team save blocked: the session receipt is damaged" );
        println( "ZMCP COOP: save blocked; damaged receipt for session " + slot );
        return;
    }
    previous = zmcp_coop_latest( slot );
    generation = receipt_generation + 1;
    target = zmcp_coop_base( slot ) + "_a.sav";
    if ( isdefined( previous ) )
    {
        if ( previous.generation >= generation )
            generation = previous.generation + 1;
        if ( previous.path == target )
            target = zmcp_coop_base( slot ) + "_b.sav";
    }
    if ( generation < 1 || generation > 2000000000 )
        return;
    level.zmcp_busy = 1;
    for ( i = 0; i < players.size; i++ )
    {
        players[i] freezecontrols( 1 );
        players[i] enableinvulnerability();
    }
    file = fs_fopen( target, "write" );
    if ( isdefined( file ) )
    {
        fs_writeline( file, "COOP,1," + level.zmcp_map );
        fs_writeline( file, "SESSION," + zmcp_coop_id( host ) + "," + players.size + "," + mode + "," + group + "," + location + "," + mod + "," + generation + "," + zmcp_coop_settings() );
        fs_writeline( file, "ROUND," + level.round_number );
        for ( i = 0; i < players.size; i++ )
        {
            player = players[i];
            fs_writeline( file, "MEMBER," + zmcp_coop_id( player ) );
            fs_writeline( file, "PLAYER," + player.score + "," + player.health + "," + player.maxhealth + "," + player.origin[0] + "," + player.origin[1] + "," + player.origin[2] + "," + player getplayerangles()[0] + "," + player getplayerangles()[1] + "," + player getplayerangles()[2] + "," + player getcurrentweapon() );
            zmcp_write_weapons( file, player );
            zmcp_write_perks( file, player );
            zmcp_write_offhands( file, player );
            zmcp_write_equipment( file, player );
            fs_writeline( file, "ENDMEMBER" );
        }
        zmcp_write_flags( file );
        // Quest/character-dependent reconstruction needs its own co-op audit.
        // ZMCP_BURIED_ONLY_BEGIN
        zmcp_write_buried_sloth( file );
        // ZMCP_BURIED_ONLY_END
        // ZMCP_NUKETOWN_ONLY_BEGIN
        zmcp_write_nuketown_perks( file );
        // ZMCP_NUKETOWN_ONLY_END
        fs_writeline( file, "END" );
        fs_fclose( file );
    }
    saved = zmcp_coop_read( target );
    success = isdefined( saved ) && saved.generation == generation && zmcp_coop_roster( saved, 1 );
    if ( success )
    {
        saved.slot = slot;
        level.zmcp_coop = saved;
        level.zmcp_coop_slot = slot;
        level.zmcp_coop_owner = saved.host;
        // A new generation replaces any earlier per-session option overrides.
        zmcp_coop_clear_overrides( slot );
        for ( i = 0; i < players.size; i++ )
        {
            name = zmcp_coop_name( players[i].name );
            if ( name != "" )
                cmdexec( "seta zmcp_coop_name_" + zmcp_coop_id( players[i] ) + " " + name );
        }
        zmcp_coop_publish( slot, saved );
        iprintlnbold( "^2Team checkpoint saved - round " + saved.round );
    }
    else
        iprintlnbold( "^1Team save failed; previous checkpoint retained" );
    if ( success && exit_after_save )
    {
        wait 1;
        exitlevel( 0 );
        return;
    }
    for ( i = 0; i < players.size; i++ )
    {
        if ( isdefined( players[i] ) )
        {
            players[i] freezecontrols( 0 );
            players[i] disableinvulnerability();
        }
    }
    level.zmcp_busy = 0;
}

zmcp_coop_abort( reason )
{
    println( "ZMCP COOP: resume aborted; snapshot files retained: " + reason );
    iprintlnbold( "^1Resume cancelled: " + reason );
    wait 2;
    exitlevel( 0 );
}

zmcp_coop_restore()
{
    level endon( "end_game" );
    level endon( "zmcp_coop_abort" );
    level thread zmcp_coop_watchdog();
    checkpoint = level.zmcp_coop;
    if ( !isdefined( checkpoint ) || zmcp_coop_used( checkpoint ) )
    {
        zmcp_coop_abort( "no unused team checkpoint" );
        return;
    }
    if ( !zmcp_coop_context( checkpoint ) )
    {
        zmcp_coop_abort( "map mode, location, mod or settings differ" );
        return;
    }
    level thread zmcp_coop_hold_players();
    // Bounded wait permits slower clients, but never starts an incomplete team.
    for ( attempt = 0; attempt < 1200; attempt++ )
    {
        if ( zmcp_coop_roster( checkpoint, 1 ) && isdefined( level.zmcp_coop_gate_entered ) && isdefined( level.flag ) && isdefined( level.flag["initial_blackscreen_passed"] ) && flag( "initial_blackscreen_passed" ) )
            break;
        if ( attempt % 100 == 0 )
            iprintlnbold( "^3Waiting for saved team - everyone open pause once" );
        wait 0.1;
    }
    if ( attempt == 1200 || !zmcp_coop_roster( checkpoint, 1 ) )
    {
        zmcp_coop_abort( "original host and exact ready team required" );
        return;
    }
    host = zmcp_command_player( get_players() );
    zmcp_restore_blockers( host );
    // ZMCP_BURIED_ONLY_BEGIN
    zmcp_restore_buried_sloth();
    // ZMCP_BURIED_ONLY_END
    players = get_players();
    for ( i = 0; i < players.size; i++ )
    {
        if ( !zmcp_coop_roster( checkpoint, 1 ) )
        {
            zmcp_coop_abort( "team changed during restoration" );
            return;
        }
        member = zmcp_coop_member( checkpoint, zmcp_coop_id( players[i] ) );
        zmcp_restore_player( players[i], member );
        players[i] setorigin( member.origin );
        players[i] setplayerangles( member.angles );
    }
    wait 0.5;
    if ( !zmcp_coop_roster( checkpoint, 1 ) )
    {
        zmcp_coop_abort( "team changed before completion" );
        return;
    }
    receipt = fs_fopen( zmcp_coop_base( checkpoint.slot ) + "_used.sav", "write" );
    if ( !isdefined( receipt ) )
    {
        zmcp_coop_abort( "could not commit consumption receipt" );
        return;
    }
    fs_writeline( receipt, "USED," + checkpoint.generation );
    fs_writeline( receipt, "END" );
    fs_fclose( receipt );
    // Validate exact receipt, not the fail-closed 'used' result for damaged I/O.
    receipt = fs_fopen( zmcp_coop_base( checkpoint.slot ) + "_used.sav", "read" );
    if ( !isdefined( receipt ) )
    {
        zmcp_coop_abort( "could not verify consumption receipt" );
        return;
    }
    line = fs_readline( receipt );
    ending = fs_readline( receipt );
    fs_fclose( receipt );
    if ( line != "USED," + checkpoint.generation || ending != "END" )
    {
        zmcp_coop_abort( "consumption receipt is damaged" );
        return;
    }
    level.zmcp_coop_owner = checkpoint.host;
    zmcp_coop_publish( checkpoint.slot, checkpoint );
    level.zmcp_coop_ready = 1;
    level.zmcp_busy = 0;
    for ( i = 0; i < players.size; i++ )
    {
        players[i] freezecontrols( 0 );
        players[i] disableinvulnerability();
    }
    iprintlnbold( "^2Team restored - checkpoint consumed" );
}

zmcp_coop_watchdog()
{
    level endon( "end_game" );
    wait 150;
    if ( !level.zmcp_coop_ready )
    {
        level notify( "zmcp_coop_abort" );
        zmcp_coop_abort( "restoration timed out" );
    }
}

zmcp_coop_hold_players()
{
    level endon( "end_game" );
    while ( !level.zmcp_coop_ready )
    {
        players = get_players();
        for ( i = 0; i < players.size; i++ )
        {
            if ( zmcp_coop_alive( players[i] ) )
            {
                players[i] freezecontrols( 1 );
                players[i] enableinvulnerability();
            }
        }
        wait 0.05;
    }
}

zmcp_coop_read( path )
{
    if ( !fs_testfile( path ) )
        return undefined;
    file = fs_fopen( path, "read" );
    if ( !isdefined( file ) )
        return undefined;
    c = spawnstruct();
    c.path = path;
    c.flags = [];
    c.machines = [];
    c.machine_locations = [];
    c.machine_location_seen = 0;
    c.machine_location_invalid = 0;
    c.members = [];
    for ( i = 0; i < 5; i++ )
    {
        c.machines[i] = 0;
        c.machine_locations[i] = -1;
    }
    member = undefined;
    header = 0;
    complete = 0;
    invalid = 0;
    for ( line_index = 0; line_index < 4096; line_index++ )
    {
        line = fs_readline( file );
        if ( !isdefined( line ) || line == "" )
            break;
        f = strtok( line, "," );
        if ( f.size < 1 || complete )
        {
            invalid = 1;
            break;
        }
        r = f[0];
        if ( line_index == 0 )
        {
            if ( f.size != 3 || r != "COOP" || f[1] != "1" || f[2] != level.zmcp_map )
            {
                invalid = 1;
                break;
            }
            header = 1;
        }
        else if ( r == "SESSION" && f.size == 9 && !isdefined( c.host ) && !isdefined( member ) )
        {
            c.host = f[1];
            c.count = int( f[2] );
            c.mode = f[3];
            c.group = f[4];
            c.location = f[5];
            c.mod = f[6];
            c.generation = int( f[7] );
            c.settings = f[8];
            for ( i = 1; i < f.size; i++ )
                if ( !zmcp_coop_token( f[i] ) )
                    invalid = 1;
        }
        else if ( r == "ROUND" && f.size == 2 && !isdefined( c.round ) && !isdefined( member ) )
            c.round = int( f[1] );
        else if ( r == "MEMBER" && f.size == 2 && !isdefined( member ) && c.members.size < 4 )
        {
            if ( !zmcp_coop_token( f[1] ) || f[1] == "0" || isdefined( zmcp_coop_member( c, f[1] ) ) )
            {
                invalid = 1;
                break;
            }
            member = spawnstruct();
            member.id = f[1];
            member.weapons = [];
            member.perks = [];
            member.offhands = [];
        }
        else if ( r == "ENDMEMBER" && f.size == 1 && isdefined( member ) )
        {
            if ( !isdefined( member.score ) || member.health < 1 || member.maxhealth < 1 || member.score < 0 || member.weapons.size == 0 )
                invalid = 1;
            c.members[c.members.size] = member;
            member = undefined;
        }
        else if ( isdefined( member ) )
        {
            if ( r == "PLAYER" && f.size == 11 && !isdefined( member.score ) )
            {
                member.score = int( f[1] );
                member.health = int( f[2] );
                member.maxhealth = int( f[3] );
                member.origin = ( float( f[4] ), float( f[5] ), float( f[6] ) );
                member.angles = ( float( f[7] ), float( f[8] ), float( f[9] ) );
                member.current_weapon = f[10];
            }
            else if ( r == "WEAPON" && f.size == 10 && member.weapons.size < 16 )
                member.weapons[member.weapons.size] = zmcp_read_weapon( f );
            else if ( r == "PERK" && f.size == 2 && member.perks.size < 32 )
                member.perks[member.perks.size] = f[1];
            else if ( r == "OFFHAND" && f.size == 4 && member.offhands.size < 16 )
                member.offhands[member.offhands.size] = zmcp_read_offhand( f );
            else if ( r == "EQUIPMENT" && f.size == 2 && !isdefined( member.equipment ) )
                member.equipment = f[1];
            else
                invalid = 1;
        }
        else if ( r == "FLAG" && f.size == 2 )
            c.flags[c.flags.size] = f[1];
        else if ( r == "MACHINE" && f.size == 2 && int( f[1] ) >= 0 && int( f[1] ) < 5 )
            c.machines[int( f[1] )] = 1;
        // ZMCP_NUKETOWN_ONLY_BEGIN
        else if ( r == "MACHINELOC" )
            zmcp_read_nuketown_location( c, f );
        // ZMCP_NUKETOWN_ONLY_END
        else if ( r == "SLOTH" && f.size == 10 && !isdefined( c.sloth ) && level.zmcp_map == "zm_buried" )
        {
            c.sloth = spawnstruct();
            c.sloth.released = int( f[1] );
            c.sloth.origin = ( float( f[2] ), float( f[3] ), float( f[4] ) );
            c.sloth.angles = ( float( f[5] ), float( f[6] ), float( f[7] ) );
            c.sloth.state = f[8];
            c.sloth.got_booze = int( f[9] );
        }
        else if ( r == "END" && f.size == 1 )
            complete = 1;
        else
            invalid = 1;
        if ( invalid )
            break;
    }
    fs_fclose( file );
    if ( invalid || !header || !complete || isdefined( member ) || !isdefined( c.host ) || !isdefined( c.round ) || c.machine_location_invalid || ( c.machine_location_seen > 0 && c.machine_location_seen != 5 ) )
        return undefined;
    if ( c.round < 1 || c.count < 2 || c.count > 4 || c.members.size != c.count || c.generation < 1 || c.generation > 2000000000 || !isdefined( zmcp_coop_member( c, c.host ) ) )
        return undefined;
    return c;
}
