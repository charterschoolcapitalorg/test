import { LightningElement, wire, api } from 'lwc';
import getFundingEstimateReceivables from '@salesforce/apex/ManualFundingEstimateEditorCtrl.getFundingEstimateReceivables';
import { refreshApex } from '@salesforce/apex';
import updateReceivables from '@salesforce/apex/ManualFundingEstimateEditorCtrl.updateReceivables';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLS = [
  { label: 'School', fieldName: 'School__c', editable: false },
  { label: 'Name', fieldName: 'Name', wrapText: true, editable: true },
  { label: 'GRV Value', fieldName: 'GRV_Amount__c', editable: true, type: 'number', typeAttributes: { maximumFractionDigits: 0} },
  { label: 'Pricing Pay Date', fieldName: 'Expected_Pay_Date__c', editable: true, type: 'date-local'},
  { label: 'Statutory Pay Date', fieldName: 'Statutory_Expected_Pay_Date__c', editable: true, type: 'date-local'}
];
export default class ManualFundingEstimateEditor extends LightningElement {

  @api recordId;
  columns = COLS;
  draftValues = [];

  @wire(getFundingEstimateReceivables, { feId: '$recordId' })
  receivables;

  async handleSave(event) {
    const updatedFields = event.detail.draftValues;
    
    // Prepare the record IDs for getRecordNotifyChange()
    const notifyChangeIds = updatedFields.map(row => { return { "recordId": row.Id } });

   // Pass edited fields to the updateReceivables Apex controller
    await updateReceivables({data: updatedFields})
    .then(result => {
      // console.log(JSON.stringify("Apex update result: "+ result));
      this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: 'Receivables updated',
            variant: 'success'
        })
      );

      // Refresh LDS cache and wires
      getRecordNotifyChange(notifyChangeIds);

      // Display fresh data in the datatable
      refreshApex(this.receivables).then(() => {
        // Clear all draft values in the datatable
        this.draftValues = [];
      });
    
    }).catch(error => {
        this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Error updating or refreshing records',
                  message: error.body.message,
                  variant: 'error'
              })
          );
      });
  }
}