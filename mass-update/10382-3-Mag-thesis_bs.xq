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
  collection($__db__)//mods:topic[. eq 'Magister-, Diplomarbeit']/ancestor::mods:mods
}; 

declare function _:get-params() as element(params) {
<params>
</params>
};

declare %updating function _:transform($e as element(mods:mods)) {
  let $genre := $e/mods:genre,
      $newGenre := <genre xmlns="http://www.loc.gov/mods/v3" authority="local">thesis</genre>,
      $genreOK := $genre[1][matches(., '^([Tt]hesis|[Bb]ook|[Bb]ookSection|[Jj]ournalArticle)$')],
      $comment1 := '#Task #10382,3 added Mag thesis',   
      $comment2 := '#Task #10382,3 correct Mag thesis',   
      $comment3 := '#Task #10382,3 removed second genre',
      $type := $e/mods:typeOfResource
      return (
        if ($genre[2]/text()) then replace node $genre[2] with comment {$comment3} else(),
        if (not($genre[1])) 
        then (
          insert node comment {$comment1} after $type,
          insert node $newGenre after $type
        ) 
        else (
          if (not($genreOK)) 
          then (
          insert node comment {$comment2}  before $genre[1],
          replace node $genre[1] with $newGenre
          )
          else()
       )
     )
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