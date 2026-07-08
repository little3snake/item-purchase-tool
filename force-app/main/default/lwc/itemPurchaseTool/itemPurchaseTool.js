import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getItems from '@salesforce/apex/ItemController.getItems';
import getAccountInfo from '@salesforce/apex/ItemController.getAccountInfo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkoutCart from '@salesforce/apex/ItemController.checkoutCart';
import { NavigationMixin } from 'lightning/navigation';

export default class ItemPurchaseTool extends NavigationMixin(LightningElement) {
    accountId;
    account;

    searchTerm = '';
    selectedType = '';
    selectedFamily = '';
    items = [];
    error;

    selectedItemId;
    selectedItem;

    cartItems = [];
    isCartModalOpen = false;

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

    get cartCount() {
        return this.cartItems.reduce((sum, item) => sum + item.quantity, 0);
    }

    get cartTotal() {
        return this.cartItems.reduce((sum, item) => {
            return sum + item.quantity * (item.Price__c || 0);
        }, 0);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({title, message, variant}));
    }

    handleAddToCart(event) {
        const itemId = event.currentTarget.dataset.id;
        const item = this.items.find((currentItem) => currentItem.Id === itemId);

        if (!item) {
            this.showToast('Error', 'Item was not found.', 'error');
            return;
        }

        if (!item.AvailableQuantity__c || item.AvailableQuantity__c <= 0) {
            this.showToast('Out of stock', 'This item is currently out of stock.', 'error');
            return;
        }

        const existingCartItem = this.cartItems.find((cartItem) => cartItem.Id === itemId);

        if (existingCartItem) {
            if (existingCartItem.quantity >= item.AvailableQuantity__c) {
                this.showToast('Not enough quantity', 'You cannot add more items than available in stock.', 'warning');
                return;
            }
            existingCartItem.quantity += 1;
            this.cartItems = [...this.cartItems];
        } else {
            this.cartItems = [...this.cartItems, {...item, quantity: 1}];
        }
        this.showToast('Added to cart', `${item.Name} was added to cart.`, 'success');
    }

    openCartModal() {
        this.isCartModalOpen = true;
    }

    closeCartModal() {
        this.isCartModalOpen = false;
    }

    handleRemoveFromCart(event) {
        const itemId = event.currentTarget.dataset.id;
        this.cartItems = this.cartItems.map((item) => {
                if (item.Id === itemId) {
                    return {...item, quantity: item.quantity - 1};
                }
                return item;
            }).filter((item) => item.quantity > 0);
        this.showToast('Updated', 'Item quantity was decreased.', 'success');
    }

    get cartButtonLabel() {
        return `Cart (${this.cartCount})`;
    }

    get cartRows() {
        return this.cartItems.map((item) => ({
            ...item,
            unitPrice: item.Price__c || 0,
            lineTotal: item.quantity * (item.Price__c || 0)
        }));
    }


    async handleCheckout() {
        if (!this.cartItems.length) {
            this.showToast('Cart is empty', 'Please add items before checkout.', 'warning');
            return;
        }

        try {
            const purchaseId = await checkoutCart({accountId: this.accountId, cartItems: this.cartItems.map((item) => ({
                    itemId: item.Id, quantity: item.quantity}))});

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: purchaseId,
                    objectApiName: 'Purchase__c',
                    actionName: 'view'
                }
            });

            this.showToast('Success', 'Purchase was created successfully.', 'success');
            this.cartItems = [];
            this.isCartModalOpen = false;
            await this.loadItems();
            console.log('Created purchase:', purchaseId);
        } catch (error) {
            this.showToast('Checkout failed', error.body?.message || 'Failed to check out cart.', 'error');
        }
    }
}