import { LightningElement, api, track } from 'lwc';

const COLUMNS = [
    { label: 'Product', fieldName: 'Product_Name_Formula__c', type: 'text' },
    { label: 'Serial Number', fieldName: 'SerialNumber', type: 'text' },
    { label: 'Cost', fieldName: 'Cost__c', type: 'currency' }
];

const SEARCHABLE_FIELDS = ['Name', 'Product_Name_Formula__c', 'SerialNumber'];

export default class SerializedAssetPicker extends LightningElement {

    @track groups = [];
    @track _selectedAssets = [];

    _serializedAssets = [];
    _serializedProductQuantities = '{}';
    _requireFullBundle = true;
    _optionalProductIds = '[]';

    columns = COLUMNS;

    @api
    get serializedAssets() {
        return this._serializedAssets;
    }
    set serializedAssets(value) {
        this._serializedAssets = value || [];
        this.buildGroups();
    }

    @api
    get serializedProductQuantities() {
        return this._serializedProductQuantities;
    }
    set serializedProductQuantities(value) {
        this._serializedProductQuantities = value || '{}';
        this.buildGroups();
    }

    // Defaults to true (unset) so any other caller of this shared component that doesn't pass
    // this parameter keeps today's behavior: full bundle pre-selected.
    @api
    get requireFullBundle() {
        return this._requireFullBundle;
    }
    set requireFullBundle(value) {
        this._requireFullBundle = value === undefined || value === null ? true : value;
        this.buildGroups();
    }

    // JSON array of Product2 Ids that are deal-type-dependent (e.g. the laptop) rather than
    // always-required. Defaults to none optional, so any other caller of this shared component
    // that doesn't pass this parameter keeps every group always-required, as before this existed.
    @api
    get optionalProductIds() {
        return this._optionalProductIds;
    }
    set optionalProductIds(value) {
        this._optionalProductIds = value || '[]';
        this.buildGroups();
    }

    @api
    get selectedAssets() {
        return this._selectedAssets;
    }

    // Read-only output for Flow to check post-screen, via a Decision element, whether every
    // group that's actually required right now satisfies its quantityNeeded. A group that's
    // deal-type-dependent (isOptional) and currently not required (requireFullBundle false) is
    // skipped entirely - its selection state never blocks. Every other group (including an
    // optional one when requireFullBundle is true) always counts.
    @api
    get selectionIsComplete() {
        if (!this.groups || this.groups.length === 0) return true;
        return this.groups.every(group => {
            const effectivelyRequired = group.isOptional ? this._requireFullBundle : true;
            if (!effectivelyRequired) return true;
            return group.selectedRows.length === group.quantityNeeded;
        });
    }

    buildGroups() {
        // Don't build until we have assets
        if (!this._serializedAssets || this._serializedAssets.length === 0) return;

        let quantityMap = {};
        try {
            quantityMap = JSON.parse(this._serializedProductQuantities || '{}');
        } catch (e) {
            console.error('Failed to parse serializedProductQuantities', e);
        }

        let optionalIds = [];
        try {
            optionalIds = JSON.parse(this._optionalProductIds || '[]');
        } catch (e) {
            console.error('Failed to parse optionalProductIds', e);
        }
        const optionalIdSet = new Set(optionalIds);

        const groupMap = {};
        this._serializedAssets.forEach(asset => {
            const prodId = asset.Product2Id;
            if (!groupMap[prodId]) {
                groupMap[prodId] = {
                    productId: prodId,
                    productName: asset.Product_Name_Formula__c || prodId,
                    quantityNeeded: quantityMap[prodId] || 1,
                    isOptional: optionalIdSet.has(prodId),
                    assets: [],
                    filteredAssets: [],
                    selectedRows: [],
                    selectionError: false,
                    searchTerm: ''
                };
            }
            groupMap[prodId].assets.push(asset);
        });

        this.groups = Object.values(groupMap).map(group => {
            // A group that isn't deal-type-dependent is always treated as required, regardless
            // of requireFullBundle - only an optional group's default selection varies by deal
            // type.
            const effectivelyRequired = group.isOptional ? this._requireFullBundle : true;
            const selectedRows = effectivelyRequired
                ? group.assets.slice(0, group.quantityNeeded).map(a => a.Id)
                : [];
            return {
                ...group,
                filteredAssets: [...group.assets],
                selectedRows,
                isRequiredNow: effectivelyRequired
            };
        });

        // Reflect any defaults in the component's output immediately, even if the screen is
        // never touched - previously this only ran from handleRowSelection().
        this.updateSelectedAssets();
    }

    handleSearch(event) {
        const productId = event.currentTarget.dataset.productId;
        const searchTerm = event.target.value.toLowerCase();

        this.groups = this.groups.map(group => {
            if (group.productId !== productId) return group;

            const filteredAssets = searchTerm
                ? group.assets.filter(asset =>
                    SEARCHABLE_FIELDS.some(field =>
                        asset[field] && String(asset[field]).toLowerCase().includes(searchTerm)
                    )
                )
                : [...group.assets];

            return { ...group, searchTerm, filteredAssets };
        });
    }

    handleRowSelection(event) {
        const productId = event.currentTarget.dataset.productId;
        const selectedRows = event.detail.selectedRows;

        this.groups = this.groups.map(group => {
            if (group.productId !== productId) return group;
            const selectionError = selectedRows.length !== group.quantityNeeded;
            return { ...group, selectedRows: selectedRows.map(r => r.Id), selectionError };
        });

        this.updateSelectedAssets();
    }

    updateSelectedAssets() {
        const allAssets = this._serializedAssets || [];
        const selected = [];

        this.groups.forEach(group => {
            group.selectedRows.forEach(id => {
                const asset = allAssets.find(a => a.Id === id);
                if (asset) selected.push(asset);
            });
        });

        this._selectedAssets = selected;
    }

    get hasGroups() {
        return this.groups && this.groups.length > 0;
    }

    // Flow calls this on every Next/Finish click for any custom component that implements it,
    // regardless of the field's isRequired setting - isRequired only gates Flow's own built-in
    // blank-check for simple value-bound fields, not a component's own validate(). A group that
    // isn't currently required (isOptional and requireFullBundle false) must be skipped here the
    // same way selectionIsComplete skips it, or an empty optional group blocks navigation anyway.
    @api
    validate() {
        let isValid = true;
        const errorMessages = [];

        this.groups = this.groups.map(group => {
            const effectivelyRequired = group.isOptional ? this._requireFullBundle : true;
            if (!effectivelyRequired) {
                return { ...group, selectionError: false };
            }
            if (group.selectedRows.length !== group.quantityNeeded) {
                isValid = false;
                errorMessages.push(
                    `Please select exactly ${group.quantityNeeded} item(s) for ${group.productName}`
                );
                return { ...group, selectionError: true };
            }
            return { ...group, selectionError: false };
        });

        return {
            isValid,
            errorMessage: errorMessages.join(' | ')
        };
    }
}