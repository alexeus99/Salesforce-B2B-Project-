public class ProposalLwcController {
// get proposals for current Opportunity using pageId 
@AuraEnabled(cacheable=true) 
public static List<Proposal__c> getProposals(String OpportunityId) {
List<Proposal__c> props = [SELECT Id, Name, Total_Price__c, Status__c FROM Proposal__c WHERE Opportunity__c = :OpportunityId];
    return props;
}

// get all equipment categories 
@AuraEnabled(cacheable=true) 
public static List<Equipment_Category__c> getCategories() {
    List <Equipment_Category__c> catList = [SELECT Id, Name FROM Equipment_Category__c];
    return catList;
}

// guerry equipments using categoryId and String input 
@AuraEnabled(cacheable=true)
public static List <Equipment__c> getEquipment(String categoryId, String input) {
    system.debug(categoryId); 
    List <Equipment__c> equipList = new List <Equipment__c>();
    String search = input + '%';
    if (input != null && input != '' && categoryId != null && categoryId != '') {
         equipList = [SELECT Id, Name,Cost__c,  Equipment_Category__r.Name FROM Equipment__c WHERE Equipment_Category__c = :categoryId AND  Name LIKE :search];
    }
   else if (categoryId != null && categoryId != '') {
    equipList = [SELECT Id, Name,Cost__c,  Equipment_Category__r.Name FROM Equipment__c WHERE Equipment_Category__c = :categoryId];
   }
   else if (input != null && input != '') {
    equipList = [SELECT Id, Name,Cost__c,  Equipment_Category__r.Name FROM Equipment__c WHERE Name LIKE :search];
   }
   else {
    equipList = [SELECT Id, Name,Cost__c,  Equipment_Category__r.Name FROM Equipment__c ];
   }  
    system.debug(equipList);
    return equipList;
}

// Use PageReference to navigate user to a different page as result of an action method.
// Create new page and put proposalId to paraments of new page.
@AuraEnabled(cacheable=false)
    public static String generateProposal(Id proposalId)
    {       
     PageReference pageRef = new PageReference('/apex/previewer');  
        pageRef.getParameters().put('proposalId', proposalId); 
  String url = pageRef.getUrl(); 
  return url;
 }

// Use deleteProposal method to delete selected proposal from organization 
 @AuraEnabled
    public static String deleteProposal(Id proposalId)
    {
    List<Proposal__c> prop = [SELECT Id,Name FROM Proposal__c WHERE Id = :proposalId LIMIT 1];
    if (prop.size() > 0) {
        String deletedProposalName = prop[0].Name;  
    delete prop;
    return deletedProposalName;   
    }   
    return proposalId;
 }

// Creating new Proposal by using 2 paraments and wrapper class to convert JSON string to Object data.
// Creating new junction record ProposalEquipmentAssociation__c

@AuraEnabled(cacheable=false)
    public static string createProposal (String OpportunityId, String records) {
        List <proposalWrapper> wrapperList = (List<proposalWrapper>) System.JSON.deserialize(records,  List<proposalWrapper>.class);  // use deserialize to convert JS String to List of Apex Objects.   
        System.debug(wrapperList);
        List<Proposal__c> proposalToAdd = new List <Proposal__c>(); 
        Proposal__c newProposal = new Proposal__c();
        newProposal.Opportunity__c = OpportunityId;
        newProposal.Status__c = 'Draft';
        proposalToAdd.add(newProposal);
        insert proposalToAdd;
        List <ProposalEquipmentAssociation__c> junkList = new List <ProposalEquipmentAssociation__c>();
        for ( proposalWrapper wrap : wrapperList ) {
          ProposalEquipmentAssociation__c item = new ProposalEquipmentAssociation__c();
          item.Equipment__c	= wrap.EquipmentId;  // use EquipmentId from wrapperList .
          item.Quantity__c	=  1;
          item.Proposal__c = newProposal.Id;
          junkList.add(item);
        }
        insert junkList;
        String proposalId = String.valueOf(newProposal.Id); 
        return proposalId;  
    }

// use SendAttachment method to create example of email and send it by ising  Messaging.sendEmail method.
// use Blob  to work with DPF file and fill it by data. This data type converts the attachments into a single object  Blob body.
 @AuraEnabled(cacheable=true)
    public static string SendAttachment(String proposalId){
        Proposal__c propos = [SELECT Id,Name,Opportunity__r.Id FROM Proposal__c WHERE Id = :proposalId LIMIT 1];
        OpportunityContactRole cont = [SELECT Contact.Email FROM OpportunityContactRole WHERE OpportunityId = :propos.Opportunity__r.Id LIMIT 1];
        String contactEmail = cont.Contact.Email;
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage(); // create empty email
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment(); // create empty attachment
        PageReference pageRef = new PageReference('/apex/previewer');   // create example of PDF 
        pageRef.getParameters().put('proposalId', proposalId); // put proposal paraments for PDF
        String url = pageRef.getUrl(); 
        pageRef.setRedirect(true);
        Blob body =  pageRef.getContent(); 
        attach.setFileName('pdfPreview.pdf');
        attach.setBody(body);
        semail.setSubject('Here is yours Proposal Details');
        semail.setToAddresses(new List<String>{contactEmail}); // fill email adress
        semail.setPlainTextBody('Good day , dear Costumer. Here you can check PFD of our Proposal'); // fill email by text
        semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach}); // fill email by attachment
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail}); // send email 
        String message='Email sent successfully.';
        return message;
}

// create wrapper class to convert JSON data. Convert String from JS to Apex object.
public class proposalWrapper {
    @AuraEnabled
	public String EquipmentId;
    @AuraEnabled
    public Integer quantity;
    //public proposalWrapper(String Id) {
    //    this.EquipmentId = Id;
    //    this.quantity = 1;
    //}


}


}



