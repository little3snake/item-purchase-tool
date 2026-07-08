public with sharing class ItemController {

	@AuraEnabled
	public static List<Item__c> getItems(String type, String family, String searchTerm) {
		String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, AvailableQuantity__c ' +
				'FROM Item__c WHERE AvailableQuantity__c > 0';

		if (!String.isBlank(type)) { query += ' AND Type__c = :type';}
		if (!String.isBlank(family)) { query += ' AND Family__c = :family';}
		query += ' ORDER BY Name ASC';
		List<Item__c> queriedItems = Database.query(query);
		if (String.isBlank(searchTerm)) { return queriedItems;}
		String normalizedSearch = searchTerm.toLowerCase();
		List<Item__c> filteredItems = new List<Item__c>();

		for (Item__c item : queriedItems) {
			String nameValue = item.Name == null ? '' : item.Name.toLowerCase();
			String descriptionValue = item.Description__c == null ? '' : item.Description__c.toLowerCase();
			if (nameValue.contains(normalizedSearch) || descriptionValue.contains(normalizedSearch)) {
				filteredItems.add(item);
			}
		}
		return filteredItems;
	}


	@AuraEnabled(cacheable=true)
	public static Account getAccountInfo(Id accountId) {
		if (accountId == null) { return null;}
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

	@AuraEnabled(cacheable=true)
	public static Boolean isCurrentUserManager() {
		User currentUser = [SELECT IsManager__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		return currentUser.IsManager__c == true;
	}


	@AuraEnabled
	public static String searchImage(String query) {
		if (String.isBlank(query)) {return null;}
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:Unsplash/search/photos?per_page=1&query=' + EncodingUtil.urlEncode(query, 'UTF-8'));
		req.setMethod('GET');

		Http http = new Http();
		HttpResponse res = http.send(req);
		//if (res.getStatusCode() != 200) { return null;}
		if (res.getStatusCode() != 200) {
			throw new AuraHandledException('Unsplash error: ' + res.getStatusCode() + ' ' + res.getBody());
		}

		Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
		List<Object> results = (List<Object>)body.get('results');
		if (results.isEmpty()) { return null;}
		Map<String,Object> photo = (Map<String,Object>)results[0];
		Map<String,Object> urls = (Map<String,Object>)photo.get('urls');
		return (String)urls.get('regular');
	}

}