<!--- requires array monies to exist --->
<CFOUTPUT>
<cfparam name="displaymoniesleadingcol" default="0">
<TR align="right">
	<cfif variables.displaymoniesleadingcol gt 0><TD colspan="#variables.displaymoniesleadingcol#"></TD></cfif>
	<TD style="padding: 0px;">&nbsp;</TD>
	<TD>&nbsp;</TD>
</TR>
<TR align="right" class="bodytext">
	<cfif variables.displaymoniesleadingcol gt 0><TD colspan="#variables.displaymoniesleadingcol#"></TD></cfif>
	<TD valign="top" class="bodytext" style="padding: 0px;" nowrap>
		Account Balance<BR>
		Total Fees<BR>
		Less District Credit<BR>
		Adjusted Due<BR>
		Less THPRD Card<BR>
		Net Due
	</TD>
	<TD valign="top" class="bodytext" style="padding: 0px;" nowrap>
		<cfif monies[1] neq ""><strong>#decimalformat( monies[1] )#</strong></cfif><BR>
		<cfif monies[2] neq "">#decimalformat( monies[2] )#</cfif><BR>
		<cfif monies[3] neq "">- #decimalformat( monies[3] )#</cfif><BR>
		<cfif monies[4] neq ""><strong>#decimalformat( monies[4] )#</strong></cfif><BR>
		<cfif monies[5] neq "">- #decimalformat( monies[5] )#</cfif><BR>
		<cfif monies[6] neq ""><strong>#decimalformat( monies[6] )#</strong></cfif>
	</TD>
</TR>
</CFOUTPUT>