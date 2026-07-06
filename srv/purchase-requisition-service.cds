using { com.jvg.purchasereq as db } from '../db/schema';

service PurchaseRequisitionService @(path:'/purchase-requisitions') {
    // Transactional root - draft-enabled at the service, not the db
    @odata.draft.enabled: true
    entity PurchaseRequisitions as projection on db.PurchaseRequisitions;

    // Owned children travel with the compositionl project them for typed accss
    entity Items as projection on db.Items;
    entity Attachments as projection on db.Attachments;

    // Master data - ready-only value-help resources
    @readyonly entity Suppliers as projection on db.Suppliers;
    @readyonly entity Products as projection on db.Products;

    // RequisitionStatuses is auto-exposed by the CodeList aspect - no need to list
}