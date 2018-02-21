<!--- if the cookie has been reset; we need to empty the form so we do not repost --->
<CFIF cookie.assmtpicks EQ 0>
	<CFSET form.assessments = "">
</CFIF>

<!--- get rid of place holder in assessment list --->
<CFSET findindex = listfind(form.assessments,0)>
<CFIF findindex NEQ 0>
	<CFSET assessmentList = listdeleteat(form.assessments,findindex)>
<CFELSE>
	<CFSET assessmentList = trim(form.assessments)>
</CFIF>

<!--- convert to session --->
<cfif assessmentList is "">
	<CFSET errormessage="No assessments were found to process.">
	<CFINCLUDE template="finishassessmentDisplay.inc">
	<cfabort>
</cfif>


<!--- routine for determining what assessments patron already has and which ones he/she should not purchase --->
<CFSET exclusion = 0>
<CFQUERY name="getPatronAssess" datasource="#application.reg_dsn#">
	select r.id
	from assessmentrates r, assessments a
	where r.name = a.assmtname
	and a.primarypatronid = #form.primarypatronid#
	and a.valid = true
</CFQUERY>

<!--- START: processing for assessment --->
<cfset AllAssmtsArray = ArrayNew(2)>
<cfset aLen = 0>

<cfquery datasource="#application.reg_dsn#" name="GetNewAssessments">
	select assmtname, assmtname as name, assmteffective, assmtexpires, grace, rate, assmteffectiveoverlaptest, assmtexpiresoverlaptest
	from assessmentratesview
	where id in (#assessmentList#)
</cfquery>

<cfloop query="GetNewAssessments">
	<cfset aLen = aLen + 1>
	<cfset AllAssmtsArray[aLen][1] = assmteffectiveoverlaptest>
	<cfset AllAssmtsArray[aLen][2] = assmtexpiresoverlaptest>
</cfloop>

<!--- check for overlapping assessments --->
<cfquery datasource="#application.reg_dsn#" name="GetExistingAssessments">
	select distinct a.primarypatronid, a.assmteffective, a.assmtexpires, av.assmteffectiveoverlaptest, av.assmtexpiresoverlaptest
	from   allassessments a, assessmentratesview av
	where  a.primarypatronid = #form.primarypatronid#
	and    a.valid = true
	and    a.assmtexpires >= current_date
     and a.assmtname = av.assmtname
</cfquery>

<cfloop query="GetExistingAssessments">
	<cfset aLen = aLen + 1>
	<cfset AllAssmtsArray[aLen][1] = assmteffectiveoverlaptest>
	<cfset AllAssmtsArray[aLen][2] = assmtexpiresoverlaptest>
</cfloop>



<cfif overlap(AllAssmtsArray) is 1>
	<CFSET errormessage="Selected assessments overlap with assessments already purchased.<br> <a href=""javascript:history.back(); "">Please go back and try gain.</a>">
	<CFDUMP var="#GetExistingAssessments#">
     <CFDUMP var="#GetNewAssessments#">
     <CFDUMP var="#form#">
     <CFINCLUDE template="finishassessmentDisplay.inc">
	<CFABORT>
</cfif>