
<CFIF not structkeyexists(form,"primarypatronid")>

<CFSAVECONTENT variable="message">
<font color="red"><strong>Possible Processing Error</strong></font><br>
<p>Our apologies. If you found yourself here after clicking the <strong>Make Payment</strong> on the payment gateway page
there may be a browser compatibility issue. If you left the window open for longer than 10 minutes the gateway has timed out.</p>

<p>Please check your <a href="/portal/leagues/index.cfm"><strong>league registration status</strong></a> and <a href="/portal/history/patronhistory.cfm?DisplayMode=I"><strong>invoice history</strong></a> before attempting another payment.</p>
</CFSAVECONTENT>

<CFINCLUDE template="includes/layout.cfm">

<CFMAIL to="dhayes@thprd.org" cc="croberts@thprd.org" subject="League Checkout: Out of sequence GET request to thprd main checkout page" type="html" from="webadmin@thprd.org">

This message is sent when processleagueBP_www.cfm receives a GET request and form is undefined.
<br>
<CFDUMP var="#form#">
<hr>
<CFDUMP var="#url#">
<hr>
<CFDUMP var="#cgi#">
<hr>
<CFDUMP var="#cookie#">

</CFMAIL>

<CFABORT>
</CFIF>


<CFINCLUDE template="section1_arraystuff_processleagueBP_www.cfm">
<CFINCLUDE template="section2_arraystuff_processleagueBP_www.cfm">




<!---cfinclude template="/common/functions.cfm" 06.12.2017--->
<cfinclude template="/common/functionsfp.cfm">

<CFSET variables.primarypatronid = cookie.primarypatronid>
<CFSET form.primarypatronid = cookie.primarypatronid>
<CFSET variables.tenderedcharge = form.adjustednetdue>


<cfif variables.tenderedcharge gt 0>
     <!---
     <cfif sessioniscomplete( form.currentsessionid )>
     	<CFSET data=completedsessiondata(form.currentsessionid)>
     	<CFLOCATION URL="giftcard_sessioncomplete.cfm?invoiceID=#data.invoicenumber#">
		<cfabort>
	</cfif>
	--->

     <!---// must confirm user is in WWW session before continuing //--->
	<CFSET checksession = sessioncheck( variables.primarypatronid )>
	<CFIF checksession.sessionID NEQ 0>
		<CFSET CurrentSessionID = checksession.sessionID>
          <!--- this needs to be passed ---><CFSET form.CurrentSessionID = CurrentSessionID>
		<CFELSE>
		<CFSET CurrentSessionID = 0>
		<!--- generic alert page --->
		<CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
		<CFABORT>
	</CFIF>

     <!--- look for payment for this session --->
	<cfinclude template="/common/invoicetranxcheckforapproval_freedompay.cfm">
</cfif>


<!--- without cart it is impossible to match a session id to something to purchase
the enrollment checks will prevent duplication

<CFDUMP var="#form#">
<CFDUMP var="#checksession#">

--->



     <!--- end look for payment for this session --->
<cftransaction action="BEGIN" isolation="REPEATABLE_READ">

     <CFSET variables.ccnum="">
     <cfset variables.localnode = "W1">

     <CFINCLUDE template="sql_businesslogic_processleagueBP_www.cfm">



	<cfif form.netdue gt 0>

                        <cfset commentstr = 'League Registration (PatronID => League:School:Tshirt:PreferredCoach): <ul>'>

                        <cfset sarray = listtoarray(form.selectschool, ',')>
                        <cfset larray = listtoarray(form.selectapptype, ',')>
                        <cfset tarray = listtoarray(form.selectshirt, ',')>

                        <cfloop from="1" to="#arraylen(sarray)#" index="i">
                                <cfif sarray[i] neq '0^0'>
                                        <cfset variable.pid = listgetat(sarray[i], 1, '^')>
                                        <cfset variable.sid = listgetat(sarray[i], 2, '^')>
                                        <cfset variable.lid = listgetat(larray[i], 2, '^')>
                                        <cfset variable.tid = listgetat(tarray[i], 2, '^')>
                                        <cfset variable.cid = 'preferredcoach' & variable.pid>
                                        <!--- BUG FIX 11/2/2017 || array include patron members not involved in registration --->
                                        <CFIF Isdefined("form.#variable.cid#")>
									<CFSET coach = evaluate("form.#variable.cid#")>
                                        <CFELSE>
									<CFSET coach = "not defined">
                                        </CFIF>
                                        
                                        <cfset commentstr = commentstr & '<li>' & variable.pid & ' => ' & variable.lid & ':' & variable.sid & ':' & variable.tid & ':' & coach & '</li>'>
                                </cfif>
                        </cfloop>
                        <cfset commentstr = commentstr & '</ul>'>
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
				<cfset customer.callcomment      = variables.commentstr>

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
               <cfset posturl = "processleagueBP_www.cfm">
               <CFSET payinstruct = "Click button below to make payment. Your browser will launch a new payment window or tab where you will enter credit card information. Once the credit card has been successfully processed you will receive a confirmation code, then the payment window will automatically close. After the payment window closes this page will refresh and display a link to your invoice.">
               <CFSET paynote = "Please do not open more than one payment window or attempt to pay for your gift card more than once. ">
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
               <!--- display happens on calling page giftcard_process.cfm | could be done here --->
               <cfset newsessionid = uCase(removeChars(application.IDmaker.randomUUID().toString(), 24, 1))>

<!--- don't know if this is correct
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

		</cfif>
	</cfif>
</cftransaction>

