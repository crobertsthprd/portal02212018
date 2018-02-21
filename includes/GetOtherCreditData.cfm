<cfoutput>

<cfif OtherCreditData is not "">
	<cfset ocNum = replace(OtherCreditData," ","","all")>
	<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
	<cf_cryp type="en" string="#ocNum#" key="#key#">
	<cfset enOtherCreditData = cryp.value>
	<cfset AttemptedCard = OtherCreditData>

	<cfquery datasource="#application.dopsds#" name="getCardData">
		SELECT   othercreditdesc,
		         cardid,
		         othercredittype,
		         isfa,
		         faapptype,
		         faappid,
		         acctid,
		         faappcurrent,
		         faloadacctid,
		         primarypatronid,
		         dops.getocavailablefunds(othercredithistorysums.cardid, othercredithistorysums.primarypatronid, <cfqueryparam value="#DollarRound(totalfees)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="#DollarRound(netdue)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="-1" cfsqltype="CF_SQL_NUMERIC">) as sumnet
		FROM     othercredithistorysums 
		where    valid

		<cfif IsNumeric(OtherCreditData) and OtherCreditData lt 999999999999>
			and   cardid = <cfqueryparam value="#OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			and   othercreditdata = <cfqueryparam value="#enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>		
			and ((isfa IS true and current_date < faappexpiredate) OR isfa IS false)
	</cfquery>



	<cfif GetCardData.recordcount is not 1>
		<BR><BR><strong>Error in fetching Other Credit Card or is invalid/not activated/on hold for review.</strong>
		<BR><BR>
		<a href="javascript:history.back();">Go Back</a>
		<cfabort>

	<cfelseif GetCardData.primarypatronid is not "">

		<cfif not IsDefined("primarypatronid") or primarypatronid is not GetCardData.primarypatronid>
			<BR><BR><strong>Specified Card is registered to another party, thus cannot be used this transaction.</strong>
			<BR><BR>
			<a href="javascript:history.back();">Go Back</a>
			<cfabort>

		</cfif>

	</cfif>



	<cfif getCardData.recordcount is 0>

		<cfif IsNumeric(OtherCreditData) and OtherCreditData lt 999999999999>
		<cfelse>
			<cf_cryp type="de" string="#enOtherCreditData#" key="#key#">
			<cfset AttemptedCard = cryp.value>

		</cfif>		

		<BR><BR><strong>Cannot determine Other card used (#AttemptedCard#). Go back and try again.</strong>
		<BR><BR>
		<a href="javascript:history.back();">Go Back</a>
		<cfabort>

	</cfif>

	<cfset otherCreditGLAcctid = getCardData.acctid>

</cfif>

</cfoutput>