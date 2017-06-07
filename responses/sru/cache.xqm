xquery version "3.0";

module namespace c = "japbib:cache";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";

declare variable $c:dbname := $model:dbname||"_cache";

declare %updating function c:scan($terms as item(), $scanClause as xs:string, $sort as xs:string) {
    let $fn := c:scan-filename($scanClause, $sort)
    return
    if (exists(c:scan($scanClause, $sort)))
    then db:replace($c:dbname, $fn,$terms)
    else db:create($c:dbname, $terms, $fn)
};

declare function c:scan($scanClause as xs:string, $sort as xs:string) {
    if (db:exists($c:dbname)) 
    then db:open($c:dbname, c:scan-filename($scanClause, $sort))
    else ()
};

declare function c:scan-filename($scanClause as xs:string, $sort as xs:string) {
    $scanClause||"-"||$sort||".xml"
};