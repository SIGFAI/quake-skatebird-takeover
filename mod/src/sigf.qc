// SkateBIRD Takeover: little shred birds on skateboards replace the soldiers, dogs, knights and
// enforcers; big boss birds replace the ogres. They roll fast, ram, and kickflip through the air.
// Killing birds quickly chains a trick combo with points.

.float sigf_combo;
.float sigf_combo_time;
.float sigf_score;
.float sigf_air;          // pitch of the flip in progress

void() bird_run1;
void() bird_flip_touch;

// ---------- feathers and tricks ----------
void(vector org, float n) bird_feathers =
{
    particle(org, '0 0 40', 208, n);        // blue feathers
    particle(org, '0 0 25', 14, n);         // cream belly feathers
    particle(org, '0 0 60', 79, n / 2);     // red cap bits
};

string(float n) sigf_trick_name =
{
    if (n == 1) return "OLLIE!";
    if (n == 2) return "KICKFLIP!";
    if (n == 3) return "HEELFLIP!";
    if (n == 4) return "360 SHOVE-IT!";
    if (n == 5) return "INDY GRAB!";
    if (n == 6) return "MCTWIST!";
    return "BIRDMAN 900!!";
};

// ---------- golden feather: dropped by dead birds ----------
void() sigf_feather_touch =
{
    if (other.classname != "player")
        return;
    T_Heal(other, 10, 0);
    other.sigf_score = other.sigf_score + 50;
    sound(other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
    sprint(other, "Golden Feather! +50 trick points\n");
    stuffcmd(other, "bf\n");
    particle(self.origin, '0 0 40', 192, 20);
    remove(self);
};

void(vector org, float n) sigf_drop_feather =
{
    local entity o;
    o = spawn();
    o.classname = "sigf_feather";
    o.movetype = MOVETYPE_TOSS;
    o.solid = SOLID_TRIGGER;
    setmodel(o, "progs/sigf_feather.spr");
    setsize(o, '-14 -14 0', '14 14 24');
    setorigin(o, org + '0 0 16');
    o.velocity_x = crandom() * 120;
    o.velocity_y = crandom() * 120;
    o.velocity_z = 250 + n * 20;
    o.effects = EF_DIMLIGHT;
    o.touch = sigf_feather_touch;
    o.nextthink = time + 30;
    o.think = SUB_Remove;
};

// ---------- animation ----------
void() bird_stand1 = [0, bird_stand2] { ai_stand(); };
void() bird_stand2 = [1, bird_stand1] { ai_stand(); };

void() bird_walk1 = [2, bird_walk2] { ai_walk(8); };
void() bird_walk2 = [3, bird_walk3] { ai_walk(8); };
void() bird_walk3 = [4, bird_walk4] { ai_walk(8); };
void() bird_walk4 = [5, bird_walk1] { ai_walk(8); };

void() bird_run1 = [2, bird_run2] { ai_run(22); if (random() < 0.05) sound(self, CHAN_VOICE, "sigf/trick.wav", 0.5, ATTN_IDLE); };
void() bird_run2 = [3, bird_run3] { ai_run(22); };
void() bird_run3 = [4, bird_run4] { ai_run(22); };
void() bird_run4 = [5, bird_run1] { ai_run(22); };

// ram: shoulder-check with the board
void() bird_ram_hit =
{
    local float dmg;
    if (!self.enemy)
        return;
    ai_face();
    if (!CanDamage(self.enemy, self))
        return;
    if (vlen(self.enemy.origin - self.origin) > 90)
        return;
    dmg = 8 + 6 * random();
    if (self.classname == "monster_sigf_bigbird")
        dmg = dmg * 2;
    T_Damage(self.enemy, self, self, dmg);
    sound(self, CHAN_WEAPON, "sigf/trick.wav", 1, ATTN_NORM);
};

void() bird_atk1 = [6, bird_atk2] { ai_charge(10); };
void() bird_atk2 = [7, bird_atk3] { ai_charge(14); };
void() bird_atk3 = [8, bird_atk4] { ai_charge(16); bird_ram_hit(); };
void() bird_atk4 = [9, bird_run1] { ai_charge(10); };

// kickflip leap: jumps at the player spinning in the air
void() bird_air1 = [8, bird_air2] { self.sigf_air = self.sigf_air + 90; self.angles_x = self.sigf_air; };
void() bird_air2 = [9, bird_air3] { self.sigf_air = self.sigf_air + 90; self.angles_x = self.sigf_air; };
void() bird_air3 = [8, bird_air4] { self.sigf_air = self.sigf_air + 90; self.angles_x = self.sigf_air; };
void() bird_air4 = [9, bird_air5] { self.sigf_air = self.sigf_air + 90; self.angles_x = self.sigf_air; };
void() bird_air5 = [8, bird_air6] { self.sigf_air = self.sigf_air + 90; self.angles_x = self.sigf_air; };
void() bird_air6 = [9, bird_air7] { self.sigf_air = self.sigf_air + 90; self.angles_x = self.sigf_air; };
void() bird_air7 = [8, bird_air8] { self.sigf_air = self.sigf_air + 90; self.angles_x = self.sigf_air; };
void() bird_air8 = [9, bird_air1] { self.sigf_air = 0; self.angles_x = 0; self.nextthink = time + 2; };   // stuck in the air for 2 s: tries again

void() bird_land1 = [6, bird_land2] { self.angles_x = 0; self.sigf_air = 0; };
void() bird_land2 = [7, bird_run1] { ai_charge(6); };

void() bird_flip_touch =
{
    local float dmg;
    if (self.health <= 0)
        return;
    if (other.takedamage && other != self)
    {
        if (vlen(self.velocity) > 300)
        {
            dmg = 12 + 8 * random();
            if (self.classname == "monster_sigf_bigbird")
                dmg = dmg * 2;
            T_Damage(other, self, self, dmg);
            sound(self, CHAN_WEAPON, "sigf/trick.wav", 1, ATTN_NORM);
        }
    }
    if (!(self.flags & FL_ONGROUND))
        return;
    self.touch = SUB_Null;
    self.think = bird_land1;
    self.nextthink = time + 0.1;
};

void() bird_flip_start =
{
    ai_face();
    sound(self, CHAN_VOICE, "sigf/trick.wav", 1, ATTN_NORM);
    self.touch = bird_flip_touch;
    makevectors(self.angles);
    self.origin_z = self.origin_z + 1;
    self.velocity = v_forward * 520 + '0 0 260';
    if (self.flags & FL_ONGROUND)
        self.flags = self.flags - FL_ONGROUND;
    self.sigf_air = 0;
};

void() bird_jump1 = [6, bird_jump2] { ai_face(); };
void() bird_jump2 = [7, bird_air1] { bird_flip_start(); };

void() bird_pain1 = [10, bird_pain2] { };
void() bird_pain2 = [11, bird_pain3] { ai_back(4); };
void() bird_pain3 = [10, bird_run1] { };

void(entity attacker, float damage) bird_pain =
{
    if (self.touch == bird_flip_touch)
        return;
    if (self.pain_finished > time)
        return;
    self.pain_finished = time + 0.8;
    sound(self, CHAN_VOICE, "sigf/tweet.wav", 1, ATTN_NORM);
    bird_feathers(self.origin + '0 0 20', 6);
    bird_pain1();
};

void() bird_die1 = [12, bird_die2] { };
void() bird_die2 = [13, bird_die3] { self.solid = SOLID_NOT; };
void() bird_die3 = [14, bird_die4] { };
void() bird_die4 = [15, bird_die5] { };
void() bird_die5 = [16, bird_die5] { };

void() bird_die =
{
    self.angles_x = 0;
    self.touch = SUB_Null;
    sound(self, CHAN_VOICE, "sigf/squawk.wav", 1, ATTN_NORM);
    bird_feathers(self.origin + '0 0 24', 40);
    if (self.health < -30)
    {
        ThrowGib("progs/gib1.mdl", self.health);
        ThrowGib("progs/gib2.mdl", self.health);
        bird_feathers(self.origin + '0 0 24', 60);
        ThrowHead("progs/gib3.mdl", self.health);
        return;
    }
    bird_die1();
};

void() bird_setup =
{
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    self.th_stand = bird_stand1;
    self.th_walk = bird_walk1;
    self.th_run = bird_run1;
    self.th_melee = bird_atk1;
    self.th_missile = bird_jump1;
    self.th_pain = bird_pain;
    self.th_die = bird_die;
};

void() monster_sigf_bird =
{
    if (deathmatch)
    {
        remove(self);
        return;
    }
    precache_model("progs/sigf_bird.mdl");
    precache_model("progs/gib1.mdl");
    precache_model("progs/gib2.mdl");
    precache_model("progs/gib3.mdl");
    precache_sound("sigf/squawk.wav");
    precache_sound("sigf/trick.wav");
    precache_sound("sigf/tweet.wav");
    self.classname = "monster_sigf_bird";
    setmodel(self, "progs/sigf_bird.mdl");
    setsize(self, '-16 -16 -24', '16 16 24');
    self.health = 70;
    bird_setup();
    walkmonster_start();
};

void() monster_sigf_bigbird =
{
    if (deathmatch)
    {
        remove(self);
        return;
    }
    precache_model("progs/sigf_bigbird.mdl");
    precache_model("progs/gib1.mdl");
    precache_model("progs/gib2.mdl");
    precache_model("progs/gib3.mdl");
    precache_sound("sigf/squawk.wav");
    precache_sound("sigf/trick.wav");
    precache_sound("sigf/tweet.wav");
    self.classname = "monster_sigf_bigbird";
    setmodel(self, "progs/sigf_bigbird.mdl");
    setsize(self, '-28 -28 -24', '28 28 52');
    self.health = 200;
    bird_setup();
    walkmonster_start();
};

// ---------- hooks ----------
void() SIGF_Precache =
{
    precache_model("progs/sigf_feather.spr");
    precache_sound("weapons/lock4.wav");
    SIGF_Preload("monster_sigf_bird", monster_sigf_bird);
    SIGF_Preload("monster_sigf_bigbird", monster_sigf_bigbird);
    cvar_set("sv_friction", "2");        // the player slides like on a board
    cvar_set("sv_gravity", "650");
};

void(float wave) SIGF_DemoWave =
{
    if (wave == 0)
    {
        self.items = self.items | IT_SUPER_SHOTGUN | IT_NAILGUN | IT_SUPER_NAILGUN | IT_ROCKET_LAUNCHER;
        self.weapon = IT_SUPER_NAILGUN;
        W_SetCurrentAmmo();
        centerprint(self, "SkateBIRDs have taken over!");
        SIGF_SpawnAhead("monster_sigf_bird", monster_sigf_bird, 300, -60);
        SIGF_SpawnAhead("monster_sigf_bird", monster_sigf_bird, 340, 60);
        SIGF_SpawnAhead("monster_sigf_bird", monster_sigf_bird, 420, 0);
        return;
    }
    SIGF_SpawnAhead("monster_sigf_bird", monster_sigf_bird, 300, -70);
    SIGF_SpawnAhead("monster_sigf_bird", monster_sigf_bird, 360, 70);
    SIGF_SpawnAhead("monster_sigf_bird", monster_sigf_bird, 440, 0);
    if (wave == 2 || wave == 5 || wave == 8)
        SIGF_SpawnAhead("monster_sigf_bigbird", monster_sigf_bigbird, 520, 0);
};

void(entity targ, entity attacker) SIGF_OnKilled =
{
    local float pts;
    if (!(targ.flags & FL_MONSTER))
        return;
    sigf_drop_feather(targ.origin, 0);
    if (targ.classname == "monster_sigf_bigbird")
    {
        sigf_drop_feather(targ.origin, 1);
        sigf_drop_feather(targ.origin, 2);
    }
    if (attacker.classname != "player")
        return;
    if (time < attacker.sigf_combo_time)
        attacker.sigf_combo = attacker.sigf_combo + 1;
    else
        attacker.sigf_combo = 1;
    attacker.sigf_combo_time = time + 4;
    pts = 100 * attacker.sigf_combo;
    attacker.sigf_score = attacker.sigf_score + pts;
    centerprint(attacker, sigf_trick_name(attacker.sigf_combo), "\ncombo x", ftos(attacker.sigf_combo), "  +", ftos(pts), "\nScore ", ftos(attacker.sigf_score));
};
