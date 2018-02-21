
<!--- check for required variables 
<CFDUMP var="#form#">
--->


<!--- GetNextInvoice(), SystemLock(), GetNextEC() and GetNextECNew(), Overlap(), Isbetween() are inluded 
<CFINCLUDE template="/portalINC/invoice_functions.cfm">--->

<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset huserid = 0>
<CFSET invoicetypestr = '-ASSMT-'>





<!---<cftransaction action="BEGIN" isolation="REPEATABLE_READ">--->

	<!--- SQL LOCK 08.24.2009
  <cfquery name="LockInvoice" datasource="#application.dopsds#">
   select   locktype
   from     dops.systemlock
   where    locktype = <cfqueryparam value="INVOICE" cfsqltype="CF_SQL_VARCHAR">
   for      update
  </cfquery>	--->	

	<cfset CurrentAccountBalance = GetAccountBalance(form.primarypatronid)>
	
	<cfif (val(form.netbalance) is not CurrentAccountBalance or val(form.creditused) gt CurrentAccountBalance)>
		<CFSET errormessage="Different account balance was found or credit used exceeds available credit.<br> <a href=""javascript:history.back(); "">Please go back and try gain.</a>">
		<CFINCLUDE template="finishassessmentDisplay.inc">
		<cfabort>
	</cfif>
	

	<!--- check for cc data NOT USED ANYMORE 08.29.2016 --->
     <!---
	<cfif val(form.amountdue - form.creditused) gt 0>

  		<cfif form.ccnum1 EQ 4801>
			<CFSET errormessage="The credit card data supplied is not compatible with our payment system. We cannot process cards starting with '4801'. <br> <a href=""javascript:history.back(); "">Please go back and select a different payment method.</a>">
			<CFINCLUDE template="finishassessmentDisplay.inc">
			<cfabort>
		</cfif>

		<cfset ccNum = form.ccnum1 & form.ccnum2 & form.ccnum3 & form.ccnum4>
		<cfset ccExp = form.ccExpMonth & "/" & right(form.ccExpYear,2)>
		<cfset ccType = form.ccType>
		<!--- check card type and number for validity --->
		<CF_mod10 ccType = "#ccType#" ccNum="#ccNum#" ccExp="#ccExp#">
		<cfset ccv1 = REREPLACE(form.ccv,"[^0-9]","","ALL")>

		<cfif len(ccv1) neq 3>
			<cfset valid = 0>
		</cfif>

		<cfif valid is 0>
			<CFSET errormessage="An invalid credit card number/CCV/expiration date was entered.<br> <a href=""javascript:history.back(); "">Please go back and try gain.</a>">
			<CFINCLUDE template="finishassessmentDisplay.inc">
			<cfabort>
		</cfif>
  

          
          
		<!---	<cf_cryp	[ type = "{ en* | de }" ] (en=encrypt, de=decrypt; default is "en")
									string = "{ string to encrypt or decrypt }"
									key = "{ key to use for encrypt or decrypt }"
									[ return = "{ name a variable to return to the calling page as a structure, default is 'cryp' }" --->
		<cfset ccNum = REPLACE(ccNum," ","","ALL")>
		<cfset ccNum = REREPLACE(ccNum,"[^0-9]","","ALL")>
		<cfset ccExp = REPLACE(ccExp," ","","ALL")>
		<cfset ccExp = REREPLACE(ccExp,"[^0-9]","","ALL")>
		
		<cf_cryp type="en" string="#ccNum#" key="#skey#">
		<cfset ccd = cryp.value>

		<cfif ltrim(rtrim(ccv1)) is not "">
			<cf_cryp type="en" string="#ccv1#" key="#skey#">
			<cfset ccven = cryp.value>
		</cfif>
	
	<cfelse>
		<cfset ccNum = "">
	</cfif>
	--->
	<!--- money OK - proceed --->

	<!--- get acct id using ADM for facid --->
	<cfquery datasource="#application.reg_dsn#" name="GetAssmtGL">
		select acctid
		from glmaster
		where facid = 'ADM'
		and passtype = 'ASSMT'
	</cfquery>

	<!--- error --->
	<cfif GetAssmtGL.recordCount is not 1>
		<CFSET errormessage="Error in obtaining information for assessment. Please contact THPRD.">
		<CFINCLUDE template="finishassessmentDisplay.inc">
		<cfabort>
	</cfif>

	<cfquery datasource="#application.reg_dsn#" name="GetGLDistCredit">
		select AcctID
		from GLMaster
		where InternalRef = 'DC'
	</cfquery>

	<cfset GLDistCreditAccount = GetGLDistCredit.acctID>

	<cfquery datasource="#application.reg_dsn#" name="GetMembers">
		SELECT   secondarypatronid
		FROM     patronrelations 
		WHERE    detachdate is NULL 
		AND      primarypatronid = #form.primarypatronid#
	</cfquery>

	<cfquery datasource="#application.reg_dsn#" name="GetPrimaryData">
		SELECT   patronrelations.addressid, patronrelations.mailingaddressid 
		FROM     patronrelations patronrelations
				 INNER JOIN patrons patrons ON patronrelations.secondarypatronid=patrons.patronid 
		WHERE    patronrelations.primarypatronid = #form.primarypatronid#
		AND      patronrelations.secondarypatronid = #form.primarypatronid#
	</cfquery>

	<cfset InvoiceDT = now()>
	<cfset Nextinvoice = GetNextInvoice()>
	<cfset ActivityLine = 0>

	<cfquery datasource="#application.reg_dsn#" name="GetMailingAddress">
		select mailingaddressid
		from patronrelations
		where primarypatronid = #form.primarypatronid#
		and secondarypatronid = #form.primarypatronid#
	</cfquery>

	<cfset TotalFees = 0>
	<cfset GLLineNo = 0>

	<cfloop query="GetNewAssessments">
		<cfset NextEC = GetNextEC()>
          <cfset nextprc = GetNextPRC()>
		<cfset ActivityLine = ActivityLine + 1>
	
		<cfquery datasource="#application.reg_dsn#" name="AddToActivity">
			insert into Activity
				(ActivityCode,PrimaryPatronID,PatronID,InvoiceFacID,InvoiceNumber,Debit,Credit,line,EC,activity)
			values
				('AP',#form.PrimaryPatronID#,#form.PrimaryPatronID#,'#LocalFac#',#NextInvoice#,#rate#,0,#ActivityLine#,#NextEC#,'Assmt #name#')
		</cfquery>
	
		<cfset GLAmount = GetNewAssessments.rate>
		<cfset totalFees = TotalFees + GLAmount>

		<cfquery datasource="#application.reg_dsn#" name="InsertNewAssessment">
			insert into Assessments
				(PrimaryPatronID,Operation,AssmtType,InvoiceFacID,
				InvoiceNumber,AssmtFee,AssmtEffective,AssmtExpires,EC,
				valid,assmtplan,assmtname,grace,prc)
			values
				(#form.PrimaryPatronID#,'N','F','#LocalFac#',
				#NextInvoice#,#rate#,#CreateODBCDate(assmteffective)#,#CreateODBCDate(AssmtExpires)#,#NextEC#,
				true,2,'#name#',#grace#,<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">)
		</cfquery>

		<cfloop query="GetMembers">

			<cfquery datasource="#application.reg_dsn#" name="InsertData">
				insert into AssessmentMembers
					(PrimaryPatronID,PatronID,EC,dtadded)
				values
					(#form.PrimarypatronID#,#secondarypatronid#,#NextEC#,#CreateODBCDateTime(InvoiceDT)#)
			</cfquery>	

		</cfloop>

		<cfset GLLineNo = GLLineNo + 1>

		<cfquery datasource="#application.reg_dsn#" name="InsertGL2">
			insert into GL
				(Credit,AcctID,InvoiceFacID,InvoiceNumber,EntryLine,ec,activitytype,activity)
			values
				(#rate#,#GetAssmtGL.AcctID#,'#LocalFac#',#NextInvoice#,#GLLineNo#,#NextEC#,'A','Assmt #name#')
		</cfquery>
	
     	     <!--- do the invoicetranxdist --->
     
        <cfquery name="InsertIntoTranxHist" datasource="#application.dopsds#">
          insert into dops.invoicetranxtrans
               ( prc,
               assmt )
          values
               ( <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
               <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no"> )
          ;

          insert into dops.invoicetranxdist
               ( primarypatronid,
               reftype,
               invoicefacid,
               invoicenumber,
               prc,
               amount,
               action )
          values
               (<cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
               <cfqueryparam value="ASSMT" cfsqltype="cf_sql_varchar" list="no">,
               <cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
               <cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
               <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
			   <cfqueryparam cfsqltype="cf_sql_money" value="#form.netdue#" list="no">,
               <!---60,  this needs to be fixed --->
               <cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">)
          </cfquery>
     
	</cfloop>

	<cfquery datasource="#application.reg_dsn#" name="InsertInvoice">
		insert into invoice
			(InvoiceFacID,InvoiceNumber,PrimaryPatronID,AddressID,mailingaddressid,
			InDistrict,TotalFees,UsedCredit,
			startingbalance,
               <!---TenderedCash,
               TenderedCheck,--->
               TenderedCC,
               <!---TenderedChange,
			CCA,
               CCED,
               CEW,
               ccType,
               CCV,--->
			Node,userid,dt,invoicetype)
		values
			('#LocalFac#',#NextInvoice#,#form.PrimaryPatronID#,#GetPrimaryData.addressid#,<cfif GetPrimaryData.mailingaddressid is "">#GetPrimaryData.addressid#<cfelse>#GetPrimaryData.mailingaddressid#</cfif>,
			false,#TotalFees#,#form.creditused#,
			#form.netbalance#,
               <!---0,0,--->
               <!--- #form.amountdue - form.creditused#, --->
				#form.amountdue#,
               <!---0,--->
               <!---
			<cfif ccNum is not "">'#ccd#','#ccExp#','#right(ccNum,4)#','#left(ccNum,1)#',<cfif ccv1 is "">null<cfelse>'#ccven#'</cfif><cfelse>null,null,null,null,null</cfif>,--->
			'#LocalNode#',#hUserID#,
			'#dateformat(InvoiceDT,"yyyy-mm-dd")# #timeformat(InvoiceDT,"HH:MM:SS")#',
			'#invoicetypestr#')
	</cfquery>

	<cfif form.creditused gt 0>
		<cfset NextEC = GetNextEC()>
		<cfset ActivityLine = ActivityLine + 1>

		<cfquery datasource="#application.reg_dsn#" name="AddToActivity">
			insert into Activity
				(ActivityCode,PrimaryPatronID,PatronID,InvoiceFacID,InvoiceNumber,Debit,Credit,line,EC)
			values
				('CU',#form.PrimaryPatronID#,#form.PrimaryPatronID#,'#LocalFac#',#NextInvoice#,#form.creditused#,0,#ActivityLine#,#NextEC#)
		</cfquery>

		<cfset GLLineNo = GLLineNo + 1>

		<cfquery datasource="#application.reg_dsn#" name="InsertGL1">
			insert into GL
				(Debit,AcctID,InvoiceFacID,InvoiceNumber,EntryLine,EC,activitytype,activity)
			values
				(#form.CreditUsed#,#GLDistCreditAccount#,'#LocalFac#',#NextInvoice#,#GLLineNo#,#NextEC#,'C','Credit')
		</cfquery>

		<cfset GLLineNo = GLLineNo + 1>
	</cfif>

	<cfset ActivityLine = ActivityLine + 1>

	<cfquery datasource="#application.reg_dsn#" name="AddToActivity">
		insert into Activity
			(ActivityCode,PatronID,InvoiceFacID,InvoiceNumber,Debit,Credit,line,EC,primarypatronid)
		values
			('PMT',#form.PrimaryPatronID#,'#LocalFac#',#NextInvoice#,0,#form.amountdue#,#ActivityLine#,#GetNextEC()#,#form.primarypatronid#)
	</cfquery>

	<cfif 1 is 11>
		<cfabort>
	</cfif>
     

     
     
     
<!---</cftransaction>--->
<!--- clear cookie 
<cfset cookie.assmtpicks=0>--->

<!---
<!--- go to receipt with receipt number --->
<CFSET confirmmessage="Assessment Purchase was successful. Thank you.<br><a href=""javascript:void(0);"" onClick=""window.open('../classes/class_summary_receipt.cfm?invoicelist=#localfac#-#NextInvoice#&p=y','receipt','toolbars=no, scrollbars=yes, resizable');"">View invoice #localfac#-#NextInvoice#</a>">
<CFINCLUDE template="finishassessmentDisplay.inc">
<!--- END: processing for assessment --->
--->

