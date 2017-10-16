xquery version "3.1";

(: This script runs the actual data update scripts. It sets a maximum of
   $_:maxNumberOfChangesPerJob per script run and runs it as often as
   necessary (determined by the scripts response to a
   call with $_:onlyGetNumberOfEntries := true() )
:)

declare namespace _ = "urn:_";

declare variable $_:maxNumberOfChangesPerJob := 100;
declare variable $_:basePath := string-join(tokenize(static-base-uri(), '/')[position() < last()], '/');
declare variable $script_to_run external := 'writer.xq';
declare variable $keep_chnaged_xml_until_finished := true();

declare function _:start-jobs-or-get-results() {
  let $update-jobs := jobs:list-details()[starts-with(@id, 'updWrite_')]
  return if (exists($update-jobs)) then
    let $wait := $update-jobs[@state="running"]!jobs:wait(@id),
        $countUnfinished := count($update-jobs[@state=("queued", "running")])
    return 
      if ($countUnfinished > 0) then <message>{$countUnfinished||' queued for execution.'}</message>
      else $update-jobs[@state="cached"]!jobs:result(@id)
  else
  let $slaveScript := unparsed-text($_:basePath||'/'||$script_to_run),
      $jobids := for $i in (0 to xs:integer(ceiling(_:number_of_changed_entries() div $_:maxNumberOfChangesPerJob)) - 1)
        return jobs:eval($slaveScript, map {
          '{urn:_}firstChangeJob': $i * $_:maxNumberOfChangesPerJob + 1,
          '{urn:_}maxNumberOfChangesPerJob': $_:maxNumberOfChangesPerJob
        }, map {
          'cache': $keep_chnaged_xml_until_finished,
          'id': 'updWrite_'||$i,
          'base-uri': $_:basePath||'/'
        })
  return 'Started '||count($jobids)||' jobs. Run again to get results.'
};

declare function _:number_of_changed_entries() as xs:integer {
  let $slaveScript := unparsed-text($_:basePath||'/'||$script_to_run),
      $id := jobs:eval($slaveScript, map {
          '{urn:_}onlyGetNumberOfEntries': true()
        }, map {
          'cache': true(),
          'id': 'numberOfEntries_1',
          'base-uri': $_:basePath||'/'
        }),
      $wait := jobs:wait($id)
   return jobs:result($id)
};

_:start-jobs-or-get-results()