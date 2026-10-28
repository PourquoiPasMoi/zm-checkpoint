#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_zonemgr;
// ZMCP_NUKETOWN_ONLY_BEGIN
#include maps\mp\zm_nuked_perks;
// ZMCP_NUKETOWN_ONLY_END

main()
{
    level.zmcp_version = 3;
    level.zmcp_map = getdvar( "mapname" );
    level.zmcp_save_file = "zm_checkpoint_" + level.zmcp_map + ".sav";
    level.zmcp_has_dvar = "zmcp_has_" + level.zmcp_map;
    level.zmcp_round_dvar = "zmcp_round_" + level.zmcp_map;
    level.zmcp_loading = 0;
    level.zmcp_busy = 0;
    level.zmcp_consumed = 0;
    level.zmcp_coop_loading = 0;
    level.zmcp_coop_ready = 0;
    level.zmcp_coop_session = 0;
    level.zmcp_selected_slot = 1;
    level.zmcp_existing = zmcp_read_checkpoint();
    for ( slot = 1; slot <= 4; slot++ )
        zmcp_solo_publish( slot, zmcp_read_checkpoint( zmcp_solo_path( slot ) ) );
    zmcp_coop_init();

    if ( !level.zmcp_coop_loading && getdvarint( "zmcp_autoload" ) )
    {
        setdvar( "zmcp_autoload", "0" );
        level.zmcp_selected_slot = zmcp_solo_slot( getdvarint( "zmcp_solo_slot" ) );
        level.zmcp_save_file = zmcp_solo_path( level.zmcp_selected_slot );
        level.zmcp_has_dvar = zmcp_solo_has_dvar( level.zmcp_selected_slot );
        level.zmcp_round_dvar = zmcp_solo_round_dvar( level.zmcp_selected_slot );
        level.zmcp_existing = zmcp_read_checkpoint();
        level.zmcp_pending = level.zmcp_existing;

        if ( isdefined( level.zmcp_pending ) )
        {
            if ( isdefined( level.zmcp_pending.settings ) && !zmcp_solo_settings_match( level.zmcp_pending.settings ) )
                level.zmcp_settings_rejected = 1;
            else
            {
                level.zmcp_loading = 1;
                replacefunc( getfunction( "maps/mp/zombies/_zm", "init_levelvars" ), ::zmcp_init_levelvars_override, -1 );

                // ZMCP_BURIED_ONLY_BEGIN
                if ( isdefined( level.zmcp_pending.quest ) )
                {
                    level.zmcp_buried_quest_restore_status = "pending";
                    level thread zmcp_restore_buried_quest_early();
                }
                // ZMCP_BURIED_ONLY_END

                // ZMCP_NUKETOWN_ONLY_BEGIN
                if ( level.zmcp_map == "zm_nuked" )
                    replacefunc( getfunction( "maps/mp/zm_nuked_perks", "perks_from_the_sky" ), ::zmcp_perks_from_the_sky_override, -1 );
                // ZMCP_NUKETOWN_ONLY_END
            }
        }
    }
}

init()
{
    setdvar( "zmcp_command", "" );
    level.zmcp_persistent_flags = [];
    level thread zmcp_collect_persistent_flags();
    level thread zmcp_command_loop();
    level thread zmcp_player_connect_loop();

    if ( isdefined( level.zmcp_settings_rejected ) )
        level thread zmcp_solo_reject_settings();

    if ( level.zmcp_coop_loading )
        level thread zmcp_coop_restore();
    else if ( level.zmcp_loading )
    {
        level thread zmcp_restore_when_ready();
        level thread zmcp_consume_on_game_end();
    }
}

zmcp_player_connect_loop()
{
    level endon( "end_game" );
    players = get_players();

    for ( i = 0; i < players.size; i++ )
        players[i] thread zmcp_start_player_threads();

    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmcp_start_player_threads();
    }
}

zmcp_start_player_threads()
{
    if ( isdefined( self.zmcp_threads_started ) )
        return;

    self.zmcp_threads_started = 1;
    if ( get_players().size > 1 )
        level.zmcp_coop_session = 1;
    if ( self ishost() && !isdefined( level.zmcp_coop_owner ) )
        level.zmcp_coop_owner = zmcp_coop_id( self );
    self thread zmcp_menu_response_loop();
    self thread zmcp_announce_after_spawn();
    self thread zmcp_zombie_counter();
}

// One numeric HUD per player: avoid repeated settext/configstring allocations.
zmcp_zombie_counter()
{
    self endon( "disconnect" );
    level endon( "end_game" );
    self.zmcp_counter_visible = 1;
    self notifyonplayercommand( "zmcp_counter_toggle", "zmcp_counter_toggle" );
    self thread zmcp_zombie_counter_toggle();
    hud = newclienthudelem( self );
    hud.horzalign = "user_left";
    hud.vertalign = "user_top";
    hud.alignx = "left";
    hud.aligny = "top";
    hud.x = 12;
    hud.y = 10;
    hud.font = "default";
    hud.fontscale = 1.6;
    hud.color = ( 0.85, 0.08, 0.05 );
    hud.glowcolor = ( 0.35, 0.05, 0.02 );
    hud.glowalpha = 0.3;
    hud.foreground = 1;
    hud.archived = 0;
    hud.alpha = 0;
    hud setvalue( 0 );
    for ( ;; )
    {
        if ( self.zmcp_counter_visible && isalive( self ) && self.sessionstate == "playing" && isdefined( level.zombie_total ) && !( level.zmcp_coop_loading && !level.zmcp_coop_ready ) )
        {
            // Stock round_wait uses these same two counters: alive + unspawned.
            remaining = get_current_zombie_count() + level.zombie_total;
            if ( remaining < 0 )
                remaining = 0;
            hud setvalue( remaining );
            hud.alpha = 0.9;
        }
        else
            hud.alpha = 0;
        wait 0.2;
    }
}

zmcp_zombie_counter_toggle()
{
    self endon( "disconnect" );
    level endon( "end_game" );
    for ( ;; )
    {
        self waittill( "zmcp_counter_toggle" );
        self.zmcp_counter_visible = !self.zmcp_counter_visible;
        wait 0.2;
    }
}

zmcp_menu_response_loop()
{
    self endon( "disconnect" );

    for ( ;; )
    {
        self waittill( "menuresponse", menu, response );

        if ( menu == "zm_checkpoint" && response == "hello_040" )
        {
            if ( !isdefined( self.zmcp_ui_compatible ) )
                println( "ZMCP COOP: UI 0.4.0 ready id=" + zmcp_coop_id( self ) + " host=" + self ishost() );
            self.zmcp_ui_compatible = 1;
        }

        if ( menu == "zm_checkpoint" && response == "save_exit" )
            level thread zmcp_save_checkpoint( self, 1 );
    }
}

zmcp_init_levelvars_override()
{
    original = getfunction( "maps/mp/zombies/_zm", "init_levelvars" );
    disabledetouronce( original );
    [[ original ]]();

    if ( !isdefined( level.zmcp_pending ) )
        return;

    level.start_round = level.zmcp_pending.round;
    level.round_number = level.zmcp_pending.round;
    level.player_starting_points = level.round_number * 500;
}

// ZMCP_NUKETOWN_ONLY_BEGIN
zmcp_perks_from_the_sky_override()
{
    level.zmcp_perks_done = 0;
    level thread maps\mp\zm_nuked_perks::turn_perks_on();
    level thread zmcp_restore_nuketown_perks();
}
// ZMCP_NUKETOWN_ONLY_END

zmcp_command_loop()
{
    level endon( "end_game" );

    for ( ;; )
    {
        command = getdvar( "zmcp_command" );

        if ( command != "" )
        {
            setdvar( "zmcp_command", "" );

            if ( command == "save" )
            {
                players = get_players();

                if ( players.size > 0 )
                    level thread zmcp_save_checkpoint( zmcp_command_player( players ), 0 );
            }
            else if ( command == "save_exit" )
            {
                players = get_players();

                if ( players.size > 0 )
                    level thread zmcp_save_checkpoint( zmcp_command_player( players ), 1 );
            }
            else if ( command == "status" )
                zmcp_show_status();
            else if ( command == "clear" )
                zmcp_clear_checkpoint();
        }

        wait 0.1;
    }
}

zmcp_announce_after_spawn()
{
    self endon( "disconnect" );
    self waittill( "spawned_player" );
    wait 2;

    if ( !level.zmcp_loading )
    {
        self iprintlnbold( "^2ZM Checkpoint ready" );
        self iprintln( "^7Open the pause menu and choose SAVE & EXIT" );
    }
}

zmcp_save_checkpoint( player, exit_after_save )
{
    if ( level.zmcp_busy )
        return;

    players = get_players();

    if ( players.size > 1 || level.zmcp_coop_session || level.zmcp_coop_loading )
    {
        zmcp_coop_save( player, exit_after_save );
        return;
    }

    if ( players.size != 1 )
    {
        if ( players.size > 0 )
            players[0] iprintlnbold( "^1Checkpoint requires exactly one player" );

        return;
    }

    if ( !isdefined( player ) || player != players[0] )
        player = players[0];

    if ( !isalive( player ) || player.sessionstate != "playing" )
    {
        player iprintlnbold( "^1Cannot save while down or spectating" );
        return;
    }

    level.zmcp_busy = 1;
    slot = zmcp_solo_slot( getdvarint( "zmcp_solo_slot" ) );
    path = zmcp_solo_path( slot );
    player freezecontrols( 1 );
    player enableinvulnerability();
    player iprintlnbold( "^3Saving checkpoint..." );
    file = fs_fopen( path, "write" );

    if ( !isdefined( file ) )
    {
        player freezecontrols( 0 );
        player disableinvulnerability();
        player iprintlnbold( "^1Checkpoint file could not be opened (FS_WRITE)" );
        println( "ZMCP: fs_fopen(write) failed for " + path + "; scr_allowFileIo=" + getdvar( "scr_allowFileIo" ) );
        level.zmcp_busy = 0;
        return;
    }

    fs_writeline( file, "CHECKPOINT," + level.zmcp_version + "," + level.zmcp_map );
    fs_writeline( file, "ROUND," + level.round_number );
    zmcp_solo_write_settings( file );
    fs_writeline( file, "PLAYER," + player.score + "," + player.health + "," + player.maxhealth + "," + player.origin[0] + "," + player.origin[1] + "," + player.origin[2] + "," + player getplayerangles()[0] + "," + player getplayerangles()[1] + "," + player getplayerangles()[2] + "," + player getcurrentweapon() );
    zmcp_write_weapons( file, player );
    zmcp_write_perks( file, player );
    zmcp_write_offhands( file, player );
    zmcp_write_equipment( file, player );
    zmcp_write_flags( file );

    // ZMCP_BURIED_ONLY_BEGIN
    zmcp_write_buried_sloth( file );
    zmcp_write_buried_quest( file );
    // ZMCP_BURIED_ONLY_END

    // ZMCP_NUKETOWN_ONLY_BEGIN
    zmcp_write_nuketown_perks( file );
    // ZMCP_NUKETOWN_ONLY_END
    fs_writeline( file, "END" );
    fs_fclose( file );
    saved_checkpoint = zmcp_read_checkpoint( path );
    player freezecontrols( 0 );

    if ( isdefined( saved_checkpoint ) && saved_checkpoint.round == level.round_number )
    {
        zmcp_solo_publish( slot, saved_checkpoint );
        player iprintlnbold( "^2Slot " + slot + " saved - round " + level.round_number );
        player iprintln( "^7Resume will appear when this map is selected." );

        if ( exit_after_save )
        {
            player iprintlnbold( "^2Returning to the lobby..." );
            wait 1.25;
            exitlevel( 0 );
            return;
        }
    }
    else
        player iprintlnbold( "^1Checkpoint write failed" );

    player disableinvulnerability();
    level.zmcp_busy = 0;
}

zmcp_write_weapons( file, player )
{
    weapons = player getweaponslistprimaries();

    for ( i = 0; i < weapons.size; i++ )
    {
        data = maps\mp\zombies\_zm_weapons::get_player_weapondata( player, weapons[i] );
        fs_writeline( file, "WEAPON," + data["name"] + "," + data["clip"] + "," + data["stock"] + "," + data["fuel"] + "," + data["heat"] + "," + data["overheat"] + "," + data["lh_clip"] + "," + data["alt_clip"] + "," + data["alt_stock"] );
    }
}

zmcp_write_perks( file, player )
{
    perks = maps\mp\zombies\_zm_perks::get_perk_array( 1 );

    for ( i = 0; i < perks.size; i++ )
    {
        if ( player hasperk( perks[i] ) )
            fs_writeline( file, "PERK," + perks[i] );
    }
}

zmcp_write_offhands( file, player )
{
    offhands = array( "frag_grenade_zm", "sticky_grenade_zm", "cymbal_monkey_zm", "emp_grenade_zm", "claymore_zm" );

    for ( i = 0; i < offhands.size; i++ )
    {
        if ( player hasweapon( offhands[i] ) )
            fs_writeline( file, "OFFHAND," + offhands[i] + "," + player getweaponammoclip( offhands[i] ) + "," + player getweaponammostock( offhands[i] ) );
    }
}

zmcp_write_equipment( file, player )
{
    equipment = player get_player_equipment();

    if ( isdefined( equipment ) )
        fs_writeline( file, "EQUIPMENT," + equipment );
}

zmcp_write_flags( file )
{
    zmcp_refresh_persistent_flags();

    for ( i = 0; i < level.zmcp_persistent_flags.size; i++ )
    {
        flag_name = level.zmcp_persistent_flags[i];

        if ( !zmcp_is_untyped_quest_flag( flag_name ) && isdefined( level.flag[flag_name] ) && flag( flag_name ) )
            fs_writeline( file, "FLAG," + flag_name );
    }
}

zmcp_is_untyped_quest_flag( flag_name )
{
    if ( level.zmcp_map != "zm_buried" )
        return 0;

    return getsubstr( flag_name, 0, 3 ) == "sq_" || getsubstr( flag_name, 0, 4 ) == "ftl_";
}

// ZMCP_BURIED_ONLY_BEGIN
zmcp_write_buried_sloth( file )
{
    if ( !isdefined( level.sloth ) || !isdefined( level.sloth.state ) )
        return;

    sloth = level.sloth;
    released = is_true( level.cell_open ) || !zmcp_sloth_is_jail_state( sloth.state );
    got_booze = is_true( sloth.got_booze );
    fs_writeline( file, "SLOTH," + released + "," + sloth.origin[0] + "," + sloth.origin[1] + "," + sloth.origin[2] + "," + sloth.angles[0] + "," + sloth.angles[1] + "," + sloth.angles[2] + "," + sloth.state + "," + got_booze );
}

zmcp_sloth_is_jail_state( state )
{
    return state == "jail_idle" || state == "jail_cower" || state == "jail_open" || state == "jail_run" || state == "jail_wait" || state == "jail_close";
}

zmcp_write_buried_quest( file )
{
    maxis_built = flag( "sq_is_max_tower_built" );
    richtofen_built = flag( "sq_is_ric_tower_built" );

    if ( maxis_built == richtofen_built )
        return;

    if ( maxis_built )
        fs_writeline( file, "QUEST,1,zm_buried,maxis,tower" );
    else
        fs_writeline( file, "QUEST,1,zm_buried,richtofen,tower" );
}
// ZMCP_BURIED_ONLY_END

// ZMCP_NUKETOWN_ONLY_BEGIN
zmcp_write_nuketown_perks( file )
{
    machines = zmcp_get_nuketown_perk_machines();

    for ( i = 0; i < machines.size; i++ )
    {
        if ( isdefined( machines[i] ) && machines[i].origin[2] < 4000 )
            fs_writeline( file, "MACHINE," + i );
    }
}
// ZMCP_NUKETOWN_ONLY_END

zmcp_read_checkpoint( path )
{
    if ( !isdefined( path ) )
        path = level.zmcp_save_file;
    if ( !fs_testfile( path ) )
        return undefined;

    file = fs_fopen( path, "read" );

    if ( !isdefined( file ) )
        return undefined;

    checkpoint = spawnstruct();
    checkpoint.version = 0;
    checkpoint.map = "";
    checkpoint.round = 1;
    checkpoint.weapons = [];
    checkpoint.perks = [];
    checkpoint.offhands = [];
    checkpoint.flags = [];
    checkpoint.machines = [];
    checkpoint.quest_seen = 0;
    checkpoint.quest_invalid = 0;
    checkpoint.settings_invalid = 0;
    checkpoint.complete = 0;

    for ( i = 0; i < 5; i++ )
        checkpoint.machines[i] = 0;

    for ( line_index = 0; line_index < 2048; line_index++ )
    {
        line = fs_readline( file );

        if ( !isdefined( line ) )
            break;

        fields = strtok( line, "," );

        if ( fields.size < 1 )
            continue;

        record = fields[0];

        if ( record == "CHECKPOINT" && fields.size >= 3 )
        {
            checkpoint.version = int( fields[1] );
            checkpoint.map = fields[2];
        }
        else if ( record == "ROUND" && fields.size >= 2 )
            checkpoint.round = int( fields[1] );
        else if ( record == "SETTINGS" )
            zmcp_solo_read_settings( checkpoint, fields );
        else if ( record == "PLAYER" && fields.size >= 11 )
        {
            checkpoint.score = int( fields[1] );
            checkpoint.health = int( fields[2] );
            checkpoint.maxhealth = int( fields[3] );
            checkpoint.origin = ( float( fields[4] ), float( fields[5] ), float( fields[6] ) );
            checkpoint.angles = ( float( fields[7] ), float( fields[8] ), float( fields[9] ) );
            checkpoint.current_weapon = fields[10];
        }
        else if ( record == "WEAPON" && fields.size >= 10 )
            checkpoint.weapons[checkpoint.weapons.size] = zmcp_read_weapon( fields );
        else if ( record == "PERK" && fields.size >= 2 )
            checkpoint.perks[checkpoint.perks.size] = fields[1];
        else if ( record == "OFFHAND" && fields.size >= 4 )
            checkpoint.offhands[checkpoint.offhands.size] = zmcp_read_offhand( fields );
        else if ( record == "EQUIPMENT" && fields.size >= 2 )
            checkpoint.equipment = fields[1];
        else if ( record == "FLAG" && fields.size >= 2 )
            checkpoint.flags[checkpoint.flags.size] = fields[1];
        else if ( record == "SLOTH" && fields.size >= 10 )
        {
            checkpoint.sloth = spawnstruct();
            checkpoint.sloth.released = int( fields[1] );
            checkpoint.sloth.origin = ( float( fields[2] ), float( fields[3] ), float( fields[4] ) );
            checkpoint.sloth.angles = ( float( fields[5] ), float( fields[6] ), float( fields[7] ) );
            checkpoint.sloth.state = fields[8];
            checkpoint.sloth.got_booze = int( fields[9] );
        }
        else if ( record == "QUEST" )
        {
            if ( checkpoint.quest_seen )
                checkpoint.quest_invalid = 1;
            else if ( fields.size != 5 )
            {
                checkpoint.quest_seen = 1;
                checkpoint.quest_invalid = 1;
            }
            else if ( int( fields[1] ) != 1 || fields[2] != "zm_buried" || ( fields[3] != "maxis" && fields[3] != "richtofen" ) || fields[4] != "tower" )
            {
                checkpoint.quest_seen = 1;
                checkpoint.quest_invalid = 1;
            }
            else
            {
                checkpoint.quest_seen = 1;
                checkpoint.quest = spawnstruct();
                checkpoint.quest.schema = 1;
                checkpoint.quest.map = fields[2];
                checkpoint.quest.branch = fields[3];
                checkpoint.quest.milestone = fields[4];
            }
        }
        else if ( record == "MACHINE" && fields.size >= 2 )
        {
            machine_index = int( fields[1] );

            if ( machine_index >= 0 && machine_index < 5 )
                checkpoint.machines[machine_index] = 1;
        }
        else if ( record == "END" )
            checkpoint.complete = 1;
    }

    fs_fclose( file );

    if ( checkpoint.quest_invalid )
        checkpoint.quest = undefined;

    if ( !checkpoint.complete || checkpoint.version != level.zmcp_version || checkpoint.map != level.zmcp_map || checkpoint.round < 1 || !isdefined( checkpoint.score ) || checkpoint.settings_invalid )
        return undefined;

    return checkpoint;
}

zmcp_read_weapon( fields )
{
    weapon = [];
    weapon["name"] = fields[1];
    weapon["clip"] = int( fields[2] );
    weapon["stock"] = int( fields[3] );
    weapon["fuel"] = int( fields[4] );
    weapon["heat"] = int( fields[5] );
    weapon["overheat"] = int( fields[6] );
    weapon["lh_clip"] = int( fields[7] );
    weapon["alt_clip"] = int( fields[8] );
    weapon["alt_stock"] = int( fields[9] );
    return weapon;
}

zmcp_read_offhand( fields )
{
    offhand = spawnstruct();
    offhand.name = fields[1];
    offhand.clip = int( fields[2] );
    offhand.stock = int( fields[3] );
    return offhand;
}

zmcp_restore_when_ready()
{
    level endon( "end_game" );
    flag_wait( "initial_blackscreen_passed" );

    while ( get_players().size != 1 )
        wait 0.1;

    player = get_players()[0];

    while ( player.sessionstate != "playing" || !isalive( player ) )
        wait 0.1;

    level.zmcp_busy = 1;
    player freezecontrols( 1 );
    player enableinvulnerability();
    player iprintlnbold( "^3Restoring round " + level.zmcp_pending.round + "..." );
    zmcp_restore_blockers( player );

    // ZMCP_BURIED_ONLY_BEGIN
    if ( isdefined( level.zmcp_pending.quest ) )
    {
        while ( !isdefined( level.zmcp_buried_quest_restore_status ) || level.zmcp_buried_quest_restore_status == "pending" )
            wait 0.1;

        if ( level.zmcp_buried_quest_restore_status != "complete" )
        {
            player freezecontrols( 0 );
            player disableinvulnerability();
            player iprintlnbold( "^1Quest restore could not finish; checkpoint kept" );
            println( "ZMCP: map=zm_buried adapter=1 phase=world milestone=tower failed; checkpoint remains valid" );
            level.zmcp_busy = 0;
            return;
        }
    }

    zmcp_restore_buried_sloth();
    // ZMCP_BURIED_ONLY_END

    wait 1.5;
    zmcp_restore_player( player );
    wait 0.5;
    player setorigin( level.zmcp_pending.origin );
    player setplayerangles( level.zmcp_pending.angles );
    zmcp_consume_checkpoint();
    player freezecontrols( 0 );
    player disableinvulnerability();
    level.zmcp_busy = 0;
    player iprintlnbold( "^2Checkpoint restored" );
    player iprintln( "^7Round restarted with your saved inventory and world progress." );
    player iprintln( "^7This checkpoint was consumed. SAVE & EXIT creates the next one." );
}

zmcp_consume_on_game_end()
{
    level waittill_any( "pre_end_game", "end_game" );
    zmcp_consume_checkpoint();
}

zmcp_consume_checkpoint()
{
    if ( level.zmcp_consumed )
        return;

    level.zmcp_consumed = 1;
    file = fs_fopen( level.zmcp_save_file, "write" );

    if ( isdefined( file ) )
    {
        fs_writeline( file, "CONSUMED" );
        fs_fclose( file );
    }
    else
        println( "ZMCP: could not invalidate consumed checkpoint " + level.zmcp_save_file );

    cmdexec( "seta " + level.zmcp_has_dvar + " 0" );
    cmdexec( "seta " + level.zmcp_round_dvar + " 0" );
    zmcp_solo_publish( level.zmcp_selected_slot, undefined );
    level.zmcp_existing = undefined;
}

zmcp_restore_player( player, checkpoint )
{
    if ( !isdefined( checkpoint ) )
        checkpoint = level.zmcp_pending;
    player takeallweapons();

    for ( i = 0; i < checkpoint.weapons.size; i++ )
        player maps\mp\zombies\_zm_weapons::weapondata_give( checkpoint.weapons[i] );

    player giveweapon( "knife_zm" );

    for ( i = 0; i < checkpoint.offhands.size; i++ )
    {
        offhand = checkpoint.offhands[i];
        player giveweapon( offhand.name );
        player setweaponammoclip( offhand.name, offhand.clip );
        player setweaponammostock( offhand.name, offhand.stock );

        if ( offhand.name == "claymore_zm" )
        {
            player set_player_placeable_mine( "claymore_zm" );
            player setactionslot( 4, "weapon", "claymore_zm" );
        }
    }

    if ( isdefined( checkpoint.equipment ) )
        player maps\mp\zombies\_zm_equipment::equipment_give( checkpoint.equipment );

    for ( i = 0; i < checkpoint.perks.size; i++ )
    {
        if ( !player hasperk( checkpoint.perks[i] ) )
            player maps\mp\zombies\_zm_perks::give_perk( checkpoint.perks[i], 0 );
    }

    player.score = checkpoint.score;
    player.pers["score"] = checkpoint.score;

    if ( checkpoint.health > player.maxhealth )
        player.health = player.maxhealth;
    else if ( checkpoint.health < 1 )
        player.health = 1;
    else
        player.health = checkpoint.health;

    if ( player hasweapon( checkpoint.current_weapon ) )
        player switchtoweapon( checkpoint.current_weapon );
}

zmcp_collect_persistent_flags()
{
    flag_wait( "zones_initialized" );
    zmcp_refresh_persistent_flags();
}

zmcp_refresh_persistent_flags()
{
    entities = getentarray();

    for ( i = 0; i < entities.size; i++ )
        zmcp_add_entity_flags( entities[i] );

    // ZMCP_BURIED_ONLY_BEGIN
    zmcp_add_named_flag( "courtyard_fountain_broken" );
    zmcp_add_named_flag( "maze_fountain_broken" );
    // ZMCP_BURIED_ONLY_END

    if ( isdefined( level.flag["power_on"] ) )
        level.zmcp_persistent_flags = add_to_array( level.zmcp_persistent_flags, "power_on", 0 );
}

zmcp_add_named_flag( flag_name )
{
    if ( isdefined( level.flag[flag_name] ) )
        level.zmcp_persistent_flags = add_to_array( level.zmcp_persistent_flags, flag_name, 0 );
}

zmcp_add_entity_flags( ent )
{
    if ( !isdefined( ent ) || !isdefined( ent.script_flag ) )
        return;

    names = strtok( ent.script_flag, "," );

    for ( i = 0; i < names.size; i++ )
        level.zmcp_persistent_flags = add_to_array( level.zmcp_persistent_flags, names[i], 0 );
}

zmcp_restore_blockers( player )
{
    doors = getentarray( "zombie_door", "targetname" );
    debris = getentarray( "zombie_debris", "targetname" );
    processed_targets = [];

    for ( i = 0; i < doors.size; i++ )
    {
        if ( isdefined( doors[i] ) && zmcp_entity_has_saved_flag( doors[i] ) && !isinarray( processed_targets, doors[i].target ) )
        {
            processed_targets = add_to_array( processed_targets, doors[i].target, 0 );

            if ( !isdefined( doors[i]._door_open ) || !doors[i]._door_open )
                doors[i] notify( "trigger", player, 1 );
        }
    }

    for ( i = 0; i < debris.size; i++ )
    {
        if ( isdefined( debris[i] ) && zmcp_entity_has_saved_flag( debris[i] ) && !isinarray( processed_targets, debris[i].target ) )
        {
            processed_targets = add_to_array( processed_targets, debris[i].target, 0 );
            debris[i] notify( "trigger", player, 1 );
        }
    }

    zmcp_restore_map_entities( player );

    wait 0.5;

    for ( i = 0; i < level.zmcp_pending.flags.size; i++ )
    {
        flag_name = level.zmcp_pending.flags[i];

        if ( !zmcp_is_untyped_quest_flag( flag_name ) && isdefined( level.flag[flag_name] ) )
            flag_set( flag_name );
    }
}

zmcp_restore_map_entities( player )
{
    // ZMCP_TRANSIT_ONLY_BEGIN
    vault_doors = getentarray( "town_bunker_door", "targetname" );

    for ( i = 0; i < vault_doors.size; i++ )
    {
        door = vault_doors[i];

        if ( !isdefined( door ) || !zmcp_entity_has_saved_flag( door ) )
            continue;

        if ( isdefined( door.damage_state ) && door.damage_state )
            continue;

        door notify( "damage", 100, player, ( 0, 0, 0 ), door.origin, "MOD_EXPLOSIVE", "", "", "", "frag_grenade_zm" );
    }
    // ZMCP_TRANSIT_ONLY_END

    // ZMCP_BURIED_ONLY_BEGIN
    holes = getentarray( "hole_breakthrough", "targetname" );

    for ( i = 0; i < holes.size; i++ )
    {
        if ( isdefined( holes[i] ) && zmcp_entity_has_saved_flag( holes[i] ) )
            holes[i] notify( "trigger", player );
    }

    barriers = getentarray( "sloth_barricade", "targetname" );

    for ( i = 0; i < barriers.size; i++ )
    {
        barrier = barriers[i];

        if ( !isdefined( barrier ) || !zmcp_entity_has_saved_flag( barrier ) )
            continue;

        pieces = getentarray( barrier.target, "targetname" );
        should_delete = !isdefined( barrier.script_string ) || barrier.script_string != "no_delete";

        for ( j = 0; j < pieces.size; j++ )
        {
            if ( should_delete )
                pieces[j] delete();
            else
            {
                pieces[j] notsolid();
                pieces[j] ghost();

                if ( isdefined( pieces[j].script_noteworthy ) && pieces[j].script_noteworthy == "clip" )
                    pieces[j] connectpaths();
            }
        }

        if ( barrier.script_flag == "jail_door1" )
            level notify( "jail_barricade_down" );

        if ( should_delete )
            barrier delete();
        else
        {
            barrier notsolid();
            barrier ghost();
        }
    }

    if ( isinarray( level.zmcp_pending.flags, "courtyard_fountain_broken" ) )
        level notify( "courtyard_fountain_open" );

    if ( isinarray( level.zmcp_pending.flags, "maze_fountain_broken" ) )
    {
        maze_fountain = getent( "maze_fountain_trigger", "targetname" );

        if ( isdefined( maze_fountain ) )
            maze_fountain notify( "damage", 1000, player, ( 0, 0, 0 ), maze_fountain.origin, "MOD_EXPLOSIVE", "", "", "", "frag_grenade_zm", 0 );
    }
    // ZMCP_BURIED_ONLY_END
}

// ZMCP_BURIED_ONLY_BEGIN
zmcp_restore_buried_quest_early()
{
    quest = level.zmcp_pending.quest;

    if ( quest.schema != 1 || quest.map != "zm_buried" || quest.milestone != "tower" || ( quest.branch != "maxis" && quest.branch != "richtofen" ) )
    {
        println( "ZMCP: map=zm_buried adapter=1 phase=world rejected malformed quest state" );
        level.zmcp_buried_quest_restore_status = "complete";
        return;
    }

    for ( i = 0; i < 600; i++ )
    {
        if ( zmcp_buried_tower_data_ready() )
            break;

        wait 0.1;
    }

    if ( !zmcp_buried_tower_data_ready() )
    {
        println( "ZMCP: map=zm_buried adapter=1 phase=world milestone=tower failed; buildables were unavailable" );
        level.zmcp_buried_quest_restore_status = "failed";
        return;
    }

    if ( flag( "start_zombie_round_logic" ) )
    {
        println( "ZMCP: map=zm_buried adapter=1 phase=early milestone=tower failed; round logic already started" );
        level.zmcp_buried_quest_restore_status = "failed";
        return;
    }

    wait_network_frame();

    if ( flag( "start_zombie_round_logic" ) )
    {
        println( "ZMCP: map=zm_buried adapter=1 phase=early milestone=tower failed; round logic started during world setup" );
        level.zmcp_buried_quest_restore_status = "failed";
        return;
    }

    if ( quest.branch == "maxis" )
    {
        maps\mp\zm_buried_sq::playfx_on_tower( "sq_tower_bolts" );
        maps\mp\zm_buried_sq::playfx_on_tower( "sq_tower_m" );
        model_names = array( "p6_zm_bu_sq_vaccume_tube", "p6_zm_bu_sq_buildable_battery" );
        maps\mp\zm_buried_sq::sq_delete_tower_pieces( model_names, level.sq_mtower_buildable.buildablezone.pieces );
    }
    else
    {
        maps\mp\zm_buried_sq::playfx_on_tower( "sq_tower_bolts" );
        maps\mp\zm_buried_sq::playfx_on_tower( "sq_tower_r" );
        model_names = array( "p6_zm_bu_sq_crystal", "p6_zm_bu_sq_satellite_dish" );
        maps\mp\zm_buried_sq::sq_delete_tower_pieces( model_names, level.sq_rtower_buildable.buildablezone.pieces );
    }

    println( "ZMCP: map=zm_buried adapter=1 phase=world replayed branch=" + quest.branch + " milestone=tower side-effects" );
    level thread zmcp_buried_signal_saved_tower( quest.branch );
}

zmcp_buried_signal_saved_tower( branch )
{
    level endon( "end_game" );
    stage_started = 0;

    for ( i = 0; i < 600; i++ )
    {
        if ( isdefined( level._last_stage_started ) && level._last_stage_started == "bt" )
        {
            stage_started = 1;
            break;
        }

        wait 0.1;
    }

    if ( !stage_started )
    {
        println( "ZMCP: map=zm_buried adapter=1 phase=early milestone=tower failed; stock bt stage did not start" );
        level.zmcp_buried_quest_restore_status = "failed";
        return;
    }

    wait 0.25;
    players = get_players();

    if ( players.size != 1 )
    {
        println( "ZMCP: map=zm_buried adapter=1 phase=early milestone=tower failed; solo player unavailable" );
        level.zmcp_buried_quest_restore_status = "failed";
        return;
    }

    if ( branch == "maxis" )
        level notify( "buried_sq_bt_m_tower_built", players[0] );
    else
        level notify( "buried_sq_bt_r_tower_built", players[0] );

    for ( i = 0; i < 50; i++ )
    {
        if ( ( branch == "maxis" && flag( "sq_is_max_tower_built" ) ) || ( branch == "richtofen" && flag( "sq_is_ric_tower_built" ) ) )
        {
            println( "ZMCP: map=zm_buried adapter=1 phase=world restored branch=" + branch + " milestone=tower" );
            level.zmcp_buried_quest_restore_status = "complete";
            return;
        }

        wait 0.1;
    }

    println( "ZMCP: map=zm_buried adapter=1 phase=world failed; stock tower completion signal was not observed" );
    level.zmcp_buried_quest_restore_status = "failed";
}

zmcp_buried_tower_data_ready()
{
    if ( !isdefined( level.sq_mtower_buildable ) || !isdefined( level.sq_rtower_buildable ) || !isdefined( level.flag ) )
        return 0;

    if ( !isdefined( level.sq_mtower_buildable.buildablezone ) || !isdefined( level.sq_rtower_buildable.buildablezone ) )
        return 0;

    if ( !isdefined( level.sq_mtower_buildable.buildablezone.pieces ) || !isdefined( level.sq_rtower_buildable.buildablezone.pieces ) )
        return 0;

    return isdefined( level.flag["sq_is_max_tower_built"] ) && isdefined( level.flag["sq_is_ric_tower_built"] );
}

zmcp_restore_buried_sloth()
{
    if ( !isdefined( level.zmcp_pending.sloth ) || !level.zmcp_pending.sloth.released )
        return;

    for ( attempts = 0; attempts < 100; attempts++ )
    {
        if ( isdefined( level.sloth ) && isdefined( level.sloth.state ) )
            break;

        wait 0.1;
    }

    if ( !isdefined( level.sloth ) || !isdefined( level.sloth.state ) )
    {
        println( "ZMCP: Buried sloth restore skipped because Arthur did not spawn" );
        return;
    }

    sloth = level.sloth;
    level.cell_open = 1;
    sloth.open_jail = 0;
    sloth.got_booze = level.zmcp_pending.sloth.got_booze;

    if ( sloth.got_booze )
        level.sloth_has_been_given_booze = 1;

    sloth forceteleport( level.zmcp_pending.sloth.origin, level.zmcp_pending.sloth.angles );
    sloth maps\mp\zombies\_zm_ai_sloth::sloth_set_state( "roam" );
    level notify( "cell_open" );
    println( "ZMCP: restored Arthur from saved state " + level.zmcp_pending.sloth.state + " as stable roam" );
}
// ZMCP_BURIED_ONLY_END

zmcp_entity_has_saved_flag( ent )
{
    if ( !isdefined( ent.script_flag ) )
        return 0;

    names = strtok( ent.script_flag, "," );

    for ( i = 0; i < names.size; i++ )
    {
        if ( isinarray( level.zmcp_pending.flags, names[i] ) )
            return 1;
    }

    return 0;
}

// ZMCP_NUKETOWN_ONLY_BEGIN
zmcp_get_nuketown_perk_machines()
{
    machines = [];
    machines[0] = getent( "vending_revive", "targetname" );
    machines[1] = getent( "vending_doubletap", "targetname" );
    machines[2] = getent( "vending_sleight", "targetname" );
    machines[3] = getent( "vending_jugg", "targetname" );
    pap_trigger = getent( "specialty_weapupgrade", "script_noteworthy" );

    if ( isdefined( pap_trigger ) )
        machines[4] = getent( pap_trigger.target, "targetname" );

    return machines;
}

zmcp_prepare_nuketown_perks()
{
    level.zmcp_perk_machines = zmcp_get_nuketown_perk_machines();
    level.zmcp_perk_triggers = [];
    level.zmcp_perk_triggers[0] = getent( "vending_revive", "target" );
    level.zmcp_perk_triggers[1] = getent( "vending_doubletap", "target" );
    level.zmcp_perk_triggers[2] = getent( "vending_sleight", "target" );
    level.zmcp_perk_triggers[3] = getent( "vending_jugg", "target" );
    level.zmcp_perk_triggers[4] = getent( "specialty_weapupgrade", "script_noteworthy" );
}

zmcp_restore_nuketown_perks()
{
    level endon( "end_game" );
    zmcp_prepare_nuketown_perks();
    machines = level.zmcp_perk_machines;
    triggers = level.zmcp_perk_triggers;

    for ( i = 0; i < machines.size; i++ )
    {
        if ( !isdefined( machines[i] ) || !isdefined( triggers[i] ) )
            continue;

        maps\mp\zm_nuked_perks::move_perk( machines[i], 8000, 5.0, 0.001 );
        triggers[i] trigger_off();
    }

    flag_wait( "initial_blackscreen_passed" );
    wait 5.1;
    remaining_machines = [];
    remaining_triggers = [];
    restored_count = 0;

    for ( i = 0; i < machines.size; i++ )
    {
        if ( level.zmcp_pending.machines[i] )
        {
            maps\mp\zm_nuked_perks::bring_perk( machines[i], triggers[i] );
            restored_count++;
        }
        else
        {
            remaining_machines[remaining_machines.size] = machines[i];
            remaining_triggers[remaining_triggers.size] = triggers[i];
        }
    }

    level.zmcp_perks_done = 1;
    level thread zmcp_continue_perk_schedule( remaining_machines, remaining_triggers, restored_count );
}

zmcp_continue_perk_schedule( machines, triggers, count )
{
    level endon( "end_game" );

    if ( count == 0 && machines.size > 0 )
    {
        wait 4;
        maps\mp\zm_nuked_perks::bring_perk( machines[0], triggers[0] );
        arrayremoveindex( machines, 0 );
        arrayremoveindex( triggers, 0 );
        count = 1;
    }

    while ( count < 5 && machines.size > 0 )
    {
        if ( count == 1 )
            maps\mp\zm_nuked_perks::wait_for_round_range( 3, 5 );
        else if ( count == 2 )
            maps\mp\zm_nuked_perks::wait_for_round_range( 6, 9 );
        else if ( count == 3 )
            maps\mp\zm_nuked_perks::wait_for_round_range( 10, 14 );
        else
            maps\mp\zm_nuked_perks::wait_for_round_range( 15, 19 );

        wait( randomintrange( 30, 60 ) );
        maps\mp\zm_nuked_perks::bring_random_perk( machines, triggers );
        count++;
    }
}
// ZMCP_NUKETOWN_ONLY_END

zmcp_show_status()
{
    players = get_players();

    if ( players.size < 1 )
        return;

    slot = zmcp_solo_slot( getdvarint( "zmcp_solo_slot" ) );
    checkpoint = zmcp_read_checkpoint( zmcp_solo_path( slot ) );

    if ( !isdefined( checkpoint ) )
        players[0] iprintlnbold( "^1No valid checkpoint" );
    else
        players[0] iprintlnbold( "^2Saved slot " + slot + ": " + level.zmcp_map + " round " + checkpoint.round );
}

zmcp_clear_checkpoint()
{
    players = get_players();
    slot = zmcp_solo_slot( getdvarint( "zmcp_solo_slot" ) );
    file = fs_fopen( zmcp_solo_path( slot ), "write" );

    if ( isdefined( file ) )
    {
        fs_writeline( file, "EMPTY" );
        fs_fclose( file );
    }

    zmcp_solo_publish( slot, undefined );

    if ( players.size > 0 )
        players[0] iprintlnbold( "^3Checkpoint cleared" );
}

