import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import { NavigationMixin } from 'lightning/navigation';
import searchAccounts from '@salesforce/apex/AccountDedupeSearch.searchAccounts';

export default class AccountDedupeCombo extends NavigationMixin(LightningElement) {
    // Flow output attributes
    @api accountName = '';          // the name the rep typed (used to create a new Account)
    @api selectedRecordId = null;   // set only when the rep picks an existing Account (null = none)
    @api selectedAccountName = null;// display name of the picked existing Account
    @api label = 'Account Name';
    @api required = false;

    @track results = [];
    @track showResults = false;
    isSearching = false;
    _debounce;

    get hasSelection() {
        return !!this.selectedRecordId;
    }

    get showDropdown() {
        return this.showResults && this.results.length > 0 && !this.hasSelection;
    }

    get noMatchesHint() {
        return (
            this.showResults &&
            !this.isSearching &&
            this.results.length === 0 &&
            this.accountName &&
            this.accountName.length >= 2 &&
            !this.hasSelection
        );
    }

    handleInput(event) {
        const value = event.target.value;
        this.accountName = value;
        this.notifyFlow('accountName', value);

        // typing after a selection clears the selection
        if (this.hasSelection) {
            this.clearSelectionState();
        }

        window.clearTimeout(this._debounce);
        const term = value;
        this._debounce = window.setTimeout(() => {
            this.runSearch(term);
        }, 300);
    }

    async runSearch(term) {
        if (!term || term.length < 2) {
            this.results = [];
            this.showResults = false;
            return;
        }
        this.isSearching = true;
        this.showResults = true;
        try {
            const data = await searchAccounts({ searchTerm: term });
            this.results = (data || []).map((acc) => {
                const pracId = this.formatId(acc.Practice_ID__c);
                const corpId = this.formatId(acc.Corporate_ID__c);
                // Only label a type when there's evidence for it. IDs are stamped
                // later (on Closed Won), so many accounts are legitimately neither.
                const isPractice = acc.Is_Practice_Account__c === true || !!pracId;
                const isCorporate = !!corpId;
                let typeLabel = '';
                let badgeClass = '';
                if (isPractice) {
                    typeLabel = 'Practice';
                    badgeClass = 'slds-badge slds-m-left_x-small slds-theme_success';
                } else if (isCorporate) {
                    typeLabel = 'Corporate';
                    badgeClass = 'slds-badge slds-m-left_x-small slds-badge_inverse';
                }
                return {
                    id: acc.Id,
                    name: acc.Name,
                    typeLabel: typeLabel,
                    hasBadge: !!typeLabel,
                    badgeClass: badgeClass,
                    meta: this.buildMeta(acc)
                };
            });
        } catch (e) {
            this.results = [];
        } finally {
            this.isSearching = false;
        }
    }

    buildMeta(acc) {
        const parts = [];
        const pracId = this.formatId(acc.Practice_ID__c);
        const corpId = this.formatId(acc.Corporate_ID__c);
        if (pracId) {
            parts.push('Practice ID ' + pracId);
        }
        if (corpId) {
            parts.push('Corp ID ' + corpId);
        }
        if (acc.ShippingCity) {
            parts.push(acc.ShippingState ? acc.ShippingCity + ', ' + acc.ShippingState : acc.ShippingCity);
        }
        return parts.join('  •  ');
    }

    formatId(val) {
        if (val === null || val === undefined || val === '') {
            return '';
        }
        // Corporate_ID__c / Practice_ID__c are numeric; drop any trailing ".0"
        return String(val).replace(/\.0+$/, '');
    }

    handleSelect(event) {
        const id = event.currentTarget.dataset.id;
        const chosen = this.results.find((r) => r.id === id);
        if (!chosen) {
            return;
        }
        this.selectedRecordId = id;
        this.selectedAccountName = chosen.name;
        this.accountName = chosen.name;
        this.showResults = false;
        this.notifyFlow('selectedRecordId', id);
        this.notifyFlow('selectedAccountName', chosen.name);
        this.notifyFlow('accountName', chosen.name);
    }

    handleClear() {
        this.clearSelectionState();
        this.accountName = '';
        this.notifyFlow('accountName', '');
        this.results = [];
        this.showResults = false;
    }

    // "View Account" (existing selected): open the record.
    handleView() {
        if (!this.selectedRecordId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.selectedRecordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    clearSelectionState() {
        this.selectedRecordId = null;
        this.selectedAccountName = null;
        this.notifyFlow('selectedRecordId', null);
        this.notifyFlow('selectedAccountName', null);
    }

    notifyFlow(name, value) {
        this.dispatchEvent(new FlowAttributeChangeEvent(name, value));
    }

    handleBlur() {
        // let click on a result register before hiding
        window.setTimeout(() => {
            this.showResults = false;
        }, 250);
    }

    // Flow screen validation: require either a typed name or a selected existing account
    @api
    validate() {
        if (this.required && !this.accountName && !this.selectedRecordId) {
            return {
                isValid: false,
                errorMessage: 'Please enter an account name or pick an existing account.'
            };
        }
        return { isValid: true };
    }
}