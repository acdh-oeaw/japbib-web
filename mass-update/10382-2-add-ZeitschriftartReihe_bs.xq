xquery version "3.1";

(: Call this script directly to process a few hundred of entries with small
   changes.
   To update the whole database with larger changes try them and then use
   write-to-db-in-junks.xq with this script as the $script_to_run parameter
   else for large changes the list of updates will exhaust the memory. 
:)

import module namespace hist = "https://acdh.oeaw.ac.at/vle/history" at "vle-history.xqm";

declare namespace _ = "urn:_";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $_:maxNumberOfChangesPerJob external := 6000;
declare variable $_:onlyGetNumberOfEntries external := false();
declare variable $_:getParams external := false();

declare variable $_:listPlaces external := _:get-params()/*[@key eq '{urn:_}listPlaces'];
declare variable $__db__ external := 'japbib_06';
declare variable $__helper_tables__ external := "helper_tables"; 
 
declare variable $subjecttoMatch := "^Zeitschriftenartige Reihe$";
declare variable $genre := "series";

declare function _:select-entries() as element(mods:mods)* {
  collection($__db__)//mods:mods[mods:subject[@usage eq 'primary' and mods:topic[matches(., $subjecttoMatch)]] and not(mods:genre)]
};

declare function _:get-params() as element(params) {
<params>
</params>
};

declare %updating function _:transform($e as element(mods:mods)) {
      let $type := $e/mods:typeOfResource, 
         $newGenre :=  (
           <genre authority="local" xmlns="http://www.loc.gov/mods/v3">
           {$genre} {comment {'#Task #10382.2.1 add '||$genre}}        
           </genre>
         ) 
  return insert node $newGenre after $type
};
(:  ca. 76 Ersetzungen

Nach dem gleichen Schema:
 Zeitschriftenartige Reihe --> Series (ca. 58)
 Ausstellungskatalog  --> Book (ca. 341)
 Bibliographie, Katalog --> Book (ca. 74)
 Dissertation --> Thesis (ca. 377)

:)  

declare function _:main() {
  let $sub := <_>{subsequence(_:select-entries(), 1, $_:maxNumberOfChangesPerJob)}</_>,
      $ret := $sub update {
    for $e in ./* return
     _:transform($e) }
  return $ret/*
  (: _:get-params()/*[@key eq '{urn:_}listPlaces'] :)
  (: map:merge(parse-xml(serialize(_:get-params()))/*/*!map{@key: *}) :)
};

if ($_:onlyGetNumberOfEntries) then count(_:select-entries())
else if ($_:getParams) then serialize(_:get-params())
else _:main()