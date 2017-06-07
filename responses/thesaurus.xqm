xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/thesaurus";

declare variable $api:path-to-thesaurus := "../thesaurus.xml";
declare variable $api:thesaurus2html := "../xsl/thesaurus2html.xsl";

declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:taxonomy-as-xml() {
    doc($api:path-to-thesaurus)
};

declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:produces("text/html", "application/xml+xhtml")
    %output:method("xml")
function api:taxonomy-as-html() {
    xslt:transform(doc($api:path-to-thesaurus), doc($api:thesaurus2html))
};