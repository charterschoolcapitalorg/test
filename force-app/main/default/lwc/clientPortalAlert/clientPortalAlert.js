import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import DUEDATE from '@salesforce/schema/Intake_Item__c.Item_Automatically_Made_Visible_Date__c';

const fields = [DUEDATE];

export default class ClientPortalAlert extends LightningElement {
  @api recordId;

  @wire(getRecord, { recordId: '$recordId', fields })
    intakeItem;

  get dueDate() {
    return getFieldValue(this.intakeItem.data, DUEDATE);
  }

}