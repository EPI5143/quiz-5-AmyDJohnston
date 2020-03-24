/*Epi5143 Winter 2020 Quiz 5*/
/*Submitted by Amy Johnston MARCH 24 2020*/

*ANSWER: The proportion of admissions which recorded a diagnosis of diabetes for admissions between January 1st 2003 
and December 31st, 2004 was: 3.72%. The code below was used to answer this question is supplied below;

*Running the contents procedure to have a look at the content of this variable before I get started;
proc contents data=epidat.NhrAbstracts;
	run;

/*STEP 1: CREATING THE "SPINE" DATASET: IDENTIFYING AND REMOVING DUPLICATE OBSERVATIONS*/
*Hint 1 says we only want 'unique' admissions (hraEncWID), so using the NODUPKEY function to identify and 
remove duplicate observations if there are any;

PROC SORT DATA=epidat.NhrAbstracts OUT=NhrAbs NODUPKEY;
	BY hraEncWID;
	RUN;
*SAS log window says: "0 observations with duplicate key values were deleted and there were a total of 24531 
observations;

/*STEP 1: CREATING THE SPINE DATASET: KEEPING ONLY UNIQUE ADMISSIONS WITH ADMIT DATES BETWEEN JAN 1 2003 AND 
DECEMBER 31 2004*/

DATA NHRabs;
	SET NHRabs; 
	KEEP hraEncWID;
		IF 2003<=year(datepart(hraAdmDtm))<=2004;
	RUN;
*I just restricted the dataset to all records between 2003 and 2004 because this will capture all records within the
date range;
*Keeping only unique admissions (hraEncWID variable) that fall within that date range- there are 2230 unique admissions;

*I used the codes below to verify that I have the correct number of observations for this date range using different options;
*First, I'm limiting to encounters in 2003;
DATA testing1;
	SET epidat.NhrAbstracts; 
	KEEP hraEncWID;
		IF year(datepart(hraAdmDtm))=2003;
	RUN;

*Then I'm limiting to encounters in 2004;
DATA testing2;
	SET epidat.NhrAbstracts; 
	KEEP hraEncWID;
		IF year(datepart(hraAdmDtm))=2004;
	RUN;
*The total number of unique encounters from 2003 and 2004 = 1102+1128 = 2230, which matches the obs for the date range
requested. YAY!;

/*STEP 2a: Renaming the linking variable so they are the same in both datasets */
DATA NEW;
	SET EPIDAT.nhrdiagnosis (RENAME=hdgHraEncWID=hraEncWID);	
	RUN;

/*STEP 2b: From the NHRDiagnosis table, sorting (prep for linking) by the linking variable 
*The new DIAGNOSIS set is what I will use to create my temporary DM set, which is the table that I will merge 
with my 'spine'*/
*Sorting my dataset by the linking variable, otherwise I'll get an error message;

PROC SORT DATA=NEW OUT=DIAGNOSIS; 
	BY hraEncWID;
	RUN;

*Note that there are 113083 observations in this dataset;

*Indicator variable is called DM (=0 for no diabetes codes, =1 for one or more diabetes code;
*Determining if one or more diagnosis codes for diabetes was present for each encounter  
in the diagnosis table;
*I am finding all of the ICD9 and ICD10 codes as indicated in hint #2 ;

DATA DM;
	SET DIAGNOSIS (KEEP=hraEncWID hdgcd);
	BY hraEncWID;
	RETAIN DM;
		IF FIRST.hraEncWID = 1 THEN DM=0;
		IF SUBSTR(hdgcd,1,3) IN ('250','E10','E11') THEN DM=1;
	DROP HDGCD;
		IF LAST.hraEncWID = 1 THEN OUTPUT;
	RUN;
*There are 32844 observations in this new DM dataset (and 2 variables);
*Here is where I am going to create my flat file- to ensure that I have one row per encounter
because there may be more than one DM code in the table;

*Sorting the data with respect to the encounter ID;
PROC SORT DATA=NHRabs;
	BY hraEncWID;
	RUN;

/*STEP 3: Merging my 'spine dataset NHRabs with my new DM dataset using the merge procedure*/

DATA DIABETES;
	MERGE NHRabs (IN=A) DM (IN=B);
	BY hraEncWID;
		IF B=0 THEN DM=0;
		IF A=1 THEN OUTPUT;
	RUN;
*Confirming # observations: 2230 from NHRAbs (spine, limited to 2003-2004 encounters)
32844 observations read from the data set WORK.DM, and the final dataset has 2230 obs 
matching my spine, so this is good!;

*The above DIABETES dataset has an indicator variable called DM that is 1 for any DM code present
and 0 for no DM code present;

PROC FREQ DATA=DIABETES;
	TABLES DM;
	TITLE1 "Proportion of admissions that recorded a diagnosis of diabetes";
	TITLE2 "for admissions between January 1st, 2003 and December 31st, 2004";
	RUN;
	
*Each time new variables are added to the SPINE, the number of observations in the newly created dataset 
 should not change. This needs to be verified;





