/***************************************************************************
Name : Cretae Reserve API
Created By  : Tejas Kapasi    
Description : 

CM000 : Success : 
CM001 : The given request is invalid. : Result Desciption-1: ‘YYYYY’ element contains Invalid value:  'XXXX' in the request.
CM002 : The format of this request is invalid. Please refer to Online Documentation.
CM003 : Missing Information in the request. : Result Description 1: Request missing required element: 'XXXXX'. 
CM004 : Internal system error. Please try again or contact your local Customer Service Center.
CM007 : Your request cannot be fulfilled for the given criteria. : Result Description 1: 'XXXXX' value for element 'YYYYY' not supported.
CM014 : Invalid Product  Code provided in the request. Please refer to Online Documentation. : Result Description 1: 'XXXXX' value for element 'YYYYY' not supported.
SC007 : Subscriber validation failed.  Please contact your D&B Representative or your local Customer Service Center. :Subscriber Number is Invalid/Not Available 
RS001 : Unable to reserve due to insufficient wallet balance. : Unable to reserve due to insufficient wallet balance.

{
  "subscribernumberlfd" : "500000246",
  "reserveamount" : 10  ,
  "currencycode" : "CAD",
  "expirydatetime" : "",
  "productid" : "338"
}

--------
{
  "reservesuccess": "Yes",
  "reserveID": "aB11900000001ogCAA",
  "message": "Success",
  "expirydatetime": "2015-07-29T08:54:14.631-04:00",
  "errorcode": "CM000",
  "currentbalance": 378.99,
  "currencycode": "CAD"
}
***************************************************************************/

@RestResource (urlMapping='/APTS_CreateReserveService/*')
global class APTS_REST_CreateReserveService {
    
    global static REQ_CreateReserveService_JSON JSONRequest;
    global static RES_CreateReserveService_JSON JSONResponse;
    global static Boolean blnRequiredDataMissing = false; 
    global static string strResultID, strResultText;
    global static string strRequestJSON, strResponseJSON ;
    global static string strReservesuccess ;
    
    //====================================================================================
    // *** REST POST *** : Require field should not be empty
    //====================================================================================
    
    @HttpPost
    global static void doPostCreateReserveservice() {

        /***************************JSON Request**********************************/
        RestRequest req = RestContext.request;
 //       strRequestJSON = req.requestbody.tostring();

        // Generate JSON Response to be sent to Services System
        JSONResponse = new RES_CreateReserveService_JSON();
		JSONResponse = new RES_CreateReserveService_JSON();

        // ------   Checking Json Request Parsing ---------------------//
        
        try{
    
    
            JSONRequest = (REQ_CreateReserveService_JSON)JSON.deserializeStrict(strRequestJSON, REQ_CreateReserveService_JSON.class);
            system.debug('JSONRequest '+JSONRequest);

        }Catch(JSONException JSEX){
            
            strReservesuccess       =  'No' ;
            strResultID             =  'CM002';
            strResultText           =  'The format of this request is invalid. Please refer to Online Documentation., ' + JSEX.getMessage();
            system.debug(JSEX.getMessage());
        } 

        // Validate JSON String for Mandatory Elements
        if( strResultID == null ){
            
            doValidateJSONReqeust();
        }

        if (strResultID == null) {
      Decimal  subscribernumber ;
            try {
              subscribernumber =   Decimal.ValueOF(JSONRequest.subscribernumber) ;
            } catch (TypeException TE) {
                strReservesuccess   =  'No' ;
                strResultID         = 'SC007';
                strResultText       = 'Subscriber validation failed.  Please contact your D&B Representative or your local Customer Service Center.';
        system.debug('TE  '+TE.getStackTraceString() + ' ' + TE.getMessage());   
                sendResponse (StrReservesuccess,strResultID,strResultText);
            }
            
            if (strResultID == null) {
                //String  productcode =        JSONRequest.productcode ;
                Decimal reserveamount           =     Decimal.ValueOf(JSONRequest.reserveamount) ;
                String  currencycode            =     JSONRequest.currencycode ;
                String  expirydatetime          =     JSONRequest.expirydatetime ;
                String  productid               =     JSONRequest.productid ;
                Decimal decExpirationTimeOnProd    ;
    
    
                system.debug('subscribernumber '+subscribernumber);
                //----------  First Get Product Id from the Product Feature Mapping Table ----------------//
                List<Product2> listProds = [SELECT Id,Name,ProductCode,APTS_Expiration_Hours__c FROM Product2 WHERE ProductCode =: productid ];
                

                System.debug('First Query From Product  '+listProds.size());
                System.debug('First Query From Product  '+listProds);
                
                if (!listProds.isEmpty() && strResultID == null) {
                    
                    decExpirationTimeOnProd = listProds[0].APTS_Expiration_Hours__c ;
                    //----------  Second Get Participating Point It will be single Record ----------------//
                    List<APTS_Participating_Point__c> listParticipatingPoint = new List<APTS_Participating_Point__c> ();
                    
                    listParticipatingPoint = [SELECT Id, Name,APTS_Subscriber_No__c,APTS_Asset_Line_Item__c ,CurrencyIsoCode,Product__c,
                                                APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c, 
                                                APTS_Asset_Line_Item__r.Apttus_Config2__NetPrice__c,
                                                APTS_Asset_Line_Item__r.WalletID__c,APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c,
                                                APTS_Asset_Line_Item__r.WalletID__r.Total_Usage_Consumed__c,
                                                APTS_Agreement_Line_Item__c,APTS_Agreement_Line_Item__r.Apttus__AgreementId__c,
                                                APTS_Agreement_Line_Item__r.Apttus__AgreementId__r.Apttus__Contract_End_Date__c
                                                FROM APTS_Participating_Point__c
                                                WHERE APTS_Subscriber_No__c =: subscribernumber
                                                AND Product__c =: listProds[0].ID
                                                AND (   APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c      = 'New' 
                                                        OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c   = 'Renewed' 
                                                        OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c   = 'Incremented' 
                                                        OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c   = 'Amended'
                                                        OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c   = 'Existing'
                                                    )
                                                ];
                    
                    System.debug( 'For this Subscriber No and Feature Find Participating Point : '+ listParticipatingPoint.size());
                    System.debug( 'For this Subscriber No and Feature Find Participating Point : '+ listParticipatingPoint);
    
                    //-------  From this Participatingpoint find Asset Line and Wallet and then Creating reserve part ---//
                    if (!listParticipatingPoint.isEmpty() ) {
    
                        Id AssetLnID =  listParticipatingPoint[0].APTS_Asset_Line_Item__c ;
                        Id WalletID  =  listParticipatingPoint[0].APTS_Asset_Line_Item__r.WalletID__c ;     
    
                        if (WalletID != null) {
    
                            Wallet__c walletSO = [SELECT Id, Name,CurrencyIsoCode ,
                                                        Status__c,Wallet_Balance__c,Wallet_Code__c                             
                                                    FROM Wallet__c 
                                                    WHERE Id =: WalletID];
    
                            // Validation Check for currency should be same as wallet currency
                            if(currencycode != walletSO.CurrencyIsoCode) {
    
                                //JSONResponse.errorcode      = 'Missing Information';
                                //JSONResponse.message        = 'Currency is not valid';
                                JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
                                strReservesuccess       = 'No' ;
                                strResultID             = 'CM007';
                                strResultText           = 'Your request cannot be fulfilled for the given criteria. : '+ currencycode + ' value for element \'currencycode\' not supported.';
                                //return JSONResponse ;
                            }
    
                            //------------  Creating Reserve Record First Then Deduct from Wallet.---------------------// 
                            system.debug('strResultID '+strResultID);
                            if (strResultID == null && (walletSO.Wallet_Balance__c >= reserveamount) && reserveamount > 0 ){
    
                                DateTime dtNow                      ;
                                Reserve__c createReserveSO          = new Reserve__c ();
                                createReserveSO.CurrencyIsoCode     = walletSO.CurrencyIsoCode;
                                createReserveSO.Start_Date__c       = Date.today();
                                createReserveSO.Wallet__c           = walletSO.Id;
                                createReserveSO.Reserve_Code__c     = productid;
                                createReserveSO.ReserveAmount__c    = reserveamount ;// decimal.ValueOf(reserveamount);
                                createReserveSO.Status__c           = 'Active';
                                createReserveSO.RemainingBalance__c = reserveamount ; // decimal.ValueOf(reserveamount);                            
                                
                                // expirydatetime is optional 
                                if (!String.isBlank(expirydatetime) ) {     
                                    try {
        
                                        JSONParser parser = JSON.createParser( '{"t":"' + expirydatetime + '"}');
                                        parser.nextToken();    // advance to the start object marker
                                        parser.nextValue();    // advance to the next value
                                        createReserveSO.End_Date__c = DateTime.newInstance( parser.getDateTimeValue().getTime());
                                        // Added 16-07 by seeing Error Code 
                                        if (createReserveSO.End_Date__c < DateTime.now()) {
                                            
                                            JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
                                            strReservesuccess       = 'No' ;
                                            strResultID             = 'CM001';
                                            strResultText           = 'The given request is invalid.' + ' expirydatetime should be Future Date ' ; 
                                        }
        
                                    } catch ( JSONException JE) {
        
                                        JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
                                        strReservesuccess       = 'No' ;
                                        strResultID             = 'CM001';
                                        strResultText           = 'The given request is invalid. : expirydatetime element contains Invalid value: \'' + expirydatetime + '\' in the request.';                           
        
                                    }
                                } else {

                                    
                                    system.debug('dtNow '+dtNow);
                                    if (decExpirationTimeOnProd != null) {
                                        dtNow = DateTime.now();
                                        if ( decExpirationTimeOnProd.toPlainString().Contains('.') ) {
                                            // that means hours in points. Need to count minutes.

                                            dtNow = dtNow.addHours(Integer.valueOf(decExpirationTimeOnProd.toPlainString().substringBefore('.')));
                                            system.debug('dtNow '+dtNow);
                                            dtNow = dtNow.addMinutes(Integer.valueOf(decExpirationTimeOnProd.toPlainString().substringAfter('.')));
                                            system.debug('dtNow '+dtNow);

                                        } else {

                                            dtNow.addHours(Integer.valueOf(decExpirationTimeOnProd));
                                            system.debug('dtNow '+dtNow);
                                        }

                                        createReserveSO.End_Date__c = dtNow ;
                                    }
                                }
    
                                //-----------------------------------------------------
                                // Create Reserve First
                                //--------------------------------------------------------------
                                system.debug('strResultID '+strResultID);
                                if (strResultID == null) {
    
                                    try {
    
                                        insert createReserveSO ;
    
                                        //---------------  Creating Response ------------------------------------//
                                        JSONResponse.reserveID      = createReserveSO.Id;
                                        StrReservesuccess = 'Yes' ;  
                                        strResultID       = 'CM000';
                                        strResultText    = 'Success';
                                        JSONResponse.currencycode   = createReserveSO.CurrencyIsoCode;
                                        if(!String.isBlank(expirydatetime)) {
                                            JSONResponse.expirydatetime = convertDateTimeISO (createReserveSO.End_Date__c) ;//String.ValueOf(createReserveSO.End_Date__c);

                                        } else {

                                            JSONResponse.expirydatetime = (dtNow == null) ? null : convertDateTimeISO(dtNow) ;
                                        }
    
                                    } catch (DmlException DE) {                        
    
                                        JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
                                        strReservesuccess       = 'No' ;
                                        strResultID             = 'CM004';
                                        strResultText           = 'Internal system error. Please try again or contact your local Customer Service Center.';
                                                                    
                                        System.debug('Exception Caught      : ' + DE.getMessage());
                                        System.debug('Exception type caught : ' + DE.getTypeName());    
                                        System.debug('Cause                 : ' + DE.getCause());    // returns null
                                        System.debug('Line number           : ' + DE.getLineNumber());    
                                        System.debug('Stack trace           : ' + DE.getStackTraceString());
                                        //return JSONResponse ;                            
                                    }
                                }                               
    
                            } else if (strResultID == null ) {   // Two case can be Possible.
    
                                if (reserveamount < 0) {
                                    
                                    JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
                                    strReservesuccess       = 'No' ;
                                    strResultID             = 'CM007';
                                    strResultText           = 'Your request cannot be fulfilled for the given criteria. ' + 'Reserve Amount Not Valid.';  
    
                                } else {        // reserveamount gratert than wallet balance.
    
                                    JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
                                    strReservesuccess       = 'No' ;
                                    strResultID             = 'RS001';
                                    strResultText           = 'Unable to reserve due to insufficient wallet balance.';  
                                }
                            } else {
    
                                // Do nothing.
                            }
                            system.debug('strResultID '+strResultID);
                            //-----------------------------------------------------
                            // Update Wallet then
                            //--------------------------------------------------------------
    
                            if (reserveamount > 0  && reserveamount != null && strResultID == 'CM000') {
    
                                system.debug('Changing Wallet Balance');
    
                                walletSO.Wallet_Balance__c = walletSO.Wallet_Balance__c - reserveamount ; // decimal.ValueOf(reserveamount);
                                
                                try {
                                    
                                    system.debug('updating Wallet Balance');
                                    update walletSO ;
                                    
                                    JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
    
                                } catch (DmlException DE) {
                                    
                                    strReservesuccess       = 'No' ;
                                    strResultID             = 'CM004';
                                    strResultText           = 'Internal system error. Please try again or contact your local Customer Service Center.';
    
                                    System.debug('Exception Caught      : ' + DE.getMessage());
                                    System.debug('Exception type caught : ' + DE.getTypeName());    
                                    System.debug('Cause                 : ' + DE.getCause());    // returns null
                                    System.debug('Line number           : ' + DE.getLineNumber());    
                                    System.debug('Stack trace           : ' + DE.getStackTraceString());
                                    //return JSONResponse ;
                                }
                            } else if (strResultID == 'CM000') { 
                                JSONResponse.currentbalance = walletSO.Wallet_Balance__c;
                                strReservesuccess       = 'No' ;
                                strResultID             = 'CM007';
                                strResultText           = 'Your request cannot be fulfilled for the given criteria.' + ' Reserve Amount Not Valid';
                            } else {
                                // Do nothing
                            }
    
                        } else { 
                            system.debug('WalletId null');                        
                            
                            strReservesuccess       = 'No' ;
                            strResultID             = 'CM007';
                            strResultText           = 'Your request cannot be fulfilled for the given criteria. : \' '+ AssetLnID + ' value for element \'AssetLnID\' not supported.' + ' Beacuse Wallet is not available this Asset';
                            //return JSONResponse ;
                        }
                    } else { 
                        
                        //JSONResponse.errorcode      = 'Missing Information';
                        //JSONResponse.message        = 'SubscriberCode Invalid and hence No Participating Point Found' ;
                        strReservesuccess       = 'No' ;
                        strResultID             = 'SC007';
                        strResultText           = 'Subscriber validation failed. Please contact your D&B Representative or your local Customer Service Center.';
                        //return JSONResponse ;
                    }            
    
                } else if (strResultID == null) {
                    strReservesuccess       = 'No' ;
                    strResultID             = 'CM014';
                    strResultText           = 'Invalid productid provided in the request. Please refer to Online Documentation. ' + productid + ' Value for element \'productid\' not supported.'  ;
                            
                } else {
                    
                    // Do nothing already set.
                }      
                
            }
        }     

        system.debug('JSONResponse '+ JSONResponse);
        sendResponse (StrReservesuccess,strResultID,strResultText);
        

    }

    public static void sendResponse(String StrReservesuccessSend ,string strResultIDSend ,string strResultTextSend) {
        
        JSONResponse.reservesuccess =  StrReservesuccessSend;
        JSONResponse.errorcode      =  strResultIDSend;
        JSONResponse.message        =  strResultTextSend ;  
        system.debug('JSONResponse '+ JSONResponse);
        strResponseJSON = JSON.serialize(JSONResponse);
        system.debug('strResponseJSON '+strResponseJSON);
        //strResponseJSON = strResponseJSON.replaceAll('\"[^\"]*\" : null,','');  // As per hari request to remove null.
        if(strResponseJSON != null)   {
      strResponseJSON = strResponseJSON.replaceAll('\"[^\"]*\":null',''); //basic removeal of null values
      strResponseJSON = strResponseJSON.replaceAll(',{2,}', ','); //remove duplicate/multiple commas
      strResponseJSON = strResponseJSON.replace('{,', '{'); //prevent opening brace from having a comma after it
      strResponseJSON = strResponseJSON.replace(',}', '}'); //prevent closing brace from having a comma before it
      strResponseJSON = strResponseJSON.replace('[,', '['); //prevent opening bracket from having a comma after it
      strResponseJSON = strResponseJSON.replace(',]', ']'); //prevent closing bracket from having a comma before it
      }
        system.debug('strResponseJSON '+strResponseJSON);
        
        if (strResultID == 'CM000') {
            RestContext.response.statuscode = 200;
        }else if(strResultID == 'CM001' || 
                 strResultID == 'CM002' || 
                 strResultID == 'CM003' ||                 
                 strResultID == 'CM014' || 
                 strResultID == 'RS001' ){
            RestContext.response.statuscode = 400;
        } else if(strResultID == 'CM007'){
           RestContext.response.statuscode = 404;               
        }else if(strResultID == 'SC007'){
            RestContext.response.statuscode = 401;            
        } else if(strResultID == 'CM004'){
            RestContext.response.statuscode = 500;            
        }     

        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(strResponseJSON);
    }


    // Validate JSON Request String to check if any required element is missing
    public static void doValidateJSONReqeust(){

        if(JSONRequest.subscribernumber == null || JSONRequest.subscribernumber == '' ){
            strReservesuccess       = 'No' ;
            blnRequiredDataMissing = true;
            strResultID = 'CM003';
            strResultText = 'Missing Information in the request. Request Missing required element: \'subscribernumber\'.';
        
        }else if(JSONRequest.reserveamount == null){
            strReservesuccess       = 'No' ;
            blnRequiredDataMissing = true;
            strResultID = 'CM003';
            strResultText = 'Missing Information in the request. Request Missing required element: \'reserveamount\'.';
        
        }else if(JSONRequest.currencycode == null || JSONRequest.currencycode == ''){
            strReservesuccess       = 'No' ;
            blnRequiredDataMissing = true;
            strResultID = 'CM003';
            strResultText = 'Missing Information in the request. Request Missing required element: \'currencycode\'.';
        
        }else if(String.isBlank(JSONRequest.productid) ){
            strReservesuccess       = 'No' ;
            blnRequiredDataMissing = true;
            strResultID = 'CM003';
            strResultText = 'Missing Information in the request. Request Missing required element: \'productid\'.';
        
        }
        

    }        

    // Convert DateTime to ISO 8601 DateTime format
    public static string convertDateTimeISO(DateTime dtValue){

        string strConvertedValue = dtValue.format('yyyy-MM-dd\'T\'hh:mm:ss.SSSXXX');

        return strConvertedValue;
    } 


    //----- Request JSON -------//
    global class REQ_CreateReserveService_JSON{
        
        /*
        {
          "subscribernumber" : "500000246",
          "reserveamount" : 10  ,
          "currencycode" : "CAD",
          "expirydatetime" : "",
          "productid" : "338"
        }
        */

        public String  subscribernumber ;
        //public String  productcode ;
        public String  reserveamount ;
        public String  currencycode ;
        public String  expirydatetime ;
        public String  productid ;
        
    }
    
    //----- Response JSON -------//
    global class RES_CreateReserveService_JSON{
        
        /*This field indicates if the reserve was a success (or) fail */
        public String reservesuccess ;
        
        /*This is the salesforce Id for the Reserve object that gets created */
        public String reserveID ;
        
        /*This provides the description of the error */
        public String message ;
        
        /*This will return the expiry date and time of the reserve. 
         * This will be returned only when the reserve is successful
         */ 
        public String expirydatetime;
        
        /*Currency will be based on the input parameter and the wallet currency. 
         * This will be returned only when the reserve is successful
         */ 
        public String currencycode ;        
        
        /*If reservation successful = ‘Yes’, then current balance = Original Balance minus reserve amount. 
         * If reservation successful = ‘No’ , then current balance = original balance. 
         * Current Balance would be returned ONLY if the reserve creation failed.
         */
        public Decimal currentbalance ;
        
        /*When the reserve is not successful, an error code will be sent back to Services */
        public String errorcode ;
        
        
    }

}