public class BatchJob   
{  
  
    public List<textBoxClass> listValueOfTextBox  
        {   
          get;   
          set;   
        }      
    public AdjustmentInfo ()  
        {  
            listvalueOfTextBox = new List<textBoxClass>();  
			
			listvalueOfTextBox = new List<textBoxClass>();  
			
			
        }  
    public PageReference isPriceOverrideAdjustment()   
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
  
     public class HierViewUpdateRequest  
         {  
             public string textBoxLabel{get;set;}  
             public getHierarchyId(String textBoxLabel)  
                 {  
                     this.textBoxLabel = textBoxLabel; 
                 }  
         }  
}  