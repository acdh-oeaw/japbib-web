Basex Browser Query interface
=============================

2016/04/04, daniel.schopper@oeaw.ac.at

This is a proof-of concept webbrowser XQuery interface for BaseX using JQuery + RestXQ. Originally it has been written to query the LIDOS XML export of the JapBib database (Cf. https://acdh.oeaw.ac.at/redmine/issues/5638) but it can be used with any data inside of BaseX.   

Installation
------------

Clone to the BaseX webapp directory (normally $basex/webapp), adjust RESTXQ paths and the name of the database to query ($api:database) in rest.xqm.  