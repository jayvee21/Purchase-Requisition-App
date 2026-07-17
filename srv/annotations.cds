using {PurchaseRequisitionService} from './purchase-requisition-service';

annotate PurchaseRequisitionService.PurchaseRequisitions with actions {
  submit   @(Common.SideEffects: {
    TargetProperties: [
      'in/status_code',
      'in/submittedAt'
    ],
    TargetEntities  : [in.status]
  });
  approve  @(Common.SideEffects: {
    TargetProperties: ['in/status_code'],
    TargetEntities  : [in.status]
  });
  decline  @(
    Common.Label      : 'Reject',
    Common.SideEffects: {
      TargetProperties: [
        'in/status_code',
        'in/rejectionReason'
      ],
      TargetEntities  : [in.status]
    }
  );
  cancel   @(Common.SideEffects: {
    TargetProperties: ['in/status_code'],
    TargetEntities  : [in.status]
  });
  process  @(Common.SideEffects: {
    TargetProperties: ['in/status_code'],
    TargetEntities  : [in.status]
  });
  complete @(Common.SideEffects: {
    TargetProperties: ['in/status_code'],
    TargetEntities  : [in.status]
  });
};
