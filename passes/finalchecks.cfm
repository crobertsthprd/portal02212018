<!--- autodoc
performs final checks on checkout pages
set variable errormsg to error, then follows thru
look for variables.error being defined to determine error
all form elements herein are assumed to be defined
autodoc --->

<cfoutput>

<cfquery name="GetGLE" datasource="#application.dopsds#">
	select   dops.getglerror( <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER"> ) as gle
</cfquery>

<cfif GetGLE.recordcount eq 1 and dollarRound( GetGLE.gle ) neq 0>
	<cfset errormsg = "GL error was detected for proposed invoice during final check.">
</cfif>

<cfif not IsDefined("variables.errormsg")>
	<!--- check for negative invoice balance --->
	<cfquery name="GetInvoiceInvoiceNet" datasource="#application.dopsds#">
		select   invoicenet,
		         invoicetype
		from     dops.invoicenet
		where    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">
	</cfquery>

	<cfif GetInvoiceInvoiceNet.invoicenet eq "">
		<cfset errormsg = "Invoice balance resulted in a blank value.">
	</cfif>

	<cfif not IsDefined("variables.errormsg")>

		<cfif GetInvoiceInvoiceNet.recordcount eq 1 and dollarRound( GetInvoiceInvoiceNet.invoicenet ) lt 0>
			<cfset errormsg = "Invoice balance resulted in a negative value.">
		</cfif>

		<!--- verify oc usage --->
		<cfif not IsDefined("variables.errormsg")>

			<cfif GetInvoiceInvoiceNet.recordcount eq 1 and IsDefined("form.tenderedoc") and form.tenderedoc gt 0>

				<cfquery name="GetOCChecks" datasource="#application.dopsds#">
					select   #decimalformat( form.tenderedoc )# as othercreditused, (

					SELECT   coalesce( sum( credit ), 0 )
					FROM     dops.othercreditdistview
					WHERE    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
					and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistsum, (

					SELECT   coalesce( sum( debit ), 0 )
					FROM     dops.othercreditdatahistory
					WHERE    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
					and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocusedsum, (

					SELECT   dops.getocbalance( othercredithistorysums.cardid, othercredithistorysums.primarypatronid )
					FROM     dops.othercredithistorysums
					where    cardid = <cfqueryparam value="#form.occardid#" cfsqltype="CF_SQL_INTEGER"> ) as cardusedbalance, (

					SELECT   faapptype
					FROM     dops.othercredithistorysums
					where    cardid = <cfqueryparam value="#form.occardid#" cfsqltype="CF_SQL_INTEGER"> ) as faapptype
				</cfquery>

				<!--- check for negative value --->
				<cfif dollarRound( val( GetOCChecks.cardusedbalance ) ) lt 0>
					<cfset errormsg = "Gift Card balance resulted in a negative value.">
				</cfif>
				<!--- end check for negative value --->

				<cfif not IsDefined("variables.errormsg")>
					<!--- verify oc dist--->
					<cfif GetOCChecks.recordcount eq 1 and dollarRound( val( GetOCChecks.ocusedsum ) ) neq dollarRound( val( GetOCChecks.othercreditused ) ) >
						<cfset errormsg = "Gift Card calculation Error was detected.">
					</cfif>

					<cfif GetOCChecks.recordcount eq 1 and dollarRound( val( GetOCChecks.ocdistsum ) ) neq dollarRound( val( form.tenderedoc ) ) >
						<cfset errormsg = "Gift card Distribution Error was detected.">
					</cfif>
					<!--- end verify oc dist--->


					<!--- verify tx dist--->
					<!--- note: dops.invoicetranx is NOT checked as may not be created at this time due to delayed cc processing --->
					<!--- only distribution is checked against specified amount from payment form as form.adjustednetdue --->
					<cfif form.adjustednetdue gt 0>

						<cfquery name="GetTXChecks" datasource="#application.dopsds#">
							SELECT   coalesce( sum( amount ), 0 ) as txdistsum
							FROM     dops.invoicetranxdist
							WHERE    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
							and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">
							and      amount > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
						</cfquery>

						<cfif GetTXChecks.recordcount eq 0 or GetTXChecks.txdistsum neq form.adjustednetdue>
							<cfset errormsg = "Credit card distribution error was detected.">
						</cfif>

					</cfif>
					<!--- end verify tx dist--->
				</cfif>

			</cfif>

		</cfif>
		<!--- end verify oc usage --->

		<!--- oc checks --->
		<cfif not IsDefined("variables.errormsg")>

			<cfquery name="GetOCChecks" datasource="#application.dopsds#">
				select   (

				SELECT   coalesce( sum( credit ), 0 )
				FROM     dops.othercreditdistview
				WHERE    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
				and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistcreditsum, (

				SELECT   coalesce( sum( debit ), 0 )
				FROM     dops.othercreditdistview
				WHERE    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
				and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistdebitsum, (

				SELECT   coalesce( sum( credit ), 0 )
				FROM     dops.othercreditdatahistory
				WHERE    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
				and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as occreditsum, (

				SELECT   coalesce( sum( debit ), 0 )
				FROM     dops.othercreditdatahistory
				WHERE    invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
				and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdebitsum
			</cfquery>

			<cfif GetOCChecks.recordcount eq 1>

				<cfif GetOCChecks.ocdistcreditsum neq GetOCChecks.ocdebitsum>
					<cfset errormsg = "Gift card distribution credit did not match debit.">
				</cfif>

				<cfif not IsDefined("variables.errormsg")>

					<cfif GetOCChecks.ocdistdebitsum neq GetOCChecks.occreditsum>
						<cfset errormsg = "Gift card distribution debit did not match credit.">
					</cfif>

				</cfif>

			</cfif>

		</cfif>
		<!--- end oc checks --->

	</cfif>

</cfif>

</cfoutput>
