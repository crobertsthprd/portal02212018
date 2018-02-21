<html>
<head>
<title>Update Contact Information</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<CFIF NOT Isdefined("type")>
<CFLOCATION url="https://www.thprd.org/portal/main.cfm">
</CFIF>

<cfoutput>
<cfswitch expression="#type#">
	<cfcase value="H"><!--- home phone --->
		<cfset typename = "Home Phone">
		<cfquery name="qGetValue" datasource="#application.reg_dsn#">
			select contactdata as currentvalue
			from patroncontact
			where contacttype = '#type#'
			and patronID = #pID#
		</cfquery>
	</cfcase>
	<cfcase value="W"><!--- work phone --->
		<cfset typename = "Work Phone">
		<cfquery name="qGetValue" datasource="#application.reg_dsn#">
			select contactdata as currentvalue
			from patroncontact
			where contacttype = '#type#'
			and patronID = #pID#
		</cfquery>
	</cfcase>
	<cfcase value="C"><!--- cell phone --->
		<cfset typename = "Cell Phone">
		<cfquery name="qGetValue" datasource="#application.reg_dsn#">
			select contactdata as currentvalue
			from patroncontact
			where contacttype = '#type#'
			and patronID = #pID#
		</cfquery>
	</cfcase>
	<cfcase value="E"><!--- email --->
		<cfset typename = "Email Address">
		<cfquery name="qGetValue" datasource="#application.reg_dsn#">
			select nocontact,loginemail as currentvalue
			from patrons
			where patronlookup = '#plkup#'
		</cfquery>
	</cfcase>
     <cfcase value="EA"><!--- auxiliary email --->
		<cfset typename = "Auxiliary Email Address(es)">
		<cfquery name="qGetValue" datasource="#application.reg_dsn#">
			select nocontact,loginemail as currentvalue,loginemail
			from patrons
			where patronlookup = '#plkup#'
		</cfquery>
          <CFIF listlen(qGetValue.loginemail) LT 1>
          Updating auxiliary emails is currently unavailable.<CFABORT>
          </CFIF> 
		
		
		<CFSET auxemails = "">
          <CFSET patronemail = listfirst(qGetValue.loginemail)>
          	<CFIF listlen(qGetValue.loginemail) GT 1>
          		<CFSET auxemails = listdeleteat(qGetValue.loginemail,1)>
          	
               </CFIF>
	</cfcase>
</cfswitch>
<body topmargin="9" leftmargin="0" marginheight="9" marginwidth="0" onLoad="document.updatecontact.newcontact.focus();">
<cfif not isdefined('updatecontact')>
	<form name="updatecontact" method="post" action="#cgi.request_uri#">
		<table width="375" cellpadding=1 border=0 cellspacing="0" bgcolor="00000" align=center>
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="0048d0">
				<tr>
				<td class="lgnhdr" colspan=2 style="padding:20px;"><strong>Update My #typename#</strong><br>
                    <CFIF type EQ "EA">These email addresses will receive class alerts pertaining to all household members.</CFIF>
                    <CFIF type EQ "E">Updating your primary email address will erase any auxiliary email addresses you may have entered.</CFIF>
                    </td>
				</tr>
				<tr>
				
				<td valign=top width=100% style="padding-left:20px;padding-right:20px;">
					<table border=0 cellpadding=1 cellspacing="0"  align="center" width=100%>
					<CFIF type NEQ "EA">
						<cfif qGetValue.recordcount gt 0>
						<tr>
						<td class="lgntext" valign="top">
                              	
                                   
                                   
							<strong>Current #typename#:</strong> #listfirst(qGetValue.currentvalue)#<input type="hidden" name="currentcontact" value="#qGetValue.currentvalue#" ><br><br>
                                   
						</td>
						</tr>
						</cfif>
                         </cfif>
					<tr>
					<td class="lgntext" valign="top">
						<strong>New #typename#<span class="lgnmsg">*</span> </strong><br>
                              <CFIF type EQ "EA">
                              	<input type="hidden" name="patronemail" value="#patronemail#">
                                   Seperate each email address with a comma<br>
                                   <textarea name="newcontact" rows="3" style="width:300px;">#auxemails#</textarea>
                              <CFELSE>
                              <input type="text" name="newcontact" class="form_input" size=25 maxlength="50">
                              </CFIF>
                              
                              
					</td>
					</tr>
					<CFIF type EQ 'E'>
                         <tr>
					<td class="lgntext" valign="top">
						<br><input type="checkbox" name="nocontact" value="true" class="form_input" <CFIF qGetValue.nocontact EQ true>checked</CFIF> > I do NOT wish to receive announcements.
					</td>
					</tr>
                         </CFIF>
					<tr>
					<td class="lgntext" valign="top">
						<br><input type="submit" name="updatecontact" class="form_input" value="Update #typename#"><br><br>
					</td>
					</tr>
					</table>
				</td>
				
				</tr>
				</table>
			</td>
			</tr>
		</table>
		<input type="hidden" name="type" value="#type#">
		<input type="hidden" name="pID" value="#pID#">
		<input type="hidden" name="oldvalue" value="#qGetValue.currentvalue#">
		<cfif isdefined('plkup')>
			<input type="hidden" name="plkup" value="#plkup#">
		</cfif>
	</form>
<cfelse>
	
     <CFSET datavalid = "true">
     
     <cfswitch expression="#form.type#">
		<cfcase value="e"><!--- email --->
			 
                <CFIF NOT IsValid("email",trim(form.newcontact)) AND trim(form.newcontact) NEQ "">
                	<CFSET datavalid = "false">
                    <CFSET msg = "The email address you entered is not valid.">
                
                <CFELSE>
                
                <CFPARAM name="form.nocontact" default="false">
                
                <CFIF trim(form.newcontact) EQ "">
                	<CFSET theEmail = trim(form.currentcontact)>
                <CFELSE>
                	<CFSET theEmail = trim(form.newcontact)>
                </CFIF>
                
                <cfquery name="qUpdate" datasource="#application.reg_dsn#">
				update patrons
				set loginemail = '#theEmail#',
                    nocontact = '#form.nocontact#'
				where patronlookup = '#plkup#'
			</cfquery>

	<CFIF trim(form.newcontact) NEQ "">
	<CFMAIL to="#form.newcontact#" cc="#form.oldvalue#" bcc="webadmin@thprd.org" from="webadmin@thprd.org" subject="THPRD Online Registration: Account Modification Email Address">
Hello,

We just wanted to let you know that we have changed your contact email from #listfirst(form.oldvalue)# to #form.newcontact#.
The change was made #dateformat(now(),"dddd mmmm d, yyyy")# at #timeformat(now(),"hh:mm:ss tt")#.

Thanks,
THPRD Online Registration
	</CFMAIL>
     </CFIF>

		<cfset msg = "Contact Information Updated">
          </CFIF>
          
		</cfcase>
          
          <cfcase value="ea"><!--- email --->
			 
                <CFSET emaillist =  form.patronemail & "," & form.newcontact>
                
                <CFIF listlen(emaillist) GT 0>
                <CFLOOP list="#emaillist#" index="i">
               	 <CFIF NOT IsValid("email",trim(i)) AND trim(i) NEQ "">
                		<CFSET datavalid = "false">
                    	<CFSET msg = "One of the email addresses you entered is not valid.">
                	 </CFIF>
                </CFLOOP>
                <CFELSE>
                	<CFSET datavalid = "false">
                    <CFSET msg = "One of the email addresses you entered is not valid.">
                </CFIF>
                
                	
           <CFIF datavalid>
                	
                <cfquery name="qUpdate" datasource="#application.reg_dsn#">
				update patrons
				set loginemail = <cfqueryparam cfsqltype="cf_sql_varchar" value="#emaillist#">
				where patronlookup = <cfqueryparam cfsqltype="cf_sql_varchar" value="#plkup#">
			</cfquery>

			
			<CFMAIL to="#emaillist#" bcc="webadmin@thprd.org" from="webadmin@thprd.org" subject="THPRD Online Registration: Account Modification Auxiliary Email Address">
Hello,

We just wanted to let you know that we have updated your auxiliary email(s).
The following addresses now receive notification: #form.newcontact#.
The change was made #dateformat(now(),"dddd mmmm d, yyyy")# at #timeformat(now(),"hh:mm:ss tt")#.

Thanks,
THPRD Online Registration
			</CFMAIL>
     		

			<cfset msg = "Contact Information Updated">
          </CFIF>
          
		</cfcase>
          
          <cfdefaultcase>
  
<cfquery name="qCheckValue" datasource="#application.reg_dsn#">
			select contactdata
			from patroncontact
			where contacttype = '#type#'
			and patronID = #pID#
		</cfquery>
		<cfif qCheckValue.recordcount gt 0>
			<cfquery name="qUpdate" datasource="#application.reg_dsn#">
				update patroncontact
				set contactdata = '#form.newcontact#'
				where patronid = '#ucase(form.pID)#'
				and contacttype = '#form.type#'
			</cfquery>
		<cfelse>
			<cfquery name="qUpdate" datasource="#application.reg_dsn#">
			insert into patroncontact
				(patronID,contacttype,contactdata)
			values
				(#pID#,'#form.type#','#form.newcontact#')
			</cfquery>
		</cfif>
          <cfset msg = "Contact Information Updated">
          
          </cfdefaultcase>
          
	</cfswitch>
		

		
	<table width="375" cellpadding=1 border=0 cellspacing="0" bgcolor="00000" align=center>
	<tr>
	<td valign=top>
		<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="0048d0">
		<tr>
		<td class="lgnhdr" align=center colspan=2><br><strong>Update Contact Information</strong><br><br></td>
		</tr>
		<tr>
		
		<td valign=top width=100%>
			<table border=0 cellpadding=1 cellspacing="0" align="center">
			<tr>
			<td class="lgntext" valign="top" align="center">
			<strong>#msg#</strong><br>
			<cfif  msg contains 'not valid'>
				<br><br><a href="javascript:history.back();" class="lgntext"><< Go Back</a><br><br>
			<cfelse>
				<br><br><a href="javascript:window.close();" class="lgntext">Close Window</a>&nbsp;&nbsp;&nbsp;<br><br>			
			</cfif>		
			</td>
			</tr>
			</table>
		</td>
		
		</tr>
		</table>
	</td>
	</tr>
</table>	
</cfif>
</body>
</cfoutput>

</html>
