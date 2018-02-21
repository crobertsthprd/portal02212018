<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>

<!---
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Patron Information</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">
--->

<!--- check for passed params --->





<cfif not IsDefined("form.startingBalance") or
	not IsDefined("form.totalFees") or
	not IsDefined("form.districtCreditUsed") or
	not IsDefined("form.amountDue") or
	not IsDefined("form.otherCreditUsed") or
	not IsDefined("form.otherCreditCardID") or
	not IsDefined("form.netDue")>
     <CFSAVECONTENT variable="message">
	Missing params.<BR>
	<cfif not IsDefined("form.startingBalance")>startingBalance<BR></cfif>
	<cfif not IsDefined("form.totalFees")>totalFees<BR></cfif>
	<cfif not IsDefined("form.districtCreditUsed")>districtCreditUsed<BR></cfif>
	<cfif not IsDefined("form.amountDue")>amountDue<BR></cfif>
	<cfif not IsDefined("form.otherCreditUsed")>otherCreditUsed<BR></cfif>
	<cfif not IsDefined("form.otherCreditCardID")>otherCreditCardID<BR></cfif>
	<cfif not IsDefined("form.netDue")>netDue<BR></cfif>
     </CFSAVECONTENT>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfif>

<cfset localfac = "WWW">
<cfset localnode = "W1">
<!---<cfset DS = "thirst">--->
<!---<cfinclude template="/common/functions.cfm">--->

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

			<cfinclude template="/common/sessioncheck.cfm">

			<cfinclude template="/common/functionsbp.cfm">



			<cfif sessioniscomplete( form.currentsessionid )>
				This session has already been completed. Log out and back in.
				<cfabort>
			</cfif>

			<!--- look for payment for this session --->
			<cfinclude template="/common/invoicetranxcheckforapproval.cfm">
			<!--- end look for payment for this session --->




			<cfset nextinvoice = getnextinvoice()>
			<cfset thismodule="REG">
			<cfset gllineno = 0>

			<cfset runningOC = 0>

			<cftransaction action="begin" isolation="REPEATABLE_READ">

			<!--- start content --->
			<cfif form.otherCreditCardID gt 0>

				<cfquery datasource="#application.dopsds#" name="GetCardData">
					select   cardid,
					         cardname,
					         isfa,
					         faappid,
					         activated,
					         valid,
					         sumnet,
					         othercreditdata,
					         othercredittype,
					         othercreditdesc,
					         acctid
					from     dops.othercredithistorysums
					where    cardid = <cfqueryparam value="#form.otherCreditCardID#" cfsqltype="cf_sql_integer" list="no">
				</cfquery>

				<cf_cryp type="de" string="#GetCardData.othercreditdata#" key="#key#">
				<cfset abbreviateoccardnumber = cryp.value>
				<cfset abbreviateoccardnumber = left( variables.abbreviateoccardnumber, 4 ) & "..." & right( variables.abbreviateoccardnumber, 4 )>
				<cfset runningoc = min( GetCardData.sumnet, form.otherCreditUsed )>
				<cfset otherCreditGLAcctid = GetCardData.acctid>
				<cfinclude template="/common/OCCardUsagePrefix.cfm">
			<cfelse>
				<cfset runningoc = 0>
			</cfif>

			<table border="0" width="100%" cellpadding="4" cellspacing="0">

			<cfquery datasource="#application.dopsds#" name="GetCurrentRegistrations">
				SELECT   sessionregconvert.*,
				         terms.termname,
				         reg.patronid,
				         patrons.lastname,
				         patrons.firstname,
				         patrons.middlename,
				         reg.termid,
				         reg.facid,
				         reg.classid,
				         reg.termid || '-' || reg.facid || '-' || reg.classid as tfc,
				         classes.description,
				         classes.glacctid,
				         classes.glmiscacctid,
				         facilities.name as facname,
				         classes.faeligible,
				         isdeposit and ispayingbalance as depositmode,
				         dcused,
				         ocused,
				         txused,
				         dcmfused,
				         ocmfused,
				         txmfused
				FROM     dops.sessionregconvert
				         INNER JOIN dops.reg ON sessionregconvert.primarypatronid=reg.primarypatronid AND sessionregconvert.regid=reg.regid
				         INNER JOIN dops.terms ON reg.termid=terms.termid AND reg.facid=terms.facid
				         INNER JOIN dops.patrons ON reg.patronid=patrons.patronid
				         INNER JOIN dops.classes ON reg.termid=classes.termid AND reg.facid=classes.facid AND reg.classid=classes.classid
				         INNER JOIN dops.facilities ON reg.facid=facilities.facid
				WHERE    sessionregconvert.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
				ORDER BY sessionregconvert.pk
			</cfquery>

			<cfif 0>
				<cfdump var="#GetCurrentRegistrations#" label="GetCurrentRegistrations">
			</cfif>

			<!---<cfif 1>

				<cfquery dbtype="query" name="t">
					SELECT   regid,
					         dcused,
					         ocused,
					         txused,
					         dcmfused,
					         ocmfused,
					         txmfused
					FROM     GetCurrentRegistrations
				</cfquery>
				<cfdump var="#t#" label="GetCurrentRegistrations resulting structure">
				<!---<cfabort>--->
			</cfif>--->





			<cfif GetCurrentRegistrations.recordcount gt 0>
				<!---<cfset gllineno = 0>--->



					<!--- process conversions --->
					<cfloop query="GetCurrentRegistrations">
						<cfset nextec = getnextec()>

						<!--- update patron last use --->
						<cfquery datasource="#application.dopsds#" name="UpdateLastUse">
							update dops.patrons
							set
								lastuse = current_date
							where  patronid = <cfqueryparam value="#GetCurrentRegistrations.patronid#" cfsqltype="CF_SQL_INTEGER">
						</cfquery>
						<!--- end update patron last use --->

						<cfif GetCurrentRegistrations.depositmode>
							<cfset thisclassfee = GetCurrentRegistrations.depositamount>
							<cfset thisclassmiscfee = 0>
						<cfelse>
							<cfset thisclassfee = GetCurrentRegistrations.classcost>
							<cfset thisclassmiscfee = GetCurrentRegistrations.miscfee>
						</cfif>

						<cfquery datasource="#application.dopsds#" name="UpdateRegEntry">
							update dops.reg
							set
								regstatus = <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">,
								isbeingconverted = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">,
								wasconverted = <cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
								deferred =

									<cfif not GetCurrentRegistrations.depositmode>
										<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
									<cfelse>
										<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
									</cfif>

								deferredpaid =

									<cfif GetCurrentRegistrations.depositmode>
										<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
									<cfelse>
										<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
									</cfif>

								feebalance = <cfqueryparam value="#variables.thisclassfee + variables.thisclassmiscfee#" cfsqltype="CF_SQL_MONEY">,
								depositonly = <cfqueryparam value="#GetCurrentRegistrations.depositmode#" cfsqltype="cf_sql_bit" list="no">,
								balancepaid = <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">
							where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
							and    regid = <cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="CF_SQL_INTEGER">
							;

							update dops.reghistory
							set
								pending = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
							where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
							and    regid = <cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="CF_SQL_INTEGER">
						</cfquery>


						<cfquery name="GetNextRegHistoryPK" datasource="#application.dopsds#">
							Select nextval('dops.reghistory_pk_seq') as pk
						</cfquery>

						<cfif GetCurrentRegistrations.miscfee gt 0>

							<cfquery name="GetNextRegHistoryMFPK" datasource="#application.dopsds#">
								Select nextval('dops.reghistory_pk_seq') as pk
							</cfquery>

						</cfif>

						<cfquery datasource="#application.dopsds#" name="InsertIntoHistory">
							insert into dops.reghistory
								(	pk,
									action,
									invoicefacid,
									invoicenumber,
									ec,
									primarypatronid,
									regid,
									finished,
									amount,
									balance,
									deferred,
									deferredpaid,
									depositonly,
									wasconverted,
									pending,
									depositbalpaid,
									userid )
							values
								(	<cfqueryparam value="#variables.GetNextRegHistoryPK.pk#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">,
									<cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">,
									<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#GetCurrentRegistrations.costec#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#GetCurrentRegistrations.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
									<cfqueryparam value="#GetCurrentRegistrations.dcused + GetCurrentRegistrations.ocused + GetCurrentRegistrations.txused#" cfsqltype="CF_SQL_MONEY">,
									<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">,
									<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --Deferred

									<cfif GetCurrentRegistrations.depositmode>
										<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">, --deferredpaid
									<cfelse>
										<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">, --deferredpaid
									</cfif>

									<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --depositonly
									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, --wasconverted
									<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --pending

									<cfif not GetCurrentRegistrations.depositmode>
										<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, --depositbalpaid
									<cfelse>
										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --depositbalpaid
									</cfif>

									<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER"> ) --user
								;

								<!--- class cost --->
								<cfif GetCurrentRegistrations.classcost gt 0>
									<cfset gllineno = variables.gllineno + 1>
									-- class GL entry 1
									insert into dops.gl
										(	acctid,
											activity,
											activitytype,
											credit,
											ec,
											entryline,
											invoicefacid,
											invoicenumber )
									values
										(	<cfqueryparam value="#GetCurrentRegistrations.glacctid#" cfsqltype="cf_sql_integer" list="no">,
											<cfqueryparam value="#GetCurrentRegistrations.tfc#" cfsqltype="cf_sql_varchar" list="no">,
											<cfqueryparam value="R" cfsqltype="cf_sql_char" maxlength="1" list="no">,
											<cfqueryparam value="#GetCurrentRegistrations.classcost#" cfsqltype="cf_sql_money" list="no">,
											<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
											<cfqueryparam value="#variables.gllineno#" cfsqltype="cf_sql_smallint" list="no">,
											<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
											<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no"> )
									;
								</cfif>

								<!---<cfif GetCurrentRegistrations.ocused gt 0 and 0>
									<cfset gllineno = variables.gllineno + 1>
									-- class GL entry 2
									insert into dops.gl
										(	acctid,
											activity,
											activitytype,
											credit,
											ec,
											entryline,
											invoicefacid,
											invoicenumber )
									values
										(	<cfqueryparam value="#GetCurrentRegistrations.glacctid#" cfsqltype="cf_sql_integer" list="no">,
											<cfqueryparam value="#GetCurrentRegistrations.tfc#" cfsqltype="cf_sql_varchar" list="no">,
											<cfqueryparam value="R" cfsqltype="cf_sql_char" maxlength="1" list="no">,
											<cfqueryparam value="#GetCurrentRegistrations.ocused#" cfsqltype="cf_sql_money" list="no">,
											<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
											<cfqueryparam value="#variables.gllineno#" cfsqltype="cf_sql_smallint" list="no">,
											<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
											<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no"> )
									;
								</cfif>--->

								<!---<cfif GetCurrentRegistrations.depositmode>
									<!--- convert deposit --->

								<cfelse>
									<!--- convert deferred --->

								</cfif>--->

						</cfquery>

						<cfif GetCurrentRegistrations.miscfee gt 0>

							<cfquery datasource="#application.dopsds#" name="InsertIntoHistory">
								insert into dops.reghistory
									(	pk,
										action,
										ismiscfee,
										invoicefacid,
										invoicenumber,
										ec,
										primarypatronid,
										regid,
										finished,
										amount,
										balance,
										deferred,
										deferredpaid,
										depositonly,
										wasconverted,
										pending,
										depositbalpaid,
										userid )
								values
									(	<cfqueryparam value="#variables.GetNextRegHistoryMFPK.pk#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
										<cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
										<cfqueryparam value="#GetCurrentRegistrations.miscec#" cfsqltype="CF_SQL_INTEGER">,
										<cfqueryparam value="#GetCurrentRegistrations.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
										<cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="CF_SQL_INTEGER">,
										<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
										<cfqueryparam value="#GetCurrentRegistrations.dcmfused + GetCurrentRegistrations.ocmfused + GetCurrentRegistrations.txmfused#" cfsqltype="CF_SQL_MONEY">,
										<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">,
										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --Deferred

										<cfif GetCurrentRegistrations.depositmode>
											<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">, --deferredpaid
										<cfelse>
											<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">, --deferredpaid
										</cfif>

										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --depositonly
										<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, --wasconverted
										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --pending

										<cfif not GetCurrentRegistrations.depositmode>
											<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, --depositbalpaid
										<cfelse>
											<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --depositbalpaid
										</cfif>

										<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">	) --user
									;

									<cfset gllineno = variables.gllineno + 1>
									-- class GL entry 3
									insert into dops.gl
										(	acctid,
											activity,
											activitytype,
											credit,
											ec,
											entryline,
											invoicefacid,
											invoicenumber )
									values
										(	<cfqueryparam value="#GetCurrentRegistrations.glmiscacctid#" cfsqltype="cf_sql_integer" list="no">,
											<cfqueryparam value="#GetCurrentRegistrations.tfc#-MF" cfsqltype="cf_sql_varchar" list="no">,
											<cfqueryparam value="R" cfsqltype="cf_sql_char" maxlength="1" list="no">,
											<cfqueryparam value="#GetCurrentRegistrations.miscfee#" cfsqltype="cf_sql_money" list="no">,
											<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
											<cfqueryparam value="#variables.gllineno#" cfsqltype="cf_sql_smallint" list="no">,
											<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
											<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no"> )
									;

									<!---<cfif GetCurrentRegistrations.ocmfused gt 0>
										<cfset gllineno = variables.gllineno + 1>
										-- class GL entry 5
										insert into dops.gl
											(	acctid,
												activity,
												activitytype,
												debit,
												ec,
												entryline,
												invoicefacid,
												invoicenumber )
										values
											(	<cfqueryparam value="#GetCurrentRegistrations.glmiscacctid#" cfsqltype="cf_sql_integer" list="no">,
												<cfqueryparam value="#GetCurrentRegistrations.tfc#-MF" cfsqltype="cf_sql_varchar" list="no">,
												<cfqueryparam value="R" cfsqltype="cf_sql_char" maxlength="1" list="no">,
												<cfqueryparam value="#GetCurrentRegistrations.ocmfused#" cfsqltype="cf_sql_money" list="no">,
												<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
												<cfqueryparam value="#variables.gllineno#" cfsqltype="cf_sql_smallint" list="no">,
												<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
												<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no"> )
										;
									</cfif>--->

								</cfquery>

							</cfif>





						<!--- oc stuff --->
						<cfif GetCurrentRegistrations.ocused gt 0>

							<cfquery datasource="#application.dopsds#" name="InsertOCRecords">
								insert into dops.othercreditdist (
									invoicefacid,
									invoicenumber,
									patronid,
									regid,
									ismiscfee,
									activity,
									action,
									cardid,
									credit)
								values
									(<cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, -- invoicefacid
									<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- invoicenumber
									<cfqueryparam value="#GetCurrentRegistrations.patronid#" cfsqltype="CF_SQL_INTEGER">, -- patronid
									<cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="CF_SQL_INTEGER">, -- regid
									<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, -- ismiscfee
									<cfqueryparam value="REG" cfsqltype="CF_SQL_VARCHAR">, -- activity
									<cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">, -- action
									<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">, -- cardid
									<cfqueryparam value="#GetCurrentRegistrations.ocused#" cfsqltype="CF_SQL_MONEY"> ) -- money
							</cfquery>

						</cfif>

						<cfif GetCurrentRegistrations.ocmfused gt 0>

							<cfquery datasource="#application.dopsds#" name="InsertOCRecords">
								insert into dops.othercreditdist (
									invoicefacid,
									invoicenumber,
									patronid,
									regid,
									ismiscfee,
									activity,
									action,
									cardid,
									credit)
								values
									(<cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, -- invoicefacid
									<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- invoicenumber
									<cfqueryparam value="#GetCurrentRegistrations.patronid#" cfsqltype="CF_SQL_INTEGER">, -- patronid
									<cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="CF_SQL_INTEGER">, -- regid
									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, -- ismiscfee
									<cfqueryparam value="REG" cfsqltype="CF_SQL_VARCHAR">, -- activity
									<cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">, -- action
									<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">, -- cardid
									<cfqueryparam value="#GetCurrentRegistrations.ocmfused#" cfsqltype="CF_SQL_MONEY"> ) -- money
							</cfquery>

						</cfif>
						<!--- end oc stuff --->





						<!--- tx stuff --->
						<cfif GetCurrentRegistrations.txused gt 0>
							<cfset nextprc = GetNextPRC()>

							<cfquery datasource="#application.dopsds#" name="InsertIntoHistory2">
								update dops.reghistory
								set
									prc = <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">
								where  pk = <cfqueryparam value="#variables.GetNextRegHistoryPK.pk#" cfsqltype="cf_sql_integer" list="no">
								;

								insert into dops.invoicetranxtrans
									(	prc,
									reg )
								values
									( <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no"> )
								;

								insert into dops.invoicetranxdist
									(	primarypatronid,
										invoicefacid,
										invoicenumber,
										regid,
										ismiscfee,
										prc,
										reftype,
										action,
										amount )
								values
								(	<cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
									<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="REG" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">,
									<cfqueryparam value="#GetCurrentRegistrations.txused#" cfsqltype="cf_sql_money" list="no"> )
							</cfquery>

							<cfinclude template="/common/invoicetranxupdatetxdist.cfm">
						</cfif>

						<cfif GetCurrentRegistrations.txmfused gt 0>
							<cfset nextprc = GetNextPRC()>

							<cfquery datasource="#application.dopsds#" name="InsertIntoHistory3">
								update dops.reghistory
								set
									prc = <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">
								where  pk = <cfqueryparam value="#variables.GetNextRegHistoryMFPK.pk#" cfsqltype="cf_sql_integer" list="no">
								;

								insert into dops.invoicetranxtrans
									(	prc,
									reg )
								values
									( <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no"> )
								;

								insert into dops.invoicetranxdist
									(	primarypatronid,
										invoicefacid,
										invoicenumber,
										regid,
										ismiscfee,
										prc,
										reftype,
										action,
										amount )
								values
								(	<cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
									<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="REG" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">,
									<cfqueryparam value="#GetCurrentRegistrations.txmfused#" cfsqltype="cf_sql_money" list="no"> )
							</cfquery>

							<cfinclude template="/common/invoicetranxupdatetxdist.cfm">
						</cfif>
						<!--- end tx stuff --->

					</cfloop>
					<!--- end process conversions --->



					<!--- post used DC --->
					<cfif form.districtCreditUsed gt 0>
						<cfset gllineno = variables.gllineno + 1>
						<cfset nextec = getnextec()>

						<cfquery datasource="#application.dopsds#" name="InsertIntoHistory">
							-- class GL entry 4
							insert into dops.gl
								(	acctid,
									activity,
									activitytype,
									debit,
									ec,
									entryline,
									invoicefacid,
									invoicenumber )
							values
								(	<cfqueryparam value="2" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="Credit" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="C" cfsqltype="cf_sql_char" maxlength="1" list="no">,
									<cfqueryparam value="#form.districtCreditUsed#" cfsqltype="cf_sql_money" list="no">,
									<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="#variables.gllineno#" cfsqltype="cf_sql_smallint" list="no">,
									<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no"> )
						</cfquery>

					</cfif>

					<cfset totalfees = form.amountdue + form.districtCreditUsed + form.otherCreditUsed>

					<!---<cfif form.otherCreditCardID gt 0>

						<cfquery datasource="#application.dopsds#" name="InsertOCData">
							insert into dops.othercreditdatahistory
								(	action,
									invoicefacid,
									invoicenumber,
									debit,
									--credit,
									userid,
									--valid,
									module,
									--,
									cardid	)
							values
								(	<cfqueryparam value="U" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="#form.otherCreditUsed#" cfsqltype="cf_sql_money" list="no">,
									<cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">,
									<cfqueryparam value="DO" cfsqltype="cf_sql_varchar" list="no">,
									<cfqueryparam value="#GetCardData.cardid#" cfsqltype="cf_sql_money" list="no">	)
						</cfquery>

					</cfif>--->

					<!--- get invoice types --->
					<cfset deptype = false>
					<cfset defertype= false>

					<cfquery datasource="#application.dopsds#" name="InsertInvoice">
						insert into dops.invoice
							(	invoicefacid,
								invoicenumber,
								totalfees,
								usedcredit,
								othercreditused,
								othercreditusedcardid,
								faappid,
								tenderedcc,
								node,
								userid,
								primarypatronid,
								addressid,
								mailingaddressid,
								indistrict,
								insufficientid,
								startingbalance,
								firstname,
								lastname,
								invoicetype )
						values
							(	<cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
								<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
								<cfqueryparam value="#form.amountdue#" cfsqltype="CF_SQL_MONEY">, --TotalFees

								<cfif form.primarypatronid gt 0>
									<cfqueryparam value="#districtCreditUsed#" cfsqltype="CF_SQL_MONEY">, -- dc used
								<cfelse>
									null,
								</cfif>

								<cfqueryparam value="#form.otherCreditUsed#" cfsqltype="CF_SQL_MONEY">, --othercreditused

								<cfif form.otherCreditCardID gt 0>
									<cfqueryparam value="#form.otherCreditCardID#" cfsqltype="CF_SQL_INTEGER">, --othercreditusedcardid
								<cfelse>
									null, ----othercreditusedcardid
								</cfif>

								<cfif form.otherCreditCardID gt 0 and GetCardData.faappid neq "">
									<cfqueryparam value="#GetCardData.faappid#" cfsqltype="CF_SQL_INTEGER">, --faappid
								<cfelse>
									null, --faappid
								</cfif>

								<cfqueryparam value="#form.netDue#" cfsqltype="CF_SQL_MONEY">, --TenderedCC
								<cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">, --LocalNode
								<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --huserID

								<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, (

								select   addressid
								from     dops.patronrelations
								where    primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								and      secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

								select   mailingaddressid
								from     dops.patronrelations
								where    primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								and      secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

								SELECT   indistrict
								FROM     dops.patronrelations
								WHERE    primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								AND      secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

								SELECT   patrons.insufficientid
								FROM     dops.patronrelations patronrelations
								         INNER JOIN dops.patrons patrons ON patronrelations.secondarypatronid=patrons.patronid
								WHERE    patronrelations.primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								AND      patronrelations.secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

								select   dops.primaryaccountbalance( <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)), (

								select   firstname
								from     dops.patrons
								where    patronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER"> ), ( -- firstname

								select   lastname
								from     dops.patrons
								where    patronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER"> ), -- lastname

								<cfqueryparam value="-REGCONV-" cfsqltype="CF_SQL_VARCHAR"> )
							;

							<cfif 1>
								;
								select invoice_relation_fill(<cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">,
									<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as inserted
							</cfif>

					</cfquery>

			<!--- finalcheck arguments:
			<cfargument name="nextinvoice" required="yes" type="numeric">
			<cfargument name="tenderedcc" required="yes" type="numeric">
			<cfargument name="occardid" required="no" type="numeric" default="0">
			<cfargument name="ocused" required="no" type="numeric" default="0">--->
			<cfset fc = finalcheck( variables.nextinvoice, form.netDue, val( form.otherCreditCardID ), form.otherCreditUsed )>

			<cfif variables.fc neq "OK">
				Final check ERROR!
				#variables.fc#
				<cfinclude template="/common/displayallinvoicetables.cfm">
				<cfabort>
			</cfif>


			<cfif 0>
				<cfinclude template="/common/displayallinvoicetables.cfm">
				<cfabort>
			</cfif>


			<cfif form.netDue gt 0>
				<!--- direction decision --->
				<cfif not variables.approved>
					<!--- no payment found --->
					<cftransaction action="ROLLBACK" />

					<cfset customer = StructNew()>

					<cfquery datasource="#application.dopsds#" name="patroninfo">
						SELECT   patroninfo.lastname,
						         patroninfo.firstname,
						         patroninfo.address1,
						         patroninfo.address2,
						         patroninfo.city,
						         patroninfo.state,
						         patroninfo.zip, (

						select   contactdata
						from     dops.patroncontact
						where    position( patroncontact.contacttype in <cfqueryparam value="HWC" cfsqltype="cf_sql_varchar" list="no"> ) > <cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">
						and      patroncontact.patronid = patroninfo.primarypatronid
						order by position( patroncontact.contacttype in <cfqueryparam value="HWC" cfsqltype="cf_sql_varchar" list="no"> )
						limit    1 ) as contact, (

						select   patrons.loginemail
						from     dops.patrons
						where    patronid = patroninfo.primarypatronid ) as email

						FROM     dops.patroninfo
						WHERE    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						AND      relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
					</cfquery>

					<cfset customer.primarypatronid  = form.primarypatronid>
					<cfset customer.currentsessionid = form.currentsessionid>
					<cfset customer.firstname        = patroninfo.firstname>
					<cfset customer.lastname         = patroninfo.lastname>
					<cfset customer.address1         = patroninfo.address1>
					<cfset customer.address2         = patroninfo.address2>
					<cfset customer.city             = patroninfo.city>
					<cfset customer.state            = uCase( patroninfo.state )>
					<cfset customer.zip              = uCase( patroninfo.zip )>
					<cfset customer.phone            = patroninfo.contact>
					<cfset customer.email            = patroninfo.email>
					<cfset customer.amount           = form.netDue>
					<cfset customer.name             = trim( customer.firstname & " " & customer.lastname )>
					<cfset customer.callcomment      = "REGCONV">

					<cfif 0>
						<cfset customer.testmode         = 1>
					<cfelse>
						<cfset customer.testmode         = 0>
					</cfif>

					<!--- set ccsale() mode --->
					<cfset customer.ccsalemode = "REAL">

					<cfif customer.testmode>
						<cfset customer.ccsalemode = "TESTD"><!--- test decline --->

						<cfif 1>
							<cfset customer.ccsalemode = "TESTA"><!--- test approval --->
						</cfif>

					</cfif>

					<!--- close and call BP web interface --->
					<cfset posturl = "regbaldue5.cfm">
					<cfinclude template="/common/invoicetranxcallclose.cfm">


					#variables.maincontent#


				<cfelse>
					<!--- finish session --->
					<!--- return 0 = OK, 1 = funds wrong, 2 = cftry failure --->

					<cfset sessionwasfinished = invoicetranxcallfinish( form.currentsessionid, variables.nextinvoice )>
					<!---sessionwasfinished = #sessionwasfinished#--->

					<cfif variables.sessionwasfinished neq 0>
						<!--- open call was created. rollback and stop user form further actions. --->
						<cftransaction action="rollback" />
					</cfif>

				</cfif>
				<!--- end direction decision --->

			</cfif>



		</cfif>

			</cftransaction>
		</table>

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