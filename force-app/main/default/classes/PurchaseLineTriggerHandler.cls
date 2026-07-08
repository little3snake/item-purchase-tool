public with sharing class PurchaseLineTriggerHandler {
	public static void recalculatePurchases(Set<Id> purchaseIds) {
		if (purchaseIds == null || purchaseIds.isEmpty()) { return;}

		Map<Id, Purchase__c> purchasesToUpdate = new Map<Id, Purchase__c>();

		for (AggregateResult result : [SELECT PurchaseId__c purchaseId,
				SUM(Amount__c) totalItems, SUM(UnitCost__c) totalUnitCost
				FROM PurchaseLine__c WHERE PurchaseId__c IN :purchaseIds GROUP BY PurchaseId__c]) {
			Id purchaseId = (Id) result.get('purchaseId');
			Decimal totalItems = (Decimal) result.get('totalItems');

			purchasesToUpdate.put(purchaseId, new Purchase__c(Id = purchaseId, TotalItems__c = totalItems, GrandTotal__c = 0));
		}

		for (PurchaseLine__c line : [SELECT PurchaseId__c, Amount__c, UnitCost__c
				FROM PurchaseLine__c WHERE PurchaseId__c IN :purchaseIds]) {
			Purchase__c purchase = purchasesToUpdate.get(line.PurchaseId__c);

			if (purchase == null) {
				purchase = new Purchase__c(Id = line.PurchaseId__c, TotalItems__c = 0, GrandTotal__c = 0);
				purchasesToUpdate.put(line.PurchaseId__c, purchase);
			}

			Decimal amount = line.Amount__c == null ? 0 : line.Amount__c;
			Decimal unitCost = line.UnitCost__c == null ? 0 : line.UnitCost__c;
			purchase.GrandTotal__c += amount * unitCost;
		}

		for (Id purchaseId : purchaseIds) {
			if (!purchasesToUpdate.containsKey(purchaseId)) {
				purchasesToUpdate.put(purchaseId, new Purchase__c(Id = purchaseId, TotalItems__c = 0, GrandTotal__c = 0));
			}
		}
		update purchasesToUpdate.values();
	}
}