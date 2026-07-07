using { com.jvg.purchasereq as db } from '../db/schema';

service PurchaseRequisitionService @(path:'/purchase-requisitions') {
    // Transactional root - draft-enabled at the service, not the db
    @odata.draft.enabled
    @restrict: [
        { grant: 'READ', to: ['Employee', 'Manager', 'Procurement', 'Admin'] },
        { grant: ['CREATE', 'UPDATE', 'DELETE'], to: ['Employee', 'Admin'] }
    ]
    entity PurchaseRequisitions as projection on db.PurchaseRequisitions actions {
        @(requires: 'Employee')
        action submit() returns PurchaseRequisitions;

        @(requires:'Manager')
        action approve() returns PurchaseRequisitions;

        @(requires:'Manager')
        action decline( reason: String @mandatory ) returns PurchaseRequisitions;

        @(requires: ['Employee', 'Admin'])
        action cancel() returns PurchaseRequisitions;

        @(requires: ['Procurement', 'Admin'])
        action process() returns PurchaseRequisitions;

        @(requires: ['Procurement','Admin'])
        action complete() returns PurchaseRequisitions;

    };

    // Owned children travel with the compositionl project them for typed accss
    entity Items as projection on db.Items;
    entity Attachments as projection on db.Attachments;

    // Master data - ready-only value-help resources
    @readonly entity Suppliers as projection on db.Suppliers;
    @readonly entity Products as projection on db.Products;

    // RequisitionStatuses is auto-exposed by the CodeList aspect - no need to list
}