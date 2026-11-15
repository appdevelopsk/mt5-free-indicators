//+------------------------------------------------------------------+
//|                                       FXEA_Currency_Strength.mq5 |
//|                                                        FXEA365   |
//|         Currency strength meter                                  |
//+------------------------------------------------------------------+
#property copyright "FXEA365"
#property link      "https://www.mql5.com/en/users/app.develop.sk"
#property version   "1.00"
#property description "Currency strength meter."
#property description "Ranks the 8 major currencies by relative strength on the chart."
#property description "Set InpSuffix if your broker adds a suffix to symbol names."
#property indicator_chart_window
#property indicator_plots   0
#property indicator_buffers 0

input int               InpLookback  = 24;             // Bars used for the rate-of-change calculation
input ENUM_TIMEFRAMES   InpTimeframe = PERIOD_H1;       // Timeframe used for the calculation
input string            InpSuffix    = "";             // Broker symbol suffix (e.g. .raw or m)
input ENUM_BASE_CORNER  InpCorner    = CORNER_LEFT_UPPER; // Panel corner
input int               InpX         = 20;             // X position (px)
input int               InpY         = 30;             // Y position (px)
input int               InpFontSize  = 10;             // Font size
input color             InpUpColor   = clrLimeGreen;   // Strong-currency colour
input color             InpDownColor = clrTomato;      // Weak-currency colour
input color             InpTextColor = clrWhiteSmoke;  // Text colour
input color             InpBgColor   = clrBlack;       // Panel background colour

string g_prefix = "FXEA_CSM_";
string g_cur[]  = {"USD","EUR","GBP","JPY","AUD","NZD","CAD","CHF"};
int    g_n      = 8;
int    g_barmax = 110;
int    g_bar    = 110;   // bar length in pixels after DPI scaling
double g_k = 1.0;   // DPI scale (1.0 at 96 dpi)
int    g_w = 0;     // panel width in pixels
int    g_h = 0;     // panel height in pixels
//+------------------------------------------------------------------+
//| Scale a pixel size by the screen DPI                             |
//+------------------------------------------------------------------+
int S(int v)
  {
   return((int)MathRound(v*g_k));
  }
//+------------------------------------------------------------------+
//| Panel X coordinate to distance from the chart corner             |
//+------------------------------------------------------------------+
int PX(int lx)
  {
   bool right = (InpCorner==CORNER_RIGHT_UPPER || InpCorner==CORNER_RIGHT_LOWER);
   return(right ? S(InpX)+g_w-lx : S(InpX)+lx);
  }
//+------------------------------------------------------------------+
//| Panel Y coordinate to distance from the chart corner             |
//+------------------------------------------------------------------+
int PY(int ly)
  {
   bool lower = (InpCorner==CORNER_LEFT_LOWER || InpCorner==CORNER_RIGHT_LOWER);
   return(lower ? S(InpY)+g_h-ly : S(InpY)+ly);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   BuildPanel();
   EventSetTimer(10);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0,g_prefix);
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
  {
   RefreshPanel();
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   RefreshPanel();
  }
//+------------------------------------------------------------------+
//| Create the panel objects                                         |
//+------------------------------------------------------------------+
void BuildPanel()
  {
   g_k   = TerminalInfoInteger(TERMINAL_SCREEN_DPI)/96.0;
   g_bar = S(g_barmax);
   int pad  = S(10);
   int rowH = S(InpFontSize + 14);
   g_w = S(46) + g_bar + S(70) + 2*pad;
   g_h = rowH*(g_n+1) + 2*pad;
   RectLabel(g_prefix+"BG",PX(0),PY(0),g_w,g_h,InpBgColor);
   TextLabel(g_prefix+"TITLE",PX(pad),PY(pad),"Currency Strength",InpTextColor);
   for(int r=0;r<g_n;r++)
     {
      int y = pad + rowH*(r+1);
      TextLabel(g_prefix+"C"+(string)r,PX(pad),PY(y),"-",InpTextColor);
      BarLabel (g_prefix+"B"+(string)r,PX(pad+S(46)),PY(y+S(3)),1,S(InpFontSize),InpUpColor);
      TextLabel(g_prefix+"V"+(string)r,PX(pad+S(46)+g_bar+S(8)),PY(y),"-",InpTextColor);
     }
   RefreshPanel();
  }
//+------------------------------------------------------------------+
//| Calculate the strength of each currency                          |
//+------------------------------------------------------------------+
void Compute(double &str[])
  {
   ArrayResize(str,g_n);
   ArrayInitialize(str,0.0);
   int cnt[];
   ArrayResize(cnt,g_n);
   ArrayInitialize(cnt,0);
   for(int i=0;i<g_n;i++)
      for(int j=0;j<g_n;j++)
        {
         if(i==j) continue;
         string sym = g_cur[i]+g_cur[j]+InpSuffix;
         if(!SymbolSelect(sym,true)) continue;
         double c0[1],cN[1];
         if(CopyClose(sym,InpTimeframe,0,1,c0)!=1) continue;
         if(CopyClose(sym,InpTimeframe,InpLookback,1,cN)!=1) continue;
         if(cN[0]<=0.0) continue;
         double chg = (c0[0]-cN[0])/cN[0]*100.0;
         str[i]+=chg; cnt[i]++;
         str[j]-=chg; cnt[j]++;
        }
   for(int i=0;i<g_n;i++)
      if(cnt[i]>0) str[i]/=cnt[i];
  }
//+------------------------------------------------------------------+
//| Recalculate and redraw the panel values                          |
//+------------------------------------------------------------------+
void RefreshPanel()
  {
   double str[];
   Compute(str);

   int idx[];
   ArrayResize(idx,g_n);
   for(int i=0;i<g_n;i++) idx[i]=i;
   for(int a=0;a<g_n-1;a++)
      for(int b=0;b<g_n-1-a;b++)
         if(str[idx[b]]<str[idx[b+1]])
           {
            int t=idx[b]; idx[b]=idx[b+1]; idx[b+1]=t;
           }

   double maxabs=0.0001;
   for(int i=0;i<g_n;i++)
      if(MathAbs(str[i])>maxabs) maxabs=MathAbs(str[i]);

   for(int r=0;r<g_n;r++)
     {
      int    ci  = idx[r];
      double v   = str[ci];
      color  c   = (v>=0.0) ? InpUpColor : InpDownColor;
      int    w   = (int)MathRound(MathAbs(v)/maxabs*g_bar);
      if(w<1) w=1;

      ObjectSetString (0,g_prefix+"C"+(string)r,OBJPROP_TEXT,g_cur[ci]);
      ObjectSetString (0,g_prefix+"V"+(string)r,OBJPROP_TEXT,DoubleToString(v,2)+"%");
      ObjectSetInteger(0,g_prefix+"V"+(string)r,OBJPROP_COLOR,c);
      ObjectSetInteger(0,g_prefix+"B"+(string)r,OBJPROP_XSIZE,w);
      ObjectSetInteger(0,g_prefix+"B"+(string)r,OBJPROP_BGCOLOR,c);
      ObjectSetInteger(0,g_prefix+"B"+(string)r,OBJPROP_COLOR,c);
     }
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Create or update a text label                                    |
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
//| Create or update a strength bar                                  |
//+------------------------------------------------------------------+
void BarLabel(string name,int x,int y,int w,int h,color bg)
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
//| Create or update the panel background                            |
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
