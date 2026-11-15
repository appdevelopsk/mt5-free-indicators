//+------------------------------------------------------------------+
//|                                         FXEA_Spread_Monitor.mq5  |
//|                                                        FXEA365   |
//|         Spread and cost monitor panel                            |
//+------------------------------------------------------------------+
#property copyright "FXEA365"
#property link      "https://www.mql5.com/en/users/app.develop.sk"
#property version   "1.00"
#property description "Spread and cost monitor panel."
#property description "Shows the live spread and the cost per 1 lot on the chart."
#property indicator_chart_window
#property indicator_plots   0
#property indicator_buffers 0

input long              InpWarnSpread = 30;            // Spread warning level (points)
input ENUM_BASE_CORNER  InpCorner     = CORNER_RIGHT_LOWER; // Panel corner
input int               InpX          = 20;            // X position (px)
input int               InpY          = 20;            // Y position (px)
input int               InpFontSize   = 10;            // Font size
input color             InpTextColor  = clrWhiteSmoke; // Text colour
input color             InpValueColor = clrGold;       // Value colour
input color             InpOkColor    = clrLimeGreen;  // Normal colour
input color             InpWarnColor  = clrTomato;     // Colour when expanding
input color             InpBgColor    = clrBlack;      // Panel background colour

string g_prefix   = "FXEA_SPM_";
string g_labels[] = {"Spread now","Average spread","Cost per 1 lot","Status"};
int    g_rows     = 4;
double g_sumSpread = 0.0;
long   g_count     = 0;
double g_k = 1.0;   // DPI scale (1.0 at 96 dpi)
int    g_w = 0;     // panel width in pixels
int    g_h = 0;     // panel height in pixels
//+------------------------------------------------------------------+
int S(int v) { return((int)MathRound(v*g_k)); }
//--- panel-local coordinates -> distances from the selected chart corner
int PX(int lx)
{
   bool right = (InpCorner==CORNER_RIGHT_UPPER || InpCorner==CORNER_RIGHT_LOWER);
   return(right ? S(InpX)+g_w-lx : S(InpX)+lx);
}
int PY(int ly)
{
   bool lower = (InpCorner==CORNER_LEFT_LOWER || InpCorner==CORNER_RIGHT_LOWER);
   return(lower ? S(InpY)+g_h-ly : S(InpY)+ly);
}

//+------------------------------------------------------------------+
int OnInit()
{
   BuildPanel();
   EventSetTimer(2);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0,g_prefix);
   ChartRedraw();
}
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   g_sumSpread += (double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
   g_count++;
   RefreshPanel();
   return(rates_total);
}
//+------------------------------------------------------------------+
void OnTimer()
{
   RefreshPanel();
}
//+------------------------------------------------------------------+
void BuildPanel()
{
   g_k = TerminalInfoInteger(TERMINAL_SCREEN_DPI)/96.0;
   int pad  = S(10);
   int rowH = S(InpFontSize + 12);
   g_w = S(250);
   g_h = rowH*(g_rows+1) + 2*pad;
   RectLabel(g_prefix+"BG",PX(0),PY(0),g_w,g_h,InpBgColor);
   TextLabel(g_prefix+"TITLE",PX(pad),PY(pad),"Spread Monitor",InpTextColor);
   for(int i=0;i<g_rows;i++)
   {
      int y = pad + rowH*(i+1);
      TextLabel(g_prefix+"L"+(string)i,PX(pad),PY(y),g_labels[i],InpTextColor);
      TextLabel(g_prefix+"V"+(string)i,PX(pad+S(120)),PY(y),"-",InpValueColor);
   }
   RefreshPanel();
}
//+------------------------------------------------------------------+
void RefreshPanel()
{
   long   spr      = SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
   double pip      = (_Digits==3 || _Digits==5) ? _Point*10.0 : _Point;
   double sprPips  = spr*_Point/pip;
   double sprPrice = spr*_Point;
   double tickVal  = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tickSz   = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double cost     = (tickSz>0) ? sprPrice/tickSz*tickVal : 0.0;
   double avgSpr   = (g_count>0) ? g_sumSpread/g_count : (double)spr;
   string cur      = AccountInfoString(ACCOUNT_CURRENCY);

   SetValue(0,DoubleToString(sprPips,1)+" pips ("+(string)spr+" pt)",InpValueColor);
   SetValue(1,DoubleToString(avgSpr*_Point/pip,1)+" pips",InpValueColor);
   SetValue(2,DoubleToString(cost,2)+" "+cur,InpValueColor);

   if(spr>InpWarnSpread) SetValue(3,"Wide",InpWarnColor);
   else                  SetValue(3,"Normal",  InpOkColor);

   ChartRedraw();
}
//+------------------------------------------------------------------+
void SetValue(int row,string text,color clr)
{
   string name = g_prefix+"V"+(string)row;
   ObjectSetString (0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
}
//+------------------------------------------------------------------+
void TextLabel(string name,int x,int y,string text,color clr)
{
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,InpCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,InpFontSize);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}
//+------------------------------------------------------------------+
void RectLabel(string name,int x,int y,int w,int h,color bg)
{
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,InpCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_COLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}
//+------------------------------------------------------------------+
