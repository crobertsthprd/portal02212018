<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Pay Balance</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>

<body leftmargin="0" topmargin="0">

<cfset localfac = "WWW">
<cfset localnode = "W1">
<!---<cfset DS = "thirst">--->
<!---<cfinclude template="/common/functionsv2.cfm">--->

<cfoutput>
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
							<td><img src="/portal/images/spacer.gif" width="130" height="1" border="0" alt=""></td>
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
			<table border="0" width="100%" cellpadding="4" cellspacing="0">


		<cfinclude template="/common/sessioncheck.cfm">

		<cfset sessiondata = getprimarysessiondata( cookie.uid )>
		<cfset currentsessionid = variables.sessiondata.sessionid>


		<CFSET startbalance = primarybalance( cookie.uID )>

		<cfquery datasource="#application.dopsds#ro" name="GetNewRegistrations">
			SELECT   reg.pk
			FROM     reg
			         INNER JOIN reghistory reghistory ON reg.primarypatronid=reghistory.primarypatronid AND reg.regid=reghistory.regid
			WHERE    reg.SessionID is not null
			and      reg.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
			limit    1
		</cfquery>

		<cfquery datasource="#application.reg_dsn#" name="GetCurrentRegistrations">
			SELECT   reg.pk,
			         reg.primarypatronid,
			         reg.regid,
			         reg.costbasis,
			         reg.miscbasis,
			         reg.feebalance,
			         reg.deferred,
			         reg.depositonly,
			         classes.iddeposit,
			         classes.oddeposit,
			         dops.getregbalance(
			         	reg.primarypatronid::integer,
			         	reg.regid::integer ) as truebal
			FROM     dops.Reg
			         INNER JOIN dops.classes ON Reg.TermID=Classes.TermID AND Reg.FacID=Classes.FacID AND Reg.ClassID=Classes.ClassID
			WHERE    reg.PrimaryPatronID = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
			and      reg.regstatus = <cfqueryparam value="E" cfsqltype="cf_sql_varchar" list="no">
			and      (( reg.depositonly and not reg.balancepaid ) or ( reg.deferred and not reg.deferredpaid ))
			and      reg.valid
			AND      Classes.EndDT >= now()
		</cfquery>

		<cfif 0>
			<cfdump var="#GetCurrentRegistrations#">
		</cfif>


		<cfloop query="GetCurrentRegistrations">
			<cfset trialregset = "convertpkset" & GetCurrentRegistrations.pk>

			<cfif IsDefined("#variables.trialregset#")>

				<cftransaction isolation="REPEATABLE_READ" action="BEGIN">
					<cfset costec1 = GetNextEC()>
					<cfset miscec1 = GetNextEC()>

					<cfquery datasource="#application.dopsds#" name="getregec">
						SELECT   ec
						FROM     dops.reghistory
						WHERE    action = <cfqueryparam value="E" cfsqltype="cf_sql_varchar" list="no">
						AND      not ismiscfee
						AND      depositonly
						AND      not depositbalpaid
					</cfquery>

					<cfquery datasource="#application.dopsds#" name="getregadjamt">
						select   adjustment
						from     dops.adjustments
						where    adjustments.ec = <cfqueryparam value="#getregec.ec#" cfsqltype="cf_sql_integer" list="no">
						and      not ismiscfee
						order by pk desc
						limit    1
					</cfquery>

					<cfquery datasource="#application.dopsds#" name="getregadjmfamt">
						select   adjustment
						from     dops.adjustments
						where    adjustments.ec = <cfqueryparam value="#getregec.ec#" cfsqltype="cf_sql_integer" list="no">
						and      ismiscfee
						order by pk desc
						limit    1
					</cfquery>

					<cfquery name="Update1" datasource="#application.dopsds#">
						update dops.reg
						set
							IsBeingConverted = <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">
						where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.PrimaryPatronID#" cfsqltype="cf_sql_integer" list="no">
						and    regid = <cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="cf_sql_integer" list="no">
						;

						delete from dops.sessionregconvert
						where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						and    regid = <cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">
						;

						insert into dops.sessionregconvert
							( sessionid,
							primarypatronid,
							regid,

							classcost,
							miscfee,

							<cfif GetCurrentRegistrations.deferred>
								isdefer,
							<cfelse>
								isdeposit,
							</cfif>

							ispayingbalance,
							costec,
							miscec )
						values
							( <cfqueryparam value="#variables.sessiondata.sessionid#" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">,

							<cfif GetCurrentRegistrations.deferred>
								<!--- defer mode --->
								<cfqueryparam value="#GetCurrentRegistrations.truebal#" cfsqltype="cf_sql_money" list="no">, -- class cost
								<cfqueryparam value="#GetCurrentRegistrations.miscbasis#" cfsqltype="cf_sql_money" list="no">, -- misc fee
							<cfelse>
								<!--- deposit mode --->
								<cfqueryparam value="#GetCurrentRegistrations.truebal#" cfsqltype="cf_sql_money" list="no">, -- class cost
								<cfqueryparam value="#GetCurrentRegistrations.miscbasis#" cfsqltype="cf_sql_money" list="no">, -- misc fee
							</cfif>

							<cfif GetCurrentRegistrations.deferred>
								<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">, -- mode
								<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">, -- ispayingbalance
							<cfelse>
								<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">, -- mode
								<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">, -- ispayingbalance
							</cfif>

							<cfqueryparam value="#variables.costec1#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#variables.miscec1#" cfsqltype="cf_sql_integer" list="no"> )
					</cfquery>

				</cftransaction>

			</cfif>

			<cfset trialregclear = "convertpkclear" & GetCurrentRegistrations.pk>

			<cfif IsDefined("#variables.trialregclear#")>

				<cftransaction isolation="REPEATABLE_READ" action="BEGIN">

					<cfquery name="Update1" datasource="#application.dopsds#">
						update dops.reg
						set
							IsBeingConverted = <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">
						where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.PrimaryPatronID#" cfsqltype="cf_sql_integer" list="no">
						and    regid = <cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="cf_sql_integer" list="no">
						;

						delete from dops.sessionregconvert
						where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						and    regid = <cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">
						;

						delete from dops.sessionregconvert
						where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						and    regid = <cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">
					</cfquery>

				</cftransaction>

			</cfif>

		</cfloop>






		<!--- toggle form --->
		<form action="#cgi.script_name#" method="post" name="paydep">
		<TR>
			<TD colspan="11">

				<table border="0" width="0" cellpadding="3" cellspacing="0">
					<TR>
						<TD colspan="7" class="pghdr"><br>Pay Deposit Balances/Deferred: Current Registrations</TD>
						<td align="right" valign="bottom"><a href="javascript:window.print();">Print</a></td>
					</TR>
					<TR valign="bottom" bgcolor="cccccc">
						<TD><strong>Class ID</strong></TD>
						<TD align="right"><strong>Reg<BR>ID</strong></TD>
						<TD><strong>Description</strong></TD>
						<TD><strong>Facility</strong></TD>
						<TD><strong>Patron</strong></TD>
						<TD><strong>Status</strong></TD>
						<TD><strong>Action</strong></TD>
						<td align="right"><strong>Amount Due</strong></td>
						<td align="right"><strong>Pay Balance</strong></td>
					</TR>

					<CFSET amountDue = 0>
					<cfset thisrow = 0>

					<!--- master loop --->
					<!--- 1=deposits, 2=deferred --->
					<cfloop from="1" to="2" step="1" index="loopcnt">

						<cfquery datasource="#application.reg_dsn#" name="GetCurrentRegistrationsForDisplay">
							SELECT   reg.pk,
							         reg.regid,
							         reg.primarypatronid,
							         reg.classid,
							         reg.feebalance,
							         reg.sessionid,
							         reg.costbasis,
							         reg.miscbasis,
							--         classes.iddeposit,
							--         classes.oddeposit,
							--         dops.hasvalidassmt( reg.primarypatronid::integer, classes.startdt::date, classes.enddt::date ) as hasvalidassmt,
							         reg.depositonly,
							         dops.getregbalance(
							         	reg.primarypatronid::integer,
							         	reg.regid::integer ) as truebal,
							         classes.Description,
							         patrons.lastname,
							         patrons.firstname,
							         patrons.middlename,
							         reg.regid,
							         facilities.name as facname,

							<cfif variables.loopcnt eq 1>
								'dep' as mode, (
							<cfelse>
								'def' as mode, (
							</cfif>

								select   sessionregconvert.costadj
								from     dops.sessionregconvert
								where    sessionregconvert.primarypatronid=reg.primarypatronid
								and      sessionregconvert.regid=reg.regid ) as costadj, (

								select   sessionregconvert.miscadj
								from     dops.sessionregconvert
								where    sessionregconvert.primarypatronid=reg.primarypatronid
								and      sessionregconvert.regid=reg.regid ) as miscadj

							FROM     dops.reg
							         INNER JOIN dops.classes ON Reg.TermID=Classes.TermID AND Reg.FacID=Classes.FacID AND Reg.ClassID=Classes.ClassID
							         INNER JOIN dops.patrons ON Reg.PatronID=patrons.PatronID
							         INNER JOIN dops.terms ON Reg.TermID=Terms.TermID AND Reg.FacID=Terms.FacID
							         INNER JOIN dops.regstatuscodes ON Reg.regstatus=regstatuscodes.StatusCode
							         INNER JOIN dops.facilities on reg.facid = facilities.facid
							WHERE    reg.PrimaryPatronID = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">

							<cfif variables.loopcnt eq 1>
								and      reg.depositonly
								and      not reg.balancepaid
								and      reg.regstatus = <cfqueryparam value="E" cfsqltype="cf_sql_varchar" list="no">
							<cfelse>
								and      reg.deferred
								and      not reg.deferredpaid
								and      reg.regstatus in (
									<cfqueryparam value="R" cfsqltype="cf_sql_char" maxlength="1" list="no">,
									<cfqueryparam value="H" cfsqltype="cf_sql_char" maxlength="1" list="no">,
									<cfqueryparam value="E" cfsqltype="cf_sql_char" maxlength="1" list="no"> )
							</cfif>

							and      reg.valid
							AND      classes.enddt >= now()
							ORDER BY reg.regid
						</cfquery>

						<cfif 0>
							<cfdump var="#GetCurrentRegistrationsForDisplay#">
						</cfif>




						<cfloop query="GetCurrentRegistrationsForDisplay">
							<cfset thisrow = variables.thisrow + 1>
							<cfset thisclassdue = 0>

							<cfquery datasource="#application.reg_dsn#" name="GetThisRegConversionStatus">
								select   pk
								from     dops.sessionregconvert
								where    primarypatronid = <cfqueryparam value="#GetCurrentRegistrationsForDisplay.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
								and      regid = <cfqueryparam value="#GetCurrentRegistrationsForDisplay.regid#" cfsqltype="cf_sql_integer" list="no">
							</cfquery>

							<cfif 0>
								<cfdump var="#GetThisRegConversionStatus#">
							</cfif>

							<CFIF Isdefined("form.reg#GetCurrentRegistrationsForDisplay.regid#_bal")>
								<CFSET thestyle = "boldtext">
							<CFELSE>
								<CFSET thestyle = "bodytext3">
							</CFIF>

							<cfset bg = "ffffff">

							<cfif variables.thisrow mod 2 eq 0>
								<cfset bg = "eeeeee">
							</cfif>

							<TR valign="top" style="background-color: #variables.bg#">
								<TD class="#variables.thestyle#">#GetCurrentRegistrationsForDisplay.ClassID#</TD>
								<TD class="#variables.thestyle#" align="right">#GetCurrentRegistrationsForDisplay.regid#</TD>
								<TD class="#variables.thestyle#">#GetCurrentRegistrationsForDisplay.Description#</TD>
								<TD class="#variables.thestyle#">#replacenocase(replacenocase(GetCurrentRegistrationsForDisplay.facname,"Recreation",""),"Center","")#</TD>
								<TD class="#variables.thestyle#">#GetCurrentRegistrationsForDisplay.lastname#, #GetCurrentRegistrationsForDisplay.firstname# #GetCurrentRegistrationsForDisplay.middlename#</TD>
								<TD class="#variables.thestyle#" nowrap>

									<cfif GetCurrentRegistrationsForDisplay.mode eq "dep">
										Balance Due
									<cfelse>
										Deferred
									</cfif>

								</TD>
								<TD class="#variables.thestyle#" nowrap>

									<cfif GetThisRegConversionStatus.recordcount eq 1>

										<!---<cfif variables.loopcnt eq 1>
											<!---<cfset amountdue = variables.amountdue + GetCurrentRegistrationsForDisplay.feebalance>--->
											<cfset thisclassdue = GetCurrentRegistrationsForDisplay.feebalance>
											<cfset amountdue = variables.amountdue + GetCurrentRegistrationsForDisplay.truebal>
										<cfelse>--->
											<!---<cfset amountdue = variables.amountdue + GetCurrentRegistrationsForDisplay.costbasis + GetCurrentRegistrationsForDisplay.miscbasis>--->
											<cfset thisclassdue = max( 0, val( GetCurrentRegistrationsForDisplay.truebal ) + val( GetCurrentRegistrationsForDisplay.miscbasis ) - val( GetCurrentRegistrationsForDisplay.costadj ) - val( GetCurrentRegistrationsForDisplay.miscadj ) )>
											<cfset amountdue = variables.amountdue + variables.thisclassdue>
										<!---</cfif>--->

										Make Payment
									</cfif>

								</TD>

								<!---<cfif GetCurrentRegistrationsForDisplay.mode eq "dep">
									<!--- deposit mode --->
									<td align="right" class="#variables.thestyle#">
										<!---$#decimalformat( GetCurrentRegistrationsForDisplay.feebalance )#--->
										<!---$#decimalformat( GetCurrentRegistrationsForDisplay.truebal )#--->
										$#decimalformat( variables.thisclassdue )#
									</td>
								<cfelse>
									<!--- defer mode --->
									<td align="right" class="#variables.thestyle#">
										<!---$#decimalformat(GetCurrentRegistrationsForDisplay.costbasis + GetCurrentRegistrationsForDisplay.miscbasis)#--->
										<!---$#decimalformat( val( GetCurrentRegistrationsForDisplay.truebal ) + val( GetCurrentRegistrationsForDisplay.miscbasis ) - val( GetCurrentRegistrationsForDisplay.costadj ) - val( GetCurrentRegistrationsForDisplay.miscadj ) )#--->
										$#decimalformat( variables.thisclassdue )#
									</td>
								</cfif>--->

								<td align="right" class="#variables.thestyle#">$#decimalformat( variables.thisclassdue )#</td>
								<TD>

									<cfif GetNewRegistrations.recordcount eq 0>

										<cfif GetThisRegConversionStatus.recordcount eq 0>
											<input type="submit" name="convertpkset#GetCurrentRegistrationsForDisplay.pk#" value="Pay" style="width: 50px;">
										<cfelse>
											<input type="submit" name="convertpkclear#GetCurrentRegistrationsForDisplay.pk#" value="Clear" style="width: 50px;">
										</cfif>

									</cfif>

								</TD>
							</TR>

							<cfif val( GetCurrentRegistrationsForDisplay.costadj ) - val( GetCurrentRegistrationsForDisplay.miscadj ) gt 0>
								<TR style="background-color: #variables.bg#">
									<TD colspan="99">Amount due reflects adjustment of #decimalformat( val( GetCurrentRegistrationsForDisplay.costadj ) - val( GetCurrentRegistrationsForDisplay.miscadj ) )#. Do not clear this line to retain this adjustment.</TD>
								</TR>
							</cfif>

						</cfloop>

					</cfloop>
					<!--- end master loop --->

					<!--- convert from wl --->
					<cfquery datasource="#application.reg_dsn#" name="GetCurrentWLRegistrations">
						select   reg.regid,
						         reg.termid,
						         reg.facid,
						         reg.classid,
						         classes.description,
						         sessionregconvert.classcost,
						         sessionregconvert.miscfee,
						         sessionregconvert.costadj,
						         sessionregconvert.miscadj,
						         sessionregconvert.converttodeposit,
						         sessionregconvert.depositamount,
						         patrons.patronid,
						         patrons.lastname,
						         patrons.firstname,
						         facilities.name as facname,
						         dops.getregrate(
						         	reg.primarypatronid::integer,
						         	reg.patronid::integer,
						         	reg.termid,
						         	reg.facid,
						         	reg.classid,
						         	false,
						         	false ) as truerate
						from     dops.sessionregconvert
						         inner join dops.reg on sessionregconvert.primarypatronid = reg.primarypatronid and sessionregconvert.regid = reg.regid
						         inner join dops.classes on reg.termid=classes.termid and reg.facid=classes.facid and reg.classid=classes.classid
						         inner join dops.patrons on reg.patronid=patrons.patronid
						         inner join dops.facilities on reg.facid=facilities.facid
						where    sessionregconvert.sessionid = <cfqueryparam value="#currentsessionid#" cfsqltype="cf_sql_varchar" list="no">
						and      reg.regstatus in (
							<cfqueryparam value="R" cfsqltype="cf_sql_char" maxlength="1" list="no">,
							<cfqueryparam value="H" cfsqltype="cf_sql_char" maxlength="1" list="no"> )
					</cfquery>

					<cfif 0>
						<cfdump var="#GetCurrentWLRegistrations#">
					</cfif>

					<cfif GetCurrentWLRegistrations.recordcount gt 0>
						<TR>
							<TD colspan="9" align="right"><br></TD>
						</TR>
						<TR>
							<TD colspan="99" class="pghdr">
								Pay Wait List to Enrolled Conversions
							</TD>
						</TR>
						<TR valign="bottom" bgcolor="cccccc">
							<TD><strong>Class ID</strong></TD>
							<TD align="right"><strong>Reg<BR>ID</strong></TD>
							<TD><strong>Description</strong></TD>
							<TD><strong>Facility</strong></TD>
							<TD><strong>Patron</strong></TD>
							<TD><strong>Status</strong></TD>
							<TD><strong>Action</strong></TD>
							<td align="right"><strong>Amount Due</strong></td>
							<TD></TD>
						</TR>

						<cfset thestyle="">
						<cfset thisrow = 0>

						<cfloop query="GetCurrentWLRegistrations">
							<cfset thisrow = variables.thisrow + 1>

							<cfset bg = "ffffff">

							<cfif variables.thisrow mod 2 eq 0>
								<cfset bg = "eeeeee">
							</cfif>

							<TR style="background-color: #variables.bg#" valign="top">
								<TD class="#variables.thestyle#">#GetCurrentWLRegistrations.ClassID#</TD>
								<TD class="#variables.thestyle#" align="right">#GetCurrentWLRegistrations.regid#</TD>
								<TD class="#variables.thestyle#">#GetCurrentWLRegistrations.Description#</TD>
								<TD class="#variables.thestyle#">#replacenocase(replacenocase(GetCurrentWLRegistrations.facname,"Recreation",""),"Center","")#</TD>
								<TD class="#variables.thestyle#">#GetCurrentWLRegistrations.lastname#, #GetCurrentWLRegistrations.firstname#</TD>
								<TD class="#variables.thestyle#" nowrap>
									Enrollment
								</TD>
								<TD class="#variables.thestyle#" nowrap>
									Make Payment
								</TD>
								<td align="right" class="#variables.thestyle#">
									<!---$#decimalformat(GetCurrentRegistrations.costbasis + GetCurrentRegistrations.miscbasis)#--->

									<cfif GetCurrentWLRegistrations.converttodeposit>
										$#decimalformat( GetCurrentWLRegistrations.depositamount )#
										<cfset amountdue = variables.amountdue + GetCurrentWLRegistrations.depositamount>
									<cfelse>
										$#decimalformat( GetCurrentWLRegistrations.classcost + GetCurrentWLRegistrations.miscfee )#
										<cfset amountdue = variables.amountdue + GetCurrentWLRegistrations.classcost + GetCurrentWLRegistrations.miscfee>
									</cfif>

								</td>
								<TD>

									<!---<cfif GetThisRegConversionStatus.recordcount eq 0>
										<input type="submit" name="convertpkset#GetCurrentRegistrations.pk#" value="Pay" style="width: 50px;">
									<cfelse>
										<input type="submit" name="convertpkclear#GetCurrentRegistrations.pk#" value="Clear" style="width: 50px;">
									</cfif>--->

								</TD>
							</tr>
							<!---<cfset amountdue = variables.amountdue + GetCurrentWLRegistrations.classcost + GetCurrentWLRegistrations.miscfee>--->

							<cfif GetCurrentWLRegistrations.costadj + GetCurrentWLRegistrations.miscadj gt 0>
								<TR style="background-color: #variables.bg#" valign="top">
									<TD colspan="8">Amount due reflects adjustment of #decimalformat( GetCurrentWLRegistrations.costadj + GetCurrentWLRegistrations.miscadj )#</TD>
									<TD></TD>
								</TR>
							</cfif>

						</cfloop>

					</cfif>

					<TR>
						<TD colspan="9" align="right"><br></TD>
					</TR>
					<TR>
						<TD colspan="7" align="right">Total of payments</TD>
						<TD align="right" style="border-top: 1px solid Grey; border-bottom: double grey;">$#decimalformat( variables.amountDue )#</TD>
						<TD></TD>
					</TR>

					<cfset creditUsed = min( variables.startbalance, variables.amountDue )>
					<cfset NetDue = max( 0, variables.amountDue - variables.startbalance )>

					<cfset monies = ArrayNew(1)>
					<!--- defined as startbal, totfees, dcused, adjdue, ocused, netdue --->
					<cfset monies[1] = variables.startbalance>
					<cfset monies[2] = variables.amountDue>
					<cfset monies[3] = variables.creditused>
					<cfset monies[4] = variables.netdue>
					<cfset monies[5] = "">
					<cfset monies[6] = "">
					<cfset displaymoniesleadingcol = 6>
					<!---
					<cfinclude template="displaymonies.cfm">
					--->
				</table>

				<br>
				<CFIF amountDue GT 0>
				<cfset lastmonth = dateadd('m','-1',now())>
				<!--- look up credit; etc --->

				<!---<table border="0" cellspacing="1" cellpadding="2">
				<TR align="right">
					<td class="bodytext" colspan="2" valign=top nowrap bgcolor="FFFFCC"><cfset lastmonth = dateadd('m','-1',now())></TD>
					<td bgcolor="FFFFCC">&nbsp;</td>
					<td class="bodytext" align="right" colspan=2 valign=top nowrap bgcolor="FFFFCC">Account Starting Balance<br>
						Total Fees<br>
						Credit Used<br>
						Amount Due<br>
					</TD>
					<td bgcolor="FFFFCC">&nbsp;</td>
					<td width="60" class="bodytext" align="right" valign=top bgcolor="FFFFCC">#decimalformat( variables.startbalance )#<br>
						#decimalformat( variables.amountDue )#<br>
						#decimalformat( variables.CreditUsed )#<br>
						<span class="bodytext_red">#decimalformat( variables.NetDue )#</span><br>
						<!---<span class="bodytext"><strong>#decimalformat( variables.NetBalance - variables.CreditUsed )#</strong></span>--->
					</TD>
				</TR>
				</table>--->
				</form>
				<!--- end toggle form --->


				<!--- submit form --->
				<div align="center">
				<form method="post" action="checkoutstepone.cfm">

					<cfif GetNewRegistrations.recordcount eq 0>
						<input <!---onClick="window.location='checkoutstepone.cfm';"---> type="submit" value="Checkout"  style="background-color:##0000cc;font-weight:bold;font-size:10px;color:##ffffff;width:150px;">
					<cfelse>
						<strong>Pay Balance is not available while registering new classes.</strong>
					</cfif>

					<!---<input type="submit" name="nextstep" value="Continue">--->
					<input type="hidden" name="currentsessionid" value="#variables.currentsessionid#">
					<input type="hidden" name="startingbalance" value="#variables.startbalance#">
					<input type="hidden" name="primarypatronid" value="#cookie.uID#">
					<input type="hidden" name="districtCreditUsed" value="#variables.creditused#">
					<input type="hidden" name="amountDue" value="#variables.amountdue#">
					<input type="hidden" name="NetDue" value="#variables.NetDue#">
				</form>
				</div>
				<!--- end submit form --->
				</CFIF>
			</TD>
		</TR>
</table>
</td>
		</tr>
		</table>
   </td>
  </tr>
  <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">

</table>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>
</cfoutput>