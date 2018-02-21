<cfif not isdefined('aID')>
	<cflocation url="categories.cfm">
	<cfabort>
</cfif>
<cfquery name="qGetCats" datasource="#application.reg_dsn#">
	select distinct coalesce(c.categoryb,'00') as categoryb, cat.description as category, subcat.description, subcat.code
	from classes c, categorya cat, categoryb subcat
	where c.agecategory like '%#aID#%'
	and c.categorya = '#form.cat#'
	and c.categorya = cat.code
	and coalesce(c.categoryb,'00') = subcat.code
	and c.endDT >= now()
	order by subcat.description desc
</cfquery>
<cfoutput>
<html>
<head>
<title>Tualatin Hills Park and Recreation District</title>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
<meta http-equiv="Content-Type" content="text/html;">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
<table border="0" cellpadding="0" cellspacing="0" width="750">
  
  <!--- <cfinclude template="#request.includes#/top_nav.cfm"> --->
  <tr>
   <td colspan="36" valign=top>
      	<table border=0 cellpadding=2 cellspacing=0 width=749>	
		<tr>
		<td colspan=5><img src="#request.imagedir#/spacer.gif" width="1" height="35" border="0" alt=""></td>
		</tr>
		<tr>
		<td>&nbsp;</td>
		<td colspan=4>
			<table width="100%">
				<tr>
					<td><span class="pghdr" >Activities/Class Search by Category</span></td>
					<td align="right"><span class="lgnusr" >#cookie.firstname# #cookie.lastname# (#cookie.login#) - <strong>#cookie.districtstatus#</strong></span></td>
				</tr>
			</table>
		</td>
		</tr>		
		<tr>
		<td><img src="../images/spacer.gif" width="20" height="300" border="0" alt=""></td>
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="#request.imagedir#/spacer.gif" width="120" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap><br>
			<a href="showcategories.cfm?aID=0" class="sidenav">Infant/Toddler</a><br>			
			<a href="showcategories.cfm?aID=1" class="sidenav">Preschool</a><br>
			<a href="showcategories.cfm?aID=2" class="sidenav">Youth</a><br>
			<a href="showcategories.cfm?aID=3" class="sidenav">Teen/Adult</a><br>
			<a href="showcategories.cfm?aID=4" class="sidenav">55+ Senior Adults</a><br>
			<a href="showcategories.cfm?aID=6" class="sidenav">Family (All Ages)</a><br>
			<a href="showcategories.cfm?aID=5" class="sidenav">Special Population</a><br>
			</td>
			</tr>		
			</table>		
		</td>
		<td valign=top><img src="../images/spacer.gif" width="5" height="300" border="0" alt=""></td>
		<td valign=top colspan=2 class="bodytext" width="100%">
			<!--- <cfif qGetCats.recordcount gt 1> --->
			<form name="choosecat" action="results.cfm" method="post">
			<table width="100%" border="0" cellpadding="1" cellspacing="0">
			<tr>
			<td class="greentext"><br><br><strong>#form.agecat#, #qGetCats.category#</strong></td>
			<td class="bodytext" valign=top align="right"><br><br><a href="index.cfm"><strong>Detailed Search</strong></a></td>			
			</tr>
			<tr>
			<td><img src="#request.imagedir#/spacer.gif" width="225" height="1" border="0" alt=""></td>
			<td>&nbsp;</td>
			</tr>
			<tr>
			<td valign="top" class="lgnusr">
			<cfset catnum = 0>
			<cfloop query="qGetCats">
			<input type="radio" name="subcat" value="#code#" <cfif catnum is 0>checked</cfif>>&nbsp;<strong><cfif description is '--- None ---'>General<cfelse>#description#</cfif></strong><br>
			<cfset catnum = catnum + 1>
			</cfloop>
			</td>
			<td class="bodytext" valign=top>
			<cfswitch expression="#form.aID#">
				<cfcase value=0><img src="../photos/people72_nb.jpg" border="0"></cfcase>
				<cfcase value=1><img src="../photos/people71_nb.jpg" border="0"></cfcase>
				<cfcase value=2><img src="../photos/people2_nb.jpg" border="0"></cfcase>
				<cfcase value=3><img src="../photos/people3_nb.jpg" border="0"></cfcase>
				<cfcase value=4><img src="../photos/people46_nb.jpg" border="0"></cfcase>
				<cfcase value=5><img src="../photos/dance2_nb.jpg" border="0"></cfcase>
				<cfcase value=6><img src="../photos/outside3_nb.jpg" border="0"></cfcase>				
			</cfswitch>
			
			</td>
			</tr>
			<tr>
			<td colspan=2><br>
			<input type="submit" name="choosecat" value="Choose Category" class="form_submit"><br><br>
			</td>
			</tr>		
			</table>
		<input type="hidden" name="aID" value="#aID#">
		<input type="hidden" name="agecat" value="#form.agecat#">
		<input type="hidden" name="cat" value="#form.cat#">
		<input type="hidden" name="catname" value="#qGetCats.category#">
		</form>
			<!---<cfelse>
				 display results
				<cfinclude template="catdisplay.cfm">
			</cfif> --->
		</td>
   		</tr>
		</table>
   </td>
   <td><img src="#request.imagedir#/spacer.gif" width="1" height="128" border="0" alt=""></td>   
  </tr>
  <tr>
   <td colspan="36" valign="top"><p></p></td>
   <td><img src="#request.imagedir#/spacer.gif" width="1" height="11" border="0" alt=""></td>
  </tr>
  <cfinclude template="../footer.cfm">

</table>
</cfoutput>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>
