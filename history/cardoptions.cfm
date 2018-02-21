<CFSILENT>
<!--- offline pending rollout strategy 
<CFLOCATION url="/portal/main.cfm">--->

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>
<cfset mode = "PP">

<cfquery datasource="#application.reg_dsn#" name="patron">
	select patronID from patrons
     where patronlookup = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#cookie.login#">
</cfquery>

</CFSILENT>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Manage Payment Options</title>
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
					<span class="pghdr"><br>Manage Payment Options</span><br>
                         The default card is listed first and will be the first option for payment at checkout.<br><br>
                         
                         <CFIF Isdefined("url.success") and url.success EQ 'true'>
                         <span style="background-color:green;color:white;"><strong>Card successfully added.</strong><br><br> 
                         </CFIF>
	

<CFIF Isdefined("url.managecard") and url.managecard EQ "default">
<CFSCRIPT>
//theKey=generateSecretKey(key); 
decryptedToken=decrypt("#url.ref#", key, "CFMX_COMPAT", "Hex"); 
</CFSCRIPT>

<!--- make card default --->
<!--- set all patron cards to preferred = false --->
<cfquery datasource="#application.reg_dsn#" name="update1">
	update patrontokens
     set preferred = false
     where patronid = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#patron.patronid#">
</cfquery>
<!--- set selected card to true --->
<cfquery datasource="#application.reg_dsn#" name="update2">
	update patrontokens
     set preferred = true
     where patronid = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#patron.patronid#">
     and token = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#decryptedToken#">
</cfquery>
</CFIF>

<CFIF Isdefined("url.managecard") and url.managecard EQ "remove">
<CFSCRIPT>
//theKey=generateSecretKey(key); 
decryptedToken=decrypt("#url.ref#", key, "CFMX_COMPAT", "Hex"); 
</CFSCRIPT>

<!--- make card default --->
<!--- set all patron cards to preferred = false --->
<cfquery datasource="#application.reg_dsn#" name="update1">
	update patrontokens
     set invaliddt = now()
     and valid = false
     where patronid = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#patron.patronid#">
     and token = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#decryptedToken#">
</cfquery>

</CFIF>



<cfquery datasource="#application.reg_dsn#" name="getCards">
	select * from patrontokens
     where patronid = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#patron.patronid#">
     and invaliddt IS NULL
     order by preferred desc
</cfquery>

<CFOUTPUT>
<form action="#cgi.script_name#" method="post">
<input type="hidden" name="formaction" value="update">
<table width="500" cellpadding="3">
<tr>
<td><strong>Label</strong></td>
<td><strong>Card Number</strong></td>
<td><strong>Expires</strong></td>
<td></td>
</tr>
<CFLOOP query="getCards">
<CFSCRIPT>
	//theKey=generateSecretKey(key); 
	encryptedToken=encrypt("#getCards.token#", key, "CFMX_COMPAT", "Hex"); 
</CFSCRIPT>
<tr>
<td valign="top">#getCards.cardreference#</td>
<td valign="top">#getCards.cardnumber#</td>
<td valign="top">#left(getCards.cardexpirationdate,2)# / #right(getCards.cardexpirationdate,2)#</td>
<td valign="top"><CFIF getCards.preferred NEQ "true"><a href="#cgi.script_name#?managecard=default&ref=#encryptedToken#">Make Default</a> | </CFIF><a href="#cgi.script_name#?managecard=remove&ref=#encryptedToken#">Remove</a></td>
</tr>
</CFLOOP>


</table>
</form>
</CFOUTPUT>

	<table width="675" cellpadding=3 cellspacing="0" border=0>
		
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