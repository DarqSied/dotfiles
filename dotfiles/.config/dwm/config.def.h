/* See LICENSE file for copyright and license details. */
#define Terminal "alacritty"
#define Termclass "Alacritty"
#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx       = 0;   /* border pixel of windows */
static const unsigned int snap           = 32;  /* snap pixel */
static const unsigned int gappih         = 5;   /* horiz inner gap between windows */
static const unsigned int gappiv         = 5;   /* vert inner gap between windows */
static const unsigned int gappoh         = 5;   /* horiz outer gap between windows and screen edge */
static const unsigned int gappov         = 5;   /* vert outer gap between windows and screen edge */
static const int swallowfloating         = 0;   /* 1 means swallow floating windows by default */
static const int smartgaps_fact          = 0;   /* gap factor when there is only one client; 0 = no gaps, 3 = 3x outer gaps */
static const int showbar                 = 0;   /* 0 means no bar */
static const int topbar                  = 1;   /* 0 means bottom bar */
/* Status is to be shown on: -1 (all monitors), 0 (a specific monitor by index), 'A' (active monitor) */
static const int statusmon               = -1;
static const int horizpadbar             = 2;   /* horizontal padding for statusbar */
static const int vertpadbar              = 6;   /* vertical padding for statusbar */

/* Indicators: see patch/bar_indicators.h for options */
static int tagindicatortype              = INDICATOR_NONE;
static int tiledindicatortype            = INDICATOR_NONE;
static int floatindicatortype            = INDICATOR_TOP_LEFT_SQUARE;
static const char *fonts[]               = {"Hack Font:size=11:antialias=true:autohint=true",
                                            "Hack Nerd Font:size=11:antialias=true:autohint=true",
                                            "FontAwesome:size:11:antialias=true:autohint=true"};
static const char dmenufont[]            = "Hack Nerd Font:size=11";

static char c000000[]                    = "#000000"; // placeholder value

static char normfgcolor[]                = "#f8f8f2";
static char normbgcolor[]                = "#000000";
static char normbordercolor[]            = "#000000";
static char normfloatcolor[]             = "#6272a4";

static char selfgcolor[]                 = "#f8f8f2";
static char selbgcolor[]                 = "#000000";
static char selbordercolor[]             = "#44475a";
static char selfloatcolor[]              = "#bd93f9";

static char titlenormfgcolor[]           = "#f8f8f2";
static char titlenormbgcolor[]           = "#000000";
static char titlenormbordercolor[]       = "#44475a";
static char titlenormfloatcolor[]        = "#6272a4";

static char titleselfgcolor[]            = "#f8f8f2";
static char titleselbgcolor[]            = "#000000";
static char titleselbordercolor[]        = "#bd93f9";
static char titleselfloatcolor[]         = "#bd93f9";

static char tagsnormfgcolor[]            = "#808080";
static char tagsnormbgcolor[]            = "#000000";
static char tagsnormbordercolor[]        = "#44475a";
static char tagsnormfloatcolor[]         = "#6272a4";

static char tagsselfgcolor[]             = "#f8f8f2";
static char tagsselbgcolor[]             = "#000000";
static char tagsselbordercolor[]         = "#bd93f9";
static char tagsselfloatcolor[]          = "#bd93f9";

static char hidnormfgcolor[]             = "#bd93f9";
static char hidselfgcolor[]              = "#8be9fd";
static char hidnormbgcolor[]             = "#000000";
static char hidselbgcolor[]              = "#000000";

static char urgfgcolor[]                 = "#ffffff";
static char urgbgcolor[]                 = "#000000";
static char urgbordercolor[]             = "#ff5555";
static char urgfloatcolor[]              = "#6272a4";


static const unsigned int baralpha = 0;       /* range(0-255) */
static const unsigned int borderalpha = 0;
static const unsigned int alphas[][3] = {
	/*                       fg      bg        border     */
	[SchemeNorm]         = { OPAQUE, baralpha, borderalpha },
	[SchemeSel]          = { OPAQUE, baralpha, borderalpha },
	[SchemeTitleNorm]    = { OPAQUE, baralpha, borderalpha },
	[SchemeTitleSel]     = { OPAQUE, baralpha, borderalpha },
	[SchemeTagsNorm]     = { OPAQUE, baralpha, borderalpha },
	[SchemeTagsSel]      = { OPAQUE, baralpha, borderalpha },
	[SchemeHidNorm]      = { OPAQUE, baralpha, borderalpha },
	[SchemeHidSel]       = { OPAQUE, baralpha, borderalpha },
	[SchemeUrg]          = { OPAQUE, baralpha, borderalpha },
};

static char *colors[][ColCount] = {
	/*                       fg                bg                border                float */
	[SchemeNorm]         = { normfgcolor,      normbgcolor,      normbordercolor,      normfloatcolor },
	[SchemeSel]          = { selfgcolor,       selbgcolor,       selbordercolor,       selfloatcolor },
	[SchemeTitleNorm]    = { titlenormfgcolor, titlenormbgcolor, titlenormbordercolor, titlenormfloatcolor },
	[SchemeTitleSel]     = { titleselfgcolor,  titleselbgcolor,  titleselbordercolor,  titleselfloatcolor },
	[SchemeTagsNorm]     = { tagsnormfgcolor,  tagsnormbgcolor,  tagsnormbordercolor,  tagsnormfloatcolor },
	[SchemeTagsSel]      = { tagsselfgcolor,   tagsselbgcolor,   tagsselbordercolor,   tagsselfloatcolor },
	[SchemeHidNorm]      = { hidnormfgcolor,   hidnormbgcolor,   c000000,              c000000 },
	[SchemeHidSel]       = { hidselfgcolor,    hidselbgcolor,    c000000,              c000000 },
	[SchemeUrg]          = { urgfgcolor,       urgbgcolor,       urgbordercolor,       urgfloatcolor },
};


/* const char *spcmd1[] = {"st", "-n", "spterm", "-g", "120x34", NULL }; */
const char *spcmd1[] = {Terminal, "-t", "spterm", "--class", "spterm", NULL };
const char *spcmd2[] = {Terminal, "-t", "spspt", "--class", "spspt", "-e", "ncspot", NULL };
const char *spcmd3[] = {Terminal, "-t", "spvol", "--class", "spvol", "-e", "pulsemixer", NULL };
static Sp scratchpads[] = {
   /* name          SHCMD  */
   {"spterm",      spcmd1},
   {"spspt",       spcmd2},
   {"spvol",       spcmd3},
};

/* Tags
 * In a traditional dwm the number of tags in use can be changed simply by changing the number
 * of strings in the tags array. This build does things a bit different which has some added
 * benefits. If you need to change the number of tags here then change the NUMTAGS macro in dwm.c.
 *
 * Examples:
 *
 *  1) static char *tagicons[][NUMTAGS*2] = {
 *         [DEFAULT_TAGS] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I" },
 *     }
 *
 *  2) static char *tagicons[][1] = {
 *         [DEFAULT_TAGS] = { "•" },
 *     }
 *
 * The first example would result in the tags on the first monitor to be 1 through 9, while the
 * tags for the second monitor would be named A through I. A third monitor would start again at
 * 1 through 9 while the tags on a fourth monitor would also be named A through I. Note the tags
 * count of NUMTAGS*2 in the array initialiser which defines how many tag text / icon exists in
 * the array. This can be changed to *3 to add separate icons for a third monitor.
 *
 * For the second example each tag would be represented as a bullet point. Both cases work the
 * same from a technical standpoint - the icon index is derived from the tag index and the monitor
 * index. If the icon index is is greater than the number of tag icons then it will wrap around
 * until it an icon matches. Similarly if there are two tag icons then it would alternate between
 * them. This works seamlessly with alternative tags and alttagsdecoration patches.
 */
static char *tagicons[][NUMTAGS] = {
	[DEFAULT_TAGS]        = { "1", "2", "3", "4", "5", "6", "", "", "" },
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F", "G", "H", "I" },
	[ALT_TAGS_DECORATION] = { "<1>", "<2>", "<3>", "<4>", "<5>", "<6>", "<7>", "<8>", "<9>" },
};


/* There are two options when it comes to per-client rules:
 *  - a typical struct table or
 *  - using the RULE macro
 *
 * A traditional struct table looks like this:
 *    // class      instance  title  wintype  tags mask  isfloating  monitor
 *    { "Gimp",     NULL,     NULL,  NULL,    1 << 4,    0,          -1 },
 *    { "Firefox",  NULL,     NULL,  NULL,    1 << 7,    0,          -1 },
 *
 * The RULE macro has the default values set for each field allowing you to only
 * specify the values that are relevant for your rule, e.g.
 *
 *    RULE(.class = "Gimp", .tags = 1 << 4)
 *    RULE(.class = "Firefox", .tags = 1 << 7)
 *
 * Refer to the Rule struct definition for the list of available fields depending on
 * the patches you enable.
 */
static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 *	WM_WINDOW_ROLE(STRING) = role
	 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
	 */

	/* RULE(.wintype = WTYPE "DIALOG", .isfloating = 1)
	* RULE(.wintype = WTYPE "UTILITY", .isfloating = 1)
	* RULE(.wintype = WTYPE "TOOLBAR", .isfloating = 1)
	* RULE(.wintype = WTYPE "SPLASH", .isfloating = 1)
    */

	/* class                instance     title       	   wintype           tags mask     isfloating   isterminal  noswallow  monitor */
	{ NULL,                 NULL,        NULL,       	   WTYPE "DIALOG",   0,            1,           0,          1,         -1 },
	{ NULL,                 NULL,        NULL,       	   WTYPE "UTILITY",  0,            1,           0,          1,         -1 },
	{ NULL,                 NULL,        NULL,       	   WTYPE "TOOLBAR",  0,            1,           0,          1,         -1 },
	{ NULL,                 NULL,        NULL,       	   WTYPE "SPLASH",   0,            1,           0,          1,         -1 },
	{ "Signal",             NULL,        NULL,       	   NULL,             1 << 6,       0,           0,          0,         -1 },
	{ "TelegramDesktop",    NULL,        NULL,       	   NULL,             1 << 6,       0,           0,          0,         -1 },
	{ "mpv",                NULL,        NULL,       	   NULL,             1 << 7,       0,           0,          0,         -1 },
	{ Termclass,            NULL,        NULL,       	   NULL,             0,            0,           1,          0,         -1 },
	{ NULL,                 NULL,        "Event Tester",   NULL,             0,            0,           0,          1,         -1 },
	{ NULL,                 "spterm",    NULL,       	   NULL,             SPTAG(0),     1,           1,          0,         -1 },
	{ NULL,                 "spspt",     NULL,       	   NULL,             SPTAG(1),     1,           1,          0,         -1 },
	{ NULL,                 "spvol",     NULL,       	   NULL,             SPTAG(2),     1,           1,          0,         -1 },
};



/* Bar rules allow you to configure what is shown where on the bar, as well as
 * introducing your own bar modules.
 *
 *    monitor:
 *      -1  show on all monitors
 *       0  show on monitor 0
 *      'A' show on active monitor (i.e. focused / selected) (or just -1 for active?)
 *    bar - bar index, 0 is default, 1 is extrabar
 *    alignment - how the module is aligned compared to other modules
 *    widthfunc, drawfunc, clickfunc - providing bar module width, draw and click functions
 *    name - does nothing, intended for visual clue and for logging / debugging
 */
static const BarRule barrules[] = {
	/* monitor   bar    alignment         widthfunc                drawfunc                clickfunc                name */
	{ -1,        0,     BAR_ALIGN_LEFT,   width_tags,              draw_tags,              click_tags,              "tags" },
	{ -1,        0,     BAR_ALIGN_LEFT,   width_ltsymbol,          draw_ltsymbol,          click_ltsymbol,          "layout" },
	{ statusmon, 0,     BAR_ALIGN_RIGHT,  width_status2d,          draw_status2d,          click_status2d,          "status2d" },
	{ -1,        0,     BAR_ALIGN_NONE,   width_wintitle,          draw_wintitle,          click_wintitle,          "wintitle" },
};

/* layout(s) */
static const float mfact     = 0.55;  /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};


/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} }, \
	{ MODKEY|Mod1Mask,              KEY,      tagnextmon,     {.ui = 1 << TAG} }, \
	{ MODKEY|Mod1Mask|ControlMask,  KEY,      tagprevmon,     {.ui = 1 << TAG} },


/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run",	NULL };
static const char *termcmd[] = { Terminal, NULL };


static Key keys[] = {
	/* modifier                     key                         function                argument */
	{ MODKEY,                       XK_p,                       spawn,                  {.v = dmenucmd } },
	{ MODKEY,                       XK_j,                       focusstack,             {.i = +1 } },
	{ MODKEY,                       XK_k,                       focusstack,             {.i = -1 } },
	{ MODKEY|ControlMask,           XK_j,                       movestack,              {.i = +1 } },
	{ MODKEY|ControlMask,           XK_k,                       movestack,              {.i = -1 } },
	{ MODKEY,                       XK_u,                       incnmaster,             {.i = +1 } },
	{ MODKEY,                       XK_i,                       incnmaster,             {.i = -1 } },
	{ MODKEY,                       XK_h,                       setmfact,               {.f = -0.05} },
	{ MODKEY,                       XK_l,                       setmfact,               {.f = +0.05} },
	{ MODKEY|ControlMask,           XK_g,                       incrgaps,               {.i = +1 } },
	{ MODKEY|ControlMask|ShiftMask, XK_g,                       incrgaps,               {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_g,                       defaultgaps,            {0} },
	{ MODKEY,                       XK_g,                       togglegaps,             {0} },
	{ MODKEY,                       XK_Tab,                     view,                   {0} },
    /* Layouts */
	{ MODKEY,                       XK_b,                       togglebar,              {0} },
	{ MODKEY,                       XK_z,                       zoom,                   {0} },
    { MODKEY,                       XK_t,                       setlayout,              {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,                       setlayout,              {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,                       setlayout,              {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,                   setlayout,              {0} },
    { MODKEY,                       XK_0,                       view,                   {.ui = ~SPTAGMASK } },
	{ MODKEY|ShiftMask,             XK_0,                       tag,                    {.ui = ~SPTAGMASK } },
	{ MODKEY,                       XK_comma,                   focusmon,               {.i = -1 } },
	{ MODKEY,                       XK_period,                  focusmon,               {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,                   tagmon,                 {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,                  tagmon,                 {.i = +1 } },
    /* Quit, Kill & Restart */
	{ MODKEY,                       XK_q,                       killclient,             {0} },
	{ MODKEY|ShiftMask,             XK_q,                       spawn,                  SHCMD("xkill") },
	{ MODKEY|ControlMask,           XK_q,                       quit,                   {0} },
	{ MODKEY|ControlMask,           XK_r,                       quit,                   {1} },
    /* Rofi */
    { MODKEY,                       XK_r,                       spawn,                  SHCMD("rofi -show combi -combi-modi 'window,drun' -modi combi -show-icons") } ,
    { MODKEY|ShiftMask,             XK_r,                       spawn,                  SHCMD("rofi -show run -modi 'run'") } ,
    { MODKEY,                       XK_v,                       spawn,                  SHCMD("rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}'") } ,
    { MODKEY|ShiftMask,             XK_v,                       spawn,                  SHCMD("rofi -show emoji -modi 'emoji'") } ,
    { MODKEY,                       XK_n,                       spawn,                  SHCMD("networkmanager_dmenu") } ,
    { MODKEY|ShiftMask,             XK_d,                       spawn,                  SHCMD("torr") } ,
    { MODKEY|ControlMask,           XK_x,                       spawn,                  SHCMD("rofi -show powermenu -modi powermenu:powermenu") } ,
    /* Custom Key Bindings */
	{ MODKEY,                       XK_Return,                  spawn,                  {.v = termcmd } },
    { MODKEY|ShiftMask,             XK_Return,                  spawn,                  SHCMD(Terminal " -e atmux") },
    { MODKEY,                       XK_w,                       spawn,                  SHCMD("librewolf") },
    { MODKEY|ShiftMask,             XK_w,                       spawn,                  SHCMD("librewolf --private-window") },
    { MODKEY|Mod1Mask,              XK_w,                       spawn,                  SHCMD("qutebrowser") },
    { MODKEY,                       XK_e,                       spawn,                  SHCMD(Terminal " -e lfrun") },
    { MODKEY|ShiftMask,             XK_e,                       spawn,                  SHCMD("thunar") },
    { MODKEY,                       XK_a,                       spawn,                  SHCMD(Terminal " -e bpytop") },
    { MODKEY,                       XK_d,                       spawn,                  SHCMD(Terminal " -e tremc") },
    { MODKEY,                       XK_c,                       spawn,                  SHCMD("clock") },
    { MODKEY|ShiftMask,             XK_c,                       spawn,                  SHCMD("cal-popup --popup") },
    /* Scratchpads */
    { MODKEY,                       XK_x,                       togglescratch,          {.ui = 0 } },
	{ MODKEY,                       XK_s,                       togglescratch,          {.ui = 1 } },
	{ MODKEY,                       XK_o,                       togglescratch,          {.ui = 2 } },
    /* Screenshot */
    { 0,                            XK_Print,                   spawn,                  SHCMD("flameshot full -p ~/Himanshu/Data/Screenshots") } ,
    { Mod1Mask,                     XK_Print,                   spawn,                  SHCMD("flameshot screen -p ~/Himanshu/Data/Screenshots") } ,
    { ControlMask,                  XK_Print,                   spawn,                  SHCMD("flameshot gui -p ~/Himanshu/Data/Screenshots") } ,
    /* Media+Vol+Brightness Keys */
    { 0,                            XF86XK_AudioMute,           spawn,                  SHCMD("volume mute") },
    { 0,                            XF86XK_AudioRaiseVolume,    spawn,                  SHCMD("volume up") },
    { 0,                            XF86XK_AudioLowerVolume,    spawn,                  SHCMD("volume down") },
    { 0,                            XF86XK_MonBrightnessUp,     spawn,                  SHCMD("brightnessctl set +10%") },
    { 0,                            XF86XK_MonBrightnessDown,   spawn,                  SHCMD("brightnessctl set 10%-") },
    { 0,                            XF86XK_AudioPlay,           spawn,                  SHCMD("playerctl play-pause") },
    { 0,                            XF86XK_AudioStop,           spawn,                  SHCMD("playerctl stop") },
    { 0,                            XF86XK_AudioNext,           spawn,                  SHCMD("playerctl next") },
    { 0,                            XF86XK_AudioPrev,           spawn,                  SHCMD("playerctl previous") },
    /* Notification Controls */
    {MODKEY,                        XK_grave,                   spawn,                  SHCMD("dunstctl close") },
    {MODKEY|Mod1Mask,               XK_grave,                   spawn,                  SHCMD("dunstctl close-all") },
    {MODKEY|ShiftMask,              XK_grave,                   spawn,                  SHCMD("dunstctl history-pop") },
    {MODKEY|ControlMask,            XK_grave,                   spawn,                  SHCMD("dunstctl set-paused toggle") },

    TAGKEYS(                        XK_1,                                               0)
	TAGKEYS(                        XK_2,                                               1)
	TAGKEYS(                        XK_3,                                               2)
	TAGKEYS(                        XK_4,                                               3)
	TAGKEYS(                        XK_5,                                               4)
	TAGKEYS(                        XK_6,                                               5)
	TAGKEYS(                        XK_7,                                               6)
	TAGKEYS(                        XK_8,                                               7)
	TAGKEYS(                        XK_9,                                               8)
};


/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask           button          function        argument */
	{ ClkLtSymbol,          0,                   Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,                   Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,                   Button2,        zoom,           {0} },
	{ ClkStatusText,        0,                   Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,              Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,              Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,              Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,                   Button1,        view,           {0} },
	{ ClkTagBar,            0,                   Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,              Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,              Button3,        toggletag,      {0} },
};

 
