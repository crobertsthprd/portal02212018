<!--- google analytics for web stats DEPRECATED ON MARCH 5, 2014
<CFIF application.serverAddress EQ "#application.publicIP#" >
<script type="text/javascript" src="https://ssl.google-analytics.com/ga.js"></script>
<script type="text/javascript">
var pageTracker = _gat._getTracker("UA-3810709-1");
pageTracker._initData();
pageTracker._trackPageview();
</script>
</CFIF>
--->
<!-- Google Analytics -->
<script>
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)})(window,document,'script','//www.google-analytics.com/analytics.js','ga');
ga('create', 'UA-3810709-1', 'auto');  // Replace with your property ID.
ga('send', 'pageview');
</script>
<!-- End Google Analytics -->
<CFINCLUDE template="/portalinc/facebook.cfm">



