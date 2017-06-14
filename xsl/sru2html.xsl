<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xcql="http://www.loc.gov/zing/cql/xcql/"
    xmlns:d="http://www.loc.gov/zing/srw/diagnostic/"
    xmlns="http://www.w3org/1999/xhtml"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:_="urn:sur2html"
    xmlns:saxon="http://saxon.sf.net/"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:param name="xcql" select="''" as="xs:string"/>
    <xsl:param name="startRecord" select="1" as="xs:integer"/>
    <xsl:param name="maximumRecords" select="10" as="xs:integer"/>
    <xsl:param name="query" select="''" as="xs:string"/>
    <xsl:param name="base-uri-public" select="''" as="xs:string"/>
    <xsl:param name="base-uri" select="''" as="xs:string"/>
    <xsl:param name="version" select="''" as="xs:string"/>
    <xsl:param name="x-style" select="''" as="xs:string"/>
    <xsl:param name="operation" select="''" as="xs:string"/>
    
    <xsl:include href="thesaurus2html.xsl"/>
    <xsl:variable name="sru-url">http://localhost:8984/japbib-web/sru</xsl:variable>
    <xsl:variable name="dict" as="document-node()" select="doc('dict-de.xml')"/>

    <xsl:function name="_:serialize">
        <xsl:param name="node" as="node()?"/>
        <xsl:param name="omit-nodes" as="node()?"/>
        <xsl:sequence select="_:serialize($node, $omit-nodes, ())"/>
    </xsl:function>
    
    <xsl:function name="_:serialize">
        <xsl:param name="node" as="node()?"/>
        <xsl:param name="omit-nodes" as="node()?"/>
        <xsl:param name="params" as="item()?"/>
        <xsl:variable name="preprocessedXML">
            <xsl:apply-templates mode="filter" select="$node">
                <xsl:with-param name="omit-nodes" tunnel="yes" select="$omit-nodes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:value-of select="serialize($preprocessedXML)"/>
    </xsl:function>
    
    <xsl:template mode="filter" match="@*|*|processing-instruction()|comment()">
        <xsl:param name="omit-nodes" as="node()?" tunnel="yes"/>
        <xsl:if test="not(. = $omit-nodes)">
           <xsl:copy>
              <xsl:apply-templates select="*|@*|text()|processing-instruction()|comment()" mode="filter"/>
           </xsl:copy>
        </xsl:if>
<!--        <xsl:if test=". = $omit-nodes">
            <xsl:message terminate="no"><xsl:value-of select="local-name(.)"/> omitted</xsl:message> 
        </xsl:if>-->
    </xsl:template>
    
    <xsl:function name="_:dict">
        <xsl:param name="id"/>
        <xsl:choose>
            <xsl:when test="exists($dict//string[@xml:id = $id])">
                <xsl:value-of select="$dict//string[@xml:id = $id]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$id"/> 
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="_:urlParameters" as="xs:string">
        <xsl:value-of select="_:urlParameters($startRecord)"/>
    </xsl:function>
    <xsl:function name="_:urlParameters" as="xs:string">
        <xsl:param name="startRecord" as="xs:integer"/>
        <xsl:value-of select="concat(
            '?version=', $version,
            '&amp;operation=searchRetrieve',
            '&amp;query=', $query,
            '&amp;maximumRecords=', $maximumRecords,
            '&amp;startRecord=', $startRecord,
            '&amp;x-style=', $x-style)"/>
    </xsl:function>
    
    <xsl:template match="/">
        <html>
            <head>
                <title>SRU Endpoint</title>
                <style type="text/css">
                    .css-switch ~ * {display: none;}
                    .css-switch:checked ~ div,
                    .css-switch:checked ~ pre,
                    .css-switch:checked ~ p,
                    .css-switch:checked ~ ul,
                    .css-switch:checked ~ ol,
                    .css-switch ~ div.show-instead,
                    .css-switch ~ pre.show-instead,
                    .css-switch ~ p.show-instead
                    {display: block;}
                    .css-switch:checked ~ span,                    
                    .css-switch:checked ~ label,
                    .css-switch ~ span.show-instead,
                    .css-switch ~ label.show-instead
                    {display: inline;}
                    .css-switch:checked ~ .show-instead {display: none;}
                </style>
            </head>
            <body>
                <xsl:apply-templates/>
            </body>
        </html>
    </xsl:template>
    <xsl:template match="sru:diagnostics">
       <div>
           <h1>ERROR</h1>
           <xsl:apply-templates/>
       </div>
    </xsl:template>
    
    <xsl:template match="d:diagnostic">
        <h5><xsl:value-of select="@key"/></h5>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="d:*" priority="-1">
        <p><xsl:value-of select="local-name()"/>: <xsl:value-of select="."/></p>
    </xsl:template>
    
    <xsl:template match="sru:searchRetrieveResponse">
        <div>
            <form action="{$base-uri-public}" method="get">
                <input name="query" value="{$query}"/>
                <input name="version" type="hidden" value="{$version}"/>
                <input name="startRecord" type="hidden" value="{$startRecord}"/>
                <input name="maximumRecords" type="hidden" value="{$maximumRecords}"/>
                <input name="operation" type="hidden" value="searchRetrieve"/>
                <button type="submit">Search</button>
            </form>
            <div class="meta">
                <xsl:if test="$xcql != ''">
                    <h4>XCQL</h4>
                    <pre><xsl:copy-of select="$xcql"/></pre>
                </xsl:if>
                <xsl:if test="$query != ''">
                    <h4>URI</h4>
                    <p>Public:
                    <pre><xsl:value-of select="concat($base-uri-public, _:urlParameters())"/></pre>
                    Private:
                    <pre><xsl:value-of select="concat($base-uri, _:urlParameters())"/></pre>
                    </p>
                </xsl:if>
                <xsl:apply-templates select="sru:extraResponseData"/>
            </div>
            <xsl:apply-templates select="sru:records"/>
        </div>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData/XPath">
        <h4>Transformed XQuery</h4>
        <pre><xsl:copy-of select="."/></pre>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData/XCQL">
        <h4>XCQL</h4>
        <pre><xsl:copy-of select="."/></pre>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData/subjects">
        <h4>Subjects</h4>
        <div>
            <input type="checkbox" class="css-switch" id="subjects-switch" name="ui-subjects-switch" style="display:none;"/>
            <label for="subjects-switch">Hide...</label>
            <xsl:apply-templates select="taxonomy"/>
            <label for="subjects-switch" class="show-instead">Show list...</label>
        </div>
    </xsl:template>
    
    <xsl:template match="sru:extraResponseData">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="sru:records">
        <div class="records">
            <h4>Records</h4>
            <table>
                <tbody>
                    <tr><td><xsl:value-of select="_:dict('numberOfRecords')"/></td><td><xsl:value-of select="../sru:numberOfRecords"/></td></tr>
                    <!--<xsl:if test="min(sru:recordNumber) gt 1">
                        <tr><td>Previous Record Position</td><td><a href="?{../sru}"><xsl:value-of select="../sru:nextRecordPosition"/></a></td></tr>
                    </xsl:if>-->
                    <xsl:if test="../sru:nextRecordPosition != ''">
                        <tr><td>Next Record Position</td><td><a href="{_:urlParameters(../sru:nextRecordPosition)}"><xsl:value-of select="../sru:nextRecordPosition"/></a></td></tr>
                    </xsl:if>
                </tbody>
            </table>
            <ol data-numberOfRecords="{../sru:numberOfRecords}" data-nextRecordPosition="{../sru:nextRecordPosition}">
                <xsl:apply-templates select="sru:record"/>
            </ol>
        </div>
    </xsl:template>
    
    <xsl:template match="sru:record">
        <li value="{sru:recordNumber}">
            <xsl:apply-templates select="sru:recordData"/>
        </li>
    </xsl:template>
    
    <xsl:template match="sru:recordData">
        <xsl:variable name="title" select="mods:mods/mods:titleInfo/*[not(self::mods:subTitle)]"/>
        <xsl:variable name="subtitle" select="mods:mods/mods:titleInfo/*[self::mods:subTitle]"/>
        <xsl:variable name="authors" select="mods:mods/mods:name[mods:role/mods:roleTerm = 'aut']/mods:namePart"/>
        <xsl:variable name="year" select="mods:mods/mods:originInfo/mods:dateIssued"/>
        <xsl:variable name="pubPlace" select="mods:mods//mods:originInfo/mods:place/mods:placeTerm"/>
        <xsl:variable name="publisher" select="mods:mods//mods:originInfo/mods:publisher"/>
        <xsl:variable name="host" select="mods:mods//mods:relatedItem[@type = 'host']"/>
        <xsl:variable name="series" select="mods:mods//mods:relatedItem[@type = 'series']"/>
        <xsl:variable name="subjects" select="mods:mods//mods:subject[not(@displayLabel)]/*"/>
        <xsl:variable name="keywords" select="mods:mods//mods:subject[@displayLabel = 'Stichworte']/*"/>
        <xsl:variable name="mods-serialized" select="_:serialize(mods:mods, mods:mods//LIDOS-Dokument)"/>
        <xsl:variable name="lidos-serialized" select="serialize(mods:mods//LIDOS-Dokument)"/>
        <xsl:variable name="genre" select="mods:mods/mods:genre"/>
        <xsl:variable name="is-book" select="$genre = 'book'"/>
        <span class="recordHead">
            <span class="authors">
                <xsl:for-each select="$authors">
                    <xsl:value-of select="."/>
                    <xsl:if test="count($authors) gt position()">
                        <xsl:text>,&#160;</xsl:text>
                    </xsl:if>
                </xsl:for-each>
                <xsl:text> </xsl:text>
            </span>
            <span class="year"><xsl:value-of select="($year,concat('[',_:dict('no-year-abbr'),']'))[1]"/></span>
            <xsl:text>,&#160;</xsl:text>
        
            <a href="sru?operation=searchRetrieve&amp;version=1.2&amp;query=id={mods:mods/mods:recordInfo/mods:recordIdentifier}&amp;x-style=record2html.xsl" class="sup"><xsl:value-of select="$title"/></a>
        </span>
        <div class="showEntry">
            <div class="showOptions">
                <form>
                    <label>Anzeige des Eintrags:
                        <select name="top5" size="1">
                            <option selected="selected" value="html">detailliert</option>
                            <!--<option>Chicago Styles Manual</option>
                            <option>BibTeX</option>S-->
                            <xsl:if test="$lidos-serialized != ''">
                                <option value="lidos">LIDOS</option>
                            </xsl:if>
                            <xsl:if test="$mods-serialized != ''">
                                <option value="mods">MODS</option>
                            </xsl:if>
                        </select>
                    </label>
                    <span class="erklärung"><span> „Detailliert“ enthält auch Stichworte, über die neue Suchabfragen möglich sind. LIDOS bezeichnet das Originalformat der Daten, MODS den aktuellen Stand der Daten in der Datenbank.</span></span>
                </form>
            </div>
            <div class="record-html">
                <ul>
                    <li class="eSegment"> <xsl:value-of select="_:dict('aut')"/> </li>
                    <li> 
                        <xsl:choose>
                            <xsl:when test="not($authors)"><xsl:value-of select="_:dict('no-aut-abbr')"/></xsl:when>
                            <xsl:otherwise>
                                <xsl:for-each select="$authors">
                                    <xsl:value-of select="."/>
                                    <xsl:call-template name="numberOfRecordsTemplate">
                                        <xsl:with-param name="index">author</xsl:with-param>
                                    </xsl:call-template>
                                    <xsl:if test="position() lt count($authors)"><br/></xsl:if>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                    </li>
                    <li class="eSegment"> <xsl:value-of select="_:dict('title')"/> </li>
                    <li>
                        <xsl:call-template name="title">
                            <xsl:with-param name="title" select="$title"/>
                            <xsl:with-param name="subtitle" select="$subtitle"/>
                        </xsl:call-template>
                    </li>
                    <xsl:if test="exists($host)">
                        <xsl:variable name="volume" select="$host/mods:part/mods:detail[@type = 'volume']"/>
                        <xsl:variable name="issue" select="$host/mods:part/mods:detail[@type = 'issue']"/>
                        <li class="eSegment"> In: </li>
                        <li>
                            <xsl:choose>
                                <xsl:when test="$host/mods:titleInfo != ''">
                                    <xsl:value-of select="string-join($host/mods:titleInfo/*,'. ')"/>
                                    <xsl:call-template name="numberOfRecordsTemplate">
                                        <xsl:with-param name="index">title</xsl:with-param>
                                        <xsl:with-param name="value"><xsl:value-of select="$host/mods:titleInfo/mods:title"/></xsl:with-param>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>[</xsl:text><xsl:value-of select="_:dict('no-title-abbr')"/><xsl:text>]</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:call-template name="volume">
                                <xsl:with-param name="volume" select="$volume"/>
                            </xsl:call-template>
                            <xsl:call-template name="issue">
                                <xsl:with-param name="year" select="$host/mods:originInfo/mods:dateIssued[matches(.,'^\d{4,4}$')]"/>
                                <xsl:with-param name="issue" select="$issue"/>
                                <xsl:with-param name="issue-date" select="$host/mods:originInfo/mods:dateIssued[matches(.,'^\d{1,2}\.\d{1,2}\.\d{4,4}$')]"/>
                            </xsl:call-template>
                            <xsl:if test="$host/mods:name">
                                <xsl:call-template name="formatName">
                                    <xsl:with-param name="name" select="$host/mods:name"/>
                                </xsl:call-template>
                            </xsl:if>
                        </li>
                    </xsl:if>
                    <xsl:if test="exists($series)">
                        <xsl:variable name="volume" select="$series/mods:part/mods:detail[@type = 'volume']"/>
                        <xsl:variable name="issue" select="$series/mods:part/mods:detail[@type = 'issue']"/>
                        <li class="eSegment"> <xsl:value-of select="_:dict('series')"/> </li>
                        <li>
                            <xsl:choose>
                                <xsl:when test="string-join($series//mods:titleInfo/*,' ') != ''">
                                    <xsl:value-of select="string-join($series//mods:titleInfo/*,' ')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="_:dict('no-value-abbr')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text> </xsl:text>
                            <xsl:if test="$volume != ''">
                                <xsl:text xml:space="preserve">; </xsl:text>
                                <xsl:value-of select="$volume"/>
                            </xsl:if>
                            <xsl:call-template name="issue">
                                <xsl:with-param name="year" select="$series/mods:originInfo/mods:dateIssued[matches(.,'^\d{4,4}$')]"/>
                                <xsl:with-param name="issue" select="$issue"/>
                                <xsl:with-param name="issue-date" select="$series/mods:originInfo/mods:dateIssued[matches(.,'^\d{1,2}\.\d{1,2}\.\d{4,4}$')]"/>
                            </xsl:call-template>
                            <xsl:call-template name="numberOfRecordsTemplate">
                                <xsl:with-param name="index">series</xsl:with-param>
                                <xsl:with-param name="value" select="$series//mods:titleInfo"/>
                            </xsl:call-template>
                        </li>
                    </xsl:if>
                    <xsl:if test="$is-book">
                        <li class="eSegment"> <xsl:value-of select="_:dict('place')"/>/<xsl:value-of select="_:dict('publisher')"/>/<xsl:value-of select="_:dict('year')"/></li>
                        <li xml:space="preserve"><xsl:value-of select="($pubPlace, _:dict('no-place-abbr'))[1]"/>: <xsl:value-of select="($publisher, _:dict('no-pub-abbr'))[1]"/>, <xsl:value-of select="($year, _:dict('no-year-abbr'))[1]"/></li>
                    </xsl:if>
                    <!--<li class="eSegment"> Co-Autoren </li>
                <li> Paul, G. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Naumann, 
                    N. (<a href="#" class="zahl" title="Suchergebnisse">6</a>); Ōbayashi, T (<a href="#" class="zahl" title="Suchergebnisse">6</a>); Blümmel, 
                    V. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Vollmer, K. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Zöllner, 
                    R. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Lokowandt, H. (<a href="#" class="zahl" title="Suchergebnisse">6</a>); Fischer, 
                    P. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Knecht, P. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Pörtner, 
                    P. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Toelken, R. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Woirgardt, 
                    M. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Ikeda, H. (<a href="#" class="zahl" title="Suchergebnisse">6</a>)</li>
                <li class="eSegment"> Kollationsvermerk 
                </li>
                <li> 300 S. : Ill., graph. Darst., Notenbeisp.</li>-->
                    
                </ul>
                <p> <b>Verwandte Suchabfragen</b> </p>
                <ul>
                    <xsl:if test="exists($subjects)">
                        <li class="eSegment">Thema</li>  
                        <xsl:for-each select="$subjects">
                            <li>
                                <xsl:value-of select="."/>
                                <xsl:text>&#160;</xsl:text>
                                <xsl:call-template name="numberOfRecordsTemplate">
                                    <xsl:with-param name="index">subject</xsl:with-param>
                                    <xsl:with-param name="value" select="string-join(*,'')"/>
                                </xsl:call-template>
                            </li>
                        </xsl:for-each>
                    </xsl:if>
                    
                    <!--<li class="eSegment">Form</li> 
                <li>Sammelwerk (<a href="#" class="zahl" title="Suchergebnisse">numberOfRecords</a>)</li>-->
                    
                    <xsl:if test="exists($keywords)">
                        <li class="eSegment">Stichworte</li>    
                        <li>
                            <xsl:for-each select="$keywords">
                                <a href="#"><xsl:value-of select="."/></a>
                                <xsl:if test="position() lt count($keywords)">
                                    <xsl:text>;&#160;</xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </li>
                    </xsl:if>
                </ul>
            </div>
            <div>
                <input type="checkbox" id="show-mods" class="css-switch" style="display:none;"/>
                <label for="show-mods">Hide...</label>
                <pre class="record-mods"><xsl:value-of select="$mods-serialized"/></pre>
                <label for="show-mods" class='show-instead'>Show MODS...</label>
            </div>
            <div>
                <input type="checkbox" id="show-lidos" class="css-switch" style="display:none;"/>
                <label for="show-lidos">Hide...</label>
                <pre class="record-lidos"><xsl:value-of select="$lidos-serialized"/></pre>
                <label for="show-lidos" class='show-instead'>Show LIDOS...</label>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template name="volume">
        <xsl:param name="volume"/>
        <xsl:if test="$volume != ''">
            <xsl:text>,&#160;</xsl:text>
            <xsl:value-of select="_:dict('vol-abbr')"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="$volume"/>
        </xsl:if>
    </xsl:template>
    
    
    <xsl:template name="issue">
        <xsl:param name="issue"/>
        <xsl:param name="year"/>
        <xsl:param name="issue-date"/>        
        <xsl:if test="$year != ''">
            <xsl:text xml:space="preserve"> </xsl:text>
            <xsl:value-of select="$year"/>
        </xsl:if>
        <xsl:if test="$issue != ''">
            <xsl:text xml:space="preserve">, </xsl:text>
            <xsl:value-of select="$issue"/>
            <xsl:if test="$issue-date != ''">
                <xsl:value-of select="_:dict('from')"/>
                <xsl:text xml:space="preserve"> </xsl:text>
                <xsl:value-of select="$issue-date"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="format-record-heading">
        
    </xsl:template>
    
    <xsl:template name="numberOfRecordsTemplate">
        <xsl:param name="index" required="yes"/>
        <xsl:param name="value" required="no" select="."/>
        <xsl:variable name="query" select="concat($index,'=&quot;',normalize-space($value),'&quot;')"/>
        <xsl:text>&#160;(</xsl:text>
        <a data-query="{$query}" href="{$sru-url}?operation=searchRetrieve&amp;version=1.2&amp;query={$query}" class="zahl" title="Suchergebnisse">numberOfRecords</a>
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    <xsl:template name="formatName">
        <xsl:param name="name" as="element(mods:name)+"/>
        <xsl:for-each select="$name">
            <xsl:value-of select="mods:namePart"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="_:dict(mods:role/mods:roleTerm)"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="title" xml:space="default">
        <xsl:param name="title"/>
        <xsl:param name="subtitle"/>
        <xsl:value-of select="string-join($title, ' ')"/>
        <xsl:if test="$subtitle != ''">
            <xsl:text xml:space="preserve">. </xsl:text><xsl:value-of select="string-join($subtitle,' ')"/><xsl:text>.</xsl:text>
        </xsl:if>
        
    </xsl:template>
</xsl:stylesheet>
