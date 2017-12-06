# Uninstall Sitecore 9

Sitecore Install Framework (SIF) to uninstall a Sitecore9 instance from a local development environment setup.  This can also be run if your installation fails to complete and your environment requires cleaning up.

This module should be place in a folder in the modules directory of your PowerShell installation, typically C:\Program Files\WindowsPowerShell\Modules

n.b this will not remove the solr services

## Usage

* Please ensure that SIF is installed
* Modify the parameters in Install-Config.json to suit your needs
* Open a PS console at the location of your Install-Config.json
* The cmdlet to invoke is Install-SitecoreConfiguration .\Install-Config.json

## Parameters

* Prefix - _The Prefix used to install the site with SIF, e.g. s9_
* SitecoreSiteName - _The name of your website e.g. s9.local_
* SolrService - _The name of your solr service_
* PathToSolr - _The path to your instance of solr, e.g. C:\Solr\solr-6.6.0\apache-solr_
* SqlServer - _The name of your SQL server instance_
* SqlAccount - _Your SQL account, typically the one used to create the databases_
* SqlPassword -  _Your SQL account's password_
