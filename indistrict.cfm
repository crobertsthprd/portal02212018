
<html>
<head>
<title>Tualatin Hills Park and Recreation District </title>
<cfoutput>
<meta http-equiv="Content-Type" content="text/html;">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" >
<table border="0" cellpadding="0" cellspacing="0" width="750">
  
	<tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		<td>&nbsp;</td>
		<td class="orangebig" align=center><img src="/portal/images/logothprd2013.gif"><br>Welcome to the myTHPRD Online Activity Registration System</td>
		</tr>		
		<tr>
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="images/spacer.gif" width="150" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap><br>
			<cfinclude template="/portalINC/admin_nav_login.cfm">
			</td>
			</tr>		
			</table>		
		</td>
		<td valign=top class="bodytext"><br>
			<table width=600 border=0 cellpadding="2" cellspacing="0">
			
			<tr>
			
			<td colspan=2 class="bodytext">
			<strong>Am I In-District?</strong><br><br>
	<cfif NOT structKeyExists(form, "myaddress")>
	Please enter your current address:<br />
<form action="<cfoutput>#cgi.script_name#</cfoutput>" method="post"><input type="text" width="20" name="myaddress" class="form" /> <input type="submit" name="go" value="Go" class="form"/><br />
<br />
Our address database is provided by Washington County. If possible, please enter your address as it appears on
your property tax statement.<br>
<br>
<b>Example:</b> 15707 SW Walker<br>
<br>
A search will only return an <strong>exact match</strong>, so please enter the address using the following abbreviations:
<br />
<table width="90%" align="center">
	<tr>
		<td valign="top" width="25%">Ave<br />
Blvd<br />
Cir<br />


</td>
		<td valign="top" width="25%">Ct<br />Hwy<br />Ln<br />

		</td>
		<td valign="top" width="25%">Lp<br />
		Pl<br />
		St<br /></td>
		<td valign="top" width="25%">Rd<br />
		Ter<br />
		Pkwy<br /></td>
	</tr>
</table>
</form>
<CFELSE>
	<CFQUERY NAME="qCheckID" datasource="#application.reg_dsn#">
		select siteaddress
		from countyid
		where upper(siteaddress) like '#uCase(form.myaddress)#%'
		limit 1
	</CFQUERY>
	<CFOUTPUT>
	
	<cfif qCheckID.recordcount gt 0><!--- in district --->
		<strong>#form.myaddress#</strong>, is considered inside THPRD boundaries.<br /><br />In-District privileges may be withheld until proof of residency can be verified.
	<cfelse>
	<!--- check OD table --->
		<CFQUERY NAME="qCheckOD" datasource="#application.reg_dsn#">
			select siteaddress
			from countyOD
			where upper(siteaddress) like '#uCase(form.myaddress)#%'
			limit 1
		</CFQUERY>
		<cfif qCheckOD.recordcount gt 0>
			The address you entered, <strong>#form.myaddress#</strong>, is considered outside THPRD boundaries.
		<cfelse><!--- not in system --->
			The address you entered, <strong>#form.myaddress#</strong>, was not found in our database.
		</cfif>
		
	</CFIF>
	<br /><br /><a href="#cgi.script_name#"><< Go Back</a>
	</CFOUTPUT>
	
</CFIF>
			<br><br>
			</td>
			</tr>
			
		</table>   
   </td>
   <td><img src="images/spacer.gif" width="1" height="128" border="0" alt=""></td>   
  </tr>
  <tr>
   <td  valign="top"><p></p></td>
   <td><img src="images/spacer.gif" width="1" height="11" border="0" alt=""></td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">
</cfoutput>
</table>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>
