//+------------------------------------------------------------------+
//|                                          QuickTradePanel.mq5     |
//|                        Copyright 2025, quicktradepanel-mql5      |
//|                 https://github.com/kissMoona/quicktradepanel-mql5 |
//+------------------------------------------------------------------+
#property copyright "Author: 猪猪大番薯"
#property link      "https://github.com/kissMoona/quicktradepanel-mql5"
#property version   "1.170"
#property description "作者：猪猪大番薯"
#property description "这个面板搭配一些奇妙的指标食用，效果更佳"

//+------------------------------------------------------------------+
//| ?                                                        |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//|                                                        |
//+------------------------------------------------------------------+
#define PANEL_NAME       "QuickTradePanel_RangeMidLab"
#define PANEL_MAGIC_DEFAULT 9527301
#define PANEL_WIDTH      860
#define PANEL_HEIGHT     130
#define BTN_HEIGHT       26
#define LBL_HEIGHT       18
#define GAP              6
#define INDENT_X         6
#define CONTENT_WIDTH    (PANEL_WIDTH - INDENT_X * 2)

//--- chart top labels
#define LBL_TOP_BG       "QTP_TopBg"
#define LBL_TOP_POS      "QTP_TopPos"
#define LBL_TOP_AVG      "QTP_TopAvg"
#define LBL_TOP_LIQ      "QTP_TopLiq"
#define LBL_TOP_PNL      "QTP_TopPnl"
#define LBL_TOP_TOTAL    "QTP_TopTotal"
#define LBL_BAR_TIMER    "QTP_BarTimer"
#define OBJ_BUY_LIQ_LINE "QTP_BuyLiqLine"
#define OBJ_SELL_LIQ_LINE "QTP_SellLiqLine"
#define OBJ_BUY_LIQ_TAG  "QTP_BuyLiqTag"
#define OBJ_SELL_LIQ_TAG "QTP_SellLiqTag"
#define OBJ_RANGE_MID_LINE "QTP_RangeMidLine"
#define OBJ_RANGE_UP_LINE  "QTP_RangeUpperLine"
#define OBJ_RANGE_DN_LINE  "QTP_RangeLowerLine"
#define OBJ_RANGE_FAIL_UP  "QTP_RangeFailUpLine"
#define OBJ_RANGE_FAIL_DN  "QTP_RangeFailDnLine"
#define OBJ_RANGE_STATE    "QTP_RangeStateLabel"
#define OBJ_RANGE_MID_TAG  "QTP_RangeMidTag"
#define OBJ_RANGE_UP_TAG   "QTP_RangeUpTag"
#define OBJ_RANGE_DN_TAG   "QTP_RangeDnTag"
#define OBJ_RANGE_FAILUP_TAG "QTP_RangeFailUpTag"
#define OBJ_RANGE_FAILDN_TAG "QTP_RangeFailDnTag"
#define TOP_FONT_NAME    "Microsoft YaHei"
#define TOP_DATA_FONT    "Consolas"
#define TOP_FONT_POS     15
#define TOP_FONT_AVG     15
#define TOP_FONT_LIQ     15
#define TOP_FONT_PNL     15
#define TOP_FONT_TOTAL   26
#define TOP_DATA_COL_WIDTH 12
#define TOP_ROW_GAP      10
#define TOP_Y_START      12
#define TOP_PANEL_MIN_WIDTH  320
#define TOP_PANEL_COLLAPSED_W 120
#define TOP_PANEL_Y      6
#define TOP_PANEL_EXPANDED_H 150
#define TOP_PANEL_INNER_PAD  10
#define TOP_PANEL_TEXT_PAD   28
#define K_RANGE_LABEL_PREFIX "QTP_KRange_"
#define K_RANGE_MAX_BARS 300
//+------------------------------------------------------------------+
//|                                                            |
//+------------------------------------------------------------------+
input group  "=== 面板设置 ==="
input double InpDefaultLots   = 0.01;   // 默认手数
input double InpLotsStep      = 0.01;   // 手数步长
input int    InpMagicNumber   = 9527001; // Magic过滤(0=全局控制)
input bool   InpCurrentOnly   = true;   // 仅统计当前品种
input int    InpSlippage      = 10;     // 最大滑点(点)
input bool   InpShowCandleRangeStats = false; // K线波幅统计默认显示
input bool   InpEnableDragTradeLevels = true; // 允许拖动订单线快速设置TP/SL
input bool   InpEnableBarCountdownSound = false; // K线倒计时提示音

input group  "=== 下单设置 ==="
input double InpStopLoss      = 0.0;    // 默认止损价格(0=不设置)
input double InpTakeProfit    = 0.0;    // 默认止盈价格(0=不设置)
input int    InpAddOnBreakevenBufferPoints = 0; // 加仓保本额外缓冲(点)
input double InpAddOnBreakevenLockProfitPercent = 25.0; // 加仓后锁定当前浮盈比例(0-100)

input group  "=== 浮盈加仓 ==="
input bool   InpEnableFloatProfitAdd = false;   // 默认关闭价格间距加仓
input double InpFloatProfitStepMoney = 1.0;     // 每间距多少价格触发一次加仓
input double InpFloatProfitAddLots   = 0.01;    // 每次自动加仓手数

input group  "=== Range Mid Lab 自动策略 ==="
input bool   InpEnableRangeMidAuto   = true;    // 启用组合中线摆动策略
input int    InpRangeDonchianPeriod  = 96;      // 唐奇安周期
input int    InpRangeBBPeriod        = 34;      // 布林中轨周期
input double InpRangeBBDeviation     = 2.0;     // 布林倍数
input int    InpRangeAdxPeriod       = 14;      // ADX周期
input int    InpRangeAtrPeriod       = 14;      // ATR周期
input double InpRangeVwapWeight      = 0.20;    // VWAP权重(0-0.8)
input double InpRangeAdxMax          = 35.0;    // 摆动阈值(ADX上限)
input int    InpRangeSlopeLookback   = 5;       // 中线斜率回看K数
input double InpRangeSlopeAtrMult    = 0.35;    // 斜率阈值(ATR倍数)
input double InpRangeBandAtrMult     = 0.60;    // 区间宽度ATR系数
input double InpRangeBandDonchMult   = 0.35;    // 区间宽度唐奇安系数
input double InpRangeEntryBandMult   = 0.60;    // 入场偏移(区间倍数)
input double InpRangeGridAtrMult     = 0.80;    // 网格补单间距(ATR倍数)
input double InpRangeFailAtrMult     = 0.25;    // 区间失效缓冲(ATR倍数)
input int    InpRangeMaxSidePositions = 1;      // 单边最大仓位数
input bool   InpRangeAllowHedge      = false;   // 允许多空同时持仓
input bool   InpRangeCloseAtMid      = true;    // 回到中线即平该侧
input bool   InpRangeVerboseLog      = true;    // 输出策略日志

//--- Arrow auto-trade is intentionally disabled in RangeMidLab.
bool   InpEnableArrowSignalTrade = false;
bool   InpArrowTradeOnLatestSignalAtLoad = false;
string InpArrowIndicatorName     = "";
int    InpArrowBuyBuffer         = 5;
int    InpArrowSellBuffer        = 6;
color  InpArrowBuyColor          = clrDodgerBlue;
color  InpArrowSellColor         = clrRed;

//+------------------------------------------------------------------+
//| ?                                                        |
//+------------------------------------------------------------------+
class CQuickTradePanel : public CAppDialog
  {
private:
   //---
   CLabel            m_lblSymbol;
   CLabel            m_lblAskBid;
   CLabel            m_lblSpread;
   CLabel            m_lblBalance;
   CLabel            m_lblEquity;

   //---
   CLabel            m_lblLotsTitle;
   CButton           m_btnLotsMinus;
   CEdit             m_edtLots;
   CButton           m_btnLotsPlus;
   CButton           m_btnLotsX2;
   CButton           m_btnLotsD2;

   //---
   CButton           m_btnBuy;
   CButton           m_btnSell;
   CButton           m_btnCloseBuys;
   CButton           m_btnCloseSells;
   CButton           m_btnCloseAll;

   //--- toggle controls
   CButton           m_btnToggleReverse;
   CButton           m_btnToggleRangeStats;
   CButton           m_btnToggleAddOnBreakeven;
   CButton           m_btnToggleFloatAdd;
   CLabel            m_lblFloatAddCfg;
   bool              m_closeReverse;       // ?
   bool              m_showCandleRangeStats;
   bool              m_autoAddOnBreakeven;
   bool              m_pendingAutoBeBuy;
   bool              m_pendingAutoBeSell;
   bool              m_autoFloatProfitAdd;
   bool              m_pendingFloatAddBuy;
   bool              m_pendingFloatAddSell;
   double            m_nextFloatAddBuyProfit;
   double            m_nextFloatAddSellProfit;
   int               m_rangeBandsHandle;
   int               m_rangeAdxHandle;
   int               m_rangeAtrHandle;
   string            m_rangeLoadedSymbol;
   ENUM_TIMEFRAMES   m_rangeLoadedPeriod;
   datetime          m_lastRangeBuyBar;
   datetime          m_lastRangeSellBar;
   string            m_lastRangeStateText;
   bool              m_arrowSignalPrimed;
   string            m_lastArrowSignalKey;
   string            m_lastArrowSignalDebug;
   int               m_arrowIndicatorHandle;
   string            m_arrowIndicatorLoadedName;
   string            m_arrowIndicatorLoadedSymbol;
   ENUM_TIMEFRAMES   m_arrowIndicatorLoadedPeriod;
   bool              m_prevDragTradeLevels;
   bool              m_hasPrevDragTradeLevels;
   CLabel            m_lblTpPrice;
   CEdit             m_edtTpPct;
   CLabel            m_lblSlPrice;
   CEdit             m_edtSlPct;
   //---
   CTrade            m_trade;
   CPositionInfo     m_posInfo;
   double            m_lots;

   //---
   int               m_asyncPending;

   //---
   ulong             m_lastUpdateTick;
   datetime          m_alertBarOpen;
   bool              m_beep3Played;
   bool              m_beep2Played;
   bool              m_beep1Played;
   string            m_lastTpText;
   string            m_lastSlText;
   ulong             m_lastTpSlEditTick;
   double            m_lastAppliedTp;
   double            m_lastAppliedSl;
   ulong             m_ignoreExternalTpSlUntil;
   bool              m_forceTpSlApply;
   int               m_topPanelLastWidth;
   ulong             m_pendingCloseTickets[];
   ulong             m_trackedPosTickets[];
   double            m_trackedPosSl[];
   double            m_trackedPosTp[];
   ulong             m_trackedOrdTickets[];
   double            m_trackedOrdSl[];
   double            m_trackedOrdTp[];

public:
                     CQuickTradePanel();
                    ~CQuickTradePanel() {}

   bool              CreatePanel(const long chart, const int subwin);
   void              UpdateInfo();
   void              Reposition();

   //---
   void              CreateChartLabels();
   void              DestroyChartLabels();
   void              ReleaseResources();
   void              RefreshCandleRangeLabels();
   void              SyncDraggedTpSlToPanel();

   //---
   virtual bool      OnEvent(const int id, const long &lparam,
                          const double &dparam, const string &sparam);

   //---
   void              OnAsyncResult(const MqlTradeTransaction &trans,
                                const MqlTradeRequest &request,
                                const MqlTradeResult &result);

private:
   //---
   bool              CreateInfoLabels(int &y);
   bool              CreateLotsRow(int &y);
   bool              CreateTradeButtons(int &y);
   bool              CreateCloseButtons(int &y);
   bool              CreateToggleRow(int &y);
   bool              CreatePctCloseRows(int &y);
   void              CreateTopBackground();
   void              CreateTopInfoLabels();
   void              DeleteTopInfoLabels();
   void              UpdateLiquidationMarkers(const double buyLiqPrice, const double sellLiqPrice);
   bool              EstimateLiquidationPrice(const ENUM_POSITION_TYPE posType, const double totalLots, const double currentPrice, double &liqPrice);
   void              UpdateRangeMidVisual(const double mid,
                                       const double entryUpper,
                                       const double entryLower,
                                       const double failUpper,
                                       const double failLower,
                                       const bool isRanging,
                                       const double adx,
                                       const double atr,
                                       const double band);
   void              UpdateRangeLineTag(const string objName,
                                     const string title,
                                     const color clr,
                                     const double price,
                                     const int xOffset);
   void              ClearRangeMidVisual();

   //---
   void              OnClickBuy();
   void              OnClickSell();
   void              OnClickCloseBuys();
   void              OnClickCloseSells();
   void              OnClickCloseAll();
   void              OnClickLotsPlus();
   void              OnClickLotsMinus();
   void              OnClickLotsX2();
   void              OnClickLotsD2();
   void              OnClickToggleReverse();
   void              OnClickToggleRangeStats();
   void              OnClickToggleAddOnBreakeven();
   void              OnClickToggleFloatAdd();

   //---
   bool              ExecuteMarketOrder(const ENUM_POSITION_TYPE posType,
                                     const double lots,
                                     const string orderComment,
                                     const bool resetInputsAfter);
   void              UpdateChartLabels(int buys, double buyLots, double buyPft,
                                    int sells, double sellLots, double sellPft,
                                    double buyAvgPrice, double sellAvgPrice,
                                    double buyLiqPrice, double sellLiqPrice);
   void              UpdateCandleRangeLabels();
   void              DeleteCandleRangeLabels();
   string            CandleRangeLabelName(const int shift);
   int               CandleRangeFontSize();
   double            CandleRangeOffset(const double candleRange, const double visibleRange);
   string            PadRight(const string text, const int width);
   double            StopoutEquityThreshold();
   void              UpdateTopPanelLayout();
   void              UpdateRangeStatsToggleButton();
   void              UpdateAddOnBreakevenToggleButton();
   void              UpdateFloatAddToggleButton();
   void              UpdateFloatAddConfigLabel();
   int               MeasureTextWidthPx(const string text, const string fontName, const int fontSize);
   int               FindTrackedPositionIndex(const ulong ticket);
   int               FindTrackedOrderIndex(const ulong ticket);
   int               FindPendingCloseIndex(const ulong ticket);
   void              AddPendingCloseTicket(const ulong ticket);
   void              RemovePendingCloseTicket(const ulong ticket);
   bool              IsBuyManagedOrderType(const ENUM_ORDER_TYPE orderType);
   bool              IsPriceValidForOrderSide(const ENUM_POSITION_TYPE posType, const double marketPrice, const double price, const bool isTakeProfit);
   bool              CollectSideExposure(const ENUM_POSITION_TYPE posType, int &count, double &totalVolume, double &netProfit, double &minOpen, double &maxOpen);
   double            CombinedProfitAtPrice(const ENUM_POSITION_TYPE posType, const double closePrice);
   bool              ComputeBreakevenStopForSide(const ENUM_POSITION_TYPE posType, double &stopPrice);
   bool              ApplyBreakevenStopForSide(const ENUM_POSITION_TYPE posType);
   void              FlagAutoBreakevenFromDeal(const ulong dealTicket, const string symbol);
   double            ComputeNextFloatAddTrigger(const ENUM_POSITION_TYPE posType,
         const double minOpen,
         const double maxOpen);
   bool              SendFloatProfitAddOrder(const ENUM_POSITION_TYPE posType);
   void              HandleFloatProfitAddDeal(const ulong dealTicket, const string symbol);
   bool              EnsureRangeIndicatorHandles();
   bool              GetRangeMidMetrics(double &donHigh,
                                        double &donLow,
                                        double &bbMid,
                                        double &bbMidPast,
                                        double &adx,
                                        double &atr,
                                        double &vwapNow,
                                        double &vwapPast,
                                        double &mid,
                                        double &midPast,
                                        double &band,
                                        bool &isRanging);
   double            ComputeSessionVWAP(const int shift, const int barsLimit);
   int               CountManagedPositions(const ENUM_POSITION_TYPE posType);
   void              ProcessRangeMidAuto(const double bid,
                                         const double ask,
                                         const int buys,
                                         const int sells,
                                         const double buyMinOpen,
                                         const double buyMaxOpen,
                                         const double sellMinOpen,
                                         const double sellMaxOpen);
   bool              EnsureArrowIndicatorHandle();
   bool              GetLatestArrowSignalFromICustom(ENUM_POSITION_TYPE &posType,
         string &signalKey,
         string &objectName,
         datetime &signalTime);
   bool              IsArrowSignalObjectType(const ENUM_OBJECT objectType);
   bool              GetLatestArrowSignalFromObjects(ENUM_POSITION_TYPE &posType,
         string &signalKey,
         string &objectName,
         datetime &signalTime);
   bool              GetLatestArrowSignal(ENUM_POSITION_TYPE &posType,
                                       string &signalKey,
                                       string &objectName,
                                       datetime &signalTime);
   void              ProcessArrowSignalAutoTrading();
   bool              SamePrice(const double a, const double b);

   //---
   double            NormLots(double lots);
   void              UpdateLotsDisplay();
   ENUM_ORDER_TYPE_FILLING DetectFilling();
   void              AsyncCloseByType(ENUM_POSITION_TYPE type);
   double            ParsePriceInput(const string text);
   void              ResolveTpSlTemplate(const ENUM_POSITION_TYPE posType, double &tp, double &sl);
   string            DescribeTradeRetcode(const uint retcode);
   void              ApplyTpSlToAll();
   void              ResetTpSlInputs();
   void              SoundClick()    { PlaySound("tick.wav"); }
   void              SoundTrade()    { PlaySound("ok.wav"); }
   void              SoundError()    { PlaySound("timeout.wav"); }
   void              SoundClose()    { PlaySound("expert.wav"); }
  };

//+------------------------------------------------------------------+
//|                                                            |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CQuickTradePanel)
ON_EVENT(ON_CLICK, m_btnBuy,        OnClickBuy)
ON_EVENT(ON_CLICK, m_btnSell,       OnClickSell)
ON_EVENT(ON_CLICK, m_btnCloseBuys,  OnClickCloseBuys)
ON_EVENT(ON_CLICK, m_btnCloseSells, OnClickCloseSells)
ON_EVENT(ON_CLICK, m_btnCloseAll,   OnClickCloseAll)
ON_EVENT(ON_CLICK, m_btnLotsPlus,   OnClickLotsPlus)
ON_EVENT(ON_CLICK, m_btnLotsMinus,  OnClickLotsMinus)
ON_EVENT(ON_CLICK, m_btnLotsX2,     OnClickLotsX2)
ON_EVENT(ON_CLICK, m_btnLotsD2,     OnClickLotsD2)
ON_EVENT(ON_CLICK, m_btnToggleReverse, OnClickToggleReverse)
ON_EVENT(ON_CLICK, m_btnToggleRangeStats, OnClickToggleRangeStats)
ON_EVENT(ON_CLICK, m_btnToggleAddOnBreakeven, OnClickToggleAddOnBreakeven)
ON_EVENT(ON_CLICK, m_btnToggleFloatAdd, OnClickToggleFloatAdd)
EVENT_MAP_END(CAppDialog)

//+------------------------------------------------------------------+
//| ?                                                          |
//+------------------------------------------------------------------+
CQuickTradePanel::CQuickTradePanel()
  {
   m_lots          = InpDefaultLots;
   m_asyncPending  = 0;
   m_lastUpdateTick = 0;
   m_alertBarOpen  = 0;
   m_beep3Played   = false;
   m_beep2Played   = false;
   m_beep1Played   = false;
   m_closeReverse  = false;
   m_showCandleRangeStats = InpShowCandleRangeStats;
   m_autoAddOnBreakeven = false;
   m_pendingAutoBeBuy = false;
   m_pendingAutoBeSell = false;
   m_autoFloatProfitAdd = InpEnableFloatProfitAdd;
   m_pendingFloatAddBuy = false;
   m_pendingFloatAddSell = false;
   m_nextFloatAddBuyProfit = 0.0;
   m_nextFloatAddSellProfit = 0.0;
   m_rangeBandsHandle = INVALID_HANDLE;
   m_rangeAdxHandle = INVALID_HANDLE;
   m_rangeAtrHandle = INVALID_HANDLE;
   m_rangeLoadedSymbol = "";
   m_rangeLoadedPeriod = PERIOD_CURRENT;
   m_lastRangeBuyBar = 0;
   m_lastRangeSellBar = 0;
   m_lastRangeStateText = "";
   m_arrowSignalPrimed = false;
   m_lastArrowSignalKey = "";
   m_lastArrowSignalDebug = "";
   m_arrowIndicatorHandle = INVALID_HANDLE;
   m_arrowIndicatorLoadedName = "";
   m_arrowIndicatorLoadedSymbol = "";
   m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
   m_prevDragTradeLevels = true;
   m_hasPrevDragTradeLevels = false;
   m_lastTpText    = "";
   m_lastSlText    = "";
   m_lastTpSlEditTick = 0;
   m_lastAppliedTp = -1.0;
   m_lastAppliedSl = -1.0;
   m_ignoreExternalTpSlUntil = 0;
   m_forceTpSlApply = false;
   m_topPanelLastWidth = TOP_PANEL_MIN_WIDTH;
  }

//+------------------------------------------------------------------+
//|                                        |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CreatePanel(const long chart, const int subwin)
  {
   long dragTradeLevels = 1;
   if(ChartGetInteger(chart, CHART_DRAG_TRADE_LEVELS, 0, dragTradeLevels))
     {
      m_prevDragTradeLevels = (dragTradeLevels != 0);
      m_hasPrevDragTradeLevels = true;
     }
   ChartSetInteger(chart, CHART_DRAG_TRADE_LEVELS, InpEnableDragTradeLevels);

//--- initial position: center-bottom
   int chartW = (int)ChartGetInteger(chart, CHART_WIDTH_IN_PIXELS);
   int chartH = (int)ChartGetInteger(chart, CHART_HEIGHT_IN_PIXELS);
   int x1 = (chartW - PANEL_WIDTH) / 2;
   if(x1 < 0)
      x1 = 0;
   int y1 = chartH - PANEL_HEIGHT - 25;
   int x2 = x1 + PANEL_WIDTH;
   int y2 = y1 + PANEL_HEIGHT;

   if(!CAppDialog::Create(chart, PANEL_NAME, subwin, x1, y1, x2, y2))
      return false;

//--- init trade engine
   int panelMagic = (InpMagicNumber == 0 ? PANEL_MAGIC_DEFAULT : InpMagicNumber);
   m_trade.SetExpertMagicNumber(panelMagic);
   m_trade.SetDeviationInPoints(InpSlippage);
   m_trade.SetTypeFilling(DetectFilling());
   m_trade.SetAsyncMode(true);   // ?

//---
   m_lots = NormLots(m_lots);

//---
   int y = 5;
   if(!CreateInfoLabels(y))
      return false;
   if(!CreateLotsRow(y))
      return false;
   if(!CreateTradeButtons(y))
      return false;
   if(!CreateCloseButtons(y))
      return false;
   if(!CreatePctCloseRows(y))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| ?                                                    |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CreateInfoLabels(int &y)
  {
   int x = INDENT_X;
   int w = (CONTENT_WIDTH - GAP * 4) / 5;

   if(!m_lblSymbol.Create(m_chart_id, m_name+"LblSym", m_subwin, x, y, x + w, y + LBL_HEIGHT))
      return false;
   m_lblSymbol.Text("品种: --");
   m_lblSymbol.FontSize(9);
   m_lblSymbol.Color(clrAliceBlue);
   if(!Add(m_lblSymbol))
      return false;
   x += w + GAP;

   if(!m_lblAskBid.Create(m_chart_id, m_name+"LblAB", m_subwin, x, y, x + w, y + LBL_HEIGHT))
      return false;
   m_lblAskBid.Text("卖价: -- 买价: --");
   m_lblAskBid.FontSize(9);
   m_lblAskBid.Color(clrSilver);
   if(!Add(m_lblAskBid))
      return false;
   x += w + GAP;

   if(!m_lblSpread.Create(m_chart_id, m_name+"LblSpd", m_subwin, x, y, x + w, y + LBL_HEIGHT))
      return false;
   m_lblSpread.Text("点差: --");
   m_lblSpread.FontSize(9);
   m_lblSpread.Color(clrDarkGray);
   if(!Add(m_lblSpread))
      return false;
   x += w + GAP;

   if(!m_lblBalance.Create(m_chart_id, m_name+"LblBal", m_subwin, x, y, x + w, y + LBL_HEIGHT))
      return false;
   m_lblBalance.Text("余额: --");
   m_lblBalance.FontSize(9);
   m_lblBalance.Color(clrSilver);
   if(!Add(m_lblBalance))
      return false;
   x += w + GAP;

   if(!m_lblEquity.Create(m_chart_id, m_name+"LblEqu", m_subwin, x, y, x + w, y + LBL_HEIGHT))
      return false;
   m_lblEquity.Text("净值: --");
   m_lblEquity.FontSize(9);
   m_lblEquity.Color(clrSilver);
   if(!Add(m_lblEquity))
      return false;

   y += LBL_HEIGHT + GAP;

   return true;
  }

//+------------------------------------------------------------------+
//| ?                                                    |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CreateLotsRow(int &y)
  {
   int x = INDENT_X;

//--- lots controls
   if(!m_lblLotsTitle.Create(m_chart_id, m_name+"LblLT", m_subwin,
                             x, y + 4, x + 36, y + LBL_HEIGHT + 4))
      return false;
   m_lblLotsTitle.Text("手数");
   m_lblLotsTitle.FontSize(9);
   if(!Add(m_lblLotsTitle))
      return false;
   x += 40;

   if(!m_btnLotsMinus.Create(m_chart_id, m_name+"BtnLM", m_subwin,
                             x, y, x + 24, y + BTN_HEIGHT - 4))
      return false;
   m_btnLotsMinus.Text("-");
   if(!Add(m_btnLotsMinus))
      return false;
   x += 28;

   if(!m_edtLots.Create(m_chart_id, m_name+"EdtLot", m_subwin,
                        x, y, x + 56, y + BTN_HEIGHT - 4))
      return false;
   m_edtLots.Text(DoubleToString(m_lots, 2));
   m_edtLots.TextAlign(ALIGN_CENTER);
   if(!Add(m_edtLots))
      return false;
   x += 60;

   if(!m_btnLotsPlus.Create(m_chart_id, m_name+"BtnLP", m_subwin,
                            x, y, x + 24, y + BTN_HEIGHT - 4))
      return false;
   m_btnLotsPlus.Text("+");
   if(!Add(m_btnLotsPlus))
      return false;
   x += 28;

   if(!m_btnLotsX2.Create(m_chart_id, m_name+"BtnX2", m_subwin,
                          x, y, x + 30, y + BTN_HEIGHT - 4))
      return false;
   m_btnLotsX2.Text("x2");
   if(!Add(m_btnLotsX2))
      return false;
   x += 34;

   if(!m_btnLotsD2.Create(m_chart_id, m_name+"BtnD2", m_subwin,
                          x, y, x + 30, y + BTN_HEIGHT - 4))
      return false;
   m_btnLotsD2.Text("/2");
   if(!Add(m_btnLotsD2))
      return false;
   x += 38;

//--- reverse + tp/sl controls on same row
   if(!m_btnToggleReverse.Create(m_chart_id, m_name+"BtnTR", m_subwin,
                                 x, y, x + 120, y + BTN_HEIGHT - 2))
      return false;
   m_btnToggleReverse.Text("反向平仓: 开");
   m_btnToggleReverse.ColorBackground(C'0,100,60');
   m_btnToggleReverse.Color(clrLime);
   m_btnToggleReverse.FontSize(9);
   if(!Add(m_btnToggleReverse))
      return false;
   x += 128;

   if(!m_lblSlPrice.Create(m_chart_id, m_name+"LblSLP", m_subwin,
                           x, y + 4, x + 24, y + LBL_HEIGHT + 4))
      return false;
   m_lblSlPrice.Text("SL:");
   m_lblSlPrice.FontSize(9);
   m_lblSlPrice.Color(clrSilver);
   if(!Add(m_lblSlPrice))
      return false;
   x += 28;

   if(!m_edtSlPct.Create(m_chart_id, m_name+"EdtSL", m_subwin,
                         x, y, x + 82, y + BTN_HEIGHT - 4))
      return false;
   m_edtSlPct.Text(InpStopLoss > 0.0 ? DoubleToString(InpStopLoss, _Digits) : "0");
   m_edtSlPct.TextAlign(ALIGN_CENTER);
   if(!Add(m_edtSlPct))
      return false;
   x += 90;

   if(!m_lblTpPrice.Create(m_chart_id, m_name+"LblTPP", m_subwin,
                           x, y + 4, x + 24, y + LBL_HEIGHT + 4))
      return false;
   m_lblTpPrice.Text("TP:");
   m_lblTpPrice.FontSize(9);
   m_lblTpPrice.Color(clrSilver);
   if(!Add(m_lblTpPrice))
      return false;
   x += 28;

   if(!m_edtTpPct.Create(m_chart_id, m_name+"EdtTP", m_subwin,
                         x, y, x + 82, y + BTN_HEIGHT - 4))
      return false;
   m_edtTpPct.Text(InpTakeProfit > 0.0 ? DoubleToString(InpTakeProfit, _Digits) : "0");
   m_edtTpPct.TextAlign(ALIGN_CENTER);
   if(!Add(m_edtTpPct))
      return false;
   x += 90;

   if(!m_btnToggleAddOnBreakeven.Create(m_chart_id, m_name+"BtnAutoBE", m_subwin,
                                        x, y, x + 92, y + BTN_HEIGHT - 2))
      return false;
   m_btnToggleAddOnBreakeven.FontSize(9);
   if(!Add(m_btnToggleAddOnBreakeven))
      return false;
   UpdateAddOnBreakevenToggleButton();
   x += 100;

   if(!m_btnToggleFloatAdd.Create(m_chart_id, m_name+"BtnFloatAdd", m_subwin,
                                  x, y, x + 92, y + BTN_HEIGHT - 2))
      return false;
   m_btnToggleFloatAdd.FontSize(9);
   if(!Add(m_btnToggleFloatAdd))
      return false;
   UpdateFloatAddToggleButton();

   y += BTN_HEIGHT + GAP;
   return true;
  }

//+------------------------------------------------------------------+
//|  BUY / SELL                                                |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CreateTradeButtons(int &y)
  {
   int x = INDENT_X;
   int w = (CONTENT_WIDTH - GAP * 4) / 5;

   if(!m_btnBuy.Create(m_chart_id, m_name+"BtnBuy", m_subwin,
                       x, y, x + w, y + BTN_HEIGHT + 2))
      return false;
   m_btnBuy.Text("BUY");
   m_btnBuy.ColorBackground(clrDodgerBlue);
   m_btnBuy.Color(clrWhite);
   m_btnBuy.FontSize(11);
   if(!Add(m_btnBuy))
      return false;
   x += w + GAP;

   if(!m_btnSell.Create(m_chart_id, m_name+"BtnSell", m_subwin,
                        x, y, x + w, y + BTN_HEIGHT + 2))
      return false;
   m_btnSell.Text("SELL");
   m_btnSell.ColorBackground(clrCrimson);
   m_btnSell.Color(clrWhite);
   m_btnSell.FontSize(11);
   if(!Add(m_btnSell))
      return false;
   x += w + GAP;

   if(!m_btnCloseBuys.Create(m_chart_id, m_name+"BtnCB", m_subwin,
                             x, y, x + w, y + BTN_HEIGHT + 2))
      return false;
   m_btnCloseBuys.Text("平多");
   m_btnCloseBuys.ColorBackground(C'40,80,140');
   m_btnCloseBuys.Color(clrWhite);
   if(!Add(m_btnCloseBuys))
      return false;
   x += w + GAP;

   if(!m_btnCloseSells.Create(m_chart_id, m_name+"BtnCS", m_subwin,
                              x, y, x + w, y + BTN_HEIGHT + 2))
      return false;
   m_btnCloseSells.Text("平空");
   m_btnCloseSells.ColorBackground(C'140,40,40');
   m_btnCloseSells.Color(clrWhite);
   if(!Add(m_btnCloseSells))
      return false;
   x += w + GAP;

   if(!m_btnCloseAll.Create(m_chart_id, m_name+"BtnCA", m_subwin,
                            x, y, x + w, y + BTN_HEIGHT + 2))
      return false;
   m_btnCloseAll.Text("一键清仓");
   m_btnCloseAll.ColorBackground(clrOrangeRed);
   m_btnCloseAll.Color(clrWhite);
   m_btnCloseAll.FontSize(11);
   if(!Add(m_btnCloseAll))
      return false;

   y += BTN_HEIGHT + GAP + 2;
   return true;
  }

//+------------------------------------------------------------------+
//| ?                                                    |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CreateCloseButtons(int &y)
  {
   return true;
  }

//+------------------------------------------------------------------+
//|                                                      |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CreateToggleRow(int &y)
  {
   int x = INDENT_X;

   if(!m_lblFloatAddCfg.Create(m_chart_id, m_name+"LblFloatAddCfg", m_subwin,
                               x, y + 4, x + 420, y + LBL_HEIGHT + 4))
      return false;
   m_lblFloatAddCfg.FontSize(9);
   m_lblFloatAddCfg.Color(clrSilver);
   if(!Add(m_lblFloatAddCfg))
      return false;
   UpdateFloatAddConfigLabel();

   y += BTN_HEIGHT + GAP - 2;
   return true;
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CreatePctCloseRows(int &y)
  {
   return true;
  }

//+------------------------------------------------------------------+
//|                                                        |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateInfo()
  {
//--- OnTick+OnTimer
   ulong refreshTick = GetTickCount();
   if(!MQLInfoInteger(MQL_TESTER) && m_lastUpdateTick > 0 && refreshTick - m_lastUpdateTick < 200)
      return;
   m_lastUpdateTick = refreshTick;
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)ChartPeriod(m_chart_id);
   if(tf <= PERIOD_CURRENT)
      tf = _Period;
   m_lblSymbol.Text("品种: " + _Symbol + "  周期: " + EnumToString(tf));

//--- Ask / Bid
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   m_lblAskBid.Text(StringFormat("卖价: %s  买价: %s",
                                 DoubleToString(ask, _Digits), DoubleToString(bid, _Digits)));
   m_lblAskBid.Color(clrSilver);

//---
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   m_lblSpread.Text(StringFormat("点差: %d 点", spread));
   m_lblSpread.Color(spread > 30 ? clrOrangeRed : clrDarkGray);

//---  / ?/
   m_lblBalance.Text(StringFormat("余额: %.2f %s",
                                  AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoString(ACCOUNT_CURRENCY)));
   m_lblBalance.Color(clrSilver);

   m_lblEquity.Text(StringFormat("净值: %.2f",
                                 AccountInfoDouble(ACCOUNT_EQUITY)));
   m_lblEquity.Color(clrSilver);

//---
   int buys = 0, sells = 0;
   double buyLots = 0, sellLots = 0, buyPft = 0, sellPft = 0;
   double buyWeightedPrice = 0.0, sellWeightedPrice = 0.0;
   double buyMinOpen = 0.0, buyMaxOpen = 0.0;
   double sellMinOpen = 0.0, sellMaxOpen = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;

      if(m_posInfo.PositionType() == POSITION_TYPE_BUY)
        {
         buys++;
         buyLots += m_posInfo.Volume();
         double openPrice = m_posInfo.PriceOpen();
         buyWeightedPrice += openPrice * m_posInfo.Volume();
         if(buyMinOpen <= 0.0 || openPrice < buyMinOpen)
            buyMinOpen = openPrice;
         if(openPrice > buyMaxOpen)
            buyMaxOpen = openPrice;
         buyPft  += m_posInfo.Profit() + m_posInfo.Swap() + m_posInfo.Commission();
        }
      else
        {
         sells++;
         sellLots += m_posInfo.Volume();
         double openPrice = m_posInfo.PriceOpen();
         sellWeightedPrice += openPrice * m_posInfo.Volume();
         if(sellMinOpen <= 0.0 || openPrice < sellMinOpen)
            sellMinOpen = openPrice;
         if(openPrice > sellMaxOpen)
            sellMaxOpen = openPrice;
         sellPft  += m_posInfo.Profit() + m_posInfo.Swap() + m_posInfo.Commission();
        }
     }
   double buyAvgPrice = (buyLots > 0.0 ? buyWeightedPrice / buyLots : 0.0);
   double sellAvgPrice = (sellLots > 0.0 ? sellWeightedPrice / sellLots : 0.0);
   double buyLiqPrice = 0.0;
   double sellLiqPrice = 0.0;
   if(buyLots > 0.0)
      EstimateLiquidationPrice(POSITION_TYPE_BUY, buyLots, bid, buyLiqPrice);
   if(sellLots > 0.0)
      EstimateLiquidationPrice(POSITION_TYPE_SELL, sellLots, ask, sellLiqPrice);

   if(!m_autoAddOnBreakeven)
     {
      m_pendingAutoBeBuy = false;
      m_pendingAutoBeSell = false;
     }
   else
     {
      if(m_pendingAutoBeBuy)
        {
         if(buyLots <= 0.0 || ApplyBreakevenStopForSide(POSITION_TYPE_BUY))
            m_pendingAutoBeBuy = false;
        }
      if(m_pendingAutoBeSell)
        {
         if(sellLots <= 0.0 || ApplyBreakevenStopForSide(POSITION_TYPE_SELL))
            m_pendingAutoBeSell = false;
        }
     }

   UpdateFloatAddConfigLabel();
   if(!m_autoFloatProfitAdd)
     {
      m_pendingFloatAddBuy = false;
      m_pendingFloatAddSell = false;
      m_nextFloatAddBuyProfit = 0.0;
      m_nextFloatAddSellProfit = 0.0;
     }
   else
     {
      if(buys <= 0)
        {
         m_pendingFloatAddBuy = false;
         m_nextFloatAddBuyProfit = 0.0;
        }
      else
         if(m_nextFloatAddBuyProfit <= 0.0)
           {
            m_nextFloatAddBuyProfit = ComputeNextFloatAddTrigger(POSITION_TYPE_BUY, buyMinOpen, buyMaxOpen);
           }

      if(sells <= 0)
        {
         m_pendingFloatAddSell = false;
         m_nextFloatAddSellProfit = 0.0;
        }
      else
         if(m_nextFloatAddSellProfit <= 0.0)
           {
            m_nextFloatAddSellProfit = ComputeNextFloatAddTrigger(POSITION_TYPE_SELL, sellMinOpen, sellMaxOpen);
           }

      if(!m_pendingFloatAddBuy && buys > 0 && m_nextFloatAddBuyProfit > 0.0 && ask >= m_nextFloatAddBuyProfit)
         SendFloatProfitAddOrder(POSITION_TYPE_BUY);

      if(!m_pendingFloatAddSell && sells > 0 && m_nextFloatAddSellProfit > 0.0 && bid <= m_nextFloatAddSellProfit)
         SendFloatProfitAddOrder(POSITION_TYPE_SELL);
     }

   ProcessRangeMidAuto(bid, ask, buys, sells, buyMinOpen, buyMaxOpen, sellMinOpen, sellMaxOpen);

//--- K bar countdown
   datetime barOpen = iTime(_Symbol, tf, 0);
   int periodSec = PeriodSeconds(tf);
   if(periodSec <= 0)
      periodSec = 60;
   datetime nowServer = TimeTradeServer();
   if(nowServer <= 0)
      nowServer = TimeCurrent();
   int remainSec = (int)((barOpen + periodSec) - nowServer);
   if(remainSec < 0)
      remainSec = 0;
   int hh = remainSec / 3600;
   int mm = (remainSec % 3600) / 60;
   int ss = remainSec % 60;
   datetime curBarTime = iTime(_Symbol, tf, 0);
   double   curHigh    = iHigh(_Symbol, tf, 0);
   double   curLow     = iLow(_Symbol, tf, 0);
   double   range      = MathMax(curHigh - curLow, 0.0);
   double   priceY     = curHigh + MathMax(range * 0.25, 120 * _Point);
   string   timerText  = StringFormat("T-%02d:%02d:%02d", hh, mm, ss);
   color    timerColor = (remainSec <= 10 ? clrOrangeRed : clrDeepSkyBlue);

   if(ObjectFind(m_chart_id, LBL_BAR_TIMER) < 0)
      ObjectCreate(m_chart_id, LBL_BAR_TIMER, OBJ_TEXT, 0, curBarTime, priceY);
   ObjectMove(m_chart_id, LBL_BAR_TIMER, 0, curBarTime, priceY);
   ObjectSetString(m_chart_id, LBL_BAR_TIMER, OBJPROP_TEXT, timerText);
   ObjectSetString(m_chart_id, LBL_BAR_TIMER, OBJPROP_FONT, "Microsoft YaHei");
   ObjectSetInteger(m_chart_id, LBL_BAR_TIMER, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(m_chart_id, LBL_BAR_TIMER, OBJPROP_COLOR, timerColor);
   ObjectSetInteger(m_chart_id, LBL_BAR_TIMER, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   ObjectSetInteger(m_chart_id, LBL_BAR_TIMER, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, LBL_BAR_TIMER, OBJPROP_HIDDEN, true);

//--- New-bar countdown beeps: 3/2/1 (optional)
   if(barOpen != m_alertBarOpen)
     {
      m_alertBarOpen = barOpen;
      m_beep3Played = false;
      m_beep2Played = false;
      m_beep1Played = false;
     }
   if(InpEnableBarCountdownSound && remainSec == 3 && !m_beep3Played)
     {
      PlaySound("stops.wav");
      m_beep3Played = true;
     }
   else
      if(InpEnableBarCountdownSound && remainSec == 2 && !m_beep2Played)
        {
         PlaySound("stops.wav");
         m_beep2Played = true;
        }
      else
         if(InpEnableBarCountdownSound && remainSec == 1 && !m_beep1Played)
           {
            PlaySound("stops.wav");
            m_beep1Played = true;
           }

//--- 已收盘K线波动标签
   if(m_showCandleRangeStats)
      UpdateCandleRangeLabels();
   else
      DeleteCandleRangeLabels();

//--- 手动拖动某笔订单的TP/SL后，先回填输入框，再复用现有同步模块
   SyncDraggedTpSlToPanel();

//---
   UpdateChartLabels(buys, buyLots, buyPft, sells, sellLots, sellPft,
                     buyAvgPrice, sellAvgPrice, buyLiqPrice, sellLiqPrice);

//--- TP/SL auto apply: no button needed
   string tpText = m_edtTpPct.Text();
   string slText = m_edtSlPct.Text();
   ulong nowTick = refreshTick;
   if(tpText != m_lastTpText || slText != m_lastSlText)
     {
      m_lastTpText = tpText;
      m_lastSlText = slText;
      m_lastTpSlEditTick = nowTick;
     }
   else
      if(nowTick - m_lastTpSlEditTick >= 500)
        {
         double tp = ParsePriceInput(tpText);
         double sl = ParsePriceInput(slText);
         if(m_forceTpSlApply || tp != m_lastAppliedTp || sl != m_lastAppliedSl)
           {
            m_forceTpSlApply = false;
            m_lastAppliedTp = tp;
            m_lastAppliedSl = sl;
            ApplyTpSlToAll();
           }
        }

   // Arrow auto-trade is disabled in this lab version.

  }

//+------------------------------------------------------------------+
//| ?                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::Reposition()
  {
   int chartW = (int)ChartGetInteger(m_chart_id, CHART_WIDTH_IN_PIXELS);
   int chartH = (int)ChartGetInteger(m_chart_id, CHART_HEIGHT_IN_PIXELS);
   int x = (chartW - PANEL_WIDTH) / 2;
   if(x < 0)
      x = 0;
   int y = chartH - PANEL_HEIGHT - 25;
   Move(x, y);
  }

//+------------------------------------------------------------------+
//| 统一市价下单入口                                                 |
//+------------------------------------------------------------------+
bool CQuickTradePanel::ExecuteMarketOrder(const ENUM_POSITION_TYPE posType,
      const double lots,
      const string orderComment,
      const bool resetInputsAfter)
  {
   double normLots = NormLots(lots);
   if(normLots <= 0.0)
      return false;

   double tp = ParsePriceInput(m_edtTpPct.Text());
   double sl = ParsePriceInput(m_edtSlPct.Text());
   ResolveTpSlTemplate(posType, tp, sl);

   double marketPrice = (posType == POSITION_TYPE_BUY
                         ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                         : SymbolInfoDouble(_Symbol, SYMBOL_BID));

   if(sl > 0.0 && !IsPriceValidForOrderSide(posType, marketPrice, sl, false))
      Print("[Panel] ", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            "提示: 当前SL价格方向不合法，可能被服务器拒绝 | SL:", DoubleToString(sl, _Digits),
            " | Price:", DoubleToString(marketPrice, _Digits));

   if(tp > 0.0 && !IsPriceValidForOrderSide(posType, marketPrice, tp, true))
      Print("[Panel] ", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            "提示: 当前TP价格方向不合法，可能被服务器拒绝 | TP:", DoubleToString(tp, _Digits),
            " | Price:", DoubleToString(marketPrice, _Digits));

   m_trade.SetTypeFilling(DetectFilling());

   bool sent = false;
   if(posType == POSITION_TYPE_BUY)
      sent = m_trade.Buy(normLots, _Symbol, 0, sl, tp, orderComment);
   else
      sent = m_trade.Sell(normLots, _Symbol, 0, sl, tp, orderComment);

   if(sent)
     {
      m_asyncPending++;
      SoundTrade();
      Print("[Panel] Async ", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " sent | Lots:", normLots,
            " | Order:", m_trade.ResultOrder(),
            " | Comment:", orderComment);

      if(m_closeReverse)
        {
         Print("[Panel] Reverse close triggered -> async close ",
               (posType == POSITION_TYPE_BUY ? "SELLs" : "BUYs"));
         AsyncCloseByType(posType == POSITION_TYPE_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY);
        }
     }
   else
     {
      SoundError();
      Print("[Panel] ", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " send failed: ", m_trade.ResultRetcodeDescription(),
            " | Comment:", orderComment);
     }

   if(resetInputsAfter)
      ResetTpSlInputs();

   return sent;
  }

//+------------------------------------------------------------------+
//| BUY  -                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickBuy()
  {
   m_lots = NormLots(StringToDouble(m_edtLots.Text()));
   UpdateLotsDisplay();
   ExecuteMarketOrder(POSITION_TYPE_BUY, m_lots, "QuickPanel Buy", true);
  }

//+------------------------------------------------------------------+
//| SELL  -                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickSell()
  {
   m_lots = NormLots(StringToDouble(m_edtLots.Text()));
   UpdateLotsDisplay();
   ExecuteMarketOrder(POSITION_TYPE_SELL, m_lots, "QuickPanel Sell", true);
  }

//+------------------------------------------------------------------+
//|                                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickCloseBuys()
  {
   SoundClose();
   AsyncCloseByType(POSITION_TYPE_BUY);
   ResetTpSlInputs();
  }

//+------------------------------------------------------------------+
//|                                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickCloseSells()
  {
   SoundClose();
   AsyncCloseByType(POSITION_TYPE_SELL);
   ResetTpSlInputs();
  }

//+------------------------------------------------------------------+
//| ?+ ?+ ?                                   |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickCloseAll()
  {
//--- do not stack close-all while async requests are pending
   if(m_asyncPending > 0)
     {
      SoundError();
      Print("[Panel] There are ", m_asyncPending, " pending async requests, please retry later");
      ResetTpSlInputs();
      return;
     }

   SoundClose();

//--- close all positions first
   AsyncCloseByType(POSITION_TYPE_BUY);
   AsyncCloseByType(POSITION_TYPE_SELL);

//--- then delete all pending orders
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      string sym = OrderGetString(ORDER_SYMBOL);
      long   mag = OrderGetInteger(ORDER_MAGIC);

      if(InpCurrentOnly && sym != _Symbol)
         continue;
      if(InpMagicNumber > 0 && mag != InpMagicNumber)
         continue;

      if(m_trade.OrderDelete(ticket))
        {
         m_asyncPending++;
         Print("[Panel] Async delete pending order #", ticket, " | Order:", m_trade.ResultOrder());
        }
     }

   ResetTpSlInputs();
  }

//+------------------------------------------------------------------+
//| ?                                        |
//+------------------------------------------------------------------+
void CQuickTradePanel::AsyncCloseByType(ENUM_POSITION_TYPE type)
  {
   m_trade.SetTypeFilling(DetectFilling());

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      if(m_posInfo.PositionType() != type)
         continue;

      ulong ticket = m_posInfo.Ticket();
      if(FindPendingCloseIndex(ticket) >= 0)
         continue;

      if(m_trade.PositionClose(ticket))
        {
         AddPendingCloseTicket(ticket);
         m_asyncPending++;
         Print("[Panel] Async close #", ticket, " ",
               (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               " | Lots:", m_posInfo.Volume(),
               " | Order:", m_trade.ResultOrder());
        }
      else
         Print("[Panel] Close failed #", ticket, ": ",
               m_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//|  +                                                             |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickLotsPlus()
  {
   SoundClick();
   m_lots = NormLots(StringToDouble(m_edtLots.Text()) + InpLotsStep);
   UpdateLotsDisplay();
  }

//+------------------------------------------------------------------+
//|  -                                                             |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickLotsMinus()
  {
   SoundClick();
   m_lots = NormLots(StringToDouble(m_edtLots.Text()) - InpLotsStep);
   UpdateLotsDisplay();
  }

//+------------------------------------------------------------------+
//|  x2                                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickLotsX2()
  {
   SoundClick();
   m_lots = NormLots(StringToDouble(m_edtLots.Text()) * 2.0);
   UpdateLotsDisplay();
  }

//+------------------------------------------------------------------+
//|  /2                                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickLotsD2()
  {
   SoundClick();
   m_lots = NormLots(StringToDouble(m_edtLots.Text()) / 2.0);
   UpdateLotsDisplay();
  }

//+------------------------------------------------------------------+
//| ?                                                  |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickToggleReverse()
  {
   SoundClick();
   m_closeReverse = !m_closeReverse;

   if(m_closeReverse)
     {
      m_btnToggleReverse.Text("反向平仓: 开");
      m_btnToggleReverse.ColorBackground(C'0,100,60');
      m_btnToggleReverse.Color(clrLime);
      Print("[Panel] 反向平仓已开启");
     }
   else
     {
      m_btnToggleReverse.Text("反向平仓: 关");
      m_btnToggleReverse.ColorBackground(C'50,50,50');
      m_btnToggleReverse.Color(clrGray);
      Print("[Panel] 反向平仓已关闭");
     }
  }

//+------------------------------------------------------------------+
//| K线波幅统计开关                                                  |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickToggleRangeStats()
  {
   SoundClick();
   m_showCandleRangeStats = !m_showCandleRangeStats;
   UpdateRangeStatsToggleButton();

   if(m_showCandleRangeStats)
     {
      UpdateCandleRangeLabels();
      Print("[Panel] K线波幅统计已开启");
     }
   else
     {
      DeleteCandleRangeLabels();
      Print("[Panel] K线波幅统计已关闭");
     }

   m_lastUpdateTick = 0;
   UpdateInfo();
  }

//+------------------------------------------------------------------+
//| 浮盈加仓保本开关                                                  |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickToggleAddOnBreakeven()
  {
   SoundClick();
   m_autoAddOnBreakeven = !m_autoAddOnBreakeven;
   if(!m_autoAddOnBreakeven)
     {
      m_pendingAutoBeBuy = false;
      m_pendingAutoBeSell = false;
     }

   UpdateAddOnBreakevenToggleButton();
   Print(m_autoAddOnBreakeven ? "[Panel] 浮盈加仓保本已开启" : "[Panel] 浮盈加仓保本已关闭");
   m_lastUpdateTick = 0;
   UpdateInfo();
  }

//+------------------------------------------------------------------+
//| 浮盈加仓开关                                                     |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickToggleFloatAdd()
  {
   SoundClick();
   m_autoFloatProfitAdd = !m_autoFloatProfitAdd;
   m_pendingFloatAddBuy = false;
   m_pendingFloatAddSell = false;
   m_nextFloatAddBuyProfit = 0.0;
   m_nextFloatAddSellProfit = 0.0;

   UpdateFloatAddToggleButton();
   UpdateFloatAddConfigLabel();
   Print(m_autoFloatProfitAdd ? "[Panel] 浮盈加仓已开启" : "[Panel] 浮盈加仓已关闭");
   m_lastUpdateTick = 0;
   UpdateInfo();
  }

//+------------------------------------------------------------------+
//| 解析价格输入(0表示不设置)                                           |
//+------------------------------------------------------------------+
double CQuickTradePanel::ParsePriceInput(const string text)
  {
   string value = text;
   StringReplace(value, " ", "");
   StringReplace(value, ",", "");
   if(value == "" || value == "0" || value == "0.0" || value == "0.00")
      return 0.0;

   double price = StringToDouble(value);
   if(price <= 0.0)
      return 0.0;

   return NormalizeDouble(price, _Digits);
  }

//+------------------------------------------------------------------+
//| 挂单是否属于买侧                                                  |
//+------------------------------------------------------------------+
bool CQuickTradePanel::IsBuyManagedOrderType(const ENUM_ORDER_TYPE orderType)
  {
   return (orderType == ORDER_TYPE_BUY_LIMIT ||
           orderType == ORDER_TYPE_BUY_STOP ||
           orderType == ORDER_TYPE_BUY_STOP_LIMIT);
  }

//+------------------------------------------------------------------+
//| 给定方向下，价格是否处于合法TP/SL一侧                             |
//+------------------------------------------------------------------+
bool CQuickTradePanel::IsPriceValidForOrderSide(const ENUM_POSITION_TYPE posType,
      const double marketPrice,
      const double price,
      const bool isTakeProfit)
  {
   if(price <= 0.0 || marketPrice <= 0.0)
      return false;

   if(posType == POSITION_TYPE_BUY)
      return (isTakeProfit ? price > marketPrice : price < marketPrice);

   return (isTakeProfit ? price < marketPrice : price > marketPrice);
  }

//+------------------------------------------------------------------+
//| 新开单前，若输入框为空，则沿用当前受控订单已有的TP/SL模板         |
//+------------------------------------------------------------------+
void CQuickTradePanel::ResolveTpSlTemplate(const ENUM_POSITION_TYPE posType, double &tp, double &sl)
  {
   bool needTp = (tp <= 0.0);
   bool needSl = (sl <= 0.0);
   if(!needTp && !needSl)
      return;

   double marketPrice = (posType == POSITION_TYPE_BUY
                         ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                         : SymbolInfoDouble(_Symbol, SYMBOL_BID));
   if(marketPrice <= 0.0)
      marketPrice = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

// 先找同方向模板，直接继承最稳。
   for(int i = PositionsTotal() - 1; (i >= 0) && (needTp || needSl); i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      if(m_posInfo.PositionType() != posType)
         continue;

      double posSl = m_posInfo.StopLoss();
      double posTp = m_posInfo.TakeProfit();

      if(needSl && IsPriceValidForOrderSide(posType, marketPrice, posSl, false))
        {
         sl = NormalizeDouble(posSl, _Digits);
         needSl = false;
        }
      if(needTp && IsPriceValidForOrderSide(posType, marketPrice, posTp, true))
        {
         tp = NormalizeDouble(posTp, _Digits);
         needTp = false;
        }
     }

   for(int i = OrdersTotal() - 1; (i >= 0) && (needTp || needSl); i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      string sym = OrderGetString(ORDER_SYMBOL);
      long   mag = OrderGetInteger(ORDER_MAGIC);
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);

      if(InpCurrentOnly && sym != _Symbol)
         continue;
      if(InpMagicNumber > 0 && mag != InpMagicNumber)
         continue;
      if(orderType != ORDER_TYPE_BUY_LIMIT  &&
         orderType != ORDER_TYPE_SELL_LIMIT &&
         orderType != ORDER_TYPE_BUY_STOP   &&
         orderType != ORDER_TYPE_SELL_STOP  &&
         orderType != ORDER_TYPE_BUY_STOP_LIMIT &&
         orderType != ORDER_TYPE_SELL_STOP_LIMIT)
         continue;

      bool orderIsBuy = IsBuyManagedOrderType(orderType);
      if((posType == POSITION_TYPE_BUY && !orderIsBuy) ||
         (posType == POSITION_TYPE_SELL && orderIsBuy))
         continue;

      double ordSl = OrderGetDouble(ORDER_SL);
      double ordTp = OrderGetDouble(ORDER_TP);

      if(needSl && IsPriceValidForOrderSide(posType, marketPrice, ordSl, false))
        {
         sl = NormalizeDouble(ordSl, _Digits);
         needSl = false;
        }
      if(needTp && IsPriceValidForOrderSide(posType, marketPrice, ordTp, true))
        {
         tp = NormalizeDouble(ordTp, _Digits);
         needTp = false;
        }
     }

// 如果只有反方向订单，则从现有两个价位里挑出当前方向合法的一侧。
   for(int i = PositionsTotal() - 1; (i >= 0) && (needTp || needSl); i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      if(m_posInfo.PositionType() == posType)
         continue;

      double candidateA = m_posInfo.StopLoss();
      double candidateB = m_posInfo.TakeProfit();

      if(needSl && IsPriceValidForOrderSide(posType, marketPrice, candidateA, false))
        {
         sl = NormalizeDouble(candidateA, _Digits);
         needSl = false;
        }
      if(needTp && IsPriceValidForOrderSide(posType, marketPrice, candidateA, true))
        {
         tp = NormalizeDouble(candidateA, _Digits);
         needTp = false;
        }
      if(needSl && IsPriceValidForOrderSide(posType, marketPrice, candidateB, false))
        {
         sl = NormalizeDouble(candidateB, _Digits);
         needSl = false;
        }
      if(needTp && IsPriceValidForOrderSide(posType, marketPrice, candidateB, true))
        {
         tp = NormalizeDouble(candidateB, _Digits);
         needTp = false;
        }
     }

   for(int i = OrdersTotal() - 1; (i >= 0) && (needTp || needSl); i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      string sym = OrderGetString(ORDER_SYMBOL);
      long   mag = OrderGetInteger(ORDER_MAGIC);
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);

      if(InpCurrentOnly && sym != _Symbol)
         continue;
      if(InpMagicNumber > 0 && mag != InpMagicNumber)
         continue;
      if(orderType != ORDER_TYPE_BUY_LIMIT  &&
         orderType != ORDER_TYPE_SELL_LIMIT &&
         orderType != ORDER_TYPE_BUY_STOP   &&
         orderType != ORDER_TYPE_SELL_STOP  &&
         orderType != ORDER_TYPE_BUY_STOP_LIMIT &&
         orderType != ORDER_TYPE_SELL_STOP_LIMIT)
         continue;

      bool orderIsBuy = IsBuyManagedOrderType(orderType);
      if((posType == POSITION_TYPE_BUY && orderIsBuy) ||
         (posType == POSITION_TYPE_SELL && !orderIsBuy))
         continue;

      double candidateA = OrderGetDouble(ORDER_SL);
      double candidateB = OrderGetDouble(ORDER_TP);

      if(needSl && IsPriceValidForOrderSide(posType, marketPrice, candidateA, false))
        {
         sl = NormalizeDouble(candidateA, _Digits);
         needSl = false;
        }
      if(needTp && IsPriceValidForOrderSide(posType, marketPrice, candidateA, true))
        {
         tp = NormalizeDouble(candidateA, _Digits);
         needTp = false;
        }
      if(needSl && IsPriceValidForOrderSide(posType, marketPrice, candidateB, false))
        {
         sl = NormalizeDouble(candidateB, _Digits);
         needSl = false;
        }
      if(needTp && IsPriceValidForOrderSide(posType, marketPrice, candidateB, true))
        {
         tp = NormalizeDouble(candidateB, _Digits);
         needTp = false;
        }
     }

   string tpText = (tp > 0.0 ? DoubleToString(tp, _Digits) : "0");
   string slText = (sl > 0.0 ? DoubleToString(sl, _Digits) : "0");
   m_edtTpPct.Text(tpText);
   m_edtSlPct.Text(slText);
   m_lastTpText = tpText;
   m_lastSlText = slText;
   m_lastTpSlEditTick = GetTickCount();

   if(tp > 0.0 || sl > 0.0)
      Print("[Panel] 新单沿用TP/SL模板 | TP:", tpText, " | SL:", slText,
            " | Side:", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"));
  }

//+------------------------------------------------------------------+
//| 交易返回码说明                                                    |
//+------------------------------------------------------------------+
string CQuickTradePanel::DescribeTradeRetcode(const uint retcode)
  {
   if(retcode == TRADE_RETCODE_DONE)
      return "Done";
   if(retcode == TRADE_RETCODE_DONE_PARTIAL)
      return "Done partial";
   if(retcode == TRADE_RETCODE_PLACED)
      return "Placed";
   if(retcode == TRADE_RETCODE_REQUOTE)
      return "Requote";
   if(retcode == TRADE_RETCODE_REJECT)
      return "Rejected";
   if(retcode == TRADE_RETCODE_CANCEL)
      return "Canceled";
   if(retcode == TRADE_RETCODE_NO_MONEY)
      return "No money";
   if(retcode == TRADE_RETCODE_TIMEOUT)
      return "Timeout";
   if(retcode == TRADE_RETCODE_INVALID)
      return "Invalid request";
   if(retcode == TRADE_RETCODE_INVALID_PRICE)
      return "Invalid price";
   if(retcode == TRADE_RETCODE_INVALID_STOPS)
      return "Invalid stops";
   if(retcode == TRADE_RETCODE_INVALID_VOLUME)
      return "Invalid volume";
   if(retcode == TRADE_RETCODE_INVALID_FILL)
      return "Invalid filling mode";
   if(retcode == TRADE_RETCODE_POSITION_CLOSED)
      return "Position already closed";
   if(retcode == TRADE_RETCODE_CLOSE_ORDER_EXIST)
      return "Close order already exists";
   if(retcode == TRADE_RETCODE_ORDER_CHANGED)
      return "Order changed";
   if(retcode == TRADE_RETCODE_TOO_MANY_REQUESTS)
      return "Too many requests";
   return "Other error";
  }

//+------------------------------------------------------------------+
//| 将输入价格应用到全部订单/持仓                                         |
//+------------------------------------------------------------------+
void CQuickTradePanel::ApplyTpSlToAll()
  {
   double tp = ParsePriceInput(m_edtTpPct.Text());
   double sl = ParsePriceInput(m_edtSlPct.Text());

   m_ignoreExternalTpSlUntil = GetTickCount() + 3000;

   m_edtTpPct.Text(tp > 0.0 ? DoubleToString(tp, _Digits) : "0");
   m_edtSlPct.Text(sl > 0.0 ? DoubleToString(sl, _Digits) : "0");

   int posOk = 0;
   int ordOk = 0;
   int skip = 0;
   int fail  = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;

      ulong ticket = m_posInfo.Ticket();
      double currentSl = m_posInfo.StopLoss();
      double currentTp = m_posInfo.TakeProfit();
      if(SamePrice(currentSl, sl) && SamePrice(currentTp, tp))
        {
         skip++;
         continue;
        }

      if(m_trade.PositionModify(ticket, sl, tp))
        {
         m_asyncPending++;
         posOk++;
        }
      else
        {
         fail++;
         Print("[Panel] PositionModify失败 #", ticket, ": ", m_trade.ResultRetcodeDescription());
        }
     }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      string sym = OrderGetString(ORDER_SYMBOL);
      long   mag = OrderGetInteger(ORDER_MAGIC);
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);

      if(InpCurrentOnly && sym != _Symbol)
         continue;
      if(InpMagicNumber > 0 && mag != InpMagicNumber)
         continue;

      if(orderType != ORDER_TYPE_BUY_LIMIT  &&
         orderType != ORDER_TYPE_SELL_LIMIT &&
         orderType != ORDER_TYPE_BUY_STOP   &&
         orderType != ORDER_TYPE_SELL_STOP  &&
         orderType != ORDER_TYPE_BUY_STOP_LIMIT &&
         orderType != ORDER_TYPE_SELL_STOP_LIMIT)
         continue;

      double priceOpen = OrderGetDouble(ORDER_PRICE_OPEN);
      double stopLimit = OrderGetDouble(ORDER_PRICE_STOPLIMIT);
      ENUM_ORDER_TYPE_TIME typeTime = (ENUM_ORDER_TYPE_TIME)OrderGetInteger(ORDER_TYPE_TIME);
      datetime expiration = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
      double currentSl = OrderGetDouble(ORDER_SL);
      double currentTp = OrderGetDouble(ORDER_TP);

      if(SamePrice(currentSl, sl) && SamePrice(currentTp, tp))
        {
         skip++;
         continue;
        }

      if(m_trade.OrderModify(ticket, priceOpen, sl, tp, typeTime, expiration, stopLimit))
        {
         m_asyncPending++;
         ordOk++;
        }
      else
        {
         fail++;
         Print("[Panel] OrderModify失败 #", ticket, ": ", m_trade.ResultRetcodeDescription());
        }
     }

   Print("[Panel] TP/SL应用完成 | TP:", (tp > 0.0 ? DoubleToString(tp, _Digits) : "0"),
         " | SL:", (sl > 0.0 ? DoubleToString(sl, _Digits) : "0"),
         " | 持仓:", posOk, " | 挂单:", ordOk, " | 跳过:", skip, " | 失败:", fail);
  }

//+------------------------------------------------------------------+
//| 按钮动作后清空TP/SL输入                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::ResetTpSlInputs()
  {
   m_edtTpPct.Text("0");
   m_edtSlPct.Text("0");
   m_lastTpText = "0";
   m_lastSlText = "0";
   m_lastAppliedTp = 0.0;
   m_lastAppliedSl = 0.0;
   m_lastTpSlEditTick = GetTickCount();
  }

//+------------------------------------------------------------------+
//| ?                                                        |
//+------------------------------------------------------------------+
double CQuickTradePanel::NormLots(double lots)
  {
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lotStep > 0)
      lots = MathFloor(lots / lotStep) * lotStep;

   lots = MathMax(minLot, MathMin(maxLot, lots));
   return NormalizeDouble(lots, 2);
  }

//+------------------------------------------------------------------+
//|                                                        |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateLotsDisplay()
  {
   m_edtLots.Text(DoubleToString(m_lots, 2));
  }

//+------------------------------------------------------------------+
//|                                              |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING CQuickTradePanel::DetectFilling()
  {
   long fillMode = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fillMode & SYMBOL_FILLING_IOC) != 0)
      return ORDER_FILLING_IOC;
   if((fillMode & SYMBOL_FILLING_FOK) != 0)
      return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
  }

//+------------------------------------------------------------------+
//| K线波动标签辅助函数                                              |
//+------------------------------------------------------------------+
string CQuickTradePanel::CandleRangeLabelName(const int shift)
  {
   return StringFormat("%s%d", K_RANGE_LABEL_PREFIX, shift);
  }

//+------------------------------------------------------------------+
//| 图表缩放越大，字体也越大                                          |
//+------------------------------------------------------------------+
int CQuickTradePanel::CandleRangeFontSize()
  {
   long scale = 0;
   if(!ChartGetInteger(m_chart_id, CHART_SCALE, 0, scale))
      scale = 2;

   switch((int)scale)
     {
      case 0:
         return 6;
      case 1:
         return 7;
      case 2:
         return 8;
      case 3:
         return 9;
      case 4:
         return 10;
      case 5:
         return 12;
     }

   return 8;
  }

//+------------------------------------------------------------------+
//| 标签放在K线低点下方，给一点安全间距                               |
//+------------------------------------------------------------------+
double CQuickTradePanel::CandleRangeOffset(const double candleRange, const double visibleRange)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      point = _Point;

   double minOffset = MathMax(80.0 * point, visibleRange * 0.008);
   double dynamicOffset = candleRange * 0.22;
   return MathMax(minOffset, dynamicOffset);
  }

//+------------------------------------------------------------------+
//| 更新已收盘K线的波动金额标签                                        |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateCandleRangeLabels()
  {
   if(!m_showCandleRangeStats)
     {
      DeleteCandleRangeLabels();
      return;
     }

   long chartId = m_chart_id;
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)ChartPeriod(chartId);
   if(tf <= PERIOD_CURRENT)
      tf = _Period;

   int bars = iBars(_Symbol, tf);
   int labelCount = MathMin(K_RANGE_MAX_BARS, MathMax(bars - 1, 0));
   int fontSize = CandleRangeFontSize();

   double priceMax = 0.0;
   double priceMin = 0.0;
   if(!ChartGetDouble(chartId, CHART_PRICE_MAX, 0, priceMax))
      priceMax = 0.0;
   if(!ChartGetDouble(chartId, CHART_PRICE_MIN, 0, priceMin))
      priceMin = 0.0;

   double visibleRange = priceMax - priceMin;
   if(visibleRange <= 0.0)
      visibleRange = 1000.0 * _Point;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(digits < 2)
      digits = 2;

   for(int shift = 1; shift <= labelCount; shift++)
     {
      datetime barTime = iTime(_Symbol, tf, shift);
      double high = iHigh(_Symbol, tf, shift);
      double low  = iLow(_Symbol, tf, shift);
      if(barTime <= 0 || high <= 0.0 || low <= 0.0 || high < low)
         continue;

      double candleRange = high - low;
      double priceY = low - CandleRangeOffset(candleRange, visibleRange);
      string name = CandleRangeLabelName(shift);
      string text = DoubleToString(candleRange, digits);

      if(ObjectFind(chartId, name) < 0)
         ObjectCreate(chartId, name, OBJ_TEXT, 0, barTime, priceY);

      ObjectMove(chartId, name, 0, barTime, priceY);
      ObjectSetString(chartId,  name, OBJPROP_TEXT, text);
      ObjectSetString(chartId,  name, OBJPROP_FONT, TOP_FONT_NAME);
      ObjectSetInteger(chartId, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(chartId, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
      ObjectSetInteger(chartId, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, name, OBJPROP_HIDDEN, true);
     }

   for(int shift = labelCount + 1; shift <= K_RANGE_MAX_BARS; shift++)
      ObjectDelete(chartId, CandleRangeLabelName(shift));
  }

//+------------------------------------------------------------------+
//| 删除K线波动标签                                                   |
//+------------------------------------------------------------------+
void CQuickTradePanel::DeleteCandleRangeLabels()
  {
   for(int shift = 1; shift <= K_RANGE_MAX_BARS; shift++)
      ObjectDelete(m_chart_id, CandleRangeLabelName(shift));
  }

//+------------------------------------------------------------------+
//| 对外暴露一个刷新入口，便于图表变化时立即同步                      |
//+------------------------------------------------------------------+
void CQuickTradePanel::RefreshCandleRangeLabels()
  {
   if(m_showCandleRangeStats)
      UpdateCandleRangeLabels();
   else
      DeleteCandleRangeLabels();
  }

//+------------------------------------------------------------------+
//| 查找已跟踪持仓索引                                                |
//+------------------------------------------------------------------+
int CQuickTradePanel::FindTrackedPositionIndex(const ulong ticket)
  {
   int total = ArraySize(m_trackedPosTickets);
   for(int i = 0; i < total; i++)
     {
      if(m_trackedPosTickets[i] == ticket)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| 查找已跟踪挂单索引                                                |
//+------------------------------------------------------------------+
int CQuickTradePanel::FindTrackedOrderIndex(const ulong ticket)
  {
   int total = ArraySize(m_trackedOrdTickets);
   for(int i = 0; i < total; i++)
     {
      if(m_trackedOrdTickets[i] == ticket)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| 查找待回执平仓票据索引                                            |
//+------------------------------------------------------------------+
int CQuickTradePanel::FindPendingCloseIndex(const ulong ticket)
  {
   int total = ArraySize(m_pendingCloseTickets);
   for(int i = 0; i < total; i++)
     {
      if(m_pendingCloseTickets[i] == ticket)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| 标记待回执平仓票据                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::AddPendingCloseTicket(const ulong ticket)
  {
   if(ticket == 0 || FindPendingCloseIndex(ticket) >= 0)
      return;

   int size = ArraySize(m_pendingCloseTickets);
   ArrayResize(m_pendingCloseTickets, size + 1);
   m_pendingCloseTickets[size] = ticket;
  }

//+------------------------------------------------------------------+
//| 移除待回执平仓票据                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::RemovePendingCloseTicket(const ulong ticket)
  {
   int idx = FindPendingCloseIndex(ticket);
   if(idx < 0)
      return;

   int size = ArraySize(m_pendingCloseTickets);
   for(int i = idx; i < size - 1; i++)
      m_pendingCloseTickets[i] = m_pendingCloseTickets[i + 1];

   ArrayResize(m_pendingCloseTickets, size - 1);
  }

//+------------------------------------------------------------------+
//| 统计指定方向当前持仓                                              |
//+------------------------------------------------------------------+
bool CQuickTradePanel::CollectSideExposure(const ENUM_POSITION_TYPE posType,
      int &count,
      double &totalVolume,
      double &netProfit,
      double &minOpen,
      double &maxOpen)
  {
   count = 0;
   totalVolume = 0.0;
   netProfit = 0.0;
   minOpen = 0.0;
   maxOpen = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      if(m_posInfo.PositionType() != posType)
         continue;

      double open = m_posInfo.PriceOpen();
      double vol = m_posInfo.Volume();
      double pnl = m_posInfo.Profit() + m_posInfo.Swap() + m_posInfo.Commission();

      if(count == 0)
        {
         minOpen = open;
         maxOpen = open;
        }
      else
        {
         minOpen = MathMin(minOpen, open);
         maxOpen = MathMax(maxOpen, open);
        }

      count++;
      totalVolume += vol;
      netProfit += pnl;
     }

   return (count > 0 && totalVolume > 0.0);
  }

//+------------------------------------------------------------------+
//| 计算指定价位下同方向整组仓位净盈亏                                |
//+------------------------------------------------------------------+
double CQuickTradePanel::CombinedProfitAtPrice(const ENUM_POSITION_TYPE posType, const double closePrice)
  {
   double totalProfit = 0.0;
   ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      if(m_posInfo.PositionType() != posType)
         continue;

      double calcProfit = 0.0;
      if(!OrderCalcProfit(orderType, _Symbol, m_posInfo.Volume(), m_posInfo.PriceOpen(), closePrice, calcProfit))
         return -DBL_MAX;

      totalProfit += calcProfit + m_posInfo.Swap() + m_posInfo.Commission();
     }

   return totalProfit;
  }

//+------------------------------------------------------------------+
//| 计算指定方向的组合保本止损价                                      |
//+------------------------------------------------------------------+
bool CQuickTradePanel::ComputeBreakevenStopForSide(const ENUM_POSITION_TYPE posType, double &stopPrice)
  {
   stopPrice = 0.0;

   int count = 0;
   double totalVolume = 0.0;
   double netProfit = 0.0;
   double minOpen = 0.0;
   double maxOpen = 0.0;
   if(!CollectSideExposure(posType, count, totalVolume, netProfit, minOpen, maxOpen))
      return false;
   if(netProfit <= 0.0)
      return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      point = _Point;

   double marketPrice = (posType == POSITION_TYPE_BUY
                         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   if(marketPrice <= 0.0)
      return false;

   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int freezeLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double minDistance = (MathMax(stopsLevel, freezeLevel) + 1) * point;
   double buffer = MathMax(0, InpAddOnBreakevenBufferPoints) * point;
   double lockPercent = MathMax(0.0, MathMin(100.0, InpAddOnBreakevenLockProfitPercent));

   if(posType == POSITION_TYPE_BUY)
     {
      double legalHigh = marketPrice - minDistance;
      if(legalHigh <= 0.0)
         return false;

      double maxProtectedProfit = CombinedProfitAtPrice(posType, legalHigh);
      if(maxProtectedProfit < 0.0)
         return false;

      double targetProfit = netProfit * lockPercent / 100.0;
      if(targetProfit < 0.0)
         targetProfit = 0.0;
      if(targetProfit > maxProtectedProfit)
         targetProfit = maxProtectedProfit;

      double span = MathMax(MathAbs(maxOpen - minOpen), 1000.0 * point);
      double low = MathMin(minOpen, marketPrice) - span;
      double lowProfit = CombinedProfitAtPrice(posType, low);
      int expand = 0;
      while(lowProfit > targetProfit && expand < 24)
        {
         span *= 2.0;
         low = MathMin(minOpen, marketPrice) - span;
         lowProfit = CombinedProfitAtPrice(posType, low);
         expand++;
        }
      if(lowProfit > targetProfit)
         return false;

      double high = legalHigh;
      for(int i = 0; i < 48; i++)
        {
         double mid = (low + high) * 0.5;
         double midProfit = CombinedProfitAtPrice(posType, mid);
         if(midProfit >= targetProfit)
            high = mid;
         else
            low = mid;
        }

      stopPrice = NormalizeDouble(MathMin(high + buffer, legalHigh), _Digits);
      return IsPriceValidForOrderSide(posType, marketPrice, stopPrice, false);
     }

   double legalLow = marketPrice + minDistance;
   double maxProtectedProfit = CombinedProfitAtPrice(posType, legalLow);
   if(maxProtectedProfit < 0.0)
      return false;

   double targetProfit = netProfit * lockPercent / 100.0;
   if(targetProfit < 0.0)
      targetProfit = 0.0;
   if(targetProfit > maxProtectedProfit)
      targetProfit = maxProtectedProfit;

   double span = MathMax(MathAbs(maxOpen - minOpen), 1000.0 * point);
   double high = MathMax(maxOpen, marketPrice) + span;
   double highProfit = CombinedProfitAtPrice(posType, high);
   int expand = 0;
   while(highProfit > targetProfit && expand < 24)
     {
      span *= 2.0;
      high = MathMax(maxOpen, marketPrice) + span;
      highProfit = CombinedProfitAtPrice(posType, high);
      expand++;
     }
   if(highProfit > targetProfit)
      return false;

   double low = legalLow;
   for(int i = 0; i < 48; i++)
     {
      double mid = (low + high) * 0.5;
      double midProfit = CombinedProfitAtPrice(posType, mid);
      if(midProfit >= targetProfit)
         low = mid;
      else
         high = mid;
     }

   stopPrice = NormalizeDouble(MathMax(low - buffer, legalLow), _Digits);
   return IsPriceValidForOrderSide(posType, marketPrice, stopPrice, false);
  }

//+------------------------------------------------------------------+
//| 将指定方向全部持仓SL推到组合保本位                                |
//+------------------------------------------------------------------+
bool CQuickTradePanel::ApplyBreakevenStopForSide(const ENUM_POSITION_TYPE posType)
  {
   double stopPrice = 0.0;
   if(!ComputeBreakevenStopForSide(posType, stopPrice))
      return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      point = _Point;

   int modified = 0;
   int skipped = 0;
   m_ignoreExternalTpSlUntil = GetTickCount() + 3000;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      if(m_posInfo.PositionType() != posType)
         continue;

      double currentSl = m_posInfo.StopLoss();
      bool shouldModify = false;
      if(posType == POSITION_TYPE_BUY)
         shouldModify = (currentSl <= 0.0 || stopPrice > currentSl + point * 0.5);
      else
         shouldModify = (currentSl <= 0.0 || stopPrice < currentSl - point * 0.5);

      if(!shouldModify)
        {
         skipped++;
         continue;
        }

      ulong ticket = m_posInfo.Ticket();
      double tp = m_posInfo.TakeProfit();
      if(m_trade.PositionModify(ticket, stopPrice, tp))
        {
         m_asyncPending++;
         modified++;
        }
      else
        {
         Print("[Panel] 加仓保本止损修改失败 #", ticket, ": ", m_trade.ResultRetcodeDescription());
        }
     }

   if(modified > 0 || skipped > 0)
     {
      Print("[Panel] 浮盈加仓保本触发 | Side:", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " | SL:", DoubleToString(stopPrice, _Digits),
            " | 锁盈比例:", DoubleToString(MathMax(0.0, MathMin(100.0, InpAddOnBreakevenLockProfitPercent)), 1), "%",
            " | 修改:", modified, " | 已更优跳过:", skipped);
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| 成交后标记待触发的加仓保本监控                                    |
//+------------------------------------------------------------------+
void CQuickTradePanel::FlagAutoBreakevenFromDeal(const ulong dealTicket, const string symbol)
  {
   if(!m_autoAddOnBreakeven || dealTicket == 0)
      return;
   if(!HistoryDealSelect(dealTicket))
      return;
   if(InpCurrentOnly && symbol != _Symbol)
      return;

   long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   if(InpMagicNumber > 0 && magic != InpMagicNumber)
      return;

   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
   if(entry != DEAL_ENTRY_IN)
      return;
   if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
      return;

   ENUM_POSITION_TYPE posType = (dealType == DEAL_TYPE_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
   double dealVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
   int count = 0;
   double totalVolume = 0.0;
   double netProfit = 0.0;
   double minOpen = 0.0;
   double maxOpen = 0.0;
   if(!CollectSideExposure(posType, count, totalVolume, netProfit, minOpen, maxOpen))
      return;

   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(lotStep <= 0.0)
      lotStep = 0.01;

   bool isAddOn = (count >= 2 || totalVolume > dealVolume + lotStep * 0.5);
   if(!isAddOn)
      return;

   if(posType == POSITION_TYPE_BUY)
      m_pendingAutoBeBuy = true;
   else
      m_pendingAutoBeSell = true;

   Print("[Panel] 检测到同向加仓，已挂起保本止损监控 | Side:",
         (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
         " | DealVol:", DoubleToString(dealVolume, 2),
         " | TotalVol:", DoubleToString(totalVolume, 2));

   if(ApplyBreakevenStopForSide(posType))
     {
      if(posType == POSITION_TYPE_BUY)
         m_pendingAutoBeBuy = false;
      else
         m_pendingAutoBeSell = false;
     }
  }

//+------------------------------------------------------------------+
//| 按当前同向最新开仓价推算下一次自动加仓的价格台阶                  |
//+------------------------------------------------------------------+
double CQuickTradePanel::ComputeNextFloatAddTrigger(const ENUM_POSITION_TYPE posType,
      const double minOpen,
      const double maxOpen)
  {
   double stepPrice = MathMax(_Point, InpFloatProfitStepMoney);
   double anchorPrice = (posType == POSITION_TYPE_BUY ? maxOpen : minOpen);
   if(anchorPrice <= 0.0)
      return 0.0;

   if(posType == POSITION_TYPE_BUY)
      return NormalizeDouble(anchorPrice + stepPrice, _Digits);

   return NormalizeDouble(anchorPrice - stepPrice, _Digits);
  }

//+------------------------------------------------------------------+
//| 发送自动浮盈加仓单                                                |
//+------------------------------------------------------------------+
bool CQuickTradePanel::SendFloatProfitAddOrder(const ENUM_POSITION_TYPE posType)
  {
   double addLots = NormLots(InpFloatProfitAddLots);
   if(addLots <= 0.0)
      return false;
   string comment = (posType == POSITION_TYPE_BUY ? "QTP FloatAdd Buy" : "QTP FloatAdd Sell");
   bool sent = ExecuteMarketOrder(posType, addLots, comment, false);
   if(!sent)
      return false;

   if(posType == POSITION_TYPE_BUY)
      m_pendingFloatAddBuy = true;
   else
      m_pendingFloatAddSell = true;

   Print("[Panel] 自动浮盈加仓已发送 | Side:",
         (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
         " | Lots:", DoubleToString(addLots, 2),
         " | TriggerPrice:",
         DoubleToString(posType == POSITION_TYPE_BUY ? m_nextFloatAddBuyProfit : m_nextFloatAddSellProfit, _Digits));
   SoundTrade();
   return true;
  }

//+------------------------------------------------------------------+
//| 自动浮盈加仓成交后的状态推进                                      |
//+------------------------------------------------------------------+
void CQuickTradePanel::HandleFloatProfitAddDeal(const ulong dealTicket, const string symbol)
  {
   if(!m_autoFloatProfitAdd || dealTicket == 0)
      return;
   if(!HistoryDealSelect(dealTicket))
      return;
   if(InpCurrentOnly && symbol != _Symbol)
      return;

   long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   if(InpMagicNumber > 0 && magic != InpMagicNumber)
      return;

   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
   string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   if(entry != DEAL_ENTRY_IN)
      return;
   if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
      return;
   if(StringFind(dealComment, "QTP FloatAdd ") != 0)
      return;

   double stepPrice = MathMax(_Point, InpFloatProfitStepMoney);
   double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
   if(dealPrice <= 0.0)
      return;

   if(dealType == DEAL_TYPE_BUY)
     {
      m_pendingFloatAddBuy = false;
      m_nextFloatAddBuyProfit = NormalizeDouble(dealPrice + stepPrice, _Digits);
     }
   else
     {
      m_pendingFloatAddSell = false;
      m_nextFloatAddSellProfit = NormalizeDouble(dealPrice - stepPrice, _Digits);
     }

   Print("[Panel] 阶梯加仓锚点已更新 | Side:",
         (dealType == DEAL_TYPE_BUY ? "BUY" : "SELL"),
         " | Deal:#", dealTicket,
         " | DealPrice:", DoubleToString(dealPrice, _Digits),
         " | NextTriggerPrice:",
         DoubleToString(dealType == DEAL_TYPE_BUY ? m_nextFloatAddBuyProfit : m_nextFloatAddSellProfit, _Digits));
  }

//+------------------------------------------------------------------+
//| 确保Range Mid Lab指标句柄可用                                     |
//+------------------------------------------------------------------+
bool CQuickTradePanel::EnsureRangeIndicatorHandles()
  {
   if(!InpEnableRangeMidAuto)
      return false;

   ENUM_TIMEFRAMES period = (ENUM_TIMEFRAMES)_Period;
   bool needReload = (m_rangeBandsHandle == INVALID_HANDLE ||
                      m_rangeAdxHandle == INVALID_HANDLE ||
                      m_rangeAtrHandle == INVALID_HANDLE ||
                      m_rangeLoadedSymbol != _Symbol ||
                      m_rangeLoadedPeriod != period);

   if(!needReload)
      return true;

   if(m_rangeBandsHandle != INVALID_HANDLE)
      IndicatorRelease(m_rangeBandsHandle);
   if(m_rangeAdxHandle != INVALID_HANDLE)
      IndicatorRelease(m_rangeAdxHandle);
   if(m_rangeAtrHandle != INVALID_HANDLE)
      IndicatorRelease(m_rangeAtrHandle);

   m_rangeBandsHandle = iBands(_Symbol, period, InpRangeBBPeriod, 0, InpRangeBBDeviation, PRICE_CLOSE);
   m_rangeAdxHandle = iADX(_Symbol, period, InpRangeAdxPeriod);
   m_rangeAtrHandle = iATR(_Symbol, period, InpRangeAtrPeriod);

   if(m_rangeBandsHandle == INVALID_HANDLE ||
      m_rangeAdxHandle == INVALID_HANDLE ||
      m_rangeAtrHandle == INVALID_HANDLE)
     {
      if(m_rangeBandsHandle != INVALID_HANDLE)
         IndicatorRelease(m_rangeBandsHandle);
      if(m_rangeAdxHandle != INVALID_HANDLE)
         IndicatorRelease(m_rangeAdxHandle);
      if(m_rangeAtrHandle != INVALID_HANDLE)
         IndicatorRelease(m_rangeAtrHandle);
      m_rangeBandsHandle = INVALID_HANDLE;
      m_rangeAdxHandle = INVALID_HANDLE;
      m_rangeAtrHandle = INVALID_HANDLE;
      return false;
     }

   m_rangeLoadedSymbol = _Symbol;
   m_rangeLoadedPeriod = period;
   return true;
  }

//+------------------------------------------------------------------+
//| 按会话计算VWAP                                                    |
//+------------------------------------------------------------------+
double CQuickTradePanel::ComputeSessionVWAP(const int shift, const int barsLimit)
  {
   datetime anchor = iTime(_Symbol, _Period, shift);
   if(anchor <= 0)
      return 0.0;

   MqlDateTime tm;
   TimeToStruct(anchor, tm);
   tm.hour = 0;
   tm.min = 0;
   tm.sec = 0;
   datetime dayStart = StructToTime(tm);

   double sumPV = 0.0;
   double sumV = 0.0;
   for(int i = shift; i < shift + barsLimit; i++)
     {
      datetime t = iTime(_Symbol, _Period, i);
      if(t <= 0 || t < dayStart)
         break;

      double high = iHigh(_Symbol, _Period, i);
      double low = iLow(_Symbol, _Period, i);
      double close = iClose(_Symbol, _Period, i);
      double volume = (double)iVolume(_Symbol, _Period, i);
      if(volume <= 0.0)
         volume = 1.0;

      double typical = (high + low + close) / 3.0;
      sumPV += typical * volume;
      sumV += volume;
     }

   if(sumV <= 0.0)
      return iClose(_Symbol, _Period, shift);
   return sumPV / sumV;
  }

//+------------------------------------------------------------------+
//| 读取组合中线与摆动状态                                            |
//+------------------------------------------------------------------+
bool CQuickTradePanel::GetRangeMidMetrics(double &donHigh,
      double &donLow,
      double &bbMid,
      double &bbMidPast,
      double &adx,
      double &atr,
      double &vwapNow,
      double &vwapPast,
      double &mid,
      double &midPast,
      double &band,
      bool &isRanging)
  {
   if(!EnsureRangeIndicatorHandles())
      return false;

   int donPeriod = MathMax(20, InpRangeDonchianPeriod);
   int slopeLookback = MathMax(1, InpRangeSlopeLookback);
   int barsLimit = MathMax(300, donPeriod * 4);

   double bbNowBuf[1], bbPastBuf[1], adxBuf[1], atrBuf[1];
   if(CopyBuffer(m_rangeBandsHandle, 0, 1, 1, bbNowBuf) != 1)
      return false;
   if(CopyBuffer(m_rangeBandsHandle, 0, 1 + slopeLookback, 1, bbPastBuf) != 1)
      return false;
   if(CopyBuffer(m_rangeAdxHandle, 0, 1, 1, adxBuf) != 1)
      return false;
   if(CopyBuffer(m_rangeAtrHandle, 0, 1, 1, atrBuf) != 1)
      return false;

   int highShift = iHighest(_Symbol, _Period, MODE_HIGH, donPeriod, 1);
   int lowShift = iLowest(_Symbol, _Period, MODE_LOW, donPeriod, 1);
   int highShiftPast = iHighest(_Symbol, _Period, MODE_HIGH, donPeriod, 1 + slopeLookback);
   int lowShiftPast = iLowest(_Symbol, _Period, MODE_LOW, donPeriod, 1 + slopeLookback);
   if(highShift < 0 || lowShift < 0 || highShiftPast < 0 || lowShiftPast < 0)
      return false;

   donHigh = iHigh(_Symbol, _Period, highShift);
   donLow = iLow(_Symbol, _Period, lowShift);
   double donHighPast = iHigh(_Symbol, _Period, highShiftPast);
   double donLowPast = iLow(_Symbol, _Period, lowShiftPast);
   bbMid = bbNowBuf[0];
   bbMidPast = bbPastBuf[0];
   adx = adxBuf[0];
   atr = atrBuf[0];
   if(atr <= 0.0)
      return false;

   vwapNow = ComputeSessionVWAP(1, barsLimit);
   vwapPast = ComputeSessionVWAP(1 + slopeLookback, barsLimit);

   double vwapWeight = MathMax(0.0, MathMin(0.8, InpRangeVwapWeight));
   double coreWeight = (1.0 - vwapWeight) * 0.5;
   double donMid = (donHigh + donLow) * 0.5;
   double donMidPast = (donHighPast + donLowPast) * 0.5;
   mid = coreWeight * donMid + coreWeight * bbMid + vwapWeight * vwapNow;
   midPast = coreWeight * donMidPast + coreWeight * bbMidPast + vwapWeight * vwapPast;

   double donRange = MathMax(0.0, donHigh - donLow);
   double bandAtr = InpRangeBandAtrMult * atr;
   double bandDon = InpRangeBandDonchMult * donRange;
   band = MathMax(MathMax(_Point, bandAtr), bandDon);

   double slopeAbs = MathAbs(mid - midPast);
   isRanging = (adx <= InpRangeAdxMax && slopeAbs <= InpRangeSlopeAtrMult * atr);
   return true;
  }

//+------------------------------------------------------------------+
//| 统计当前受控持仓数量                                              |
//+------------------------------------------------------------------+
int CQuickTradePanel::CountManagedPositions(const ENUM_POSITION_TYPE posType)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      if(m_posInfo.PositionType() != posType)
         continue;
      count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Range Mid Lab 自动策略主逻辑                                     |
//+------------------------------------------------------------------+
void CQuickTradePanel::ProcessRangeMidAuto(const double bid,
      const double ask,
      const int buys,
      const int sells,
      const double buyMinOpen,
      const double buyMaxOpen,
      const double sellMinOpen,
      const double sellMaxOpen)
  {
   if(!InpEnableRangeMidAuto)
     {
      ClearRangeMidVisual();
      return;
     }

   double donHigh = 0.0, donLow = 0.0, bbMid = 0.0, bbMidPast = 0.0;
   double adx = 0.0, atr = 0.0, vwapNow = 0.0, vwapPast = 0.0;
   double mid = 0.0, midPast = 0.0, band = 0.0;
   bool isRanging = false;
   if(!GetRangeMidMetrics(donHigh, donLow, bbMid, bbMidPast, adx, atr, vwapNow, vwapPast,
                          mid, midPast, band, isRanging))
     {
      ClearRangeMidVisual();
      return;
     }

   datetime barTime = iTime(_Symbol, _Period, 0);
   if(barTime <= 0)
      return;

   double failUpper = donHigh + InpRangeFailAtrMult * atr;
   double failLower = donLow - InpRangeFailAtrMult * atr;
   double entryUpper = mid + band * InpRangeEntryBandMult;
   double entryLower = mid - band * InpRangeEntryBandMult;
   UpdateRangeMidVisual(mid, entryUpper, entryLower, failUpper, failLower, isRanging, adx, atr, band);
   double slopeAbs = MathAbs(mid - midPast);
   string stateText = (isRanging ?
                       "RANGING" :
                       StringFormat("BLOCKED | ADX=%.2f>%.2f or Slope=%.5f>%.5f",
                                    adx, InpRangeAdxMax, slopeAbs, InpRangeSlopeAtrMult * atr));
   if(InpRangeVerboseLog && stateText != m_lastRangeStateText)
     {
      m_lastRangeStateText = stateText;
      Print("[RangeMidLab] 状态切换 | ", stateText,
            " | Mid:", DoubleToString(mid, _Digits),
            " | Band:", DoubleToString(band, _Digits));
     }
   if(buys > 0 && bid <= failLower)
     {
      if(InpRangeVerboseLog)
         Print("[RangeMidLab] BUY失效退出 | Bid:", DoubleToString(bid, _Digits),
               " | FailLower:", DoubleToString(failLower, _Digits));
      AsyncCloseByType(POSITION_TYPE_BUY);
     }
   if(sells > 0 && ask >= failUpper)
     {
      if(InpRangeVerboseLog)
         Print("[RangeMidLab] SELL失效退出 | Ask:", DoubleToString(ask, _Digits),
               " | FailUpper:", DoubleToString(failUpper, _Digits));
      AsyncCloseByType(POSITION_TYPE_SELL);
     }

   if(!isRanging)
      return;

   if(InpRangeCloseAtMid)
     {
      if(buys > 0 && bid >= mid)
        {
         if(InpRangeVerboseLog)
            Print("[RangeMidLab] BUY触达中线退出 | Mid:", DoubleToString(mid, _Digits));
         AsyncCloseByType(POSITION_TYPE_BUY);
        }
      if(sells > 0 && ask <= mid)
        {
         if(InpRangeVerboseLog)
            Print("[RangeMidLab] SELL触达中线退出 | Mid:", DoubleToString(mid, _Digits));
         AsyncCloseByType(POSITION_TYPE_SELL);
        }
     }

   int maxSide = MathMax(1, InpRangeMaxSidePositions);
   int buyCount = CountManagedPositions(POSITION_TYPE_BUY);
   int sellCount = CountManagedPositions(POSITION_TYPE_SELL);

   bool allowBuy = (buyCount < maxSide) && (InpRangeAllowHedge || sellCount == 0);
   bool allowSell = (sellCount < maxSide) && (InpRangeAllowHedge || buyCount == 0);
   double gridStep = MathMax(_Point, InpRangeGridAtrMult * atr);

   if(allowBuy)
     {
      bool initialBuy = (buyCount <= 0);
      double triggerBuy = entryLower;
      if(!initialBuy && buyMinOpen > 0.0)
         triggerBuy = buyMinOpen - gridStep;
      if(ask <= triggerBuy && m_lastRangeBuyBar != barTime)
        {
         string comment = (initialBuy ? "RangeMid Buy" : "RangeMid Grid Buy");
         if(ExecuteMarketOrder(POSITION_TYPE_BUY, m_lots, comment, false))
           {
            m_lastRangeBuyBar = barTime;
            if(InpRangeVerboseLog)
               Print("[RangeMidLab] BUY触发 | Ask:", DoubleToString(ask, _Digits),
                     " | Trigger:", DoubleToString(triggerBuy, _Digits),
                     " | ADX:", DoubleToString(adx, 2));
           }
        }
     }

   if(allowSell)
     {
      bool initialSell = (sellCount <= 0);
      double triggerSell = entryUpper;
      if(!initialSell && sellMaxOpen > 0.0)
         triggerSell = sellMaxOpen + gridStep;
      if(bid >= triggerSell && m_lastRangeSellBar != barTime)
        {
         string comment = (initialSell ? "RangeMid Sell" : "RangeMid Grid Sell");
         if(ExecuteMarketOrder(POSITION_TYPE_SELL, m_lots, comment, false))
           {
            m_lastRangeSellBar = barTime;
            if(InpRangeVerboseLog)
               Print("[RangeMidLab] SELL触发 | Bid:", DoubleToString(bid, _Digits),
                     " | Trigger:", DoubleToString(triggerSell, _Digits),
                     " | ADX:", DoubleToString(adx, 2));
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| 确保箭头指标句柄可用                                              |
//+------------------------------------------------------------------+
bool CQuickTradePanel::EnsureArrowIndicatorHandle()
  {
   string indicatorName = InpArrowIndicatorName;
   StringTrimLeft(indicatorName);
   StringTrimRight(indicatorName);

   if(indicatorName == "")
     {
      if(m_arrowIndicatorHandle != INVALID_HANDLE)
        {
         IndicatorRelease(m_arrowIndicatorHandle);
         m_arrowIndicatorHandle = INVALID_HANDLE;
        }
      m_arrowIndicatorLoadedName = "";
      m_arrowIndicatorLoadedSymbol = "";
      m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
      return false;
     }

   ENUM_TIMEFRAMES currentPeriod = (ENUM_TIMEFRAMES)_Period;
   if(m_arrowIndicatorHandle != INVALID_HANDLE &&
      m_arrowIndicatorLoadedName == indicatorName &&
      m_arrowIndicatorLoadedSymbol == _Symbol &&
      m_arrowIndicatorLoadedPeriod == currentPeriod)
     {
      return true;
     }

   if(m_arrowIndicatorHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_arrowIndicatorHandle);
      m_arrowIndicatorHandle = INVALID_HANDLE;
     }

   ResetLastError();
   m_arrowIndicatorHandle = iCustom(_Symbol, currentPeriod, indicatorName);
   if(m_arrowIndicatorHandle == INVALID_HANDLE)
     {
      int err = GetLastError();
      Print("[Panel] 箭头指标 iCustom 句柄创建失败 | Name:", indicatorName,
            " | Error:", err);
      m_arrowIndicatorLoadedName = "";
      m_arrowIndicatorLoadedSymbol = "";
      m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
      return false;
     }

   m_arrowIndicatorLoadedName = indicatorName;
   m_arrowIndicatorLoadedSymbol = _Symbol;
   m_arrowIndicatorLoadedPeriod = currentPeriod;
   return true;
  }

//+------------------------------------------------------------------+
//| 通过 iCustom 读取最新箭头信号                                    |
//+------------------------------------------------------------------+
bool CQuickTradePanel::GetLatestArrowSignalFromICustom(ENUM_POSITION_TYPE &posType,
      string &signalKey,
      string &objectName,
      datetime &signalTime)
  {
   signalKey = "";
   objectName = "";
   signalTime = 0;
   m_lastArrowSignalDebug = "";

   string indicatorName = InpArrowIndicatorName;
   StringTrimLeft(indicatorName);
   StringTrimRight(indicatorName);
   if(indicatorName == "")
      return false;

   string lowerName = indicatorName;
   StringToLower(lowerName);
   if(StringFind(lowerName, "halftrend") < 0)
      return false;

   if(!EnsureArrowIndicatorHandle())
      return false;

   const int lookback = 200;
   datetime barTimes[];
   double highs[];
   double lows[];
   ArraySetAsSeries(barTimes, true);
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   int timeCopied = CopyTime(_Symbol, (ENUM_TIMEFRAMES)_Period, 1, lookback, barTimes);
   int highCopied = CopyHigh(_Symbol, (ENUM_TIMEFRAMES)_Period, 1, lookback, highs);
   int lowCopied = CopyLow(_Symbol, (ENUM_TIMEFRAMES)_Period, 1, lookback, lows);
   if(timeCopied <= 0 || highCopied <= 0 || lowCopied <= 0)
      return false;

   int buyBufferIndex = MathMax(0, InpArrowBuyBuffer);
   int sellBufferIndex = MathMax(0, InpArrowSellBuffer);

   double buyBuffer[];
   double sellBuffer[];
   ArraySetAsSeries(buyBuffer, true);
   ArraySetAsSeries(sellBuffer, true);

   int buyCopied = CopyBuffer(m_arrowIndicatorHandle, buyBufferIndex, 1, lookback, buyBuffer);
   int sellCopied = CopyBuffer(m_arrowIndicatorHandle, sellBufferIndex, 1, lookback, sellBuffer);
   if(buyCopied <= 0 && sellCopied <= 0)
      return false;

   datetime debugTimes[];
   double debugBuy[];
   double debugSell[];
   ArraySetAsSeries(debugTimes, true);
   ArraySetAsSeries(debugBuy, true);
   ArraySetAsSeries(debugSell, true);
   int debugTimeCopied = CopyTime(_Symbol, (ENUM_TIMEFRAMES)_Period, 0, 4, debugTimes);
   int debugBuyCopied = CopyBuffer(m_arrowIndicatorHandle, buyBufferIndex, 0, 4, debugBuy);
   int debugSellCopied = CopyBuffer(m_arrowIndicatorHandle, sellBufferIndex, 0, 4, debugSell);

   int latestShift = -1;
   ENUM_POSITION_TYPE latestSide = POSITION_TYPE_BUY;
   double latestPrice = 0.0;

   int maxCount = MathMin(timeCopied, MathMin(highCopied, lowCopied));
   string detectionSummary = "";
   int autoBuyBuffer = -1;
   int autoSellBuffer = -1;
   int autoBuyShift = INT_MAX;
   int autoSellShift = INT_MAX;
   double autoBuyPrice = 0.0;
   double autoSellPrice = 0.0;

   for(int buf = 0; buf <= 7; buf++)
     {
      double probe[];
      ArraySetAsSeries(probe, true);
      int probeCopied = CopyBuffer(m_arrowIndicatorHandle, buf, 1, lookback, probe);
      if(probeCopied <= 0)
         continue;

      int nonEmpty = 0;
      int belowBars = 0;
      int aboveBars = 0;
      int firstShift = -1;
      double firstPrice = 0.0;

      int probeCount = MathMin(maxCount, probeCopied);
      for(int i = 0; i < probeCount; i++)
        {
         double value = probe[i];
         if(value == EMPTY_VALUE || value == 0.0)
            continue;

         nonEmpty++;
         int shift = i + 1;
         if(firstShift < 0)
           {
            firstShift = shift;
            firstPrice = value;
           }

         double tol = MathMax(_Point * 10.0, 0.0);
         if(value < lows[i] - tol)
            belowBars++;
         else
            if(value > highs[i] + tol)
               aboveBars++;
        }

      if(nonEmpty <= 0)
         continue;

      double density = (double)nonEmpty / (double)probeCount;
      detectionSummary += " b" + IntegerToString(buf)
                          + "{n=" + IntegerToString(nonEmpty)
                          + ",d=" + DoubleToString(density, 2)
                          + ",dn=" + IntegerToString(belowBars)
                          + ",up=" + IntegerToString(aboveBars)
                          + ",s=" + IntegerToString(firstShift) + "}";

      bool sparseEnough = (density <= 0.20 || nonEmpty <= 6);
      if(!sparseEnough || firstShift < 0)
         continue;

      if(belowBars > 0 && aboveBars == 0 && firstShift < autoBuyShift)
        {
         autoBuyBuffer = buf;
         autoBuyShift = firstShift;
         autoBuyPrice = firstPrice;
        }

      if(aboveBars > 0 && belowBars == 0 && firstShift < autoSellShift)
        {
         autoSellBuffer = buf;
         autoSellShift = firstShift;
         autoSellPrice = firstPrice;
        }
     }

   bool usedAutoDetection = false;
   if(autoBuyBuffer >= 0 || autoSellBuffer >= 0)
     {
      usedAutoDetection = true;
      if(autoBuyBuffer >= 0 && (autoSellBuffer < 0 || autoBuyShift <= autoSellShift))
        {
         latestShift = autoBuyShift;
         latestSide = POSITION_TYPE_BUY;
         latestPrice = autoBuyPrice;
         signalTime = barTimes[autoBuyShift - 1];
         buyBufferIndex = autoBuyBuffer;
        }
      else
         if(autoSellBuffer >= 0)
           {
            latestShift = autoSellShift;
            latestSide = POSITION_TYPE_SELL;
            latestPrice = autoSellPrice;
            signalTime = barTimes[autoSellShift - 1];
            sellBufferIndex = autoSellBuffer;
           }
     }

   if(!usedAutoDetection)
     {
      int fallbackCount = MathMin(maxCount, MathMax(buyCopied, sellCopied));
      for(int i = 0; i < fallbackCount; i++)
        {
         bool hasBuy = (i < buyCopied && buyBuffer[i] != EMPTY_VALUE && buyBuffer[i] != 0.0);
         bool hasSell = (i < sellCopied && sellBuffer[i] != EMPTY_VALUE && sellBuffer[i] != 0.0);

         if(!hasBuy && !hasSell)
            continue;

         latestShift = i + 1;
         signalTime = barTimes[i];
         if(hasBuy && !hasSell)
           {
            latestSide = POSITION_TYPE_BUY;
            latestPrice = buyBuffer[i];
           }
         else
            if(hasSell && !hasBuy)
              {
               latestSide = POSITION_TYPE_SELL;
               latestPrice = sellBuffer[i];
              }
            else
              {
               latestSide = (sellBuffer[i] > buyBuffer[i] ? POSITION_TYPE_SELL : POSITION_TYPE_BUY);
               latestPrice = (latestSide == POSITION_TYPE_BUY ? buyBuffer[i] : sellBuffer[i]);
              }
         break;
        }
     }

   if(latestShift < 0 || signalTime <= 0)
      return false;

   posType = latestSide;
   int usedBufferIndex = (latestSide == POSITION_TYPE_BUY ? buyBufferIndex : sellBufferIndex);
   objectName = "iCustom:" + indicatorName + ":buf" + IntegerToString(usedBufferIndex);
   signalKey = objectName + "|" + IntegerToString((long)signalTime) + "|" +
               IntegerToString((int)posType) + "|" + DoubleToString(latestPrice, _Digits);

   string debugText = "Src=iCustom"
                      + " | BufB=" + IntegerToString(buyBufferIndex)
                      + " | BufS=" + IntegerToString(sellBufferIndex)
                      + " | Mode=" + (usedAutoDetection ? "auto-sparse" : "manual-fallback")
                      + " | PickShift=" + IntegerToString(latestShift)
                      + " | PickSide=" + (latestSide == POSITION_TYPE_BUY ? "BUY" : "SELL")
                      + " | Detect=" + detectionSummary;
   for(int k = 0; k < 4; k++)
     {
      string timeText = "--";
      if(k < debugTimeCopied && debugTimes[k] > 0)
         timeText = TimeToString(debugTimes[k], TIME_MINUTES);

      string buyText = "--";
      if(k < debugBuyCopied && debugBuy[k] != EMPTY_VALUE && debugBuy[k] != 0.0)
         buyText = DoubleToString(debugBuy[k], _Digits);

      string sellText = "--";
      if(k < debugSellCopied && debugSell[k] != EMPTY_VALUE && debugSell[k] != 0.0)
         sellText = DoubleToString(debugSell[k], _Digits);

      debugText += " | s" + IntegerToString(k)
                   + "@" + timeText
                   + " B=" + buyText
                   + " S=" + sellText;
     }
   debugText += " | Full=";
   for(int buf = 0; buf <= 7; buf++)
     {
      double probe[];
      ArraySetAsSeries(probe, true);
      int probeCopied = CopyBuffer(m_arrowIndicatorHandle, buf, 0, 4, probe);

      debugText += "b" + IntegerToString(buf) + "[";
      for(int shift = 0; shift < 4; shift++)
        {
         if(shift > 0)
            debugText += ",";

         string probeText = "--";
         if(shift < probeCopied && probe[shift] != EMPTY_VALUE && probe[shift] != 0.0)
            probeText = DoubleToString(probe[shift], _Digits);

         debugText += "s" + IntegerToString(shift) + "=" + probeText;
        }
      debugText += "]";
      if(buf < 7)
         debugText += ";";
     }
   m_lastArrowSignalDebug = debugText;
   return true;
  }

//+------------------------------------------------------------------+
//| 箭头型图表对象识别                                                |
//+------------------------------------------------------------------+
bool CQuickTradePanel::IsArrowSignalObjectType(const ENUM_OBJECT objectType)
  {
   switch(objectType)
     {
      case OBJ_ARROW:
      case OBJ_ARROW_UP:
      case OBJ_ARROW_DOWN:
      case OBJ_ARROW_BUY:
      case OBJ_ARROW_SELL:
      case OBJ_ARROW_THUMB_UP:
      case OBJ_ARROW_THUMB_DOWN:
      case OBJ_TEXT:
         return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| 获取当前图表上最新的箭头信号                                      |
//+------------------------------------------------------------------+
bool CQuickTradePanel::GetLatestArrowSignalFromObjects(ENUM_POSITION_TYPE &posType,
      string &signalKey,
      string &objectName,
      datetime &signalTime)
  {
   signalKey = "";
   objectName = "";
   signalTime = 0;
   m_lastArrowSignalDebug = "";

   string keyword = InpArrowIndicatorName;
   StringReplace(keyword, " ", "");
   if(keyword == "")
      return false;

   string keywordLower = keyword;
   StringToLower(keywordLower);

   int total = ObjectsTotal(m_chart_id, -1, -1);
   if(total <= 0)
      return false;

   ENUM_POSITION_TYPE latestSide = POSITION_TYPE_BUY;
   for(int i = 0; i < total; i++)
     {
      string name = ObjectName(m_chart_id, i, -1, -1);
      if(name == "")
         continue;

      string lowerName = name;
      StringToLower(lowerName);
      if(StringFind(lowerName, keywordLower) < 0)
         continue;

      ENUM_OBJECT objectType = (ENUM_OBJECT)ObjectGetInteger(m_chart_id, name, OBJPROP_TYPE);
      if(!IsArrowSignalObjectType(objectType))
         continue;

      color arrowColor = (color)ObjectGetInteger(m_chart_id, name, OBJPROP_COLOR);
      ENUM_POSITION_TYPE side = POSITION_TYPE_BUY;
      bool matched = false;
      if(arrowColor == InpArrowBuyColor)
        {
         side = POSITION_TYPE_BUY;
         matched = true;
        }
      else
         if(arrowColor == InpArrowSellColor)
           {
            side = POSITION_TYPE_SELL;
            matched = true;
           }
      if(!matched)
         continue;

      datetime arrowTime = (datetime)ObjectGetInteger(m_chart_id, name, OBJPROP_TIME, 0);
      if(arrowTime <= 0)
         continue;

      if(arrowTime > signalTime || (arrowTime == signalTime && name > objectName))
        {
         signalTime = arrowTime;
         objectName = name;
         latestSide = side;
        }
     }

   if(signalTime <= 0 || objectName == "")
      return false;

   posType = latestSide;
   signalKey = objectName + "|" + IntegerToString((long)signalTime) + "|" + IntegerToString((int)posType);
   m_lastArrowSignalDebug = "Src=objects | Name=" + objectName;
   return true;
  }

//+------------------------------------------------------------------+
//| 获取最新箭头信号：优先 iCustom，失败则回退对象识别                |
//+------------------------------------------------------------------+
bool CQuickTradePanel::GetLatestArrowSignal(ENUM_POSITION_TYPE &posType,
      string &signalKey,
      string &objectName,
      datetime &signalTime)
  {
   if(GetLatestArrowSignalFromICustom(posType, signalKey, objectName, signalTime))
      return true;

   return GetLatestArrowSignalFromObjects(posType, signalKey, objectName, signalTime);
  }

//+------------------------------------------------------------------+
//| 根据箭头指标最新信号自动开单                                      |
//+------------------------------------------------------------------+
void CQuickTradePanel::ProcessArrowSignalAutoTrading()
  {
   if(!InpEnableArrowSignalTrade)
     {
      if(m_arrowIndicatorHandle != INVALID_HANDLE)
        {
         IndicatorRelease(m_arrowIndicatorHandle);
         m_arrowIndicatorHandle = INVALID_HANDLE;
        }
      m_arrowIndicatorLoadedName = "";
      m_arrowIndicatorLoadedSymbol = "";
      m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
      m_arrowSignalPrimed = false;
      m_lastArrowSignalKey = "";
      m_lastArrowSignalDebug = "";
      return;
     }

   ENUM_POSITION_TYPE posType = POSITION_TYPE_BUY;
   string signalKey = "";
   string objectName = "";
   datetime signalTime = 0;
   if(!GetLatestArrowSignal(posType, signalKey, objectName, signalTime))
      return;

   if(!m_arrowSignalPrimed)
   {
      m_arrowSignalPrimed = true;
      m_lastArrowSignalKey = signalKey;

      m_lots = NormLots(StringToDouble(m_edtLots.Text()));
      UpdateLotsDisplay();

      bool sentOnLoad = false;
      bool hasExistingExposure = false;
      for(int i = PositionsTotal() - 1; i >= 0 && !hasExistingExposure; i--)
      {
         if(!m_posInfo.SelectByIndex(i))
            continue;
         if(m_posInfo.Symbol() != _Symbol)
            continue;
         hasExistingExposure = true;
      }

      for(int i = OrdersTotal() - 1; i >= 0 && !hasExistingExposure; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(ticket == 0)
            continue;

         string sym = OrderGetString(ORDER_SYMBOL);
         if(sym != _Symbol)
            continue;

         ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(orderType != ORDER_TYPE_BUY_LIMIT &&
            orderType != ORDER_TYPE_SELL_LIMIT &&
            orderType != ORDER_TYPE_BUY_STOP &&
            orderType != ORDER_TYPE_SELL_STOP &&
            orderType != ORDER_TYPE_BUY_STOP_LIMIT &&
            orderType != ORDER_TYPE_SELL_STOP_LIMIT)
            continue;

         hasExistingExposure = true;
      }

      if(InpArrowTradeOnLatestSignalAtLoad && m_asyncPending <= 0 && !hasExistingExposure)
      {
         string loadComment = (posType == POSITION_TYPE_BUY ? "QTP Arrow Buy" : "QTP Arrow Sell");
         sentOnLoad = ExecuteMarketOrder(posType, m_lots, loadComment, false);
         if(sentOnLoad)
         {
            Print("[Panel] 历史最新箭头信号已执行 | Side:",
                  (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                  " | Object:", objectName,
                  " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
                  " | Lots:", DoubleToString(m_lots, 2),
                  " | Debug:", m_lastArrowSignalDebug);
           }
        }

      Print("[Panel] 箭头指标自动开单已就绪 | 最新信号对象:", objectName,
            " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
            " | LoadTrade:", (InpArrowTradeOnLatestSignalAtLoad ? (sentOnLoad ? "ON-SENT" : (hasExistingExposure ? "ON-BLOCKED-BY-EXPOSURE" : "ON-SKIP")) : "OFF"),
            " | Debug:", m_lastArrowSignalDebug);
      return;
   }

   if(signalKey == m_lastArrowSignalKey)
      return;

   if(m_asyncPending > 0)
      return;

   m_lastArrowSignalKey = signalKey;
   m_lots = NormLots(StringToDouble(m_edtLots.Text()));
   UpdateLotsDisplay();

   string comment = (posType == POSITION_TYPE_BUY ? "QTP Arrow Buy" : "QTP Arrow Sell");
   bool sent = ExecuteMarketOrder(posType, m_lots, comment, false);
   if(sent)
     {
      Print("[Panel] 箭头指标自动开单触发 | Side:",
            (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " | Object:", objectName,
            " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
            " | Lots:", DoubleToString(m_lots, 2),
            " | Debug:", m_lastArrowSignalDebug);
     }
  }

//+------------------------------------------------------------------+
//| 价格比较，避免浮点误差导致误判                                    |
//+------------------------------------------------------------------+
bool CQuickTradePanel::SamePrice(const double a, const double b)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      point = _Point;
   return (MathAbs(a - b) <= point * 0.5);
  }

//+------------------------------------------------------------------+
//| 检测图表手动拖动后的TP/SL变化，并回填到面板输入框                  |
//+------------------------------------------------------------------+
void CQuickTradePanel::SyncDraggedTpSlToPanel()
  {
   ulong nowTick = GetTickCount();
   bool ignoreExternal = (nowTick < m_ignoreExternalTpSlUntil);

   ulong currentPosTickets[];
   double currentPosSl[];
   double currentPosTp[];
   ArrayResize(currentPosTickets, 0);
   ArrayResize(currentPosSl, 0);
   ArrayResize(currentPosTp, 0);

   ulong currentOrdTickets[];
   double currentOrdSl[];
   double currentOrdTp[];
   ArrayResize(currentOrdTickets, 0);
   ArrayResize(currentOrdSl, 0);
   ArrayResize(currentOrdTp, 0);

   double changedSl = 0.0;
   double changedTp = 0.0;
   ulong  changedTicket = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;

      int idx = ArraySize(currentPosTickets);
      ArrayResize(currentPosTickets, idx + 1);
      ArrayResize(currentPosSl, idx + 1);
      ArrayResize(currentPosTp, idx + 1);

      ulong ticket = m_posInfo.Ticket();
      double sl = m_posInfo.StopLoss();
      double tp = m_posInfo.TakeProfit();

      currentPosTickets[idx] = ticket;
      currentPosSl[idx] = sl;
      currentPosTp[idx] = tp;

      if(ignoreExternal)
         continue;

      int trackedIdx = FindTrackedPositionIndex(ticket);
      if(trackedIdx < 0)
         continue;

      if(!SamePrice(sl, m_trackedPosSl[trackedIdx]) ||
         !SamePrice(tp, m_trackedPosTp[trackedIdx]))
        {
         changedSl = sl;
         changedTp = tp;
         changedTicket = ticket;
         break;
        }
     }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;

      string sym = OrderGetString(ORDER_SYMBOL);
      long   mag = OrderGetInteger(ORDER_MAGIC);
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);

      if(InpCurrentOnly && sym != _Symbol)
         continue;
      if(InpMagicNumber > 0 && mag != InpMagicNumber)
         continue;

      if(orderType != ORDER_TYPE_BUY_LIMIT  &&
         orderType != ORDER_TYPE_SELL_LIMIT &&
         orderType != ORDER_TYPE_BUY_STOP   &&
         orderType != ORDER_TYPE_SELL_STOP  &&
         orderType != ORDER_TYPE_BUY_STOP_LIMIT &&
         orderType != ORDER_TYPE_SELL_STOP_LIMIT)
         continue;

      int idx = ArraySize(currentOrdTickets);
      ArrayResize(currentOrdTickets, idx + 1);
      ArrayResize(currentOrdSl, idx + 1);
      ArrayResize(currentOrdTp, idx + 1);

      double sl = OrderGetDouble(ORDER_SL);
      double tp = OrderGetDouble(ORDER_TP);

      currentOrdTickets[idx] = ticket;
      currentOrdSl[idx] = sl;
      currentOrdTp[idx] = tp;

      if(ignoreExternal || changedTicket != 0)
         continue;

      int trackedIdx = FindTrackedOrderIndex(ticket);
      if(trackedIdx < 0)
         continue;

      if(!SamePrice(sl, m_trackedOrdSl[trackedIdx]) ||
         !SamePrice(tp, m_trackedOrdTp[trackedIdx]))
        {
         changedSl = sl;
         changedTp = tp;
         changedTicket = ticket;
         break;
        }
     }

   ArrayResize(m_trackedPosTickets, ArraySize(currentPosTickets));
   ArrayResize(m_trackedPosSl, ArraySize(currentPosSl));
   ArrayResize(m_trackedPosTp, ArraySize(currentPosTp));
   ArrayCopy(m_trackedPosTickets, currentPosTickets);
   ArrayCopy(m_trackedPosSl, currentPosSl);
   ArrayCopy(m_trackedPosTp, currentPosTp);

   ArrayResize(m_trackedOrdTickets, ArraySize(currentOrdTickets));
   ArrayResize(m_trackedOrdSl, ArraySize(currentOrdSl));
   ArrayResize(m_trackedOrdTp, ArraySize(currentOrdTp));
   ArrayCopy(m_trackedOrdTickets, currentOrdTickets);
   ArrayCopy(m_trackedOrdSl, currentOrdSl);
   ArrayCopy(m_trackedOrdTp, currentOrdTp);

   if(changedTicket == 0)
      return;

   string tpText = (changedTp > 0.0 ? DoubleToString(changedTp, _Digits) : "0");
   string slText = (changedSl > 0.0 ? DoubleToString(changedSl, _Digits) : "0");

   m_edtTpPct.Text(tpText);
   m_edtSlPct.Text(slText);

   m_forceTpSlApply = false;
   m_lastTpText = tpText;
   m_lastSlText = slText;
   m_lastAppliedTp = changedTp;
   m_lastAppliedSl = changedSl;
   m_lastTpSlEditTick = nowTick;

   Print("[Panel] 检测到手动拖动TP/SL，已回填输入框并立即同步 | Ticket:",
         changedTicket, " | TP:", tpText, " | SL:", slText);

   ApplyTpSlToAll();
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::CreateChartLabels()
  {
   long chartId = m_chart_id;
   CreateTopBackground();
   CreateTopInfoLabels();
   UpdateTopPanelLayout();

//--- bar countdown attached to current candle
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)ChartPeriod(chartId);
   if(tf <= PERIOD_CURRENT)
      tf = _Period;
   datetime curBarTime = iTime(_Symbol, tf, 0);
   double curHigh = iHigh(_Symbol, tf, 0);
   double curLow  = iLow(_Symbol, tf, 0);
   double range   = MathMax(curHigh - curLow, 0.0);
   double priceY  = curHigh + MathMax(range * 0.25, 120 * _Point);
   ObjectCreate(chartId, LBL_BAR_TIMER, OBJ_TEXT, 0, curBarTime, priceY);
   ObjectSetString(chartId,  LBL_BAR_TIMER, OBJPROP_TEXT, "T--:--:--");
   ObjectSetString(chartId,  LBL_BAR_TIMER, OBJPROP_FONT, "Microsoft YaHei");
   ObjectSetInteger(chartId, LBL_BAR_TIMER, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(chartId, LBL_BAR_TIMER, OBJPROP_COLOR, clrDeepSkyBlue);
   ObjectSetInteger(chartId, LBL_BAR_TIMER, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   ObjectSetInteger(chartId, LBL_BAR_TIMER, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, LBL_BAR_TIMER, OBJPROP_HIDDEN, true);

   UpdateCandleRangeLabels();
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::CreateTopBackground()
  {
   long chartId = m_chart_id;
   int chartW = (int)ChartGetInteger(chartId, CHART_WIDTH_IN_PIXELS);
   int panelWidth = MathMax(TOP_PANEL_MIN_WIDTH, m_topPanelLastWidth);
   int panelLeft = (chartW - panelWidth) / 2;
   if(panelLeft < 8)
      panelLeft = 8;

   if(ObjectFind(chartId, LBL_TOP_BG) < 0)
      ObjectCreate(chartId, LBL_TOP_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_XDISTANCE, panelLeft);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_YDISTANCE, TOP_PANEL_Y);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_YSIZE, TOP_PANEL_EXPANDED_H);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_BORDER_COLOR, clrDimGray);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_BACK, false);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::CreateTopInfoLabels()
  {
   long chartId = m_chart_id;
   int  chartW  = (int)ChartGetInteger(chartId, CHART_WIDTH_IN_PIXELS);
   int  panelWidth = MathMax(TOP_PANEL_MIN_WIDTH, m_topPanelLastWidth);
   int  panelLeft = (chartW - panelWidth) / 2;
   if(panelLeft < 8)
      panelLeft = 8;
   int  dataLeftX = panelLeft + TOP_PANEL_TEXT_PAD;
   int  labelCenterX = panelLeft + panelWidth / 2;

   if(ObjectFind(chartId, LBL_TOP_POS) < 0)
      ObjectCreate(chartId, LBL_TOP_POS, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_XDISTANCE, dataLeftX);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_YDISTANCE, TOP_Y_START);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(chartId,  LBL_TOP_POS, OBJPROP_FONT, TOP_DATA_FONT);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_FONTSIZE, TOP_FONT_POS);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_COLOR, clrAliceBlue);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_HIDDEN, true);
   ObjectSetString(chartId,  LBL_TOP_POS, OBJPROP_TEXT, "POS  L 0 (0.00L)    S 0 (0.00L)");

   if(ObjectFind(chartId, LBL_TOP_AVG) < 0)
      ObjectCreate(chartId, LBL_TOP_AVG, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_XDISTANCE, dataLeftX);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_YDISTANCE, TOP_Y_START + TOP_FONT_POS + TOP_ROW_GAP);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(chartId,  LBL_TOP_AVG, OBJPROP_FONT, TOP_DATA_FONT);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_FONTSIZE, TOP_FONT_AVG);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_HIDDEN, true);
   ObjectSetString(chartId,  LBL_TOP_AVG, OBJPROP_TEXT, "AVG  L --          S --");

   if(ObjectFind(chartId, LBL_TOP_LIQ) < 0)
      ObjectCreate(chartId, LBL_TOP_LIQ, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_XDISTANCE, dataLeftX);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_YDISTANCE, TOP_Y_START + TOP_FONT_POS + TOP_ROW_GAP + TOP_FONT_AVG + TOP_ROW_GAP);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(chartId,  LBL_TOP_LIQ, OBJPROP_FONT, TOP_DATA_FONT);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_FONTSIZE, TOP_FONT_LIQ);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_HIDDEN, true);
   ObjectSetString(chartId,  LBL_TOP_LIQ, OBJPROP_TEXT, "LIQ  L --          S --");

   if(ObjectFind(chartId, LBL_TOP_PNL) < 0)
      ObjectCreate(chartId, LBL_TOP_PNL, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_XDISTANCE, dataLeftX);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_YDISTANCE, TOP_Y_START + TOP_FONT_POS + TOP_ROW_GAP + TOP_FONT_AVG + TOP_ROW_GAP + TOP_FONT_LIQ + TOP_ROW_GAP);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(chartId,  LBL_TOP_PNL, OBJPROP_FONT, TOP_DATA_FONT);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_FONTSIZE, TOP_FONT_PNL);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_COLOR, clrGainsboro);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_HIDDEN, true);
   ObjectSetString(chartId,  LBL_TOP_PNL, OBJPROP_TEXT, "UPL  L +0.00       S +0.00");

   if(ObjectFind(chartId, LBL_TOP_TOTAL) < 0)
      ObjectCreate(chartId, LBL_TOP_TOTAL, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_XDISTANCE, labelCenterX);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_YDISTANCE, TOP_Y_START + TOP_FONT_POS + TOP_ROW_GAP + TOP_FONT_AVG + TOP_ROW_GAP + TOP_FONT_LIQ + TOP_ROW_GAP + TOP_FONT_PNL + TOP_ROW_GAP);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_ANCHOR, ANCHOR_UPPER);
   ObjectSetString(chartId,  LBL_TOP_TOTAL, OBJPROP_FONT, TOP_FONT_NAME);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_FONTSIZE, TOP_FONT_TOTAL);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_COLOR, clrGray);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_HIDDEN, true);
   ObjectSetString(chartId,  LBL_TOP_TOTAL, OBJPROP_TEXT, "NET UPL 0.00");
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::DeleteTopInfoLabels()
  {
   ObjectDelete(m_chart_id, LBL_TOP_POS);
   ObjectDelete(m_chart_id, LBL_TOP_AVG);
   ObjectDelete(m_chart_id, LBL_TOP_LIQ);
   ObjectDelete(m_chart_id, LBL_TOP_PNL);
   ObjectDelete(m_chart_id, LBL_TOP_TOTAL);
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateRangeStatsToggleButton()
  {
   if(!m_btnToggleRangeStats.IsVisible())
      return;

   if(m_showCandleRangeStats)
     {
      m_btnToggleRangeStats.Text("波幅统计: 开");
      m_btnToggleRangeStats.ColorBackground(C'0,100,60');
      m_btnToggleRangeStats.Color(clrLime);
     }
   else
     {
      m_btnToggleRangeStats.Text("波幅统计: 关");
      m_btnToggleRangeStats.ColorBackground(C'50,50,50');
      m_btnToggleRangeStats.Color(clrGray);
     }
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateAddOnBreakevenToggleButton()
  {
   if(!m_btnToggleAddOnBreakeven.IsVisible())
      return;

   if(m_autoAddOnBreakeven)
     {
      m_btnToggleAddOnBreakeven.Text("保本:开");
      m_btnToggleAddOnBreakeven.ColorBackground(C'0,100,60');
      m_btnToggleAddOnBreakeven.Color(clrLime);
     }
   else
     {
      m_btnToggleAddOnBreakeven.Text("保本:关");
      m_btnToggleAddOnBreakeven.ColorBackground(C'50,50,50');
      m_btnToggleAddOnBreakeven.Color(clrGray);
     }
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateFloatAddToggleButton()
  {
   if(!m_btnToggleFloatAdd.IsVisible())
      return;

   if(m_autoFloatProfitAdd)
     {
      m_btnToggleFloatAdd.Text("加仓:开");
      m_btnToggleFloatAdd.ColorBackground(C'0,100,60');
      m_btnToggleFloatAdd.Color(clrLime);
     }
   else
     {
      m_btnToggleFloatAdd.Text("加仓:关");
      m_btnToggleFloatAdd.ColorBackground(C'50,50,50');
      m_btnToggleFloatAdd.Color(clrGray);
     }
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateFloatAddConfigLabel()
  {
   if(!m_lblFloatAddCfg.IsVisible())
      return;

   string text = StringFormat("每间距 %.2f 价格  +%.2f 手",
                              MathMax(0.01, InpFloatProfitStepMoney),
                              NormLots(InpFloatProfitAddLots));
   if(m_autoFloatProfitAdd)
      text += StringFormat("  |  BUY@%s  SELL@%s",
                           (m_nextFloatAddBuyProfit > 0.0 ? DoubleToString(m_nextFloatAddBuyProfit, _Digits) : "--"),
                           (m_nextFloatAddSellProfit > 0.0 ? DoubleToString(m_nextFloatAddSellProfit, _Digits) : "--"));

   m_lblFloatAddCfg.Text(text);
   m_lblFloatAddCfg.Color(m_autoFloatProfitAdd ? clrAliceBlue : clrSilver);
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
double CQuickTradePanel::StopoutEquityThreshold()
  {
   double stopoutValue = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
   if(stopoutValue <= 0.0)
      return 0.0;

   long stopoutMode = AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
   if(stopoutMode == ACCOUNT_STOPOUT_MODE_PERCENT)
     {
      double margin = AccountInfoDouble(ACCOUNT_MARGIN);
      if(margin <= 0.0)
         return 0.0;
      return margin * stopoutValue / 100.0;
     }

   return stopoutValue;
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
string CQuickTradePanel::PadRight(const string text, const int width)
  {
   string result = text;
   int len = StringLen(result);
   while(len < width)
     {
      result += " ";
      len++;
     }
   return result;
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
bool CQuickTradePanel::EstimateLiquidationPrice(const ENUM_POSITION_TYPE posType,
      const double totalLots,
      const double currentPrice,
      double &liqPrice)
  {
   liqPrice = 0.0;
   if(totalLots <= 0.0 || currentPrice <= 0.0)
      return false;

   double thresholdEquity = StopoutEquityThreshold();
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(thresholdEquity <= 0.0 || currentEquity <= 0.0)
      return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0)
      point = _Point;
   if(point <= 0.0)
      return false;

   double adverseProfit = 0.0;
   bool calcOk = false;
   if(posType == POSITION_TYPE_BUY)
      calcOk = OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, totalLots, currentPrice, currentPrice - point, adverseProfit);
   else
      calcOk = OrderCalcProfit(ORDER_TYPE_SELL, _Symbol, totalLots, currentPrice, currentPrice + point, adverseProfit);

   if(!calcOk)
      return false;

   double lossPerPoint = MathAbs(adverseProfit);
   if(lossPerPoint <= 0.0)
      return false;

   double equityBuffer = currentEquity - thresholdEquity;
   if(equityBuffer <= 0.0)
     {
      liqPrice = currentPrice;
      return true;
     }

   double adversePoints = equityBuffer / lossPerPoint;
   if(posType == POSITION_TYPE_BUY)
      liqPrice = currentPrice - adversePoints * point;
   else
      liqPrice = currentPrice + adversePoints * point;

   liqPrice = NormalizeDouble(liqPrice, _Digits);
   return (liqPrice > 0.0);
  }

//+------------------------------------------------------------------+
//| 更新Range Mid可视化                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateRangeMidVisual(const double mid,
      const double entryUpper,
      const double entryLower,
      const double failUpper,
      const double failLower,
      const bool isRanging,
      const double adx,
      const double atr,
      const double band)
  {
   long chartId = m_chart_id;

   if(ObjectFind(chartId, OBJ_RANGE_MID_LINE) < 0)
      ObjectCreate(chartId, OBJ_RANGE_MID_LINE, OBJ_HLINE, 0, 0, mid);
   ObjectSetDouble(chartId, OBJ_RANGE_MID_LINE, OBJPROP_PRICE, mid);
   ObjectSetInteger(chartId, OBJ_RANGE_MID_LINE, OBJPROP_COLOR, clrDeepSkyBlue);
   ObjectSetInteger(chartId, OBJ_RANGE_MID_LINE, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(chartId, OBJ_RANGE_MID_LINE, OBJPROP_WIDTH, 2);
   ObjectSetInteger(chartId, OBJ_RANGE_MID_LINE, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, OBJ_RANGE_MID_LINE, OBJPROP_HIDDEN, true);

   if(ObjectFind(chartId, OBJ_RANGE_UP_LINE) < 0)
      ObjectCreate(chartId, OBJ_RANGE_UP_LINE, OBJ_HLINE, 0, 0, entryUpper);
   ObjectSetDouble(chartId, OBJ_RANGE_UP_LINE, OBJPROP_PRICE, entryUpper);
   ObjectSetInteger(chartId, OBJ_RANGE_UP_LINE, OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(chartId, OBJ_RANGE_UP_LINE, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(chartId, OBJ_RANGE_UP_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(chartId, OBJ_RANGE_UP_LINE, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, OBJ_RANGE_UP_LINE, OBJPROP_HIDDEN, true);

   if(ObjectFind(chartId, OBJ_RANGE_DN_LINE) < 0)
      ObjectCreate(chartId, OBJ_RANGE_DN_LINE, OBJ_HLINE, 0, 0, entryLower);
   ObjectSetDouble(chartId, OBJ_RANGE_DN_LINE, OBJPROP_PRICE, entryLower);
   ObjectSetInteger(chartId, OBJ_RANGE_DN_LINE, OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(chartId, OBJ_RANGE_DN_LINE, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(chartId, OBJ_RANGE_DN_LINE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(chartId, OBJ_RANGE_DN_LINE, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, OBJ_RANGE_DN_LINE, OBJPROP_HIDDEN, true);

   if(ObjectFind(chartId, OBJ_RANGE_FAIL_UP) < 0)
      ObjectCreate(chartId, OBJ_RANGE_FAIL_UP, OBJ_HLINE, 0, 0, failUpper);
   ObjectSetDouble(chartId, OBJ_RANGE_FAIL_UP, OBJPROP_PRICE, failUpper);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_UP, OBJPROP_COLOR, clrTomato);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_UP, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_UP, OBJPROP_WIDTH, 1);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_UP, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_UP, OBJPROP_HIDDEN, true);

   if(ObjectFind(chartId, OBJ_RANGE_FAIL_DN) < 0)
      ObjectCreate(chartId, OBJ_RANGE_FAIL_DN, OBJ_HLINE, 0, 0, failLower);
   ObjectSetDouble(chartId, OBJ_RANGE_FAIL_DN, OBJPROP_PRICE, failLower);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_DN, OBJPROP_COLOR, clrTomato);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_DN, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_DN, OBJPROP_WIDTH, 1);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_DN, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, OBJ_RANGE_FAIL_DN, OBJPROP_HIDDEN, true);

   UpdateRangeLineTag(OBJ_RANGE_MID_TAG, "中线", clrDeepSkyBlue, mid, 230);
   UpdateRangeLineTag(OBJ_RANGE_UP_TAG, "入场上沿", clrOrange, entryUpper, 230);
   UpdateRangeLineTag(OBJ_RANGE_DN_TAG, "入场下沿", clrOrange, entryLower, 230);
   UpdateRangeLineTag(OBJ_RANGE_FAILUP_TAG, "失效上沿", clrTomato, failUpper, 230);
   UpdateRangeLineTag(OBJ_RANGE_FAILDN_TAG, "失效下沿", clrTomato, failLower, 230);

   if(ObjectFind(chartId, OBJ_RANGE_STATE) < 0)
      ObjectCreate(chartId, OBJ_RANGE_STATE, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, OBJ_RANGE_STATE, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, OBJ_RANGE_STATE, OBJPROP_XDISTANCE, 12);
   ObjectSetInteger(chartId, OBJ_RANGE_STATE, OBJPROP_YDISTANCE, TOP_PANEL_Y + TOP_PANEL_EXPANDED_H + 8);
   ObjectSetInteger(chartId, OBJ_RANGE_STATE, OBJPROP_FONTSIZE, 10);
   ObjectSetString(chartId, OBJ_RANGE_STATE, OBJPROP_FONT, TOP_FONT_NAME);
   ObjectSetInteger(chartId, OBJ_RANGE_STATE, OBJPROP_COLOR, (isRanging ? clrLime : clrOrangeRed));
   ObjectSetInteger(chartId, OBJ_RANGE_STATE, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, OBJ_RANGE_STATE, OBJPROP_HIDDEN, true);
   string statusText = StringFormat("RangeMid[%s] ADX=%.2f ATR=%.2f Band=%.2f Mid=%s",
                                    (isRanging ? "ON" : "OFF"),
                                    adx, atr, band, DoubleToString(mid, _Digits));
   ObjectSetString(chartId, OBJ_RANGE_STATE, OBJPROP_TEXT, statusText);
  }

//+------------------------------------------------------------------+
//| 更新Range Mid线条标签                                              |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateRangeLineTag(const string objName,
      const string title,
      const color clr,
      const double price,
      const int xOffset)
  {
   long chartId = m_chart_id;
   datetime t = iTime(_Symbol, (ENUM_TIMEFRAMES)ChartPeriod(chartId), 0);
   if(t <= 0)
      t = TimeCurrent();

   int x = 0, y = 0;
   if(!ChartTimePriceToXY(chartId, m_subwin, t, price, x, y))
      return;

   int chartW = (int)ChartGetInteger(chartId, CHART_WIDTH_IN_PIXELS);
   int chartH = (int)ChartGetInteger(chartId, CHART_HEIGHT_IN_PIXELS);
   int xDist = MathMax(8, chartW - xOffset);
   int yDist = MathMax(0, MathMin(chartH - 18, y - 8));

   if(ObjectFind(chartId, objName) < 0)
      ObjectCreate(chartId, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chartId, objName, OBJPROP_XDISTANCE, xDist);
   ObjectSetInteger(chartId, objName, OBJPROP_YDISTANCE, yDist);
   ObjectSetString(chartId, objName, OBJPROP_FONT, TOP_FONT_NAME);
   ObjectSetInteger(chartId, objName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(chartId, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(chartId, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chartId, objName, OBJPROP_HIDDEN, true);
   ObjectSetString(chartId, objName, OBJPROP_TEXT,
                   title + " " + DoubleToString(price, _Digits));
  }

//+------------------------------------------------------------------+
//| 清理Range Mid可视化                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::ClearRangeMidVisual()
  {
   ObjectDelete(m_chart_id, OBJ_RANGE_MID_LINE);
   ObjectDelete(m_chart_id, OBJ_RANGE_UP_LINE);
   ObjectDelete(m_chart_id, OBJ_RANGE_DN_LINE);
   ObjectDelete(m_chart_id, OBJ_RANGE_FAIL_UP);
   ObjectDelete(m_chart_id, OBJ_RANGE_FAIL_DN);
   ObjectDelete(m_chart_id, OBJ_RANGE_STATE);
   ObjectDelete(m_chart_id, OBJ_RANGE_MID_TAG);
   ObjectDelete(m_chart_id, OBJ_RANGE_UP_TAG);
   ObjectDelete(m_chart_id, OBJ_RANGE_DN_TAG);
   ObjectDelete(m_chart_id, OBJ_RANGE_FAILUP_TAG);
   ObjectDelete(m_chart_id, OBJ_RANGE_FAILDN_TAG);
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateLiquidationMarkers(const double buyLiqPrice, const double sellLiqPrice)
  {
   long chartId = m_chart_id;
   datetime anchorTime = iTime(_Symbol, (ENUM_TIMEFRAMES)ChartPeriod(chartId), 0);
   if(anchorTime <= 0)
      anchorTime = TimeCurrent();

   if(buyLiqPrice > 0.0)
     {
      if(ObjectFind(chartId, OBJ_BUY_LIQ_LINE) < 0)
         ObjectCreate(chartId, OBJ_BUY_LIQ_LINE, OBJ_HLINE, 0, 0, buyLiqPrice);
      ObjectSetDouble(chartId, OBJ_BUY_LIQ_LINE, OBJPROP_PRICE, buyLiqPrice);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_LINE, OBJPROP_COLOR, clrOrangeRed);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_LINE, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_LINE, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_LINE, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_LINE, OBJPROP_HIDDEN, true);

      if(ObjectFind(chartId, OBJ_BUY_LIQ_TAG) < 0)
         ObjectCreate(chartId, OBJ_BUY_LIQ_TAG, OBJ_ARROW_RIGHT_PRICE, 0, anchorTime, buyLiqPrice);
      else
         ObjectMove(chartId, OBJ_BUY_LIQ_TAG, 0, anchorTime, buyLiqPrice);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_TAG, OBJPROP_COLOR, clrOrangeRed);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_TAG, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_TAG, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, OBJ_BUY_LIQ_TAG, OBJPROP_HIDDEN, true);
     }
   else
     {
      ObjectDelete(chartId, OBJ_BUY_LIQ_LINE);
      ObjectDelete(chartId, OBJ_BUY_LIQ_TAG);
     }

   if(sellLiqPrice > 0.0)
     {
      if(ObjectFind(chartId, OBJ_SELL_LIQ_LINE) < 0)
         ObjectCreate(chartId, OBJ_SELL_LIQ_LINE, OBJ_HLINE, 0, 0, sellLiqPrice);
      ObjectSetDouble(chartId, OBJ_SELL_LIQ_LINE, OBJPROP_PRICE, sellLiqPrice);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_LINE, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_LINE, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_LINE, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_LINE, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_LINE, OBJPROP_HIDDEN, true);

      if(ObjectFind(chartId, OBJ_SELL_LIQ_TAG) < 0)
         ObjectCreate(chartId, OBJ_SELL_LIQ_TAG, OBJ_ARROW_RIGHT_PRICE, 0, anchorTime, sellLiqPrice);
      else
         ObjectMove(chartId, OBJ_SELL_LIQ_TAG, 0, anchorTime, sellLiqPrice);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_TAG, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_TAG, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_TAG, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(chartId, OBJ_SELL_LIQ_TAG, OBJPROP_HIDDEN, true);
     }
   else
     {
      ObjectDelete(chartId, OBJ_SELL_LIQ_LINE);
      ObjectDelete(chartId, OBJ_SELL_LIQ_TAG);
     }
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
int CQuickTradePanel::MeasureTextWidthPx(const string text, const string fontName, const int fontSize)
  {
   if(text == "")
      return 0;

   uint width = 0;
   uint height = 0;
   TextSetFont(fontName, fontSize, 0, 0);
   TextGetSize(text, width, height);
   return (int)width;
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateTopPanelLayout()
  {
   long chartId = m_chart_id;
   int chartW = (int)ChartGetInteger(chartId, CHART_WIDTH_IN_PIXELS);
   int panelWidth = m_topPanelLastWidth;

   int maxTextWidth = 0;
   if(ObjectFind(chartId, LBL_TOP_POS) >= 0)
     {
      int width = (int)ObjectGetInteger(chartId, LBL_TOP_POS, OBJPROP_XSIZE);
      if(width <= 0)
         width = MeasureTextWidthPx(ObjectGetString(chartId, LBL_TOP_POS, OBJPROP_TEXT), TOP_DATA_FONT, TOP_FONT_POS);
      maxTextWidth = MathMax(maxTextWidth, width);
     }
   if(ObjectFind(chartId, LBL_TOP_AVG) >= 0)
     {
      int width = (int)ObjectGetInteger(chartId, LBL_TOP_AVG, OBJPROP_XSIZE);
      if(width <= 0)
         width = MeasureTextWidthPx(ObjectGetString(chartId, LBL_TOP_AVG, OBJPROP_TEXT), TOP_DATA_FONT, TOP_FONT_AVG);
      maxTextWidth = MathMax(maxTextWidth, width);
     }
   if(ObjectFind(chartId, LBL_TOP_LIQ) >= 0)
     {
      int width = (int)ObjectGetInteger(chartId, LBL_TOP_LIQ, OBJPROP_XSIZE);
      if(width <= 0)
         width = MeasureTextWidthPx(ObjectGetString(chartId, LBL_TOP_LIQ, OBJPROP_TEXT), TOP_DATA_FONT, TOP_FONT_LIQ);
      maxTextWidth = MathMax(maxTextWidth, width);
     }
   if(ObjectFind(chartId, LBL_TOP_PNL) >= 0)
     {
      int width = (int)ObjectGetInteger(chartId, LBL_TOP_PNL, OBJPROP_XSIZE);
      if(width <= 0)
         width = MeasureTextWidthPx(ObjectGetString(chartId, LBL_TOP_PNL, OBJPROP_TEXT), TOP_DATA_FONT, TOP_FONT_PNL);
      maxTextWidth = MathMax(maxTextWidth, width);
     }
   if(ObjectFind(chartId, LBL_TOP_TOTAL) >= 0)
     {
      int width = (int)ObjectGetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_XSIZE);
      if(width <= 0)
         width = MeasureTextWidthPx(ObjectGetString(chartId, LBL_TOP_TOTAL, OBJPROP_TEXT), TOP_FONT_NAME, TOP_FONT_TOTAL);
      maxTextWidth = MathMax(maxTextWidth, width);
     }

   int maxAllowedWidth = chartW - 16;
   panelWidth = MathMax(TOP_PANEL_MIN_WIDTH, maxTextWidth + TOP_PANEL_TEXT_PAD * 2 + 28);
   if(maxAllowedWidth > 0 && panelWidth > maxAllowedWidth)
      panelWidth = maxAllowedWidth;
   m_topPanelLastWidth = panelWidth;

   int centerX = chartW / 2;
   int panelLeft = centerX - panelWidth / 2;
   if(panelLeft < 8)
      panelLeft = 8;

   int panelHeight = TOP_PANEL_EXPANDED_H;
   int labelCenterX = panelLeft + panelWidth / 2;
   int dataLeftX = panelLeft + TOP_PANEL_TEXT_PAD;
   if(ObjectFind(chartId, LBL_TOP_BG) >= 0)
     {
      ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_XDISTANCE, panelLeft);
      ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_YDISTANCE, TOP_PANEL_Y);
      ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_XSIZE, panelWidth);
      ObjectSetInteger(chartId, LBL_TOP_BG, OBJPROP_YSIZE, panelHeight);
     }

   if(ObjectFind(chartId, LBL_TOP_POS) >= 0)
      ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_XDISTANCE, dataLeftX);
   if(ObjectFind(chartId, LBL_TOP_AVG) >= 0)
      ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_XDISTANCE, dataLeftX);
   if(ObjectFind(chartId, LBL_TOP_LIQ) >= 0)
      ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_XDISTANCE, dataLeftX);
   if(ObjectFind(chartId, LBL_TOP_PNL) >= 0)
      ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_XDISTANCE, dataLeftX);
   if(ObjectFind(chartId, LBL_TOP_TOTAL) >= 0)
      ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_XDISTANCE, labelCenterX);
  }

//+------------------------------------------------------------------+
//|                                                |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateChartLabels(int buys, double buyLots, double buyPft,
      int sells, double sellLots, double sellPft,
      double buyAvgPrice, double sellAvgPrice,
      double buyLiqPrice, double sellLiqPrice)
  {
   long chartId = m_chart_id;
   UpdateLiquidationMarkers(buyLiqPrice, sellLiqPrice);

   if(ObjectFind(chartId, LBL_TOP_POS) < 0 ||
      ObjectFind(chartId, LBL_TOP_AVG) < 0 ||
      ObjectFind(chartId, LBL_TOP_LIQ) < 0 ||
      ObjectFind(chartId, LBL_TOP_PNL) < 0 ||
      ObjectFind(chartId, LBL_TOP_TOTAL) < 0)
     {
      CreateTopInfoLabels();
      UpdateTopPanelLayout();
     }

//--- 持仓
   string longPosText = StringFormat("%d (%.2fL)", buys, buyLots);
   string shortPosText = StringFormat("%d (%.2fL)", sells, sellLots);
   string posText = "POS  L " + PadRight(longPosText, TOP_DATA_COL_WIDTH) + " S " + PadRight(shortPosText, TOP_DATA_COL_WIDTH);
   ObjectSetString(chartId, LBL_TOP_POS, OBJPROP_TEXT, posText);
   ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_COLOR,
                    (buys + sells > 0) ? clrWhite : clrGray);

//--- 均价
   string buyAvgText = (buys > 0 && buyAvgPrice > 0.0 ? DoubleToString(buyAvgPrice, _Digits) : "--");
   string sellAvgText = (sells > 0 && sellAvgPrice > 0.0 ? DoubleToString(sellAvgPrice, _Digits) : "--");
   string avgText = "AVG  L " + PadRight(buyAvgText, TOP_DATA_COL_WIDTH) + " S " + PadRight(sellAvgText, TOP_DATA_COL_WIDTH);
   ObjectSetString(chartId, LBL_TOP_AVG, OBJPROP_TEXT, avgText);
   ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_COLOR,
                    (buys + sells > 0) ? clrRed : clrGray);

   string buyLiqText = (buyLiqPrice > 0.0 ? DoubleToString(buyLiqPrice, _Digits) : "--");
   string sellLiqText = (sellLiqPrice > 0.0 ? DoubleToString(sellLiqPrice, _Digits) : "--");
   string liqText = "LIQ  L " + PadRight(buyLiqText, TOP_DATA_COL_WIDTH) + " S " + PadRight(sellLiqText, TOP_DATA_COL_WIDTH);
   ObjectSetString(chartId, LBL_TOP_LIQ, OBJPROP_TEXT, liqText);
   ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_COLOR,
                    ((buyLiqPrice > 0.0) || (sellLiqPrice > 0.0)) ? clrOrange : clrGray);

//--- 多空浮盈
   string longUplText = StringFormat("%+.2f", buyPft);
   string shortUplText = StringFormat("%+.2f", sellPft);
   string pnlText = "UPL  L " + PadRight(longUplText, TOP_DATA_COL_WIDTH) + " S " + PadRight(shortUplText, TOP_DATA_COL_WIDTH);
   ObjectSetString(chartId, LBL_TOP_PNL, OBJPROP_TEXT, pnlText);

//--- color for buy/sell P/L row
   color pnlColor = clrSilver;
   if(buys + sells > 0)
     {
      if(buyPft + sellPft >= 0)
         pnlColor = clrLimeGreen;
      else
         pnlColor = clrCoral;
     }
   ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_COLOR, pnlColor);

//--- 总浮盈
   double totalPnl = buyPft + sellPft;
   string totalText = StringFormat("NET UPL %+.2f", totalPnl);
   ObjectSetString(chartId, LBL_TOP_TOTAL, OBJPROP_TEXT, totalText);

//--- total color: profit/loss/flat
   color totalColor = clrGray;
   if(buys + sells > 0)
     {
      if(totalPnl > 0)
         totalColor = clrLime;
      else
         if(totalPnl < 0)
            totalColor = clrRed;
         else
            totalColor = clrWhite;
     }
   ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_COLOR, totalColor);

   ChartRedraw(chartId);
   UpdateTopPanelLayout();

  }

//+------------------------------------------------------------------+
//| ?                                                  |
//+------------------------------------------------------------------+
void CQuickTradePanel::DestroyChartLabels()
  {
   ObjectDelete(m_chart_id, LBL_TOP_BG);
   DeleteTopInfoLabels();
   ObjectDelete(m_chart_id, LBL_BAR_TIMER);
   ObjectDelete(m_chart_id, OBJ_BUY_LIQ_LINE);
   ObjectDelete(m_chart_id, OBJ_SELL_LIQ_LINE);
   ObjectDelete(m_chart_id, OBJ_BUY_LIQ_TAG);
   ObjectDelete(m_chart_id, OBJ_SELL_LIQ_TAG);
   DeleteCandleRangeLabels();
   ClearRangeMidVisual();
  }

//+------------------------------------------------------------------+
//|                                                         |
//+------------------------------------------------------------------+
void CQuickTradePanel::ReleaseResources()
  {
   if(m_hasPrevDragTradeLevels)
      ChartSetInteger(m_chart_id, CHART_DRAG_TRADE_LEVELS, m_prevDragTradeLevels);

   if(m_arrowIndicatorHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_arrowIndicatorHandle);
      m_arrowIndicatorHandle = INVALID_HANDLE;
     }
   if(m_rangeBandsHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_rangeBandsHandle);
      m_rangeBandsHandle = INVALID_HANDLE;
     }
   if(m_rangeAdxHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_rangeAdxHandle);
      m_rangeAdxHandle = INVALID_HANDLE;
     }
   if(m_rangeAtrHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_rangeAtrHandle);
      m_rangeAtrHandle = INVALID_HANDLE;
     }
   m_arrowIndicatorLoadedName = "";
   m_arrowIndicatorLoadedSymbol = "";
   m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
   m_rangeLoadedSymbol = "";
   m_rangeLoadedPeriod = PERIOD_CURRENT;
  }

//+------------------------------------------------------------------+
//|                                                    |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnAsyncResult(const MqlTradeTransaction &trans,
                                     const MqlTradeRequest &request,
                                     const MqlTradeResult &result)
  {
   if(request.position > 0)
      RemovePendingCloseTicket(request.position);

   bool isFloatAddRequest = (StringFind(request.comment, "QTP FloatAdd ") == 0);
   ENUM_POSITION_TYPE floatAddSide = POSITION_TYPE_BUY;
   if(request.type == ORDER_TYPE_SELL)
      floatAddSide = POSITION_TYPE_SELL;

//---
   if(trans.type == TRADE_TRANSACTION_REQUEST)
     {
      if(m_asyncPending > 0)
         m_asyncPending--;

      if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
        {
         Print("[Panel] Async request success | ID:", result.request_id,
               " | Order:", result.order, " | Deal:", result.deal);
        }
      else
        {
         string desc = DescribeTradeRetcode(result.retcode);
         Print("[Panel] Async request failed | ID:", result.request_id,
               " | Code:", result.retcode, " | ", desc);

         if(isFloatAddRequest)
           {
            if(floatAddSide == POSITION_TYPE_BUY)
               m_pendingFloatAddBuy = false;
            else
               m_pendingFloatAddSell = false;
           }
        }
     }

//---
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      Print("[Panel] Deal: #", trans.deal,
            " | ", EnumToString(trans.deal_type),
            " | Vol:", trans.volume,
            " | Price:", trans.price,
            " | ", trans.symbol);
      FlagAutoBreakevenFromDeal(trans.deal, trans.symbol);
      HandleFloatProfitAddDeal(trans.deal, trans.symbol);
     }
  }

//+------------------------------------------------------------------+
//|                                                        |
//+------------------------------------------------------------------+
CQuickTradePanel g_panel;

//+------------------------------------------------------------------+
//| Expert initialization                                              |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!g_panel.CreatePanel(0, 0))
     {
      Print("Panel create failed");
      return INIT_FAILED;
     }

   g_panel.CreateChartLabels();
   g_panel.Run();
   g_panel.UpdateInfo();

//--- periodic refresh; UpdateInfo itself is throttled
   EventSetMillisecondTimer(500);

   Print("QuickTradePanel loaded | Symbol:", _Symbol,
         " | Async:ON | Magic filter:", InpMagicNumber);

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_panel.ReleaseResources();
   g_panel.DestroyChartLabels();
   g_panel.Destroy(reason);
   Comment("");
   Print("QuickTradePanel unloaded");
  }

//+------------------------------------------------------------------+
//| Timer -                                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
   g_panel.UpdateInfo();
  }

//+------------------------------------------------------------------+
//| Tick -                                         |
//+------------------------------------------------------------------+
void OnTick()
  {
   g_panel.UpdateInfo();
  }

//+------------------------------------------------------------------+
//|  - ?+                                |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
  {
//---
   g_panel.ChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_DRAG || id == CHARTEVENT_OBJECT_CHANGE)
      g_panel.SyncDraggedTpSlToPanel();

   if(id == CHARTEVENT_CHART_CHANGE)
     {
      g_panel.RefreshCandleRangeLabels();
      g_panel.UpdateInfo();
     }
  }

//+------------------------------------------------------------------+
//|                                                    |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   g_panel.OnAsyncResult(trans, request, result);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
