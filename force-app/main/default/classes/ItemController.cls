public with sharing class ItemController {
	@AuraEnabled
	public static List<Item__c> getItems(String type, String family, String searchTerm) {
		String searchPattern = '%' + String.escapeSingleQuotes(String.isBlank(searchTerm) ? '' : searchTerm.trim()) + '%';
		String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, AvailableQuantity__c FROM Item__c WHERE AvailableQuantity__c > 0';

		if (!String.isBlank(type)) {
			query += ' AND Type__c = :type';
		}
		if (!String.isBlank(family)) {
			query += ' AND Family__c = :family';
		}
		if (!String.isBlank(searchTerm)) {
			query += ' AND (Name LIKE :searchPattern OR Description__c LIKE :searchPattern)';
		}
		// in alphabetical order
		query += ' ORDER BY Name ASC';
		return Database.query(query);
	}


	@AuraEnabled(cacheable=true)
	public static Account getAccountInfo(Id accountId) {
		if (accountId == null) {
			return null;
		}
		return [SELECT Id, Name, AccountNumber, Industry FROM Account WHERE Id = :accountId LIMIT 1];
	}


	public class CartItemDTO {
		@AuraEnabled public Id itemId { get; set; }
		@AuraEnabled public Integer quantity { get; set; }
	}

	@AuraEnabled
	public static Id checkoutCart(Id accountId, List<CartItemDTO> cartItems) {
		if (accountId == null) {
			throw new AuraHandledException('Account is required.');
		}

		if (cartItems == null || cartItems.isEmpty()) {
			throw new AuraHandledException('Cart is empty.');
		}

		Set<Id> itemIds = new Set<Id>();
		for (CartItemDTO cartItem : cartItems) {
			if (cartItem.itemId == null || cartItem.quantity == null || cartItem.quantity <= 0) {
				throw new AuraHandledException('Invalid cart item.');
			}
			itemIds.add(cartItem.itemId);
		}

		Map<Id, Item__c> itemsById = new Map<Id, Item__c>([SELECT Id, Price__c, AvailableQuantity__c
				FROM Item__c WHERE Id IN :itemIds FOR UPDATE]);

		for (CartItemDTO cartItem : cartItems) {
			Item__c item = itemsById.get(cartItem.itemId);
			if (item == null) {
				throw new AuraHandledException('Item was not found.');
			}
			if (item.AvailableQuantity__c == null || item.AvailableQuantity__c < cartItem.quantity) {
				throw new AuraHandledException('Not enough quantity is available.');
			}

			if (item.Price__c == null) {
				throw new AuraHandledException('Item price is missing.');
			}
		}

		Purchase__c purchase = new Purchase__c(ClientId__c = accountId, TotalItems__c = 0, GrandTotal__c = 0);
		insert purchase;

		List<PurchaseLine__c> purchaseLines = new List<PurchaseLine__c>();

		for (CartItemDTO cartItem : cartItems) {
			Item__c item = itemsById.get(cartItem.itemId);
			Decimal unitCost = item.Price__c == null ? 0 : item.Price__c;

			purchaseLines.add(new PurchaseLine__c(PurchaseId__c = purchase.Id, ItemId__c = item.Id,
					Amount__c = cartItem.quantity, UnitCost__c = unitCost));
			item.AvailableQuantity__c -= cartItem.quantity;
		}
		insert purchaseLines;
		update itemsById.values();

		return purchase.Id;
	}
}