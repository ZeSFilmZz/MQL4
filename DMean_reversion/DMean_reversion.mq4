//+------------------------------------------------------------------+
//|                                         TestDMean_reversion2.mq4 |
//|                                          Copyright 2022, Thu In. |
//|                              https://www.facebook.com/ChaiLhee.F |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Thu In."
#property link      "https://www.facebook.com/ChaiLhee.F"
#property version   "1.00"
#property strict

input double Lots = 0.02;
input int SLpoint = 2900;
input int TPpoint = 2000;
input int AVofATR = 200;
input int LimitOrder = 1;
input double VolPointPerDay = 1000;
input double PointDiffPriceAndKAMA = 500;
extern int  OpenTradeHour=0;
extern int  OpenTradeMinutes=0;
extern int  OpenTradeSeconds=0;
extern int  CloseTradeHour=23;
extern int  CloseTradeMinutes=59;
extern int  CloseTradeSeconds=59;
extern int  CloseTradeFridayHour=20;
extern int  CloseTradeFridayMinutes=55;
extern int  CloseTradeFridaySeconds=0;
enum CloseByIndy {OPEN=1,CLOSE=0};
extern CloseByIndy CloseByIndicator=1;

int LastBar=0;
double KAMA = 0;
double HMA = 0;
double HMAPre = 0;
double dataATR[];
double dataAVATR[];
double AvATR = 0;
double StdATR = 0;
bool BuySignal = false;
bool SellSignal = false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if( !isFridayNight() ){     
      GetKAMAIndy();
      GetHMAIndy();
      GetATR(3,AVofATR);
      GetAvandStdOfATR();
      if( SellSignal && !BuySignal ) CloseOrderByIndy("SELL");
      if( BuySignal && !SellSignal ) CloseOrderByIndy("BUY");
      CheckBuySignal();
      CheckSellSignal();
      if(LastBar<Bars && isTimeToTrade() ){
         if( SellSignal && !BuySignal ) EntryOrder("SELL");
         if( BuySignal && !SellSignal ) EntryOrder("BUY");
      }
     // Comment(BuySignal+","+SellSignal);
   }
   else {
      //CloseAllLossOrder();
      //CloseAllOrder();
      GetKAMAIndy();
      GetHMAIndy();
      GetATR(3,AVofATR);
      GetAvandStdOfATR();
      if( SellSignal && !BuySignal ) CloseOrderByIndy("SELL");
      if( BuySignal && !SellSignal ) CloseOrderByIndy("BUY");
      if( (int)(TimeCurrent() % 86400 )> 20 * 3600 + 59 * 60 ){
         if( OrdersTotalOfAScalpThisSymbol()==0 ){
            BuySignal = false;
            SellSignal = false;
         }
         else CloseAllOrder();
      }
   }

  }
//+------------------------------------------------------------------+


//-----------------------------ตรวจสอบเวลาเทรด-----------------------------------------------------------------------------------------------------------------
bool isTimeToTrade(){
   datetime now = TimeCurrent();  #define HR2400 86400
   int tod = (int)(now % HR2400) ;   // Time of day.
   int todOpen = OpenTradeHour * 3600 + OpenTradeMinutes * 60 + OpenTradeSeconds;
   int todClose = CloseTradeHour * 3600 + CloseTradeMinutes * 60 + CloseTradeSeconds;
   
   if( tod>todOpen && tod<todClose ) return true;
   return false;
}
bool isFridayNight(){
   datetime now = TimeCurrent();  //#define HR2400 86400
   int tod = (int)(now % HR2400) ;   // Time of day.
   int todClose = CloseTradeFridayHour * 3600 + CloseTradeFridayMinutes * 60 + CloseTradeFridaySeconds;
   
   if( DayOfWeek() != 5 ) {
      return false;
   }
   else {
      if( tod>todClose ) return true;
   }
   return false;
}

//-------------------------รับค่าIndy-------------------------------------------------------------
void GetKAMAIndy(){
   KAMA = iCustom(NULL,0,"kama_adaptive",10,4,5,30,0.0,0,0);
}

void GetHMAIndy(){
   double value1 = iCustom(NULL,0,"hull-moving-average",10,1,0,0,1);
   double value2 = iCustom(NULL,0,"hull-moving-average",10,1,0,1,1);
   double value1Pre = iCustom(NULL,0,"hull-moving-average",10,1,0,0,2);
   double value2Pre = iCustom(NULL,0,"hull-moving-average",10,1,0,1,2);
   if( value1>200000000 ) HMA = value2;
   else HMA = value1;
   if( value1Pre>200000000 ) HMAPre = value2Pre;
   else HMAPre = value1Pre;
}

void GetATR(int bar,int AVbar){
   ArrayResize(dataATR,bar);
   ArrayResize(dataAVATR,AVbar);
   for(int i=0; i<bar ; i++){
      dataATR[i] = iATR(NULL,0,6,i);
   }
   for(int i=0; i<AVbar ; i++){
      dataAVATR[i] = iATR(NULL,0,6,i);
   }
   
}
void GetAvandStdOfATR(){
   AvATR = iMAOnArray(dataAVATR,0,ArraySize(dataAVATR),0,MODE_EMA,0);
   StdATR = iStdDevOnArray(dataAVATR,0,ArraySize(dataAVATR),0,MODE_EMA,0);
}

//---------------------------เช็คเงื่อนไขindy---------------------------------------------------------
bool checkATR(){
   if( dataATR[1]<dataATR[2] && dataATR[1]>AvATR+StdATR ) return true; //&& dataATR[1]>AvATR+StdATR
   return false;
}

bool checkBUYHMA(){
   if( Close[1]>HMA && HMAPre<HMA ) return true;
   return false;
}

bool checkSELLHMA(){
   if( Close[1]<HMA && HMAPre>HMA) return true; 
   return false;
}

void CheckBuySignal(){
   if( Bid>KAMA ) BuySignal=false ;
   if( iHigh(NULL,PERIOD_D1,0)-iLow(NULL,PERIOD_D1,0) > VolPointPerDay*Point && KAMA-Bid > PointDiffPriceAndKAMA*Point && dataATR[0]>AvATR+StdATR ){ //iHigh(NULL,PERIOD_D1,0)-iLow(NULL,PERIOD_D1,0) > VolPointPerDay*Point &&
      if(!BuySignal) LastBar=Bars;
      BuySignal=true;
   }
}

void CheckSellSignal(){
   if( Bid<KAMA ) SellSignal=false ;
   if( iHigh(NULL,PERIOD_D1,0)-iLow(NULL,PERIOD_D1,0) > VolPointPerDay*Point && Bid-KAMA > PointDiffPriceAndKAMA*Point && dataATR[0]>AvATR+StdATR ){ //iHigh(NULL,PERIOD_D1,0)-iLow(NULL,PERIOD_D1,0) > VolPointPerDay*Point &&
      if(!SellSignal) LastBar=Bars;
      SellSignal=true;
   }
}

//---------------------------check LimitOrder---------------------------------
bool checkLimitOrderBUY(){
   if( OrdersTotal()< LimitOrder ) return true;
   return false;
}
bool checkLimitOrderSELL(){ 
   if( OrdersTotal()< LimitOrder ) return true;
   return false;
}


//-------------------------เข้าOrder----------------------------------------------------------
void EntryOrder( string side ) {
   if( side == "BUY"){
      if( checkBUYHMA() && checkATR() && checkLimitOrderBUY() ) { 
         int tic = OrderSend(Symbol(),OP_BUY,Lots,Ask,2,Bid-SLpoint*Point,Bid+TPpoint*Point,NULL,8888,0,clrGreen);
         LastBar=Bars;
      }
   }
   else if ( side == "SELL"){
      if( checkSELLHMA() && checkATR() && checkLimitOrderSELL() ) { 
         int tic = OrderSend(Symbol(),OP_SELL,Lots,Bid,2,Ask+SLpoint*Point,Ask-TPpoint*Point,NULL,8888,0,clrRed);
         LastBar=Bars;
      }
   }
}

//--------------------ปิดOrderโดยใช้Inde------------------------------------------------------
void CloseOrderByIndy( string side ){
   if( CloseByIndicator ) {
      bool Tic=true;
      if( side == "BUY" ){
         if( OrdersTotal()>0 ){
            for( int i=0 ; i<OrdersTotal() ; i++ ){
               if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
                  if( OrderSymbol()==Symbol() && OrderMagicNumber()==8888 && Bid>KAMA ) { //OrderProfit()+OrderCommission()+OrderSwap() > 0 &&
                     Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack); 
                     LastBar=Bars;
                     BuySignal = false;
                  }
                  /*if( OrderProfit() > 0 && HMA<HMAPre && Close[1]<HMA ){
                     Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack); 
                     LastBar=Bars;
                     //BuySignal = false;
                  }
                  if( OrderProfit() < 0 && HMA<HMAPre && Close[1]<HMA ){
                     Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack); 
                     LastBar=Bars;
                  }*/
               }
            }
         }
      }
      if( side == "SELL" ){
         if( OrdersTotal()>0 ){
            for( int i=0 ; i<OrdersTotal() ; i++ ){
               if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
                  if( OrderSymbol()==Symbol() && OrderMagicNumber()==8888 && Bid<KAMA ) { //OrderProfit()+OrderCommission()+OrderSwap() > 0 &&
                     Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack);  
                     LastBar=Bars;
                     SellSignal = false;
                  }
                  /*if( OrderProfit() > 0 && HMA>HMAPre && Close[1]>HMA ){
                     Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack); 
                     LastBar=Bars;
                     //SellSignal = false;
                  }
                  if( OrderProfit() < 0 && HMA>HMAPre && Close[1]>HMA ){
                     Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack); 
                     LastBar=Bars;
                  }*/
               }
            }
         }
      }
      if(!Tic) Print("Cannot close Order!!");
   }
}

int OrdersTotalOfAScalpThisSymbol(){
   int count=0;
   for( int i=0 ; i<OrdersTotal() ; i++ ){
      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==8888 ) count++;
      }
   }
   return count;
}


void CloseAllOrder(){
   bool Tic=false;
   if( OrdersTotalOfAScalpThisSymbol()>0 ){
      for( int i=0 ; i<OrdersTotal() ; i++ ){
            if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
               if( OrderType()==OP_BUY  ) {
                  if(OrderSymbol()==Symbol() && OrderMagicNumber()==8888 ) Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack); 
               }
               else if( OrderType()==OP_SELL  )  {
                  if(OrderSymbol()==Symbol() && OrderMagicNumber()==8888 ) Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack);
               }
            }
         }
   }
}


