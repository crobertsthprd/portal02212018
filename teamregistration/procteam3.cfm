<cfset application.dopsds = "dopsds">



<cfoutput>
<CFINCLUDE template="/portalINC/checkopencall.cfm">
<!---cfinclude template="/common/functions.cfm" 06122017 --->
<cfinclude template="/common/functionsfp.cfm">
<cfinclude template="/common/checkformelements.cfm">
<cfset sessionvars = getprimarysessiondata(cookie.uid, "TEAM")>

<!--- temp override --->
<CFSET sessionvars.sessionid = form.currentsessionid>

<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" )>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<CFSET variables.thisModule = "TEAM">
<CFSET variables.collisionMsg = "Activities not related to Team Registration were detected.">
<!--- NOTE: no session tables exist for team registration, therefore sessionvars.module must be "NONE" --->
<!--- standard code to determine if there are other items in basket // need to keep track of district credit // assumes closed cfoutput--->
<cfif variables.sessionvars.module neq "NONE" and variables.sessionvars.module neq variables.thisModule>
	<CFSAVECONTENT variable="message">
	<cfoutput>#variables.collisionMsg#<BR>
	#sessionvars.modulecomments#<cfif 0>#sessionvars.module#</cfif>
	</cfoutput>
	</CFSAVECONTENT>
	<cfset form.patronlookup = "">
	<cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>


<cfquery datasource="#application.dopsds#ro" name="GetTeam">
	SELECT   *
	FROM     dops.trteamview
	WHERE    teamid = <cfqueryparam value="#form.teamid#" cfsqltype="cf_sql_integer" list="no">
	and      divisionid = <cfqueryparam value="#form.divisionid#" cfsqltype="cf_sql_integer" list="no">
	and      leagueid = <cfqueryparam value="#form.leagueid#" cfsqltype="cf_sql_integer" list="no">
</cfquery>

<cfif 0>
	<cfdump var="#GetTeam#" format="text">
</cfif>

<cfif GetTeam.recordcount eq 0>
	<cfsavecontent variable="message">
	Specified team was not found.
     </cfsavecontent>
<cfelseif GetTeam.invoicefacid neq "">
	<cfsavecontent variable="message">
	Specified team was already paid on invoice #GetTeam.invoicefacid#-#GetTeam.invoicenumber#.
     </cfsavecontent>
     <cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>


<!---
<form action="procteam3.cfm" method="post">
<input name="currentsessionid" type="hidden" value="#form.currentsessionid#">
<input name="ghostcardcount" type="hidden" value="#form.ghostcardcount#">
<input type="hidden" name="teamid" value="#form.teamid#">
<input type="hidden" name="divisionid" value="#form.divisionid#">
<input type="hidden" name="leagueid" value="#form.leagueid#">
--->

<cfif 0>
	<cfdump var="#GetTeam#">
</cfif>

<cfif 0>
	<cfdump var="#form#">
</cfif>


<cfset paymentmode = "T">

<cfif form.ghostcardcount gt 0>
	<cfset paymentmode = "TG">
</cfif>

<!--- look for payment for this session --->
<cfinclude template="/common/invoicetranxcheckforapproval_freedompay.cfm">
<!--- end look for payment for this session --->


<cftransaction isolation="REPEATABLE_READ" action="BEGIN">

<!---processteamreg( #cookie.uid#, #variables.paymentmode#, #cookie.uid#, #GetTeam.teamid#, #form.ghostcardcount#, #form.totalFees#, 0 )--->
<cfset result = processteamreg( form.currentsessionid, cookie.uid, variables.paymentmode, cookie.uid, GetTeam.teamid, form.ghostcardcount, form.totalFees, form.netDue, form.districtCreditUsed, form.othercreditcardid, form.othercreditused, 0 )>

<cfif 0>
	<cfdump var="#result#" label="result">
</cfif>

<cfif not result.auth>
	Processing attempt unsuccessful.
	<cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>


<cfif form.netDue gt 0>
	<cfset nextinvoice = result.invoicenumber>
	<cfset nextprc = result.prc>
	<cfinclude template="/common/invoicetranxupdatetxdist.cfm">
</cfif>

<cfif 0>
	<cfset approved = result.auth>
	<cfset localfac = result.invoicefacid>
	<cfinclude template="/portalINC/displayallinvoicetables.cfm">
</cfif>


<cfif 0>
	<cfabort>
</cfif>





			<cfif form.netDue gt 0>
				<!--- direction decision --->
				<cfif not variables.approved>
					<!--- no payment found --->
					<cftransaction action="ROLLBACK" />

					<cfset customer = StructNew()>

					<cfquery datasource="#application.dopsds#" name="patroninfo">
						SELECT   patroninfo.lastname,
						         patroninfo.firstname,
						         patroninfo.address1,
						         patroninfo.address2,
						         patroninfo.city,
						         patroninfo.state,
						         patroninfo.zip, (

						select   contactdata
						from     dops.patroncontact
						where    position( patroncontact.contacttype in <cfqueryparam value="HWC" cfsqltype="cf_sql_varchar" list="no"> ) > <cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">
						and      patroncontact.patronid = patroninfo.primarypatronid
						order by position( patroncontact.contacttype in <cfqueryparam value="HWC" cfsqltype="cf_sql_varchar" list="no"> )
						limit    1 ) as contact, (

						select   patrons.loginemail
						from     dops.patrons
						where    patronid = patroninfo.primarypatronid ) as email

						FROM     dops.patroninfo
						WHERE    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						AND      relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
					</cfquery>

					<cfset customer.primarypatronid  = form.primarypatronid>
					<cfset customer.currentsessionid = sessionvars.sessionid>
					<cfset customer.firstname        = patroninfo.firstname>
					<cfset customer.lastname         = patroninfo.lastname>
					<cfset customer.address1         = patroninfo.address1>
					<cfset customer.address2         = patroninfo.address2>
					<cfset customer.city             = patroninfo.city>
					<cfset customer.state            = uCase( patroninfo.state )>
					<cfset customer.zip              = uCase( patroninfo.zip )>
					<cfset customer.phone            = patroninfo.contact>
					<cfset customer.email            = patroninfo.email>
					<cfset customer.amount           = form.netDue>
					<cfset customer.name             = trim( customer.firstname & " " & customer.lastname )>
					<cfset customer.callcomment      = "Team Registration: Team ID: #form.teamid# with #form.ghostcardcount# ghost cards">

					<cfif 0>
						<cfset customer.testmode         = 1>
					<cfelse>
						<cfset customer.testmode         = 0>
					</cfif>

					<!--- set ccsale() mode --->
					<cfset customer.ccsalemode = "REAL">

					<cfif customer.testmode>
						<cfset customer.ccsalemode = "TESTD"><!--- test decline --->

						<cfif 1>
							<cfset customer.ccsalemode = "TESTA"><!--- test approval --->
						</cfif>

					</cfif>

					<!--- close and call BP web interface --->
					<cfset posturl = "procteam3.cfm">
                         
					<cfinclude template="/common/invoicetranxcallclose_freedompay.cfm">
					<cftransaction action="commit" />
					<cfinclude template="includes/layout.cfm">
					<!--- commit insertion record --->
					<cfabort>

				<cfelse>
					<!--- finish session --->
					<!--- return 0 = OK, 1 = funds wrong, 2 = cftry failure --->

					<cfset sessionwasfinished = invoicetranxcallfinish( sessionvars.sessionid, variables.nextinvoice )>
					<!---sessionwasfinished = #sessionwasfinished#--->

					<cfif variables.sessionwasfinished neq 0>
						<cftransaction action="rollback" />

						<!--- open call was created. rollback and stop user form further actions. --->
						<CFSAVECONTENT variable="message">
						<font color="red"><strong>Session Error</strong></font><br>
						We encountered a problem during the checkout process.
                              
                              #sessionvars.sessionid# | #variables.nextinvoice# | #sessionwasfinished#
                              
                              
						</CFSAVECONTENT>

						<CFSET nobackbutton = true>
						<CFSET currentstep = 6>
						<CFSET headertitle="Transaction Not Complete">
						<CFINCLUDE template = "includes/layout.cfm">
						<CFABORT>
					</cfif>
					<cftransaction action="commit" />
				</cfif>
				<!--- end direction decision --->

			</cfif>
<!-- end processing -->





<!-- close session to prevent dups -->
<cfquery datasource="#application.dopsds#" name="closesession">
	select dops.webclosehousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no"> )
</cfquery>

<cfset str1 = result.invoicefacid & "-" & result.invoicenumber>
<CFSET CurrentInvoiceFac = result.invoicefacid>
<CFSET CurrentInvoiceNumber = result.invoicenumber>

<CFSCRIPT>
	//theKey=generateSecretKey(key); 
	encrypted=encrypt("#CurrentInvoiceFac#-#CurrentInvoiceNumber#", key, "CFMX_COMPAT", "Hex"); 
</CFSCRIPT>

<CFSAVECONTENT variable="successmessage">
Purchase complete. <a target="_blank" href="/checkout/invoice/printinvoice.cfm?i=#encrypted#"><strong>Click here</strong></a> to view invoice. Your temporary invoice number is <strong>#CurrentInvoiceNumber#</strong>. The invoice will appear in your <strong>Invoice History</strong>.<br>
</CFSAVECONTENT>

<!-- open new session -->
<cfquery datasource="#application.dopsds#" name="newsession">
	select dops.webloadhousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar" list="no"> )
</cfquery>

<CFINCLUDE template = "includes/layout.cfm">	
<!-- close transaction -->
</cftransaction>
<cfabort>










<!--- notes --->
<!--- it is assumed the team already exists as this routine only updates trteam --->
<!--- ghost card insertions and checks are handled --->
<!--- fees are derived from trteamview --->

<!--- set pmtmode as needed:
team payment only: T
ghost card only: G
both team and gh: TG
--->

<CFFUNCTION name="processteamreg" returntype="struct" output="yes">
     <CFARGUMENT name="currentsessionid" required="yes" type="string">
     <CFARGUMENT name="primarypatronid" required="yes" type="numeric">
     <CFARGUMENT name="pmtmode" required="yes" type="string">
     <CFARGUMENT name="patronid" required="yes" type="numeric">
     <CFARGUMENT name="teamid" required="yes" type="numeric">
     <CFARGUMENT name="ghostcardstobuy" required="yes" type="numeric">
     <CFARGUMENT name="totalFees" required="yes" type="numeric">
     <CFARGUMENT name="netDue" required="yes" type="numeric">
     <CFARGUMENT name="districtCreditUsed" required="yes" type="numeric">
     <CFARGUMENT name="othercreditcardid" required="yes" type="numeric">
     <CFARGUMENT name="othercreditused" required="yes" type="numeric">
     <CFARGUMENT name="contactpk" required="yes" type="numeric">
     <CFARGUMENT name="localfac" required="no" type="string" default="WWW">
     <CFARGUMENT name="testmode"  required="no" type="boolean" default="0">
     <CFSET var errormsg = "">
     <CFSET var teamsum = "">
     <CFSET var temp = "">
     <CFSET var checkfees = "">
     <CFSET var checkstatus = "">
     <CFSET var insertInvoice = "">
     <CFSET var getViewData = "">
     <CFSET var ActivityLine = 0>
     <CFSET var gllineno = 0>
     <CFSET var nextprc = 0>
     <CFSET var NextInvoice= "">
     <CFSET var totalfeesum = 0>
     <CFSET var runningtotalfeesum = 0>
     <CFSET var goahead = 0>
     <CFSET var invoicetype = "">
     <CFSET var finalcheckresult = "">
     <CFSET var tempec = 0>
     <CFSET var runningdc = arguments.districtCreditUsed>
     <CFSET var runningtx = arguments.netDue>
     <CFSET var GetGLDistCredit = "">
     <CFSET var fundsUsed = "">
     <cfset local.approved = false>
     <CFSET var fundsUsed = structnew()>
     <CFSET var response = structnew()>
     <CFSET response.auth = false>

	<!---<cfset approved = false>--->

	<cfquery datasource="#application.dopsds#" name="local.GetGLDistCredit">
		select   AcctID
		from     dops.GLMaster
		where    InternalRef = <cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfquery datasource="#application.dopsds#" name="local.CheckFees">
		select   acctid,
		         leaguefees,
		         ghostcardfee * <cfqueryparam value="#arguments.ghostcardstobuy#" cfsqltype="cf_sql_integer" list="no"> as gcfees
		from     dops.trteamview
		where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
	</cfquery>

     <cfif find("T", arguments.pmtmode) gt 0>
          <cfset temp = CheckFees.leaguefees>
     <cfelse>
          <cfset temp = 0>
     </cfif>

     <cfif find("G", arguments.pmtmode) gt 0>
          <cfset temp = local.temp + CheckFees.gcfees>
     </cfif>

     <cfif dollarRound(local.temp) neq dollarRound(arguments.totalfees) or dollarRound(local.temp) eq 0>
          <!---<cfset response.auth = 0>--->
          <cfset response.errormsg = "Specified funds did not match expected amount. #decimalformat(local.temp)# vs #decimalformat(arguments.totalfees)#.">
          <CFRETURN local.response>
     </cfif>

     <cfif arguments.pmtmode is "T" or arguments.pmtmode is "TG">
          <!--- check for already done --->
		<cfquery datasource="#application.dopsds#" name="local.CheckStatus">
			select   invoicefacid
			from     dops.trteam
			where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

          <!--- if invoicefacid is not null, already done so stop --->
          <cfif CheckStatus.invoicefacid is not "">
               <!--- failure stuff --->
               <!---<cfset response.auth = 0>--->
               <cfset response.errormsg = "Specified team has already been paid for.">
               <CFRETURN local.response>
          </cfif>

     </cfif>

		<cfset local.totalfeesum = local.CheckFees.leaguefees + local.CheckFees.gcfees>
		<cfset local.runningtotalfeesum = local.totalfeesum>

		<!--- set funds --->
		<cfset local.fundsUsed["team_dc"] = min( local.runningdc, local.CheckFees.leaguefees )>
		<cfset local.runningdc = local.runningdc - local.fundsUsed["team_dc"]>
		<cfset local.runningtotalfeesum = local.runningtotalfeesum - local.fundsUsed["team_dc"]>

		<cfset local.fundsUsed["ghost_dc"] = min( local.runningdc, local.CheckFees.gcfees )>
		<cfset local.runningtotalfeesum = local.runningtotalfeesum - local.fundsUsed["ghost_dc"]>

		<cfset local.fundsUsed["team_tx"] = min( local.runningtx, local.CheckFees.leaguefees - local.fundsUsed["team_dc"] )>
		<cfset local.runningtx = local.runningtx - local.fundsUsed["team_tx"]>
		<cfset local.runningtotalfeesum = local.runningtotalfeesum - local.fundsUsed["team_tx"]>

		<cfset local.fundsUsed["ghost_tx"] = min( local.runningtx, local.CheckFees.gcfees - local.fundsUsed["ghost_dc"] )>
		<cfset local.runningtotalfeesum = local.runningtotalfeesum - local.fundsUsed["ghost_tx"]>

		<cfif 0>
			<cfdump var="#local.fundsUsed#">
		</cfif>

		<cfif ( local.fundsUsed["team_dc"] +
				local.fundsUsed["team_tx"] +
				local.fundsUsed["ghost_dc"] +
				local.fundsUsed["ghost_tx"] neq local.CheckFees.leaguefees + local.CheckFees.gcfees )
				or
				( local.fundsUsed["team_dc"] + local.fundsUsed["ghost_dc"] neq arguments.districtCreditUsed )
				or
				( local.fundsUsed["team_tx"] + local.fundsUsed["ghost_tx"] neq arguments.netDue )
				or
				( local.fundsUsed["team_dc"] + local.fundsUsed["team_tx"] neq local.CheckFees.leaguefees )
				or
				( local.fundsUsed["ghost_dc"] + local.fundsUsed["ghost_tx"] neq local.CheckFees.gcfees )
				>
			<cfset response.errormsg = "Specified funds did not match expected amounts.">
			<CFRETURN local.response>
		</cfif>
		<!--- end set funds --->




		<!---<cfset local.fundsUsed["team_tx"] = min( local.totalfeesum - local.runningdc )>--->
		<cfset local.fundsUsed["ghost_tx"] = local.CheckFees.leaguefees + local.CheckFees.gcfees - local.runningdc>

		<cfif arguments.pmtmode is "T">
			<!--- team payment only --->
			<cfset local.invoicetype = "-TR-">
		<cfelseif arguments.pmtmode is "TG">
			<!--- team team and ghost payment --->
			<cfset local.invoicetype = "-TR-TRG-">
		<cfelseif arguments.pmtmode is "G">
			<!--- team ghost payment only --->
			<cfset local.invoicetype = "-TRG-">
		</cfif>




		<cfset local.NextInvoice = GetNextInvoice()>

		<cfif local.fundsUsed["team_tx"] + local.fundsUsed["ghost_tx"] gt 0>
			<cfset local.nextprc = getnextprc()>
		</cfif>


		<cfquery datasource="#application.dopsds#" name="local.InsertInvoice">
			insert into dops.invoice
				(
					invoicefacid,
					invoicenumber,
					totalfees,
					othercreditused,
					othercreditusedcardid,
					tenderedcc,
					usedcredit,
					node,
					primarypatronlookup,
					firstname,
					lastname,
					userid,
					primarypatronid,
					addressid,
					mailingaddressid,
					indistrict,
					insufficientid,
					startingbalance,
					invoicetype,
					prc
				)
			values
				(
					<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
					<cfqueryparam value="#local.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
					<cfqueryparam value="#arguments.totalfees#" cfsqltype="CF_SQL_MONEY">, --TotalFees

					<cfif arguments.othercreditcardid gt 0>
						<cfqueryparam value="#arguments.othercreditused#" cfsqltype="cf_sql_money" list="no">, -- othercreditused
						<cfqueryparam value="#arguments.othercreditcardid#" cfsqltype="cf_sql_integer" list="no">, -- othercreditusedcardid
					<cfelse>
						<cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">, -- othercreditused
						null, -- othercreditusedcardid
					</cfif>

					<cfqueryparam value="#arguments.netDue#" cfsqltype="CF_SQL_MONEY">, --netDue
					<cfqueryparam value="#arguments.districtCreditUsed#" cfsqltype="cf_sql_money" list="no">, -- districtCreditUsed
					<cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">, --LocalNode

					(
						select   patronlookup
						from     dops.patrons
						where    patronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="cf_sql_integer" list="no">), ( -- firstname

						select   firstname
						from     dops.patrons
						where    patronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="cf_sql_integer" list="no">), ( -- firstname

						select   lastname
						from     dops.patrons
						where    patronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="cf_sql_integer" list="no">), -- lastname

					<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --huserID
					<cfqueryparam value="#arguments.primarypatronid#" cfsqltype="cf_sql_integer" list="no">, ( -- primary

						select   addressid
						from     dops.patronrelations
						where    primarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
						and      secondarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

						select   mailingaddressid
						from     dops.patronrelations
						where    primarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
						and      secondarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

						SELECT   indistrict
						FROM     dops.patronrelations
						WHERE    primarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
						AND      secondarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

						SELECT   patrons.insufficientid
						FROM     dops.patronrelations patronrelations
						         INNER JOIN dops.patrons patrons ON patronrelations.secondarypatronid=patrons.patronid
						WHERE    patronrelations.primarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
						AND      patronrelations.secondarypatronid = <cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

						select   dops.primaryaccountbalance(<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)),

					<cfqueryparam value="#invoicetype#" cfsqltype="CF_SQL_VARCHAR">, -- invoice type(s)

					<cfif local.fundsUsed["team_tx"] + local.fundsUsed["ghost_tx"] gt 0>
						<cfqueryparam value="#local.nextprc#" cfsqltype="cf_sql_integer" list="no">
					<cfelse>
						null
					</cfif>
				)
			</cfquery>





			<cfif find("T", arguments.pmtmode) gt 0>

				<cfquery datasource="#application.dopsds#" name="local.InsertInvoice">
					update  dops.trteam
					set
						invoicefacid = <cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">,
						invoicenumber = <cfqueryparam value="#local.NextInvoice#" cfsqltype="CF_SQL_INTEGER" list="No">
					where   teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
					;

					<cfset local.nextec = getNextEC()>
					<cfset GLLineNo = local.GLLineNo + 1>

					insert into dops.GL
						(
							credit,
							acctid,
							invoicefacid,
							invoicenumber,
							entryline,
							ec,
							activitytype,
							activity
						)
					values
						(
							<cfqueryparam value="#CheckFees.leaguefees#" cfsqltype="cf_sql_money" list="no">, -- leaguefees
							<cfqueryparam value="#CheckFees.acctid#" cfsqltype="cf_sql_money" list="no">,
							<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR" list="No">, --LocalFac
							<cfqueryparam value="#local.NextInvoice#" cfsqltype="CF_SQL_INTEGER" list="No">, --NextInvoice
							<cfqueryparam value="#local.GLLineNo#" cfsqltype="CF_SQL_INTEGER" list="No">, --GLLineNo
							<cfqueryparam value="#local.nextec#" cfsqltype="CF_SQL_INTEGER" list="No">, --EC
							<cfqueryparam value="TR" cfsqltype="CF_SQL_VARCHAR" list="No">, -- activity
							<cfqueryparam value="Team Registration" cfsqltype="CF_SQL_VARCHAR" list="No">
						)
					;

					<!--- districtCreditUsage --->
					<cfif local.fundsUsed["team_dc"] gt 0>
						<!---<cfset local.thisdc = min( local.runningdc, CheckFees.leaguefees )>
						<cfset local.runningdc = local.runningdc - local.thisdc>--->
						<cfset GLLineNo = local.GLLineNo + 1>

						insert into dops.gl
							(
								debit,
								acctid,
								invoicefacid,
								invoicenumber,
								entryline,
								ec,
								activitytype,
								activity
							)
						values
							(
								<cfqueryparam value="#local.fundsUsed["team_dc"]#" cfsqltype="CF_SQL_MONEY">,
								<cfqueryparam value="#local.GetGLDistCredit.acctid#" cfsqltype="CF_SQL_INTEGER">,
								<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#local.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
								<cfqueryparam value="#local.GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
								<cfqueryparam value="#local.nextec#" cfsqltype="CF_SQL_INTEGER">,
								<cfqueryparam value="TR" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="Team Registration DC Usage" cfsqltype="CF_SQL_VARCHAR">
							)
						;
					</cfif>
					<!--- end districtCreditUsage --->


					<cfif local.fundsUsed["team_tx"] gt 0>
						;
						insert into dops.invoicetranxtrans
							(
								prc,
								inv
							)
						values
							(
								<cfqueryparam value="#local.nextprc#" cfsqltype="CF_SQL_INTEGER">,
								<cfqueryparam value="#local.nextprc#" cfsqltype="CF_SQL_INTEGER">
							)
						;

						insert into dops.invoicetranxdist
							(
								action,
								amount,
								invoicefacid,
								invoicenumber,
								primarypatronid,
								reftype,
								prc
							)
						values
							(
								<cfqueryparam value="S" cfsqltype="CF_SQL_varchar">,
								<cfqueryparam value="#local.fundsUsed["team_tx"]#" cfsqltype="CF_SQL_money">,
								<cfqueryparam value="#arguments.LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#local.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
								<cfqueryparam value="#arguments.primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
								<cfqueryparam value="TR" cfsqltype="CF_SQL_VARCHAR">,
								<cfqueryparam value="#local.nextprc#" cfsqltype="CF_SQL_INTEGER">
							)
					</cfif>

				</cfquery>

				<!---<cfif local.fundsUsed["team_tx"] gt 0>
					this routine run outside function
				</cfif>--->

			</cfif>





			<cfif find("G", pmtmode) gt 0>

				<cfquery datasource="#application.dopsds#" name="local.InsertInvoice">
				insert into dops.trghostcard
					(
						teamid,
						invoicefacid,
						invoicenumber,
						qty
					)
				values
					(
						<cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">,
						<cfqueryparam value="#arguments.localfac#" cfsqltype="cf_sql_varchar" list="no">,
						<cfqueryparam value="#local.NextInvoice#" cfsqltype="cf_sql_integer" list="no">,
						<cfqueryparam value="#arguments.ghostcardstobuy#" cfsqltype="cf_sql_integer" list="no">
					)
				;

				<cfset local.nextec = getNextEC()>
				<cfset GLLineNo = local.GLLineNo + 1>

				insert into dops.GL
					(
						credit,
						acctid,
						invoicefacid,
						invoicenumber,
						entryline,
						ec,
						activitytype,
						activity
					)
				values
					(
						(
							select   ghostcardfee * <cfqueryparam value="#arguments.ghostcardstobuy#" cfsqltype="cf_sql_integer" list="no">
							from     dops.trteamview
							where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">), ( --Totalfees

							select   acctid
							from     dops.trteamview
							where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">),

						<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR" list="No">, --LocalFac
						<cfqueryparam value="#local.NextInvoice#" cfsqltype="CF_SQL_INTEGER" list="No">, --NextInvoice
						<cfqueryparam value="#local.GLLineNo#" cfsqltype="CF_SQL_INTEGER" list="No">, --GLLineNo
						<cfqueryparam value="#local.nextec#" cfsqltype="CF_SQL_INTEGER" list="No">, --EC
						<cfqueryparam value="TRG" cfsqltype="CF_SQL_VARCHAR" list="No">, -- activity
						<cfqueryparam value="Team Registration Ghost Card" cfsqltype="CF_SQL_VARCHAR" list="No">
					)
				;

				<!--- districtCreditUsage --->
				<cfif local.fundsUsed["ghost_dc"] gt 0>
					<!---<cfset local.thisdc = min( local.runningdc, CheckFees.leaguefees )>
					<cfset local.runningdc = local.runningdc - local.thisdc>--->
					<cfset GLLineNo = local.GLLineNo + 1>

					insert into dops.gl
						(
							debit,
							acctid,
							invoicefacid,
							invoicenumber,
							entryline,
							ec,
							activitytype,
							activity
						)
					values
						(
							<cfqueryparam value="#local.fundsUsed["ghost_dc"]#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="#local.GetGLDistCredit.acctid#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#arguments.localfac#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#local.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#local.GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#local.nextec#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="TRG" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="Team Registration Ghost Card DC Usage" cfsqltype="CF_SQL_VARCHAR">
						)
					;
				</cfif>

				</cfquery>
				<!--- end districtCreditUsage --->

			</cfif>








		<cfquery datasource="#application.dopsds#" name="local.CheckTeam">
			select   ghostcardviolation
			from     dops.trteamview
			where    teamid = <cfqueryparam value="#arguments.teamid#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

          <cfif local.CheckTeam.ghostcardviolation>
               <!--- violated ghost card limit --->

               <!--- failure stuff --->

               <!---<cfset response.auth = 0>--->
               <cfset response.errormsg = "Too many ghost cards were specified.">
               <CFRETURN local.response>
           <cfelse>
               <!---cfinclude template="/portal/includes/FinalChecks.cfm">--->

			<!---
			<cfargument name="nextinvoice" required="yes" type="numeric">
			<cfargument name="tenderedcc" required="yes" type="numeric">
			<cfargument name="occardid" required="no" type="numeric" default="0">
			<cfargument name="ocused" required="no" type="numeric" default="0">--->
			<CFSET local.finalcheckresult = finalcheck( local.nextinvoice, form.netDue, form.othercreditcardid, form.othercreditused )>

			<cfif 0>
				<cfinclude template="/portalINC/displayallinvoicetables.cfm">
				<cfabort>
			</cfif>

			<CFIF local.finalcheckresult EQ "OK">

				<cfif IsDefined("arguments.TestMode") and arguments.TestMode is 1>

					<!---<cfquery datasource="#application.dopsds#" name="local.getviewdata">
						select   *
						from     dops.trteamview
						where    teamid = <cfqueryparam value="#teamid#" cfsqltype="cf_sql_integer" list="no">
					</cfquery>

					<cfif 0>
						<cfdump var="#local.getviewdata#">
					</cfif>--->

					<!---<cfinclude template="/portalINC/displayallinvoicetables.cfm">--->
					<!--- rollback in testing --->

					<cfset response.auth = true>
					<cfset response.invoiceNumber = local.NextInvoice>
					<cfset response.invoicefacid = arguments.localfac>
					<cfset response.invoicetype = local.invoicetype>
					<cfset response.prc = local.nextprc>
					<CFABORT>
					<CFRETURN response>
				<CFELSE>
					<cfset response.auth = true>
					<cfset response.invoiceNumber = local.NextInvoice>
					<cfset response.invoicefacid = arguments.localfac>
					<cfset response.invoicetype = local.invoicetype>
					<cfset response.prc = local.nextprc>
					<CFRETURN response>
				</cfif>

			<CFELSE>
				<!---<cfset response.auth = 0>--->
				<cfset response.errormsg = finalcheck.errormsg>
				<CFRETURN response>
			</CFIF>

	</cfif>



</CFFUNCTION>


</cfoutput>
