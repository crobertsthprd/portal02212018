<!--- get basket passes --->
<cfoutput>

<cfset OCFundsDist = ArrayNew(2)>
<cfset passloopcnt = 0>

<!--- fetch passes in same order as entered --->
<cfquery datasource="#application.dopsds#" name="GetBasketPasses">
	SELECT   sessionpasses.passtype,
	         sessionpasses.passspan,
	         sessionpasses.passterm,
	         sessionpasses.passfee,
	         sessionpasses.ec,
	         passtype.passdescription
	FROM     dops.sessionpasses
	         INNER JOIN dops.passtype ON sessionpasses.passtype=passtype.passtype
	WHERE    sessionpasses.sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
	and      isnewpass
	order by sessionpasses.ec
</cfquery>

<cfif GetBasketPasses.recordcount eq 0>
	<tr>
		<td colspan=99>No passes found in basket</td>
	</tr>
	<TR valign="top">
		<TD colspan="99"><BR></td>
	</tr>
<cfelse>
	<TR valign="top" style="background-color: cccccc;">
		<TD nowrap>Pass Type / Duration</td>
		<TD nowrap>Pass Members</td>
		<TD nowrap align="right">Pass Fee</td>
	</tr>

	<cfset runningsum = 0>

	<cfloop query="GetBasketPasses">
		<TR valign="top">
			<TD>
				#GetBasketPasses.passdescription#,

				<cfif GetBasketPasses.passspan eq "I">
					Individual,
				<cfelseif GetBasketPasses.passspan eq "C">
					Couple,
				<cfelseif GetBasketPasses.passspan eq "F">
					Family,
				<cfelse>
					Unknown,
				</cfif>

				#GetBasketPasses.passterm# month
				<A href="passes.cfm?remec=#GetBasketPasses.ec#" title="Remove this pass">Remove</a>
			</td>

			<cfquery datasource="#application.dopsds#" name="GetBasketPassMembers">
				SELECT   sessionpassmembers.pk,
				         patrons.patronid,
				         patrons.lastname,
				         patrons.firstname,
				         passtype.passtype,
				         passtype.passdescription,
				         extract( 'years' from age( current_date, patrons.dob )) as years,
				         extract( 'months' from age( current_date, patrons.dob )) as months
				FROM     dops.sessionpassmembers
				         INNER JOIN dops.patrons ON sessionpassmembers.patronid=patrons.patronid
				         INNER JOIN dops.sessionpasses ON sessionpassmembers.ec=sessionpasses.ec
				         INNER JOIN dops.passtype ON sessionpasses.passtype=passtype.passtype
				WHERE    sessionpassmembers.ec = <cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="cf_sql_integer" list="no">
				ORDER BY patrons.lastname, patrons.firstname, patrons.middlename
			</cfquery>

			<TD>

				<cfloop query="GetBasketPassMembers">
					#GetBasketPassMembers.lastname#,
					#GetBasketPassMembers.firstname#
					(#GetBasketPassMembers.years#y, #GetBasketPassMembers.months#m)
					<BR>
				</cfloop>

			</td>
			<TD align="right">#decimalformat( GetBasketPasses.passfee )#</td>
		</tr>
		<TR>
			<TD colspan="99"><BR></td>
		</tr>
		<cfset runningsum = variables.runningsum + GetBasketPasses.passfee>
	</cfloop>

	<TR valign="top">
		<TD nowrap colspan="2" align="right">Total Fees</td>
		<TD nowrap align="right" style="border-top-color: Grey; border-top-style: solid; border-top-width: 1px; border-bottom-color: Grey; border-bottom-style: double;">#decimalformat( variables.runningsum )#</td>
	</tr>
</cfif>

</cfoutput>