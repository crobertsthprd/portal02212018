<cfquery datasource="#application.dopsdsro#" name="gnr">
select   reg.patronid,reg.sessionID
from     reg
where    reg.sessionid is not null 
and      reg.primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
</cfquery>

<!--- lock out if we have cart and possible hidden payment 
<CFIF gnr.recordcount GT 0>
	<CFSET patrondatafromfunction = Patrondata(cookie.primarypatronID)>
     <CFPARAM name="patrondatafromfunction.pmtfailure" default="false">
	<CFIF patrondatafromfunction.pmtfailure EQ "true">
     	<CFLOCATION url="/portal/index.cfm?msg=951">
		<CFABORT>
     </CFIF>
</CFIF>
--->

<CFQUERY name="open" datasource="dopsds">
	SELECT   *
	FROM     dops.getprimaryregstatus( <CFQUERYPARAM cfsqltype="cf_sql_integer" value="#cookie.primarypatronid#"> )
     WHERE HASBALANCEDUE OR ISBEINGCONVERTED OR ISDEFERRED
</CFQUERY>
<!--- token test project --->
<CFQUERY name="pilot" datasource="dopsds">
SELECT   primarypatronid,
         patronid,
         termid,
         facid,
         classid
FROM     dops.reg
WHERE    classid in ( 'DC12WH', 'DC12VS', 'DC12RP', 'DC12RH', 'DC12MK', 'DC12MC', 'DC11WH', 'DC11VS', 'DC11RP', 'DC11RH', 'DC11MK', 'DC11MC', 'DC10WH', 'DC10VS', 'DC10RP', 'DC10RH', 'DC10MK', 'DC10MC', 'DC01WH', 'DC01VS', 'DC01RP', 'DC01RH', 'DC01MK', 'DC01MC' )
</CFQUERY>


<a href="/portal/classes/index.cfm" class="sidenav">Class Search/<BR>Shopping Cart<CFIF gnr.recordcount GT 0> (<CFOUTPUT>#gnr.recordcount#</CFOUTPUT>)</CFIF></a><br><br />
<a href="/portal/main.cfm?DisplayMode=M" class="sidenav">My THPRD Homepage</a><br>
<a href="/portal/history/patronhistory.cfm?DisplayMode=M" class="sidenav">My Household</a><br>
<a href="/portal/history/patronhistory.cfm?DisplayMode=L" class="sidenav" style="color:white;background:green;padding:1px;">Aquatic & Tennis Levels</a><br>
<a href="/portal/history/patronhistory.cfm?DisplayMode=R" class="sidenav">Current Registrations</a>&nbsp;&nbsp;&nbsp;<br>
<a href="/portal/history/dropin.cfm" class="sidenav">Drop-In History</a><br>
<a href="/portal/history/patronhistory.cfm?DisplayMode=I" class="sidenav">Invoice History</a><br>
<a href="/portal/history/patronhistory.cfm?DisplayMode=P" class="sidenav">Pass Status</a><br>

<cfif cookie.ds is 'Out of District'>
<a href="/portal/assessments/index1.cfm" class="sidenav">Assessments</a><br>
</cfif>
<!---<a href="../history/esubscribe.cfm" class="sidenav">E-Subscriptions</span><br>
<a target="_blank" href="https://www.thprd.org/store/giftcard_home.cfm" class="sidenav">Gift Cards</a><br>--->

<CFIF listfind(valuelist(pilot.primarypatronid),cookie.primarypatronid) NEQ 0>
<br />
<div style="color:white;background:#66C;padding:1px;font-size:12px"><strong>Payment Methods</strong></div>
<a href="/portal/history/cardoptions.cfm" class="sidenav">Manage Options</a><br />
<a href="/portal/history/addcard.cfm" class="sidenav">Add Credit Card</a><br />
</CFIF>



<br />
<a href="/portal/regbaldue/regbaldue1.cfm" class="sidenav">Pay Balance <CFIF open.recordcount GT 0> (<CFOUTPUT>#open.recordcount#</CFOUTPUT>)</CFIF></a><br><br>

<div style="background-color:#03F;color:white;padding:2px;font-size:12px;"><strong>Gift Cards</strong></div>
&bull; <a href="/portal/oc/ocinfo.cfm" class="sidenav">Reload</a><br>
&bull; <a href="/portal/oc/giftcardsregister.cfm" class="sidenav">Register</a><br>
&bull; <a href="/portal/oc/giftcardsregister.cfm" class="sidenav">View History</a><br>
<br />
<a href="/portal/passes/passes.cfm" class="sidenav">Buy Passes</a><br>
<a href="/portal/leagues/index.cfm" class="sidenav">Youth League<br />&nbsp;&nbsp;&nbsp;Registration</a><br />


<a href="/portal/teamregistration/procteam.cfm" class="sidenav">Adult Sports<br />&nbsp;&nbsp;&nbsp;Pay League Fee</a><br />
<br />

<table cellpadding="2">
	<tr>
		<td bgcolor="#CC0000">
<a href="/portal/history/ec.cfm" class="sidenav"><font color="white">Emergency Contact &<br />&nbsp;&nbsp;&nbsp;Medical Information</font></a>
</td>
	</tr>
</table>
<br />
<a href="http://www.thprd.org/activities/activities-guide" class="sidenav" target="_blank"><strong>Activities Guide</strong></a><br><br />
