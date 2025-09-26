-- ----ECDS Base code Sept 2024 - Basic for getting started on UDAL

-- --Test save

-- --Saved: MIdlands/04 UEC/30 Winter Pack 202425/Deep dives/Aviodable Attendances

-- --Check on respiratory snomen codes for ARI hubs

-- select * from  [UKHD_ECDS_TOS].[Code_Sets_Max_Created] 
-- 	where Sheet_name like '%diagnosis%' 
-- 	and Der_ECDS_Group1 like '%infectious%'
-- 	and ECDS_Group2 like '%Respiratory%'
-- 	--and SNOMED_Code  = '507291000000100'
-- 	--and SNOmed_UK_Preferred_Term like '%self%'
-- 	order by snomed_code

-- 	----Check on Mental health 


-- select * from  [UKHD_ECDS_TOS].[Code_Sets_Max_Created] 
-- 	where Sheet_name like '%diagnosis%' 
-- 	and ECDS_Group2 like '%mental%'
-- 	order by snomed_code

-- --Check on Frailty
-- Select * from [UKHD_ECDS_TOS].[Code_Sets]  as rD1  
-- where rD1.Sheet_Name like '%DIAGNOSIS%'
-- and SNOMED_Code = '239873007'
-- or SNOMED_Description like '%falls%'

-- --coded findings table explore
-- SELECT TOP (1000) [EC_Ident]
--       ,[Generated_Record_ID]
--       ,[EC_Load_ID]
--       ,[Number]
--       ,[Code]
--       ,[IsCodeApproved]
--       ,[Timestamp]
--       ,[Der_Financial_Year]
--       ,[Deleted]
--       ,[UDALFileID]
--   FROM [Reporting_MESH_ECDS].[EC_ClinicalCodedFindings]
--   where code = '1129371000000104' ---canadian fraility assessement for midly frail



	--Draft code -- Summary by flags -- Run from here!

	with cte as (
	
	--Create flags and event level records to test. 
	Select
	--Avoidable attendance flag
	case when  EC_Department_Type = '01' AND --Type 1 only
			    ed.EC_Discharge_Status_SNOMED_CT in ('1077021000000100','182992009','1066321000000107') AND -- Discharged with followup treatment by GP, Discharged no followup required, Left department before treatment 
				([Der_EC_Investigation_All] in ('27171005','67900009','1088291000000101') or [Der_EC_Investigation_All]is NULL) AND --Urinalysis, Pregnancy test, Investigation not indicated
				([Der_EC_Treatment_All] in ('413334001','266712008','183964008' ) or [Der_EC_Treatment_All] is NULL) AND --Guidance/advice only � written, Prescription/medicines prepped to take away, None (consider guidance/advice option)
				ed.[EC_AttendanceCategory]  = '1' AND 
				ed.[EC_Arrival_Mode_SNOMED_CT] in ('1048061000000105','1048071000000103') --Public transport/taxi, Walk in
		THEN '1' ELSE '0' end as 'Avoidable_flag',
	--Avoidable dental attendance flag
	case when EC_Department_Type = '01' AND --Type 1 only
			    ed.EC_Discharge_Status_SNOMED_CT in ('1077021000000100','182992009','1066321000000107') and
				([Der_EC_Investigation_All] in ('53115007') or [Der_EC_Investigation_All]is NULL) and --Dental investigation  
				([Der_EC_Treatment_All] in ('81733005') or [Der_EC_Treatment_All] is NULL)  and --Dental treatment 
				ed.[EC_AttendanceCategory]  = '1' and 
				ed.[EC_Arrival_Mode_SNOMED_CT] in ('1048061000000105','1048071000000103')
	THEN '1' ELSE '0' end as 'Avoidable_dental_flag',
	--Low acuity flag
	case when ed.EC_Acuity_SNOMED_CT in ('1077241000000103','1077251000000100') --low and standard
		THEN '1' ELSE '0' end as 'Low_standard_acuity',
	--ARI Flag
	case when  rd1.Sheet_name like '%diagnosis%' 
				and rd1.Der_ECDS_Group1 like '%infectious%'
				and rd1.ECDS_Group2 like '%Respiratory%'
	THEN '1' ELSE '0' end as 'ARI_Flag',
	--Mental Health Flag
	case when	 rcc.Der_ECDS_Group1 = 'Psychosocial / Behaviour change' 
			or  rd1.ECDS_Group2 = 'Mental health'  --diagnosis 1 group only does nto look at other diagnosis
			or  [EC_Injury_Intent_SNOMED_CT] = '276853009'  --self inflicted injury
			or   ed.EC_Discharge_Status_SNOMED_CT  = '1077041000000107' --Streamed to mental health service'  
         then '1' Else '0' end as 'Mental_Health_Flag',
		 --Self Harm Flag
	case when	[EC_Injury_Intent_SNOMED_CT] = '276853009'  --self inflicted injury
        then '1' Else '0' end as 'Self_Harm_Flag',
 	--Primary Care Open hour flag
	case when (cast (ED.ARRIVAL_TIME as time) between '09:00:00' and '18:00:00' ) and
	         [Working_Day_Type] = 'Y' --none Weekend and Bank Holidays
		 THEN '1' ELSE '0' end as 'Primary_Care_Open',
		 --Potential Primary Care conditions - Codes provided by Heather Thornton, 7th November 24
	case when	rcc.snomed_code in ('267036007','230145002','762898005','449614009','21522001','14760008','62315008',
									'422587007','422400008','65958008','79890006','77880009','405729008','40739000','25064002',
									'40917007','271782001','404640003','44077006','26079004','22631008','193462001','399963005',
									'299972003','283682007','271807003','297982009','444905003','247441003','418363000','161887000',
									'93459000','95668009','81680005','162356005','300132001','15188001','60862001','249366005','68235000',
									'267102003','49727002','421581006','75705005','41652007','246679005','161891005','45326000','771083005',
									'74323005','444899003','56608008','53057004','18876004','300955002','49218002','78514002','1003722009',
									'300954003','247373008','47933007','2733002','285365001','271771009','49650001','162116003','718403007',
									'34436003','20502007','281398003','225565007','300528000','1874001000000104','1874011000000102','301822002',
									'289610003','290085007','248062006','366979004','48694002','248020004','386661006','80394007','302866003','410379003',
									'162214009','13791008','161152002','182888003','84387000') 
			then '1' else '0' end as 'Potential_Primary_Care_Complaint',
    --Wound Care Flag
	 CASE 
            WHEN rcc.snomed_code IN ('399963005', '299972003', '283682007') 
            THEN '1' ELSE '0' 
        END AS 'Wound_Care',
  --Frailty Flag
  CASE WHEN rcc.[ECDS_Description] IN (
    'Dizziness', 
    'Falls', 
    'Falls / unsteady on feet', 
    'Syncope (collapse with LOC)', 
    'Near syncope (feeling faint without LOC)', 
    'Unsteady when walking'
  ) AND  ED.AGE_AT_ARRIVAL >= 75
  THEN '1'
  --WHEN [ECDS_Description] IS NULL THEN 'NULL'
  ELSE '0'
--   case when  ED.AGE_AT_ARRIVAL >= 65
--  AND (rD1.SNOMED_Code IN (
--        '444814009', -- Frailty syndrome - this is the code for viral sinnitus
--        '71948008', -- Heart failure - does not exsit in snomed table as diagnosis but other codes for comorbidity exist
--        '32485007', -- Osteoporosis- does not exsit in snomed table but 64859006 does for osteoporisis, also discharge planning fall prevention code 
--        '239873007', -- Falls
--        '386807006'  -- Dementia
--      )
--  OR ed.EC_Chief_Complaint_SNOMED_CT IN (
--        '721006008', -- General weakness
--        '59282003'  -- Difficulty walking  falls cheif complaint = 161898004. use this??
--      ))
-- 	 then '1' else '0' 
	 End AS 'Frailty_Flag',	 

	--Admitted/Non admitted
	rDD.der_ECDS_Group1 as 'Discharge group',
	--Age
	CASE WHEN ED.AGE_AT_ARRIVAL <= 24 AND ED.AGE_AT_ARRIVAL >= 0 THEN '00 - 24'  
	WHEN ED.AGE_AT_ARRIVAL <= 64 AND ED.AGE_AT_ARRIVAL >= 25 THEN '25 - 64' 
	WHEN ED.AGE_AT_ARRIVAL >= 65 THEN '65+' 
	ELSE 'Not Plausible' END AS 'AGE GROUP',
	--Breach 4 hour flag
	case when ed.Der_EC_Duration > 241 then '1' else '0' end as 'Breach_4_hours',
	--Time/Date stamp issue
	case when ed.Der_EC_Arrival_Date_Time is null then 'NULL_Arrival_Date/time'
		when [EC_Initial_Assessment_Date] is null then 'NULL_Assessment_Date/time'
		when [EC_Seen_For_Treatment_Time] is null then 'NULL_Treatment_Date'
        when [Clinically_Ready_To_Proceed_Timestamp] is null then 'NULL_CRTP_Date/time'
		when [Der_EC_Departure_Date_Time] is null then 'NULL_Departure_Date/time' 
		when ed.Der_EC_Arrival_Date_Time > cast([EC_Initial_Assessment_Date] + [EC_Initial_Assessment_Time] as datetime2) then 'Arrived after Assessment' 
		when cast([EC_Initial_Assessment_Date] + [EC_Initial_Assessment_Time] as datetime2) > cast([EC_Seen_For_Treatment_Date] +[EC_Seen_For_Treatment_Time] as DATETIME2) then 'Assessed after Treatment'
		when cast([EC_Seen_For_Treatment_Date] +[EC_Seen_For_Treatment_Time] as datetime2) > [Clinically_Ready_To_Proceed_Timestamp] then 'Treated after discharge'
		when [Clinically_Ready_To_Proceed_Timestamp] > [Der_EC_Departure_Date_Time] then 'Clinicallly Ready after discharge'
	
	else '?' end as 'DQ_Times',
	--National dashbaord flag
	case when ([EC_Initial_Assessment_Time_Since_Arrival] >=0 OR [EC_Initial_Assessment_Time_Since_Arrival] IS NULL)
AND  ([EC_Departure_Time_Since_Arrival]-[EC_Seen_For_Treatment_Time_Since_Arrival] >=0 OR [EC_Departure_Time_Since_Arrival]-[EC_Seen_For_Treatment_Time_Since_Arrival] IS NULL)
AND  ([EC_Seen_For_Treatment_Time_Since_Arrival]-[EC_Initial_Assessment_Time_Since_Arrival] >=0 OR [EC_Seen_For_Treatment_Time_Since_Arrival]-[EC_Initial_Assessment_Time_Since_Arrival] IS NULL)
AND  ([Clinically_Ready_To_Proceed_Time_Since_Arrival]-[EC_Initial_Assessment_Time_Since_Arrival] >=0 OR [Clinically_Ready_To_Proceed_Time_Since_Arrival]-[EC_Initial_Assessment_Time_Since_Arrival] IS NULL)
AND  ([EC_Departure_Time_Since_Arrival]-[Clinically_Ready_To_Proceed_Time_Since_Arrival] >=0 OR [EC_Departure_Time_Since_Arrival]-[Clinically_Ready_To_Proceed_Time_Since_Arrival]  IS NULL)
AND  ([EC_Departure_Time_Since_Arrival] >=0 OR [EC_Departure_Time_Since_Arrival] IS NULL)
AND  ([EC_Seen_For_Treatment_Time_Since_Arrival] >=0 OR [EC_Seen_For_Treatment_Time_Since_Arrival] IS NULL) 
then '1' else '0' end as 'NAtional_Dashbaord_Flag',
	--Provider 
	vophp.Integrated_Care_Board_Name as 'Provider_ICB',
	vOPHP.Organisation_Name as 'Provider_Organisation_Name',
		--Purchaser
	rescom.Integrated_Care_Board_Name as 'Purchaser(Patient)_ICB',
	--site
	vOPHS.Site_Name,
	ed.EC_Department_Type,
	--event
	ed.EC_Ident,
	EC_AttendanceCategory,
	rdf.MonthYear_MMM_YYYY as 'Month_Year',
	ED.ARRIVAL_DATE,                         
	ED.ARRIVAL_TIME,
	--ed.Der_EC_Duration, 
	--ed.Der_EC_Arrival_Date_Time,
	ed.Der_EC_Departure_Date_Time,
	[EC_Initial_Assessment_Date],
[EC_Initial_Assessment_Time],
[EC_Initial_Assessment_Time_Since_Arrival],
[EC_Seen_For_Treatment_Date],
[EC_Seen_For_Treatment_Time],
[EC_Seen_For_Treatment_Time_Since_Arrival],
[Clinically_Ready_To_Proceed_Time_Since_Arrival],
--[Clinically_Ready_To_Proceed_Timestamp],
--[EC_Conclusion_Date],
--[EC_Conclusion_Time],
--[EC_Conclusion_Time_Since_Arrival],
[EC_Departure_Date],
[EC_Departure_Time],
--[Der_EC_Departure_Date_Time],
[EC_Departure_Time_Since_Arrival],
ed.Der_EC_Arrival_Date_Time,
cast([EC_Initial_Assessment_Date] + [EC_Initial_Assessment_Time] as datetime2) as 'Assessment date time',
cast([EC_Seen_For_Treatment_Date] +[EC_Seen_For_Treatment_Time] as datetime2) as 'Treatment date time',
[Clinically_Ready_To_Proceed_Timestamp],
cast([EC_Departure_Date] + [EC_Departure_Time] as DAtetime2 ) as 'Departure BST date time',
CAST(    DATEDIFF(MINUTE, CAST([EC_Initial_Assessment_Date] + ' ' + [EC_Initial_Assessment_Time] AS DATETIME2),  CAST([EC_Seen_For_Treatment_Date] + ' ' + [EC_Seen_For_Treatment_Time] AS DATETIME2)) AS int) AS 'Initial Assessement to Treatment (mins)',
--CAST(    DATEDIFF(MINUTE, CAST([EC_Seen_For_Treatment_Date] + ' ' + [EC_Seen_For_Treatment_Time] AS DATETIME2),  [Der_EC_Departure_Date_Time]) AS int) AS 'Treatment to Departure (mins)',
CAST(    DATEDIFF(MINUTE, CAST([EC_Seen_For_Treatment_Date] + ' ' + [EC_Seen_For_Treatment_Time] AS DATETIME2),  [Clinically_Ready_To_Proceed_Timestamp]) AS int) AS 'Treatment to Clinically Ready (mins)',
CAST(    DATEDIFF(MINUTE, [Clinically_Ready_To_Proceed_Timestamp],[Der_EC_Departure_Date_Time]) AS int) AS 'Clinically Ready to Discharge (mins)',

ed.Der_EC_Duration, 
	case when ed.Der_EC_Duration is Null then 'Unknown'
		 when ed.Der_EC_Duration >= 0 and ed.Der_EC_Duration <= 240 then '00h-4H00m'
	     when ed.Der_EC_Duration >= 240 and ed.Der_EC_Duration <= 719 then '04h01m-11h59m'
	     when ed.Der_EC_Duration >= 720 and ed.Der_EC_Duration <= 4320 then '12h-72hrs'
		 when ed.Der_EC_Duration > 4321  then 'over 72hrs'
		 else 'DQ Issue' end as 'Duration Bands',

	--complaint and outcome
	rAC.SNOMED_UK_Preferred_Term as 'AcuityDescription',
	ed.EC_Arrival_Mode_SNOMED_CT,
	rAS.SNOMED_UK_Preferred_Term as 'AttendanceSourceCategory',
	rAS.Der_ECDS_Group1 as 'AttendanceSourceGroup',
	ed.EC_Chief_Complaint_SNOMED_CT,
	rCC.SNOMED_UK_Preferred_Term as 'CHIEF COMPLAINT DESCRIPTION', 
	rcc.Der_ECDS_Group1 as 'CHIEF COMPLAINT GROUPING', 
	ed.EC_Discharge_Status_SNOMED_CT,
	rDS.SNOMED_UK_Preferred_Term as 'Discharge Status',
	rDD.SNOMED_UK_Preferred_Term as 'Discharge Destination', 
	rII.SNOMED_UK_Preferred_Term as 'Injury Intent', 
	--Diagnosis
	Der_Number_EC_Diagnosis,
	Der_EC_Diagnosis_All,
	diag.[EC_Diagnosis_01],
	rd1.SNOMED_UK_Preferred_Term as 'Diagnosis1',
	rd1.Der_ECDS_Group1 as 'Diagnosis 1 Grouping',
	rd1.ECDS_Group2 as 'Diagnosis 1 Sub Grouping',
	diag.[EC_Diagnosis_02],
	rd2.SNOMED_UK_Preferred_Term as 'Diagnosis2',
		diag.[EC_Diagnosis_03],
	rd3.SNOMED_UK_Preferred_Term as 'Diagnosis3',
	--Investigation
	Der_Number_EC_Investigation,  
	rI1.SNOMED_UK_Preferred_Term as 'Investigation1',
		INV.[EC_Investigation_01],
	--Treatment
	Der_Number_EC_Treatment, 
	rT1.SNOMED_UK_Preferred_Term as 'Treatment1',
		Treat.[EC_Treatment_01],
	--Patient	
	ED.DER_PSEUDO_NHS_NUMBER, 
	ED.AGE_AT_ARRIVAL,
   --GP
	ed.[GP_Practice_Code],
	vOGP.[GP_Name],
	vOGP.[GP_PCN_Name]
	
	             
			
FROM   

--[Reporting_MESH_ECDS].[EC_Core] AS ED --Reporting table
--[MESH_FUAECDS].[FUA_EC] as ED--Slim table
[MESH_ECDS].[EC_Core]as ED --view verion of Datalake table
--[Reporting_MESH_ECDS].[EC_Core_snapshot] as ED --monthly snapshot of reporting table
		--look up Provider
left join [Reporting_UKHD_ODS].[Provider_Hierarchies_ICB]  as vOPHP on ED.[der_provider_code] = vOPHP.organisation_code 
--Look up Site
left join [Reporting_UKHD_ODS].[Provider_site]  as vOPHS on ED.[Site_Code_of_Treatment] = vOPHS.Site_code
--Look up Purchaser
left join [MESH_ECDS].[EC_2425_Der] der on der.EC_Ident = ed.EC_ident and der.[Der_Financial_Year] = ed.[Der_Financial_year]
left join [Reporting_UKHD_ODS].[Commissioner_Hierarchies_ICB] as rescom on rescom.[Organisation_Code] = der.[Responsible_Purchaser_Code] 
--Look up PAtient ICB
left join [MESH_ECDS].[EC_CCG] ccg on  ccg.EC_Ident = ed.EC_ident and ccg.[Der_Financial_Year] = ed.[Der_Financial_year]
--look up GP
left join [Reporting_UKHD_ODS].[GP_Hierarchies_All] as vOGP on ed.GP_Practice_Code = vOGP.GP_Code and [Rel_Active] = 'TRUE' --get latest record with active PCN
--Get more date info
left join [Internal_Reference].[Date_Full] as rDF on ED.ARRIVAL_DATE = rdf.full_date  
	--get SNOMED code descriptions using ETOS,  select correct sheet name (these may need updating when new verions of ETOS are released). New view in development to avoid Code deprecated issue
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rAC on rAC.SNOMED_Code = ed.EC_Acuity_SNOMED_CT and  rAC.Sheet_Name_Short = 'ACUITY'
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rDD on rDD.SNOMED_Code = ed.Discharge_Destination_SNOMED_CT   and rDD.Sheet_Name_Short = 'DISCHARGE DESTINATION'
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rDS on rDS.SNOMED_Code = ed.EC_Discharge_Status_SNOMED_CT   and rDS.Sheet_Name_Short = 'DISCHARGE STATUS'
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rAS on rAS.SNOMED_Code = ed.EC_Attendance_Source_SNOMED_CT   and rAS.Sheet_Name_Short = 'ATTENDANCE SOURCE'
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rAM on rAM.SNOMED_Code = ed.EC_Arrival_Mode_SNOMED_CT and rAM.Sheet_Name_Short = 'ARRIVAL MODE'
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rCC on rCC.SNOMED_Code = ed.EC_Chief_Complaint_SNOMED_CT   and rCC.Sheet_Name_Short = 'CHIEF COMPLAINT'
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rII on rII.SNOMED_Code = ed.EC_Injury_Intent_SNOMED_CT   and rII.Sheet_Name_Short = 'INJURY INTENT'
left join [MESH_ECDS].[EC_Diagnosis] as Diag on ed.EC_Ident = diag.EC_Ident
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rD1 on rD1.SNOMED_Code = diag.[EC_Diagnosis_01]   and rD1.Sheet_Name_Short = 'DIAGNOSIS'
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rD2 on rD2.SNOMED_Code = diag.[EC_Diagnosis_02]   and rD2.Sheet_Name_Short = 'DIAGNOSIS'    
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rD3 on rD3.SNOMED_Code = diag.[EC_Diagnosis_03]   and rD3.Sheet_Name_Short = 'DIAGNOSIS'  
left join [MESH_ECDS].[EC_Investigation] as INV on ed.EC_Ident = INV.EC_Ident
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rI1 on rI1.SNOMED_Code = INV.[EC_Investigation_01]   and rI1.Sheet_Name_Short = 'Investigation'
left join [MESH_ECDS].[EC_Treatment] as Treat on ed.EC_Ident = Treat.EC_Ident
left join [UKHD_ECDS_TOS].[Code_Sets_Max_Created]  as rT1 on rT1.SNOMED_Code = Treat.[EC_Treatment_01]   and rT1.Sheet_Name_Short = 'Treatment'

	
where 
cast ( ed.Der_EC_Arrival_Date_Time as date ) >= '2022-01-01' and
	 vOPHP.Region_Code = 'Y60' and
   vOPHP.NHSE_Organisation_Type = 'Acute Trust' 
 -- and ed.deleted = 0 --if using FAU slim table
  --and (ed.EC_Arrival_Mode_SNOMED_CT is not null and rAS.SNOMED_UK_Preferred_Term is null)
  --and vophp.Integrated_Care_Board_Name = 'NHS NOTTINGHAM AND NOTTINGHAMSHIRE INTEGRATED CARE BOARD'
  --and der_provider_code = 'RWE'
  and  ED.EC_Ident = '2690818080'
 
 --and ED.[Site_Code_of_Treatment] = 'NQTE4' 


	)
--summary from cte

Select  Provider_ICB, 
[Purchaser(Patient)_ICB],
EC_Department_Type,
Month_Year,
[AGE GROUP],
--allows to select mulitple flags
Avoidable_flag,
Avoidable_dental_flag,
Low_standard_acuity,
ARI_Flag,
Mental_Health_Flag,
Self_Harm_Flag,
Potential_Primary_Care_Complaint,
Primary_Care_Open,
Wound_Care,
Breach_4_hours,
Frailty_Flag,
count (distinct EC_Ident) as 'attendances'


from cte


group by  Provider_ICB, 
[Purchaser(Patient)_ICB],
Month_Year,
[AGE GROUP],
EC_Department_Type,
--allows to select mulitple flags
Avoidable_flag,
Avoidable_dental_flag,
Low_standard_acuity,
ARI_Flag,
Mental_Health_Flag,
Self_Harm_Flag,
Potential_Primary_Care_Complaint,
Primary_Care_Open,
Wound_Care,
Breach_4_hours,
Frailty_Flag

--order by Provider_ICB, [Purchaser(Patient)_ICB], Month_Year,Avoidable_flag,Avoidable_dental_flag,Low_standard_acuity,ARI_Flag,Mental_health_Flag,Potential_Primary_Care_Complaint,Primary_Care_Open

