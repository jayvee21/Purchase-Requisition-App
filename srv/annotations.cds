using { PurchaseRequisitionService } from './purchase-requisition-service';

annotate PurchaseRequisitionService.PurchaseRequisitions with actions {
  decline @(Common.Label: 'Reject');
};
