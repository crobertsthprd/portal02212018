<cfif form.creditused gt 0>

	<cfquery datasource="#application.dopsds#" name="GetDCAcctid">
		SELECT   acctid
		FROM     dops.glmaster
		WHERE    internalref = <cfqueryparam value="DC" cfsqltype="cf_sql_varchar" list="no">
	</cfquery>

	<cfif GetDCAcctid.recordcount eq 0>
		<cfsavecontent variable="message">
				Could not find district credit data.
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</cfsavecontent>	
          <cfinclude template="includes/layout.cfm">
		<cfabort>
	</cfif>

</cfif>

<cfquery datasource="#application.dopsds#" name="GetBasketPasses">
	SELECT   *,
	         0 as acctid
	FROM     dops.sessionpasses
	         INNER JOIN dops.passtype ON sessionpasses.passtype=passtype.passtype
	WHERE    sessionpasses.sessionid = <cfqueryparam value="#form.currentsessionid#" cfsqltype="cf_sql_varchar" list="no">
	and      sessionpasses.isnewpass
	order by sessionpasses.ec
</cfquery>

<cfif GetBasketPasses.recordcount eq 0>
		<cfsavecontent variable="message">
				No passes found in basket
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</cfsavecontent>	
          <cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>

<!--- set GLs --->
<cfloop query="GetBasketPasses">
	<!--- get GL --->
	<cfquery datasource="#application.dopsds#" name="GetPassGL">
		select   acctid
		from     dops.passtypegl
		where    facid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
		and      passtype = <cfqueryparam value="#GetBasketPasses.PassType#" cfsqltype="CF_SQL_VARCHAR">
		and      acctid is not null
	</cfquery>

	<cfif GetPassGL.RecordCount neq 1>
		<cfset errormsg = "Error in fetching data for pass.">
	<cfelse>
		<cfset QuerySetCell( GetBasketPasses, "acctid", GetPassGL.acctid, GetBasketPasses.currentrow )>
	</cfif>

</cfloop>

<cfif IsDefined("variables.errormsg")>
		<cfsavecontent variable="message">
				#variables.errormsg#
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</cfsavecontent>	
          <cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>
<!--- end set GLs --->
<cfif 0>
	<cfdump var="#GetBasketPasses#">
</cfif>


<!--- get oc card data --->
<cfif form.tenderedoc gt 0>
	<cfif form.OCCardNumber eq "">
		<cfset errormsg = "Gift Card funds were specified but no card was found.">
	<cfelse>
		<cfset ocNum = REReplace( form.OCCardNumber, "[^0-9]", "", "all" )>
		<cf_cryp type="en" string="#variables.ocNum#" key="#variables.key#">

		<cfif cryp.value eq "">
			<cfset errormsg = "Gift card number did not properly decode.">
		<cfelse>
			<cfset enOtherCreditData = cryp.value>

			<!--- lookup card by id - improves speed --->
			<cfquery datasource="#application.dopsds#" name="getCardData">
				SELECT   cardid,
				         activated,
				         valid,
				         primarypatronid,
				         holdforreview,
				         isfa,
				         faappid,
				         acctid
				FROM     dops.othercredithistorysums
				where    othercreditdata = <cfqueryparam value="#variables.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>

			<cfif getCardData.recordcount eq 0>
				<cfset errormsg = "Gift Card funds were specified but no card was found.">
			<cfelse>

				<cfif getCardData.holdforreview or not getCardData.valid>
					<cfset errormsg = "Gift card was found but is not valid.">
				</cfif>

			</cfif>

		</cfif>

	</cfif>

</cfif>
<!--- end get oc card data --->

<cfif IsDefined("variables.errormsg")>
	<TR>
		<TD colspan="99">
			#variables.errormsg#
			<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</td>
	</tr>
	<cfabort>
</cfif>



<!--- create invoice then update as needed --->
<cfset nextinvoice = GetNextInvoice()>
<cfset GLLineNo = 0>

<!---init is code 
<cfif form.adjustednetdue gt 0>
	

	<cfset thistranxpk = invoicetranxprecheck(
		gethousehold.primarypatronid[1],
		form.sid,
		form.adjustednetdue,
		form.ccfirstname,
		form.cclastname,
		"",
		"")>

	<!--- convert back to integer response --->
	<cfset origthistranxpk = variables.thistranxpk>
	<cfset thistranxpk = val( variables.thistranxpk )>

	<cfif variables.thistranxpk eq 0>
		<TR>
			<TD colspan="99">
				Error in determining transaction initialization code.<BR><BR>#variables.origthistranxpk#<BR><BR>Go back and try again or contact THPRD for assistance.
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
			</td>
		</tr>
		<cfabort>
	</cfif>

</cfif>--->