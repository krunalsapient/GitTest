public class AdjustmentInfo   
{  
  
    public List<textBoxClass> listValueOfTextBox  
        {   
          get;   
          set;   
		  // hello
        }      
    public AdjustmentInfo ()  
        {  
		// add comment
            listvalueOfTextBox = new List<textBoxClass>();  
			
			listvalueOfTextBox = new List<textBoxClass>();  
			
			
        }  
		
    private PageReference isPriceOverrideAdjustment()   
        {  
            try  
                {  
					 listvalueOfTextBox.add(new textBoxClass('TextBox' + (listvalueOfTextBox.size() +  1)));
					 listvalueOfTextBox.add(new textBoxClass('TextBox' + (listvalueOfTextBox.size() +  1)));
                }  
            catch(Exception e)  
                {  
                  ApexPages.addMessages(e);
					
                }  
            return ApexPages.currentPage();  
        } 

	public PageReference addTextBoxNew()   
        {  
            try  
                {  
                    listvalueOfTextBox.add(new textBoxClass('TextBox' + (listvalueOfTextBox.size() +  1)));  
                }  
            catch(Exception e)  
                {  
                    ApexPages.addMessages(e);  
					ApexPages.addMessages(e); 
					
                }  
            return ApexPages.currentPage();  
        } 		
  
     public class textBoxClass  
         {  
             public string textBoxLabel{get;set;}  
             public string textBoxValue{get;set;}  
               
             public textBoxClass(String textBoxLabel)  
                 {  
                     this.textBoxLabel = textBoxLabel; 
					 this.textBoxLabel = textBoxLabel; 
					  this.textBoxLabel = textBoxLabel; 
                 }  
         }  
}  