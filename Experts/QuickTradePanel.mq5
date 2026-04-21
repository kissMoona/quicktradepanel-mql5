//+------------------------------------------------------------------+
//|                                          QuickTradePanel.mq5     |
//|                        Copyright 2025, quicktradepanel-mql5      |
//|                 https://github.com/kissMoona/quicktradepanel-mql5 |
//+------------------------------------------------------------------+
#property copyright "Author: 猪猪大番薯"
#property link      "https://github.com/kissMoona/quicktradepanel-mql5"
#property version   "1.18"
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
#define PANEL_NAME       "QuickTradePanel"
#define PANEL_MAGIC_DEFAULT 9527001
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
#define TOP_PANEL_LEFT_PAD   10
#define TOP_PANEL_RIGHT_PAD  10
#define TOP_PANEL_MEASURE_FUDGE 0
#define TOP_PANEL_RIGHT_EXTRA 34
//+------------------------------------------------------------------+
//|                                                            |
//+------------------------------------------------------------------+
input group  "=== 面板设置 ==="
input double InpDefaultLots   = 0.01;   // 默认手数
input double InpLotsStep      = 0.01;   // 手数步长
input int    InpMagicNumber   = 9527001; // Magic过滤(0=全局控制)
input bool   InpCurrentOnly   = true;   // 仅统计当前品种
input int    InpSlippage      = 10;     // 最大滑点(点)
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

input group  "=== 箭头指标自动开单 ==="
input bool   InpEnableArrowSignalTrade = true;  // 启用箭头指标自动开单
input bool   InpArrowTradeOnLatestSignalAtLoad = true; // 加载后立即按当前最新信号开单
input string InpArrowIndicatorName     = "halftrend-1.02"; // 指标名称关键字(对象名包含即可)
input int    InpArrowBuyBuffer         = 5;     // iCustom买入信号缓冲区
input int    InpArrowSellBuffer        = 6;     // iCustom卖出信号缓冲区
input color  InpArrowBuyColor          = clrDodgerBlue; // 买入箭头颜色
input color  InpArrowSellColor         = clrRed;        // 卖出箭头颜色
input bool   InpEnableArrowConfirmFilter = true; // 启用多周期同向确认
input ENUM_TIMEFRAMES InpArrowConfirmPeriod = PERIOD_M1; // 确认周期

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
   CButton           m_btnToggleAddOnBreakeven;
   CButton           m_btnToggleFloatAdd;
   CLabel            m_lblFloatAddCfg;
   bool              m_closeReverse;       // ?
   bool              m_autoAddOnBreakeven;
   bool              m_pendingAutoBeBuy;
   bool              m_pendingAutoBeSell;
   bool              m_autoFloatProfitAdd;
   bool              m_pendingFloatAddBuy;
   bool              m_pendingFloatAddSell;
   double            m_nextFloatAddBuyProfit;
   double            m_nextFloatAddSellProfit;
   bool              m_arrowSignalPrimed;
   string            m_lastArrowSignalKey;
   string            m_lastArrowSignalDebug;
   bool              m_arrowPendingReentry;
   ENUM_POSITION_TYPE m_arrowPendingPosType;
   string            m_arrowPendingSignalKey;
   string            m_arrowPendingObjectName;
   datetime          m_arrowPendingSignalTime;
   string            m_arrowInflightSignalKey;
   int               m_arrowIndicatorHandle;
   string            m_arrowIndicatorLoadedName;
   string            m_arrowIndicatorLoadedSymbol;
   ENUM_TIMEFRAMES   m_arrowIndicatorLoadedPeriod;
   int               m_arrowConfirmIndicatorHandle;
   string            m_arrowConfirmIndicatorLoadedName;
   string            m_arrowConfirmIndicatorLoadedSymbol;
   ENUM_TIMEFRAMES   m_arrowConfirmIndicatorLoadedPeriod;
   string            m_arrowConfirmBlockedKey;
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
   ulong             m_lastDragSyncTick;
   double            m_lastAppliedTp;
   double            m_lastAppliedSl;
   ulong             m_ignoreExternalTpSlUntil;
   bool              m_forceTpSlApply;
   int               m_topPanelLastWidth;
   int               m_topPanelLastChartWidth;
   string            m_topPosTextCache;
   string            m_topAvgTextCache;
   string            m_topLiqTextCache;
   string            m_topPnlTextCache;
   string            m_topTotalTextCache;
   color             m_topPosColorCache;
   color             m_topAvgColorCache;
   color             m_topLiqColorCache;
   color             m_topPnlColorCache;
   color             m_topTotalColorCache;
   ulong             m_pendingCloseTickets[];
   int               m_pendingAsyncActions[];
   ulong             m_pendingAsyncPositions[];
   ulong             m_pendingAsyncOrders[];
   string            m_pendingAsyncSymbols[];
   string            m_pendingAsyncComments[];
   int               m_pendingAsyncTypes[];
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
   void              SyncDraggedTpSlToPanel(const bool force=false);

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
   string            PadRight(const string text, const int width);
   double            StopoutEquityThreshold();
   void              UpdateTopPanelLayout();
   void              UpdateAddOnBreakevenToggleButton();
   void              UpdateFloatAddToggleButton();
   void              UpdateFloatAddConfigLabel();
   int               MeasureTextWidthPx(const string text, const string fontName, const int fontSize);
   int               FindTrackedPositionIndex(const ulong ticket);
   int               FindTrackedOrderIndex(const ulong ticket);
   int               FindPendingCloseIndex(const ulong ticket);
   void              AddPendingCloseTicket(const ulong ticket);
   void              RemovePendingCloseTicket(const ulong ticket);
   void              AddPendingAsyncRequest(const ENUM_TRADE_REQUEST_ACTIONS action,
                                         const string symbol,
                                         const string comment,
                                         const ulong position,
                                         const ulong order,
                                         const int requestType);
   int               FindPendingAsyncRequestIndex(const MqlTradeRequest &request);
   void              RemovePendingAsyncRequestByIndex(const int index);
   bool              IsBuyManagedOrderType(const ENUM_ORDER_TYPE orderType);
   bool              IsPriceValidForOrderSide(const ENUM_POSITION_TYPE posType, const double marketPrice, const double price, const bool isTakeProfit);
   void              NormalizeSafeStopsForSide(const ENUM_POSITION_TYPE posType,
                                            const double marketPrice,
                                            const double rawSl,
                                            const double rawTp,
                                            double &safeSl,
                                            double &safeTp);
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
   bool              EnsureArrowIndicatorHandleForPeriod(const ENUM_TIMEFRAMES period,
         int &handle,
         string &loadedName,
         string &loadedSymbol,
         ENUM_TIMEFRAMES &loadedPeriod);
   bool              EnsureArrowIndicatorHandle();
   bool              GetLatestArrowSignalFromICustomForPeriod(const ENUM_TIMEFRAMES period,
         int &handle,
         string &loadedName,
         string &loadedSymbol,
         ENUM_TIMEFRAMES &loadedPeriod,
         ENUM_POSITION_TYPE &posType,
         string &signalKey,
         string &objectName,
         datetime &signalTime,
         string &debugText);
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
   bool              PassesArrowConfirmFilter(const ENUM_POSITION_TYPE primaryPosType,
         const string primarySignalKey,
         const string primaryObjectName,
         const datetime primarySignalTime,
         string &filterState);
   bool              HasManagedExposureForArrow();
   void              CloseManagedExposureForArrow();
   void              ProcessArrowSignalAutoTrading();
   bool              SamePrice(const double a, const double b);

   //---
   double            NormLots(double lots);
   double            ResolveWorkingLots(const double fallbackLots = 0.0, const bool syncDisplay = true);
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
   m_lastDragSyncTick = 0;
   m_closeReverse  = true;
   m_autoAddOnBreakeven = false;
   m_pendingAutoBeBuy = false;
   m_pendingAutoBeSell = false;
   m_autoFloatProfitAdd = InpEnableFloatProfitAdd;
   m_pendingFloatAddBuy = false;
   m_pendingFloatAddSell = false;
   m_nextFloatAddBuyProfit = 0.0;
   m_nextFloatAddSellProfit = 0.0;
   m_arrowSignalPrimed = false;
   m_lastArrowSignalKey = "";
   m_lastArrowSignalDebug = "";
   m_arrowPendingReentry = false;
   m_arrowPendingPosType = POSITION_TYPE_BUY;
   m_arrowPendingSignalKey = "";
   m_arrowPendingObjectName = "";
   m_arrowPendingSignalTime = 0;
   m_arrowInflightSignalKey = "";
   m_arrowIndicatorHandle = INVALID_HANDLE;
   m_arrowIndicatorLoadedName = "";
   m_arrowIndicatorLoadedSymbol = "";
   m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
   m_arrowConfirmIndicatorHandle = INVALID_HANDLE;
   m_arrowConfirmIndicatorLoadedName = "";
   m_arrowConfirmIndicatorLoadedSymbol = "";
   m_arrowConfirmIndicatorLoadedPeriod = PERIOD_CURRENT;
   m_arrowConfirmBlockedKey = "";
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
   m_topPanelLastChartWidth = 0;
   m_topPosTextCache = "";
   m_topAvgTextCache = "";
   m_topLiqTextCache = "";
   m_topPnlTextCache = "";
   m_topTotalTextCache = "";
   m_topPosColorCache = clrNONE;
   m_topAvgColorCache = clrNONE;
   m_topLiqColorCache = clrNONE;
   m_topPnlColorCache = clrNONE;
   m_topTotalColorCache = clrNONE;
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
   if(m_lastUpdateTick > 0 && refreshTick - m_lastUpdateTick < 300)
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

   ProcessArrowSignalAutoTrading();

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
   if(marketPrice <= 0.0)
      marketPrice = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

   double safeSl = 0.0;
   double safeTp = 0.0;
   NormalizeSafeStopsForSide(posType, marketPrice, sl, tp, safeSl, safeTp);

   if(sl > 0.0 && safeSl <= 0.0)
      Print("[Panel] ", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            "提示: 当前SL价格方向不合法，已自动清零 | SL:", DoubleToString(sl, _Digits),
            " | Price:", DoubleToString(marketPrice, _Digits));

   if(tp > 0.0 && safeTp <= 0.0)
      Print("[Panel] ", (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            "提示: 当前TP价格方向不合法，已自动清零 | TP:", DoubleToString(tp, _Digits),
            " | Price:", DoubleToString(marketPrice, _Digits));

   m_trade.SetTypeFilling(DetectFilling());

   bool sent = false;
   if(posType == POSITION_TYPE_BUY)
      sent = m_trade.Buy(normLots, _Symbol, 0, safeSl, safeTp, orderComment);
   else
      sent = m_trade.Sell(normLots, _Symbol, 0, safeSl, safeTp, orderComment);

   if(sent)
     {
      AddPendingAsyncRequest(TRADE_ACTION_DEAL,
                             _Symbol,
                             orderComment,
                             0,
                             0,
                             (int)(posType == POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL));
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
   m_lots = ResolveWorkingLots();
   ExecuteMarketOrder(POSITION_TYPE_BUY, m_lots, "QuickPanel Buy", true);
  }

//+------------------------------------------------------------------+
//| SELL  -                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickSell()
  {
   m_lots = ResolveWorkingLots();
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
         AddPendingAsyncRequest(TRADE_ACTION_REMOVE, "", "", 0, ticket, -1);
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
          AddPendingAsyncRequest(TRADE_ACTION_DEAL, "", "", ticket, 0, -1);
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
   double currentLots = ResolveWorkingLots(0.0, false);
   m_lots = NormLots(currentLots + InpLotsStep);
   UpdateLotsDisplay();
  }

//+------------------------------------------------------------------+
//|  -                                                             |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickLotsMinus()
  {
   SoundClick();
   double currentLots = ResolveWorkingLots(0.0, false);
   m_lots = NormLots(currentLots - InpLotsStep);
   UpdateLotsDisplay();
  }

//+------------------------------------------------------------------+
//|  x2                                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickLotsX2()
  {
   SoundClick();
   double currentLots = ResolveWorkingLots(0.0, false);
   m_lots = NormLots(currentLots * 2.0);
   UpdateLotsDisplay();
  }

//+------------------------------------------------------------------+
//|  /2                                                            |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnClickLotsD2()
  {
   SoundClick();
   double currentLots = ResolveWorkingLots(0.0, false);
   m_lots = NormLots(currentLots / 2.0);
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
//| 按方向清洗TP/SL，非法价位自动清零                                  |
//+------------------------------------------------------------------+
void CQuickTradePanel::NormalizeSafeStopsForSide(const ENUM_POSITION_TYPE posType,
      const double marketPrice,
      const double rawSl,
      const double rawTp,
      double &safeSl,
      double &safeTp)
  {
   safeSl = 0.0;
   safeTp = 0.0;

   if(rawSl > 0.0 && IsPriceValidForOrderSide(posType, marketPrice, rawSl, false))
      safeSl = NormalizeDouble(rawSl, _Digits);

   if(rawTp > 0.0 && IsPriceValidForOrderSide(posType, marketPrice, rawTp, true))
      safeTp = NormalizeDouble(rawTp, _Digits);
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
   int safeClears = 0;

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
      double marketPrice = (m_posInfo.PositionType() == POSITION_TYPE_BUY
                            ? SymbolInfoDouble(m_posInfo.Symbol(), SYMBOL_BID)
                            : SymbolInfoDouble(m_posInfo.Symbol(), SYMBOL_ASK));
      if(marketPrice <= 0.0)
         marketPrice = SymbolInfoDouble(m_posInfo.Symbol(), SYMBOL_LAST);

      double safeSl = 0.0;
      double safeTp = 0.0;
      NormalizeSafeStopsForSide(m_posInfo.PositionType(), marketPrice, sl, tp, safeSl, safeTp);
      if((sl > 0.0 && safeSl <= 0.0) || (tp > 0.0 && safeTp <= 0.0))
         safeClears++;

      if(SamePrice(currentSl, safeSl) && SamePrice(currentTp, safeTp))
        {
          skip++;
          continue;
        }

      if(m_trade.PositionModify(ticket, safeSl, safeTp))
        {
         AddPendingAsyncRequest(TRADE_ACTION_SLTP, "", "", ticket, 0, -1);
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
      ENUM_POSITION_TYPE posType = (IsBuyManagedOrderType(orderType) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
      double marketPrice = (posType == POSITION_TYPE_BUY
                            ? SymbolInfoDouble(sym, SYMBOL_ASK)
                            : SymbolInfoDouble(sym, SYMBOL_BID));
      if(marketPrice <= 0.0)
         marketPrice = SymbolInfoDouble(sym, SYMBOL_LAST);

      double safeSl = 0.0;
      double safeTp = 0.0;
      NormalizeSafeStopsForSide(posType, marketPrice, sl, tp, safeSl, safeTp);
      if((sl > 0.0 && safeSl <= 0.0) || (tp > 0.0 && safeTp <= 0.0))
         safeClears++;

      if(SamePrice(currentSl, safeSl) && SamePrice(currentTp, safeTp))
        {
          skip++;
          continue;
        }

      if(m_trade.OrderModify(ticket, priceOpen, safeSl, safeTp, typeTime, expiration, stopLimit))
        {
         AddPendingAsyncRequest(TRADE_ACTION_MODIFY, "", "", 0, ticket, -1);
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
         " | 持仓:", posOk, " | 挂单:", ordOk, " | 跳过:", skip,
         " | 安全清零:", safeClears, " | 失败:", fail);
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

   if(lotStep <= 0.0)
      lotStep = 0.01;
   if(minLot <= 0.0)
      minLot = lotStep;
   if(maxLot < minLot)
      maxLot = minLot;

   lots = MathMax(minLot, MathMin(maxLot, lots));

   double steps = MathRound((lots - minLot) / lotStep);
   lots = minLot + steps * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));

   int lotDigits = 2;
   if(lotStep > 0.0)
      lotDigits = (int)MathRound(-MathLog10(lotStep));
   lotDigits = (int)MathMax(0, MathMin(8, lotDigits));

   return NormalizeDouble(lots, lotDigits);
  }

//+------------------------------------------------------------------+
//| 从面板输入框同步当前工作手数                                      |
//+------------------------------------------------------------------+
double CQuickTradePanel::ResolveWorkingLots(const double fallbackLots, const bool syncDisplay)
  {
   double parsedLots = StringToDouble(m_edtLots.Text());
   if(parsedLots <= 0.0)
     {
      if(m_lots > 0.0)
         parsedLots = m_lots;
      else
         if(fallbackLots > 0.0)
            parsedLots = fallbackLots;
         else
            parsedLots = InpDefaultLots;
     }

   m_lots = NormLots(parsedLots);
   if(syncDisplay)
      UpdateLotsDisplay();

   return m_lots;
  }

//+------------------------------------------------------------------+
//|                                                        |
//+------------------------------------------------------------------+
void CQuickTradePanel::UpdateLotsDisplay()
  {
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int lotDigits = 2;
   if(lotStep > 0.0)
      lotDigits = (int)MathRound(-MathLog10(lotStep));
   lotDigits = (int)MathMax(0, MathMin(8, lotDigits));
   m_edtLots.Text(DoubleToString(m_lots, lotDigits));
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
//| 登记本面板发出的异步请求                                           |
//+------------------------------------------------------------------+
void CQuickTradePanel::AddPendingAsyncRequest(const ENUM_TRADE_REQUEST_ACTIONS action,
      const string symbol,
      const string comment,
      const ulong position,
      const ulong order,
      const int requestType)
  {
   int size = ArraySize(m_pendingAsyncActions);
   ArrayResize(m_pendingAsyncActions, size + 1);
   ArrayResize(m_pendingAsyncPositions, size + 1);
   ArrayResize(m_pendingAsyncOrders, size + 1);
   ArrayResize(m_pendingAsyncSymbols, size + 1);
   ArrayResize(m_pendingAsyncComments, size + 1);
   ArrayResize(m_pendingAsyncTypes, size + 1);

   m_pendingAsyncActions[size] = (int)action;
   m_pendingAsyncPositions[size] = position;
   m_pendingAsyncOrders[size] = order;
   m_pendingAsyncSymbols[size] = symbol;
   m_pendingAsyncComments[size] = comment;
   m_pendingAsyncTypes[size] = requestType;
  }

//+------------------------------------------------------------------+
//| 查找是否为本面板登记过的异步请求                                   |
//+------------------------------------------------------------------+
int CQuickTradePanel::FindPendingAsyncRequestIndex(const MqlTradeRequest &request)
  {
   int total = ArraySize(m_pendingAsyncActions);
   for(int i = total - 1; i >= 0; i--)
     {
      if(m_pendingAsyncActions[i] != (int)request.action)
         continue;
      if(m_pendingAsyncPositions[i] > 0 && m_pendingAsyncPositions[i] != request.position)
         continue;
      if(m_pendingAsyncOrders[i] > 0 && m_pendingAsyncOrders[i] != request.order)
         continue;
      if(m_pendingAsyncSymbols[i] != "" && m_pendingAsyncSymbols[i] != request.symbol)
         continue;
      if(m_pendingAsyncComments[i] != "" && m_pendingAsyncComments[i] != request.comment)
         continue;
      if(m_pendingAsyncTypes[i] >= 0 && m_pendingAsyncTypes[i] != (int)request.type)
         continue;
      return i;
     }

   return -1;
  }

//+------------------------------------------------------------------+
//| 删除已回执的异步请求登记                                           |
//+------------------------------------------------------------------+
void CQuickTradePanel::RemovePendingAsyncRequestByIndex(const int index)
  {
   int size = ArraySize(m_pendingAsyncActions);
   if(index < 0 || index >= size)
      return;

   for(int i = index; i < size - 1; i++)
     {
      m_pendingAsyncActions[i] = m_pendingAsyncActions[i + 1];
      m_pendingAsyncPositions[i] = m_pendingAsyncPositions[i + 1];
      m_pendingAsyncOrders[i] = m_pendingAsyncOrders[i + 1];
      m_pendingAsyncSymbols[i] = m_pendingAsyncSymbols[i + 1];
      m_pendingAsyncComments[i] = m_pendingAsyncComments[i + 1];
      m_pendingAsyncTypes[i] = m_pendingAsyncTypes[i + 1];
     }

   ArrayResize(m_pendingAsyncActions, size - 1);
   ArrayResize(m_pendingAsyncPositions, size - 1);
   ArrayResize(m_pendingAsyncOrders, size - 1);
   ArrayResize(m_pendingAsyncSymbols, size - 1);
   ArrayResize(m_pendingAsyncComments, size - 1);
   ArrayResize(m_pendingAsyncTypes, size - 1);
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
         AddPendingAsyncRequest(TRADE_ACTION_SLTP, "", "", ticket, 0, -1);
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
   double addLots = ResolveWorkingLots(InpFloatProfitAddLots);
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
//| 确保箭头指标句柄可用                                              |
//+------------------------------------------------------------------+
bool CQuickTradePanel::EnsureArrowIndicatorHandleForPeriod(const ENUM_TIMEFRAMES period,
      int &handle,
      string &loadedName,
      string &loadedSymbol,
      ENUM_TIMEFRAMES &loadedPeriod)
  {
   string indicatorName = InpArrowIndicatorName;
   StringTrimLeft(indicatorName);
   StringTrimRight(indicatorName);

   if(indicatorName == "")
     {
      if(handle != INVALID_HANDLE)
        {
         IndicatorRelease(handle);
         handle = INVALID_HANDLE;
        }
      loadedName = "";
      loadedSymbol = "";
      loadedPeriod = PERIOD_CURRENT;
      return false;
     }

   if(handle != INVALID_HANDLE &&
      loadedName == indicatorName &&
      loadedSymbol == _Symbol &&
      loadedPeriod == period)
     {
      return true;
     }

   if(handle != INVALID_HANDLE)
     {
      IndicatorRelease(handle);
      handle = INVALID_HANDLE;
     }

   ResetLastError();
   handle = iCustom(_Symbol, period, indicatorName);
   if(handle == INVALID_HANDLE)
     {
      int err = GetLastError();
      Print("[Panel] 箭头指标 iCustom 句柄创建失败 | Name:", indicatorName,
            " | TF:", EnumToString(period),
            " | Error:", err);
      loadedName = "";
      loadedSymbol = "";
      loadedPeriod = PERIOD_CURRENT;
      return false;
     }

   loadedName = indicatorName;
   loadedSymbol = _Symbol;
   loadedPeriod = period;
   return true;
  }

//+------------------------------------------------------------------+
//| 通过 iCustom 读取最新箭头信号                                    |
//+------------------------------------------------------------------+
bool CQuickTradePanel::EnsureArrowIndicatorHandle()
  {
   return EnsureArrowIndicatorHandleForPeriod((ENUM_TIMEFRAMES)_Period,
                                              m_arrowIndicatorHandle,
                                              m_arrowIndicatorLoadedName,
                                              m_arrowIndicatorLoadedSymbol,
                                              m_arrowIndicatorLoadedPeriod);
  }

//+------------------------------------------------------------------+
//| 通过 iCustom 读取指定周期的最新箭头信号                          |
//+------------------------------------------------------------------+
bool CQuickTradePanel::GetLatestArrowSignalFromICustomForPeriod(const ENUM_TIMEFRAMES period,
      int &handle,
      string &loadedName,
      string &loadedSymbol,
      ENUM_TIMEFRAMES &loadedPeriod,
      ENUM_POSITION_TYPE &posType,
      string &signalKey,
      string &objectName,
      datetime &signalTime,
      string &debugText)
  {
   signalKey = "";
   objectName = "";
   signalTime = 0;
   debugText = "";

   string indicatorName = InpArrowIndicatorName;
   StringTrimLeft(indicatorName);
   StringTrimRight(indicatorName);
   if(indicatorName == "")
      return false;

   string lowerName = indicatorName;
   StringToLower(lowerName);
   if(StringFind(lowerName, "halftrend") < 0)
      return false;

   if(!EnsureArrowIndicatorHandleForPeriod(period, handle, loadedName, loadedSymbol, loadedPeriod))
      return false;

   const int lookback = 200;
   datetime barTimes[];
   double highs[];
   double lows[];
   ArraySetAsSeries(barTimes, true);
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   int timeCopied = CopyTime(_Symbol, period, 1, lookback, barTimes);
   int highCopied = CopyHigh(_Symbol, period, 1, lookback, highs);
   int lowCopied = CopyLow(_Symbol, period, 1, lookback, lows);
   if(timeCopied <= 0 || highCopied <= 0 || lowCopied <= 0)
      return false;

   int buyBufferIndex = MathMax(0, InpArrowBuyBuffer);
   int sellBufferIndex = MathMax(0, InpArrowSellBuffer);

   double buyBuffer[];
   double sellBuffer[];
   ArraySetAsSeries(buyBuffer, true);
   ArraySetAsSeries(sellBuffer, true);

   int buyCopied = CopyBuffer(handle, buyBufferIndex, 1, lookback, buyBuffer);
   int sellCopied = CopyBuffer(handle, sellBufferIndex, 1, lookback, sellBuffer);
   if(buyCopied <= 0 && sellCopied <= 0)
      return false;

   datetime debugTimes[];
   double debugBuy[];
   double debugSell[];
   ArraySetAsSeries(debugTimes, true);
   ArraySetAsSeries(debugBuy, true);
   ArraySetAsSeries(debugSell, true);
   int debugTimeCopied = CopyTime(_Symbol, period, 0, 4, debugTimes);
   int debugBuyCopied = CopyBuffer(handle, buyBufferIndex, 0, 4, debugBuy);
   int debugSellCopied = CopyBuffer(handle, sellBufferIndex, 0, 4, debugSell);

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
      int probeCopied = CopyBuffer(handle, buf, 1, lookback, probe);
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

   string debugInfo = "Src=iCustom"
                      + " | TF=" + EnumToString(period)
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

      debugInfo += " | s" + IntegerToString(k)
                   + "@" + timeText
                   + " B=" + buyText
                   + " S=" + sellText;
     }
   debugInfo += " | Full=";
   for(int buf = 0; buf <= 7; buf++)
     {
      double probe[];
      ArraySetAsSeries(probe, true);
      int probeCopied = CopyBuffer(handle, buf, 0, 4, probe);

      debugInfo += "b" + IntegerToString(buf) + "[";
      for(int shift = 0; shift < 4; shift++)
        {
         if(shift > 0)
            debugInfo += ",";

         string probeText = "--";
         if(shift < probeCopied && probe[shift] != EMPTY_VALUE && probe[shift] != 0.0)
            probeText = DoubleToString(probe[shift], _Digits);

         debugInfo += "s" + IntegerToString(shift) + "=" + probeText;
        }
      debugInfo += "]";
      if(buf < 7)
         debugInfo += ";";
     }
   debugText = debugInfo;
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
   string debugText = "";
   bool ok = GetLatestArrowSignalFromICustomForPeriod((ENUM_TIMEFRAMES)_Period,
                                                      m_arrowIndicatorHandle,
                                                      m_arrowIndicatorLoadedName,
                                                      m_arrowIndicatorLoadedSymbol,
                                                      m_arrowIndicatorLoadedPeriod,
                                                      posType,
                                                      signalKey,
                                                      objectName,
                                                      signalTime,
                                                      debugText);
   m_lastArrowSignalDebug = debugText;
   return ok;
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
//| 多周期确认过滤：主周期信号需得到确认周期同向确认                  |
//+------------------------------------------------------------------+
bool CQuickTradePanel::PassesArrowConfirmFilter(const ENUM_POSITION_TYPE primaryPosType,
      const string primarySignalKey,
      const string primaryObjectName,
      const datetime primarySignalTime,
      string &filterState)
  {
   filterState = "Filter=OFF";
   if(!InpEnableArrowConfirmFilter)
     {
      m_arrowConfirmBlockedKey = "";
      return true;
     }

   ENUM_TIMEFRAMES confirmPeriod = InpArrowConfirmPeriod;
   if(confirmPeriod == PERIOD_CURRENT || confirmPeriod == (ENUM_TIMEFRAMES)_Period)
     {
      filterState = "Filter=SAME-TF";
      m_arrowConfirmBlockedKey = "";
      return true;
     }

   ENUM_POSITION_TYPE confirmPosType = POSITION_TYPE_BUY;
   string confirmSignalKey = "";
   string confirmObjectName = "";
   datetime confirmSignalTime = 0;
   string confirmDebug = "";

   bool gotConfirm = GetLatestArrowSignalFromICustomForPeriod(confirmPeriod,
                                                              m_arrowConfirmIndicatorHandle,
                                                              m_arrowConfirmIndicatorLoadedName,
                                                              m_arrowConfirmIndicatorLoadedSymbol,
                                                              m_arrowConfirmIndicatorLoadedPeriod,
                                                              confirmPosType,
                                                              confirmSignalKey,
                                                              confirmObjectName,
                                                              confirmSignalTime,
                                                              confirmDebug);

   string tfText = EnumToString(confirmPeriod);
   if(!gotConfirm)
     {
      filterState = "Filter=WAIT-NO-SIGNAL"
                    + " | TF:" + tfText
                    + " | MainObj:" + primaryObjectName
                    + " | MainTime:" + TimeToString(primarySignalTime, TIME_DATE|TIME_SECONDS);

      if(primarySignalKey != m_arrowConfirmBlockedKey)
        {
         Print("[Panel] 箭头信号被确认周期拦截 | Need:",
               (primaryPosType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               " | TF:", tfText,
               " | Reason:NO-SIGNAL",
               " | MainObject:", primaryObjectName,
               " | MainTime:", TimeToString(primarySignalTime, TIME_DATE|TIME_SECONDS),
               (confirmDebug != "" ? " | ConfirmDebug:" + confirmDebug : ""));
         m_arrowConfirmBlockedKey = primarySignalKey;
        }
      return false;
     }

   filterState = "Filter=TF:" + tfText
                 + " | Main:" + (primaryPosType == POSITION_TYPE_BUY ? "BUY" : "SELL")
                 + " | Confirm:" + (confirmPosType == POSITION_TYPE_BUY ? "BUY" : "SELL")
                 + " | ConfirmTime:" + TimeToString(confirmSignalTime, TIME_DATE|TIME_SECONDS)
                 + " | ConfirmObj:" + confirmObjectName;

   if(confirmPosType != primaryPosType)
     {
      if(primarySignalKey != m_arrowConfirmBlockedKey)
        {
         Print("[Panel] 箭头信号被确认周期拦截 | Need:",
               (primaryPosType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               " | ConfirmNow:", (confirmPosType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               " | TF:", tfText,
               " | MainObject:", primaryObjectName,
               " | MainTime:", TimeToString(primarySignalTime, TIME_DATE|TIME_SECONDS),
               " | ConfirmTime:", TimeToString(confirmSignalTime, TIME_DATE|TIME_SECONDS));
         m_arrowConfirmBlockedKey = primarySignalKey;
        }
      return false;
     }

   m_arrowConfirmBlockedKey = "";
   return true;
  }

//+------------------------------------------------------------------+
//| 是否存在当前面板管理范围内的仓位/挂单                            |
//+------------------------------------------------------------------+
bool CQuickTradePanel::HasManagedExposureForArrow()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_posInfo.SelectByIndex(i))
         continue;
      if(InpCurrentOnly && m_posInfo.Symbol() != _Symbol)
         continue;
      if(InpMagicNumber > 0 && m_posInfo.Magic() != InpMagicNumber)
         continue;
      return true;
     }

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

      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT  &&
         orderType != ORDER_TYPE_SELL_LIMIT &&
         orderType != ORDER_TYPE_BUY_STOP   &&
         orderType != ORDER_TYPE_SELL_STOP  &&
         orderType != ORDER_TYPE_BUY_STOP_LIMIT &&
         orderType != ORDER_TYPE_SELL_STOP_LIMIT)
         continue;

      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| 单单模式下先清理旧仓，再开新信号单                               |
//+------------------------------------------------------------------+
void CQuickTradePanel::CloseManagedExposureForArrow()
  {
   AsyncCloseByType(POSITION_TYPE_BUY);
   AsyncCloseByType(POSITION_TYPE_SELL);

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

      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(orderType != ORDER_TYPE_BUY_LIMIT  &&
         orderType != ORDER_TYPE_SELL_LIMIT &&
         orderType != ORDER_TYPE_BUY_STOP   &&
         orderType != ORDER_TYPE_SELL_STOP  &&
         orderType != ORDER_TYPE_BUY_STOP_LIMIT &&
         orderType != ORDER_TYPE_SELL_STOP_LIMIT)
         continue;

      if(m_trade.OrderDelete(ticket))
        {
         AddPendingAsyncRequest(TRADE_ACTION_REMOVE, "", "", 0, ticket, -1);
         m_asyncPending++;
         Print("[Panel] 单单模式删除挂单 #", ticket, " | Order:", m_trade.ResultOrder());
        }
      else
         Print("[Panel] 单单模式挂单删除失败 #", ticket, ": ",
               m_trade.ResultRetcodeDescription());
     }
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
      if(m_arrowConfirmIndicatorHandle != INVALID_HANDLE)
        {
         IndicatorRelease(m_arrowConfirmIndicatorHandle);
         m_arrowConfirmIndicatorHandle = INVALID_HANDLE;
        }
      m_arrowIndicatorLoadedName = "";
      m_arrowIndicatorLoadedSymbol = "";
      m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
      m_arrowConfirmIndicatorLoadedName = "";
      m_arrowConfirmIndicatorLoadedSymbol = "";
      m_arrowConfirmIndicatorLoadedPeriod = PERIOD_CURRENT;
      m_arrowSignalPrimed = false;
      m_lastArrowSignalKey = "";
      m_lastArrowSignalDebug = "";
      m_arrowPendingReentry = false;
      m_arrowPendingSignalKey = "";
      m_arrowPendingObjectName = "";
      m_arrowPendingSignalTime = 0;
      m_arrowInflightSignalKey = "";
      m_arrowConfirmBlockedKey = "";
      return;
     }

   if(!TerminalInfoInteger(TERMINAL_CONNECTED))
      return;

   MqlTick currentTick;
   if(!SymbolInfoTick(_Symbol, currentTick) || currentTick.ask <= 0.0 || currentTick.bid <= 0.0)
      return;

   ENUM_POSITION_TYPE posType = POSITION_TYPE_BUY;
   string signalKey = "";
   string objectName = "";
   datetime signalTime = 0;
   if(!GetLatestArrowSignal(posType, signalKey, objectName, signalTime))
      return;

   string filterState = "";
   bool confirmPassed = PassesArrowConfirmFilter(posType, signalKey, objectName, signalTime, filterState);
   if(!confirmPassed)
      return;

   bool singleOrderMode = !m_autoFloatProfitAdd; // 浮盈加仓关闭时：箭头模式按“一次一单”执行
   bool hasExistingExposure = HasManagedExposureForArrow();

   if(m_arrowSignalPrimed && m_lastArrowSignalKey == "" && !m_arrowPendingReentry &&
      m_asyncPending <= 0 && hasExistingExposure)
     {
      m_lastArrowSignalKey = signalKey;
      Print("[Panel] 已有持仓，当前箭头信号仅作为基线接管，不立即重开仓 | Side:",
            (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " | Object:", objectName,
            " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
            " | ", filterState);
      return;
     }

    if(!m_arrowSignalPrimed)
    {
       m_arrowSignalPrimed = true;
       bool markSignalHandled = !InpArrowTradeOnLatestSignalAtLoad;

       m_lots = ResolveWorkingLots();

       bool sentOnLoad = false;
       if(hasExistingExposure)
          markSignalHandled = true;

       if(InpArrowTradeOnLatestSignalAtLoad && m_asyncPending <= 0 && !hasExistingExposure)
       {
          string loadComment = (posType == POSITION_TYPE_BUY ? "QTP Arrow Buy" : "QTP Arrow Sell");
          sentOnLoad = ExecuteMarketOrder(posType, m_lots, loadComment, false);
          if(sentOnLoad)
          {
             m_arrowInflightSignalKey = signalKey;
             Print("[Panel] 历史最新箭头信号已执行 | Side:",
                   (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                   " | Object:", objectName,
                   " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
                   " | Lots:", DoubleToString(m_lots, 2),
                   " | ", filterState,
                   " | Debug:", m_lastArrowSignalDebug);
            }
          markSignalHandled = sentOnLoad;
         }

       m_lastArrowSignalKey = (markSignalHandled ? signalKey : "");

       Print("[Panel] 箭头指标自动开单已就绪 | 最新信号对象:", objectName,
             " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
            " | LoadTrade:", (InpArrowTradeOnLatestSignalAtLoad ? (sentOnLoad ? "ON-SENT" : (hasExistingExposure ? "ON-PRIMED-BY-EXPOSURE" : "ON-SKIP")) : "OFF"),
            " | ", filterState,
            " | Debug:", m_lastArrowSignalDebug);
      return;
   }

   if(!singleOrderMode && m_arrowPendingReentry)
     {
      m_arrowPendingReentry = false;
      m_arrowPendingSignalKey = "";
      m_arrowPendingObjectName = "";
      m_arrowPendingSignalTime = 0;
     }

   // 单单模式：先平旧单，待无仓后再开新信号单；若等待期间有更新信号，则覆盖为最新信号
   if(singleOrderMode && m_arrowPendingReentry)
     {
      if(signalKey != m_arrowPendingSignalKey)
        {
         m_arrowPendingPosType = posType;
         m_arrowPendingSignalKey = signalKey;
         m_arrowPendingObjectName = objectName;
         m_arrowPendingSignalTime = signalTime;
         Print("[Panel] 单单模式信号更新，已替换待开方向 | Side:",
               (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               " | Object:", objectName,
               " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
               " | ", filterState);
        }

      if(m_asyncPending > 0)
         return;

      if(HasManagedExposureForArrow())
        {
         CloseManagedExposureForArrow();
         return;
        }

      m_lots = ResolveWorkingLots();

      string pendingComment = (m_arrowPendingPosType == POSITION_TYPE_BUY ? "QTP Arrow Buy" : "QTP Arrow Sell");
      bool sentPending = ExecuteMarketOrder(m_arrowPendingPosType, m_lots, pendingComment, false);
      if(sentPending)
        {
         m_arrowInflightSignalKey = m_arrowPendingSignalKey;
         Print("[Panel] 箭头指标自动开单触发(单单模式) | Side:",
                (m_arrowPendingPosType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                " | Object:", m_arrowPendingObjectName,
               " | Time:", TimeToString(m_arrowPendingSignalTime, TIME_DATE|TIME_SECONDS),
               " | Lots:", DoubleToString(m_lots, 2),
               " | ", filterState,
               " | Debug:", m_lastArrowSignalDebug);
        }

      if(sentPending)
        {
         m_arrowPendingReentry = false;
         m_arrowPendingSignalKey = "";
         m_arrowPendingObjectName = "";
         m_arrowPendingSignalTime = 0;
        }
      return;
     }

   if(signalKey == m_lastArrowSignalKey)
      return;

   if(singleOrderMode)
     {
      m_arrowPendingReentry = true;
      m_arrowPendingPosType = posType;
      m_arrowPendingSignalKey = signalKey;
      m_arrowPendingObjectName = objectName;
      m_arrowPendingSignalTime = signalTime;

      if(m_asyncPending > 0)
         return;

      if(HasManagedExposureForArrow())
        {
         Print("[Panel] 单单模式触发：检测到旧仓，先平仓再开新信号单 | Side:",
               (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               " | Object:", objectName,
               " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
               " | ", filterState);
         CloseManagedExposureForArrow();
         return;
        }

      m_lots = ResolveWorkingLots();

      string singleComment = (posType == POSITION_TYPE_BUY ? "QTP Arrow Buy" : "QTP Arrow Sell");
      bool sentSingle = ExecuteMarketOrder(posType, m_lots, singleComment, false);
      if(sentSingle)
        {
         m_arrowInflightSignalKey = signalKey;
         Print("[Panel] 箭头指标自动开单触发(单单模式) | Side:",
                (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                " | Object:", objectName,
               " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
               " | Lots:", DoubleToString(m_lots, 2),
               " | ", filterState,
               " | Debug:", m_lastArrowSignalDebug);
        }

      if(sentSingle)
        {
         m_arrowPendingReentry = false;
         m_arrowPendingSignalKey = "";
         m_arrowPendingObjectName = "";
         m_arrowPendingSignalTime = 0;
        }
      return;
     }

   if(m_asyncPending > 0)
      return;

   m_lots = ResolveWorkingLots();

   string comment = (posType == POSITION_TYPE_BUY ? "QTP Arrow Buy" : "QTP Arrow Sell");
   bool sent = ExecuteMarketOrder(posType, m_lots, comment, false);
   if(sent)
     {
      m_arrowInflightSignalKey = signalKey;
       Print("[Panel] 箭头指标自动开单触发 | Side:",
             (posType == POSITION_TYPE_BUY ? "BUY" : "SELL"),
             " | Object:", objectName,
            " | Time:", TimeToString(signalTime, TIME_DATE|TIME_SECONDS),
            " | Lots:", DoubleToString(m_lots, 2),
            " | ", filterState,
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
void CQuickTradePanel::SyncDraggedTpSlToPanel(const bool force)
  {
   ulong nowTick = GetTickCount();
   if(!force && m_lastDragSyncTick > 0 && nowTick - m_lastDragSyncTick < 250)
      return;
   m_lastDragSyncTick = nowTick;

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
   int  dataLeftX = panelLeft + TOP_PANEL_LEFT_PAD;
   int  contentRightX = panelLeft + panelWidth - TOP_PANEL_RIGHT_PAD;
   int  labelCenterX = dataLeftX + (contentRightX - dataLeftX) / 2;

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

   double linkedLots = ResolveWorkingLots((InpFloatProfitAddLots > 0.0 ? InpFloatProfitAddLots : InpDefaultLots), false);
   string text = StringFormat("每间距 %.2f 价格  +%.2f 手",
                              MathMax(0.01, InpFloatProfitStepMoney),
                              linkedLots);
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

   int dataCharWidth = MeasureTextWidthPx("W", TOP_DATA_FONT, TOP_FONT_POS);
   int totalCharWidth = MeasureTextWidthPx("W", TOP_FONT_NAME, TOP_FONT_TOTAL);
   if(dataCharWidth <= 0)
      dataCharWidth = 10;
   if(totalCharWidth <= 0)
      totalCharWidth = 16;

   string posText = (m_topPosTextCache != "" ? m_topPosTextCache : "POS  L 0 (0.00L)  S 0 (0.00L)");
   string avgText = (m_topAvgTextCache != "" ? m_topAvgTextCache : "AVG  L --  S --");
   string liqText = (m_topLiqTextCache != "" ? m_topLiqTextCache : "LIQ  L --  S --");
   string pnlText = (m_topPnlTextCache != "" ? m_topPnlTextCache : "UPL  L +0.00  S +0.00");
   string totalText = (m_topTotalTextCache != "" ? m_topTotalTextCache : "NET UPL +0.00");

   int maxDataChars = StringLen(posText);
   maxDataChars = MathMax(maxDataChars, StringLen(avgText));
   maxDataChars = MathMax(maxDataChars, StringLen(liqText));
   maxDataChars = MathMax(maxDataChars, StringLen(pnlText));

   int posRenderWidth = MeasureTextWidthPx(posText, TOP_DATA_FONT, TOP_FONT_POS);
   int avgRenderWidth = MeasureTextWidthPx(avgText, TOP_DATA_FONT, TOP_FONT_AVG);
   int liqRenderWidth = MeasureTextWidthPx(liqText, TOP_DATA_FONT, TOP_FONT_LIQ);
   int pnlRenderWidth = MeasureTextWidthPx(pnlText, TOP_DATA_FONT, TOP_FONT_PNL);
   int totalRenderWidth = MeasureTextWidthPx(totalText, TOP_FONT_NAME, TOP_FONT_TOTAL);

   int dataFloorWidth = (maxDataChars + 1) * dataCharWidth;
   int dataRenderWidth = MathMax(posRenderWidth, avgRenderWidth);
   dataRenderWidth = MathMax(dataRenderWidth, liqRenderWidth);
   dataRenderWidth = MathMax(dataRenderWidth, pnlRenderWidth);
   int dataTextWidth = MathMax(dataFloorWidth, dataRenderWidth + dataCharWidth);

   int totalFloorWidth = (StringLen(totalText) + 1) * totalCharWidth;
   int totalTextWidth = MathMax(totalFloorWidth, totalRenderWidth + totalCharWidth / 2);
   int maxTextWidth = MathMax(dataTextWidth, totalTextWidth);
   int panelSafetyWidth = MathMax(dataCharWidth * 2, totalCharWidth);

   int maxAllowedWidth = chartW - 16;
   int corePanelWidth = MathMax(TOP_PANEL_MIN_WIDTH, maxTextWidth + TOP_PANEL_LEFT_PAD + TOP_PANEL_RIGHT_PAD + TOP_PANEL_MEASURE_FUDGE + panelSafetyWidth);
   panelWidth = corePanelWidth + TOP_PANEL_RIGHT_EXTRA;
   if(maxAllowedWidth > 0 && panelWidth > maxAllowedWidth)
      panelWidth = maxAllowedWidth;
   m_topPanelLastWidth = panelWidth;

   int centerX = chartW / 2;
   int panelLeft = centerX - corePanelWidth / 2;
   if(panelLeft < 8)
      panelLeft = 8;

   int panelHeight = TOP_PANEL_EXPANDED_H;
   int dataLeftX = panelLeft + TOP_PANEL_LEFT_PAD;
   int contentRightX = panelLeft + panelWidth - TOP_PANEL_RIGHT_PAD;
   int labelCenterX = dataLeftX + (contentRightX - dataLeftX) / 2;
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
   bool visualChanged = false;

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
   color posColor = ((buys + sells > 0) ? clrWhite : clrGray);
   if(posText != m_topPosTextCache)
     {
      ObjectSetString(chartId, LBL_TOP_POS, OBJPROP_TEXT, posText);
      m_topPosTextCache = posText;
      visualChanged = true;
     }
   if(posColor != m_topPosColorCache)
     {
      ObjectSetInteger(chartId, LBL_TOP_POS, OBJPROP_COLOR, posColor);
      m_topPosColorCache = posColor;
      visualChanged = true;
     }

//--- 均价
   string buyAvgText = (buys > 0 && buyAvgPrice > 0.0 ? DoubleToString(buyAvgPrice, _Digits) : "--");
   string sellAvgText = (sells > 0 && sellAvgPrice > 0.0 ? DoubleToString(sellAvgPrice, _Digits) : "--");
   string avgText = "AVG  L " + PadRight(buyAvgText, TOP_DATA_COL_WIDTH) + " S " + PadRight(sellAvgText, TOP_DATA_COL_WIDTH);
   color avgColor = ((buys + sells > 0) ? clrRed : clrGray);
   if(avgText != m_topAvgTextCache)
     {
      ObjectSetString(chartId, LBL_TOP_AVG, OBJPROP_TEXT, avgText);
      m_topAvgTextCache = avgText;
      visualChanged = true;
     }
   if(avgColor != m_topAvgColorCache)
     {
      ObjectSetInteger(chartId, LBL_TOP_AVG, OBJPROP_COLOR, avgColor);
      m_topAvgColorCache = avgColor;
      visualChanged = true;
     }

   string buyLiqText = (buyLiqPrice > 0.0 ? DoubleToString(buyLiqPrice, _Digits) : "--");
   string sellLiqText = (sellLiqPrice > 0.0 ? DoubleToString(sellLiqPrice, _Digits) : "--");
   string liqText = "LIQ  L " + PadRight(buyLiqText, TOP_DATA_COL_WIDTH) + " S " + PadRight(sellLiqText, TOP_DATA_COL_WIDTH);
   color liqColor = (((buyLiqPrice > 0.0) || (sellLiqPrice > 0.0)) ? clrOrange : clrGray);
   if(liqText != m_topLiqTextCache)
     {
      ObjectSetString(chartId, LBL_TOP_LIQ, OBJPROP_TEXT, liqText);
      m_topLiqTextCache = liqText;
      visualChanged = true;
     }
   if(liqColor != m_topLiqColorCache)
     {
      ObjectSetInteger(chartId, LBL_TOP_LIQ, OBJPROP_COLOR, liqColor);
      m_topLiqColorCache = liqColor;
      visualChanged = true;
     }

//--- 多空浮盈
   string longUplText = StringFormat("%+.2f", buyPft);
   string shortUplText = StringFormat("%+.2f", sellPft);
   string pnlText = "UPL  L " + PadRight(longUplText, TOP_DATA_COL_WIDTH) + " S " + PadRight(shortUplText, TOP_DATA_COL_WIDTH);
   if(pnlText != m_topPnlTextCache)
     {
      ObjectSetString(chartId, LBL_TOP_PNL, OBJPROP_TEXT, pnlText);
      m_topPnlTextCache = pnlText;
      visualChanged = true;
     }

//--- color for buy/sell P/L row
   color pnlColor = clrSilver;
   if(buys + sells > 0)
     {
      if(buyPft + sellPft >= 0)
         pnlColor = clrLimeGreen;
      else
         pnlColor = clrCoral;
     }
   if(pnlColor != m_topPnlColorCache)
     {
      ObjectSetInteger(chartId, LBL_TOP_PNL, OBJPROP_COLOR, pnlColor);
      m_topPnlColorCache = pnlColor;
      visualChanged = true;
     }

//--- 总浮盈
   double totalPnl = buyPft + sellPft;
   string totalText = StringFormat("NET UPL %+.2f", totalPnl);
   if(totalText != m_topTotalTextCache)
     {
      ObjectSetString(chartId, LBL_TOP_TOTAL, OBJPROP_TEXT, totalText);
      m_topTotalTextCache = totalText;
      visualChanged = true;
     }

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
   if(totalColor != m_topTotalColorCache)
     {
      ObjectSetInteger(chartId, LBL_TOP_TOTAL, OBJPROP_COLOR, totalColor);
      m_topTotalColorCache = totalColor;
      visualChanged = true;
     }

   int chartW = (int)ChartGetInteger(chartId, CHART_WIDTH_IN_PIXELS);
   if(visualChanged || chartW != m_topPanelLastChartWidth)
     {
      m_topPanelLastChartWidth = chartW;
      UpdateTopPanelLayout();
      ChartRedraw(chartId);
     }

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
   if(m_arrowConfirmIndicatorHandle != INVALID_HANDLE)
     {
      IndicatorRelease(m_arrowConfirmIndicatorHandle);
      m_arrowConfirmIndicatorHandle = INVALID_HANDLE;
     }
   m_arrowIndicatorLoadedName = "";
   m_arrowIndicatorLoadedSymbol = "";
   m_arrowIndicatorLoadedPeriod = PERIOD_CURRENT;
   m_arrowConfirmIndicatorLoadedName = "";
   m_arrowConfirmIndicatorLoadedSymbol = "";
   m_arrowConfirmIndicatorLoadedPeriod = PERIOD_CURRENT;
   m_arrowConfirmBlockedKey = "";
  }

//+------------------------------------------------------------------+
//|                                                    |
//+------------------------------------------------------------------+
void CQuickTradePanel::OnAsyncResult(const MqlTradeTransaction &trans,
                                     const MqlTradeRequest &request,
                                     const MqlTradeResult &result)
  {
   bool isFloatAddRequest = (StringFind(request.comment, "QTP FloatAdd ") == 0);
   bool isArrowRequest = (StringFind(request.comment, "QTP Arrow ") == 0);
   ENUM_POSITION_TYPE floatAddSide = POSITION_TYPE_BUY;
   if(request.type == ORDER_TYPE_SELL)
      floatAddSide = POSITION_TYPE_SELL;

//---
   if(trans.type == TRADE_TRANSACTION_REQUEST)
     {
      int pendingReqIdx = FindPendingAsyncRequestIndex(request);
      if(pendingReqIdx < 0)
         return;

      bool trackedCloseRequest = (m_pendingAsyncPositions[pendingReqIdx] > 0 &&
                                  request.action == TRADE_ACTION_DEAL);
      if(trackedCloseRequest && request.position > 0)
         RemovePendingCloseTicket(request.position);

      RemovePendingAsyncRequestByIndex(pendingReqIdx);

      if(m_asyncPending > 0)
         m_asyncPending--;

      if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
        {
         if(isArrowRequest && m_arrowInflightSignalKey != "")
            m_lastArrowSignalKey = m_arrowInflightSignalKey;
         if(isArrowRequest)
            m_arrowInflightSignalKey = "";

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
          if(isArrowRequest)
             m_arrowInflightSignalKey = "";
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
      g_panel.SyncDraggedTpSlToPanel(true);

   if(id == CHARTEVENT_CHART_CHANGE)
      {
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
