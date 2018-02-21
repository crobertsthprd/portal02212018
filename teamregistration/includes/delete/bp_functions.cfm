<!--- functions: place correctly: just here to get this going --->
<cffunction name="getccreference" output="yes" returntype="String">
<cfargument name="currentsessionid" required="yes" type="string">
<cfargument name="callpk" required="yes" type="numeric">
<cfargument name="servername" required="yes" type="string">

<!--- create credit call reference for insertion into processor --->
<cfset var local.reference = "">
<cfset var local.GetCallPK = "">

<!--- build reference --->
<cfset local.reference = "R" & numberformat( arguments.callpk, "0000000000")>

<cfif arguments.servername eq "DEV">
	<cfset local.reference = local.reference & "-D-">
<cfelseif arguments.servername eq "DB">
	<cfset local.reference = local.reference & "-P-">
<cfelse>
	<cfreturn ""><!--- error so return nothing --->
</cfif>

<cfset local.reference = local.reference & arguments.currentsessionid>
<!--- end build reference --->

<cfreturn local.reference>
</cffunction>




<!--- final checks function: returns "OK" if everything is correct. If not, returns error as string. --->
<cffunction name="finalchecks" output="Yes" returntype="string">
<cfargument name="thisfacid" type="string" required="true">
<cfargument name="thisinvoice" type="numeric" required="true">
<cfset var Check4InvoiceWasCreated = "" />
<cfset var GetGLE = "" />
<cfset var GetInvoiceInvoiceNet = "" />
<cfset var GetOCChecks = "" />
<cfset var GetOCErrorRecords = "" />
<cfset var GetTXChecks = "" />

<cfquery name="local.Check4InvoiceWasCreated" datasource="#application.dopsds#">
	select   pk
	from     dops.invoice
	where    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
	and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
	limit    1
</cfquery>

<!--- no invoice created so return nothing --->
<cfif local.Check4InvoiceWasCreated.recordcount eq 0>
	<cfreturn "OK">
</cfif>

<cfquery name="local.GetGLE" datasource="#application.dopsds#">
	select   dops.getglerror( <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER"> ) as gle
</cfquery>

<cfif local.GetGLE.recordcount eq 1 and dollarRound( GetGLE.gle ) neq 0>
	<cfreturn "GL error of was detected for proposed invoice during final check">
	<cfabort>
</cfif>

<!--- check for negative invoice balance --->
<cfquery name="local.GetInvoiceInvoiceNet" datasource="#application.dopsds#">
	select   invoicenet,
	         invoicetype
	from     dops.invoicenet
	where    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
	and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
</cfquery>

<cfif local.GetInvoiceInvoiceNet.invoicenet eq "">
	<cfreturn "Invoice balance resulted in a blank value.">
	<cfabort>
</cfif>

<cfif local.GetInvoiceInvoiceNet.recordcount eq 1 and dollarRound( local.GetInvoiceInvoiceNet.invoicenet ) lt 0>
	<cfreturn "Invoice balance resulted in a negative value">
	<cfabort>
</cfif>

<!--- verify oc usage --->
<cfif local.GetInvoiceInvoiceNet.recordcount eq 1 and IsDefined("othercreditused") and IsDefined("OtherCreditData") and othercreditused gt 0 and OtherCreditData is not "">

	<cfquery name="local.GetOCChecks" datasource="#application.dopsds#">
		select   #decimalformat( form.othercreditused )# as othercreditused, (

		SELECT   coalesce( sum( credit ), 0 )
		FROM     dops.othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistsum, (

		SELECT   coalesce( sum( debit ), 0 )
		FROM     dops.othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocusedsum, (

		SELECT   dops.getocbalance( othercredithistorysums.cardid, othercredithistorysums.primarypatronid )
		FROM     dops.othercredithistorysums
		where

		<cfif IsNumeric( form.OtherCreditData ) and form.OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="#form.OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#arguments.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as cardusedbalance, (

		SELECT   faapptype
		FROM     dops.othercredithistorysums
		where

		<cfif IsNumeric( form.OtherCreditData ) and form.OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="#form.OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#arguments.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as faapptype

	</cfquery>

	<!--- check for negative value --->
	<cfif dollarRound( val( GetOCChecks.cardusedbalance ) ) lt 0>
		<strong>Other Credit balance resulted in a negative value: #dollarformat( GetOCChecks.cardusedbalance )#. Go back and try again. If problem persists, contact IS.</strong><BR><BR>
		<cfinclude template="/Common/BackButton.cfm">

		<cfif servername is "DEV" or debug_user is 22952>
			<cfdump var="#GetOCChecks#" label="GetOCChecks">
			<cfinclude template="/Common/displayallinvoicetables.cfm">
			<cfinclude template="/Common/displaymemory.cfm">
		</cfif>

		<cfabort>

	</cfif>
	<!--- end check for negative value --->


	<!--- verify oc dist--->
	<cfif not IsDefined("DistributionOnly")>

		<cfif GetOCChecks.recordcount is 1 and dollarRound( val( GetOCChecks.ocusedsum ) ) neq dollarRound( val( GetOCChecks.othercreditused ) )>
			<strong>Other Credit Used calculation Error.<BR><BR>

			<cfif IsDefined("request.errormsg")>
				#request.errormsg#
			<cfelse>
				Expected #decimalformat( GetOCChecks.othercreditused )#, found #decimalformat( GetOCChecks.ocusedsum )#
			</cfif>

			<BR><BR>

			Go back and try checkout again or contact IS if problem persists.</strong><BR><br>
			<cfinclude template="/Common/BackButton.cfm">

			<cfif servername is "DEV" or debug_user is 22952>
				<cfdump var="#GetOCChecks#" label="GetOCChecks">
				<cfinclude template="/Common/displayallinvoicetables.cfm">
				<cfinclude template="/Common/displaymemory.cfm">
			</cfif>

			<cfabort>

		</cfif>

	</cfif>

	<cfif GetOCChecks.recordcount is 1 and dollarRound( val( GetOCChecks.ocdistsum ) ) neq dollarRound( val( othercreditused ) )>
		<strong>Other Credit Distribution Error.<BR><BR>

		<cfif IsDefined( "request.errormsg" )>
			#request.errormsg#
		<cfelse>
			Found used OC of #decimalformat( GetOCChecks.othercreditused )# vs. OC dist sum of #decimalformat( GetOCChecks.ocdistsum )#.
		</cfif>

		<br><br>

		<cfquery name="local.GetOCErrorRecords" datasource="#application.dopsds#">
			SELECT   *
			FROM     dops.othercreditdist
			WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
		</cfquery>

		<cfif 0>
			<cfdump var="#local.GetOCErrorRecords#" label="Raw OC dist records">
		</cfif>

		<BR><BR>
		Go back and try checkout again or contact IS if problem persists.</strong><BR><br>
		<cfinclude template="/Common/BackButton.cfm">

		<cfif servername is "DEV" or debug_user is 22952>
			<cfdump var="#GetOCChecks#" label="GetOCChecks">
			<cfinclude template="/Common/displayallinvoicetables.cfm">
			<cfinclude template="/Common/displaymemory.cfm">
		</cfif>

		<cfabort>
	</cfif>

	<!--- end verify oc dist--->


	<!--- verify tx dist--->
	<!--- note: dops.invoicetranx is NOT checked as may not be created at this time due to delayed cc processing --->
	<!--- only distribution is checked against specified amount from payment form as form.tenderedcharge --->
	<cfif IsDefined("form.tenderedcharge") and form.tenderedcharge gt 0 and 1>

		<cfquery name="local.GetTXChecks" datasource="#application.dopsds#">
			SELECT   coalesce( sum( amount ), 0 ) as txdistsum
			FROM     dops.invoicetranxdist
			WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
			and      amount > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
		</cfquery>

		<cfif GetTXChecks.txdistsum neq form.tenderedcharge>
			<strong>TX Distribution Error.<BR><BR>

			<cfif IsDefined("request.errormsg")>
				#request.errormsg#
			<cfelse>
				Expected #decimalformat( form.tenderedcharge )#, found #decimalformat( GetTXChecks.txdistsum )#.
			</cfif>

			<br><br>

			Go back and try checkout again or contact IS if problem persists.</strong><BR><br>
			<cfinclude template="/Common/BackButton.cfm">

			<cfif servername is "DEV" or IsDefined("debug_user") and debug_user is 22952>
				<cfdump var="#GetTXChecks#" label="GetTXChecks">
				<cfinclude template="/Common/displayallinvoicetables.cfm">
				<cfinclude template="/Common/displaymemory.cfm">
			</cfif>

			<cfabort>
		</cfif>

	</cfif>
	<!--- end verify tx dist--->

</cfif>
<!--- end verify oc usage --->

<cfif IsDefined( "arguments.performoctests" )>
	<cfquery name="local.GetOCChecks" datasource="#application.dopsds#">
		select   (

		SELECT   coalesce( sum( credit ), 0 )
		FROM     dops.othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistcreditsum, (

		SELECT   coalesce( sum( debit ), 0 )
		FROM     dops.othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistdebitsum, (

		SELECT   coalesce( sum( credit ), 0 )
		FROM     dops.othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as occreditsum, (

		SELECT   coalesce( sum( debit ), 0 )
		FROM     dops.othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdebitsum
	</cfquery>

	<cfif GetOCChecks.recordcount eq 1>

		<cfif GetOCChecks.ocdistcreditsum neq GetOCChecks.ocdebitsum>
			ERROR: OC dist credit of #decimalformat( GetOCChecks.ocdistcreditsum )# did not match OC debit of #decimalformat( GetOCChecks.ocdebitsum )#<BR>
		</cfif>

		<cfif GetOCChecks.ocdistdebitsum neq GetOCChecks.occreditsum>
			ERROR: OC dist debit of #decimalformat( GetOCChecks.ocdistdebitsum )# did not match OC credit of #decimalformat( GetOCChecks.occreditsum )#<BR>
		</cfif>

	</cfif>

</cfif>
<!--- end invoice was created --->

<cfreturn "OK">
</cffunction>
<!--- end final checks --->




<cffunction name="GetNextPRC" output="Yes" returntype="numeric">
<cfset var GetNextPRC = "" />

<cfquery name="local.GetNextPRC" datasource="#application.dopsds#">
	Select nextval('"dops"."prc_seq"') as tmp
</cfquery>

<cfreturn local.GetNextPRC.tmp>

</cffunction>




<!--- function get user data defined --->
<cffunction output="yes" name="GetBPUserData" description="BridgePay User Fetch routine">
<cfset var BridgePayUserParams = "">
<cfset var BridgePayUserStruct = "">

<cfquery name="local.BridgePayUserParams" datasource="#application.dopsds#">
	select   (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayUserID" cfsqltype="cf_sql_varchar" list="no"> ) as bpuserid, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayPW" cfsqltype="cf_sql_varchar" list="no"> ) as bppassword, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayMerchantCode" cfsqltype="cf_sql_varchar" list="no"> ) as bpMerchantCode, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayMerchantAccountCode" cfsqltype="cf_sql_varchar" list="no"> ) as bpMerchantAccountCode
</cfquery>

<cfif local.BridgePayUserParams.recordcount eq 0 or
	local.BridgePayUserParams.bpuserid eq "" or
	local.BridgePayUserParams.bppassword eq "" or
	local.BridgePayUserParams.bpMerchantCode eq "" or
	local.BridgePayUserParams.bpMerchantAccountCode eq "">
	<cfreturn "ERROR: Data returned from fetching BridgePay user params failed. Contact IS.">
	<cfabort>
</cfif>

<cfset local.BridgePayUserStruct = StructNew()>
<cfset StructInsert( local.BridgePayUserStruct, "BPUserID", local.BridgePayUserParams.bpuserid )>
<cfset StructInsert( local.BridgePayUserStruct, "BPPassword", local.BridgePayUserParams.bppassword )>
<cfset StructInsert( local.BridgePayUserStruct, "BpMerchantCode", local.BridgePayUserParams.bpMerchantCode )>
<cfset StructInsert( local.BridgePayUserStruct, "BPMerchantAccountCode", local.BridgePayUserParams.bpMerchantAccountCode )>
<cfreturn local.BridgePayUserStruct>
</cffunction>




<cffunction name="GetNextInvoiceBP" returntype="numeric">
<cfset gn = "" />

<!--- grabs the next TEMPORARY invoice number (aka, invoice.pk sequence ) --->
<cfquery datasource="#application.dopsds#" name="local.gn">
	SELECT dops.getnextinvoice( '' ) as nextinvoice
</cfquery>

<cfreturn local.gn.nextinvoice>
</cffunction>

<!--- end function get user data defined --->
