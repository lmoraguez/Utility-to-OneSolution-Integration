-- CREATE VIEW utility_integration_view AS

-- Utility Integration View
-- Written By: Luis Moraguez
-- Date: 8/21/2018
-- Revised By: Luis Moraguez
-- Revised: 3/5/2019
-- Revision: 2

-- # Licensed under the GNU LESSER GENERAL PUBLIC LICENSE <https://www.gnu.org/licenses/lgpl-3.0.en.html>

-- ### Installation services available if needed. Basic service includes:
---- # Tailoring the views to your environment, locality (state plane formulas), & features needed
---- # Training on the features available

-- ### Additional/Optional services
---- # Integrating with the CAD Training Environment
---- # Updating integration as new features are added


-- CAD Event Number -> Utility CADS Number
-- Case Number -> Utility Case Number
-- Date (calltime)
-- Time (calltime)
-- Lat
-- Long
-- Address (street) + (citydesc) + (state = 'FL') + (zip)
-- Classification Type (Traffic Stop, Arrest, Burglary, etc) (expcode)
-- Officer Name

-- Multiple calls are linked to the same event number by dispatch if they are related
-- Classification can be maintained by editing the export code under Nature Code Maintenance in CAD
---- Export code must match how it is shown in AVaiL Classifications in order for auto-classification to work
-- When inci_id is blank, accident has been cleared: filter using (inci_id <> '')

-- Sources for Formula:
---- https://social.msdn.microsoft.com/Forums/sqlserver/en-US/9a33d577-5b0f-4c9e-afc1-6eb176888ab1/convert-data-values-in-columns-to-another-value-based-on-a-math-formula?forum=transactsql
---- http://www.homedatasheet.com/flsp/
---- http://georepository.com/projection_15318/SPCS83-Florida-East-zone-US-Survey-feet.html


-- Statement for when callsource is SELF or SCHED
-- geox and geoy are the State Plane coordinates (FL EAST NAD1983 0901) of the actual location of incident because that is where officer self-dispatched
-- Latitude and Longitude has to be calculated

		SELECT (SUBSTRING(inci_id, 1, 2)+'-'+SUBSTRING(inci_id, 3, 4)+'-'+SUBSTRING(inci_id, 7, 4)) AS inci_id,
				CASE WHEN case_id = '' THEN '' ELSE (SUBSTRING(case_id, 1, 2)+'-'+SUBSTRING(case_id, 3, 6)) END AS case_id,
				calltime,
				NULL AS timeclose,
				callsource,
				street,
				citydesc AS city,
				state = 'FL',
				zip,
				CASE WHEN b.expcode = 'ACCIDENT' THEN 'Accident'
					 WHEN b.expcode = 'ARREST' THEN 'Arrest'
					 WHEN b.expcode = 'DOMESTIC' THEN 'Domestic'
					 WHEN b.expcode = 'DRUGS' THEN 'Drugs'
					 WHEN b.expcode = 'FELONY' THEN 'Felony'
					 WHEN b.expcode = 'HOMICIDE' THEN 'Homicide'
					 WHEN b.expcode = 'TRAFFIC' THEN 'Traffic Stop'
					 WHEN b.expcode = 'TRAINING' THEN 'Training'
					 WHEN b.expcode = 'WEAPONS' THEN 'Weapons'
					 ELSE 'Other' END AS classification,
				Latitude,
				Longitude,
				substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS badge,
				substring((SELECT '; ' + RTRIM(LTRIM(name)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS officer
		 FROM [cad].[dbo].[incident] a
		  Cross Apply  
			(
				Select 
				 N0 = 0.0,						--False Northing		
				 E0 = 656166.6666666665,		--False Easting
				 K0 = 0.9999411764705882,		--Scale Factor
				 e = 0.08181919111988833,
				 ePrime = 0.08208852110265381,
				 V0 = 0.005022893948,
				 V2 = 0.000029370625,
				 V4 = 0.000000235059,
				 V6 = 0.000000002181,
				 L0 = 81.0,						--Central Meridian
				 Easting = CAST(geox AS DECIMAL(18,10)), 
				 Northing = CAST(geoy AS DECIMAL(18,10))
			) as CAStatic
			Cross Apply 
			  (
					Select m2sft = 1200.0/3937.0,
						   EPrime2 = Easting - E0
			  ) as CAComputed1
			Cross Apply 
				(
					Select  S0 = 2692050.5001/m2sft,
	  						 r = 6367449.14577/m2sft,
							 a = 6378137.0/m2sft
				) as CAComputed2
			Cross Apply
				(
					Select
						w = (Northing - N0 + S0)/(K0*r)
				) as CAComputed4						  
			Cross Apply
				(
					Select
						[of] = w + (sin(w)*cos(w))*(V0 + V2*power(cos(w),2) + V4*power(cos(w),4) + V6*power(cos(w),6))
				) as CAComputed5						  
			Cross Apply
				(
					Select
						Rf = K0*a/sqrt((1 - power(e,2)*power(sin([of]),2))),
						tf = tan([of]),
						nf = ePrime*cos([of]) 
				) as CAComputed6						  
			Cross Apply
				(
					Select
							Q = EPrime2/Rf,
							B2 = -0.5 * tf * (1 + POWER(nf,2)),
							B4 = -1/12*(5 + 3 * POWER(tf,2) +POWER(nf,2) * (1-9 * POWER(tf,2)) - 4 * POWER(nf,4)),
							B6 = 1/360*(61 + 90*POWER(tf,2) + 45*POWER(tf,4) + POWER(nf,2)*(46 - 252*POWER(tf,2) - 90*POWER(tf,4)))
				) as CAComputed7						  
			Cross Apply
				(
					Select
							Latitude = ([of] + B2*POWER(Q,2)*(1 + POWER(Q,2)*(B4 + B6*POWER(Q,2))))*180/(PI()),
							B3 = -1/6*(1 + 2*POWER(tf,2) + POWER(nf,2)),
							B5 = 1/120*(5 + 28*POWER(tf,2) + 24*POWER(tf,4) + POWER(nf,2)*(6 + 8*POWER(tf,2))),
							B7 = -1/5040*(61 + 662*POWER(tf,2) + 1320*POWER(tf,4) + 720*POWER(tf,6))
				) as CAComputed8						  
			Cross Apply
				(
					Select 
							L = Q*(1 + POWER(Q,2)*(B3 + POWER(Q,2)*(B5 + B7*POWER(Q,2))))
				) as CAComputed9
			Cross Apply
				(
					Select 
							Longitude = (L0 - (L/cos([of]))*180/(PI()))*-1
				) as CAComputedLatLong
				-- Join to get export code from nature table
				INNER JOIN [cad].[dbo].[nature] b ON a.natureid = b.natureid
			WHERE callsource IN ('SELF', 'SCHED') AND
			(inci_id <> '') AND
			(service = 'LAW') AND
			(calltime >= DATEADD(DD, -1, GETDATE())) AND
			(a.naturecode <> '') AND
			(substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) IS NOT NULL)
-- End calculation of Latitude and Longitude				
				
UNION -- Combine with results from other callsource

-- When callsource is not SELF or SCHED, geox and geoy just represent the State Plane Coords of where the officer was dispatched from
-- Latitude and Longitude are the actual location of the incident and don't need to be calculated
SELECT (SUBSTRING(inci_id, 1, 2)+'-'+SUBSTRING(inci_id, 3, 4)+'-'+SUBSTRING(inci_id, 7, 4)) AS inci_id,
		CASE WHEN case_id = '' THEN '' ELSE (SUBSTRING(case_id, 1, 2)+'-'+SUBSTRING(case_id, 3, 6)) END AS case_id,
		calltime,
		NULL AS timeclose,
		callsource,
		street,
		citydesc AS city,
		state = 'FL',
		zip,
		CASE WHEN b.expcode = 'ACCIDENT' THEN 'Accident'
			 WHEN b.expcode = 'ARREST' THEN 'Arrest'
			 WHEN b.expcode = 'DOMESTIC' THEN 'Domestic'
			 WHEN b.expcode = 'DRUGS' THEN 'Drugs'
			 WHEN b.expcode = 'FELONY' THEN 'Felony'
			 WHEN b.expcode = 'HOMICIDE' THEN 'Homicide'
			 WHEN b.expcode = 'TRAFFIC' THEN 'Traffic Stop'
			 WHEN b.expcode = 'TRAINING' THEN 'Training'
			 WHEN b.expcode = 'WEAPONS' THEN 'Weapons'
			 ELSE 'Other' END AS classification,
		latitude,
		longitude,
		substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS badge,
		substring((SELECT '; ' + RTRIM(LTRIM(name)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS officer
FROM [cad].[dbo].[incident] a
-- Join to get export code from nature table
INNER JOIN [cad].[dbo].[nature] b ON a.natureid = b.natureid 
WHERE callsource NOT IN ('SELF', 'SCHED') AND
(inci_id <> '') AND
(service = 'LAW') AND
(calltime >= DATEADD(DD, -1, GETDATE())) AND
((latitude <> '0') OR (latitude <> '')) AND
((longitude <> '0') OR (longitude <> '')) AND
(a.naturecode <> '') AND
(substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) IS NOT NULL)

UNION /*Combine with historical data*/

-- Statement for when callsource is SELF or SCHED
-- geox and geoy are the State Plane coordinates (FL EAST NAD1983 0901) of the actual location of incident because that is where officer self-dispatched
-- Latitude and Longitude has to be calculated

		SELECT (SUBSTRING(inci_id, 1, 2)+'-'+SUBSTRING(inci_id, 3, 4)+'-'+SUBSTRING(inci_id, 7, 4)) AS inci_id,
				CASE WHEN case_id = '' THEN '' ELSE (SUBSTRING(case_id, 1, 2)+'-'+SUBSTRING(case_id, 3, 6)) END AS case_id,
				calltime,
				timeclose,
				callsource,
				street,
				citydesc AS city,
				state = 'FL',
				zip,
				CASE WHEN b.expcode = 'ACCIDENT' THEN 'Accident'
					 WHEN b.expcode = 'ARREST' THEN 'Arrest'
					 WHEN b.expcode = 'DOMESTIC' THEN 'Domestic'
					 WHEN b.expcode = 'DRUGS' THEN 'Drugs'
					 WHEN b.expcode = 'FELONY' THEN 'Felony'
					 WHEN b.expcode = 'HOMICIDE' THEN 'Homicide'
					 WHEN b.expcode = 'TRAFFIC' THEN 'Traffic Stop'
					 WHEN b.expcode = 'TRAINING' THEN 'Training'
					 WHEN b.expcode = 'WEAPONS' THEN 'Weapons'
					 ELSE 'Other' END AS classification,
				Latitude,
				Longitude,
				substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS badge,
				substring((SELECT '; ' + RTRIM(LTRIM(name)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS officer
		 FROM [cad].[dbo].[inmain] a
		  Cross Apply  
			(
				Select 
				 N0 = 0.0,						--False Northing		
				 E0 = 656166.6666666665,		--False Easting
				 K0 = 0.9999411764705882,		--Scale Factor
				 e = 0.08181919111988833,
				 ePrime = 0.08208852110265381,
				 V0 = 0.005022893948,
				 V2 = 0.000029370625,
				 V4 = 0.000000235059,
				 V6 = 0.000000002181,
				 L0 = 81.0,						--Central Meridian
				 Easting = CAST(geox AS DECIMAL(18,10)), 
				 Northing = CAST(geoy AS DECIMAL(18,10))
			) as CAStatic
			Cross Apply 
			  (
					Select m2sft = 1200.0/3937.0,
						   EPrime2 = Easting - E0
			  ) as CAComputed1
			Cross Apply 
				(
					Select  S0 = 2692050.5001/m2sft,
	  						 r = 6367449.14577/m2sft,
							 a = 6378137.0/m2sft
				) as CAComputed2
			Cross Apply
				(
					Select
						w = (Northing - N0 + S0)/(K0*r)
				) as CAComputed4						  
			Cross Apply
				(
					Select
						[of] = w + (sin(w)*cos(w))*(V0 + V2*power(cos(w),2) + V4*power(cos(w),4) + V6*power(cos(w),6))
				) as CAComputed5						  
			Cross Apply
				(
					Select
						Rf = K0*a/sqrt((1 - power(e,2)*power(sin([of]),2))),
						tf = tan([of]),
						nf = ePrime*cos([of]) 
				) as CAComputed6						  
			Cross Apply
				(
					Select
							Q = EPrime2/Rf,
							B2 = -0.5 * tf * (1 + POWER(nf,2)),
							B4 = -1/12*(5 + 3 * POWER(tf,2) +POWER(nf,2) * (1-9 * POWER(tf,2)) - 4 * POWER(nf,4)),
							B6 = 1/360*(61 + 90*POWER(tf,2) + 45*POWER(tf,4) + POWER(nf,2)*(46 - 252*POWER(tf,2) - 90*POWER(tf,4)))
				) as CAComputed7						  
			Cross Apply
				(
					Select
							Latitude = ([of] + B2*POWER(Q,2)*(1 + POWER(Q,2)*(B4 + B6*POWER(Q,2))))*180/(PI()),
							B3 = -1/6*(1 + 2*POWER(tf,2) + POWER(nf,2)),
							B5 = 1/120*(5 + 28*POWER(tf,2) + 24*POWER(tf,4) + POWER(nf,2)*(6 + 8*POWER(tf,2))),
							B7 = -1/5040*(61 + 662*POWER(tf,2) + 1320*POWER(tf,4) + 720*POWER(tf,6))
				) as CAComputed8						  
			Cross Apply
				(
					Select 
							L = Q*(1 + POWER(Q,2)*(B3 + POWER(Q,2)*(B5 + B7*POWER(Q,2))))
				) as CAComputed9
			Cross Apply
				(
					Select 
							Longitude = (L0 - (L/cos([of]))*180/(PI()))*-1
				) as CAComputedLatLong
				-- Join to get export code from nature table
				INNER JOIN [cad].[dbo].[nature] b ON a.natureid = b.natureid
			WHERE callsource IN ('SELF', 'SCHED') AND
			(inci_id <> '') AND
			(service = 'LAW') AND
			(calltime >= DATEADD(DD, -1, GETDATE())) AND
			(a.naturecode <> '') AND
			(substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) IS NOT NULL)
-- End calculation of Latitude and Longitude				
				
UNION -- Combine with results from other callsource

-- When callsource is not SELF or SCHED, geox and geoy just represent the State Plane Coords of where the officer was dispatched from
-- Latitude and Longitude are the actual location of the incident and don't need to be calculated
SELECT (SUBSTRING(inci_id, 1, 2)+'-'+SUBSTRING(inci_id, 3, 4)+'-'+SUBSTRING(inci_id, 7, 4)) AS inci_id,
		CASE WHEN case_id = '' THEN '' ELSE (SUBSTRING(case_id, 1, 2)+'-'+SUBSTRING(case_id, 3, 6)) END AS case_id,
		calltime,
		timeclose,
		callsource,
		street,
		citydesc AS city,
		state = 'FL',
		zip,
		CASE WHEN b.expcode = 'ACCIDENT' THEN 'Accident'
			 WHEN b.expcode = 'ARREST' THEN 'Arrest'
			 WHEN b.expcode = 'DOMESTIC' THEN 'Domestic'
			 WHEN b.expcode = 'DRUGS' THEN 'Drugs'
			 WHEN b.expcode = 'FELONY' THEN 'Felony'
			 WHEN b.expcode = 'HOMICIDE' THEN 'Homicide'
			 WHEN b.expcode = 'TRAFFIC' THEN 'Traffic Stop'
			 WHEN b.expcode = 'TRAINING' THEN 'Training'
			 WHEN b.expcode = 'WEAPONS' THEN 'Weapons'
			 ELSE 'Other' END AS classification,
		latitude,
		longitude,
		substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS badge,
		substring((SELECT '; ' + RTRIM(LTRIM(name)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) AS officer
FROM [cad].[dbo].[inmain] a
-- Join to get export code from nature table
INNER JOIN [cad].[dbo].[nature] b ON a.natureid = b.natureid 
WHERE callsource NOT IN ('SELF', 'SCHED') AND
(inci_id <> '') AND
(service = 'LAW') AND
(calltime >= DATEADD(DD, -1, GETDATE())) AND
((latitude <> '0') OR (latitude <> '')) AND
((longitude <> '0') OR (longitude <> '')) AND
(a.naturecode <> '') AND
(substring((SELECT '; ' + RTRIM(LTRIM(emdept_id)) FROM [cad].[dbo].[unitper] WHERE unitperid = a.primeuper for xml path ('')), 3, 10000) IS NOT NULL)
