<html>
<head>
	<title>Pass Purchase Step 2</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>

<cfoutput>

<cfif not IsDefined("cookie.uid")>
	<cfabort>
</cfif>

<cfif not IsDefined("url.passtype") or not IsDefined("url.passspan")>
	<cfabort>
</cfif>

<cfquery datasource="#application.slavedopsds#" name="GetHousehold">
	SELECT   sessionpatrons.primarypatronid,
	         patrons.patronlookup,
	         sessionpatrons.relationtype,
	         patrons.lastname,
	         patrons.firstname,
	         patrons.middlename,
	         patrons.dob,
	         extract( 'years' from age( current_date, patrons.dob )) as years,
	         extract( 'months' from age( current_date, patrons.dob )) as months,
	         sessionpatrons.indistrict,
	         patrons.patroncomment,
	         patrons.verified,
	         patrons.patronid,
	         dops.isid( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no"> ) as indistrict,
	         dops.usescrate( sessionpatrons.patronid::integer, current_date) as issenior,
	         dops.usemilrate( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">, sessionpatrons.patronid::integer ) as ismil
	FROM     dops.sessionpatrons
	         inner join dops.patrons on sessionpatrons.secondarypatronid=patrons.patronid
	WHERE    sessionpatrons.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
	AND      not patrons.inactive
	ORDER BY sessionpatrons.relationtype, upper(patrons.lastname), upper(patrons.firstname)
</cfquery>

<cfquery dbtype="query" name="gethousehold1">
	select   patronid,
	         firstname,
	         relationtype
	from     gethousehold
	order by relationtype, patronid
</cfquery>

<cfquery dbtype="query" name="gethousehold2">
	select   patronid,
	         firstname,
	         relationtype
	from     gethousehold
	order by relationtype, patronid
</cfquery>

<cfquery datasource="#application.slavedopsds#" name="GetThisSetTerms">
	select   passterm
	from     dops.passrates
	where    passtype = <cfqueryparam value="#url.passtype#" cfsqltype="cf_sql_varchar" list="no">
	group by passterm
	order by passterm
</cfquery>

<cfif 0>
	<cfdump var="#GetThisSetTerms#">
</cfif>


<table width="100%" border=0>

<cfif ( url.passspan eq "C" and GetHousehold.recordcount lt 2 ) or
	( url.passspan eq "F" and GetHousehold.recordcount lt 3 ) or
	( IsDefined("url.suppressspan") )>

	<TR>
		<td colspan="99"><strong>Not Applicable</strong></td>
	</tr>
	<cfabort>
</cfif>

<cfif not GetHousehold.indistrict>
	<TR>
		<td colspan="99"><strong>With Assessment:</strong></td>
	</tr>
</cfif>

<cfif url.passspan eq "I">
	<!--- individual --->
	<cfloop query="gethousehold1">
		<TR>
			<td colspan="99" style="border-bottom: 1px solid Grey;"><strong>#gethousehold1.firstname#</strong></td>
		</tr>

		<cfloop query="GetThisSetTerms">
			<cfset patronslist = gethousehold1.patronid>

			<cfquery datasource="#application.slavedopsds#" name="GetThisRate">
				select   dops.getpassrate(
					<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
					<cfqueryparam value="#url.passtype#" cfsqltype="cf_sql_varchar" list="no">,
					<cfqueryparam value="#GetThisSetTerms.passterm#" cfsqltype="cf_sql_smallint" list="no">,
					<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
					'{ #variables.patronslist# }',
					true ) as v
			</cfquery>

			<tr>
				<td nowrap align="right">#GetThisSetTerms.passterm# months</td>
				<td align="right">#decimalformat( GetThisRate.v )#</td>
			</tr>
		</cfloop>

	</cfloop>

	<cfif not GetHousehold.indistrict>
		<TR>
			<td colspan="99"><strong>Without Assessment:</strong></td>
		</tr>
		<TR>
			<td colspan="99" style="border-bottom: 1px solid Grey;"><strong>#gethousehold1.firstname# / #gethousehold2.firstname#</strong></td>
		</tr>

		<cfloop query="gethousehold1">

			<cfloop query="GetThisSetTerms">
				<cfset patronslist = gethousehold1.patronid>

				<cfquery datasource="#application.slavedopsds#" name="GetThisRate">
					select   dops.getpassrate(
						<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
						<cfqueryparam value="#url.passtype#" cfsqltype="cf_sql_varchar" list="no">,
						<cfqueryparam value="#GetThisSetTerms.passterm#" cfsqltype="cf_sql_smallint" list="no">,
						<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
						'{ #variables.patronslist# }',
						false ) as v
				</cfquery>

				<tr>
					<td nowrap align="right">#GetThisSetTerms.passterm# months</td>
					<td align="right">#decimalformat( GetThisRate.v )#</td>
				</tr>
			</cfloop>

		</cfloop>

	</cfif>
	<!--- end individual --->

<cfelseif url.passspan eq "C">
	<!--- couple --->
	<cfloop query="gethousehold1">

		<cfloop query="gethousehold2">

			<cfif gethousehold1.patronid neq gethousehold2.patronid and gethousehold2.currentrow gt gethousehold1.currentrow>
				<TR>
					<td colspan="99" style="border-bottom: 1px solid Grey;"><strong>#gethousehold1.firstname# / #gethousehold2.firstname#</strong></td>
				</tr>

				<cfloop query="GetThisSetTerms">
					<cfset patronslist = gethousehold1.patronid & "," & gethousehold2.patronid>

					<cfquery datasource="#application.slavedopsds#" name="GetThisRate">
						select   dops.getpassrate(
							<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#url.passtype#" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="#GetThisSetTerms.passterm#" cfsqltype="cf_sql_smallint" list="no">,
							<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
							'{ #variables.patronslist# }',
							true ) as v
					</cfquery>

					<tr>
						<td nowrap align="right">#GetThisSetTerms.passterm# months</td>
						<td align="right">#decimalformat( GetThisRate.v )#</td>
					</tr>
				</cfloop>

			</cfif>

		</cfloop>

	</cfloop>

	<cfif not GetHousehold.indistrict>
		<TR>
			<td colspan="99"><strong>Without Assessment:</strong></td>
		</tr>

		<cfloop query="gethousehold1">

			<cfloop query="gethousehold2">

				<cfif gethousehold1.patronid neq gethousehold2.patronid and gethousehold2.currentrow gt gethousehold1.currentrow>
					<TR>
						<td colspan="99" style="border-bottom: 1px solid Grey;"><strong>#gethousehold1.firstname# / #gethousehold2.firstname#</strong></td>
					</tr>

					<cfloop query="GetThisSetTerms">
						<cfset patronslist = gethousehold1.patronid & "," & gethousehold2.patronid>

						<cfquery datasource="#application.slavedopsds#" name="GetThisRate">
							select   dops.getpassrate(
								<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
								<cfqueryparam value="#url.passtype#" cfsqltype="cf_sql_varchar" list="no">,
								<cfqueryparam value="#GetThisSetTerms.passterm#" cfsqltype="cf_sql_smallint" list="no">,
								<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
								'{ #variables.patronslist# }',
								false ) as v
						</cfquery>

						<tr>
							<td nowrap align="right">#GetThisSetTerms.passterm# months</td>
							<td align="right">#decimalformat( GetThisRate.v )#</td>
						</tr>
					</cfloop>

				</cfif>

			</cfloop>

		</cfloop>
	</cfif>
	<!--- end couple --->

<cfelse>
	<!--- family --->
	<cfset patronslist = "-">

	<cfloop query="gethousehold1">
		<cfset patronslist = variables.patronslist & "," & gethousehold1.patronid>
	</cfloop>

	<cfset patronslist = mid( variables.patronslist, 3, 999 )>
	<TR>
		<td colspan="99"><strong>All Members</strong></td>
	</tr>

	<cfloop query="GetThisSetTerms">

		<cfquery datasource="#application.slavedopsds#" name="GetThisRate">
			select   dops.getpassrate(
				<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#url.passtype#" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="#GetThisSetTerms.passterm#" cfsqltype="cf_sql_smallint" list="no">,
				<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
				'{ #variables.patronslist# }',
				true ) as v
		</cfquery>

		<tr>
			<td align="right">#GetThisSetTerms.passterm# months</td>
			<td align="right">#decimalformat( GetThisRate.v )#</td>
		</tr>
	</cfloop>

	<cfif not GetHousehold.indistrict>
		<TR>
			<td colspan="99"><strong>Without Assessment:</strong></td>
		</tr>
		<TR>
			<td colspan="99"><strong>AllMembers</strong></td>
		</tr>

		<cfloop query="GetThisSetTerms">

			<cfquery datasource="#application.slavedopsds#" name="GetThisRate">
				select   dops.getpassrate(
					<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
					<cfqueryparam value="#url.passtype#" cfsqltype="cf_sql_varchar" list="no">,
					<cfqueryparam value="#GetThisSetTerms.passterm#" cfsqltype="cf_sql_smallint" list="no">,
					<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
					'{ #variables.patronslist# }',
					false ) as v
			</cfquery>

			<tr>
				<td align="right">#GetThisSetTerms.passterm# months</td>
				<td align="right">#decimalformat( GetThisRate.v )#</td>
			</tr>
		</cfloop>
	</cfif>

	<!--- end family --->
</cfif>

</tr>
</table>

</html>
</cfoutput>