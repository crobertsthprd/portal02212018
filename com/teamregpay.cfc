

<CFCOMPONENT>

<!--- notes --->
<!--- it is assumed the team already exists as this routine only updates trteam --->
<!--- ghost card insertions and checks are handled --->
<!--- fees are derived from trteamview --->

<!--- set pmtmode as needed:
team payment only: T
ghost card only: G
both team and gh: TG
--->

<!--- place on calling page and remove cfset below:
<cfif primarypatronid is 147756>
	<input name="TestMode" type="Checkbox" checked>Test Mode&nbsp;&nbsp;&nbsp;
</cfif> --->

<!--- dependencies: application.invoicefunctions.getNextInvoice() and application.invoicefunctions.GetNextEC() and application.invoicefunctions.dollarRound() --->

<CFFUNCTION name="processteamreg" returntype="struct" output="yes">
     <CFARGUMENT name="primarypatronid" required="yes" type="numeric">
     <CFARGUMENT name="pmtmode" required="yes" type="string">
     <CFARGUMENT name="patronid" required="yes" type="numeric">
     <CFARGUMENT name="teamid" required="yes" type="numeric">
     <CFARGUMENT name="cctype" required="yes" type="string">
     <CFARGUMENT name="cc1" required="yes" type="numeric">
     <CFARGUMENT name="cc2" required="yes" type="numeric">
     <CFARGUMENT name="cc3" required="yes" type="numeric">
     <CFARGUMENT name="cc4" required="yes" type="numeric">
     <CFARGUMENT name="ccv" required="yes" type="numeric">
     <CFARGUMENT name="ccexpiremonth" required="yes" type="numeric">
     <CFARGUMENT name="ccexpireyear" required="yes" type="numeric">
     <CFARGUMENT name="ghostcardstobuy" required="yes" type="numeric">
     <CFARGUMENT name="totalfees" required="yes" type="numeric">
     <CFARGUMENT name="contactpk" required="yes" type="numeric">
     <CFARGUMENT name="localfac" required="no" type="string" default="WWW">
     <CFARGUMENT name="testmode"  required="no" type="boolean" default="1">
     <CFSET var errormsg = "">
     <CFSET var ccencrypt = "">
     <CFSET var ccvencrypt = "">
     <CFSET var teamsum = "">
     <CFSET var temp = "">
     <CFSET var ccnum = "">
     <CFSET var checkfees = "">
     <CFSET var checkstatus = "">
     <CFSET var insertInvoice = "">
     <CFSET var getViewData = "">
     <CFSET var ActivityLine = 0>
     <CFSET var gllineno  = 0>
     <CFSET var NextInvoice= "">
     <CFSET var totalfeesum = 0>
     <CFSET var goahead = 0>
     <CFSET var ccExp = 0>
     <CFSET var invoicetype = 0>
     <CFSET var response = structnew()>
     <cfset ccNum = REREPLACE(cc1 & cc2 & cc3 & cc4,"[^0-9]","","ALL")>
     <cfif len(ccNum) is 16>
          <cfset goahead = 1>
          <cfelse>
          <!--- failure stuff --->
          <cfset response.auth = 0>
          <cfset response.errormsg = "Credit card is not corrent format or missing digits.">
          <CFRETURN response>
     </cfif>
     
     <!--- defined encoded cc data: remove when impliemnting cfcrypt() @ "encrypt ccd" 
<cfset ccd = "334345837453786543765347343453476">
<cfset ccven = "123123">--->
     
		
     
     
     <cf_cryp type="en" string="#ccnum#" key="#application.key#">
     <CFSET ccencrypt = cryp.value>
     <cf_cryp type="en" string="#arguments.ccv#" key="#application.key#">
     <CFSET ccvencrypt = cryp.value>
     <cfquery datasource="#application.dopsds#" name="CheckFees">
		select   leaguefees,  ghostcardfee * <cfqueryparam value="#arguments.ghostcardstobuy#" cfsqltype="cf_sql_integer" list="no"> as gcfees
		from     dops.trteamview
		where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>
     <cfif find("T", arguments.pmtmode) gt 0>
          <cfset temp = CheckFees.leaguefees>
          <cfelse>
          <cfset temp = 0>
     </cfif>
     <cfif find("G", arguments.pmtmode) gt 0>
          <cfset temp = temp + CheckFees.gcfees>
     </cfif>
     <cfif application.invoicefunctions.dollarRound(temp) neq application.invoicefunctions.dollarRound(arguments.totalfees) or application.invoicefunctions.dollarRound(temp) is 0>
          <cfset response.auth = 0>
          <cfset repsponse.errormsg = "Specified funds did not match expected amount. #decimalformat(temp)# vs #decimalformat(arguments.totalfees)#.">
          <CFRETURN response>
     </cfif>
     <cfif arguments.pmtmode is "T" or arguments.pmtmode is "TG">
          <!--- check for already done --->
          <cfquery datasource="#application.dopsds#" name="CheckStatus">
		select   invoicefacid
		from     dops.trteam
		where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>
          
          <!--- if invoicefacid is not null, already done so stop --->
          <cfif CheckStatus.invoicefacid is not "">
               <!--- failure stuff --->
               <cfset response.auth = 0>
               <cfset response.errormsg = "Specified team has already been paid for.">
               <CFRETURN response>
          </cfif>
     </cfif>
     <cfset ccExp = arguments.ccexpiremonth & right(arguments.ccexpireyear, 2)>
     <cfif arguments.pmtmode is "T">
          <!--- team payment only --->
          <cfset invoicetype = "-TR-">
          <cfelseif arguments.pmtmode is "TG">
          <!--- team team and ghost payment --->
          <cfset invoicetype = "-TR-TRG-">
          <cfelseif arguments.pmtmode is "G">
          <!--- team ghost payment only --->
          <cfset invoicetype = "-TRG-">
     </cfif>
     <cftransaction isolation="REPEATABLE_READ" action="BEGIN">
          <cfset NextInvoice = application.invoicefunctions.GetNextInvoice()>
          
          <!--- <cfinclude template="/portal/includes/CheckCCValidity.cfm"> --->
          
          <cfquery datasource="#application.dopsds#" name="InsertInvoice">
			insert into invoice
				(invoicefacid,
				invoicenumber,
				totalfees,
				tenderedcc,
				cca,
				cced,
				cew,
				cctype,
				ccv,
				firstname, 
				lastname, 
				contact,
				node,
				userid,
				addressid,
				invoicetype)
			values
				(<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
				<cfqueryparam value="#arguments.totalfees#" cfsqltype="CF_SQL_MONEY">, --TotalFees
				<cfqueryparam value="#arguments.totalfees#" cfsqltype="CF_SQL_MONEY">, --TenderedCC
				<cfqueryparam value="#ccencrypt#" cfsqltype="CF_SQL_VARCHAR">, --CCA
				<cfqueryparam value="#ccExp#" cfsqltype="CF_SQL_VARCHAR">, --CCED
				<cfqueryparam value="#right(ccNum,4)#" cfsqltype="CF_SQL_VARCHAR">, --CEW
				<cfqueryparam value="#left(ccNum,1)#" cfsqltype="CF_SQL_VARCHAR">, --ccType
				<cfqueryparam value="#CCVencrypt#" cfsqltype="CF_SQL_VARCHAR">, ( --CCV

				select   lastname
				from     patrons
				where    patronid = <cfqueryparam value="#arguments.patronid#" cfsqltype="cf_sql_integer" list="no">), (

				select   firstname
				from     patrons
				where    patronid = <cfqueryparam value="#arguments.patronid#" cfsqltype="cf_sql_integer" list="no">), (

				select   contactdata
				from     patroncontact
				where    pk = <cfqueryparam value="#arguments.contactpk#" cfsqltype="cf_sql_integer" list="no">), 

				<cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">, --LocalNode
				<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, ( --huserID

				SELECT   patronaddresses.addressid
				FROM     dops.patronrelations 
				         INNER JOIN dops.patronaddresses ON patronrelations.addressid=patronaddresses.addressid 
				WHERE    patronrelations.primarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
				AND      patronrelations.relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">),

				<cfqueryparam value="#invoicetype#" cfsqltype="CF_SQL_VARCHAR">) -- invoice type(s)
			;

			<cfset GLLineNo = GLLineNo + 1>

			<cfif find("T", arguments.pmtmode) gt 0>
				update  dops.trteam
				set
					invoicefacid = <cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">,
					invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER" list="No">
				where  teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
				;

				insert into GL
					(credit,
					acctid,
					invoicefacid,
					invoicenumber,
					entryline,
					ec,
					activitytype,
					activity)
				values
					( (
					select   leaguefees
					from     dops.trteamview
					where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">), ( --Totalfees
	
					select   acctid
					from     dops.trteamview
					where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">),
	
					<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR" list="No">, --LocalFac
					<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER" list="No">, --NextInvoice
					<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER" list="No">, --GLLineNo
					<cfqueryparam value="#application.invoicefunctions.GetNextEC()#" cfsqltype="CF_SQL_INTEGER" list="No">, --EC
					<cfqueryparam value="TR" cfsqltype="CF_SQL_VARCHAR" list="No">, -- activity
					<cfqueryparam value="Team Registration" cfsqltype="CF_SQL_VARCHAR" list="No">)
				;
			</cfif>

			<cfif find("G", pmtmode) gt 0>
				insert into trghostcard
					(teamid, 
					invoicefacid, 
					invoicenumber, 
					qty)
				values
					(<cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">, 
					<cfqueryparam value="#arguments.localfac#" cfsqltype="cf_sql_varchar" list="no">, 
					<cfqueryparam value="#NextInvoice#" cfsqltype="cf_sql_integer" list="no">, 
					<cfqueryparam value="#ghostcardstobuy#" cfsqltype="cf_sql_integer" list="no">)
				;

				insert into GL
					(credit,
					acctid,
					invoicefacid,
					invoicenumber,
					entryline,
					ec,
					activitytype,
					activity)
				values
					( (
					select   ghostcardfee * <cfqueryparam value="#arguments.ghostcardstobuy#" cfsqltype="cf_sql_integer" list="no">
					from     dops.trteamview
					where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">), ( --Totalfees
	
					select   acctid
					from     dops.trteamview
					where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">),
	
					<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR" list="No">, --LocalFac
					<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER" list="No">, --NextInvoice
					<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER" list="No">, --GLLineNo
					<cfqueryparam value="#application.invoicefunctions.GetNextEC()#" cfsqltype="CF_SQL_INTEGER" list="No">, --EC
					<cfqueryparam value="TRG" cfsqltype="CF_SQL_VARCHAR" list="No">, -- activity
					<cfqueryparam value="Team Registration Ghost Card" cfsqltype="CF_SQL_VARCHAR" list="No">)
				;
			</cfif>

			select   ghostcardviolation
			from     dops.trteamview
			where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>
          <cfif InsertInvoice.ghostcardviolation>
               <!--- violated ghost card limit --->
               <cftransaction action="ROLLBACK">
               <!--- failure stuff --->
               
               <cfset response.auth = 0>
               <cfset response.errormsg = "Too many ghost cards were specified.">
               <CFRETURN response>
           <cfelse>
               <!---cfinclude template="/portal/includes/FinalChecks.cfm">--->
               
			
			
			<CFSET finalcheck = application.invoicecheck.glcheck(NextInvoice)>
               
               
               
			<CFIF finalcheck.auth EQ 1>
                    <cfif IsDefined("arguments.TestMode") and arguments.TestMode is 1>
                         <cfquery datasource="#application.dopsds#" name="getviewdata">
					select   *
					from     dops.trteamview
					where    teamid = <cfqueryparam value="#teamid#" cfsqltype="cf_sql_integer" list="no">
					</cfquery>
                         <cfdump var="#getviewdata#">
                         <cfinclude template="/portalINC/displayallinvoicetables.cfm">
                         <!--- rollback in testing --->
                         <CFTRANSACTION action="rollback">
                         <cfset response.auth = 1>
                         <cfset response.invoiceID = NextInvoice>
                         <cfset response.invoicefac = arguments.localfac>
                         <cfset response.invoicetype = arguments.pmtmode>
                         <CFABORT>
                         <CFRETURN response>
                         <CFELSE>
                         <cfset response.auth = 1>
                         <cfset response.invoiceID = NextInvoice>
                         <cfset response.invoicefac = arguments.localfac>
                         <cfset response.invoicetype = arguments.pmtmode>
                         <CFRETURN response>
                    </cfif>
               <CFELSE>
               	<cfset response.auth = 0>
                    <cfset response.errormsg = finalcheck.errormsg>
               	<CFRETURN response>
               </CFIF>
          </cfif>
     </cftransaction>
</CFFUNCTION>
</cfcomponent>