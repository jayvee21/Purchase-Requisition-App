import cds from '@sap/cds';

export default class PurchaseRequisitionService extends cds.ApplicationService {
    init() {
        const { PurchaseRequisitions: PR } = this.entities;

        this.before('*', '*', req =>
        console.log('AUTH>', req.event, 'user=', req.user.id, 'roles=', req.user.roles));

        
        this.before('CREATE', PR, async (req) => {
            if (!req.data.requester) req.data.requester = req.user.id;
        });
        
        // ---- State machine: guard the "when", then transition ----
        this.on('submit', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Draft')
                return req.error(400, 'Only a draft requisition can be submitted.');
            await UPDATE(req.subject).with({
                status_code: 'Submitted',
                submittedAt: new Date().toISOString()
            });
            return SELECT.one.from(req.subject);
        });


        this.on('approve', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Submitted')
                return req.error(400, `Cannot approve a requisition in status '${pr?.status_code}'.`);
            await UPDATE(req.subject).with({ status_code: 'Approved'});
            return SELECT.one.from(req.subject);
        });

        this.on('decline', PR, async (req) => {
            const { reason } = req.data;
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Submitted')
                return req.error(400, `Cannot decline a requisition in status '${pr?.status_code}'.`);
            await UPDATE(req.subject).with({ status_code: 'Rejected', rejectionReason: reason });
            return SELECT.one.from(req.subject);
        });

        this.on('cancel', PR, async (req) =>{
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if ( !['Draft', 'Submitted'].includes(pr?.status_code) )
                return req.error(400, 'Only a draft or submitted requisition can be cancelled.');
            await UPDATE(req.subject).with({ status_code: 'Cancelled' });
            return SELECT.one.from(req.subject);
        });

        // ---- Derived total: recompute on save, never trust the client ----
        this.before('SAVE', PR, (req) => {
            const pr = req.data;
            let total = 0;
            for (const item of pr.items ?? []) {
                item.amount = (Number(item.quantity) || 0) * (Number(item.unitPrice) || 0);
                total += item.amount;
            }
            pr.totalAmount = total;
        });

        this.on('process', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Approved') 
                return req.error(400, `Cannot process a requisition in status '${pr?.status_code}'.`);
            await UPDATE(req.subject).with({ status_code: 'Processing' });
            return SELECT.one.from(req.subject);
        });

        this.on('complete', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Processing')
                return req.error(400, `Cannot complete a requisition in status '${pr?.status_code}'.`);
            await UPDATE(req.subject).with({ status_code: 'Completed'});
            return SELECT.one.from(req.subject);
        });

        return super.init();
    }
}