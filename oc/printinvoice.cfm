<CFIF Isdefined("request.loadtest")>
		<CFQUERY name="getOneInvoice" datasource="#application.dopsdsro#">
		SELECT  invoicenumber, 
				invoicefacid
		FROM     dops.invoice
		WHERE    invoicefacid = 'WWW'
		and dt > '2009-01-01'
		offset   random() * 2000		
		limit    1
	</CFQUERY>
	<CFSET invoicelist = '#getOneInvoice.invoicefacid#-#getOneInvoice.invoicenumber#'>
</CFIF>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>THPRD Online Registration Summary</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="16" topmargin="25" marginheight="0" onLoad="window.print();">
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


<cfset PrintDisclaimer = 0>


	<cfset CurrentInvoiceFac = url.CurrentInvoiceFac>
	<cfset CurrentInvoiceNumber = url.CurrentInvoiceNumber>
	<cfset TotalFees = 0>
	<cfset TotalDefered = 0>

	<cfquery datasource="#application.dopsds#" name="GetInvoiceData">
		SELECT   INVOICE.indistrict, INVOICE.totalfees, invoice.primarypatronlookup, invoice.primarypatronid,
		         INVOICE.startingbalance, INVOICE.usedcredit, 
		         INVOICE.newcredit, INVOICE.tenderedcash, 
		         INVOICE.tenderedcheck, INVOICE.tenderedcc, 
		         INVOICE.tenderedchange, INVOICE.cced, INVOICE.cew, 
		         INVOICE.node, INVOICE.dt, INVOICE.comments, 
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
		         invoice.applyprocessfee, invoice.invoiceType
		FROM     invoice INVOICE
		         LEFT OUTER JOIN patrons PATRONS ON INVOICE.primarypatronid=PATRONS.patronid
		         INNER JOIN facilities FACILITIES ON INVOICE.invoicefacid=FACILITIES.facid
		where    invoicefacid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#CurrentInvoiceFac#" />
		and      invoicenumber = <cfqueryparam cfsqltype="cf_SQL_MONEY" value="#CurrentInvoiceNumber#" />
	</cfquery>

	<cfif GetInvoiceData.recordcount is not 0>
		<!--- RegInv denotes a regular invoice or not: 1=normal, 0 = generic only --->
		<cfif GetInvoiceData.p_patronid is "" or GetInvoiceData.misctendtype is not "" or GetInvoiceData.InvoiceType EQ '-IC-' or GetInvoiceData.InvoiceType EQ '-REF-' or GetInvoiceData.InvoiceType EQ '-AD-'>
			<cfset Reginv = 0>
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
<!--- ----------------- --->
<!--- League Enrollment --->
<!--- ----------------- --->

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
		         fee
		FROM     content.th_league_enrollments_view
		where    invoicefacid = <cfqueryparam value="#CurrentInvoiceFac#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#CurrentInvoiceNumber#" cfsqltype="CF_SQL_INTEGER">
	</cfquery>

	<cfset TotalPaid = GetInvoiceData.tenderedcash + GetInvoiceData.tenderedcheck + GetInvoiceData.tenderedcc>
	
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
		</cfloop>

		<TR align="right">
			<TD colspan="4"><strong>Total Fees</strong></TD>
			<TD style="border-top-color: Black; border-top-style: solid; border-top-width: 1px; border-bottom-color: Black; border-bottom-style: double;"><strong>#numberformat(totalfees, "99,999.99")#</strong></TD>
		</TR>
		<TR>
			<TD>&nbsp;</TD>
		</TR>
	</table>

</cfif>				
				
				

		</tbody>
		<tfoot>
			<TR>
				<TD>
					<table width="650" border=0>
						<TR>
							<TD class="bodytext" align="center">THPRD Administration Office * 15707 SW Walker Road * Beaverton, OR 97006 * (503) 645-6433</TD>
						</TR>
					</table>
				</TD>
			</TR>
		</tfoot>


</cfoutput>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>


</html>
