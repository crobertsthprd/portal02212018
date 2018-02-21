<!--- get basket passes --->


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
	<!--- no passes found --->
     <CFSET runningsum = 0>
<cfelse>
	<cfset runningsum = 0>
	<cfloop query="GetBasketPasses">
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
		<cfset runningsum = variables.runningsum + GetBasketPasses.passfee>
	</cfloop>
</cfif>

