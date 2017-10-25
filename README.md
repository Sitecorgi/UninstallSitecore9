# UninstallSitecore9
Short and simple PowerShell Script to uninstall a Sitecore9 instance from a local development environment setup.  This can also be run if your installation fails to complete and your environment requires cleaning up.

n.b this will not remove the solr services although that can be added with a very small modification to the script

## Parameters

*Prefix - _The Prefix used to install the site with SIF, e.g. s9_
*SitecoreSiteName - _The name of your website e.g. s9.local_
*SolrService, - _The name of your solr service
*PathToSolr, - _The path to your instance of solr, e.g. C:\Solr\solr-6.6.0\apache-solr_
*SqlServer, - _The name of your SQL server instance_
*SqlAccount, _Your SQL account, typically the one used to create the databases_
*SqlPassword _Your SQL account's password_



