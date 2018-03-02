xquery version "3.1";

(: Call this script directly to process a few hundred of entries with small
   changes.
   To update the whole database with larger changes try them and then use
   write-to-db-in-junks.xq with this script as the $script_to_run parameter
   else for large changes the list of updates will exhaust the memory. 
:)

declare namespace mods = "http://www.loc.gov/mods/v3";

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";

declare variable $_:maxNumberOfChangesPerJob external := 300;
declare variable $_:onlyGetNumberOfEntries external := false();
declare variable $_:db-name := 'japbib_06';
declare variable $_:getParams external := false();

declare variable $__db__ external := "japbib_06";
declare variable $__helper_tables__ external := "helper_tables";
 
declare function _:select-entries() as element(mods:mods)* {
(: Wähle originInfo ohne dateIssued, aber mit (nicht geparstem) Text, außer Ortsnamen (--> Verlagsangabe) :)
  collection($__db__)//LIDOS-Dokument/Jahr[matches(., '(^19|20)\d\d$')]/ancestor::mods:mods[mods:relatedItem[@type='host']/mods:originInfo[not(mods:dateIssued)][text()[matches(., '[\d\w]')][not(matches(., 'Tübingen|Zürich|Düsseldorf|Hamburg|Wien|Berlin|Dresden|München|Herne|Bonn|Wiesbaden|Bochum|T[oô]ky[oô]|Kassel|Köln|Schaffhausen|Weinheim|Gütersloh|Frankfurt|Lausanne|Konstanz|Heidelberg|Münster|Stuttgart|Duisburg'))]]]
};
declare function _:get-params() as element(params) {
<params>
</params>
};

declare %updating function _:transform($e as element(mods:mods)) {
  (: Nimm Jahresangabe aus Lidos und packe unklare Zeitangabe in <edition></edition> :)
  let $Jahr := $e//LIDOS-Dokument/Jahr/text(),
      $comment := 'Task #9277 2: dateIssed von Lidos/Jahr übernehmen',
      $dateIssued := <dateIssued>{$Jahr}</dateIssued>,
      $originInfo := $e/mods:relatedItem[@type='host']/mods:originInfo,
      $oldText := $originInfo/text()[1],
      $oldComment := $originInfo[comment()[matches(., 'Erscheinungsverm')]]/comment() 
      
  return ( 
      insert node comment{$comment} as first into $e/mods:relatedItem[@type='host']/mods:originInfo, 
      insert node $dateIssued  as first into $originInfo, 
      if ($oldComment and $oldText) 
      then (
         replace node $oldComment with comment {'Task #9277 2: placed "...Erscheinungsverm." in <edition>'}, 
         replace node $oldText with <edition>{$oldText}</edition> 
      )
      else () 
    )      
};

declare %updating function _:main() {
  let $entries-subset := subsequence(_:select-entries(), 1, $_:maxNumberOfChangesPerJob),
      $store-in-history := hist:save-entry-in-history($_:db-name, $entries-subset)
  return (
    for $e in $entries-subset
  return (
     _:transform($e),     
     hist:add-change-record($e) ,
     db:output(serialize($e update
     { _:transform(.),     
       hist:add-change-record(.) })) ),
  jobs:wait($store-in-history)
  )
};

if ($_:onlyGetNumberOfEntries) then db:output(count(_:select-entries()))
else if ($_:getParams) then db:output(serialize(_:get-params()))
else _:main()
(: db:output(serialize(
<db name="{$__db__}" _:maxNumberOfChangesPerJob="{$_:maxNumberOfChangesPerJob}" _:firstChangeJob="{$_:firstChangeJob}">
{subsequence($_:listPlaces, 1, 10)}
</db>
)) :)