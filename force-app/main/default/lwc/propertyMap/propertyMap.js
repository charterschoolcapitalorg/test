import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import STREET from '@salesforce/schema/Account.BillingStreet';
import CITY from '@salesforce/schema/Account.BillingCity';
import STATE from '@salesforce/schema/Account.BillingState';
import ZIP from '@salesforce/schema/Account.BillingPostalCode';

const fields = [STREET, CITY, STATE, ZIP];

export default class LightningMapExample extends LightningElement {
  @api recordId;
  street;
  city;
  state;
  zip;
  account;

  @wire(getRecord, { recordId: '$recordId', fields })
    account({ error, data }) {
      if (error) {
        console.log('Something went wrong:', error);
      } else if (data) {
        this.account = data;
        this.street = this.account.fields.BillingStreet.value;
        this.city = this.account.fields.BillingCity.value;
        this.state = this.account.fields.BillingState.value;
        this.zip = this.account.fields.BillingPostalCode.value;
        this.mapMarkers = [{
          location: {
            City: this.city,
            PostalCode: this.zip,
            State: this.state,
            Street: this.street
          },
        }];
      }
    }
}