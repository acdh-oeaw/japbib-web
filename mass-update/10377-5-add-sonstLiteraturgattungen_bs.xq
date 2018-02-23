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

declare variable $_:maxNumberOfChangesPerJob external := 1500;
declare variable $_:onlyGetNumberOfEntries external := false();
declare variable $_:getParams external := false();

declare variable $_:listPlaces external := _:get-params()/*[@key eq '{urn:_}listPlaces'];
declare variable $__db__ external := 'japbib_06';
declare variable $__helper_tables__ external := "helper_tables";

declare function _:select-entries() as element(mods:mods)* { 
  (: Literaturgattung, die nachfolgend automatisch hinzugefügt wurde:)
  collection($__db__)//mods:mods[.//mods:subject[@usage='primary'][mods:topic[matches(., '^(Neuauflage|elektronische Publikation|audiovisuelles Material|Sammlung|Vorwort, Nachwort)$')]]/following-sibling::mods:subject[1]]
}; 
  

declare function _:get-params() as element(params) {
<params>
</params>
};

declare %updating function _:transform($e as element(mods:mods)) {
   let $newSubject := ( 
      <subject usage="secondary">
      <topic>Form</topic>
      <!--Task #10377,5: add sonstige Literaturgattungen-->
      <topic>sonstige Literaturgattungen</topic>
      </subject> 
     ) 
  for $subject in $e//.//mods:subject[@usage='primary'][mods:topic[matches(., '^(Neuauflage|elektronische Publikation|audiovisuelles Material|Sammlung|Vorwort, Nachwort)$')]]/following-sibling::mods:subject[1]
      return replace node $subject with $newSubject
};

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