xquery version "3.0";

(:
The MIT License (MIT)

Copyright (c) 2016 Austrian Centre for Digital Humanities at the Austrian Academy of Sciences

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE
:)

module namespace index = "japbib:index";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "responses/sru/diagnostics.xqm";

declare variable $index:INDEX_TYPE_FT := "ft";

declare function index:namespaces($context as xs:string) as element(ns)* {
    index:map($context)/../namespaces/ns
};

declare function index:base-elt($map as element(map)){
    $map/xs:string(@base_elem)
};

declare function index:map($context as xs:string) as element() {
    let $map := doc("maps.xml")//map[@key = $context]
    return 
        if (exists($map))
        then $map
        else diag:diagnostics('unsupported-context-set', $context)
};

declare function index:index-from-map($index-key as xs:string, $map as element(map)){
    let $i := $map//index[@key eq $index-key]
    return 
        if (exists($i))
        then $i
        else diag:diagnostics('index-unknown', $index-key)
};

declare function index:index-as-xpath-from-map($index-key as xs:string, $map as element(map)){
    index:index-as-xpath-from-map($index-key, $map, ())
};
declare function index:index-as-xpath-from-map($index-key as xs:string, $map as element(map), $aspect as xs:string?) {
    let $indexDef := index:index-from-map($index-key, $map)
    return
        switch ($aspect)
            case 'match' return string-join(($indexDef/path, $indexDef/path/@match), '/')
            case 'match-only' return if (exists($indexDef/path/@match)) then $indexDef/path/@match else '.'
            case 'label' return string-join(($indexDef/path,$indexDef/path/@label), '/')
            case 'path-only' return $indexDef/path
            default return $indexDef/path
};

declare function index:case($index-key as xs:string, $map as element(map)) as xs:boolean{
  if ((index:index-from-map($index-key, $map)/xs:string(@case),'')[1] = ('yes', 'true', '1')) then true() else false()
};

declare function index:scr($index-key as xs:string, $map as element(map)) as xs:string{
  (index:index-from-map($index-key, $map)/xs:string(@scr),'contains')[1]
};

declare function index:datatype($index-key as xs:string, $map as element(map)) as xs:string? {
  index:index-from-map($index-key, $map)/xs:string(@datatype)  
};

declare function index:map-to-indexInfo() {
    for $m in doc("maps.xml")/map//map
    return 
    <zr:indexInfo xmlns:zr="http://explain.z3950.org/dtd/2.1/">
        <zr:set name="{$m/@title}" identifier="{$m/@key}"/>
        {for $i in $m//index
        return 
        <zr:index>
            <zr:title lang="de">{$i/data(@label)}</zr:title>
            <zr:map>
                <zr:name set="sru">{$i/data(@key)}</zr:name>
            </zr:map>
        </zr:index>}
    </zr:indexInfo>
};

declare function index:map-to-schemaInfo() { 
    <zr:schemaInfo xmlns:zr="http://explain.z3950.org/dtd/2.1/">{
        for $m in doc("maps.xml")/map//map
        return
        <zr:schema name="{$m/@name}" identifier="{$m/@index}">
          <zr:title>{data($m/@title)}</zr:title>
        </zr:schema>
    }</zr:schemaInfo>
};

