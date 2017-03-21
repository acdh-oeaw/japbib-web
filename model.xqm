xquery version "3.0" encoding "utf-8";

module namespace model = "http://acdh.oeaw.ac.at/webapp/model";

declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $model:dbname := "japBib5";
declare variable $model:db := collection($model:dbname);

declare function model:query($q as xs:string) {
    model:query-by-field($q, ())
};

declare function model:query-by-field($q as xs:string, $field as xs:string?) {    
    switch ($field)
        case "entry" return $model:db//mods:mods[@xml:id eq $q]
        case "author" return $model:db//mods:name[mods:role/mods:roleTerm = 'aut'][contains(., $q)]/mods:namePart
        case "pubDate" return $model:db//mods:dateIssued[. eq $q]
        default return $model:db//text()[contains(., $q)]/parent::*
};

declare function model:browse($field as xs:string?) {
    switch ($field)
        case "entry" return $model:db//mods:mods
        case "author" return $model:db//mods:name[mods:role/mods:roleTerm = 'aut']/mods:namePart
        case "pubDate" return $model:db//mods:dateIssued
        case "subject" return $model:db//mods:topic
        case "title" return $model:db//mods:titleInfo
        default return error()
};

