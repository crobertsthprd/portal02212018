<!--- one location; should not require login like it does here --->
<CFLOCATION url="/portal/searchhelp.cfm">
<CFABORT>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Search Help</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css"> 
</head>

<body topmargin="0" leftmargin="0" marginheight="0">
<TABLE WIDTH="500" cellpadding=1 cellspacing=0>
<tr bgcolor="0048d0">
<td align=center style="color:white;" class="bodytext" colspan=2><strong>Class Search / Registration Help</strong></td>
</tr>
<tr>
<td colspan="2" align="right"><img src="../photos/print.gif" border="0" onMouseup="javascript:window.print();" alt="Print Search Help">&nbsp;<img src="../photos/close.gif" border="0" onMouseup="javascript:window.close();" alt="Close Window"></td>
</tr>
<TR>
<td>&nbsp;&nbsp;</td>
<TD>


<strong>Search Help</strong><br>


To search for classes, you can use two methods, based on how you wish to search. 
<br>
<br>
You can enter all your desired classes in the <strong>Search by Class Number</strong> box and click <strong>Search By Number</strong> button. 
This will scroll through all entered classes, page after page. 
Upon registering your classes in each page, you will remain in the same location in your search, whereas you may merely continue to the remaining classes.
The classes searched must be the complete class ID. For example CA11121 will return CA11121. CA1112 will not return CA11121.
Using this method you can quickly get to your classes without going through the search process multiple times.
Each class specified must be separated with any non-character, such as a space, comma, etc.
<br>
<br>
You can also use the <strong>Detailed Activities/Class Search</strong> mode, you can enter search parameters to sear for.
To exclude classes, prepend a dash (-) immediately before the word to exclude (no space). For example, <strong>swim -private</strong> will return all classes that are NOT private lessons.
The search method options are <strong>All Words</strong>, where all words are required,
<strong>Any Word</strong> where any of the words are required and
<strong>Phrase</strong>, where the exact phrase has to be found. Do not use exclusion word in this mode.
Each word must be separated with any non-character, such as a space, comma, etc.
<br>
<br>
<strong>Checkbox Options</strong><BR>
<UL>
<LI><strong>Include Already Started:</strong> By default, all classes that have already started is suppressed since they cannot be registered. When checked, started classes are included.</LI>
<LI><strong>Include Completed/Canceled:</strong> By default, all classes that are completed or canceled are suppressed. When checked, such classes are included.</LI>
<LI><strong>Ignore Patron Age:</strong> Selected patron ages are included in the search. When checked, patron ages are ignored.</LI>
<LI><strong>Suppress Filled:</strong> When checked, suppress classes that are already filled and only offer waiting list enrollment.</LI>
<LI><strong>Suppress Waitlisted:</strong> When checked, suppress classes that already have waiting lists.</LI>
</UL>

<strong>Registration Help</strong><br>

To register patron(s) in classes, select each patron you wish to add for each class listed.
You may select multiple patrons if needed for each class.
To unselect, CTRL-click each patron to remove, or click <strong>Reset Selections</strong> to clear all selections on the current page (previous enrollments are not affected).
You may also click <strong>Previous</strong> or <strong>More</strong> to navigate to other search results pages.
When all patrons are selected for each class, click <strong>Enroll Selected Patrons</strong>.
Each enrollment will be immediate and be displayed at the top with the enrollment status.
<br>
<br>
If a class has a deposit option available, you will see a checkbox on the bottom to enroll with the deposit option.
Merely check this <strong>before</strong> you <strong>Enroll Selected Patrons</strong>.
If you did not use this option but wished to, merely <strong>Drop</strong> said class and enroll again using the deposit option.
<br><br>
<div align="center"><A href="javascript:;" onClick="window.close()">Close Window</A></div>
</TD>
</TR>
</TABLE>




<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>
