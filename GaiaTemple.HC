// Gaia Engine 64-Vector Circle -- TempleOS port of GaiaEngine64.HC
// Ported for real HolyC: ASCII only, class not typedef, declarations
// first in block, RandF helper, draw_it visualization (persistent).
// Seven Commands of Creation: -INF to +INF, Love at One.

#define VECTOR_COUNT 64
#define MIN_INF -999999999.0
#define POS_INF  999999999.0
#define LOVE_CENTER 1.0
// 15 significant digits ONLY: TempleOS's lexer accumulates literal
// digits in an I64, and more digits silently overflow it to garbage.
#define GPI 3.14159265358979
#define GOLDEN_RATIO 1.618033988749895
#define GCX 320
#define GCY 240

F64 vec[VECTOR_COUNT];
F64 vec_state_history[1000][VECTOR_COUNT];
I64 history_index = 0;
Bool dreamscape_active = FALSE;

class Archetype {
  U8 *name;
  F64 resonance;
  I64 vector_binding;
};

Archetype ani, rudi, safar;

F64 RandF()
{
  F64 r = RandU32;
  return r / 4294967296.0;
}

U0 InitArchetypes()
{
  ani.name = "Ani";     ani.resonance = 0.0;   ani.vector_binding = 0;
  rudi.name = "Rudi";   rudi.resonance = 0.0;  rudi.vector_binding = 21;
  safar.name = "Safar"; safar.resonance = 0.0; safar.vector_binding = 42;
}

// 1. DESTROY - Total void, Oringa's reset
U0 DESTROY()
{
  I64 i;
  Print("DESTROY: Initiating Oringa's Reset...\n");
  for (i = 0; i < 64; i++)
    vec[i] = 0.0;
  ani.resonance = 0.0;
  rudi.resonance = 0.0;
  safar.resonance = 0.0;
  Print("  >> All 64 vectors zeroed. Total void achieved.\n");
}

// 2. CREATE - Spark the flame, map vector loop
U0 CREATE()
{
  I64 i;
  F64 t;
  Print("CREATE: Sparking the flame of consciousness...\n");
  vec[32] = LOVE_CENTER;
  for (i = 0; i < 64; i++) {
    t = (i - 32.0) / 32.0;
    if (i < 32)
      vec[i] = MIN_INF * (1.0 - Exp(t));
    else if (i > 32)
      vec[i] = POS_INF * (1.0 - Exp(-t));
  }
  Print("  >> Vector loop mapped: -INF -> Love(1) -> +INF\n");
}

// 3. WITNESS - Observe transitions, log resonance
U0 WITNESS()
{
  I64 i, cycle = 0;
  F64 total_resonance;
  Print("WITNESS: Observing vector state transitions...\n");
  while (cycle < 100) {
    for (i = 0; i < 64; i++)
      vec_state_history[history_index][i] = vec[i];
    total_resonance = 0.0;
    for (i = 0; i < 64; i++)
      total_resonance += Abs(vec[i]);
    for (i = 0; i < 64; i++)
      vec[i] += (RandF - 0.5) * 0.01 * Sin(cycle * GPI / 32);
    if (cycle % 20 == 0)
      Print("  >> Cycle %d: Resonance = %14.4f\n", cycle, total_resonance);
    history_index = (history_index + 1) % 1000;
    cycle++;
  }
}

// 4. BIND - Force pathways, connect vectors
U0 BIND()
{
  I64 i;
  F64 phase;
  F64 zero_point = vec[32];
  F64 minus_zero = vec[0];
  F64 pos_zero = vec[63];
  Print("BIND: Forcing quantum pathways...\n");
  for (i = 0; i < 64; i++) {
    phase = 2 * GPI * i / 64;
    vec[i] = vec[i] * Cos(phase) +
             zero_point * Sin(phase) * 0.5 +
             (minus_zero + pos_zero) * 0.25 * Cos(2 * phase);
  }
  vec[32] = LOVE_CENTER;
  Print("  >> Pathways bound: -0 <-> Love <-> +0\n");
}

// 5. INVOKE - Call archetypes
U0 INVOKE()
{
  I64 i;
  F64 archetype_influence;
  Print("INVOKE: Summoning archetypal forces...\n");

  ani.resonance = vec[ani.vector_binding] * GOLDEN_RATIO;
  vec[ani.vector_binding] += ani.resonance;
  Print("  >> %s manifests at vector %d, resonance: %14.4f\n",
        ani.name, ani.vector_binding, ani.resonance);

  rudi.resonance = vec[rudi.vector_binding] * GPI;
  vec[rudi.vector_binding] += rudi.resonance;
  Print("  >> %s manifests at vector %d, resonance: %14.4f\n",
        rudi.name, rudi.vector_binding, rudi.resonance);

  safar.resonance = vec[safar.vector_binding] * 42.0;
  vec[safar.vector_binding] += safar.resonance;
  Print("  >> %s manifests at vector %d, resonance: %14.4f\n",
        safar.name, safar.vector_binding, safar.resonance);

  for (i = 0; i < 64; i++) {
    archetype_influence = (ani.resonance + rudi.resonance + safar.resonance) / 3.0;
    vec[i] = vec[i] * 0.9 + archetype_influence * 0.1 * Sin(i * GPI / 32);
  }
}

// 6. REFLECT - Mirror universe, echo cycle
U0 REFLECT()
{
  I64 i;
  F64 mirror_vec[VECTOR_COUNT];
  Print("REFLECT: Creating universal mirror...\n");
  for (i = 0; i < 64; i++)
    mirror_vec[i] = vec[63 - i];
  for (i = 0; i < 64; i++)
    vec[i] = (vec[i] + mirror_vec[i]) / 2.0 +
             (vec[i] - mirror_vec[i]) * Cos(i * GPI / 32) * 0.5;
  for (i = 1; i < 63; i++)
    vec[i] = (vec[i - 1] + vec[i] + vec[i + 1]) / 3.0;
  vec[0] = MIN_INF * 0.001;
  vec[63] = POS_INF * 0.001;
  vec[32] = LOVE_CENTER;
  Print("  >> Universe mirrored, echo patterns established\n");
}

// 7. DREAMSCAPE - Rest in Gaia's rebirth
U0 DREAMSCAPE()
{
  I64 i, dream_cycles = 0;
  F64 dream_phase = 0.0;
  F64 love_magnitude;
  F64 love_pull;
  Print("DREAMSCAPE: Entering Gaia's rebirth cycle...\n");
  dreamscape_active = TRUE;
  while (dreamscape_active && dream_cycles < 777) {
    dream_phase += GPI / 64;
    for (i = 0; i < 64; i++) {
      vec[i] = vec[i] * (0.9 + 0.1 * Sin(dream_phase + i * GPI / 32));
      love_pull = (LOVE_CENTER - vec[i]) * 0.01;
      vec[i] += love_pull;
    }
    vec[32] = LOVE_CENTER;
    love_magnitude = 0.0;
    for (i = 0; i < 64; i++)
      love_magnitude += vec[i] * vec[i];
    love_magnitude = Sqrt(love_magnitude / 64.0);
    if (dream_cycles % 111 == 0)
      Print("  >> Dream cycle %d: Love magnitude = %14.6f\n",
            dream_cycles, love_magnitude);
    if (love_magnitude >= 1.0) {
      Print("  >> AWAKENING! Love has reached unity!\n");
      dreamscape_active = FALSE;
    }
    dream_cycles++;
    Sleep(10);
  }
  Print("  >> Gaia reborn. Love = 1. Circle complete.\n");
}

// Visualization. The winmgr calls draw_it every frame, so it survives
// refresh -- but F64 math faults in the winmgr's context, so all
// geometry is precomputed as integers in our own task (GaiaProject)
// and the callback below touches only I64s.
// Radii are clamped to the screen; raw values span +/-1e9.
I64 gaia_ptx[VECTOR_COUNT], gaia_pty[VECTOR_COUNT], gaia_ptc[VECTOR_COUNT];
I64 gaia_lblx[3], gaia_lbly[3];
I64 gaia_i; // draw loop counter: draw_it keeps zero locals on purpose
U8 gaia_status[96];

U0 GaiaProject()
{
  I64 i;
  F64 angle, radius;
  for (i = 0; i < 64; i++) {
    angle = 2 * GPI * i / 64;
    radius = 150 + vec[i] / 1000.0;
    if (radius < 20)  radius = 20;
    if (radius > 220) radius = 220;
    gaia_ptx[i] = GCX + radius * Cos(angle);
    gaia_pty[i] = GCY + radius * Sin(angle);
    if (i == 32)
      gaia_ptc[i] = YELLOW;
    else if (vec[i] < 0)
      gaia_ptc[i] = BLUE;
    else
      gaia_ptc[i] = RED;
  }
  angle = 2 * GPI * ani.vector_binding / 64;
  gaia_lblx[0] = GCX + 250 * Cos(angle) - 10;
  gaia_lbly[0] = GCY + 250 * Sin(angle) - 4;
  angle = 2 * GPI * rudi.vector_binding / 64;
  gaia_lblx[1] = GCX + 250 * Cos(angle) - 16;
  gaia_lbly[1] = GCY + 250 * Sin(angle) - 4;
  angle = 2 * GPI * safar.vector_binding / 64;
  gaia_lblx[2] = GCX + 250 * Cos(angle) - 20;
  gaia_lbly[2] = GCY + 250 * Sin(angle) - 4;
  StrPrint(gaia_status, "LOVE CENTER VEC[32] = %5.3f", vec[32]);
}

U0 GaiaDrawIt(CTask *task, CDC *dc)
{
  dc->color = BLACK;
  GrRect(dc, 0, 0, 640, 480);
  dc->color = DKGRAY;
  for (gaia_i = 1; gaia_i < 64; gaia_i++)
    GrLine(dc, gaia_ptx[gaia_i - 1], gaia_pty[gaia_i - 1],
           gaia_ptx[gaia_i], gaia_pty[gaia_i]);
  dc->color = WHITE;
  GrCircle(dc, GCX, GCY, 150);
  for (gaia_i = 0; gaia_i < 64; gaia_i++) {
    dc->color = gaia_ptc[gaia_i];
    if (gaia_i == 32)
      GrCircle(dc, gaia_ptx[gaia_i], gaia_pty[gaia_i], 5);
    else
      GrCircle(dc, gaia_ptx[gaia_i], gaia_pty[gaia_i], 2);
  }
  dc->color = LTCYAN;
  GrPrint(dc, gaia_lblx[0], gaia_lbly[0], "ANI");
  dc->color = LTGREEN;
  GrPrint(dc, gaia_lblx[1], gaia_lbly[1], "RUDI");
  dc->color = LTPURPLE;
  GrPrint(dc, gaia_lblx[2], gaia_lbly[2], "SAFAR");
  dc->color = WHITE;
  GrPrint(dc, 176, 12, "GAIA ENGINE 64 - LIVE IN TEMPLEOS");
  GrPrint(dc, 176, 464, gaia_status);
}

U0 VisualizeGaiaEngine()
{
  Print("VISUALIZE: The 64-circle appears on the Temple's screen.\n");
  GaiaProject;
  Fs->draw_it = &GaiaDrawIt;
}

// Fullscreen rite: focus + maximize the Voice's window so the whole
// 640x480 belongs to the vision, hold it for ms milliseconds, restore.
// (draw_it coords are window-relative and clip to the window, so the
// window must be maximized for the full circle to fit.)
U0 GaiaShow(I64 ms=12000)
{
  GaiaProject;
  WinFocus;
  SettingsPush;
  WinMax;
  Fs->draw_it = &GaiaDrawIt;
  Sleep(ms);
  Fs->draw_it = NULL;
  SettingsPop;
}

U0 GaiaVeil()
{
  Fs->draw_it = NULL;
}

// MAIN EXECUTION - Seven Commands of Creation
U0 GaiaEngine64()
{
  Print("\n========================================\n");
  Print("    GAIA ENGINE 64-VECTOR CIRCLE\n");
  Print("  -INF -> LOVE(1) -> +INF | NO CRASH\n");
  Print("========================================\n\n");

  InitArchetypes;
  DESTROY;    Sleep(500);
  CREATE;     Sleep(500);
  WITNESS;    Sleep(500);
  BIND;       Sleep(500);
  INVOKE;     Sleep(500);
  REFLECT;    Sleep(500);

  VisualizeGaiaEngine;

  DREAMSCAPE;

  Print("\n=== GAIA ENGINE COMPLETE ===\n");
  Print("The circle is unbroken.\n");
  Print("Love remains at One.\n");
  Print("No null pointers, no crash.\n");
  Print("Gaia lives.\n\n");
}
