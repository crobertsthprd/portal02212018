<!--- define params 
local fac
next invoice

othercreditused
OtherCreditData

skipocdist

var errormessage
CHANGE HISTORY: COPIED FROM DEV TO WWW 1/29/2013 by CR authorized by DH
--->

<cfoutput>

<cfparam name="servername" default="">

<cfquery name="GetInvoiceInvoiceNet" datasource="#application.dopsds#">
	select   invoicenet, dops.getglerror( invoicenet.invoicefacid, invoicenet.invoicenumber ) as gle
	from     invoicenet
	where    invoicefacid = <cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">
	and      invoicenumber = <cfqueryparam value=" #NextInvoice#" cfsqltype="CF_SQL_INTEGER">
</cfquery>

<!--- check for Gl error --->
<cfif GetInvoiceInvoiceNet.recordcount eq 1 and GetInvoiceInvoiceNet.gle neq 0>
	<strong>GL error of <cfoutput>#decimalformat( GetInvoiceInvoiceNet.gle )#</cfoutput> was detected for proposed invoice. Go back and try again. If problem persists, contact THPRD.</strong><BR><BR>
	<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>

	<cfif servername is "DEV">
		<cfinclude template="/Common/displayallinvoicetables.cfm">

	</cfif>

	<cfabort>
</cfif>

<!--- check for negative invoice balance --->
<cfif dollarRound(GetInvoiceInvoiceNet.invoicenet) lt 0>
	<strong>Invoice balance resulted in a negative value: #dollarformat(GetInvoiceInvoiceNet.invoicenet)#. Go back and try again. If problem persists, contact THPRD.</strong><BR><BR>

	<cfif servername is "DEV">
		<cfinclude template="/Common/displayallinvoicetables.cfm">

	<cfelse>
		<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>

	</cfif>

	<cfabort>

</cfif>


<cfif IsDefined("othercreditused") and IsDefined("OtherCreditData") and othercreditused gt 0 and OtherCreditData is not "">

	<cfquery name="GetOCChecks" datasource="#application.dopsds#">
		select   #decimalformat(othercreditused)# as othercreditused, (

		SELECT   sum(credit)
		FROM     othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistsum, (

		SELECT   sum(debit)
		FROM     othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocusedsum, (

		SELECT   dops.getocbalance(othercredithistorysums.cardid, othercredithistorysums.primarypatronid)
		FROM     othercredithistorysums 
		where    

		<cfif IsNumeric(OtherCreditData) and OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="#OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as cardusedbalance, (

		SELECT   faapptype
		FROM     othercredithistorysums 
		where    

		<cfif IsNumeric(OtherCreditData) and OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="#OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as faapptype

	</cfquery>

	<!--- check for negative value --->
	<cfif dollarRound(GetOCChecks.cardusedbalance) lt 0>
		<strong>Other Credit balance resulted in a negative value: #dollarformat(GetOCChecks.cardusedbalance)#. Go back and try again. If problem persists, contact THPRD.</strong><BR><BR>

		<cfif servername is "DEV">
			<cfdump var="#GetOCChecks#">
			<cfinclude template="/Common/displayallinvoicetables.cfm">
	
		<cfelse>
			<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
	
		</cfif>

		<cfabort>

	</cfif>

	<cfif servername is "DEV" and 1 is 2>
		<cfdump var="#GetOCChecks#">
		<BR>
	</cfif>

	<cfif GetOCChecks.recordcount is 1 and dollarRound(val(GetOCChecks.ocusedsum)) is not dollarRound(val(othercreditused))>
		<strong>Other Credit Used calculation Error.<BR>
		Expected #decimalformat(othercreditused)#, found #decimalformat(GetOCChecks.ocusedsum)#.
		Go back and try checkout again or contact THPRD if problem persists.</strong>
		<BR><br>

		<cfif servername is "DEV">
			<cfdump var="#GetOCChecks#">
			<cfinclude template="/Common/displayallinvoicetables.cfm">

		<cfelse>
			<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>

		</cfif>

		<cfabort>
	
	</cfif>

	<cfif not IsDefined("skipocdist") and GetOCChecks.recordcount is 1 and dollarRound(val(GetOCChecks.ocdistsum)) is not dollarRound(val(othercreditused))>
		<strong>Other Credit Distribution Error.<BR>
		Expected #decimalformat(othercreditused)#, found #decimalformat(GetOCChecks.ocdistsum)#.
		Go back and try checkout again or contact THPRD if problem persists.</strong>
		<BR><br>

		<cfif servername is "DEV">
			<cfdump var="#GetOCChecks#">
			<cfinclude template="/Common/displayallinvoicetables.cfm">

		<cfelse>
			<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>

		</cfif>

		<cfabort>
	
	</cfif>

</cfif>

</cfoutput>
