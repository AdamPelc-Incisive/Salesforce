/**
 * @description Invocable action that returns Inventory and Ordered asset counts
 *              for a given Product2 Id, plus a collection of the Ordered assets.
 * @category Lock 8 Actions
 */
public with sharing class GetAssetInventory {

    /**
     * @description Input parameters for the GetAssetInventory invocable action.
     */
    public class Request {
        @InvocableVariable(label='Product Id' description='Product2 Id to retrieve asset counts for.' required=true)
        public Id productId;
    }

    /**
     * @description Output parameters returned by the GetAssetInventory invocable action.
     */
    public class Result {
        @InvocableVariable(label='Inventory Count')
        public Integer inventoryCount;

        @InvocableVariable(label='Ordered Count')
        public Integer orderedCount;

        @InvocableVariable(label='Total Count')
        public Integer totalCount;

        @InvocableVariable(label='Ordered Assets')
        public List<Asset> orderedAssets;
    }

    /**
     * @description Queries Asset records for the given Product2 Id and returns
     *              counts broken out by Inventory and Ordered status, a combined total,
     *              and the full collection of Ordered asset records.
     * @param requests List of Request objects (bulk-safe, processes first record)
     * @return List of Result objects containing asset counts and ordered asset records
     */
    @InvocableMethod(
        label='Get Asset Inventory'
        category='Lock 8 Actions'
        description='Returns Inventory and Ordered asset counts for a given Product2 Id, plus a collection of Ordered assets.'
    )
    public static List<Result> getInventory(List<Request> requests) {
        Request req = requests[0];
        Result res = new Result();
        res.inventoryCount = 0;
        res.orderedCount   = 0;

        for (AggregateResult ar : [
            SELECT Status, COUNT(Id) cnt
            FROM Asset
            WHERE Product2Id = :req.productId
            AND Status IN ('Inventory', 'Ordered')
            GROUP BY Status
        ]) {
            String status = (String) ar.get('Status');
            Integer cnt   = (Integer) ar.get('cnt');

            if (status == 'Inventory') {
                res.inventoryCount = cnt;
            } else if (status == 'Ordered') {
                res.orderedCount = cnt;
            }
        }

        res.totalCount = res.inventoryCount + res.orderedCount;

        res.orderedAssets = [
            SELECT Id, Name, Product2Id, Status, SerialNumber, AccountId
            FROM Asset
            WHERE Product2Id = :req.productId
            AND Status = 'Ordered'
        ];

        return new List<Result>{ res };
    }
}