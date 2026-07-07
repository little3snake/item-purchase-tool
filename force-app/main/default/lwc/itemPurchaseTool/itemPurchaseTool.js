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

    selectedItemId;
    selectedItem;

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

    connectedCallback() {
        this.loadItems();
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.accountId = currentPageReference.state?.c__accountId;
            this.loadAccount();
        }
    }

    async loadAccount() {
        try {
            this.account = await getAccountInfo({
                accountId: this.accountId
            });
        } catch (error) {
            this.error = error.body?.message || 'Failed to load account';
        }
    }

    async loadItems() {
        try {
            this.items = await getItems({
                type: this.selectedType,
                family: this.selectedFamily,
                searchTerm: this.searchTerm
            });
            this.error = undefined;
        } catch (error) {
            this.items = [];
            this.error = error.body?.message || 'Failed to load items';
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.loadItems();
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.loadItems();
    }

    handleFamilyChange(event) {
        this.selectedFamily = event.detail.value;
        this.loadItems();
    }

    get isModalOpen() {
        return this.selectedItemId !== undefined;
    }

    handleDetailsClick(event) {
        this.selectedItemId = event.currentTarget.dataset.id;
        this.selectedItem = this.items.find((item) => item.Id === this.selectedItemId);
    }

    closeModal() {
        this.selectedItemId = undefined;
        this.selectedItem = undefined;
    }
}