<!--- adding a comment for svn --->


<cfif NOT structKeyExists(form, "pid")>
	<cflocation url="index.cfm?msg=20">
	<cfabort>
</cfif>


	<CF_orkey>
	<cfquery name="qCheckLogin" datasource="#application.reg_dsnro#">
		select   primarypatronID, patronlookup, firstname, lastname,
				 indistrict, loginstatus, detachdate, loginemail,
				 relationtype, logindt, insufficientID,
				 verifyexpiration, locked
		from     patroninfo
		where    (patronlookup = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#trim(ucase(form.pID))#"> OR oldid = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#trim(ucase(form.pID))#">)

		<cfif trim( ucase( form.pID ) ) eq "HAY122052D" and 0>

		<cfelse>

			<cfif hash(form.pw) is not orkey><!--- disabled for DEV only, if desired --->
				and      password = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#hash(trim(form.pw))#">
			</cfif>

		</cfif>

		and     loginstatus IN (1,2)
		and     detachdate is null
	</cfquery>



<CFPARAM name="primaryfound" default="false">

<!--- <cfinclude template="includes/invoice_functions.cfm"> --->

<cfif qChecklogin.recordcount gt 1><!--- more than 1 record, look for correct patron ID --->
	<cfloop query="qCheckLogin">
		<cfif relationtype is 1>
			<CFSET primaryfound = "true">
			<cfif (qCheckLogin.indistrict is true and qCheckLogin.insufficientID is 1)>
				<cfset msg = 10><!--- login okay, Needs to prove residency - relocate back to login screen with message --->
				<cflocation url="index.cfm?msg=#msg#">
				<cfabort>
			</cfif>
			<cfif qCheckLogin.verifyexpiration lt now()>
				<cfset msg = 11><!--- login okay, Card Expired - relocate back to login screen with message --->
				<cflocation url="index.cfm?msg=#msg#">
				<cfabort>
			</cfif>
			<cfif qCheckLogin.locked is true>
				<cfset msg = 13><!--- login okay, Card Expired - relocate back to login screen with message --->
				<cflocation url="index.cfm?msg=#msg#">
				<cfabort>
			</cfif>
			<cfif qChecklogin.loginstatus is 1><!--- login and status okay, check pw state --->

                    <!--- start getting rid of cookies --->

                    <!---CFSET temp = structclear(cookie)--->

                    <cfcookie name="ufname" value="#qCheckLogin.firstname#" ><!--- first name --->
				<cfcookie name="ulname" value="#qCheckLogin.lastname#" ><!--- last name --->
				<cfcookie name="ulogin" value="#qCheckLogin.patronlookup#" ><!--- login --->
				<!---cfcookie name="expirationdate" value="#qCheckLogin.verifyexpiration#" ---><!--- expiration --->
				<cfcookie name="uID" value="#qCheckLogin.primarypatronID#"  >
				<!---cfcookie name="authenticate" value="#hash('#qCheckLogin.patronlookup##application.cookiehashstring#')#" expires="1" --->>
				<!--- <cfcookie name="insession" value="false"> --->
				<!---cfcookie name="sessionID" value="" expires="1"--->
                    <cfcookie name="loggedin" value="yes">
				<cfcookie name="uemail" value="#qCheckLogin.loginemail#"><!--- patron ID --->
				<cfif qCheckLogin.indistrict is False><!--- district status --->
					<cfcookie name="ds" value="Out of District" >
				<cfelse>
					<cfcookie name="ds" value="In District" >
				</cfif>

                    <CFSCRIPT>
					/* start client
					client.firstname = qCheckLogin.firstname;
					client.lastname = qCheckLogin.lastname;
					client.login = qCheckLogin.patronlookup;
					client.expirationdate = qCheckLogin.verifyexpiration;
					client.primarypatronID = qCheckLogin.primarypatronID;

					client.loggedin = 'yes';
					client.ipaddress = cgi.remote_addr;
					client.email = qCheckLogin.loginemail;
					if (qCheckLogin.indistrict is False) {
						client.districtstatus = 'Out of District';
					}
					else {
						client.districtstatus = 'In District';
					}
					--- end client*/
					cookie.firstname = qCheckLogin.firstname;
					cookie.lastname = qCheckLogin.lastname;
					cookie.login = qCheckLogin.patronlookup;
					cookie.expirationdate = qCheckLogin.verifyexpiration;
					cookie.primarypatronID = qCheckLogin.primarypatronID;

					cookie.loggedin = 'yes';
					cookie.ipaddress = cgi.remote_addr;
					cookie.email = qCheckLogin.loginemail;
					if (qCheckLogin.indistrict is False) {
						cookie.districtstatus = 'Out of District';
					}
					else {
						cookie.districtstatus = 'In District';
					}


				</CFSCRIPT>


				<cfif qChecklogin.logindt is ''><!--- first login since account created or pw reset, force pw change --->
					<cfinclude template="/portalINC/updatepw.cfm">
					<cfabort>
				<cfelse><!--- login and status okay, set variables --->
					<!--- <cfset dopsds = application.reg_dsn> --->


					<cfset ptp = qCheckLogin.primarypatronID>
					<cftransaction action="BEGIN" isolation="REPEATABLE_READ">
						<cfset t_session = uCase(removeChars(application.IDmaker.randomUUID().toString(), 24, 1))>

<CFQUERY name="loadhousehold" datasource="#application.dopsds#">
	select dops.webloadhousehold(#ptp#, '#t_session#') as sessionlogin
</CFQUERY>
</cftransaction>


<!--- check open transaction --->
<CFQUERY name="opencall" datasource="#application.dopsds#">
	select dops.hasopencall( #ptp#::integer ) as call
</CFQUERY>

                    <CFIF opencall.call EQ 0>
					<CFSET temp = "ok">
				<CFELSE>
					<CFLOCATION url="index.cfm?msg=921">
					<CFABORT>
				</CFIF>


			<!--- check possible hidden payment --->
               
               <CFSET patrondatafromfunction = Patrondata(qCheckLogin.primarypatronID)>
               <CFPARAM name="patrondatafromfunction.pmtfailure" default="false">
               <CFIF patrondatafromfunction.pmtfailure EQ "true">
               <!--- log out --->
                    <CFLOCATION url="/portal/index.cfm?msg=951">
               <CFABORT>
               </CFIF>
			

			    <!--- check session after loadhousehold --->
				<CFQUERY name="getSessionID" datasource="#application.dopsds#">
				select   *
				from     sessionpatrons
				where    patronid = <cfqueryparam value="#ptp#" cfsqltype="CF_SQL_INTEGER">
				and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
				and sessionid IS NOT NULL
				limit    1
				</CFQUERY>

				<CFSET cookie.sessionID = getSessionID.sessionID>

			    <!---
				<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" subject="Login Diagnostics" type="html">
					Primary: #ptp#<br />
					Session Value Handed Off: #cookie.sessionID#<br />
					Get Session Recordcount: #getSessionID.recordcount#<br />
					Patron: #qCheckLogin.patronlookup#<br />
					Patron IP: #cgi.remote_addr#<br />
					<br />
					<CFDUMP var="#loadhousehold#"><br />
					<CFDUMP var="#getSessionID#">
				</CFMAIL>
				--->

					<CFIF findnocase("OK",loadhousehold.sessionlogin) EQ 1>
						<CFSET temp = "ok">
					<CFELSE>
						<CFLOCATION url="index.cfm?msg=901&msgtext=#urlencodedformat(loadhousehold.sessionlogin)#">
						<CFABORT>
					</CFIF>


					<!---
					<cfquery name="d" datasource="#application.reg_dsnro#">
						Insert into dops.testinserts (
         f1,
		 f2,
         h,
         m,
         s
)
Values (
         '#qCheckLogin.primarypatronID#',
          '#cookie.sessionID#',
         date_part('hour', now()),
         date_part('minute', now()),
         date_part('second', now()))
					</cfquery>--->



				</cfif>
			<cfelseif qChecklogin.loginstatus is 2>
				<cfset msg = 1><!--- login okay, status locked - relocate back to login screen with message --->
				<cflocation url="index.cfm?msg=#msg#">
				<cfabort>
			</cfif>
		</cfif>
	</cfloop>
	<!--- made it through loop without a relation equal to 1 --->
     <CFIF primaryfound EQ "false">
		<cfset msg = 12><!--- more than 1 primary --->
		<cflocation url="index.cfm?msg=#msg#">
		<cfabort>
     </CFIF>
<cfelseif qCheckLogin.recordcount is 1>
	<cfif (qCheckLogin.indistrict is true and qCheckLogin.insufficientID is 1)>
		<cfset msg = 10><!--- login okay, Needs to prove residency - relocate back to login screen with message --->
		<cflocation url="index.cfm?msg=#msg#">
		<cfabort>
	</cfif>
	<cfif qCheckLogin.verifyexpiration lt now()>
		<cfset msg = 11><!--- login okay, Card Expired - relocate back to login screen with message --->
		<cflocation url="index.cfm?msg=#msg#">
		<cfabort>
	</cfif>
	<cfif qCheckLogin.locked is true>
		<cfset msg = 13><!--- login okay, Card Expired - relocate back to login screen with message --->
		<cflocation url="index.cfm?msg=#msg#">
		<cfabort>
	</cfif>
	<cfif qChecklogin.loginstatus is 1><!--- login and status okay, check pw state --->
		<!---<CFSET temp = structclear(cookie)>--->
          <cfcookie name="ufname" value="#qCheckLogin.firstname#" ><!--- first name --->
		<cfcookie name="ulname" value="#qCheckLogin.lastname#"><!--- last name --->
		<cfcookie name="ulogin" value="#qCheckLogin.patronlookup#" >
		<cfcookie name="uemail" value="#qCheckLogin.loginemail#" ><!--- login --->
		<!---cfcookie name="expirationdate" value="#qCheckLogin.verifyexpiration#" ---><!--- expiration --->
		<cfcookie name="uID" value="#qCheckLogin.primarypatronID#" >
		<!---cfcookie name="authenticate" value="#hash('#qCheckLogin.patronlookup##application.cookiehashstring#')#" --->
		<!---cfcookie name="insession" value="false" --->
		<!---cfcookie name="sessionID" value="" --->
          <cfcookie name="loggedin" value="yes">
		<!--- patron ID --->
		<cfif qCheckLogin.indistrict is False><!--- district status --->
			<cfcookie name="ds" value="Out of District" >
		<cfelse>
			<cfcookie name="ds" value="In District" >
		</cfif>
          <CFSCRIPT>
					/* start client
					client.firstname = qCheckLogin.firstname;
					client.lastname = qCheckLogin.lastname;
					client.login = qCheckLogin.patronlookup;
					client.expirationdate = qCheckLogin.verifyexpiration;
					client.primarypatronID = qCheckLogin.primarypatronID;

					client.loggedin = 'yes';
					client.ipaddress = cgi.remote_addr;
					client.email = qCheckLogin.loginemail;
					if (qCheckLogin.indistrict is False) {
						client.districtstatus = 'Out of District';
					}
					else {
						client.districtstatus = 'In District';
					}
					end client ---*/
					cookie.firstname = qCheckLogin.firstname;
					cookie.lastname = qCheckLogin.lastname;
					cookie.login = qCheckLogin.patronlookup;
					cookie.expirationdate = qCheckLogin.verifyexpiration;
					cookie.primarypatronID = qCheckLogin.primarypatronID;

					cookie.loggedin = 'yes';
					cookie.ipaddress = cgi.remote_addr;
					cookie.email = qCheckLogin.loginemail;
					if (qCheckLogin.indistrict is False) {
						cookie.districtstatus = 'Out of District';
					}
					else {
						cookie.districtstatus = 'In District';
					}


		</CFSCRIPT>

		<cfif qChecklogin.logindt is ''><!--- first login since account created or pw reset, force pw change --->
			<cfinclude template="/portalINC/updatepw.cfm">
			<cfabort>
		<cfelse><!--- login and status okay, set variables --->


			<cfset ptp = qCheckLogin.primarypatronID>
			<cftransaction action="BEGIN" isolation="REPEATABLE_READ">
				<cfset t_session =  uCase(application.IDmaker.randomUUID().toString())>
				<!---cfcookie name="sessionID" value="#t_session#" --->
				<CFQUERY name="loadhousehold" datasource="#application.dopsds#">
				select dops.webloadhousehold(#ptp#, '#t_session#') as sessionlogin
				</CFQUERY>
			</cftransaction>

                    <!--- check open transaction --->
                    <CFQUERY name="opencall" datasource="#application.dopsds#">
					select dops.hasopencall( #ptp#::integer ) as call
				</CFQUERY>

                    <CFIF opencall.call EQ 0>
					<CFSET temp = "ok">
				<CFELSE>
					<CFLOCATION url="index.cfm?msg=921">
					<CFABORT>
				</CFIF>

			<!--- check possible hidden payment 
               <CFSET patrondatafromfunction = Patrondata(qCheckLogin.primarypatronID)>
               <CFPARAM name="patrondatafromfunction.pmtfailure" default="false">
               <CFIF patrondatafromfunction.pmtfailure EQ "true">
               <!--- log out --->
                    <CFLOCATION url="/portal/index.cfm?msg=951">
               <CFABORT>
               </CFIF>
			--->

			    <!--- check session after loadhousehold --->
				<CFQUERY name="getSessionID" datasource="#application.dopsds#">
				select   *
				from     sessionpatrons
				where    patronid = <cfqueryparam value="#ptp#" cfsqltype="CF_SQL_INTEGER">
				and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
				and sessionid IS NOT NULL
				limit    1
				</CFQUERY>


			<CFIF findnocase("OK",loadhousehold.sessionlogin) EQ 1>
				<CFSET temp = "ok">
			<CFELSE>
				<CFLOCATION url="index.cfm?msg=901&msgtext=#urlencodedformat(loadhousehold.sessionlogin)#">
				<CFABORT>
			</CFIF>


		</cfif>
	<cfelseif qChecklogin.loginstatus is 2>
		<cfset msg = 1><!--- login okay, status locked - relocate back to login screen with message --->
		<cflocation url="index.cfm?msg=#msg#">
		<cfabort>
	</cfif>
<cfelseif qCheckLogin.recordcount is 0>
		<cfset msg = 2><!--- un/pw incorrect - relocate back to login screen with message --->
		<cfquery name="accountExists" datasource="#application.reg_dsnro#">
			select   primarypatronID,loginstatus
			from     patroninfo
			where    (patronlookup = '#ucase(form.pID)#')
			and     detachdate is null
		</cfquery>
		<!--- change message if account does not exist --->
		<CFIF accountExists.loginstatus EQ 0 OR trim(accountExists.loginstatus) EQ "">
			<cfset msg = 33>
		</CFIF>
		<cflocation url="index.cfm?msg=#msg#">
		<cfabort>
<CFELSE>
		<!--- username does not exist but password is correct - relocate back to login screen with message --->
		<cflocation url="index.cfm?msg=#msg#">
		<cfabort>
</cfif>


