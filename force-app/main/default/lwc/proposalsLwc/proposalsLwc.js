import { LightningElement,wire,api, track } from 'lwc';
import getProposals from '@salesforce/apex/ProposalLwcController.getProposals';
import getCategories from '@salesforce/apex/ProposalLwcController.getCategories';
import getEquipment from '@salesforce/apex/ProposalLwcController.getEquipment';
import PROPOSAL_NAME from "@salesforce/schema/Proposal__c.Name";
import generateProposal from "@salesforce/apex/ProposalLwcController.generateProposal";
import deleteProposal from "@salesforce/apex/ProposalLwcController.deleteProposal";
import SendAttachment from "@salesforce/apex/ProposalLwcController.SendAttachment";
import createProposal from '@salesforce/apex/ProposalLwcController.createProposal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';



const columns = [
    { label: 'Name', fieldName: 'proposalNameURL', type: 'url', typeAttributes: {
        label: {fieldName: PROPOSAL_NAME.fieldApiName, target: "_black"}
    }
},
    { label: 'Total Price', fieldName: 'Total_Price__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c', type: 'text', cellAttributes: {
        alignment: 'right'
    } }, 
   
];


const columnsAddTable = [
    { label: 'Category', fieldName: 'categoryName', type: 'text' },
    { label: 'Product Name', fieldName: 'Name', type: 'text' },    
    { label: 'Amount', fieldName: 'Cost__c', type: 'currency'},
    { label: 'Qantity', fieldName: 'qantity', type: 'number'}
]; 


export default class ProposalsLwc extends LightningElement {    
    @api recordId;
    data = [];
    columns = columns;
    isOpenModal = false;
    categories = [];
    options =[];
    columnsAddTable = columnsAddTable;
    equipment =[];
    amount = [];
    proposalName = [];
    proposalId;
    proposalURL;
    isSendModalOpen = false;
    deletedProposalName;
    @track tempProposalId;
    tempCategory;
    searchEquipment = [];
    tempSearchInput;
    newProposalItems = [];
    selectedRows = [];
    opportunityId = '';
    disabledSave = true;
    wiredProposals;
  

    // use consctructor with super method to add custom action to table 
    constructor() {
        super(); 
        this.columns = [
            ...this.columns,
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
        ]
    }
  
 // use this method to work with actions and make them inactive if its needed
    getRowActions(row, doneCallback) {
        const actions = [];
     
        actions.push( { label: 'Send', name: 'send', disabled: row['Status__c'] !== 'Draft' });
        actions.push( { label: 'Delete', name: 'delete', disabled: row['Status__c'] !== 'Draft'});   
        doneCallback(actions);
        };
        
    // use wire method to get data from Controller 
    @wire(getProposals, {
        OpportunityId: '$recordId',
    })Proposals(result) {
        this.wiredProposals = result;
        if (result.data) {
           this.data = result.data.map ((proposal) => {  
            return {... proposal, proposalNameURL: `/${proposal.Id}`}; // add to all proposals records proposalNameURL 
           });
        } else if (result.error) {
            console.log(result.error);
        }      
    }

    // use wire method to get data from Controller 
    @wire(getCategories, {}) 
    Equipment_Category__c({ error, data }) {
        if (data) {
           this.categories = data;
           this.options = data.map( category => {
            return { label : category.Name, value : category.Id }; // get 2 values from each category
          });                     
        } else if (error) {
            console.log(error);
        }      
    }


        handeleChangeCategory(event) {
            console.log(event.detail);
            this.tempCategory = event.detail.value;
            console.log(this.tempCategory);                               
            }   

        handleChangeInput(event) {
            this.tempSearchInput = event.detail.value;
            console.log(event.detail);              
            }


        handleSearch() {              
            console.log(this.tempCategory);
            console.log(this.tempSearchInput);
        // use getEquipment method to get equipments by categoryId and input. Add custom CategoryName field to use it in table. 
            getEquipment({categoryId : this.tempCategory, input: this.tempSearchInput}).then(result => {
                this.equipment = result.map ( equip => {
                    return {...equip, categoryName: equip.Equipment_Category__r.Name, qantity : 1
                        }        
                    })       
                }); 
            console.log(this.equipment); 
            }

// use switch method to use delete or send actions
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'send':
                this.send(row);
                break;
            default:
        }
    }

// use rowId for deleteProposal method and send notification for user.
    deleteRow(row) {
        console.log(row.Id);
        deleteProposal({proposalId: row.Id}).then(
            result => {               
               this.deletedProposalName = result;
               console.log(this.deletedProposalName);
               const evt = new ShowToastEvent({                
                title: 'Success',
                message: 'Proposal has been deleted',
                variant: 'success',                                
            });
            this.dispatchEvent(evt);
            refreshApex(this.wiredProposals);  // refresh datatable 
            }).catch(error => {
                console.log('Error ====> '+ JSON.stringify(error));
                const evt = new ShowToastEvent({                
                    title: 'Error',
                    message: 'Proposal cannot be deleted',
                    variant: 'error',   
                });
                this.dispatchEvent(evt);   
            });
    }

     // use send method to save in proposalURL  result of generateProposal method and use proposalURL in iFrame HTML to show content.
    send(row) {
        this.tempProposalId = row.Id;
        generateProposal({proposalId: row.Id}).then(
            result => {               
                this.proposalURL = result;                            
                this.isSendModalOpen = true;                
            }).catch(error => {
                console.log('Error ====> '+error);   
            });
    }

// use sendConfrirmed method to fill proposalID with argument and run SendAttachment method. 
    sendConfirmed() {
        SendAttachment({proposalId: this.tempProposalId}).then(
            result => {  
                console.log(this.tempProposalId);                                         
            }).catch(error => {
                console.log('Error ====> '+error);   
            });
    }

// save selected rows in array. Take EquipmentID from selectedRows.length. 
    handleRowSelection(event) {
        this.selectedRows = [];      
        for (let i = 0; i < event.detail.selectedRows.length; i++) 
        {  
            this.selectedRows.push({ EquipmentId: event.detail.selectedRows[i].Id});
        }
        if (this.selectedRows.length) {  // if selectedRows is not empty 
            this.disabledSave = false;   // enable Save buttom
        }
        else {
            this.disabledSave = true;
        }
        console.log(JSON.stringify(this.selectedRows));  // selected rows in console. 
    }


    handleSave() {
        this.opportunityId = this.recordId;        
        createProposal({OpportunityId: this.opportunityId, records: JSON.stringify(this.selectedRows)}).then(
            result => {               
                console.log('Inserted  ' + result + '  proposal') ; 
                    const evt = new ShowToastEvent({                
                            title: 'Success',
                            message: 'Proposal has been created',
                            variant: 'success',   
                        });
                        this.dispatchEvent(evt);
                        this.isOpenModal = false;                                      
            }).catch(error => {
                console.log('Error ====> '+error);
                const evt = new ShowToastEvent({                
                    title: 'Error',
                    message: 'Proposal has not been created',
                    variant: 'error'   
                });
                this.dispatchEvent(evt);
            });
    }
      

    closeSendModal() {
        this.isSendModalOpen = false;
    }


    openModal() {
        this.isOpenModal = true;
        this.handleSearch();          
    }


    closeModal(){
        this.isOpenModal = false;
    }

    
}










