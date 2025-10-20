WITH CTE AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ICReceiptItems.ICReceiptItemID) AS STT,
        CASE 
            WHEN ROW_NUMBER() OVER (ORDER BY ICReceiptItems.ICReceiptItemID) % 2 = 0 
            THEN ROW_NUMBER() OVER (ORDER BY ICReceiptItems.ICReceiptItemID) 
        END AS STT_Chan,
        CASE 
            WHEN ROW_NUMBER() OVER (ORDER BY ICReceiptItems.ICReceiptItemID) % 2 <> 0 
            THEN ROW_NUMBER() OVER (ORDER BY ICReceiptItems.ICReceiptItemID) 
        END AS STT_Le,
        CASE 
            WHEN ROW_NUMBER() OVER (ORDER BY ICReceiptItems.ICReceiptItemID) % 2 = 0 
            THEN ICProducts.ICProductNo 
        END AS SP_Chan,
        CASE 
            WHEN ROW_NUMBER() OVER (ORDER BY ICReceiptItems.ICReceiptItemID) % 2 <> 0 
            THEN ICProducts.ICProductNo 
        END AS SP_Le,
        ICReceipts.ICReceiptID,
        ICReceipts.ICReceiptNo,
        CAST(ICReceipts.ICReceiptDate AS DATETIME) ICReceiptDate,
        ICReceipts.ICReceiptDesc,
        ICReceipts.ICReceiptInvNo,
        ICStocks.ICStockNo,
        ICStocks.ICStockName,
        ICStockSlots.ICStockSlotName,
        ICStocks.ICStockAddL1,
        ICReceiptItems.ICReceiptItemUnitPrice,
        ICReceiptItems.ICReceiptItemQty,
        ICReceiptItems.ICReceiptItemStkQty,
        ICReceiptItems.ICReceiptItemDesc,
        ICReceiptItems.ICReceiptItemPrice,
        ICReceiptItems.ICReceiptItemLotNo,
        ICReceiptItems.ICReceiptItemSerialNo,
        ICReceiptItems.ICReceiptItemBarCodeNo,
        ICReceiptItems.ICReceiptItemBarCode,
        APSuppliers.APSupplierNo,
        APSuppliers.APSupplierName,
        APSuppliers.APSupplierAddL1,
        ICProducts.ICProductNo,
        ICProducts.ICProductName,
        ICProducts.ICProductDesc,
        ICProductWO.ICProductNo ICProductWONo,
        ICProductWO.ICProductName ICProductWOName,
        ICUOMs.ICUOMNo,
        ICUOMs.ICUOMName,
        ICStkUOMs.ICUOMNo ICStkUOMNo,
        ICStkUOMs.ICUOMName ICStkUOMName,
        APPOs.APPONo,
        ARSOs.ARSOName,
        ICReceiptItems.ICReceiptItemID
    FROM dbo.ICReceiptItems (NOLOCK) ICReceiptItems
        INNER JOIN dbo.ICReceipts (NOLOCK) ICReceipts
            ON ICReceiptItems.FK_ICReceiptID = ICReceipts.ICReceiptID
               AND ICReceiptItems.AAStatus = 'Alive'
               AND ICReceipts.AAStatus = 'Alive'
               AND ICReceipts.ICReceiptID = {?prICReceiptID}
        INNER JOIN dbo.ICProducts (NOLOCK) ICProducts
            ON ICReceiptItems.FK_ICProductID = ICProducts.ICProductID
               AND ICProducts.AAStatus = 'Alive'
        LEFT JOIN dbo.ICProducts (NOLOCK) ICProductWO
            ON ICReceiptItems.FK_ICProductIDWO = ICProductWO.ICProductID
               AND ICProductWO.AAStatus = 'Alive'
        LEFT JOIN dbo.ICStockSlots (NOLOCK) ICStockSlots
            ON ICReceiptItems.FK_ICStockSlotID = ICStockSlots.ICStockSlotID
               AND ICStockSlots.AAStatus = 'Alive'   
        LEFT JOIN dbo.ICStocks (NOLOCK) ICStocks
            ON ICReceipts.FK_ICStockID = ICStocks.ICStockID
               AND ICStocks.AAStatus = 'Alive'
        LEFT JOIN dbo.APSuppliers (NOLOCK) APSuppliers
            ON ICReceipts.FK_APSupplierID = APSuppliers.APSupplierID
               AND APSuppliers.AAStatus = 'Alive'
        LEFT JOIN dbo.APPOs (NOLOCK) APPOs
            ON ICReceiptItems.FK_APPOID = APPOs.APPOID
               AND APPOs.AAStatus = 'Alive'
        LEFT JOIN dbo.ICUOMs (NOLOCK) ICUOMs
            ON ICUOMs.ICUOMID = ICReceiptItems.FK_ICUOMID
               AND ICUOMs.AAStatus = 'Alive'
        LEFT JOIN dbo.ICUOMs (NOLOCK) ICStkUOMs
            ON ICStkUOMs.ICUOMID = ICReceiptItems.FK_ICStkUOMID
               AND ICStkUOMs.AAStatus = 'Alive'
        LEFT JOIN dbo.ARSOs ARSOs
            ON ARSOs.ARSOID = ICReceiptItems.FK_ARSOID
               AND ARSOs.AAStatus = 'Alive'
)
SELECT *
INTO #kq
FROM CTE
WHERE STT % 2 = 0
ORDER BY STT;

SELECT * FROM #kq;

DROP TABLE #kq;