<cfset FACardLimit = 0>
<cfset bg = "E2E2E2">


<!---
Pre-check for new registrations to minimize query time
if regs are found, perform full query below
reg,patronid is required even if no row was found at a later time in code
--->
<cfset tc = gettickcount()>
<cfset showExtraData = true>


<cfquery datasource="#application.dopsdsro#" name="GetNewRegistrations">
	select   reg.patronid,reg.sessionID
	from     reg
	where    reg.sessionid is not null
	and      reg.primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
	limit    1
</cfquery>

<cfif GetNewRegistrations.recordcount gt 0>

	<cfset CurrentSessionID = GetNewRegistrations.sessionID>

	<!--- do full query --->
	<cfquery datasource="#application.dopsdsro#" name="GetNewRegistrations">
		SELECT   reg.termid,
		         reg.facid,
		         reg.classid,
		         reg.patronid,
		         reg.regstatus,
		         reg.ratemethod,
		         reg.deferred,
		         reg.isstandby,
		         ratemethod.ratedesc,
		         classes.faeligible as classfaeligible,
		         patrons.firstname,
		         regstatuscodes.statusdescription,
		         reg.regid,
		         classes.description,
		         classes.defer,
		         reg.depositonly,
		         reg.feebalance,
		         terms.termname,
		         facilities.name as facname,

			(
				select   faeligible
				from     dops.patronrelations
				where    patronrelations.primarypatronid = reg.primarypatronid
				and      patronrelations.secondarypatronid = reg.patronid
				limit    1
			) as faeligible,

			(
				<!---extract amount sum--->
				SELECT   sum( rh.amount )
				FROM     dops.reghistory rh
				WHERE    rh.primarypatronid=reg.primarypatronid
				AND      rh.regid=reg.regid
				and      not rh.ismiscfee
				<!---end extract amount sum--->
			) as sumamount,

			(
				<!---extract amount mf sum--->
				SELECT   sum( rh.amount )
				FROM     dops.reghistory rh
				WHERE    rh.primarypatronid=reg.primarypatronid
				AND      rh.regid=reg.regid
				and      rh.ismiscfee
				<!---end extract amount mf sum--->
			) as summfamount,

			(
				<!---extract adjustments--->
				SELECT   coalesce( sum( adjustments.adjustment ), 0 )
				FROM     dops.reghistory
				         inner join dops.adjustments on adjustments.ec=reghistory.ec
				WHERE    reghistory.primarypatronid=reg.primarypatronid
				AND      reghistory.regid=reg.regid
				<!---end extract adjustments--->
			) as sumadjustment

		FROM     dops.reg
		         INNER JOIN dops.patrons ON reg.patronid=patrons.patronid
		         INNER JOIN dops.regstatuscodes ON reg.regstatus=regstatuscodes.statuscode
		         INNER JOIN dops.classes ON reg.termid=classes.termid AND reg.facid=classes.facid AND reg.classid=classes.classid
		         INNER JOIN dops.ratemethod ON reg.ratemethod=ratemethod.method
		         inner join dops.terms on reg.termid=terms.termid and reg.facid=terms.facid
		         inner join dops.facilities on facilities.facid = reg.facid
		WHERE    reg.sessionid is not null
		and      reg.primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
		ORDER BY reg.dt
	</cfquery>

	<cfif 0>
		<cfdump var="#GetNewRegistrations#">
		<cfabort>
	</cfif>

	<CFQUERY name="gettermcount" dbtype="query">
		select   count(termid), termid
		from     GetNewRegistrations
		group by termid
		order by termid
	</CFQUERY>

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

<cfsavecontent variable="shoppingcart">
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
		<TD style="color:#FFFFFF;"><strong>Patron</strong></TD>
		<TD style="color:#FFFFFF;"><strong>Status</strong></TD>
		<TD style="color:#FFFFFF;" align="left"><strong>Rate</strong></TD>
		<TD style="color:#FFFFFF;" align="center"><strong>Fee</strong></TD>
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
		<cfif listfind(valuelist(GetNewRegistrations.termid),'1503') GT 0>
			<cfset showolddisclaimer = true>
	</cfif>

		<cfset TotalMonies = 0>
		<cfoutput>
		<CFSET waitlistcount = 0>
		<CFSET showfakey = "false">

		<cfloop query="GetNewRegistrations">
			<cfset fa = ListToArray(facname, " ")>
			<cfset t = variables.primarypatronid &  "_" & GetNewRegistrations.regid & "_" & variables.primarypatronid + GetNewRegistrations.regid & "_" & replace(CurrentSessionID, "-", "", "all")>
			<cf_cryp type="en" string="#variables.t#" key="#skey#">
			<cfset t = cryp.value>

			<cfif faeligible is 1>
				<cfset FACardLimit = FACardLimit + val(GetNewRegistrations.sumamount) + val(GetNewRegistrations.summfamount) - val(GetNewRegistrations.feebalance)>
				<cfset ShowFA = 1>
			</cfif>
			<CFIF getnewregistrations.currentrow mod 2 EQ 1>
				<CFSET thebgcolor = "##ffffff;">
			<CFELSE>
				<CFSET thebgcolor = "##dddddd;">
			</CFIF>


			<TR valign="top" style="background-color:#variables.thebgcolor#;">
				<TD valign="middle" class="blackborder">&nbsp;#GetNewRegistrations.termname#</TD>
				<TD valign="middle" class="blackborder">#fa[1]# #fa[2]#</TD>
				<TD valign="middle" class="blackborder"><strong>#GetNewRegistrations.classid#</strong><cfif variables.showExtraData> (#GetNewRegistrations.regid#)</cfif> - #GetNewRegistrations.description#</TD>
				<TD valign="middle" class="blackborder">#GetNewRegistrations.firstname#</TD>
				<TD nowrap valign="middle" class="blackborder">
					<strong>#GetNewRegistrations.statusdescription#</strong>
					<cfif GetNewRegistrations.depositonly> (Deposit)</cfif>
					<cfif GetNewRegistrations.deferred> (Deferred)</cfif>
					<cfif GetNewRegistrations.isstandby> (EWP)</cfif>
				</TD>
				<TD valign="middle" class="blackborder">#GetNewRegistrations.ratedesc#</TD>
				<TD valign="middle" align="right" nowrap class="blackborder">

					<cfif GetNewRegistrations.statusdescription is "Wait List">
						N/A
						<CFSET waitlistcount = variables.waitlistcount + 1>

					<cfelse>

						<cfif GetNewRegistrations.classfaeligible and GetNewRegistrations.faeligible>
							*
							<CFSET showfakey = "true">
						</cfif>

						<cfif GetNewRegistrations.depositonly>
							#decimalformat(val(GetNewRegistrations.sumamount))#
							<cfset TotalMonies = variables.TotalMonies + val(GetNewRegistrations.sumamount)>

						<cfelseif  GetNewRegistrations.deferred>
							#decimalformat(0)#

						<cfelse>
							<cfset tfee = val(GetNewRegistrations.sumamount) + val(GetNewRegistrations.summfamount)>
							#decimalformat( variables.tfee )#
							<cfset TotalMonies = variables.TotalMonies + variables.tfee>

						</cfif>

					</cfif>

				</TD>

				<cfif not IsDefined("suppressdropbutton")>
					<TD align="right" class="blackborder"><input name="dropclass" type="button" value="Drop" class="form_submit" onClick="if (confirm('Drop class #GetNewRegistrations.classid# for #replace(GetNewRegistrations.firstname, '"', "", "all")#?')) {document.f.dc.value='#t#';form.submit();}"></TD>
				<CFELSE>
					<TD align="right" class="blackborder">&nbsp;</td>
				</cfif>

			</TR>

			<!--- display comments for above enrollment --->
			<cfif GetNewRegistrations.sumadjustment gt 0>

				<cfquery datasource="#application.dopsdsro#" name="GetAdjustData">
					SELECT   adjustmentdescriptions.adjustmentdescription
					FROM     dops.reghistory
					         inner join dops.adjustments on reghistory.ec=adjustments.ec
					         inner join dops.adjustmentdescriptions on adjustments.adjustmentcode=adjustmentdescriptions.adjustmentcode
					WHERE    reghistory.primarypatronid = <cfqueryparam value="#cookie.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
					AND      reghistory.regid = <cfqueryparam value="#GetNewRegistrations.regid#" cfsqltype="cf_sql_integer" list="no">
					ORDER BY reghistory.pk
				</cfquery>

				<tr>
					<td colspan="99" valign="top" style="background-color:#variables.thebgcolor#;">The above class reflects a cost adjustment of $#DecimalFormat( GetNewRegistrations.sumadjustment )#<cfif GetAdjustData.recordcount eq 1> for #GetAdjustData.adjustmentdescription#</cfif></td>
				</tr>
			</cfif>

			<cfif GetNewRegistrations.deferred>
				<tr>
					<td colspan="99" valign="top" style="background-color:#variables.thebgcolor#;">The above class is marked as payment being deferred. The balance of $#decimalformat( GetNewRegistrations.feebalance )# must be paid by #dateformat( GetNewRegistrations.defer, "mm/dd/yyyy" )#.</td>
				</tr>
			</cfif>

			<cfif GetNewRegistrations.depositonly>
				<tr>
					<td colspan="99" valign="top" style="background-color:#variables.thebgcolor#;">The above class is marked as deposit only which is to be paid at this time. The balance of $#decimalformat( GetNewRegistrations.feebalance )# must be paid before attending class.</td>
				</tr>
			</cfif>

			<cfif GetNewRegistrations.isstandby>
				<tr>
					<td colspan="99" valign="top" style="background-color:#variables.thebgcolor#;">The above class is marked as an Employee Wellness Plan (EWP) enrollment.</td>
				</tr>
			</cfif>

		</cfloop>




		<!--- <A href="index.cfm?dc=#t#"><strong>Drop</strong></A> --->
		<input readonly name="dc" type="hidden">

		<TR valign="top"  >
			<TD colspan="2" valign="top" >

                    <CFIF showfakey EQ "true">
                    <strong>* = Scholorship Eligible Class</strong>
                    </cfif>

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
					<input onClick="window.location='checkoutstepone.cfm';" type="button" value="Checkout"  style="background-color:##0000cc;font-weight:bold;font-size:10px;color:##ffffff;width:150px;">
				<cfelseif IsDefined("suppressdropbutton") OR suppresstitle EQ 0>
					<input onClick="window.location='index.cfm';" type="button" value="Add More Classes" style="background-color:##0000cc;font-weight:bold;font-size:10px;color:##ffffff;width:170px;">
				</cfif>

			</TD>
			<TD align="right">
				<strong>Total $</strong>

				<!--- <cfif IsDefined("ShowFA")>
					<BR><BR><strong>Family Assistance Eligible Total $</strong>
				</cfif> --->

			</TD>
			<TD align="right" valign="top"><strong>#decimalformat(variables.TotalMonies)#</strong>

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
<br>
<div style="color:white;background-color:#d53131;padding:3px;"><div style="float:left;margin-right:5px;"><img src="images/alert.png" width="25" height="25"></div><strong>NOTE:  Once your class is in your shopping cart, your spot is reserved!  Just complete your payment within <CFOUTPUT>#application.sessionInterval#</CFOUTPUT>.  Due to high volume, you may experience a delay in credit card processing during peak registration.</strong></div>

<hr color="#f58220" width=100% align="center" size="5px">

</cfsavecontent>

<CFPARAM name="showolddisclaimer" default="false">