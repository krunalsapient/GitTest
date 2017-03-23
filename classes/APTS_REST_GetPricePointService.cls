/***************************************************************************
Name : Response Handler For Cretae Reserve API
Created By : Tejas Kapasi    
Description : Is In Progress to change Error COde and Message

CM000 : Success : 
CM001 : The given request is invalid.
CM002 : The format of this request is invalid. Please refer to Online Documentation.
CM003 : Missing Information in the request. : Result Description 1: Request missing required element: 'XXXXX'. 
CM004 : Internal system error. Please try again or contact your local Customer Service Center.
CM007 : Your request cannot be fulfilled for the given criteria. : Result Description 1: 'XXXXX' value for element 'YYYYY' not supported.
CM014 : Invalid Product  Code provided in the request. Please refer to Online Documentation. Result Description 1: 'XXXXX' value for element 'YYYYY' not supported.
ProductCode Invalid for Product Feature Mapping.
PP001  : Price not available for the requested Product(s).  Price not available for the following Product, Country Code combination: '<ProductCode1, CountryCode1>'
No Asset Usage Price Tier Found for Region : XXX And this ProductCode YYYY
***************************************************************************/

@RestResource (urlMapping='/APTS_GetPricePointService/*')
global class APTS_REST_GetPricePointService {
    
    global static REQ_GetPricePointService_JSON JSONRequest;
    global static RES_GetPricePointService_JSON JSONResponse;
    global static string strResultID, strResultText;
    global static string strRequestJSON, strResponseJSON ;
    global static Boolean blnRequiredDataMissing = false;
    global static Boolean blnTwoHundread, blnFourhundread , blnFourOFour, blnFiveHundread ,blnFourOone ;

    //====================================================================================
    // *** REST POST *** : Require field should not be empty
    //====================================================================================
    
    @HttpPost
    global static void dogetPricingPointPOST() {
        
        /***************************JSON Request**********************************/
        RestRequest req = RestContext.request;
        strRequestJSON = req.requestbody.tostring();
        
        
        // ------------------- First Check joson Request Validation Start ------------------------------//
        try{
    
            JSONRequest = (REQ_GetPricePointService_JSON)JSON.deserializeStrict(strRequestJSON, REQ_GetPricePointService_JSON.class);
            system.debug('JSONRequest '+JSONRequest);
        }Catch(JSONException JSEX){
            blnFourhundread = true;
            // Generate JSON Response to be sent Back
            JSONResponse = new RES_GetPricePointService_JSON();
            
            strResultID = 'CM002';
            strResultText = 'The format of this request is invalid. Please refer to Online Documentation. ' + JSEX.getMessage();
            JSONResponse.error = 'Yes' + ' : ' + strResultText ;
            system.debug(JSEX.getMessage());
        }    
        // ------------------- First Check joson Request Validation End ---------------------------------//
        
        // ----------------------------------------------------------------------------------------------//
        //----------        if JSON string is valid then perform Price point Service logic. -------------//
        // ----------------------------------------------------------------------------------------------//
        if( strResultID == null ){
            /* Calling Helper Function */
            APTS_REST_GetPricePointService.doGetPricePoint();
        }

        // --------------------- Prepeare Joson Response     ------------------//
        strResponseJSON = JSON.serialize(JSONResponse);

        //strResponseJSON = strResponseJSON.replaceAll('\"[^\"]*\" : null,','');  // As per hari request to remove null.
        if(strResponseJSON != null)   {
            strResponseJSON = strResponseJSON.replaceAll('\"[^\"]*\":null',''); //basic removeal of null values
            strResponseJSON = strResponseJSON.replaceAll(',{2,}', ','); //remove duplicate/multiple commas
            strResponseJSON = strResponseJSON.replace('{,', '{'); //prevent opening brace from having a comma after it
            strResponseJSON = strResponseJSON.replace(',}', '}'); //prevent closing brace from having a comma before it
            strResponseJSON = strResponseJSON.replace('[,', '['); //prevent opening bracket from having a comma after it
            strResponseJSON = strResponseJSON.replace(',]', ']'); //prevent closing bracket from having a comma before it
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(strResponseJSON);

        system.debug('blnFiveHundread' + blnFiveHundread);
        system.debug('blnFourOFour' + blnFourOFour);
        system.debug('blnFourOone'+ blnFourOone);
        system.debug('blnFourhundread' + blnFourhundread);
        system.debug('blnTwoHundread'+ blnTwoHundread);


        if(blnFiveHundread == true){
            RestContext.response.statuscode = 500;            
        }else if (blnFourOone == true) {
            RestContext.response.statuscode = 401;
        }else if(blnFourOFour == true){
            RestContext.response.statuscode = 404;
        }else if(blnFourhundread == true){
            RestContext.response.statuscode = 400;
        }else if (blnTwoHundread == true) {
            RestContext.response.statuscode = 200;
        } else {
            RestContext.response.statuscode = 500;
        }
        system.debug('RestContext.response '+RestContext.response);


    }    
   
    
    private static void doValidatingSubscriberID (String strErrorCode , String strErrorMessage) {

        if(JSONRequest.getPricing != null && !JSONRequest.getPricing.isEmpty() ){

            // Generate JSON Response to be sent Back
            JSONResponse = new RES_GetPricePointService_JSON();
            List<APTS_PricePointSubpriceDetails> listPP = new List<APTS_PricePointSubpriceDetails>();

            // Prepare Two Set Here From Input Json Request.
            for( APTS_PricePoint_SubGetPricing getPricingObj : JSONRequest.getPricing ){
                
                //-----  Response Object --------------//
                APTS_PricePointSubpriceDetails pricePointRespDetails = new APTS_PricePointSubpriceDetails();
                
                //---------------- Response Paramaeters ---------//
                pricePointRespDetails.dNBProductID          = getPricingObj.dNBProductID ;
                pricePointRespDetails.countryISOAlpha2Code  = getPricingObj.countryISOAlpha2Code ;                            
                pricePointRespDetails.errorcode             = strErrorCode ;
                pricePointRespDetails.message               = strErrorMessage ;
                system.debug('pricePointRespDetails '+pricePointRespDetails);
                listPP.add(pricePointRespDetails);

                JSONResponse.priceDetails = listPP;

            }    
        }   

        if (strErrorCode == 'SC007') {

            strResultID         = 'SC007';   // just to stop procced further.
            blnFourOone         =  true;
            system.debug('strResultID '+strResultID);
        } else {
            system.debug('strResultID '+strResultID);
            strResultID         = 'CM003';   // just to stop procced further.
            blnFourhundread     =  true;
        }
        
        JSONResponse.error  = 'Yes';                             
        system.debug('JSONResponse.error '+JSONResponse.error); 
    }

    
    //--- Actual Price point logic goes here doGetPricePoint --------//
    global static void doGetPricePoint(){
        system.debug('>>>>>>>>>>>>>>>>>>>> Inside doGetPricePoint LOGIC >>>>>>>>>>>>>>>>>>>');
           
        try {
            Decimal subscribernumber ; 
            Set<String> setcountryISOAlpha2Code                     = new Set<String>();
            Set<String> setdNBProductID                             = new Set<String>();            
            List<Country_Group__c> listCoutryGroup                  = new List<Country_Group__c>();
            Map<String,String> mapCountryRegion                     = new Map<String,String>();
            List<Product_Code_Feature_mapping__c> listProdFchrMpng  = new List<Product_Code_Feature_mapping__c>();
            Map<String,String> mapProdCodeFeatureId                 = new Map<String,String>();
            List<APTS_Participating_Point__c> listParticipatingPnt  = new List<APTS_Participating_Point__c>();
            Set<ID> setAssetLnId                                    = new Set<ID>();
            Map<String,String> mapSubscriberFeatrAssetLnId          = new Map<String,String>();
            List<Apttus_Config2__AssetUsagePriceTier__c> listAssetPt= new List<Apttus_Config2__AssetUsagePriceTier__c>();
            Map<String,List<Apttus_Config2__AssetUsagePriceTier__c>> mapAssetAndAssetUPTR = new Map<String,List<Apttus_Config2__AssetUsagePriceTier__c>>();
            
            // Generate JSON Response to be sent Back
            JSONResponse = new RES_GetPricePointService_JSON();
            List<APTS_PricePointSubpriceDetails> listPP = new List<APTS_PricePointSubpriceDetails>();
            
            // Subscriber number Check 
            if(JSONRequest.subscribernumber != null && JSONRequest.subscribernumber != ''){

                //subscribernumber = JSONRequest.subscribernumber.remove(',') ;      // if they entered subscribernumber including , 
                system.debug('Subscriber number : '+JSONRequest.subscribernumber);
                
                try {
                    
                    subscribernumber = Decimal.ValueOF(JSONRequest.subscribernumber)   ;
                    
                } catch (TypeException TE) {
                    system.debug('Decimal Exception');                    
                    doValidatingSubscriberID ('SC007','Subscriber validation failed.  Please contact your D&B Representative or your local Customer Service Center.');
                }
                
            } else {
                system.debug('null Exception');    
                doValidatingSubscriberID ('CM003','Missing Information in the request. Request Missing required element: \'subscribernumber\'.') ;
                                
            }
            
            
            //Create two set of ProductId and CountryIsoAlphaCode
            if(JSONRequest.getPricing != null && !JSONRequest.getPricing.isEmpty() && strResultID == null){
                system.debug('JSONRequest.getPricing '+JSONRequest.getPricing);
                // Prepare Two Set Here From Input Json Request.
                for( APTS_PricePoint_SubGetPricing getPricingObj : JSONRequest.getPricing ){
                    system.debug('getPricingObj '+ getPricingObj);
                    // set1 ISOAlpha2code
                    if(getPricingObj.countryISOAlpha2Code != null && getPricingObj.countryISOAlpha2Code != ''){
                    
                        setcountryISOAlpha2Code.add(getPricingObj.countryISOAlpha2Code);    // Prepare Set 1
                    }
                    // set 2 ProductId
                    if(getPricingObj.dNBProductID != null && getPricingObj.dNBProductID != '' ){
                        
                        setdNBProductID.add(getPricingObj.dNBProductID);    // Prepares Set 2
                           
                    }
                }    
            } else {
                
                // Because if error occured during first check of subscribernumber then we dont need to override that.
                if (strResultID == null) {
                    strResultID         = 'CM003';
                    strResultText       = 'Missing Information in the request. Request Missing required element: \'getPricing\'.';
                    JSONResponse.error  = 'Yes' + ' : ' + strResultText;
                    blnFourhundread     =  true; 
                    system.debug('JSONResponse.error '+JSONResponse.error);
                } 
                //blnFourOone = true ;
            }    
            system.debug('FIRST set countryISOAlpha2Code -->'+ setcountryISOAlpha2Code);
            system.debug('SECOND set dNBProductID --> '+ setdNBProductID);
        
            // 1)   Get Region using country ISOAlpha2code 
            if (strResultID == null) {
                listCoutryGroup =  [SELECT Id,Name,Regions__c,Country_Code__c FROM Country_Group__c WHERE Country_Code__c In : setcountryISOAlpha2Code];
                system.debug('list CoutryGroup where countrycode in setcountryISOAlpha2Code : '+listCoutryGroup);
                
                // prepare map1 for this countryIso -> Region
                if (!listCoutryGroup.isEmpty()) {
                    
                    for (Country_Group__c cntrygrp :listCoutryGroup) {
                        
                        mapCountryRegion.put(cntrygrp.Country_Code__c,cntrygrp.Regions__c);
                    }   
                } 
                system.debug(' mapCountryRegion ' + mapCountryRegion);
            }
             

            // 2)   Get Feature Id from product code
            if (strResultID == null) {
                listProdFchrMpng = [SELECT Id,Product__c,Product_Code_GIR__c FROM Product_Code_Feature_mapping__c WHERE Product_Code_GIR__c In : setdNBProductID ];
                system.debug('listProdFchrMpng Where Product_Code_GIR__c In setdNBProductID : '+listProdFchrMpng);
                
                // prepare map2 for this product code -> Feature Id
                if (!listProdFchrMpng.isEmpty()) {
                    
                    for (Product_Code_Feature_mapping__c prdFtrMap :listProdFchrMpng) {
    
                        mapProdCodeFeatureId.put(prdFtrMap.Product_Code_GIR__c,prdFtrMap.Product__c);
                    }   
                }
                system.debug(' mapProdCodeFeatureId ' + mapProdCodeFeatureId);
            }
            

            // 3)   Get Asset Line from Subsciber ID and Feature ID—Make sure you get the correct Asset i.e. using Asset status field
            if (strResultID == null) {
                listParticipatingPnt = [SELECT Id,APTS_Subscriber_No__c,Product__c,APTS_Asset_Line_Item__c,APTS_Asset_Line_Item__r.WalletID__c 
                                        FROM APTS_Participating_Point__c 
                                        WHERE APTS_Subscriber_No__c  =: subscribernumber  
                                        AND Product__c In : mapProdCodeFeatureId.Values() 
                                        ];
                system.debug('listParticipatingPnt where Subscriber no and product id in value of this mapProdCodeFeatureId '+listParticipatingPnt); 
                // all pp and collect AssetLineId Set.
                // set3 assetln Ids
                // prepare map3 subscriberId-FeatureId -> AssetLnId
                if (!listParticipatingPnt.isEmpty()) {
    
                    for (APTS_Participating_Point__c PP : listParticipatingPnt) {
    
                        setAssetLnId.add(PP.APTS_Asset_Line_Item__c);
                        mapSubscriberFeatrAssetLnId.put(PP.APTS_Subscriber_No__c+PP.Product__c,PP.APTS_Asset_Line_Item__c);
                    }    
                }   
                system.debug('setAssetLnId '+setAssetLnId);
                system.debug('mapSubscriberFeatrAssetLnId '+mapSubscriberFeatrAssetLnId);
            }
           
            // 4)   Get Price from Asset Usage Tiers using asset line, region, and product code
            if (strResultID == null) {
                listAssetPt = [SELECT Id,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__Dimension1Value__c,
                                CurrencyIsoCode,
                                Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__Dimension2Value__c
                                FROM Apttus_Config2__AssetUsagePriceTier__c 
                                WHERE Apttus_Config2__AssetLineItemId__c IN : setAssetLnId
                                AND Apttus_Config2__Dimension1Value__c IN : mapCountryRegion.Values() 
                                AND Apttus_Config2__Dimension2Value__c IN :setdNBProductID
                            ];            
                system.debug('listAssetPt Where asset Id in set and dimension1 and 5 value in map and set'+ listAssetPt);
                
                //prepeare map of Asset and its usage price tier.
                if (!listAssetPt.isEmpty()) {
    
                    Set<Id> setAssetId = new Set<Id>();
                    
                    for (Apttus_Config2__AssetUsagePriceTier__c astUsagePtr :listAssetPt) {
    
                        setAssetId.add(astUsagePtr.Apttus_Config2__AssetLineItemId__c);
    
                        if (!mapAssetAndAssetUPTR.containskey(astUsagePtr.Apttus_Config2__AssetLineItemId__c)) {
                            
                            List<Apttus_Config2__AssetUsagePriceTier__c> localList = new List<Apttus_Config2__AssetUsagePriceTier__c>();
                            localList.add(astUsagePtr);
                            mapAssetAndAssetUPTR.put(astUsagePtr.Apttus_Config2__AssetLineItemId__c,localList);
    
                        } else {
                            
                            List<Apttus_Config2__AssetUsagePriceTier__c> allReadyUsageTier = new  List<Apttus_Config2__AssetUsagePriceTier__c>();
                            allReadyUsageTier = mapAssetAndAssetUPTR.get(astUsagePtr.Apttus_Config2__AssetLineItemId__c);
                            allReadyUsageTier.add(astUsagePtr);
                            mapAssetAndAssetUPTR.put(astUsagePtr.Apttus_Config2__AssetLineItemId__c,allReadyUsageTier);
                        }
                    }
                }
                system.debug('mapAssetAndAssetUPTR '+mapAssetAndAssetUPTR);
            }
            
            //------ Now Prepare Output or Process Logic to Find Out Exact Equivalent OutPut ---//
            
            if(JSONRequest.getPricing != null && !JSONRequest.getPricing.isEmpty() && strResultID == null){                
                
                system.debug('***********************   Actual Logic starting ******************************');
                // Iterate through each Pricing Detail and Prepare Result.
                for( APTS_PricePoint_SubGetPricing getPricingObj : JSONRequest.getPricing ) {
                    
                    //-----  Response Object --------------//
                    APTS_PricePointSubpriceDetails pricePointRespDetails = new APTS_PricePointSubpriceDetails();
                    
                    String dNBProductID         = getPricingObj.dNBProductID; 
                    String countryISOAlpha2Code = getPricingObj.countryISOAlpha2Code;

                    system.debug('dNBProductID'+dNBProductID);
                    system.debug('countryISOAlpha2Code '+countryISOAlpha2Code);

                    String region    ;
                    String featureId ;
                    String assetId   ;
                    Decimal price    ;
                    String currencyCode ;

                    //-----  Set region --------------// 
                    if (mapCountryRegion.containskey(countryISOAlpha2Code) && strResultID == null) {

                        region    =  mapCountryRegion.get(countryISOAlpha2Code) ;

                    } else if (strResultID == null) {

                        JSONResponse.error      = 'Yes';
                        system.debug('JSONResponse.error '+JSONResponse.error);
                        strResultID             = 'CM001';// 23- 07 Changed 'CM007';
                        strResultText           = 'The given request is invalid. ' + 'Region Does not Found for this countryISOAlpha2Code';
                    }

                    //-----  Set featureId --------------// 
                    if (mapProdCodeFeatureId.containskey(dNBProductID) && strResultID == null) {

                        featureId =  mapProdCodeFeatureId.get(dNBProductID) ; // Actually ProductCode not salesforce ProductId(Feature)

                    } else if (strResultID == null){
                        
                        JSONResponse.error  = 'Yes';
                        system.debug('JSONResponse.error '+JSONResponse.error);
                        strResultID         = 'CM014';
                        strResultText       = 'Invalid Product  Code provided in the request. Please refer to Online Documentation.' + dNBProductID + ' value for element \'dNBProductID\' not supported.';
                    }

                    //-----  Set assetId --------------// 
                    if (mapSubscriberFeatrAssetLnId.containskey(subscribernumber+featureId) && strResultID == null) {

                        assetId   =  mapSubscriberFeatrAssetLnId.get(subscribernumber+featureId) ;

                    } else if (strResultID == null){
                        
                        JSONResponse.error  = 'Yes';
                        strResultID         = 'SC007';//'CM007';
                        strResultText       = 'Subscriber validation failed. Please contact your D&B Representative or your local Customer Service Center.';
                    }
                                       
                    
                    List<Apttus_Config2__AssetUsagePriceTier__c> listAssetPtr = new List<Apttus_Config2__AssetUsagePriceTier__c>();
                    
                    // Now Retrieve Asset usage price tier of this asset line id.
                    if (mapAssetAndAssetUPTR.containskey(assetId) && strResultID == null){

                        listAssetPtr = mapAssetAndAssetUPTR.get(assetId);
                    }else if (strResultID == null){
                        JSONResponse.error  = 'Yes';
                        system.debug('JSONResponse.error '+JSONResponse.error);
                        strResultID         = 'PP001';//'CM007';
                        strResultText       = 'Price not available for the following Product, Country Code combination: '+ 
                                              '<' + dNBProductID +',' +countryISOAlpha2Code + '>' ;
                    }
                    
                    
                    if (!listAssetPtr.isEmpty() && strResultID == null) {
                        String strCurrency = '';
                        for (Apttus_Config2__AssetUsagePriceTier__c auptr :listAssetPtr) {

                            if (auptr.Apttus_Config2__Dimension1Value__c == region && auptr.Apttus_Config2__Dimension2Value__c  == dNBProductID) {

                                price = auptr.Apttus_Config2__AdjustmentAmount__c;
                                strCurrency = auptr.CurrencyIsoCode ;
                                system.debug('auptr '+auptr);
                                system.debug('auptr '+auptr.CurrencyIsoCode);
                                //break;
                            } /*else {

                                JSONResponse.error = 'Yes';
                                strResultText = 'No Asset Usage Price Tier Found for Region : '+region + ' And this ProductCode '+ dNBProductID;
                            }*/

                        }

                        system.debug('price '+price);
                        if (price != null) {
                            currencyCode = strCurrency;
                            strResultID         = 'CM000';
                            strResultText       = 'Success';
                        }
                        if (price == null) {
                            JSONResponse.error  = 'Yes';
                            system.debug('JSONResponse.error '+JSONResponse.error);
                            strResultID         = 'PP001';
                            strResultText       = 'Price not available for the following Product, Country Code combination: ' + '<'+dNBProductID+','+countryISOAlpha2Code + '>';
                        }
                    } 

                    //---------------- Response Paramaeters ---------//
                    pricePointRespDetails.dNBProductID          = dNBProductID ;
                    pricePointRespDetails.countryISOAlpha2Code  = countryISOAlpha2Code ;
                    pricePointRespDetails.price                 = price;
                    pricePointRespDetails.currencyCode          = currencyCode;
                    pricePointRespDetails.errorcode             = strResultID ;
                    pricePointRespDetails.message               = strResultText;
                    system.debug('pricePointRespDetails '+pricePointRespDetails);
                    listPP.add(pricePointRespDetails);
                    if (strResultID == 'CM000') {
                        blnTwoHundread = true;
                    }else if(strResultID == 'CM001' || strResultID == 'CM002' || strResultID == 'CM003' || strResultID == 'PP001' || strResultID == 'CM014'){
                        blnFourhundread = true ;
                    }else if(strResultID == 'CM007'){
                        blnFourOFour = true;
                    }else if(strResultID == 'CM004'){
                        blnFiveHundread = true;            
                    }else if (strResultID == 'SC007') {
                        blnFourOone = true ;
                    }
                    strResultID         = null;
                    strResultText       = null;
                }
                    JSONResponse.priceDetails = listPP;
                system.debug('JSONResponse '+JSONResponse);
                
                system.debug('***********************   Actual Logic Ending  ******************************');
            }

        } catch (Exception E) {
            System.debug('Exception Caught      : ' + E.getMessage());
            System.debug('Exception type caught : ' + E.getTypeName());    
            System.debug('Cause                 : ' + E.getCause());    
            System.debug('Line number           : ' + E.getLineNumber());    
            System.debug('Stack trace           : ' + E.getStackTraceString());
            
        }
    }
    
    
    
    //----- Request JSON -------//
    global class REQ_GetPricePointService_JSON{
        
        public String subscribernumber = '';
        public List<APTS_PricePoint_SubGetPricing> getPricing = new List<APTS_PricePoint_SubGetPricing>();
        
    }
    
    //----- Response JSON -------//
    global class RES_GetPricePointService_JSON{
        
        public String error = 'No';
        public List<APTS_PricePointSubpriceDetails> priceDetails = new List<APTS_PricePointSubpriceDetails>();
        
    }

}