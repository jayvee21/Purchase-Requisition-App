sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"com/jvg/purchasereq/requisitions/purchaserequisitions/test/integration/pages/PurchaseRequisitionsList.gen",
	"com/jvg/purchasereq/requisitions/purchaserequisitions/test/integration/pages/PurchaseRequisitionsObjectPage.gen"
], function (JourneyRunner, PurchaseRequisitionsListGenerated, PurchaseRequisitionsObjectPageGenerated) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('com/jvg/purchasereq/requisitions/purchaserequisitions') + '/test/flp.html#app-preview',
        pages: {
			onThePurchaseRequisitionsListGenerated: PurchaseRequisitionsListGenerated,
			onThePurchaseRequisitionsObjectPageGenerated: PurchaseRequisitionsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

