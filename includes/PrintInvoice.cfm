<cfset dopsds    = "dopsds">
<cfset nldopsds  = "dopsds">
<!---cfset servername  = "dev" --->
<cfset NETSCAPE71SCALER = 1>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Print Invoice</title>
	<link rel="stylesheet" type="text/css" href="/webimages/reports.css">
</head>

<cfoutput>

<cfsetting requestTimeout="100">

<cfif IsDefined("PrintMe") and PrintMe is 2>
	<body onLoad="window.print()"</script>
<cfelse>
	<body>
</cfif>

<cfif not IsDefined("NoResizeWindow")>
	<script type="text/javascript" language="JavaScript1.2">
		window.resizeTo(screen.availWidth*0.8,screen.availHeight*0.9)
	</script>
</cfif>

<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset DS = "dopsds">

<!--- print temp card if supplied p_patronid --->
<cfif IsDefined("p_patronid")>

	<cfquery datasource="#application.dopsds#" name="CheckForCardData">
		SELECT   TEMPCARDDATA.patronid
		FROM     tempcarddata TEMPCARDDATA
		where    tempcarddata.patronid = #p_patronid#
	</cfquery>

	<cfif CheckForCardData.recordcount is not 0>
		<cfset NoOfferAllCards = 1>
		<cfinclude template="/Thirst/Reports/TempCardBody.cfm">
		<br style="page-break-before:always">
	</cfif>

</cfif>

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

<cfset ShowRetainComment = 1>
<cfset FirstInvoice = 1>

<form action="file:///X|/www/secure/portal/includes/PrintInvoice.cfm" name="f" method="post">
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
		         INVOICE.tenderedchange, INVOICE.cced, INVOICE.cew, INVOICE.ccreturn,  
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
		         invoice.othercreditusedcardid,
		         invoice.invoicetype,
				 0 AS ISRESERVATIONINVOICE 
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
		<cfif GetInvoiceData.isreservationinvoice is 1 or GetInvoiceData.p_patronid is "" or GetInvoiceData.misctendtype is not "" or GetInvoiceData.invoiceType EQ "-IC-" or GetInvoiceData.invoiceType EQ "-REF-" or GetInvoiceData.invoiceType EQ "-AD-">
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

		<cfif RegInv is 1 or GetInvoiceData.invoiceType EQ "-IC-" or GetInvoiceData.invoiceType EQ "-REF-" or GetInvoiceData.invoiceType EQ "-AD-">

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
								<TD class="font12pt" ><img width="303" height="73" src="/webimages/thpflogo.jpg"><br>Tualatin Hills Park Foundation Transaction Receipt</TD>
							<CFELSE>
								<TD width="1px" rowspan="2"><img width="80" height="80" src="/webimages/thprdlogo.gif"></TD>
								<TD class="font12pt">Tualatin Hills Park & Recreation District<BR>Transaction Receipt</TD>
								</CFIF>
								<TD width="1%" nowrap>
									<cfif FirstInvoice is 1>
										
										
										<cfif not IsDefined("UseCurrentPatronAddress")>
											<!--- <input name="UseCurrentPatronAddress" type="Submit" value="Reload With Current Addresses" style="width: 200;"> --->
											<A class="NoPrint" href="/secure/portal/includes/PrintInvoice.cfm?invoicelist=#invoicelist#&UseCurrentPatronAddress=1">Reload With Current Address(es)</A>&nbsp;&nbsp;
											<!--- <input name="UseCurrentPatronAddress" type="Submit" value="Reload With Current Addresses" style="width: 200;"> --->
										</cfif>

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
				<cfif cgi.server_addr EQ application.devIP>
					<TR>
						<TD class="BlackBox" align="center" style="font-size: larger; background-color: Red;">
							<strong>!!! Test Invoice - Do NOT issue as real!!!</strong>
						</TD>
					</tr>
				</cfif>

				<TR valign="bottom" style="height: #Netscape71Scaler * 37#mm;">
					<TD>
						<table width="100%" border="0">
							<TR valign="bottom">
								<TD class="font10pt" style="padding-left: #Netscape71Scaler * 13#mm; width: #Netscape71Scaler * 115#mm;">
									<!--- patron data --->
									<cfif (RegInv is 1 or GetInvoiceData.invoiceType EQ "-IC-" or GetInvoiceData.invoiceType EQ "-REF-" or GetInvoiceData.invoiceType EQ "-AD-")>
									
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
									<cfif (GetInvoiceData.isreservationinvoice is 1 OR Find("-OCP-",GetInvoiceData.invoicetype) gt 0 OR Find("-OCR-",GetInvoiceData.invoicetype) gt 0) AND RegInv is 0>
									CASE 2 <br>
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
											<cf_cryp type="de" string="#GetOtherCreditRecords.othercreditdata[1]#" key="#skey#">
											<cfset originalOtherCreditData = cryp.value>
										<cfelse>
											<cfset originalOtherCreditData = "">
										</cfif>

										<cfif GetOtherCreditRecords.othercreditdata is not "">
											<cf_cryp type="de" string="#GetOtherCreditRecords.othercreditdata[2]#" key="#skey#">
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










				<cfif RegInv is 1>
					<!--- ----------- --->
					<!--- THPRD Cards --->
					<!--- ----------- --->
					<cfset TotalCardFees = 0>
	
					<cfquery datasource="#application.dopsds#" name="GetCards">
						SELECT   PATRONS.lastname, PATRONS.firstname, CARDHISTORY.printcard, 
						         CARDHISTORY.photomark, CARDHISTORY.amount 
						FROM     cardhistory CARDHISTORY
						         INNER JOIN patrons PATRONS ON CARDHISTORY.patronid=PATRONS.patronid 
						WHERE    CARDHISTORY.invoicefacid = '#CurrentInvoiceFac#'
						AND      CARDHISTORY.invoicenumber = #CurrentInvoiceNumber#
					</cfquery>
	
					<cfif GetCards.recordcount is not 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD colspan="8" class="ReportBold">THPRD Cards</TD>
									</TR>
									<TR class="ReportBold">
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
											<TD align="right"><strong>#decimalformat(amount)#</strong></TD>
										</TR>
									</cfloop>
									<TR class="ReportBold">
										<TD colspan="3" align="right">Total Card Fees:</TD>
										<TD align="right" style="border-top: 1px solid Black;"><strong>#DecimalFormat(TotalCardFees)#</strong></TD>
									</TR>
								</table>
							</TD>
						</TR>
					</cfif>
			
					<!--- ------------------- --->
					<!--- Assessment Upgrades --->
					<!--- ------------------- --->
					<cfif GetInvoiceData.dt lte "2004-12-31">

						<cfquery datasource="#application.dopsds#" name="GetAssessmentsUG">
							SELECT   ALLASSESSMENTS.*<!--- ,
							         <cfif dbe is "M">value<cfelse>coalesce</cfif>(ADJUSTMENTS.adjustment,0) AS adjustment, 
							         <cfif dbe is "M">value<cfelse>coalesce</cfif>(ADJUSTMENTS.adjustmentcode,0) AS adjustmentcode  --->
							FROM     ALLASSESSMENTS ALLASSESSMENTS
							         <!--- LEFT OUTER JOIN ADJUSTMENTS ADJUSTMENTS ON ALLASSESSMENTS.INVOICEFACID=ADJUSTMENTS.INVOICEFACID AND ALLASSESSMENTS.INVOICENUMBER=ADJUSTMENTS.INVOICENUMBER AND ALLASSESSMENTS.EC=ADJUSTMENTS.EC --->
							WHERE    ALLASSESSMENTS.INVOICEFACID = '#CurrentInvoiceFac#' 
							AND      ALLASSESSMENTS.INVOICENUMBER = #CurrentInvoiceNumber#
							AND      ALLASSESSMENTS.OPERATION = 'U'
						</cfquery>
				
						<cfif GetAssessmentsUG.recordcount is not 0>
							<cfset TotalFees = TotalFees + GetAssessmentsUG.assmtfee>
		
							<cfquery datasource="#application.dopsds#" name="GetAssessmentMembers">
								SELECT   distinct ASSESSMENTMEMBERS.patronid, PATRONS.lastname, 
								         PATRONS.firstname, PATRONS.middlename
								FROM     assessmentmembers ASSESSMENTMEMBERS
								         INNER JOIN assessments ASSESSMENTS ON ASSESSMENTMEMBERS.primarypatronid=ASSESSMENTS.primarypatronid AND ASSESSMENTMEMBERS.ec=ASSESSMENTS.ec
								         INNER JOIN patrons PATRONS ON ASSESSMENTMEMBERS.patronid=PATRONS.patronid 
								WHERE    ASSESSMENTS.invoicefacid = '#CurrentInvoiceFac#'
								AND      ASSESSMENTS.invoicenumber = #CurrentInvoiceNumber#
							</cfquery>
		
							<cfquery datasource="#application.dopsds#" name="GetAssmtUGAdjustment">
								SELECT   ADJUSTMENTS.EC, ADJUSTMENTS.ADJUSTMENT, 
								         ADJUSTMENTDESCRIPTIONS.ADJUSTMENTDESCRIPTION 
								FROM     ADJUSTMENTS
								         INNER JOIN ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.ADJUSTMENTCODE=ADJUSTMENTDESCRIPTIONS.ADJUSTMENTCODE 
								WHERE    ADJUSTMENTS.PRIMARYPATRONID = #GetAssessmentsUG.primarypatronid#
								AND      ADJUSTMENTS.EC = #GetAssessmentsUG.EC#
							</cfquery>

							<TR>
								<TD>
									<table width="100%">
										<TR>
											<TD class="ReportBold" colspan="8">Assessments</TD>
										</TR>
										<TR class="ReportBold">
											<TD>Assessment Type</TD>
											<TD>Members</TD>
											<TD>Effective</TD>
											<TD>Expiration</TD>
											<TD align="right">Net Cost</TD>
										</TR>
										<TR valign="top">
											<TD>
												<cfif GetAssessmentsUG.assmtplan is 1>
													<cfif GetAssessmentsUG.assmttype is "F">
														Family,
													<cfelse>
														Single,
													</cfif>
													&nbsp;&nbsp;(<cfif GetAssessmentsUG.operation is "N">New<cfelse>Upgrade</cfif>)
												<cfelse>
													Household
												</cfif>
											</TD>
											<TD>
												<cfloop query="GetAssessmentMembers">
													#GetAssessmentMembers.lastname#, #GetAssessmentMembers.firstname#<BR>
												</cfloop>
											</TD>
											<TD>#DateFormat(GetAssessmentsUG.assmteffective,"mm/dd/yyyy")#</TD>
											<TD>#DateFormat(GetAssessmentsUG.assmtexpires,"mm/dd/yyyy")#</TD>
											<TD align="right"><strong>#decimalformat(GetAssessmentsUG.assmtfee)#</strong></TD>
										</TR>
		
										<cfif GetAssmtUGAdjustment.recordcount is not 0>
											<TR valign="top">
												<TD colspan="5" align="right">Reflects an adjustment of #DecimalFormat(GetAssmtUGAdjustment.adjustment)# for #GetAssmtUGAdjustment.adjustmentdescription#</TD>
												<TD></TD>
											</TR>
										</cfif>
		
									</table>
								</TD>
							</TR>
		
						</cfif>

					</cfif>

					<!--- --------------- --->
					<!--- New Assessments --->
					<!--- --------------- --->
					<cfquery datasource="#application.dopsds#" name="GetAssessments">
						SELECT   ALLASSESSMENTS.*<!--- , ALLASSESSMENTS.EC --->
						         <!--- <cfif dbe is "M">value<cfelse>coalesce</cfif>(ADJUSTMENTS.adjustment,0) AS adjustment, 
						         <cfif dbe is "M">value<cfelse>coalesce</cfif>(ADJUSTMENTS.adjustmentcode,0) AS adjustmentcode, --->
						FROM     ALLASSESSMENTS ALLASSESSMENTS
						         <!--- LEFT OUTER JOIN ADJUSTMENTS ADJUSTMENTS ON ALLASSESSMENTS.INVOICEFACID=ADJUSTMENTS.INVOICEFACID AND ALLASSESSMENTS.INVOICENUMBER=ADJUSTMENTS.INVOICENUMBER AND ALLASSESSMENTS.EC=ADJUSTMENTS.EC --->
						WHERE    ALLASSESSMENTS.INVOICEFACID = '#CurrentInvoiceFac#' 
						AND      ALLASSESSMENTS.INVOICENUMBER = #CurrentInvoiceNumber#
						AND      ALLASSESSMENTS.OPERATION = 'N'
						ORDER BY ALLASSESSMENTS.ASSMTEFFECTIVE
					</cfquery>

					<cfif GetAssessments.recordcount is not 0>

						<cfset plan1count = 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="ReportBold" colspan="8">Assessments</TD>
									</TR>
									<TR class="ReportBold">
										<TD>Assessment Type</TD>
										<TD>Members</TD>
										<TD>Effective</TD>
										<TD>Expiration</TD>
										<TD align="right">Net Cost</TD>
									</TR>

								<cfloop query="GetAssessments">
		
									<cfquery datasource="#application.dopsds#" name="GetAssmtAdjustment">
										SELECT   ADJUSTMENTS.EC, ADJUSTMENTS.ADJUSTMENT, 
										         ADJUSTMENTDESCRIPTIONS.ADJUSTMENTDESCRIPTION 
										FROM     ADJUSTMENTS
										         INNER JOIN ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.ADJUSTMENTCODE=ADJUSTMENTDESCRIPTIONS.ADJUSTMENTCODE 
										WHERE    ADJUSTMENTS.PRIMARYPATRONID = #primarypatronid#
										AND      ADJUSTMENTS.EC = #EC#
									</cfquery>

									<cfif GetAssessments.assmtplan is 1>
										<cfset Plan1Count = Plan1Count + 1>

										<cfif Plan1Count is 1>

											<cfquery datasource="#application.dopsds#" name="GetAssessmentMembers">
												SELECT   distinct ASSESSMENTMEMBERS.patronid, PATRONS.lastname, 
												         PATRONS.firstname, PATRONS.middlename
												FROM     assessmentmembers ASSESSMENTMEMBERS
												         INNER JOIN assessments ASSESSMENTS ON ASSESSMENTMEMBERS.primarypatronid=ASSESSMENTS.primarypatronid AND ASSESSMENTMEMBERS.ec=ASSESSMENTS.ec
												         INNER JOIN patrons PATRONS ON ASSESSMENTMEMBERS.patronid=PATRONS.patronid 
												WHERE    ASSESSMENTS.invoicefacid = '#CurrentInvoiceFac#'
												AND      ASSESSMENTS.invoicenumber = #CurrentInvoiceNumber#
												AND      ASSESSMENTS.EC = #EC#
											</cfquery>

										</cfif>
				
									</cfif>
		
									<cfif GetAssessments.assmtplan is 1 or (GetAssessments.assmtplan is 2 and patronid is primarypatronid)>

										<cfif Plan1Count is 1 or GetAssessments.assmtplan is not 1>
											<cfset TotalFees = TotalFees + GetAssessments.assmtfee>
											<TR valign="top">
												<TD>
													<cfif GetAssessments.assmtplan is 1>
														<cfif GetAssessments.assmttype is "F">
															Family,
														<cfelse>
															Single,
														</cfif>
														&nbsp;&nbsp;(<cfif GetAssessments.operation is "N">New<cfelse>Upgrade</cfif>)
													<cfelse>
														#assmtname#
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
												<TD>#DateFormat(GetAssessments.assmteffective,"mm/dd/yyyy")#</TD>
												<TD>#DateFormat(GetAssessments.assmtexpires,"mm/dd/yyyy")#</TD>
												<TD align="right"><strong>#decimalformat(GetAssessments.assmtfee)#</strong></TD>
											</TR>
			
											<cfif GetAssmtAdjustment.recordcount is not 0>
												<TR valign="top">
													<TD colspan="5" align="right">Reflects an adjustment of #DecimalFormat(GetAssmtAdjustment.adjustment)# for #GetAssmtAdjustment.adjustmentdescription#</TD>
													<TD></TD>
												</TR>
											</cfif>
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
					<cfquery datasource="#application.dopsds#" name="GetAsstCredits">
						SELECT   credit, activity 
						FROM     ACTIVITY 
						WHERE    INVOICEFACID = '#CurrentInvoiceFac#'
						AND      INVOICENUMBER = #CurrentInvoiceNumber#
						AND      ACTIVITYCODE = 'ASCR'
					</cfquery>

					<cfif GetAsstCredits.recordcount gt 0>
						<TR>
							<TD>
								<table width="100%">
									<TR valign="top">
										<TD class="ReportBold">Assessment Cancelation/Credit</TD>
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
					<cfquery datasource="#application.dopsds#" name="GetPasses">
						SELECT   PASSES.ec, PASSES.primarypatronid, passes.passterm,
						         PASSSPAN.passspandescription, PASSTYPE.passdescription, 
						         PASSES.passexpires, PASSES.upgraded, PASSES.passallocation, 
						         PASSES.passfee, 
						         <!--- <cfif dbe is "M">value<cfelse>coalesce</cfif>(ADJUSTMENTS.adjustment,0) as adjustment, 
						         <cfif dbe is "M">value<cfelse>coalesce</cfif>(ADJUSTMENTS.adjustmentcode,0) as adjustmentcode, --->
									passes.upgradetype, passes.upgradebasis, passes.modified
						FROM     passes PASSES
						         INNER JOIN passtype PASSTYPE ON PASSES.passtype=PASSTYPE.passtype
						         INNER JOIN passspan PASSSPAN ON PASSES.passspan=PASSSPAN.passspan
						         <!--- LEFT OUTER JOIN adjustments ADJUSTMENTS ON PASSES.ec=ADJUSTMENTS.ec AND PASSES.primarypatronid=ADJUSTMENTS.primarypatronid --->
						WHERE    PASSES.invoicefacid = '#CurrentInvoiceFac#'
						AND      PASSES.invoicenumber = #CurrentInvoiceNumber#
						AND      passes.modified is null
					</cfquery>
			
					<cfif GetPasses.recordcount is not 0>
						<cfset PassFees = 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="ReportBold" colspan="8">Passes</TD>
									</TR>
									<TR class="ReportBold">
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
	
										<cfquery datasource="#application.dopsds#" name="GetPassMembers">
											SELECT   PATRONS.lastname, PATRONS.firstname, PATRONS.middlename, passmembers.dtadded
											FROM     passmembers PASSMEMBERS
											         INNER JOIN patrons PATRONS ON PASSMEMBERS.patronid=PATRONS.patronid 
											WHERE    PASSMEMBERS.primarypatronid = #GetPasses.primarypatronid#
											AND      PASSMEMBERS.ec = #GetPasses.ec#
											AND      (PASSMEMBERS.DTAdded, PASSMEMBERS.DTAdded) overlaps (#CreateODBCDateTime(GetInvoiceData.DT)#, interval '1 second')
										</cfquery>
		
										<cfquery datasource="#application.dopsds#" name="GetPassAdjustment">
											SELECT   ADJUSTMENTS.EC, ADJUSTMENTS.ADJUSTMENT, 
											         ADJUSTMENTDESCRIPTIONS.ADJUSTMENTDESCRIPTION 
											FROM     ADJUSTMENTS
											         INNER JOIN ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.ADJUSTMENTCODE=ADJUSTMENTDESCRIPTIONS.ADJUSTMENTCODE 
											WHERE    ADJUSTMENTS.PRIMARYPATRONID = #primarypatronid#
											AND      ADJUSTMENTS.EC = #EC#
										</cfquery>

										<TR valign="top">
											<TD>#GetPasses.passdescription#
												<cfif GetPasses.modified is not "">
													<BR>
													<cfquery datasource="#application.dopsds#" name="GetModifcation">
														select description
														from modifications
														where code = '#modified#'
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
											<TD>#DateFormat(GetPasses.Passexpires,"mm/dd/yyyy")#</TD>
											<TD align="right">
												<cfif upgradebasis is not "">
													#decimalformat(upgradebasis)#
												</cfif></TD>
											<TD align="right">
												<cfif upgradebasis is not "">
													#decimalformat(upgradebasis - GetPasses.passfee)#
												</cfif></TD>
											</TD>
											<TD align="right"><cfif GetPassAdjustment.recordcount gt 0>#decimalformat(GetPasses.passfee+GetPassAdjustment.adjustment)#<cfelse>#decimalformat(GetPasses.passfee)#</cfif></TD>
											<TD align="right">#decimalformat(GetPassAdjustment.adjustment)#</TD>
											<TD align="right"><strong>#decimalformat(GetPasses.passfee)#</strong></TD>
										</TR>
										<cfif GetPassAdjustment.recordcount is not 0>
											<TR valign="top">
												<TD colspan="5" align="right">Reflects an adjustment of #DecimalFormat(GetPassAdjustment.adjustment)# for #GetPassAdjustment.adjustmentdescription#</TD>
												<TD></TD>
											</TR>
										</cfif>
									</TD>
								</TR>
							</cfloop>
							<TR>
								<td colspan="3"><cfif IsDefined("postinvoiceadded1")>* denotes patron was added at a later time</cfif></td>
								<TD colspan="4" align="right" class="ReportBold">Total Pass Fees:</TD>
								<TD align="right" colspan="2" class="ReportBold" style="border-top: 1px solid Black;">#DecimalFormat(PassFees)#</TD>
							</TR>
						</table>
					</cfif>




					<!--- ----------------- --->
					<!--- Pass modifcations --->
					<!--- ----------------- --->
					<cfquery datasource="#application.dopsds#" name="GetVoidedPasses">
						SELECT   PASSES.ec, PASSES.primarypatronid, 
						         PASSSPAN.passspandescription, PASSTYPE.passdescription, 
						         PASSES.passexpires, PASSES.upgraded, PASSES.passallocation, 
						         PASSES.passfee, passes.modified, coalesce(passes.credit,0) as credit
						FROM     passes PASSES
						         INNER JOIN passtype PASSTYPE ON PASSES.passtype=PASSTYPE.passtype
						         INNER JOIN passspan PASSSPAN ON PASSES.passspan=PASSSPAN.passspan
						WHERE    PASSES.invoicefacid = '#CurrentInvoiceFac#'
						AND      PASSES.invoicenumber = #CurrentInvoiceNumber#
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
										<TD class="ReportBold" colspan="8">Modified Passes</TD>
									</TR>
	
									<TR class="ReportBold">
										<TD>Pass Type</TD>
										<TD>Members</TD>
										<TD>Expiration</TD>
										<TD align="right">Net Credit</TD>
									</TR>
	
									<cfloop query="GetVoidedPasses">
										<cfset VoidedPassFees = VoidedPassFees + GetVoidedPasses.passfee>
	
										<cfquery datasource="#application.dopsds#" name="GetPassMembers">
											SELECT   PATRONS.lastname, PATRONS.firstname, PATRONS.middlename, passmembers.dtadded
											FROM     passmembers PASSMEMBERS
											         INNER JOIN patrons PATRONS ON PASSMEMBERS.patronid=PATRONS.patronid 
											WHERE    PASSMEMBERS.primarypatronid = #GetVoidedPasses.primarypatronid#
											AND      PASSMEMBERS.ec = #GetVoidedPasses.ec#
											AND      (PASSMEMBERS.DTAdded, PASSMEMBERS.DTAdded) overlaps (#CreateODBCDateTime(GetInvoiceData.DT)#, interval '1 second')
										</cfquery>
	
										<TR valign="top">
											<TD>#GetVoidedPasses.passdescription#
												<BR>
												<cfquery datasource="#application.dopsds#" name="GetModifcation">
													select description
													from modifications
													where code = '#modified#'
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
													#DateFormat(GetVoidedPasses.Passexpires,"mm/dd/yyyy")#
												<cfelse>
													N/A
												</cfif>
											</TD>
											<TD align="right">
												<strong>#numberformat(credit,"99,999.99")#</strong>
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
	
					<cfquery name="GetDrops" datasource="#application.dopsds#">
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
						         facilities.state, facilities.zip, facilities.phone, reg.dropreason, 
						         reghistory.classcreditid, reg.patronid, reg.isstandby, reg.relinquishdt
						FROM     reg REG
						         INNER JOIN patrons PATRONS ON REG.patronid=PATRONS.patronid
						         INNER JOIN reghistory REGHISTORY ON REG.primarypatronid=REGHISTORY.primarypatronid AND REG.regid=REGHISTORY.regid
						         INNER JOIN terms TERMS ON REG.termid=TERMS.termid AND REG.facid=TERMS.facid
						         INNER JOIN facilities FACILITIES ON REG.facid=FACILITIES.facid
						         INNER JOIN classes CLASSES ON REG.termid=CLASSES.termid AND REG.facid=CLASSES.facid AND REG.classid=CLASSES.classid 
						WHERE    REGHISTORY.invoicefacid = '#CurrentInvoiceFac#'
						AND      REGHISTORY.invoicenumber = #CurrentInvoiceNumber#
						AND      REGHISTORY.action in ('D','C','X')
						ORDER BY FACILITIES.name, TERMS.termid, PATRONS.lastname, PATRONS.firstname, REG.classid
					</cfquery>

					<cfif GetDrops.recordcount gt 0>
						<cfset PrintDisclaimer = 1>
						<cfset LastPatronID = 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="ReportBold" colspan="9">Class Drops / Credits / Cancellations</TD>
									</TR>
									<cfset CurrentFac = "">
									<cfset CurrentRegID = 0>

									<cfloop query="GetDrops">

										<cfif CurrentRegID is not regid>
											<cfset CurrentRegID = RegID>
										</cfif>

										<cfif action is not "D"><!--- credits and cancellations only --->
	
											<cfquery datasource="#application.dopsds#" name="GetCreditReason" maxrows="1">
												select reason
												from classcredits
												where invoicefacid = '#getdrops.invoicefacid#'
												and classcreditid = #getdrops.classcreditid#
												limit 1
											</cfquery>
	
										</cfif>
	
										<cfif IsMiscFee is 0>
											<cfset TotalClassCredits = TotalClassCredits + getdrops.amount>
											<cfset DidMiscFee = 0>
										<cfelse>
											<cfset DidMiscFee = 1>
										</cfif>
	
										<cfif CurrentFac is not facid>
											<TR>
												<TD colspan="9" align="center" class="FacilityLine">#name#, #addr1#, #city#, #state# #zip# (#left(phone,3)#) #mid(phone,4,3)#-#right(phone,4)#</TD>
											</TR>
											<cfset CurrentFac = facid>
										</cfif>
	
										<cfquery datasource="#application.dopsds#" name="GetCostFee">
											SELECT   REGHISTORY.amount, reghistory.ec
											FROM     reghistory REGHISTORY
											WHERE    REGHISTORY.primarypatronid = #GetDrops.primarypatronid#
											AND      REGHISTORY.regid = #GetDrops.RegID#
											AND      REGHISTORY.action in ('D','C','X')
											and      reghistory.IsMiscFee = false
											and      reghistory.invoicefacid = '#CurrentInvoiceFac#'
											and      reghistory.invoicenumber = #CurrentInvoiceNumber#
										</cfquery>
					
										<cfquery datasource="#application.dopsds#" name="GetMiscFee">
											SELECT   REGHISTORY.amount, reghistory.ec
											FROM     reghistory REGHISTORY
											WHERE    REGHISTORY.primarypatronid = #GetDrops.primarypatronid#
											AND      REGHISTORY.regid = #GetDrops.RegID#
											AND      REGHISTORY.action in ('D','C','X')
											and      reghistory.IsMiscFee = true
											and      reghistory.invoicefacid = '#CurrentInvoiceFac#'
											and      reghistory.invoicenumber = #CurrentInvoiceNumber#
										</cfquery>

										<cfquery datasource="#application.dopsds#" name="GetLocations">
											SELECT   DISTINCT LOCATIONS.locdescription 
											FROM     locationschedule LOCATIONSCHEDULE
											         INNER JOIN locations LOCATIONS ON LOCATIONSCHEDULE.facid=LOCATIONS.facid AND LOCATIONSCHEDULE.locid=LOCATIONS.locid
											WHERE    LOCATIONSCHEDULE.termid = '#GetDrops.termid#' 
											AND      LOCATIONSCHEDULE.facid = '#GetDrops.facid#' 
											AND      LOCATIONSCHEDULE.activity = '#GetDrops.classid#'
										</cfquery>
					
										<cfif PatronID is not LastPatronID>
											<cfset LastPatronID = PatronID>
											<TR valign="top">
												<TD colspan="9" class="PatronLine">#GetDrops.lastname#, #GetDrops.firstname#&nbsp;&nbsp;&nbsp;#GetDrops.patronlookup#</TD>
											</TR>
										</cfif>

										<cfif IsMiscFee is 0>
											<TR valign="top">
												<TD nowrap>
													<cfquery datasource="#application.dopsds#" name="GetCodeDesc">
														select statusdescription
														from regstatuscodes
														where statuscode = '#GetDrops.action#'
													</cfquery>

													<cfif WasWLDrop is 1>WL&nbsp;</cfif>#GetCodeDesc.statusdescription#
												<cfif isstandby is 1> (Stby<cfif relinquishdt is not "">-relinquished #dateformat(relinquishdt,"m/d/y")#</cfif>)</cfif>
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
												<TD>#DateFormat(GetDrops.startdt,"mm/dd/yyyy")#<cfif dateformat(GetDrops.startdt) is not dateformat(GetDrops.enddt)>-#DateFormat(GetDrops.enddt,"mm/dd/yyyy")#</cfif></TD>
												<TD align="right">
													<cfif GetDrops.startdt is not "" and GetDrops.enddt is not "" and GetDrops.enddt greater than or equal to GetDrops.startdt>
														<!--- calculate weeks to consider missing weeks --->
														<cfquery datasource="#application.dopsds#" name="_GetDT">
															select   date(startdt) as t
															from     locationschedule
															where    termid = '#GetDrops.termid#'
															and      facid = '#GetDrops.facid#'
															and      activity = '#GetDrops.classid#'
															order by startdt
														</cfquery>
														
														#durationweeks("_GetDT","t",1)#
													</cfif>
												</TD>
												<TD align="right"><cfif waswldrop is 0><strong>#DecimalFormat(GetCostFee.amount)#</strong></cfif></TD>
											</TR>
										</cfif>
					
										<cfif GetMiscFee.recordcount is not 0 and DidMiscFee is 1>
											<cfset TotalClassCredits = TotalClassCredits + GetMiscFee.amount>
											<TR valign="top">
												<TD colspan="8" align="right">Misc Fee</TD>
												<TD align="right"><strong>#DecimalFormat(GetMiscFee.amount)#</strong></TD>
											</TR>
										</cfif>
					
										<cfif waswldrop is 0 and DidMiscFee is 0>
											<TR>
												<TD colspan="7" >Reason: <cfif action is "D">#GetDrops.dropreason#<cfelse>#GetCreditReason.reason#</cfif></TD>
											</TR>
										</cfif>
	
									</cfloop>
	
									<TR class="ReportBold">
										<TD colspan="7" align="right">Total Class Credits:</TD>
										<TD align="right" colspan="2" style="border-top: 1px solid Black;"><strong>#DecimalFormat(TotalClassCredits)#</strong></TD>
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
	
					<cfquery name="GetConversions" datasource="#application.dopsds#">
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
						         facilities.state, facilities.zip, facilities.phone, reg.patronid, classes.finalpaymentdue, 
						         reg.isstandby, reg.relinquishdt
						FROM     reg REG
						         INNER JOIN patrons PATRONS ON REG.patronid=PATRONS.patronid
						         INNER JOIN reghistory REGHISTORY ON REG.primarypatronid=REGHISTORY.primarypatronid AND REG.regid=REGHISTORY.regid
						         INNER JOIN terms TERMS ON REG.termid=TERMS.termid AND REG.facid=TERMS.facid
						         INNER JOIN facilities FACILITIES ON REG.facid=FACILITIES.facid
						         INNER JOIN classes CLASSES ON REG.termid=CLASSES.termid AND REG.facid=CLASSES.facid AND REG.classid=CLASSES.classid 
						WHERE    REGHISTORY.invoicefacid = '#CurrentInvoiceFac#'
						AND      REGHISTORY.invoicenumber = #CurrentInvoiceNumber#
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
										<TD class="ReportBold" colspan="10">Registration Conversions</TD>
									</TR>
									<cfset CurrentFac = "">
	
									<cfloop query="GetConversions">
	
										<cfif GetConversions.action is "E">
											<cfset TotalClassCosts = TotalClassCosts + amount>
										</cfif>
	
										<cfif CurrentFac is not facid>
											<TR>
												<TD colspan="9" align="center" class="FacilityLine">#name#, #addr1#, #city#, #state# #zip# (#left(phone,3)#) #mid(phone,4,3)#-#right(phone,4)#</TD>
											</TR>
											<cfset CurrentFac = facid>
										</cfif>
	
										<cfquery datasource="#application.dopsds#" name="GetMiscFee">
											SELECT   ADJUSTMENTS.adjustment, ADJUSTMENTS.adjustmentcode, 
											         REGHISTORY.amount, reghistory.ec
											FROM     reghistory REGHISTORY
											         LEFT OUTER JOIN adjustments ADJUSTMENTS ON REGHISTORY.primarypatronid=ADJUSTMENTS.primarypatronid AND REGHISTORY.ec=ADJUSTMENTS.ec
											WHERE    REGHISTORY.primarypatronid = #GetConversions.primarypatronid#
											AND      REGHISTORY.regid = #GetConversions.RegID#
											AND      reghistory.IsMiscFee = true
											AND      REGHISTORY.invoicefacid = '#CurrentInvoiceFac#'
											AND      REGHISTORY.invoicenumber = #CurrentInvoiceNumber#
										</cfquery>
					
										<cfquery datasource="#application.dopsds#" name="GetLocations">
											SELECT   DISTINCT LOCATIONS.locdescription 
											FROM     locationschedule LOCATIONSCHEDULE
											         INNER JOIN locations LOCATIONS ON LOCATIONSCHEDULE.facid=LOCATIONS.facid AND LOCATIONSCHEDULE.locid=LOCATIONS.locid
											WHERE    LOCATIONSCHEDULE.termid = '#GetConversions.termid#' 
											AND      LOCATIONSCHEDULE.facid = '#GetConversions.facid#' 
											AND      LOCATIONSCHEDULE.activity = '#GetConversions.classid#'
										</cfquery>
					
										<cfquery datasource="#application.dopsds#" name="GetAdjustment">
											SELECT   ADJUSTMENTS.adjustment, 
											         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
											FROM     adjustments ADJUSTMENTS
											         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
											WHERE    ec = #GetConversions.ec#
											AND      primarypatronid = #GetConversions.primarypatronid#
										</cfquery>
	
										<cfquery datasource="#application.dopsds#" name="GetConvertionDescription">
											SELECT   ACTIVITYCODES.activitydescription 
											FROM     activity ACTIVITY
											         INNER JOIN activitycodes ACTIVITYCODES ON ACTIVITY.activitycode=ACTIVITYCODES.activitycode
											WHERE    ec = #GetConversions.ec#
											AND      primarypatronid = #GetConversions.primarypatronid#
										</cfquery>
	
										<cfif PatronID is not LastPatronID>
											<cfset LastPatronID = PatronID>
											<TR valign="top">
												<TD colspan="9" class="PatronLine">#GetConversions.lastname#, #GetConversions.firstname#&nbsp;&nbsp;&nbsp;#GetConversions.patronlookup#</TD>
											</TR>
										</cfif>
										<TR valign="top">
											<TD>
												<cfquery datasource="#application.dopsds#" name="GetOriginalInvoice" maxrows="1">
													select   invoicefacid, invoicenumber
													from     reghistory
													where    primarypatronid = #primarypatronid#
													and      regid = #regid#
													order by dt
													limit    1
												</cfquery>				
		
												<cfquery datasource="#application.dopsds#" name="GetCodeDesc">
													select statusdescription
													from regstatuscodes
													where statuscode = '#GetConversions.action#'
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
											<TD>#DateFormat(GetConversions.startdt,"mm/dd/yyyy")#<cfif dateformat(GetConversions.startdt) is not dateformat(GetConversions.enddt)>-#DateFormat(GetConversions.enddt,"mm/dd/yyyy")#</cfif></TD>
											<TD align="right">
												<cfif GetConversions.startdt is not "" and GetConversions.enddt is not "" and GetConversions.enddt greater than or equal to GetConversions.startdt>
													<!--- calculate weeks to consider missing weeks --->
													<cfquery datasource="#application.dopsds#" name="_GetDT">
														select   date(startdt) as t
														from     locationschedule
														where    termid = '#GetConversions.termid#'
														and      facid = '#GetConversions.facid#'
														and      activity = '#GetConversions.classid#'
														order by startdt
													</cfquery>
													
													#durationweeks("_GetDT","t",1)#
												</cfif>
											</TD>
											<TD align="right"><!--- Basis: #numberformat(costbasis,"9,999.99")#/#numberformat(miscbasis,"9,999.99")# ---></TD>
											<TD align="right"><cfif action is "E" and deferred is 0><strong>#DecimalFormat(GetConversions.amount)#</strong></cfif></TD>
										</TR>
					
										<cfif action is "E">
											<cfset TotalFees = TotalFees + GetConversions.amount>
										</cfif>
					
										<cfif GetConversions.deferred is 1>
											<TR valign="top">
												<TD colspan="9" align="right">Payment has been deferred. Patron must pay balance of #DecimalFormat(GetConversions.balance)# on or before #DateFormat(GetConversions.defer,"mm/dd/yyyy")#</TD>
												<TD></TD>
											</TR>
											<cfset TotalDefered = TotalDefered + GetConversions.balance>
										</cfif>
	
										<cfif GetConversions.depositonly is 1>
											<TR valign="top">
												<TD colspan="9" align="right">Only the deposit was paid. Patron must pay balance of #DecimalFormat(GetConversions.balance)# on or before #DateFormat(GetConversions.finalpaymentdue,"mm/dd/yyyy")#</TD>
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
													<TD align="right"><strong>#DecimalFormat(GetMiscFee.amount)#</strong></TD>
												</TR>
												<cfset TotalFees = TotalFees + GetMiscFee.amount>

												<cfif GetMiscFee.adjustment is not "" and GetMiscFee.adjustment is not 0>
						
													<cfquery datasource="#application.dopsds#" name="GetMiscFeeAdjustment">
														SELECT   ADJUSTMENTS.adjustment, 
														         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
														FROM     adjustments ADJUSTMENTS
														         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
														WHERE    ec = #GetMiscFee.ec#
														AND      primarypatronid = #GetConversions.primarypatronid#
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

									<TR class="ReportBold">
										<TD colspan="8" align="right">Total Class Costs:</TD>
										<TD align="right" colspan="2" style="border-top: 1px solid Black;"><strong>#DecimalFormat(TotalClassCosts)#</strong></TD>
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
	
					<cfquery name="GetRegistrations" datasource="#application.dopsds#">
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
						         facilities.state, facilities.zip, facilities.phone, reg.patronid, classes.finalpaymentdue,
						         reg.isstandby, reg.relinquishdt
						FROM     reg REG
						         INNER JOIN patrons PATRONS ON REG.patronid=PATRONS.patronid
						         INNER JOIN reghistory REGHISTORY ON REG.primarypatronid=REGHISTORY.primarypatronid AND REG.regid=REGHISTORY.regid
						         INNER JOIN terms TERMS ON REG.termid=TERMS.termid AND REG.facid=TERMS.facid
						         INNER JOIN facilities FACILITIES ON REG.facid=FACILITIES.facid
						         INNER JOIN classes CLASSES ON REG.termid=CLASSES.termid AND REG.facid=CLASSES.facid AND REG.classid=CLASSES.classid 
						WHERE    REGHISTORY.invoicefacid = '#CurrentInvoiceFac#'
						AND      REGHISTORY.invoicenumber = #CurrentInvoiceNumber#
						AND      REGHISTORY.action in ('E','W','P','F')
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
								<table width="100%">
									<TR>
										<TD class="ReportBold" colspan="9">Class Enrollments</TD>
									</TR>
									<cfset CurrentFac = "">
	
									<cfloop query="GetRegistrations">
	
										<cfif GetRegistrations.action is "E">
											<cfset TotalClassCosts = TotalClassCosts + amount>
										</cfif>
	
										<cfif CurrentFac is not facid>
											<TR>
												<TD colspan="9" align="center" class="FacilityLine">#name#, #addr1#, #city#, #state# #zip# (#left(phone,3)#) #mid(phone,4,3)#-#right(phone,4)#</TD>
											</TR>
											<cfset CurrentFac = facid>
										</cfif>
	
										<cfquery datasource="#application.dopsds#" name="GetMiscFee">
											SELECT   ADJUSTMENTS.adjustment, ADJUSTMENTS.adjustmentcode, 
											         REGHISTORY.amount, reghistory.ec
											FROM     reghistory REGHISTORY
											         LEFT OUTER JOIN adjustments ADJUSTMENTS ON REGHISTORY.primarypatronid=ADJUSTMENTS.primarypatronid AND REGHISTORY.ec=ADJUSTMENTS.ec
											WHERE    REGHISTORY.primarypatronid = #GetRegistrations.primarypatronid#
											AND      REGHISTORY.regid = #GetRegistrations.RegID#
											AND      REGHISTORY.action = 'E'
											AND      reghistory.IsMiscFee = true
											AND      REGHISTORY.invoicefacid = '#CurrentInvoiceFac#'
											AND      REGHISTORY.invoicenumber = #CurrentInvoiceNumber#
										</cfquery>
					
										<cfquery datasource="#application.dopsds#" name="GetLocations">
											SELECT   DISTINCT LOCATIONS.locdescription 
											FROM     locationschedule LOCATIONSCHEDULE
											         INNER JOIN locations LOCATIONS ON LOCATIONSCHEDULE.facid=LOCATIONS.facid AND LOCATIONSCHEDULE.locid=LOCATIONS.locid
											WHERE    LOCATIONSCHEDULE.termid = '#GetRegistrations.termid#' 
											AND      LOCATIONSCHEDULE.facid = '#GetRegistrations.facid#' 
											AND      LOCATIONSCHEDULE.activity = '#GetRegistrations.classid#'
										</cfquery>
					
										<cfquery datasource="#application.dopsds#" name="GetAdjustment">
											SELECT   ADJUSTMENTS.adjustment, 
											         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
											FROM     adjustments ADJUSTMENTS
											         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
											WHERE    ec = <cfif ec is "">0<cfelse>#GetRegistrations.ec#</cfif>
											AND      primarypatronid = #GetRegistrations.primarypatronid#
										</cfquery>
					
										<cfif PatronID is not LastPatronID>
											<cfset LastPatronID = PatronID>
											<TR valign="top">
												<TD colspan="9" class="PatronLine">#GetRegistrations.lastname#, #GetRegistrations.firstname#&nbsp;&nbsp;&nbsp;#GetRegistrations.patronlookup#</TD>
											</TR>
										</cfif>
										<TR valign="top">
											<TD>
												<cfquery datasource="#application.dopsds#" name="GetCodeDesc">
													select statusdescription
													from regstatuscodes
													where statuscode = '#GetRegistrations.action#'
												</cfquery>
												#GetCodeDesc.statusdescription#
												<cfif GetRegistrations.deferred is 1> (deferred)</cfif>
												<cfif GetRegistrations.depositonly is 1> (dep only)</cfif>
												<cfif isstandby is 1> (Stby<cfif relinquishdt is not "">-relinquished #dateformat(relinquishdt,"m/d/y")#</cfif>)</cfif>
												
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
											<TD>#DateFormat(GetRegistrations.startdt,"mm/dd/yyyy")#<cfif dateformat(GetRegistrations.startdt) is not dateformat(GetRegistrations.enddt)>-#DateFormat(GetRegistrations.enddt,"mm/dd/yyyy")#</cfif></TD>
											<TD align="right">
												<cfif GetRegistrations.startdt is not "" and GetRegistrations.enddt is not "" and GetRegistrations.enddt gte GetRegistrations.startdt>
													<!--- calculate weeks to consider missing weeks --->
													<cfquery datasource="#application.dopsds#" name="_GetDT">
														select   date(startdt) as t
														from     locationschedule
														where    termid   = '#GetRegistrations.termid#'
														and      facid    = '#GetRegistrations.facid#'
														and      activity = '#GetRegistrations.classid#'
														order by startdt
													</cfquery>
													
													#durationweeks("_GetDT","t",1)#
												</cfif>
											</TD>
											<TD align="right"><cfif action is "E" and deferred is 0><strong>#DecimalFormat(GetRegistrations.amount)#</strong></cfif></TD>
										</TR>
					
										<cfif action is "E">
											<cfset TotalFees = TotalFees + GetRegistrations.amount>
										</cfif>
					
										<cfif GetRegistrations.deferred is 1>
											<TR valign="top">
												<TD colspan="8" align="right">Payment has been deferred. Patron must pay balance of #DecimalFormat(GetRegistrations.balance)# on or before #DateFormat(GetRegistrations.defer,"mm/dd/yyyy")#</TD>
												<TD></TD>
											</TR>
											<cfset TotalDefered = TotalDefered + GetRegistrations.balance>
										</cfif>
	
										<cfif GetRegistrations.depositonly is 1>
											<TR valign="top">
												<TD colspan="8" align="right">Only the deposit was paid. Patron must pay balance of #DecimalFormat(GetRegistrations.balance)#<cfif finalpaymentdue is not ""> on or before #dateformat(finalpaymentdue,"mm/dd/yyyy")#</cfif>.</TD>
												<TD></TD>
											</TR>
										</cfif>
	
										<cfif GetAdjustment.adjustmentdescription is not "">
											<TR valign="top">
												<TD colspan="8" align="right">Reflects a cost adjustment of #DecimalFormat(GetAdjustment.adjustment)# for #GetAdjustment.adjustmentdescription#</TD>
												<TD></TD>
											</TR>
										</cfif>
					
										<cfif GetMiscFee.recordcount is not 0 and GetRegistrations.deferred is 0 and GetRegistrations.depositonly is 0>
											<cfset TotalClassCosts = TotalClassCosts + GetMiscFee.amount>
	
											<TR valign="top">
												<TD colspan="8" align="right">Misc Fee</TD>
												<TD align="right"><strong>#DecimalFormat(GetMiscFee.amount)#</strong></TD>
											</TR>
					
											<cfset TotalFees = TotalFees + GetMiscFee.amount>
											<cfif GetMiscFee.adjustment is not "" and GetMiscFee.adjustment is not 0>
					
												<cfquery datasource="#application.dopsds#" name="GetMiscFeeAdjustment">
													SELECT   ADJUSTMENTS.adjustment, 
													         ADJUSTMENTDESCRIPTIONS.adjustmentdescription 
													FROM     adjustments ADJUSTMENTS
													         INNER JOIN adjustmentdescriptions ADJUSTMENTDESCRIPTIONS ON ADJUSTMENTS.adjustmentcode=ADJUSTMENTDESCRIPTIONS.adjustmentcode
													WHERE    ec = #GetMiscFee.ec#
													AND      primarypatronid = #GetRegistrations.primarypatronid#
												</cfquery>
					
												<TR>
													<TD colspan="8" align="right">Reflects a misc fee adjustment of #DecimalFormat(GetMiscFeeAdjustment.adjustment)# for #GetMiscFeeAdjustment.adjustmentdescription#</TD>
													<TD></TD>
												</TR>
											</cfif>
					
										</cfif>
					
										<cfif GetRegistrations.classcomments is not "">
											<TR valign="top">
												<TD colspan="9">#GetRegistrations.classcomments#</TD>
											</TR>
										</cfif>
	
									</cfloop>
									<TR>
										<TD colspan="7" align="right" class="ReportBold">Total Invoice Class Costs:</TD>
										<TD align="right" colspan="2" class="ReportBold" style="border-top: 1px solid Black;"><strong>#DecimalFormat(TotalClassCosts)#</strong></TD>
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
					<cfquery datasource="#application.dopsds#" name="GetDropinData">
						SELECT   DROPINSELECTIONS.fee, 
						         DROPINSELECTIONS.senior, PATRONS.lastname, 
						         PATRONS.firstname, PATRONS.middlename, 
						         DROPINSELECTIONS.description, DROPINHISTORY.ncreason,DROPINHISTORY.nc,DROPINSELECTIONS.isextrapatron
						FROM     dropinselections
						         INNER JOIN dropinhistory ON DROPINSELECTIONS.facid=DROPINHISTORY.facid AND DROPINSELECTIONS.clickid=DROPINHISTORY.clickid
						         LEFT OUTER JOIN patrons ON DROPINSELECTIONS.patronid=PATRONS.patronid
						WHERE    DROPINHISTORY.facid = '#CurrentInvoiceFac#' 
						AND      DROPINHISTORY.invoicenumber = #CurrentInvoiceNumber#
						ORDER BY PATRONS.lastname, PATRONS.firstname
					</cfquery>				
	
					<cfset TotalDropinFees = 0>

					<cfif GetDropinData.recordcount is not 0>
						<TR>
							<TD>
								<table width="100%">
									<TR>
										<TD class="ReportBold" colspan="5">Dropin Acitivites</TD>
									</TR>
									<TR style="font-weight: 900;">
										<TD>Patron</TD>
										<TD></TD>
										<TD>Activity</TD>
										<td>Senior Rate</td>
										<TD align="right">Fee</TD>
									</TR>
									<cfloop query="GetDropinData">
										<TR>
											<TD><cfif lastname is not "">#lastname#, #firstname# #middlename#<cfelse>Unknown</cfif></TD>
											<TD><cfif isextrapatron is 1>(Extra Patron)</cfif></TD>
											<TD>#description#</TD>
											<TD>#YesNoFormat(senior)#</TD>
											<TD align="right">#numberformat(Fee,"99,999.99")#</TD>
											<cfset TotalDropinFees = TotalDropinFees + Fee>
											<cfset IsNC = nc>
											<cfset ncreason1 = ncreason>
										</TR>
									</cfloop>
									<TR class="ReportBold">
										<TD colspan="4" align="right">Total Dropin Fees</TD>
										<TD align="right" style="border-top: 1px solid Black;"><strong>#numberformat(TotalDropinFees,"99,999.99")#</strong></TD>
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
					<cfset NetDue = TotalFees - GetInvoiceData.usedcredit>
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<cfset Balance = TotalPaid - NetDue>

					<cfif GetOtherCreditUsed.recordcount is 1>
						<cfset Balance = Balance + GetOtherCreditUsed.debit>
					</cfif>

					<cfset NetAccountBal = BeginBalance + NewCredits - CreditApplied + TotalPaid - GetInvoiceData.tenderedchange - NetDue>

					<cfif GetOtherCreditUsed.recordcount is 1>
						<cfset NetAccountBal = NetAccountBal + GetOtherCreditUsed.debit>
					</cfif>

					<cfset boxstr = 'style="border-top-width: 1px; border-top-style: solid; border-top-color: Black;"'>

					<cfif suppresssummary is 0>
						<TR>
							<TD>
								<table width="100%">
									<TR align="right" valign="top">
										<TD width="30%" class="ReportBold">Payments</TD>
										<TD #boxstr#>Cash:</TD>
										<TD #boxstr#>#DecimalFormat(GetInvoiceData.tenderedcash)#</TD>
										<TD #boxstr#>Beginning Account Bal:</TD>
										<TD #boxstr#>#DecimalFormat(BeginBalance)#</TD>
										<TD #boxstr#>Net Due:</TD>
										<TD #boxstr#>
											<cfif GetOtherCreditUsed.recordcount is 1>
												<cfset NetDue = NetDue - GetOtherCreditUsed.debit>
											</cfif>
											#DecimalFormat(NetDue)#
										</TD>
									</TR>
									<TR align="right" valign="top">
										<TD></TD>
										<TD>Check:</TD>
										<TD>#DecimalFormat(GetInvoiceData.tenderedcheck)#</TD>
										<TD align="right">New Credit:</TD>
										<TD align="right">#DecimalFormat(NewCredits)#</TD>
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
	
											<cfif GetOtherCreditUsed.recordcount is 1>
												<TD><strong>#GetOtherCreditUsed.othercreditdesc#</strong> Usage</TD>
												<TD>#decimalformat(GetOtherCreditUsed.debit)#</TD>
											<cfelse>
												<TD></TD>
	 											<TD></TD>
											</cfif>
	
										<TD>Net Account Bal:</TD>
										<TD>#DecimalFormat(NetAccountBal)#</TD>
									</TR>
                                                      <cfif GetInvoiceData.ccreturn gt 0>

                                                                                <cfquery datasource="#reportds#" name="GetRefundReceipts">
                                                                                        SELECT   receipt
                                                                                        FROM     dops.invoicetranxdist
                                                                                        WHERE    invoicefacid = <cfqueryparam value="#CurrentInvoiceFac#" cfsqltype="cf_sql_varchar" list="no">
                                                                                        AND      invoicenumber = <cfqueryparam value="#CurrentInvoiceNumber#" cfsqltype="cf_sql_integer" list="no">
                                                                                        AND      amount < <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
                                                                                        GROUP BY receipt
                                                                                </cfquery>

                                                                                <TR align="right">
                                                                                        <TD colspan="6" nowrap>
                                                                                                less Credit Card Refund:
                                                                                                #replace( ValueList( GetRefundReceipts.receipt ), ",", ", ", "all" )#
                                                                                        </TD>
                                                                                        <TD>#decimalformat( GetInvoiceData.ccreturn )#</TD>
                                                                                </TR>
                                                                                <TR align="right">
                                                                                        <TD colspan="6" nowrap>Net Account Bal:</TD>
                                                                                        <TD>#decimalformat( NetAccountBal - GetInvoiceData.ccreturn )#</TD>
                                                                                </TR>
                                                      </cfif>

								</table>
							</td>
						</TR>
	
						<cfif ShowRetainComment is 1 and GetInvoiceData.p_patronid is not "" and GetInvoiceData.othercreditusedcardid[GetInvoiceData.currentrow] gt 0 or 1 is 12>
							<TR>
								<TD align="center" class="BlackBox">Be sure to retain <strong>#GetOtherCreditUsed.othercreditdesc#</strong> until completion as any credits may be applied to said card</TD>
							</TR>
						</cfif>

					</cfif>

				</table>
	
				<cfif PrintDisclaimer is 1>
	
					<cfquery datasource="#application.dopsds#" name="GetDisclaimer">
						select disclaimcontents
						from disclaimers
						where disclaimname = 'Refunds'
					</cfquery>
		
					<cfif GetDisclaimer.recordcount is 1>
						<TR><TD>
							<table width="100%">
								<TR>
									<TD style="font-size: 6pt;">#Replace(GetDisclaimer.disclaimcontents,chr(13),"<BR>","all")#</TD>
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
				<cfquery datasource="#application.dopsds#" name="GetDropinData">
					SELECT   DROPINSELECTIONS.fee, DROPINSELECTIONS.senior,
					         DROPINselections.description, DROPINHISTORY.ncreason,DROPINHISTORY.nc
					FROM     dropinselections
					         INNER JOIN dropinhistory ON DROPINSELECTIONS.facid=DROPINHISTORY.facid AND DROPINSELECTIONS.clickid=DROPINHISTORY.clickid
					WHERE    DROPINHISTORY.facid = '#CurrentInvoiceFac#' 
					AND      DROPINHISTORY.invoicenumber = #CurrentInvoiceNumber#
				</cfquery>
		
				<cfset TotalDropinFees = 0>
		
				<cfif GetDropinData.recordcount is not 0>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="ReportBold" colspan="3">Dropin Acitivites</TD>
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
								<TD align="right"><strong>#numberformat(Fee,"99,999.99")#</strong></TD>
								<cfset TotalDropinFees = TotalDropinFees + Fee>
								<cfset IsNC = nc>
								<cfset ncreason1 = ncreason>
							</TR>
						</cfloop>
						<TR class="ReportBold">
							<TD colspan="2" align="right">Total Dropin Fees</TD>
							<TD align="right"><strong>#numberformat(TotalDropinFees,"99,999.99")#</strong></TD>
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
									<TD class="ReportBold" colspan="5">Payments</TD>
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

					<cfif ShowRetainComment is 1 and GetInvoiceData.p_patronid is not "" and GetInvoiceData.othercreditusedcardid[GetInvoiceData.currentrow] gt 0 or 1 is 12>
						<TR>
							<TD align="center" class="BlackBox">Be sure to retain <strong>#GetOtherCreditUsed.othercreditdesc#</strong> until completion as any credits may be applied to said card</TD>
						</TR>
					</cfif>

				</table>
				</cfif>		























				<!--- ------------ --->
				<!--- Reservations --->
				<!--- ------------ --->
				<cfif IsDefined("GetReservationData.recordcount") and GetReservationData.recordcount gt 0>

					<cfquery name="GetAddressData" datasource="#application.dopsds#">
						SELECT   patronaddresses.address1, patronaddresses.address2, 
						         patronaddresses.city, patronaddresses.state, 
						         patronaddresses.zip 
						FROM     invoice invoice
						         INNER JOIN patronaddresses patronaddresses ON invoice.mailingaddressid=patronaddresses.addressid 
						WHERE    invoice.invoicefacid = '#CurrentInvoiceFac#'
						AND      invoice.invoicenumber = #CurrentInvoiceNumber#
					</cfquery>

					<cfquery name="GetPayments" datasource="#application.dopsds#">
						SELECT   reservationpayments.paymenttype,
						         reservationpayments.usedcredit, 
						         reservationpayments.tenderedcash, 
						         reservationpayments.tenderedcheck, 
						         reservationpayments.tenderedcc, locations.locdescription, 
						         reservations.activity, reservationpayments.reservationid,
						         reservations.ratemethod, reservations.idregbasis, 
						         reservations.odregbasis, reservations.idsenbasis, 
						         reservations.odsenbasis, reservations.securedeposit,
						         locationschedule.startdt, locationschedule.enddt, locationschedule.pk as locationschedulepk,
						         reservationactivities.suppresslocationoninvoice,
						         reservationpatrons.lastname, reservationpatrons.firstname, 
						         reservationpatrons.middlename,
						         reservationpatrons.indistrict, 
						         reservationpatrons.insufficientid, reservationpatrons.senior  
						FROM     reservationpayments reservationpayments
						         INNER JOIN locationschedule locationschedule ON reservationpayments.schedulepk=locationschedule.pk
						         INNER JOIN locations locations ON locationschedule.locid=locations.locid AND locationschedule.facid=locations.facid
						         INNER JOIN reservations reservations ON reservationpayments.reservationid=reservations.reservationid 
						         INNER JOIN reservationactivities reservationactivities ON reservations.activityid=reservationactivities.activityid 
						         INNER JOIN reservationpatrons reservationpatrons ON reservationpayments.respatronid=reservationpatrons.respatronid 
						WHERE    reservationpayments.invoicefacid = '#CurrentInvoiceFac#'
						AND      reservationpayments.invoicenumber = #CurrentInvoiceNumber#
						ORDER BY reservationpayments.reservationid
					</cfquery>

					<cfquery name="GetDistinctSlots" dbtype="query">
						select   distinct reservationid, locationschedulepk, locdescription, activity, ratemethod, idregbasis, odregbasis,
						         idsenbasis, odsenbasis, securedeposit, suppresslocationoninvoice, startdt, enddt<!--- , usedcredit + tenderedcash + tenderedcheck + tenderedcc as tendered --->
						from     GetPayments
						order by reservationid
					</cfquery>

					<cfquery name="GetDistinctReservations" dbtype="query">
						select   distinct reservationid, activity, ratemethod, idregbasis, idsenbasis, odregbasis, odsenbasis, securedeposit, suppresslocationoninvoice
						from     GetPayments
						order by reservationid
					</cfquery>

					<!--- <cfset totaltenderedcash = 0>
					<cfset totaltenderedcheck = 0>
					<cfset totaltenderedcc = 0>
					<cfset totalusedcredit = 0> --->
					<!--- <cfset TotalFees = 0> --->

					<cfset linestyle = 'border-top-color: Gray; border-top-style: solid; border-top-width: 1px;'>
					<cfloop query="GetDistinctReservations">
						<cfset ThisResPaid = 0>
						<!--- <cfset colspanval = GetPayments.recordcount> --->
						<TR>
							<TD>
								<table width="100%">
									<TR valign="bottom" class="ReportBold">
										<TD style="#linestyle#">Reservation ID #numberformat(reservationid,"9999999")#</TD>
										<TD style="#linestyle# padding-right: 1cm;" align="right">ID Basis</TD>
										<TD style="#linestyle# padding-right: 1cm;" align="right" colspan="2">OD Basis</TD>
										<TD style="#linestyle#">Method</TD>
										<TD style="#linestyle#" align="right">Security Dep</TD>
										<TD style="#linestyle#">&nbsp;</TD>
									</TR>
									<TR valign="top">
										<TD>#activity#</TD>
										<TD align="right" style="padding-right: 1cm;"><strong>#numberformat(idregbasis,"99,999.99")#</strong><BR>#numberformat(idsenbasis,"99,999.99")#</TD>
										<TD align="right" style="padding-right: 1cm;" colspan="2"><strong>#numberformat(odregbasis,"99,999.99")#</strong><BR>#numberformat(odsenbasis,"99,999.99")#</TD>
										<TD><cfinclude template="/Reservations/ReservationRateDesc.cfm"></TD>
										<TD align="right"><cfif securedeposit gt 0>#numberformat(securedeposit,"99,999.99")#<cfelse>N/A</cfif></TD>
									</TR>
									<TR style="font-weight: 900;" align="center">
										<TD>Location</TD>
										<TD>Date/Time</TD>
										<TD colspan="2">Duration</TD>
										<TD style="padding-right: 1cm;"><strong>Paid Portion For</strong></TD>
										<TD><strong>DS/Sen</strong></TD>
										<TD align="right"><strong>Amount</strong></TD>
									</TR>


									<cfloop query="GetDistinctSlots">

										<cfif reservationid is GetDistinctReservations.reservationid[GetDistinctReservations.currentrow]>
											<cfset AlreadyDone = "">
											<TR valign="top">
												<TD>
													<cfif GetDistinctSlots.suppresslocationoninvoice[GetDistinctSlots.currentrow] is 1>
														Assigned upon arrival
													<cfelse>
														#locdescription#<BR>
													</cfif>
		
												</TD>
												<TD>#dateformat(startdt,"mm/dd/yyyy")# #timeformat(startdt,"hh:mmtt")# to <cfif dateformat(startdt) is not dateformat(enddt)>#dateformat(enddt,"mm/dd/yyyy")# </cfif>#timeformat(enddt,"hh:mmtt")#</TD>
												<CF_HowLongHasItBeen DATE1="#startdt#" DATE2="#enddt#" ADDWORDS="Yes" ABBREVIATED="no">
												<TD align="right" nowrap>#howlong_hours#</TD>
												<TD style="padding-right: 1cm;" align="right" nowrap>#howlong_minutes#</TD>
		
												<!--- <cfif colspanval gt 0> --->
													<cfset colspanval = 0>
													<TD nowrap>
														<cfloop query="GetPayments">
															<cfif reservationid is GetDistinctReservations.reservationid[GetDistinctReservations.currentrow] and locationschedulepk is GetDistinctSlots.locationschedulepk[GetDistinctSlots.currentrow]>
																#lastname#, #firstname# #middlename#<br>
															</cfif>
														</cfloop>
													</TD>
													<TD align="center" nowrap>
														<cfloop query="GetPayments">
															<cfif reservationid is GetDistinctReservations.reservationid[GetDistinctReservations.currentrow] and locationschedulepk is GetDistinctSlots.locationschedulepk[GetDistinctSlots.currentrow]>
																<cfif indistrict is 0 or insufficientid is 1>OD<cfelse>ID</cfif>/<cfif senior is 0>Reg<cfelse>Sen</cfif><br>
															</cfif>
														</cfloop>
													</TD>
													<TD nowrap align="right">
													<cfloop query="GetPayments">
				
														<cfif paymenttype is "N" and Find(lastname & "__" & firstname & "__" & middlename,AlreadyDone) is 0 or 1 is 1><!---  and resinvfac is CurrentInvoiceFac and resinvnumber is CurrentInvoice --->
		
															<cfif reservationid is GetDistinctReservations.reservationid[GetDistinctReservations.currentrow] and locationschedulepk is GetDistinctSlots.locationschedulepk[GetDistinctSlots.currentrow]>
																<cfset ThisPaid = tenderedcash + tenderedcheck + tenderedcc + usedcredit>
																<cfset ThisResPaid = ThisResPaid + ThisPaid>
																#NumberFormat(ThisPaid,"99,999.99")#<BR>
															</cfif>
		
															<cfset AlreadyDone = AlreadyDone & "||" & lastname & "__" & firstname & "__" & middlename>
														</cfif>
		
													</cfloop>
												</TD>
											</TR>
										</cfif>

									</cfloop>

									<!--- </cfloop> --->

									<!--- <cfset TotalPaid = 0>
									<cfset AlreadyDone = ""> --->

									<!--- normal payments
									<cfloop query="GetPayments">

	
									</cfloop> --->
	
									<!--- deposits --->
									<cfset HasDeposit = 0>
	
									<cfloop query="GetReservationData">
	
										<cfif paymenttype is "D">
											<cfset HasDeposit = 1>
											<cfbreak>
										</cfif>
	
									</cfloop>
	
									<cfif HasDeposit is 1>
										<cfset AlreadyDone = "">
	
										<cfloop query="GetReservationData">
											<!--- deposit --->
											<cfif paymenttype is "D" and Find(lastname & "__" & firstname,AlreadyDone) is 0><!---  and resinvfac is CurrentInvoiceFac and resinvnumber is CurrentInvoice --->
												<cfset ThisPaid = tenderedcash + tenderedcheck + tenderedcc + usedcredit>
												<TR valign="top">
													<TD></TD>
													<TD></TD>
													<TD></TD>
													<TD></TD>
													<TD><strong>Deposit</strong></TD>
													<TD></TD>
													<TD align="right">#numberformat(ThisPaid,"999,999.99")#</TD>
												</TR>
												<cfset ThisResPaid = ThisResPaid + ThisPaid>
												<cfset AlreadyDone = AlreadyDone & "||" & lastname & "__" & firstname>
											</cfif>
	
										</cfloop>
	
									</cfif>
	
									<!--- secureity deposits --->
									<cfif GetReservationData.securedeposit[1] gt 0>
										<cfset AlreadyDone = "">
	
										<cfloop query="GetReservationData">
											<!--- security deposit --->	
											<cfif paymenttype is "S" and Find(lastname & "__" & firstname,AlreadyDone) is 0><!---  and resinvfac is CurrentInvoiceFac and resinvnumber is CurrentInvoice --->
												<cfset ThisPaid = tenderedcash + tenderedcheck + tenderedcc + usedcredit>
												<TR valign="top">
													<TD></TD>
													<TD></TD>
													<TD></TD>
													<TD></TD>
													<TD><strong>Security Deposit</strong></TD>
													<TD></TD>
													<TD align="right">#numberformat(ThisPaid,"999,999.99")#</TD>
												</TR>
												<cfset ThisResPaid = ThisResPaid + ThisPaid>
												<cfset AlreadyDone = AlreadyDone & "||" & lastname & "__" & firstname>
											</cfif>
	
										</cfloop>
	
									</cfif>
	
									<TR>
										<TD colspan="6"></TD>
										<TD align="right" style="border-top: 1px solid Black;"><strong>#numberformat(ThisResPaid,"999,999.99")#</strong></TD>
									</TR>
								</table>
							</TD>
						</TR>
						<cfset TotalFees = TotalFees + ThisResPaid>
					</cfloop>






					<!--- ------- --->
					<!--- Summary --->
					<!--- ------- --->
					<!--- <cfset TotalFees = TotalPaid> --->
					<cfset BeginBalance = GetInvoiceData.startingbalance>
					<cfset NewCredits = 0>
					<cfset CreditApplied = GetInvoiceData.usedcredit>
					<cfset NetDue = TotalFees - GetInvoiceData.usedcredit>
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<cfset Balance = TotalPaid - NetDue>
					<cfset NetAccountBal = BeginBalance - CreditApplied + TotalPaid - GetInvoiceData.tenderedchange - NetDue>
					<cfset boxstr = 'style="border-top-width: 1px; border-top-style: solid; border-top-color: Black;"'>
					<TR>
						<TD>
							<table width="100%">
								<TR align="right" valign="top">
									<TD width="30%" class="ReportBold">Payments</TD>
									<TD #boxstr#>Cash:</TD>
									<TD #boxstr#>#DecimalFormat(GetInvoiceData.tenderedcash)#</TD>
									<TD #boxstr#>Beginning Account Bal:</TD>
									<TD #boxstr#>#DecimalFormat(BeginBalance)#</TD>
									<TD #boxstr#>Net Due:</TD>
									<TD #boxstr#>#DecimalFormat(NetDue)#</TD>
								</TR>
								<TR align="right" valign="top">
									<TD></TD>
									<TD>Check:</TD>
									<TD>#DecimalFormat(GetInvoiceData.tenderedcheck)#</TD>
									<TD align="right">New Credit:</TD>
									<TD align="right">#DecimalFormat(NewCredits)#</TD>
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
									<TD>Net Due:</TD>
									<TD>#DecimalFormat(max(0,NetDue))#</TD>
									<TD>Net Account Bal:</TD>
									<TD>#DecimalFormat(NetAccountBal)#</TD>
								</TR>
							</table>
						</td>
					</TR>

					<cfif ShowRetainComment is 1 and GetInvoiceData.p_patronid is not "" and GetInvoiceData.othercreditusedcardid[GetInvoiceData.currentrow] gt 0 or 1 is 12>
						<TR>
							<TD align="center" class="BlackBox">Be sure to retain <strong>#GetOtherCreditUsed.othercreditdesc#</strong> until completion as any credits may be applied to said card</TD>
						</TR>
					</cfif>

				</table>
			</cfif>



























				<cfif GetInvoiceData.misctendtype is not "">
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>

					<cfquery datasource="#application.dopsds#" name="GetMiscTendType">
						select *
						FROM misctenderingtypes
						where code = #GetInvoiceData.misctendtype#
					</cfquery>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="ReportBold" colspan="3">Misc Tendering</TD>
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
							<TD align="right"><strong>#numberformat(TotalPaid,"99,999.99")#</strong></TD>
						</TR>
					</table>
					</TD></TR>
		
					<!--- ------- --->
					<!--- Summary --->
					<!--- ------- --->
					<TR>
						<TD>
							<table align="right" width="100%">
								<TR>
									<TD class="ReportBold" colspan="5">Payments</TD>
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
				</table>
				</cfif>

				<!--- issued credit invoice --->
				<cfif GetInvoiceData.invoiceType eq "-IC-">
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="ReportBold" colspan="3">Issued Credit</TD>
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

					<cfif ShowRetainComment is 1 and GetInvoiceData.p_patronid is not "" and GetInvoiceData.othercreditusedcardid[GetInvoiceData.currentrow] gt 0 or 1 is 12>
						<TR>
							<TD align="center" class="BlackBox">Be sure to retain <strong>#GetOtherCreditUsed.othercreditdesc#</strong> until completion as any credits may be applied to said card</TD>
						</TR>
					</cfif>

				</table>
				</cfif>

				<!--- refund invoice --->
				<cfif GetInvoiceData.InvoiceType EQ '-REF-'>
					<cfset ProcFee = 4>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="ReportBold" colspan="3">Account Balance Refund</TD>
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
						<TR valign="top">
							<cfset amount = max(abs(GetInvoiceData.Tenderedcc),abs(GetInvoiceData.TenderedCheck))>
							<TD align="right">#numberformat(GetInvoiceData.startingbalance,"99,999.99")#</TD>
							<TD align="right"><cfif GetInvoiceData.applyprocessfee is 1>#numberformat(ProcFee,"999.99")#<cfelse>0.00</cfif></TD>
							<TD align="right"><strong>#numberformat(amount,"99,999.99")#</strong></TD>
							<TD align="right">#numberformat(0,"99,999.99")#</TD>
							<TD align="right" nowrap><cfif GetInvoiceData.Tenderedcc is not 0>Credit to Card<cfelse>Check</cfif></TD>
						</TR>
						<TR>
							<TD colspan="4">#GetInvoiceData.comments#</TD>
						</tr>
					</table>
					</TD></TR>
				</table>
				</cfif>

				<!--- debit account invoice --->
				<cfif GetInvoiceData.InvoiceType EQ '-AD-'>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="ReportBold" colspan="3">Account Debit</TD>
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
							<TD align="right"><cfif GetInvoiceData.Tenderedcc is not 0>Credit to Card<cfelseif GetInvoiceData.TenderedCash is not 0>Correction<cfelse>Check</cfif></TD>
						</TR>
						<TR>
							<TD colspan="4">#GetInvoiceData.comments#</TD>
						</tr>
					</table>
					</TD></TR>
				</table>
				</cfif>

				<!--- foundation invoice --->
				<!--- changed from invoicefacid to invoicetype. CR 04/03/2008 --->
				<cfif GetInvoiceData.invoicetype is "-FND-">
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="ReportBold" colspan="3">Foundation Activity</TD>
						</TR>
						<TR>
							<TD><strong>Comments</strong></TD>
							<TD align="right"><strong>Fees</strong></TD>
						</TR>

						<TR>
							<TD>#GetInvoiceData.comments#</TD>
							<TD align="right"><strong>#numberformat(TotalPaid,"99,999.99")#</strong></TD>
						</TR>
					</table>
					</TD></TR>
		
					<!--- ------- --->
					<!--- Summary --->
					<!--- ------- --->
					<TR>
						<TD>
							<table align="right" width="100%">
								<TR>
									<TD class="ReportBold" colspan="5">Payments</TD>
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
				</table>
				</cfif>
				<!--- classic car show invoice --->
				<!--- changed from invoicefacid to invoicetype. CR 05/15/2008 --->
				<cfif GetInvoiceData.invoicetype is "-FNDCCS-">
					<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
					<TR><TD>
					<table width="100%">
						<TR>
							<TD class="ReportBold" colspan="3">Classic Car Show</TD>
						</TR>
						<TR>
							<TD><strong>Comments</strong></TD>
							<TD align="right"><strong>Fees</strong></TD>
						</TR>

						<TR>
							<TD>#GetInvoiceData.comments#</TD>
							<TD align="right"><strong>#numberformat(TotalPaid,"99,999.99")#</strong></TD>
						</TR>
					</table>
					</TD></TR>
		
					<!--- ------- --->
					<!--- Summary --->
					<!--- ------- --->
					<TR>
						<TD>
							<table align="right" width="100%">
								<TR>
									<TD class="ReportBold" colspan="5">Payments</TD>
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
				</table>
				</cfif>

				<!--- end generic invoice --->
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

	<cfelse>

		<cfif not IsDefined("CheckForCardData.recordcount") or CheckForCardData.recordcount is 0>
			<BR><BR><BR><BR>
			<table align="center">
				<TR>
					<TD align="center" style="font-size: 16pt;">No invoice was found or was not needed.</TD>
				</TR>
				<TR>
					<TD><input style="width: 100%;" onClick="window.close()" type="Button" value="Close Window"></TD>
				</TR>
			</table>

		</cfif>

	</cfif>

</cfloop>
</form>
</cfoutput>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>

</html>
