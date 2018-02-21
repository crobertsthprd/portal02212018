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
	Missing parameters. Go back and try again.<BR>
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

<cfset t = ListToArray( form.currentsessionid )>
<cfset form.currentsessionid = t[1]>

<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset invoicetranxcallcomments = "">

<!---<cfinclude template="/common/functionsv2.cfm">--->
<cfinclude template="/common/sessioncheck.cfm">
<cfinclude template="/common/functionsfp.cfm">
<cfinclude template="/common/checkformelements.cfm">
<cfset sessionvars = getprimarysessiondata(cookie.uid)>

<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" ) or form.currentsessionid neq sessionvars.sessionid>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<cfif sessionvars.module neq "REGCONV">
	<CFSAVECONTENT variable="message">
	Activities not related to class deposit/deferred payment operations were detected.
	</CFSAVECONTENT>
	<cfset form.patronlookup = "">
	<cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>


<cfif sessioniscomplete( form.currentsessionid )>
	<CFSAVECONTENT variable="message">
		This session has already been completed. Log out and back in.
	</CFSAVECONTENT>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfif>

<!--- look for payment for this session --->
<cfinclude template="/common/invoicetranxcheckforapproval_freedompay.cfm">
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
				         sessionregconvert.isdeposit and sessionregconvert.ispayingbalance as depositmode
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
				<cfabort>
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

						<cfif GetCurrentRegistrations.costadj gt 0>
							<!--- insert cost adjustment --->

							<cfquery datasource="#application.dopsds#" name="InsertCostAdj">
								insert into dops.adjustments
									(
										ec,
										adjustment,
										adjustmentcode,
										primarypatronid,
										invoicefacid,
										invoicenumber,
										ismiscfee,
										comments
									)
								values
									(
										<cfqueryparam value="#GetCurrentRegistrations.costec#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="#GetCurrentRegistrations.costadj#" cfsqltype="cf_sql_money" list="no">,
										<cfqueryparam value="#GetCurrentRegistrations.adjustmentcode#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">,
										<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,

										<cfif GetCurrentRegistrations.adjustreason neq "">
											<cfqueryparam value="#GetCurrentRegistrations.adjustreason#" cfsqltype="cf_sql_varchar" list="no">
										<cfelse>
											null
										</cfif>
									)
							</cfquery>

						</cfif>

						<cfif GetCurrentRegistrations.miscadj gt 0>
							<!--- insert misc adjustment --->

							<cfquery datasource="#application.dopsds#" name="InsertMiscAdj">
								insert into dops.adjustments
									(
										ec,
										adjustment,
										adjustmentcode,
										primarypatronid,
										invoicefacid,
										invoicenumber,
										ismiscfee,
										comments
									)
								values
									(
										<cfqueryparam value="#GetCurrentRegistrations.miscec#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="#GetCurrentRegistrations.miscadj#" cfsqltype="cf_sql_money" list="no">,
										<cfqueryparam value="#GetCurrentRegistrations.adjustmentcode#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">,
										<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
										<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,

										<cfif GetCurrentRegistrations.adjustreason neq "">
											<cfqueryparam value="#GetCurrentRegistrations.adjustreason#" cfsqltype="cf_sql_varchar" list="no">
										<cfelse>
											null
										</cfif>
									)
							</cfquery>

						</cfif>

						<cfset invoicetranxcallcomments = variables.invoicetranxcallcomments & "Class Conversion: #GetCurrentRegistrations.tfc# (#GetCurrentRegistrations.RegID#) for #GetCurrentRegistrations.patronid#. ">
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

								<cfif GetCurrentRegistrations.converttodeposit>
									deferred = <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
									wasconverted = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">,
									deferredpaid = <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
									feebalance = <cfqueryparam value="#GetCurrentRegistrations.balancedue#" cfsqltype="CF_SQL_MONEY">,
									balancepaid = <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">

								<cfelse>
									wasconverted = <cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
									deferred =

										<cfif not GetCurrentRegistrations.depositmode>
											<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
										<cfelse>
											<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
										</cfif>

									deferredpaid =

										<cfif GetCurrentRegistrations.depositmode or GetCurrentRegistrations.iswl>
											<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
										<cfelse>
											<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
										</cfif>

									<cfif GetCurrentRegistrations.iswl>
										feebalance = <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">,
										balancepaid = <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
									<cfelse>
										feebalance = <cfqueryparam value="#variables.thisclassfee + variables.thisclassmiscfee#" cfsqltype="CF_SQL_MONEY">,
										balancepaid = <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
									</cfif>

									depositonly = <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">

								</cfif>

								where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
								and    regid = <cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="CF_SQL_INTEGER">
								;

								<!---update dops.reghistory
								set
									pending =

										<cfif GetCurrentRegistrations.converttodeposit>
											<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
										<cfelse>
											<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
										</cfif>

								where  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
								and    regid = <cfqueryparam value="#GetCurrentRegistrations.RegID#" cfsqltype="CF_SQL_INTEGER">--->
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

									<cfif GetCurrentRegistrations.converttodeposit>
										<cfqueryparam value="#GetCurrentRegistrations.balancedue#" cfsqltype="CF_SQL_MONEY">,
										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT" list="no">, --deferred
										<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">, --deferredpaid
										<cfqueryparam value="true" cfsqltype="CF_SQL_BIT" list="no">, --depositonly
									<cfelse>
										<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">,
										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT" list="no">, --deferred

										<cfif GetCurrentRegistrations.depositmode>
											<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">, --deferredpaid
										<cfelse>
											<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">, --deferredpaid
										</cfif>

										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT" list="no">, --depositonly
									</cfif>

									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, --wasconverted

									<cfif GetCurrentRegistrations.converttodeposit>
										<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, --pending
									<cfelse>
										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --pending
									</cfif>

									<cfif GetCurrentRegistrations.converttodeposit>
										<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --depositbalpaid
									<cfelse>

										<cfif not GetCurrentRegistrations.depositmode>
											<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">, --depositbalpaid
										<cfelse>
											<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">, --depositbalpaid
										</cfif>

									</cfif>

									<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER"> ) --user
								;

								<cfif GetCurrentRegistrations.converttodeposit>
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
											<cfqueryparam value="#GetCurrentRegistrations.depositamount#" cfsqltype="cf_sql_money" list="no">,
											<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
											<cfqueryparam value="#variables.gllineno#" cfsqltype="cf_sql_smallint" list="no">,
											<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
											<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no"> )
									;

								<cfelse>
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

								</cfif>

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
							<!---CALLING invoicetranxupdatetxdist.cfm <br>--->
							<cfinclude template="/common/invoicetranxupdatetxdist.cfm">
						</cfif>
						<!--- end tx stuff --->

						<!--- remove session record --->
						<cfquery datasource="#application.dopsds#" name="RemoveSessionRecord">
							delete from dops.sessionregconvert
							WHERE  primarypatronid = <cfqueryparam value="#GetCurrentRegistrations.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
							and    regid = <cfqueryparam value="#GetCurrentRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">
							and    sessionid = <cfqueryparam value="#GetCurrentRegistrations.sessionid#" cfsqltype="cf_sql_varchar" list="no">
						</cfquery>

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

								<CFPARAM name="form.primarypatronid" default="#cookie.primarypatronid#">

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
				<CFSAVECONTENT variable="message">
					Final accounting checks resulted in mismatch. Unable to process.<br>
					<CFOUTPUT>#variables.fc#</CFOUTPUT><br>
					<CFIF listfind(application.developerip,cgi.remote_addr) GT 0 or 1>
						<cfinclude template="/common/displayallinvoicetables.cfm">
					</CFIF>
				</CFSAVECONTENT>
				<CFINCLUDE template = "includes/layout.cfm">
				<cfabort>
			</cfif>





			<!--- final test point --->
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
					<cfset customer.callcomment      = variables.invoicetranxcallcomments>

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
					<cfset posturl = "regbaldue5_www.cfm">
					<cfinclude template="/common/invoicetranxcallclose_freedompay.cfm">
					<cftransaction action="commit" />
					<cfinclude template="includes/layout.cfm">
                         <CFABORT>


				<cfelse>
					<!--- finish session --->
					<!--- return 0 = OK, 1 = funds wrong, 2 = cftry failure --->

					<cfset sessionwasfinished = invoicetranxcallfinish( form.currentsessionid, variables.nextinvoice )>
					<!---sessionwasfinished = #sessionwasfinished#--->

					<cfif variables.sessionwasfinished neq 0>
						<!--- open call was created. rollback and stop user form further actions. --->
                              <cftransaction action="rollback" />
                              <CFMAIL to="webadmin@thprd.org" cc="dhayes@thprd.org" bcc="bli@thprd.org" from="webadmin@thprd.org" subject="Possible Session Error - Class Check Out">
                                   This email was sent by checkoutregbp_www.cfm line 861. Approval but session not finished.
                                   <CFDUMP var="#cookie#">
                              </CFMAIL>
                              <CFSAVECONTENT variable="message">
                                   <font color="red"><strong>Session Error</strong></font><br>
               				We encountered a problem during the checkout process. The web team has been notified. We apologize for the inconvenience. For assistance please contact a local center. <a href="http://www.thprd.org/facilities/directory/" target="_blank">Click here for our online directory</a>.
                              </CFSAVECONTENT>
                              <CFSET nobackbutton = true>
                              <CFSET currentstep = 6>
                              <CFSET headertitle="Transaction Not Complete">
                              <CFINCLUDE template = "includes/layout.cfm">

                              <CFABORT>
					</cfif>

				</cfif>
				<!--- end direction decision --->
			</cfif>
		</cfif>
</cftransaction>

<!--- close session to prevent dups --->
<cfquery datasource="#application.dopsds#" name="closesession">
	select dops.webclosehousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no"> )
</cfquery>

<cfset str1 = localfac & "-" & nextinvoice>
<CFSET CurrentInvoiceFac = localfac>
<CFSET CurrentInvoiceNumber = nextinvoice>

<CFSCRIPT>
	//theKey=generateSecretKey(key);
	encrypted=encrypt("#CurrentInvoiceFac#-#CurrentInvoiceNumber#", key, "CFMX_COMPAT", "Hex");
</CFSCRIPT>

<CFSAVECONTENT variable="successmessage">
<CFOUTPUT>
Purchase complete. <a target="_blank" href="/checkout/invoice/printinvoice.cfm?i=#encrypted#"><strong>Click here</strong></a> to view invoice. Your temporary invoice number is <strong>#CurrentInvoiceNumber#</strong>. The invoice will appear in your <strong>Invoice History</strong>.<br>
<div style="height:150px;"><br></div>
</CFOUTPUT>
</CFSAVECONTENT>
<!--- open new session --->
<cfquery datasource="#application.dopsds#" name="newsession">
	select dops.webloadhousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar" list="no"> )
</cfquery>
<CFSET nobackbutton = true>
<CFSET currentstep = 7>
<CFSET headertitle="Finished">
<CFINCLUDE template = "includes/layout.cfm">


