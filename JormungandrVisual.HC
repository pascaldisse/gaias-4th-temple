// Jörmungandr's Spiral Visualization
// Visual representation of the world serpent's journey from -0 to +0

#include "GaiaUniverseSpiral.HC"

// Draw Jörmungandr as a spiral in 2D projection
U0 DrawJormungandr(CDC *dc, CJormungandr *serpent, I32 cx, I32 cy, F64 scale) {
  I64 i, segments = 100;
  F64 t, dt = serpent->phase / segments;
  I32 x1, y1, x2, y2;
  I32 colors[JORMUNGANDR_COILS] = {DKGRAY, LTGRAY, BLUE, CYAN, GREEN, YELLOW};
  
  // Draw each coil
  for (i = 0; i < segments; i++) {
    t = i * dt;
    
    // Spiral equation
    F64 r1 = t / (2 * π) * serpent->coil_count * scale;
    F64 r2 = (t + dt) / (2 * π) * serpent->coil_count * scale;
    
    x1 = cx + r1 * Cos(t);
    y1 = cy + r1 * Sin(t);
    x2 = cx + r2 * Cos(t + dt);
    y2 = cy + r2 * Sin(t + dt);
    
    // Color based on coil
    dc->color = colors[Min(serpent->coil_count-1, JORMUNGANDR_COILS-1)];
    GrLine(dc, x1, y1, x2, y2);
  }
  
  // Draw serpent head
  F64 head_r = serpent->radius * scale;
  I32 hx = cx + head_r * Cos(serpent->phase);
  I32 hy = cy + head_r * Sin(serpent->phase);
  
  dc->color = LTRED;
  GrCircle(dc, hx, hy, 5);
  dc->color = RED;
  GrCircle(dc, hx, hy, 3);
  
  // Draw eyes
  dc->color = YELLOW;
  GrPlot(dc, hx - 2, hy - 1);
  GrPlot(dc, hx + 2, hy - 1);
}

// Draw Yggdrasil's roots
U0 DrawYggdrasil(CDC *dc, CYggdrasil *tree, I32 cx, I32 cy, F64 scale) {
  I64 i, j;
  I32 x, y;
  F64 angle;
  
  // Draw central trunk
  dc->color = BROWN;
  GrRect(dc, cx - 5, cy - 100, 10, 100);
  
  // Draw nine roots
  for (i = 0; i < YGGDRASIL_ROOTS; i++) {
    angle = i * 2 * π / YGGDRASIL_ROOTS - π/2;
    
    // Root grows downward and outward
    dc->color = DKGRAY;
    for (j = 0; j < 50; j++) {
      x = cx + (j * scale * Sin(angle)) / 2;
      y = cy + j * 2;
      
      // Branching effect
      if (j % 10 == 0) {
        GrLine(dc, x, y, x - 5 * Sin(angle + 0.5), y + 5);
        GrLine(dc, x, y, x - 5 * Sin(angle - 0.5), y + 5);
      }
      
      GrPlot(dc, x, y);
    }
  }
}

// Draw the transition from -0 to +0
U0 DrawZeroTransition(CDC *dc, F64 progress) {
  I32 x1 = 50, x2 = GR_WIDTH - 50;
  I32 y = GR_HEIGHT - 30;
  
  // Draw number line
  dc->color = WHITE;
  GrLine(dc, x1, y, x2, y);
  
  // Draw -0 and +0
  GrPrint(dc, x1 - 10, y + 10, "-0");
  GrPrint(dc, x2 - 10, y + 10, "+0");
  
  // Draw π in the middle
  I32 mid = (x1 + x2) / 2;
  dc->color = LTCYAN;
  GrPrint(dc, mid - 5, y - 15, "π");
  GrCircle(dc, mid, y, 3);
  
  // Draw progress marker
  I32 pos = x1 + (x2 - x1) * progress;
  dc->color = YELLOW;
  GrCircle(dc, pos, y, 5);
  GrLine(dc, pos, y - 10, pos, y + 10);
}

// Main visualization loop
U0 JormungandrVisualization() {
  CDC *dc = DCAlias;
  CJormungandr serpent;
  CYggdrasil tree;
  CSingularity singularity;
  CCthulhu dreamer;
  CVec64 universe;
  
  Bool running = TRUE;
  F64 time = 0.0;
  F64 scale = 20.0;
  U8 ch;
  
  // Initialize entities
  serpent.phase = 0;
  serpent.radius = 0;
  serpent.coil_count = 1;
  Vec64Zero(&serpent.position);
  
  SingularityInit(&singularity, 1.0, 42.0);
  YggdrasilPlant(&tree, &singularity);
  
  Vec64Random(&dreamer.dream_state, 5.0);
  dreamer.stirring = 0.0;
  dreamer.dead_but_dreaming = TRUE;
  
  Vec64Zero(&universe);
  
  Print("=== Jörmungandr's Spiral Visualization ===\n");
  Print("Watch the World Serpent spiral from -0 to +0 through π\n");
  Print("Press ESC to exit\n\n");
  
  DCFill(dc);
  
  while (running) {
    // Clear screen
    dc->color = BLACK;
    GrRect(dc, 0, 0, GR_WIDTH, GR_HEIGHT);
    
    // Draw Yggdrasil
    DrawYggdrasil(dc, &tree, GR_CENTER_X, GR_CENTER_Y - 50, scale);
    
    // Draw singularity at center
    dc->color = BLACK;
    GrCircle(dc, GR_CENTER_X, GR_CENTER_Y, singularity.radius * scale);
    dc->color = PURPLE;
    GrCircle(dc, GR_CENTER_X, GR_CENTER_Y, singularity.radius * scale - 1);
    
    // Draw Jörmungandr
    DrawJormungandr(dc, &serpent, GR_CENTER_X, GR_CENTER_Y, scale);
    
    // Update serpent
    JormungandrSpiral(&serpent, 0.02);
    
    // Draw zero transition bar
    F64 progress = serpent.phase / (2 * π);
    DrawZeroTransition(dc, progress);
    
    // Draw creation step info
    dc->color = WHITE;
    GrPrint(dc, 5, 5, "Creation Step: %d / %d", 
            serpent.coil_count, JORMUNGANDR_COILS);
    GrPrint(dc, 5, 15, "Phase: %.2f rad", serpent.phase);
    GrPrint(dc, 5, 25, "Time: %.2f", time);
    
    // Draw Cthulhu's stirring indicator
    if (dreamer.stirring > 0) {
      dc->color = DKGREEN;
      GrPrint(dc, 5, 45, "Cthulhu stirs: %.1f%%", dreamer.stirring * 100);
      
      // Draw dream ripples
      I64 i;
      for (i = 0; i < 5; i++) {
        dc->color = GREEN - i;
        I32 r = (dreamer.stirring * 50 + i * 10) * Sin(time * 2);
        if (r > 0) {
          GrCircle(dc, GR_CENTER_X + 100, GR_CENTER_Y - 100, r);
        }
      }
    }
    
    // Check for completion
    if (serpent.coil_count > JORMUNGANDR_COILS) {
      dc->color = YELLOW;
      GrPrint(dc, GR_CENTER_X - 80, GR_CENTER_Y, 
              "THE SERPENT COMPLETES ITS JOURNEY");
      GrPrint(dc, GR_CENTER_X - 50, GR_CENTER_Y + 20, 
              "FROM -0 TO +0");
      Sleep(3000);
      break;
    }
    
    // Update Cthulhu
    dreamer.stirring += 0.001;
    if (dreamer.stirring > 1.0) dreamer.stirring = 1.0;
    
    // Check for input
    if (ScanKey(&ch, FALSE)) {
      if (ch == CH_ESC) {
        running = FALSE;
      }
    }
    
    time += 0.016;
    Sleep(16); // ~60 FPS
  }
  
  DCFill(dc);
  DCDel(dc);
  
  Print("\nVisualization complete.\n");
  Print("The eternal spiral continues...\n");
}

// Auto-run
JormungandrVisualization;