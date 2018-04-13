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

declare variable $subject := "Zeitschriftenartikel";
declare variable $genre := "journalArticle";
declare variable $genretoMatch := "^[Jj]ournalArticle$";

declare function _:select-entries() as element(mods:mods)* { 
  collection($__db__)//mods:mods[mods:genre[matches(., $genretoMatch)]][not(mods:subject[contains(., $subject)])]
}; 

declare function _:get-params() as element(params) {
<params>
</params>
};

declare %updating function _:transform($e as element(mods:mods)) {
      let $firstSubject := $e/mods:subject[1],
        $newSubject := (        
        <subject usage="primary" xmlns="http://www.loc.gov/mods/v3">
        {comment {'#Task #10382,1.3 add '||$subject}}
        <topic xmlns="http://www.loc.gov/mods/v3">$subject</topic>
        </subject>,    
        <subject usage="secondary" xmlns="http://www.loc.gov/mods/v3"> 
        <topic xmlns="http://www.loc.gov/mods/v3">Form</topic>
        </subject>
        ) 
  return insert node $newSubject before $firstSubject
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