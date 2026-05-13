//+------------------------------------------------------------------+
//|                            FirstFiveMinutes.mq5                  |
//|              Trading Strategy Indicator for MetaTrader 5          |
//| Detects first 5-minute range, FVGs, and engulfing candles        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link      "https://github.com/Ayandashaun/AI-DEV"
#property version   "1.0"
#property indicator_chart_window
#property strict

#include <Arrays/ArrayObj.mqh>

//+------------------------------------------------------------------+
// INPUT PARAMETERS
//+------------------------------------------------------------------+

// First 5-Minute Range Lines
input bool ShowFirstFiveMinLines = true;
input color LineHighColor = clrGreen;
input color LineLowColor = clrRed;
input ENUM_LINE_STYLE LineStyle = STYLE_DASHED;
input int LineThickness = 2;

// Fair Value Gaps
input bool ShowFVG = true;
input color BullishFVGColor = C'144, 238, 144';
input color BearishFVGColor = C'255, 192, 192';
input int FVGOpacity = 30;
input int MaxFVGsDisplay = 100;

// Engulfing Candles
input bool ShowEngulfing = true;
input int MaxEngulfingDisplay = 100;
input int ArrowSize = 5;
input int AtrPeriod = 2;
input int AtrMultiplier = 2;

//+------------------------------------------------------------------+
// GLOBAL VARIABLES
//+------------------------------------------------------------------+

bool first5MinDetected = false;
datetime firstCandleTime = 0;
double first5MinHigh = 0;
double first5MinLow = 0;
datetime first5MinSessionDate = 0;  // Track session date instead of bar index

// Lines for first 5-min
string lineHighName = "";
string lineLowName = "";

// FVG tracking
CArrayObj fvgArray;
int fvgCount = 0;

// Engulfing tracking
CArrayObj engulfingArray;
int engulfingCount = 0;

// Time constants (EST times)
int marketOpenHour = 9;
int marketOpenMinute = 30;
int marketCloseHour = 16;
int marketCloseMinute = 0;

// ATR buffer
double atrBuffer[];

//+------------------------------------------------------------------+
// INDICATOR INITIALIZATION
//+------------------------------------------------------------------+

int OnInit()
{
   // Resize ATR buffer
   ArraySetAsSeries(atrBuffer, true);
   ArrayResize(atrBuffer, AtrPeriod + 1);
   
   // Initialize object arrays
   fvgArray.Clear();
   engulfingArray.Clear();
   
   // Generate unique line names based on current session
   lineHighName = "FFM_LineHigh_" + TimeToString(iTime(_Symbol, PERIOD_D1, 0), TIME_DATE);
   lineLowName = "FFM_LineLow_" + TimeToString(iTime(_Symbol, PERIOD_D1, 0), TIME_DATE);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
// INDICATOR DEINITIALIZATION
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   // Clean up objects on deinitialization if needed
   // Lines and shapes can be left for reference
}

//+------------------------------------------------------------------+
// MAIN CALCULATION FUNCTION
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Only work on 1-minute or 5-minute timeframes
   ENUM_TIMEFRAMES currentTF = _Period;
   if(currentTF != PERIOD_M1 && currentTF != PERIOD_M5)
   {
      return prev_calculated;
   }
   
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   int limit = rates_total - prev_calculated;
   if(limit > 1000) limit = 1000; // Limit processing for performance
   
    for(int i = limit; i >= 1; i--)
    {
       // Detect first 5-minute candle
       if(currentTF == PERIOD_M5)
       {
          // Check if this is a new session
          datetime sessionDate = iTime(_Symbol, PERIOD_D1, i);
          if(sessionDate != first5MinSessionDate)
          {
             first5MinDetected = false;  // New session, allow detection
          }
          
          if(!first5MinDetected && IsFirstFiveMinBar(time[i]))
          {
             first5MinDetected = true;
             firstCandleTime = time[i];
             first5MinHigh = high[i];
             first5MinLow = low[i];
             first5MinSessionDate = sessionDate;
             
             if(ShowFirstFiveMinLines)
             {
                DrawFirstFiveMinLines();
             }
          }
       }
       
       // Detect FVGs on 1-minute timeframe only
       if(currentTF == PERIOD_M1 && first5MinDetected && ShowFVG && i >= 3)
       {
          if(DetectFVG(high, low, close, i))
          {
             // FVG detected and drawn
          }
       }
       
       // Detect engulfing candles on 1-minute timeframe only
       if(currentTF == PERIOD_M1 && first5MinDetected && ShowEngulfing && i >= 2)
       {
          if(DetectEngulfing(high, low, close, i, time))
          {
             // Engulfing detected and drawn
          }
       }
       
       // Update first 5-min lines if they exist
       if(ShowFirstFiveMinLines && first5MinDetected && currentTF == PERIOD_M5)
       {
          UpdateFirstFiveMinLines(time[i]);
       }
    }
   
   return rates_total;
}

//+------------------------------------------------------------------+
// HELPER FUNCTIONS
//+------------------------------------------------------------------+

// Check if bar is the first 5-minute candle at 9:30 EST
bool IsFirstFiveMinBar(datetime barTime)
{
   MqlDateTime dt;
   TimeToStruct(barTime, dt);
   
   // Check if it's 9:30 EST
   if(dt.hour == marketOpenHour && dt.min == marketOpenMinute)
   {
      return true;
   }
   
   return false;
}

// Detect Fair Value Gap (bullish or bearish)
bool DetectFVG(const double &high[], const double &low[], const double &close[], int barIndex)
{
   // i = current bar, i+1 = previous bar, i+2 = bar before previous
   int i1 = barIndex;
   int i2 = barIndex + 1;
   int i3 = barIndex + 2;
   
   if(i3 >= ArraySize(high))
      return false;
   
   // Check for bullish FVG (gap up)
   // Condition: low[i3] > high[i1]
   if(low[i3] > high[i1])
   {
      // Draw bullish FVG rectangle
      double fvgTop = low[i3];
      double fvgBottom = high[i1];
      
      DrawFVGRectangle(barIndex, fvgTop, fvgBottom, true);
      return true;
   }
   
   // Check for bearish FVG (gap down)
   // Condition: high[i3] < low[i1]
   if(high[i3] < low[i1])
   {
      // Draw bearish FVG rectangle
      double fvgTop = low[i1];
      double fvgBottom = high[i3];
      
      DrawFVGRectangle(barIndex, fvgTop, fvgBottom, false);
      return true;
   }
   
   return false;
}

// Draw FVG rectangle
void DrawFVGRectangle(int barIndex, double top, double bottom, bool isBullish)
{
   if(fvgCount >= MaxFVGsDisplay)
      return;
   
   string rectName = "FFM_FVG_" + IntToString(barIndex) + "_" + IntToString(fvgCount);
   
   // Get time for rectangle
   datetime currentTime = iTime(_Symbol, _Period, barIndex);
   datetime futureTime = iTime(_Symbol, _Period, barIndex > 50 ? barIndex - 50 : 0);
   
   if(futureTime == 0)
      futureTime = currentTime + PeriodSeconds(_Period) * 50;
   
   color rectColor = isBullish ? BullishFVGColor : BearishFVGColor;
   
   // Create rectangle object
   if(ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, currentTime, top, futureTime, bottom))
   {
      ObjectSetInteger(0, rectName, OBJPROP_FILL, true);
      ObjectSetInteger(0, rectName, OBJPROP_FILLTRANSPARENCY, FVGOpacity);
      ObjectSetInteger(0, rectName, OBJPROP_COLOR, rectColor);
      ObjectSetInteger(0, rectName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, rectName, OBJPROP_BACK, true);
      fvgCount++;
   }
}

// Detect engulfing candles
bool DetectEngulfing(const double &high[], const double &low[], const double &close[], int barIndex, const datetime &time[])
{
   int currentBar = barIndex;
   int previousBar = barIndex + 1;
   
   if(previousBar >= ArraySize(high))
      return false;
   
   bool isBullishEngulf = false;
   bool isBearishEngulf = false;
   
   // Check for bullish engulfing
   // Current candle low < previous candle low AND current candle high > previous candle high
   if(low[currentBar] < low[previousBar] && high[currentBar] > high[previousBar])
   {
      isBullishEngulf = true;
   }
   
   // Check for bearish engulfing
   // Current candle high < previous candle high AND current candle low > previous candle low
   if(high[currentBar] < high[previousBar] && low[currentBar] > low[previousBar])
   {
      isBearishEngulf = true;
   }
   
   if(isBullishEngulf || isBearishEngulf)
   {
      DrawEngulfingArrow(barIndex, isBullishEngulf, low[currentBar], high[currentBar]);
      return true;
   }
   
   return false;
}

// Draw engulfing arrow
void DrawEngulfingArrow(int barIndex, bool isBullish, double candleLow, double candleHigh)
{
   if(engulfingCount >= MaxEngulfingDisplay)
      return;
   
   // Calculate arrow position using ATR
   double atr = CalculateATR(barIndex);
   double arrowOffset = atr * AtrMultiplier * Point();
   
   // Arrow position
   double arrowPrice;
   if(isBullish)
   {
      arrowPrice = candleLow - arrowOffset;
   }
   else
   {
      arrowPrice = candleHigh + arrowOffset;
   }
   
   string arrowName = "FFM_Engulf_" + IntToString(barIndex) + "_" + IntToString(engulfingCount);
   datetime arrowTime = iTime(_Symbol, _Period, barIndex);
   
   // Create arrow
   int arrowCode = isBullish ? 241 : 242; // 241=up arrow, 242=down arrow
   
   if(ObjectCreate(0, arrowName, OBJ_ARROW, 0, arrowTime, arrowPrice))
   {
      ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, isBullish ? clrBlue : clrRed);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, ArrowSize);
      ObjectSetInteger(0, arrowName, OBJPROP_BACK, false);
      engulfingCount++;
   }
}

// Calculate ATR for arrow spacing
double CalculateATR(int barIndex)
{
   double atr = iATR(_Symbol, _Period, AtrPeriod, barIndex);
   
   // Fallback if iATR fails
   if(atr <= 0)
   {
      atr = High[barIndex] - Low[barIndex];
   }
   
   return atr;
}

// Draw first 5-minute lines
void DrawFirstFiveMinLines()
{
   // Draw high line
   if(ObjectCreate(0, lineHighName, OBJ_HLINE, 0, 0, first5MinHigh))
   {
      ObjectSetInteger(0, lineHighName, OBJPROP_COLOR, LineHighColor);
      ObjectSetInteger(0, lineHighName, OBJPROP_STYLE, LineStyle);
      ObjectSetInteger(0, lineHighName, OBJPROP_WIDTH, LineThickness);
      ObjectSetInteger(0, lineHighName, OBJPROP_BACK, true);
   }
   
   // Draw low line
   if(ObjectCreate(0, lineLowName, OBJ_HLINE, 0, 0, first5MinLow))
   {
      ObjectSetInteger(0, lineLowName, OBJPROP_COLOR, LineLowColor);
      ObjectSetInteger(0, lineLowName, OBJPROP_STYLE, LineStyle);
      ObjectSetInteger(0, lineLowName, OBJPROP_WIDTH, LineThickness);
      ObjectSetInteger(0, lineLowName, OBJPROP_BACK, true);
   }
}

// Update first 5-minute lines (extend until market close)
void UpdateFirstFiveMinLines(datetime barTime)
{
   MqlDateTime dt;
   TimeToStruct(barTime, dt);
   
   // Check if we've reached market close time
   if(dt.hour >= marketCloseHour && dt.min >= marketCloseMinute)
   {
      // Lines remain until next session
   }
   
   // Keep lines visible - no update needed as horizontal lines persist
}

//+------------------------------------------------------------------+
