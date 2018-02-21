<!--- need better security --->
<CFSILENT>
<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>



<!--- set mode: editmode=0 (default) means read only, 1 = allow edit --->
<cfparam name="editmode" default="1">
<CFSET dopsds = "dopsds">
<CFSET primaryPatronID = cookie.uid>
<cfquery name="getHousehold" datasource="#dopsds#ro">
	SELECT   patronrelations.secondarypatronid as patronid, 
     	    patronrelations.primarypatronid,
	         patrons.firstname,
              patrons.middlename,
	         patrons.lastname, 
              patrons.dob,
              patrons.patronlookup,
              patrons.gender,
	         patronrelations.relationtype, 
	         relationshiptype.relationshipdesc,
	         patronrelations.edupdate
	FROM     dops.patronrelations
	         inner join dops.relationshiptype ON patronrelations.RelationType=relationshiptype.RelationType
	         inner join dops.patrons on patronrelations.secondarypatronid=patrons.patronid
	WHERE    patronrelations.primarypatronid = <cfqueryparam value="#primaryPatronID#" cfsqltype="cf_sql_integer" list="no">
	<!---and      secondarypatronid = <cfqueryparam value="#PatronID#" cfsqltype="cf_sql_integer" list="no">--->
	order by patrons.dob desc, patronrelations.relationtype, patrons.lastname, patrons.firstname
</cfquery>


<!--- FIX confirmation message ---> 

</CFSILENT>


<CFOUTPUT>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Emergency Contact Information</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">

<table border="0" cellpadding="0" cellspacing="0" width="750">
  <tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		
		<td colspan=2 class="pghdr">
			<!--- start header --->
			<CFINCLUDE template="/portalINC/dsp_header.cfm">
			<!--- end header --->
		</td>
			
		<tr>
		
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="/siteimages/spacer.gif" width="130" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap class="lgnusr"><br>
			<!--- start nav --->
			<cfinclude template="/portalINC/admin_nav_history.cfm">
			<!--- end nav --->
			</td>
			</tr>		
			</table>		
		</td>
		
		<td valign=top class="bodytext" width="100%">
		<!--- start content --->
		

<!--- Emergency Contact Info --->
<br />
<div class="pghdr">Emergency Contact / Medical & Physical Information</div>
<CFLOOP query="getHousehold">

     <CFOUTPUT>
     <table width="650" border=0 cellpadding=3 cellspacing="0">
     <TR bgcolor="000000">
		<TD colspan="5" style="color:##FFF;"><strong>#lastname#, #firstname# #middlename# (#patronlookup#)  -
                    <cfif gender is "M">
                         Male
                         <cfelseif gender is "F">
                         Female
                    </cfif>
                    <cfif relationshipdesc NEQ "Self">#relationshipdesc#<CFELSE>Primary</cfif></strong></TD>
          </TR>
                
          <tr valign="top" >
          	<td colspan="5" style="border-color:##E0E0E0;border-width:1px;border-style:solid;">
               
               <cfif edupdate neq "">
               <div style="color:##390;margin-bottom:4px;">Emergency contact information last updated on #DateFormat( edupdate )#.</div><br>
               <!---
               <form name="contactcurrent" action="#cgi.script_name#" method="post">
                    <input type="checkbox" name="ecCurrent" value="true">
                    Check to indicate all information is current.
                    <input type="submit" value="Submit"><br>
                    <br></form>--->
                    <div align="center"><strong><a href="ecupdate.cfm?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#getHousehold.patronid#','mykey')))#">View/Update Emergency Contact Information</strong></a></div>
               
               <CFELSE>
               <div style="color:##C00;">Emergency contact information has <strong>NOT</strong> been entered for this family member.</div>
               <br>
          	<div align="center" style="border-color:##FF6;"><strong><a href="ecupdate.cfm?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#getHousehold.patronid#','mykey')))#">Add Emergency Contact Information</a></strong></div>
               </cfif>
               
               </td>
          </tr>  
          </TABLE>  
</CFOUTPUT>
<br>
</CFLOOP>


</td>
		</tr>
		</table>   
   </td>
  </tr>
  <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">

</table>
</body>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</html>
</cfoutput>
