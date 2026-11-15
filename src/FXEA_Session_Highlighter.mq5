//+------------------------------------------------------------------+
//|                                     FXEA_Session_Highlighter.mq5 |
//|                                                        FXEA365   |
//|         Trading session highlighter                              |
//+------------------------------------------------------------------+
#property copyright "FXEA365"
#property link      "https://www.mql5.com/en/users/app.develop.sk"
#property version   "1.10"
#property description "Trading session highlighter."
#property description "Draws the Tokyo, London and New York trading sessions as boxes on the chart."
#property description "Session hours are specified in broker server time."
#property indicator_chart_window
#property indicator_plots   0
#property indicator_buffers 0

input int   InpDaysBack    = 15;            // Days to draw
input bool  InpShowTokyo   = true;          // Show the Tokyo session
input int   InpTokyoStart  = 2;             // Tokyo session start hour (server time, 0-23)
input int   InpTokyoEnd    = 11;            // Tokyo session end hour (server time, 1-24)
input color InpTokyoColor  = clrSteelBlue;  // Tokyo session colour
input bool  InpShowLondon  = true;          // Show the London session
input int   InpLondonStart = 10;            // London session start hour
input int   InpLondonEnd   = 19;            // London session end hour
input color InpLondonColor = clrSeaGreen;   // London session colour
input bool  InpShowNY      = true;          // Show the New York session
input int   InpNYStart     = 15;            // New York session start hour
input int   InpNYEnd       = 24;            // New York session end hour
input color InpNYColor     = clrIndianRed;  // New York session colour
input bool  InpFill        = true;          // Fill the box

string g_prefix = "FXEA_SESS_";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
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
//--- redraw only when a new bar appears
   static datetime lastbar = 0;
   if(prev_calculated>0 && time[rates_total-1]==lastbar)
      return(rates_total);
   lastbar = time[rates_total-1];
   DrawSessions();
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Redraw all session boxes                                         |
//+------------------------------------------------------------------+
void DrawSessions()
  {
   ObjectsDeleteAll(0,g_prefix);
   datetime now   = TimeCurrent();
   datetime today = (datetime)((now/86400)*86400);   // server-time midnight of today
   for(int d=0; d<InpDaysBack; d++)
     {
      datetime day = today - d*86400;
      if(InpShowTokyo)  DrawBox("T",d,day,InpTokyoStart, InpTokyoEnd, InpTokyoColor);
      if(InpShowLondon) DrawBox("L",d,day,InpLondonStart,InpLondonEnd,InpLondonColor);
      if(InpShowNY)     DrawBox("N",d,day,InpNYStart,    InpNYEnd,    InpNYColor);
     }
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Draw one session box for the given day                           |
//+------------------------------------------------------------------+
void DrawBox(string tag,int d,datetime day,int hStart,int hEnd,color clr)
  {
   if(hEnd<=hStart) return;
//--- session time range
   datetime t1 = day + hStart*3600;
   datetime t2 = day + hEnd*3600;
   datetime now = TimeCurrent();
   if(t1>=now) return;                  // do not draw sessions that have not started yet
   if(t2>now)  t2 = now;
//--- bars that belong to the session
   int b1 = iBarShift(_Symbol,PERIOD_CURRENT,t1,false);
   int b2 = iBarShift(_Symbol,PERIOD_CURRENT,t2,false);
   if(b1<0 || b2<0) return;
   if(iTime(_Symbol,PERIOD_CURRENT,b2)<t1) return;   // no bars inside the session (weekend, holiday)
   if(iTime(_Symbol,PERIOD_CURRENT,b1)<t1) b1--;     // skip a bar that opened before the session
   int count = b1 - b2 + 1;
   if(count<=0) return;
//--- session high and low
   int hi = iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,count,b2);
   int lo = iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,count,b2);
   if(hi<0 || lo<0) return;
   double pHigh = iHigh(_Symbol,PERIOD_CURRENT,hi);
   double pLow  = iLow(_Symbol,PERIOD_CURRENT,lo);
   if(pHigh<=0 || pLow<=0) return;
//--- create or update the rectangle
   string name = g_prefix+tag+(string)d;
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_RECTANGLE,0,0,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_TIME,0,t1);
   ObjectSetDouble (0,name,OBJPROP_PRICE,0,pHigh);
   ObjectSetInteger(0,name,OBJPROP_TIME,1,t2);
   ObjectSetDouble (0,name,OBJPROP_PRICE,1,pLow);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FILL,InpFill);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }
//+------------------------------------------------------------------+
