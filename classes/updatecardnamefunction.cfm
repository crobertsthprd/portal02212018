<CFFUNCTION name="updatecardname"  returntype="struct" >
<CFARGUMENT name="cardname" required="yes" type="string">
<CFARGUMENT name="cardnumber" required="yes" type="numeric">
<CFARGUMENT name="primarypatronid" required="yes" type="numeric">
<CFSET var adjcardname = "">
<CFSET var checkcards = "">
<CFSET var response = structnew()>
<CFSET var ocNum = "">
<CFSET var enOtherCreditData = "">



<cfset adjcardname = trim(ucase(rereplace(arguments.cardname,"[^a-zA-Z1-9]","","ALL")))>

<CFIF len(adjcardname) LT 7>
	<CFSET response.namecarderror = "Card name must have at least 7 alphanumeric characters">
     <CFRETURN response>
</CFIF>

<CFIF len(adjcardname) GT 18>
	<CFSET response.namecarderror = "Card name must have no more than 18 alphanumeric characters">
     <CFRETURN response>
</CFIF>

<cfquery datasource="#application.dopsds#" name="checkCards">
	SELECT   s.cardid,
     (select cardname from othercreditdata where cardid = s.cardid) AS cardname
	FROM     othercredithistorysums s
	WHERE    s.primarypatronid = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#arguments.primarypatronid#">
	and      valid = true 
	ORDER BY s.cardid
</cfquery>



<CFLOOP query="checkCards">
	<CFIF trim(checkcards.cardname) EQ trim(adjcardname)>
     	<CFSET response.namecarderror = "Card name must be unique.">
          <CFRETURN response>
     </CFIF>
</CFLOOP>



<cfset ocNum = replace(arguments.cardnumber," ","","all")>
<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
<cf_cryp type="en" string="#ocNum#" key="#skey#">
<cfset enOtherCreditData = cryp.value>



<!--- DO QUERY; assuming we have one update to do --->
<CFQUERY name="updatecardname" datasource="#application.reg_dsn#">
	update othercreditdata
     set cardname = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#adjcardname#">
     where othercreditdata = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#enOtherCreditData#">
</CFQUERY>

<CFSET response.namecardsuccess = "Card name successfully updated.">



<CFRETURN response>

</CFFUNCTION>