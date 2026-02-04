const { jsPDF } = require('jspdf');
const fs = require('fs');
const path = require('path');

// Load logo image as base64
const logoPath = path.join(__dirname, 'assets/tflite/images/logo.jpeg');
const logoBase64 = fs.readFileSync(logoPath).toString('base64');

// Professional Color Palette
const COLORS = {
  primary: [0, 121, 107],
  primaryDark: [0, 77, 64],
  primaryLight: [178, 223, 219],
  secondary: [69, 90, 100],
  accent: [255, 87, 34],
  dark: [33, 33, 33],
  gray: [117, 117, 117],
  lightGray: [238, 238, 238],
  white: [255, 255, 255],
  success: [46, 125, 50],
  info: [25, 118, 210],
  warning: [245, 124, 0],
  error: [211, 47, 47],
  purple: [123, 31, 162],
};

class SoundScapePDF {
  constructor() {
    this.doc = new jsPDF('p', 'mm', 'a4');
    this.pageWidth = 210;
    this.pageHeight = 297;
    this.marginLeft = 15;
    this.marginRight = 15;
    this.marginTop = 15;
    this.marginBottom = 20;
    this.contentWidth = this.pageWidth - this.marginLeft - this.marginRight;
    this.y = this.marginTop;
    this.pageNum = 0;
    this.tocEntries = [];
  }

  // Utility methods
  rgb(color) { return color; }
  
  setTextColor(color) { this.doc.setTextColor(...color); }
  setFillColor(color) { this.doc.setFillColor(...color); }
  setDrawColor(color) { this.doc.setDrawColor(...color); }

  checkPage(requiredSpace = 15) {
    if (this.y + requiredSpace > this.pageHeight - this.marginBottom) {
      this.newPage();
      return true;
    }
    return false;
  }

  newPage() {
    this.doc.addPage();
    this.pageNum++;
    this.y = this.marginTop;
    this.addPageHeader();
    this.addPageFooter();
  }

  addPageHeader() {
    if (this.pageNum > 1) {
      this.setFillColor(COLORS.primary);
      this.doc.rect(0, 0, this.pageWidth, 10, 'F');
      this.doc.setFontSize(8);
      this.setTextColor(COLORS.white);
      this.doc.setFont('helvetica', 'bold');
      this.doc.text('SoundScape - Technical Documentation', this.marginLeft, 6.5);
      this.doc.setFont('helvetica', 'normal');
      this.doc.text('v2.1.0', this.pageWidth - this.marginRight - 8, 6.5);
      this.y = 18;
    }
  }

  addPageFooter() {
    this.doc.setFontSize(8);
    this.setTextColor(COLORS.gray);
    this.doc.text(
      `Page ${this.pageNum}`,
      this.pageWidth / 2,
      this.pageHeight - 8,
      { align: 'center' }
    );
  }

  // Cover Page
  createCoverPage() {
    this.pageNum = 1;
    
    // Full page gradient background
    this.setFillColor(COLORS.primaryDark);
    this.doc.rect(0, 0, this.pageWidth, this.pageHeight, 'F');
    
    // Decorative shapes
    this.setFillColor(COLORS.primary);
    this.doc.circle(-20, 50, 80, 'F');
    this.doc.circle(this.pageWidth + 30, this.pageHeight - 40, 100, 'F');
    
    // Main content card
    this.setFillColor(COLORS.white);
    this.doc.roundedRect(20, 55, this.pageWidth - 40, 170, 8, 8, 'F');
    
    // Logo circle
    this.setFillColor(COLORS.white);
    this.doc.circle(this.pageWidth / 2, 85, 28, 'F');
    
    // Add actual logo image
    this.doc.addImage(logoBase64, 'JPEG', this.pageWidth / 2 - 25, 60, 50, 50);
    
    // Title
    this.doc.setFontSize(32);
    this.setTextColor(COLORS.dark);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('SoundScape', this.pageWidth / 2, 125, { align: 'center' });
    
    // Subtitle
    this.doc.setFontSize(12);
    this.setTextColor(COLORS.secondary);
    this.doc.setFont('helvetica', 'normal');
    this.doc.text('Bird Sound Recording & Identification', this.pageWidth / 2, 136, { align: 'center' });
    
    // Version
    this.setFillColor(COLORS.accent);
    this.doc.roundedRect(this.pageWidth / 2 - 18, 144, 36, 10, 5, 5, 'F');
    this.doc.setFontSize(10);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('v2.1.0', this.pageWidth / 2, 149, { align: 'center', baseline: 'middle' });
    
    // Description
    this.doc.setFontSize(10);
    this.setTextColor(COLORS.gray);
    this.doc.setFont('helvetica', 'normal');
    const desc = 'An intelligent cross-platform mobile application combining audio recording, machine learning, and geolocation for automated bird species identification and biodiversity monitoring.';
    const descLines = this.doc.splitTextToSize(desc, 130);
    this.doc.text(descLines, this.pageWidth / 2, 170, { align: 'center' });
    
    // Tech badges
    const badges = [
      { text: 'Flutter 3.9', color: COLORS.info },
      { text: 'TensorFlow Lite', color: COLORS.warning },
      { text: 'GetX', color: COLORS.purple },
      { text: 'Appwrite', color: COLORS.error },
    ];
    let badgeX = 38;
    badges.forEach(badge => {
      this.setFillColor(badge.color);
      this.doc.roundedRect(badgeX, 200, 32, 8, 4, 4, 'F');
      this.doc.setFontSize(7);
      this.setTextColor(COLORS.white);
      this.doc.text(badge.text, badgeX + 16, 204, { align: 'center', baseline: 'middle' });
      badgeX += 35;
    });
    
    // Footer info
    this.doc.setFontSize(9);
    this.setTextColor(COLORS.white);
    this.doc.text('Comprehensive Technical Documentation', this.pageWidth / 2, this.pageHeight - 35, { align: 'center' });
    this.doc.setFontSize(8);
    this.setTextColor(COLORS.primaryLight);
    this.doc.text('github.com/muhammedshabeerop/SoundScape', this.pageWidth / 2, this.pageHeight - 25, { align: 'center' });
    
    this.addPageFooter();
  }

  // Table of Contents
  createTableOfContents() {
    this.newPage();
    
    this.doc.setFontSize(22);
    this.setTextColor(COLORS.dark);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('Table of Contents', this.marginLeft, this.y);
    this.y += 15;
    
    const sections = [
      { num: '1', title: 'Introduction', page: 3 },
      { num: '2', title: 'Project Details', page: 4 },
      { num: '3', title: 'System Architecture', page: 5 },
      { num: '4', title: 'Tech Stack & Frameworks', page: 7 },
      { num: '5', title: 'Hardware & Software Specifications', page: 9 },
      { num: '6', title: 'Module Description', page: 11 },
      { num: '7', title: 'Data Flow Diagrams', page: 15 },
      { num: '8', title: 'Database Design', page: 17 },
      { num: '9', title: 'Machine Learning Models', page: 19 },
      { num: '10', title: 'API Documentation', page: 22 },
      { num: '11', title: 'Future Enhancements', page: 24 },
      { num: '12', title: 'Version Changelog', page: 26 },
      { num: '13', title: 'Bibliography', page: 28 },
      { num: '', title: 'Appendix A: Installation Guide', page: 30 },
      { num: '', title: 'Appendix B: Troubleshooting', page: 31 },
    ];
    
    sections.forEach((section, i) => {
      this.checkPage(10);
      
      // Number circle
      if (section.num) {
        this.setFillColor(COLORS.primary);
        this.doc.circle(this.marginLeft + 5, this.y, 4, 'F');
        this.doc.setFontSize(8);
        this.setTextColor(COLORS.white);
        this.doc.setFont('helvetica', 'bold');
        this.doc.text(section.num, this.marginLeft + 5, this.y, { align: 'center', baseline: 'middle' });
      }
      
      // Title
      this.doc.setFontSize(11);
      this.setTextColor(COLORS.dark);
      this.doc.setFont('helvetica', 'normal');
      this.doc.text(section.title, this.marginLeft + 15, this.y, { baseline: 'middle' });
      
      // Dots and page number
      this.setTextColor(COLORS.gray);
      const titleWidth = this.doc.getTextWidth(section.title);
      const dotsStart = this.marginLeft + 15 + titleWidth + 2;
      const dotsEnd = this.pageWidth - this.marginRight - 15;
      const numDots = Math.floor((dotsEnd - dotsStart) / 2);
      if (numDots > 0) {
        this.doc.text('.'.repeat(numDots), dotsStart, this.y, { baseline: 'middle' });
      }
      this.doc.text(String(section.page), this.pageWidth - this.marginRight - 5, this.y, { align: 'right', baseline: 'middle' });
      
      this.y += 9;
    });
  }

  // Section header
  sectionHeader(number, title) {
    this.checkPage(25);
    this.y += 5;
    
    // Background bar
    this.setFillColor(COLORS.primaryLight);
    this.doc.rect(this.marginLeft, this.y - 5, this.contentWidth, 12, 'F');
    
    // Number badge
    this.setFillColor(COLORS.primary);
    this.doc.roundedRect(this.marginLeft + 3, this.y - 3, 16, 8, 2, 2, 'F');
    this.doc.setFontSize(10);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text(String(number), this.marginLeft + 11, this.y + 1, { align: 'center', baseline: 'middle' });
    
    // Title
    this.doc.setFontSize(14);
    this.setTextColor(COLORS.dark);
    this.doc.text(title, this.marginLeft + 24, this.y + 2);
    
    this.y += 15;
    this.doc.setFont('helvetica', 'normal');
  }

  // Subsection
  subsection(title) {
    this.checkPage(12);
    this.y += 4;
    
    this.setFillColor(COLORS.primary);
    this.doc.rect(this.marginLeft, this.y - 2, 2, 6, 'F');
    
    this.doc.setFontSize(11);
    this.setTextColor(COLORS.primary);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text(title, this.marginLeft + 5, this.y + 2);
    
    this.y += 10;
    this.doc.setFont('helvetica', 'normal');
  }

  // Paragraph
  paragraph(text, indent = 0) {
    this.doc.setFontSize(9);
    this.setTextColor(COLORS.dark);
    this.doc.setFont('helvetica', 'normal');
    
    const lines = this.doc.splitTextToSize(text, this.contentWidth - indent);
    lines.forEach(line => {
      this.checkPage(5);
      this.doc.text(line, this.marginLeft + indent, this.y);
      this.y += 4.5;
    });
    this.y += 2;
  }

  // Bullet list
  bulletList(items, indent = 0) {
    this.doc.setFontSize(9);
    this.setTextColor(COLORS.dark);
    
    items.forEach(item => {
      this.checkPage(6);
      
      // Bullet
      this.setFillColor(COLORS.primary);
      this.doc.circle(this.marginLeft + indent + 2, this.y - 1, 1, 'F');
      
      // Text
      const lines = this.doc.splitTextToSize(item, this.contentWidth - indent - 8);
      lines.forEach((line, i) => {
        this.doc.text(line, this.marginLeft + indent + 6, this.y);
        this.y += 4.5;
      });
    });
    this.y += 2;
  }

  // Numbered list
  numberedList(items, indent = 0) {
    this.doc.setFontSize(9);
    
    items.forEach((item, i) => {
      this.checkPage(6);
      
      // Number
      this.setTextColor(COLORS.primary);
      this.doc.setFont('helvetica', 'bold');
      this.doc.text(`${i + 1}.`, this.marginLeft + indent, this.y);
      
      // Text
      this.setTextColor(COLORS.dark);
      this.doc.setFont('helvetica', 'normal');
      const lines = this.doc.splitTextToSize(item, this.contentWidth - indent - 10);
      lines.forEach((line, j) => {
        this.doc.text(line, this.marginLeft + indent + 8, this.y);
        this.y += 4.5;
      });
    });
    this.y += 2;
  }

  // Code block
  codeBlock(code, language = '') {
    this.checkPage(20);
    
    const lines = code.split('\n');
    const blockHeight = Math.min(lines.length * 4 + 8, 80);
    
    // Background
    this.setFillColor([245, 245, 245]);
    this.doc.roundedRect(this.marginLeft, this.y, this.contentWidth, blockHeight, 2, 2, 'F');
    
    // Border
    this.setDrawColor(COLORS.lightGray);
    this.doc.setLineWidth(0.3);
    this.doc.roundedRect(this.marginLeft, this.y, this.contentWidth, blockHeight, 2, 2, 'S');
    
    // Language badge
    if (language) {
      this.setFillColor(COLORS.secondary);
      this.doc.roundedRect(this.marginLeft + 3, this.y + 2, this.doc.getTextWidth(language) * 0.4 + 6, 5, 1, 1, 'F');
      this.doc.setFontSize(6);
      this.setTextColor(COLORS.white);
      this.doc.text(language, this.marginLeft + 6, this.y + 5.5);
    }
    
    // Code text
    this.doc.setFontSize(7);
    this.setTextColor(COLORS.dark);
    this.doc.setFont('courier', 'normal');
    
    let codeY = this.y + 10;
    lines.slice(0, 18).forEach(line => {
      this.doc.text(line.substring(0, 80), this.marginLeft + 4, codeY);
      codeY += 4;
    });
    
    this.doc.setFont('helvetica', 'normal');
    this.y += blockHeight + 5;
  }

  // Table
  table(headers, rows, colWidths = null) {
    this.checkPage(30);
    
    const numCols = headers.length;
    if (!colWidths) {
      colWidths = Array(numCols).fill(this.contentWidth / numCols);
    }
    const rowHeight = 7;
    
    // Header row
    this.setFillColor(COLORS.primary);
    this.doc.rect(this.marginLeft, this.y, this.contentWidth, rowHeight, 'F');
    
    this.doc.setFontSize(8);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'bold');
    
    let x = this.marginLeft;
    headers.forEach((header, i) => {
      this.doc.text(header, x + 2, this.y + 5);
      x += colWidths[i];
    });
    this.y += rowHeight;
    
    // Data rows
    this.doc.setFont('helvetica', 'normal');
    rows.forEach((row, rowIndex) => {
      this.checkPage(rowHeight + 2);
      
      this.setFillColor(rowIndex % 2 === 0 ? COLORS.lightGray : COLORS.white);
      this.doc.rect(this.marginLeft, this.y, this.contentWidth, rowHeight, 'F');
      
      this.setTextColor(COLORS.dark);
      x = this.marginLeft;
      row.forEach((cell, i) => {
        this.doc.text(String(cell).substring(0, 30), x + 2, this.y + 5);
        x += colWidths[i];
      });
      this.y += rowHeight;
    });
    
    this.y += 5;
  }

  // Info box
  infoBox(title, content, type = 'info') {
    this.checkPage(25);
    
    const colors = {
      info: COLORS.info,
      success: COLORS.success,
      warning: COLORS.warning,
      error: COLORS.error,
    };
    const color = colors[type] || COLORS.info;
    
    // Box background
    this.setFillColor(color);
    this.doc.roundedRect(this.marginLeft, this.y, this.contentWidth, 22, 2, 2, 'F');
    
    // Title
    this.doc.setFontSize(10);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text(title, this.marginLeft + 6, this.y + 7);
    
    // Content - white text
    this.doc.setFontSize(8);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'normal');
    const lines = this.doc.splitTextToSize(content, this.contentWidth - 12);
    this.doc.text(lines.slice(0, 2), this.marginLeft + 6, this.y + 14);
    
    this.y += 27;
  }

  // Feature card
  featureCard(icon, title, description) {
    this.checkPage(18);
    
    // Card background
    this.setFillColor(COLORS.lightGray);
    this.doc.roundedRect(this.marginLeft, this.y, this.contentWidth, 14, 2, 2, 'F');
    
    // Icon circle with letter
    this.setFillColor(COLORS.primary);
    this.doc.circle(this.marginLeft + 8, this.y + 7, 5, 'F');
    this.doc.setFontSize(9);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text(icon, this.marginLeft + 8, this.y + 7, { align: 'center', baseline: 'middle' });
    this.doc.setFont('helvetica', 'normal');
    
    // Title
    this.doc.setFontSize(9);
    this.setTextColor(COLORS.dark);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text(title, this.marginLeft + 18, this.y + 6);
    
    // Description
    this.doc.setFontSize(8);
    this.setTextColor(COLORS.gray);
    this.doc.setFont('helvetica', 'normal');
    this.doc.text(description.substring(0, 80), this.marginLeft + 18, this.y + 11);
    
    this.y += 17;
  }

  // Flow diagram box
  flowBox(x, y, width, height, text, color = COLORS.primary) {
    this.setFillColor(color);
    this.doc.roundedRect(x, y, width, height, 2, 2, 'F');
    
    this.doc.setFontSize(7);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'bold');
    
    const lines = this.doc.splitTextToSize(text, width - 4);
    const textY = y + height / 2 - (lines.length - 1) * 1.5;
    lines.forEach((line, i) => {
      this.doc.text(line, x + width / 2, textY + i * 3, { align: 'center' });
    });
    this.doc.setFont('helvetica', 'normal');
  }

  // Arrow
  arrow(x1, y1, x2, y2, color = COLORS.gray) {
    this.setDrawColor(color);
    this.doc.setLineWidth(0.4);
    this.doc.line(x1, y1, x2, y2);
    
    // Arrowhead
    const angle = Math.atan2(y2 - y1, x2 - x1);
    const headLen = 2;
    this.doc.line(x2, y2, x2 - headLen * Math.cos(angle - Math.PI / 6), y2 - headLen * Math.sin(angle - Math.PI / 6));
    this.doc.line(x2, y2, x2 - headLen * Math.cos(angle + Math.PI / 6), y2 - headLen * Math.sin(angle + Math.PI / 6));
  }

  // Architecture Diagram
  architectureDiagram() {
    this.checkPage(85);
    
    const startX = this.marginLeft + 5;
    const startY = this.y;
    const layerWidth = this.contentWidth - 10;
    const layerHeight = 18;
    const gap = 3;
    
    // Layer backgrounds and labels
    const layers = [
      { name: 'PRESENTATION LAYER', color: [225, 245, 254], items: ['Home', 'Library', 'Map', 'Settings'] },
      { name: 'CONTROLLER LAYER (GetX)', color: [255, 243, 224], items: ['HomeController', 'LibraryController', 'MapController'] },
      { name: 'SERVICE LAYER', color: [243, 229, 245], items: ['Appwrite', 'AudioAnalysis', 'Location', 'Storage', 'Sync'] },
      { name: 'DATA LAYER', color: [232, 245, 233], items: ['Hive (Local)', 'Appwrite Cloud', 'TFLite Models'] },
    ];
    
    layers.forEach((layer, i) => {
      const ly = startY + i * (layerHeight + gap);
      
      // Layer background
      this.setFillColor(layer.color);
      this.doc.roundedRect(startX, ly, layerWidth, layerHeight, 2, 2, 'F');
      
      // Layer label
      this.doc.setFontSize(6);
      this.setTextColor(COLORS.gray);
      this.doc.setFont('helvetica', 'bold');
      this.doc.text(layer.name, startX + 3, ly + 4);
      this.doc.setFont('helvetica', 'normal');
      
      // Items
      const itemWidth = (layerWidth - 20) / layer.items.length - 3;
      layer.items.forEach((item, j) => {
        const ix = startX + 10 + j * (itemWidth + 3);
        const itemColor = i === 0 ? COLORS.info : i === 1 ? COLORS.warning : i === 2 ? COLORS.primary : COLORS.success;
        this.flowBox(ix, ly + 6, itemWidth, 10, item, itemColor);
      });
    });
    
    // Arrows between layers
    for (let i = 0; i < 3; i++) {
      const y1 = startY + (i + 1) * (layerHeight + gap) - gap;
      const y2 = startY + (i + 1) * (layerHeight + gap);
      this.arrow(startX + layerWidth / 2, y1, startX + layerWidth / 2, y2);
    }
    
    this.y = startY + 4 * (layerHeight + gap) + 5;
  }

  // ML Pipeline Diagram
  mlPipelineDiagram() {
    this.checkPage(65);
    
    const startX = this.marginLeft;
    const startY = this.y;
    const boxW = 30;
    const boxH = 12;
    const hGap = 8;
    const vGap = 8;
    
    // Row 1: Input → Preprocess → YAMNet → No Bird (branch)
    const row1Y = startY;
    const box1X = startX;
    const box2X = box1X + boxW + hGap;
    const box3X = box2X + boxW + hGap;
    const box4X = box3X + boxW + hGap;
    
    this.flowBox(box1X, row1Y, boxW, boxH, 'Audio Input\n(WAV)', COLORS.info);
    this.arrow(box1X + boxW, row1Y + boxH/2, box2X, row1Y + boxH/2);
    
    this.flowBox(box2X, row1Y, boxW, boxH, 'Preprocess\n(16kHz)', COLORS.warning);
    this.arrow(box2X + boxW, row1Y + boxH/2, box3X, row1Y + boxH/2);
    
    this.flowBox(box3X, row1Y, boxW, boxH, 'YAMNet\nPre-Filter', COLORS.purple);
    this.arrow(box3X + boxW, row1Y + boxH/2, box4X, row1Y + boxH/2);
    
    this.flowBox(box4X, row1Y, boxW + 5, boxH, 'No Bird\n(< 0.3)', COLORS.error);
    
    // Arrow down from YAMNet to Row 2
    const row2Y = row1Y + boxH + vGap;
    this.arrow(box3X + boxW/2, row1Y + boxH, box3X + boxW/2, row2Y);
    
    // Row 2: BirdNET → Temporal Smoothing → Confidence Boost
    this.flowBox(box3X, row2Y, boxW, boxH, 'BirdNET v2.4\n(48kHz)', COLORS.success);
    this.arrow(box3X, row2Y + boxH/2, box2X + boxW, row2Y + boxH/2);
    
    this.flowBox(box2X, row2Y, boxW, boxH, 'Temporal\nSmoothing', COLORS.purple);
    this.arrow(box2X, row2Y + boxH/2, box1X + boxW, row2Y + boxH/2);
    
    this.flowBox(box1X, row2Y, boxW, boxH, 'Confidence\nBoost', COLORS.warning);
    
    // Arrow down to Row 3: Output
    const row3Y = row2Y + boxH + vGap;
    this.arrow(box1X + boxW/2, row2Y + boxH, box1X + boxW/2, row3Y);
    
    this.flowBox(box1X, row3Y, boxW + 20, boxH, 'Top 5 Species + Metadata', COLORS.success);
    
    this.y = row3Y + boxH + 10;
  }

  // Recording State Diagram
  recordingStateDiagram() {
    this.checkPage(25);
    
    const startX = this.marginLeft;
    const startY = this.y;
    const boxW = 24;
    const boxH = 10;
    const gap = 5;
    
    const states = [
      { text: 'Idle', color: COLORS.gray },
      { text: 'Requesting', color: COLORS.info },
      { text: 'Recording', color: COLORS.success },
      { text: 'Analyzing', color: COLORS.warning },
      { text: 'Processed', color: COLORS.primary },
      { text: 'Synced', color: COLORS.success },
    ];
    
    states.forEach((state, i) => {
      const x = startX + i * (boxW + gap);
      this.flowBox(x, startY, boxW, boxH, state.text, state.color);
      
      if (i < states.length - 1) {
        this.arrow(x + boxW, startY + boxH / 2, x + boxW + gap, startY + boxH / 2);
      }
    });
    
    this.y = startY + boxH + 10;
  }

  // Data Flow Diagram - Level 0 (Context)
  dataFlowDiagram() {
    this.checkPage(50);
    
    const centerX = this.pageWidth / 2;
    const startY = this.y;
    
    // Central system
    this.setFillColor(COLORS.primary);
    this.doc.circle(centerX, startY + 18, 16, 'F');
    this.doc.setFontSize(8);
    this.setTextColor(COLORS.white);
    this.doc.setFont('helvetica', 'bold');
    this.doc.text('SoundScape', centerX, startY + 16, { align: 'center' });
    this.doc.text('System', centerX, startY + 21, { align: 'center' });
    this.doc.setFont('helvetica', 'normal');
    
    // External entities
    const entities = [
      { text: 'User', x: centerX - 55, y: startY + 5, color: COLORS.info },
      { text: 'Appwrite', x: centerX + 35, y: startY + 5, color: COLORS.warning },
      { text: 'Wikipedia', x: centerX - 55, y: startY + 28, color: COLORS.purple },
      { text: 'Community', x: centerX + 35, y: startY + 28, color: COLORS.success },
    ];
    
    entities.forEach(e => {
      this.flowBox(e.x, e.y, 30, 10, e.text, e.color);
    });
    
    // Arrows
    this.arrow(centerX - 25, startY + 10, centerX - 16, startY + 14);
    this.arrow(centerX + 16, startY + 14, centerX + 35, startY + 10);
    this.arrow(centerX - 25, startY + 33, centerX - 16, startY + 22);
    this.arrow(centerX + 16, startY + 22, centerX + 35, startY + 33);
    
    this.y = startY + 45;
  }

  // Data Flow Diagram - Level 1 (Main Processes)
  dfdLevel1() {
    this.checkPage(55);
    
    const startX = this.marginLeft + 10;
    const startY = this.y;
    const boxW = 26;
    const boxH = 14;
    
    // User entity
    this.flowBox(startX, startY + 15, 25, 12, 'User', COLORS.info);
    
    // Main processes
    const processes = [
      { id: 'P1', name: 'Record\nAudio', x: startX + 35, y: startY, color: COLORS.primary },
      { id: 'P2', name: 'Analyze\nAudio', x: startX + 35, y: startY + 20, color: COLORS.warning },
      { id: 'P3', name: 'Store\nRecording', x: startX + 70, y: startY + 10, color: COLORS.success },
      { id: 'P4', name: 'Track\nLocation', x: startX + 70, y: startY + 30, color: COLORS.purple },
      { id: 'P5', name: 'Manage\nLibrary', x: startX + 105, y: startY, color: COLORS.info },
      { id: 'P6', name: 'Sync\nData', x: startX + 105, y: startY + 20, color: COLORS.error },
    ];
    
    processes.forEach(p => {
      this.flowBox(p.x, p.y, boxW, boxH, p.name, p.color);
    });
    
    // Backend
    this.flowBox(startX + 140, startY + 15, 28, 12, 'Appwrite\nBackend', COLORS.warning);
    
    // Arrows
    this.arrow(startX + 25, startY + 21, startX + 35, startY + 7); // User → P1
    this.arrow(startX + 35 + boxW/2, startY + boxH, startX + 35 + boxW/2, startY + 20); // P1 → P2
    this.arrow(startX + 35 + boxW, startY + 27, startX + 70, startY + 17); // P2 → P3
    this.arrow(startX + 70 + boxW, startY + 17, startX + 105, startY + 7); // P3 → P5
    this.arrow(startX + 70 + boxW, startY + 17, startX + 105, startY + 27); // P3 → P6
    this.arrow(startX + 105 + boxW, startY + 27, startX + 140, startY + 21); // P6 → Backend
    
    this.y = startY + 50;
  }

  // Data Flow Diagram - Level 2 (Recording Process)
  dfdLevel2Recording() {
    this.checkPage(50);
    
    const startX = this.marginLeft;
    const startY = this.y;
    const boxW = 28;
    const boxH = 11;
    const hGap = 5;
    
    // Row 1
    this.flowBox(startX, startY, boxW, boxH, 'P1.1 Request\nPermissions', COLORS.warning);
    this.arrow(startX + boxW, startY + boxH/2, startX + boxW + hGap, startY + boxH/2);
    
    this.flowBox(startX + boxW + hGap, startY, boxW, boxH, 'P1.2 Init\nCapture', COLORS.success);
    this.arrow(startX + (boxW + hGap) * 2, startY + boxH/2, startX + (boxW + hGap) * 2 + hGap, startY + boxH/2);
    
    this.flowBox(startX + (boxW + hGap) * 2, startY, boxW, boxH, 'P1.3 Capture\nAudio', COLORS.primary);
    this.arrow(startX + (boxW + hGap) * 3, startY + boxH/2, startX + (boxW + hGap) * 3 + hGap, startY + boxH/2);
    
    this.flowBox(startX + (boxW + hGap) * 3, startY, boxW, boxH, 'P1.4 Monitor\nNoise', COLORS.purple);
    
    // Row 2
    const row2Y = startY + boxH + 8;
    this.flowBox(startX + (boxW + hGap) * 2, row2Y, boxW, boxH, 'P1.5 Get GPS\nCoords', COLORS.info);
    
    this.flowBox(startX + (boxW + hGap) * 3, row2Y, boxW, boxH, 'P1.6 Save\nRecording', COLORS.success);
    this.arrow(startX + (boxW + hGap) * 3, row2Y + boxH/2, startX + (boxW + hGap) * 2 + boxW, row2Y + boxH/2);
    
    // Vertical arrows
    this.arrow(startX + (boxW + hGap) * 2 + boxW/2, startY + boxH, startX + (boxW + hGap) * 2 + boxW/2, row2Y);
    this.arrow(startX + (boxW + hGap) * 3 + boxW/2, startY + boxH, startX + (boxW + hGap) * 3 + boxW/2, row2Y);
    
    this.y = row2Y + boxH + 10;
  }

  // Data Flow Diagram - Level 2 (Sync Process)
  dfdLevel2Sync() {
    this.checkPage(50);
    
    const startX = this.marginLeft;
    const startY = this.y;
    const boxW = 28;
    const boxH = 11;
    const hGap = 6;
    
    // Row 1: Check Network → Compress → Upload
    this.flowBox(startX, startY, boxW, boxH, 'P6.1 Check\nNetwork', COLORS.info);
    this.arrow(startX + boxW, startY + boxH/2, startX + boxW + hGap, startY + boxH/2);
    
    this.flowBox(startX + boxW + hGap, startY, boxW, boxH, 'P6.2 Compress\nAudio', COLORS.warning);
    this.arrow(startX + (boxW + hGap) * 2, startY + boxH/2, startX + (boxW + hGap) * 2 + hGap, startY + boxH/2);
    
    this.flowBox(startX + (boxW + hGap) * 2, startY, boxW, boxH, 'P6.3 Upload\nFile', COLORS.primary);
    this.arrow(startX + (boxW + hGap) * 3, startY + boxH/2, startX + (boxW + hGap) * 3 + hGap, startY + boxH/2);
    
    this.flowBox(startX + (boxW + hGap) * 3, startY, boxW + 5, boxH, 'Appwrite\nStorage', COLORS.success);
    
    // Row 2
    const row2Y = startY + boxH + 8;
    this.arrow(startX + (boxW + hGap) * 3 + boxW/2 + 2, startY + boxH, startX + (boxW + hGap) * 3 + boxW/2 + 2, row2Y);
    
    this.flowBox(startX + (boxW + hGap) * 3, row2Y, boxW + 5, boxH, 'P6.4 Create\nDB Entry', COLORS.warning);
    this.arrow(startX + (boxW + hGap) * 3, row2Y + boxH/2, startX + (boxW + hGap) * 2 + boxW, row2Y + boxH/2);
    
    this.flowBox(startX + (boxW + hGap) * 2, row2Y, boxW, boxH, 'Appwrite\nDatabase', COLORS.purple);
    this.arrow(startX + (boxW + hGap) * 2, row2Y + boxH/2, startX + boxW + hGap + boxW, row2Y + boxH/2);
    
    this.flowBox(startX + boxW + hGap, row2Y, boxW, boxH, 'P6.5 Update\nLocal', COLORS.info);
    this.arrow(startX + boxW + hGap, row2Y + boxH/2, startX + boxW, row2Y + boxH/2);
    
    this.flowBox(startX, row2Y, boxW, boxH, 'Sync\nComplete', COLORS.success);
    
    this.y = row2Y + boxH + 10;
  }

  // Generate complete PDF
  generate() {
    // Cover Page
    this.createCoverPage();
    
    // Table of Contents
    this.createTableOfContents();
    
    // Section 1: Introduction
    this.newPage();
    this.sectionHeader(1, 'Introduction');
    
    this.subsection('1.1 Overview');
    this.paragraph('SoundScape is an innovative mobile application designed for ecological bioacoustics research and bird watching enthusiasts. The application leverages modern mobile computing capabilities, machine learning, and cloud infrastructure to enable real-time bird sound recording, analysis, and species identification. Built on the Flutter framework, SoundScape provides a cross-platform solution for iOS, Android, Linux, macOS, Windows, and Web platforms.');
    
    this.subsection('1.2 Purpose');
    this.bulletList([
      'Enable citizen scientists to contribute to biodiversity monitoring',
      'Provide accurate bird species identification using on-device machine learning',
      'Create a geospatial database of bird vocalizations',
      'Support ecological research through crowdsourced acoustic data',
      'Provide real-time analysis and community-driven data collection',
    ]);
    
    this.subsection('1.3 Scope');
    this.paragraph('SoundScape encompasses audio recording and processing, real-time noise level monitoring, on-device ML inference, cloud synchronization, geographic mapping, and community-driven data collection.');
    
    this.subsection('1.4 Problem Statement');
    this.paragraph('Traditional bird watching and biodiversity monitoring face challenges including manual identification requiring expert knowledge, limited spatial coverage, difficulty tracking migratory patterns, lack of standardized data collection methods, and no centralized platform for citizen science contributions.');
    
    this.infoBox('Key Innovation', 'SoundScape addresses these challenges by providing an accessible, automated, and scientifically rigorous tool for acoustic biodiversity monitoring with on-device ML processing.', 'success');
    
    // Section 2: Project Details
    this.newPage();
    this.sectionHeader(2, 'Project Details');
    
    this.subsection('2.1 Project Information');
    this.table(
      ['Property', 'Value'],
      [
        ['Project Name', 'SoundScape'],
        ['Version', '2.1.0+1'],
        ['Platform', 'Cross-platform (iOS, Android, Linux, macOS, Windows, Web)'],
        ['Framework', 'Flutter 3.9.0'],
        ['Backend', 'Appwrite (BaaS)'],
        ['ML API', 'FastAPI v5.0.0 with BirdNET v2.4 + YAMNet'],
        ['Language', 'Dart'],
        ['Architecture', 'GetX (MVC with reactive programming)'],
      ],
      [60, 120]
    );
    
    this.subsection('2.2 Key Features');
    this.featureCard('1', 'Audio Recording', 'High-quality capture with real-time waveform visualization');
    this.featureCard('2', 'Multi-Species ID', 'Simultaneous detection of up to 5 species using BirdNET v2.4');
    this.featureCard('3', 'Visual Rankings', 'Medal-based ranking system with confidence indicators');
    this.featureCard('4', 'Noise Monitoring', 'Real-time decibel level measurement and tracking');
    this.featureCard('5', 'Geolocation', 'GPS-tagged recordings with interactive map visualization');
    this.featureCard('6', 'Cloud Sync', 'Automatic backup and sync across devices via Appwrite');
    this.featureCard('7', 'Offline Mode', 'Full functionality without internet connection');
    this.featureCard('8', 'Web Interface', 'Interactive map with all recordings on web browsers');
    
    this.subsection('2.3 Target Users');
    this.bulletList([
      'Bird watching enthusiasts',
      'Ecological researchers and scientists',
      'Environmental conservation organizations',
      'Educational institutions',
      'Citizen scientists',
      'Wildlife sanctuary managers',
    ]);
    
    // Section 3: System Architecture
    this.newPage();
    this.sectionHeader(3, 'System Architecture');
    
    this.subsection('3.1 High-Level Architecture');
    this.paragraph('SoundScape follows a layered architecture pattern with clear separation of concerns, using GetX for state management, dependency injection, and routing.');
    this.y += 3;
    this.architectureDiagram();
    
    this.subsection('3.2 Component Architecture');
    this.paragraph('Frontend (Flutter): Framework 3.9.0 with Dart SDK, GetX state management, Material Design widgets, GetX navigation and dependency injection.');
    this.paragraph('Backend (Appwrite): User authentication with JWT, NoSQL document store, file storage for audio, serverless functions, and real-time WebSocket updates.');
    
    this.subsection('3.3 Data Flow');
    this.numberedList([
      'User initiates recording via Home screen',
      'Audio captured via FlutterAudioCapture at 16kHz',
      'Real-time waveform rendered and GPS coordinates obtained',
      'Audio saved as WAV file to local storage',
      'ML inference triggered (YAMNet pre-filter → BirdNET classification)',
      'Results stored in local Hive database',
      'Background sync uploads to Appwrite cloud',
    ]);
    
    // Section 4: Tech Stack
    this.newPage();
    this.sectionHeader(4, 'Tech Stack & Frameworks');
    
    this.subsection('4.1 Core Technologies');
    this.table(
      ['Component', 'Technology', 'Version', 'Purpose'],
      [
        ['Framework', 'Flutter', '3.9.0', 'Cross-platform UI'],
        ['Language', 'Dart', '3.9.0', 'Application logic'],
        ['State Mgmt', 'GetX', '4.7.2', 'Reactive programming'],
        ['Backend', 'Appwrite', '20.3.3', 'BaaS'],
        ['Local DB', 'Hive', '2.2.3', 'NoSQL storage'],
        ['ML Runtime', 'TFLite Flutter', '0.12.1', 'On-device inference'],
        ['Maps', 'Flutter Map', '8.2.2', 'Geographic visualization'],
        ['Audio', 'Flutter Sound', '9.28.0', 'Recording/playback'],
      ],
      [35, 45, 25, 75]
    );
    
    this.subsection('4.2 Audio Libraries');
    this.codeBlock(`flutter_sound: ^9.28.0          # Audio recording/playback
flutter_audio_capture: ^1.1.2   # Low-level audio capture
audio_waveforms: ^2.0.2         # Waveform visualization`, 'yaml');
    
    this.subsection('4.3 Location Services');
    this.codeBlock(`geolocator: ^14.0.2             # GPS positioning
latlong2: ^0.9.1                # Coordinate calculations
flutter_map: ^8.2.2             # Interactive maps`, 'yaml');
    
    this.subsection('4.4 Backend Integration');
    this.codeBlock(`appwrite: ^20.3.3               # Appwrite SDK
dio: ^5.4.0                     # HTTP client
connectivity_plus: ^6.1.1       # Network status`, 'yaml');
    
    this.subsection('4.5 Sensors & Utilities');
    this.codeBlock(`sensors_plus: ^7.0.0            # Accelerometer, gyroscope
flutter_compass: ^0.8.1         # Magnetic compass
permission_handler: ^12.0.1     # Runtime permissions
uuid: ^4.5.2                    # UUID generation
intl: ^0.20.2                   # Internationalization`, 'yaml');
    
    // Section 5: Hardware & Software Specs
    this.newPage();
    this.sectionHeader(5, 'Hardware & Software Specifications');
    
    this.subsection('5.1 Mobile Device Requirements');
    this.table(
      ['Platform', 'Minimum', 'Recommended'],
      [
        ['Android OS', '6.0 (API 23)', '10.0+'],
        ['iOS', '12.0', '15.0+'],
        ['RAM', '2 GB', '4 GB'],
        ['Storage', '500 MB', '2 GB'],
        ['Processor', 'ARM64/x86_64', 'A9 chip or later'],
      ],
      [50, 65, 65]
    );
    
    this.subsection('5.2 Sensor Specifications');
    this.table(
      ['Sensor', 'Specification', 'Purpose'],
      [
        ['Microphone', '20Hz-20kHz, 44.1kHz, 16-bit', 'Audio capture'],
        ['GPS', '±5-10m accuracy, 1Hz', 'Location tagging'],
        ['Accelerometer', '±2g to ±16g, 50Hz', 'Device orientation'],
        ['Compass', '0.1° resolution, ±2°', 'Recording direction'],
      ],
      [45, 75, 60]
    );
    
    this.subsection('5.3 Network Requirements');
    this.bulletList([
      'Minimum: 2G/EDGE for basic data sync',
      'Recommended: 4G/LTE or WiFi for faster uploads',
      'Audio upload: ~1 MB/minute (WAV), ~200 KB/minute (compressed)',
      'Latency: <500ms for real-time features',
      'Full offline support with background sync when online',
    ]);
    
    this.subsection('5.4 Desktop Requirements');
    this.table(
      ['Platform', 'OS Version', 'RAM', 'Storage'],
      [
        ['Linux', 'Ubuntu 20.04+', '4 GB', '1 GB'],
        ['macOS', '10.14 (Mojave)+', '4 GB', '1 GB'],
        ['Windows', '10 (1809)+', '4 GB', '1 GB'],
      ],
      [45, 60, 35, 40]
    );
    
    this.subsection('5.5 Audio Format Specifications');
    this.codeBlock(`Format: WAV (PCM)
Sample Rate: 44100 Hz (recording), 16kHz/48kHz (ML inference)
Channels: Mono
Bit Depth: 16-bit
Encoding: Linear PCM`, 'text');
    
    // Section 6: Module Description
    this.newPage();
    this.sectionHeader(6, 'Module Description');
    
    this.subsection('6.1 Authentication Module');
    this.paragraph('Purpose: Handle user registration, login, and session management.');
    this.bulletList([
      'Email/password authentication',
      'Social login (Google, Apple) support',
      'Password reset functionality',
      'Session persistence with automatic token refresh',
    ]);
    
    this.subsection('6.2 Home (Recording) Module');
    this.paragraph('Core audio recording and analysis functionality with real-time processing.');
    this.bulletList([
      'Real-time waveform visualization and audio level meter',
      'Recording timer with minimum 15-second enforcement',
      'Live ML predictions during recording',
      'Automatic GPS tagging and speech detection',
    ]);
    
    this.subsection('6.3 Recording Pipeline');
    this.numberedList([
      'User taps record button → Request microphone permission',
      'Initialize audio capture (44.1kHz, mono)',
      'Start GPS tracking for location tagging',
      'Real-time waveform rendering and noise monitoring',
      'Buffer audio for YAMNet speech detection (>70% discards)',
      'User stops recording (minimum 15 seconds enforced)',
      'Save audio as WAV, trigger BirdNET analysis',
      'Store results locally, queue for cloud sync',
    ]);
    
    this.subsection('6.4 Recording State Machine');
    this.recordingStateDiagram();
    
    this.subsection('6.5 Library Module');
    this.paragraph('Browse, search, and manage saved recordings with multi-species indicators.');
    this.bulletList([
      'List all recordings with primary species and "+X more" indicator',
      'Search by species name, filter by date/confidence/location',
      'Swipe-to-delete and bulk selection',
      'Export recordings and sync status indicator',
    ]);
    
    this.newPage();
    this.subsection('6.6 Details Module');
    this.paragraph('Display comprehensive information about specific recordings with multi-species support.');
    this.bulletList([
      'Audio playback with waveform visualization',
      'Multi-species display with visual rankings (🏆🥈🥉)',
      'Detection statistics bar (species count, best match %, confidence)',
      'Color-coded confidence levels (Green→Blue→Orange→Grey)',
      'Species information from Wikipedia for all detected species',
      'Location map and share functionality',
    ]);
    
    this.subsection('6.7 Map Module');
    this.paragraph('Visualize recordings on interactive geographic maps.');
    this.bulletList([
      'Interactive OpenStreetMap with zoom/pan',
      'Clustered markers for dense areas',
      'Filter by species, date, and confidence',
      'Heatmap visualization for species density',
    ]);
    
    this.subsection('6.8 Noise Monitor Module');
    this.paragraph('Real-time ambient noise level measurement and classification.');
    this.table(
      ['dB Range', 'Classification', 'Example'],
      [
        ['0-30', 'Very Quiet', 'Whisper, rustling leaves'],
        ['30-60', 'Quiet', 'Normal conversation'],
        ['60-80', 'Moderate', 'Busy office, traffic'],
        ['80-100', 'Loud', 'Factory, lawn mower'],
        ['100+', 'Very Loud', 'Hearing damage risk'],
      ],
      [40, 60, 80]
    );
    
    this.subsection('6.9 Settings Module');
    this.paragraph('User preferences and app configuration including recording quality, ML model selection, theme settings, and data management.');
    
    this.subsection('6.10 Sync Module');
    this.paragraph('Background synchronization with intelligent network handling.');
    this.bulletList([
      'WiFi: Auto-upload all pending, download latest models',
      'Cellular: Upload only if enabled, compress before upload',
      'Offline: Queue operations, sync when connection restored',
      'Conflict resolution: Compare timestamps, newer version wins',
    ]);
    
    // Section 7: Data Flow Diagrams
    this.newPage();
    this.sectionHeader(7, 'Data Flow Diagrams');
    
    this.subsection('7.1 Context Diagram (Level 0)');
    this.paragraph('The context diagram shows SoundScape system interacting with external entities: User, Appwrite Backend, Wikipedia API, and Community Users.');
    this.dataFlowDiagram();
    
    this.subsection('7.2 Main Processes (Level 1)');
    this.paragraph('Level 1 DFD decomposes the system into six main processes that handle recording, analysis, storage, and synchronization.');
    this.dfdLevel1();
    
    this.newPage();
    this.subsection('7.3 Recording Process (Level 2)');
    this.paragraph('Detailed breakdown of the recording process from permission request to saving the audio file.');
    this.dfdLevel2Recording();
    
    this.subsection('7.4 Analysis Process (Level 2)');
    this.paragraph('The ML pipeline showing audio preprocessing, YAMNet filtering, BirdNET classification, and result generation.');
    this.mlPipelineDiagram();
    
    this.subsection('7.5 Sync Process (Level 2)');
    this.paragraph('Data synchronization flow from network check through upload and database entry creation.');
    this.dfdLevel2Sync();
    
    this.subsection('7.6 Data Stores');
    this.table(
      ['Store', 'Type', 'Contents'],
      [
        ['D1: Local DB', 'Hive', 'Recording metadata, preferences, offline queue'],
        ['D2: Audio Files', 'File System', 'WAV recordings, cached images'],
        ['D3: ML Models', 'Asset Bundle', 'YAMNet, BirdNET models'],
        ['D4: Cloud DB', 'Appwrite', 'User accounts, synced recordings'],
        ['D5: Cloud Storage', 'Appwrite', 'Audio files, images'],
      ],
      [45, 40, 95]
    );
    
    // Section 8: Database Design
    this.newPage();
    this.sectionHeader(8, 'Database Design');
    
    this.subsection('8.1 Local Database Schema (Hive)');
    this.codeBlock(`@HiveType(typeId: 0)
class Recording extends HiveObject {
  @HiveField(0) String id;              // UUID
  @HiveField(1) String filePath;        // Local file path
  @HiveField(2) double latitude;
  @HiveField(3) double longitude;
  @HiveField(4) DateTime timestamp;
  @HiveField(5) int duration;           // milliseconds
  @HiveField(6) String? commonName;     // Primary species
  @HiveField(7) double? confidence;     // 0.0 - 1.0
  @HiveField(8) String status;          // pending/processed/uploaded
  @HiveField(9) String? s3key;          // Cloud storage key
  @HiveField(10) Map<String, double>? predictions; // Top 5
}`, 'dart');
    
    this.subsection('8.2 Cloud Database Schema (Appwrite)');
    this.codeBlock(`{
  "$id": "unique()",
  "$collection": "recordings",
  "userId": "string",
  "commonName": "string",
  "scientificName": "string[]",
  "confidence": "float",
  "confidenceLevel": "integer[]",
  "latitude": "float",
  "longitude": "float",
  "timestamp": "datetime",
  "duration": "integer",
  "status": "enum(pending,processed,verified)",
  "s3key": "string",
  "predictions": "json"
}`, 'json');
    
    this.subsection('8.3 Database Indexes');
    this.bulletList([
      'userId_timestamp (userId ASC, timestamp DESC)',
      'commonName_confidence (commonName ASC, confidence DESC)',
      'location (latitude, longitude) - Geospatial index',
      'status_timestamp (status ASC, timestamp DESC)',
    ]);
    
    // Section 9: Machine Learning
    this.newPage();
    this.sectionHeader(9, 'Machine Learning Models');
    
    this.subsection('9.1 Multi-Model Architecture (v5.0.0)');
    this.paragraph('SoundScape utilizes a two-stage ML pipeline combining YAMNet for bird detection/filtering and BirdNET v2.4 for species classification.');
    
    this.subsection('9.2 YAMNet (Bird Pre-Filter)');
    this.table(
      ['Property', 'Value'],
      [
        ['Purpose', 'Fast bird detection to filter non-bird sounds'],
        ['Architecture', 'MobileNet-based CNN'],
        ['Source', 'TensorFlow Hub'],
        ['Input', 'Audio waveform @ 16kHz'],
        ['Output', '521 audio event classes'],
        ['Threshold', '0.3 (30% bird confidence)'],
        ['Processing Time', '~0.1-0.2s for 5s audio'],
      ],
      [55, 125]
    );
    
    this.subsection('9.3 BirdNET v2.4 (Species Classification)');
    this.table(
      ['Property', 'Value'],
      [
        ['Purpose', 'High-accuracy bird species identification'],
        ['Architecture', 'EfficientNet backbone CNN'],
        ['Source', 'Zenodo (Cornell Lab)'],
        ['Input', '3s spectrograms @ 48kHz'],
        ['Output', '6,522 global bird species'],
        ['Model Size', '~40MB (TFLite FP32)'],
        ['Processing Time', '~0.8-1.2s per 3s segment'],
      ],
      [55, 125]
    );
    
    this.subsection('9.4 Advanced Prediction Algorithms');
    this.paragraph('Overlapping Windows: 50% overlap (2.5s stride) for boundary detection, ensuring birds vocalizing near segment boundaries are detected.');
    this.paragraph('Temporal Smoothing: Dual-method smoothing using moving average convolution and exponential weighted average to reduce prediction jitter.');
    this.paragraph('Confidence Boosting: Up to 10% boost when both YAMNet and BirdNET agree on bird presence, increasing user trust in results.');
    
    this.newPage();
    this.subsection('9.5 Performance Metrics');
    this.table(
      ['Metric', 'v1.0 (BirdNET only)', 'v2.0 (Combined)', 'Improvement'],
      [
        ['Bird Detection Precision', '85%', '92%', '+7%'],
        ['Species Accuracy (Top-1)', '78%', '89%', '+11%'],
        ['Species Accuracy (Top-5)', '91%', '97%', '+6%'],
        ['Non-bird Rejection', '80%', '96%', '+16%'],
        ['Processing (bird audio)', '2.5s', '2.8s', '-12%'],
        ['Processing (non-bird)', '2.5s', '0.3s', '+88%'],
      ],
      [55, 50, 45, 30]
    );
    
    this.subsection('9.6 Latency Analysis (15s audio)');
    this.codeBlock(`Audio download:        0.5s
Preprocessing (16kHz): 0.2s
YAMNet pre-filter:     0.2s
Preprocessing (48kHz): 0.3s
BirdNET inference:     4.5s (6 chunks)
Temporal smoothing:    0.1s
Post-processing:       0.2s
─────────────────────────────
Total:                 ~6.0s

For non-bird audio:    ~0.9s (85% faster!)`, 'text');
    
    // Section 10: API Documentation
    this.newPage();
    this.sectionHeader(10, 'API Documentation');
    
    this.subsection('10.1 Appwrite REST API');
    this.paragraph('Base URL: https://fra.cloud.appwrite.io/v1');
    
    this.codeBlock(`Authentication:
POST /account/sessions/email     # Login
GET  /account/sessions/current   # Current session
DELETE /account/sessions/{id}    # Logout

Database:
POST   /databases/{db}/collections/{col}/documents
GET    /databases/{db}/collections/{col}/documents
PATCH  /databases/{db}/collections/{col}/documents/{id}
DELETE /databases/{db}/collections/{col}/documents/{id}

Storage:
POST /storage/buckets/{bucket}/files
GET  /storage/buckets/{bucket}/files/{id}/view
GET  /storage/buckets/{bucket}/files/{id}/download`, 'http');
    
    this.subsection('10.2 ML Classification API');
    this.codeBlock(`POST /classify/combined

Request:
  Content-Type: multipart/form-data
  file: audio file (WAV/M4A)

Response:
{
  "model": "combined",
  "bird_detected": true,
  "predictions": [
    {"class_name": "American Robin", "score": 0.89},
    {"class_name": "House Sparrow", "score": 0.45}
  ],
  "confidence_method": "boosted",
  "processing_time": 5.2,
  "audio_duration": 15.0
}`, 'json');
    
    this.subsection('10.3 Third-Party APIs');
    this.bulletList([
      'Wikipedia API: GET /api/rest_v1/page/summary/{species}',
      'OpenStreetMap: Tile server for flutter_map',
    ]);
    
    // Section 11: Future Enhancements
    this.newPage();
    this.sectionHeader(11, 'Future Enhancements');
    
    this.subsection('11.1 Short-term (3-6 months)');
    this.bulletList([
      'Spectrogram visualization with full frequency spectrum',
      'Sound event detection for individual calls within recordings',
      'Noise reduction pre-processing to enhance audio quality',
      'User profiles with achievements and statistics',
      'Comments, discussions, and verification system',
      'Leaderboards for top contributors',
    ]);
    
    this.subsection('11.2 Medium-term (6-12 months)');
    this.bulletList([
      'Custom model training for personal models',
      'Federated learning for privacy-preserving training',
      'Smart watch app for quick recording from wearables',
      'Web dashboard for browser-based analysis',
      'eBird integration for observation export',
      'GBIF export for Global Biodiversity Information Facility',
    ]);
    
    this.subsection('11.3 Long-term (1-2 years)');
    this.bulletList([
      'Migration tracking to visualize species movement',
      'Population trends and habitat analysis',
      'Image recognition combined with audio identification',
      'Multi-language support (20+ languages)',
      'Regional models specialized for different continents',
      'Natural language queries ("Show me robins near water")',
    ]);
    
    this.subsection('11.4 Technical Improvements');
    this.bulletList([
      'Background processing with queued analysis',
      'Incremental sync for changed data only',
      'End-to-end encryption for sensitive recordings',
      'Two-factor authentication',
      'CDN integration for faster global downloads',
      'GraphQL API for efficient data fetching',
    ]);
    
    // Section 12: Changelog
    this.newPage();
    this.sectionHeader(12, 'Version Changelog');
    
    this.subsection('12.1 Version 2.1.0 "Web Explorer"');
    this.paragraph('Release Date: February 3, 2026');
    this.bulletList([
      'NEW: Interactive web map interface with full-screen OpenStreetMap',
      'NEW: Details panel with animated slide-in sidebar',
      'NEW: Platform-aware routing (kIsWeb detection)',
      'NEW: Marker system with user location and recordings',
      'NEW: Playback controls in web details panel',
      'IMPROVED: All recordings displayed on map with click interaction',
    ]);
    
    this.subsection('12.2 Version 2.0.0 "Multi-Species"');
    this.paragraph('Release Date: February 3, 2026');
    this.bulletList([
      'MAJOR: Multi-species detection (up to 5 species per recording)',
      'MAJOR: Two-stage ML pipeline (YAMNet + BirdNET v2.4)',
      'NEW: Visual rankings with medal system (🏆🥈🥉)',
      'NEW: Color-coded confidence levels',
      'NEW: Detection statistics bar',
      'NEW: Temporal smoothing and confidence boosting',
      'IMPROVED: 88% faster processing for non-bird audio',
      'IMPROVED: +11% species accuracy (Top-1)',
    ]);
    
    this.subsection('12.3 API Version 5.0.0');
    this.bulletList([
      'NEW: POST /classify/combined endpoint',
      'NEW: Bird pre-filter with 0.3 threshold',
      'NEW: Overlapping windows (50% stride)',
      'NEW: Temporal smoothing algorithms',
      'NEW: Confidence boosting (up to 10%)',
      'OPTIMIZED: kaiser_fast resampling (30% speedup)',
    ]);
    
    // Section 13: Bibliography
    this.newPage();
    this.sectionHeader(13, 'Bibliography');
    
    this.subsection('13.1 Academic References');
    this.numberedList([
      'Kahl, S., et al. (2021). "BirdNET: A deep learning solution for avian diversity monitoring." Ecological Informatics, 61, 101236.',
      'Gemmeke, J.F., et al. (2017). "Audio Set: An ontology and human-labeled dataset for audio events." IEEE ICASSP, 776-780.',
      'Stowell, D., et al. (2019). "Automatic acoustic detection of birds through deep learning." Methods in Ecology and Evolution.',
      'Vellinga, W.P. & Planqué, R. (2015). "The Xeno-canto Collection and its Relation to Sound Recognition." CLEF Working Notes.',
    ]);
    
    this.subsection('13.2 Technical Documentation');
    this.numberedList([
      'Flutter Documentation (2024). Flutter Framework. https://flutter.dev/docs',
      'Dart Programming Language (2024). Dart Language Specification. https://dart.dev/guides',
      'Appwrite Documentation (2024). Appwrite BaaS. https://appwrite.io/docs',
      'TensorFlow Lite (2024). TFLite Guide. https://tensorflow.org/lite/guide',
      'GetX Documentation (2024). GetX State Management. https://pub.dev/packages/get',
    ]);
    
    this.subsection('13.3 Online Resources');
    this.bulletList([
      'Cornell Lab of Ornithology - Macaulay Library: https://macaulaylibrary.org',
      'Xeno-canto Foundation - Bird Sound Database: https://xeno-canto.org',
      'TensorFlow Hub - YAMNet: https://tfhub.dev/google/yamnet/1',
      'Zenodo - BirdNET v2.4: https://zenodo.org/records/15050749',
    ]);
    
    // Appendix A: Installation
    this.newPage();
    this.sectionHeader('A', 'Appendix A: Installation Guide');
    
    this.subsection('A.1 Prerequisites');
    this.bulletList([
      'Flutter SDK: 3.9.0 or higher',
      'Dart SDK: 3.9.0 or higher',
      'Android Studio / Xcode (for mobile development)',
      'Git for version control',
    ]);
    
    this.subsection('A.2 Clone and Install');
    this.codeBlock(`# Clone repository
git clone https://github.com/muhammedshabeerop/SoundScape.git
cd SoundScape/frontend

# Install dependencies
flutter pub get

# Configure Appwrite (edit appwrite.config.json)
{
  "projectId": "your-project-id",
  "endpoint": "https://fra.cloud.appwrite.io/v1",
  "databaseId": "your-database-id",
  "bucketId": "your-bucket-id"
}`, 'bash');
    
    this.subsection('A.3 Run Application');
    this.codeBlock(`# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Desktop
flutter run -d linux    # or macos, windows`, 'bash');
    
    this.subsection('A.4 Build for Production');
    this.codeBlock(`# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web
flutter build web --release`, 'bash');
    
    // Appendix B: Troubleshooting
    this.newPage();
    this.sectionHeader('B', 'Appendix B: Troubleshooting Guide');
    
    this.subsection('B.1 Common Issues');
    this.table(
      ['Issue', 'Solution'],
      [
        ['App crashes on recording', 'Ensure microphone permissions granted in device settings'],
        ['Species not identified', 'Record for at least 15 seconds in quiet environment'],
        ['GPS showing 0,0', 'Enable location services and wait for GPS signal'],
        ['Sync failing', 'Check internet connection and Appwrite credentials'],
        ['Low confidence scores', 'Move closer to bird, reduce background noise'],
        ['Model not loading', 'Reinstall app to restore bundled ML models'],
      ],
      [60, 120]
    );
    
    this.subsection('B.2 Performance Optimization');
    this.bulletList([
      'Close other apps to free RAM for ML inference',
      'Use WiFi for faster audio uploads',
      'Enable auto-upload only on WiFi to save mobile data',
      'Clear app cache periodically for storage management',
    ]);
    
    this.subsection('B.3 Contact & Support');
    this.bulletList([
      'GitHub Issues: https://github.com/muhammedshabeerop/SoundScape/issues',
      'Email: support@soundscape.app',
      'Documentation: COMPREHENSIVE_DOCUMENTATION.md',
    ]);
    
    // Final footer on last page
    this.y = this.pageHeight - 30;
    this.doc.setFontSize(8);
    this.setTextColor(COLORS.gray);
    this.doc.text('© 2026 SoundScape Project. MIT License.', this.pageWidth / 2, this.y, { align: 'center' });
    this.doc.text('Generated from COMPREHENSIVE_DOCUMENTATION.md', this.pageWidth / 2, this.y + 5, { align: 'center' });
    
    // Save PDF
    const buffer = this.doc.output('arraybuffer');
    fs.writeFileSync('SoundScape_Documentation.pdf', Buffer.from(buffer));
    console.log('✅ PDF generated: SoundScape_Documentation.pdf');
    console.log(`   Pages: ${this.pageNum}`);
  }
}

// Generate PDF
const pdf = new SoundScapePDF();
pdf.generate();
