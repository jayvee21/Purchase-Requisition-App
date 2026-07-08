using PurchaseRequisitionService as srv from '../../srv/purchase-requisition-service';

/**
 * Labels (define once, reused by every table/form below)
 */

annotate srv.PurchaseRequisitions with {
    title           @title: 'Title';
    requester       @title: 'Requested By';
    totalAmount     @title: 'Total Amount' @Measures.ISOCurrency: currency_code;
    submittedAt     @title: 'Submitted At';
    rejectionReason @title: 'Rejection Reason';
    status          @title: 'Status';
}

// Value help so "Requested By" is a searchable picker over known requesters
annotate srv.PurchaseRequisitions with {
    requester
        @Common.ValueList: {
            CollectionPath: 'Requestors',
            Parameters: [
                { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: requester, ValueListProperty: 'ID' }
            ]
        }
};


//──────────────────────────────────────────────────────────
// LIST REPORT — filter bar + table
//──────────────────────────────────────────────────────────

annotate srv.PurchaseRequisitions with @(
    UI.SelectionFields: [
        status_code,
        requester
    ],

    UI.LineItem       : [
        {
            $Type: 'UI.DataField',
            Value: title
        },
        {
            $Type: 'UI.DataField',
            Value: requester
        },
        {
            $Type: 'UI.DataField',
            Value: totalAmount
        },
        {
            $Type      : 'UI.DataField',
            Value      : status_code,
            Criticality: status.criticality
        },
        // action buttons in the table toolbar
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseRequisitionService.submit',
            Label : 'Submit'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseRequisitionService.approve',
            Label : 'Approve'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseRequisitionService.decline',
            Label : 'Reject'
        },
    ]
);

//──────────────────────────────────────────────────────────
// OBJECT PAGE — header, form section, items section
//──────────────────────────────────────────────────────────
annotate srv.PurchaseRequisitions with @(
    UI.HeaderInfo: {
        TypeName      : 'Requisition',
        TypeNamePlural: 'Requisitions',
        Title         : {
            $Type: 'UI.DataField',
            Value: title
        },
        Description   : {
            $Type: 'UI.DataField',
            Value: status.name
        },  
    },

    // header buttons (top-right of the object page)
    UI.Identification: [
        { $Type: 'UI.DataFieldForAction', Action: 'PurchaseRequisitionService.submit', Label: 'Submit' },
        { $Type: 'UI.DataFieldForAction', Action: 'PurchaseRequisitionService.approve', Label: 'Approve' },
        { $Type: 'UI.DataFieldForAction', Action: 'PurchaseRequisitionService.decline', Label: 'Reject' },
        { $Type: 'UI.DataFieldForAction', Action: 'PurchaseRequisitionService.cancel', Label: 'Cancel' },
        { $Type: 'UI.DataFieldForAction', Action: 'PurchaseRequisitionService.process', Label: 'Process' },
        { $Type: 'UI.DataFieldForAction', Action: 'PurchaseRequisitionService.complete', Label: 'Complete' },
    ],

    UI.FieldGroup #General: {
        Data: [
            { $Type: 'UI.DataField', Value: title },
            { $Type: 'UI.DataField', Value: description },
            { $Type: 'UI.DataField', Value: requester },
            { $Type: 'UI.DataField', Value: totalAmount },
            { $Type: 'UI.DataField', Value: currency_code },
            { $Type: 'UI.DataField', Value: submittedAt },
            { $Type: 'UI.DataField', Value: rejectionReason }
        ]
    },

    UI.Facets: [
        { $Type: 'UI.ReferenceFacet', Label: 'General Information', Target: '@UI.FieldGroup#General' },
        { $Type: 'UI.ReferenceFacet', Label: 'Items', Target: 'items/@UI.LineItem'}
    ]
);
   
//──────────────────────────────────────────────────────────
// ITEMS — the child table rendered by the "Items" facet
//──────────────────────────────────────────────────────────
annotate srv.Items with @UI.LineItem: [
    { $Type: 'UI.DataField', Value: product_ID, Label: 'Product' },
    { $Type: 'UI.DataField', Value: quantity },
    { $Type: 'UI.DataField', Value: unitPrice },
    { $Type: 'UI.DataField', Value: amount }
];

annotate srv.Items with {
    unitPrice @Measures.ISOCurrency: currency_code;
    amount    @Measures.ISOCurrency: currency_code;
}

// Value help so "Product" is a searchable picker, not a raw UUID
annotate srv.Items with {
    product 
        @Common.Text : product.name // ← human-readable text
        @Common.TextArrangement: #TextOnly // ← hide the UUID, show name only
        @Common.ValueList: {
            CollectionPath: 'Products',
            Parameters: [
                { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: product_ID, ValueListProperty: 'ID' },
                { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' },
                { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'price' }
            ]    
    }
};