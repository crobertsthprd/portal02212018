<cfcomponent>



<cffunction name="GetNextInvoice" returntype="numeric">
	<cfargument name="_UseThisFac" type="string" default="WWW" required="No">

	<cfquery datasource="#application.dopsds#" name="gn">
		SELECT dops.getnextinvoice(<cfqueryparam value="#_UseThisFac#" cfsqltype="cf_sql_varchar" list="no">)
	</cfquery>

	<cfreturn gn.getnextinvoice>
</cffunction>



<cffunction name="SetOCUsage" output="Yes" returntype="numeric">
<!--- 
Inserts OC usage into othercreditdist
returns number of records inserted

if you wish to run this on an invoice that was elready processed, delete records from dops.othercreditdist for said invoice first
this is highly NOT recommended as a valid FA application must be in place, if appropriate, to correctly process

call GetGLError() BEFORE calling this routine.

this routine MUST be called AFTER inserting ALL othercreditdatahistory records in calling application as some of those records' credit will be cleared if expired FA

--->

<cfargument name="_invoicefacid" type="string" required="Yes">
<cfargument name="_invoicenumber" type="numeric" required="Yes">
<!--- <cfset _sumdebit = 0>
<cfset _sumcredit = 0> --->


<!---  
Array Definition:
[1] = patronid
[2] = regid, if applicable
[3] = invoicefacid - not used
[4] = activity or class
[5] = action
[6] = GC card id
[7] = debit to activity
[8] = credit to activity basis
[9] = distributed credit to activity - no longer used
[10] = entry type

[9] calculated based on distributed funds between all credit amounts
--->

<cfset var _hadFA = 0 />
<cfset var _SetOCUsageGo = 1 />
<cfset var _faapptype = 0 />
<cfset var _del = '' />
<cfset var _GetInvoiceData = '' />
<cfset var _ClearFAUsedFA = '' />
<cfset var RunningOCBalance = 0.00 />
<cfset var _GetFAType = '' />
<cfset var RecArray = ArrayNew(2)>
<cfset var RecArrayCounter = 0>
<cfset var _activitydescription = "" />
<cfset var _ArrayDesc = "" />
<cfset var _GetMTDescription = "" />
<cfset var _GetInvoiceMembers = "" />
<cfset var tmp = 0 />
<cfset var done = 0 />
<cfset var thismtfee = 0 />
<cfset var propfee = 0 />
<cfset var startrec = 0 />
<cfset var endrec = 0 />
<cfset var thisfee = 0 />
<cfset var _GetDropInType = '' />
<cfset var _GetDropIn = '' />
<cfset var _thisdifee = '' />
<cfset var _GetPatrons = '' />
<cfset var _GetRes = '' />
<cfset var bal = 0 />
<cfset var _GetOCRegRecords = "" />
<cfset var _GetRegRecords = "" />
<cfset var _GetFA2PatronData = "" />
<cfset var _updateSessionFABalance = "" />
<cfset var _GetPasses = "" />
<cfset var _GetPassMembers = "" />
<cfset var thispassfee = 0 />
<cfset var fee = 0 />
<cfset var startarraycheck = 0 />
<cfset var endarraycheck = 0 />
<cfset var _tmppatronfees = "" />
<cfset var _LimitpassExpiration = "" />
<cfset var _GetAssessments = "" />
<cfset var thisassmtfee = 0 />
<cfset var _GetAssmtMembers = "" />
<cfset var _GetCards = "" />
<cfset var _FoundRec = "" />
<cfset var _InsertOCRecords = "" />
<cfset var _GetFA2SummaryData = "" />
<cfset var _ClearOCHistoryForNoValidApp = "" />
<cfset var _GetOCDistEntries = "" />
<cfset var _DisableOCSumCheck = 0>
<cfset var _ThisCredit = 0>
<cfset var _TmpLeagDropSum = 0>
<cfset var _thisRunningCreditBalanceLimit = 0.00>
<cfset var _TotalOCAllocation = 0.00>
<cfset var _RatioRound = 0.00>

<cfif _SetOCUsageGo is 1>

	<cfquery name="_GetInvoiceData" datasource="#dopsds#">
		select   othercreditusedcardid, primarypatronid, othercreditused, invoicetype, misctendtype
		from     invoice
		where    invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
		and      invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
		and      not isvoided
	</cfquery>

	<cfif 1 is 2>
		<cfdump var="#_GetInvoiceData#">
	</cfif>

	<cfif _GetInvoiceData.recordcount is 1 and _GetInvoiceData.primarypatronid is not "">
	
		<cfquery name="_ClearFAUsedFA" datasource="#dopsds#">
			update   patronrelations
			set
				sessionusedfa = <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
			where    primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		</cfquery>
	
	</cfif>
	
	<cfif _GetInvoiceData.recordcount is 1>
		<cfset RunningOCBalance = _GetInvoiceData.othercreditused>
		
		<cfif _GetInvoiceData.othercreditusedcardid gt 0 and _GetInvoiceData.primarypatronid is not "">
		
			<cfquery name="_GetFAType" datasource="#dopsds#">
				SELECT   apptype, expiredate 
				FROM     faapps 
				WHERE    current_date between eligibledate and expiredate
				AND      cardidtoload = <cfqueryparam value="#_GetInvoiceData.othercreditusedcardid#" cfsqltype="CF_SQL_INTEGER">
				and      primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
				and      status = <cfqueryparam value="G" cfsqltype="CF_SQL_CHAR" maxlength="1">
				order by pk
				limit    1
			</cfquery>
		
			<cfif _GetFAType.recordcount is 1>
				<cfset _faapptype = _GetFAType.apptype>
			</cfif>
		
		</cfif>
	
	<cfelse>
		<cfset _SetOCUsageGo = 0>
	</cfif>

</cfif>



<cfif _SetOCUsageGo is 1>

	<!--- league enrollment --->
	<cfif RunningOCBalance gt 0 and _GetInvoiceData.invoicetype is "-LEAG-">
		<!--- <cfinclude template="/Common/FunctionGetOCUsageMTLeag.cfm"> --->

		<!--- league code --->
		<cfif _GetInvoiceData.invoicetype is "-MT-">
		
			<cfquery datasource="#dopsds#" name="_GetMTDescription">
				SELECT   misctenddescription as activitydescription
				FROM     misctenderingtypes 
				WHERE    code = <cfqueryparam value="#_GetInvoiceData.misctendtype#" cfsqltype="CF_SQL_INTEGER">
			</cfquery>
		
			<cfset _activitydescription = _GetMTDescription.activitydescription>
			<cfset _ArrayDesc = "MT">
		
		<cfelseif _GetInvoiceData.invoicetype is "-LEAG-">
			<cfset _activitydescription = "League Registration">
			<cfset _ArrayDesc = "LEAG">
		
		<cfelse>
			<cfset request.errormsg = "<strong>Could not determine GC calculation method. Contact IS.</strong>">
			<CFRETURN -1>
		
		</cfif>
		
		
		
		
		
		<cfquery datasource="#dopsds#" name="_GetInvoiceMembers">
			SELECT   secondarypatronid, (
		
			         select   sessionavailablefa
			         from     patronrelations
			         where    patronrelations.secondarypatronid = invoicerelations.secondarypatronid
			         and      patronrelations.primarypatronid = invoicerelations.primarypatronid) as fa2limit,
		
			         (
			         select dops.getfapatronbalance(invoicerelations.primarypatronid, invoicerelations.secondarypatronid)) as fa2balance
		
			FROM     dops.invoicerelations
			WHERE    invoicerelations.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
			AND      invoicerelations.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
			and      invoicerelations.activethisinvoice
			order by (
		
			         select   sessionavailablefa
			         from     patronrelations
			         where    patronrelations.secondarypatronid = invoicerelations.secondarypatronid
			         and      patronrelations.primarypatronid = invoicerelations.primarypatronid), secondarypatronid
		</cfquery>
		
		<cfif _GetInvoiceMembers.recordcount gt 0>
			<!--- _faapptype = #_faapptype# --->
		
			<cfif _faapptype lt 2>
				<cfset thismtfee = RunningOCBalance>
				<cfset propfee = int((thismtfee * 100) / _GetInvoiceMembers.recordcount)>
				<cfset propfee = propfee / 100>
				<cfset startrec = 0>
				<cfset endrec = 0>
				<cfset tmp = 0>
		
				<cfloop query="_GetInvoiceMembers">
					<cfset RecArrayCounter = RecArrayCounter + 1>
					<cfset RecArray[RecArrayCounter][1]  = secondarypatronid>
					<cfset RecArray[RecArrayCounter][2]  = "">
					<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
					<cfset RecArray[RecArrayCounter][4]  = _activitydescription>
					<cfset RecArray[RecArrayCounter][5]  = "P">
					<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
					<cfset RecArray[RecArrayCounter][7]  = 0>
					<cfset RecArray[RecArrayCounter][8]  = propfee>
					<cfset RecArray[RecArrayCounter][9]  = 0>
					<cfset RecArray[RecArrayCounter][10] = _ArrayDesc>
					<cfset tmp = tmp + propfee>
					<cfset RunningOCBalance = RunningOCBalance - propfee>
				</cfloop>
		
				<!--- balance OC --->
				<cfif DollarRound(RunningOCBalance) is not 0>
					<cfset done = 0>
		
					<!--- nudge balances --->
					<cfloop from="1" to="100" step="1" index="x">
		
						<cfloop query="_GetInvoiceMembers">
							<cfset RecArray[currentrow][8] = RecArray[currentrow][8] + 0.01>
							<cfset RunningOCBalance = RunningOCBalance - 0.01>
		
							<!--- balance obtained --->
							<cfif DollarRound(RunningOCBalance) is 0>
								<cfset done = 1>
								<cfbreak>
							</cfif>
		
						</cfloop>
		
						<cfif done is 1>
							<cfbreak>
						</cfif>
		
					</cfloop>
		
				</cfif>
		
			<cfelseif _faapptype is 2>
				<!--- check for excessive patron use --->
				<cfset tmp = 0>
		
				<cfloop query="_GetInvoiceMembers">
					<cfset tmp = tmp + fa2balance>
				</cfloop>
		
				<cfif RunningOCBalance gt tmp>
					<cfset request.errormsg = "<strong>Error</strong>: Used Card funds exceeded specified amount on invoice. #numberformat(tmp, "99,999.99")# vs. #numberformat(RunningOCBalance, "99,999.99")#.">
					<!---
					<cfinclude template="/Common/BackButton.cfm">
					<cfabort> --->
					<CFRETURN -1>
				</cfif>
		
				<cfloop query="_GetInvoiceMembers">
					<cfset thisfee = min(fa2balance, RunningOCBalance)>
		
					<cfif thisfee gt 0>
						<cfset RecArrayCounter = RecArrayCounter + 1>
						<cfset RecArray[RecArrayCounter][1]  = secondarypatronid>
						<cfset RecArray[RecArrayCounter][2]  = "">
						<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
						<cfset RecArray[RecArrayCounter][4]  = _activitydescription>
						<cfset RecArray[RecArrayCounter][5]  = "P">
						<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
						<cfset RecArray[RecArrayCounter][7]  = 0>
						<cfset RecArray[RecArrayCounter][8]  = thisfee>
						<cfset RecArray[RecArrayCounter][9]  = 0>
						<cfset RecArray[RecArrayCounter][10] = _ArrayDesc>
						<cfset RunningOCBalance = RunningOCBalance - thisfee>
					</cfif>
		
					<cfif dollarRound(RunningOCBalance) is 0>
						<cfbreak>
					</cfif>
		
				</cfloop>
		
			<cfelse>
				<!---
				<strong>Error</strong>: Cannot determine proper Gift Card method. Contact IS.
				<BR><BR>
				<cfinclude template="/Common/BackButton.cfm">
				<cfabort>--->
				<cfset request.errormsg = "<strong>Error</strong>: Cannot determine proper Card method. Contact IS.">
				<CFRETURN -1>
			</cfif>
		
		<cfelse>
			<!--- not primary based --->
			<cfset RecArrayCounter = 1>
			<cfset RecArray[RecArrayCounter][1]  = "">
			<cfset RecArray[RecArrayCounter][2]  = "">
			<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
			<cfset RecArray[RecArrayCounter][4]  = _activitydescription>
			<cfset RecArray[RecArrayCounter][5]  = "P">
			<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
			<cfset RecArray[RecArrayCounter][7]  = 0>
			<cfset RecArray[RecArrayCounter][8]  = _GetInvoiceData.othercreditused>
			<cfset RecArray[RecArrayCounter][9]  = 0>
			<cfset RecArray[RecArrayCounter][10] = _ArrayDesc>
			<cfset RunningOCBalance = RunningOCBalance - _GetInvoiceData.othercreditused>
		</cfif>

		<!--- end league code --->








	<cfelse>
		<!--- daily ops --->
		<!--- <cfinclude template="/Common/FunctionGetOCUsageDOPS.cfm"> --->


		<!--- daily ops code --->

		<!--- registration --->
		<cfquery name="_GetOCRegRecords" datasource="#dopsds#">
			SELECT   othercreditdata.cardid,
			         othercreditdata.isfa,
			         invoice.invoicetype,
			         invoice.primarypatronid
			FROM     dops.othercreditdatahistory 
			         INNER JOIN dops.othercreditdata ON othercreditdatahistory.cardid=othercreditdata.cardid 
			         INNER JOIN dops.invoice ON othercreditdatahistory.invoicefacid=dops.invoice.invoicefacid AND othercreditdatahistory.invoicenumber=dops.invoice.invoicenumber
			WHERE    othercreditdatahistory.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
			AND      othercreditdatahistory.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
			and      dops.othercreditdatahistory.action in (<cfqueryparam value="U" cfsqltype="CF_SQL_VARCHAR">,<cfqueryparam value="B" cfsqltype="CF_SQL_VARCHAR">)
			and      not invoice.isvoided
			and      (position(<cfqueryparam value="-REG-" cfsqltype="CF_SQL_VARCHAR"> in invoicetype) > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
			or       position(<cfqueryparam value="-REGCONV-" cfsqltype="CF_SQL_VARCHAR"> in invoicetype) > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
			GROUP BY othercreditdata.cardid, othercreditdata.isfa, invoice.invoicetype, invoice.primarypatronid
		</cfquery>
		
		<cfloop query="_GetOCRegRecords">
		
			<cfif isfa is 1>
				<cfset _hadFA = 1>
			</cfif>
		
			<!--- get appropriate patrons --->
			<cfquery datasource="#dopsds#" name="_GetRegRecords">
				SELECT   reg.patronid,
				         reghistory.amount,
				         reghistory.action,
				         reg.termid,
				         reg.facid,
				         reg.classid,
				         reg.deferredpaid,
				         reg.wasconverted,
				         reg.regid,
				         0.00 as thisamount,
				         0.00000 as thisratio
				FROM     reghistory 
				         INNER JOIN reg ON reghistory.primarypatronid=reg.primarypatronid AND reghistory.regid=reg.regid 
				         INNER JOIN patrons ON reg.patronid=patrons.patronid 
				         INNER JOIN patronrelations on reg.primarypatronid=patronrelations.primarypatronid and reg.patronid=patronrelations.secondarypatronid
				where    reghistory.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
				and      reghistory.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
				and      not reghistory.deferred
				and      reghistory.amount > <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
				and      reg.primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
				and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">
				order by reghistory.amount desc, reg.dt
			</cfquery>
		
			<cfset _TotalOCAllocation = 0.00>
		
			<cfloop query="_GetRegRecords">
				<cfset _TotalOCAllocation = _TotalOCAllocation + amount>
			</cfloop>
		
			<!--- fill fee ratios --->
			<cfloop query="_GetRegRecords">
				<cfset QuerySetCell(_GetRegRecords, "thisratio",  _GetRegRecords.amount[_GetRegRecords.currentrow] / _TotalOCAllocation, _GetRegRecords.currentrow)>
			</cfloop>
		
			<cfset _TotalOCAllocation = min(_TotalOCAllocation, RunningOCBalance)>
		
			<cfloop query="_GetRegRecords">
		
				<cfif _GetRegRecords.recordcount gt 0>
					<cfset QuerySetCell(_GetRegRecords, "thisamount", dollarRound(_TotalOCAllocation * _GetRegRecords.thisratio[_GetRegRecords.currentrow]), _GetRegRecords.currentrow)>
				</cfif>
		
			</cfloop>
		
			<!--- penny rounding on first record --->
			<cfloop from="1" to="100" step="1" index="x">
				<cfset _RatioRound = 0.00>
			
				<cfloop query="_GetRegRecords">
					<cfset _RatioRound = _RatioRound + thisamount>
				</cfloop>
		
				<cfif dollarRound(_RatioRound) gt _TotalOCAllocation>
					<cfset QuerySetCell(_GetRegRecords, "thisamount", _GetRegRecords.thisamount[1] - 0.01, 1)>
		
				<cfelseif dollarRound(_RatioRound) lt _TotalOCAllocation>
					<cfset QuerySetCell(_GetRegRecords, "thisamount", _GetRegRecords.thisamount[1] + 0.01, 1)>
		
				<cfelse>
					<cfbreak>
		
				</cfif>
		
				<cfset QuerySetCell(_GetRegRecords, "thisamount", max(0, _GetRegRecords.thisamount[1]), 1)>
			</cfloop>
		
			<cfloop query="_GetRegRecords">
				<cfset RecArrayCounter = RecArrayCounter + 1>
				<cfset RecArray[RecArrayCounter][1] = patronid>
				<cfset RecArray[RecArrayCounter][2] = _GetRegRecords.regid[_GetRegRecords.currentrow]>
				<cfset RecArray[RecArrayCounter][3] = uCase(_invoicefacid)>
				<cfset RecArray[RecArrayCounter][4] = termid & "-" & facid & "-" & classid>
				<cfset RecArray[RecArrayCounter][5] = action>
				<cfset RecArray[RecArrayCounter][6] = _GetOCRegRecords.cardid[_GetOCRegRecords.currentrow]>
				<cfset RecArray[RecArrayCounter][7] = 0>
				<cfset RecArray[RecArrayCounter][8]  = _GetRegRecords.thisamount[_GetRegRecords.currentrow]>
				<cfset RecArray[RecArrayCounter][9] = 0>
		
				<!--- process debits --->
		
				<!--- get FA patron balance --->
				<cfif _faapptype is 1>
					<cfset RecArray[RecArrayCounter][8] = min(RunningOCBalance, RecArray[RecArrayCounter][8])>
		
				<cfelseif _faapptype is 2>
				
					<cfquery name="_GetFA2PatronData" datasource="#dopsds#">
						select   pk, sessionavailablefa - sessionusedfa as faavail
						from     patronrelations
						where    primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
						and      secondarypatronid = <cfqueryparam value="#_GetRegRecords.patronid#" cfsqltype="CF_SQL_INTEGER">
						and      patronrelations.faeligible
					</cfquery>
				
					<cfif _GetFA2PatronData.recordcount is 1>
						<cfset RecArray[RecArrayCounter][8] = min(_GetFA2PatronData.faavail, RecArray[RecArrayCounter][8])>
		
						<cfquery name="_updateSessionFABalance" datasource="#dopsds#">
							update  patronrelations
							set
								sessionusedfa = sessionusedfa + <cfqueryparam value="#RecArray[RecArrayCounter][8]#" cfsqltype="CF_SQL_MONEY">
							where   pk = <cfqueryparam value="#_GetFA2PatronData.pk#" cfsqltype="CF_SQL_INTEGER">
						</cfquery>
		
					</cfif>
		
				</cfif>
		
				<cfset RunningOCBalance = RunningOCBalance - RecArray[RecArrayCounter][8]>
				<cfset RecArray[RecArrayCounter][10] = "REG">
		
				<cfif wasconverted is 1 or deferredpaid is 1>
					<cfset RecArray[RecArrayCounter][10] = "REGCONV">
				</cfif>
		
			</cfloop>
		
		</cfloop>
		<!--- end registration --->
		
		
		
		
		<!--- passes --->
		<cfif Find("-PASS-", _GetInvoiceData.invoicetype) gt 0 or Find("-PASSUG-", _GetInvoiceData.invoicetype) gt 0>
		
			<cfquery datasource="#dopsds#" name="_GetPasses">
				SELECT   passes.ec, passes.passfee, passes.credit, passes.passtype
				FROM     dops.passes
				         INNER JOIN dops.invoice ON passes.invoicefacid=invoice.invoicefacid AND passes.invoicenumber=invoice.invoicenumber 
				         INNER JOIN passtype on passes.passtype=passtype.passtype
				where    passes.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
				and      passes.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
				and      passes.passfee > <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
				order by passtype.processorder
			</cfquery>
		
			<cfloop query="_GetPasses">
				<cfset thispassfee = min(RunningOCBalance, _GetPasses.passfee[_GetPasses.currentrow])>
		
				<cfquery datasource="#dopsds#" name="_GetPassMembers">
					SELECT   patronid, ec
					FROM     dops.passmembers 
					WHERE    ec = <cfqueryparam value="#ec#" cfsqltype="CF_SQL_INTEGER">
					and      primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
					order by patronid
				</cfquery>
		
				<cfset fee = DollarRound(Ceiling((thispassfee * 100) / _GetPassMembers.recordcount) / 100)>
				<cfset tmp = 0>
				<cfset startarraycheck = 0>
				<cfset endarraycheck = 0>
		
				<cfloop query="_GetPassMembers">
					<cfset RecArrayCounter = RecArrayCounter + 1>
					<cfset RecArray[RecArrayCounter][1]  = patronid>
					<cfset RecArray[RecArrayCounter][2]  = "">
					<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
					<cfset RecArray[RecArrayCounter][4]  = _GetPasses.passtype[_GetPasses.currentrow]>
					<cfset RecArray[RecArrayCounter][5]  = "P">
					<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
					<cfset RecArray[RecArrayCounter][7]  = 0>
					<cfset RecArray[RecArrayCounter][8]  = fee>
					<cfset RecArray[RecArrayCounter][9]  = 0>
					<cfset RecArray[RecArrayCounter][10] = "PASS">
					<cfset tmp = tmp + fee>
		
					<cfif startarraycheck is 0>
						<cfset startarraycheck = RecArrayCounter>
					</cfif>
		
					<cfset endarraycheck = RecArrayCounter>
					<cfset RunningOCBalance = RunningOCBalance - fee>
				</cfloop>
		
				<!--- add or subtract pennies from last patron until balanced --->
				<cfif DollarRound(tmp) is not DollarRound(thispassfee) and _GetPassMembers.recordcount gt 1>
		
					<cfloop from="1" to="#_GetPassMembers.recordcount#" step="1" index="x">
		
						<cfif tmp lt thispassfee>
							<cfset tmp = DollarRound(tmp + 0.01)>
							<cfset RecArray[RecArrayCounter][8] = DollarRound(RecArray[RecArrayCounter][8] + 0.01)>
							<cfset RunningOCBalance = RunningOCBalance - 0.01>
						<cfelseif tmp gt thispassfee>
							<cfset tmp = DollarRound(tmp - 0.01)>
							<cfset RecArray[RecArrayCounter][8] = DollarRound(RecArray[RecArrayCounter][8] - 0.01)>
							<cfset RunningOCBalance = RunningOCBalance + 0.01>
						<cfelse>
							<cfbreak>
						</cfif>
		
					</cfloop>
		
				</cfif>
		
				<!--- get FA patron balance and check to verify ALL can be fully covered by patrons share this pass --->
				<cfif _faapptype is 2 and startarraycheck is not 0>
					<cfset _tmppatronfees = 0>
		
					<cfloop from="#startarraycheck#" to="#endarraycheck#" step="1" index="x">
						<cfset _tmppatronfees = _tmppatronfees + DollarRound(RecArray[x][8])>
					</cfloop>
		
					<cfif DollarRound(_tmppatronfees) is not DollarRound(_GetPasses.passfee[_GetPasses.currentrow])>
						<cfset request.errormsg = "<strong>Insufficient funds available or unbalance calculation for specified pass #passtype# due to card restriction. Differance of #numberformat(_tmppatronfees - _GetPasses.passfee[_GetPasses.currentrow], "99,999.99")# Go back and try again.</strong>">
						<CFRETURN -1>
					</cfif>
		
					<!--- update patron fees --->
					<cfquery name="_updateSessionFABalance" datasource="#dopsds#">
		
						<cfloop from="#startarraycheck#" to="#endarraycheck#" step="1" index="x">
							update  patronrelations
							set
								sessionusedfa = sessionusedfa + <cfqueryparam value="#RecArray[x][8]#" cfsqltype="CF_SQL_MONEY">
							where   primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
							and     secondarypatronid = <cfqueryparam value="#RecArray[x][1]#" cfsqltype="CF_SQL_INTEGER">
							;
						</cfloop>
		
					</cfquery>
		
				</cfif>
		
				<cfif IsDefined("_GetFAType.expiredate") and _GetFAType.expiredate is not "" and _faapptype gt 0>
					<!--- limit pass expiration to fa app expiration --->
					<cfquery name="_LimitpassExpiration" datasource="#dopsds#">
						update  passes
						set
							passexpires = least(passexpires, <cfqueryparam value="#CreateODBCDate(_GetFAType.expiredate)#" cfsqltype="CF_SQL_DATE">)
						where   primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
						and     ec = <cfqueryparam value="#ec#" cfsqltype="CF_SQL_INTEGER">
					</cfquery>
		
				</cfif>
		
			</cfloop>
		
		</cfif>
		<!--- end passes --->
		
		
		
		
		<!--- assessments --->
		<cfif Find("-ASSMT-", _GetInvoiceData.invoicetype) gt 0>
		
			<!--- <cfif _GetPatrons.recordcount gt 0> --->
			
				<cfquery datasource="#dopsds#" name="_GetAssessments">
					SELECT   assessments.assmtfee, assessments.assmttype, assessments.EC
					FROM     dops.assessments 
					WHERE    assessments.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
					AND      assessments.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
				</cfquery>
			
			
			
				<cfloop query="_GetAssessments">
					<cfset thisassmtfee = min(RunningOCBalance, _GetAssessments.assmtfee[_GetAssessments.currentrow])>
			
					<cfquery datasource="#dopsds#" name="_GetAssmtMembers">
						SELECT   patronid, EC 
						FROM     dops.assessmentmembers 
						WHERE    ec = <cfqueryparam value="#ec#" cfsqltype="CF_SQL_INTEGER">
						order by patronid
					</cfquery>
			
					<cfset fee = DollarRound(Ceiling((thisassmtfee * 100) / _GetAssmtMembers.recordcount) / 100)>
					<!--- <cfset fee = DollarRound(thisassmtfee / _GetAssmtMembers.recordcount)> --->
					<cfset tmp = 0>
			
					<cfloop query="_GetAssmtMembers">
						<cfset RecArrayCounter = RecArrayCounter + 1>
						<cfset RecArray[RecArrayCounter][1]  = patronid>
						<cfset RecArray[RecArrayCounter][2]  = "">
						<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
						<cfset RecArray[RecArrayCounter][4]  = _GetAssessments.assmttype[_GetAssessments.currentrow]>
						<cfset RecArray[RecArrayCounter][5]  = "P">
						<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
						<cfset RecArray[RecArrayCounter][7]  = 0>
						<cfset RecArray[RecArrayCounter][8]  = fee>
			
						<!--- get FA patron balance --->
						<cfif _faapptype gt 0>
							<cfset RecArray[RecArrayCounter][8] = 0>
						<cfelse>
							<cfset RunningOCBalance = RunningOCBalance - fee>
						</cfif>
			
						<cfset RecArray[RecArrayCounter][9]  = 0>
						<cfset RecArray[RecArrayCounter][10] = "ASSMT">
						<cfset tmp = tmp + fee>
					</cfloop>
			
					<!--- add or subtract pennies until balanced --->
					<cfif tmp is not thisassmtfee and _GetAssmtMembers.recordcount gt 1>
			
						<cfloop from="1" to="100" step="1" index="x">
			
							<cfif tmp lt thisassmtfee>
								<cfset tmp = tmp + 0.01>
								<cfset RecArray[RecArrayCounter][8] = RecArray[RecArrayCounter][8] + 0.01>
								<cfset RunningOCBalance = RunningOCBalance - 0.01>
							<cfelseif tmp gt thisassmtfee>
								<cfset tmp = tmp - 0.01>
								<cfset RecArray[RecArrayCounter][8] = RecArray[RecArrayCounter][8] - 0.01>
								<cfset RunningOCBalance = RunningOCBalance + 0.01>
							<cfelse>
								<cfbreak>
							</cfif>
			
						</cfloop>
			
					</cfif>
			
				</cfloop>
			
			<!--- </cfif> --->
		
		</cfif>
		<!--- end assessments --->
		




		<!--- end daily ops code --->








	</cfif>


	<!--- final posting --->
	<cfset _FoundRec = 0>

	<cfif RecArrayCounter gt 0>
		<cfset tmp = 0>
	
		<!--- check for negatives due to adjusting --->
		<cfloop from="1" to="#RecArrayCounter#" step="1" index="x">
	
			<cfif DollarRound(RecArray[x][8]) lt 0.00>
				<cfset request.errormsg = "<strong>Negative patron balance of #Numberformat(RecArray[x][8], "99,999.99")# processing #RecArray[x][10]# entry was found. Go back and try again.</strong>">
				<CFRETURN -1>
			</cfif>
	
		</cfloop>

		<cfif 1 is 11>
			<cfdump var="#RecArray#">
		</cfif>

		<!--- check for postable data --->
		<cfloop from="1" to="#RecArrayCounter#" step="1" index="x">

			<cfif RecArray[x][8] gt 0 or RecArray[x][7] gt 0>
				<cfset _FoundRec = _FoundRec + 1>
			</cfif>

		</cfloop>

		<cfif _FoundRec gt 0>
			<!--- all OK, post data --->

			<cfif 1 is 12>
				<cfdump var="#RecArray#">
				<cfabort>
			</cfif>
	
			<cfloop from="1" to="#RecArrayCounter#" step="1" index="x">

				<cfif RecArray[x][8] gt 0 or RecArray[x][7] gt 0>
	
					<cfquery datasource="#dopsds#" name="_InsertOCRecords">
						insert into othercreditdist (
							invoicefacid,
							invoicenumber,
							patronid,
							regid,
							activity,
							action,
							cardid,
							debit,
							credit)
						values
							(<cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">, -- invoicefacid
							<cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">, -- invoicenumber
							<cfif RecArray[x][1] is "">null<cfelse><cfqueryparam value="#RecArray[x][1]#" cfsqltype="CF_SQL_INTEGER"></cfif>, -- patronid
							<cfif RecArray[x][2] is "">null<cfelse><cfqueryparam value="#RecArray[x][2]#" cfsqltype="CF_SQL_INTEGER"></cfif>, -- regid
							<cfqueryparam value="#RecArray[x][4]#" cfsqltype="CF_SQL_VARCHAR">, -- activity
							<cfqueryparam value="#RecArray[x][10]#" cfsqltype="CF_SQL_VARCHAR">, -- action
							<cfqueryparam value="#RecArray[x][6]#" cfsqltype="CF_SQL_INTEGER">, -- cardid
							<cfqueryparam value="#RecArray[x][7]#" cfsqltype="CF_SQL_MONEY">, -- debit
							<cfqueryparam value="#RecArray[x][8]#" cfsqltype="CF_SQL_MONEY">) -- credit
					</cfquery>
	
					<cfset tmp = tmp + RecArray[x][8]>
				</cfif>
	
			</cfloop>

		</cfif>
	
		<cfif _DisableOCSumCheck is 0 and (DollarRound(RunningOCBalance) is not 0 or DollarRound(tmp) is not DollarRound(_GetInvoiceData.othercreditused))>
			<cfset request.errormsg = "<strong>ERROR: Total OC Card amount specified was insufficient or the used amount did not match specified amount or running OC balance did not match starting value.<br>
			GC Usage $ #numberformat(tmp, "99,999.99")# vs. Invoice $ #numberformat(_GetInvoiceData.othercreditused, "99,999.99")#<br>
			Diff: #numberformat(tmp - _GetInvoiceData.othercreditused, "99,999.99")#<br>
			RunningGCBalance: #numberformat(RunningOCBalance, "99,999.99")#</strong><BR>
			Maximum OC amount to use: #numberformat(tmp, "99,999.99")#">
			<CFRETURN -1>

		<cfelseif _DisableOCSumCheck is 1 and (DollarRound(tmp) gt DollarRound(_GetInvoiceData.othercreditused))>
			<cfset request.errormsg = "<strong>ERROR: Total OC Card amount specified was insufficient or the used was greater than specified amount or running OC balance did not match starting value.<br>
			GC Usage $ #numberformat(tmp, "99,999.99")# vs. Invoice $ #numberformat(_GetInvoiceData.othercreditused, "99,999.99")#<br>
			Diff: #numberformat(tmp - _GetInvoiceData.othercreditused, "99,999.99")#<br>
			RunningGCBalance: #numberformat(RunningOCBalance, "99,999.99")#</strong><BR>
			Maximum OC amount to use: #numberformat(tmp, "99,999.99")#">
			<CFRETURN -1>

		</cfif>
	
	</cfif>
	
	<!--- final FA check --->
	<cfif _faapptype is 2 and (Find("-MT-", _GetInvoiceData.invoicetype) gt 0 or Find("-LEAG-", _GetInvoiceData.invoicetype) gt 0 or Find("REG", _GetInvoiceData.invoicetype) gt 0 or Find("PASS", _GetInvoiceData.invoicetype))>
	
		<cfquery name="_GetFA2SummaryData" datasource="#dopsds#">
			select   sum(sessionusedfa) as s
			from     patronrelations
			where    primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
			and      faeligible
			and      sessionusedfa > sessionavailablefa 
		</cfquery>
	
		<cfif _GetFA2SummaryData.recordcount is 1 and _GetFA2SummaryData.s is not "" and DollarRound(val(_GetFA2SummaryData.s)) lt 0>
			<cfset request.errormsg = "<strong>ERROR: Detected total of #numberformat(val(_GetFA2SummaryData.s), "99,999.99")# negative OC balance upon processing OC insertions. Go back and try again. If problem persists, leave session as is and contact IS.</strong>">
			<CFRETURN -1>
		</cfif>
	
	</cfif>
	<!--- end final FA check --->
	
	<!--- set credit to 0.00 on OC records where no current FA app exists --->
	<cfif _hadFA is 1>
	
		<cfquery name="_ClearOCHistoryForNoValidApp" datasource="#dopsds#">
			update  othercreditdatahistory
			set
				credit = <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">,
				comments = ltrim(comments || <cfqueryparam value=" - Expired FA App recovery" cfsqltype="CF_SQL_VARCHAR">)
			WHERE   othercreditdatahistory.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
			AND     othercreditdatahistory.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
			AND     othercreditdatahistory.credit > <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
	
			-- check for FA card
			and     (
					select   isfa
					from     othercreditdata
					where    cardid = othercreditdatahistory.cardid)
	
			-- check for current application
			and     othercreditdatahistory.cardid != (
					select   cardidtoload
					from     faapps
					WHERE    current_date between eligibledate and expiredate
					and      primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
					and      status = <cfqueryparam value="G" cfsqltype="CF_SQL_CHAR" maxlength="1">
					order by faappid
					limit    1)
		</cfquery>

	</cfif>




	<!--- check for used OC balance --->
	<cfif _GetInvoiceData.othercreditused gt 0>

		<cfquery name="_GetOCDistEntries" datasource="#dopsds#">
			select   sum(credit) as c
			from     othercreditdist
			where    invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
		</cfquery>

		<cfif _GetOCDistEntries.recordcount gt 0>

			<cfif _DisableOCSumCheck is 0 and _GetOCDistEntries.c is not _GetInvoiceData.othercreditused>
				<cfset request.errormsg = "<strong>OC Card distribution was not as expected. Go back and try again.</strong>">
				<CFRETURN -1>

			<cfelseif _DisableOCSumCheck is 1 and _GetOCDistEntries.c gt _GetInvoiceData.othercreditused>
				<cfset request.errormsg = "<strong>OC Card distribution was greater than expected. Go back and try again.</strong>">
				<CFRETURN -1>

			</cfif>

		</cfif>

	</cfif>
	
	<!--- return number of records inserted --->
	<cfreturn _FoundRec>
	<!--- end processing --->

<cfelse>
	<!--- process skipped so return 0 --->
	<cfreturn 0>

</cfif>

</cffunction>












	<cffunction name="SystemLock" output="yes" returntype="numeric">
		<cfargument name="_DSToLock" default="#application.dopsds#">
		
		<cfset var _SystemLock = '' />
		
		<cftry>
	
			<cfquery datasource="#_DSToLock#" name="_SystemLock">
				select   *
				from     systemlock
				for      update
			</cfquery>
	
			<cfreturn 1>
		<cfcatch>
			<!--- <BR><BR>
			<strong>Could not obtain database lock for required operation.<BR>
			<BR>If problem persists, contact IS.<BR>
			<input onClick="window.back()" type="button" value="Go Back And Try Again" class="GoButton">
			<cfabort> --->
			<cfreturn 0>
		</cfcatch>
		</cftry>
	
	</cffunction>


	
	<cffunction name="MonthsToYM">
		<cfargument required="Yes" name="MonthsToConvert" default="0" type="numeric">
		<cfargument required="No" name="Abbreviated" default="No" type="boolean">
		
		<cfset var _varYears = '' />
		<cfset var _varMonths = '' />
		<cfset var _varStr = '' />
		
		<cfset _VarYears = int(MonthsToConvert/12)>
		<cfset _VarMonths = MonthsToConvert - (_VarYears * 12)>
	
		<cfif Abbreviated is "Yes">
			<cfset _VarStr = ToString(_VarYears) & " yrs, " & ToString(_VarMonths) & " mths">
		<cfelse>
			<cfset _VarStr = ToString(_VarYears) & " years, " & ToString(_VarMonths) & " months">
		</cfif>
	
		<cfreturn _VarStr>
	</cffunction>
	


	<cffunction name="AssmtCredit" returntype="numeric">
	 <cfargument name="_type" required="Yes" type="string">
	 <cfargument name="_expires" required="Yes" type="date">
	
		<cfset var _assmtrefund = '' />
	
	 <cfset _assmtrefund = (ceiling(25/366*100)/100) * datediff("d",now(),_expires)>
	 
	 <cfif _type is "F">
	  <cfset _assmtrefund = _assmtrefund * 2>
	 </cfif>
	 
	 <cfreturn _assmtrefund>
	</cffunction>
	


	<cffunction name="GetRate" returntype="numeric">
	<!--- call by:
	GetRate(Mode,IDRegRate, IDSenRate, ODRegRate, ODSenRate, PrimaryPatronID, PatronDOB, BusinessCenterFac, BusinessCenterID, IsID, Start, End)
	Mode is either "R" or "P", denoting "registration or Passes
	For passes an additional column is selected instead of calculating value
	 --->
	<cfargument name="_Mode" required="Yes" type="string">
	<cfargument name="_IDRegRate" required="Yes" type="numeric">
	<cfargument name="_IDSenRate" required="Yes" type="numeric">
	<cfargument name="_ODRegRate" required="Yes" type="numeric">
	<cfargument name="_ODSenRate" required="Yes" type="numeric">
	<cfargument name="_PrimaryPatronID" required="Yes" type="numeric">
	<cfargument name="_PatronDOB" required="Yes" type="numeric">
	<cfargument name="_BusinessCenterFac" required="Yes" type="string">
	<cfargument name="_BusinessCenterID" required="Yes" type="string">
	<cfargument name="_IsID" required="Yes" type="numeric">
	<cfargument name="_Start" required="Yes" type="date">
	<cfargument name="_End" required="Yes" type="date">
	<cfargument name="_TermID" required="No" type="string">
	<cfargument name="_RegP1" required="No">
	<cfargument name="_SenP1" required="No">
	<cfargument name="_IsAssmtExempt" required="No" default="0" type="numeric">
	
	<cfset var _patronMonths = '' />
	<cfset var _IsSen = '' />
	<cfset var _getFacilitySCAge = '' />
	<cfset var _GetAssessmentPlan2Data = '' />
	<cfset var _GetSessionAssessmentData = '' />
	<cfset var _GetIDODScaler = '' />
	
	<cfquery datasource="#application.dopsds#" name="_GetFacilitySCAge">
	 select   scmonths
	 from     facilities
	 where    facid = '#_BusinessCenterFac#'
	</cfquery>
	
	<cfset _PatronMonths = datediff("M",_PatronDOB,_Start)>
	
	<cfif _PatronMonths gte _GetFacilitySCAge.scmonths>
	 <cfset _IsSen = 1>
	<cfelse>
	 <cfset _IsSen = 0>
	</cfif>
	
	<cfif _IsID is 1 and _IsSen is 0>
	 <cfreturn _IDRegRate>
	
	<cfelseif _IsID is 1 and _IsSen is 1>
	 <cfreturn _IDSenRate>
	
	<cfelseif _IsID is 0>
	
	 <cfquery datasource="#application.dopsds#" name="_GetAssessmentPlan2Data">
	  select distinct ASSMTPLAN
	  from allassessments
	  where primarypatronid = #_PrimaryPatronID#
	  and valid
	  and #CreateODBCDate(_Start)# >= ASSMTEFFECTIVEWG
	  and #CreateODBCDate(_Start)# <= ASSMTEXPIRESWG
	  <cfif IsDefined("_End") and _End is not "" and 1 is 2>
	   and #CreateODBCDate(_End)# >= ASSMTEFFECTIVEWG
	   and #CreateODBCDate(_End)# <= ASSMTEXPIRESWG
	  </cfif>
	 </cfquery>
	
	 <cfquery datasource="#application.dopsds#" name="_GetSessionAssessmentData">
	  select *
	  from sessionassessments
	  where primarypatronid = #_PrimaryPatronID#
	  and #CreateODBCDate(_Start)# >= ASSMTEFFECTIVE - grace::integer
	  and #CreateODBCDate(_Start)# <= ASSMTEXPIRES + grace::integer
	  <cfif IsDefined("_End") and _End is not "" and 1 is 2>
	   and #CreateODBCDate(_End)# >= ASSMTEFFECTIVE - grace::integer
	   and #CreateODBCDate(_End)# <= ASSMTEXPIRES + grace::integer
	  </cfif>
	 </cfquery>
	
	 <cfif ListFind(2,ValueList(_GetAssessmentPlan2Data.AssmtPlan)) is not 0 or _GetSessionAssessmentData.recordcount is not 0>
	  <!--- Plan 2 assessment --->
	  <cfif _IsSen is 1>
	   <cfreturn _ODSenRate>
	  <cfelse>
	   <cfreturn _ODRegRate>
	  </cfif>
	
	 <cfelseif _IsAssmtExempt is 1>
	  <!--- assessmemt exempt rate --->
	  <cfif _IsSen is 1>
	   <cfreturn _ODSenRate>
	  <cfelse>
	   <cfreturn _ODRegRate>
	  </cfif>
	
	 <cfelseif ListFind(1,ValueList(_GetAssessmentPlan2Data.AssmtPlan)) is not 0>
	  <!--- Plan 1 assessment --->
	  <cfif _Mode is "R">
	   <!--- Registration Mode --->
	   <cfquery name="_GetIDODScaler" datasource="#application.dopsds#">
	    SELECT   IDTOPLAN1 
	    FROM     BUSINESSCENTERS 
	    WHERE    FACID = '#_BusinessCenterFac#'
	    AND      BUSINESSCENTERID = '#_BusinessCenterID#'
	   </cfquery>
	
	   <cfif _GetIDODScaler.recordcount is not 1>
	    <strong>Error in determining rate from GetIDODScaler. Contact IS.</strong>
	    <cfabort>
	   </cfif>
	
	   <!--- calculate Plan 1 rate --->
	   <cfif IsDefined("_TermID") and _TermID is "0509">
	    <!--- adjust to match brochure this term only --->
	    <cfif _IsSen is 1>
	     <cfreturn _SenP1>
	    <cfelse>
	     <cfreturn _RegP1>
	    </cfif>
	
	   <cfelse>
	
	    <cfif _IsSen is 1>
	     <cfreturn _IDSenRate * _GetIDODScaler.IDTOPLAN1>
	    <cfelse>
	     <cfreturn _IDRegRate * _GetIDODScaler.IDTOPLAN1>
	    </cfif>
	
	   </cfif>
	
	  </cfif>
	
	 <cfelse>
	  <!--- no assessment --->
	  <!--- <cfreturn _IDRegRate> --->
	
	  <cfif _IsSen is 1>
	   <cfreturn _ODSenRate>
	  <cfelse>
	   <cfreturn _ODRegRate>
	  </cfif>
	
	 </cfif>
	
	</cfif>
	 
	</cffunction>
	
	
	
	
	<cffunction name="GetAccountBalance" output="Yes" returntype="numeric">
	<cfargument name="_primary" required="Yes">
	
	<cfset var _GetAccountBalance = '' />
	
	<cfquery name="_GetAccountBalance" datasource="#application.dopsds#">
		select dops.primaryaccountbalance(<cfqueryparam value="#_primary#" cfsqltype="CF_SQL_INTEGER">, current_date + 1) as NetBalance
	</cfquery>
	
	<cfreturn _GetAccountBalance.NetBalance>
	</cffunction>
	
	
	
	
	<cffunction name="DollarRound" output="Yes" returntype="numeric">
	<cfargument name="_value" required="No" type="numeric" default="0">
	<cfreturn round(_value * 100) / 100>
	</cffunction>
	
	
	
	
	<cffunction name="DurationWeeks">
	 <!--- 
	  process previously generated query
	  dt order must be in ascending order
	  _ColumnToUse is the column to evaluate
	  --->
	 <cfargument name="_QueryToUse" type="string" required="Yes">
	 <cfargument name="_ColumnToUse" type="string" required="Yes">
	 <cfargument name="_ReturnAsString" type="numeric" required="No" default="0">
	
		<cfset var _Duration = '' />
		<cfset var _LastWeek = '' />
		<cfset var _tmp = '' />
	
	
	 <cfset _Duration = 0>
	 <cfset _LastWeek = 0>
	
	 <cfloop query="#_QueryToUse#">
	  <cfset _tmp = week(evaluate(_ColumnToUse))>
	
	  <cfif _tmp is not _LastWeek>
	   <cfset _LastWeek = _tmp>
	   <cfset _Duration = _Duration + 1>
	  </cfif>
	
	 </cfloop>
	
	 <cfif _ReturnAsString is 1>
	  <cfset _Duration = _Duration & " Week(s)">
	 </cfif>
	
	 <cfreturn _Duration>
	</cffunction>
	
	
	
	
	<cffunction name="GetReturnQty" output="Yes" returntype="numeric">
		
		<cfset var _ReturnQty = '' />
	
	<cfquery datasource="#application.dopsdsro#" name="_ReturnQty" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
		select   varvalue
		from     dops.systemvars
		where    varname = 'WebClassSearchReturnQty'
	</cfquery>
	
	<cfif _ReturnQty.recordcount is 0>
		<cfreturn 5>
	<cfelse>
		<cfreturn _ReturnQty.varvalue>
	</cfif>
	
	</cffunction>
	
	
	
	
	<cffunction name="GetReturnQtyRegMode" output="Yes" returntype="numeric">
		
		<cfset var _ReturnQtyRegMode = '' />
	
	<cfquery datasource="#application.dopsdsro#" name="_ReturnQtyRegMode" cachedwithin="#CreateTimeSpan(0, 0, 10, 0)#">
		select   varvalue
		from     dops.systemvars
		where    varname = 'WebClassSearchReturnQtyRegMode'
	</cfquery>
	
	<cfif _ReturnQtyRegMode.recordcount is 0>
		<cfreturn 5>
	<cfelse>
		<cfreturn _ReturnQtyRegMode.varvalue>
	</cfif>
	
	</cffunction>
	
	
	
	
	<cffunction name="GetSessionid">
	<cfargument name="_PrimaryPatronID" required="Yes" type="numeric">
	
		<cfset var _CheckForCurrentSession = '' />
	
	<cfif not isDefined("CurrentSessionID")>
		<!--- check for already in session --->
		<cfquery datasource="#application.dopsds#" name="_CheckForCurrentSession">
			SELECT   sessionID, node, facid
			FROM     SessionPatrons
			where    PatronID = <cfqueryparam value="#_PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
			and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
			limit    1
		</cfquery>
		
		<!--- check for thprd control --->
		<cfif _CheckForCurrentSession.RecordCount gt 0>
		
			<cfif _CheckForCurrentSession.facid is not "WWW" or _CheckForCurrentSession.node is not "W1">
				<cfreturn "">
			</cfif>
		
			<cfreturn _CheckForCurrentSession.SessionID>
		<cfelse>
			<cfreturn "">
		</cfif>
	
	<cfelse>
		<cfreturn CurrentSessionID>
	</cfif>
	
	</cffunction>
	



<!--- 	<cffunction name="GetNextInvoice_notused" returntype="numeric">
		<cfargument name="_UseThisFac" type="string" default="" required="No">
		
		<cfset var _NextInvoice = '' />
		<cfset var e = '' />
		<cfset var f = '' />
		<cfset var h = '' />
		<cfset var n = '' />
		<cfset var GNI1 = '' />
		<cfset var _CheckForThisInvoice = '' />
		<cfset var GNI1A = '' />
		<cfset var GNI1B = '' />
		<cfset var GNI1C = '' />
		<cfset var GNI1D = '' />
		<cfset var GNI1E = '' />
		<cfset var GNI1F = '' />
		<cfset var GNI1G = '' />
		<cfset var GNI1H = '' />
		<cfset var GNI2 = '' />
	
		<cfquery datasource="#application.dopsds#" name="GNI1">
			SELECT   coalesce(InvoiceNumber) as NI
			FROM     invoice
			WHERE    InvoiceFacID = 

			<cfif _UseThisFac is not "">
				<cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR">
			<cfelse>
				<cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR">
			</cfif>

			ORDER BY InvoiceNumber desc
			limit    1
		</cfquery>
	
		<cfset _NextInvoice = val(GNI1.NI)>
	



		<cfif cgi.server_addr EQ application.devIP and 1 is 1>
	
			<cfquery datasource="#application.dopsds#" name="GN">
				select greatest( (
				
				select   coalesce(InvoiceNumber, 0)
				from     invoice
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
	
				select   coalesce(InvoiceNumber, 0)
				from     invoicerelations
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
				
				select   coalesce(InvoiceNumber, 0)
				from     dropinhistory
				where    facid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
				
				select   coalesce(InvoiceNumber, 0)
				from     othercreditdatahistory
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
				
				select   coalesce(InvoiceNumber, 0)
				from     passes
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
				
				select   coalesce(InvoiceNumber, 0)
				from     reservationpayments
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
				
				select   coalesce(InvoiceNumber, 0)
				from     gl
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
				
				select   coalesce(InvoiceNumber, 0)
				from     assessments
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1), (
				
				select   coalesce(InvoiceNumber, 0)
				from     activity
				where    invoicefacid = <cfif _UseThisFac is not ""><cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR"><cfelse><cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR"></cfif>
				order by invoicenumber desc
				limit    1) ) as nextinv
			</cfquery>
	
			<cfset _NextInvoice = gn.nextinv>
		</cfif>



		
	
		<cfset _NextInvoice = _NextInvoice + 1>
	
		<cfif _NextInvoice is 1>
	
			<cfquery datasource="#application.dopsds#" name="GNI2">
				SELECT   Facilities.StartingInvoice as NI
				FROM     Facilities
				WHERE    FacID = 

				<cfif _UseThisFac is not "">
					<cfqueryparam value="#_UseThisFac#" cfsqltype="CF_SQL_VARCHAR">
				<cfelse>
					<cfqueryparam value="#localfac#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>

			</cfquery>
	
			<cfif GNI2.recordcount is not 1>
				<BR><BR><BR><strong>Error in determining next invoice for this facility: <cfoutput>#_UseThisFac#</cfoutput>. Contact IS.</strong>
				<cfabort>
			</cfif>
	
			<cfset _NextInvoice = GNI2.NI>
		</cfif>
	
		<cfif _NextInvoice less than 2>
			<cftransaction action="ROLLBACK">
			<strong>Error in fetching next invoice. Contact IS.</strong>
			<cfabort>
		</cfif>
	
		<cfif 1 is 11>
	
			<cfquery datasource="#application.dopsds#" name="_CheckForThisInvoice">
				select   pk
				from     invoice
				where    invoicefacid = <cfif _UseThisFac is not "">'#_UseThisFac#'<cfelse>'#localfac#'</cfif>
				and      invoicenumber = <cfqueryparam value="#_NextInvoice#" cfsqltype="CF_SQL_INTEGER">
			</cfquery>
		
			<cfif _CheckForThisInvoice.recordcount gt 0>
				<cftransaction action="ROLLBACK">
				<strong>Error in fetching next invoice. Go back and try again. (<cfoutput>#_NextInvoice#</cfoutput>)</strong>
				<cfabort>
			</cfif>
	
		</cfif>
	
		<cfreturn _NextInvoice>
	</cffunction>
 --->	
	
	
	
	<!--- future version of GetNextEC() --->
	<cffunction name="GetNextEC" returntype="numeric">
		
		<cfset var _GetNextEC = '' />
	
		<cfquery datasource="#application.dopsds#" name="_GetNextEC">
			Select nextval('"dops"."sysec_pk_seq"') as tmp
		</cfquery>
	
		<cfreturn _GetNextEC.tmp>
	</cffunction>
	



	<cffunction name="Overlap" output="Yes" returntype="numeric" description="Checks for overlapping">
		<!--- returns 0 if no overlap, 1 if overlaps --->
		<!--- array format: --->
		<!--- v1, v2 --->
		<!--- v1, v2 --->
		<!--- v1, v2 --->
		<!--- ...... --->
		<cfargument name="_OArray" type="array" required="Yes">
		
		<cfset var _AssmtOverlap = '' />
		<cfset var _xa = '' />
		<cfset var _ya = '' />
		
		<cfset _AssmtOverlap = 0>
	
		<cfif ArrayLen(_OArray) gt 1>
			<!--- loop thru array to detect overlapping timeframes --->
			<cfloop from="1" to="#ArrayLen(_OArray)#" step="1" index="_xa">
	
				<cfloop from="1" to="#ArrayLen(_OArray)#" step="1" index="_ya">
	
					<cfif _xa is not _ya>
	
						<cfif isbetween(_OArray[_ya][1],_OArray[_xa][1],_OArray[_xa][2]) is 1>
							<cfset _AssmtOverlap = 1>
							<cfbreak>
						</cfif>
	
						<cfif isbetween(_OArray[_ya][2],_OArray[_xa][1],_OArray[_xa][2]) is 1>
							<cfset _AssmtOverlap = 1>
							<cfbreak>
						</cfif>
	
					</cfif>
	
				</cfloop>
	
				<cfif _AssmtOverlap is 1>
					<cfbreak>
				</cfif>
		
			</cfloop>
	
		</cfif>
	
		<cfreturn _AssmtOverlap>
	</cffunction>
	
	
	
	<cffunction name="isbetween">
		<cfargument name="_TestVal" required="Yes">
		<cfargument name="_BeginVal" required="Yes">
		<cfargument name="_EndVal" required="Yes">
		<cfargument name="_NotInclusive" required="No" type="numeric" default="0">
		
		<cfset var _tmp = '' />
		<cfset var _BeginBal = '' />
	
		<cfif _BeginVal gt _EndVal>
			<cfset _tmp = _EndVal>
			<cfset _EndVal = _BeginVal>
			<cfset _BeginVal = _tmp>
		</cfif>
	
		<cfif _NotInclusive is 1>
			<cfif _TestVal gt _BeginVal and _TestVal lt _EndVal>
				<cfreturn 1>
			<cfelse>
				<cfreturn 0>
			</cfif>
		<cfelse>
			<cfif _TestVal gte _BeginVal and _TestVal lte _EndVal>
				<cfreturn 1>
			<cfelse>
				<cfreturn 0>
			</cfif>
		</cfif>
	</cffunction>



	<cffunction name="tf" output="Yes" returntype="string">
		<cfargument name="_boolval" required="Yes" type="numeric">
		
		<cfif _boolval is 1>
			<cfreturn "true">
		<cfelse>
			<cfreturn "false">
		</cfif>
	
	</cffunction>
	
	
	
	
	<cffunction name="GetDistrictStatus" returntype="array">
		<!--- Usage: GetDistrictStatus(primarypatronid, householdmode, wrap, abbreviation, DistrictStat, InsufficientID, Verified) --->
		<!--- specifiy _primarypatronid as 0 if calling with other params: otherwise, primary will be seeked, DistrictStat, InsufficientID, Verified will be ignored--->
	
		<!--- returned array elements:
		_GetDistrictStatusArray[1] = ID/OD as 1 or 0
		_GetDistrictStatusArray[2] = Insufficient ID as 1 or 0>
		_GetDistrictStatusArray[3] = ID/OD Rate Determination as 1 or 0
		_GetDistrictStatusArray[4] = text as result
		_GetDistrictStatusArray[5] = color as [color]
		_GetDistrictStatusArray[6] = district status as weight 0=OD or unknown, 1=Ins, 2=Ver, 3=ID
		--->
	
		<cfargument name="_GetDistrictStatusPrimarypatronid" required="Yes" type="numeric">
	
		<!--- householdmode: 0=not in housegold mode, 1=in household mode --->
		<cfargument name="_GetDistrictHouseholdMode" required="No" type="numeric" default="0">
	
		<!--- wrap: 0=no wrap, 1 = wrat at --->
		<cfargument name="_GetDistrictStatusWrap" required="No" type="numeric" default="0">
	
		<!---  _abbreviation: 0=none, 1=short, 2=minimal--->
		<cfargument name="_GetDistrictStatusAbbreviation" required="No" type="numeric" default="0">
	
		<cfargument name="_GetDistrictStatusDistStatus" required="No" type="numeric" default="0">
		<cfargument name="_GetDistrictStatusInsufficientID" required="No" type="numeric" default="0">
		<cfargument name="_GetDistrictStatusVerified" required="No" type="numeric" default="0">
		
		<cfset var _GetDistrictStatusArray = '' />
		<cfset var _GetPrimaryDistrictStatus = '' />
		
		<cfset _GetDistrictStatusArray = ArrayNew(1)>
	
		<cfif _GetDistrictStatusPrimarypatronid gt 0>
	
			<cfquery datasource="#application.dopsds#" name="_GetPrimaryDistrictStatus">
		
				<cfif _GetDistrictHouseholdMode is 1>
					SELECT   indistrict, insufficientid, verified
					FROM     sessionpatrons
					WHERE    primarypatronid = #_GetDistrictStatusPrimarypatronid# 
					AND      relationtype = 1 
				<cfelse>
					SELECT   patronrelations.indistrict, patrons.insufficientid, patrons.verified
					FROM     patronrelations patronrelations
					         INNER JOIN patrons patrons ON patronrelations.primarypatronid=patrons.patronid 
					WHERE    patronrelations.primarypatronid = #_GetDistrictStatusPrimarypatronid# 
					AND      patronrelations.relationtype = 1 
				</cfif>
		
				limit 1
			</cfquery>
		
			<cfif _GetPrimaryDistrictStatus.recordcount is 1>
				<cfset _GetDistrictStatusDistStatus = _GetPrimaryDistrictStatus.indistrict>
				<cfset _GetDistrictStatusInsufficientID = _GetPrimaryDistrictStatus.insufficientid>
				<cfset _GetDistrictStatusVerified = _GetPrimaryDistrictStatus.verified>
			</cfif>
	
		</cfif>
	
		<!--- Ddetermine status --->
		<cfif _GetDistrictStatusDistStatus is 0>
			<cfset _GetDistrictStatusArray[1] = 0>
			<cfset _GetDistrictStatusArray[2] = 0>
	
			<cfif _GetDistrictStatusAbbreviation is 0>
				<cfset _GetDistrictStatusArray[4] = "Out of District">
			<cfelseif _GetDistrictStatusAbbreviation is 1>
				<cfset _GetDistrictStatusArray[4] = "Out of Dist">
			<cfelse>
				<cfset _GetDistrictStatusArray[4] = "OD">
			</cfif>
	
			<cfset _GetDistrictStatusArray[5] = "FF6666">
			<cfset _GetDistrictStatusArray[6] = 0>
	
		<cfelseif _GetDistrictStatusInsufficientID is 1>
			<cfset _GetDistrictStatusArray[1] = 0>
			<cfset _GetDistrictStatusArray[2] = 1>
	
			<cfif _GetDistrictStatusAbbreviation is 0>
				<cfset _GetDistrictStatusArray[4] = "In District (Insufficient Proof)">
			<cfelseif _GetDistrictStatusAbbreviation is 1>
				<cfset _GetDistrictStatusArray[4] = "In Dist (Ins Proof)">
			<cfelse>
				<cfset _GetDistrictStatusArray[4] = "Ins">
			</cfif>
	
			<cfset _GetDistrictStatusArray[5] = "FF9900">
			<cfset _GetDistrictStatusArray[6] = 1>
	
		<cfelseif _GetDistrictStatusVerified is 0>
			<cfset _GetDistrictStatusArray[1] = 1>
			<cfset _GetDistrictStatusArray[2] = 0>
	
			<cfif _GetDistrictStatusAbbreviation is 0>
				<cfset _GetDistrictStatusArray[4] = "In District (To Be Verified)">
			<cfelseif _GetDistrictStatusAbbreviation is 1>
				<cfset _GetDistrictStatusArray[4] = "In Dist (To Verify)">
			<cfelse>
				<cfset _GetDistrictStatusArray[4] = "Ver">
			</cfif>
	
			<cfset _GetDistrictStatusArray[5] = "00FFFF">
			<cfset _GetDistrictStatusArray[6] = 2>
		
		<cfelseif _GetDistrictStatusVerified is 1>
			<cfset _GetDistrictStatusArray[1] = 1>
			<cfset _GetDistrictStatusArray[2] = 0>
		
			<cfif _GetDistrictStatusAbbreviation is 0>
				<cfset _GetDistrictStatusArray[4] = "In District">
			<cfelseif _GetDistrictStatusAbbreviation is 1>
				<cfset _GetDistrictStatusArray[4] = "In Dist">
			<cfelse>
				<cfset _GetDistrictStatusArray[4] = "ID">
			</cfif>
	
			<cfset _GetDistrictStatusArray[5] = "Lime">
			<cfset _GetDistrictStatusArray[6] = 3>
	
		<cfelse>
			<cfset _GetDistrictStatusArray[1] = 0>
			<cfset _GetDistrictStatusArray[2] = 0>
	
			<cfif _GetDistrictStatusAbbreviation is 0>
				<cfset _GetDistrictStatusArray[4] = "Unknown">
			<cfelseif _GetDistrictStatusAbbreviation is 1>
				<cfset _GetDistrictStatusArray[4] = "Unk">
			<cfelse>
				<cfset _GetDistrictStatusArray[4] = "Unk">
			</cfif>
	
			<cfset _GetDistrictStatusArray[5] = "FF00FF">
			<cfset _GetDistrictStatusArray[6] = 0>
			
		</cfif>
	
		<!--- determine ID/OD Rate element value --->
		<cfif _GetDistrictStatusArray[1] is 1 and _GetDistrictStatusArray[2] is 0>
			<cfset _GetDistrictStatusArray[3] = 1>
		<cfelse>
			<cfset _GetDistrictStatusArray[3] = 0>
		</cfif>
	
		<cfif _GetDistrictStatusWrap is 1>
			<cfset _GetDistrictStatusArray[4] = replace(_GetDistrictStatusArray[4]," (","<BR>(")>
		</cfif>
	
		<!--- returned array elements:
		_GetDistrictStatusArray[1] = ID/OD as 1 or 0
		_GetDistrictStatusArray[2] = Insufficient ID as 1 or 0>
		_GetDistrictStatusArray[3] = ID/OD Rate Determination as 1 or 0
		_GetDistrictStatusArray[4] = text as result
		_GetDistrictStatusArray[5] = color as [color]
		_GetDistrictStatusArray[6] = district status as weight 0=OD or unknown, 1=Ins, 2=Ver, 3=ID
		--->
	
		<cfif IsDefined("debugvars")>
			<!--- display vars for debugging --->
			<cfoutput>
				GetDistrictStatus() vars:<BR>
				_GetDistrictStatusPrimarypatronid = #_GetDistrictStatusPrimarypatronid#<BR>
				_GetDistrictHouseholdMode = #_GetDistrictHouseholdMode#<BR>
				_GetDistrictStatusWrap = #_GetDistrictStatusWrap#<BR>
				_GetDistrictStatusAbbreviation = #_GetDistrictStatusAbbreviation#<BR>
				_GetDistrictStatusDistStatus = #_GetDistrictStatusDistStatus#<BR>
				_GetDistrictStatusInsufficientID = #_GetDistrictStatusInsufficientID#<BR>
				_GetDistrictStatusVerified = #_GetDistrictStatusVerified#<BR>
				<cfdump var="#_GetDistrictStatusArray#">
			</cfoutput>
	
		</cfif>
	
		<cfreturn _GetDistrictStatusArray>
	</cffunction>
	
	
	
	
	<cffunction name="IsInSession" output="Yes" returntype="numeric" access="public">
		<cfargument name="_patronid" required="Yes">
		<cfargument name="_SkipDropIn" required="No" default="0">
		
		<cfset var CheckForSession = '' />
		<cfset var CheckForDropinSession = '' />
	
		<cfquery datasource="#application.dopsds#" name="CheckForSession">
			select   exists(
			         select   pk
			         from     SESSIONPATRONS
			         where    patronid = #_patronid#
			         and      node != 'W1') as tmp
		</cfquery>	
	
		<cfif CheckForSession.tmp is 0 and _SkipDropIn is 0>
	
			<cfquery datasource="#application.dopsds#" name="CheckForDropinSession">
				select   exists(
				         select   pk
				         from     SESSIONDROPIN
				         where    patronid = #_patronid#) as tmp
			</cfquery>
	
		</cfif>
	
		<cfif _SkipDropIn is 1 and CheckForSession.tmp is 0>
			<cfreturn 0>
		<cfelseif CheckForSession.tmp is 0 and CheckForDropinSession.tmp is 0>
			<cfreturn 0>
		<cfelse>
			<cfreturn 1>
		</cfif>
	
	</cffunction>
	
	
	
	<!--- <cffunction name="FirstClassLevel" output="Yes" returntype="string">
	<cfargument name="_str">
	
	<cfif _str is "">
		<cfreturn "">
	</cfif>
	
	<cfreturn mid(_str,  2,  Find("-", _str, 3) - 2)>
	</cffunction>
	 --->
	

	
	<cffunction name="checksessioncount" returntype="boolean">
		
		<cfset var q = '' />
		<!---// Alagad TODO:  Is there any way to factor this away, or
				make it not run on every page request?  Not sure of the
				use case here, so unwilling to make changes //--->
		<CFQUERY name="q_checksessioncount" datasource="#application.dopsds#">
		SELECT   varvalue::numeric > (
	         select   count(*)
	         from     sessionpatrons
	         where    facid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
	         and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
	         ) AS theval
		FROM     dops.systemvars
		WHERE    varname = <cfqueryparam value="WebMaxSessions" cfsqltype="CF_SQL_VARCHAR">
		</CFQUERY>
		<CFRETURN q_checksessioncount.theval>
	</cffunction>
	
	

	<cffunction name="StringPad" output="Yes" returntype="string">
	<cfargument name="_var" required="Yes" type="string">
	<cfargument name="_count" required="Yes" type="numeric">
	<cfargument name="_chr" required="No" type="string" default="-">
	<cfreturn RepeatString(_chr,_count) & _var & RepeatString(_chr,_count)>
	</cffunction>


	
	<cffunction name="sqlquote" returntype="string" description="returns null or [str] as appropriate">
	 <cfargument name="_str" required="No" default="">
	 <!--- select mode of 1 returns SELECT syntax instead of INSERT / UPDATE syntax --->
	 <cfargument name="_selectmode" required="No" default="0">
	
	 <cfset _str = Replace(_str,"'","''","all")>
	 
	 <cfif _selectmode is 1>
	 
	  <cfif _str is "">
	   <cfreturn "is null"> 
	  <cfelse>
	   <cfreturn "= '" & _str & "'">
	  </cfif>
	 
	 <cfelse>
	 
	  <cfif ltrim(rtrim(_str)) is "">
	   <cfreturn "null"> 
	  <cfelse>
	   <cfreturn "'" & ltrim(rtrim(_str)) & "'">
	  </cfif>
	 
	 </cfif>
	 
	</cffunction>








	<cffunction name="WhoAmI" output="Yes" description="Returns DEV, MASTER or SLAVE of DB">
		<cfset var WhoAmI = '' />

		<!---// while a method talking to application scope is not the
				most 'correct' way to do this, as it breaks encapsulation,
				I think this will be the best way to accomplish the goal
				of this particular method - Alagad //--->	
		<cfif not structKeyExists(application, "whoami") OR not len(application.whoami)>

			<cfquery name="WhoAmI" datasource="#application.dopsds#">
				select whoami() as whoami
			</cfquery>
			
			<cfset application.whoami = WhoAmI.whoami />
		</cfif>	
	
		<cfreturn application.whoami>
	</cffunction>


	







<!--- <cffunction name="SetOCUsageOld" output="Yes" returntype="numeric">
	<!--- 
	Inserts OC usage into othercreditdist
	returns number of records inserted
	
	if you wish to run this on an invoice that was elready processed, delete records from dops.othercreditdist for said invoice first
	this is highly NOT recommended as a valid FA application must be in place, if appropriate, to correctly process
	
	call GetGLError() BEFORE calling this routine.
	
	this routine MUST be called AFTER inserting ALL othercreditdatahistory records in calling application as some of those records' credit will be cleared if expired FA
	--->
	
	<cfargument name="_invoicefacid" type="string" required="Yes">
	<cfargument name="_invoicenumber" type="numeric" required="Yes">
	<!--- <cfset _sumdebit = 0>
	<cfset _sumcredit = 0> --->
	
	<!---  
	Array Definition:
	[1] = patronid
	[2] = regid, if applicable
	[3] = invoicefacid - not used
	[4] = activity or class
	[5] = action
	[6] = GC card id
	[7] = debit to activity
	[8] = credit to activity basis
	[9] = distributed credit to activity - no longer used
	[10] = entry type
	
	[9] calculated based on distributed funds between all credit amounts
	--->
	<cfset var _hadFA = 0 />
	<cfset var _SetOCUsageGo = 1 />
	<cfset var _faapptype = 0 />
	<cfset var _del = '' />
	<cfset var _GetInvoiceData = '' />
	<cfset var _ClearFAUsedFA = '' />
	<cfset var RunningOCBalance = '' />
	<cfset var _GetFAType = '' />
	<cfset var RecArray = ArrayNew(2)>
	<cfset var RecArrayCounter = 0>
	<cfset var _activitydescription = "" />
	<cfset var _ArrayDesc = "" />
	<cfset var _GetMTDescription = "" />
	<cfset var _GetInvoiceMembers = "" />
	<cfset var tmp = 0 />
	<cfset var done = 0 />
	<cfset var adj = 0.01 />
	<cfset var thismtfee = 0 />
	<cfset var propfee = 0 />
	<cfset var startrec = 0 />
	<cfset var endrec = 0 />
	<cfset var thisfee = 0 />
	<cfset var _GetDropInType = '' />
	<cfset var _GetDropIn = '' />
	<cfset var _thisdifee = '' />
	<cfset var _GetPatrons = '' />
	<cfset var _GetRes = '' />
	<cfset var bal = 0 />
	<cfset var _GetOCRegRecords = "" />
	<cfset var _GetRegRecords = "" />
	<cfset var _GetFA2PatronData = "" />
	<cfset var _updateSessionFABalance = "" />
	<cfset var _GetPasses = "" />
	<cfset var _GetPassMembers = "" />
	<cfset var thispassfee = 0 />
	<cfset var fee = 0 />
	<cfset var startarraycheck = 0 />
	<cfset var endarraycheck = 0 />
	<cfset var _tmppatronfees = "" />
	<cfset var _LimitpassExpiration = "" />
	<cfset var _GetAssessments = "" />
	<cfset var thisassmtfee = 0 />
	<cfset var _GetAssmtMembers = "" />
	<cfset var _GetCards = "" />
	<cfset var _FoundRec = "" />
	<cfset var _InsertOCRecords = "" />
	<cfset var _GetFA2SummaryData = "" />
	<cfset var _ClearOCHistoryForNoValidApp = "" />
	<cfset var _GetOCDistEntries = "" />
	<cfset var _TotalOCAllocation = 0.00>
	<cfset var _RatioRound = 0.00>

	<!--- process only if OC records were found 
	<cfif _GetOCRecords.recordcount is 0>
		<cfset _SetOCUsageGo = 0>
	</cfif>--->
	
	<cfif _SetOCUsageGo is 1>
		<!--- skip if dist records exit, meaning already processed --->
		<cfquery name="_del" datasource="#application.dopsds#">
			select   pk
			from     othercreditdist
			where    invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
			limit    1
		</cfquery>
		
		<cfif _del.recordcount is 1>
			<cfset _SetOCUsageGo = 0>
			<!--- <strong>Gift Card distribution data was found which cannot be removed for this invoice.</strong> --->
		</cfif>

	</cfif>
	
	<cfif _SetOCUsageGo is 1>
	
		<cfquery name="_GetInvoiceData" datasource="#application.dopsds#">
			select   othercreditusedcardid, primarypatronid, othercreditused, invoicetype
			from     invoice
			where    invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
			and      invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
			and      isvoided = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
		</cfquery>
		
		<cfif _GetInvoiceData.recordcount is 1 and _GetInvoiceData.primarypatronid is not "">
		
			<cfquery name="_ClearFAUsedFA" datasource="#application.dopsds#">
				update   patronrelations
				set
					sessionusedfa = <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
				where    primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
			</cfquery>
		
		</cfif>
		
		<cfif _GetInvoiceData.recordcount is 1>
			<cfset RunningOCBalance = _GetInvoiceData.othercreditused>
			
			<cfif _GetInvoiceData.othercreditusedcardid gt 0 and _GetInvoiceData.primarypatronid is not "">
			
				<cfquery name="_GetFAType" datasource="#application.dopsds#">
					SELECT   apptype, expiredate 
					FROM     faapps 
					WHERE    current_date between eligibledate and expiredate
					AND      cardidtoload = <cfqueryparam value="#_GetInvoiceData.othercreditusedcardid#" cfsqltype="CF_SQL_INTEGER">
					and      primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
					and      status = <cfqueryparam value="G" cfsqltype="CF_SQL_CHAR" maxlength="1">
					order by pk
					limit    1
				</cfquery>
			
				<cfif _GetFAType.recordcount is 1>
					<cfset _faapptype = _GetFAType.apptype>
				</cfif>
			
			</cfif>
		
		<cfelse>
			<cfset _SetOCUsageGo = 0>
		</cfif>
	
	</cfif>
	
	<cfif _SetOCUsageGo is 1>
	
		<cfif _GetInvoiceData.invoicetype is "-LEAG-">
			<cfset _activitydescription = "League Registration">
			<cfset _ArrayDesc = "LEAG">
		
		<cfelse>
			<cfset request.errormsg = "<strong>Could not determine card calculation method. Contact THPRD.</strong>">
			<CFRETURN -1>
		
		</cfif>
		
		<cfquery datasource="#application.dopsds#" name="_GetInvoiceMembers">
			SELECT   secondarypatronid, (
		
			         select   sessionavailablefa
			         from     patronrelations
			         where    patronrelations.secondarypatronid = invoicerelations.secondarypatronid
			         and      patronrelations.primarypatronid = invoicerelations.primarypatronid) as fa2limit,
		
			         (
			         select dops.getfapatronbalance(invoicerelations.primarypatronid, invoicerelations.secondarypatronid)) as fa2balance
		
			FROM     dops.invoicerelations
			WHERE    invoicerelations.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
			AND      invoicerelations.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
			and      invoicerelations.activethisinvoice
			order by (
		
			         select   sessionavailablefa
			         from     patronrelations
			         where    patronrelations.secondarypatronid = invoicerelations.secondarypatronid
			         and      patronrelations.primarypatronid = invoicerelations.primarypatronid), secondarypatronid
		</cfquery>
		
		<cfif _GetInvoiceMembers.recordcount gt 0>
			<!--- _faapptype = #_faapptype# --->
		
			<cfif _faapptype lt 2>
				<cfset thismtfee = RunningOCBalance>
				<cfset propfee = int((thismtfee * 100) / _GetInvoiceMembers.recordcount)>
				<cfset propfee = propfee / 100>
				<cfset startrec = 0>
				<cfset endrec = 0>
				<cfset tmp = 0>
		
				<cfloop query="_GetInvoiceMembers">
					<cfset RecArrayCounter = RecArrayCounter + 1>
					<cfset RecArray[RecArrayCounter][1]  = secondarypatronid>
					<cfset RecArray[RecArrayCounter][2]  = "">
					<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
					<cfset RecArray[RecArrayCounter][4]  = _activitydescription>
					<cfset RecArray[RecArrayCounter][5]  = "P">
					<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
					<cfset RecArray[RecArrayCounter][7]  = 0>
					<cfset RecArray[RecArrayCounter][8]  = propfee>
					<cfset RecArray[RecArrayCounter][9]  = 0>
					<cfset RecArray[RecArrayCounter][10] = _ArrayDesc>
					<cfset tmp = tmp + propfee>
					<cfset RunningOCBalance = RunningOCBalance - propfee>
				</cfloop>
		
				<!--- balance OC --->
				<cfif DollarRound(RunningOCBalance) is not 0>
					<cfset done = 0>
		
					<!--- nudge balances --->
					<cfloop from="1" to="100" step="1" index="x">
		
						<cfloop query="_GetInvoiceMembers">
							<cfset RecArray[currentrow][8] = RecArray[currentrow][8] + 0.01>
							<cfset RunningOCBalance = RunningOCBalance - 0.01>
		
							<!--- balance obtained --->
							<cfif DollarRound(RunningOCBalance) is 0>
								<cfset done = 1>
								<cfbreak>
							</cfif>
		
						</cfloop>
		
						<cfif done is 1>
							<cfbreak>
						</cfif>
		
					</cfloop>
		
				</cfif>
		
			<cfelseif _faapptype is 2>
				<!--- check for excessive patron use --->
				<cfset tmp = 0>
		
				<cfloop query="_GetInvoiceMembers">
					<cfset tmp = tmp + fa2balance>
				</cfloop>
		
				<cfif RunningOCBalance gt tmp>
					<cfset request.errormsg = "<strong>Error</strong>: Used Card funds exceeded specified amount on invoice. #numberformat(tmp, "99,999.99")# vs. #numberformat(RunningOCBalance, "99,999.99")#.">
					<!---
					<cfinclude template="/Common/BackButton.cfm">
					<cfabort> --->
					<CFRETURN -1>
				</cfif>
		
				<cfloop query="_GetInvoiceMembers">
					<cfset thisfee = min(fa2balance, RunningOCBalance)>
		
					<cfif thisfee gt 0>
						<cfset RecArrayCounter = RecArrayCounter + 1>
						<cfset RecArray[RecArrayCounter][1]  = secondarypatronid>
						<cfset RecArray[RecArrayCounter][2]  = "">
						<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
						<cfset RecArray[RecArrayCounter][4]  = _activitydescription>
						<cfset RecArray[RecArrayCounter][5]  = "P">
						<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
						<cfset RecArray[RecArrayCounter][7]  = 0>
						<cfset RecArray[RecArrayCounter][8]  = thisfee>
						<cfset RecArray[RecArrayCounter][9]  = 0>
						<cfset RecArray[RecArrayCounter][10] = _ArrayDesc>
						<cfset RunningOCBalance = RunningOCBalance - thisfee>
					</cfif>
		
					<cfif dollarRound(RunningOCBalance) is 0>
						<cfbreak>
					</cfif>
		
				</cfloop>
		
			<cfelse>
				<!---
				<strong>Error</strong>: Cannot determine proper Gift Card method. Contact IS.
				<BR><BR>
				<cfinclude template="/Common/BackButton.cfm">
				<cfabort>--->
				<cfset request.errormsg = "<strong>Error</strong>: Cannot determine proper Card method. Contact IS.">
				<CFRETURN -1>
			</cfif>
		
		<cfelse>
			<!--- not primary based --->
			<cfset RecArrayCounter = 1>
			<cfset RecArray[RecArrayCounter][1]  = "">
			<cfset RecArray[RecArrayCounter][2]  = "">
			<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
			<cfset RecArray[RecArrayCounter][4]  = _activitydescription>
			<cfset RecArray[RecArrayCounter][5]  = "P">
			<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
			<cfset RecArray[RecArrayCounter][7]  = 0>
			<cfset RecArray[RecArrayCounter][8]  = _GetInvoiceData.othercreditused>
			<cfset RecArray[RecArrayCounter][9]  = 0>
			<cfset RecArray[RecArrayCounter][10] = _ArrayDesc>
			<cfset RunningOCBalance = RunningOCBalance - _GetInvoiceData.othercreditused>
		</cfif>

		
		
		
	
		<cfelse>
			
			<!--- registration --->
			<cfquery name="_GetOCRegRecords" datasource="#application.dopsds#">
				SELECT   othercreditdata.cardid,
				         othercreditdata.isfa,
				         invoice.invoicetype,
				         invoice.primarypatronid
				FROM     dops.othercreditdatahistory 
				         INNER JOIN dops.othercreditdata ON othercreditdatahistory.cardid=othercreditdata.cardid 
				         INNER JOIN dops.invoice ON othercreditdatahistory.invoicefacid=dops.invoice.invoicefacid AND othercreditdatahistory.invoicenumber=dops.invoice.invoicenumber
				WHERE    othercreditdatahistory.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
				AND      othercreditdatahistory.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
				and      dops.othercreditdatahistory.action in ('U','B')
				and      not invoice.isvoided
				and      (position(<cfqueryparam value="-REG-" cfsqltype="CF_SQL_VARCHAR"> in invoicetype) > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
				or       position(<cfqueryparam value="-REGCONV-" cfsqltype="CF_SQL_VARCHAR"> in invoicetype) > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
				GROUP BY othercreditdata.cardid, othercreditdata.isfa, invoice.invoicetype, invoice.primarypatronid
			</cfquery>
			
			<cfloop query="_GetOCRegRecords">
			
				<cfif isfa is 1>
					<cfset _hadFA = 1>
				</cfif>
			
				<!--- get appropriate patrons --->
				<cfquery datasource="#application.dopsds#" name="_GetRegRecords">
					SELECT   reg.patronid,
					         reghistory.amount,
					         reghistory.action,
					         reg.termid,
					         reg.facid,
					         reg.classid,
					         reg.deferredpaid,
					         reg.wasconverted,
					         reg.regid,
					         0.00 as thisamount,
					         0.00000 as thisratio
					FROM     reghistory 
					         INNER JOIN reg ON reghistory.primarypatronid=reg.primarypatronid AND reghistory.regid=reg.regid 
					         INNER JOIN patrons ON reg.patronid=patrons.patronid 
					         INNER JOIN patronrelations on reg.primarypatronid=patronrelations.primarypatronid and reg.patronid=patronrelations.secondarypatronid
					where    reghistory.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
					and      reghistory.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
					and      not reghistory.deferred
					and      reghistory.amount > <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
					and      reg.primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
					and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">
					order by reghistory.amount desc, reg.dt
				</cfquery>
			
				<cfset _TotalOCAllocation = 0.00>
			
				<cfloop query="_GetRegRecords">
					<cfset _TotalOCAllocation = _TotalOCAllocation + amount>
				</cfloop>
			
				<!--- fill fee ratios --->
				<cfloop query="_GetRegRecords">
					<cfset QuerySetCell(_GetRegRecords, "thisratio",  _GetRegRecords.amount[_GetRegRecords.currentrow] / _TotalOCAllocation, _GetRegRecords.currentrow)>
				</cfloop>
			
				<cfset _TotalOCAllocation = min(_TotalOCAllocation, RunningOCBalance)>
			
				<cfloop query="_GetRegRecords">
			
					<cfif _GetRegRecords.recordcount gt 0>
						<cfset QuerySetCell(_GetRegRecords, "thisamount", dollarRound(_TotalOCAllocation * _GetRegRecords.thisratio[_GetRegRecords.currentrow]), _GetRegRecords.currentrow)>
					</cfif>
			
				</cfloop>
			
				<!--- penny rounding on first record --->
				<cfloop from="1" to="100" step="1" index="x">
					<cfset _RatioRound = 0.00>
				
					<cfloop query="_GetRegRecords">
						<cfset _RatioRound = _RatioRound + thisamount>
					</cfloop>
			
					<cfif dollarRound(_RatioRound) gt _TotalOCAllocation>
						<cfset QuerySetCell(_GetRegRecords, "thisamount", _GetRegRecords.thisamount[1] - 0.01, 1)>
			
					<cfelseif dollarRound(_RatioRound) lt _TotalOCAllocation>
						<cfset QuerySetCell(_GetRegRecords, "thisamount", _GetRegRecords.thisamount[1] + 0.01, 1)>
			
					<cfelse>
						<cfbreak>
			
					</cfif>
			
					<cfset QuerySetCell(_GetRegRecords, "thisamount", max(0, _GetRegRecords.thisamount[1]), 1)>
				</cfloop>
			
				<cfloop query="_GetRegRecords">
					<cfset RecArrayCounter = RecArrayCounter + 1>
					<cfset RecArray[RecArrayCounter][1] = patronid>
					<cfset RecArray[RecArrayCounter][2] = _GetRegRecords.regid[_GetRegRecords.currentrow]>
					<cfset RecArray[RecArrayCounter][3] = uCase(_invoicefacid)>
					<cfset RecArray[RecArrayCounter][4] = termid & "-" & facid & "-" & classid>
					<cfset RecArray[RecArrayCounter][5] = action>
					<cfset RecArray[RecArrayCounter][6] = _GetOCRegRecords.cardid[_GetOCRegRecords.currentrow]>
					<cfset RecArray[RecArrayCounter][7] = 0>
					<cfset RecArray[RecArrayCounter][8]  = _GetRegRecords.thisamount[_GetRegRecords.currentrow]>
					<cfset RecArray[RecArrayCounter][9] = 0>
			
					<!--- process debits --->
			
					<!--- get FA patron balance --->
					<cfif _faapptype is 1>
						<cfset RecArray[RecArrayCounter][8] = min(RunningOCBalance, RecArray[RecArrayCounter][8])>
			
					<cfelseif _faapptype is 2>
					
						<cfquery name="_GetFA2PatronData" datasource="#application.dopsds#">
							select   pk, sessionavailablefa - sessionusedfa as faavail
							from     patronrelations
							where    primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
							and      secondarypatronid = <cfqueryparam value="#_GetRegRecords.patronid#" cfsqltype="CF_SQL_INTEGER">
							and      patronrelations.faeligible
						</cfquery>
					
						<cfif _GetFA2PatronData.recordcount is 1>
							<cfset RecArray[RecArrayCounter][8] = min(_GetFA2PatronData.faavail, RecArray[RecArrayCounter][8])>
			
							<cfquery name="_updateSessionFABalance" datasource="#application.dopsds#">
								update  patronrelations
								set
									sessionusedfa = sessionusedfa + <cfqueryparam value="#RecArray[RecArrayCounter][8]#" cfsqltype="CF_SQL_MONEY">
								where   pk = <cfqueryparam value="#_GetFA2PatronData.pk#" cfsqltype="CF_SQL_INTEGER">
							</cfquery>
			
						</cfif>
			
					</cfif>
			
					<cfset RunningOCBalance = RunningOCBalance - RecArray[RecArrayCounter][8]>
					<cfset RecArray[RecArrayCounter][10] = "REG">
			
					<cfif wasconverted is 1 or deferredpaid is 1>
						<cfset RecArray[RecArrayCounter][10] = "REGCONV">
					</cfif>
			
				</cfloop>
			
			
			</cfloop>
			<!--- end registration --->





			
			<!--- assessments --->
			<cfif Find("-ASSMT-", _GetInvoiceData.invoicetype) gt 0>
			
				<cfquery datasource="#application.dopsds#" name="_GetAssessments">
					SELECT   assessments.assmtfee, assessments.assmttype, assessments.EC
					FROM     dops.assessments 
					WHERE    assessments.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
					AND      assessments.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
				</cfquery>
			
				<cfloop query="_GetAssessments">
					<cfset thisassmtfee = min(RunningOCBalance, _GetAssessments.assmtfee[_GetAssessments.currentrow])>
			
					<cfquery datasource="#application.dopsds#" name="_GetAssmtMembers">
						SELECT   patronid, EC 
						FROM     dops.assessmentmembers 
						WHERE    ec = <cfqueryparam value="#ec#" cfsqltype="CF_SQL_INTEGER">
						order by patronid
					</cfquery>
			
					<cfset fee = DollarRound(Ceiling((thisassmtfee * 100) / _GetAssmtMembers.recordcount) / 100)>
					<!--- <cfset fee = DollarRound(thisassmtfee / _GetAssmtMembers.recordcount)> --->
					<cfset tmp = 0>
			
					<cfloop query="_GetAssmtMembers">
						<cfset RecArrayCounter = RecArrayCounter + 1>
						<cfset RecArray[RecArrayCounter][1]  = patronid>
						<cfset RecArray[RecArrayCounter][2]  = "">
						<cfset RecArray[RecArrayCounter][3]  = uCase(_invoicefacid)>
						<cfset RecArray[RecArrayCounter][4]  = _GetAssessments.assmttype[_GetAssessments.currentrow]>
						<cfset RecArray[RecArrayCounter][5]  = "P">
						<cfset RecArray[RecArrayCounter][6]  = _GetInvoiceData.othercreditusedcardid>
						<cfset RecArray[RecArrayCounter][7]  = 0>
						<cfset RecArray[RecArrayCounter][8]  = fee>
			
						<!--- get FA patron balance --->
						<cfif _faapptype gt 0>
							<cfset RecArray[RecArrayCounter][8] = 0>
						<cfelse>
							<cfset RunningOCBalance = RunningOCBalance - fee>
						</cfif>
			
						<cfset RecArray[RecArrayCounter][9]  = 0>
						<cfset RecArray[RecArrayCounter][10] = "ASSMT">
						<cfset tmp = tmp + fee>
					</cfloop>
			
					<!--- add or subtract pennies until balanced --->
					<cfif tmp is not thisassmtfee and _GetAssmtMembers.recordcount gt 1>
			
						<cfloop from="1" to="100" step="1" index="x">
			
							<cfif tmp lt thisassmtfee>
								<cfset tmp = tmp + 0.01>
								<cfset RecArray[RecArrayCounter][8] = RecArray[RecArrayCounter][8] + 0.01>
								<cfset RunningOCBalance = RunningOCBalance - 0.01>
							<cfelseif tmp gt thisassmtfee>
								<cfset tmp = tmp - 0.01>
								<cfset RecArray[RecArrayCounter][8] = RecArray[RecArrayCounter][8] - 0.01>
								<cfset RunningOCBalance = RunningOCBalance + 0.01>
							<cfelse>
								<cfbreak>
							</cfif>
			
						</cfloop>
			
					</cfif>
			
				</cfloop>
		
			</cfif>
			<!--- end assessments --->
			

		</cfif>
		<!--- End Daily Ops --->	




	
		<!--- final posting --->
		<cfset _FoundRec = 0>
	
		<cfif RecArrayCounter gt 0>
			<cfset tmp = 0>
		
			<!--- check for negatives due to adjusting --->
			<cfloop from="1" to="#RecArrayCounter#" step="1" index="x">
		
				<cfif DollarRound(RecArray[x][8]) lt 0.00>
					<cfset request.errormsg = "<strong>Negative patron balance of #Numberformat(RecArray[x][8], "99,999.99")# processing #RecArray[x][10]# entry was found. Go back and try again.</strong>
					<BR><BR>">
					<CFRETURN -1>
				<!---
					<strong>Negative patron balance of #Numberformat(RecArray[x][8], "99,999.99")# processing #RecArray[x][10]# entry was found. Go back and try again.</strong>
					<BR><BR>
					<cfinclude template="/Common/BackButton.cfm">
					<cfabort>--->
				</cfif>
		
			</cfloop>
	
			<cfif 1 is 12>
				<cfdump var="#RecArray#">
			</cfif>
	
			<!--- check for postable data --->
			<cfloop from="1" to="#RecArrayCounter#" step="1" index="x">
	
				<cfif RecArray[x][8] gt 0 or RecArray[x][7] gt 0>
					<cfset _FoundRec = _FoundRec + 1>
				</cfif>
	
			</cfloop>
	
			<cfif _FoundRec gt 0>
				<!--- all OK, post data --->
				
				<cfloop from="1" to="#RecArrayCounter#" step="1" index="x">
					<cfif RecArray[x][8] gt 0 or RecArray[x][7] gt 0>
						 <cfquery datasource="#application.dopsds#" name="_InsertOCRecords">
						  insert into dops.othercreditdist (
						   invoicefacid,
						   invoicenumber,
						   patronid,
						   regid,
						   activity,
						   action,
						   cardid,
						   debit,
						   credit)
						  values
						   (<cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">, -- invoicefacid
						   <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">, -- invoicenumber
						   <cfif RecArray[x][1] is "">null<cfelse><cfqueryparam value="#RecArray[x][1]#" cfsqltype="CF_SQL_INTEGER"></cfif>, -- patronid
						   <cfif RecArray[x][2] is "">null<cfelse><cfqueryparam value="#RecArray[x][2]#" cfsqltype="CF_SQL_INTEGER"></cfif>, -- regid
						   <cfqueryparam value="#RecArray[x][4]#" cfsqltype="CF_SQL_VARCHAR">, -- activity
						   <cfqueryparam value="#RecArray[x][10]#" cfsqltype="CF_SQL_VARCHAR">, -- action
						   <cfqueryparam value="#RecArray[x][6]#" cfsqltype="CF_SQL_INTEGER">, -- cardid
						   <cfqueryparam value="#RecArray[x][7]#" cfsqltype="CF_SQL_MONEY">, -- debit
						   <cfqueryparam value="#RecArray[x][8]#" cfsqltype="CF_SQL_MONEY">) -- credit
						 </cfquery>
					 	<cfset tmp = tmp + RecArray[x][8]>
					</cfif>
				</cfloop>
				
			</cfif>
		
			<cfif 1 is 11>
				<cfdump var="#RecArray#">
			</cfif>
		
			<cfif DollarRound(RunningOCBalance) is not 0 or DollarRound(tmp) is not DollarRound(_GetInvoiceData.othercreditused)>
				<cfset request.errormsg = "<strong>ERROR: Total Gift Card amount specified was insufficient or the used amount did not match specified amount or running OC balance did not match starting value.<br>
				OC Usage $ #numberformat(tmp, "99,999.99")# vs. Invoice $ #numberformat(_GetInvoiceData.othercreditused, "99,999.99")#<br>
				Diff: #numberformat(tmp - _GetInvoiceData.othercreditused, "99,999.99")#<br>
				RunningOCBalance: #numberformat(RunningOCBalance, "99,999.99")#</strong>
				<BR><BR>">
				<CFRETURN -1>
			</cfif>
		
		</cfif>
		
		<!--- final FA check --->
		<cfif _faapptype is 2 and (Find("-LEAG-", _GetInvoiceData.invoicetype) gt 0 or Find("REG", _GetInvoiceData.invoicetype) gt 0 or Find("PASS", _GetInvoiceData.invoicetype))>
		
			<cfquery name="_GetFA2SummaryData" datasource="#application.dopsds#">
				select   sum(sessionusedfa) as s
				from     patronrelations
				where    primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
				and      faeligible = <cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
				and      sessionusedfa > sessionavailablefa 
			</cfquery>
		
			<cfif _GetFA2SummaryData.recordcount is 1 and _GetFA2SummaryData.s is not "" and DollarRound(val(_GetFA2SummaryData.s)) lt 0>
				<cfset request.errormsg = "<strong>ERROR: Detected total of #numberformat(val(_GetFA2SummaryData.s), "99,999.99")# negative OC balance upon processing OC insertions. Go back and try again. If problem persists, leave session as is and contact IS.</strong>
				<BR><BR>">
				<CFRETURN -1>			
			</cfif>
		
		</cfif>
		<!--- end final FA check --->
		
		<!--- set credit to 0.00 on OC records where no current FA app exists --->
		<cfif _hadFA is 1>
		
			<cfquery name="_ClearOCHistoryForNoValidApp" datasource="#application.dopsds#">
				update  othercreditdatahistory
				set
					credit = <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">,
					comments = ltrim(comments || <cfqueryparam value=" - Expired FA App recovery" cfsqltype="CF_SQL_VARCHAR">)
				WHERE   othercreditdatahistory.invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
				AND     othercreditdatahistory.invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
				AND     othercreditdatahistory.credit > <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
		
				-- check for FA card
				and     (
						select   isfa
						from     othercreditdata
						where    cardid = othercreditdatahistory.cardid) = <cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
		
				-- check for current application
				and     othercreditdatahistory.cardid != (
						select   cardidtoload
						from     faapps
						WHERE    current_date between eligibledate and expiredate
						and      primarypatronid = <cfqueryparam value="#_GetInvoiceData.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
						and      status = <cfqueryparam value="G" cfsqltype="CF_SQL_CHAR" maxlength="1">
						order by faappid
						limit    1)
			</cfquery>
	
		</cfif>
	
	
	
	
		<!--- check for used OC balance --->
		<cfif _GetInvoiceData.othercreditused gt 0>
	
			<cfquery name="_GetOCDistEntries" datasource="#application.dopsds#">
				select   sum(credit) as c
				from     othercreditdist
				where    invoicefacid = <cfqueryparam value="#uCase(_invoicefacid)#" cfsqltype="CF_SQL_VARCHAR">
				and      invoicenumber = <cfqueryparam value="#_invoicenumber#" cfsqltype="CF_SQL_INTEGER">
			</cfquery>
	
			<cfif _GetOCDistEntries.recordcount gt 0>
	
				<cfif _GetOCDistEntries.c is not _GetInvoiceData.othercreditused>
					<cfset request.errormsg = "<strong>Gift Card distribution was not as expected. Go back and try again.</strong>
					<BR><BR>">
					<CFRETURN -1>	
				</cfif>
	
			</cfif>
	
		</cfif>
		
		<cfif 1 is 11 and REMOTE_HOST is "192.168.160.92">
			<cfset request.errormsg = "<strong>Stopped for testing</strong>">
			<CFRETURN -1>	
		</cfif>
		
		<!--- return number of records inserted --->
		<cfreturn _FoundRec>
		<!--- end processing --->
	<cfelse>
		<!--- process skipped so return 0 --->
		<cfreturn 0>
	</cfif>

</cffunction> --->





<CFFUNCTION name="sessioncheck" output="no" returntype="struct">
	<CFARGUMENT name="PrimaryPatronID" required="yes" type="numeric">
	<CFSET var getSessionID = "">
	<CFSET var response = structnew()>

	<CFQUERY name="getSessionID" datasource="#application.dopsds#">
		select * from dops.getsessionvars(<CFQUERYPARAM cfsqltype="cf_sql_integer" value="#arguments.PrimaryPatronID#">)
	</CFQUERY>
	
	<CFIF getSessionID.getsessionvars[3] NEQ "NONE" and getSessionID.getsessionvars[1] EQ 'WWW'>
		<CFSET response.sessionID = getSessionID.getsessionvars[3]>
	<CFELSE>
		<CFIF getSessionID.getsessionvars[3] NEQ "NONE" AND getSessionID.getsessionvars[1] NEQ 'NONE'>
			<CFSET response.sessionID = 0>
			<CFSET response.message = "This account is current in session with a phone operator at #getSessionID.getsessionvars[1]#">
			<CFSET response.apachelogline = "fac#getSessionID.getsessionvars[1]#">
		<CFELSE>
			<CFSET response.sessionID = 0>
			<CFSET response.message = "Error determining session.">
			<CFSET response.apachelogline = "nosession">
		</CFIF>
	
<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" subject="WWW Portal Session Catch" type="html">
#response.message#<br />
Server Address: #cgi.server_addr#<br />

The patronID passed in the query is: #arguments.PrimaryPatronID#.<br />
The patron IP address is: #cgi.remote_addr#.<br />

<CFDUMP var="#form#">

<CFDUMP var="#cookie#">

<CFDUMP var="#getSessionID#">

</CFMAIL>
		<CFHTTP url="https://www.thprd.org/portal/sessioncatch.cfm?ipaddress=#cgi.remote_addr#&log=#response.apachelogline#" ></CFHTTP>
	
		
</CFIF>
	<CFRETURN response>
</CFFUNCTION>



</cfcomponent>
