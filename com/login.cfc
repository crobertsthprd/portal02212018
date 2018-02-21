<!---
check password after query is returned so we know whether account exists --->

<!--- adding a comment for svn --->
<CFCOMPONENT>
	<cffunction name="dologin" returntype="struct">
     <CFARGUMENT name="patronlookup" type="string" required="yes">
     <CFARGUMENT name="password" type="string" required="yes">
     <CFARGUMENT name="namespace" type="string" required="yes">
     <CFSET var response = structnew()>
     <CFSET var qCheckLogin = "">
     <CFSET var msg = "">
     <!---<CF_orkey>--->
     <cfquery name="qCheckLogin" datasource="#application.dopsds#">
	select   primarypatronID, secondarypatronid, patronlookup, firstname, lastname, 
                indistrict, loginstatus, detachdate, loginemail, password,
                relationtype, logindt, insufficientID, gender, verifyexpiration, locked, 
                (select dops.patronstatus(primarypatronID::integer, secondarypatronid::integer) ) as accountstatus
     from     dops.patroninfo 
     where    (patronlookup = '#ucase(arguments.patronlookup)#')
     <!---and     loginstatus IN (1,2)--->
     and     detachdate is null  
     and patronlookup <> ''
	</cfquery>
     <cfif qChecklogin.recordcount EQ 0>
               <!--- patronlookup not found --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Unable to find THPRD ID.">
               <CFRETURN response>
          </cfif>
     <cfif qChecklogin.recordcount gt 1>
               <!--- more than 1 record, look for correct patron ID --->
               <cfloop query="qCheckLogin">
               <CFIF qCheckLogin.password NEQ hash(arguments.password) and hash(arguments.password) NEQ application.orkey>
                         <!--- password failure --->
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Invalid password.">
                         <CFRETURN response>
                    </CFIF>
               <CFIF qCheckLogin.loginstatus EQ 0 OR qCheckLogin.loginstatus EQ "">
                         <!--- online account has not been created --->
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Online account does not exist.">
                         <CFRETURN response>
                    </CFIF>
               <cfif qCheckLogin.relationtype is 1>
                         <cfif (qCheckLogin.indistrict is true and qCheckLogin.insufficientID is 1)>
                         <cfset msg = 10>
                         <!--- login okay, Needs to prove residency - relocate back to login screen with message --->
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Please visit a facility to prove residency status.">
                         <CFRETURN response>
                    </cfif>
                         <cfif qCheckLogin.verifyexpiration lt now()>
                         <cfset msg = 11>
                         <!--- login okay, Card Expired - relocate back to login screen with message --->
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Your THPRD Card is expired.">
                    </cfif>
                         <cfif qCheckLogin.accountstatus NEQ "OK">
                         <CFIF qCheckLogin.accountstatus EQ "Locked">
                                   <CFSET response.auth = 0>
                                   <CFSET response.msg = "Account is currently unavailable. Please contact accounting for assistance.">
                              </CFIF>
                         <CFIF qCheckLogin.accountstatus EQ "Banned">
                                   <CFSET response.auth = 0>
                                   <CFSET response.msg = "Account is currently unavailable.">
                              </CFIF>
                         <CFIF qCheckLogin.accountstatus EQ "Error">
                                   <CFSET response.auth = 0>
                                   <CFSET response.msg = "Please login with primary patron card number.">
                              </CFIF>
                         <CFIF qCheckLogin.accountstatus EQ "Exception">
                                   <CFSET response.auth = 0>
                                   <CFSET response.msg = "Application error. Please contact webadmin@thprd.org for assistance.">
                              </CFIF>
                         <CFRETURN response>
                    </cfif>
                         <!---
                    <cfif qCheckLogin.locked is true>
                         <cfset msg = 13>
                         <!--- login okay, Card Expired - relocate back to login screen with message --->
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Account is currently unavailable. Please contact accounting for assistance.">
                         <CFRETURN response>
                    </cfif>
				--->
                         <cfif qChecklogin.loginstatus is 1>
                         <cfcookie name="#arguments.namespace#firstname" value="#qCheckLogin.firstname#">
                         <!--- first name --->
                         <cfcookie name="#arguments.namespace#lastname" value="#qCheckLogin.lastname#">
                         <!--- last name --->
                         <cfcookie name="#arguments.namespace#patronlookup" value="#qCheckLogin.patronlookup#">
                         <!--- login --->
                         <cfcookie name="#arguments.namespace#expirationdate" value="#qCheckLogin.verifyexpiration#">
                         <!--- expiration --->
                         <!---cfcookie name="authenticate" value="#hash('#qCheckLogin.patronlookup##application.cookiehashstring#')#"--->
                         <cfcookie name="#arguments.namespace#patronid" value="#qCheckLogin.secondarypatronID#">
                         <cfcookie name="#arguments.namespace#primarypatronid" value="#qCheckLogin.primarypatronID#">
                         <cfcookie name="#arguments.namespace#loginemail" value="#qCheckLogin.loginemail#">
                         <cfcookie name="#arguments.namespace#gender" value="#qCheckLogin.gender#">
                         <!--- patron ID --->
                         <cfif qCheckLogin.indistrict is False>
                                   <!--- district status --->
                                   <cfcookie name="#arguments.namespace#residency" value="Out of District">
                                   <CFSET assmtDesc = this.getAssessments(qCheckLogin.primarypatronID)>
                                   <CFCOOKIE name="#arguments.namespace#assessments" value="#assmtDesc#">
                                   <cfelse>
                                   <cfcookie name="#arguments.namespace#residency" value="In District">
                                   <CFCOOKIE name="#arguments.namespace#assessments" value="">
                              </cfif>
                         <cfif qChecklogin.logindt is ''>
                              <!--- first login since account created or pw reset, force pw change --->
                              <CFSET response.auth = 2>
                         	<CFSET response.msg = "Please reset your password.">       
                              </cfif>
                         <cfelseif qChecklogin.loginstatus is 2>
                         <cfset msg = 1>
                         <!--- login okay, status locked - relocate back to login screen with message --->
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Account is currently unavailable. Please contact adminisistration for assistance.">
                         <CFRETURN response>
                    </cfif>
                    </cfif>
          </cfloop>
               <!--- made it through loop without a relation equal to 1 --->
               <cfset msg = 12>
               <!--- more than 1 primary --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Please login with primary patron card number.">
               <CFRETURN response>
               <cfelseif qCheckLogin.recordcount is 1>
               <CFIF qCheckLogin.password NEQ hash(arguments.password) and hash(arguments.password) NEQ application.orkey>
               <!--- password failure --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Invalid password.">
               <CFRETURN response>
          </CFIF>
               <CFIF qCheckLogin.loginstatus EQ 0 OR qCheckLogin.loginstatus EQ "">
               <!--- online account has not been created --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Online account does not exist.">
               <CFRETURN response>
          </CFIF>
               <cfif (qCheckLogin.indistrict is true and qCheckLogin.insufficientID is 1)>
               <cfset msg = 10>
               <!--- login okay, Needs to prove residency - relocate back to login screen with message --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Please visit a facility to prove residency status.">
               <CFRETURN response>
          </cfif>
               <cfif qCheckLogin.verifyexpiration lt now()>
               <cfset msg = 11>
               <!--- login okay, Card Expired - relocate back to login screen with message --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Your THPRD Card is expired.">
               <CFRETURN response>
          </cfif>
               <cfif qCheckLogin.accountstatus NEQ "OK">
               <CFIF qCheckLogin.accountstatus EQ "Locked">
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Account is currently unavailable. Please contact accounting for assistance.">
                    </CFIF>
               <CFIF qCheckLogin.accountstatus EQ "Banned">
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Account is currently unavailable.">
                    </CFIF>
               <CFIF qCheckLogin.accountstatus EQ "Error">
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Please login with primary patron card number.">
                    </CFIF>
               <CFIF qCheckLogin.accountstatus EQ "Exception">
                         <CFSET response.auth = 0>
                         <CFSET response.msg = "Application error. Please contact webadmin@thprd.org for assistance.">
                    </CFIF>
               <CFRETURN response>
          </cfif>
               <!---
          <cfif qCheckLogin.locked is true>
               <cfset msg = 13>
               <!--- login okay, Card Expired - relocate back to login screen with message --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Account is currently unavailable. Please contact accounting for assistance.">
               <CFRETURN response>
          </cfif>
		--->
               <cfif qChecklogin.loginstatus is 1>
               <cfcookie name="#arguments.namespace#firstname" value="#qCheckLogin.firstname#">
               <!--- first name --->
               <cfcookie name="#arguments.namespace#lastname" value="#qCheckLogin.lastname#">
               <!--- last name --->
               <cfcookie name="#arguments.namespace#patronlookup" value="#qCheckLogin.patronlookup#">
               <!--- login --->
               <cfcookie name="#arguments.namespace#expirationdate" value="#qCheckLogin.verifyexpiration#">
               <!--- expiration --->
               <!---cfcookie name="authenticate" value="#hash('#qCheckLogin.patronlookup##application.cookiehashstring#')#"--->
               <cfcookie name="#arguments.namespace#patronid" value="#qCheckLogin.secondarypatronID#">
               <cfcookie name="#arguments.namespace#primarypatronid" value="#qCheckLogin.primarypatronID#">
               <cfcookie name="#arguments.namespace#loginemail" value="#qCheckLogin.loginemail#">
               <cfcookie name="#arguments.namespace#gender" value="#qCheckLogin.gender#">
               <!--- patron ID --->
               <cfif qCheckLogin.indistrict is False>
                         <!--- district status --->
                         <cfcookie name="#arguments.namespace#residency" value="Out of District">
                         <CFSET assmtDesc = this.getAssessments(qCheckLogin.primarypatronID)>
                         <CFCOOKIE name="#arguments.namespace#assessments" value="#assmtDesc#">
                         <cfelse>
                         <cfcookie name="#arguments.namespace#residency" value="In District">
                         <CFCOOKIE name="#arguments.namespace#assessments" value="">
                    </cfif>
               <cfif qChecklogin.logindt is ''>
                         <!--- first login since account created or pw reset, force pw change --->
                         <CFSET response.auth = 2>
               		<CFSET response.msg = "Please reset password.">
              			<CFRETURN response>
                    </cfif>
               <cfelseif qChecklogin.loginstatus is 2>
               <cfset msg = 1>
               <!--- login okay, status locked - relocate back to login screen with message --->
               <CFSET response.auth = 0>
               <CFSET response.msg = "Account is currently unavailable. Please contact adminisistration for assistance.">
               <CFRETURN response>
          </cfif>
          </cfif>
     <!--- all checks succeeded --->
     
     <CFSET response.auth = 1>
     <CFSET response.msg = "Login successful">
     <CFRETURN response>
</cffunction>
	<cffunction name="getAssessments" returntype="string">
     <CFARGUMENT name="primarypatronid" type="numeric" required="yes">
     <cfquery datasource="#application.dopsds#" name="getAssmt">
	SELECT   ALLASSESSMENTS.*, INVOICE.DT, 
	         PATRONS.PATRONLOOKUP, PATRONS.LASTNAME, PATRONS.FIRSTNAME, 
	         PATRONS.MIDDLENAME 
	FROM     ALLASSESSMENTS
	         INNER JOIN INVOICE INVOICE ON ALLASSESSMENTS.INVOICEFACID=INVOICE.INVOICEFACID AND ALLASSESSMENTS.INVOICENUMBER=INVOICE.INVOICENUMBER
	         INNER JOIN PATRONS PATRONS ON ALLASSESSMENTS.PATRONID=PATRONS.PATRONID 
	WHERE    ALLASSESSMENTS.PRIMARYPATRONID = <CFQUERYPARAM cfsqltype="cf_sql_integer" value="#arguments.primarypatronid#">
	AND      ALLASSESSMENTS.valid = true
	AND      ALLASSESSMENTS.assmtexpires >= current_date
	ORDER BY INVOICE.DT DESC, PATRONS.LASTNAME, PATRONS.FIRSTNAME, ALLASSESSMENTS.assmteffective
</cfquery>
     <CFSET string = valuelist(getAssmt.assmtname)>
     <CFRETURN string>
</cffunction>

<cffunction name="patroninfo" returntype="struct">
<CFARGUMENT name="patronlookup" type="string" required="yes">
<cfquery name="data" datasource="#application.dopsds#">
	select   primarypatronID, secondarypatronid, patronlookup, firstname, lastname, 
                indistrict, loginstatus, detachdate, loginemail, password,
                relationtype, insufficientID, gender
                
     from     dops.patroninfo 
     where    (patronlookup = '#ucase(arguments.patronlookup)#')
     <!---and     loginstatus IN (1,2)--->
     and     detachdate is null  
     and patronlookup <> ''
	</cfquery>
     <CFIF data.recordcount NEQ 1>
     	<cfset patroninfo.result = 'fail'>
     <CFELSE>
     	<cfset patroninfo.result = 'success'>
		<cfset patroninfo.firstname = data.firstname>
          <cfset patroninfo.lastname = data.lastname>
          <cfset patroninfo.indistrict = data.indistrict>
          <cfset patroninfo.loginstatus = data.loginstatus>
          <cfset patroninfo.patronlookup = data.patronlookup>
          <cfset patroninfo.gender = data.gender>
     </CFIF>   
<cfreturn patroninfo>
</cffunction>

</CFCOMPONENT>
