namespace com.jvg.purchasereq;

using {
    cuid,
    managed,
    Currency,
    sap.common.CodeList
} from '@sap/cds/common';

using { Attachments } from '@cap-js/attachments';


// ---- Status as a code list (localizable, value-help ready) ----
entity RequisitionStatuses : CodeList {
    key code        : String(12);
        criticality : Integer // 3=positive, 2=critical, 1=negative, 0=neutral
}

// ---- Header (draft-enabled later, at the service) ----
entity PurchaseRequisitions : cuid, managed {
    title       : String(100) not null;
    description : String(1000);
    status      : Association to RequisitionStatuses default 'Draft';
    requester   : String(255); // employee userid; auto-fill decision pending
    submittedAt : Timestamp;
    totalAmount : Decimal(15, 2) default 0;
    currency    : Currency;
    rejectionReason : String(1000);
    items       : Composition of many Items
                      on items.parent = $self;
    attachments : Composition of many Attachments;
}


annotate PurchaseRequisitions.attachments with {
    content @Validation.Maximum        : '10MB'
            @Core.AcceptableMediaTypes : ['application/pdf', 'image/png', 'image/jpeg'];
}

// ---- Owned line items -----
entity Items : cuid, managed {
    parent    : Association to PurchaseRequisitions not null;
    product   : Association to Products @mandatory;
    quantity  : Decimal(13, 3) not null default 1 @assert.range: [(0), _];
    unitPrice : Decimal(15, 2);
    amount    : Decimal(15, 2);
    currency  : Currency;
}



// ---- Reference / master data (value-help sources) ----
entity Suppliers : cuid, managed {
    name     : String(120) not null;
    email    : String(255);
    products : Association to many Products
                   on products.supplier = $self;
}


entity Products : cuid, managed {
    name     : String(120) not null;
    price    : Decimal(15, 2);
    currency : Currency;
    supplier : Association to Suppliers;
}
