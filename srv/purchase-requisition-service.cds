using { com.jvg.purchasereq as db } from '../db/schema';

service PurchaseRequisitionService @(path:'/purchase-requisitions') {
    // Transactional root - draft-enabled at the service, not the db
    @odata.draft.enabled
    @restrict: [
        { grant: 'READ',   to: ['Manager','Procurement','Admin'] },
        { grant: 'READ',   to: 'Employee', where: 'createdBy = $user' },
        
        { grant: 'CREATE', to: ['Employee', 'Admin'] },
        { grant: ['UPDATE', 'DELETE'], to: 'Employee', where: 'createdBy = $user' },
        { grant: ['UPDATE','DELETE'], to: 'Admin' },

        // Ownership applies to lifecycle actions too
        { grant: 'submit', to: 'Employee', where: 'createdBy = $user' },
        { grant: 'cancel', to: 'Employee', where: 'createdBy = $user' },
        { grant: 'cancel', to: 'Admin' },

        { grant: 'approve', to: 'Manager' },
        { grant:  'decline',to: 'Manager' },
        { grant: 'process', to: ['Procurement', 'Admin'] },
        { grant: 'complete', to: ['Procurement', 'Admin'] }
    ]
    @cds.redirection.target
    entity PurchaseRequisitions as projection on db.PurchaseRequisitions actions {
        @Core.OperationAvailable: ($self.status.code = 'Draft')
        action submit() returns PurchaseRequisitions;

        @Core.OperationAvailable: ($self.status.code = 'Submitted')
        action approve() returns PurchaseRequisitions;

        @Core.OperationAvailable: ($self.status.code = 'Submitted')
        action decline( reason: String @mandatory ) returns PurchaseRequisitions;

        @Core.OperationAvailable: ($self.status.code = 'Draft' or $self.status.code = 'Submitted')
        action cancel() returns PurchaseRequisitions;

        @Core.OperationAvailable: ($self.status.code = 'Approved')
        action process() returns PurchaseRequisitions;

        @Core.OperationAvailable: ($self.status.code = 'Processing')
        action complete() returns PurchaseRequisitions;

    };

    @readonly 
    entity Requestors as select  from db.PurchaseRequisitions distinct{
        key requester as ID
    } where requester is not null;

    // Owned children travel with the compositional project them for typed access
    @restrict: [
        { grant: 'READ', to: ['Manager', 'Procurement', 'Admin'] },
        { grant: '*', to: 'Admin' },
        { grant: '*', to: 'Employee', where: 'parent.createdBy = $user' }
    ]
    entity Items as projection on db.Items;
    entity Attachments as projection on db.Attachments;

    // Master data - ready-only value-help resources
    @readonly entity Suppliers as projection on db.Suppliers;
    @readonly entity Products as projection on db.Products;

    // RequisitionStatuses is auto-exposed by the CodeList aspect - no need to list
}