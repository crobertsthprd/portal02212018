<BR><BR><strong>All operations completed. Rolled back for testing.</strong>
<a href="javascript:history.go(-1);"><strong><< Go back.</strong></a>
<br><br>

<cfoutput>

<cfquery datasource="#application.dopsds#" name="GetInvoiceTables">
	SELECT   tables.table_schema, 
	         tables.table_name 
	FROM     information_schema.columns columns
	         INNER JOIN information_schema.tables tables ON columns.table_catalog=tables.table_catalog AND columns.table_schema=tables.table_schema AND columns.table_name=tables.table_name 
	WHERE    columns.column_name = <cfqueryparam value="invoicefacid" cfsqltype="CF_SQL_VARCHAR"> 
	AND      tables.table_type = <cfqueryparam value="BASE TABLE" cfsqltype="CF_SQL_VARCHAR"> 
	and      columns.table_name != <cfqueryparam value="classcredits" cfsqltype="CF_SQL_VARCHAR">
	GROUP BY tables.table_schema, tables.table_name 
	ORDER BY tables.table_schema, tables.table_name
</cfquery>

<cfloop query="GetInvoiceTables">

	<cfquery datasource="#application.dopsds#" name="GetInvoiceTablesData">
		SELECT   *
		from     "#table_schema#"."#table_name#"
		where    invoicefacid = <cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#nextinvoice#" cfsqltype="CF_SQL_INTEGER">
	</cfquery>

	<cfif GetInvoiceTablesData.recordcount gt 0>
		<cfdump var="#GetInvoiceTablesData#" label="#GetInvoiceTablesData.recordcount# records for #uCase(table_schema)#.#uCase(table_name)#">
	<cfelse>
		<strong>No records for <cfoutput>#table_schema#.#table_name#</cfoutput></strong><BR><BR>

	</cfif>

</cfloop>

</cfoutput>

<cfabort>
