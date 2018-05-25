xquery version "3.1";

module namespace _ = "https://acdh.oeaw.ac.at/vle/history";

import module namespace session = "http://basex.org/modules/session";

declare namespace bxerr = "http://basex.org/errors";

declare variable $_:user external := '';

declare %updating function _:add-change-record($e as element()) {
  let $user := try {session:get('dba')} catch bxerr:BXSE0003 | session:get {if ($_:user ne '') then $_:user else user:current()},
      $newEntry :=
      element {QName($e/namespace-uri(),'fs')} {
        namespace {''} {$e/namespace-uri()},
        attribute type {'change'},
        <f name="who">
          <symbol>{attribute value {$user}}</symbol>
        </f>,
        <f name="when">
          <symbol>{attribute value {format-dateTime(current-dateTime(),'[Y0001]_[M01]_[D01]')}}</symbol>
        </f>
      }
  return insert node $newEntry as last into $e
};

declare function _:save-entry-in-history($db-base-name as xs:string, $cur-nodes as node()+) as xs:string {
  let $hist-db-name := $db-base-name||'__hist',
      $hist-nodes := <_/> update {insert node $cur-nodes into .} update {./*!_:add-timestamp(.) },
      $script := 
      'import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";
       declare variable $hist-nodes external;       
       try { hist:_save-entry-in-history(collection("'||$hist-db-name||'"), "'||$hist-db-name||'", $hist-nodes) }
       catch err:FODC0002 { db:create("'||$hist-db-name||'", <hist>{$hist-nodes/*}</hist>, "'||$hist-db-name||'.xml") }',
      $jid := jobs:eval($script, map {
        'hist-nodes': $hist-nodes
      }, map {
        'cache': false(),
        'base-uri': static-base-uri()
      }) 
  return $jid
};

declare %updating function _:_save-entry-in-history($hist-db as document-node(), $hist-db-name as xs:string, $hist-nodes as node()+) {
  insert node $hist-nodes/* as last into $hist-db/hist
};

declare %updating function _:add-timestamp($cur-node as node()) {
   insert node (attribute dt {format-dateTime(current-dateTime(),'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')}) into $cur-node 
};