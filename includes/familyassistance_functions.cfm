<!--- added march 12, 2008 --->
<cffunction name="GetOtherCreditGLAcctID" output="Yes" returntype="numeric">
	<!--- gets usage gl acctid for card, returning family assist if appropriate; use '1' for second parameter if you want to determine whether a card is family assistance --->
	<cfargument name="_cardid" required="Yes" type="numeric">
	<cfargument name="_isfa" required="No" default="0" type="numeric">
	<cfquery datasource="#application.dopsds#" name="_GetCardDataForAcctID">
	SELECT   othercredittypes.acctid, othercredittypes.faacctid, othercreditdata.isfa
	FROM     othercreditdata othercreditdata
		   INNER JOIN othercredittypes othercredittypes ON othercreditdata.othercredittype=othercredittypes.othercredittype 
	WHERE    othercreditdata.cardid = #_cardid#
	</cfquery>
	<cfif _isfa is 0>
		<!--- return acct id --->
		<cfif _GetCardDataForAcctID.recordcount is 0>
			<cfreturn 0>
		<cfelseif _GetCardDataForAcctID.isfa is 1>
			<cfreturn _GetCardDataForAcctID.faacctid>
		<cfelse>
			<cfreturn _GetCardDataForAcctID.acctid>
		</cfif>
	<cfelse>
	<!--- return type --->
		<cfif _GetCardDataForAcctID.recordcount is 0>
			<cfreturn 0>
		<cfelse>
			<cfreturn _GetCardDataForAcctID.isfa>
		</cfif>
	</cfif>
</cffunction>

<cffunction name="GetCurrentOtherCreditFAAppID">
	 <cfargument name="_cardid" type="numeric" required="yes"> 
	 <cfquery name="_GetAppData" datasource="#application.dopsds#">
	  SELECT   faappid
	  from     faapps
	  where    cardidtoload = #_cardid#
	  and      status = 'G'
	  order by faappid desc
	  limit    1
	 </cfquery>
	 <cfif _GetAppData.recordcount is 1>
	 	<cfreturn _GetAppData.faappid>
	 <cfelse>
	 	<cfreturn "">
	 </cfif>
 </cffunction>

