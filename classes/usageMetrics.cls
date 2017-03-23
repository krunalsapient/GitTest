public class usageMetrics
{
	public class MetricUsageData
	{
		//File Id
		String headerId { get;set;}

		// Actual File - Usage data (blob file)   
		String metricsDataFile {get;set;}
	 
		//Type of file
		String metricsDataFileContentType {get;set;}
		
		//File length
		Integer metricsDataFileLength {get;set;}
		
		//The date when the usage metrics collection job was run
		String metricsRunDate { get;set;}
		
		//The end time and date for the data collection
		String metricsEndDate {get;set;}
		
		//The start time and date for the data collection.
		String metricsStartDate { get;set;}
		
		//The type of data being collected. The possible values are CustomObject and Visualforce
		String metricsType {get;set;}
		
		//The namespace prefix of the package for which data is being collected. [App name]
		String namespacePrefix {get;set;}

		//The server instance from which this data was collected, for example, “na8.”
		String sendingInstance {get;set;}
	}
    
	public void execute(List<MetricsDataFile__C> fileList, boolean isScheduler)
	{
		System.debug('**Execute start***');
		Set<ID> metricsDataFileIds = getMetricsDataFileIds(fileList);
		Map<Id, List<Attachment>> mapUsageMetricsAttachment = getMetricsAttachment(metricsDataFileIds);
		
		Config_Metrics_Data_File__c configMetrics = Config_Metrics_Data_File__c.getInstance('Push');
		for(MetricsDataFile__c dataFile : fileList)
		{
            MetricsDataFile__c metricsDataFile = [select ID, MetricsDataFileContentType__C, MetricsDataFileLength__C FROM MetricsDataFile__C WHERE  ID =: dataFile.ID];
            
            MetricUsageData metricUsageData = new MetricUsageData(); 
            metricUsageData.headerId = metricsDataFile.ID;
            metricUsageData.metricsDataFile = getAttachment(mapUsageMetricsAttachment, metricsDataFile.Id);
            metricUsageData.metricsDataFileContentType = metricsDataFile.MetricsDataFileContentType__C;
            metricUsageData.metricsDataFileLength= 2000;
            /*metricUsageData.metricsRunDate= System.now().formatGmt('MM/dd/yyyy hh:mm a');
            metricUsageData.metricsEndDate= metricsDataFile.MetricsEndDate__C.formatGmt('MM/dd/yyyy hh:mm a');
            metricUsageData.metricsStartDate= metricsDataFile.MetricsStartDate__C.formatGmt('MM/dd/yyyy hh:mm a');
            metricUsageData.metricsType= metricsDataFile.MetricsType__C;
            metricUsageData.namespacePrefix= metricsDataFile.NamespacePrefix__C;
            metricUsageData.sendingInstance= metricsDataFile.SendingInstance__C;*/
            String jsonMetrics = JSON.serialize(metricUsageData);
            
            if(isScheduler)
            {
                sendData(jsonMetrics, metricsDataFile.ID);
                configMetrics.Last_Processed_Id__c = metricsDataFile.ID;
                upsert configMetrics;
            }
            else
            {
                sendDataFuture(jsonMetrics, metricsDataFile.ID);
            }
            
		}
	
	}
	
    private String getAttachment(Map<Id, List<Attachment>> mapUsageMetricsAttachment, String headerId )
    {
        if(mapUsageMetricsAttachment != null)
        {
            Attachment metricsAttachment = (mapUsageMetricsAttachment.get(headerId))[0];
            return (metricsAttachment.Body).toString();
        }
        return '';
    }
    
	private Set<ID> getMetricsDataFileIds(List<MetricsDataFile__C> metricDataFiles)
	{
		Set<ID> metricsDataFileIds = new Set<ID>();
		for(MetricsDataFile__c metricsDataFile : metricDataFiles)
		{
			metricsDataFileIds.add(metricsDataFile.Id);
		}
		return metricsDataFileIds;
    }
    
	private Map<Id, List<Attachment>> getMetricsAttachment(Set<ID> metricsDataFileIds)
	{
		Map<Id, List<Attachment>> mapUsageMetricsAttachment = new Map<Id, List<Attachment>>();
		if(metricsDataFileIds == null)
		{
			return mapUsageMetricsAttachment;
		}
		
		List<Attachment> attachments = [select ID, Body,ParentId from attachment where ParentId in : metricsDataFileIds];
		
		for(ID metricsDataFileId : metricsDataFileIds)
		{
			for(Attachment attachment : attachments)
			{
				if(attachment.ParentID == metricsDataFileId)
				{
					if(mapUsageMetricsAttachment.get(metricsDataFileId) == null)
					{
						List<Attachment> metricsAttachments = new List<Attachment> ();
						metricsAttachments.add(attachment);
						mapUsageMetricsAttachment.put(metricsDataFileId, metricsAttachments);
					}
					else
					{
						List<Attachment> metricsAttachments = mapUsageMetricsAttachment.get(metricsDataFileId);
						metricsAttachments.add(attachment);
						mapUsageMetricsAttachment.put(metricsDataFileId, metricsAttachments);
					}
				}
			}
		}
		return mapUsageMetricsAttachment;
	}
    
	@future(callout=true)
    private static void sendDataFuture(String jsonDataString, String headerId) 
    {
        sendData(jsonDataString, headerId);
    }
    
    private static void sendData(String jsonDataString, String headerId) 
    {  
        //System.debug('jsonDataString :' + jsonDataString);
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setTimeout(120000);
        
        Config_Metrics_Data_File__c configMetrics = Config_Metrics_Data_File__c.getInstance('Push');
        request.setEndpoint(configMetrics.Heroku_URL__c);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(jsonDataString);
        
        try 
        {
            Http http = new Http();
            HTTPResponse response = http.send(request);
            //VerifyResponse(response, headerId);
            System.debug('Status Code : ' + response.getStatusCode());
        } 
        catch (Exception e) 
        {
           /* MetricsDataFile_Status__c MdfStat = new MetricsDataFile_Status__c();
   		 	MdfStat.MetricsDataFileId__c = headerId;
    		MdfStat.Date_Processed__c  = System.now();
            MdfStat.Message__c = e.getMessage();
            MdfStat.FailCounter__c = 1;
            MdfStat.Trace__c = e.getStackTraceString();
			MdfStat.Comment__c = '';
            System.debug('Exception : ' + e);
            upsertFailureExists(MdfStat, false);   */ 
        }
    }
    
	/*private static void VerifyResponse(HTTPResponse response, string headerId)
	{
		Boolean isDataInserted = true;
		integer responseStatus = response.getStatusCode();
		MetricsDataFile_Status__c MdfStat = new MetricsDataFile_Status__c();
		MdfStat.MetricsDataFileId__c = headerId;
		MdfStat.Date_Processed__c  = System.now();
		MdfStat.FailCounter__c = 1;
		MdfStat.Comment__c = '';
		
		if(responseStatus != 200)
		{
			MdfStat.Message__c = string.valueof(responseStatus);
			MdfStat.Trace__c = '';
			isDataInserted = false;
		}
		else // If status is 200 (OK)
		{
			string responseJSON = response.getBody();
			if(responseJSON != null && responseJSON != '')
			{
				JSONParser parser = JSON.createParser(responseJSON);
				String status = '';
				while (parser.nextToken() != null) 
				{
					if ((parser.getCurrentToken() == JSONToken.FIELD_NAME))
					{
						String fieldName = parser.getText();
						parser.nextToken();
						if(fieldName == 'message') 
						{
							MdfStat.Message__c = parser.getText();
						} 
						else if(fieldName == 'trace')
						{
							MdfStat.Trace__c = parser.getText();
						}
						else if(fieldName == 'status')
						{
							status = parser.getText();
						}
					}
				}
				if(status == 'Fail')
				{
					isDataInserted = false;
				}
				else
				{
					isDataInserted = true;
				}
			}
			else
			{
				MdfStat.Message__c = '';
				MdfStat.Trace__c = '';
				isDataInserted = true;
			}
		}
		upsertFailureExists(MdfStat, isDataInserted);
	}
	  
	private static void upsertFailureExists(MetricsDataFile_Status__c metricsDataFileStatus, Boolean isDataInserted)
	{
		String headerId = metricsDataFileStatus.MetricsDataFileId__c;
        String query = 'SELECT Id, MetricsDataFileId__c, FailCounter__c FROM MetricsDataFile_Status__c Where MetricsDataFileId__c =: headerId';
        List<MetricsDataFile_Status__c> filestatus = Database.query(query);
        
		if(filestatus.size() > 0) //If data exists for same header id in failure, increment counter in case of isDataInserted = false else delete failure record;
		{
			if(isDataInserted) //Data Insertion Successfully
			{
				delete filestatus[0];
			}
			else
			{
                
				metricsDataFileStatus.FailCounter__c = filestatus[0].FailCounter__c + 1;
				metricsDataFileStatus.Id = filestatus[0].Id;
				upsert metricsDataFileStatus;
			}
        }
		else
        {
            if(!isDataInserted) //Data Insertion Successfully
			{
				insert metricsDataFileStatus;
            }
        }
         
	}*/
}