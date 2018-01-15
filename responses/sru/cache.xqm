xquery version "3.0";

module namespace c = "japbib:cache";

import module namespace db = "http://basex.org/modules/db";
import module namespace prof = "http://basex.org/modules/prof";
import module namespace l = "http://basex.org/modules/admin";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";

declare variable $c:dbname := $model:dbname||"__cache";
declare variable $c:thesaurus-fn := 'thesaurus.xml';
declare variable $c:index-options := map{'textindex': true(), 'ftindex': true(), 'casesens': false(), 'diacritics': false()};

declare function c:scan($terms as document-node(), $scanClauseParsed as element(scanClause), $sort as xs:string) {
    let $fn := c:scan-filename($scanClauseParsed, $sort)
    return c:save-fn($terms, $fn)
};

declare function c:thesaurus($xml as document-node()) {
   c:save-fn($xml, $c:thesaurus-fn)
};

declare function c:save-fn($xml as document-node(), $fn as xs:string) {
 let $query := ``[
      import module namespace c = "japbib:cache" at "cache.xqm";
      import module namespace l = "http://basex.org/modules/admin";
      declare variable $xml external;
      try {
      let $index-options := map:merge(($c:index-options, map{'language': 'de'})),
          $fn-exists := exists(`{c:get-fn-query($fn)}`)
      return if ($fn-exists)
      then 
        let $log := l:write-log('cache:scan replacing cached scan in `{$c:dbname}`: `{$fn}`')
        return (db:replace("`{$c:dbname}`", "`{$fn}`" ,$xml), db:optimize("`{$c:dbname}`", true(), $index-options))
      else if (db:exists("`{$c:dbname}`")) then
        let $log := l:write-log('cache:scan creating cached scan in `{$c:dbname}`: `{$fn}`')
        return (db:add("`{$c:dbname}`", $xml, "`{$fn}`"), db:optimize("`{$c:dbname}`", true(), $index-options))
      else
        let $log := l:write-log('cache:scan creating cached scan and db `{$c:dbname}`: `{$fn}`')
        return db:create("`{$c:dbname}`", $xml, "`{$fn}`", $index-options)
    } catch err:FODC0007 {
         ()
    }
   ]``,
      $saveJobId := jobs:eval($query, map{'xml': $xml }, map {
      'cache': true(),
      'id': 'cache-'||$fn||'.xq',
      'base-uri': string-join(tokenize(static-base-uri(), '/')[last() > position()], '/')||'/'||'cache-'||$fn||'.xq'}), $_ := jobs:wait($saveJobId)
  return jobs:result($saveJobId)
};

declare function c:scan($scanClauseParsed as element(scanClause), $sort as xs:string) as document-node()? {
    (: Beware: logging here is expensive (in searchRetrieve requests) :)
    let (:$log := l:write-log('cache:scan $scanClause := '||$scanClauseParsed/index||' $sort := '||$sort, 'DEBUG'),:)
        $fn := c:scan-filename($scanClauseParsed, $sort),
        $jid := jobs:eval(c:get-fn-query($fn), (), map {'cache': true()}), $_ := jobs:wait($jid)
(:       , $logRest := l:write-log('cache:scan return '||substring(if (exists($ret)) then serialize($ret) else '()', 1, 240), 'DEBUG'):)
    return jobs:result($jid)
};

declare function c:thesaurus() as document-node()? {
  let $jid := jobs:eval(c:get-fn-query($c:thesaurus-fn), (), map {'cache': true()}), $_ := jobs:wait($jid)
  return jobs:result($jid)
};

declare function c:get-fn-query($fn as xs:string) as xs:string {
``[   try {
        db:open("`{$c:dbname}`", "`{$fn}`")
      } catch err:FODC0007 {
        ()
      }]``
};

declare function c:scan-filename($scanClauseParsed as element(scanClause), $sort as xs:string) as xs:string {
    (: could also be import module namespace w = "http://basex.org/modules/web"; w:encode-url() but oXygen does not like url encoded filenames :) 
    $scanClauseParsed/index||"-"||$sort||".xml"
};

(: hand optimization, don not use without thorough consideration :)
declare function c:text-nodes-in-cached-file-equal($string as xs:string, $dn as document-node()) as text()* {
  db:text($c:dbname, $string)[base-uri(.) = base-uri($dn)]
};