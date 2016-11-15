module namespace api = "http://acdh.oeaw.ac.at/webapp/api";
import module namespace view = "http://acdh.oeaw.ac.at/webapp/view" at "view.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Implement any additional REST endpoints in this file :)
declare 
    %rest:path("MYWEBAPP/query")
    %rest:GET
    %rest:query-param("q", "{$q}")
    %rest:query-param("startAt", "{$startAt}")
    %rest:query-param("max", "{$max}")
    (:%output:method("xhtml")
    %output:omit-xml-declaration("no")
    %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")  
    %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"):)
function api:query($q as xs:string, $startAt as xs:integer?, $max as xs:integer?) {
    error(
        xs:QName('err:not-implemented'),
        'Function api:query() has to be implemented in rest.xqm'
    )
};