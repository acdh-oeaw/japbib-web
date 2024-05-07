xquery version "3.1";
import module namespace scans = "http://acdh.oeaw.ac.at/japbib/api/refresh" at "../webapp/japbib-web/responses/sru/refresh-scans.xqm";
import module namespace thesaurus = "http://acdh.oeaw.ac.at/japbib/api/thesaurus" at "../webapp/japbib-web/responses/thesaurus.xqm";

(scans:refresh-cache(),
thesaurus:taxonomy-as-html-cached("refresh",()),
"Cache refreshed")[3]