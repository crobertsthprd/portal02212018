<CFSILENT>

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>
<cfset mode = "PP">



<!--- <cfquery name="GetOldestDI" datasource="#application.reg_dsn#" maxrows="1">
	select dt
	from dropinhistory
	order by dt desc
</cfquery> --->

<cfquery datasource="#application.reg_dsn#" name="GetPatronData">
	SELECT   PATRONS.lastname, PATRONS.firstname, PATRONS.gender, patrons.patronlookup,
	         PATRONS.dob, PatronRelations.InDistrict, 
	         PATRONADDRESSES.address1, PATRONADDRESSES.address2,
				PATRONADDRESSES.city, PATRONADDRESSES.state, patrons.patronid, patrons.dob,
				patronrelations.primarypatronid
	FROM     patronrelations PATRONRELATIONS
	         INNER JOIN patronaddresses PATRONADDRESSES ON PATRONADDRESSES.addressid=PATRONRELATIONS.addressid
	         INNER JOIN patrons PATRONS ON PATRONRELATIONS.secondarypatronid=PATRONS.patronid 
	WHERE    PATRONS.patronid = <cfif mode is "P">#patronid#<cfelse>#cookie.uid#</cfif>
	AND      patrons.inactive = false
</cfquery>

<cfset LastMonth = datediff("m","2004-02-01",now())>

	<!--- household mode --->
	<cfquery datasource="#application.reg_dsn#" name="GetPatrons">
		SELECT   PATRONRELATIONS.secondarypatronid, PATRONS.lastname, patrons.patronlookup,
		         PATRONS.firstname, PATRONS.gender, PATRONS.dob,
		         PATRONRELATIONS.primarypatronid 
		FROM     patronrelations PATRONRELATIONS
		         INNER JOIN patrons PATRONS ON PATRONRELATIONS.secondarypatronid=PATRONS.patronid 
		WHERE    PATRONRELATIONS.primarypatronid = #cookie.uid#
		AND      patrons.inactive = false
		ORDER BY PATRONRELATIONS.relationtype
	</cfquery>
</CFSILENT>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Dropin Usage History</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<cfoutput>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">

<table border="0" cellpadding="0" cellspacing="0" width="750">
  
  <!--- <cfinclude template="#request.includes#/top_nav.cfm"> --->
	<tr>
		<td valign=top>
   			<table border=0 cellpadding=2 cellspacing=0 width=749>
					<tr>
						<td colspan=3 class="pghdr">
						<!--- start header --->
						<CFINCLUDE template="/portalINC/dsp_header.cfm">
						<!--- end header --->
						</td>
					</tr>
				<tr>
					<td valign=top>
						<table border=0 cellpadding=2 cellspacing=0>
							<tr>
								<td><img src="/siteimages/spacer.gif" width="130" height="1" border="0" alt=""></td>
							</tr>
							<tr>
								<td valign=top nowrap class="lgnusr"><br>
								<!--- start nav --->
								<cfinclude template="/portalINC/admin_nav_history.cfm">
								<!--- end nav --->
								</td>
							</tr>		
						</table>		
					</td>
					<td valign=top colspan=2 class="bodytext" align=left>
					<!--- START HISTORY CONTENT --->
					<span class="pghdr"><br>Drop-In History</span>
	
	<input type="Hidden" name="primarypatronid" value="#cookie.uid#">
	<table width="675" cellpadding=3 cellspacing="0" border=0>
		<form action="dropin.cfm" method="post" name="dih">
		<TR>
			<TD colspan="5" align="center"><cfif IsDefined("ShowRange")><b>Household Drop-In History for #replace(ShowRange,"-","/")#</b></cfif></TD>
		</TR>
		<tr>
			<td colspan="4" align=center>All data is displayed in descending order. View the month of
			<select name="ShowRange" class="form_input">
			<cfset ThisMonth = month(now())>
			<cfset ThisYear = year(now())>

			<cfloop from="0" to="#LastMonth#" step="1" index="q">
				<option <cfif IsDefined("ShowRange") and ShowRange is numberformat(ThisMonth,"00") & "/" & ThisYear>selected</cfif> value="#numberformat(ThisMonth,"00")#-#ThisYear#">#numberformat(ThisMonth,"00")# / #ThisYear#
				<cfset ThisMonth = ThisMonth - 1>

				<cfif ThisMonth is 0>
					<cfset ThisMonth = 12>
					<cfset ThisYear = ThisYear - 1>
				</cfif>

			</cfloop>
			</select>
			<input type="Submit" value="View History" class="form_submit">
			</td>	
		</tr>

		<!--- <cfset showprimdata = 1> --->

		<cfloop query="GetPatrons">
			<cfset ThisPatron = GetPatrons.secondarypatronid>
			<cfset ThisPatronLastName = GetPatrons.lastname>
			<cfset ThisPatronFirstName = GetPatrons.firstname>
			<cfset ThisPatronGender = GetPatrons.gender>
			<cfset ThisPatronDOB = GetPatrons.DOB>
			<CF_HowLongHasItBeen DATE1="#ThisPatronDOB#" DATE2="#now()#" ADDWORDS="Yes" Abbreviated="yes">
			<cfset age = #HowLong_Years# & ", " & #HowLong_Months#>

			<tr bgcolor="0048d0">
				<td colspan="4" class="bodytext_white">
					<strong>#ThisPatronLastName#, #ThisPatronFirstName# (#patronlookup#)</strong><!--- , <cfif ThisPatronGender is "M">Male<cfelse>Female</cfif>, #dateformat(ThisPatronDOB,"mm/dd/yyyy")# (#age#) ---><BR>
				</td>	
			</tr>

			<cfquery datasource="#application.reg_dsn#" name="GetHistory">
				SELECT   DROPINHISTORY.dt, 
				         DROPINACTIVITIES.description, DROPINSELECTIONS.facid, 
				         PATRONS.lastname, PATRONS.firstname, PATRONS.renter, patrons.patronlookup,
				         PATRONS.dob,dropinhistory.invoicenumber, dropinselections.passtype, facilities.name
				FROM     dropinselections DROPINSELECTIONS
				         INNER JOIN dropinhistory DROPINHISTORY ON DROPINSELECTIONS.facid=DROPINHISTORY.facid AND DROPINSELECTIONS.clickid=DROPINHISTORY.clickid
				         INNER JOIN dropinactivities DROPINACTIVITIES ON DROPINSELECTIONS.activityid=DROPINACTIVITIES.activityid
				         INNER JOIN patrons PATRONS ON DROPINSELECTIONS.patronid=PATRONS.patronid
						 inner join facilities on dropinselections.facid = facilities.facid 
				WHERE    DROPINSELECTIONS.patronid = #ThisPatron#

				AND      
				<cfif IsDefined("ShowRange")>
					date_part('month',dt) = #left(ShowRange,2)#
					and date_part('year',dt) = #right(ShowRange,4)#
				<cfelse>
					date_part('month',dt) = #month(now())#
					and date_part('year',dt) = #year(now())#
				</cfif>

				ORDER BY DROPINHISTORY.dt DESC
				limit 2000
			</cfquery>

			<cfif GetHistory.recordcount is 0>
				<TR>
					<TD colspan="4">No history found</TD>
				</TR>
			<cfelse>
				<TR class="bodytext" bgcolor="ededed">
					<TD><strong>Facility</strong></TD>
					<TD><strong>Date/Time</strong></TD>
					<TD><strong>Activity</strong></TD>
					<TD><strong>Pass Type</strong> (if any)</TD>
				</TR>
	
				<cfloop query="GetHistory">

					<cfif IsDefined("passtype") and passtype is not "">

						<cfquery datasource="#application.reg_dsn#" name="GetPassData">
							select passdescription
							from passtype
							where passtype = '#passtype#'
							limit 1
						</cfquery>

					</cfif>

					<tr>
						<TD nowrap><cfif invoicenumber is -1><A href="javascript:void(window.open('../classes/class_summary_receipt.cfm?invoicelist=#facid#-#invoicenumber#','','width=750,height=550,toolbars=no, scrollbars=yes, resizable'))">#facid#-#invoicenumber#</A><cfelse>#name#</cfif>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>
						<TD>#dateformat(dt,"mm/dd/yyyy")# #timeformat(dt,"hh:mmtt")#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>
						<TD>#description#&nbsp;&nbsp;&nbsp;&nbsp;</TD>
						<TD><cfif IsDefined("passtype") and passtype is not "">#GetPassData.passdescription#</cfif></TD>
					</tr>
				</cfloop>
			</cfif>
		</cfloop>
		</form>
	</table>
					<!--- END HISTORY CONTENT --->
					</td>
				</tr>
			</table>
		</td>
    </tr>
	<tr>
		<td colspan="3"><img src="#request.imagedir#/spacer.gif" width="1" height="11" border="0" alt=""></td>
	</tr>
<cfinclude template="/portalINC/footer.cfm">
</table>
</body>
</html>
</cfoutput>