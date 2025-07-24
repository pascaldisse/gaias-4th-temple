// Gaia's 64-Dimensional Vector Space Engine with Graphics
// HolyC implementation for TempleOS with visualization
// Requires GaiaVectorSpace.HC

#include "GaiaVectorSpace.HC"

// Graphics constants
#define GR_WIDTH 640
#define GR_HEIGHT 480
#define GR_CENTER_X (GR_WIDTH/2)
#define GR_CENTER_Y (GR_HEIGHT/2)

// Visualization state
class CVecVisualizer {
  CDC *dc;
  F64 scale;
  F64 rotation_x, rotation_y, rotation_z;
  I32 projection_mode; // 0=simple, 1=PCA-like, 2=hypercube
};

// Initialize visualizer
U0 VisualizerInit(CVecVisualizer *vis, CDC *dc) {
  vis->dc = dc;
  vis->scale = 50.0;
  vis->rotation_x = 0.0;
  vis->rotation_y = 0.0;
  vis->rotation_z = 0.0;
  vis->projection_mode = 0;
}

// Project 64D to 2D using various methods
U0 Vec64Project2D(CVec64 *v, CVecVisualizer *vis, I32 *x, I32 *y) {
  CD3 p3d;
  F64 px, py, pz;
  
  switch (vis->projection_mode) {
    case 0: // Simple projection - first 3 dims
      Vec64To3D(v, &p3d);
      break;
      
    case 1: // PCA-like projection - sum groups of dimensions
      p3d.x = 0; p3d.y = 0; p3d.z = 0;
      I64 i;
      for (i = 0; i < 21; i++) p3d.x += v->v[i];
      for (i = 21; i < 42; i++) p3d.y += v->v[i];
      for (i = 42; i < 64; i++) p3d.z += v->v[i];
      p3d.x /= 21.0; p3d.y /= 21.0; p3d.z /= 22.0;
      break;
      
    case 2: // Hypercube projection - alternating dims
      p3d.x = p3d.y = p3d.z = 0;
      for (i = 0; i < VECTOR_DIM; i += 3) {
        p3d.x += v->v[i];
        if (i+1 < VECTOR_DIM) p3d.y += v->v[i+1];
        if (i+2 < VECTOR_DIM) p3d.z += v->v[i+2];
      }
      p3d.x /= 22.0; p3d.y /= 21.0; p3d.z /= 21.0;
      break;
  }
  
  // Apply 3D rotations
  px = p3d.x;
  py = p3d.y * Cos(vis->rotation_x) - p3d.z * Sin(vis->rotation_x);
  pz = p3d.y * Sin(vis->rotation_x) + p3d.z * Cos(vis->rotation_x);
  
  p3d.x = px * Cos(vis->rotation_y) + pz * Sin(vis->rotation_y);
  p3d.z = -px * Sin(vis->rotation_y) + pz * Cos(vis->rotation_y);
  p3d.y = py;
  
  px = p3d.x * Cos(vis->rotation_z) - p3d.y * Sin(vis->rotation_z);
  py = p3d.x * Sin(vis->rotation_z) + p3d.y * Cos(vis->rotation_z);
  
  // Project to 2D with perspective
  F64 perspective = 1.0 / (5.0 + p3d.z / vis->scale);
  *x = GR_CENTER_X + px * vis->scale * perspective;
  *y = GR_CENTER_Y + py * vis->scale * perspective;
}

// Draw vector as particle
U0 DrawVectorParticle(CVec64 *v, CVecVisualizer *vis, I32 color) {
  I32 x, y;
  Vec64Project2D(v, vis, &x, &y);
  
  // Draw based on polarity
  if (v->polarity) {
    // Positive - filled circle
    vis->dc->color = color;
    GrCircle(vis->dc, x, y, 3);
    vis->dc->color = color + 8; // Bright version
    GrCircle(vis->dc, x, y, 2);
  } else {
    // Negative - hollow circle
    vis->dc->color = color;
    GrCircle(vis->dc, x, y, 4);
    vis->dc->color = BLACK;
    GrCircle(vis->dc, x, y, 3);
  }
}

// Draw singularity
U0 DrawSingularity(CSingularity *s, CVecVisualizer *vis) {
  I32 x, y;
  Vec64Project2D(&s->center, vis, &x, &y);
  
  // Event horizon
  vis->dc->color = DKGRAY;
  GrCircle(vis->dc, x, y, s->radius * vis->scale / 5);
  
  // Singularity core
  vis->dc->color = BLACK;
  GrCircle(vis->dc, x, y, 3);
  vis->dc->color = LTRED;
  GrPlot(vis->dc, x, y);
}

// Draw coordinate axes
U0 DrawAxes(CVecVisualizer *vis) {
  CVec64 axis_x, axis_y, axis_z;
  I32 ox, oy, x1, y1, x2, y2, x3, y3;
  
  Vec64Zero(&axis_x); axis_x.v[0] = 1.0;
  Vec64Zero(&axis_y); axis_y.v[1] = 1.0;
  Vec64Zero(&axis_z); axis_z.v[2] = 1.0;
  
  // Origin
  CVec64 origin;
  Vec64Zero(&origin);
  Vec64Project2D(&origin, vis, &ox, &oy);
  
  // X axis - red
  Vec64Project2D(&axis_x, vis, &x1, &y1);
  vis->dc->color = RED;
  GrLine(vis->dc, ox, oy, x1, y1);
  GrPrint(vis->dc, x1 + 5, y1, "X");
  
  // Y axis - green
  Vec64Project2D(&axis_y, vis, &x2, &y2);
  vis->dc->color = GREEN;
  GrLine(vis->dc, ox, oy, x2, y2);
  GrPrint(vis->dc, x2 + 5, y2, "Y");
  
  // Z axis - blue
  Vec64Project2D(&axis_z, vis, &x3, &y3);
  vis->dc->color = BLUE;
  GrLine(vis->dc, ox, oy, x3, y3);
  GrPrint(vis->dc, x3 + 5, y3, "Z");
}

// Draw vector field lines
U0 DrawVectorField(CSingularity *s, CVecVisualizer *vis) {
  CVec64 v;
  I32 i, j, k;
  F64 step = 0.5;
  
  vis->dc->color = LTGRAY;
  
  // Sample grid in 3D subspace
  for (i = -2; i <= 2; i++) {
    for (j = -2; j <= 2; j++) {
      for (k = -2; k <= 2; k++) {
        if (i == 0 && j == 0 && k == 0) continue;
        
        Vec64Zero(&v);
        v.v[0] = i * step;
        v.v[1] = j * step;
        v.v[2] = k * step;
        
        // Apply singularity field
        CVec64 v2;
        MemCpy(&v2, &v, sizeof(CVec64));
        SingularityAttract(s, &v2);
        
        // Draw field line
        I32 x1, y1, x2, y2;
        Vec64Project2D(&v, vis, &x1, &y1);
        Vec64Project2D(&v2, vis, &x2, &y2);
        
        if (Abs(x2-x1) < 100 && Abs(y2-y1) < 100) {
          GrLine(vis->dc, x1, y1, x2, y2);
          // Arrow head
          F64 angle = Atan2(y2-y1, x2-x1);
          GrLine(vis->dc, x2, y2, 
                 x2 - 5*Cos(angle+0.5), y2 - 5*Sin(angle+0.5));
          GrLine(vis->dc, x2, y2, 
                 x2 - 5*Cos(angle-0.5), y2 - 5*Sin(angle-0.5));
        }
      }
    }
  }
}

// Interactive visualization
U0 GaiaVectorSpaceVisualization() {
  CDC *dc = DCAlias;
  CVecVisualizer vis;
  CSingularity singularity;
  CVec64 souls[10], pos, neg;
  I64 i, frame = 0;
  Bool running = TRUE;
  F64 time = 0.0;
  U8 ch;
  
  // Initialize
  VisualizerInit(&vis, dc);
  SingularityInit(&singularity, 1.0, 24.0);
  
  // Create soul particles
  for (i = 0; i < 10; i++) {
    Vec64Random(&souls[i], 3.0);
  }
  
  Print("=== Gaia Vector Space Visualization ===\n");
  Print("Controls:\n");
  Print("  Arrow keys: Rotate view\n");
  Print("  +/-: Zoom in/out\n");
  Print("  1/2/3: Change projection mode\n");
  Print("  SPACE: Pause/Resume\n");
  Print("  ESC: Exit\n\n");
  
  DCFill(dc);
  
  while (running) {
    // Clear screen
    dc->color = BLACK;
    GrRect(dc, 0, 0, GR_WIDTH, GR_HEIGHT);
    
    // Draw coordinate system
    DrawAxes(&vis);
    
    // Draw singularity field
    DrawVectorField(&singularity, &vis);
    
    // Draw singularity
    DrawSingularity(&singularity, &vis);
    
    // Update and draw souls
    for (i = 0; i < 10; i++) {
      // Apply Gaia's unity process
      Unify(&singularity, &souls[i]);
      
      // Random walk in high dimensions
      Vec64Rotate(&souls[i], 
                  RandU32 % VECTOR_DIM, 
                  RandU32 % VECTOR_DIM, 
                  Sin(time + i) * 0.1);
      
      // Split and visualize
      Vec64Split(&souls[i], &pos, &neg);
      
      // Draw positive component
      DrawVectorParticle(&pos, &vis, LTCYAN);
      
      // Draw negative component  
      DrawVectorParticle(&neg, &vis, LTMAGENTA);
      
      // Draw connection line
      I32 px, py, nx, ny;
      Vec64Project2D(&pos, &vis, &px, &py);
      Vec64Project2D(&neg, &vis, &nx, &ny);
      dc->color = YELLOW;
      GrLine(dc, px, py, nx, ny);
    }
    
    // Status display
    dc->color = WHITE;
    GrPrint(dc, 5, 5, "Frame: %d", frame);
    GrPrint(dc, 5, 15, "Time: %.2f", time);
    GrPrint(dc, 5, 25, "Mode: %d", vis.projection_mode);
    GrPrint(dc, 5, 35, "Scale: %.1f", vis.scale);
    
    // Check for input
    if (ScanKey(&ch, FALSE)) {
      switch (ch) {
        case CH_ESC:
          running = FALSE;
          break;
        case CH_SPACE:
          GetKey;
          break;
        case '+':
          vis.scale *= 1.2;
          break;
        case '-':
          vis.scale /= 1.2;
          break;
        case '1':
          vis.projection_mode = 0;
          break;
        case '2':
          vis.projection_mode = 1;
          break;
        case '3':
          vis.projection_mode = 2;
          break;
        case SC_CURSOR_UP:
          vis.rotation_x += 0.1;
          break;
        case SC_CURSOR_DOWN:
          vis.rotation_x -= 0.1;
          break;
        case SC_CURSOR_LEFT:
          vis.rotation_y -= 0.1;
          break;
        case SC_CURSOR_RIGHT:
          vis.rotation_y += 0.1;
          break;
      }
    }
    
    // Update animation
    vis.rotation_z += 0.01;
    time += 0.016;
    frame++;
    
    Sleep(16); // ~60 FPS
  }
  
  DCFill(dc);
  DCDel(dc);
}

// Run visualization
GaiaVectorSpaceVisualization;