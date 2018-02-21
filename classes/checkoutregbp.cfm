<CFSETTING showdebugoutput="yes">

<cfsetting requesttimeout = 1000>



<CFSETTING enablecfoutputonly="no">
<!--- LIST ALL DEPENDENCIES

securedops maps to /checkout/includes/dops

/securedops/FunctionTranx.cfc instantiated as application.functiontranx by application.cfc
/securedops/functions.cfm instantiated in component application.dopscheckout by application.cfc
/securedops/FunctionGetOCUsage.cfm instantiated in component application.dopscheckout by application.cfc
/securedops/FunctionGetOCUsageDOPS.cfm *include called by function setocusage()
/securedops/GetOtherCreditData.cfm - i recoded this inline due to dependencies
/securedops/OCCardUsagePrefix.cfm
/securedops/checkoutReg.cfm
/securedops/displayallinvoicetables.cfm
/securedops/processorcatch.cfm
/securedops/BackButton.cfm
/securedops/CFCatchErrors.cfm
/securedops/processorcallclose.cfm
/securedops/FinalChecks.cfm

includes/layout.cfm

page is called by /portal/classes/class_summary_trans_confirm.cfm

POSTGRES Function: dops.insertinvoicetranssubmit()

Had S meaning invalid session. In reality, an 'S' is the default value for dops.invoicetranxsubmit.action upon insertion. Action is updated later. Should CF die before this gets updated, the S will still be there, meaning the routine failed. Changed the invalid 'S' result to 'V'.

G = Submission is granted to continue
T = Throttled submission
C = Specified session has an open processor call
K = has call w/o acknowledgement
B = InternetSecureIsUsed or InternetSecureIsUsedOnWeb (if isonweb is true) was not used
R = Recent page submission being less than 30 seconds
V = Specified session not valid
A = Specified session was approved
P = Specified session has a problem

--->



<!--- get BP params --->
<cfif form.tenderedcharge gt 0>
	<cfset BPData = GetBPUserData()>

	<cfif not IsStruct( variables.BPData )>
		<CFSAVECONTENT variable="message">
		We did not receive proper credentials to process the request for a credit card. Please go back and try again.<br>
		</CFSAVECONTENT>

		<CFSET nobackbutton = false>
		#variables.message#<CFINCLUDE template = "includes/layout.cfm">
		<cfabort>
	</cfif>

</cfif>

<cfif NOT structkeyexists( form, "primarypatronid" )>
	<CFSAVECONTENT variable="message">
	We did not receive proper credentials to process the request. Please go back and try again.<br>
	</CFSAVECONTENT>

	<CFSET nobackbutton = false>
	#variables.message#<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfif>

<CFIF NOT structkeyexists(form,"refpolicy")>
	<CFSAVECONTENT variable="message">
	<CFOUTPUT>Please acknowledge that you have read and agree to the THPRD refund policy.<br>
	</CFOUTPUT>
	</CFSAVECONTENT>
	<CFSET nobackbutton = false>
	#variables.message#<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</CFIF>

<!---<cftry>--->

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
	and      loginstatus = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
	and      relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
</cfquery>

<cfif 0>
	<cfdump var="#GetPrimaryPatronData#">
</cfif>

<!---<cfcatch>
	<CFSAVECONTENT variable="message">
	An error ocurred.<br>
	<strong><< Go back and try again.</strong></a>
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfcatch>

</cftry>--->

<cfset sessionArray = ListToArray( GetPrimaryPatronData.sessiondata, ":" )>
<cfset currentsessionid = sessionArray[2]>

<!--- check to veryify user can continue --->
<!--- check for web session --->
<cfif variables.sessionArray[1] neq "WWW">
	<CFSAVECONTENT variable="message">
	Not same session facid
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<cfoutput>#variables.message#</cfoutput><CFINCLUDE template = "includes/layout.cfm">
	<cfabort>

<!--- check for being locked --->
<cfelseif GetPrimaryPatronData.locked>
	<CFSAVECONTENT variable="message">
	Account is locked. Contact THPRD accounting.
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<cfoutput>#variables.message#</cfoutput><CFINCLUDE template = "includes/layout.cfm">
	<cfabort>

<!--- check same session --->
<cfelseif variables.currentsessionid neq form.currentsessionid>
	<CFSAVECONTENT variable="message">
	Different sessionid.
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<cfoutput>#variables.message#</cfoutput><CFINCLUDE template = "includes/layout.cfm">
	<cfabort>

<!--- check starting balance the same as rendered on last page --->
<cfelseif dollarRound( GetPrimaryPatronData.startingbalance ) neq dollarRound( form.availablecredit )>
	<CFSAVECONTENT variable="message">
	Starting balance not the same
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<cfoutput>#variables.message#</cfoutput><CFINCLUDE template = "includes/layout.cfm">
	<cfabort>

<!--- check for open call
<cfelseif GetPrimaryPatronData.hasopencall>
	<CFSAVECONTENT variable="message">
	has open call
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<cfoutput>#variables.message#</cfoutput><CFINCLUDE template = "includes/layout.cfm">
	<cfabort> --->

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
	<a href="#application.portalserver#/portal/classes/index.cfm?cartempty=1&patronlookup=#GetPrimaryPatronData.patronlookup#"><strong><< Return to class search</strong></a></CFOUTPUT>
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
<!--- <cfset recentappemptlimit = 60> --->


<!--- end --->

<!--- <cfset application.possibleerrorflag = false> --->

<!---<cfset mode = application.processormode>--->
<cfset testmode = false>

<cfif IsDefined( "cookie.debugmode" ) and cookie.debugmode eq dateformat( now(), "D" )>
	<cfset testmode = true>
</cfif>




<!--- get next pk --->
<cfquery datasource="#application.dopsds#ro" name="getnextcallpk">
	Select nextval('dops.invoicetranxcall_pk_seq') as callpk
</cfquery>
<!--- end get next pk --->

<cfif 1><!--- set dev mode --->
	<cfset callreference = getccreference( form.currentsessionid, getnextcallpk.callpk, "DEV" )>
<cfelse><!--- set production mode --->
	<cfset callreference = getccreference( form.currentsessionid, getnextcallpk.callpk, "DB" )>
</cfif>

<cfif variables.callreference eq "">
	<CFSAVECONTENT variable="message">
	Error in determining credit card call reference code.
	</CFSAVECONTENT>
	<CFSET nobackbutton = true>
	<cfoutput>#variables.message#</cfoutput><CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfif>

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
<cfset keepthisinvoice = 1>

<!---<cftry>--->




<cftransaction action="BEGIN" isolation="REPEATABLE_READ">

<!--- look for payment for this session --->
<cfinclude template="/portal/invoicetranxcheckforapproval.cfm">
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
          <cfset NextInvoice = GetNextInvoiceBP()>


          <!--- ----------------- --->
          <!--- Other Credit used --->
          <!--- ----------------- --->
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
                             dops.getavailableocfunds( othercredithistorysums.cardid::integer, othercredithistorysums.primarypatronid::integer, #numberformat(form.totalfees,"______.00")#, #numberformat(form.netdue,"______.00")#, true ) as sumnet
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
               <CFOUTPUT>#variables.othercreditdata# #IsNumeric(variables.OtherCreditData)# Error in fetching Other Credit Card or is invalid/not activated/on hold for review.</CFOUTPUT>
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

               <cfinclude template="/securedops/OCCardUsagePrefix.cfm">

          </cfif>

		<cfset TotalOtherCreditAmount = 0>

			<!--- do actual reg processing --->
          <cfinclude template="checkoutReg.cfm">

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
               <cfset KeepThisInvoice = 1>
               <cfset NextEC = application.dopscheckout.GetNextEC()>
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

					<cfinclude template="/portal/invoicetranxupdatetxdist.cfm">

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
			<cfinclude template="/securedops/displayallinvoicetables.cfm">
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
               <cfset KeepThisInvoice = 1>
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
    <cfset ocdist = application.dopscheckout.SetOCUsage( variables.LocalFac, variables.NextInvoice )>

    <cfif variables.ocdist lt 0>

	    <CFSAVECONTENT variable="diagnostics">
		    <cfinclude template="/securedops/displayallinvoicetables.cfm">
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
          <CFSET finalchecksmsg = finalchecks( variables.localfac, variables.NextInvoice )>

          <CFIF finalchecksmsg NEQ "OK">
               <CFSET message = finalchecksmsg>
               <cfoutput>#finalchecksmsg#</cfoutput><cfabort><CFINCLUDE template = "includes/layout.cfm">
               <cfabort>
          </CFIF>





		<!--- make processor call --->
		<cfif form.tenderedcharge gt 0>

			<!--- direction decision --->
			<cfif CheckForApproval.recordcount eq 0>
				<!--- no payment found --->
				<cftransaction action="ROLLBACK" />

				<!--- build all form elements --->
				<cfset hiddenfieldsdebug = 0>

				<cfloop list="#form.fieldNames#" index="elementloop">

					<cfif lCase( variables.elementloop ) neq "browserhistorydepth">
						<cfoutput>
						<input name="#variables.elementloop#" value="#lTrim( rTrim( form[ variables.elementloop ] ) )#" type="<cfif variables.hiddenfieldsdebug>text<cfelse>hidden</cfif>" <cfif variables.hiddenfieldsdebug>title="#variables.elementloop#" readonly</cfif>>
						</cfoutput>
					</cfif>

				</cfloop>
				<!--- end build all form elements --->

				<!---<cfif IsDefined("cookie.ccsalemode") and cookie.ccsalemode neq "">
					<cfset mode = uCase( cookie.ccsalemode )>
				<cfelse>
					<cfset mode = "real">
				</cfif>--->


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
				<cfset customer.amount           = form.tenderedcharge>
				<cfset customer.name             = customer.firstname & " " & customer.lastname>
				<cfset customer.callcomment      = "On Line Reg">

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

				<cfinclude template="/portal/invoicetranxcallclose.cfm">
				<cfabort>

			<cfelse>
				<!--- finish session --->
				<cfinclude template="/portal/invoicetranxcallfinish.cfm">
			</cfif>
		<!--- end direction decision --->







			<!--- insert invoiceID for mailing
			<CFIF cgi.server_addr NEQ application.devIP>

				<cfquery datasource="#application.dopsds#" name="queuemailer">
					insert into webinvoicequeue
						( invoicenumber, email )
					VALUES
						( <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#GetPrimaryPatronData.loginemail#" cfsqltype="CF_SQL_VARCHAR"> )
				</cfquery>

			</CFIF> --->

			<cfif 0>
				<cfinclude template="../displayallinvoicetables.cfm">
				<cfabort>
			</cfif>

		</cfif>
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




<!--- VERY IMPORTANT! update sessionid so they can do another transaction --->
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

<!--- send email indicating success
<CFMAIL to="#application.erroremail1#" from="webadmin@thprd.org" cc="#application.erroremail2#" subject="Online Checkout Completed" type="html">

Checkout.thprd.org successfully created the following invoice: WWW-#variables.nextinvoice# (#now()#)<br>
<br>
<CFDUMP var="#variables.result#">
</CFMAIL>
--->
<CFSAVECONTENT variable="successmessage">
<CFOUTPUT>Processing is complete. <a href="/checkout/invoice/printinvoice.cfm?invoicelist=WWW-#variables.nextinvoice#" target="_blank">View Invoice</a><br><br>

<!--- 2014 web site registration survey
THPRD would like to know what you think are the strengths and weaknesses of the current park district website. We are interested in your comments on the full site. Please take a moment to complete <a href="https://www.surveymonkey.com/s/2014THPRDWEBSURVEY" target="_new">this brief survey</a>. We greatly appreciate your feedback.<br>
<ul>
<li><a href="https://www.surveymonkey.com/s/2014THPRDWEBSURVEY" target="_new"><strong>Click here to take survey</strong></a><br><br>
</ul>
--->

<!---
THPRD would like to know how you hear about our class offerings, special events and general information about the park district.<br /><br />In appreciation for taking the time to fill out <a target="_blank" href="https://www.surveymonkey.com/s/THPRDSummer2014" style="color:##ffff00;"><strong>this brief survey</strong></a>, each respondent will have a chance to win a $50 THPRD gift card in drawing to be held May 8th. Thank you!

<ul>
<li><a href="https://www.surveymonkey.com/s/THPRDSummer2014" target="_new"><strong>Click here to take survey</strong></a><br><br>
</ul>
--->

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
<CFSET currentstep = 6>
<CFINCLUDE template = "includes/layout.cfm">



<cfabort>





















<!--- functions: place correctly: just here to get this going --->
<cffunction name="getccreference" output="yes" returntype="String">
<cfargument name="currentsessionid" required="yes" type="string">
<cfargument name="callpk" required="yes" type="numeric">
<cfargument name="servername" required="yes" type="string">

<!--- create credit call reference for insertion into processor --->
<cfset var local.reference = "">
<cfset var local.GetCallPK = "">

<!--- build reference --->
<cfset local.reference = "R" & numberformat( arguments.callpk, "0000000000")>

<cfif arguments.servername eq "DEV">
	<cfset local.reference = local.reference & "-D-">
<cfelseif arguments.servername eq "DB">
	<cfset local.reference = local.reference & "-P-">
<cfelse>
	<cfreturn ""><!--- error so return nothing --->
</cfif>

<cfset local.reference = local.reference & arguments.currentsessionid>
<!--- end build reference --->

<cfreturn local.reference>
</cffunction>




<!--- final checks function: returns "OK" if everything is correct. If not, returns error as string. --->
<cffunction name="finalchecks" output="Yes" returntype="string">
<cfargument name="thisfacid" type="string" required="true">
<cfargument name="thisinvoice" type="numeric" required="true">
<cfset var Check4InvoiceWasCreated = "" />
<cfset var GetGLE = "" />
<cfset var GetInvoiceInvoiceNet = "" />
<cfset var GetOCChecks = "" />
<cfset var GetOCErrorRecords = "" />
<cfset var GetTXChecks = "" />

<cfquery name="local.Check4InvoiceWasCreated" datasource="#application.dopsds#">
	select   pk
	from     dops.invoice
	where    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
	and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
	limit    1
</cfquery>

<!--- no invoice created so return nothing --->
<cfif local.Check4InvoiceWasCreated.recordcount eq 0>
	<cfreturn "OK">
</cfif>

<cfquery name="local.GetGLE" datasource="#application.dopsds#">
	select   dops.getglerror( <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER"> ) as gle
</cfquery>

<cfif local.GetGLE.recordcount eq 1 and dollarRound( GetGLE.gle ) neq 0>
	<cfreturn "GL error of was detected for proposed invoice during final check">
	<cfabort>
</cfif>

<!--- check for negative invoice balance --->
<cfquery name="local.GetInvoiceInvoiceNet" datasource="#application.dopsds#">
	select   invoicenet,
	         invoicetype
	from     dops.invoicenet
	where    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
	and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
</cfquery>

<cfif local.GetInvoiceInvoiceNet.invoicenet eq "">
	<cfreturn "Invoice balance resulted in a blank value.">
	<cfabort>
</cfif>

<cfif local.GetInvoiceInvoiceNet.recordcount eq 1 and dollarRound( local.GetInvoiceInvoiceNet.invoicenet ) lt 0>
	<cfreturn "Invoice balance resulted in a negative value">
	<cfabort>
</cfif>

<!--- verify oc usage --->
<cfif local.GetInvoiceInvoiceNet.recordcount eq 1 and IsDefined("othercreditused") and IsDefined("OtherCreditData") and othercreditused gt 0 and OtherCreditData is not "">

	<cfquery name="local.GetOCChecks" datasource="#application.dopsds#">
		select   #decimalformat( form.othercreditused )# as othercreditused, (

		SELECT   coalesce( sum( credit ), 0 )
		FROM     dops.othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistsum, (

		SELECT   coalesce( sum( debit ), 0 )
		FROM     dops.othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocusedsum, (

		SELECT   dops.getocbalance( othercredithistorysums.cardid, othercredithistorysums.primarypatronid )
		FROM     dops.othercredithistorysums
		where

		<cfif IsNumeric( form.OtherCreditData ) and form.OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="#form.OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#arguments.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as cardusedbalance, (

		SELECT   faapptype
		FROM     dops.othercredithistorysums
		where

		<cfif IsNumeric( form.OtherCreditData ) and form.OtherCreditData lt 999999999999>
			cardid = <cfqueryparam value="#form.OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
		<cfelse>
			othercreditdata = <cfqueryparam value="#arguments.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
		</cfif>) as faapptype

	</cfquery>

	<!--- check for negative value --->
	<cfif dollarRound( val( GetOCChecks.cardusedbalance ) ) lt 0>
		<strong>Other Credit balance resulted in a negative value: #dollarformat( GetOCChecks.cardusedbalance )#. Go back and try again. If problem persists, contact IS.</strong><BR><BR>
		<cfinclude template="/Common/BackButton.cfm">

		<cfif servername is "DEV" or debug_user is 22952>
			<cfdump var="#GetOCChecks#" label="GetOCChecks">
			<cfinclude template="/Common/displayallinvoicetables.cfm">
			<cfinclude template="/Common/displaymemory.cfm">
		</cfif>

		<cfabort>

	</cfif>
	<!--- end check for negative value --->


	<!--- verify oc dist--->
	<cfif not IsDefined("DistributionOnly")>

		<cfif GetOCChecks.recordcount is 1 and dollarRound( val( GetOCChecks.ocusedsum ) ) neq dollarRound( val( GetOCChecks.othercreditused ) )>
			<strong>Other Credit Used calculation Error.<BR><BR>

			<cfif IsDefined("request.errormsg")>
				#request.errormsg#
			<cfelse>
				Expected #decimalformat( GetOCChecks.othercreditused )#, found #decimalformat( GetOCChecks.ocusedsum )#
			</cfif>

			<BR><BR>

			Go back and try checkout again or contact IS if problem persists.</strong><BR><br>
			<cfinclude template="/Common/BackButton.cfm">

			<cfif servername is "DEV" or debug_user is 22952>
				<cfdump var="#GetOCChecks#" label="GetOCChecks">
				<cfinclude template="/Common/displayallinvoicetables.cfm">
				<cfinclude template="/Common/displaymemory.cfm">
			</cfif>

			<cfabort>

		</cfif>

	</cfif>

	<cfif GetOCChecks.recordcount is 1 and dollarRound( val( GetOCChecks.ocdistsum ) ) neq dollarRound( val( othercreditused ) )>
		<strong>Other Credit Distribution Error.<BR><BR>

		<cfif IsDefined( "request.errormsg" )>
			#request.errormsg#
		<cfelse>
			Found used OC of #decimalformat( GetOCChecks.othercreditused )# vs. OC dist sum of #decimalformat( GetOCChecks.ocdistsum )#.
		</cfif>

		<br><br>

		<cfquery name="local.GetOCErrorRecords" datasource="#application.dopsds#">
			SELECT   *
			FROM     dops.othercreditdist
			WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
		</cfquery>

		<cfif 0>
			<cfdump var="#local.GetOCErrorRecords#" label="Raw OC dist records">
		</cfif>

		<BR><BR>
		Go back and try checkout again or contact IS if problem persists.</strong><BR><br>
		<cfinclude template="/Common/BackButton.cfm">

		<cfif servername is "DEV" or debug_user is 22952>
			<cfdump var="#GetOCChecks#" label="GetOCChecks">
			<cfinclude template="/Common/displayallinvoicetables.cfm">
			<cfinclude template="/Common/displaymemory.cfm">
		</cfif>

		<cfabort>
	</cfif>

	<!--- end verify oc dist--->


	<!--- verify tx dist--->
	<!--- note: dops.invoicetranx is NOT checked as may not be created at this time due to delayed cc processing --->
	<!--- only distribution is checked against specified amount from payment form as form.tenderedcharge --->
	<cfif IsDefined("form.tenderedcharge") and form.tenderedcharge gt 0 and 1>

		<cfquery name="local.GetTXChecks" datasource="#application.dopsds#">
			SELECT   coalesce( sum( amount ), 0 ) as txdistsum
			FROM     dops.invoicetranxdist
			WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">
			and      amount > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
		</cfquery>

		<cfif GetTXChecks.txdistsum neq form.tenderedcharge>
			<strong>TX Distribution Error.<BR><BR>

			<cfif IsDefined("request.errormsg")>
				#request.errormsg#
			<cfelse>
				Expected #decimalformat( form.tenderedcharge )#, found #decimalformat( GetTXChecks.txdistsum )#.
			</cfif>

			<br><br>

			Go back and try checkout again or contact IS if problem persists.</strong><BR><br>
			<cfinclude template="/Common/BackButton.cfm">

			<cfif servername is "DEV" or IsDefined("debug_user") and debug_user is 22952>
				<cfdump var="#GetTXChecks#" label="GetTXChecks">
				<cfinclude template="/Common/displayallinvoicetables.cfm">
				<cfinclude template="/Common/displaymemory.cfm">
			</cfif>

			<cfabort>
		</cfif>

	</cfif>
	<!--- end verify tx dist--->

</cfif>
<!--- end verify oc usage --->

<cfif IsDefined( "arguments.performoctests" )>
	<cfquery name="local.GetOCChecks" datasource="#application.dopsds#">
		select   (

		SELECT   coalesce( sum( credit ), 0 )
		FROM     dops.othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistcreditsum, (

		SELECT   coalesce( sum( debit ), 0 )
		FROM     dops.othercreditdistview
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdistdebitsum, (

		SELECT   coalesce( sum( credit ), 0 )
		FROM     dops.othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as occreditsum, (

		SELECT   coalesce( sum( debit ), 0 )
		FROM     dops.othercreditdatahistory
		WHERE    invoicefacid = <cfqueryparam value="#arguments.thisfacid#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#arguments.thisinvoice#" cfsqltype="CF_SQL_INTEGER">) as ocdebitsum
	</cfquery>

	<cfif GetOCChecks.recordcount eq 1>

		<cfif GetOCChecks.ocdistcreditsum neq GetOCChecks.ocdebitsum>
			ERROR: OC dist credit of #decimalformat( GetOCChecks.ocdistcreditsum )# did not match OC debit of #decimalformat( GetOCChecks.ocdebitsum )#<BR>
		</cfif>

		<cfif GetOCChecks.ocdistdebitsum neq GetOCChecks.occreditsum>
			ERROR: OC dist debit of #decimalformat( GetOCChecks.ocdistdebitsum )# did not match OC credit of #decimalformat( GetOCChecks.occreditsum )#<BR>
		</cfif>

	</cfif>

</cfif>
<!--- end invoice was created --->

<cfreturn "OK">
</cffunction>
<!--- end final checks --->




<cffunction name="GetNextPRC" output="Yes" returntype="numeric">
<cfset var GetNextPRC = "" />

<cfquery name="local.GetNextPRC" datasource="#application.dopsds#">
	Select nextval('"dops"."prc_seq"') as tmp
</cfquery>

<cfreturn local.GetNextPRC.tmp>

</cffunction>




<!--- function get user data defined --->
<cffunction output="yes" name="GetBPUserData" description="BridgePay User Fetch routine">
<cfset var BridgePayUserParams = "">
<cfset var BridgePayUserStruct = "">

<cfquery name="local.BridgePayUserParams" datasource="#application.dopsds#">
	select   (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayUserID" cfsqltype="cf_sql_varchar" list="no"> ) as bpuserid, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayPW" cfsqltype="cf_sql_varchar" list="no"> ) as bppassword, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayMerchantCode" cfsqltype="cf_sql_varchar" list="no"> ) as bpMerchantCode, (

	select   varvalue
	from     dops.systemvars
	where    varname = <cfqueryparam value="BridgePayMerchantAccountCode" cfsqltype="cf_sql_varchar" list="no"> ) as bpMerchantAccountCode
</cfquery>

<cfif local.BridgePayUserParams.recordcount eq 0 or
	local.BridgePayUserParams.bpuserid eq "" or
	local.BridgePayUserParams.bppassword eq "" or
	local.BridgePayUserParams.bpMerchantCode eq "" or
	local.BridgePayUserParams.bpMerchantAccountCode eq "">
	<cfreturn "ERROR: Data returned from fetching BridgePay user params failed. Contact IS.">
	<cfabort>
</cfif>

<cfset local.BridgePayUserStruct = StructNew()>
<cfset StructInsert( local.BridgePayUserStruct, "BPUserID", local.BridgePayUserParams.bpuserid )>
<cfset StructInsert( local.BridgePayUserStruct, "BPPassword", local.BridgePayUserParams.bppassword )>
<cfset StructInsert( local.BridgePayUserStruct, "BpMerchantCode", local.BridgePayUserParams.bpMerchantCode )>
<cfset StructInsert( local.BridgePayUserStruct, "BPMerchantAccountCode", local.BridgePayUserParams.bpMerchantAccountCode )>
<cfreturn local.BridgePayUserStruct>
</cffunction>




<cffunction name="GetNextInvoiceBP" returntype="numeric">
<cfset gn = "" />

<!--- grabs the next TEMPORARY invoice number (aka, invoice.pk sequence ) --->
<cfquery datasource="#application.dopsds#" name="local.gn">
	SELECT dops.getnextinvoice( '' ) as nextinvoice
</cfquery>

<cfreturn local.gn.nextinvoice>
</cffunction>

<!--- end function get user data defined --->
