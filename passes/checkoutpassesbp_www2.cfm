<CFPARAM name="form.occardid" default="">
<CFPARAM name="form.tenderedoc" default="0">


<!--- very important - NAMING PROBLEM --->
<CFSET form.netdue = form.adjustednetdue>

<!--- not sure what is going on: commas 09.05.2017 | need to switch to don's function --->
<CFIF Isdefined("form.adjustednetdue")>
	<CFSET form.adjustednetdue = replacenocase(form.adjustednetdue,",","","all")>
</CFIF>

<CFIF Isdefined("form.netdue")>
	<CFSET form.netdue = replacenocase(form.netdue,",","","all")>
</CFIF>

<CFSETTING requesttimeout="10">

<!---cfinclude template="/common/functions.cfm" 06/12/2017 --->


<CFSET variables.primarypatronid = cookie.primarypatronid>
<CFSET form.primarypatronid = cookie.primarypatronid>
<CFSET variables.tenderedcharge = form.adjustednetdue>

<cfinclude template="/common/functionsfp.cfm">

<CFSET checksession = sessioncheck( variables.primarypatronid )>
<CFIF checksession.sessionID NEQ 0>
	<CFSET CurrentSessionID = checksession.sessionID>
     <CFSET form.CurrentSessionID = CurrentSessionID>
<CFELSE>
	<CFSET CurrentSessionID = 0>
	<!--- generic alert page --->
	<CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
	<CFABORT>
</CFIF>
<CFINCLUDE template="prechecks.cfm">

<cfif form.adjustednetdue gt 0>
     <!--- look for payment for this session --->
	<cfinclude template="/common/invoicetranxcheckforapproval_freedompay.cfm">
</cfif>



<!--- end look for payment for this session --->
<cftransaction action="BEGIN" isolation="REPEATABLE_READ">

     <CFINCLUDE template="businesslogicSQL.cfm">
     <!---
     <cfquery datasource="#application.dopsds#" name="InsertNewCard">

          <!--- application specific inserts including invoice --->

          insert into dops.invoicetranxtrans
               ( prc,
               oc )
          values
               ( <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
               <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no"> )
          ;

          insert into dops.invoicetranxdist
               ( primarypatronid,
               reftype,
               invoicefacid,
               invoicenumber,
               prc,
               amount,
               action )
          values
               ( <cfqueryparam value="#variables.thisprimarypatronid#" cfsqltype="cf_sql_integer" list="no">,
               <cfqueryparam value="OC" cfsqltype="cf_sql_varchar" list="no">,
               <cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
               <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
               <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
               <cfqueryparam value="#variables.ThisTranxAmount#" cfsqltype="cf_sql_money" list="no">,
               <cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no"> )
	</cfquery>
	--->


	<cfif form.netdue gt 0>
	<!--- direction decision --->
		<cfif not variables.approved>
		<!--- no payment found --->
			<cftransaction action="ROLLBACK" />
               <!--- build structure just to be compatable with non-patron charges --->
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
				<cfset customer.currentsessionid = form.currentsessionid>
				<cfset customer.firstname        = patroninfo.firstname>
				<cfset customer.lastname         = patroninfo.lastname>
				<cfset customer.address1         = patroninfo.address1>
				<cfset customer.address2         = patroninfo.address2>
				<cfset customer.city             = patroninfo.city>
				<cfset customer.state            = uCase( patroninfo.state )>
				<cfset customer.zip              = uCase( patroninfo.zip )>
				<cfset customer.phone            = patroninfo.contact>
				<cfset customer.email            = patroninfo.email>
				<cfset customer.amount           = form.adjustednetdue>
				<cfset customer.name             = customer.firstname & " " & customer.lastname>
				<cfset customer.callcomment      = "Pass">

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
               <cfset posturl = "checkoutpassesbp_www2.cfm">
               <CFSET payinstruct = "Click button below to make payment. Your browser will launch a new payment window or tab where you will enter credit card information. Once the credit card has been successfully processed you will receive a confirmation code, then the payment window will automatically close. After the payment window closes this page will refresh and display a link to your invoice.">
               <CFSET paynote = "Please do not open more than one payment window or attempt to pay for your gift card more than once. ">
               <CFSET gamodule = "passes">
               <cfinclude template="/common/invoicetranxcallclose_freedompay.cfm">
               <cftransaction action="commit" />
               <cfinclude template="includes/layout.cfm">
               <!--- commit insertion record --->
               <cfabort>
		<cfelse>
			<!--- finish session --->
			<!--- return 0 = OK, 1 = funds wrong, 2 = cftry failure --->
			<cfset sessionwasfinished = invoicetranxcallfinish( form.currentsessionid, variables.nextinvoice )>
			<cfif variables.sessionwasfinished neq 0>
				<!--- open call was created. rollback and stop user form further actions. --->
				<!--- this should abort? --->
				<cftransaction action="rollback" />
				Session locked.
               	<CFABORT>
			</cfif>
			<cftransaction action="commit" />
               <!--- need to take user out of session --->
               <!--- display invoice link --->
		</cfif>
	</cfif>

     <!--- the final section is for transaction where form.netdue EQ 0 or approved tranactions --->
	<!--- VERY IMPORTANT! update sessionid so they can do another transaction --->

	<!--- remove session pass data --->
	<cfquery datasource="#application.dopsds#" name="ClearSession">
		-- delete members
		delete   from dops.sessionpassmembers
		where    ec in (

		select   sessionpasses.ec
		from     dops.sessionpasses
		where    sessionpasses.sessionid = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="cf_sql_varchar" list="no"> )
		;

		-- delete passes
		delete   from dops.sessionpasses
		where    sessionid = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="cf_sql_varchar" list="no">
		;
	</cfquery>

	<!--- block current session
	<cfquery datasource="#application.dopsds#" name="ClearSession">
		-- create session blocking record
		insert into dops.sessionlock
			( sessionid,
			node,
			userid )
		values
			( <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="W1" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no"> )
	</cfquery>

		<cfset newsessionid = uCase(removeChars(application.IDmaker.randomUUID().toString(), 24, 1))>

			<CFQUERY name="newsession" datasource="#application.dopsds#">
	insert into sessions
		( sessionid )
	VALUES
		( <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> )
	;

	update sessionpatrons         set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="cf_sql_varchar" list="no">;
	update sessionpatronsorigdata set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="cf_sql_varchar" list="no">;
	update sessionquerylisting    set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="cf_sql_varchar" list="no">;
	update sessionquerywords      set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="cf_sql_varchar" list="no">;
</CFQUERY> --->



<!--- close session to prevent dups --->
<cfquery datasource="#application.dopsds#" name="closesession">
	select dops.webclosehousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no"> )
</cfquery>
<!--- open new session --->
<cfquery datasource="#application.dopsds#" name="newsession">
	select dops.webloadhousehold( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar" list="no"> )
</cfquery>

<CFSCRIPT>
	//theKey=generateSecretKey(key); 
	encrypted=encrypt("WWW-#variables.nextinvoice#", key, "CFMX_COMPAT", "Hex"); 
</CFSCRIPT>

<CFSAVECONTENT variable="successmessage">
<CFOUTPUT>Processing is complete. <a href="/checkout/invoice/printinvoice.cfm?i=#encrypted#" target="_blank">View Invoice</a><br><br>

<!--- Registration Specific Message --->


     <div style="height:200px;">&nbsp;</div>
     <hr color="##f58220" width=100% align="center" size="5px">

</CFOUTPUT>
</CFSAVECONTENT>
<CFSET nobackbutton = true>
<CFSET currentstep = 7>
<CFSET headertitle="Finished">
<CFINCLUDE template = "includes/layout.cfm">
</cftransaction>
