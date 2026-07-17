import cds from '@sap/cds';
import { PurchaseRequisition, PurchaseRequisitions as PR, Items, Products } from '#cds-models/PurchaseRequisitionService';
import { PurchaseRequisitions as DbPR } from '#cds-models/com/jvg/purchasereq';

export default class PurchaseRequisitionService extends cds.ApplicationService {
    init() {



        // --- Drafttime: keep item amount and parent total live ----
        const recalcParentTotal = async (parentID: string) => {
            const items = await SELECT.from(Items.drafts)
                .columns('amount','currency_code')
                .where({ parent_ID: parentID });
            const total = items.reduce( (sum, i) => sum + (Number(i.amount) || 0), 0 );
            const currency_code = items.find(i => i.currency_code)?.currency_code ?? null;
            await UPDATE(PR.drafts, parentID).with({ totalAmount: total, currency_code });
        }

        this.before('*', '*', req =>
        console.log('AUTH>', req.event, 'user=', req.user.id, 'roles=', req.user.roles));

        this.before(['CREATE','UPDATE'], Items.drafts, async (req) => {
            // product picked → default price & currency (only if not set manually)
            if (req.data.product_ID) {
                const p = await SELECT.one.from(Products, req.data.product_ID)
                          .columns('price', 'currency_code');
                if (p) {
                    req.data.unitPrice ??= p.price;
                    req.data.currency_code ??= p.currency_code;
                }
            }

            // merge incoming patch with stored values, recompute line amount
            if ('quantity' in req.data || 'unitPrice' in req.data || 'product_ID' in req.data) {
                const old = await SELECT.one.from(req.subject).columns('quantity', 'unitPrice');
                const qty = req.data.quantity ?? old?.quantity ?? 0;
                const price = req.data.unitPrice ?? old?.unitPrice ?? 0;
                req.data.amount = Number(qty) * Number(price);
            }
        });

        this.after(['CREATE','UPDATE'], Items.drafts, async (_, req)=> {
            const parentID = req.data.parent_ID
                ?? (await SELECT.one.from(req.subject).columns('parent_ID'))?.parent_ID;
            if (parentID) await recalcParentTotal(parentID);
        });

        // deletion: capture the parent before the row disappears 
        this.before('DELETE', Items.drafts, async (req) => {
            const item = await SELECT.one.from(req.subject).columns('parent_ID');
            (req as any)._parentID = item?.parent_ID;
        });

        this.after('DELETE', Items.drafts, async (_, req) => {
            const parentID = (req as any)._parentID;
            if (parentID) await recalcParentTotal(parentID);
        })
        
        this.before('CREATE', PR, async (req) => {
            if (!req.data.requester) req.data.requester = req.user.id;
        });
        
        // ---- State machine: guard the "when", then transition ----
        this.on('submit', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Draft')
                return req.error(400, 'Only a draft requisition can be submitted.');
            
            const { ID } = req.params.at(-1) as { ID : string };
            const row = await SELECT.one.from(Items).columns('count(*) as n').where({ parent_ID: ID });
            if (!(row as any)?.n) 
                return req.error(400, 'Add at least one item before submitting.', 'items');

            await UPDATE(DbPR, ID).with({
                status_code: 'Submitted',
                submittedAt: new Date().toISOString()
            });
            return SELECT.one.from(req.subject);
        });


        this.on('approve', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Submitted')
                return req.error(400, `Cannot approve a requisition in status '${pr?.status_code}'.`);
            const { ID } = req.params.at(-1) as { ID : string };
            await UPDATE(DbPR, ID).with({
                status_code: 'Approved',
            });
            return SELECT.one.from(req.subject);
        });

        this.on(PurchaseRequisition.actions.decline, PR.name, async (req) => {
            const { reason } = req.data;
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Submitted')
                return req.error(400, `Cannot decline a requisition in status '${pr?.status_code}'.`);
            const { ID } = req.params.at(-1) as { ID : string };
            await UPDATE(DbPR, ID).with({ status_code: 'Rejected', rejectionReason: reason });
            return SELECT.one.from(req.subject);
        });

        this.on('cancel', PR, async (req) =>{
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if ( !['Draft', 'Submitted'].includes(pr?.status_code) )
                return req.error(400, 'Only a draft or submitted requisition can be cancelled.');
            const { ID } = req.params.at(-1) as { ID : string };
            await UPDATE(DbPR, ID).with({ status_code: 'Cancelled' });
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
            pr.currency_code = pr.items?.find(i => i.currency_code)?.currency_code ?? null;
        });

        this.on('process', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Approved') 
                return req.error(400, `Cannot process a requisition in status '${pr?.status_code}'.`);
            const { ID } = req.params.at(-1) as { ID : string };
            await UPDATE(DbPR, ID).with({ status_code: 'Processing' });
            return SELECT.one.from(req.subject);
        });

        this.on('complete', PR, async (req) => {
            const pr = await SELECT.one.from(req.subject).columns('status_code');
            if (pr?.status_code !== 'Processing')
                return req.error(400, `Cannot complete a requisition in status '${pr?.status_code}'.`);
            const { ID } = req.params.at(-1) as { ID : string };
            await UPDATE(DbPR, ID).with({ status_code: 'Completed'});
            return SELECT.one.from(req.subject);
        });

        return super.init();
    }
}