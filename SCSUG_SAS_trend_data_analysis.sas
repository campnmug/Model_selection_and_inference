
%let dir=C:\Users\myers\Dropbox\Myers_x220\Documents\WORK\SAS\SAS_SCSUG;
/* Code for SCSUG paper */
/* HANDS ON WORKSHOP
Title of paper is
DO YOU KNOW WHEN YOUR DATA IS LYING TO YOU? 
THE HOW OF REGRESSION ANALYSIS WITH QUANTITATIVE AND QUALITATIVE VARIABLES
Invited paper by Kirk Paul Lafler.
*/

Data Y;	
	/* read Y variable. The @@ allows reading multiple data from the same line */
	input Y @@; 
	datalines;  
	12.35  13.71  16.00  17.94  20.76  21.11  24.63
	27.56  32.88  35.16  39.26  44.28  47.27  51.55
;
run;

Proc means data=Y mean std maxdec=4;
	Title1 'Verify you entered the data correctly by matching proc means results. ';
	Title2 'The correct mean of Y is 28.8900 and the standard deviation of Y is 12.9719'; run; title1;


Data work.trdata;
	/* 	Problem articulation: Explain the trend in variable Y.						*/
	/* 		H0: An intervention that begins in T=8 has no effect on the trend line 	*/
	/* 		H1: An intervention at T=8 changes the trend line 						*/
	/*  Alternative problem: 														*/
	/*		The actual equation is simply nonlinear in variables such as y = T TSQ	*/
	set Y;
	T=_N_; 					/* 1. Create time variable T. */
	TSQ = T*T;				/* 2. Create time-squared value. */
	D=0; if T>=8 then D=1;	/* 3. Create binary variable for the intervention. */
	DT = D*T;				/* 4. Create interaction of D and T. */
run;

ods pdf file="&dir/TR_paper_visual_results.pdf" ;

/* A VISUAL APPROACH USING PROC SGPLOT, reg and loess plots. */

ods graphics on / noborder width=5in;
%let xref = %str(xaxis values=(1 to 14 by 1); refline 7.5 / axis=x label="<-- Policy change" labelloc=inside labelpos=min ;);

title1 'Model 1: Y follows a Linear Trend.';
title2 'PROC SGPLOT with REG Statement.';
PROC SGPLOT data=trdata ;
	reg x=T y=Y / CLM CLI ;
	&xref;
	run;

title1 'Model 2: Y follows a Quadratic Trend.';
title2 'PROC SGPLOT with REG Statement.';
PROC SGPLOT data=trdata ;
	reg x=T y=Y / degree=2 CLM CLI ;
	&xref;
	run;

title1 'Nonparametric Local Regression LOESS Model.';
title2 'Tracing out the points with LOESS and comparing to the Linear Trend.';
PROC SGPLOT data=trData;
	reg x=T y=Y / degree=1 CLM CLI CLMTRANSPARENCY=.5;
	loess x=T y=Y /interpolation=linear degree=2;  
	&xref;
run;

title1 'Model 4: Structural Break with Linear Trend by Group=D';
title2 'Separate linear regressions before and after policy change';
PROC SGPLOT data=trdata;
	reg x=T y=Y / CLM CLI CLMTRANSPARENCY=.5;
	reg x=T y=Y / CLM CLI group=D markerattrs=(symbol=circlefilled color=black size=10px) CLMTRANSPARENCY=.25;
	&xref;
run;

title1 'Local regression by group=D';
title2 'Separate LOESS regressions before and after policy change';
PROC SGPLOT data=trData;
	reg x=T y=Y / CLM CLI CLMTRANSPARENCY=.5;
	loess x=T y=Y / group=D 
		interpolation=linear degree=1 markerattrs=(symbol=circlefilled color=black size=10px) CLMTRANSPARENCY=.25;  
		/* CUBIC or LINEAR, 1 or 2 */
	&xref;
run;

title1 'Model 3a: Structural Break with Quadratic Trend by Group=D';
title2 'Separate linear regressions before and after policy change';
PROC SGPLOT data=trdata;
	reg x=T y=Y / CLM CLI CLMTRANSPARENCY=.5;
	reg x=T y=Y / degree=2 CLM CLI group=D markerattrs=(symbol=circlefilled color=black size=10px) CLMTRANSPARENCY=.25;
	&xref;
run;

ods graphics off;
ods pdf close;

/****************************************************************************/

ods pdf file="&dir/TR_paper_regression_results.pdf" ;


/* A STATISTICAL APPROACH USING PROC REG */


ods graphics on;
Title1 'Regression Specifications - full sample' ;
PROC REG data=trdata;
	var T TSQ D DT;
	model_1: model Y = T;
	run;

	title2 'Just throw in a dummy variable';
	model_3: model y = t d;
	run;

	title2 'Quadratic Model';
	model_2: model Y = T TSQ;
	run;

	title2 'Structural break model';
	model_4: model Y = T D DT;
	run;

	title2 ‘Before Sample, T=1,...,7';

	PROC 	reg data=work.trdata;
		model_5: model Y = T      ;
		model_6: model Y = T TSQ  ;
		where D=0;
		run;
	 
	title2 ‘After Sample, T=8,..., 14';

	PROC 	reg data=work.trdata;
		model_7: model Y = T      ;
		model_8: model Y = T TSQ  ;
		where D=1;
		run;

		quit;


/* Non-nesting hypothesis tests */


Title1 'Non-nested hypothesis - J-test';
Proc reg data=trdata;
 		model_2: model Y = T TSQ  ;
		output out=Mquad p=Yquadhat;
		run;
Proc reg data=trdata;
 		model_4: model Y = T D DT  ;
		output out=Minter p=Ybreakhat;
		run;
Proc reg data=Mquad;
		model_4A: model Y = T D DT Yquadhat;
		run;
Proc reg data=Minter;
 		model_2A: model Y = T TSQ Ybreakhat ;
		run;


Title1 'Non-nested hypothesis test - super model, F-test';
Proc reg data=trdata;
		model_4A: model Y = T  TSQ D DT ;
		quad: test tsq = 0;
		interactive: test d =dt=0;
		run;
		quit;

ods pdf close;
