//+------------------------------------------------------------------+
//             Copyright Â© 2012, 2013 chew-z                        |
//+------------------------------------------------------------------+
#property copyright "Pin Bar Reversal © 2012, 2013, 2014 chew-z"
#include <TradeContext.mq4>
#include <TradeTools\TradeTools5.mqh>
#include <stdlib.mqh>

int magic_number_1 = 20551236;
string orderComment = "Pin Bar Reversal 1.0";
string AlertText = "";
string AlertEmailSubject = "";
static int BarTime;

int ticketArr[];
//--------------------------
int OnInit()     {
   BarTime = 0;
   for(int i=0; i < maxContracts; i++) //re-initialize table with order tickets
        ticketArr[i] = 0;
   AlertEmailSubject = Symbol() + orderComment + " alert";
   if (Digits == 5 || Digits == 3){    // Adjust for five (5) digit brokers.
      pips2dbl    = Point*10; pips2points = 10;   Digits_pips = 1;
   } else {    pips2dbl    = Point;    pips2points =  1;   Digits_pips = 0; }
   ArrayResize(ticketArr, maxContracts);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)   {
   Print(__FUNCTION__,"_Deinitalization reason code = ", getDeinitReasonText(reason));
}
//-------------------------
void OnTick()    {
bool isNewBar = NewBar();
bool isNewDay = NewDay();
double StopLoss, TakeProfit, price;
bool  ShortBuy = false, LongBuy = false;
int cnt, check;
int contracts = 0;
double Lots;

if ( isNewDay ) {
   for(int i=0; i < maxContracts; i++) //re-initialize an array with order tickets
      ticketArr[i] = 0;
}
if ( isNewBar ) {

// DISCOVER SIGNALS
      if (PinBar2(minBar) >=  3.0 )   {  LongBuy = true;   }
      if (PinBar2(minBar) <= -3.0 )   {  ShortBuy = true;  }

   cnt = f_OrdersTotal(magic_number_1, ticketArr); //-1 = no active orders
   while ( cnt >= 0) {                              //Print ("Ticket #", ticketArr[k]);
      if(OrderSelect(ticketArr[cnt], SELECT_BY_TICKET, MODE_TRADES) )   {
// EXIT MARKET [time exit]
         if( (OrderType() == OP_BUY || OrderType() == OP_SELL) )   {
                  if(TradeIsBusy() < 0) // Trade Busy semaphore
                     break;
                  RefreshRates();
                  if (OrderType()==OP_SELL) price = Ask;
                  if (OrderType()==OP_BUY)  price = Bid;
                  check = OrderClose(OrderTicket(), OrderLots(), price, 5, Violet);
                  TradeIsNotBusy();
                  f_SendAlerts(orderComment + " trade exit attempted.\rResult = " + ErrorDescription(GetLastError()) + ". \rPrice = " + DoubleToStr(Ask, 5));
         }
       }//if OrderSelect
      cnt--;
      } //end while

// MONEY MANAGEMENT
         Lots =  maxLots;
         cnt = f_OrdersTotal(magic_number_1, ticketArr) + 1;   //how many open lots?
         contracts = f_Money_Management() - cnt;               //how many possible?
// ENTER MARKET CONDITIONS
if( cnt < contracts )   { //if we are able to open new lots...
// check for long position (BUY) possibility
      if(LongBuy == true )      { // pozycja z sygnalu
         price = Ask;
         StopLoss = NormalizeDouble(price - minBar*pips2dbl, Digits);
         TakeProfit = NormalizeDouble(price + 2*minBar*pips2dbl, Digits);
   //--------Transaction        //Print (StopLoss," - ", price, " - ", TakeProfit);
         check = f_SendOrders(OP_BUY, contracts, Lots, StopLoss, TakeProfit, magic_number_1, orderComment);
   //--------
         if(check == 0)         {
              AlertText = "BUY order opened : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
               + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5);
         }  else { AlertText = "Error opening BUY order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Ask, 5) + ", L = " + DoubleToStr(L, 5); }
         f_SendAlerts(AlertText);
      }
// check for short position (SELL) possibility
      if(ShortBuy == true )      { // pozycja z sygnalu
         price = Bid;
         StopLoss = NormalizeDouble(price + SL*pips2dbl, Digits);
         TakeProfit = NormalizeDouble(price - TP*pips2dbl, Digits);
   //--------Transaction        //Print (TakeProfit, " - ", price, " - ", StopLoss);
          check = f_SendOrders(OP_SELL, contracts, Lots, StopLoss, TakeProfit, magic_number_1, orderComment);
   //--------
         if(check == 0)         {
               AlertText = "SELL order opened : " + Symbol() + ", " + TFToStr(Period())+ " -\r"
               + orderComment + " " + contracts + " order(s) opened. \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5);
         }  else { AlertText = "Error opening SELL order : " + ErrorDescription(check) + ". \rPrice = " + DoubleToStr(Bid, 5) + ", H = " + DoubleToStr(H, 5); }
         f_SendAlerts(AlertText);
      }
    }
  }//isNewBar
}// exit OnTick()
