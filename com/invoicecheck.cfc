<!--- dependencies: application.invoicefunctions.dollaround() --->
<cfcomponent>
<cffunction name="glcheck" returntype="struct" output="yes">
     <CFARGUMENT name="nextinvoice" type="numeric" required="yes">
     <CFARGUMENT name="localfac" type="string" required="no" default="WWW">
     <CFARGUMENT name="servername" type="string" required="no" default="">
     <CFARGUMENT name="othercreditused" type="numeric" required="no" default="0">
     <CFARGUMENT name="OtherCreditData" type="numeric" required="no" default="0">
     <!--- encrypted othercreditData --->
     <CFARGUMENT name="enOtherCreditData" type="string" required="no" default="">
     <CFSET var GetInvoiceInvoiceNet="">
     <CFSET var GetOCChecks = "">
     <CFSET var response = structnew()>
     <cfquery name="GetInvoiceInvoiceNet" datasource="#application.dopsds#">
	select   invoicenet, dops.getglerror(invoicenet.invoicefacid, invoicenet.invoicenumber) as gle
	from     invoicenet
	where    invoicefacid = <cfqueryparam value="#arguments.LocalFac#" cfsqltype="CF_SQL_VARCHAR">
	and      invoicenumber = <cfqueryparam value="#arguments.NextInvoice#" cfsqltype="CF_SQL_INTEGER">
	</cfquery>
     
     <!--- check for Gl error --->
     <cfif GetInvoiceInvoiceNet.recordcount is 1 and GetInvoiceInvoiceNet.gle is not 0>
          <cfset response.auth = 0>
          <cfset response.errormsg = "GL error of #decimalformat(GetGLE.gle)# was detected for proposed invoice. Go back and try again. If problem persists, contact THPRD.">
          <cfif arguments.servername is "DEV">
               <CFOUTPUT>#response.errormsg#</CFOUTPUT>
               <cfinclude template="/portalINC/displayallinvoicetables.cfm">
               <cfabort>
          </cfif>
          <CFRETURN response>
     </cfif>
     
     <!--- check for negative invoice balance --->
     <cfif application.invoicefunctions.dollarRound(GetInvoiceInvoiceNet.invoicenet) lt 0>
          <cfset response.auth = 0>
          <cfset response.errormsg = "Invoice balance resulted in a negative value: #dollarformat(GetInvoiceInvoiceNet.invoicenet)#. Go back and try again. If problem persists, contact THPRD.">
          <cfif arguments.servername is "DEV">
               <CFOUTPUT>#response.errormsg#</CFOUTPUT>
               <cfinclude template="/portalINC/displayallinvoicetables.cfm">
               <cfabort>
          </cfif>
          <CFRETURN response>
     </cfif>
     
     
     
     <cfif arguments.othercreditused gt 0>
          <cfquery name="GetOCChecks" datasource="#application.dopsds#">
		select   #decimalformat(arguments.othercreditused)# as othercreditused, (

		SELECT   sum(credit)
		FROM     othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistsum, (

		SELECT   sum(debit)
		FROM     othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as ocusedsum, (

		SELECT   dops.getocbalance(othercredithistorysums.cardid, othercredithistorysums.primarypatronid)
		FROM     othercredithistorysums 
		where    

		<cfif arguments.OtherCreditData GT 0 and arguments.OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="#arguments.OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#arguments.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as cardusedbalance, (

		SELECT   faapptype
		FROM     othercredithistorysums 
		where    

		<cfif arguments.OtherCreditData GT 0 and arguments.OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="arguments.#OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#arguments.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as faapptype

	</cfquery>
          
          <!--- check for negative value --->
          <cfif dollarRound(GetOCChecks.cardusedbalance) lt 0>
               <cfset response.auth = 0>
               <cfset response.errormsg = "Other Credit balance resulted in a negative value: #dollarformat(GetOCChecks.cardusedbalance)#. Go back and try again. If problem persists, contact THPRD.">
               <cfif arguments.servername is "DEV">
                    <CFOUTPUT>#response.errormsg#</CFOUTPUT><br>
                    <cfdump var="#GetOCChecks#">
                    <cfinclude template="/portalINC/displayallinvoicetables.cfm">
                    <cfabort>
               </cfif>
               <CFRETURN response>
          </cfif>
          <cfif GetOCChecks.recordcount is 1 and dollarRound(val(GetOCChecks.ocusedsum)) is not dollarRound(val(othercreditused))>
               <cfset response.auth = 0>
               <cfset response.errormsg = "Other Credit Used calculation Error. Expected #decimalformat(othercreditused)#, found #decimalformat(GetOCChecks.ocusedsum)#. Go back and try checkout again or contact THPRD if problem persists.">
               <cfif arguments.servername is "DEV">
                    <CFOUTPUT>#response.errormsg#</CFOUTPUT><br>
                    <cfdump var="#GetOCChecks#">
                    <cfinclude template="/portalINC/displayallinvoicetables.cfm">
                    <cfabort>
               </cfif>
               <CFRETURN response>
          </cfif>
     </cfif>
     <cfset response.auth = 1>
     <cfset response.errormsg = "GL Check successful.">
     <CFRETURN response>
</cffunction>
</cfcomponent>
