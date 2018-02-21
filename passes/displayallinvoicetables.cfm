<!--- autodoc
displays data from all tables that contain an invoicefacid and invoicenumber field
used to debug invoices ot when user uses a "test" option on a page
autodoc --->

<BR>

<cfoutput>

<!--- display invoicenet.invoicenet --->
<cfif IsDefined("nextinvoice")>

	<cfquery datasource="#application.dopsds#" name="getinvoicenet">
		SELECT   invoicenet,
		         primarypatronid
		from     invoicenet
		where    invoicefacid  = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="CF_SQL_INTEGER">
	</cfquery>

	<strong>dops.primaryaccountbalance( #getinvoicenet.primarypatronid# ) reported ending account balance of #decimalformat( getinvoicenet.invoicenet )#</strong>
	<BR><BR>
</cfif>


<cfif IsDefined("variables.nextinvoice")>

	<cfquery datasource="#application.dopsds#" name="GetInvoiceTables">
		SELECT   tables.table_schema,
		         tables.table_name,
		         columns.column_name
		FROM     information_schema.columns columns
		         INNER JOIN information_schema.tables tables ON columns.table_catalog=tables.table_catalog AND columns.table_schema=tables.table_schema AND columns.table_name=tables.table_name
		WHERE    columns.column_name = <cfqueryparam value="invoicenumber" cfsqltype="CF_SQL_VARCHAR">
		         --columns.column_name in ('invoicefacid', 'facid')
		AND      tables.table_type = <cfqueryparam value="BASE TABLE" cfsqltype="CF_SQL_VARCHAR">
		and      columns.table_name != <cfqueryparam value="classcredits" cfsqltype="CF_SQL_VARCHAR">
		and      tables.table_schema != <cfqueryparam value="testdops" cfsqltype="cf_sql_varchar" list="no">
		GROUP BY tables.table_schema, tables.table_name, columns.column_name
		ORDER BY tables.table_schema, tables.table_name
	</cfquery>

	<!--- <cfdump var="#GetInvoiceTables#" label="GetInvoiceTables"> --->




	<cfloop query="GetInvoiceTables">
		<cfset f = "">
		<cfset v = "">

		<cfif lCase(column_name) is "facid">
			<cfset v = evaluate("#facid#")>
			<cfset f = "facid">

		<cfelseif lCase(column_name) is "invoicefacid">
			<cfset v = evaluate("WWW")>
			<cfset f = "invoicefacid">

		</cfif>

		<cfquery datasource="#application.dopsds#" name="GetInvoiceTablesData">
			SELECT   *
			from     "#table_schema#"."#table_name#"
			where    <cfif table_name is "dropinhistory">facid<cfelse>invoicefacid</cfif> = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#nextinvoice#" cfsqltype="CF_SQL_INTEGER">
		</cfquery>

		<cfif IsDefined("GetInvoiceTablesData.recordcount") and GetInvoiceTablesData.recordcount gt 0>
			<strong>#table_schema#.#table_name# records (#GetInvoiceTablesData.recordcount#):</strong><BR>
			<cfdump var="#GetInvoiceTablesData#" label="#GetInvoiceTablesData.recordcount# records for #uCase(table_schema)#.#uCase(table_name)#">

		<cfelse>
			<strong>#table_schema#.#table_name# records: None</strong><BR>

		</cfif>

	</cfloop>

</cfif>

</cfoutput>
