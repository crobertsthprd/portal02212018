<!--- /checkout/invoice/printinvoice.cfm?i=l --->

<CFABORT>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>THPRD Online Registration Summary</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="16" topmargin="25" marginheight="0" <!---onLoad="window.print();"--->>
<cfoutput>
<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset DS = "#application.reg_dsn#">
<!---
<cfset session.classlist = "">
<cfset session.uniqueIDclasslist = "">--->
<!--- remove classes from session --->
<!--- invoicelist format: FFF-NNNNNNNN[,FFF-NNNNNNNN] --->
<!--- where FFF denotes trimmed facility code, NNNNNNNN denotes invoicenumber --->
<!--- any number of invoices can be printed per supplied list --->
<cfif not IsDefined("invoicelist")>
	<strong>No invoices were defined</strong>
	<cfabort>
</cfif>

<cfset ThisInvoice = ListToArray(invoicelist)>
<cfset InvoiceCount = arraylen(ThisInvoice)>
<cfset PrintDisclaimer = 0>

<cfif InvoiceCount is 0>
	<strong>No invoices were found to process</strong>
	<cfabort>
</cfif>

<cfloop from="1" to="#InvoiceCount#" step="1" index="CurrentInvoice">
	<cfset CurrentInvoiceFac = ucase(left(ThisInvoice[CurrentInvoice],Find("-",ThisInvoice[CurrentInvoice])-1))>
	<cfset CurrentInvoiceNumber = mid(ThisInvoice[CurrentInvoice],Find("-",ThisInvoice[CurrentInvoice])+1,99)>
	<cfset TotalFees = 0>
	<cfset TotalDefered = 0>

	<cfquery datasource="#DS#" name="GetInvoiceData">
		SELECT   INVOICE.indistrict, INVOICE.totalfees, invoice.primarypatronlookup, invoice.primarypatronid,
		         INVOICE.startingbalance, INVOICE.usedcredit, 
		         INVOICE.newcredit, INVOICE.tenderedcash, 
		         INVOICE.tenderedcheck, INVOICE.tenderedcc, 
		         INVOICE.tenderedchange, INVOICE.cced, INVOICE.cew, INVOICE.ccreturn,
		         INVOICE.node, INVOICE.dt, INVOICE.comments, INVOICE.othercreditused, INVOICE.othercreditusedcardid,
		         PATRONS.patronlookup, PATRONS.lastname, PATRONS.firstname, 
		         PATRONS.middlename, PATRONS.renter, PATRONS.insufficientid, 
		         INVOICE.printable, 
		         FACILITIES.name AS facname, FACILITIES.addr1 AS facaddr, 
		         FACILITIES.city AS faccity, FACILITIES.state AS facstate, 
		         FACILITIES.zip AS faczip, FACILITIES.phone AS facphone,
					invoice.expassmtwarn, invoice.primarypatronid as p_patronid,
					invoice.addressid, misctendtype,
		         invoice.lastname as invlastname, invoice.firstname as invfirstname,
		         invoice.contact as invcontact, invoice.isvoided,
		         invoice.applyprocessfee, invoice.invoiceType,
		         invoice.FAAPPID
		FROM     invoice 
		         LEFT OUTER JOIN patrons PATRONS ON INVOICE.primarypatronid=PATRONS.patronid
		         INNER JOIN facilities FACILITIES ON INVOICE.invoicefacid=FACILITIES.facid
		where    invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
		and      invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
	</cfquery>

	<cfif GetInvoiceData.recordcount is not 0>
	
	<cfquery datasource="#application.dopsds#" name="GetOtherCreditCredits">
			SELECT   othercreditdatahistory.action, othercreditdatahistory.credit, 
			         othercreditdatahistory.comments, 
			         othercreditdata.othercreditdata,
			         othercreditdatahistory.crinvoicefacid, 
			         othercreditdatahistory.crinvoicenumber,
			         othercredittypes.othercreditdesc 
			FROM     othercreditdatahistory othercreditdatahistory
			         INNER JOIN othercreditactivities othercreditactivities ON othercreditdatahistory.action=othercreditactivities.activitycode
			         INNER JOIN othercreditdata othercreditdata ON othercreditdatahistory.cardid=othercreditdata.cardid 
			         INNER JOIN othercredittypes on othercreditdata.othercredittype=othercredittypes.othercredittype
			WHERE    othercreditdatahistory.valid = true 
			AND      othercreditdatahistory.credit > 0 
			AND      othercreditdatahistory.action = 'B'
			AND      invoicefacid = '#CurrentInvoiceFac#'
			and      invoicenumber = #CurrentInvoiceNumber#
		</cfquery>

		<cfquery datasource="#application.dopsds#" name="GetOtherCreditActivity">
			SELECT   othercreditdatahistory.cardid, othercreditdata.othercreditdata,
			         othercredittypes.othercreditdesc,
			         othercreditactivities.description, 
			         othercreditdatahistory.debit,
			         othercreditdatahistory.credit
			FROM     othercreditdatahistory 
			         INNER JOIN othercreditdata on othercreditdatahistory.cardid=othercreditdata.cardid
			         INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype
			         INNER JOIN othercreditactivities othercreditactivities ON othercreditdatahistory.action=othercreditactivities.activitycode 
			WHERE    othercreditdatahistory.invoicefacid = '#CurrentInvoiceFac#'
			AND      othercreditdatahistory.invoicenumber = #CurrentInvoiceNumber#
		</cfquery>
	
		<!--- RegInv denotes a regular invoice or not: 1=normal, 0 = generic only --->
		<cfif GetInvoiceData.p_patronid is "" or GetInvoiceData.misctendtype is not "" or GetInvoiceData.InvoiceType EQ '-IC-' or GetInvoiceData.InvoiceType EQ '-REF-' or GetInvoiceData.InvoiceType EQ '-AD-'>
			<cfset Reginv = 0>
		<cfelse>
			<cfset RegInv = 1>
		</cfif>

		<cfif RegInv is 1 or GetInvoiceData.InvoiceType EQ '-IC-' or GetInvoiceData.InvoiceType EQ '-REF-' or GetInvoiceData.InvoiceType EQ '-AD-'>

			<cfquery datasource="#DS#" name="GetAddressData">
				select PATRONADDRESSES.address1, PATRONADDRESSES.address2, 
				       PATRONADDRESSES.city, PATRONADDRESSES.state, 
				       PATRONADDRESSES.zip,
				       PATRONADDRESSES.comment
				from   patronaddresses
				where  addressid = <cfif GetInvoiceData.addressid is "">0<cfelse>#GetInvoiceData.addressid#</cfif>
			</cfquery>

		</cfif>

		<table width="650" border=0 cellpadding="1" cellspacing="0" >
			<!--- ------------- --->
			<!--- invoice header--->
			<!--- ------------- --->
			<thead>
				<TR valign="top">
					<TD>
						<table width="100%">
							<TR align="center" valign="middle">
								<TD width="1px" rowspan="2"><img src="../photos/thprdlogo.gif" alt="Logo"></TD>
								<TD class="pghdr" colspan="2">Tualatin Hills Park & Recreation District<BR>Transaction Receipt</TD>
							</TR>
							<TR>
								<TD align="right"></TD>
								<TD align="right"><cfif GetInvoiceData.isvoided is 1><strong>VOIDED </strong></cfif>Invoice: #CurrentInvoiceFac#-#CurrentInvoiceNumber#&nbsp;&nbsp;
									#DateFormat(GetInvoiceData.dt,"mm/dd/yyyy")# #TimeFormat(GetInvoiceData.dt,"hh:mmtt")#&nbsp;&nbsp;
									<cfif GetInvoiceData.indistrict is 1>(In Dist)<cfelse>(Out Dist)</cfif><cfif GetInvoiceData.primarypatronlookup is not "">&nbsp;ID:#GetInvoiceData.primarypatronlookup#</cfif>
									<cfif GetInvoiceData.cew is not ""><BR>Card: <cfif IsDefined("SCD")><cfelse>XXXX XXXX XXXX #GetInvoiceData.cew#</cfif>&nbsp;#left(GetInvoiceData.cced,2)#/#right(GetInvoiceData.cced,2)#</cfif>
								</TD>
							</TR>
						</table>
					</TD>
				</TR>
			</thead>
			<tbody>
				<!--- --------------------- --->
				<!--- invoice address lines --->
				<!--- --------------------- --->
				<TR>
					<TD>
						<table width="100%">
							<TR><TD colspan="5" height="1"></TD></TR><!--- spacer row - adjust to match envelope window --->
							<TR valign="top">
								<TD width="30"></TD><!--- spacer column - adjust to match envelope window --->
								<TD width="320" style="font-size: 9pt;">
									<!--- patron data --->
									<cfif RegInv is 1 or GetInvoiceData.InvoiceType EQ '-IC-' or GetInvoiceData.InvoiceType EQ '-REF-' or GetInvoiceData.InvoiceType EQ '-AD-'>
										#GetInvoiceData.FirstName# #GetInvoiceData.Lastname#<br>
										#GetAddressData.Address1#<br>
										<cfif GetAddressData.Address2 is not "">#GetAddressData.address2#<BR></cfif>
										#GetAddressData.city#, #GetAddressData.state# #GetAddressData.zip#
									</cfif>
									<cfif RegInv is 0 and GetInvoiceData.invlastname is not "">
										#GetInvoiceData.invFirstName# #GetInvoiceData.invLastname#<br>
										#GetInvoiceData.invcontact#
									</cfif>
								</TD>
								<TD style="font-size: 9pt;">
									<!--- facility data --->
									#GetInvoiceData.facname#<br>
									#GetInvoiceData.facaddr#<br>
									#GetInvoiceData.faccity#, #GetInvoiceData.facstate# #GetInvoiceData.faczip#<br>
									(#left(GetInvoiceData.facphone,3)#) #mid(GetInvoiceData.facphone,4,3)#-#mid(GetInvoiceData.facphone,7,4)#
								</TD>
							</TR>
							<TR><TD colspan="5" height="20"></TD></TR><!--- spacer row - adjust to match envelope window --->
						</table>
					</TD>
				</TR>







<!--- all other credit types --->




<cfif Find("-OCP-",GetInvoiceData.invoicetype) gt 0>
	<!--- ---------------------- --->
	<!--- Gift Card New Purchase --->
	<!--- ---------------------- --->
	<cfquery datasource="#application.dopsds#" name="GetOtherCreditRecords">
		SELECT   othercredittypes.othercreditdesc, 
		         othercreditdata.othercreditdata, 
		         othercreditdatahistory.credit, othercreditdata.queuedtoship, 
		         othercreditdata.shipdt,
		         shiplastname, shipfirstname, shipaddress, shipcity, shipstate, shipzip, othercreditdata.maxload
		FROM     othercreditdata othercreditdata
		         INNER JOIN othercreditdatahistory othercreditdatahistory ON othercreditdata.cardid=othercreditdatahistory.cardid
		         INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype 
		WHERE    othercreditdatahistory.action = 'P' 
		AND      othercreditdatahistory.invoicefacid = '#CurrentInvoiceFac#' 
		AND      othercreditdatahistory.invoicenumber =  #CurrentInvoiceNumber#
		AND      othercreditdata.queuedtoship = true 
		ORDER BY othercredittypes.othercreditdesc
	</cfquery>

	<!--- queuedtoship = true denotes was purchased w/ no card being issued at time of purchase --->
	<cfif GetOtherCreditRecords.recordcount gt 0>
		<cfset totalcreditfees = 0>

		<cfquery dbtype="query" name="GetTypes">
			select   distinct othercreditdesc
			from     GetOtherCreditRecords
			order by othercreditdesc
		</cfquery>

		<TR>
			<TD align="left">
				<table width="100%">

					<cfif GetOtherCreditRecords.othercreditdesc[1] is "Voucher">
						<TR>
							<TD class="ReportBold" colspan="2">#GetOtherCreditRecords.othercreditdesc# Issuance Activity</TD>
						</TR>

						<cf_cryp type="de" string="#GetOtherCreditRecords.othercreditdata#" key="#key#">
						<cfset deOtherCreditData = cryp.value>

						<TR>
							<TD><strong>XXXX XXXX XXXX #right(deOtherCreditData,4)#</strong></TD>
						</TR>
						<TR>
							<TD>Balance is calculated at checkout time up to accumulated benefit of <strong>#numberformat(GetOtherCreditRecords.maxload , "999,999.99")#</strong></TD>
						</TR>

						<cfset suppresssummary = 1>
					<cfelse>

						<cfloop query="GetTypes">
							<TR>
								<TD class="ReportBold" colspan="3">#othercreditdesc# Purchase Activity</TD>
							</TR>
							<TR class="ReportBold" align="center">
								<TD>Card Data</TD>
								<TD>Shipping Date</TD>
								<TD align="right">Load</TD>
							</TR>

							<cfloop query="GetOtherCreditRecords">

								<cfif othercreditdata is not "">
									<cf_cryp type="de" string="#othercreditdata#" key="#key#">
									<cfset deOtherCreditData = cryp.value>
								<cfelse>
									<cfset deOtherCreditData = "">
								</cfif>

								<cfif othercreditdesc is GetTypes.othercreditdesc[GetTypes.currentrow]>
									<TR align="center">
										<TD><strong><cfif deOtherCreditData is "">Pending<cfset cardpending = 1><cfelse>XXXX XXXX XXXX #right(deOtherCreditData,4)#</cfif></strong></TD>
										<TD><cfif queuedtoship is 1 and shipdt is "">Pending<cfset cardpending = 1><cfelse>#dateformat(shipdt,"mm/dd/yyyy")#</cfif></TD>
										<TD align="right" style="width: 3cm;">#numberformat(credit,"99,999.99")#</TD>
									</TR>
									<cfset totalcreditfees = totalcreditfees + credit>

									<cfif shiplastname is not "">
										<TR>
											<TD align="center">
												Recipient: #shipfirstname# #shiplastname#, #shipaddress#, #shipcity#, #shipstate# #shipzip#
											</TD>
										</TR>
									</cfif>

								</cfif>

							</cfloop>

						</cfloop>

						<TR align="center">
							<TD><cfif IsDefined("cardpending")>Pendings will be replaced with actual data once fulfillment is complete</cfif></TD>
							<TD class="ReportBold" align="right">Total</TD>
							<TD class="ReportBold" align="right" style="border-top: 1px solid Black; width: 2cm;"><strong>#numberformat(totalcreditfees,"99,999.99")#</strong></TD>
						</TR>
					</cfif>

				</table>
			</TD>
		</TR>
		<cfset TotalFees = TotalFees + totalcreditfees>
	</cfif>

</cfif>








<cfif Find("-OCM-",GetInvoiceData.invoicetype) gt 0>

	<cfquery name="GetOCRecords" datasource="#application.dopsds#">
		SELECT   othercreditdata.othercreditdata, 
		         othercreditdatahistory.action, 
		         othercreditdatahistory.credit, othercreditdatahistory.debit,
		         othercreditdatahistory.userid 
		FROM     othercreditdatahistory othercreditdatahistory
		         INNER JOIN othercreditdata othercreditdata ON othercreditdatahistory.cardid=othercreditdata.cardid 
		WHERE    othercreditdatahistory.invoicefacid = '#CurrentInvoiceFac#' 
		AND      othercreditdatahistory.invoicenumber = #CurrentInvoiceNumber#
	</cfquery>

	<cfif GetOCRecords.recordcount gt 0>
		<TR>
			<TD>
				<table width="100%">
					<TR>
						<TD class="ReportBold" colspan="3">Gift Card Balance Migration</TD>
					</TR>
					<TR class="ReportBold" align="center">
						<TD>Source Card</TD>
						<TD>Destination Card</TD>
						<TD>Balance Migrated</TD>
					</TR>

					<TR align="center">
						<TD>

						<cfloop query="GetOCRecords">

							<cfif action is "MS">
								<cf_cryp type="de" string="#othercreditdata#" key="#key#">
								<cfset deothercreditdata = cryp.value>
								<strong>XXXX XXXX XXXX #right(deothercreditdata,4)#</strong>
							</cfif>

						</cfloop>


						</TD>
						<TD>

						<cfloop query="GetOCRecords">

							<cfif action is "MD">
								<cf_cryp type="de" string="#othercreditdata#" key="#key#">
								<cfset deothercreditdata = cryp.value>
								<strong>XXXX XXXX XXXX #right(deothercreditdata,4)#</strong>
							</cfif>

						</cfloop>


						</TD>

						<TD>

						<cfloop query="GetOCRecords">

							<cfif action is "MS">
								<strong>#numberformat(credit + debit, "99,999.99")#</strong>
							</cfif>

						</cfloop>


						</TD>

					</TR>

				</table>
			</TD>
		</TR>

	</cfif>

</cfif>









<cfif Find("-OCR-",GetInvoiceData.invoicetype) gt 0>
	<!--- ---------------- --->
	<!--- Gift Card Reload --->
	<!--- ---------------- --->
	<cfquery datasource="#application.dopsds#" name="GetOtherCreditRecords">
		SELECT   othercredittypes.othercreditdesc, othercreditactivities.description, 
		         othercreditdata.othercreditdata, othercreditdatahistory.module,
		         othercreditdatahistory.credit 
		FROM     othercreditdata 
		         INNER JOIN othercreditdatahistory othercreditdatahistory ON othercreditdata.cardid=othercreditdatahistory.cardid
		         INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype 
		         INNER JOIN othercreditactivities othercreditactivities ON othercreditdatahistory.action=othercreditactivities.activitycode 
		WHERE    othercreditdatahistory.invoicefacid = '#CurrentInvoiceFac#'
		AND      othercreditdatahistory.invoicenumber = #CurrentInvoiceNumber#
		AND      othercreditdatahistory.action = 'R'
		ORDER BY othercredittypes.othercreditdesc
	</cfquery>

	<cfif GetOtherCreditRecords.recordcount gt 0>
		<cfset totalcreditfees = 0>

		<cfquery dbtype="query" name="GetTypes">
			select   distinct othercreditdesc
			from     GetOtherCreditRecords
			order by othercreditdesc
		</cfquery>

		<TR>
			<TD>
				<table width="100%">

					<cfloop query="GetTypes">
						<TR>
							<TD class="ReportBold" colspan="3">#othercreditdesc# Reload Activity</TD>
						</TR>
						<TR class="ReportBold" align="center">
							<TD>Card Data</TD>
							<TD>Action</TD>
							<TD align="right" style="width: 3cm;">Load</TD>
						</TR>

						<cfloop query="GetOtherCreditRecords">
							<cf_cryp type="de" string="#othercreditdata#" key="#key#">
							<cfset deothercreditdata = cryp.value>

							<cfif othercreditdesc is GetTypes.othercreditdesc[GetTypes.currentrow]>
								<TR align="center">
									<TD><strong>XXXX XXXX XXXX #right(deothercreditdata,4)#</strong></TD>
									<TD>#description#</TD>
									<TD align="right" style="width: 2cm;">#numberformat(credit,"999,999.99")#</TD>
								</TR>
								<cfset totalcreditfees = totalcreditfees + credit>
							</cfif>

						</cfloop>

					</cfloop>

					<TR class="ReportBold" align="center">
						<TD></TD>
						<TD align="right">Total</TD>
						<TD align="right" style="border-top: 1px solid Black;"><strong>#numberformat(totalcreditfees,"99,999.99")#</strong></TD>
					</TR>
				</table>
			</TD>
		</TR>
		<cfset TotalFees = TotalFees + totalcreditfees>
	</cfif>

</cfif>









<cfif Find("-OCT-",GetInvoiceData.invoicetype) gt 0>
	<!--- ------------------ --->
	<!--- Gift Card Transfer --->
	<!--- ------------------ --->
	<cfquery datasource="#application.dopsds#" name="GetOtherCreditRecords">
		SELECT   othercredittypes.othercreditdesc, 
		         othercreditdata.othercreditdata, 
		         othercreditdatahistory.credit, othercreditdatahistory.debit,
		         othercreditactivities.description, othercreditdata.transfercardid, transfermode,
		         othercreditdata.transferfee
		FROM     othercreditdata othercreditdata
		         INNER JOIN othercreditdatahistory othercreditdatahistory ON othercreditdata.cardid=othercreditdatahistory.cardid
		         INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype 
		         INNER JOIN othercreditactivities on othercreditdatahistory.action=othercreditactivities.activitycode
		WHERE    othercreditdatahistory.action in ('T','L')
		AND      othercreditdatahistory.invoicefacid = '#CurrentInvoiceFac#' 
		AND      othercreditdatahistory.invoicenumber = #CurrentInvoiceNumber#
		ORDER BY othercreditdatahistory.cardid
	</cfquery>

	<cfif GetOtherCreditRecords.recordcount is 2>
		<cfset totalcreditfees = 0>
		<TR>
			<TD>
				<table width="100%">
					<TR>
						<TD class="ReportBold" colspan="3">#GetOtherCreditRecords.othercreditdesc[1]# <cfif GetOtherCreditRecords.transfermode[1] is "R">Replacement<cfelse>Transfer</cfif> Activity</TD>
					</TR>
					<TR class="ReportBold" align="center">
						<TD>Original Card</TD>
						<TD>Original Balance</TD>
						<TD><cfif GetOtherCreditRecords.transfermode is "R">New Card<cfelse>Transfered To Card</cfif></TD>

						<cfif GetOtherCreditRecords.transfermode is "R">
							<TD>Transfer Fee</TD>
						</cfif>

						<TD>Transfered Amount</TD>
					</TR>

					<cfif GetOtherCreditRecords.othercreditdata is not "">
						<cf_cryp type="de" string="#GetOtherCreditRecords.othercreditdata[1]#" key="#key#">
						<cfset originalOtherCreditData = cryp.value>
					<cfelse>
						<cfset originalOtherCreditData = "">
					</cfif>

					<cfif GetOtherCreditRecords.othercreditdata is not "">
						<cf_cryp type="de" string="#GetOtherCreditRecords.othercreditdata[2]#" key="#key#">
						<cfset newOtherCreditData = cryp.value>
					<cfelse>
						<cfset newOtherCreditData = "">
					</cfif>

					<TR align="center">
						<TD>#mid(originalOtherCreditData,1,4)# #mid(originalOtherCreditData,5,4)# #mid(originalOtherCreditData,9,4)# #mid(originalOtherCreditData,13,4)#</TD>
						<TD style="width: 3cm;">#numberformat(GetOtherCreditRecords.debit[1],"99,999.99")#</TD>
						<TD>XXXX XXXX XXXX #right(newOtherCreditData,4)#</TD>

						<cfif GetOtherCreditRecords.transfermode is "R">
							<TD style="width: 3cm;">#numberformat(GetOtherCreditRecords.transferfee[1],"99,999.99")#</TD>
						</cfif>

						<TD style="width: 3cm;">#numberformat(GetOtherCreditRecords.credit[2],"99,999.99")#</TD>
					</TR>
				</table>
				<BR>
			</TD>
		</TR>
		<TR>
			<TD align="center" colspan="4">Original card has been invalidated and is no longer usable<BR><BR></TD>
		</TR>
		<cfset TotalFees = TotalFees + GetOtherCreditRecords.credit[2]>
	</cfif>

	<cfset suppresssummary = 1>
</cfif>



<cfif Find("-OCK-",GetInvoiceData.invoicetype) gt 0>
	<!--- -------------------- --->
	<!--- Gift Card Revocation --->
	<!--- -------------------- --->
	<cfquery datasource="#application.dopsds#" name="GetFAAppData">
		SELECT   fahistory.faappid, fahistory.cardidloaded, faapps.returned, fahistory.comments  
		FROM     fahistory fahistory
		         INNER JOIN faapps faapps ON fahistory.faappid=faapps.faappid 
		WHERE    fahistory.invoicefacid = '#CurrentInvoiceFac#'
		AND      fahistory.invoicenumber = #CurrentInvoiceNumber#
		limit    1
	</cfquery>

	<cfif GetFAAppData.recordcount is 1>

		<cfquery datasource="#application.dopsds#" name="GetOtherCreditRecords">
			SELECT   othercredittypes.othercreditdesc, othercreditdata.othercreditdata
			FROM     othercreditdata 
			         INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype 
			WHERE    othercreditdata.cardid = #GetFAAppData.cardidloaded#
		</cfquery>

		<cfif GetOtherCreditRecords.recordcount gt 0>
			<cfset totalcreditfees = 0>

			<cfquery dbtype="query" name="GetTypes">
				select   distinct othercreditdesc
				from     GetOtherCreditRecords
				order by othercreditdesc
			</cfquery>

			<TR>
				<TD>
					<table width="100%">

						<cfloop query="GetTypes">
							<TR>
								<TD class="ReportBold" colspan="3">#othercreditdesc# Revocation</TD>
							</TR>
							<TR class="ReportBold" align="center">
								<TD>Application ##</TD>
								<TD>Card Data</TD>
								<TD align="right" style="width: 3cm;">Returned</TD>
							</TR>

							<cfloop query="GetOtherCreditRecords">
								<cf_cryp type="de" string="#othercreditdata#" key="#key#">
								<cfset deothercreditdata = cryp.value>

								<cfif othercreditdesc is GetTypes.othercreditdesc[GetTypes.currentrow]>
									<TR align="center">
										<TD>#GetInvoiceData.faappid#</TD>
										<TD><strong>XXXX XXXX XXXX #right(deothercreditdata,4)#</strong></TD>
										<TD align="right" style="width: 2cm;">#numberformat(GetFAAppData.returned,"999,999.99")#</TD>
									</TR>
									<TR>
										<TD colspan="3">Comments: #GetFAAppData.comments#</TD>
									</TR>
								</cfif>

							</cfloop>

						</cfloop>

					</table>
				</TD>
			</TR>

		</cfif>

	</cfif>

</cfif>







<!--- end all other credit types --->





				
				<cfif RegInv is 1>
			<!--- league reg --->	
<cfif GetInvoiceData.invoicetype is "-LEAG-">

	<cfquery datasource="#application.dopsdsro#" name="GetLeagueData">
		SELECT   lastname, 
		         firstname, 
		         middlename, 
		         sizedescription, 
		         e_school, 
		         m_school, 
		         h_school, 
		         leaguedesc, 
		         fee,
		         comments,
		         preferredcoach
		FROM     content.th_league_enrollments_view
		where    invoicefacid = <cfqueryparam value="#CurrentInvoiceFac#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#CurrentInvoiceNumber#" cfsqltype="CF_SQL_INTEGER">
	</cfquery>

	<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
	<TR><TD>
	<table width="100%">
		<TR>
			<TD class="ReportBold" colspan="4">League Enrollment<BR><BR></TD>
		</TR>
		<TR>
			<TD><strong>Patron</strong></TD>
			<TD><strong>Shirt</strong></TD>
			<TD><strong>School Path</strong></TD>
			<TD><strong>Type</strong></TD>
			<TD align="right"><strong>Fee</strong></TD>
		</TR>

		<cfset totalfees = 0>

		<cfloop query="GetLeagueData">
			<TR>
				<TD>#lastname#, #firstname# #middlename#</TD>

				<cfset pathing = "">

				<cfif e_school is not "">
					<cfset pathing = e_school & " -> " & m_school & " -> " & h_school>
				<cfelseif m_school is not "">
					<cfset pathing = m_school & " -> " & h_school>
				<cfelse>
					<cfset pathing = h_school>
				</cfif>

				<TD>#sizedescription#</TD>
				<TD>#pathing#</TD>
				<TD>#leaguedesc#</TD>
				<TD align="right">#numberformat(fee, "99,999.99")#</TD>
			</TR>

			<cfset totalfees = totalfees + fee>
			
        	<cfif preferredcoach is not "">
         	<TR>
          		<TD colspan="5" style="font-style: italic;">Preferred Coach: #preferredcoach#</TD>
       	  	</TR>
        	</cfif>
 
        	<cfif comments is not "">
        	<TR>
          		<TD colspan="5" style="font-style: italic;">Comments: #comments#</TD>
         	</TR>
        	</cfif>			
			
		</cfloop>

		<TR align="right">
			<TD colspan="4"><strong>Total Fees</strong></TD>
			<TD style="border-top-color: Black; border-top-style: solid; border-top-width: 1px; border-bottom-color: Black; border-bottom-style: double;"><strong>#numberformat(totalfees, "99,999.99")#</strong></TD>
		</TR>
		<TR>
			<TD>&nbsp;</TD>
		</TR>
		<tr>
			<td colspan="5"><b>Reminder</b><br>The <A href="javascript:;" onClick="javascript:void(window.open('http://www.thprd.org/pdfs/document70.pdf','','menubar=1,toolbar=1,status=1,scrollbars=1,resizable=1'))">Emergency/Medical Consent form</a> needs to be received by the Athletic Center for your registration to be complete.  Forms can be mailed or dropped off at the Athletic Center, 15707 SW Walker Rd., Beaverton OR 97006.<br>
<!---<br>
<strong>5th Grade Placement</strong><br>
Individuals will be placed on teams and will be notified by a coach or THPRD Staff by November 25th.<br>
<br>
<b>Middle School Placement</b><br>
Individuals interested in being placed on a competitive team will need to attend a player evaluation. Evaluation locations and times will be available on the <a href="http://www.thprd.org/" target="_blank">THPRD web site</a> after October 9th. Parent will need to bring registration receipt to the Athletic Center prior to the evaluation date to receive an evaluation number. Individuals already committed to a team or wanting to be placed on a recreation team do not need to attend an evaluation. Individuals that do not attend an evaluation will be placed on a recreation team.<br><br>

<strong>Metro Jr General Placement</strong><br>

Individuals interested in being placed on a competitive team will need to attend a
player evaluation. Evaluation locations and times will be available on
this web site after October 9th. Parent will need to bring registration receipt to
the Athletic Center prior to the evaluation date to receive an evaluation number.<br>
<br>

Individuals need to attend at least one tryout for their grade, sex and school,
however, every effort should be made to attend all scheduled tryouts.
Individuals selected on a Metro Jr team will be contacted by their coach after the last day
of tryouts.<br>
<br>

<strong>Individuals that do not make a Metro Jr team will need to call the Athletic
Center to request a refund for the Metro Jr program then register online for
the Middle School program. <u>Individuals will not be automatically placed on
a Middle school team.</u></strong> Middle School program registration will be accepted
through November 6. Middle School player evaluations for competitive teams
will be held the week of November 1st.<br><br>--->
			</td>
		</tr>
	</table>
	</TD></TR>

	</cfif>				
				
					<!--- ----------- --->
					<!--- THPRD Cards --->
					<!--- ----------- --->
					<cfset TotalCardFees = 0>
	
					<cfquery datasource="#DS#" name="GetCards">
						SELECT   PATRONS.lastname, PATRONS.firstname, CARDHISTORY.printcard, 
						         CARDHISTORY.photomark, CARDHISTORY.amount 
						FROM     cardhistory CARDHISTORY
						         INNER JOIN patrons PATRONS ON CARDHISTORY.patronid=PATRONS.patronid 
						WHERE    CARDHISTORY.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						AND      CARDHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
					</cfquery>
	
					<cfif GetCards.recordcount is not 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD colspan="8" class="bodytext_bold">THPRD Cards</TD>
									</TR>
									<TR class="bodytext_bold">
										<TD>Patron</TD>
										<TD>To Print</TD>
										<TD>Had Photo</TD>
										<TD align="right">Cost</TD>
									</TR>
	
									<cfset TotalCardFees = 0>
	
									<cfloop query="GetCards">
										<cfset TotalFees = TotalFees + amount>
										<cfset TotalCardFees = TotalCardFees + amount>
										<TR valign="top">
											<TD>#Lastname#, #firstname#</TD>
											<TD>#YesNoFormat(printcard)#</TD>
											<TD>#YesNoFormat(photomark)#</TD>
											<TD align="right">#decimalformat(amount)#</TD>
										</TR>
									</cfloop>
									<TR class="bodytext_bold">
										<TD colspan="3" align="right">Total Card Fees:</TD>
										<TD align="right">#DecimalFormat(TotalCardFees)#</TD>
									</TR>
								</table>
							</TD>
						</TR>
					</cfif>
			
					<!--- ------------------- --->
					<!--- Assessment Upgrades --->
					<!--- ------------------- --->
					<cfquery datasource="#DS#" name="GetAssessments">
						SELECT   ASSESSMENTS.operation, ASSESSMENTS.assmttype, 
						         ASSESSMENTS.assmtfee, ASSESSMENTS.assmtexpires, 
						         coalesce(ADJUSTMENTS.adjustment,0) as adjustment, coalesce(ADJUSTMENTS.adjustmentcode,0) as adjustmentcode
						FROM     assessments ASSESSMENTS
						         LEFT OUTER JOIN adjustments ADJUSTMENTS ON ASSESSMENTS.primarypatronid=ADJUSTMENTS.primarypatronid AND ASSESSMENTS.ec=ADJUSTMENTS.ec
						where    ASSESSMENTS.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						and      ASSESSMENTS.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						and      assessments.operation = 'U'
					</cfquery>
			
					<cfif GetAssessments.recordcount is not 0>
						<cfset TotalFees = TotalFees + GetAssessments.assmtfee>
	
						<cfquery datasource="#DS#" name="GetAssessmentMembers">
							SELECT   distinct ASSESSMENTMEMBERS.patronid, PATRONS.lastname, 
							         PATRONS.firstname, PATRONS.middlename
							FROM     assessmentmembers ASSESSMENTMEMBERS
							         INNER JOIN assessments ASSESSMENTS ON ASSESSMENTMEMBERS.primarypatronid=ASSESSMENTS.primarypatronid AND ASSESSMENTMEMBERS.ec=ASSESSMENTS.ec
							         INNER JOIN patrons PATRONS ON ASSESSMENTMEMBERS.patronid=PATRONS.patronid 
							WHERE    ASSESSMENTS.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
							AND      ASSESSMENTS.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						</cfquery>
	
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="bodytext_bold" colspan="8">Assessments</TD>
									</TR>
									<TR class="bodytext_bold">
										<TD>Assessment Type</TD>
										<TD>Members</TD>
										<TD>Expiration</TD>
										<!--- <TD align="right">Cost</TD> --->
										<!--- <TD align="right">Adjust</TD> --->
										<TD align="right">Net Cost</TD>
									</TR>
									<TR valign="top">
										<TD><cfif GetAssessments.assmttype is "F">Family<cfelse>Single</cfif>&nbsp;&nbsp;(<cfif GetAssessments.operation is "N">New<cfelse>Upgrade</cfif>)</TD>
										<TD>
											<cfloop query="GetAssessmentMembers">
												#GetAssessmentMembers.lastname#, #GetAssessmentMembers.firstname#<BR>
											</cfloop>
										</TD>
										<TD>#DateFormat(GetAssessments.assmtexpires,"mm/dd/yy")#</TD>
										<!--- <TD align="right">#decimalformat(GetAssessments.assmtfee+GetAssessments.adjustment)#</TD> --->
										<!--- <TD align="right">#decimalformat(GetAssessments.adjustment)#</TD> --->
										<TD align="right">#decimalformat(GetAssessments.assmtfee)#</TD>
									</TR>
	
									<cfif GetAssessments.adjustmentcode is not 0>
	
										<cfquery datasource="#DS#" name="GetAdjustmentDesc">
											SELECT   adjustmentdescription 
											FROM     adjustmentdescriptions
											WHERE    adjustmentcode = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetAssessments.adjustmentcode#" />
										</cfquery>
	
										<TR valign="top">
											<TD colspan="5" align="right">Reflects an adjustment of #DecimalFormat(GetAssessments.adjustment)# for #GetAdjustmentDesc.adjustmentdescription#</TD>
											<TD></TD>
										</TR>
									</cfif>
	
								</table>
							</TD>
						</TR>
	
					</cfif>

					<!--- --------------- --->
					<!--- New Assessments --->
					<!--- --------------- --->
					<cfquery datasource="#DS#" name="GetAssessments">
						SELECT   ALLASSESSMENTS.*,
						         coalesce(ADJUSTMENTS.adjustment,0) AS adjustment, 
						         coalesce(ADJUSTMENTS.adjustmentcode,0) AS adjustmentcode, ALLASSESSMENTS.EC
						FROM     ALLASSESSMENTS ALLASSESSMENTS
						         LEFT OUTER JOIN ADJUSTMENTS ADJUSTMENTS ON ALLASSESSMENTS.INVOICEFACID=ADJUSTMENTS.INVOICEFACID AND ALLASSESSMENTS.INVOICENUMBER=ADJUSTMENTS.INVOICENUMBER AND ALLASSESSMENTS.EC=ADJUSTMENTS.EC
						WHERE    ALLASSESSMENTS.INVOICEFACID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" /> 
						AND      ALLASSESSMENTS.INVOICENUMBER = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						AND      ALLASSESSMENTS.OPERATION = 'N'
						ORDER BY ALLASSESSMENTS.ASSMTEFFECTIVE
					</cfquery>
			
					<cfif GetAssessments.recordcount is not 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="bodytext_bold" colspan="8">Assessments</TD>
									</TR>
									<TR class="bodytext_bold">
										<TD>Assessment Type</TD>
										<TD>Members</TD>
										<TD>Effective</TD>
										<TD>Expiration</TD>
										<TD align="right">Net Cost</TD>
									</TR>

								<cfloop query="GetAssessments">
		
									<cfif GetAssessments.assmtplan is 1>
		
										<cfquery datasource="#DS#" name="GetAssessmentMembers">
											SELECT   distinct ASSESSMENTMEMBERS.patronid, PATRONS.lastname, 
											         PATRONS.firstname, PATRONS.middlename
											FROM     assessmentmembers ASSESSMENTMEMBERS
											         INNER JOIN assessments ASSESSMENTS ON ASSESSMENTMEMBERS.primarypatronid=ASSESSMENTS.primarypatronid AND ASSESSMENTMEMBERS.ec=ASSESSMENTS.ec
											         INNER JOIN patrons PATRONS ON ASSESSMENTMEMBERS.patronid=PATRONS.patronid 
											WHERE    ASSESSMENTS.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
											AND      ASSESSMENTS.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
											AND      ASSESSMENTS.EC = #EC#
										</cfquery>
				
									</cfif>
		
									<cfif GetAssessments.assmtplan is 1 or (GetAssessments.assmtplan is 2 and patronid is primarypatronid)>
										<cfset TotalFees = TotalFees + GetAssessments.assmtfee>
										<TR valign="top">
											<TD>
												<cfif GetAssessments.assmtplan is 1>
													<cfif GetAssessments.assmttype is "F">
														Family,
													<cfelse>
														Single,
													</cfif>
													Plan #GetAssessments.assmtplan#&nbsp;&nbsp;(<cfif GetAssessments.operation is "N">New<cfelse>Upgrade</cfif>)
												<cfelse>
													#assmtname# (Plan #GetAssessments.assmtplan#)
												</cfif>
											</TD>
											<TD>
												<cfif GetAssessments.assmtplan is 1>

													<cfloop query="GetAssessmentMembers">
														#GetAssessmentMembers.lastname#, #GetAssessmentMembers.firstname#<BR>
													</cfloop>

												<cfelse>
													All Household Members
												</cfif>
											</TD>
											<TD>#DateFormat(GetAssessments.assmteffective,"mm/dd/yy")#</TD>
											<TD>#DateFormat(GetAssessments.assmtexpires,"mm/dd/yy")#</TD>
											<TD align="right">#decimalformat(GetAssessments.assmtfee)#</TD>
										</TR>
		
										<cfif GetAssessments.adjustmentcode is not 0>
		
											<cfquery datasource="#DS#" name="GetAdjustmentDesc">
												SELECT   adjustmentdescription 
												FROM     adjustmentdescriptions
												WHERE    adjustmentcode = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetAssessments.adjustmentcode#" />
											</cfquery>
		
											<TR valign="top">
												<TD colspan="5" align="right">Reflects an adjustment of #DecimalFormat(GetAssessments.adjustment)# for #GetAdjustmentDesc.adjustmentdescription#</TD>
												<TD></TD>
											</TR>
										</cfif>
									</cfif>
								</cfloop>
							</table>
						</TD>
					</TR>
					</cfif>
	
					<!--- ------------------ --->
					<!--- Assessment Credits --->
					<!--- ------------------ --->
					<cfquery datasource="#DS#" name="GetAsstCredits">
						SELECT   credit, activity 
						FROM     ACTIVITY 
						WHERE    INVOICEFACID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						AND      INVOICENUMBER = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						AND      ACTIVITYCODE = <cfqueryparam cfsqltype="cf_sql_varchar" value="ASCR" />
					</cfquery>

					<cfif GetAsstCredits.recordcount gt 0>
						<TR>
							<TD>
								<table width="100%">
									<TR valign="top">
										<TD class="bodytext_bold">Assessment Cancelation/Credit</TD>
										<TD>#replace(replace(GetAsstCredits.activity," F,"," Family,","all")," S,"," Single,","all")#</TD>
										<TD align="right"><strong>#numberformat(GetAsstCredits.credit,"99.99")#</strong><BR><BR></TD>
									</TR>
								</table>
							</TD>
						</TR>
						<cfset AsstCredits = GetAsstCredits.credit>
					</cfif>

					<!--- ------ --->
					<!--- Passes --->
					<!--- ------ --->
					<cfquery datasource="#DS#" name="GetPasses">
						SELECT   PASSES.ec, PASSES.primarypatronid, passes.passterm,
						         PASSSPAN.passspandescription, PASSTYPE.passdescription, 
						         PASSES.passexpires, PASSES.upgraded, PASSES.passallocation, 
						         PASSES.passfee, coalesce(ADJUSTMENTS.adjustment,0) as adjustment, 
						         coalesce(ADJUSTMENTS.adjustmentcode,0) as adjustmentcode,
									passes.upgradetype, passes.upgradebasis, passes.modified
						FROM     passes PASSES
						         INNER JOIN passtype PASSTYPE ON PASSES.passtype=PASSTYPE.passtype
						         INNER JOIN passspan PASSSPAN ON PASSES.passspan=PASSSPAN.passspan
						         LEFT OUTER JOIN adjustments ADJUSTMENTS ON PASSES.ec=ADJUSTMENTS.ec AND PASSES.primarypatronid=ADJUSTMENTS.primarypatronid
						WHERE    PASSES.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						AND      PASSES.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						AND      passes.modified is null
					</cfquery>
			
					<cfif GetPasses.recordcount is not 0>
						<cfset PassFees = 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="bodytext_bold" colspan="8">Passes</TD>
									</TR>
									<TR class="bodytext_bold">
										<TD>Pass Type</TD>
										<TD>Pass Term</TD>
										<TD>Members</TD>
										<TD>Expiration</TD>
										<TD align="right">Basis</TD>
										<TD align="right">Credit</TD>
										<TD align="right">Cost</TD>
										<TD align="right">Adjust</TD>
										<TD align="right">Net Cost</TD>
									</TR>
									<cfloop query="GetPasses">
										<cfset TotalFees = TotalFees + GetPasses.passfee>
										<cfset PassFees = PassFees + GetPasses.passfee>
	
										<cfquery datasource="#DS#" name="GetPassMembers">
											SELECT   PATRONS.lastname, PATRONS.firstname, PATRONS.middlename, passmembers.dtadded
											FROM     passmembers PASSMEMBERS
											         INNER JOIN patrons PATRONS ON PASSMEMBERS.patronid=PATRONS.patronid 
											WHERE    PASSMEMBERS.primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetPasses.primarypatronid#" />
											AND      PASSMEMBERS.ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetPasses.ec#" />
											AND      PASSMEMBERS.DTAdded = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#dateformat(GetInvoiceData.DT,"yyyy-mm-dd")# #timeformat(GetInvoiceData.DT,"HH:MM:SS")#" />
										</cfquery>
		
										<TR valign="top">
											<TD>#GetPasses.passdescription#
												<cfif GetPasses.modified is not "">
													<BR>
													<cfquery datasource="#DS#" name="GetModifcation">
														select description
														from modifications
														where code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#modified#" />
													</cfquery>
	
													#GetModifcation.description#
												<cfelseif GetPasses.upgraded is 1>
													<BR>(
													<cfif left(upgradetype,1) is not mid(upgradetype,2,1)>
														<cfif left(upgradetype,1) is "I">Individual</cfif>
														<cfif left(upgradetype,1) is "C">Couple</cfif>-
														<cfif mid(upgradetype,2,1) is "C">Couple</cfif>
														<cfif mid(upgradetype,2,1) is "F">Family</cfif>
													</cfif>
													<cfif mid(upgradetype,3,2) is not mid(upgradetype,5,2)>
														#val(mid(upgradetype,3,2))#-#val(mid(upgradetype,5,2))# month
													</cfif>
													Upgrade )
												<cfelse>
													( New )
												</cfif>
											</TD>
											<TD>#Passterm# months</TD>
											<TD>
												<cfloop query="GetPassMembers">
													#lastname#, #firstname#<!--- <cfif postinvoiceadded is 1> *<cfset postinvoiceadded1 = 1></cfif> ---><BR>
												</cfloop>
											</TD>
											<TD>#DateFormat(GetPasses.Passexpires,"mm/dd/yy")#</TD>
											<TD align="right">
												<cfif upgradebasis is not "">
													#decimalformat(upgradebasis)#
												</cfif></TD>
											<TD align="right">
												<cfif upgradebasis is not "">
													#decimalformat(upgradebasis - GetPasses.passfee)#
												</cfif></TD>
											</TD>
											<TD align="right">
												#decimalformat(GetPasses.passfee+GetPasses.adjustment)#
												
											</TD>
											<TD align="right">#decimalformat(GetPasses.adjustment)#</TD>
											<TD align="right">#decimalformat(GetPasses.passfee)#</TD>
										</TR>
										<cfif GetPasses.adjustmentcode is not 0>
		
											<cfquery datasource="#DS#" name="GetAdjustmentDesc">
												SELECT   adjustmentdescription 
												FROM     adjustmentdescriptions
												WHERE    adjustmentcode = #GetPasses.adjustmentcode#
											</cfquery>
		
											<TR valign="top">
												<TD colspan="5" align="right">Reflects an adjustment of #DecimalFormat(GetPasses.adjustment)# for #GetAdjustmentDesc.adjustmentdescription#</TD>
												<TD></TD>
											</TR>
										</cfif>
									</TD>
								</TR>
							</cfloop>
							<TR>
								<td colspan="3"><cfif IsDefined("postinvoiceadded1")>* denotes patron was added at a later time</cfif></td>
								<TD colspan="4" align="right" class="bodytext_bold">Total Pass Fees:</TD>
								<TD align="right" colspan="2" class="bodytext_bold">#DecimalFormat(PassFees)#</TD>
							</TR>
						</table>
					</cfif>
	
					<!--- ----------------- --->
					<!--- Pass modifcations --->
					<!--- ----------------- --->
					<cfquery datasource="#DS#" name="GetVoidedPasses">
						SELECT   PASSES.ec, PASSES.primarypatronid, 
						         PASSSPAN.passspandescription, PASSTYPE.passdescription, 
						         PASSES.passexpires, PASSES.upgraded, PASSES.passallocation, 
						         PASSES.passfee, passes.modified, coalesce(passes.credit,0) as credit
						FROM     passes PASSES
						         INNER JOIN passtype PASSTYPE ON PASSES.passtype=PASSTYPE.passtype
						         INNER JOIN passspan PASSSPAN ON PASSES.passspan=PASSSPAN.passspan
						WHERE    PASSES.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						AND      PASSES.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						AND      passes.modified is not null
					</cfquery>
			
					<cfset TotalPassCredit = 0>
	
					<cfif GetVoidedPasses.recordcount is not 0>
						<cfset TotalPassCredit = GetVoidedPasses.credit>
						<cfset VoidedPassFees = 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="bodytext_bold" colspan="8">Modified Passes</TD>
									</TR>
	
									<TR class="bodytext_bold">
										<TD>Pass Type</TD>
										<TD>Members</TD>
										<TD>Expiration</TD>
										<TD align="right">Net Credit</TD>
									</TR>
	
									<cfloop query="GetVoidedPasses">
										<cfset VoidedPassFees = VoidedPassFees + GetVoidedPasses.passfee>
										<!---
										<cfquery datasource="#DS#" name="GetPassMembers">
											SELECT   PATRONS.lastname, PATRONS.firstname, PATRONS.middlename, passmembers.dtadded
											FROM     passmembers PASSMEMBERS
											         INNER JOIN patrons PATRONS ON PASSMEMBERS.patronid=PATRONS.patronid 
											WHERE    PASSMEMBERS.primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetVoidedPasses.primarypatronid#" />
											AND      PASSMEMBERS.ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetVoidedPasses.ec#" />
											AND      PASSMEMBERS.DTAdded = <cfqueryparam cfsqltype="cf_sql_varchar" value="#dateformat(GetInvoiceData.DT,"yyyy-mm-dd")# #timeformat(GetInvoiceData.DT,"HH:MM:SS")#" />
										</cfquery>
										--->
										<cfquery datasource="#DS#" name="GetPassMembers">
											SELECT   PATRONS.lastname, PATRONS.firstname, PATRONS.middlename, passmembers.dtadded
 											FROM     passmembers PASSMEMBERS
        									INNER JOIN patrons PATRONS ON PASSMEMBERS.patronid=PATRONS.patronid 
 											WHERE    PASSMEMBERS.primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetVoidedPasses.primarypatronid#" />
 											AND      PASSMEMBERS.ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetVoidedPasses.ec#" />
											AND      (PASSMEMBERS.DTAdded, PASSMEMBERS.DTAdded) overlaps (#CreateODBCDateTime(GetInvoiceData.DT)#, interval '1 second')
											
										</cfquery>
										
										
										<TR valign="top">
											<TD>#GetVoidedPasses.passdescription#
												<BR>
												<cfquery datasource="#DS#" name="GetModifcation">
													select description
													from modifications
													where code = <cfqueryparam cfsqltype="cf_sql_varchar" value="#modified#" />
												</cfquery>
	
												#GetModifcation.description#
											</TD>
											<TD>
												<cfloop query="GetPassMembers">
													#lastname#, #firstname#<BR>
												</cfloop>
											</TD>
											<TD>
												<cfif not (modified is "FV" or modified is "PV")>
													#DateFormat(GetVoidedPasses.Passexpires,"mm/dd/yy")#
												<cfelse>
													N/A
												</cfif>
											</TD>
											<TD align="right">
												#numberformat(credit,"99,999.99")#
												<!--- <cfif modified is not "E" and modified is not "T">
													#decimalformat(VoidedPassFees)#
												<cfelse>
													0.00
												</cfif> --->
											</TD>
										</TR>
									</TD>
								</TR>
							</cfloop>
						</table>
					</cfif>
	
					<!--- --------------------- --->
					<!--- Class Credits / Drops --->
					<!--- --------------------- --->
					<cfset TotalClassCredits = 0>
	
					<cfquery name="GetDrops" datasource="#DS#">
						SELECT   PATRONS.patronlookup, PATRONS.lastname, PATRONS.firstname, 
						         PATRONS.middlename, PATRONS.gender, REG.classid, 
						         REG.regstatus, <!--- REG.reglevel,  --->REG.senior, REG.deferred, 
						         REG.deferredpaid, REG.depositonly, REG.balancepaid, 
						         REGHISTORY.action, coalesce(REGHISTORY.amount,0) as amount, TERMS.termname, reghistory.ismiscfee,
						         FACILITIES.name, CLASSES.description, CLASSES.startdt, 
						         CLASSES.enddt, CLASSES.suncount, CLASSES.moncount, 
						         CLASSES.tuecount, CLASSES.wedcount, CLASSES.thucount, 
						         CLASSES.fricount, CLASSES.satcount, FACILITIES.addr1, 
						         FACILITIES.city, FACILITIES.state, FACILITIES.zip, 
						         FACILITIES.phone, REG.facid, REG.termid, reghistory.invoicefacid,
						         REGHISTORY.primarypatronid, REGHISTORY.ec, 
						         CLASSES.classcomments, REG.regid, CLASSES.defer, reg.waswldrop,
						         reg.feebalance, reghistory.balance, facilities.addr1, facilities.city,
						         facilities.state, facilities.zip, facilities.phone, reg.dropreason, reghistory.classcreditid, reg.patronid
						FROM     reg REG
						         INNER JOIN patrons PATRONS ON REG.patronid=PATRONS.patronid
						         INNER JOIN reghistory REGHISTORY ON REG.primarypatronid=REGHISTORY.primarypatronid AND REG.regid=REGHISTORY.regid
						         INNER JOIN terms TERMS ON REG.termid=TERMS.termid AND REG.facid=TERMS.facid
						         INNER JOIN facilities FACILITIES ON REG.facid=FACILITIES.facid
						         INNER JOIN classes CLASSES ON REG.termid=CLASSES.termid AND REG.facid=CLASSES.facid AND REG.classid=CLASSES.classid 
						WHERE    REGHISTORY.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						AND      REGHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						AND      REGHISTORY.action in ('D','C','X','V')
						and      reghistory.IsMiscFee = false
						ORDER BY FACILITIES.name, TERMS.termid, PATRONS.lastname, PATRONS.firstname, REG.classid
					</cfquery>
			
					<cfif GetDrops.recordcount is not 0>
						<cfset PrintDisclaimer = 1>
						<cfset LastPatronID = 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="bodytext_bold" colspan="9">Class Drops / Credits / Cancellations</TD>
									</TR>
									<cfset CurrentFac = "">
	
									<cfloop query="GetDrops">
	
										<cfif action is not "D"><!--- credits and cancellations only --->
	
											<cfquery datasource="#DS#" name="GetCreditReason">
												select reason
												from classcredits
												where invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
												and classcreditid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
												limit 1
											</cfquery>
	
										</cfif>
	
										<cfset TotalClassCredits = TotalClassCredits + getdrops.amount>
	
										<cfif CurrentFac is not facid>
											<TR>
												<TD colspan="9" align="center" class="FacilityLine">#name#, #addr1#, #city#, #state# #zip# (#left(phone,3)#) #mid(phone,4,3)#-#mid(phone,7,4)#</TD>
											</TR>
											<cfset CurrentFac = facid>
										</cfif>
	
										<cfquery datasource="#DS#" name="GetMiscFee">
											SELECT   REGHISTORY.amount, reghistory.ec
											FROM     reghistory REGHISTORY
											WHERE    REGHISTORY.primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetDrops.primarypatronid#" />
											AND      REGHISTORY.regid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetDrops.RegID#" />
											AND      REGHISTORY.action in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="D,C,X">)
											and      reghistory.IsMiscFee = true
										</cfquery>
					
										<cfquery datasource="#DS#" name="GetLocations">
											SELECT   DISTINCT LOCATIONS.locdescription 
											FROM     locationschedule LOCATIONSCHEDULE
											         INNER JOIN locations LOCATIONS ON LOCATIONSCHEDULE.facid=LOCATIONS.facid AND LOCATIONSCHEDULE.locid=LOCATIONS.locid
											WHERE    LOCATIONSCHEDULE.termid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetDrops.termid#" />
											AND      LOCATIONSCHEDULE.facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetDrops.facid#" />
											AND      LOCATIONSCHEDULE.activity = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetDrops.classid#" />
										</cfquery>
					
										<!--- <cfquery datasource="#DS#" name="GetAdjustment">
											SELECT   ADJUSTMENTS.adjustment, 
											         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
											FROM     adjustments ADJUSTMENTS
											         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
											WHERE    ec = #GetDrops.ec#
											AND      primarypatronid = #GetDrops.primarypatronid#
										</cfquery> --->
					
										<cfif PatronID is not LastPatronID>
											<cfset LastPatronID = PatronID>
											<TR valign="top">
												<TD colspan="9" class="bodytext">#GetDrops.lastname#, #GetDrops.firstname#&nbsp;&nbsp;&nbsp;#GetDrops.patronlookup#</TD>
											</TR>
										</cfif>
										<TR valign="top">
											<TD nowrap>
												<cfquery datasource="#DS#" name="GetCodeDesc">
													select statusdescription
													from regstatuscodes
													where statuscode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetDrops.action#" />
												</cfquery>
												<cfif WasWLDrop is 1>WL&nbsp;</cfif>#GetCodeDesc.statusdescription#
											</TD>
											<TD>#GetDrops.classid#</TD>
											<TD>#GetDrops.description#</TD>
											<TD>#ValueList(GetLocations.locdescription)#</TD>
											<TD nowrap>
												<cfif GetDrops.suncount + GetDrops.moncount + GetDrops.tuecount + GetDrops.wedcount + GetDrops.thucount + GetDrops.fricount + GetDrops.satcount is not 0>
													<span class="BlackBox"><cfif GetDrops.suncount is 0>&nbsp;<cfelse>S</cfif></span>
													<span class="BlackBox"><cfif GetDrops.moncount is 0>&nbsp;<cfelse>M</cfif></span>
													<span class="BlackBox"><cfif GetDrops.tuecount is 0>&nbsp;<cfelse>T</cfif></span>
													<span class="BlackBox"><cfif GetDrops.wedcount is 0>&nbsp;<cfelse>W</cfif></span>
													<span class="BlackBox"><cfif GetDrops.thucount is 0>&nbsp;<cfelse>T</cfif></span>
													<span class="BlackBox"><cfif GetDrops.fricount is 0>&nbsp;<cfelse>F</cfif></span>
													<span class="BlackBox"><cfif GetDrops.satcount is 0>&nbsp;<cfelse>S</cfif></span>
												</cfif>
											</TD>
											<TD>#lCase(TimeFormat(GetDrops.startdt,"hh:mmtt"))#-#lCase(TimeFormat(GetDrops.enddt,"hh:mmtt"))#</TD>
											<TD>#DateFormat(GetDrops.startdt,"mm/dd/yy")#-#DateFormat(GetDrops.enddt,"mm/dd/yy")#</TD>
											<TD align="right">
												<cfif GetDrops.startdt is not "" and GetDrops.enddt is not "" and GetDrops.enddt greater than or equal to GetDrops.startdt>
													<!--- calculate weeks: calculated by weeks between start and end dates, ignores missing weeks--->
													
													<cfquery datasource="#DS#" name="_GetDT">
													 select   date(startdt) as t
													 from     locationschedule
													 where    termid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetDrops.termid#" />
													 and      facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetDrops.facid#" />
													 and      activity = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetDrops.classid#" />
													 order by startdt
													</cfquery>
 													<cfset Duration = durationweeks("_GetDT","t",0)>
													

													
													<cfset Duration = DateDiff("ww",#GetDrops.startdt#,#GetDrops.enddt#)>
								
													<cfif DayOfWeek(GetDrops.startdt) less than or equal to DayOfWeek(GetDrops.enddt)>
														<cfset Duration = Duration + 1>
													</cfif>
													#Duration#&nbsp;wk(s)
												</cfif>
											</TD>
											<TD align="right"><cfif waswldrop is 0>#DecimalFormat(GetDrops.amount)#</cfif></TD>
										</TR>
					
										<cfif GetMiscFee.recordcount is not 0>
											<cfset TotalClassCredits = TotalClassCredits + GetMiscFee.amount>
	
											<TR valign="top">
												<TD colspan="8" align="right">Misc Fee</TD>
												<TD align="right">#DecimalFormat(GetMiscFee.amount)#</TD>
											</TR>
					
											<!--- <cfif GetMiscFee.adjustment is not "" and GetMiscFee.adjustment is not 0>
					
												<cfquery datasource="#DS#" name="GetMiscFeeAdjustment">
													SELECT   ADJUSTMENTS.adjustment, 
													         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
													FROM     adjustments ADJUSTMENTS
													         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
													WHERE    ec = #GetMiscFee.ec#
													AND      primarypatronid = #GetDrops.primarypatronid#
												</cfquery>
					
											</cfif> --->
					
										</cfif>
					
										<cfif waswldrop is 0>
											<TR>
												<TD colspan="7" >Reason: <cfif action is "D">#GetDrops.dropreason#<cfelse>#GetCreditReason.reason#</cfif></TD>
											</TR>
										</cfif>
	
									</cfloop>
	
									<TR class="bodytext_bold">
										<TD colspan="7" align="right">Total Class Credits:</TD>
										<TD align="right" colspan="2">#DecimalFormat(TotalClassCredits)#</TD>
									</TR>
	
								</table>
							</td>
						</tr>
					</cfif>
					<!--- end class credits / drops --->
	
					<!--- ----------- --->
					<!--- Conversions --->
					<!--- ----------- --->
					<cfset TotalClassCosts = 0>
	
					<cfquery name="GetConversions" datasource="#DS#">
						SELECT   PATRONS.patronlookup, PATRONS.lastname, PATRONS.firstname, 
						         PATRONS.middlename, PATRONS.gender, REG.classid, reg.costbasis, reg.miscbasis,
						         REG.senior, REGHISTORY.deferred, 
						         REG.deferredpaid, REGHISTORY.depositonly, REGHISTORY.depositbalpaid, 
						         REGHISTORY.action, REGHISTORY.amount, TERMS.termname, 
						         FACILITIES.name, CLASSES.description, CLASSES.startdt, 
						         CLASSES.enddt, CLASSES.suncount, CLASSES.moncount, 
						         CLASSES.tuecount, CLASSES.wedcount, CLASSES.thucount, 
						         CLASSES.fricount, CLASSES.satcount, FACILITIES.addr1, 
						         FACILITIES.city, FACILITIES.state, FACILITIES.zip, 
						         FACILITIES.phone, REG.facid, REG.termid, 
						         REGHISTORY.primarypatronid, REGHISTORY.ec, classes.finalpaymentdue,
						         CLASSES.classcomments, REG.regid, CLASSES.defer,
						         reg.feebalance, reghistory.balance, facilities.addr1, facilities.city,
						         facilities.state, facilities.zip, facilities.phone, reg.patronid, classes.finalpaymentdue
						FROM     reg REG
						         INNER JOIN patrons PATRONS ON REG.patronid=PATRONS.patronid
						         INNER JOIN reghistory REGHISTORY ON REG.primarypatronid=REGHISTORY.primarypatronid AND REG.regid=REGHISTORY.regid
						         INNER JOIN terms TERMS ON REG.termid=TERMS.termid AND REG.facid=TERMS.facid
						         INNER JOIN facilities FACILITIES ON REG.facid=FACILITIES.facid
						         INNER JOIN classes CLASSES ON REG.termid=CLASSES.termid AND REG.facid=CLASSES.facid AND REG.classid=CLASSES.classid 
						WHERE    REGHISTORY.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						AND      REGHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						and      reghistory.IsMiscFee = false
						and      reghistory.wasconverted = true
						ORDER BY FACILITIES.name, TERMS.termid, PATRONS.lastname, PATRONS.firstname, REG.classid
					</cfquery>
			
					<cfif GetConversions.recordcount is not 0>
						<cfset PrintDisclaimer = 1>
						<cfset LastPatronID = 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="bodytext_bold" colspan="10">Registration Conversions</TD>
									</TR>
									<cfset CurrentFac = "">
	
									<cfloop query="GetConversions">
	
										<cfif GetConversions.action is "E">
											<cfset TotalClassCosts = TotalClassCosts + amount>
										</cfif>
	
										<cfif CurrentFac is not facid>
											<TR>
												<TD colspan="9" align="center" class="FacilityLine">#name#, #addr1#, #city#, #state# #zip# (#left(phone,3)#) #mid(phone,4,3)#-#mid(phone,7,4)#</TD>
											</TR>
											<cfset CurrentFac = facid>
										</cfif>
	
										<cfquery datasource="#DS#" name="GetMiscFee">
											SELECT   ADJUSTMENTS.adjustment, ADJUSTMENTS.adjustmentcode, 
											         REGHISTORY.amount, reghistory.ec
											FROM     reghistory REGHISTORY
											         LEFT OUTER JOIN adjustments ADJUSTMENTS ON REGHISTORY.primarypatronid=ADJUSTMENTS.primarypatronid AND REGHISTORY.ec=ADJUSTMENTS.ec
											WHERE    REGHISTORY.primarypatronid = #GetConversions.primarypatronid#
											AND      REGHISTORY.regid = #GetConversions.RegID#
											AND      reghistory.IsMiscFee = true
											AND      REGHISTORY.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
											AND      REGHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
										</cfquery>
					
										<cfquery datasource="#DS#" name="GetLocations">
											SELECT   DISTINCT LOCATIONS.locdescription 
											FROM     locationschedule LOCATIONSCHEDULE
											         INNER JOIN locations LOCATIONS ON LOCATIONSCHEDULE.facid=LOCATIONS.facid AND LOCATIONSCHEDULE.locid=LOCATIONS.locid
											WHERE    LOCATIONSCHEDULE.termid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetConversions.termid#" />
											AND      LOCATIONSCHEDULE.facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetConversions.facid#" />
											AND      LOCATIONSCHEDULE.activity = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetConversions.classid#" />
										</cfquery>
					
										<cfquery datasource="#DS#" name="GetAdjustment">
											SELECT   ADJUSTMENTS.adjustment, 
											         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
											FROM     adjustments ADJUSTMENTS
											         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
											WHERE    ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetConversions.ec#" />
											AND      primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetConversions.primarypatronid#" />
										</cfquery>
	
										<cfquery datasource="#DS#" name="GetConvertionDescription">
											SELECT   ACTIVITYCODES.activitydescription 
											FROM     activity ACTIVITY
											         INNER JOIN activitycodes ACTIVITYCODES ON ACTIVITY.activitycode=ACTIVITYCODES.activitycode
											WHERE    ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetConversions.ec#" />
											AND      primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetConversions.primarypatronid#" />
										</cfquery>
	
										<cfif PatronID is not LastPatronID>
											<cfset LastPatronID = PatronID>
											<TR valign="top">
												<TD colspan="9" class="bodytext">#GetConversions.lastname#, #GetConversions.firstname#&nbsp;&nbsp;&nbsp;#GetConversions.patronlookup#</TD>
											</TR>
										</cfif>
										<TR valign="top">
											<TD>
												<cfquery datasource="#DS#" name="GetOriginalInvoice">
													select invoicefacid, invoicenumber
													from reghistory
													where primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#primarypatronid#" />
													and regid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#regid#" />
													order by dt
													limit 1
												</cfquery>				
		
												<cfquery datasource="#DS#" name="GetCodeDesc">
													select statusdescription
													from regstatuscodes
													where statuscode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetConversions.action#" />
												</cfquery>
												#GetConvertionDescription.activitydescription#<!--- #GetCodeDesc.statusdescription# ---> (#GetOriginalInvoice.invoicefacid#-#GetOriginalInvoice.invoicenumber#)
												<cfif GetConversions.deferred is 1> (deferred)</cfif>
												<cfif GetConversions.depositonly is 1> (dep only)</cfif>
											</TD>
	
											<TD>#GetConversions.classid#</TD>
											<TD>#GetConversions.description#</TD>
											<TD>#ValueList(GetLocations.locdescription)#</TD>
											<TD nowrap>
												<cfif GetConversions.suncount + GetConversions.moncount + GetConversions.tuecount + GetConversions.wedcount + GetConversions.thucount + GetConversions.fricount + GetConversions.satcount is not 0>
													<span class="BlackBox"><cfif GetConversions.suncount is 0>&nbsp;<cfelse>S</cfif></span>
													<span class="BlackBox"><cfif GetConversions.moncount is 0>&nbsp;<cfelse>M</cfif></span>
													<span class="BlackBox"><cfif GetConversions.tuecount is 0>&nbsp;<cfelse>T</cfif></span>
													<span class="BlackBox"><cfif GetConversions.wedcount is 0>&nbsp;<cfelse>W</cfif></span>
													<span class="BlackBox"><cfif GetConversions.thucount is 0>&nbsp;<cfelse>T</cfif></span>
													<span class="BlackBox"><cfif GetConversions.fricount is 0>&nbsp;<cfelse>F</cfif></span>
													<span class="BlackBox"><cfif GetConversions.satcount is 0>&nbsp;<cfelse>S</cfif></span>
												</cfif>
											</TD>
											<TD>#lCase(TimeFormat(GetConversions.startdt,"hh:mmtt"))#-#lCase(TimeFormat(GetConversions.enddt,"hh:mmtt"))#</TD>
											<TD>#DateFormat(GetConversions.startdt,"mm/dd/yy")#-#DateFormat(GetConversions.enddt,"mm/dd/yy")#</TD>
											<TD align="right">
												<cfif GetConversions.startdt is not "" and GetConversions.enddt is not "" and GetConversions.enddt greater than or equal to GetConversions.startdt>
													<!--- calculate weeks: calculated by weeks between start and end dates, ignores missing weeks--->
													
													<cfquery datasource="#DS#" name="_GetDT">
													 select   date(startdt) as t
													 from     locationschedule
													 where    termid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetConversions.termid#" />
													 and      facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetConversions.facid#" />
													 and      activity = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetConversions.classid#" />
													 order by startdt
													</cfquery>
 													<cfset Duration = durationweeks("_GetDT","t",0)>
													

													
													<cfset Duration = DateDiff("ww",#GetConversions.startdt#,#GetConversions.enddt#)>
								
													<cfif DayOfWeek(GetConversions.startdt) less than or equal to DayOfWeek(GetConversions.enddt)>
														<cfset Duration = Duration + 1>
													</cfif>
													#Duration#&nbsp;wk(s)
												</cfif>
											</TD>
											<TD align="right"><!--- Basis: #numberformat(costbasis,"9,999.99")#/#numberformat(miscbasis,"9,999.99")# ---></TD>
											<TD align="right"><cfif action is "E" and deferred is 0>#DecimalFormat(GetConversions.amount)#</cfif></TD>
										</TR>
					
										<cfif action is "E">
											<cfset TotalFees = TotalFees + GetConversions.amount>
										</cfif>
					
										<cfif GetConversions.deferred is 1>
											<TR valign="top">
												<TD colspan="9" align="right">Payment has been deferred. Patron must pay balance of #DecimalFormat(GetConversions.balance)# on or before #DateFormat(GetConversions.defer,"mm/dd/yy")#</TD>
												<TD></TD>
											</TR>
											<cfset TotalDefered = TotalDefered + GetConversions.balance>
										</cfif>
	
										<cfif GetConversions.depositonly is 1>
											<TR valign="top">
												<TD colspan="9" align="right">Only the deposit was paid. Patron must pay balance of #DecimalFormat(GetConversions.balance)# on or before #DateFormat(GetConversions.finalpaymentdue,"mm/dd/yy")#</TD>
												<TD></TD>
											</TR>
										</cfif>
	
										<cfif GetAdjustment.adjustmentdescription is not "">
											<TR valign="top">
												<TD colspan="9" align="right">Reflects a cost adjustment of #DecimalFormat(GetAdjustment.adjustment)# for #GetAdjustment.adjustmentdescription#</TD>
												<TD></TD>
											</TR>
										</cfif>
					
										<cfif GetMiscFee.recordcount is not 0 and GetConversions.depositonly is 0>
	
											<cfif GetMiscFee.amount is not 0>
	
												<cfset TotalClassCosts = TotalClassCosts + GetMiscFee.amount>
		
												<TR valign="top">
													<TD colspan="9" align="right">Misc Fee</TD>
													<TD align="right">#DecimalFormat(GetMiscFee.amount)#</TD>
												</TR>
						
												<cfset TotalFees = TotalFees + GetMiscFee.amount>
												<cfif GetMiscFee.adjustment is not "" and GetMiscFee.adjustment is not 0>
						
													<cfquery datasource="#DS#" name="GetMiscFeeAdjustment">
														SELECT   ADJUSTMENTS.adjustment, 
														         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
														FROM     adjustments ADJUSTMENTS
														         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
														WHERE    ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetMiscFee.ec#" />
														AND      primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetConversions.primarypatronid#" />
													</cfquery>
						
													<TR>
														<TD colspan="9" align="right">Reflects a misc fee adjustment of #DecimalFormat(GetMiscFeeAdjustment.adjustment)# for #GetMiscFeeAdjustment.adjustmentdescription#</TD>
														<TD></TD>
													</TR>
												</cfif>
					
											</cfif>
	
										</cfif>
					
										<cfif GetConversions.classcomments is not "">
											<TR valign="top">
												<TD colspan="10">#GetConversions.classcomments#</TD>
											</TR>
										</cfif>
	
									</cfloop>
									<TR class="bodytext_bold">
										<TD colspan="8" align="right">Total Class Costs:</TD>
										<TD align="right" colspan="2">#DecimalFormat(TotalClassCosts)#</TD>
									</TR>
									<cfif GetInvoiceData.expassmtwarn is 1>
										<TR>
											<TD colspan="10" align="center">
												Please note that one or more classes will start after the current assessment has expired. The patron will be required to purchase an assessment before starting the class(es).
											</TD>
										</TR>
									</cfif>
								</table>
							</td>
						</tr>
					</cfif>
					<!--- end conversions --->
	
					<!--- ----------------- --->
					<!--- New Registrations --->
					<!--- ----------------- --->
					<cfset TotalClassCosts = 0>
	
					<cfquery name="GetRegistrations" datasource="#DS#">
						SELECT   PATRONS.patronlookup, PATRONS.lastname, PATRONS.firstname, 
						         PATRONS.middlename, PATRONS.gender, REG.classid, 
						         REG.senior, REGHISTORY.deferred, 
						         REGHISTORY.deferredpaid, REGHISTORY.depositonly, REGHISTORY.depositbalpaid, 
						         REGHISTORY.action, REGHISTORY.amount, TERMS.termname, 
						         FACILITIES.name, CLASSES.description, CLASSES.startdt, 
						         CLASSES.enddt, CLASSES.suncount, CLASSES.moncount, 
						         CLASSES.tuecount, CLASSES.wedcount, CLASSES.thucount, 
						         CLASSES.fricount, CLASSES.satcount, FACILITIES.addr1, 
						         FACILITIES.city, FACILITIES.state, FACILITIES.zip, 
						         FACILITIES.phone, REG.facid, REG.termid, 
						         REGHISTORY.primarypatronid, REGHISTORY.ec, 
						         CLASSES.classcomments, REG.regid, CLASSES.defer,
						         reg.feebalance, reghistory.balance, facilities.addr1, facilities.city,
						         facilities.state, facilities.zip, facilities.phone, reg.patronid, classes.finalpaymentdue
						FROM     reg REG
						         INNER JOIN patrons PATRONS ON REG.patronid=PATRONS.patronid
						         INNER JOIN reghistory REGHISTORY ON REG.primarypatronid=REGHISTORY.primarypatronid AND REG.regid=REGHISTORY.regid
						         INNER JOIN terms TERMS ON REG.termid=TERMS.termid AND REG.facid=TERMS.facid
						         INNER JOIN facilities FACILITIES ON REG.facid=FACILITIES.facid
						         INNER JOIN classes CLASSES ON REG.termid=CLASSES.termid AND REG.facid=CLASSES.facid AND REG.classid=CLASSES.classid 
						WHERE    REGHISTORY.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
						AND      REGHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						AND      REGHISTORY.action in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="E,W,P,F,V" />)
						and      reghistory.IsMiscFee = false
						and      reghistory.deferredpaid = false
						and      reghistory.wasconverted = false
						ORDER BY FACILITIES.name, TERMS.termid, PATRONS.lastname, PATRONS.firstname, REG.classid
					</cfquery>
			
					<cfif GetRegistrations.recordcount is not 0>
						<cfset PrintDisclaimer = 1>
						<cfset LastPatronID = 0>
						<TR>
							<TD>
								<table width="100%" border=0 cellpadding=1 cellspacing="0">
									<TR>
										<TD class="bodytext_bold" colspan="9">Registration Summary</TD>
									</TR>
									<cfset CurrentFac = "">
									
									<cfloop query="GetRegistrations">
	
										<cfif GetRegistrations.action is "E">
											<cfset TotalClassCosts = TotalClassCosts + amount>
										</cfif>
	
										<cfif CurrentFac is not facid>
											<cfset bgcolor="ededed">
											<TR bgcolor="0048d0">
												<TD colspan="9" align="center" class="bodytext_white">#name#, #addr1#, #city#, #state# #zip# (#left(phone,3)#) #mid(phone,4,3)#-#mid(phone,7,4)#</TD>
											</TR>
											<cfset CurrentFac = facid>
										</cfif>
	
										<cfquery datasource="#DS#" name="GetMiscFee">
											SELECT   ADJUSTMENTS.adjustment, ADJUSTMENTS.adjustmentcode, 
											         REGHISTORY.amount, reghistory.ec
											FROM     reghistory REGHISTORY
											         LEFT OUTER JOIN adjustments ADJUSTMENTS ON REGHISTORY.primarypatronid=ADJUSTMENTS.primarypatronid AND REGHISTORY.ec=ADJUSTMENTS.ec
											WHERE    REGHISTORY.primarypatronid = #GetRegistrations.primarypatronid#
											AND      REGHISTORY.regid = #GetRegistrations.RegID#
											AND      REGHISTORY.action = 'E'
											AND      reghistory.IsMiscFee = true
											AND      REGHISTORY.invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
											AND      REGHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
										</cfquery>
					
										<cfquery datasource="#DS#" name="GetLocations">
											SELECT   DISTINCT LOCATIONS.locdescription 
											FROM     locationschedule LOCATIONSCHEDULE
											         INNER JOIN locations LOCATIONS ON LOCATIONSCHEDULE.facid=LOCATIONS.facid AND LOCATIONSCHEDULE.locid=LOCATIONS.locid
											WHERE    LOCATIONSCHEDULE.termid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetRegistrations.termid#" />
											AND      LOCATIONSCHEDULE.facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetRegistrations.facid#" />
											AND      LOCATIONSCHEDULE.activity = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetRegistrations.classid#" />
										</cfquery>
					
										<cfquery datasource="#DS#" name="GetAdjustment">
											SELECT   ADJUSTMENTS.adjustment, 
											         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
											FROM     adjustments ADJUSTMENTS
											         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
											WHERE    ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#numberFormat(GetRegistrations.ec, "0")#" /> <!---// Alagad: numberFormat() will convert a blank string to a 0, so removed the cfif statement //--->
											AND      primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetRegistrations.primarypatronid#" />
										</cfquery>
					
										<cfif PatronID is not LastPatronID>
											<cfset LastPatronID = PatronID>
											<TR valign="top" bgcolor="#bgcolor#">
												<TD colspan="9" class="greentext"><strong>#GetRegistrations.lastname#, #GetRegistrations.firstname#&nbsp;&nbsp;(#GetRegistrations.patronlookup#)</strong></TD>
											</TR>
										</cfif>
										<TR valign="top" bgcolor="#bgcolor#">
											<TD>
												<cfquery datasource="#DS#" name="GetCodeDesc">
													select statusdescription
													from regstatuscodes
													where statuscode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetRegistrations.action#" />
												</cfquery>
												#GetCodeDesc.statusdescription#
												<cfif GetRegistrations.deferred is 1> (deferred)</cfif>
												<cfif GetRegistrations.depositonly is 1> (dep only)</cfif>
											</TD>
											<TD>#GetRegistrations.classid#</TD>
											<TD>#GetRegistrations.description#</TD>
											<TD>#ValueList(GetLocations.locdescription)#</TD>
											<TD nowrap>
												<cfif GetRegistrations.suncount + GetRegistrations.moncount + GetRegistrations.tuecount + GetRegistrations.wedcount + GetRegistrations.thucount + GetRegistrations.fricount + GetRegistrations.satcount is not 0>
													<span class="BlackBox"><cfif GetRegistrations.suncount is 0>&nbsp;<cfelse>S</cfif></span>
													<span class="BlackBox"><cfif GetRegistrations.moncount is 0>&nbsp;<cfelse>M</cfif></span>
													<span class="BlackBox"><cfif GetRegistrations.tuecount is 0>&nbsp;<cfelse>T</cfif></span>
													<span class="BlackBox"><cfif GetRegistrations.wedcount is 0>&nbsp;<cfelse>W</cfif></span>
													<span class="BlackBox"><cfif GetRegistrations.thucount is 0>&nbsp;<cfelse>T</cfif></span>
													<span class="BlackBox"><cfif GetRegistrations.fricount is 0>&nbsp;<cfelse>F</cfif></span>
													<span class="BlackBox"><cfif GetRegistrations.satcount is 0>&nbsp;<cfelse>S</cfif></span>
												</cfif>
											</TD>
											<TD>#lCase(TimeFormat(GetRegistrations.startdt,"hh:mmtt"))#-#lCase(TimeFormat(GetRegistrations.enddt,"hh:mmtt"))#</TD>
											<TD>#DateFormat(GetRegistrations.startdt,"mm/dd/yy")#-#DateFormat(GetRegistrations.enddt,"mm/dd/yy")#</TD>
											<TD align="right">
												<cfif GetRegistrations.startdt is not "" and GetRegistrations.enddt is not "" and GetRegistrations.enddt greater than or equal to GetRegistrations.startdt>
													<!--- calculate weeks: calculated by weeks between start and end dates, ignores missing weeks--->
													
													<cfquery datasource="#DS#" name="_GetDT">
													 select   date(startdt) as t
													 from     locationschedule
													 where    termid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetRegistrations.termid#" />
													 and      facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetRegistrations.facid#" />
													 and      activity = <cfqueryparam cfsqltype="cf_sql_varchar" value="#GetRegistrations.classid#" />
													 order by startdt
													</cfquery>
													<cfset Duration = durationweeks("_GetDT","t",0)>
													
													<cfset Duration = DateDiff("ww",#GetRegistrations.startdt#,#GetRegistrations.enddt#)>
								
													<cfif DayOfWeek(GetRegistrations.startdt) less than or equal to DayOfWeek(GetRegistrations.enddt)>
														<cfset Duration = Duration + 1>
													</cfif>
													#Duration#&nbsp;wk(s)
												</cfif>
											</TD>
											<TD align="right"><cfif action is "E" and deferred is 0>#DecimalFormat(GetRegistrations.amount)#</cfif></TD>
										</TR>
					
										<cfif action is "E">
											<cfset TotalFees = TotalFees + GetRegistrations.amount>
										</cfif>
					
										<cfif GetRegistrations.deferred is 1>
											<TR valign="top" bgcolor="#bgcolor#">
												<TD colspan="8" align="right">Payment has been deferred. Patron must pay balance of #DecimalFormat(GetRegistrations.balance)# on or before #DateFormat(GetRegistrations.defer,"mm/dd/yy")#</TD>
												<TD></TD>
											</TR>
											<cfset TotalDefered = TotalDefered + GetRegistrations.balance>
										</cfif>
	
										<cfif GetRegistrations.depositonly is 1>
											<TR valign="top" bgcolor="#bgcolor#">
												<TD colspan="8" align="right">Only the deposit was paid. Patron must pay balance of #DecimalFormat(GetRegistrations.balance)#<cfif finalpaymentdue is not ""> on or before #dateformat(finalpaymentdue,"mm/dd/yy")#</cfif>.</TD>
												<TD></TD>
											</TR>
										</cfif>
	
										<cfif GetAdjustment.adjustmentdescription is not "">
											<TR valign="top" bgcolor="#bgcolor#">
												<TD colspan="8" align="right">Reflects a cost adjustment of #DecimalFormat(GetAdjustment.adjustment)# for #GetAdjustment.adjustmentdescription#</TD>
												<TD></TD>
											</TR>
										</cfif>
					
										<cfif GetMiscFee.recordcount is not 0 and GetRegistrations.deferred is 0 and GetRegistrations.depositonly is 0>
											<cfset TotalClassCosts = TotalClassCosts + GetMiscFee.amount>
	
											<TR valign="top" bgcolor="#bgcolor#">
												<TD colspan="8" align="right">Misc Fee</TD>
												<TD align="right">#DecimalFormat(GetMiscFee.amount)#</TD>
											</TR>
					
											<cfset TotalFees = TotalFees + GetMiscFee.amount>
											<cfif GetMiscFee.adjustment is not "" and GetMiscFee.adjustment is not 0>
					
												<cfquery datasource="#DS#" name="GetMiscFeeAdjustment">
													SELECT   ADJUSTMENTS.adjustment, 
													         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
													FROM     adjustments ADJUSTMENTS
													         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
													WHERE    ec = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetMiscFee.ec#" />
													AND      primarypatronid = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetRegistrations.primarypatronid#" />
												</cfquery>
					
												<TR bgcolor="#bgcolor#">
													<TD colspan="8" align="right">Reflects a misc fee adjustment of #DecimalFormat(GetMiscFeeAdjustment.adjustment)# for #GetMiscFeeAdjustment.adjustmentdescription#</TD>
													<TD></TD>
												</TR>
											</cfif>
					
										</cfif>
					
										<cfif GetRegistrations.classcomments is not "">
											<TR valign="top" bgcolor="#bgcolor#">
												<TD colspan="9">#GetRegistrations.classcomments#</TD>
											</TR>
										</cfif>
										<cfif bgcolor is 'ededed'>
											<cfset bgcolor = "ffffff">
										<cfelse>
											<cfset bgcolor = "ededed">
										</cfif>
									</cfloop>
									<TR class="bodytext_bold">
										<TD colspan="7" align="right">Total Invoice Class Costs:</TD>
										<TD align="right" colspan="2">#DecimalFormat(TotalClassCosts)#</TD>
									</TR>
									<cfif GetInvoiceData.expassmtwarn is 1>
										<TR>
											<TD colspan="9" align="center">
												Please note that one or more classes will start after the current assessment has expired. The patron will be required to purchase an assessment before starting the class(es).
											</TD>
										</TR>
									</cfif>
								</table>
							</td>
						</tr>
					</cfif>
					<!--- end registrations --->
					
					<!--- ------ --->
					<!--- Dropin --->
					<!--- ------ --->
					<cfquery datasource="#DS#" name="GetDropinData">
						SELECT   DROPINSELECTIONS.fee, 
						         DROPINSELECTIONS.senior, PATRONS.lastname, 
						         PATRONS.firstname, PATRONS.middlename, 
						         DROPINSELECTIONS.description, DROPINHISTORY.ncreason,DROPINHISTORY.nc   
						FROM     dropinselections
						         INNER JOIN dropinhistory ON DROPINSELECTIONS.facid=DROPINHISTORY.facid AND DROPINSELECTIONS.clickid=DROPINHISTORY.clickid
						         LEFT OUTER JOIN patrons ON DROPINSELECTIONS.patronid=PATRONS.patronid
						         <!--- INNER JOIN dropinactivities ON DROPINSELECTIONS.facid=DROPINACTIVITIES.facid AND DROPINSELECTIONS.activityid=DROPINACTIVITIES.activityid  --->
						WHERE    DROPINHISTORY.facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" /> 
						AND      DROPINHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
						ORDER BY PATRONS.lastname, PATRONS.firstname
					</cfquery>				
	
					<cfset TotalDropinFees = 0>

					<cfif GetDropinData.recordcount is not 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="bodytext_bold" colspan="4">Dropin Acitivites</TD>
									</TR>
									<TR>
										<TD>Patron</TD>
										<TD>Activity</TD>
										<td>Senior Rate</td>
										<TD align="right">Fee</TD>
									</TR>
									<cfloop query="GetDropinData">
										<TR>
											<TD><cfif lastname is not "">#lastname#, #firstname# #middlename#</cfif></TD>
											<TD>#description#</TD>
											<TD>#YesNoFormat(senior)#</TD>
											<TD align="right">#numberformat(Fee,"99,999.99")#</TD>
											<cfset TotalDropinFees = TotalDropinFees + Fee>
											<cfset IsNC = nc>
											<cfset ncreason1 = ncreason>
										</TR>
									</cfloop>
									<TR class="bodytext_bold">
										<TD colspan="3" align="right">Total Dropin Fees</TD>
										<TD align="right">#numberformat(TotalDropinFees,"99,999.99")#</TD>
									</TR>
									<cfif IsNC is 1>
										<TR>
											<TD align="right">No charge for activities. Reason: #ncreason1#</TD>
										</TR>
									</cfif>
								</table>
							</td>
						</tr>
						<cfset TotalFees = TotalFees + TotalDropinFees>
					</cfif>
	
					<!--- ------- --->
					<!--- Summary --->
					<!--- ------- --->
					<cfset BeginBalance = GetInvoiceData.startingbalance>
					<cfset NewCredits = TotalClassCredits>
	
					<cfif IsDefined("VoidedPassFees")>
						<cfset NewCredits = TotalPassCredit>
					</cfif>
					
					<cfif IsDefined("AsstCredits")>
						<cfset NewCredits = NewCredits + AsstCredits>
					</cfif>
					
					<!--- <cfset TotalFees = TotalFees> --->
					<cfset CreditApplied = GetInvoiceData.usedcredit>
					<cfset NetDue = TotalFees-GetInvoiceData.usedcredit>
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<cfset Balance = TotalPaid - NetDue>
					
					<cfif GetInvoiceData.othercreditusedcardid gt 0>
						<cfset Balance = Balance + GetInvoiceData.othercreditused>
					</cfif>					
					
					<cfset NetAccountBal = BeginBalance + NewCredits - CreditApplied + TotalPaid - GetInvoiceData.tenderedchange - NetDue>
					
					<!--- <cfif GetOtherCreditUsed.recordcount is 1> --->
					<cfif GetInvoiceData.othercreditusedcardid gt 0>
						<cfset NetAccountBal = NetAccountBal + GetInvoiceData.othercreditused>
					</cfif>

					<cfset boxstr = 'style="border-top-width: 1px; border-top-style: solid; border-top-color: Black;"'>

					<cfquery datasource="#application.dopsds#" name="GetOCCredits">
						SELECT   sum(credit) AS sumcredit 
						FROM     othercreditdatahistory 
						WHERE    invoicefacid = '#CurrentInvoiceFac#' 
						AND      invoicenumber = #CurrentInvoiceNumber# 
						AND      action = 'B'
					</cfquery>

					<cfif GetOCCredits.recordcount is 0 or GetOCCredits.sumcredit is "">
						<cfset thissumcredit = 0>
					<cfelse>
						<cfset thissumcredit = GetOCCredits.sumcredit>
					</cfif>

					<cfif GetInvoiceData.invoicetype is "-OCP-" and GetInvoiceData.faappid is not "">
						<cfset suppresssummary = 1>
					</cfif>					
					
                         

					
					<CFPARAM name="suppresssummary" default="0">
					<cfif suppresssummary is 0>
						<TR>
							<TD>
								<table width="100%">
									<TR align="right" valign="top">
										<TD width="30%" class="ReportBold">Payments</TD>
										<TD >Cash:</TD>
										<TD #DecimalFormat(GetInvoiceData.tenderedcash)#</TD>
										<TD >Beginning Account Bal:</TD>
										<TD >#DecimalFormat(BeginBalance)#</TD>
										<TD >Net Due:</TD>
										<TD class="bodytext_red">
											<!--- <cfif GetOtherCreditUsed.recordcount is 1> --->
											<cfif GetInvoiceData.othercreditusedcardid gt 0>
												<cfset NetDue = NetDue - GetInvoiceData.othercreditused>
											</cfif>
											#DecimalFormat(NetDue)#
										</TD>
									</TR>
									<TR align="right" valign="top">
										<TD></TD>
										<TD>Check:</TD>
										<TD>#DecimalFormat(GetInvoiceData.tenderedcheck)#</TD>
										<TD align="right"><cfif GetOCCredits.sumcredit gt 0>* </cfif>New Credit:</TD>
										<TD align="right">#DecimalFormat(NewCredits - thissumcredit)#</TD>
										<TD>Total Paid:</TD>
										<TD>#DecimalFormat(TotalPaid)#</TD>
									</TR>
									<TR align="right" valign="top">
										<TD></TD>
										<TD>Charge:</TD>
										<TD>#DecimalFormat(GetInvoiceData.tenderedcc)#</TD>
										<TD>Total Fees:</TD>
										<TD>#DecimalFormat(TotalFees)#</TD>
										<TD>Balance:</TD>
										<TD>#DecimalFormat(Balance)#</TD>
									</TR>
									<TR align="right" valign="top">
										<TD></TD>
										<TD>Total Paid:</TD>
										<TD>#DecimalFormat(TotalPaid)#</TD>
										<TD>Credit Applied:</TD>
										<TD>#DecimalFormat(CreditApplied)#</TD>
										<TD>Change:</TD>
										<TD>#DecimalFormat(GetInvoiceData.tenderedchange)#</TD>
									</TR>
									<TR align="right" valign="top">
										<TD></TD>
										<TD><cfif TotalDefered is not 0>Deferred Fees:</cfif></TD>
										<TD><cfif TotalDefered is not 0>#DecimalFormat(TotalDefered)#</cfif></TD>
	
											<!--- <cfif GetOtherCreditUsed.recordcount is 1> --->
											<cfif GetInvoiceData.othercreditusedcardid gt 0>
												<cf_cryp type="de" string="#GetOtherCreditActivity.othercreditdata#" key="#skey#">
												<cfset deOtherCreditData = cryp.value>

												<TD><strong>#GetOtherCreditActivity.othercreditdesc[1]# (...#right(deOtherCreditData,4)#) Usage:</strong></TD>
												<TD>#decimalformat(GetInvoiceData.othercreditused)#</TD>
											<cfelse>
												<TD></TD>
	 											<TD></TD>
											</cfif>
	
										<TD>Net Account Bal:</TD>
                                                  <CFIF GetInvoiceData.ccreturn gt 0>
                                                  <TD style="color:red;" >#DecimalFormat(NetAccountBal - thissumcredit)#</TD>
                                                  <CFELSE>
                                                  <TD class="bodytext_red" >#DecimalFormat(NetAccountBal - thissumcredit)#</TD>
                                                  </CFIF>
										
									</TR>
                                             
                                             <!--- check to see if this is a credit card refund --->
				    <cfif GetInvoiceData.ccreturn gt 0>
     
                         <cfquery datasource="#application.dopsds#" name="GetRefundReceipts">
                                 SELECT   receipt
                                 FROM     dops.invoicetranxdist
                                 WHERE    invoicefacid = <cfqueryparam value="#CurrentInvoiceFac#" cfsqltype="cf_sql_varchar" list="no">
                                 AND      invoicenumber = <cfqueryparam value="#CurrentInvoiceNumber#" cfsqltype="cf_sql_integer" list="no">
                                 AND      amount < <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
                                 GROUP BY receipt
                         </cfquery>
     
                              <TR align="right">
                                      <TD colspan="6" nowrap>
                                              Credit Card Refund<br>
                                              #replace( ValueList( GetRefundReceipts.receipt ), ",", ", ", "all" )#
                                      </TD>
                                      <TD valign="top">- #decimalformat( GetInvoiceData.ccreturn )#</TD>
                              </TR>
                              <TR align="right">
                                      <TD colspan="6" nowrap>Net Account Bal:</TD>
                                      <TD><b style="color:red">#decimalformat( NetAccountBal - GetInvoiceData.ccreturn )#</b></TD>
                              </TR>
     				</cfif>
                                             
								</table>
							</td>
						</TR>

						<cfif GetOCCredits.sumcredit gt 0>
							<TR>
								<TD align="right"><strong>* #numberformat(GetOCCredits.sumcredit,"999,999.99")# of class credits were applied back to original Gift Card(s). This amount has been subtracted from the New Credit amount.</strong></TD>
							</TR>
						</cfif>
						<CFPARAM name="showretaincomment" default="1">
						<cfif ShowRetainComment is 1 and GetInvoiceData.p_patronid is not "" and GetInvoiceData.othercreditusedcardid[GetInvoiceData.currentrow] gt 0 or 1 is 12>
							<TR>
								<TD align="center" class="BlackBox">Be sure to retain <strong>#GetOtherCreditActivity.othercreditdesc[1]#</strong> until activity completion as any credits may be applied to said card</TD>
							</TR>
						</cfif>

					</cfif>
					
					<!--- OLD
					<TR>
						<TD>
							<table width="100%" border=0>
								<TR>
									<TD class="bodytext_bold" colspan="7">Payments</TD>
								</TR>
								<TR align="right" valign="top">
									<TD width="30%"></TD>
									<TD>Cash:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcash)#</TD>
									<TD>Beginning Account Bal:</TD>
									<TD>#DecimalFormat(BeginBalance)#</TD>
									<TD>Net Due:</TD>
									<TD class="bodytext_red">#DecimalFormat(NetDue)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Check:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcheck)#</TD>
									<TD align="right">New Credit:</TD>
									<TD align="right">#DecimalFormat(NewCredits)#</TD>
									<TD>Total Paid:</TD>
									<TD><strong>#DecimalFormat(TotalPaid)#</strong></TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Charge:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcc)#</TD>
									<TD>Total Fees:</TD>
									<TD>#DecimalFormat(TotalFees)#</TD>
									<TD>Balance:</TD>
									<TD>#DecimalFormat(Balance)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Total Paid:</TD>
									<TD>#DecimalFormat(TotalPaid)#</TD>
									<TD>Credit Applied:</TD>
									<TD>#DecimalFormat(CreditApplied)#</TD>
									<TD>Change:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedchange)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD><cfif TotalDefered is not 0>Deferred Fees:</cfif></TD>
									<TD><cfif TotalDefered is not 0>#DecimalFormat(TotalDefered)#</cfif></TD>
									<TD>Net Due:</TD>
									<TD>#DecimalFormat(max(0,NetDue))#</TD>
									<TD>Net Account Bal:</TD>
									<TD class="bodytext_red">#DecimalFormat(NetAccountBal)#</TD>
								</TR>
							</table>
				
						</td>
					</TR>
					--->
				
	
				<cfif PrintDisclaimer is 1>
	
					<cfquery datasource="#DS#" name="GetDisclaimer">
						select disclaimcontents
						from disclaimers
						where disclaimname = 'Refunds'
					</cfquery>
		
					<cfif GetDisclaimer.recordcount is 1>
						<TR><TD>
							<table width="650" border=0>
								<TR>
									<TD style="font-size: 6pt;">#Replace(GetDisclaimer.disclaimcontents,chr(13),"<BR>","all")#</TD>
								</TR>
								<TR>
									<TD style="font-size: 6pt;">NOTE: All drops/cancellations must be made in person or by phone. Please call or visit the appropriate facility hosting the class or activity to process the drop/cancellation.</TD>
								</TR>
							</table>
						</TD></TR>
					</cfif>
	
				</cfif>

			<cfelse>
				<!--- generic invoice --->
				<!--- ------ --->
				<!--- Dropin --->
				<!--- ------ --->
				<cfquery datasource="#DS#" name="GetDropinData">
					SELECT   DROPINSELECTIONS.fee, DROPINSELECTIONS.senior,
					         DROPINselections.description, DROPINHISTORY.ncreason,DROPINHISTORY.nc   
					FROM     dropinselections
					         INNER JOIN dropinhistory ON DROPINSELECTIONS.facid=DROPINHISTORY.facid AND DROPINSELECTIONS.clickid=DROPINHISTORY.clickid
					         <!--- INNER JOIN dropinactivities ON DROPINSELECTIONS.facid=DROPINACTIVITIES.facid AND DROPINSELECTIONS.activityid=DROPINACTIVITIES.activityid  --->
					WHERE    DROPINHISTORY.facid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
					AND      DROPINHISTORY.invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
				</cfquery>				
		
				<cfset TotalDropinFees = 0>
		
				<cfif GetDropinData.recordcount is not 0>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="bodytext_bold" colspan="3">Dropin Acitivites</TD>
						</TR>
						<TR>
							<TD>Activity</TD>
							<td>Senior Rate</td>
							<TD align="right">Fee</TD>
						</TR>
						<cfloop query="GetDropinData">
							<TR>
								<TD>#description#</TD>
								<TD>#YesNoFormat(senior)#</TD>
								<TD align="right">#numberformat(Fee,"99,999.99")#</TD>
								<cfset TotalDropinFees = TotalDropinFees + Fee>
								<cfset IsNC = nc>
								<cfset ncreason1 = ncreason>
							</TR>
						</cfloop>
						<TR class="bodytext_bold">
							<TD colspan="2" align="right">Total Dropin Fees</TD>
							<TD align="right">#numberformat(TotalDropinFees,"99,999.99")#</TD>
						</TR>
						<cfif IsNC is 1>
							<TR>
								<TD align="right">No charge for activities. Reason: #ncreason1#</TD>
							</TR>
						</cfif>
					</table>
					</TD></TR>
					<cfset TotalFees = TotalDropinFees>
		
					<!--- ------- --->
					<!--- Summary --->
					<!--- ------- --->
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<TR>
						<TD>
							<table align="right" width="100%">
								<TR>
									<TD class="bodytext_bold" colspan="5">Payments</TD>
								</TR>
								<TR align="right" valign="top">
									<TD width="50%"></TD>
									<TD>Cash:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcash)#</TD>
									<TD>Total Fees:</TD>
									<TD>#DecimalFormat(TotalFees)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Check:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcheck)#</TD>
									<TD>Total Paid:</TD>
									<TD>#DecimalFormat(TotalPaid)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Charge:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcc)#</TD>
									<TD>Change:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedchange)#</TD>
								</TR>
							</table>
						</td>
					</TR>
				
				</cfif>

				<cfif GetInvoiceData.misctendtype is not "">
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>

					<cfquery datasource="#DS#" name="GetMiscTendType">
						select *
						FROM misctenderingtypes
						where code = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#GetInvoiceData.misctendtype#" />
					</cfquery>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="bodytext_bold" colspan="3">Misc Tendering</TD>
						</TR>
						<TR>
							<TD><strong>Activity</strong></TD>
							<TD><strong>Comments</strong></TD>
							<TD align="right"><strong>Fees</strong></TD>
						</TR>
						<TR>
							<TD colspan="3">&nbsp;</TD>
						</TR>
						<TR>
							<TD>#GetMiscTendType.misctenddescription#</TD>
							<TD>#GetInvoiceData.comments#</TD>
							<TD align="right">#numberformat(TotalPaid,"99,999.99")#</TD>
						</TR>
						<!--- <TR class="bodytext_bold">
							<TD colspan="2" align="right">Total Fees</TD>
							<TD align="right">#numberformat(TotalDropinFees,"99,999.99")#</TD>
						</TR> --->
					</table>
					</TD></TR>
		
					<!--- ------- --->
					<!--- Summary --->
					<!--- ------- --->
					<TR>
						<TD>
							<table align="right" width="100%">
								<TR>
									<TD class="bodytext_bold" colspan="5">Payments</TD>
								</TR>
								<TR align="right" valign="top">
									<TD width="50%"></TD>
									<TD>Cash:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcash)#</TD>
									<TD>Total Fees:</TD>
									<TD>#DecimalFormat(TotalPaid)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Check:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcheck)#</TD>
									<TD>Total Paid:</TD>
									<TD>#DecimalFormat(TotalPaid)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Charge:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcc)#</TD>
									<TD></TD>
									<TD></TD>
								</TR>
							</table>
						</td>
					</TR>
				
				</cfif>

				<!--- issued credit invoice --->
				<cfif GetInvoiceData.InvoiceType EQ '-IC-'>
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="bodytext_bold" colspan="3">Issued Credit</TD>
						</TR>
						<TR valign="bottom">
							<TD><strong>Reason</strong></TD>
							<TD align="right" nowrap><strong>Starting<BR>Balance</strong></TD>
							<TD align="right" nowrap><strong>Issued<BR>Credit<BR>Amount</strong></TD>
							<TD align="right" nowrap><strong>Net<BR>Account<BR>Balance</strong></TD>
						</TR>
						<TR>
							<TD colspan="3">&nbsp;</TD>
						</TR>
						<TR>
							<TD>#GetInvoiceData.comments#</TD>
							<TD align="right">#numberformat(GetInvoiceData.startingbalance,"99,999.99")#</TD>
							<TD align="right">#numberformat(GetInvoiceData.newcredit,"99,999.99")#</TD>
							<TD align="right">#numberformat(GetInvoiceData.newcredit + GetInvoiceData.startingbalance,"99,999.99")#</TD>
						</TR>
					</table>
					</TD></TR>
				
				</cfif>

				<!--- irefund invoice --->
				<cfif GetInvoiceData.InvoiceType EQ '-REF-'>
					<cfset ProcFee = 4>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="bodytext_bold" colspan="3">Account Balance Refund</TD>
						</TR>
						<TR>
							<TD colspan="4">Comments</TD>
						</tr>
						<TR valign="bottom">
							<TD align="right" nowrap><strong>Starting<BR>Balance</strong></TD>
							<TD align="right" nowrap><strong>Processing<BR>Fee</strong></TD>
							<TD align="right" nowrap><strong>Net<BR>Refund</strong></TD>
							<TD align="right" nowrap><strong>Net<BR>Account<BR>Balance</strong></TD>
							<TD align="right" nowrap><strong>Refund<BR>Form</strong></TD>
						</TR>
						<TR>
							<TD colspan="3">&nbsp;</TD>
						</TR>
						<TR>
							<cfset amount = max(abs(GetInvoiceData.Tenderedcc),abs(GetInvoiceData.TenderedCheck))>
							<TD align="right">#numberformat(GetInvoiceData.startingbalance,"99,999.99")#</TD>
							<TD align="right"><cfif GetInvoiceData.applyprocessfee is 1>#numberformat(ProcFee,"999.99")#<cfelse>0.00</cfif></TD>
							<TD align="right">#numberformat(amount,"99,999.99")#</TD>
							<TD align="right">#numberformat(0,"99,999.99")#</TD>
							<TD align="right"><cfif GetInvoiceData.Tenderedcc is not 0>Credit to Card<cfelse>Check</cfif></TD>
						</TR>
						<TR>
							<TD colspan="4">#GetInvoiceData.comments#</TD>
						</tr>
					</table>
					</TD></TR>
				
				</cfif>

				<!--- debit account invoice --->
				<cfif GetInvoiceData.InvoiceType EQ '-AD-'>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="bodytext_bold" colspan="3">Account Debit</TD>
						</TR>
						<TR>
							<TD colspan="4">Comments</TD>
						</tr>
						<TR valign="bottom">
							<TD align="right" nowrap><strong>Starting<BR>Balance</strong></TD>
							<TD align="right" nowrap><strong>Net<BR>Debit</strong></TD>
							<TD align="right" nowrap><strong>Net<BR>Account<BR>Balance</strong></TD>
							<TD align="right" nowrap><strong>Debit<BR>Form</strong></TD>
						</TR>
						<TR>
							<TD colspan="3">&nbsp;</TD>
						</TR>
						<TR>
							<cfset BeginBalance = GetInvoiceData.startingbalance>
							<cfset NetAccountBal = BeginBalance - GetInvoiceData.usedcredit>
							<cfset amount = max(GetInvoiceData.TenderedCheck,GetInvoiceData.TenderedCC)>
							<TD align="right">#numberformat(GetInvoiceData.startingbalance,"99,999.99")#</TD>
							<TD align="right">#numberformat(amount,"99,999.99")#</TD>
							<TD align="right">#numberformat(NetAccountBal,"99,999.99")#</TD>
							<TD align="right"><cfif GetInvoiceData.Tenderedcc is not 0>Credit to Card<cfelse>Check</cfif></TD>
						</TR>
						<TR>
							<TD colspan="4">#GetInvoiceData.comments#</TD>
						</tr>
					</table>
					</TD></TR>
				
				</cfif>

				<!--- end generic invoice --->
			</cfif>

		</tbody>
		<tfoot>
			<TR>
				<TD>
					<table width="650" border=0>
						<TR>
							<TD class="bodytext" align="center"><br>THPRD Administration Office * 15707 SW Walker Road * Beaverton, OR 97006 * (503) 645-6433</TD>
						</TR>
					</table>
				</TD>
			</TR>
		</tfoot>
		</table>
		<cfif InvoiceCount is not CurrentInvoice>
			<br style="page-break-before:always">
		</cfif>

	<cfelse>

		<cfif not IsDefined("CheckForCardData.recordcount") or CheckForCardData.recordcount is 0>
			<BR><BR><BR><BR>
			<table align="center" width=800 cellpadding="1" cellspacing="0">
				<TR>
					<TD align="center" style="pghdr">No invoice was found or was not needed.</TD>
				</TR>
				<TR>
					<TD><input onClick="window.close()" type="Button" value="Close Window" class="form_submit"></TD>
				</TR>
			</table>

		</cfif>

	</cfif>

</cfloop>

</cfoutput>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>


</html>
