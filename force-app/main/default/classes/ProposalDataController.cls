
public with sharing class ProposalDataController {
public List<Account> accounts {get; set;}
public List<Contact> contacts {get;set;}  
public List<ProposalEquipmentAssociation__c> props {get;set;}
public Proposal__c proposal {get;set;}
public OpportunityContactRole contact {get;set;}
public Account account {get;set;}
public Decimal TotalCost {get;set;}
public List<ProposalEquipmentAssociation__c> itemList {get;set;}


public ProposalDataController() {
String proposalId = ApexPages.currentPage().getParameters().get('proposalId');

this.proposal = [SELECT  Opportunity__r.AccountId, Name
                FROM Proposal__c 
                WHERE Id = :proposalId 
                LIMIT 1];
                 
this.account = [SELECT Id, Name
                FROM Account 
                WHERE Id = :this.proposal.Opportunity__r.AccountId 
                LIMIT 1];
                           
String oppId = this.proposal.Opportunity__c;

this.contact = [SELECT Contact.Name, Contact.MailingCountry, Contact.MailingPostalCode, Contact.MailingState, Contact.MailingCity, Contact.MailingStreet, Contact.Email 
                FROM OpportunityContactRole 
                WHERE OpportunityId = :oppid 
                LIMIT 1];

this.itemList = [SELECT Name, Equipment__r.Name,Quantity__c, Equipment__r.Cost__c, Total_Price__c,Price__c
                                                   FROM ProposalEquipmentAssociation__c 
                                                   WHERE Proposal__r.id  = :proposalId ]; 
                                                                                                                                                                               

this.TotalCost = 0;
For (ProposalEquipmentAssociation__c i : itemList) 
{
 TotalCost += i.Total_Price__c.setScale(2);
}

}

}

 
    






   




    

          