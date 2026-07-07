using { com.jvg.purchasereq as db } from '../db/schema';

service PurchaseRequisitionService @(path:'/purchase-requisitions') {
    // Transactional root - draft-enabled at the service, not the db
    @odata.draft.enabled
    @restrict: [
        { grant: 'READ',   to: ['Employee','Manager','Procurement','Admin'] },
        { grant: ['CREATE','UPDATE','DELETE'], to: ['Employee','Admin'] },
        // --- bound actions: grant is the action NAME ---
        { grant: 'submit',   to: 'Employee' },
        { grant: 'approve',  to: 'Manager' },
        { grant: 'decline',  to: 'Manager' },
        { grant: 'cancel',   to: ['Employee','Admin'] },
        { grant: 'process',  to: ['Procurement','Admin'] },
        { grant: 'complete', to: ['Procurement','Admin'] }
    ]
    entity PurchaseRequisitions as projection on db.PurchaseRequisitions actions {
        action submit() returns PurchaseRequisitions;
        action approve() returns PurchaseRequisitions;
        action decline( reason: String @mandatory ) returns PurchaseRequisitions;
        action cancel() returns PurchaseRequisitions;
        action process() returns PurchaseRequisitions;
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