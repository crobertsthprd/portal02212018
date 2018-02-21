<CFIF invoicetranxcallthrottle()>

<CFSAVECONTENT variable="message">
<font color="red" style="font-size:14px;"><strong>Credit Card processing is currently unavailable due to high volume</strong></font><br>
<p>All of the classes in your <a href="https://www.thprd.org/portal/classes/index.cfm">shopping cart</a> have been reserved. Please wait <strong><u>two minutes</u></strong> before attempting another payment.
<div align="center"><form><input type="button" value="Make Payment" onClick="location.reload();"></form></div>
</CFSAVECONTENT>
<CFSET nobackbutton = true>
<CFINCLUDE template="includes/layout.cfm">

<!---
<CFMAIL to="dhayes@thprd.org" cc="croberts@thprd.org" subject="User Throttled" type="html" from="webadmin@thprd.org">

This message is sent when checkoutregBP_www.cfm throttles a checkout request due to high volume
<br>
<CFDUMP var="#form#">
<hr>
<CFDUMP var="#url#">
<hr>
<CFDUMP var="#cgi#">
<hr>
<CFDUMP var="#cookie#">

</CFMAIL>
--->
<CFABORT>
</CFIF>

<CFIF not structkeyexists(form,"patronlookup")>

<CFSAVECONTENT variable="message">
<font color="red"><strong>Possible Processing Error</strong></font><br>
<p>Our apologies. If you found yourself here after clicking the <strong>Make Payment</strong> on the payment gateway page
there may be a browser compatibility issue. If you left the window open for longer than 10 minutes the gateway has timed out.</p>

<p>Your class enrollments are reserved.</p>
</CFSAVECONTENT>

<CFINCLUDE template="includes/layout.cfm">

<CFMAIL to="dhayes@thprd.org" cc="croberts@thprd.org" subject="Class Checkout: Out of sequence GET request to thprd main checkout page" type="html" from="webadmin@thprd.org">

This message is sent when checkoutregBP_www.cfm receives a GET request and form is undefined.
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

<CFIF structkeyexists(form,"tenderedcharge")>
	<CFSET form.netdue = form.tenderedcharge>
</CFIF>


<!--- check open call --->
<CFINCLUDE template="/portalINC/checkopencall.cfm">



<!--- LIST ALL DEPENDENCIES

form variables
	form.tenderedcharge
	form.primarypatronid
	form.refpolicy
	form.currentsessionid
	form.giftcarddebitamount
	form.checksumgiftcardnumber
	form.creditused

application variables

includes
/common/functions.cfm
/portal/classes/includes/layout.cfm
/common/invoicetranxcheckforapproval.cfm
/common/invoicetranxupdatetxdist.cfm
/securedops/OCCardUsagePrefix.cfm //adds payment entries to gift card accounts
/common/checkoutReg.cfm
/common/displayallinvoicetables.cfm
/common/invoicetranxcallclose.cfm
/common/invoicetranxcallfinish.cfm

--->

<!--- page description

get patron information for layout template
include business logic functions - these are at the variable scope

--->
<CFSETTING showdebugoutput="yes" requesttimeout = "1000" enablecfoutputonly="no">
<!--- first thing is look up the patron info --->

<cfquery name="Patron" datasource="#application.dopsds#ro">
	select   primarypatronID,
	         patronlookup,
	         firstname,
	         lastname,
	         indistrict,
	         loginstatus,
	         detachdate,
	         loginemail,
	         relationtype,
	         logindt,
	         insufficientID,
	         verifyexpiration,
	         locked
	from     dops.patroninfo
	where    ( patronlookup = <cfqueryparam value="#lTrim( rTrim( ucase( form.patronlookup ) ) )#" cfsqltype="cf_sql_varchar" list="no"> )
	and      loginstatus = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
	and      detachdate is null
</cfquery>


<cfinclude template="/common/functionsfp.cfm">

<cfif NOT structkeyexists( form, "primarypatronid" )>
	<CFSAVECONTENT variable="message">
	We did not receive proper credentials to process the request. Please go back and try again.<br>
	</CFSAVECONTENT>
	<CFSET nobackbutton = false>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfif>

<CFIF NOT structkeyexists(form,"refpolicy")>
	<CFSAVECONTENT variable="message">
	<CFOUTPUT>Please acknowledge that you have read and agree to the THPRD refund policy.<br>
	</CFOUTPUT>
	</CFSAVECONTENT>
	<CFSET nobackbutton = false>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</CFIF>

<cfquery name="GetPrimaryPatronData" datasource="#application.dopsds#ro">
	select   whoami() as whoami,
	         primarypatronID,
	         patronlookup,
	         firstname,
	         lastname,
	         indistrict,
	         loginstatus,
	         detachdate,
	         loginemail,
	         relationtype,
	         logindt,
	         insufficientID,
	         verifyexpiration,
	         locked,
	         dops.getsession( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="4" cfsqltype="cf_sql_integer" list="no"> ) as sessiondata,
	         dops.primaryaccountbalance( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">, now()::timestamp ) as startingbalance,
	         dops.hasopencall( <cfqueryparam value="#form.currentsessionid#" cfsqltype="cf_sql_varchar" list="no"> ) as hasopencall
	from     dops.patroninfo
	where    ( patroninfo.primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no"> )
	and      relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
</cfquery>

<cfif 0>
	<cfdump var="#GetPrimaryPatronData#">
</cfif>

<!--- need to add some kinde of catch --->



<cfset sessionArray = ListToArray( GetPrimaryPatronData.sessiondata, ":" )>

<CFIF getPrimaryPatronData.sessiondata EQ "NONE" OR arrayLen(sessionArray) EQ 1>
	<CFSAVECONTENT variable="message">
	Error determining session. If you have classes in your basket please call THPRD for assistance.<br>
     If your basket is empty please log out and log back in. Thank you.
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</CFIF>


<!--- are we changing the session here??? --->
<cfset currentsessionid = sessionArray[2]>

<!--- check to veryify user can continue --->
<!--- check for web session --->
<cfif variables.sessionArray[1] neq "WWW">
	<CFSAVECONTENT variable="message">
	Not same session facid
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
<!--- check for being locked --->
<cfelseif GetPrimaryPatronData.locked>
	<CFSAVECONTENT variable="message">
	Account is locked. Contact THPRD accounting.
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
<!--- check same session --->
<cfelseif variables.currentsessionid neq form.currentsessionid>
	<CFSAVECONTENT variable="message">
	We have completed the previous shopping cart session.<br>
     For security reasons please <a href="/portal/index.cfm?action=logout"><strong>log out</strong></a> and log back in to to begin a new session.
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
<!--- check starting balance the same as rendered on last page --->
<cfelseif dollarRound( GetPrimaryPatronData.startingbalance ) neq dollarRound( form.availablecredit )>
	<CFSAVECONTENT variable="message">
	Starting balance not the same
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
<!--- check for open call
<cfelseif GetPrimaryPatronData.hasopencall>
	<CFSAVECONTENT variable="message">
	has open call
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<cfoutput>#variables.message#</cfoutput><CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
--->
</cfif>
<!--- check for cart contents --->
<cfquery datasource="#application.dopsds#ro" name="GetNewRegistrations">
	select   reg.patronid,
	         reg.sessionID
	from     dops.reg
	where    reg.sessionid is not null
	and      reg.primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
	limit    1
</cfquery>

<CFIF GetNewRegistrations.recordcount EQ 0>
	<CFSAVECONTENT variable="message">
	<CFOUTPUT>Shopping cart is empty. This means that checkout has been completed. Please check invoice history for details.<br>
	<a href="/portal/classes/index.cfm?cartempty=1&patronlookup=#GetPrimaryPatronData.patronlookup#"><strong><< Return to class search</strong></a></CFOUTPUT>
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</CFIF>



<!--- set defaults --->
<!---<cfset primarypatronid = form.primarypatronid>--->
<cfset localfac = "WWW">
<cfset localnode = "W1">
<!--- <cfset DS = "#application.reg_dsn#"> --->
<!---<cfset pid = primarypatronid>--->
<cfset GLLineNo = 0>
<cfset ShowCurrentReg = 0>
<!--- set to 0 to suppress showing current regs --->
<!--- toggle vars to show msg do ease in formatting --->
<cfset ShowInSession = 0>
<cfset ShowDeleteConfirm = 0>
<cfset ShowCancelled = 0>
<cfset ShowAlreadyEnrolled = 0>
<cfset ShowNoAssmt = 0>
<cfset ShowWaitList = 0>
<cfset ShowError = 0>
<cfset ShowNonExistanceError = 0>
<cfset ShowNoRecords = 0>
<cfset ShowNoClasses = 0>
<cfset ShowNoActions = 0>
<cfset ShowNotAvail = 0>
<cfset current_session_value = "60">
<cfset countcounter = 0>

<cfset testmode = false>

<cfif IsDefined( "cookie.debugmode" ) and cookie.debugmode eq dateformat( now(), "D" )>
	<cfset testmode = true>
</cfif>

<!--- get next pk
<cfquery datasource="#application.dopsds#ro" name="getnextcallpk">
	Select nextval('dops.invoicetranxcall_pk_seq') as callpk
</cfquery>
<!--- end get next pk ---> --->

<!---Insert DOPS processing code here. --->
<CFSET invoicetypestr = "-REG-">
<!--- initial giftcard set up --->
<!--- convert to proper naming --->
<CFSET othercreditused = replacenocase(form.giftcarddebitamount,",","","all")>
<CFSET othercreditdata = form.checksumgiftcardnumber>
<cfset OtherCreditReturn = 0>
<cfset huserid = 0>
<CFSET facardid = "">
<cfset TOTALNEWCREDIT = 0>

<!--- define vars for code compatability with internal --->
<cfset TenderedCash = 0>
<cfset TenderedCheck = 0>
<cfset TenderedChange = 0>
<cfset REMAININGTENDERDCC = replacenocase(form.tenderedCharge,",","","all")>
<cfset form.tenderedCharge = replacenocase(form.tenderedCharge,",","","all")>
<CFSET ds_stat = GetPrimaryPatronData.indistrict>




<!---<cfif form.netdue gt 0>

	<cfif GetPrimaryPatronData.whoami eq "DEV"><!--- set dev mode --->
		<cfset callreference = getccreference( form.currentsessionid, getnextcallpk.callpk, "DEV" )>
	<cfelse><!--- set production mode --->
		<cfset callreference = getccreference( form.currentsessionid, getnextcallpk.callpk, "DB" )>
	</cfif>

	<cfoutput>#callreference#</cfoutput>

	<cfif variables.callreference eq "">
		<CFSAVECONTENT variable="message">
		Error in determining credit card call reference code.
		</CFSAVECONTENT>
		<CFSET nobackbutton = true>
		<CFINCLUDE template = "includes/layout.cfm">
		<cfabort>
	</cfif>

	<cfquery datasource="#application.dopsds#" name="insertprocessorattempt">
		-- insert call attempt record
		insert into dops.invoicetranxcall
			( pk,
			node,
			primarypatronid,
			sessionid,
			action,
			amount,
			procname,
			isused,
			istest,
			callcomment )
		values
			( <cfqueryparam value="#getnextcallpk.callpk#" cfsqltype="cf_sql_integer" list="no">,
			<cfqueryparam value="#variables.localnode#" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
			<cfqueryparam value="#form.currentsessionid#" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="S" cfsqltype="cf_sql_char" list="no">,
			<cfqueryparam value="#form.netdue#" cfsqltype="cf_sql_money" list="no">,
			<cfqueryparam value="BP" cfsqltype="cf_sql_char" list="no">,
			<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,

			<cfif 1>
				<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
			<cfelse>
				<cfqueryparam value="#form.testmode#" cfsqltype="cf_sql_bit" list="no">,
			</cfif>

			<cfqueryparam value="Web Reg" cfsqltype="cf_sql_varchar" list="no"> )
	</cfquery>

</cfif>--->

<CFTRY>
	<CFSET temp = evalFPsession(form.currentsessionid)>
          <CFIF findnocase("OK: NO UNFINISHED",temp) EQ 0>
               <CFMAIL to="dhayes@thprd.org" cc="croberts@thprd.org" from="noreply@thprd.org" subject="Portal WWW evalFPsession" type="HTML">
                    <CFDUMP var = "#temp#">
               </CFMAIL>
          </CFIF>
     <CFCATCH>
          <CFMAIL to="dhayes@thprd.org" cc="croberts@thprd.org" from="noreply@thprd.org" subject="Portal WWW evalFPsession eval catch" type="HTML">
               <CFDUMP var = "#cfcatch#">
          </CFMAIL>
     </CFCATCH>
</CFTRY>

<!--- check for pmtrec 
<CFSET patrondatafromfunction = Patrondata(form.primarypatronid)>
<CFIF patrondatafromfunction.pmtfailure EQ "true">
	<!--- log out --->
	<CFLOCATION url="/portal/index.cfm?action=logout">
	<CFABORT>
</CFIF>
--->

<cftransaction action="BEGIN" isolation="REPEATABLE_READ">


<!--- look for payment for this session || returns approved as true or false --->
<cfinclude template="/common/invoicetranxcheckforapproval_freedompay.cfm">
<!--- end look for payment for this session --->



<cfquery datasource="#application.dopsds#" name="GetPatronData">
	select   *
	from     SessionPatrons
	where    SessionID = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">
	order by relationtype
</cfquery>
          <cfset ThisModule = "WWW">
          <cfset ActivityLine = 0>
          <cfset GLLineNo = 0>
          <cfset NextInvoice = GetNextInvoice()>
	  <!---<cfset NextInvoice = GetNextInvoiceBP()> 06/12/2017--->

          <!--- ----------------- --->
          <!--- Other Credit used --->
          <!--- ----------------- --->
          <!--- numberformat(replacenocase(form.netdue,",",""),"______.00") --->
          <cfif variables.othercreditused gt 0 and variables.OtherCreditData is not 0>
               <!--- we validate and encrypt on the prior page --->
               <cfset enOtherCreditData = variables.OtherCreditData>
               <cfquery datasource="#application.dopsds#" name="getCardData">
                    SELECT   othercreditdesc,
                             cardid,
                             othercredittype,
                             isfa,
                             faapptype,
                             faappid,
                             acctid,
                             faappcurrent,
                             faloadacctid,
                             primarypatronid,
                             dops.getavailableocfunds( othercredithistorysums.cardid::integer, othercredithistorysums.primarypatronid::integer, #numberformat(form.totalfees,"______.00")#, #numberformat(replacenocase(form.netdue,",",""),"______.00")#, true ) as sumnet
                    FROM     dops.othercredithistorysums
                    where    valid

                    <cfif IsNumeric(variables.OtherCreditData) and variables.OtherCreditData lt 999999999999>
                         and   cardid = <cfqueryparam value="#variables.OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
                    <cfelse>
                         and   othercreditdata = <cfqueryparam value="#variables.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
                    </cfif>
                         and   ((isfa IS true and current_date < faappexpiredate) OR isfa IS false)
               </cfquery>


               <cfif GetCardData.recordcount is not 1>
               <CFSAVECONTENT variable="message">
               <CFOUTPUT>#variables.othercreditdata# #IsNumeric(variables.OtherCreditData)# Error in fetching Gift Card or is invalid/not activated/on hold for review.</CFOUTPUT>
               </CFSAVECONTENT>
               <CFINCLUDE template = "includes/layout.cfm">
               <cfabort>
               <cfelseif GetCardData.primarypatronid is not "">
                    <cfif not IsDefined("primarypatronid") or form.primarypatronid is not GetCardData.primarypatronid>
                    	<CFSAVECONTENT variable="message">
               			<CFOUTPUT>Specified Card is registered to another party, thus cannot be used this transaction.</CFOUTPUT>
               		</CFSAVECONTENT>
              		 	<CFINCLUDE template = "includes/layout.cfm">
              	 		<cfabort>
                    </cfif>
               </cfif>
               <cfif getCardData.recordcount is 0>
                    <cfif IsNumeric(variables.OtherCreditData) and variables.OtherCreditData lt 999999999999>

                    <cfelse>
                         <cf_cryp type="de" string="#variables.enOtherCreditData#" key="#key#">
                         <cfset AttemptedCard = cryp.value>
                    </cfif>
                    <CFSAVECONTENT variable="message">
               		<CFOUTPUT>Cannot determine Other card used (#variables.AttemptedCard#). Go back and try again.</CFOUTPUT>
               	</CFSAVECONTENT>
               	<CFINCLUDE template = "includes/layout.cfm">
              	 <cfabort>
               </cfif>

               <cfset otherCreditGLAcctid = getCardData.acctid>
			<!--- include requires query getCardData and form.OtherCreditUsed --->
               <cfinclude template="/common/OCCardUsagePrefix.cfm">

          </cfif>

		<cfset TotalOtherCreditAmount = 0>

		<!--- do actual reg processing --->
          <!--- looks like this requires nextInvoice? LINE 273 --->
          <cfinclude template="/common/classes/checkoutReg.cfm">

          <cfif variables.TotalOtherCreditAmount is not variables.OtherCreditReturn>
               <CFSAVECONTENT variable="message">
               <CFOUTPUT>Calculated Gift Card Credit does match what was expected. Expected#numberformat(variables.OtherCreditReturn,"999,999.99")#: Found#numberformat(variables.TotalOtherCreditAmount,"999,999.99")#Difference of#numberformat(variables.TotalOtherCreditAmount - variables.OtherCreditReturn,"999,999.99")#.</CFOUTPUT>
               </CFSAVECONTENT>
               <CFINCLUDE template = "includes/layout.cfm">
               <cfabort>
          </cfif>
          <cfif form.othercreditused gt 0>
               <cfset facardid = GetCardData.faappid>
          </cfif>


	<cfquery datasource="#application.dopsds#" name="InsertInvoice">
		insert into invoice
			(InvoiceFacID,
			InvoiceNumber,
			TotalFees,
			usedcredit,
			othercreditused,
			othercreditusedcardid,
			faappid,
			TenderedCC,
			Node,
			userid,
			primarypatronid,
			primarypatronlookup,
			addressid,
			MAILINGADDRESSID,
			indistrict,
			insufficientid,
			startingbalance,
			invoicetype)
		values
			(<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
			<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
			<cfqueryparam value="#form.totalfees#" cfsqltype="CF_SQL_MONEY">, --TotalFees
			<cfqueryparam value="#form.CreditUsed#" cfsqltype="CF_SQL_MONEY">, --Used Credit
			<cfqueryparam value="#form.othercreditused#" cfsqltype="CF_SQL_MONEY">, --othercreditused

			<cfif form.othercreditused gt 0>
				<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">, --othercreditusedcardid
			<cfelse>
				null, --othercreditusedcardid
			</cfif>

			<cfif form.othercreditused gt 0 and GetCardData.faappid is not "">
				<cfqueryparam value="#GetCardData.faappid#" cfsqltype="CF_SQL_INTEGER">, --faappid
			<cfelse>
				null, --faappid
			</cfif>

			<cfqueryparam value="#form.TenderedCharge#" cfsqltype="CF_SQL_MONEY">, --TenderedCC
			<cfqueryparam value="#variables.LocalNode#" cfsqltype="CF_SQL_VARCHAR">, --LocalNode
			<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --huserID
			<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, (

			select   patronlookup
			from     patrons
			where    patronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			select   addressid
			from     patronrelations
			where    primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			and      secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			select   mailingaddressid
			from     patronrelations
			where    primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			and      secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			SELECT   indistrict
			FROM     patronrelations
			WHERE    primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			AND      secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			SELECT   patrons.insufficientid
			FROM     patronrelations patronrelations
			         INNER JOIN patrons patrons ON patronrelations.secondarypatronid=patrons.patronid
			WHERE    patronrelations.primarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			AND      patronrelations.secondarypatronid = <cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			select   dops.primaryaccountbalance(<cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)),

			<cfqueryparam value="-REG-" cfsqltype="CF_SQL_VARCHAR">)
	</cfquery>

	<cfif 0>

		<cfquery datasource="#application.dopsds#" name="InsertInvoicePatrons">
			select invoice_relation_fill_web(<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as inserted
		</cfquery>

		<cfif InsertInvoicePatrons.inserted is 0>
		     <CFSAVECONTENT variable="message">
		     <CFOUTPUT>Could not insert patrons for proposed invoice. Go back and try again.</CFOUTPUT>
		     </CFSAVECONTENT>
		     <CFMAIL to = "#application.erroremail1#" from="webadmin@thprd.org" cc="#application.erroremail2#" subject="Error on Checkout: Could not insert patrons for proposed invoice. Go back and try again." type="html">
		          #message#
		          </CFMAIL>
		     <CFINCLUDE template = "includes/layout.cfm">
		     <cfabort>
		</cfif>

	</cfif>

          <cfset AllMonies = TenderedCharge>

          <!--- ----------- --->
          <!--- used credit --->
          <!--- ----------- --->
          <cfif form.CreditUsed greater than 0>
               <cfset NextEC = application.functions.GetNextEC()>
               <cfset ActivityLine = variables.ActivityLine + 1>
               <cfquery datasource="#application.dopsds#" name="AddToActivity">
			insert into Activity
				(ActivityCode,
				PrimaryPatronID,
				PatronID,
				InvoiceFacID,
				InvoiceNumber,
				Debit,
				Credit,
				line,
				EC)
			values
				(<cfqueryparam value="CU" cfsqltype="CF_SQL_VARCHAR">, --1
				<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, --2
				<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, --3
				<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --4
				<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --5
				<cfqueryparam value="#form.CreditUsed#" cfsqltype="CF_SQL_MONEY">, --6
				<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --7
				<cfqueryparam value="#variables.ActivityLine#" cfsqltype="CF_SQL_INTEGER">, --8
				<cfqueryparam value="#variables.NextEC#" cfsqltype="CF_SQL_INTEGER">) --9
			;

			<cfset GLLineNo = GLLineNo + 1>

			insert into GL
				(Debit,
				AcctID,
				InvoiceFacID,
				InvoiceNumber,
				EntryLine,
				EC,
				activitytype,
				activity)
			values
				(<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">, (

				select   AcctID
				from     GLMaster
				where    InternalRef = <cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">), --1
				<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --3
				<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --4
				<cfqueryparam value="#variables.GLLineNo#" cfsqltype="CF_SQL_INTEGER">, --5
				<cfqueryparam value="#variables.NextEC#" cfsqltype="CF_SQL_INTEGER">, --6
				<cfqueryparam value="C" cfsqltype="CF_SQL_VARCHAR">, --7
				<cfqueryparam value="Credit" cfsqltype="CF_SQL_VARCHAR">) --8
		</cfquery>
		</cfif>

		<!--- process invoicetranxdist --->
		<cfset nextprc = 0>
		<cfset RunningTransDist = 0>

		<cfif variables.RemainingTenderdCC gt 0>
			<!--- <cfset RunningTenderedCharge = 0.00> --->
			<cfquery name="GetTranxHistThisInvoice" datasource="#application.dopsds#">
				select   regid,
				         amount,
				         ismiscfee,
				         pk
				from     dops.reghistory
				where    invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
				and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
				and      amount > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
				order by pk
			</cfquery>

			<cfloop query="GetTranxHistThisInvoice">

				<cfif variables.RemainingTenderdCC gt 0 and GetTranxHistThisInvoice.amount gt 0>

					<cfquery datasource="#application.dopsds#" name="GetIssuedOC">
						select   debit
						from     dops.othercreditdist
						where    invoicefacid = <cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">
						and      invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">
						and      debit > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
						and      regid = <cfqueryparam value="#GetTranxHistThisInvoice.regid#" cfsqltype="cf_sql_smallint" list="no">
						and      ismiscfee = <cfqueryparam value="#GetTranxHistThisInvoice.ismiscfee#" cfsqltype="cf_sql_bit" list="no">
					</cfquery>

					<cfset ThisTranxAmount = min( variables.RemainingTenderdCC, GetTranxHistThisInvoice.amount ) - val( GetIssuedOC.debit )>

					<cfif variables.ThisTranxAmount gt 0>
					<cfset nextprc = GetNextPRC()>

					<cfquery name="InsertIntoTranxHist" datasource="#application.dopsds#">
						update dops.reghistory
						set
							prc = <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">
						where  pk = <cfqueryparam value="#GetTranxHistThisInvoice.pk#" cfsqltype="cf_sql_integer" list="no">
						;

						insert into dops.invoicetranxtrans
							( prc,
							reg )
						values
							( <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no"> )
						;

						insert into dops.invoicetranxdist
							( primarypatronid,
							regid,
							ismiscfee,
							reftype,
							invoicefacid,
							invoicenumber,
							prc,
							amount,
							action )
						values
							( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#GetTranxHistThisInvoice.regid#" cfsqltype="cf_sql_smallint" list="no">,
							<cfqueryparam value="#GetTranxHistThisInvoice.ismiscfee#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="REG" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#variables.ThisTranxAmount#" cfsqltype="cf_sql_money" list="no">,
							<cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no"> )
					</cfquery>

					<cfinclude template="/common/invoicetranxupdatetxdist.cfm">

					<cfset RunningTransDist = variables.RunningTransDist + variables.ThisTranxAmount>
					<cfset RemainingTenderdCC = max( 0, variables.RemainingTenderdCC - variables.thistranxamount )>
					</cfif>
				</cfif>
			</cfloop>

		<!--- final prc check --->
		<cfquery datasource="#application.dopsds#" name="CheckPRCdist">
			select   prc, amount
			from     dops.invoicetranxdist
			where    invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
			and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfset sumdist = 0>

		<cfloop query="CheckPRCdist">
			<cfset sumdist = variables.sumdist + val( CheckPRCdist.amount )>
		</cfloop>

		<cfif dollarRound( variables.sumdist ) neq form.tenderedcharge or dollarRound( variables.RunningTransDist ) neq form.tenderedcharge >
			<CFSAVECONTENT variable="message">
			<CFOUTPUT>Calculated credit card funds distribution did not match entered value.<br>
			<br>
			Tendered Charge:<strong>#decimalformat( form.tenderedcharge  )#</strong><BR>
			Distribution Sum:<strong>#decimalformat( variables.sumdist )#</strong><BR>
			Running Sum:<strong>#decimalformat( variables.RunningTransDist )#</strong>

			<!--- <CFIF application.showdebugoutput EQ true> --->

		<cfquery datasource="#application.dopsds#" name="Gettranxhist">
				select   *
				from     dops.invoicetranxdist
				where    invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
				and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfdump var="#Gettranxhist#">
			<cfinclude template="/common/displayallinvoicetables.cfm">
			<!--- </CFIF> --->

			</CFOUTPUT>
		</CFSAVECONTENT>

		<CFMAIL to = "#application.erroremail1#" from="webadmin@thprd.org" cc="#application.erroremail2#" subject="Error on Checkout: Calculated credit card funds distribution did not match entered value." type="html">
		#message#
		</CFMAIL>
		<CFINCLUDE template = "includes/layout.cfm">
		<cfabort>
		</cfif>

		<!--- verify equal counts / values --->








		<!--- oc / tranx sum checks --->
		<cfquery name="GetRegsThisInvoice" datasource="#application.dopsds#">
			select   reghistory.regid,
			         sum( reghistory.amount ) as sumregamount
			from     dops.reg
			         inner join dops.reghistory on reg.primarypatronid=reghistory.primarypatronid and reg.regid=reghistory.regid
			where    reghistory.invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
			and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
			and      reghistory.amount > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
			group by reghistory.regid
			order by reghistory.regid
		</cfquery>

		<cfloop query="GetRegsThisInvoice">

			<cfquery name="test1" datasource="#application.dopsds#">
				select   sum( amount ) as s
				from     dops.invoicetranxdist
				where    invoicetranxdist.invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
				and      invoicetranxdist.invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
				and      invoicetranxdist.regid = <cfqueryparam value="#GetRegsThisInvoice.regid#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>

			<cfquery name="test2" datasource="#application.dopsds#">
				select   sum( credit ) as s
				from     dops.othercreditdist
				where    othercreditdist.invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
				and      othercreditdist.invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
				and      othercreditdist.regid = <cfqueryparam value="#GetRegsThisInvoice.regid#" cfsqltype="cf_sql_integer" list="no">
				and      credit > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
			</cfquery>

			<!--- ensure dist sums lte full amount for this reg --->
			<cfif val( test1.s ) + val( test2.s ) gt GetRegsThisInvoice.sumregamount>
				<CFSAVECONTENT variable="message">
				<CFOUTPUT>
				ERROR: Sums for OC and Tranx exceed true reg amount. TX:#decimalformat( val( test1.s ) )# + OC:#decimalformat( val( test2.s ) )# > #decimalformat( variables.sumregamount )# for regid #GetRegsThisInvoice.regid#. Diff: #decimalformat( variables.sumregamount - val( test1.s ) + val( test2.s ) )#. Go back and try again.
				</CFOUTPUT>
				</CFSAVECONTENT>
				<CFMAIL to = "#application.erroremail1#" from="webadmin@thprd.org" cc="#application.erroremail2#" subject="Error on Checkout: Tranx counts do not match" type="html">
				#variables.message#
				</CFMAIL>
				<CFINCLUDE template = "includes/layout.cfm">
				<cfabort>
			</cfif>

		</cfloop>
		<!--- end oc / tranx sum checks --->












		<cfquery datasource="#application.dopsds#" name="CheckPRCdist">
			select   prc
			from     dops.invoicetranxdist
			where    invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
			and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
			group by prc
			order by prc
		</cfquery>

		<cfquery name="GetTranxHistThisInvoice" datasource="#application.dopsds#">
			select   prc
			from     dops.reghistory
			where    invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
			and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
			and      prc > <cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">
			group by prc
		</cfquery>

		<cfquery name="GetTranxHistThisInvoice" dbtype="query">
			select   prc
			from     GetTranxHistThisInvoice
			group by prc
			order by prc
		</cfquery>

               <cfif CheckPRCdist.recordcount neq GetTranxHistThisInvoice.recordcount>
                    <CFSAVECONTENT variable="message">
                    <CFOUTPUT>Tranx counts do not match: Distribution of #CheckPRCdist.recordcount# records vs. invoice total of #GetTranxHistThisInvoice.recordcount# records</CFOUTPUT>
                    <CFIF application.showdebuginfo EQ true>
                         <cfquery datasource="#application.dopsds#" name="Gettranxhist">
				select   *
				from     dops.invoicetranxdist
				where    invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
				and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>
                         <cfdump var="#Gettranxhist#">
                         <cfinclude template="/securedops/displayallinvoicetables.cfm">
                    </CFIF>
                    </CFSAVECONTENT>
                    <CFMAIL to = "#application.erroremail1#" from="webadmin@thprd.org" cc="#application.erroremail2#" subject="Error on Checkout: Tranx counts do not match" type="html">
                    #message#
                    </CFMAIL>
                    <CFINCLUDE template = "includes/layout.cfm">
                    <cfabort>
               </cfif>

               <!--- compare values --->
               <cfloop query="GetTranxHistThisInvoice">
                    <cfif GetTranxHistThisInvoice.prc[ GetTranxHistThisInvoice.currentrow ] neq CheckPRCdist.prc[ GetTranxHistThisInvoice.currentrow ]>
                         <CFSAVECONTENT variable="message">
                         <CFOUTPUT>Tranx contents do not match.</CFOUTPUT>
                         <CFIF application.showdebuginfo EQ true>
                              <cfquery datasource="#application.dopsds#" name="Gettranxhist">
				select   *
				from     dops.invoicetranxdist
				where    invoicefacid = <cfqueryparam value="#variables.localfac#" cfsqltype="cf_sql_varchar" list="no">
				and      invoicenumber = <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>
                              <cfdump var="#Gettranxhist#">
                              <cfinclude template="/securedops/displayallinvoicetables.cfm">
                         </CFIF>
                         </CFSAVECONTENT>
                         <CFINCLUDE template = "includes/layout.cfm">
                         <cfabort>
                    </cfif>
               </cfloop>
          </cfif>
          <!--- end process tranxhist --->

          <!--- -------------------- --->
          <!--- post tendered monies --->
          <!--- -------------------- --->
          <cfif AllMonies greater than 0>
               <cfset ActivityLine = ActivityLine + 1>
               <cfquery datasource="#application.dopsds#" name="AddToActivity">
			insert into Activity
				(ActivityCode,
				PatronID,
				InvoiceFacID,
				InvoiceNumber,
				Debit,
				Credit,
				line,
				EC,
				primarypatronid)
			values
				(<cfqueryparam value="PMT" cfsqltype="CF_SQL_VARCHAR">, --1
				<cfqueryparam value="#form.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, --2
				<cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --3
				<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --4
				<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --5
				<cfqueryparam value="#variables.AllMonies#" cfsqltype="CF_SQL_MONEY">, --6
				<cfqueryparam value="#variables.ActivityLine#" cfsqltype="CF_SQL_INTEGER">, --7
				<cfqueryparam value="#GetNextEC()#" cfsqltype="CF_SQL_INTEGER">, --8
				<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">) --9
		</cfquery>
	</cfif>

	<cfquery datasource="#application.dopsds#" name="FinalInvoiceData">
		update   patrons
		set
			lastuse = current_date
		where    patronid in (

		SELECT   reg.patronid
		FROM     reghistory
		         INNER JOIN reg reg ON reghistory.primarypatronid=reg.primarypatronid AND reghistory.regid=reg.regid
		WHERE    reghistory.invoicefacid = <cfqueryparam value="#variables.LocalFac#" cfsqltype="CF_SQL_VARCHAR">
		AND      reghistory.invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">)
	</cfquery>

          <!--- correct improper patronid in activity vs reghistory --->
          <cfquery datasource="#application.dopsds#" name="GetImproperRegIDInActivity">
		SELECT   activity.pk AS activitypk,
		         reg.patronid AS regpatron
		FROM     dops.activity
		         INNER JOIN dops.reg ON activity.primarypatronid=reg.primarypatronid AND activity.regid=reg.regid AND activity.patronid!=reg.patronid
		where    activity.primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		ORDER BY activity.pk desc
		limit    50
	</cfquery>

          <cfif GetImproperRegIDInActivity.recordcount gt 0>
               <cfloop query="GetImproperRegIDInActivity">
                    <cfquery datasource="#application.dopsds#" name="UpdateReg">
				update activity
				set
					patronid = <cfqueryparam value="#GetImproperRegIDInActivity.regpatron#" cfsqltype="CF_SQL_INTEGER">
				where pk = <cfqueryparam value="#GetImproperRegIDInActivity.activitypk#" cfsqltype="CF_SQL_INTEGER">
			</cfquery>
               </cfloop>
          </cfif>





<!--- insert gift card distribution info if needed --->
<cfif OtherCreditUsed gt 0>

    <CFSET _invoicefacid = "WWW">
    <CFSET _invoicenumber = "#variables.nextinvoice#">
    <!---				//called from /portal/includes/functions.cfc --->
    <cfset ocdist = SetOCUsage( variables.LocalFac, variables.NextInvoice )>

    <cfif variables.ocdist lt 0>

	    <CFSAVECONTENT variable="diagnostics">
		    <cfinclude template="/common/displayallinvoicetables.cfm">
	    </CFSAVECONTENT>

	    <CFMAIL to="#application.erroremail1#" from="webadmin@thprd.org" cc="#application.erroremail2#" subject="Error on Checkout: OCUsage" type="html">
		    #diagnostics#
		    <br>
		    <CFDUMP var="#form#">
		    <CFDUMP var="#cgi#">
	    </CFMAIL>

	    <CFSAVECONTENT variable="message">
		    <CFOUTPUT>Other Credit Distribution Error was detected for proposed invoice. Go back and try again. If problem persists, contact THPRD.</CFOUTPUT>
	    </CFSAVECONTENT>

	    <CFINCLUDE template = "includes/layout.cfm">
	    <cfabort>
    </cfif>

    <!--- check for correct oc funds vs. distribution --->
    <cfquery name="CheckOCDataSums" datasource="#application.dopsds#">
	    select dops.getocdisterror( '#variables.localfac#', #variables.nextinvoice#::integer )
    </cfquery>

    <cfif val( CheckOCDataSums.getocdisterror ) neq 0>

	    <CFSAVECONTENT variable="message">
		    <strong>Other Credit Distribution error was detected for proposed invoice.
		    Go back and try again. If problem persists, contact THPRD.
		    <BR><BR>Found difference of <cfoutput>#decimalformat( CheckOCDataSums.getocdisterror )#</cfoutput></strong>
		    <BR>
	    </CFSAVECONTENT>

	    <CFINCLUDE template = "includes/layout.cfm">
	    <cfabort>
    </cfif>
    <!--- end check for correct oc funds vs. distribution --->

</cfif>

          <!--- FOR TESTING --->
          <CFSET skipocdist = true>

          <!---<CFSET finalchecksmsg = finalchecks( variables.localfac, variables.NextInvoice, form.othercreditused )>

          <CFIF finalchecksmsg NEQ "OK">
               <CFSET message = finalchecksmsg>
               <cfoutput>#finalchecksmsg#</cfoutput><cfabort><CFINCLUDE template = "includes/layout.cfm">
               <cfabort>
          </CFIF>--->
			<CFSET form.netdue = replacenocase(form.netdue,",","","all")>
			<cfset finalchecksmsg = finalcheck( variables.nextinvoice, form.netdue, val( form.othercreditcardid ), form.othercreditused )>

			<cfif variables.finalchecksmsg neq "OK" or 0>
				<CFSET message = finalchecksmsg>
				<cfoutput>#finalchecksmsg#</cfoutput>
				<CFINCLUDE template = "includes/layout.cfm">
				<cfabort>
			</cfif>

<CFQUERY name="checkViaWarp" datasource="#application.dopsds#">
SELECT   varvalue
FROM     dops.systemvars
WHERE    varname = 'usecreditcardholdingtable'
</CFQUERY>

<CFIF checkViaWarp.varvalue EQ 'Y'>
	<CFSET viaWarp = true>
<CFELSE>
	<CFSET viaWarp = false>
</CFIF>

<!--- viawarp option is deprecated --->
<CFSET viaWarp = false>

<!--- testing: viaWarp = true
<CFSET viaWarp = true>--->

		<!--- make processor call --->
		<cfif form.tenderedcharge gt 0>
			<CFIF viaWarp EQ true>
                    <CFQUERY name="getCardData" datasource="#application.dopsds#">
                    SELECT   *
                    FROM     dops.sessionccd
                    WHERE    sessionid = '#form.currentsessionid#'
                    </CFQUERY>

                    <CFIF getCardData.recordcount EQ 0>
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

                         <!--- faclist created in checkoutReg routine --->
                         <CFPARAM name="variables.classfaclist" default="">

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
                         <cfset customer.amount           = form.tenderedcharge>
                         <cfset customer.name             = customer.firstname & " " & customer.lastname>
                         <cfset customer.callcomment      = "Reg">

                         <CFIF variables.classfaclist NEQ "">
                              <cfset customer.callcomment = customer.callcomment & ": " & variables.classfaclist>
                         </CFIF>

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

                         <cfset posturl = "checkoutregbp_www.cfm">
                         <cfinclude template="/common/invoicetranxcallclose_viawarp.cfm">
                         <cfinclude template="includes/layout.cfm">

                         <cfif 0>
                              <!--- confirm record is inserted --->
                              <cfquery datasource="#application.reg_dsn#" name="test">
                                   select  *
                                   from    dops.invoicetranxcall
                                   where   pk = <cfqueryparam value="#getnextcallpk.callpk#" cfsqltype="cf_sql_integer" list="no">
                              </cfquery>
                              <cfdump var="#test#">
                         </cfif>

                         <!--- commit insertion record --->
                         <cftransaction action="commit" />
                         <cfabort>
                    <CFELSE>
                         <cfquery datasource="#application.reg_dsn#" name="test">
					update dops.invoice
                         set
                         cctype = '#getCardData.type#',
                         cca = '#getCardData.cca#',
                         cced = '#getCardData.exp#',
                         cew = '#getCardData.cew#',
                         ccv = '#getCardData.ccv#'
                         where invoicefacid = 'WWW'
                         and invoicenumber = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#variables.nextinvoice#">
                         </cfquery>
					<cfquery datasource="#application.reg_dsn#" name="test">
                         update dops.invoicetranxcall
                         set
                         result = 'Processor was not used',
                         processorcalled = false
                         where sessionid = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.currentsessionid#">
                         </cfquery>

					<!--- finish session || not used
					<cfset sessionwasfinished = invoicetranxcallfinish( form.currentsessionid, variables.nextinvoice )>
					<cfif variables.sessionwasfinished neq 0>
                              <!--- open call was created. rollback and stop user form further actions. --->
                              <cftransaction action="rollback" />
                              <CFMAIL to="webadmin@thprd.org" cc="dhayes@thprd.org" from="webadmin@thprd.ogr" subject="DEV Possible Session Error - Class Check Out">
                                   This email was sent by checkoutregbp_www.cfm line 1094. Approval but session not finished.
                                   <CFDUMP var="#cookie#">
                              </CFMAIL>
                              <CFSAVECONTENT variable="message">
                                   <font color="red"><strong>Session Error</strong></font><br>
               We encountered a problem during the checkout process. The web team has been notified. We apologize for the inconvenience. For assistance please contact a local center. <a href="http://www.thprd.org/facilities/directory/" target="_blank">Click here for our online directory</a>.
                              </CFSAVECONTENT>
                              <CFSET nobackbutton = true>
                              <CFSET currentstep = 6>
                              <CFSET headertitle="Transaction Not Complete">
                              <CFINCLUDE template = "includes/layout.cfm">
                              <CFABORT>
                         </cfif>--->
                    </CFIF>

               <CFELSE>


			<!--- direction decision fp--->
			<cfif CheckForApproval.recordcount eq 0>
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

				<!--- faclist created in checkoutReg routine --->
                    <CFPARAM name="variables.classfaclist" default="">

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
				<cfset customer.amount           = form.tenderedcharge>
				<cfset customer.name             = customer.firstname & " " & customer.lastname>
				<cfset customer.callcomment      = "Registrations (Term-Fac-Class-Patron):<BR>">

				<cfif IsDefined("ProcessRegForComments") and 1>

					<cfloop query="ProcessRegForComments">
						<cfset customer.callcomment = customer.callcomment & ProcessRegForComments.termid & "-" & ProcessRegForComments.facid & "-" & ProcessRegForComments.classid & "-" & ProcessRegForComments.patronid & "<BR>">
					</cfloop>

				</cfif>

				<CFIF variables.classfaclist NEQ "">
                    	<cfset customer.callcomment = customer.callcomment & ": " & variables.classfaclist>
                    </CFIF>

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

				<cfset posturl = "checkoutregbp_www.cfm">
				<cfinclude template="/common/invoicetranxcallclose_freedompay.cfm">
				<cfinclude template="includes/layout.cfm">

				<cfif 0>
					<!--- confirm record is inserted --->
					<cfquery datasource="#application.reg_dsn#" name="test">
						select  *
						from    dops.invoicetranxcall
						where   pk = <cfqueryparam value="#getnextcallpk.callpk#" cfsqltype="cf_sql_integer" list="no">
					</cfquery>

					<cfdump var="#test#">
				</cfif>

				<!--- commit insertion record --->
				<cftransaction action="commit" />
				<cfabort>
			<cfelse>
				<!--- finish session --->
				<cfset sessionwasfinished = invoicetranxcallfinish( form.currentsessionid, variables.nextinvoice )>
				<cfif variables.sessionwasfinished neq 0>
					<!--- open call was created. rollback and stop user form further actions. --->
					<cftransaction action="rollback" />
                         <CFMAIL to="webadmin@thprd.org" cc="dhayes@thprd.org" from="webadmin@thprd.org" subject="Possible Session Error - Class Check Out" type="html">
                         	This email was sent by checkoutregbp_www.cfm line 1258. Approval but session not finished.
                         	Result from invoicetranxcallfinish(): #sessionwasfinished#

                              <CFDUMP var="#cookie#">
                         </CFMAIL>
                         <CFSAVECONTENT variable="message">
						<font color="red"><strong>Session Error</strong></font><br>
		We encountered a problem during the checkout process. The web team has been notified. We apologize for the inconvenience. For assistance please contact a local center. <a href="http://www.thprd.org/facilities/directory/" target="_blank">Click here for our online directory</a>.

					</CFSAVECONTENT>
					<CFSET nobackbutton = true>
					<CFSET currentstep = 6>
					<CFSET headertitle="Transaction Not Complete">
					<CFINCLUDE template = "includes/layout.cfm">

                         <CFABORT>
				</cfif>
			</cfif>
			<!--- end direction decision --->
		</CFIF>

     </cfif>





			<!--- insert invoiceID for mailing
			<CFIF cgi.server_addr NEQ application.devIP>

				<cfquery datasource="#application.dopsds#" name="queuemailer">
					insert into webinvoicequeue
						( invoicenumber, email )
					VALUES
						( <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#GetPrimaryPatronData.loginemail#" cfsqltype="CF_SQL_VARCHAR"> )
				</cfquery>

			</CFIF>

			<cfif 0>
				<cfinclude template="/common/displayallinvoicetables.cfm">
				<cfabort>
			</cfif>

		</cfif>--->
		<!--- end tenderedcharge gt 0 --->

		<!--- rollback and display data if testing
		<cfif IsDefined("variables.TestMode") or cgi.remote_addr EQ application.webmasterIP>
			<cfset invoicefacid = variables.localfac>
			<cfset invoicenumber = variables.nextinvoice>
			<cfinclude template="../displayallinvoicetables.cfm">
			<cftransaction action="ROLLBACK" />
			<cfabort>
		</cfif> --->

	</cftransaction>




<!--- check for reg errors --->
<cfif 1>

<cftry>

<cfquery datasource="#application.dopsds#" name="checkforreghistoryerror">
	SELECT   *
	FROM     dops.reghistory
	where    not exists(

	SELECT   pk
	FROM     dops.reg
	WHERE    reg.primarypatronid=reghistory.primarypatronid
	AND      reg.regid=reghistory.regid)

	and      reghistory.dt::date = current_date
	and      reghistory.primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
</cfquery>

<cfif checkforreghistoryerror.recordcount gt 0>

<CFMAIL to="dhayes@thprd.org" from="noreply@thprd.org" subject="web reghistory reg match error" type="html">
<cfoutput>#now()#</cfoutput>

<cfdump var="#checkforreghistoryerror#">
</cfmail>

</cfif>

<cfcatch>
</cfcatch>

</cftry>

</cfif>
<!--- end check for reg errors --->




<!--- VERY IMPORTANT! update sessionid so they can do another transaction
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
</CFQUERY>
--->
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
<CFOUTPUT><p>Processing is complete. <a href="/checkout/invoice/printinvoice.cfm?i=#encrypted#" target="_blank">View Invoice</a></p>

<!--- Registration Specific Message 
<p>Thanks for registering for THPRD fall activities. If you have a moment, please fill out <a href="https://www.surveymonkey.com/r/7PVZHYJ">this brief survey</a>. As a thank you, you will have a chance to win a $50 gift card to THPRD. <a href="https://www.surveymonkey.com/r/7PVZHYJ">2017 Fall Registration Survey</a></p>--->



     <div style="height:200px;">&nbsp;</div>
     <hr color="##f58220" width=100% align="center" size="5px">
     <div align="center">
          <!---<table>
               <tr>
                    <td align="center"><form action="#application.portalserver#/portal/classes/index.cfm" method="post">
                              <input type="hidden" value="#GetPrimaryPatronData.patronlookup#" name="patronlookup">
                              <input type="hidden" value="true" name="checkoutcomplete">
                              <input type="submit" value="Continue Shopping" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;">
                         </form></td>
                    <td align="center"><form action="#application.portalreturnurl#" method="post">
                              <input type="hidden" value="#GetPrimaryPatronData.patronlookup#" name="patronlookup">
                              <input type="hidden" value="true" name="checkoutcompletelogout">
                              <input type="submit" value="Log Out" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;">
                         </form></td>
               </tr>
          </table>--->
     </div>
</CFOUTPUT>
</CFSAVECONTENT>
<CFSET nobackbutton = true>
<CFSET currentstep = 7>
<CFSET headertitle="Finished">
<CFINCLUDE template = "includes/layout.cfm">



<cfabort>






















