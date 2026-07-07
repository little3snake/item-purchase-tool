import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getItems from '@salesforce/apex/ItemController.getItems';
import getAccountInfo from '@salesforce/apex/ItemController.getAccountInfo';

export default class ItemPurchaseTool extends LightningElement {
    accountId;
    account;

    searchTerm = '';
    selectedType = '';
    selectedFamily = '';
    items = [];
    error;

    typeOptions = [
        { label: 'All', value: '' },
        { label: 'Electronics', value: 'Electronics' },
        { label: 'Furniture', value: 'Furniture' },
        { label: 'Appliances', value: 'Appliances' },
        { label: 'Other', value: 'Other' }
    ];

    familyOptions = [
        { label: 'All', value: '' },
        { label: 'Office', value: 'Office' },
        { label: 'Home', value: 'Home' },
        { label: 'Outdoor', value: 'Outdoor' },
        { label: 'Other', value: 'Other' }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.accountId = currentPageReference.state?.c__accountId;
        }
    }

    @wire(getAccountInfo, { accountId: '$accountId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
        } else if (error) {
            this.error = error.body?.message || 'Failed to load account';
        }
    }

    @wire(getItems, {
        type: '$selectedType',
        family: '$selectedFamily',
        searchTerm: '$searchTerm'
    })
    wiredItems({ error, data }) {
        if (data) {
            this.items = data;
            this.error = undefined;
        } else if (error) {
            this.items = [];
            this.error = error.body?.message || 'Failed to load items';
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
    }

    handleFamilyChange(event) {
        this.selectedFamily = event.detail.value;
    }
}