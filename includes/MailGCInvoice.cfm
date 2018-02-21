<cfset NETSCAPE71SCALER = 1>

<cfmail to="#trim(theEmail)#" from="webadmin@thprd.org" cc="cjackson@thprd.org" bcc="webadmin@thprd.org" subject="THPRD Online Payment Receipt - Gift Card" type="html">

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Gift Card Invoice</title>
	<link rel="stylesheet" type="text/css" href="https://www.thprd.org/webimages/reports.css">
</head>

<body>
<cfset ThisInvoice = ListToArray(invoicelist)>
<cfset InvoiceCount = arraylen(ThisInvoice)>
<cfset PrintDisclaimer = 0>

<cfif InvoiceCount is 0>
	<strong>No invoices were found to process</strong>
	<cfabort>
</cfif>

<cfset ShowRetainComment = 1>
<cfset FirstInvoice = 1>

<form action="PrintInvoice.cfm" name="f" method="post">
<input name="invoicelist" type="Hidden" value="#invoicelist#">

<cfloop from="1" to="#InvoiceCount#" step="1" index="CurrentInvoice">
	<cfset CurrentInvoiceFac = ucase(left(ThisInvoice[CurrentInvoice],Find("-",ThisInvoice[CurrentInvoice])-1))>
	<cfset CurrentInvoiceNumber = mid(ThisInvoice[CurrentInvoice],Find("-",ThisInvoice[CurrentInvoice])+1,99)>
	<cfset TotalFees = 0>
	<cfset TotalDefered = 0>
	<cfset UseCurrentAddress = 0>
	<cfset suppresssummary = 0>

	<cfquery datasource="#application.dopsds#" name="GetInvoiceData">
		SELECT   INVOICE.indistrict, INVOICE.totalfees, invoice.primarypatronlookup,
		         INVOICE.startingbalance, INVOICE.usedcredit, invoice.invoicefacid,
		         INVOICE.newcredit, INVOICE.tenderedcash, 
		         INVOICE.tenderedcheck, INVOICE.tenderedcc, 
		         INVOICE.tenderedchange, INVOICE.cced, INVOICE.cew, 
		         INVOICE.node, INVOICE.dt, INVOICE.comments, 
		         PATRONS.patronlookup, PATRONS.lastname, PATRONS.firstname, 
		         PATRONS.middlename, PATRONS.renter, PATRONS.insufficientid, 
		         INVOICE.printable, invoice.invoiceaddress,
		         FACILITIES.name AS facname, FACILITIES.addr1 AS facaddr, 
		         FACILITIES.city AS faccity, FACILITIES.state AS facstate, 
		         FACILITIES.zip AS faczip, FACILITIES.phone AS facphone,
		         invoice.expassmtwarn, invoice.primarypatronid as p_patronid,
		         invoice.addressid, invoice.mailingaddressid, misctendtype,
		         invoice.lastname as invlastname, invoice.firstname as invfirstname,
		         invoice.contact as invcontact, invoice.isvoided,
		         invoice.applyprocessfee,
		         invoice.isreservationinvoice, invoice.othercreditusedcardid,
		         invoice.invoicetype
		FROM     invoice INVOICE
		         LEFT OUTER JOIN patrons PATRONS ON INVOICE.primarypatronid=PATRONS.patronid
		         INNER JOIN facilities FACILITIES ON INVOICE.invoicefacid=FACILITIES.facid
		where    invoicefacid = '#CurrentInvoiceFac#'
		and      invoicenumber = #CurrentInvoiceNumber#
	</cfquery>

	<cfif GetInvoiceData.recordcount is not 0>

		<cfquery datasource="#application.dopsds#" name="GetOtherCreditUsed">
			SELECT   othercredittypes.othercreditdesc,
			         othercreditactivities.description, 
			         othercreditdatahistory.debit
			FROM     othercreditdatahistory 
			         INNER JOIN othercreditdata on othercreditdatahistory.cardid=othercreditdata.cardid
			         INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype
			         INNER JOIN othercreditactivities othercreditactivities ON othercreditdatahistory.action=othercreditactivities.activitycode 
			WHERE    othercreditdatahistory.invoicefacid =  '#CurrentInvoiceFac#'
			AND      othercreditdatahistory.invoicenumber = #CurrentInvoiceNumber#
			AND      othercreditdatahistory.action = 'U'
		</cfquery>

		<!--- RegInv denotes a regular invoice or not: 1=normal, 0 = generic only --->
		<cfif GetInvoiceData.isreservationinvoice is 1 or GetInvoiceData.p_patronid is "" or GetInvoiceData.misctendtype is not "" or GetInvoiceData.InvoiceType EQ '-IC-' or GetInvoiceData.InvoiceType EQ '-REF-' or GetInvoiceData.InvoiceType EQ '-AD-'>
			<cfset Reginv = 0>

			<cfif GetInvoiceData.isreservationinvoice is 1>

				<cfquery datasource="#application.dopsds#" name="GetReservationData">
					SELECT   distinct locations.locid, locations.locdescription, locationschedule.startdt, 
					         locationschedule.enddt, reservationpatrons.respatronid,
					         reservationpatrons.lastname, reservationpatrons.firstname, reservationpatrons.middlename,
					         reservationactivities.suppresslocationoninvoice, 
					         reservations.reservationid, reservations.description, 
					         reservations.ratemethod, reservations.idregbasis, reservations.odregbasis,
					         reservations.idsenbasis, reservations.odsenbasis,
					         reservations.comments, reservationpayments.usedcredit, 
					         reservationpayments.tenderedcash, 
					         reservationpayments.tenderedcheck, 
					         reservationpayments.tenderedcc,
					         reservations.deposit, reservations.securedeposit,reservationpayments.paymenttype,
					         reservationpayments.paidbyrespatronid
					FROM     reservationpayments
					         INNER JOIN reservations reservations ON reservationpayments.reservationid=reservations.reservationid
					         INNER JOIN locationschedule locationschedule ON reservations.reservationid=locationschedule.reservationid
					         INNER JOIN locations locations ON locationschedule.locid=locations.locid AND locationschedule.facid=locations.facid
					         INNER JOIN reservationactivities reservationactivities ON reservations.facid=reservationactivities.facid AND reservations.activityid=reservationactivities.activityid 
					         inner join reservationpatrons on reservationpatrons.respatronid=reservationpayments.respatronid
					WHERE    reservationpayments.invoicefacid = '#CurrentInvoiceFac#' 
					AND      reservationpayments.invoicenumber = #CurrentInvoiceNumber# 
					ORDER BY locations.locdescription, locationschedule.startdt, locationschedule.enddt, lastname, firstname, middlename
				</cfquery>

			</cfif>

		<cfelse>
			<cfset RegInv = 1>
		</cfif>

		<cfif RegInv is 1 or GetInvoiceData.InvoiceType EQ '-IC-' or GetInvoiceData.InvoiceType EQ '-REF-' or GetInvoiceData.InvoiceType EQ '-AD-'>

			<cfquery datasource="#application.dopsds#" name="GetAddressData">
				select PATRONADDRESSES.address1, PATRONADDRESSES.address2, 
				       PATRONADDRESSES.city, PATRONADDRESSES.state, 
				       PATRONADDRESSES.zip,
				       PATRONADDRESSES.comment
				from   patronaddresses
				where  addressid = 
				<cfif GetInvoiceData.mailingaddressid is not "" and GetInvoiceData.mailingaddressid is not 0>
					#GetInvoiceData.mailingaddressid#
				<cfelseif GetInvoiceData.addressid is not "" and GetInvoiceData.addressid is not 0>
					#GetInvoiceData.addressid#
				<cfelse>
					0
				</cfif>

			</cfquery>

			<cfif GetInvoiceData.p_patronid gt 0 and IsDefined("UseCurrentPatronAddress")>

				<cfquery datasource="#application.dopsds#" name="GetAddressDataUCA" maxrows="1">
					SELECT   PATRONADDRESSES.ADDRESS1, PATRONADDRESSES.ADDRESS2, 
					         PATRONADDRESSES.CITY, PATRONADDRESSES.STATE, 
					         PATRONADDRESSES.ZIP, PATRONADDRESSES.comment
					FROM     PATRONRELATIONS PATRONRELATIONS
					         INNER JOIN PATRONADDRESSES PATRONADDRESSES ON PATRONRELATIONS.MAILINGADDRESSID=PATRONADDRESSES.ADDRESSID 
					WHERE    PATRONRELATIONS.PRIMARYPATRONID = #GetInvoiceData.p_patronid#
					AND      PATRONADDRESSES.ADDRESS1 is not null
					limit    1
				</cfquery>

				<cfif GetAddressDataUCA.recordcount is 1>
					<cfset UseCurrentAddress = 1>
				</cfif>

			</cfif>

		</cfif>

		<table width="100%">
			<!--- ------------- --->
			<!--- invoice header--->
			<!--- ------------- --->
			<thead>
				<TR valign="top" style="height: #1 * 25#mm;">
					<TD>
						<table width="100%">
							<TR align="center" valign="center">
								<!--- start conditional for THPF --->
							<CFIF trim(getInvoiceData.Node) EQ "FND">
								<TD width="1px" rowspan="2">&nbsp;</TD>
								<TD class="font12pt" ><img width="303" height="73" src="https://www.thprd.org//webimages/thpflogo.jpg"><br>Tualatin Hills Park Foundation Transaction Receipt</TD>
							<CFELSE>
								<TD width="1px" rowspan="2"><img width="80" height="80" src="https://www.thprd.org//webimages/thprdlogo.gif"></TD>
								<TD class="font12pt">Tualatin Hills Park & Recreation District<BR>Transaction Receipt</TD>
								</CFIF>
								<TD width="1%" nowrap>
									<cfif FirstInvoice is 1>
										<!---
										<cfif not IsDefined("UseCurrentPatronAddress")>
											<!--- <input name="UseCurrentPatronAddress" type="Submit" value="Reload With Current Addresses" style="width: 200;"> --->
											<A class="NoPrint" href="PrintInvoice.cfm?invoicelist=#invoicelist#&UseCurrentPatronAddress=1">Reload With Current Address(es)</A>&nbsp;&nbsp;
											<!--- <input name="UseCurrentPatronAddress" type="Submit" value="Reload With Current Addresses" style="width: 200;"> --->
										</cfif>
										--->


										<!--- <input onClick="window.close()" type="button" value="Close Window" class="NoPrint" style="width: 200;"> --->
										<A class="NoPrint" href="javascript:;" onClick="window.close()">Close</A>
										<cfset FirstInvoice = 0>
									<cfelse>

									</cfif>
								</TD>
							</TR>
							<TR>
								<TD align="right" colspan="2"><cfif GetInvoiceData.isvoided is 1><strong>VOIDED</strong> </cfif>Invoice: #CurrentInvoiceFac#-#CurrentInvoiceNumber#&nbsp;
									#DateFormat(GetInvoiceData.dt,"mm/dd/yyyy")# #TimeFormat(GetInvoiceData.dt,"hh:mmtt")#&nbsp;
									<cfif GetInvoiceData.indistrict is 1>(In District)<cfelse>(Out of District)</cfif><cfif GetInvoiceData.primarypatronlookup is not "">&nbsp;ID:#GetInvoiceData.primarypatronlookup#</cfif>
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


				<TR valign="bottom" style="height: #Netscape71Scaler * 37#mm;">
					<TD>
						<table width="100%" border="0">
							<TR valign="bottom">
								<TD class="font10pt" style="padding-left: #Netscape71Scaler * 13#mm; width: #Netscape71Scaler * 115#mm;">
									<!--- patron data --->
									<cfif RegInv is 1 or GetInvoiceData.InvoiceType EQ '-IC-' or GetInvoiceData.InvoiceType EQ '-REF-' or GetInvoiceData.InvoiceType EQ '-AD-'>

										<cfif GetInvoiceData.Lastname is not "Unknown">

											#GetInvoiceData.FirstName# #GetInvoiceData.Lastname#<br>
	
											<cfif UseCurrentAddress is 1>
												#GetAddressDataUCA.Address1#<br>
												<cfif GetAddressDataUCA.Address2 is not "">#GetAddressDataUCA.address2#<BR></cfif>
												#GetAddressDataUCA.city#<cfif GetAddressDataUCA.city is not "">, </cfif>#GetAddressDataUCA.state# #GetAddressDataUCA.zip#
											<cfelse>
												#GetAddressData.Address1#<br>
												<cfif GetAddressData.Address2 is not "">#GetAddressData.address2#<BR></cfif>
												#GetAddressData.city#<cfif GetAddressData.city is not "">, </cfif>#GetAddressData.state# #GetAddressData.zip#
											</cfif>

										</cfif>

									</cfif>
									
									<!--- use reservation for gift cards --->
									<cfif (GetInvoiceData.isreservationinvoice is 1 OR Find("-OCP-",GetInvoiceData.invoicetype) gt 0 OR Find("-OCR-",GetInvoiceData.invoicetype) gt 0) AND RegInv Is 0>

										<cfquery name="GetReservationAddress" datasource="#application.dopsds#">
											SELECT   patronaddresses.address1, patronaddresses.address2, 
											         patronaddresses.city, patronaddresses.state, 
											         patronaddresses.zip
											FROM     patronaddresses patronaddresses
											WHERE    addressid = #GetInvoiceData.addressid#
										</cfquery>

										<cfif GetInvoiceData.p_patronid is "">
											#GetInvoiceData.InvFirstName# #GetInvoiceData.InvLastname#
										<cfelse>
											#GetInvoiceData.FirstName# #GetInvoiceData.Lastname#
										</cfif>

										<br>
										#GetReservationAddress.Address1#<br>
										<cfif GetReservationAddress.Address2 is not "">#GetReservationAddress.address2#<BR></cfif>
										<cfif GetReservationAddress.city is not "">#GetReservationAddress.city#, #GetReservationAddress.state#</cfif> #GetReservationAddress.zip#

									<cfelseif RegInv is 0 and GetInvoiceData.invlastname is not "" and Find("-OCP-",GetInvoiceData.invoicetype) EQ 0 AND Find("-OCR-",GetInvoiceData.invoicetype) EQ 0>
										#GetInvoiceData.invFirstName# #GetInvoiceData.invLastname#<br>

										<cfif GetInvoiceData.invoiceaddress is not "">
											#replace(GetInvoiceData.invoiceaddress,chr(13),"<BR>","all")#<BR>
										<cfelse>
											#GetInvoiceData.invcontact#
										</cfif>

									</cfif>
									
									
								</TD>
								<TD class="font9pt">
									<!--- facility data --->
									<cfif getinvoicedata.invoicefacid is "WWW">

										<cfquery datasource="#application.dopsds#" name="GetFacDataForOnline">
											SELECT   name 
											FROM     facilities 
											WHERE    facid = 'ADM'
										</cfquery>

										#GetFacDataForOnline.name# (On-Line)<br>
									<cfelse>
										#GetInvoiceData.facname#<br>
									</cfif>

									#GetInvoiceData.facaddr#<br>
									#GetInvoiceData.faccity#, #GetInvoiceData.facstate# #GetInvoiceData.faczip#<br>
									(#left(GetInvoiceData.facphone,3)#) #mid(GetInvoiceData.facphone,4,3)#-#right(GetInvoiceData.facphone,4)#
								</TD>
							</TR>
						</table>
					</TD>
				</TR>
				<TR>
					<TD style="height: 10mm;">&nbsp;</TD>
				</TR>








					<cfif Find("-OCP-",GetInvoiceData.invoicetype) gt 0>
						<!--- ---------------------- --->
						<!--- Gift Card New Purchase --->
						<!--- ---------------------- --->
						<cfquery datasource="#application.dopsds#" name="GetOtherCreditRecords">
							SELECT   othercredittypes.othercreditdesc, 
							         othercreditdata.othercreditdata, 
							         othercreditdatahistory.credit, othercreditdata.queuedtoship, 
							         othercreditdata.shipdt,
							         shiplastname, shipfirstname, shipaddress, shipcity, shipstate, shipzip
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
								<TD>
									<table width="100%">
	
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
													<cf_cryp type="de" string="#othercreditdata#" key="#skey#">
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
											<TD></TD>
											<TD class="ReportBold" align="right">Total</TD>
											<TD class="ReportBold" align="right" style="border-top: 1px solid Black; width: 2cm;"><strong>#numberformat(totalcreditfees,"99,999.99")#</strong></TD>
										</TR>
									</table>
								</TD>
							</TR>
							<cfset TotalFees = TotalFees + totalcreditfees>
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
				<cf_cryp type="de" string="#GetOtherCreditRecords.othercreditdata#" key="#skey#">
											<cfset originalOtherCreditData = cryp.value>
	
												<cfif othercreditdesc is GetTypes.othercreditdesc[GetTypes.currentrow]>
													<TR align="center">
														<TD><strong>XXXX XXXX XXXX #right(originalOtherCreditData,4)#</strong></TD>
														<TD>#description#</TD>
														<TD align="right" style="width: 2cm;">#numberformat(credit,"99,999.99")#</TD>
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
							         othercreditdatahistory.credit, othercreditdatahistory.debit
							FROM     othercreditdata othercreditdata
							         INNER JOIN othercreditdatahistory othercreditdatahistory ON othercreditdata.cardid=othercreditdatahistory.cardid
							         INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype 
							WHERE    othercreditdatahistory.action = 'T' 
							AND      othercreditdatahistory.invoicefacid = '#CurrentInvoiceFac#' 
							AND      othercreditdatahistory.invoicenumber =  #CurrentInvoiceNumber#
							ORDER BY othercreditdatahistory.cardid
						</cfquery>

						<!--- queuedtoship = true denotes was purchased w/ no card being issued at time of purchase --->
						<cfif GetOtherCreditRecords.recordcount is 2>
							<cfset totalcreditfees = 0>
							<TR>
								<TD>
									<table width="100%">
										<TR>
											<TD class="ReportBold" colspan="3">#GetOtherCreditRecords.othercreditdesc[1]# Transfer Activity</TD>
										</TR>
										<TR class="ReportBold" align="center">
											<TD>Original Card Data</TD>
											<TD>Original Balance</TD>
											<TD>New Card Data</TD>
											<TD>Transfer Fee</TD>
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
											<TD style="width: 3cm;">#numberformat(GetOtherCreditRecords.debit[1] - GetOtherCreditRecords.credit[2],"99,999.99")#</TD>
											<TD style="width: 3cm;">#numberformat(GetOtherCreditRecords.credit[2],"99,999.99")#</TD>
										</TR>
									</table>
									<BR>
								</TD>
							</TR>
							<TR>
								<TD align="center" colspan="4">Original card has been invalidated and no longer usable<BR><BR></TD>
							</TR>
							<cfset TotalFees = TotalFees + GetOtherCreditRecords.credit[2]>
						</cfif>

						<cfset suppresssummary = 1>
					</cfif>

		</tbody>
		<tfoot>
			<TR>
				<TD>
					<table width="100%">
						<TR>
							<TD class="FooterLine" align="center">THPRD Administration Office * 15707 SW Walker Road * Beaverton, OR 97006 * (503) 645-6433</TD>
						</TR>
					</table>
				</TD>
			</TR>
		</tfoot>

		<cfif InvoiceCount is not CurrentInvoice>
			<br style="page-break-before:always">
		</cfif>



	</cfif>

</cfloop>
</form>

</body>
</html>


</cfmail>
