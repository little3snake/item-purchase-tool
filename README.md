# Item Purchase Tool

A Salesforce Lightning Web Component application for browsing items, managing a shopping cart, and creating purchase records. The project was implemented as a Salesforce Developer technical assignment.

---

# Features

The application implements the following functionality:

- Open the Item Purchase Tool from the Account page.
- Display Account information:
    - Name
    - Account Number
    - Industry
- Browse available items.
- Filter items by Family and Type.
- Search items by Name and Description.
- Display the number of currently listed items.
- View item details in a modal window.
- Display item images.
- Add items to a shopping cart.
- View cart contents in a modal.
- Prevent adding out-of-stock items.
- Validate available quantity during checkout.
- Create Purchase and Purchase Line records.
- Automatically decrease available item quantity after successful checkout.
- Automatically calculate Purchase totals using an Apex Trigger.
- Redirect the user to the created Purchase record after checkout.
- Allow managers to create new items.
- Hide the Create Item button for non-manager users.
- Automatically retrieve an image from Unsplash when a new item is created.

---

# Project Setup

Before running the application:

1. Deploy the project to a Salesforce Developer Org.
2. Create an application on Unsplash Developer Portal.
3. Generate an Unsplash Access Key.
4. Configure:
    - Named Credential (Unsplash)
    - External Credential (Unsplash)
5. Replace
```
Client-ID YOUR_ACCESS_KEY
```
with your own Unsplash Access Key.

6. Add the following domain to CSP Trusted Sites:
```
https://images.unsplash.com
```
7. Assign the UnsplashAccess Permission Set to the current user.

---

# Data Model
```
Account
│
└── Purchase__c
│
└── PurchaseLine__c
│
└── Item__c
```

### Item__c

| Field | Type |
|-------|------|
| Name | Text |
| Description__c | Text Area |
| Type__c | Picklist |
| Family__c | Picklist |
| Image__c | URL |
| Price__c | Number |
| AvailableQuantity__c | Number |

### Purchase__c

| Field | Type |
|-------|------|
| ClientId__c | Lookup(Account) |
| TotalItems__c | Number |
| GrandTotal__c | Currency |

### PurchaseLine__c

| Field | Type |
|-------|------|
| PurchaseIdc | Master-Detail(Purchasec) |
| ItemIdc | Master-Detail(Itemc) |
| Amount__c | Number |
| UnitCost__c | Currency |

### User

| Field | Type |
|-------|------|
| IsManager__c | Checkbox |

---

# Security

The Unsplash Access Key is not included in this repository.

Authentication is configured using Salesforce **External Credentials** and **Named Credentials**.

Replace
```
Client-ID YOUR_ACCESS_KEY
```
with your own Unsplash Access Key before running the project.

---

# CSP Trusted Sites

The following domain must be added:
```
https://images.unsplash.com
```
---

# Main Components

## Lightning Web Component

### itemPurchaseTool

Responsibilities:

- Render the user interface
- Load Account information
- Load and filter items
- Search items
- Display item details
- Manage shopping cart
- Perform checkout
- Open Create Item modal
- Retrieve Unsplash images
- Redirect to Purchase record

---

## Apex

### ItemController

Responsibilities:

- Load items
- Load Account information
- Validate manager permissions
- Perform checkout
- Create Purchase records
- Create Purchase Line records
- Update item quantity
- Retrieve image URLs from Unsplash

### PurchaseLineTriggerHandler

Responsibilities:

- Recalculate Purchase totals
- Update TotalItems
- Update GrandTotal

---

## Trigger

### PurchaseLineTrigger

Calls the handler after Purchase Line insert, update and delete operations.

---

# Unit Tests

Apex business logic is covered by unit tests.

Test classes:

- ItemControllerTest
- PurchaseLineTriggerHandlerTest

Test results:

- Tests Ran: **9**
- Pass Rate: **100%**
- Org Wide Coverage: **91%**

Coverage by class:
| Class | Coverage |
|--------|----------|
| ItemController | 90% |
| PurchaseLineTriggerHandler | 90% |
| PurchaseLineTrigger | 100% |

Covered scenarios include:

- Item filtering
- Item searching
- Account loading
- Successful checkout
- Checkout validation
- Manager permission validation
- Unsplash API callout (mock)
- Trigger recalculation after insert
- Trigger recalculation after update
- Trigger recalculation after delete

All Apex tests complete successfully with no failures.

---

# Running Tests

Run all Apex tests:
```bash
sf apex run test \
--tests ItemControllerTest \
--tests PurchaseLineTriggerHandlerTest \
--result-format human \
--code-coverage \
--wait 10
```
---

# Deployment

Deploy the project:
```bash
sf project deploy start
```

Validate deployment with local tests:
```bash
sf project deploy start --test-level RunLocalTests
```
---

# Project Structure
```
force-app/
└── main/
└── default/
├── classes/
├── triggers/
├── lwc/
├── objects/
├── layouts/
├── flexipages/
├── tabs/
├── permissionsets/
├── namedCredentials/
├── externalCredentials/
└── cspTrustedSites/
```
---

# Implemented Requirements

- Open Item Purchase Tool from Account layout
- Display Account information
- Filter items by Type and Family
- Display item count
- Search by Name and Description
- View item details
- Display item images
- Add items to cart
- Display cart contents
- Validate stock availability
- Perform checkout
- Create Purchase records
- Create Purchase Line records
- Decrease available quantity
- Automatically calculate Purchase totals
- Redirect to Purchase record
- Manager-only item creation
- Automatic Unsplash image retrieval
- Apex unit test coverage

---

# Final Status

All functional requirements from the provided technical assignment have been implemented, including:

- Lightning Web Components
- Apex business logic
- Apex Trigger
- Unsplash API integration
- Salesforce security configuration
- Unit tests
- Automatic purchase total calculation