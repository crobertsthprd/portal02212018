<cfcomponent displayname="MyPortal" output="true" hint="Handle the application." bindingname="portal">
	<!--- Set up the application. --->
	<cfset THIS.Name = "PortalCFC" />
	<cfset THIS.ApplicationTimeout = CreateTimeSpan( 0, 1, 0, 0 ) />
	<cfset THIS.SessionManagement = false />
	<cfset THIS.ClientManagement = false />
	<cfset THIS.SetClientCookies = false />
	<cfset registrationconfig = "false" />
	<!--- Define the page request properties. --->
	<cfsetting requesttimeout="20" showdebugoutput="false" enablecfoutputonly="false" />
	
	<cffunction name="OnApplicationStart" access="public" returntype="boolean" output="false" hint="Fires when the application is first created.">
		<!---// set application scoped values //---><cfset application.dsn="contentds">
		<cfobjectcache action="clear">
		<cfset application.reg_dsn = "dopsds">
		<cfset application.reg_dsnro = "dopsds">
		<cfset application.contentproductionds = "contentds">
		<cfset application.contentds = "contentds">
		<cfset application.contentdsro = "contentds">
		<cfset application.dopsdsro = "dopsds">
		<cfset application.dopsds ="dopsds">
		<!---<cfset application.slavedopsds ="slavedopsds">--->
		<cfset application.slavedopsds ="dopsds">
		<cfset application.common_dsn ="commonds"> 
		<cfset application.classsearchslave_dsn ="dopsds">
		<cfset application.classsearchproduction_dsn ="dopsds"> 
		<CFSET application.webimages = "/webimages">
		<CFSET application.webmasterIP = "192.168.164.187">
		<CFSET application.developerIP = "192.168.160.92,192.168.160.97,192.168.160.180,192.168.160.181,208.71.201.1,192.168.164.78,192.168.165.59,192.168.164.187">
		<CFSET application.documentServerIP = "192.168.160.25">
		<CFSET application.proxyServerIP = "192.168.160.2">
		<CFSET application.newinternalIP = "192.168.224.180">
		<CFSET application.internalIP = "192.168.224.180">
		<CFSET application.devIP = "192.168.160.33">
		<CFSET application.externalIP = "192.168.7.2">
		<CFSET application.publicIP = "208.71.201.29">
          <CFSET application.erroremail1 = "dhayes@thprd.org">
          <CFSET application.erroremail2 = "croberts@thprd.org">
		<cfset application.productionserver = true>
		<cfset application.cookiehashstring = "alagadsubversion#month(now())#">
		<cfset application.maildebugmode = "">
		<cfset application.maxregusers="200">
          <!--- must be set in checkout as well --->
          <CFSET application.invoicekey = "lastset02092017">
		<CFIF cgi.server_addr EQ application.devIP>
			<cfset application.devconfig = "true">
		<CFELSE>
			<cfset application.devconfig = "false">	
		</CFIF>
		<!---// create objects //--->
		<cfset application.IDmaker = createobject("java", "java.util.UUID") />
		<cfset application.contentPickerPortal = createObject("component", "wwwcom.contentnew") />
		<cfset application.functions = createObject("component","portalINC.functions") />
		<cfset application.laststart = now()>
          <cfset application.daysclasssearchavailable = 40>
          <cfset application.serverAddress = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostAddress()>
          
          <CFIF application.serverAddress EQ "208.71.201.21">
          	<CFSET application.whoami = "cf2">
          <CFELSEIF application.serveraddress EQ "208.71.201.27">
          	<CFSET application.whoami = "cf4">
          <CFELSEIF application.serveraddress EQ "208.71.201.22">
          	<CFSET application.whoami = "cf1">
          <CFELSEIF application.serveraddress EQ "208.71.201.26">
          	<CFSET application.whoami = "cf3">
          <CFELSE>
          	<CFSET application.whoami = "iwww">
          </CFIF>
		
          
          <!--- query db to see where we should checkout // NOT USES --->
		<CFSET application.checkouturl = "https://checkout.thprd.org/checkout/portal/process.cfm">
          

		
          <CFQUERY name="application.regday" datasource="#application.dopsds#" cachedwithin="#CreateTimeSpan(1, 0, 0, 0)#">
			Select   exists(
select   termid
from     dops.webterms
where    ( current_date = allowweb::date
or       current_date = allowoddt::date )
and      date_part( 'hour', now() ) between 7 and 12 ) as isregday
               
		</CFQUERY>
          
          <CFIF application.regday.isregday EQ true>
          	<CFSET application.checkoutonclick = "manualcall">
          <CFELSE>
          	<CFSET application.checkoutonclick = "nodelay">
          </CFIF>
          
		<CFQUERY name="application.getrange" datasource="#application.dopsds#" cachedwithin="#CreateTimeSpan(1, 0, 0, 0)#">
			select * from othercredittypes
			where othercredittype = 'GC'
		</CFQUERY>
		<CFQUERY name="application.getmailadmin" datasource="#application.dopsds#" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
			Select varvalue
			from   systemvars
			where  varname = 'GiftCardNotificationEmail'
		</CFQUERY>
		<CFSET application.giftcardNotify = application.getmailadmin.varvalue>
		<CFSET application.gcmax = application.getrange.maxload>
		<CFIF application.gcmax EQ 0>
			<CFSET application.gcmax = 500>
		</CFIF>
		<CFSET application.gcissuemin = application.getrange.minissueval>
		<CFSET application.gcreloadmin =application.getrange.minreloadval>
		<!--- set max since db sets it to zero --->
		<CFIF application.gcmax EQ 0>
			<CFSET application.gcmax = 500>
		</CFIF>
		
		<cfquery datasource="#application.dopsds#" name="GetSessionExpireTime" cachedwithin="#CreateTimeSpan(1, 0, 0, 0)#">
			select   varvalue as minutes
			from     systemvars
			where    varname = 'WebMaxTimeoutAsString'
		</cfquery>
		<CFSET application.sessionInterval = GetSessionExpireTime.minutes>		
		
		<cfreturn true />
	</cffunction>
	
	<cffunction	name="OnSessionStart" access="public" returntype="void" output="false" hint="Fires when the session is first created.">
		<cfset application.sessionstatus = 'started'>
		<cfreturn />
	</cffunction>
	
	<cffunction name="OnRequestStart" access="public" returntype="boolean" output="false" hint="Fires at first part of page processing.">
		
          <cfargument	name="TargetPage" type="string" required="true"	/>
		<cfsetting requesttimeout="20" showdebugoutput="false" enablecfoutputonly="false" />
         
		<!--- manual setting --->
		<CFIF 0 EQ application.devIP>
			<CFSETTING showdebugoutput="yes">
		</CFIF>
		
		<!---// Relocated into onRequestStart by Alagad //--->
		<CFIF findnocase("thprd.com",cgi.SERVER_NAME) GT 0>
			<CFLOCATION url="http://www.thprd.org">
		</CFIF>	
		
          <CFIF cgi.remote_addr EQ "178.255.82.66">
			<CFLOCATION url="https://www.thprd.org/portal/offline.cfm">
		</CFIF>
          
		<CFIF cgi.server_port NEQ "443">
			<CFLOCATION url="https://www.thprd.org/portal/">
		</CFIF>	
		
          <CFIF application.serverAddress EQ "192.168.224.180">
          	<CFSET application.portalstatus = "open">
          	<CFSET application.closuremessage="">
			<CFSET application.closuremessage = "NOTICE: Online registration will be unavailable today from 9:00 p.m to 12:00 midnight - Tuesday August 1, 2017.">
          <CFELSE>
          	<CFSET application.portalstatus = "open">
          	<CFSET application.closuremessage="">
			<CFSET application.closuremessage = "NOTICE: Online registration will be unavailable today from 9:00 p.m to 12:00 midnight - Tuesday August 1, 2017.">
          </CFIF>
          
          <!---
          <CFIF datecompare(now(),"{ts '2017-08-01 21:00:00'}","s") GT 0 and datecompare(now(),"{ts '2017-08-01 23:59:59'}","s") LT 0>
			<CFSET application.portalstatus = "closed"> <!--- closed --->
  		<CFELSE>
          	<CFSET application.portalstatus = "closurepending"> 
          </CFIF>
          --->
          
		<!---// Copy the functions from our application.functions new variable
		to the local variables scope rather than recreating on each
		request //--->		
          
          <!------><CFINCLUDE template="/common/functionsv2.cfm">
          <!--- deprecated may break everything // 06/12/2017 
		<cfloop list="#structKeyList(application.functions)#" index="i">
			<cfset variables[i] = application.functions[i] />
		</cfloop>--->
		
		<!---// Added by Alagad: Allow a url parm of init=true to 
				force onApplicationStart to recreate objects to be 
				re-used throughout the web site //--->
		<cfif structKeyExists(url, "init") AND url.init eq 'true'>
			<cfset onApplicationStart() />
               <CFMAIL to="croberts@thprd.org" from="webadmin@thprd.org" subject="Manual Restart">
               #cgi.server_addr#
               Will be blank on 32. Change to Java.
               </CFMAIL>
		</cfif>

		<cfif datediff('n',application.laststart,now()) GT 60>
			<cfset onApplicationStart() />
		</cfif>

		<cfparam name="request.filepath" default="/srv/www/htdocs/www">
		<cfparam name="request.webdir" default="portal">
		<cfparam name="request.webportal" default="https://www.thprd.org/portal/">
		<cfparam name="request.imagedir" default="/portal/images">
		<cfparam name="request.classes" default="/portal/classes">
		<cfset request.searchreturnqty = 5>

		<cfif (NOT structkeyexists(cookie,'loggedin') OR cookie.loggedin is 'no') and NOT structkeyexists(form,"pID") and findnocase('/portal/index.cfm',cgi.script_name) EQ 0 and findnocase('/portal/newuser.cfm',cgi.script_name) EQ 0>
			<cfset cookie.loggedin = "pending">
			<cflocation url="index.cfm?notauthorized=true&source=app202">
			<cfabort>
		</cfif>
		
		<cf_skey>
		<cfset key = skey>
		<cfset UseNewCodeMethod = 1>
		
		<!---cferror type="request" template="/portal/errorrequest.html"--->
		<!--- Return out. --->
		<cfreturn true />
	</cffunction>
	
	<cffunction	name="OnRequest" access="public" returntype="void" output="true" hint="Fires after pre page processing is complete.">
		<cfargument	name="TargetPage" type="string" required="true"	/>
		<cfinclude template="#arguments.TargetPage#" />
		<cfreturn />
	</cffunction>
	
	<cffunction	name="OnRequestEnd"	access="public"	returntype="void" output="true" hint="Fires after the page processing is complete.">
     	  
            
            <!---
		  <CFIF cgi.remote_addr EQ application.webmasterIP OR findnocase("192.168.164",cgi.remote_addr) GT 0>
  <!---Client:<br />
  <CFDUMP var="#client#">--->
  Debugging info visible to internal IPs only<br>
  <br><br><hr />
  Cookie:<br />
  <CFDUMP var="#cookie#">
  <CFDUMP var="#application.serverAddress#">
  
  <CFIF Isdefined("gettermcount")>
  <CFDUMP var="#gettermcount#">
  </CFIF>
  
  <CFIF Isdefined("form")>
  	<CFDUMP var="#form#">
  </CFIF>
  
  
    <CFIF Isdefined("pilot")>
  	<CFDUMP var="#valuelist(pilot.primarypatronid)#">
     <CFOUTPUT>#cookie.primarypatronid#<br>
	#listfind(valuelist(pilot.primarypatronid),cookie.primarypatronid)#</CFOUTPUT>
     
  </CFIF>
  
  
  
  </CFIF>
  --->
  
          
          
		<cfreturn />
	</cffunction>
	
	<cffunction	name="OnSessionEnd"	access="public"	returntype="void" output="false" hint="Fires when the session is terminated.">
		<cfargument	name="SessionScope"	type="struct" required="true" />
		<cfargument	name="ApplicationScope" type="struct" required="false" default="#StructNew()#" />
		<cfreturn />
	</cffunction>
	
	<cffunction name="OnApplicationEnd" access="public" returntype="void" output="false" hint="Fires when the application is terminated.">
		<cfargument	name="ApplicationScope"	type="struct" required="false" default="#StructNew()#" />
		<cfreturn />
	</cffunction>
	
	<cffunction	name="OnError" access="public" returntype="void" output="true" hint="Fires when an exception occurs that is not caught by a try/catch.">
		<cfargument	name="Exception" type="any" required="true"	/>
		<cfargument	name="EventName" type="string" required="false" default="" />

		  <CFLOG file="error" application="yes" text="Exception type: #ARGUMENTS.Exception.Message# | Template: #cgi.script_name# | Remote Address: #cgi.remote_addr# | HTTP Reference: #cgi.HTTP_REFERER#, Diagnostics: #ARGUMENTS.Exception.Rootcause# | Browser: #cgi.HTTP_USER_AGENT#"> 
	
     		<!--- for 6/30/2015 --->
<CFIF dateformat(now(),"mm/dd/yyyy") EQ "06/30/2015">
	<CFLOCATION url="http://www.thprd.org/offline.html">
</CFIF>
    
     		
             <cfinclude template="/portalINC/error.cfm">  

	</cffunction>
	
</cfcomponent>
