public class AssetTriggerHandler {

    public static void handleStatusChange(List<Asset> newAssets, Map<Id, Asset> oldMap) {

        // Step 1: Collect Product2 Ids where Status changed to or from 'Inventory'
        Set<Id> affectedProductIds = new Set<Id>();

        for (Asset a : newAssets) {
            String oldStatus = (oldMap != null && oldMap.containsKey(a.Id))
                ? oldMap.get(a.Id).Status
                : null;
            Boolean wasInventory = oldStatus == 'Inventory';
            Boolean isInventory  = a.Status == 'Inventory';

            if (wasInventory != isInventory && a.Product2Id != null) {
                affectedProductIds.add(a.Product2Id);
            }
        }

        if (affectedProductIds.isEmpty()) return;

        // Step 2: Find affected bundle product Ids in two ways:
        // (a) affected product is a component piece (Product__c)
        // (b) affected product IS the bundle product (Required_for_Product__c)
        Set<Id> affectedBundleProductIds = new Set<Id>();

        for (Product_Component_Setting__c pcs : [
            SELECT Required_for_Product__c
            FROM Product_Component_Setting__c
            WHERE Product__c IN :affectedProductIds
            OR Required_for_Product__c IN :affectedProductIds
        ]) {
            affectedBundleProductIds.add(pcs.Required_for_Product__c);
        }

        if (affectedBundleProductIds.isEmpty()) return;

        // Step 3: Get ALL component settings for those bundle products
        Map<Id, List<Product_Component_Setting__c>> settingsByBundleId =
            new Map<Id, List<Product_Component_Setting__c>>();
        Set<Id> allProductIdsToCount = new Set<Id>();

        // Always include the bundle products themselves (qty 1 each)
        allProductIdsToCount.addAll(affectedBundleProductIds);

        for (Product_Component_Setting__c pcs : [
            SELECT Required_for_Product__c, Product__c, Quantity__c
            FROM Product_Component_Setting__c
            WHERE Required_for_Product__c IN :affectedBundleProductIds
            AND Product__c != null
        ]) {
            if (!settingsByBundleId.containsKey(pcs.Required_for_Product__c)) {
                settingsByBundleId.put(pcs.Required_for_Product__c, new List<Product_Component_Setting__c>());
            }
            settingsByBundleId.get(pcs.Required_for_Product__c).add(pcs);
            allProductIdsToCount.add(pcs.Product__c);
        }

        // Step 4: Get inventory counts for all relevant products in one query
        // (bundle products + all their components)
        Map<Id, Integer> inventoryCountByProductId = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Product2Id, COUNT(Id) cnt
            FROM Asset
            WHERE Product2Id IN :allProductIdsToCount
            AND Status = 'Inventory'
            GROUP BY Product2Id
        ]) {
            inventoryCountByProductId.put(
                (Id) ar.get('Product2Id'),
                (Integer) ar.get('cnt')
            );
        }

        // Step 5: Calculate deployable bundle count for each affected bundle
        // Constraint 1: inventory of the bundle product itself (always qty 1)
        // Constraint 2: floor(inventory / quantityNeeded) for each component
        // Deployable = min across all constraints
        List<Product2> bundlesToUpdate = new List<Product2>();

        for (Id bundleProductId : affectedBundleProductIds) {
            List<Product_Component_Setting__c> settings = settingsByBundleId.get(bundleProductId);

            if (settings == null || settings.isEmpty()) continue;

            // Start with the bundle product's own inventory as the first constraint
            Integer deployable = inventoryCountByProductId.containsKey(bundleProductId)
                ? inventoryCountByProductId.get(bundleProductId)
                : 0;

            // Then constrain by each component
            for (Product_Component_Setting__c pcs : settings) {
                Integer quantityNeeded = (pcs.Quantity__c != null) ? (Integer) pcs.Quantity__c : 1;
                Integer inStock = inventoryCountByProductId.containsKey(pcs.Product__c)
                    ? inventoryCountByProductId.get(pcs.Product__c)
                    : 0;

                Integer canFulfill = (quantityNeeded > 0) ? (inStock / quantityNeeded) : 0;
                if (canFulfill < deployable) {
                    deployable = canFulfill;
                }
            }

            bundlesToUpdate.add(new Product2(
                Id = bundleProductId,
                Deployable_Bundles_In_Stock__c = deployable,
                Bundle_Stock_Last_Calculated__c = System.now()
            ));
        }

        if (!bundlesToUpdate.isEmpty()) {
            update bundlesToUpdate;
        }
    }
}