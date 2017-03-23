/*
Author : Tejas Kapasi
Description : RestFul Service for GetBalance API.
Hold the Response in APTS_GetBalance_ResponseHandler class
@changed : 14-08 : instead of Feature__c -> Product__c

1. Authentication : 
https://test.salesforce.com/services/oauth2/token

form-data
grant_type -> password
client_id -> 3MVG9dPGzpc3kWydTliia4eMn9r5o9glATpuFWLbnZ7Ay2GY5GjyruWNeFfnOWjGGd2yCzcy8XN62J90MTXhP
client_secret -> 3207349938930344659
username -> ryavari@dnb.com.qtc
password -> ramin!@#456v94s1hpzm4oEdTelXi4DtdazS

{
    "id": "https://test.salesforce.com/id/00De0000005Vi7YEAS/005e0000002QBiUAAW",
    "issued_at": "1435205660887",
    "token_type": "Bearer",
    "instance_url": "https://cs15.salesforce.com",
    "signature": "b1A9ezm9lUs40562DWl0BqSBuvhyqHAkpD0rDkT1kXE=",
    "access_token": "00De0000005Vi7Y!ARsAQDYjHINrxfmZL.JsKlTUZ36qc4LNOU4S4t1FxU.1zIJ2EpzLCIUMZWPH8rP4AJmdfk4mYm1WOv6.AD2aCt6DRwvFgXyz"
}
----------------------------------------------

2. Access to GetBalance Service

End Point POST Request : https://cs15.salesforce.com/services/apexrest/APTS_GetBalanceService/
Header Parameters : 
Authorization -> Bearer 00De0000005Vi7Y!ARsAQDYjHINrxfmZL.JsKlTUZ36qc4LNOU4S4t1FxU.1zIJ2EpzLCIUMZWPH8rP4AJmdfk4mYm1WOv6.AD2aCt6DRwvFgXyz
Content-Type  -> application/json

Input Parameters as JSON
{
  "subscriberNumber" : "500,000,095",
  "productCode" : "ABC123",
  "countryCode" : "US"  
}

--------
{
  "TotalUsage": 0,
  "Status": "Yes",
  "ReserveAmount": 0,
  "PromotionalAmount": 1000,
  "Message": "",
  "LastModifiedDateTime": "2015-07-13T10:10:11.000-07:00",
  "InvestedAmount": 510.8,
  "ExpirationOption": "Auto Renewal",
  "ErrorCode": "",
  "DomesticUnlimited": 0,
  "AgreementEndDate": "2015-07-31T12:00:00.000-07:00"
}

*/

@RestResource (urlMapping='/APTS_GetBalanceService/*')
global class APTS_REST_GetBalanceService {
    
    public static String sErrorContainer;

    //====================================================================================
    // *** REST POST *** : Require field should not be empty, method to post a new Contact
    //====================================================================================
    
    @HttpPost
    global static APTS_GetBalance_ResponseHandler post(String subscriberNumber , String  productCode , String countryCode) {
        subscriberNumber = subscriberNumber.remove(',');
        APTS_GetBalance_ResponseHandler response = new APTS_GetBalance_ResponseHandler();
        try {
            
            /* Prepare Response Result Here */
            /* Queying Participatig Point such that we get 2 ALI / 2 Participating point records*/                      

            List<APTS_Participating_Point__c> listpp = prepareALIfromParticipatingPoint (decimal.valueOf(subscriberNumber), productCode) ;
            Id assetLineId ;

            if (!listpp.isEmpty() && sErrorContainer == null) {

                assetLineId = listpp[0].APTS_Asset_Line_Item__c ;

                
                if (assetLineId != null || assetLineId != '') {
                    
                    Apttus_Config2__AssetLineItem__c AssetLnSo = [select Id,Name,Apttus_Config2__EndDate__c ,WalletID__c,WalletID__r.LastModifiedDate,
                                                                        WalletID__r.Total_Usage_Consumed__c,WalletID__r.Order_Start_Date__c,WalletID__r.Order_End_Date__c,WalletID__r.Total_Reserve_Amount__c,
                                                                        WalletID__r.Total_Flexible_Amount__c,WalletID__r.Total_Investment_Amount__c,
                                                                        Apttus_Config2__AttributeValueId__r.APTS_Expiration_Option__c,
                                                                        Apttus_Config2__AttributeValueId__r.Number_of_Terms__c
                                                                FROM Apttus_Config2__AssetLineItem__c 
                                                                WHERE Id =: assetLineId];
                    //WalletID__r.Domestic_Unlimited_Fee__c
                    //List<Apttus_Config2__AssetAttributeValue__c> assetAttriValues = AssetLnSo.Apttus_Config2__AssetAttributeValues__r ;

                    system.debug('AssetLnSo '+AssetLnSo.WalletID__r.Order_Start_Date__c + '  ' + AssetLnSo.WalletID__r.Order_End_Date__c);
                    
                    //response.AgreementEndDate = String.ValueOf(AssetLnSo.Apttus_Config2__EndDate__c) ; //'01/06/2015';
                    //response.ExpirationOption = assetAttriValues[0].APTS_Expiration_Option__c;     
                      
                    
                    system.debug('response.TotalUsage   '+response.TotalUsage);
                    system.debug('AssetLnSo.WalletID__c '+AssetLnSo.WalletID__c);
                    
                    if (AssetLnSo.WalletID__c != null) {
                        
                        system.debug('Wallet Id Found '+AssetLnSo.WalletID__c);

                        //------------------- Most of the response fields comming from Wallet itself -----------------//

                        response.PromotionalAmount      = AssetLnSo.WalletID__r.Total_Flexible_Amount__c;
                        response.InvestedAmount         = AssetLnSo.WalletID__r.Total_Investment_Amount__c;
                        response.AgreementEndDate       = convertDateISO(AssetLnSo.WalletID__r.Order_End_Date__c);//String.ValueOf(AssetLnSo.WalletID__r.Order_End_Date__c) ; //'01/06/2015';
                        response.TotalUsage             = AssetLnSo.WalletID__r.Total_Usage_Consumed__c; 
                        response.LastModifiedDateTime   = convertDateTimeISO(AssetLnSo.WalletID__r.LastModifiedDate);//String.ValueOf(AssetLnSo.WalletID__r.LastModifiedDate) ; 
                        response.ReserveAmount          = AssetLnSo.WalletID__r.Total_Reserve_Amount__c;
                        response.ExpirationOption       = AssetLnSo.Apttus_Config2__AttributeValueId__r.APTS_Expiration_Option__c;
                        response.AgrrementNumberOfTerms = AssetLnSo.Apttus_Config2__AttributeValueId__r.Number_of_Terms__c;
                        response.AgreementStartDate     = convertDateISO(AssetLnSo.WalletID__r.Order_Start_Date__c);
                        //response.DomesticUnlimited      = AssetLnSo.WalletID__r.Domestic_Unlimited_Fee__c ; //0; /* Changed on 20-07 */
                        response.DomesticUnlimited      = 0 ;
                        response.Status                 = 'Yes';
                                                
                    } else {

                        response.Status = 'No';
                        response.ErrorCode = 'Missing Information';
                        sErrorContainer = 'Wallet Not Associated to the Asset Line' ;
                        response.Message = sErrorContainer ;
                        system.debug('Some Error');
                    }
                } else {

                    response.Status = 'No';
                    response.ErrorCode = 'Missing Information';
                    sErrorContainer = 'No Asset Line Item Found for this Subscriber No';      
                    response.Message = sErrorContainer ;
                }
                
            } else {

                response.Status = 'No';
                response.ErrorCode = 'Invalid Information';
                //sErrorContainer = 'No Participating Point Found for this Subscriber No';  
                response.Message = sErrorContainer ;
            }

            
            
            
        } catch(Exception E) {
            //Add custom error code when you could not insert a record
            //response.ErrorCode = '';
            response.Status = 'No';
            response.Message = e.getMessage();
            System.debug('Exception Caught      : ' +e.getMessage());            
            System.debug('Exception type caught : ' + E.getTypeName());    
            System.debug('Cause                 : ' + E.getCause());    
            System.debug('Line number           : ' + E.getLineNumber());    
            System.debug('Stack trace           : ' + E.getStackTraceString()); 
        }
        return response;   
    }

    
    private static List<APTS_Participating_Point__c> prepareALIfromParticipatingPoint (Decimal subscriberNumber , String productCode){

        List<APTS_Participating_Point__c> listParticipatingPoint = new List<APTS_Participating_Point__c> ();
        List<Product_Code_Feature_mapping__c> listProdFeatureMapping = new List<Product_Code_Feature_mapping__c>();
        try {

            if (productCode != '' && productCode != null) {

                try { 

                    listProdFeatureMapping = [Select Id, Name,Product__c ,Product_Code_GIR__c FROM Product_Code_Feature_mapping__c WHERE Product_Code_GIR__c =: productCode ] ;
                    
                    if (listProdFeatureMapping.isEmpty()) {

                        sErrorContainer = 'No Record found for this Product Code no';            
                        system.debug('Exception Caught For Product Feature Mapping');
                    }

                } catch (QueryException QEP) {

                    sErrorContainer = 'Error Occured while Qerying using this Product Code no';            
                    system.debug('Exception Caught ' + QEP.getMessage());
                }

                if (!listProdFeatureMapping.isEmpty() && sErrorContainer == null) {
                    system.debug('listProdFeatureMapping '+listProdFeatureMapping);
                    system.debug('listProdFeatureMapping '+listProdFeatureMapping[0].Product__c );
                        
                    try { 
                        listParticipatingPoint = [Select Id, Name,APTS_Subscriber_No__c,APTS_Asset_Line_Item__c,APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c,
                                        APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c
                                      FROM APTS_Participating_Point__c
                                      WHERE APTS_Subscriber_No__c =: subscriberNumber  
                                      AND ( APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'New' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'Renewed' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'Incremented' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'Amended')
                                      AND  Product__c =: listProdFeatureMapping[0].Product__c 
                                      ORDER BY CreatedDate DESC ]; 

                        if (listParticipatingPoint.isEmpty()) {

                            sErrorContainer = 'No Partcipating point Found For this Subscriber No';            
                            system.debug('Exception Caught No PP Found');
                        }
                                
                    } catch (QueryException QEPP) {

                            sErrorContainer = 'Error Occured while Qerying using this Subscriber No';            
                            system.debug('Exception Caught ' + QEPP.getMessage());

                    }

                } else {

                    sErrorContainer = 'Error Occured Because No Record Found for Product Code In Product Feature Mapping.';            
                    system.debug('Exception Caught ');

                }

            } else {

                try {

                    listParticipatingPoint = [Select Id, Name,APTS_Subscriber_No__c,APTS_Asset_Line_Item__c,APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c,
                                        APTS_Asset_Line_Item__r.Apttus_Config2__LineType__c
                                      FROM APTS_Participating_Point__c
                                      WHERE 
                                      APTS_Subscriber_No__c =: subscriberNumber
                                      AND ( APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'New' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'Renewed' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'Incremented' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'Amended' OR APTS_Asset_Line_Item__r.Apttus_Config2__AssetStatus__c = 'Existing')
                                      ORDER BY CreatedDate DESC ]; 
                
                } catch (QueryException QE) {

                    sErrorContainer = 'Error Occured while Qerying using this Subscriber no';            
                    system.debug('Exception Caught ' + QE.getMessage());
                }
                

            }
            
        } catch (Exception E) {
            sErrorContainer = 'Error Occured while Qerying using this Subscriber no And Product Code';
            
            system.debug('Exception Caught ' + E.getMessage());
        }
        
        system.debug('listParticipatingPoint --> '+listParticipatingPoint.size());
        system.debug('listParticipatingPoint --> '+listParticipatingPoint);

        return  listParticipatingPoint ;           

    }  
    
    public static string convertDateISO(Date dValue){

        string strConvertedValue = DateTime.newInstance(dValue, Time.newInstance(0,0,0,0)).format('yyyy-MM-dd\'T\'hh:mm:ss.SSSXXX');

        return strConvertedValue;
    }

    // Convert DateTime to ISO 8601 DateTime format
    public static string convertDateTimeISO(DateTime dtValue){

        string strConvertedValue = dtValue.format('yyyy-MM-dd\'T\'hh:mm:ss.SSSXXX');

        return strConvertedValue;
    }  


}