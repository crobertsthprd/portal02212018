<cfset dopsds    = "dopsds">
<cfset nldopsds  = "dopsds">
<CFSET request.theCardType = 'GC'>
<!---<CFINCLUDE template="/portalINC/invoice_functions.cfm">--->
<CFINCLUDE template="/portalINC/addressfinder.cfm">
<!---<CFINCLUDE template="/portalINC/insession_function.cfm">---->


<!--- use welcome field for message in othercreditdata --->

<!--- REQUIRED UDFS
createUUID()
systemlock()
GetNextEC()
--->

<!--- REQUIRED ATTRIBUTES 
othercredittype: varchar
newpurchase: bit
amount:decimal

creditused: 0
tenderedcharge: decimal
formstartbalance: decimal

ccnum: integer
ccexp: date (mm/yyyy)
ccv: integer

thispatronid: 0
--->

<!--- 
process new and recharging of other credit

new cards use card data of 'TBD-'
'OCP' denotes other credit purchase
'OCR' denotes other credit recharge
everything done in transaction!
never allow any card to be purchased with another card
new cards are always processed as non-activated
callable for both portal and non-portal

be sure to insert these for each new card:

othercreditdata.shippingname, 
othercreditdata.shippingaddress, 
othercreditdata.shippingcity, 
othercreditdata.shippingstate, 
othercreditdata.shippingzip

IMPORTANT: on portal page, use patron's online credit FIRST

on portal page, use primarypatron data

all cfaborts denote some form of error that needs to be explained to patron
--->

<!---<cf_cryp	[ type = "{ en* | de }" ] (en=encrypt, de=decrypt; default is "en")
				string = "{ string to encrypt or decrypt }"
				key = "{ key to use for encrypt or decrypt }"
				[ return = "{ name a variable to return to the calling page as a structure, default is 'cryp' }" 
--->
<cfset ccNum = REPLACE(attributes.ccNum," ","","ALL")>
<cfset ccNum = REREPLACE(attributes.ccNum,"[^0-9]","","ALL")>

<!--- do credit card validation --->
<CF_mod10 ccType = "#attributes.ccType#" ccNum="#attributes.ccNum#" ccExp="#attributes.ccExp4valid#">
<cfif valid is 0>
	<CFSET confirmmessage = "The Credit Card data supplied is not valid. Please try again.">
	<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(confirmmessage)#">
<cfabort>
</cfif>

<!--- do credit card validation --->
<CFSET firstfour = left(trim(attributes.ccNum),4)>
<cfif firstfour EQ '4801'>
	<CFSET confirmmessage = "The credit card data supplied is not compatable with our payment system. We cannot process cards starting with '4801'. Please use a different payment method.<br><br>">
	<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(confirmmessage)#">
<cfabort>
</cfif>

<!--- encrypt the card --->

<cf_cryp type="en" string="#attributes.ccNum#" key="#skey#">
<cfset ccd = cryp.value>
<cf_cryp type="en" string="#attributes.ccv#" key="#skey#">
<cfset ccven = cryp.value>

<cfoutput>
<!--- make hidden field on calling page: fill with CreateUUID(): used to prevent duplicate orders --->
<!--- uses query "CheckSession" below --->
<cfset Sessionid = CreateUUID()>
<!--- set from calling page --->
<cfset CreditUsed = attributes.creditused>
<cfset tenderedcharge = attributes.amountdue>
<cfset formstartbalance = attributes.netbalance><!--- real primary patron balance when calling previous page: compare to now --->

<!--- welcome message --->
<cfset formcomments = "">

<CFIF listfind(application.developerip,cgi.remote_addr) GT 0 and Isdefined("form.rollback")>
<cfset testmode = 1><!--- 0=commit, 1=rollback --->
<CFELSE>
<cfset testmode = 0>
</CFIF>




<cfparam name="thisprimarypatronid" default="#attributes.primarypatronid#">
<!--- replace following query with the appropriate fetch method: remove for production --->
<cfset DoNotAllowNonPrimaryRecharge = 1>
<cfset cardtype = 1>
<!---cfdump var="#finalCart#"--->

<!--- if from portal page, thisprimarypatronid = primarypatronid: otherwise, 0 --->
<!--- used to lock card usage to portal patron: need option to do so --->
<!--- can only be invoked if from portal page, as primary is needed to relate to --->
<!--- not using credit for public site --->
<cfif CreditUsed gt 0 and thisprimarypatronid is 0>
	
	<CFSET confirmmessage = "Must be known patron to use credit">
	<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(confirmmessage)#">
	<cfabort>
</cfif>
<!--- check for already processed --->
<cfquery datasource="#application.dopsds#" name="CheckSession">
	select sessionid
	from sessions
	where sessionid = '#sessionid#'
</cfquery>
<cfif CheckSession.recordcount gt 0>
	Already processed
	<cfabort>
</cfif>
<!--- end check for already processed --->
<cftransaction action="BEGIN" isolation="REPEATABLE_READ">

	<!--- SQL LOCK 08.24.2009--->	
  <cfquery name="LockInvoice" datasource="#application.dopsds#">
   select   locktype
   from     dops.systemlock
   where    locktype = <cfqueryparam value="INVOICE" cfsqltype="CF_SQL_VARCHAR">
   for      update
  </cfquery>

<!---cfset systemlock(); removed --->
<!--- check for inside session --->
<cfif thisprimarypatronid gt 0 and IsInSession(thisprimarypatronid) is 1>
	<CFSET responsemessage="In session">
	<CFOUTPUT>#responsemessage#</CFOUTPUT>
	<cfabort>
</cfif>
<!--- defined WWW as module --->
<cfset module = "WWW">
<cfset localfac = "WWW">
<cfset localnode = "W1">
<!--- currently only 1 type is availavbe. each new type will increment in card number as the 2nd and 3rd digit. set from calling page --->
<!--- misc vars --->
<cfparam name="GLLineNo" default="0">
<cfparam name="ActivityLine" default="0">
<cfset huserid = 0>
<cfset NextInvoice = GetNextInvoice(module)>
<cfset InvoiceDT = now()>
<!--- begin final processing --->
<cfset totalfees = 0>
<cfset newmode = 0>
<cfset rechargemode = 0>
<cfset invoicetypestr = "">
<!--- load gl account id --->
<cfloop from="1" to="#arraylen(finalcart)#" index="i">
	
	<!--- get GL for card type --->
	<cfquery datasource="#application.dopsds#" name="GetGLCode">
		select acctid, othercreditdesc, othercredittype
		from othercredittypes
		where othercredittype = '#request.theCardType#'
	</cfquery>
	<cfif GetGLCode.recordcount is not 1>
		<CFSET responsemessage = "GL error">
		<CFOUTPUT>#responsemessage#</CFOUTPUT>
		<cfabort><!--- if not found, stop --->
	<cfelse>
		<cfset acctid = GetGLCode.acctid>
	</cfif>
	<cfif DoNotAllowNonPrimaryRecharge is 1 and finalcart[i].newpurchase is 0>
		<cfset x = replace(finalcart[i].reloadcardnumber," ","","all")>
		<cfset x = REREPLACE(x,"[^0-9]","","ALL")>
		<cfif x is not "">
			<cf_cryp type="en" string="#x#" key="#skey#">
			<cfset x = cryp.value>
		<cfelse>
			<cfset x = "">
		</cfif>
		<cfquery datasource="#application.dopsds#" name="GetCardDataForReload">
			select  primarypatronid
			from    othercreditdata
			where   othercreditdata = '#x#'
		</cfquery>
		<cfif GetCardDataForReload.recordcount gt 0 and GetCardDataForReload.primarypatronid is not thisprimarypatronid and trim(GetCardDataForReload.primarypatronid) NEQ ''>
			<CFSET errormessage = "Found one or more cards to be reloaded that are registered to another patron.">
			<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(errormessage)#">
			<cfabort>
		</cfif>
	</cfif>
	
	
	<CFIF structkeyexists(finalcart[i],"reloadamount") >
		<CFSET finalcart[i].amount = finalcart[i].reloadamount>
	</CFIF>
	<cfset totalfees = totalfees + finalcart[i].amount>
</cfloop>

<cfif totalfees is 0>
	<CFSET errormessage="No cards found to process.">
	<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(errormessage)#">
	<cfabort>
</cfif>
<cfset StartCredit = 0>
<cfif thisprimarypatronid gt 0>
	<cfset StartCredit = GetAccountBalance(thisprimarypatronid)>
</cfif>
<!--- look for changed starting balance --->
<cfif thisprimarypatronid gt 0 and StartCredit is not formstartbalance>
	<CFSET message="A change in starting balance was detected. Start purchase process again.">
	<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(message)#">
	<cfabort>
</cfif>
<!--- replace with method used to get address just like registration --->
<CFIF thisprimarypatronid NEQ 0>
	<cfquery datasource="#application.dopsds#" name="GetMailingAddress">
		select mailingaddressid
		from patronrelations
		where primarypatronid = #thisprimarypatronid#
		and secondarypatronid = #thisprimarypatronid#
	</cfquery>
	<cfset UseThisAddress = GetMailingAddress.mailingaddressid>
	<cfif UseThisAddress is "">
		<cfset UseThisAddress = 0>
	</cfif>
<CFELSE>
	<cfset UseThisAddress = 0>
</CFIF>
<!--- end replace --->
<cfset InDistrict = 0>
<cfif CreditUsed gt StartCredit>
	
	<CFSET errormessage="Credit used is greater than available credit">
	<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(errormessage)#">
	<cfabort>
</cfif>
<cfset availablecredit = StartCredit>
<!--- funds check --->
<cfif CreditUsed + tenderedcharge is not totalfees>
	
	<CFSET errormessage="Funds mismatch.">
	<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(errormessage)#">
	<cfabort>
</cfif>
<!--- processing --->
<cfif arraylen(finalcart) is not 0>
	<cfif thisprimarypatronid gt 0>
		<cfquery datasource="#nldopsds#" name="GetPrimaryDistrictStatus">
			SELECT   patrons.patronlookup, patronrelations.indistrict 
			FROM     patrons patrons
			         INNER JOIN patronrelations patronrelations ON patrons.patronid=patronrelations.primarypatronid 
			WHERE    patrons.patronid = #thisprimarypatronid#
			AND      patronrelations.relationtype = 1
		</cfquery>
	</cfif>
	<cfloop from="1" to="#arraylen(finalcart)#" index="a">
		
		<cfquery datasource="#application.dopsds#" name="GetTypeLimits">
			select minissueval, minreloadval, maxload, othercreditdesc
			from othercredittypes
			where othercredittype = '#request.theCardType#'
		</cfquery>
		<cfset NextEC = GetNextEC()>
		<cfif finalcart[a].newpurchase is 1>
			<!--- check limits --->
			<cfif finalcart[a].amount lt GetTypeLimits.minissueval>
				<CFSET message = "Insufficient amount to initially purchase card. Must be at least #dollarformat(GetTypeLimits.minissueval)#.">
				<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(message)#">
				<cfabort>
			<cfelseif finalcart[a].amount gt application.gcmax>
				<CFSET message = "Excessive amount to initially purchase card. Must be no more than #dollarformat(GetTypeLimits.maxload)#.">
				<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(message)#">
				<cfabort>
			</cfif>
			<cfquery name="GetNextCardID" datasource="#application.dopsds#">
				select cardid
				from   othercreditdata
				order  by cardid desc
				limit  1
			</cfquery>
			<cfif GetNextCardID.recordcount is 0>
				<cfset cardid = 1>
			<cfelse>
				<cfset cardid = GetNextCardID.cardid + 1>
			</cfif>

			<!--- use real data for shipping fields --->
			<cfquery datasource="#application.dopsds#" name="InsertNewCard1">
				insert into othercreditdata
					(cardid, othercredittype, shiplastname, shipfirstname, shipaddress, shipcity, shipstate, shipzip, welcome,styleid,letterheadid, message_to, message_from)
				values
					(#cardid#, '#request.theCardType#', '#finalcart[a].rlastname#', '#finalcart[a].rfirstname#', '#finalcart[a].raddress1#<CFIF trim(finalcart[a].raddress2) NEQ "">, #finalcart[a].raddress2#</CFIF>',
					 '#finalcart[a].rcity#', '#finalcart[a].rstate#', '#finalcart[a].rzip#', '#trim(finalcart[a].message)#',#finalcart[a].cardstyle#,#finalcart[a].letterhead#,'#finalcart[a].message_to#','#finalcart[a].message_from#')<!--- use REAL first, last, address, city, state, zip --->
			</cfquery>

			<cfquery datasource="#application.dopsds#" name="InsertNewCard2">
				insert into othercreditdatahistory
					(cardid, credit, invoicefacid, invoicenumber, action, userid, module, ec)
				values
					(#cardid#, #finalcart[a].amount#, '#LocalFac#', #NextInvoice#, 'P', 0, '#module#', #NextEC#)
			</cfquery>

			<cfset newmode = 1>
		<!--- recharge --->
		<cfelse>
			<cfset ocNum = replace(finalcart[a].reloadcardnumber," ","","all")>
			<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
		
			<cfif ocNum is not "">
				<cf_cryp type="en" string="#ocNum#" key="#skey#">
				<cfset enOtherCreditData = cryp.value>
			<cfelse>
				<cfset enOtherCreditData = "">
			</cfif>

			<!--- verify max of one occurance: index controlled --->
			<cfquery datasource="#application.dopsds#" name="CheckIfAvailable">
				SELECT   *
				FROM     othercreditdata
				WHERE    othercreditdata = '#enOtherCreditData#'
				limit    2
			</cfquery>

			<cfif CheckIfAvailable.recordcount is 0>
				<cfset othercrediterrormessagemsg = "Specified card #othercreditdata# was not found to be issued.">
				
			<cfelseif CheckIfAvailable.recordcount gt 1>
				<cfset othercrediterrormessagemsg = "Specified card #othercreditdata# was found more than once. Contact THPRD.">
				
				<!--- should never happen but... --->
			<cfelseif CheckIfAvailable.valid is 0>
				<cfset othercrediterrormessagemsg = "Specified card #othercreditdata# was found but is invalid.">
				
				
			</cfif>

			<!--- stop on first error and rollback --->
			<cfif IsDefined("othercrediterrormessagemsg")>
				<cftransaction action="ROLLBACK">
				<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(othercrediterrormessagemsg)#">
				<cfabort>
			</cfif>

			<cfquery datasource="#application.dopsds#" name="RechargeCard">
				insert into othercreditdatahistory
					(cardid, credit, invoicefacid, invoicenumber, action, userid, module, ec)
				values
					(#CheckIfAvailable.cardid#, #finalcart[a].reloadamount#, '#LocalFac#',#NextInvoice#, 'R', 0, '#module#', #NextEC#)
			</cfquery>

			<!--- check limits --->
			<cfquery datasource="#application.dopsds#" name="CheckMaxBalance">
				select sumnet
				from   othercredithistorysums
				where  cardid = #CheckIfAvailable.cardid#
			</cfquery>

			<cfif CheckMaxBalance.sumnet gt application.gcmax>
				<cfset othercrediterrormessagemsg = "Excessive amount to card. Balance after recharging can be more than #dollarformat(application.gcmax)#  (found tentative balance of #dollarformat(CheckMaxBalance.sumnet)#).">
				<CFLOCATION url="#attributes.redirecterrorpage#?error=#urlencodedformat(othercrediterrormessagemsg)#">
				<cfabort>
			</cfif>

			<cfset rechargemode = 1>
		</cfif>
		<cfset GLAmount = finalcart[a].amount>
		<cfif thisprimarypatronid gt 0>
			<cfset ActivityLine = ActivityLine + 1>
			<cfquery datasource="#application.dopsds#" name="AddToActivity">
				insert into Activity
					(Activity,ActivityCode,PatronID,InvoiceFacID,InvoiceNumber,Credit,line,EC,primarypatronid,action)
				values
					('#GetTypeLimits.othercreditdesc# <cfif finalcart[a].newpurchase is 1>Purchase<cfelse>Reload</cfif>',<cfif finalcart[a].newpurchase is 1>'OCP'<cfelse>'OCR'</cfif>,<cfif thisprimarypatronid gt 0>#thisprimarypatronid#<cfelse>null</cfif>,'#LocalFac#',#NextInvoice#,#glamount#,#ActivityLine#,#NextEC#,<cfif thisprimarypatronid gt 0>#thisprimarypatronid#<cfelse>null</cfif>,<cfif finalcart[a].newpurchase is 1>'OCP'<cfelse>'OCR'</cfif>)
			</cfquery>
		</cfif>
		<cfif GLAmount greater than 0>
			<cfset GLLineNo = GLLineNo + 1>
			<cfquery datasource="#application.dopsds#" name="InsertGL2">
				insert into GL
					(Credit,AcctID,InvoiceFacID,InvoiceNumber,EntryLine,ec,activitytype,activity)
				values
					(#GLAmount#,#AcctID#,'#LocalFac#',#NextInvoice#,#GLLineNo#,#NextEC#,<cfif #finalcart[a].newpurchase# is 1>'OCP'<cfelse>'OCR'</cfif>,'#GetTypeLimits.othercreditdesc# <cfif #finalcart[a].newpurchase# is 1>Purchase<cfelse>Reload</cfif>')
			</cfquery>
		</cfif>
	</cfloop>
	<cfif CreditUsed greater than 0 and thisPrimaryPatronID gt 0>
		<cfquery datasource="#application.dopsds#" name="GetGLDistCredit">
			select AcctID
			from GLMaster
			where InternalRef = 'DC'
		</cfquery>
		<cfset GLDistCreditAccount = GetGLDistCredit.acctID>
		<cfset NextEC = GetNextEC()>
		<cfif thisprimarypatronid gt 0>
			<cfset ActivityLine = ActivityLine + 1>
			<cfquery datasource="#application.dopsds#" name="AddToActivity">
				insert into Activity
					(ActivityCode,PrimaryPatronID,PatronID,InvoiceFacID,InvoiceNumber,Debit,Credit,line,EC)
				values
					('CU',#thisPrimaryPatronID#,#thisPrimaryPatronID#,'#LocalFac#',#NextInvoice#,#CreditUsed#,0,#ActivityLine#,#NextEC#)
			</cfquery>
		</cfif>
		<cfset GLLineNo = GLLineNo + 1>
		<cfquery datasource="#application.dopsds#" name="InsertGL1">
			insert into GL
				(Debit,AcctID,InvoiceFacID,InvoiceNumber,EntryLine,EC,activitytype,activity)
			values
				(#CreditUsed#,#GLDistCreditAccount#,'#LocalFac#',#NextInvoice#,#GLLineNo#,#NextEC#,'C','Credit')
		</cfquery>
	</cfif>
	<cfif TenderedCharge gt 0 and thisprimarypatronid gt 0>
		<cfset ActivityLine = ActivityLine + 1>
		<cfquery datasource="#application.dopsds#" name="AddToActivity">
			insert into Activity
				(ActivityCode,PatronID,InvoiceFacID,InvoiceNumber,Debit,Credit,line,EC,primarypatronid)
			values
				('PMT',<cfif thisprimarypatronid gt 0>#thisprimarypatronid#<cfelse>null</cfif>,'#LocalFac#',#NextInvoice#,0,#TenderedCharge#,#ActivityLine#,#GetNextEC()#,<cfif thisprimarypatronid gt 0>#thisprimarypatronid#<cfelse>null</cfif>)
		</cfquery>
	</cfif>
	<cfif newmode is 1>
		<cfset invoicetypestr = invoicetypestr & "-OCP-">
	</cfif>
	<cfif rechargemode is 1>
		<cfset invoicetypestr = invoicetypestr & "-OCR-">
	</cfif>
	<cfset invoicetypestr = replace(invoicetypestr,"--","-","all")>
	<!--- insert address into address table --->


	
	<cfquery datasource="#application.dopsds#" name="InsertInvoice">
		insert into invoice
			(InvoiceFacID,InvoiceNumber,PrimaryPatronID,primarypatronlookup,AddressID,
			mailingaddressid,
			InDistrict,TotalFees,UsedCredit,
			startingbalance,TenderedCash,TenderedCheck,TenderedCC,TenderedChange,
			CCA,CCED,CEW,ccType,CCV,
			Node,userid,
			invoicetype)
		values
			('#LocalFac#',#NextInvoice#,<cfif thisprimarypatronid gt 0>#thisprimarypatronid#,'#GetPrimaryDistrictStatus.patronlookup#'<cfelse>null,null</cfif>,#UseThisAddress#,
			<cfif GetMailingAddress.mailingaddressid is "">#UseThisAddress#<cfelse>#GetMailingAddress.mailingaddressid#</cfif>,
			<cfif IsDefined("GetPrimaryDistrictStatus.InDistrict") and GetPrimaryDistrictStatus.InDistrict is 1>true<cfelse>false</cfif>,#TotalFees#,#CreditUsed#,
			#AvailableCredit#,0,0,#TenderedCharge#,0,
			<cfif ccNum is not "">'#ccd#','#attributes.ccExp#','#right(ccNum,4)#','#left(ccNum,1)#',<cfif attributes.ccv is "">null<cfelse>'#ccven#'</cfif><cfelse>null,null,null,null,null</cfif>,
			'#LocalNode#',#hUserID#,
			'#invoicetypestr#')
	</cfquery>
</cfif>
<!--- for testing --->
<cfif testmode is 1>
	<cftransaction action="ROLLBACK">
     Rolled back for testing.
     <CFABORT>
</cfif>
</cftransaction>

</cfoutput>
