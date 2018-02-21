


<CFSET invoicetypestr = "-REG-">
<!--- initial giftcard set up --->
<!--- convert to proper naming --->
<CFSET othercreditused = form.giftcarddebitamount>
<CFSET othercreditdata = form.giftcardnumber>
<cfset OtherCreditReturn = 0>
<cfset huserid = 0>
<cfset primarypatronid = pid>
<!---<cfset CurrentSessionID = GetSessionID(primarypatronid)>--->
<!---cfset CurrentSessionID = cookie.sessionID>--->

<!--- CurrentSessionID defined on lines 19-26 of class_summary.cfm --->
<CFIF NOT structkeyexists(variables,"CurrentSessionID")>Fatal Error<CFABORT></CFIF>
<CFSET facardid = "">
<cfset ccnum = ccnum1 & ccnum2 & ccnum3 & ccnum4>
<cfset TOTALNEWCREDIT = 0>
<cfset ccexp = ccExpMonth & right(ccExpYear, 2)>

<cfif ccnum is not "">
	<cf_cryp type="en" string="#ccNum#" key="#key#">
	<cfset ccd = cryp.value>
	<cf_cryp type="en" string="#ccv#" key="#key#">
	<cfset ccven = cryp.value>

	<cfif ccd is "" or ccven is "">
		Missing or incorrect credit card data detected
		<BR><BR><a href="javascript:history.back();">Go Back</a>
		<cfabort>
	</cfif>

	<!--- check for visas starting 4801 as they are not compatible with our payment system --->
	<cfif left(ccNum, 4) is "4801">
		<BR><BR>
		<strong>The credit card data supplied is not compatible with our payment system. All cards starting with "4801" are not usable. Please use another payment method.</strong><BR><BR>
		<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<BR><BR><cfabort>
	</cfif>

</cfif>


<!--- define vars for code compatability with internal --->
<cfset TenderedCash = 0>
<cfset TenderedCheck = 0>
<cfset TenderedChange = 0>
<cfset primarypatronid = cookie.uID>

<!--- 
<cfquery datasource="#application.dopsdsro#" name="GetGLDistCredit" cachedwithin="#CreateTimeSpan(1,0,0,0)#">
	select   AcctID
	from     GLMaster
	where    InternalRef = <cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">
</cfquery>

<cfif GetGLDistCredit.RecordCount is not 1>
	<strong>Error in fetching system information. Go back and try again.</strong>
	<BR><BR><a href="javascript:history.back();">Go Back</a>
	<cfabort>
</cfif>

<cfset GLDistCreditAccount = GetGLDistCredit.acctID>
 --->

<cfif FindNoCase("In", cookie.DS)>
	<cfset ds_stat = "true">
<cfelse>
	<cfset ds_stat = "false">
</cfif>

<cfset keepthisinvoice = 1>

<cftransaction action="BEGIN" isolation="REPEATABLE_READ">

	<cfquery name="LockInvoice" datasource="#application.dopsds#">
		select   facid
		from     dops.facilities
		where    facid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
		for      update
	</cfquery>

	<cfquery datasource="#application.dopsds#" name="GetPatronData">
		select   *
		from     SessionPatrons
		where    SessionID = <cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">
		order by relationtype
	</cfquery>

	<cfset ThisModule = "WWW">
	<cfset ActivityLine = 0>
	<cfset GLLineNo = 0>
	<cfset NextInvoice = GetNextInvoice()>


	<!--- verify starting credit --->
	<cfquery name="GetStartingAccountBalanceCheck" datasource="#application.dopsds#">
		select dops.primaryaccountbalance(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)
	</cfquery>

	<cfif dollarRound(GetStartingAccountBalanceCheck.primaryaccountbalance) is not dollarRound(originalavailablecredit)>
		<BR><BR><strong>Starting account balance did not match true balance.</strong>
		<BR><BR>
		<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<cfabort>

	</cfif>




	<!--- ----------------- --->
	<!--- Other Credit used --->
	<!--- ----------------- --->
	<cfif othercreditused gt 0 and OtherCreditData is not 0>
		<cfset ocNum = replace(OtherCreditData," ","","all")>
		<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
		<cf_cryp type="en" string="#ocNum#" key="#skey#">
		<cfset enOtherCreditData = cryp.value>

		<cfinclude template="/portalINC/GetOtherCreditData.cfm">
		<cfset otherCreditGLAcctid = getCardData.acctid>
		<cfinclude template="/portalINC/OCCardUsagePrefix.cfm">
	
	</cfif>





	<cfset TotalOtherCreditAmount = 0>
	<cfinclude template="checkoutReg.cfm">




	<cfif TotalOtherCreditAmount is not OtherCreditReturn>
		<BR><BR><strong>Error: Calculated Gift Card Credit does not what was expected. Expected #numberformat(OtherCreditReturn,"999,999.99")#: Found #numberformat(TotalOtherCreditAmount,"999,999.99")# Difference of #numberformat(TotalOtherCreditAmount - OtherCreditReturn,"999,999.99")#</strong>. Go back and try again.
		<BR><BR><a href="javascript:history.back();">Go Back</a>
		<cfabort>
	</cfif>

	<cfif othercreditused gt 0>
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

			<cfif ccNum is not "">
				CCA,
				CCED,
				CEW,
				ccType,
				CCV,
			</cfif>

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
			(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
			<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
			<cfqueryparam value="#totalfees#" cfsqltype="CF_SQL_MONEY">, --TotalFees
			<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">, --Used Credit
			<cfqueryparam value="#othercreditused#" cfsqltype="CF_SQL_MONEY">, --othercreditused

			<cfif othercreditused gt 0>
				<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">, --othercreditusedcardid
			<cfelse>
				null, ----othercreditusedcardid
			</cfif>
			
			<cfif othercreditused gt 0 and GetCardData.faappid is not "">
				<cfqueryparam value="#GetCardData.faappid#" cfsqltype="CF_SQL_INTEGER">, --faappid
			<cfelse>
				null, --faappid
			</cfif>
			
			<cfqueryparam value="#TenderedCharge#" cfsqltype="CF_SQL_MONEY">, --TenderedCC

			<cfif ccNum is not "">
				<cfqueryparam value="#ccd#" cfsqltype="CF_SQL_VARCHAR">, --CCA
				<cfqueryparam value="#ccExp#" cfsqltype="CF_SQL_VARCHAR">, --CCED
				<cfqueryparam value="#right(ccNum,4)#" cfsqltype="CF_SQL_VARCHAR">, --CEW
				<cfqueryparam value="#left(ccNum,1)#" cfsqltype="CF_SQL_VARCHAR">, --ccType
				<cfqueryparam value="#ccven#" cfsqltype="CF_SQL_VARCHAR">, --CCV
			</cfif>

			<cfqueryparam value="#LocalNode#" cfsqltype="CF_SQL_VARCHAR">, --LocalNode
			<cfqueryparam value="#huserID#" cfsqltype="CF_SQL_INTEGER">, --huserID
			<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">, (
		
			select   patronlookup
			from     patrons
			where    patronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			select   addressid
			from     patronrelations
			where    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			and      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			select   mailingaddressid
			from     patronrelations
			where    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			and      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			SELECT   indistrict 
			FROM     patronrelations 
			WHERE    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			AND      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			SELECT   patrons.insufficientid 
			FROM     patronrelations patronrelations
			         INNER JOIN patrons patrons ON patronrelations.secondarypatronid=patrons.patronid 
			WHERE    patronrelations.primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER"> 
			AND      patronrelations.secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

			select   dops.primaryaccountbalance(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)),

			<cfqueryparam value="-REG-" cfsqltype="CF_SQL_VARCHAR">)
		;

		select invoice_relation_fill(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as inserted
	</cfquery>

<!--- at some point remove the function above --->




	<cfif InsertInvoice.inserted is 0>
		<strong>Could not insert patrons for proposed invoice. Go back and try again.</strong>
		<br><br>
		<a href="javascript:history.back();">Go Back</a>
		<cfabort>
	</cfif>

	<cfset AllMonies = TenderedCharge>

	<!--- ----------- --->
	<!--- used credit --->
	<!--- ----------- --->
	<cfif CreditUsed greater than 0>
		<cfset KeepThisInvoice = 1>
		<cfset NextEC = GetNextEC()>
		<cfset ActivityLine = ActivityLine + 1>

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
				<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, --2
				<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, --3
				<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --4
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --5
				<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">, --6
				<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --7
				<cfqueryparam value="#ActivityLine#" cfsqltype="CF_SQL_INTEGER">, --8
				<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">) --9
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
				<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --3
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --4
				<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">, --5
				<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">, --6
				<cfqueryparam value="C" cfsqltype="CF_SQL_VARCHAR">, --7
				<cfqueryparam value="Credit" cfsqltype="CF_SQL_VARCHAR">) --8
		</cfquery>

	</cfif>





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
				<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, --2
				<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --3
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --4
				<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --5
				<cfqueryparam value="#AllMonies#" cfsqltype="CF_SQL_MONEY">, --6
				<cfqueryparam value="#ActivityLine#" cfsqltype="CF_SQL_INTEGER">, --7
				<cfqueryparam value="#GetNextEC()#" cfsqltype="CF_SQL_INTEGER">, --8
				<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">) --9
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
		WHERE    reghistory.invoicefacid = <cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">
		AND      reghistory.invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">)
	</cfquery>




	<!--- correct improper patronid in activity vs reghistory --->
	<cfquery datasource="#application.dopsds#" name="GetImproperRegIDInActivity">
		SELECT   activity.pk AS activitypk, 
		         reg.patronid AS regpatron
		FROM     dops.activity
		         INNER JOIN dops.reg ON activity.primarypatronid=reg.primarypatronid AND activity.regid=reg.regid AND activity.patronid!=reg.patronid 
		where    activity.primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
		ORDER BY activity.pk desc
		limit    50
	</cfquery>

	<cfif GetImproperRegIDInActivity.recordcount gt 0>
	
		<cfloop query="GetImproperRegIDInActivity">
	
			<cfquery datasource="#application.dopsds#" name="UpdateReg">
				update activity
				set
					patronid = <cfqueryparam value="#regpatron#" cfsqltype="CF_SQL_INTEGER">
				where pk = <cfqueryparam value="#activitypk#" cfsqltype="CF_SQL_INTEGER">
			</cfquery>
	
		</cfloop>
	
	</cfif>





	<!--- insert gift card distribution info if needed --->
	<cfif OtherCreditUsed gt 0>
		<cfset dopsds = application.dopsds>
		<cfset ocdist = SetOCUsage(LocalFac, NextInvoice)>

		<cfif ocdist lt 0>
			<strong>Other Credit Distribution Error was detected for proposed invoice. Go back and try again. If problem persists, contact THPRD.</strong><BR><BR>
			<a href="javascript:history.back();">Go Back</a>

			<cfif 1 is 11>
				<BR><BR><cfoutput>#request.errormsg#</cfoutput>
			</cfif>

			<cfabort>
		</cfif>

	</cfif>



	<cfinclude template="/portalINC/FinalChecks.cfm">



	<!--- rollback and display data if testing --->
	<cfif 1 is 11 or IsDefined("TestMode") or cgi.remote_addr EQ application.webmasterIP>
		
		<cfinclude template="/portalINC/displayallinvoicetables.cfm">

	</cfif>



	<!--- insert invoiceID for mailing --->
	<CFIF cgi.server_addr NEQ application.devIP>

		<cfquery datasource="#application.dopsds#" name="queuemailer">
			insert into webinvoicequeue
				(invoicenumber,email)
			VALUES
				(<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,<cfqueryparam value="#cookie.uemail#" cfsqltype="CF_SQL_VARCHAR">)
		</cfquery>

	</CFIF>

</cftransaction>
