<cfoutput>

<!--- check open call --->
<CFINCLUDE template="/portalINC/checkopencall.cfm">
<!---cfinclude template="/common/functions.cfm" 06122017 --->
<cfinclude template="/common/checkformelements.cfm">

<cfif not IsDefined("cookie.uid")>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
</cfif>

<cfset sessionvars = getprimarysessiondata(cookie.uid)>

<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" )>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<cfif IsDefined("form.clearcards")>

	<cfquery datasource="#application.reg_dsn#" name="insertCard">
		delete from dops.sessionothercredit
		where  sessionid = <cfqueryparam value="#sessionvars.sessionid#" cfsqltype="cf_sql_varchar" list="no">
	</cfquery>

</cfif>

<cfif IsDefined("form.loadcards")>
<!---<cfset StructInsert( local.retstruct, "facid", local.GetData.dbsession[1] )>
<cfset StructInsert( local.retstruct, "facname", local.getfacdata.name )>
<cfset StructInsert( local.retstruct, "facphone", phoneformat( local.getfacdata.phone ) )>
<cfset StructInsert( local.retstruct, "node", local.GetData.dbsession[2] )>
<cfset StructInsert( local.retstruct, "sessionid", local.GetData.dbsession[3] )>
<cfset StructInsert( local.retstruct, "minutes", local.GetData.dbsession[4] )>
<cfset StructInsert( local.retstruct, "idleminutes", local.GetData.dbsession[5] )>
<cfset StructInsert( local.retstruct, "timeout", local.GetData.dbsession[6] )>--->

	<cfquery datasource="#application.reg_dsn#" name="getCards">
		SELECT   s.cardid,
		         s.othercredittype,
		         s.othercreditdata
		FROM     dops.othercredithistorysums s
		WHERE    s.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
		and      valid
		and      not s.isfa
		and      s.othercredittype in ( <cfqueryparam value="GC" cfsqltype="cf_sql_varchar" list="no"> )
	</cfquery>

	<cfloop query="getCards">
		<cfset t = "cardid" & getCards.cardid>
          
          <!---Here: <CFOUTPUT>#isNumeric( evaluate( variables.t))# - #evaluate( variables.t)#</CFOUTPUT>--->

		<cfif isNumeric( evaluate( variables.t) ) and evaluate( variables.t) gt 0>

			<cftry>

				<cfquery datasource="#application.reg_dsn#" name="insertCard">
					insert into dops.sessionothercredit
						(
							facid,
							node,
							sessionid,
							linktoprimary,
							othercredittype,
							othercreditdata,
							newpurchase,
							amount
						)
					values
						(
							<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="W1" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="#sessionvars.sessionid#" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#getCards.othercredittype#" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="#getCards.othercreditdata#" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#evaluate( variables.t)#" cfsqltype="cf_sql_money" list="no">
						)
				</cfquery>

			<cfcatch></cfcatch>
			</cftry>

		</cfif>

	</cfloop>

</cfif>






<!--- query to get registered cards --->
<cfquery datasource="#application.reg_dsn#" name="getCards">
	SELECT   s.sumnet,
	         s.cardid,
	         s.othercreditdesc,
	         s.othercreditdata,
	(select cardname from othercreditdata where cardid = s.cardid) AS cardname
	FROM     dops.othercredithistorysums s
	WHERE    s.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
	and      valid
	and      not s.isfa
	and      s.othercredittype in ( <cfqueryparam value="GC" cfsqltype="cf_sql_varchar" list="no"> )
	ORDER BY s.cardid
</cfquery>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Gift Card Reload</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">
<table border="0" cellpadding="0" cellspacing="0" width="750">
  <tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
			<tr>
				<td colspan=2 class="pghdr">
				<!--- start header --->
				<CFINCLUDE template="/portalINC/dsp_header.cfm">
				<!--- end header --->
				</td>
			</tr>
			<tr>
				<td valign=top>
					<table border=0 cellpadding=2 cellspacing=0>
						<tr>
							<td width="130"><img src="/portal/images/spacer.gif" width="130" height="1" border="0" alt=""></td>
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
				<td valign=top class="bodytext" width="100%">
				<!--- start content --->
				<br><span class="pghdr">Registered Cards</span><br>

				<cfquery datasource="#application.reg_dsn#" name="getSessionCards">
					SELECT   *
					FROM     dops.sessionothercredit
					WHERE    sessionid = <cfqueryparam value="#sessionvars.sessionid#" cfsqltype="cf_sql_varchar" list="no">
				</cfquery>

				<table border="0" cellpadding="3" cellspacing="0" width="100%">
					<tr bgcolor="dddddd" >
						<td><strong>Card Number / Card Name</strong> <sup><a href="javascript:alert('Name a card to make managing multiple cards easier.');"><strong>?</strong></a></sup></td>
						<td><strong>Type</strong></td>
						<td><strong>Balance</strong></td>
						<td align="center"><strong>Actions</strong></td>
					</tr>
					<cfset cardsum = 0>

					<cfset totalreloadamount = 0>

					<form method="post" action="ocinfo.cfm">
					<input type="hidden" name="currentsessionid" value="#sessionvars.sessionid#">

					<CFLOOP query="getcards">
						<cf_cryp type="de" string="#getcards.othercreditdata#" key="#skey#">
						<tr >
						<td>
							<strong>#ccformat( cryp.value )#</strong>
							<CFIF trim(getcards.cardname) NEQ ""> / #getcards.cardname#</CFIF><br>
						<td valign="top">#getcards.othercreditdesc#</td>
						<td valign="top" align="right">$#decimalformat(sumnet)#</td>
						<cfset cardsum = variables.cardsum + sumnet>
						<td valign="top" align="right" nowrap>
							<cfset addedamount = 0>

							<cfloop query="getSessionCards">

								<cfif getSessionCards.othercreditdata eq getcards.othercreditdata>
									<cfset addedamount = getSessionCards.amount>
									<cfset totalreloadamount = variables.totalreloadamount + getSessionCards.amount>
								</cfif>

							</cfloop>

							<cfif getSessionCards.recordcount gt 0>

								<cfif variables.addedamount gt 0>
									Reloading with #decimalformat(variables.addedamount)#
								</cfif>

							<cfelse>
								Reload with $
								<input type="text" name="cardid#getCards.cardid#" value="" style="width: 60px;" >
							</cfif>

						</td>
						<!---<td align="center" valign="top"><CFIF allowreloadflag EQ 1 AND getcards.isfa EQ 0><a href="giftcards.cfm?reloadcardnumber=#cryp.value#">Reload</a> | </CFIF><a href="giftcards.cfm?historycardnumber=#cryp.value#">View History</a></td>--->
					</tr>
					</CFLOOP>

					<TR align="right">
						<TD colspan="2">#getCards.recordcount# cards on file</TD>
						<TD style="border-bottom: double Grey;	border-top: 1px solid Grey;">#decimalformat( variables.cardsum )#</TD>
						<TD>

							<cfif variables.totalreloadamount gt 0>
								<input type="submit" value="Remove all load amounts" name="clearcards">
							<cfelse>
								<input type="submit" value="Load with above values" name="loadcards">
							</cfif>

						</TD>
					</TR>

					</form>

					<TR align="right">
						<TD colspan="99" align="right">

							<cfif variables.totalreloadamount gt 0>
								Total of all loading amounts: #decimalformat( variables.totalreloadamount )#
								<BR><BR>

								<!--- next step --->
								<form method="post" action="checkoutccinfo.cfm">
								<input type="hidden" name="currentsessionid" value="#sessionvars.sessionid#">
								<input type="hidden" name="primarypatronid" value="#cookie.uid#">
								<input type="hidden" name="totalfees" value="#variables.totalreloadamount#">
								<input type="submit" name="go1" value="Continue">
								</form>
								<!--- end next step --->

							<cfelse>
								Enter all loading amounts
							</cfif>

						</TD>
					</TR>

				</table>

				<!--- end content --->
				</td>
			</tr>
		</table>
   </td>
  </tr>
  <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">

</cfoutput>

</table>
</body>