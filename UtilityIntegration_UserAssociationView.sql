-- CREATE VIEW utility_user_assoc_view AS

-- Utility Integration View - User Associations
-- Written By: Luis Moraguez
-- Date: 8/21/2018

-- # Licensed under the GNU LESSER GENERAL PUBLIC LICENSE <https://www.gnu.org/licenses/lgpl-3.0.en.html>

-- ### Installation services available if needed. Basic service includes:
---- # Tayloring the views to your environment, locality (state plane formulas), & features needed
---- # Training on the features available

-- ### Additional/Optional services
---- # Integrating with the CAD Training Environment
---- # Updating integration as new features are added

-- Live Data
SELECT (SUBSTRING(a.inci_id, 1, 2)+'-'+SUBSTRING(a.inci_id, 3, 4)+'-'+SUBSTRING(a.inci_id, 7, 4)) AS inci_id, b.transtype, b.timestamp, c.emdept_id, c.name, c.intime, c.outtime
FROM [cad].[dbo].[incident] a
INNER JOIN [cad].[dbo].[log] b ON a.inci_id = b.inci_id 
INNER JOIN [cad].[dbo].[unitper] c ON b.unitperid = c.unitperid
WHERE
(a.inci_id <> '') AND
(service = 'LAW') AND
((ISNUMERIC(c.emdept_id) = 1) OR c.emdept_id LIKE 'CE%') AND
(a.calltime >= DATEADD(DD, -1, GETDATE())) AND
((a.latitude <> '0') OR (a.latitude <> '')) AND
((a.longitude <> '0') OR (a.longitude <> '')) AND
(a.naturecode <> '') AND
b.transtype IN ('A','DA')

UNION -- Historical data

SELECT (SUBSTRING(a.inci_id, 1, 2)+'-'+SUBSTRING(a.inci_id, 3, 4)+'-'+SUBSTRING(a.inci_id, 7, 4)) AS inci_id, b.transtype, b.timestamp, c.emdept_id, c.name, c.intime, c.outtime
FROM [cad].[dbo].[inmain] a
INNER JOIN [cad].[dbo].[incilog] b ON a.inci_id = b.inci_id 
INNER JOIN [cad].[dbo].[unitper] c ON b.unitperid = c.unitperid
WHERE
(a.inci_id <> '') AND
(service = 'LAW') AND
((ISNUMERIC(c.emdept_id) = 1) OR c.emdept_id LIKE 'CE%') AND
(a.calltime >= DATEADD(DD, -1, GETDATE())) AND
((a.latitude <> '0') OR (a.latitude <> '')) AND
((a.longitude <> '0') OR (a.longitude <> '')) AND
(a.naturecode <> '') AND
b.transtype IN ('A','DA')
