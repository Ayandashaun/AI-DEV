# FirstFiveMinutes Indicator

Professional MetaTrader 5 indicator for trading the first 5-minute range breakout strategy with Fair Value Gap (FVG) confirmation.

## Overview

**FirstFiveMinutes** is a sophisticated trading indicator designed for day traders focusing on the US equity market open. It identifies and visualizes:

1. **First 5-Minute Range** - Two horizontal lines marking the high and low of the first 5-minute candle opening at 9:30 EST
2. **Fair Value Gaps (FVG)** - Unfilled price gaps identified through three-candle patterns, displayed as colored rectangles
3. **Engulfing Candles** - Complete engulfing candles marked with directional arrows for retest confirmation

## Strategy Context

The indicator supports a proven breakout strategy:
- **Primary Trade**: Breakout of the first 5-minute range on 1-minute timeframe
- **Confirmation**: FVG formation on breakout, engulfing candles on FVG retest
- **Optimal Use**: 1-minute and 5-minute charts during US market hours (9:30-16:00 EST)

## Installation

1. Copy `FirstFiveMinutes.mq5` to your MetaTrader 5 indicators folder:
   ```
   C:\Users\[Username]\AppData\Roaming\MetaQuotes\Terminal\[Terminal ID]\MQL5\Indicators\
   ```

2. Restart MetaTrader 5 or right-click on the Indicators folder and select "Refresh"

3. Attach to a 1-minute or 5-minute chart:
   - Insert → Indicators → FirstFiveMinutes

## Features

### First 5-Minute Range Lines
- **Automatic Detection**: Identifies the 9:30 EST candle automatically
- **Extended Lines**: Span from candle close until market close (16:00 EST)
- **Non-Repainting**: Lines lock in immediately after the first candle closes
- **Customizable**: Color, style, and thickness adjustable via inputs

### Fair Value Gap Detection
- **Definition**: Three consecutive candles where the third candle doesn't overlap the first candle's body
- **Types**: Bullish (gap up) and bearish (gap down) FVGs
- **Display**: Rectangles with semi-transparent fills for clarity
- **Timeframe**: Detected on 1-minute charts only (enabled on 5-minute too, but shows lines only)
- **Performance**: Limited to 100 most recent FVGs for optimal performance

### Engulfing Candle Detection
- **Definition**: Candles that completely engulf previous candle's high and low
- **Arrow Indicators**: Blue upward arrows for bullish, red downward for bearish
- **Spacing**: ATR(2)-based positioning for optimal visualization
- **Non-Repainting**: Arrows appear only after candle closes
- **Performance**: Limited to 100 most recent arrows

## Input Parameters

### First 5-Minute Range Lines
- **ShowFirstFiveMinLines** (bool): Enable/disable line display (default: true)
- **LineHighColor** (color): High line color (default: Green)
- **LineLowColor** (color): Low line color (default: Red)
- **LineStyle** (enum): Line drawing style - STYLE_SOLID, STYLE_DASHED, etc. (default: STYLE_DASHED)
- **LineThickness** (int): Line width in pixels, 1-5 (default: 2)

### Fair Value Gaps
- **ShowFVG** (bool): Enable/disable FVG rectangles (default: true)
- **BullishFVGColor** (color): Color for bullish gaps (default: Light green)
- **BearishFVGColor** (color): Color for bearish gaps (default: Light red)
- **FVGOpacity** (int): Rectangle transparency, 0-100 (default: 30)
- **MaxFVGsDisplay** (int): Maximum number of FVG rectangles to show (default: 100)

### Engulfing Candles
- **ShowEngulfing** (bool): Enable/disable engulfing arrows (default: true)
- **MaxEngulfingDisplay** (int): Maximum number of engulfing arrows to show (default: 100)
- **ArrowSize** (int): Arrow size multiplier, 1-5 (default: 5 - largest)
- **AtrPeriod** (int): ATR period for arrow spacing calculation (default: 2)
- **AtrMultiplier** (int): ATR multiplier for arrow offset (default: 2)

## Usage

### On 5-Minute Chart
1. Attach indicator to 5-minute chart
2. Observe first 5-minute range lines appear at 9:30 EST
3. Lines remain visible until 16:00 EST market close
4. Use for reference on your 1-minute trading

### On 1-Minute Chart
1. Attach indicator to 1-minute chart
2. First 5-minute range lines visible for reference
3. Monitor FVG rectangles for breakout confirmation
4. Use engulfing arrows to identify retest opportunities
5. Combine with your risk management rules for trade execution

## Algorithm Details

### Non-Repainting Guarantee
All drawings lock in immediately after their respective candles close:
- First 5-minute lines: After 9:30 EST candle closes
- FVG rectangles: After the third candle of the pattern closes
- Engulfing arrows: After the engulfing candle closes

### Performance Optimization
- Processing limited to 1000 bars per calculation cycle
- Object count limited to prevent MT5 lag
- Efficient array-based object management
- Session-aware detection prevents redundant calculations

### Time Zone Handling
- Reference time: 9:30 EST (hard-coded, works for US equities)
- Market close: 16:00 EST (hard-coded)
- Note: Adjust hour/minute constants in code for different sessions

## Troubleshooting

### Lines Not Appearing
- Verify attachment on 5-minute timeframe
- Check that current time is between 9:30-16:00 EST
- Ensure ShowFirstFiveMinLines input is set to true
- Check chart time zone settings

### FVG/Engulfing Not Showing
- Verify attachment on 1-minute timeframe
- Ensure ShowFVG and ShowEngulfing inputs are true
- First 5-minute lines must be detected first
- Check if maximum display counts are reached (increase MaxFVGsDisplay or MaxEngulfingDisplay)

### Indicator Not Compiling
- Verify MetaTrader 5 is fully updated
- Check that MQL5 ArrayObj library is available
- Ensure file is saved as .mq5 (not .mq4)
- Compile through MetaEditor (Tools → Compile)

## Known Limitations

1. **Time Zone**: Currently hardcoded for EST. For other time zones, modify the marketOpenHour, marketOpenMinute, marketCloseHour, marketCloseMinute constants in the code
2. **Horizontal Lines**: MT5 does not support transparency on horizontal lines - they remain fully opaque
3. **Chart Switching**: When switching between timeframes, some state may reset - reattach indicator if needed
4. **Weekend/Holidays**: Indicator has no built-in awareness of trading holidays

## Development

### Compiled File
The indicator is pre-compiled and ready to use. To recompile from source:

1. Open MetaEditor (Tools → Edit)
2. Navigate to the FirstFiveMinutes.mq5 file
3. Click Compile (or Ctrl+F5)
4. Load compiled indicator onto chart

### Source Code Repository
- **GitHub**: https://github.com/Ayandashaun/AI-DEV
- **Structure**: FirstFiveMinutes folder contains spec.md, log.md, and the indicator source
- **History**: Full commit history available for tracking development

## Technical Specifications

| Property | Value |
|----------|-------|
| **Platform** | MetaTrader 5 |
| **Language** | MQL5 |
| **Chart Window** | Indicator subwindow (chart overlay) |
| **Timeframes** | 1-minute, 5-minute |
| **Objects** | Horizontal lines, rectangles, arrow symbols |
| **Version** | 1.0 |

## Disclaimer

This indicator is provided for educational and informational purposes only. Past performance does not guarantee future results. Always backtest strategies thoroughly and use proper risk management. The author assumes no liability for losses incurred through use of this indicator.

## Support

For issues, questions, or feature requests:
1. Check troubleshooting section above
2. Review spec.md for detailed specifications
3. Review log.md for development history and technical notes
4. Consult the GitHub repository for updates

---

**Last Updated**: 2026-05-13  
**Indicator Version**: 1.0  
**Repository**: https://github.com/Ayandashaun/AI-DEV
