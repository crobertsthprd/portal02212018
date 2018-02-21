<!--- dependencies

changed dopsds to application.dopds - defined in calling page's application.cfc
removed dollarround - unscoped function round(tranx_amount * 100) / 100
changed key to application.key

//--->

<!---
General notes:

TransType = one of the following codes:
00 for "Purchase"
02 for "Pre-authorization"
11 for "Online Refund"
15 for "Pre-Auth Completion"
06 for "Online Void"
21 for "Cancel Pre-Auth" (sent to https://direct.internetsecure.com/CancelPreauth)
22 for "Authenticate Card"

Must call this function file before initial calling:
<cfinclude template="/Common/FunctionTranx.cfm">

Set calling page requesttimeout to at least 300
Actual processor call timeout is set in dops.systemvars

Any page that uses a test mode (var name testmode) no processor call is performed and simulated approval is returned.

If processor gateway ever changes, look for <GatewayID></GatewayID> and set to correct value

Set calling page requesttimeout to at least 300
Actual processor call timeout is set in dops.systemvars



function call sequence:

OpenTranxCall()

<cftransaction action="BEGIN">
processes

if error

</cftransaction>
<cftransaction action="ROLLBACK">

</cftransaction>

if error occured or decline
	CloseTranxCall()
endif

 --->



<cfcomponent displayname="functiontranx" hint="ColdFusion Component for Interfacing CC Processor">






<cffunction name="GetNextPRC" output="Yes" returntype="numeric">
<cfset var GetNextPRC = "" />

<cfquery name="GetNextPRC" datasource="#application.dopsds#">
	Select nextval('"dops"."prc_seq"') as tmp
</cfquery>

<cfreturn GetNextPRC.tmp>
</cffunction>







<cffunction name="OpenTranxCall" hint="Creates tranx call record. Used to maintain call attempt history." output="Yes" returntype="numeric">
<cfargument name="tranx_node" type="string" required="Yes">
<cfargument name="tranx_ccfunds" type="numeric" required="Yes">
<cfargument name="tranx_primarypatronid" type="numeric" required="yes">
<cfargument name="tranx_sessionid" type="string" required="Yes">
<cfargument name="tranx_action" type="string" required="Yes">
<cfargument name="tranx_submitpk" type="numeric" required="yes">
<cfargument name="tranx_cardholderfirstname" type="string" required="no" default="">
<cfargument name="tranx_cardholderlastname" type="string" required="no" default="">
<cfargument name="tranx_cardholderphone" type="string" required="no" default="">
<cfargument name="tranx_callcomment" type="string" required="no" default="">

<cfset var getinsertprocessorattemptval = "">
<cfset var insertprocessorattempt = "">

<!---
this function MUST be called BEFORE processing cftransaction
--->

<!--- set datasource --->
<cfset var funcds = application.dopsds>

<!--- get next pk --->
<cfquery name="getinsertprocessorattemptval" datasource="#local.funcds#">
	Select nextval('dops.invoicetranxcall_pk_seq') as tmp
</cfquery>

<!--- create record with above pk --->
<cfquery name="insertprocessorattempt" datasource="#local.funcds#">
	insert into dops.invoicetranxcall
		( pk,
		node,
		primarypatronid,
		sessionid,
		action,
		<cfif arguments.tranx_submitpk gt 0>submitpk,</cfif>
		<cfif arguments.tranx_cardholderfirstname neq "">cardholderfirstname,</cfif>
		<cfif arguments.tranx_cardholderlastname neq "">cardholderlastname,</cfif>
		<cfif arguments.tranx_cardholderphone neq "">cardholderphone,</cfif>
		<cfif arguments.tranx_callcomment neq "">callcomment,</cfif>
		amount )
	values
		( <cfqueryparam value="#local.getinsertprocessorattemptval.tmp#" cfsqltype="cf_sql_integer" list="no">,
		<cfqueryparam value="#arguments.tranx_node#" cfsqltype="cf_sql_varchar" list="no">,
		<cfqueryparam value="#arguments.tranx_primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
		<cfqueryparam value="#arguments.tranx_sessionid#" cfsqltype="cf_sql_varchar" list="no">,
		<cfqueryparam value="#arguments.tranx_action#" cfsqltype="cf_sql_varchar" list="no">,

		<cfif arguments.tranx_submitpk gt 0>
			<cfqueryparam value="#arguments.tranx_submitpk#" cfsqltype="cf_sql_integer" list="no">,
		</cfif>

		<cfif arguments.tranx_cardholderfirstname neq "">
			<cfqueryparam value="#arguments.tranx_cardholderfirstname#" cfsqltype="cf_sql_varchar" list="no">,
		</cfif>

		<cfif arguments.tranx_cardholderlastname neq "">
			<cfqueryparam value="#arguments.tranx_cardholderlastname#" cfsqltype="cf_sql_varchar" list="no">,
		</cfif>

		<cfif arguments.tranx_cardholderphone neq "">
			<cfqueryparam value="#arguments.tranx_cardholderphone#" cfsqltype="cf_sql_varchar" list="no">,
		</cfif>

		<cfif arguments.tranx_callcomment neq "">
			<cfqueryparam value="#arguments.tranx_callcomment#" cfsqltype="cf_sql_varchar" list="no">,
		</cfif>

		<cfqueryparam value="#arguments.tranx_ccfunds#" cfsqltype="cf_sql_money" list="no"> )
</cfquery>

<!--- return fetched pk --->
<cfreturn local.getinsertprocessorattemptval.tmp>
</cffunction>















<cffunction name="CloseTranxCall" hint="Closes tranx call record" output="No">
<cfargument name="tranx_close_processor" type="struct" required="Yes">

<!---
This is needed only when an error occurs.
This MUST be called AFTER cftransaction as an error within the transaction will be rolled back from ccsale() data changes
Same is true if processor returned declined as all data changes within ccsale will be rolled back

tranx_call must at least contain the following:

tranx_call.callpk where value = value from OpenTranxCall()
tranx_call.page where value is the page received from processor
tranx_call.receipt where value is the receipt received from processor
tranx_call.guid where value is the guid received from processor
tranx_call.Verbiage where value is returned string value from processor
tranx_call.action
tranx_call.node
tranx_call.primarypatronid
tranx_call.sessionid
tranx_call.processorcalled
--->

<!--- set datasource --->
<cfset var funcds = application.dopsds>

<cfquery name="updatetranxcallclose" datasource="#local.funcds#">
	update dops.invoicetranxcall
	set
		result = <cfqueryparam value="#arguments.tranx_close_processor.Verbiage#" cfsqltype="cf_sql_varchar" list="no">,
		processorcalled = <cfqueryparam value="#arguments.tranx_close_processor.processorcalled#" cfsqltype="cf_sql_bit" list="no">

		<cfif IsDefined("arguments.tranx_close_processor.receipt") and arguments.tranx_close_processor.receipt neq "">
			, receipt = <cfqueryparam value="#arguments.tranx_close_processor.receipt#" cfsqltype="cf_sql_varchar" list="no">
		</cfif>

		<cfif IsDefined("arguments.tranx_close_processor.guid") and arguments.tranx_close_processor.guid neq "">
			, guid = <cfqueryparam value="#arguments.tranx_close_processor.guid#" cfsqltype="cf_sql_varchar" list="no">
		</cfif>

		<cfif IsDefined("arguments.tranx_close_processor.page") and arguments.tranx_close_processor.page neq "">
			, page = <cfqueryparam value="#arguments.tranx_close_processor.page#" cfsqltype="cf_sql_varchar" list="no">
		</cfif>

		<cfif IsDefined("arguments.tranx_close_processor.proctext") and arguments.tranx_close_processor.proctext neq "">
			, proctext = <cfqueryparam value="#arguments.tranx_close_processor.proctext#" cfsqltype="cf_sql_varchar" list="no">
		</cfif>

		<cfif IsDefined("arguments.tranx_close_processor.proctime") and arguments.tranx_close_processor.proctime gt 0>
			, proctime = <cfqueryparam value="#arguments.tranx_close_processor.proctime#" cfsqltype="cf_sql_integer" list="no">
		</cfif>

	where  pk = <cfqueryparam value="#arguments.tranx_close_processor.callpk#" cfsqltype="cf_sql_integer" list="no">
	and    result is null
	and    sessionid = <cfqueryparam value="#arguments.tranx_close_processor.sessionid#" cfsqltype="cf_sql_varchar" list="no">
</cfquery>

</cffunction>

<!--- cc interface overview
Must call this function file before initial calling:
<cfinclude template="/Common/FunctionTranx.cfm">

Any page that uses a test mode (var name testmode) no processor call is performed and simulated approval is returned.
--->

<cffunction name="ccsale_v2" hint="returns TranxResponse from internetsecure.com for ccsale" output="Yes" returntype="struct" access="public">
<!---
usage:

ccsale( mode, callpk, sessionid, node, invoicefacid, invoicenumber [ , customer ] )

where
mode = "SIMA" | "SIMD" | "TESTA" | "TESTD" | "REAL" (case insensitive)
SIMA = Simulated approved: returns "Approved: Simulated sale transaction approved."
SIMD = Simulated declined: returns "Declined: Simulated sale transaction declined."
TESTA = Test Approval from internetsecure
TESTD = Test Decline from internetsecure
REAL = Normal Processing from internetsecure

callpk = transcall.pk created prior to calling this routine
sessionid = session id from CreateUUID(), which must exist throughout entire process
node = PC node
invoicefacid = invoicefacid
invoicenumber = invoicenumber (use either real or temporary number)
customer = customer structure, if not patron based (optional). see example below.

When using simulation mode, the returned receipt is prepended with "S" (real ones do not)

Only cards from USA are allowed.

example:

If non-patron do this before function call:
(use any name structure you wish for customer)
<cfset customer = StructNew()>
<cfset customer.name = first and last names>
<cfset customer.address = address>
<cfset customer.city = city>
<cfset customer.state = state>
<cfset customer.zip = zip>
<cfset customer.phone = phone>

Do all invoice processing BEFORE calling this routine (somewhere near and before </cftransaction>)
If returned value is anything other than starting with "Approved:" denotes attempted failed with returned value being failure reason (either from bank or within this function)
If returned data is NOT XML, the error string is returned
--->

<cfargument name="tranx_mode" type="string" required="Yes">
<cfargument name="tranx_callpk" type="numeric" required="Yes">
<cfargument name="tranx_sessionid" type="string" required="Yes">
<cfargument name="tranx_node" type="string" required="Yes">
<cfargument name="tranx_invoicefacid" type="string" required="Yes">
<cfargument name="tranx_invoicenumber" type="numeric" required="Yes">
<cfargument name="tranx_cardnumber" type="string" required="Yes">
<cfargument name="tranx_ccv" type="string" required="Yes">
<cfargument name="tranx_expmon" type="string" required="Yes">
<cfargument name="tranx_expyear" type="string" required="Yes">
<cfargument name="tranx_customer2" type="struct" required="No">

<!--- set datasource --->
<cfset var funcds = application.dopsds>

<!--- define vars --->
<cfset var tranx_result = StructNew()>
<cfset var sendstrXML = "">
<cfset var receivestrXML = "">
<cfset var xmlData = "">
<cfset var tmpreceipt = "">
<cfset var tranx_cardexpmonth = 0>
<cfset var tranx_cardexpyear = 0>
<cfset var GetInvoiceCCData = "">
<cfset var GetTranxPrimaryData = "">
<cfset var CreateInvoicetranxRecord = "">
<cfset var UpdateTranx = "">
<cfset var ISURL = "">
<cfset var ForcePersonalDataBlanking = false>
<cfset var LocalStartTime = 0>
<cfset var objGet = StructNew()>



<!--- test mode value --->
<cfif ListFind( "SIMA,SIMD,TESTA,TESTD,REAL", arguments.tranx_mode ) eq 0>
	<cfset local.tranx_result.Verbiage = "Mode not acceptable value. Only code of SIMA or SIMD or TESTA or TESTD or REAL is allowed.">
	<cfreturn local.tranx_result>
	<cfabort>

</cfif>

<cfset local.tranx_result.approvalcode = "D"><!--- assume declined --->
<cfset local.tranx_result.receipt = "">
<cfset local.tranx_result.guid = "">
<cfset local.tranx_result.Verbiage = "Undefined ccsale error">
<cfset local.tranx_result.page = "">
<cfset local.tranx_result.invoicefacid = "">
<cfset local.tranx_result.invoicenumber = 0>
<cfset local.tranx_result.callpk = arguments.tranx_callpk>
<cfset local.tranx_result.node = arguments.tranx_node>
<cfset local.tranx_result.action = "S">
<cfset local.tranx_result.primarypatronid = 0>
<cfset local.tranx_result.sessionid = arguments.tranx_sessionid>
<cfset local.tranx_result.processorcalled = false>
<cfset local.tranx_result.proctime = 0>
<cfset local.tranx_result.usepk = 0>
<cfset local.tranx_result.amount = 0>
<cfset local.tranx_result.proctext = "">
<cfset local.tranx_cardexpmonth = arguments.tranx_expmon>
<cfset local.tranx_cardexpyear = arguments.tranx_expyear>

<cfif val( local.tranx_cardexpyear ) lt 2000>
	<cfset local.tranx_cardexpyear = val( local.tranx_cardexpyear ) + 2000>
</cfif>

<!--- end define vars --->

<cfquery datasource="#local.funcds#" name="GetInvoiceCCData">
	-- get invoice data
	select   invoicefacid,
	         invoicenumber,
	         primarypatronid,
	         invoicetype like <cfqueryparam value="%-REG-%" cfsqltype="cf_sql_varchar" list="no"> as isreginvoice,
	         tenderedcc,
	         cced, (

	select   receipt
	from     dops.invoicetranx
	where    invoicetranx.invoicefacid = invoice.invoicefacid
	and      invoicetranx.invoicenumber = invoice.invoicenumber) as receipt, (

	select   guid
	from     dops.invoicetranx
	where    invoicetranx.invoicefacid = invoice.invoicefacid
	and      invoicetranx.invoicenumber = invoice.invoicenumber) as guid, exists(

	select   pk
	from     dops.invoicetranxdist
	where    invoicefacid =  invoice.invoicefacid
	and      invoicenumber =  invoice.invoicenumber) as hasinvoicetranxdist, exists(

	select   sessionid
	from     dops.invoicetranxbypass
	where    invoicetranxbypass.sessionid = <cfqueryparam value="#arguments.tranx_sessionid#" cfsqltype="cf_sql_varchar" list="no">) as bypassprocess, exists(

	select   pk
	from     dops.invoicetranxcall
	where    pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">) as invoicetranxcallrecordfound, exists(

	select   receipt
	from     dops.invoicetranx
	where    sessionid = <cfqueryparam value="#local.tranx_result.sessionid#" cfsqltype="cf_sql_varchar" list="no">) as sessionalreadyprocessed, (

	select   upper( varvalue )
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureIsUsed" cfsqltype="cf_sql_varchar" list="no">) as useinternetsecure, (

	select   upper( varvalue )
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureIsUsedOnWeb" cfsqltype="cf_sql_varchar" list="no">) as useinternetsecureforweb, (

	select   upper( varvalue )
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureIsUsedOnWebForReg" cfsqltype="cf_sql_varchar" list="no">) as useinternetsecureforwebforreg, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureTimeout" cfsqltype="cf_sql_varchar" list="no">) as internetsecuretimeout, (

	select   upper( varvalue )
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureTimeoutBypass" cfsqltype="cf_sql_varchar" list="no">) as bypassoninternetsecuretimeout, (

	select   upper( varvalue )
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureProxyIsUsedOnWeb" cfsqltype="cf_sql_varchar" list="no">) as InternetSecureProxyIsUsedOnWeb, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureProxy" cfsqltype="cf_sql_varchar" list="no">) as internetsecureproxy, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureProxyPort" cfsqltype="cf_sql_varchar" list="no">) as internetsecureproxyport, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureGatewayID" cfsqltype="cf_sql_varchar" list="no">) as InternetSecureGatewayID, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="InternetSecureURL" cfsqltype="cf_sql_varchar" list="no">) as InternetSecureURL

	from     dops.invoice
	where    invoice.invoicefacid = <cfqueryparam value="#arguments.tranx_invoicefacid#" cfsqltype="cf_sql_varchar" list="no">
	and      invoice.invoicenumber = <cfqueryparam value="#arguments.tranx_invoicenumber#" cfsqltype="cf_sql_integer" list="no">
</cfquery>

<cfset local.tranx_result.amount = local.GetInvoiceCCData.tenderedcc>

<!--- check vars formats --->
<cfif len( local.GetInvoiceCCData.useinternetsecure ) neq 1 or len( local.GetInvoiceCCData.useinternetsecureforweb ) neq 1 or len( local.GetInvoiceCCData.bypassoninternetsecuretimeout ) neq 1>
	<cfset local.tranx_result.Verbiage = "System variables useinternetsecure and/or bypassoninternetsecuretimeout are incorrect format. Contact IS.">
	<cfreturn local.tranx_result>

</cfif>

<cfif local.GetInvoiceCCData.recordcount neq 1 or IsDefined("failnouniqueinvoice")>
	<cfset local.tranx_result.Verbiage = "Unique Invoice not found">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif not local.GetInvoiceCCData.invoicetranxcallrecordfound or IsDefined("failnopreloadedtranscallrecord")>
	<cfset local.tranx_result.Verbiage = "Pre-loaded invoicetranxcall record not found">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif not local.GetInvoiceCCData.hasinvoicetranxdist or IsDefined("failnopreloadedtransdistrecord")>
	<cfset local.tranx_result.Verbiage = "Pre-loaded invoicetranxdist records not found">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif len( local.tranx_result.sessionid ) LT 32 or IsDefined("failsessionincorrectformat")>
	<cfset local.tranx_result.Verbiage = "Control sessionid was not correct format">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif local.GetInvoiceCCData.sessionalreadyprocessed or IsDefined("failsessionalreadycompleted")>
	<cfset local.tranx_result.Verbiage = "Session was already invoiced">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif (round(local.GetInvoiceCCData.tenderedcc * 100) / 100) lte 0 or IsDefined("failamountlte0")>
	<cfset local.tranx_result.Verbiage = "Specified charge amount was less than or equal to zero">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif ( local.GetInvoiceCCData.primarypatronid eq 0 and not IsDefined("arguments.tranx_customer2") ) or IsDefined("failcustomerstructurenotfound")>
	<cfset local.tranx_result.Verbiage = "No primary nor customer structure was defined">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

</cfif>

<cfset local.tranx_result.cced = local.GetInvoiceCCData.cced>

<cfif val( local.GetInvoiceCCData.primarypatronid ) neq 0>
	<cfset local.tranx_result.primarypatronid = local.GetInvoiceCCData.primarypatronid>
	<!--- primary based mode --->

	<cfquery datasource="#local.funcds#" name="GetTranxPrimaryData">
		SELECT   <cfif local.ForcePersonalDataBlanking>''<cfelse>trim( patrons.firstname ) || ' ' || trim( patrons.lastname )</cfif> as name,
		         <cfif local.ForcePersonalDataBlanking>''<cfelse>trim( coalesce( patronaddresses.address1, '' ) || ' ' || coalesce( patronaddresses.address2, '') )</cfif> as address,
		         patronaddresses.city,
		         patronaddresses.state,
		         patronaddresses.zip, (

		select   <cfif local.ForcePersonalDataBlanking>''<cfelse>contactdata</cfif>
		from     dops.patroncontact
		where    patroncontact.patronid = patronrelations.primarypatronid
		and      patroncontact.contacttype in ( <cfqueryparam value="C" cfsqltype="cf_sql_char" maxlength="1" list="no">, <cfqueryparam value="H" cfsqltype="cf_sql_char" maxlength="1" list="no"> )
		order by patroncontact.contacttype desc
		limit    1) as phone

		FROM     dops.patronrelations
		         INNER JOIN dops.patrons ON patronrelations.primarypatronid=patrons.patronid
		         INNER JOIN dops.patronaddresses ON patronrelations.mailingaddressid=patronaddresses.addressid
		WHERE    patronrelations.primarypatronid = <cfqueryparam value="#local.GetInvoiceCCData.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
		AND      patronrelations.relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_smallint" list="no">
	</cfquery>

<cfelse>
	<!--- not primary based mode --->
	<cfset local.GetTranxPrimaryData = QueryNew( "name, address, city, state, zip, phone" )>
	<cfset QueryAddRow( local.GetTranxPrimaryData, 1 )>
	<cfset QuerySetCell( local.GetTranxPrimaryData, "name",    arguments.tranx_customer2.name )>
	<cfset QuerySetCell( local.GetTranxPrimaryData, "address", arguments.tranx_customer2.address )>
	<cfset QuerySetCell( local.GetTranxPrimaryData, "city",    arguments.tranx_customer2.city )>
	<cfset QuerySetCell( local.GetTranxPrimaryData, "state",   arguments.tranx_customer2.state )>
	<cfset QuerySetCell( local.GetTranxPrimaryData, "zip",     arguments.tranx_customer2.zip )>
	<cfset QuerySetCell( local.GetTranxPrimaryData, "phone",   arguments.tranx_customer2.phone )>

</cfif>

<cfif local.GetTranxPrimaryData.recordcount eq 0 or IsDefined("failprimaryorpatronrecordnotfound")>
	<cfset local.tranx_result.Verbiage = "Primary / patron record could not be found">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif IsBoolean( local.GetInvoiceCCData.bypassprocess ) and local.GetInvoiceCCData.bypassprocess>
	<!--- bypass flag is set by accounting whan an IS transaction did occur but internal attempt failed --->
	<!--- This allows user to try again without actually calling processor --->
	<cfset local.tranx_result.Verbiage = "Bypassed">
	<cfset local.tranx_result.approvalcode = "A">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		-- bypass
		insert into dops.invoicetranx
			(sessionid,
			invoicefacid,
			invoicenumber,
			callpk,
			action,
			amount,
			bypassed)
		values
			(<cfqueryparam value="#local.tranx_result.sessionid#" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="#arguments.tranx_invoicefacid#" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="#arguments.tranx_invoicenumber#" cfsqltype="cf_sql_integer" list="no">,
			<cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">,
			<cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">,
			<cfqueryparam value="#local.GetInvoiceCCData.tenderedcc#" cfsqltype="cf_sql_money" list="no">,
			<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">)
		;

		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		;

		delete from dops.invoicetranxbypass
		where  invoicetranxbypass.sessionid = <cfqueryparam value="#arguments.tranx_sessionid#" cfsqltype="cf_sql_varchar" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

<cfelseif ( local.GetInvoiceCCData.receipt neq "" or local.GetInvoiceCCData.guid neq "" ) or IsDefined("failtransactionforsessionidalreadycompleted")>
	<!--- fails in cases where processor returned an approval --->
	<!--- user needs to contact accounting to have the bypass flag set to continue --->
	<cfset local.tranx_result.Verbiage = "Transaction for sessionid already performed. Contact accounting to set bypass flag if needed.">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

</cfif>

<!--- check patron data, if enabled --->
<cfif 0>

	<cfif ( ltrim( rtrim( local.GetTranxPrimaryData.name ) ) eq "" or ltrim( rtrim( local.GetTranxPrimaryData.address ) ) eq "" or ltrim( rtrim( local.GetTranxPrimaryData.city ) ) eq "" or ltrim( rtrim( local.GetTranxPrimaryData.state ) ) eq "" or ltrim( rtrim( local.GetTranxPrimaryData.zip ) ) eq "" ) or IsDefined("failpatronaddress")>
		<cfset local.tranx_result.Verbiage = "Patron / non-patron data not found">

		<cfif ltrim( rtrim( local.GetTranxPrimaryData.name ) ) eq "">
			<cfset local.tranx_result.Verbiage = local.tranx_result.Verbiage & " [NAME]">
		</cfif>

		<cfif ltrim( rtrim( local.GetTranxPrimaryData.address ) ) eq "">
			<cfset local.tranx_result.Verbiage = local.tranx_result.Verbiage & " [ADDRESS]">
		</cfif>

		<cfif ltrim( rtrim( local.GetTranxPrimaryData.city ) ) eq "">
			<cfset local.tranx_result.Verbiage = local.tranx_result.Verbiage & " [CITY]">
		</cfif>

		<cfif ltrim( rtrim( local.GetTranxPrimaryData.state ) ) eq "">
			<cfset local.tranx_result.Verbiage = local.tranx_result.Verbiage & " [STATE]">
		</cfif>

		<cfif ltrim( rtrim( local.GetTranxPrimaryData.zip ) ) eq "">
			<cfset local.tranx_result.Verbiage = local.tranx_result.Verbiage & " [ZIP]">
		</cfif>

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			update dops.invoicetranxcall
			set
				result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
			where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfreturn local.tranx_result>
		<cfabort>

	</cfif>

</cfif>

<cfif IsDefined("failgenericerror")>
	<!--- cause generic error --->
	<cfset local.ttt = ttt>
</cfif>


<!--- products tag format: price::qty::product code::description::flags --->
<!---email receipt options: N=None, A=Approvals only, D=Decines only, Y=all receipts --->

<cfsavecontent variable="local.sendstrXML">
<CFOUTPUT>
	<TranxRequest>
		<GatewayID>#local.GetInvoiceCCData.InternetSecureGatewayID#</GatewayID>
		<Products>#numberformat( abs( local.GetInvoiceCCData.tenderedcc ), "999999999.99" )#::1::#arguments.tranx_sessionid#::THPRD Purchase Invoice<cfif val( local.GetInvoiceCCData.primarypatronid ) gt 0> #val( local.GetInvoiceCCData.primarypatronid )#</cfif><cfif arguments.tranx_mode neq "REAL"><cfif uCase( arguments.tranx_mode ) eq "TESTA">::{TEST}<cfelseif uCase( arguments.tranx_mode ) eq "TESTD" >::{TESTD}</cfif></cfif></Products>
		<xxxName>#XmlFormat( local.GetTranxPrimaryData.name )#</xxxName>
		<xxxAddress>#XmlFormat( local.GetTranxPrimaryData.address )#</xxxAddress>
		<xxxCity>#XmlFormat( local.GetTranxPrimaryData.city )#</xxxCity>
		<xxxState>#XmlFormat( local.GetTranxPrimaryData.state )#</xxxState>
		<xxxZipCode>#XmlFormat( local.GetTranxPrimaryData.zip )#</xxxZipCode>
		<xxxCountry>US</xxxCountry>
		<xxxPhone>#XmlFormat( local.GetTranxPrimaryData.phone )#</xxxPhone>
		<xxxCard_Number>#arguments.tranx_cardnumber#</xxxCard_Number>
		<xxxCCMonth>#local.tranx_cardexpmonth#</xxxCCMonth>
		<xxxCCYear>#local.tranx_cardexpyear#</xxxCCYear>
		<CVV2>#arguments.tranx_ccv#</CVV2>
		<CVV2Indicator>1</CVV2Indicator>
		<xxxTransType>00</xxxTransType>
		<xxxVar1>#arguments.tranx_sessionid#</xxxVar1>
		<xxxVar2>#arguments.tranx_callpk#</xxxVar2>
		<xxxSendCustomerEmailReceipt>N</xxxSendCustomerEmailReceipt>
		<xxxSendMerchantEmailReceipt>N</xxxSendMerchantEmailReceipt>
	</TranxRequest>
</CFOUTPUT>
</cfsavecontent>




<cfset local.tranx_result.Verbiage = "Undefined tranx result: Just before invoicetranx insertion">

<cfquery datasource="#local.funcds#" name="CreateInvoicetranxRecord">
	Select nextval( 'dops.invoicetranx_pk_seq' ) as z
</cfquery>

<cfquery datasource="#local.funcds#" name="CreateInvoicetranxRecord">
	-- make invoice tranx record
	insert into dops.invoicetranx
		(pk,
		sessionid,
		invoicefacid,
		invoicenumber,
		callpk,
		action,
		amount)
	values
		( <cfqueryparam value="#local.CreateInvoicetranxRecord.z#" cfsqltype="cf_sql_integer" list="no">,
		<cfqueryparam value="#local.tranx_result.sessionid#" cfsqltype="cf_sql_varchar" list="no">,
		<cfqueryparam value="#arguments.tranx_invoicefacid#" cfsqltype="cf_sql_varchar" list="no">,
		<cfqueryparam value="#arguments.tranx_invoicenumber#" cfsqltype="cf_sql_integer" list="no">,
		<cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">,
		<cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">,
		<cfqueryparam value="#local.GetInvoiceCCData.tenderedcc#" cfsqltype="cf_sql_money" list="no"> )
</cfquery>

<cfset local.tranx_result.Verbiage = "Undefined tranx result: Just before HTTP call">

<cfif uCase( arguments.tranx_mode ) eq "SIMA" or uCase( arguments.tranx_mode ) eq "SIMD">
	<!--- simulate processor response --->
	<cfset local.tranx_result.proctime = GetTickcount()>
	<cfset local.tmpreceipt = "S" & toString( int( rand("SHA1PRNG") * 10000000000 ) ) & "." & toString( int( rand("SHA1PRNG") * 100 ) ) & "S" & toString( int( rand("SHA1PRNG") * 10 ) )>
	<cfset local.tranx_result.receipt = local.tmpreceipt>
	<cfset local.tranx_result.guid = lCase( CreateUUID() )>

	<cfif uCase( arguments.tranx_mode ) eq "SIMA">
		<cfset local.tranx_result.approvalcode = "A">
		<cfset local.tranx_result.Verbiage = "Simulated sale transaction approved">
	<cfelse>
		<cfset local.tranx_result.approvalcode = "D">
		<cfset local.tranx_result.Verbiage = "Simulated sale transaction declined">
	</cfif>

	<cfif 1>
		<cfset local.request.absoluteprocessorcall = true>
		<cfset local.tranx_result.processorcalled = true>

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			update dops.invoicetranxcall
			set
				processorcalled = <cfqueryparam value="#local.tranx_result.processorcalled#" cfsqltype="cf_sql_bit" list="no">
			where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

	</cfif>

	<cfset local.request.proctime = GetTickcount()>
	<cfset local.request.absoluteproctime = 0>
	<cfset local.LocalStartTime = GetTickcount()>

	<!--- simulate processor --->
	<cfif 1>
		<cfset local.request.absoluteprocessorcall = true>
		<cfset local.tranx_result.processorcalled = true>
	</cfif>

	<cfset local.rn2 = randomize( 1 )>
	<cfset local.rn2 = rand( "SHA1PRNG" ) * 2000>
	<cfset sleep( 500 + rn2 )>

	<cfif 0>
		<cfset sleep( 30000 )>
	</cfif>

	<cfset local.tranx_result.proctime = GetTickcount() - local.tranx_result.proctime>
	<cfset request.absoluteproctime = GetTickcount() - local.LocalStartTime>

<cfelse>
	<cfset request.absoluteprocessorcalled = true>
	<cfset local.tranx_result.processorcalled = true>

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		update dops.invoicetranxcall
		set
			processorcalled = <cfqueryparam value="#local.tranx_result.processorcalled#" cfsqltype="cf_sql_bit" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfif 1>
		<!--- normal processor call --->
		<cfset local.ISURL = local.GetInvoiceCCData.InternetSecureURL>

	<cfelse>
		<!--- test processor call --->
		<cfif 0>
			<cfset local.ISURL = "https://ec2-50-16-239-0.compute-1.amazonaws.com/basic.php">
		<cfelse>
			<cfset local.ISURL = "http://50.16.239.0/basic2.php">
		</cfif>

	</cfif>

	<cfset local.tranx_result.proctime = GetTickcount()>
	<cfset local.LocalStartTime = GetTickcount()>

	<!--- perform processor call --->
	<cfif local.GetInvoiceCCData.InternetSecureProxyIsUsedOnWeb eq "Y">

		<cfhttp
			url="#local.ISURL#"
			method="POST"
			useragent="#CGI.http_user_agent#"
			timeout="#max( 1, local.GetInvoiceCCData.internetsecuretimeout )#"
			throwonerror="no"
			result="local.objGet"
			proxyserver="#local.GetInvoiceCCData.InternetSecureProxy#"
			proxyport="#local.GetInvoiceCCData.InternetSecureProxyPort#">
			<cfhttpparam type="formfield" name="xxxRequestData" value="#local.sendstrXML.Trim()#">
			<cfhttpparam type="formfield" name="xxxRequestMode" value="X">
		</cfhttp>

	<cfelse>

		<cfhttp
			url="#local.ISURL#"
			method="POST"
			useragent="#CGI.http_user_agent#"
			timeout="#max( 1, local.GetInvoiceCCData.internetsecuretimeout )#"
			throwonerror="no"
			result="local.objGet">
			<cfhttpparam type="formfield" name="xxxRequestData" value="#local.sendstrXML.Trim()#">
			<cfhttpparam type="formfield" name="xxxRequestMode" value="X">
		</cfhttp>

	</cfif>

<!--- removed for move to production
	<cfif IsDefined("cookie.failafterprocessorcall") and cookie.failafterprocessorcall eq "1">
		Simulated http call failure.
		<cfabort>
	</cfif>
--->
	<!--- end perform processor call --->
	<cfset local.tranx_result.proctime = GetTickcount() - local.tranx_result.proctime>
	<cfset request.absoluteproctime = GetTickcount() - local.LocalStartTime>
	<cfset local.tranx_result.Verbiage = "Undefined tranx result: Just after HTTP call">
	<cfset request.absoluteproctext = "">

	<CFIF Structkeyexists( local.objGet,"FileContent" )>
		<cfset local.receivestrXML = local.objGet.FileContent>

	<CFELSE>
		<cfset local.receivestrXML = "local.objGet.FileContent Not Defined">

	</CFIF>

	<cfset request.absoluteproctext = local.receivestrXML>


</cfif>

<cfif uCase( arguments.tranx_mode ) eq "SIMA" or uCase( arguments.tranx_mode ) eq "SIMD">

	<cfif uCase( arguments.tranx_mode ) eq "SIMA">

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			update dops.invoicetranx
			set
				receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">,
				guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">,
				amount = <cfqueryparam value="#local.tranx_result.amount#" cfsqltype="cf_sql_money" list="no">
			where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxcall
			set
				receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">,
				guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">,
				result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">,
				page =

				<cfif local.tranx_result.page eq "">
					null
				<cfelse>
					<cfqueryparam value="#local.tranx_result.page#" cfsqltype="cf_sql_varchar" list="no">
				</cfif>

			where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxdist
			set
				receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">,
				guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">
			where  invoicefacid = <cfqueryparam value="#arguments.tranx_invoicefacid#" cfsqltype="cf_sql_varchar" list="no">
			and    invoicenumber = <cfqueryparam value="#arguments.tranx_invoicenumber#" cfsqltype="cf_sql_integer" list="no">
			and    action = <cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">
			and    receipt is null
			and    guid is null
		</cfquery>

		<cfreturn local.tranx_result>
		<cfabort>

	<cfelse>

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			delete from dops.invoicetranx
			where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxcall
			set
				result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
			where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfreturn local.tranx_result>
		<cfabort>

	</cfif>


<cfelseif IsXml( local.receivestrXML )>
	<cfset local.xmlData = XmlParse( local.receivestrXML )>
	<cfset local.tranx_result.proctext = local.receivestrXML>
	<cfset local.tranx_result.Verbiage = "Undefined tranx result: Just before call evaluation">

	<cfif ( IsDefined( "local.xmlData.TranxResponse.Error.XmlText" ) and local.xmlData.TranxResponse.Error.XmlText neq "" )>
		<cfset local.tranx_result.receipt = local.xmlData.TranxResponse.ReceiptNumber.XmlText>
		<cfset request.absolutereceipt = local.tranx_result.receipt>

		<cfset local.tranx_result.page = local.xmlData.TranxResponse.Page.XmlText>
		<cfset request.absolutepage = local.tranx_result.page>

		<cfset local.tranx_result.guid = local.xmlData.TranxResponse.GUID.XmlText>
		<cfset request.absoluteguid = local.tranx_result.guid>

		<cfset local.tranx_result.Verbiage = local.xmlData.TranxResponse.Verbiage.XmlText>
		<cfset request.absoluteVerbiage = local.tranx_result.Verbiage>

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			delete from dops.invoicetranx
			where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxcall
			set
				result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">,
				proctext = <cfqueryparam value="#local.tranx_result.proctext#" cfsqltype="cf_sql_varchar" list="no">,
				proctime = <cfqueryparam value="#local.tranx_result.proctime#" cfsqltype="cf_sql_integer" list="no">
			where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfreturn local.tranx_result>
		<cfabort>

	<cfelseif IsDefined("local.xmlData.TranxResponse.Page.XmlText") and ListFind( "2000,90000", local.xmlData.TranxResponse.Page.XmlText )>
		<!--- processor approved transaction --->
		<cfset local.tranx_result.approvalcode = "A">

		<cfset local.tranx_result.receipt = local.xmlData.TranxResponse.ReceiptNumber.XmlText>
		<cfset request.absolutereceipt = local.tranx_result.receipt>

		<cfset local.tranx_result.page = local.xmlData.TranxResponse.Page.XmlText>
		<cfset request.absolutepage = local.tranx_result.page>

		<cfset local.tranx_result.guid = local.xmlData.TranxResponse.GUID.XmlText>
		<cfset request.absoluteguid = local.tranx_result.guid>

		<cfset local.tranx_result.Verbiage = local.xmlData.TranxResponse.Verbiage.XmlText>
		<cfset request.absoluteVerbiage = local.tranx_result.Verbiage>

		<cfset local.tranx_result.amount = val( local.xmlData.TranxResponse.xxxAmount.XmlText )>

		<cfif 0>
			<!--- set amazon vars replacements --->
			<cfset local.tranx_result.receipt = local.xmlData.TranxResponse.xxxvar3.XmlText>
			<cfset local.tranx_result.guid = local.xmlData.TranxResponse.xxxvar4.XmlText>
		</cfif>

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			update dops.invoicetranx
			set
				receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">,
				guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">,
				page = <cfqueryparam value="#local.tranx_result.page#" cfsqltype="cf_sql_varchar" list="no">,
				amount = <cfqueryparam value="#local.tranx_result.amount#" cfsqltype="cf_sql_money" list="no">
			where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxcall
			set
				receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">,
				guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">,
				result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">,
				page = <cfqueryparam value="#local.tranx_result.page#" cfsqltype="cf_sql_varchar" list="no">,
				proctext = <cfqueryparam value="#local.tranx_result.proctext#" cfsqltype="cf_sql_varchar" list="no">,
				proctime = <cfqueryparam value="#local.tranx_result.proctime#" cfsqltype="cf_sql_integer" list="no">
			where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxdist
			set
				receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">,
				guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">
			where  invoicefacid = <cfqueryparam value="#arguments.tranx_invoicefacid#" cfsqltype="cf_sql_varchar" list="no">
			and    invoicenumber = <cfqueryparam value="#arguments.tranx_invoicenumber#" cfsqltype="cf_sql_integer" list="no">
			and    action = <cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">
			and    receipt is null
			and    guid is null
		</cfquery>

	<cfelseif IsDefined( "local.xmlData.TranxResponse.Page.XmlText" ) and local.xmlData.TranxResponse.Page.XmlText neq "">
		<!--- processor declined transaction --->
		<cfset local.tranx_result.receipt = local.xmlData.TranxResponse.ReceiptNumber.XmlText>
		<cfset request.absolutereceipt = local.tranx_result.receipt>

		<cfset local.tranx_result.page = local.xmlData.TranxResponse.Page.XmlText>
		<cfset request.absolutepage = local.tranx_result.page>

		<cfset local.tranx_result.guid = local.xmlData.TranxResponse.GUID.XmlText>
		<cfset request.absoluteguid = local.tranx_result.guid>

		<cfset local.tranx_result.Verbiage = local.xmlData.TranxResponse.Verbiage.XmlText>
		<cfset request.absoluteVerbiage = local.tranx_result.Verbiage>

		<cfif 0>
			<!--- set amazon vars replacements --->
			<cfset local.tranx_result.receipt = local.xmlData.TranxResponse.xxxvar3.XmlText>
			<cfset request.absolutereceipt = local.tranx_result.receipt>

			<cfset local.tranx_result.guid = local.xmlData.TranxResponse.xxxvar4.XmlText>
			<cfset request.absoluteguid = local.tranx_result.guid>

		</cfif>

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			-- decline
			delete from dops.invoicetranx
			where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxcall
			set
				receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">,
				guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">,
				page = <cfqueryparam value="#local.tranx_result.page#" cfsqltype="cf_sql_varchar" list="no">,
				proctext = <cfqueryparam value="#local.tranx_result.proctext#" cfsqltype="cf_sql_varchar" list="no">,
				proctime = <cfqueryparam value="#local.tranx_result.proctime#" cfsqltype="cf_sql_integer" list="no">
			where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfreturn local.tranx_result>
		<cfabort>

	<cfelse>
		<cfset local.tranx_result.Verbiage = "Unknown xmlData error">

		<cfif IsDefined( "local.xmlData.TranxResponse.ReceiptNumber.XmlText" ) and local.xmlData.TranxResponse.ReceiptNumber.XmlText neq "">
			<cfset local.tranx_result.receipt = local.xmlData.TranxResponse.ReceiptNumber.XmlText>
			<cfset request.absolutereceipt = local.tranx_result.receipt>
		</cfif>

		<cfif IsDefined( "local.xmlData.TranxResponse.Page.XmlText" ) and local.xmlData.TranxResponse.Page.XmlText neq "">
			<cfset local.tranx_result.page = local.xmlData.TranxResponse.Page.XmlText>
			<cfset request.absolutepage = local.tranx_result.page>
		</cfif>

		<cfif IsDefined( "local.xmlData.TranxResponse.GUID.XmlText" ) and local.xmlData.TranxResponse.GUID.XmlText neq "">
			<cfset local.tranx_result.guid = local.xmlData.TranxResponse.GUID.XmlText>
			<cfset request.absoluteguid = local.tranx_result.guid>
		</cfif>

		<cfif IsDefined( "local.xmlData.TranxResponse.Verbiage.XmlText" ) and local.xmlData.TranxResponse.Verbiage.XmlText neq "">
			<cfset local.tranx_result.Verbiage = local.xmlData.TranxResponse.Verbiage.XmlText>
			<cfset request.absoluteVerbiage = local.tranx_result.Verbiage>
		</cfif>

		<cfquery datasource="#local.funcds#" name="UpdateTranx">
			delete from dops.invoicetranx
			where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
			;

			update dops.invoicetranxcall
			set
				proctime = <cfqueryparam value="#local.tranx_result.proctime#" cfsqltype="cf_sql_integer" list="no">

				<cfif IsDefined("local.tranx_result.receipt") and local.tranx_result.receipt neq "">
					, receipt = <cfqueryparam value="#local.tranx_result.receipt#" cfsqltype="cf_sql_varchar" list="no">
				</cfif>

				<cfif IsDefined("local.tranx_result.page") and local.tranx_result.page neq "">
					, page = <cfqueryparam value="#local.tranx_result.page#" cfsqltype="cf_sql_varchar" list="no">
				</cfif>

				<cfif IsDefined("local.tranx_result.Verbiage") and local.tranx_result.Verbiage neq "">
					, result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">
				</cfif>

				<cfif IsDefined("local.tranx_result.guid") and local.tranx_result.guid neq "">
					, guid = <cfqueryparam value="#local.tranx_result.guid#" cfsqltype="cf_sql_varchar" list="no">
				</cfif>

				<cfif IsDefined("local.tranx_result.proctext") and local.tranx_result.proctext neq "">
					, proctext = <cfqueryparam value="#local.tranx_result.proctext#" cfsqltype="cf_sql_varchar" list="no">
				</cfif>

			where pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfreturn local.tranx_result>
		<cfabort>

	</cfif>


<cfelseif FindNoCase( "CONNECTION FAILURE", local.receivestrXML ) gt 0>
	<cfset local.tranx_result.Verbiage = "Declined due to connection failure">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		delete from dops.invoicetranx
		where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		;

		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">,
			proctime = <cfqueryparam value="#local.tranx_result.proctime#" cfsqltype="cf_sql_integer" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>


<cfelseif FindNoCase( "CONNECTION TIMEOUT", local.receivestrXML ) gt 0>
	<cfset local.tranx_result.Verbiage = "Declined due to connection timeout">

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		delete from dops.invoicetranx
		where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		;

		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">,
			proctime = <cfqueryparam value="#local.tranx_result.proctime#" cfsqltype="cf_sql_integer" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>


<cfelse>
	<cfset local.tranx_result.Verbiage = "Invalid request: " & local.receivestrXML>

	<cfquery datasource="#local.funcds#" name="UpdateTranx">
		delete from dops.invoicetranx
		where  callpk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
		;

		update dops.invoicetranxcall
		set
			result = <cfqueryparam value="#local.tranx_result.Verbiage#" cfsqltype="cf_sql_varchar" list="no">,
			proctime = <cfqueryparam value="#local.tranx_result.proctime#" cfsqltype="cf_sql_integer" list="no">
		where  pk = <cfqueryparam value="#local.tranx_result.callpk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<cfreturn local.tranx_result>
	<cfabort>

</cfif>

<cfreturn local.tranx_result>

</cffunction>












<cffunction output="true" name="invoicetranxprecheck" description="invoice tranx precheck" returntype="string">
<!---
returns result as string
if result is numeric, precheck was sucessful and returned the needed tranxpk for later ops
otherwise, if a string, then precheck failed with error as string--->
<cfargument name="ccprimary" type="numeric" required="true">
<cfargument name="sessionid" type="string" required="true">
<cfargument name="cctendered" type="numeric" required="true">
<cfargument name="cardholderfirstname" type="string" required="false" default="">
<cfargument name="cardholderlastname" type="string" required="false" default="">
<cfargument name="cardholderphone" type="string" required="false" default="">
<cfargument name="callcomment" type="string" required="false" default="">

<!--- declare vars --->
<cfset var result = "">
<cfset var Getproceedpk = "">
<cfset var insertinvoicetranxsubmit = "">
<cfset var UpdateSubmit = "">
<cfset var thistranxpk = 0>
<!--- end declare vars --->

<cfoutput>

<cfif arguments.cctendered gt 0>

	<cfquery datasource="#application.dopsds#" name="local.Getproceedpk">
		select   nextval( 'dops.invoicetranxsubmit_pk_seq' ) as pk
	</cfquery>

	<cfquery datasource="#application.dopsds#" name="insertinvoicetranxsubmit">
		select   dops.insertinvoicetranxsubmit( <cfqueryparam value="#local.Getproceedpk.pk#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#arguments.ccprimary#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#arguments.sessionid#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no"> ) as status
	</cfquery>

	<!---
	insertinvoicetranxsubmit.status codes:

	G = Submission is granted to continue
	T = Throttled submission
	C = Specified session has an open processor call
	K = has call w/o acknowledgement
	B = InternetSecureIsUsed or InternetSecureIsUsedOnWeb (if isonweb is true) was not used
	R = Recent page submission being less than 30 seconds
	V = Specified session not valid
	A = Specified session was approved
	P = Specified session has a problem
	--->

	<cfif local.insertinvoicetranxsubmit.status eq "T">

		<cfsavecontent variable="result">
		Processor is busy. Please wait at least 30 seconds then go back and try again. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	<cfelseif local.insertinvoicetranxsubmit.status eq "R">

		<cfsavecontent variable="result">
		A recent attempt was detected. Please wait at least 30 seconds then go back and try again. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	<cfelseif local.insertinvoicetranxsubmit.status eq "C">

		<cfsavecontent variable="result">
		We have attempted to process your transaction and we are still waiting to hear back from the bank processor. Please go back, wait 1 minute and try again. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	<cfelseif local.insertinvoicetranxsubmit.status eq "K">

		<cfsavecontent variable="result">
		Processor response is still pending. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	<cfelseif local.insertinvoicetranxsubmit.status eq "V">

		<cfsavecontent variable="result">
		It appears that this transaction has already been either completed or cancelled. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	<cfelseif local.insertinvoicetranxsubmit.status eq "A">

		<!--- this one should never happen as a new sessionid will be created upon approval and caught before here, but just in case --->
		<cfsavecontent variable="result">
		It appears payment for this session was approved but the session itself has not finished or the browser was clicked back. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	<cfelseif local.insertinvoicetranxsubmit.status eq "P">

		<!--- stop the patron from any further attempts --->
		<cfsavecontent variable="result">
		Payment may have already been made. Call THPRD for assistance. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	<cfelseif local.insertinvoicetranxsubmit.status eq "B">
		<!--- do nothing: being bypassed --->

	<cfelseif local.insertinvoicetranxsubmit.status eq "G">
		<!--- do nothing: go ahead and process --->

	<cfelse>

		<cfsavecontent variable="result">
		Could not determine action to take. Contact THPRD. Response Code: #local.insertinvoicetranxsubmit.status#
		</cfsavecontent>

		<cfreturn local.result>

	</cfif>

	<CFIF IsDefined( "local.insertinvoicetranxsubmit.status" )>

		<cfif find( local.insertinvoicetranxsubmit.status, "BGN" ) eq 0>
			<!--- stop as not ready to go forward --->
			<cfsavecontent variable="result">
			Something went wrong. Go back and try again after a short wait. Contact THPRD if problem persists. Response Code: #local.insertinvoicetranxsubmit.status#
			</cfsavecontent>

			<cfreturn local.result>
		</cfif>

	</CFIF>

	<cftransaction isolation="REPEATABLE_READ" action="BEGIN">
		<!---OpenTranxCall params:
		<cfargument name="tranx_node" type="string" required="Yes">
		<cfargument name="tranx_ccfunds" type="numeric" required="Yes">
		<cfargument name="tranx_primarypatronid" type="numeric" required="yes">
		<cfargument name="tranx_sessionid" type="string" required="Yes">
		<cfargument name="tranx_action" type="string" required="Yes">
		<cfargument name="tranx_submitpk" type="numeric" required="yes">
		<cfargument name="tranx_cardholderfirstname" type="string" required="no" default="">
		<cfargument name="tranx_cardholderlastname" type="string" required="no" default="">
		<cfargument name="tranx_cardholderphone" type="string" required="no" default="">
		<cfargument name="tranx_callcomment" type="string" required="no" default="">--->

		<cfset local.thistranxpk = OpenTranxCall(
			"W1",
			arguments.cctendered,
			arguments.ccprimary,
			arguments.sessionid,
			"S",
			local.Getproceedpk.pk,
			arguments.cardholderfirstname,
			arguments.cardholderlastname,
			arguments.cardholderphone,
			arguments.callcomment )>

		<cfif local.thistranxpk eq 0>
			<cfsavecontent variable="result">
			Error in determining tranx code. Go back and try again or contact THPRD Information Services.
			</cfsavecontent>

			<cfreturn local.result>
		</cfif>

	</cftransaction>

	<!--- update call with result --->
	<cfquery datasource="#application.dopsds#" name="UpdateSubmit">
		update   dops.invoicetranxsubmit
		set
			action = <cfqueryparam value="G" cfsqltype="cf_sql_char" maxlength="1" list="no">
		where    pk = <cfqueryparam value="#local.Getproceedpk.pk#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

	<!--- return Getproceedpk.pk as string --->
	<cfreturn '#local.thistranxpk#'>

<cfelse>
	<cfreturn "0">
</cfif>

</cfoutput>

</cffunction>
<!--- end cffunction invoicetranxprecheck() definition --->



</cfcomponent>