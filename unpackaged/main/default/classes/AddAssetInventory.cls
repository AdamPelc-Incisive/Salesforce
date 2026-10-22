/**
 * @description Invocable action to create Asset records for a product.
 *              In bundle mode, creates the main product asset plus all component assets
 *              based on Product_Component_Setting__c records of the specified bundle type.
 *              In single product mode, creates assets for the specified product only.
 * @category Lock 8 Actions
 */
public with sharing class AddAssetInventory {

    /**
     * @description Input parameters for the AddAssetInventory invocable action.
     */
    public class Request {
        @InvocableVariable(label='Product Id' description='Product2 Id of the product to receive. For bundles, this is the Required_for_Product__c value.' required=true)
        public Id productId;

        @InvocableVariable(label='Quantity' description='Number of units to receive into inventory' required=true)
        public Integer quantity;

        @InvocableVariable(label='Account Id' description='Account to assign all created assets to' required=true)
        public Id accountId;

        @InvocableVariable(label='Status' description='Asset status to set — typically Inventory or Ordered. Defaults to Inventory if blank.')
        public String status;

        @InvocableVariable(label='Bundle Type' description='Product_Bundle_Type__c value to filter component settings by. Defaults to Received if blank. Ignored when Single Product is true.')
        public String bundleType;

        @InvocableVariable(label='Single Product' description='If true, creates assets for this product only — no component lookup. If false or blank, treats product as a bundle and creates component assets too.')
        public Boolean singleProduct;
    }

    /**
     * @description Output parameters returned by the AddAssetInventory invocable action.
     */
    public class Result {
        @InvocableVariable(label='Created Assets')
        public List<Asset> createdAssets;

        @InvocableVariable(label='Status Message')
        public String statusMessage;

        @InvocableVariable(label='Is Error')
        public Boolean isError;
    }

    /**
     * @description Creates Asset records for a product and optionally its bundle components.
     *              Defaults to bundle mode (looks up Received-type component settings).
     *              Set Single Product = true to skip component lookup entirely.
     * @param requests List of Request objects (bulk-safe, processes first record)
     * @return List of Result objects containing created assets and status info
     */
    @InvocableMethod(label='Add Assets/Bundles' category='Lock 8 Actions' description='Creates assets for a product. In bundle mode, also creates component assets based on Product_Component_Setting__c. In single product mode, creates assets for the product only.')
    public static List<Result> receiveBundles(List<Request> requests) {
        Request req = requests[0];
        Result res = new Result();
        res.createdAssets = new List<Asset>();
        res.isError = false;

        String assetStatus = String.isNotBlank(req.status) ? req.status : 'Inventory';
        String bundleType  = String.isNotBlank(req.bundleType) ? req.bundleType : 'Received';
        Boolean isSingle   = req.singleProduct == true;

        // Validate quantity
        if (req.quantity == null || req.quantity <= 0) {
            res.isError = true;
            res.statusMessage = 'Error: Quantity must be a positive integer.';
            return new List<Result>{ res };
        }

        // Fetch product name for asset naming
        List<Product2> productList = [SELECT Id, Name FROM Product2 WHERE Id = :req.productId LIMIT 1];
        if (productList.isEmpty()) {
            res.isError = true;
            res.statusMessage = 'Error: Product not found for Id: ' + req.productId;
            return new List<Result>{ res };
        }
        String productName = productList[0].Name;

        List<Asset> assetsToInsert = new List<Asset>();

        // Always create quantity assets for the main product
        for (Integer i = 0; i < req.quantity; i++) {
            assetsToInsert.add(new Asset(
                Name       = productName,
                Product2Id = req.productId,
                AccountId  = req.accountId,
                Status     = assetStatus
            ));
        }

        if (!isSingle) {
            return handleBundleMode(req, res, assetsToInsert, bundleType, productName);
        }

        return handleSingleMode(res, assetsToInsert, req.quantity, productName);
    }

    /**
     * @description Handles bundle mode: looks up component settings, builds component assets, and inserts all.
     * @param req Original request
     * @param res Result object to populate
     * @param assetsToInsert Pre-populated list with main product assets
     * @param bundleType Resolved bundle type string
     * @param productName Resolved main product name
     * @return Populated Result list
     */
    private static List<Result> handleBundleMode(
        Request req,
        Result res,
        List<Asset> assetsToInsert,
        String bundleType,
        String productName
    ) {
        List<Product_Component_Setting__c> componentSettings = [
            SELECT Id, Product__c, Quantity__c
            FROM Product_Component_Setting__c
            WHERE Required_for_Product__c = :req.productId
            AND Product_Bundle_Type__c = :bundleType
            AND Product__c != null
        ];

        if (componentSettings.isEmpty()) {
            res.isError = true;
            res.statusMessage = 'Error: No ' + bundleType + '-type component settings found for this product. '
                + 'Verify Product_Component_Setting__c records exist with Product_Bundle_Type__c = ' + bundleType + '. '
                + 'To receive a non-bundled product, set Single Product = true.';
            return new List<Result>{ res };
        }

        // Fetch component product names
        Set<Id> componentProductIds = new Set<Id>();
        for (Product_Component_Setting__c pcs : componentSettings) {
            componentProductIds.add(pcs.Product__c);
        }
        Map<Id, String> componentNameById = new Map<Id, String>();
        for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Id IN :componentProductIds]) {
            componentNameById.put(p.Id, p.Name);
        }

        // Build component assets
        for (Product_Component_Setting__c pcs : componentSettings) {
            Integer componentQty  = (pcs.Quantity__c != null) ? (Integer) pcs.Quantity__c : 1;
            Integer totalToCreate = req.quantity * componentQty;
            String  componentName = componentNameById.containsKey(pcs.Product__c)
                ? componentNameById.get(pcs.Product__c)
                : 'Component';

            for (Integer i = 0; i < totalToCreate; i++) {
                assetsToInsert.add(new Asset(
                    Name       = componentName,
                    Product2Id = pcs.Product__c,
                    AccountId  = req.accountId,
                    Status     = req.status != null ? req.status : 'Inventory'
                ));
            }
        }

        try {
            insert assetsToInsert;
            res.createdAssets = assetsToInsert;
            res.statusMessage = 'Success — created ' + assetsToInsert.size() + ' asset(s): '
                + req.quantity + ' x ' + productName
                + buildComponentSummary(componentSettings, componentNameById, req.quantity) + '.';
            res.isError = false;
        } catch (DmlException e) {
            res.isError = true;
            res.statusMessage = 'Error inserting assets: ' + e.getDmlMessage(0);
        }

        return new List<Result>{ res };
    }

    /**
     * @description Handles single product mode: inserts main product assets only.
     * @param res Result object to populate
     * @param assetsToInsert Pre-populated list with main product assets
     * @param quantity Number of assets being created
     * @param productName Resolved main product name
     * @return Populated Result list
     */
    private static List<Result> handleSingleMode(
        Result res,
        List<Asset> assetsToInsert,
        Integer quantity,
        String productName
    ) {
        try {
            insert assetsToInsert;
            res.createdAssets = assetsToInsert;
            res.statusMessage = 'Success — created ' + quantity + ' asset(s): '
                + quantity + ' x ' + productName + '.';
            res.isError = false;
        } catch (DmlException e) {
            res.isError = true;
            res.statusMessage = 'Error inserting assets: ' + e.getDmlMessage(0);
        }

        return new List<Result>{ res };
    }

    /**
     * @description Builds a readable component summary string for the status message.
     * @param settings List of component settings
     * @param componentNameById Map of product Id to product name
     * @param quantity Quantity multiplier
     * @return Formatted string like ', 2 x Power Cord, 4 x Battery'
     */
    private static String buildComponentSummary(
        List<Product_Component_Setting__c> settings,
        Map<Id, String> componentNameById,
        Integer quantity
    ) {
        List<String> parts = new List<String>();
        for (Product_Component_Setting__c pcs : settings) {
            Integer componentQty = (pcs.Quantity__c != null) ? (Integer) pcs.Quantity__c : 1;
            parts.add((quantity * componentQty) + ' x ' + (componentNameById.containsKey(pcs.Product__c)
                ? componentNameById.get(pcs.Product__c) : 'Component'));
        }
        return parts.isEmpty() ? '' : ', ' + String.join(parts, ', ');
    }
}