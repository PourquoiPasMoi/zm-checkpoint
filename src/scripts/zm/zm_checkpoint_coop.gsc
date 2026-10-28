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

zmcp_coop_base()
{
    return "zm_checkpoint_coop_" + level.zmcp_map;
}

zmcp_coop_init()
{
    level.zmcp_coop = zmcp_coop_latest();
    zmcp_coop_publish();
    if ( !getdvarint( "zmcp_coop_autoload" ) )
        return;
    setdvar( "zmcp_coop_autoload", "0" );
    setdvar( "zmcp_autoload", "0" );
    // An invalid request must fail closed, not start a fresh playable match.
    level.zmcp_coop_loading = 1;
    level.zmcp_loading = 1;
    level.zmcp_busy = 1;
    replacefunc( getfunction( "maps/mp/zombies/_zm", "round_think" ), ::zmcp_coop_round_gate, -1 );
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

zmcp_coop_latest()
{
    a = zmcp_coop_read( zmcp_coop_base() + "_a.sav" );
    b = zmcp_coop_read( zmcp_coop_base() + "_b.sav" );
    if ( !isdefined( a ) )
        return b;
    if ( !isdefined( b ) || a.generation > b.generation )
        return a;
    return b;
}

zmcp_coop_used( checkpoint )
{
    path = zmcp_coop_base() + "_used.sav";
    if ( !fs_testfile( path ) )
        return 0;
    file = fs_fopen( path, "read" );
    if ( !isdefined( file ) )
        return 1;
    line = fs_readline( file );
    ending = fs_readline( file );
    fs_fclose( file );
    // A damaged receipt is uncertain: do not allow an already used generation.
    if ( !isdefined( line ) || !isdefined( ending ) || ending != "END" )
        return 1;
    fields = strtok( line, "," );
    if ( fields.size != 2 || fields[0] != "USED" )
        return 1;
    return int( fields[1] ) >= checkpoint.generation;
}

zmcp_coop_publish()
{
    prefix = "zmcp_coop_" + level.zmcp_map + "_";
    checkpoint = level.zmcp_coop;
    cmdexec( "seta " + prefix + "has 0" );
    if ( !isdefined( checkpoint ) || zmcp_coop_used( checkpoint ) )
        return;
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
    cmdexec( "seta " + prefix + "has 1" );
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
    previous = zmcp_coop_latest();
    generation = 1;
    target = zmcp_coop_base() + "_a.sav";
    if ( isdefined( previous ) )
    {
        generation = previous.generation + 1;
        if ( previous.path == target )
            target = zmcp_coop_base() + "_b.sav";
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
        level.zmcp_coop = saved;
        level.zmcp_coop_owner = saved.host;
        zmcp_coop_publish();
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
    receipt = fs_fopen( zmcp_coop_base() + "_used.sav", "write" );
    if ( !isdefined( receipt ) )
    {
        zmcp_coop_abort( "could not commit consumption receipt" );
        return;
    }
    fs_writeline( receipt, "USED," + checkpoint.generation );
    fs_writeline( receipt, "END" );
    fs_fclose( receipt );
    // Validate exact receipt, not the fail-closed 'used' result for damaged I/O.
    receipt = fs_fopen( zmcp_coop_base() + "_used.sav", "read" );
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
    zmcp_coop_publish();
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
    c.members = [];
    for ( i = 0; i < 5; i++ )
        c.machines[i] = 0;
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
    if ( invalid || !header || !complete || isdefined( member ) || !isdefined( c.host ) || !isdefined( c.round ) )
        return undefined;
    if ( c.round < 1 || c.count < 2 || c.count > 4 || c.members.size != c.count || c.generation < 1 || c.generation > 2000000000 || !isdefined( zmcp_coop_member( c, c.host ) ) )
        return undefined;
    return c;
}
