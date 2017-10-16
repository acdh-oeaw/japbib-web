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

declare variable $_:maxNumberOfChangesPerJob external := 10;
declare variable $_:firstChangeJob external := 1;
declare variable $_:onlyGetNumberOfEntries external := false();
declare variable $_:db-name := 'japbib_06';
declare variable $_:thesaurus := 
  for $c in doc('../../japbib-web/thesaurus.xml')//catDesc return
    <topic xmlns="http://www.loc.gov/mods/v3" primary="{$c}">{
      for $pc in $c/ancestor::*:category except $c/.. return
        <topic>{($pc/*:catDesc)/text()}</topic>
      }
    </topic>;

declare function _:select-entries() as element(mods:mods)* {
  collection($_:db-name)//mods:mods[not(mods:subject/@usage)]
};

declare %updating function _:transform($e as element(mods:mods)) {  
    let $subjects := $e/mods:subject[not(@displayLabel)]
    return for $subject in $subjects
      let $newSubject := (
        <subject usage="primary" xmlns="http://www.loc.gov/mods/v3">
        {(comment {'#Task #9222 add super categories'||$subject/mods:topic}, $subject/*)}
        </subject>,
        <subject usage="secondary" xmlns="http://www.loc.gov/mods/v3">
        {$_:thesaurus[@primary = $subject/mods:topic]/*}
        </subject>
        )
      return replace node $subject with $newSubject
};

declare %updating function _:main() {
  let $entries-subset := subsequence(_:select-entries(), 1, $_:maxNumberOfChangesPerJob)
  return ( 
     hist:save-entry-in-history($_:db-name, $entries-subset),
  for $e in $entries-subset
  return (
     _:transform($e),     
     hist:add-change-record($e) ,
     db:output(serialize($e update
     { _:transform(.),     
       hist:add-change-record(.) })) )
  )
};

if ($_:onlyGetNumberOfEntries) then db:output(count(_:select-entries()))
else _:main()