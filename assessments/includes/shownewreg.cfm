<cfset FACardLimit = 0>
<cfset bg = "E2E2E2">


<!--- 
Pre-check for new registrations to minimize query time
if regs are found, perform full query below
reg,patronid is required even if no row was found at a later time in code
--->
<cfset tc = gettickcount()>



<cfquery datasource="#application.dopsdsro#" name="GetNewRegistrations">
	select   reg.patronid,reg.sessionID
	from     reg
	where    reg.sessionid is not null 
	and      reg.primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
	limit    1
</cfquery>

<cfif GetNewRegistrations.recordcount gt 0>
	<CFSET cookie.sessionID = GetNewRegistrations.sessionID>
	<cfset CurrentSessionID = GetNewRegistrations.sessionID>

	<!--- do full query --->
	<cfquery datasource="#application.dopsdsro#" name="GetNewRegistrations">
		SELECT   reg.termid,
		         reg.facid,
		         reg.classid,
		         reg.patronid,
		         reg.regstatus,
		         patrons.firstname,
		         regstatuscodes.statusdescription,
					(
					select   termname
					from     terms
					where    terms.termid = reg.termid
					limit    1) as termname,

		         reg.regid,
		         classes.description,
		         reg.depositonly, (

		         select name from facilities where facilities.facid = reg.facid) as facname,

		         reg.costbasis,
		         reg.miscbasis,
		         reg.feebalance, (

		         select faeligible from patronrelations where patronrelations.primarypatronid = reg.primarypatronid and patronrelations.secondarypatronid = reg.patronid) as faeligible
		FROM     reg 
		         --INNER JOIN reghistory ON reg.primarypatronid=reghistory.primarypatronid AND reg.regid=reghistory.regid and reghistory.ismiscfee = false 
		         INNER JOIN patrons ON reg.patronid=patrons.patronid 
		         INNER JOIN regstatuscodes ON reg.regstatus=regstatuscodes.statuscode 
		         INNER JOIN classes ON reg.termid=classes.termid AND reg.facid=classes.facid AND reg.classid=classes.classid 
		WHERE    reg.sessionid is not null
		and      reg.primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
		         <!--- reg.SessionID = <cfqueryparam value="#cookie.sessionID#" cfsqltype="CF_SQL_VARCHAR"> --->
<!--- 		AND      reghistory.IsMiscFee = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
		AND      reghistory.voided = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
		and      reghistory.invoicefacid is null
		and      reghistory.invoicenumber is null
 --->		ORDER BY reg.dt
	</cfquery>

</cfif>

<!--- <cfif not IsDefined("getCards")>

	<cfquery datasource="#application.dopsdsro#" name="getCards">
		select   s.sumnet, s.isfa, s.othercreditdata 
		from     othercredithistorysums s
		where    s.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">
		and      s.activated is true
		and      s.valid is true
		order by s.cardid
	</cfquery>

</cfif> --->


<div ID="alertboxyellow">
<table cellpadding="2" cellspacing="0" border="0" width="730" >

	<cfif not isDefined("suppresstitle") or suppresstitle EQ 0>
		<TR>
			<TD colspan="9" style="border-bottom-color:#000000;border-bottom-style:solid;border-bottom-width:1px;"><span class="pghdr">Shopping Cart - New Registrations</span></TD>
		</TR>
	</cfif>

	<!--- you can use var 'errormsg' being defined (1 or 0) if an error occured to change display if desired --->
	<cfif IsDefined("msg")>
		<TR align="center">
			<TD align="center" colspan="9"><strong><cfoutput>#msg#</cfoutput></strong></TD>
		</TR>
	</cfif>

	<TR style="background-color:#000000;">
		<TD style="color:#FFFFFF;"><strong>Term</strong></TD>
		<TD style="color:#FFFFFF;"><strong>Facility</strong></TD>
		<TD style="color:#FFFFFF;"><strong>Class</strong></TD>
		<TD style="color:#FFFFFF;"><strong>Description</strong></TD>
		<TD style="color:#FFFFFF;"><strong>Patron</strong></TD>
		<TD style="color:#FFFFFF;"><strong>Status</strong></TD>
		<TD style="color:#FFFFFF;" align="right"><strong>Fee</strong></TD>
		<TD style="color:#FFFFFF;">&nbsp;</TD>
	</TR>

	<cfif GetNewRegistrations.recordcount is 0>
		<TR>
			<TD colspan="8" style="background-color:#FFFFFF;" align="center"><strong>Your shopping cart is empty</strong></TD>
		</TR>

		<!--- <cfif GetCards.recordcount gt 0>
			<TR>
				<TD colspan="8"><strong>Registered Gift Cards Found:</strong><BR>

					<CFLOOP query="getcards">
						<cf_cryp type="de" string="#getcards.othercreditdata#" key="#skey#">
						XXXX XXXX XXXX <!--- #left(cryp.value,4)# #insert(" ",mid(cryp.value,5,8),4)# ---><cfoutput>#right(cryp.value,4)# ($ #numberformat(sumnet, "99,999.99")#)<cfif currentrow is not recordcount><BR></cfif></cfoutput>
					</CFLOOP>

				</TD>
			</TR>
		</cfif> --->

	<cfelse>
		<cfset TotalMonies = 0>
		<cfoutput>
		<CFSET waitlistcount = 0>
		<cfloop query="GetNewRegistrations">
			<cfset fa = ListToArray(facname, " ")>
			<cfset TotalMonies = TotalMonies + val(costbasis) + val(miscbasis) - val(feebalance)>
			<cfset t = primarypatronid &  "_" & regid & "_" & primarypatronid + regid & "_" & replace(CurrentSessionID, "-", "", "all")>
			<cf_cryp type="en" string="#t#" key="#skey#">
			<cfset t = cryp.value>

			<cfif faeligible is 1>
				<cfset FACardLimit = FACardLimit + val(costbasis) + val(miscbasis) - val(feebalance)>
				<cfset ShowFA = 1>
			</cfif>
			<CFIF getnewregistrations.currentrow mod 2 EQ 1>
				<CFSET thebgcolor = "##ffffff;">
			<CFELSE>
				<CFSET thebgcolor = "##dddddd;">
			</CFIF>
			
			<TR valign="top" style="background-color:#thebgcolor#;">
				<TD valign="middle" class="blackborder">&nbsp;#termname#</TD>
				<TD valign="middle" class="blackborder">#fa[1]# #fa[2]#</TD>
				<TD valign="middle" class="blackborder">#classid#</TD>
				<TD valign="middle" class="blackborder">#description#</TD>
				<TD valign="middle" class="blackborder">#firstname#</TD>
				<TD nowrap valign="middle" class="blackborder"><strong>#statusdescription#</strong><cfif depositonly is 1> (dep)</cfif></TD>
				<TD valign="middle" align="right" nowrap class="blackborder">

					<cfif statusdescription is "Wait List">
						N/A
                              <CFSET waitlistcount = waitlistcount + 1>
					<cfelse>
						<cfif faeligible is 1>* </cfif>#Numberformat(val(costbasis) + val(miscbasis) - val(feebalance), "99,999.99")#
					</cfif>

				</TD>

				<cfif not IsDefined("suppressdropbutton")>
					<TD align="right" class="blackborder"><input name="dropclass" type="button" value="Drop" class="form_submit" onClick="if (confirm('Drop class #classid# for #replace(firstname, '"', "", "all")#?')) {document.f.dc.value='#t#';form.submit();}"></TD>
				<CFELSE>
					<TD align="right" class="blackborder">&nbsp;</td>
				</cfif>

			</TR>
		</cfloop>
		<!--- <A href="index.cfm?dc=#t#"><strong>Drop</strong></A> --->
		<input readonly name="dc" type="hidden">

		<TR valign="top" valign="baseline" >
			<TD colspan="2" valign="top" >

				<!--- <cfif GetCards.recordcount gt 0>
					<strong>Registered Gift Cards Found:</strong><BR>
	
					<CFLOOP query="getcards">
						<cf_cryp type="de" string="#getcards.othercreditdata#" key="#skey#">
						XXXX XXXX XXXX #right(cryp.value,4)# ($ #numberformat(sumnet, "99,999.99")#)<cfif currentrow is not recordcount><BR></cfif>
					</CFLOOP>

				</cfif> --->

			</TD>
			<TD align="center" colspan="3" valign="top">

				<cfif not IsDefined("suppresstitle") >
					<input onClick="window.location='class_summary.cfm?r=#datepart('s',now())#'" type="button" value="Checkout"  style="background-color:##0000cc;font-weight:bold;font-size:10px;color:##ffffff;width:150px;">
				<cfelseif IsDefined("suppressdropbutton") OR suppresstitle EQ 0>
					<input onClick="window.location='index.cfm?r=#datepart('s',now())#';" type="button" value="Continue Shopping" style="background-color:##0000cc;font-weight:bold;font-size:10px;color:##ffffff;width:170px;">
				</cfif>

			</TD>
			<TD align="right">
				<strong>Total $</strong>

				<!--- <cfif IsDefined("ShowFA")>
					<BR><BR><strong>Family Assistance Eligible Total $</strong>
				</cfif> --->

			</TD>
			<TD align="right" valign="top"><strong>#NumberFormat(TotalMonies, "999,999.99")#</strong>

				<!--- <cfif IsDefined("ShowFA")>
					<BR><BR><strong>#NumberFormat(FACardLimit, "999,999.99")#</strong>
				</cfif> --->

			</TD>
		</TR>
		</cfoutput>

	</cfif>

</table>

<cfif 1 is 2>
	tc: <cfoutput>#gettickcount() - tc#</cfoutput>
</cfif>
</div>
<hr color="#f58220" width=100% align="center" size="5px">
