# FirstFiveMinutes Indicator - Specification

## Problem Statement
Build an indicator for MetaTrader 5 that identifies trading opportunities based on the first 5-minute candle of the trading day. The indicator supports a breakout strategy that trades breakout of the first 5-minute range on the 1-minute timeframe, using Fair Value Gaps (FVG) on breakout and engulfing candles on FVG retest as confirmation.

## User Context
- **Strategy**: Trades breakout of first 5-minute range on 1m timeframe
- **Confirmation**: Uses FVG on breakout and engulfing on FVG retest
- **Platform**: MetaTrader 5
- **Supported Timeframes**: 1-minute and 5-minute charts

---

## Feature Specifications

### 1. First 5-Minute Range Lines
**Objective**: Draw two horizontal lines representing the high and low of the first 5-minute candle of the trading day.

**Requirements**:
- **Time Reference**: 9:30 EST (market open for US equities/forex sessions)
- **Logic**: 
  - Detect the first 5-minute candle that opens at or after 9:30 EST
  - Extract the high and low of this candle
  - If market opens late or gaps, use the first candle after market open
- **Drawing**:
  - High line: Displayed in one color (e.g., green or custom)
  - Low line: Displayed in another color (e.g., red or custom)
  - Lines span from candle close until market close (16:00 EST)
- **Properties**:
  - Non-repainting: Lines lock in immediately after the first 5-minute candle closes
  - Line style: Dashed or solid (user configurable via inputs)
  - Line thickness: 2 pixels (user configurable)

**Availability**: Visible on all supported timeframes

---

### 2. Fair Value Gap (FVG) Detection and Visualization

**Objective**: Identify and highlight FVGs formed after market open on 1-minute charts.

**FVG Definition**:
- Three consecutive candles where the third candle's body does NOT overlap with the first candle's body
- FVG is formed when:
  - **Bullish FVG**: Gap up (first candle low > third candle high)
  - **Bearish FVG**: Gap down (first candle high < third candle low)

**Requirements**:
- **Detection**: Scan for FVGs only after the first 5-minute candle completes
- **Timeframe**: Only detect and display FVGs on 1-minute charts (to avoid clutter)
- **Visualization**:
  - Draw rectangles representing the gap zone
  - Bullish FVG: Light green rectangle (custom color, semi-transparent)
  - Bearish FVG: Light red rectangle (custom color, semi-transparent)
  - Rectangle height: Gap distance
  - Rectangle width: Extends from third candle open to a defined forward extent (e.g., 50 candles ahead or until filled)

**Properties**:
- Non-repainting: FVG rectangles lock in after the third candle closes
- Maximum visible FVGs: Limit to last 100 to prevent performance degradation
- User can toggle FVG visibility via input

---

### 3. Engulfing Candle Detection and Arrow Indicators

**Objective**: Identify engulfing candles formed after market open and mark them with directional arrows.

**Engulfing Definition**:
- **Bullish Engulfing**: Current candle completely engulfs both body AND wicks of the previous candle (current low < prev low AND current high > prev high)
- **Bearish Engulfing**: Current candle completely engulfs both body AND wicks of the previous candle (current high < prev high AND current low > prev low)

**Requirements**:
- **Detection**: Scan for engulfing candles only after the first 5-minute candle completes
- **Timeframe**: Detect on 1-minute charts only
- **Arrow Styling**:
  - **Bullish Engulfing**: Blue upward arrow below the candle
  - **Bearish Engulfing**: Red downward arrow below the candle
  - Arrow Size: ENUM_ARROW_ANCHOR_TOP (largest available size)
  - Spacing from Candle: ATR(2) * 2 pips below candle low (bullish) or above candle high (bearish)

**Properties**:
- Non-repainting: Arrows appear after the engulfing candle closes
- User can toggle engulfing arrow visibility via input
- Maximum visible arrows: Limit to last 100 to prevent performance degradation

---

## Input Parameters

```
// First 5-Minute Range Lines
input bool ShowFirstFiveMinLines = true;           // Show first 5-min high/low lines
input color LineHighColor = clrGreen;              // High line color
input color LineLowColor = clrRed;                 // Low line color
input ENUM_LINE_STYLE LineStyle = STYLE_DASHED;   // Line style
input int LineThickness = 2;                       // Line thickness (1-5)

// Fair Value Gaps
input bool ShowFVG = true;                         // Show FVG rectangles
input color BullishFVGColor = C'144, 238, 144';    // Bullish FVG color (light green)
input color BearishFVGColor = C'255, 192, 192';    // Bearish FVG color (light red)
input int FVGOpacity = 30;                         // FVG rectangle opacity (0-100)
input int MaxFVGsDisplay = 100;                    // Maximum FVGs to display

// Engulfing Candles
input bool ShowEngulfing = true;                   // Show engulfing arrows
input int MaxEngulfingDisplay = 100;               // Maximum engulfing arrows to display
input int ArrowSize = 3;                           // Arrow size (1-5, 5 is largest)
input int AtrPeriod = 2;                           // ATR period for arrow spacing
input int AtrMultiplier = 2;                       // ATR multiplier for arrow spacing

// Time Zone Settings
input string TimeZone = "US/Eastern";              // Time zone for 9:30 EST reference
```

---

## Algorithm Overview

### Initialization
1. On indicator initialization, store the session start time (9:30 EST) and session end time (16:00 EST)
2. Initialize buffers for lines, rectangles, and arrows
3. Set up color and style variables from input parameters

### On Each New Bar
1. **Detect First 5-Minute Candle**:
   - Check if current bar is on 5-minute chart
   - Verify if current bar opens at or after 9:30 EST
   - If yes and not already marked, lock in the high/low and draw lines

2. **Detect FVGs** (1-minute chart only):
   - Look back 3 candles (i, i-1, i-2)
   - Check if candles meet FVG criteria (gap between candle 1 and candle 3)
   - If FVG detected and bar index > first5MinIndex, draw rectangle
   - Maintain a queue of recent FVGs, limit to MaxFVGsDisplay

3. **Detect Engulfing Candles** (1-minute chart only):
   - Compare current candle high/low with previous candle high/low
   - Check if current candle engulfs previous (both directions)
   - If engulfing and bar index > first5MinIndex, calculate arrow position using ATR
   - Draw arrow at calculated position
   - Maintain a queue of recent arrows, limit to MaxEngulfingDisplay

4. **Line Management**:
   - Extend lines until 16:00 EST (market close)
   - After market close, lines remain visible for reference until next session

### Non-Repainting Logic
- All drawings lock in immediately after their respective candles close
- No historical modifications once drawn
- Arrow/rectangle/line positions are fixed once placed

---

## Git Workflow

### Step 1: Initialize Local Git Repository
```bash
cd C:\Users\User\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Indicators\AI DEV\FirstFiveMinutes
git init
git config user.name "Developer"
git config user.email "dev@local.com"
```

### Step 2: Create Initial Commit
```bash
git add .
git commit -m "Initial commit: FirstFiveMinutes indicator spec and logging setup"
```

### Step 3: Create Remote Repository on GitHub
```bash
gh repo create AI-DEV --public --source=. --remote=origin --push
```

### Step 4: Folder Structure in Repository
The repository `AI-DEV` will contain:
```
AI-DEV/
├── FirstFiveMinutes/          (This folder)
│   ├── spec.md               (This specification)
│   ├── log.md                (Development log)
│   ├── FirstFiveMinutes.mq5  (Main indicator code)
│   └── README.md             (Optional: Quick reference)
└── .gitignore                (Exclude unnecessary files)
```

---

## Development Phases

### Phase 1: Setup and Planning (COMPLETED)
- [x] Create spec.md with full specifications
- [x] Create log.md for development tracking
- [ ] Set up git repository

### Phase 2: Core Development
- [ ] Implement first 5-minute line detection and drawing
- [ ] Implement FVG detection algorithm
- [ ] Implement FVG rectangle drawing
- [ ] Implement engulfing candle detection algorithm
- [ ] Implement engulfing arrow drawing

### Phase 3: Refinement
- [ ] Add all input parameters
- [ ] Implement non-repainting logic
- [ ] Add error handling and validation
- [ ] Optimize performance

### Phase 4: Testing & Deployment
- [ ] Compile indicator in MetaTrader 5
- [ ] Test on 1-minute chart
- [ ] Test on 5-minute chart
- [ ] Verify line drawing at market open
- [ ] Verify FVG detection accuracy
- [ ] Verify engulfing candle detection accuracy
- [ ] Push final version to GitHub

### Phase 5: Documentation
- [ ] Complete README.md with usage instructions
- [ ] Document any known limitations
- [ ] Document future enhancement ideas

---

## Success Criteria

1. ✓ Lines appear exactly at first 5-minute candle high/low
2. ✓ Lines remain visible until 16:00 EST
3. ✓ FVGs are accurately detected on 1-minute timeframe only
4. ✓ FVG rectangles are visible and properly colored
5. ✓ Engulfing candles are accurately detected on 1-minute timeframe only
6. ✓ Arrows appear with correct color (blue bullish, red bearish)
7. ✓ Arrows spaced correctly using ATR(2) * 2
8. ✓ No repainting occurs across all features
9. ✓ Indicator compiles without errors
10. ✓ Repository pushed to GitHub with proper structure

---

## Notes
- All times referenced are in EST (Eastern Standard Time)
- Indicator designed for US equity market sessions (9:30-16:00 EST)
- Non-repainting ensures reliable strategy backtesting and live trading
- Performance optimized by limiting displayed objects to maximize counts
