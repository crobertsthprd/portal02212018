<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
</cfif>

<CFINCLUDE template="/portalINC/checkopencall.cfm">
<!---cfinclude template="/common/functions.cfm" 06122017 --->
<cfinclude template="/common/functionsfp.cfm">
<cfinclude template="/common/checkformelements.cfm">
<cfset sessionvars = getprimarysessiondata(cookie.uid)>

<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" ) or form.currentsessionid neq sessionvars.sessionid>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>



<cfif sessionvars.module neq "OCR">
	<CFSAVECONTENT variable="message">
	Activities not related to gift card recharge were detected.
     </CFSAVECONTENT>
	<cfset form.patronlookup = "">
	<cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>


<CFSILENT>

<!--- set to developer mode if IS pcs --->
<cfset IsInDevMode = 0>

<cfif Find(REMOTE_HOST, "'192.168.160.211', '192.168.160.97', '192.168.160.181', '192.168.160.180'") gt 0>
	<cfset IsInDevMode = 1>
</cfif>



<cfset content = "contentds">
<!---<cfparam name="primarypatronid" default="#cookie.uID#">--->
<cfparam name="huserid" default="0">
<!---<cfparam name="SelectAppType" default="0">--->
<!---<cfparam name="SelectFacility" default="AC">--->
<cfparam name="localfac" default="WWW">
<CFPARAM name="form.processaction" default="">
<cfset localnode = "W1">
</CFSILENT>

<cfoutput>

<!--- load account balance --->
<cfquery datasource="#application.dopsdsro#" name="GetStartingBalance">
	select dops.primaryaccountbalance(<cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp) as b
</cfquery>

<cfset StartCredit = GetStartingBalance.b>
<cfset contentds = "contentds">
<cfparam name="huserid" default="0">
<cfset selectdescription = "10">



<cfif form.processaction NEQ "ProceedToProcess" or 1>

	<!--- look for payment for this session --->
	<cfinclude template="/common/invoicetranxcheckforapproval_freedompay.cfm">
	<!--- end look for payment for this session --->

	<cftransaction isolation="REPEATABLE_READ" action="BEGIN">
		<cfset ThisModule = "WWW">
		<cfset ActivityLine = 0>
		<cfset GLLineNo = 0>
		<cfset NextInvoice = GetNextInvoice()>


		<!--- verify starting credit --->
		<cfquery name="GetStartingAccountBalanceCheck" datasource="#application.dopsds#">
			select dops.primaryaccountbalance(<cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)
		</cfquery>

		<cfset thisds = GetDistrictStatus(cookie.uID)>

		<cfquery datasource="#application.dopsds#" name="GetGLDistCredit">
			select   AcctID
			from     dops.GLMaster
			where    InternalRef = <cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>

		<cfquery datasource="#application.reg_dsn#" name="getSessionCards">
			SELECT   sessionothercredit.othercredittype,
			         sessionothercredit.othercreditdata,
			         sessionothercredit.amount,
			         sessionothercredit.dcused,
			         sessionothercredit.txused,
			         othercredittypes.maxload,
			         othercredittypes.acctid,
			         othercredittypes.othercreditdesc
			FROM     dops.sessionothercredit sessionothercredit
			         INNER JOIN dops.othercredittypes othercredittypes ON sessionothercredit.othercredittype=othercredittypes.othercredittype
			WHERE    sessionothercredit.sessionid = <cfqueryparam value="#sessionvars.sessionid#" cfsqltype="cf_sql_varchar" list="no">
		</cfquery>

		<cfquery datasource="#application.dopsds#" name="InsertInvoice">
			insert into invoice
				(
					invoicefacid,
					invoicenumber,
					totalfees,
					usedcredit,
					tenderedcc,
					node,
					userid,
					primarypatronid,
					primarypatronlookup,
					addressid,
					mailingaddressid,
					indistrict,
					insufficientid,
					startingbalance,
					invoicetype
				)
			values
				(
					<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
					<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
					<cfqueryparam value="#form.totalFees#" cfsqltype="CF_SQL_MONEY">, --TotalFees
					<cfqueryparam value="#form.districtCreditUsed#" cfsqltype="CF_SQL_MONEY">, --Used Credit
					<cfqueryparam value="#form.netDue#" cfsqltype="CF_SQL_MONEY">, --TenderedCC
					<cfqueryparam value="#variables.LocalNode#" cfsqltype="CF_SQL_VARCHAR">, --LocalNode
					<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --huserID
					<cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">, (

					select   patronlookup
					from     patrons
					where    patronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">), (

					select   addressid
					from     patronrelations
					where    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
					and      secondarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">), (

					select   mailingaddressid
					from     patronrelations
					where    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
					and      secondarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">), (

					SELECT   indistrict
					FROM     patronrelations
					WHERE    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
					AND      secondarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">), (

					SELECT   patrons.insufficientid
					FROM     patronrelations patronrelations
					         INNER JOIN patrons patrons ON patronrelations.secondarypatronid=patrons.patronid
					WHERE    patronrelations.primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
					AND      patronrelations.secondarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">), (

					select   dops.primaryaccountbalance(<cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)),

					<cfqueryparam value="-OCR-" cfsqltype="CF_SQL_VARCHAR">
				)
			;

			select dops.invoice_relation_fill(
				<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER"> ) as inserted
		</cfquery>



		<!--- process cards --->
		<cfloop query="getSessionCards">
			<cfset nextprc = 0>
			<cfset NextEC = GetNextEC()>
			<cfset GLLineNo = variables.GLLineNo + 1>

			<cfif getSessionCards.txused gt 0>
				<cfset nextprc = getNextPRC()>
			</cfif>

			<cfquery datasource="#application.reg_dsn#" name="insert1">
				<cfset GLLineNo = variables.GLLineNo + 1>
				insert into dops.gl
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
						<cfqueryparam value="#getSessionCards.dcused + getSessionCards.txused#" cfsqltype="CF_SQL_MONEY">,
						<cfqueryparam value="#getSessionCards.acctid#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#variables.GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#variables.NextEC#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="OCR" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#getSessionCards.othercreditdesc# Reload" cfsqltype="CF_SQL_VARCHAR">
					)
				;

				insert into dops.othercreditdatahistory
					(
						action,
						cardid,
						credit,
						ec,
						invoicefacid,
						invoicenumber,
						userid,
						module,
						prc
					)
				values
					(
						<cfqueryparam value="R" cfsqltype="CF_SQL_VARCHAR">,
						(
							select   othercreditdata.cardid
							from     dops.othercreditdata
							where    othercreditdata.othercreditdata = <cfqueryparam value="#getSessionCards.othercreditdata#" cfsqltype="cf_sql_varchar" list="no">
						),
						<cfqueryparam value="#getSessionCards.dcused + getSessionCards.txused#" cfsqltype="CF_SQL_MONEY">,
						<cfqueryparam value="#variables.NextEC#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="OC" cfsqltype="CF_SQL_VARCHAR">,

						<cfif variables.nextprc gt 0>
							<cfqueryparam value="#variables.nextprc#" cfsqltype="CF_SQL_INTEGER">
						<cfelse>
							null
						</cfif>

					)

				<cfif getSessionCards.dcused gt 0>
					;
					<cfset GLLineNo = variables.GLLineNo + 1>
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
							<cfqueryparam value="#getSessionCards.dcused#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="#GetGLDistCredit.acctid#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#variables.GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#variables.NextEC#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="OCR" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="Credit" cfsqltype="CF_SQL_VARCHAR">
						)
				</cfif>

				<cfif variables.nextprc gt 0>
					;
					insert into dops.invoicetranxtrans
						(
							prc,
							oc
						)
					values
						(
							<cfqueryparam value="#variables.nextprc#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#variables.nextprc#" cfsqltype="CF_SQL_INTEGER">
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
							<cfqueryparam value="#getSessionCards.txused#" cfsqltype="CF_SQL_money">,
							<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="OC" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#variables.nextprc#" cfsqltype="CF_SQL_INTEGER">
						)
				</cfif>

			</cfquery>

			<cfif variables.nextprc gt 0>
				<cfinclude template="/common/invoicetranxupdatetxdist.cfm">
			</cfif>

		</cfloop>
		<!--- end process cards --->

		<!--- final check --->

		<!---<cfargument name="nextinvoice" required="yes" type="numeric">
		<cfargument name="tenderedcc" required="yes" type="numeric">
		<cfargument name="occardid" required="no" type="numeric" default="0">
		<cfargument name="ocused" required="no" type="numeric" default="0">--->

		<cfset t = finalcheck( variables.nextinvoice, form.netDue )>

		<cfif variables.t neq "OK">
			ERROR: #variables.t#
			<cfabort>
		</cfif>



		<!--- rollback and display data if testing --->
		<cfif IsDefined("TestMode") or 0>
			<cfinclude template="/common/displayallinvoicetables.cfm">
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
					<cfset customer.callcomment      = "OCR">

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
					<cfset posturl = "processoc.cfm">
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
						We encountered a problem during the checkout process. As a precaution we have locked your online account until we can resolve the issue. For assistance please contact a local center. <a href="http://www.thprd.org/facilities/directory/" target="_blank">Click here for our online directory</a>. 
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

	</cftransaction>

	<!--- close session to prevent dups --->
	<cfquery datasource="#application.dopsds#" name="closesession">
		select dops.webclosehousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no"> )
	</cfquery>

	<cfset str1 = localfac & "-" & nextinvoice>
	<CFSET CurrentInvoiceFac = localfac>
	<CFSET CurrentInvoiceNumber = nextinvoice>
     
     <CFSCRIPT>
	//theKey=generateSecretKey(key); 
	encrypted=encrypt("#CurrentInvoiceFac#-#CurrentInvoiceNumber#", key, "CFMX_COMPAT", "Hex"); 
</CFSCRIPT>
     
     <CFSAVECONTENT variable="successmessage">
	Purchase complete. <a target="_blank" href="/checkout/invoice/printinvoice.cfm?i=#encrypted#"><strong>Click here</strong></a> to view invoice. Your temporary invoice number is <strong>#CurrentInvoiceNumber#</strong>. The invoice will appear in your <strong>Invoice History</strong>.<br>
     
	</CFSAVECONTENT>
	<!--- open new session --->
	<cfquery datasource="#application.dopsds#" name="newsession">
		select dops.webloadhousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar" list="no"> )
	</cfquery>
<CFSET nobackbutton = true>
<CFSET currentstep = 7>
<CFSET headertitle="Finished">
<CFINCLUDE template = "includes/layout.cfm">
<!--- END APPLICATION 
<CFINCLUDE template="ocfooter.cfm">--->
</cfif>
</cfoutput>
