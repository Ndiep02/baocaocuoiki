DECLARE @MSID INT = {?prPPMSID}

-- Chi ti?t h? s?
SELECT a.PPMSItemID,
       a.FK_PPMSItemID,
       a.FK_PPRoutingID,
       a.FK_ICProductID,
       pro.ICProductNo,
       pro.ICProductName,
       pro.ICProductCodes
INTO #ItemData
FROM dbo.PPMSItems a
INNER JOIN dbo.ICProducts pro
    ON pro.ICProductID = a.FK_ICProductID
    AND pro.AAStatus = a.AAStatus
WHERE a.AAStatus = 'Alive'
  AND a.FK_PPMSID = @MSID;

-- Thành ph?m g?c
SELECT TOP 1
    b.ICProductNo      AS ICProductNoRoot,
    b.ICProductName    AS ICProductNameRoot,
    b.ICProductCodes   AS ICProductCodesRoot
INTO #ProRoot
FROM #ItemData a
INNER JOIN dbo.ICProducts b
    ON b.ICProductID = a.FK_ICProductID
WHERE a.FK_PPMSItemID = 0;
-- Phân c?p s? th? t? - recursive CTE
WITH RecursiveCTE AS 
(
    SELECT a.PPMSItemID,
           a.FK_PPMSItemID,
           a.FK_PPRoutingID,
           a.ICProductNo,
           a.ICProductName,
           a.ICProductCodes,
           a.FK_ICProductID,
           CAST(1 AS INT) LV
    FROM #ItemData a
    WHERE a.FK_PPMSItemID = 0

    UNION ALL

    SELECT c.PPMSItemID,
           c.FK_PPMSItemID,
           c.FK_PPRoutingID,
           c.ICProductNo,
           c.ICProductName,
           c.ICProductCodes,
           c.FK_ICProductID,
           b.LV + 1
    FROM RecursiveCTE b 
    INNER JOIN #ItemData c ON c.FK_PPMSItemID = b.PPMSItemID
)
SELECT CAST(ROW_NUMBER() OVER (ORDER BY MIN(LV) DESC, MIN(b.PPRoutingOperationSortOrder)) AS INT) AS STT,
       PPMSItemID,
       b.FK_PPPhaseCfgID,
       MIN(LV) AS LV,
       MIN(b.PPRoutingOperationSortOrder) AS PhaseOrder,
       MAX(a.ICProductNo) AS ICProductNo,
       MAX(a.ICProductName) AS ICProductName,
       MAX(a.ICProductCodes) AS ICProductCodes,
       MAX(a.FK_PPMSItemID) AS FK_PPMSItemID,
       MAX(a.FK_ICProductID) AS FK_ICProductID
INTO #STT
FROM RecursiveCTE a
INNER JOIN dbo.PPRoutingOperations b
    ON b.FK_PPRoutingID = a.FK_PPRoutingID
    AND b.AAStatus = 'Alive'
GROUP BY PPMSItemID, b.FK_PPPhaseCfgID
ORDER BY MIN(LV) DESC, MIN(b.PPRoutingOperationSortOrder)

-- Mã BTP (g?p Name/Code/No thành ColDetail, xu?ng dòng b?ng CRLF)
SELECT 
    a.STT,
    a.FK_PPPhaseCfgID,
    a.PhaseOrder,
    a.PPMSItemID,
    CAST(N'BTP s? d?ng' AS NVARCHAR(100)) AS ColCaption,
  
    STUFF((
    SELECT CHAR(13) + CHAR(10) 
           + '  '+  ck.ICProductName 
           + CHAR(13) + CHAR(10) 
           + ck.ICProductCodes 
           + CHAR(13) + CHAR(10) 
           + ck.ICProductNo 
    FROM #STT ck
    WHERE ck.FK_PPMSItemID = a.PPMSItemID
    FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ColDetail,
    CAST('' AS NVARCHAR(MAX)) AS OFValueNo,
    CAST('' AS NVARCHAR(MAX)) AS OFValueName,
    CAST(NULL AS IMAGE) AS ColImage,
    CAST(1 AS INT) AS DataSort,
    CAST('BTP' AS VARCHAR(50)) AS DataGroup,
	   NULL AS IOFNum
INTO #KQ1
FROM #STT a
WHERE EXISTS (SELECT 1 FROM #STT b WHERE b.FK_PPMSItemID = a.PPMSItemID)

-- Yêu c?u k? thu?t
UNION ALL
SELECT a.STT,
       a.FK_PPPhaseCfgID,
       a.PhaseOrder,
       a.PPMSItemID,
       CAST(N'Yêu c?u k? thu?t:' AS NVARCHAR(100)) AS ColCaption,
       '' AS ColDetail,
       '' AS OFValueNo,
       '' AS OFValueName,
       CAST(NULL AS IMAGE) AS ColImage,
       2 AS DataSort,
       'YCKT' AS DataGroup,
	   NULL AS IOFNum
FROM #STT a

-- IOF04
UNION ALL
SELECT a.STT,
       a.FK_PPPhaseCfgID,
       a.PhaseOrder,
       a.PPMSItemID,
       CAST(N'' AS NVARCHAR(100)) AS ColCaption,
       iof.ADOFName AS ColDetail,
       pro.ICProductIOF04Combo AS OFValueNo,
       iofi.ADOFItemName AS OFValueName,
       CAST(NULL AS IMAGE) AS ColImage,
       3 AS DataSort,
       'IOF04' AS DataGroup,
	   CAST(SUBSTRING('IOF04', 4, LEN('IOF04')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF04' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF04Combo
WHERE pro.ICProductIOF04Combo IS NOT NULL AND LEN(pro.ICProductIOF04Combo) > 0


-- IOF05
UNION ALL
SELECT a.STT,
       a.FK_PPPhaseCfgID,
       a.PhaseOrder,
       a.PPMSItemID,
       CAST(N'' AS NVARCHAR(100)) AS ColCaption,
       iof.ADOFName AS ColDetail,
       pro.ICProductIOF05Combo AS OFValueNo,
       iofi.ADOFItemName AS OFValueName,
       CAST(NULL AS IMAGE) AS ColImage,
      3 AS DataSort,
       'IOF05' AS DataGroup,
	   CAST(SUBSTRING('IOF05', 4, LEN('IOF05')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof 
       ON iof.ADOFNo = 'IOF05' 
      AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi 
       ON iofi.FK_ADOFID = iof.ADOFID 
      AND iofi.AAStatus = 'Alive' 
      AND iofi.ADOFItemNo = pro.ICProductIOF05Combo
WHERE pro.ICProductIOF05Combo IS NOT NULL 
  AND LEN(pro.ICProductIOF05Combo) > 0


--IOF06
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF06Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF06' DataGroup,
		CAST(SUBSTRING('IOF06', 4, LEN('IOF06')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF06' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF06Combo
WHERE pro.ICProductIOF06Combo IS NOT NULL AND LEN(pro.ICProductIOF06Combo) > 0


--IOF07
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF07Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF07' DataGroup,
		CAST(SUBSTRING('IOF07', 4, LEN('IOF07')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF07' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF07Combo
WHERE pro.ICProductIOF07Combo IS NOT NULL AND LEN(pro.ICProductIOF07Combo) > 0


--IOF08
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF08Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF08' DataGroup,
		CAST(SUBSTRING('IOF08', 4, LEN('IOF08')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF08' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF08Combo
WHERE pro.ICProductIOF08Combo IS NOT NULL AND LEN(pro.ICProductIOF08Combo) > 0


--IOF09
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF09Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF09' DataGroup,
		CAST(SUBSTRING('IOF09', 4, LEN('IOF09')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF09' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF09Combo
WHERE pro.ICProductIOF09Combo IS NOT NULL AND LEN(pro.ICProductIOF09Combo) > 0


--IOF10
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF10Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF10' DataGroup,
		CAST(SUBSTRING('IOF10', 4, LEN('IOF10')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF10' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF10Combo
WHERE pro.ICProductIOF10Combo IS NOT NULL AND LEN(pro.ICProductIOF10Combo) > 0


--IOF11
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF11Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF11' DataGroup,
		CAST(SUBSTRING('IOF11', 4, LEN('IOF11')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF11' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF11Combo
WHERE pro.ICProductIOF11Combo IS NOT NULL AND LEN(pro.ICProductIOF11Combo) > 0


--IOF12
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF12Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF12' DataGroup,
		CAST(SUBSTRING('IOF12', 4, LEN('IOF12')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF12' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF12Combo
WHERE pro.ICProductIOF12Combo IS NOT NULL AND LEN(pro.ICProductIOF12Combo) > 0


--IOF13
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF13Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF13' DataGroup,
		CAST(SUBSTRING('IOF13', 4, LEN('IOF13')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF13' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF13Combo
WHERE pro.ICProductIOF13Combo IS NOT NULL AND LEN(pro.ICProductIOF13Combo) > 0


--IOF14
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF14Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF14' DataGroup,
		CAST(SUBSTRING('IOF14', 4, LEN('IOF14')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF14' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF14Combo
WHERE pro.ICProductIOF14Combo IS NOT NULL AND LEN(pro.ICProductIOF14Combo) > 0


--IOF15
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF15Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF15' DataGroup,
		CAST(SUBSTRING('IOF15', 4, LEN('IOF15')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF15' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF15Combo
WHERE pro.ICProductIOF15Combo IS NOT NULL AND LEN(pro.ICProductIOF15Combo) > 0


--IOF16
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF16Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF16' DataGroup,
		CAST(SUBSTRING('IOF16', 4, LEN('IOF16')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF16' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF16Combo
WHERE pro.ICProductIOF16Combo IS NOT NULL AND LEN(pro.ICProductIOF16Combo) > 0


--IOF17
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF17Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF17' DataGroup,
		CAST(SUBSTRING('IOF17', 4, LEN('IOF17')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF17' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF17Combo
WHERE pro.ICProductIOF17Combo IS NOT NULL AND LEN(pro.ICProductIOF17Combo) > 0


--IOF18
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF18Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF18' DataGroup,
		CAST(SUBSTRING('IOF18', 4, LEN('IOF18')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF18' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF18Combo
WHERE pro.ICProductIOF18Combo IS NOT NULL AND LEN(pro.ICProductIOF18Combo) > 0


--IOF19
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF19Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF19' DataGroup,
		CAST(SUBSTRING('IOF19', 4, LEN('IOF19')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF19' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF19Combo
WHERE pro.ICProductIOF19Combo IS NOT NULL AND LEN(pro.ICProductIOF19Combo) > 0


--IOF20
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF20Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF20' DataGroup,
		CAST(SUBSTRING('IOF20', 4, LEN('IOF20')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF20' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF20Combo
WHERE pro.ICProductIOF20Combo IS NOT NULL AND LEN(pro.ICProductIOF20Combo) > 0


--IOF21
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF21Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF21' DataGroup,
		CAST(SUBSTRING('IOF21', 4, LEN('IOF21')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF21' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF21Combo
WHERE pro.ICProductIOF21Combo IS NOT NULL AND LEN(pro.ICProductIOF21Combo) > 0


--IOF22
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF22Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF22' DataGroup,
		CAST(SUBSTRING('IOF22', 4, LEN('IOF22')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF22' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF22Combo
WHERE pro.ICProductIOF22Combo IS NOT NULL AND LEN(pro.ICProductIOF22Combo) > 0


--IOF23
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF23Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF23' DataGroup,
		CAST(SUBSTRING('IOF23', 4, LEN('IOF23')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF23' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF23Combo
WHERE pro.ICProductIOF23Combo IS NOT NULL AND LEN(pro.ICProductIOF23Combo) > 0


--IOF24
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF24Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF24' DataGroup,
		CAST(SUBSTRING('IOF24', 4, LEN('IOF24')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF24' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF24Combo
WHERE pro.ICProductIOF24Combo IS NOT NULL AND LEN(pro.ICProductIOF24Combo) > 0


--IOF25
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF25Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF25' DataGroup,
		CAST(SUBSTRING('IOF25', 4, LEN('IOF25')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF25' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF25Combo
WHERE pro.ICProductIOF25Combo IS NOT NULL AND LEN(pro.ICProductIOF25Combo) > 0


--IOF26
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF26Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF26' DataGroup,
		CAST(SUBSTRING('IOF26', 4, LEN('IOF26')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF26' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF26Combo
WHERE pro.ICProductIOF26Combo IS NOT NULL AND LEN(pro.ICProductIOF26Combo) > 0


--IOF27
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF27Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF27' DataGroup,
		CAST(SUBSTRING('IOF27', 4, LEN('IOF27')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF27' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF27Combo
WHERE pro.ICProductIOF27Combo IS NOT NULL AND LEN(pro.ICProductIOF27Combo) > 0


--IOF28
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF28Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF28' DataGroup,
		CAST(SUBSTRING('IOF28', 4, LEN('IOF28')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF28' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF28Combo
WHERE pro.ICProductIOF28Combo IS NOT NULL AND LEN(pro.ICProductIOF28Combo) > 0


--IOF29
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF29Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF29' DataGroup,
		CAST(SUBSTRING('IOF29', 4, LEN('IOF29')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF29' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF29Combo
WHERE pro.ICProductIOF29Combo IS NOT NULL AND LEN(pro.ICProductIOF29Combo) > 0


--IOF30
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF30Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF30' DataGroup,
		CAST(SUBSTRING('IOF30', 4, LEN('IOF30')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF30' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF30Combo
WHERE pro.ICProductIOF30Combo IS NOT NULL AND LEN(pro.ICProductIOF30Combo) > 0


--IOF31
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF31Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF31' DataGroup,
		CAST(SUBSTRING('IOF31', 4, LEN('IOF31')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF31' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF31Combo
WHERE pro.ICProductIOF31Combo IS NOT NULL AND LEN(pro.ICProductIOF31Combo) > 0


--IOF32
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF32Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF32' DataGroup,
		CAST(SUBSTRING('IOF32', 4, LEN('IOF32')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF32' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF32Combo
WHERE pro.ICProductIOF32Combo IS NOT NULL AND LEN(pro.ICProductIOF32Combo) > 0


--IOF33
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF33Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF33' DataGroup,
		CAST(SUBSTRING('IOF33', 4, LEN('IOF33')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF33' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF33Combo
WHERE pro.ICProductIOF33Combo IS NOT NULL AND LEN(pro.ICProductIOF33Combo) > 0


--IOF34
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF34Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF34' DataGroup,
		CAST(SUBSTRING('IOF34', 4, LEN('IOF34')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF34' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF34Combo
WHERE pro.ICProductIOF34Combo IS NOT NULL AND LEN(pro.ICProductIOF34Combo) > 0


--IOF35
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF35Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF35' DataGroup,
		CAST(SUBSTRING('IOF35', 4, LEN('IOF35')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF35' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF35Combo
WHERE pro.ICProductIOF35Combo IS NOT NULL AND LEN(pro.ICProductIOF35Combo) > 0


--IOF36
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF36Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF36' DataGroup,
		CAST(SUBSTRING('IOF36', 4, LEN('IOF36')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF36' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF36Combo
WHERE pro.ICProductIOF36Combo IS NOT NULL AND LEN(pro.ICProductIOF36Combo) > 0


--IOF37
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF37Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF37' DataGroup,
		CAST(SUBSTRING('IOF37', 4, LEN('IOF37')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF37' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF37Combo
WHERE pro.ICProductIOF37Combo IS NOT NULL AND LEN(pro.ICProductIOF37Combo) > 0


--IOF38
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF38Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF38' DataGroup,
		CAST(SUBSTRING('IOF38', 4, LEN('IOF38')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF38' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF38Combo
WHERE pro.ICProductIOF38Combo IS NOT NULL AND LEN(pro.ICProductIOF38Combo) > 0


--IOF39
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF39Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF39' DataGroup,
		CAST(SUBSTRING('IOF39', 4, LEN('IOF39')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF39' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF39Combo
WHERE pro.ICProductIOF39Combo IS NOT NULL AND LEN(pro.ICProductIOF39Combo) > 0


--IOF40
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF40Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF40' DataGroup,
		CAST(SUBSTRING('IOF40', 4, LEN('IOF40')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF40' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF40Combo
WHERE pro.ICProductIOF40Combo IS NOT NULL AND LEN(pro.ICProductIOF40Combo) > 0


--IOF41
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF41Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF41' DataGroup,
		CAST(SUBSTRING('IOF41', 4, LEN('IOF41')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF41' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF41Combo
WHERE pro.ICProductIOF41Combo IS NOT NULL AND LEN(pro.ICProductIOF41Combo) > 0


--IOF42
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF42Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF42' DataGroup,
		CAST(SUBSTRING('IOF42', 4, LEN('IOF42')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF42' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF42Combo
WHERE pro.ICProductIOF42Combo IS NOT NULL AND LEN(pro.ICProductIOF42Combo) > 0


--IOF43
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF43Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF43' DataGroup,
		CAST(SUBSTRING('IOF43', 4, LEN('IOF43')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF43' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF43Combo
WHERE pro.ICProductIOF43Combo IS NOT NULL AND LEN(pro.ICProductIOF43Combo) > 0


--IOF44
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF44Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF44' DataGroup,
		CAST(SUBSTRING('IOF44', 4, LEN('IOF44')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF44' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF44Combo
WHERE pro.ICProductIOF44Combo IS NOT NULL AND LEN(pro.ICProductIOF44Combo) > 0


--IOF45
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF45Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF45' DataGroup,
		CAST(SUBSTRING('IOF45', 4, LEN('IOF45')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF45' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF45Combo
WHERE pro.ICProductIOF45Combo IS NOT NULL AND LEN(pro.ICProductIOF45Combo) > 0


--IOF46
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF46Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF46' DataGroup,
		CAST(SUBSTRING('IOF46', 4, LEN('IOF46')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF46' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF46Combo
WHERE pro.ICProductIOF46Combo IS NOT NULL AND LEN(pro.ICProductIOF46Combo) > 0


--IOF47
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF47Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF47' DataGroup,
		CAST(SUBSTRING('IOF47', 4, LEN('IOF47')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF47' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF47Combo
WHERE pro.ICProductIOF47Combo IS NOT NULL AND LEN(pro.ICProductIOF47Combo) > 0


--IOF48
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF48Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF48' DataGroup,
		CAST(SUBSTRING('IOF48', 4, LEN('IOF48')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF48' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF48Combo
WHERE pro.ICProductIOF48Combo IS NOT NULL AND LEN(pro.ICProductIOF48Combo) > 0


--IOF49
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF49Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF49' DataGroup,
		CAST(SUBSTRING('IOF49', 4, LEN('IOF49')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF49' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF49Combo
WHERE pro.ICProductIOF49Combo IS NOT NULL AND LEN(pro.ICProductIOF49Combo) > 0


--IOF50
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF50Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF50' DataGroup,
		CAST(SUBSTRING('IOF50', 4, LEN('IOF50')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF50' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF50Combo
WHERE pro.ICProductIOF50Combo IS NOT NULL AND LEN(pro.ICProductIOF50Combo) > 0


--IOF51
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF51Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF51' DataGroup,
		CAST(SUBSTRING('IOF51', 4, LEN('IOF51')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF51' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF51Combo
WHERE pro.ICProductIOF51Combo IS NOT NULL AND LEN(pro.ICProductIOF51Combo) > 0


--IOF52
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF52Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF52' DataGroup,
		CAST(SUBSTRING('IOF52', 4, LEN('IOF52')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF52' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF52Combo
WHERE pro.ICProductIOF52Combo IS NOT NULL AND LEN(pro.ICProductIOF52Combo) > 0


--IOF53
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF53Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF53' DataGroup,
		CAST(SUBSTRING('IOF53', 4, LEN('IOF53')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF53' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF53Combo
WHERE pro.ICProductIOF53Combo IS NOT NULL AND LEN(pro.ICProductIOF53Combo) > 0


--IOF54
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF54Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF54' DataGroup,
		CAST(SUBSTRING('IOF54', 4, LEN('IOF54')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF54' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF54Combo
WHERE pro.ICProductIOF54Combo IS NOT NULL AND LEN(pro.ICProductIOF54Combo) > 0


--IOF55
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF55Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF55' DataGroup,
		CAST(SUBSTRING('IOF55', 4, LEN('IOF55')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF55' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF55Combo
WHERE pro.ICProductIOF55Combo IS NOT NULL AND LEN(pro.ICProductIOF55Combo) > 0


--IOF56
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF56Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF56' DataGroup,
		CAST(SUBSTRING('IOF56', 4, LEN('IOF56')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF56' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF56Combo
WHERE pro.ICProductIOF56Combo IS NOT NULL AND LEN(pro.ICProductIOF56Combo) > 0


--IOF57
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF57Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF57' DataGroup,
		CAST(SUBSTRING('IOF57', 4, LEN('IOF57')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF57' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF57Combo
WHERE pro.ICProductIOF57Combo IS NOT NULL AND LEN(pro.ICProductIOF57Combo) > 0


--IOF58
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF58Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF58' DataGroup,
		CAST(SUBSTRING('IOF58', 4, LEN('IOF58')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF58' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF58Combo
WHERE pro.ICProductIOF58Combo IS NOT NULL AND LEN(pro.ICProductIOF58Combo) > 0


--IOF59
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF59Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF59' DataGroup,
		CAST(SUBSTRING('IOF59', 4, LEN('IOF59')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF59' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF59Combo
WHERE pro.ICProductIOF59Combo IS NOT NULL AND LEN(pro.ICProductIOF59Combo) > 0


--IOF60
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF60Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF60' DataGroup,
		CAST(SUBSTRING('IOF60', 4, LEN('IOF60')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF60' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF60Combo
WHERE pro.ICProductIOF60Combo IS NOT NULL AND LEN(pro.ICProductIOF60Combo) > 0


--IOF61
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF61Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF61' DataGroup,
		CAST(SUBSTRING('IOF61', 4, LEN('IOF61')) AS INT) AS IOFNum


FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF61' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF61Combo
WHERE pro.ICProductIOF61Combo IS NOT NULL AND LEN(pro.ICProductIOF61Combo) > 0


--IOF62
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF62Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF62' DataGroup,
		CAST(SUBSTRING('IOF62', 4, LEN('IOF62')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF62' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF62Combo
WHERE pro.ICProductIOF62Combo IS NOT NULL AND LEN(pro.ICProductIOF62Combo) > 0


--IOF63
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF63Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF63' DataGroup,
		CAST(SUBSTRING('IOF63', 4, LEN('IOF63')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF63' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF63Combo
WHERE pro.ICProductIOF63Combo IS NOT NULL AND LEN(pro.ICProductIOF63Combo) > 0


--IOF64
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF64Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF64' DataGroup,
		CAST(SUBSTRING('IOF64', 4, LEN('IOF64')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF64' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF64Combo
WHERE pro.ICProductIOF64Combo IS NOT NULL AND LEN(pro.ICProductIOF64Combo) > 0


--IOF65
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF65Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF65' DataGroup,
		CAST(SUBSTRING('IOF65', 4, LEN('IOF65')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF65' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF65Combo
WHERE pro.ICProductIOF65Combo IS NOT NULL AND LEN(pro.ICProductIOF65Combo) > 0


--IOF66
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF66Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF66' DataGroup,
		CAST(SUBSTRING('IOF66', 4, LEN('IOF66')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF66' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF66Combo
WHERE pro.ICProductIOF66Combo IS NOT NULL AND LEN(pro.ICProductIOF66Combo) > 0


--IOF67
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF67Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF67' DataGroup,
		CAST(SUBSTRING('IOF67', 4, LEN('IOF67')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF67' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF67Combo
WHERE pro.ICProductIOF67Combo IS NOT NULL AND LEN(pro.ICProductIOF67Combo) > 0


--IOF68
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF68Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF68' DataGroup,
		CAST(SUBSTRING('IOF68', 4, LEN('IOF68')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF68' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF68Combo
WHERE pro.ICProductIOF68Combo IS NOT NULL AND LEN(pro.ICProductIOF68Combo) > 0


--IOF69
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF69Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF69' DataGroup,
		CAST(SUBSTRING('IOF69', 4, LEN('IOF69')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF69' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF69Combo
WHERE pro.ICProductIOF69Combo IS NOT NULL AND LEN(pro.ICProductIOF69Combo) > 0


--IOF70
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF70Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF70' DataGroup
		,
		CAST(SUBSTRING('IOF70', 4, LEN('IOF70')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF70' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF70Combo
WHERE pro.ICProductIOF70Combo IS NOT NULL AND LEN(pro.ICProductIOF70Combo) > 0


--IOF71
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,pro.ICProductIOF71Combo OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF71' DataGroup,
		CAST(SUBSTRING('IOF71', 4, LEN('IOF71')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
LEFT JOIN dbo.ADOFs iof ON iof.ADOFNo = 'IOF71' AND iof.AAStatus = 'Alive'
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = pro.ICProductIOF71Combo
WHERE pro.ICProductIOF71Combo IS NOT NULL AND LEN(pro.ICProductIOF71Combo) > 0


--IOF100
UNION ALL 
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,code.ICProductICodeValue OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF100' DataGroup,
		CAST(SUBSTRING('IOF100', 4, LEN('IOF100')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
INNER JOIN dbo.ICProductICodes code ON (code.FK_ICProductID = pro.ICProductID AND code.AAStatus ='Alive')
INNER JOIN dbo.ADOFs iof ON (iof.ADOFNo = 'IOF100' AND iof.AAStatus = 'Alive' AND code.FK_ADOFID=iof.ADOFID)
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = code.ICProductICodeValue
WHERE code.ICProductICodeValue IS NOT NULL AND LEN(code.ICProductICodeValue) > 0
--IOF101
UNION ALL 
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'' AS NVARCHAR(100)) ColCaption
		,iof.ADOFName ColDetail
		,code.ICProductICodeValue OFValueNo
		,iofi.ADOFItemName OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,3 DataSort
		,'IOF101' DataGroup
		,
		CAST(SUBSTRING('IOF101', 4, LEN('IOF101')) AS INT) AS IOFNum
FROM #STT a
INNER JOIN dbo.ICProducts pro ON pro.ICProductID = a.FK_ICProductID
INNER JOIN dbo.ICProductICodes code ON (code.FK_ICProductID = pro.ICProductID AND code.AAStatus ='Alive')
INNER JOIN dbo.ADOFs iof ON (iof.ADOFNo = 'IOF101' AND iof.AAStatus = 'Alive' AND code.FK_ADOFID=iof.ADOFID)
LEFT JOIN dbo.ADOFItems iofi ON iofi.FK_ADOFID = iof.ADOFID AND iofi.AAStatus = 'Alive' AND iofi.ADOFItemNo = code.ICProductICodeValue
WHERE code.ICProductICodeValue IS NOT NULL AND LEN(code.ICProductICodeValue) > 0

-- Tên TP (gom Name/Code/No thành ColDetail, xu?ng dòng)
UNION ALL
SELECT a.STT,
       a.FK_PPPhaseCfgID,
       a.PhaseOrder,
       a.PPMSItemID,
       CAST(N'Ký hi?u bán thành ph?m' AS NVARCHAR(100)) AS ColCaption,
       pro.ICProductName 
       + CHAR(13) + CHAR(10) 
       + pro.ICProductCodes 
       + CHAR(13) + CHAR(10) 
       + pro.ICProductNo AS ColDetail,
       CAST('' AS NVARCHAR(MAX)) AS OFValueNo,
       CAST('' AS NVARCHAR(MAX)) AS OFValueName,
       CAST(NULL AS IMAGE) AS ColImage,
       4 AS DataSort,
       'TP' AS DataGroup,
	   NULL AS IOFNum
FROM #STT a
LEFT JOIN dbo.ICProducts pro 
       ON pro.ICProductID = a.FK_ICProductID

--Yêu c?u s?n ph?m
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,CAST( N'Yêu c?u s?n ph?m' AS NVARCHAR(100)) ColCaption
		,'' ColDetail
		,CAST('' AS NVARCHAR(MAX)) OFValueNo
		,CAST('' AS NVARCHAR(MAX)) OFValueName
		,CAST(NULL AS IMAGE) ColImage
		,5 DataSort
		,'YC' DataGroup,
	   NULL AS IOFNum
FROM #STT a
--H??ng d?n s?n xu?t
UNION ALL
SELECT a.STT,a.FK_PPPhaseCfgID,a.PhaseOrder,a.PPMSItemID
		,'' ColCaption
		,IIF(c.PPMSItemInstructionDocDesc IS NULL OR LEN(c.PPMSItemInstructionDocDesc) = 0,b.PPMSItemInstructionDesc,c.PPMSItemInstructionDocDesc) ColDetail
		,CAST('' AS NVARCHAR(MAX)) OFValueNo
		,CAST('' AS NVARCHAR(MAX)) OFValueName
		,c.PPMSItemInstructionDocImage ColImage
		,6 DataSort
		,'Instruction' DataGroup,
	   NULL AS IOFNum
FROM #STT a
INNER JOIN dbo.PPMSItemInstructions b ON b.FK_PPMSItemID = a.PPMSItemID
									AND b.FK_PPPhaseCfgID = a.FK_PPPhaseCfgID
									AND b.AAStatus = 'Alive'
LEFT JOIN dbo.PPMSItemInstructionDocs c ON c.FK_PPMSItemInstructionID = b.PPMSItemInstructionID
										AND c.AAStatus = 'Alive'
DELETE #KQ1
WHERE STT  = (SELECT MAX(cke.STT) FROM #STT cke)
		AND DataGroup <> 'YC' AND DataGroup <> 'Instruction'
--T?ng k?t
SELECT CASE WHEN NOT EXISTS(SELECT 'x' FROM #KQ1 cke WHERE cke.STT = a.STT AND cke.PhaseOrder = a.PhaseOrder AND cke.FK_PPPhaseCfgID = a.FK_PPPhaseCfgID AND cke.DataSort < a.DataSort)
			THEN CAST(a.STT AS VARCHAR(10)) ELSE '' END STT
		,CASE WHEN NOT EXISTS(SELECT 'x' FROM #KQ1 cke WHERE cke.STT = a.STT AND cke.PhaseOrder = a.PhaseOrder AND cke.FK_PPPhaseCfgID = a.FK_PPPhaseCfgID AND cke.DataSort < a.DataSort)
			THEN b.PPPhaseCfgName ELSE '' END Phase
		,CASE WHEN NOT EXISTS(SELECT 'x' FROM #KQ1 cke WHERE cke.STT = a.STT AND cke.PhaseOrder = a.PhaseOrder AND cke.FK_PPPhaseCfgID = a.FK_PPPhaseCfgID AND cke.DataSort < a.DataSort)
			THEN ws.PPWorkCenterName ELSE '' END PPWorkCenterName
		,a.ColCaption
		,a.ColDetail
		,a.OFValueNo
		,a.OFValueName
		,a.ColImage
		,a.DataSort
		,a.STT ORDER1
		,a.PhaseOrder ORDER2
		,d.PPMSNo
		,CAST(d.PPMSDate AS DATETIME) PPMSDate
		,d.PPMSDesc
		,d.PPMSRevision
		,e.*
		,a.DataGroup
		,a.IOFNum
		,CAST(ROW_NUMBER() OVER (ORDER BY a.STT,a.PhaseOrder,a.DataSort) AS INT) RowNumber
		,aproval.HREmployeeName1Aproval
		,aproval.HREmployeeSignature1Picture
		,aproval.HREmployeeName2Aproval
		,aproval.HREmployeeSignature2Picture
		,aproval.HREmployeeName3Aproval
		,aproval.HREmployeeSignature3Picture
		,aproval.HREmployeeName4Aproval
		,aproval.HREmployeeSignature4Picture
		,aproval.HREmployeeName5Aproval
		,aproval.HREmployeeSignature5Picture
FROM #KQ1 a
LEFT JOIN dbo.PPPhaseCfgs b ON b.PPPhaseCfgID = a.FK_PPPhaseCfgID
LEFT JOIN dbo.PPWorkCenters ws ON ws.PPWorkCenterID = b.FK_PPWorkCenterID
LEFT JOIN dbo.PPMSItems c ON c.PPMSItemID = a.PPMSItemID
LEFT JOIN dbo.PPMSs d ON d.PPMSID = c.FK_PPMSID
LEFT JOIN #ProRoot e ON 1=1
LEFT JOIN (SELECT * FROM dbo.Fnc_GetDocEployeeAproval(@MSID,'MSDS')) aproval ON aproval.DocID = d.PPMSID

ORDER BY a.STT,a.PhaseOrder,a.DataSort, a.IOFNum
DROP TABLE #ItemData
DROP TABLE #STT
DROP TABLE #KQ1
DROP TABLE #ProRoot