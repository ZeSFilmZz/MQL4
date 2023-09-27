//+------------------------------------------------------------------+
//|                                             AdapScalp_V2_3_2.mq4 |
//|                                          Copyright 2022, Thu In. |
//|                              https://www.facebook.com/ChaiLhee.F |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Thu In."
#property link      "https://www.facebook.com/ChaiLhee.F"
#property version   "2.32"
#property strict

input double Lots = 0.01;
input int SLpoint = 5800;
input int TPpoint = 2000;
input int CheckConATR = 2;
input int CheckATR = 3;
input int AVofATR = 200;
input int VortexShift = 1;
input int LimitOrder = 3;
input double SlopeAverageATR = 0;
input double DollarProfitTarget = 0;
input double DividedOfSL = 3; // SLD/Average Vol per day
input string SideTrade = "BUY";
extern int  OpenTradeHour=2;
extern int  OpenTradeMinutes=0;
extern int  OpenTradeSeconds=0;
extern int  CloseTradeHour=22;
extern int  CloseTradeMinutes=0;
extern int  CloseTradeSeconds=0;
extern int  CloseTradeFridayHour=20;
extern int  CloseTradeFridayMinutes=55;
extern int  CloseTradeFridaySeconds=0;
enum CloseByIndy {OPEN=1,CLOSE=0};
extern CloseByIndy CloseByIndicator=1;

int LastBar=0;
double ALMA = 0;
double ALMA1 = 0;
double ALMA2 = 0;
double ALMAUp = 0;
double ALMADown = 0;
double PlusVI = 0;
double MinusVI = 0;
double PlusVICurrent = 0;
double MinusVICurrent = 0;
double dataATR[];
double dataAVATR[];
double AvATR = 0;
double StdATR = 0;
double LastPriceTrade = 0;
double ALMAofDay = 0;
double ALMA1ofDay = 0;
double ALMA2ofDay = 0;
double ALMA3ofDay = 0;
bool EA_Status = true;
bool Waiting = false;


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
   GetALMAofDayIndy();
   CheckWaiting();
   if(!Waiting){
   CheckEA_Status();
   if( EA_Status ) {
      if( !isFridayNight() ){      
         GetALMAIndy();
         GetVortexIndy(VortexShift);
         GetATR(CheckATR,AVofATR);
         GetAvandStdOfATR();
         //CloseOrderByIndy("SELL");
         CloseOrderByIndy(SideTrade);
         if(LastBar<Bars && isTimeToTrade() ){
            //EntryOrder("SELL");
            //EntryOrder("BUY");
            EntryOrder(SideTrade);
         }
      }
      else {
         GetALMAIndy();
         GetVortexIndy(VortexShift);
         GetATR(CheckATR,AVofATR);
         GetAvandStdOfATR();
         CloseOrderByIndy(SideTrade);
         //CloseAllLossOrder();
         //CloseAllOrder();
      }
   }
   else {
      CloseAllOrder();
   }
   }
   //else CloseAllOrder();
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
   /*if( DayOfWeek() != 5 && DayOfWeek() != 6 ) {
      //if( tod < 23 * 3600 + 55 * 60 ) 
      return true;
      //else return false;
   }
   else {
      if( tod<todClose ) return true;
   }
   return false;
   */
}
bool isFridayNight(){
   datetime now = TimeCurrent();  //#define HR2400 86400
   int tod = (int)(now % HR2400) ;   // Time of day.
   int todClose = CloseTradeFridayHour * 3600 + CloseTradeFridayMinutes * 60 + CloseTradeFridaySeconds;
   
   if( DayOfWeek() != 5 ) {
      //if( tod < 23 * 3600 + 55 * 60 ) 
      return false;
      //else return false;
   }
   else {
      if( tod>todClose ) return true;
   }
   return false;
}

//-------------------------รับค่าIndy-------------------------------------------------------------
void GetALMAIndy(){
   ALMA = iCustom(NULL,0,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,0,0);
   ALMA1 = iCustom(NULL,0,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,0,1);
   ALMA2 = iCustom(NULL,0,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,0,2);
   ALMAUp = iCustom(NULL,0,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,1,0);
   ALMADown = iCustom(NULL,0,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,2,0);
}

void GetALMAofDayIndy() {
   ALMAofDay = iCustom(NULL,PERIOD_D1,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,0,0);
   ALMA1ofDay = iCustom(NULL,PERIOD_D1,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,0,1);
   ALMA2ofDay = iCustom(NULL,PERIOD_D1,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,0,2);
   ALMA3ofDay = iCustom(NULL,PERIOD_D1,"ALMA",0,18,6.0,0.85,0.0,0.0,0,1,0,0,0,0,3);
}

void GetVortexIndy(int shift){
   PlusVI = iCustom(NULL,0,"vortex-indicator",40,0,shift);
   MinusVI = iCustom(NULL,0,"vortex-indicator",40,1,shift);
   PlusVICurrent = iCustom(NULL,0,"vortex-indicator",40,0,0);
   MinusVICurrent = iCustom(NULL,0,"vortex-indicator",40,1,0);
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
   AvATR = iMAOnArray(dataAVATR,0,ArraySize(dataAVATR),0,MODE_SMA,0);
   StdATR = iStdDevOnArray(dataAVATR,0,ArraySize(dataAVATR),0,MODE_SMA,0);
   //Print(AvATR+","+StdATR+"......."+iBandsOnArray(dataAVATR,0,ArraySize(dataAVATR),1,0,MODE_MAIN,0)+","+iBandsOnArray(dataAVATR,0,ArraySize(dataAVATR),1,0,MODE_LOWER,0));
}

//---------------------------เช็คเงื่อนไขindy---------------------------------------------------------
void CheckWaiting(){
      if( (ALMA1ofDay < ALMA2ofDay && ALMA2ofDay > ALMA3ofDay)||(ALMA1ofDay > ALMA2ofDay && ALMA2ofDay < ALMA3ofDay)  ) Waiting=true;
      else Waiting = false;
}
void CheckEA_Status() {
   if(SideTrade == "BUY"){
      if( ALMA1ofDay < ALMA2ofDay  ) EA_Status = false;
      else EA_Status = true;
   }
   else if(SideTrade == "SELL"){
      if( ALMA1ofDay > ALMA2ofDay  ) EA_Status = false;
      else EA_Status = true;
   }
}

bool checkATR(int barCheck){
   bool cATR = true;
   //int bar = ArraySize(dataATR);
   for(int i=0; i<barCheck-1 ; i++){
      if( dataATR[i]<dataATR[i+1] ) cATR = false;  // if( dataATR[0]<dataATR[i+1] ) cATR = false;
   }
   if( dataATR[0]>=AvATR+StdATR ) cATR = false;
   if( dataATR[0]<=AvATR-StdATR ) cATR = false;
   return cATR;
}

bool checkBUYALMA() {
   if( Bid>ALMA  ) return true;  //if( Ask>ALMAUp && ALMAUp<2100000000 && ALMADown>2100000000 )   && Low[0]<ALMA1  && Close[1]<=ALMA1 && ALMA1<ALMA && ALMA2<ALMA1
   return false;
}
bool checkSELLALMA() {
   if( Ask<ALMA  ) return true; //if( Bid<ALMADown && ALMADown<2100000000 && ALMAUp>2100000000 )  && High[0]>ALMA1 && Close[1]>=ALMA1 && ALMA1>ALMA && ALMA2>ALMA1
   return false;
}

bool checkBUYVortex(){
   if( (PlusVI>=MinusVI && PlusVICurrent>MinusVICurrent && PlusVICurrent>1) || (PlusVI<MinusVI  && PlusVICurrent>MinusVICurrent && PlusVICurrent>1)  ) return true;  //&& PlusVI>PlusVI2 // && PlusVICurrent>PlusVI && PlusVICurrent>(PlusVI+PlusVICurrent)/2 
   return false;
}
bool checkSELLVortex(){
   if( (PlusVI<=MinusVI && PlusVICurrent<MinusVICurrent && MinusVICurrent>1) || (PlusVI>MinusVI  && PlusVICurrent<MinusVICurrent && MinusVICurrent>1) ) return true;  //&& MinusVI>MinusVI2 // && MinusVICurrent>MinusVI
   return false;
}

bool checkCloseBUYVortex(){
   if( PlusVI<MinusVI && PlusVICurrent<MinusVICurrent  ) return true;  //&& PlusVI>PlusVI2 //&& PlusVICurrent<PlusVI
   return false;
}
bool checkCloseSELLVortex(){
   if( PlusVICurrent>MinusVICurrent  ) return true;  //PlusVI>MinusVI && MinusVI>MinusVI2 //&& MinusVICurrent<MinusVI
   return false;
}
bool checkHighVolATR(){
    if( dataATR[0]>=AvATR+StdATR ) return true;
    return false;
}
bool checkLowVolATR(){
   bool CVATR = true;
    for( int i=0; i<ArraySize(dataATR) ; i++){
      if( dataATR[i]>AvATR-StdATR ) CVATR=false;
    }
    return CVATR;
}

//---------------------------check LimitOrder---------------------------------
bool checkLimitOrderBUY(){
   if( OrdersTotalOfAScalpThisSymbol()==0 ) return true;
   else if( OrdersTotalOfAScalpThisSymbol()<LimitOrder ){
      double MinLastPriceTrade=0;
      for( int i=0 ; i<OrdersTotal() ; i++ ){ 
         if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){ 
            if( OrderSymbol()==Symbol() ){
               MinLastPriceTrade = OrderOpenPrice();
               break;
            }
         }
      }
      for( int i=1 ; i<OrdersTotal() ; i++ ){
         if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
            if( OrderSymbol()==Symbol() ){
               if(OrderOpenPrice()<MinLastPriceTrade) MinLastPriceTrade=OrderOpenPrice();
            }
         }
      }
      LastPriceTrade = MinLastPriceTrade;
      if( Ask<(LastPriceTrade-(SLpoint/(DividedOfSL*LimitOrder))*Point) ) return true;
   }
   return false;
}
bool checkLimitOrderSELL(){
   if( OrdersTotalOfAScalpThisSymbol()==0 ) return true;
   else if( OrdersTotalOfAScalpThisSymbol()<LimitOrder ){
      double MaxLastPriceTrade=0;
      for( int i=0 ; i<OrdersTotal() ; i++ ){ 
         if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){ 
            if( OrderSymbol()==Symbol() ){
               MaxLastPriceTrade = OrderOpenPrice();
               break;
            }
         }
      }
      for( int i=1 ; i<OrdersTotal() ; i++ ){
         if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
            if( OrderSymbol()==Symbol() ){
               if(OrderOpenPrice()>MaxLastPriceTrade) MaxLastPriceTrade=OrderOpenPrice();
            }
         }
      }
      LastPriceTrade = MaxLastPriceTrade;
      if( Bid>(LastPriceTrade+(SLpoint/(DividedOfSL*LimitOrder))*Point) ) return true;
   }
   return false;
}


//-------------------------เข้าOrder----------------------------------------------------------
void EntryOrder( string side ) {
   if( side == "BUY"){
      if( checkBUYALMA() && checkBUYVortex() && checkATR(CheckConATR) && checkLimitOrderBUY() && avSlopeATR()>SlopeAverageATR ) { 
         int tic = OrderSend(Symbol(),OP_BUY,Lots,Ask,2,Bid-SLpoint*Point,Bid+TPpoint*Point,NULL,2222,0,clrGreen);
         LastPriceTrade = Ask;
         LastBar=Bars;
      }
   }
   else if ( side == "SELL"){
      if( checkSELLALMA() && checkSELLVortex() && checkATR(CheckConATR) && checkLimitOrderSELL() && avSlopeATR()>SlopeAverageATR ) { 
         int tic = OrderSend(Symbol(),OP_SELL,Lots,Bid,2,Ask+SLpoint*Point,Ask-TPpoint*Point,NULL,2222,0,clrRed);
         LastPriceTrade = Bid;
         LastBar=Bars;
      }
   }
}

//--------------------ปิดOrderโดยใช้Inde------------------------------------------------------
void CloseOrderByIndy( string side ){
   if( CloseByIndicator ) {
      bool Tic=true;
      if( side == "BUY" ){
         if( OrdersTotalOfAScalpThisSymbol()>0 ){
            for( int i=0 ; i<OrdersTotal() ; i++ ){
               if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
                  if( OrderSymbol()==Symbol() && OrderMagicNumber()==2222 && OrderProfit()+OrderCommission()+OrderSwap() > DollarProfitTarget && ( ( Bid<ALMA  )  ) ) { //( Bid<ALMA && Close[1]<ALMA1 ) || checkLowVolATR()
                     Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack); //|| ( checkCloseBUYVortex()&&checkATR() )
                     LastBar=Bars;
                  }
                  //else if( OrderProfit() < 0 ) Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack);
               }
            }
         }
      }
      if( side == "SELL" ){
         if( OrdersTotalOfAScalpThisSymbol()>0 ){
            for( int i=0 ; i<OrdersTotal() ; i++ ){
               if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
                  if( OrderSymbol()==Symbol() && OrderMagicNumber()==2222 && OrderProfit()+OrderCommission()+OrderSwap() > DollarProfitTarget && ( (Ask>ALMA  )  ) ) { //(Ask>ALMA && Close[1]>ALMA1 ) || checkLowVolATR()
                     Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack);  //|| ( checkCloseSELLVortex()&&checkATR() )
                     LastBar=Bars;
                  }
                  //if( OrderProfit()+OrderCommission()+OrderSwap() < 0 && checkCloseSELLVortex() && checkHighVolATR() ) Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack);
               }
            }
         }
      }
      if(!Tic) Print("Cannot close Order!!");
   }
}

/*
double avSlopeATR(){
   double slp=0;
   for( int i=1 ; i<ArraySize(dataATR) ; i++ ){
      slp = slp+dataATR[0]-dataATR[i];
   }
   Comment(slp);
   return (slp/Point)/(ArraySize(dataATR)-1);
}
*/

double avSlopeATR(){
   double slp=0;
   double SigXY=0;
   double SigX=0;
   double SigY=0;
   double SigXSquare=0;
   int No=ArraySize(dataATR);
   for( int i=1 ; i<=No ; i++ ){
      SigXY = SigXY+(i*dataATR[No-i]);
      SigX = SigX+i;
      SigY = SigY+dataATR[No-i];
      SigXSquare = SigXSquare+(i*i);
   }
   slp = ( (No*SigXY) - (SigX*SigY) )/( (No*SigXSquare)-(SigX*SigX) );
  // Comment (slp/Point);
   return (slp/Point);
}


int OrdersTotalOfAScalpThisSymbol(){
   int count=0;
   for( int i=0 ; i<OrdersTotal() ; i++ ){
      if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==2222 ) count++;
      }
   }
   return count;
}
/*
void CloseAllLossOrder(){
   bool Tic=false;
   if( OrdersTotal()>0 ){
      for( int i=0 ; i<OrdersTotal() ; i++ ){
            if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
               if( OrderType()==OP_BUY && OrderProfit()<0 && checkCloseBUYVortex() ) Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack); 
               else if( OrderType()==OP_SELL && OrderProfit()<0 && checkCloseSELLVortex() ) Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack);
            }
         }
   }
}
*/
void CloseAllOrder(){
   bool Tic=false;
   if( OrdersTotal()>0 ){
      for( int i=0 ; i<OrdersTotal() ; i++ ){
            if( OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true ){
               if( OrderType()==OP_BUY && OrderMagicNumber()==2222 ) Tic = OrderClose(OrderTicket(),OrderLots(),Bid,2,clrBlack); 
               else if( OrderType()==OP_SELL && OrderMagicNumber()==2222 ) Tic = OrderClose(OrderTicket(),OrderLots(),Ask,2,clrBlack);
            }
         }
   }
}

