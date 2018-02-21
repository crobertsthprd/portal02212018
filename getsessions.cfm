<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<title>Untitled Document</title>
</head>

<cfapplication name="sessionLister" sessionManagement="yes" sessiontimeout="#createtimespan(0,0,2,0)#">
<!--- application tracker object --->
<cfset appObj = createObject("java","coldfusion.runtime.ApplicationScopeTracker")>
<!--- get the enumeration of application keys --->
<cfset apps = appObj.getApplicationKeys()>
<!--- session tracker object --->
<cfset tracker = createObject("java","coldfusion.runtime.SessionTracker")>
<!--- while there are more applications in the enumeration --->
<cfloop condition="#apps.hasMoreElements()#">
<!--- get the app name --->
<cfset appname = apps.nextElement()>
<!--- get the sessions for this app name --->
<cfset sessions = tracker.getSessionCollection(appname)>
<!--- dump the sessions out --->
<cfdump var="#sessions#" label="#appname#">
</cfloop>


<body>
</body>
</html>
