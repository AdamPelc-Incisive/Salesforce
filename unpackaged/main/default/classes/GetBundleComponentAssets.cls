public class GetBundleComponentAssets {

    public class Request {
        @InvocableVariable(label='Product Id' description='The Product2 Id of the bundle to look up components for' required=true)
        public Id productId;

        @InvocableVariable(label='Product Bundle Type' description='Optional. Filters component settings by Product Bundle Type picklist value e.g. Shipped, Received')
        public String productBundleType;
    }

    public class Result {
        @InvocableVariable(label='Serialized Assets')
        public List<Asset> serializedAssets;

        @InvocableVariable(label='Serialized Product Quantities')
        public String serializedProductQuantities;

        @InvocableVariable(label='Optional Product Ids')
        public String optionalProductIds;

        @InvocableVariable(label='Unserialized Assets')
        public List<Asset> unserializedAssets;

        @InvocableVariable(label='Status Message')
        public String statusMessage;

        @InvocableVariable(label='Is Error')
        public Boolean isError;

        @InvocableVariable(label='Has Non-Serial Assets')
        public Boolean hasNonSerialAssets;

        @InvocableVariable(label='Has Serialized Assets')
        public Boolean hasSerializedAssets;
    }

    @InvocableMethod(
        label='Get Bundle Component Assets'
        category='Lock 8 Actions'
        description='Looks up Product Component Settings for a bundle product, then returns available inventory assets split by serialized/unserialized, with a completeness check.'
    )
    public static List<Result> getBundleAssets(List<Request> requests) {
        Request req = requests[0];
        Result res = new Result();
        res.serializedAssets = new List<Asset>();
        res.unserializedAssets = new List<Asset>();
        res.isError = false;
        res.optionalProductIds = '[]';

        // Track quantity needed per serialized product for LWC
        Map<Id, Integer> serializedQuantityMap = new Map<Id, Integer>();
        // Serialized products that are deal-type-dependent (e.g. the laptop) rather than
        // always-required. Everything else reaching the picker (e.g. ICAM's Scan Bodies Set)
        // stays required regardless of deal type - see Product_Component_Setting__c.Optional__c.
        Set<Id> optionalProductIdSet = new Set<Id>();

        // Step 1: Get all component settings for this bundle product
        String settingsQuery = 'SELECT Id, Name, Product__c, Quantity__c, Product_Bundle_Type__c, Optional__c FROM Product_Component_Setting__c WHERE Required_for_Product__c = :productId';
        Id productId = req.productId;
        String productBundleType = req.productBundleType;

        if (String.isNotBlank(req.productBundleType)) {
            settingsQuery += ' AND Product_Bundle_Type__c = :productBundleType';
        }

        List<Product_Component_Setting__c> componentSettings = Database.query(settingsQuery);

        if (componentSettings.isEmpty()) {
            res.statusMessage = 'No bundle components configured for this product.';
            res.isError = false;
            res.hasNonSerialAssets = false;
            res.hasSerializedAssets = false;
            return new List<Result>{ res };
        }

        // Step 2: Collect the component Product Ids we need to find inventory for
        Set<Id> componentProductIds = new Set<Id>();
        // Map from component Product Id -> the setting record (for completeness check)
        Map<Id, Product_Component_Setting__c> settingByProductId = new Map<Id, Product_Component_Setting__c>();

        for (Product_Component_Setting__c pcs : componentSettings) {
            if (pcs.Product__c != null) {
                componentProductIds.add(pcs.Product__c);
                settingByProductId.put(pcs.Product__c, pcs);
            }
        }

        // Step 3a: Query Product2 to get Serialized__c and Name for each component product
        Map<Id, Boolean> isSerializedByProductId = new Map<Id, Boolean>();
        Map<Id, String> productNameById = new Map<Id, String>();
        for (Product2 p : [
            SELECT Id, Name, Serialized__c
            FROM Product2
            WHERE Id IN :componentProductIds
        ]) {
            isSerializedByProductId.put(p.Id, p.Serialized__c == true);
            productNameById.put(p.Id, p.Name);
        }

        // Step 3b: Query inventory assets for all component products in one SOQL call
        List<Asset> inventoryAssets = [
            SELECT Id, Name, Product2Id, Status, SerialNumber, Serial_Number_Set__c, AccountId, Product_Name_Formula__c, Cost__c
            FROM Asset
            WHERE Product2Id IN :componentProductIds
            AND Status = 'Inventory'
            ORDER BY Product2Id, Name ASC
        ];

        // Step 4: Bucket assets by product, then split into serialized/unserialized using Product2.Serialized__c
        // We need the per-product grouping for the completeness check
        Map<Id, List<Asset>> assetsByProductId = new Map<Id, List<Asset>>();
        for (Asset a : inventoryAssets) {
            if (!assetsByProductId.containsKey(a.Product2Id)) {
                assetsByProductId.put(a.Product2Id, new List<Asset>());
            }
            assetsByProductId.get(a.Product2Id).add(a);
        }

        // Step 5: Completeness check + build output lists
        List<String> missingItems = new List<String>();

        for (Id compProductId : componentProductIds) {
            Product_Component_Setting__c setting = settingByProductId.get(compProductId);
            List<Asset> available = assetsByProductId.containsKey(compProductId)
                ? assetsByProductId.get(compProductId)
                : new List<Asset>();

            Integer quantityNeeded = (setting.Quantity__c != null) ? (Integer) setting.Quantity__c : 1;
            Boolean isSerialized = isSerializedByProductId.containsKey(compProductId)
                ? isSerializedByProductId.get(compProductId)
                : false;
            String productName = productNameById.containsKey(compProductId)
                ? productNameById.get(compProductId)
                : compProductId;

            if (isSerialized) {
                if (available.size() < quantityNeeded) {
                    Integer shortfall = quantityNeeded - available.size();
                    missingItems.add(
                        productName + ' — need ' + quantityNeeded + ', have ' + available.size()
                        + ' (short ' + shortfall + ')'
                    );
                }
                res.serializedAssets.addAll(available);
                serializedQuantityMap.put(compProductId, quantityNeeded);
                if (setting.Optional__c == true) {
                    optionalProductIdSet.add(compProductId);
                }

            } else {
                if (available.size() < quantityNeeded) {
                    Integer shortfall = quantityNeeded - available.size();
                    missingItems.add(
                        productName + ' — need ' + quantityNeeded + ', have ' + available.size()
                        + ' (short ' + shortfall + ')'
                    );
                } else {
                    // Grab exactly quantityNeeded assets — they get silently reassigned in the background
                    for (Integer i = 0; i < quantityNeeded; i++) {
                        res.unserializedAssets.add(available[i]);
                    }
                }
            }
        }

        // Build JSON string of productId -> quantityNeeded for LWC
        List<String> jsonParts = new List<String>();
        for (Id prodId : serializedQuantityMap.keySet()) {
            jsonParts.add('"' + prodId + '":' + serializedQuantityMap.get(prodId));
        }
        res.serializedProductQuantities = '{' + String.join(jsonParts, ',') + '}';

        // Build JSON array of optional (deal-type-dependent) product Ids for the LWC
        List<String> optionalIdParts = new List<String>();
        for (Id prodId : optionalProductIdSet) {
            optionalIdParts.add('"' + prodId + '"');
        }
        res.optionalProductIds = '[' + String.join(optionalIdParts, ',') + ']';

        res.hasNonSerialAssets = !res.unserializedAssets.isEmpty();
        res.hasSerializedAssets = !res.serializedAssets.isEmpty();

        // Step 6: Build status message
        if (missingItems.isEmpty()) {
            res.statusMessage = 'Success — all bundle components have sufficient inventory.';
            res.isError = false;
        } else {
            res.statusMessage = 'Warning: Bundle is incomplete. Missing or insufficient inventory for:\n• '
                + String.join(missingItems, '\n• ');
            res.isError = true;
        }

        return new List<Result>{ res };
    }
}