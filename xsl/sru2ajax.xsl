<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:_="urn:sur2html"
    xmlns="http://www.w3org/1999/xhtml"
    exclude-result-prefixes="#all"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>Produces various parts of the website using a searchRetrieve query
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="no" method="xhtml"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:include href="lib/serialization.xsl"/>
    <xsl:include href="lib/localization.xsl"/>
    <xsl:include href="lib/buildurls.xsl"/>
    
    <xsl:variable name="serialization-parameters">
        <output:serialization-parameters
            xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
            <output:method value="xml"/>
            <output:version value="1.0"/>
            <output:indent value="yes"/>
            <output:omit-xml-declaration value="yes"/>
        </output:serialization-parameters>
    </xsl:variable>
    
    <xsl:template match="/">
        <div class="ajax-result">
            <div class="navResults">
                <div class="countResults">
                    <span class="numberofRecords"><xsl:value-of select="/sru:searchRetrieveResponse/sru:numberOfRecords"/></span>&#xa0;Treffer 
                </div>
                <div class="hitList">
                    <span id="pullLeft" class="pull" title="Liste nach links ziehen (hintere anzeigen)">≪</span>
                    <a class="hits first{if ($startRecord &lt;= 10) then ' here' else ''}" href="#{_:urlParameters(1)}" title="Treffer 1–10">1</a>
                    <span class="fenster" id="fenster1">
                        <span id="hitRow">
                            <xsl:for-each select="1 to ((/sru:searchRetrieveResponse/sru:numberOfRecords - 11) idiv 10)">
                                <a class="hits{if ($startRecord &gt;= (. * 10 + 1) and $startRecord &lt;= (. * 10 + 10)) then ' here' else ''}" href="#{_:urlParameters(. * 10 + 1)}" title="Treffer {. * 10 + 1}—{. * 10 + 10}"><xsl:value-of select=". + 1"/></a>
                            </xsl:for-each>
                        </span>  
                    </span>
                    <xsl:variable name="lastPage" as="xs:integer" select="(/sru:searchRetrieveResponse/sru:numberOfRecords - 1) idiv 10"/>
                    <a class="hits last{if ($startRecord &gt;= ($lastPage * 10 + 1)) then ' here' else ''}" href="#{_:urlParameters($lastPage * 10 + 1)}" title="Treffer {$lastPage * 10 + 1}–{/sru:searchRetrieveResponse/sru:numberOfRecords}"><xsl:value-of select="$lastPage"/></a>
                    <span id="pullRight" class="pull" title="Liste nach rechts ziehen (vordere anzeigen)">≫</span>
                </div>
            </div>
            <div class="search-result">
                <xsl:apply-templates
                    select="sru:searchRetrieveResponse/sru:records"/>                
            </div>
            <div class="categoryFilter">
                <xsl:apply-templates
                    select="sru:searchRetrieveResponse/sru:extraResponseData/subjects/taxonomy"/>
            </div>
        </div>
    </xsl:template>

    <!-- Results -->
    
    <xsl:template match="sru:records">
        <ol data-numberOfRecords="{/sru:searchRetrieveResponse/sru:numberOfRecords}" data-nextRecordPosition="{sru:searchRetrieveResponse/sru:nextRecordPosition}" class="results"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="sru:record">
        <li value="{sru:recordNumber}"><xsl:apply-templates select="sru:recordData/mods:mods"/></li>
    </xsl:template>
    
    <xsl:template match="mods:mods">
        <xsl:if test="not(mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')])"><span class="authors"><xsl:value-of select="_:dict('no-aut-abbr')"/></span></xsl:if>
        <xsl:apply-templates select="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]"/><xsl:text xml:space="prsserve"> </xsl:text>
        <xsl:if test="not(.//mods:originInfo/mods:dateIssued)"><span class="year"><xsl:value-of select="concat('[',_:dict('no-year-abbr'),']')"/></span></xsl:if>
        <xsl:apply-templates select=".//mods:originInfo/mods:dateIssued"/><xsl:text>,</xsl:text>
        <a class="plusMinus" href="#"><xsl:apply-templates select="mods:titleInfo"/></a>
        <xsl:apply-templates select="." mode="detail"/>
    </xsl:template>
    
    <xsl:template match="mods:mods" mode="detail">
        <div class="showEntry" style="display:none;">
            <div class="showOptions">
                <label>Anzeige des Eintrags: <select name="top5" size="1" data-format="html">
                        <option value="html" selected="selected">detailliert</option>
                        <option value="mods">MODS</option>
                        <option value="lidos">Lidos</option>
                    </select>
                </label>
                <span class="tipp" title="Tipp"><span class="display" style="display: none;">„Detailliert“ 
                    enthält Stichworte, über die neue Suchabfragen möglich 
                    sind.</span></span>
            </div>
            <div class="record-html">
                <ul><xsl:call-template name="detail-list-items"/></ul>
                <div class="addInfo">
                <p><b>Weitere bibliographische Angaben</b></p>
                <ul><xsl:call-template name="more-detail-list-items"/></ul>
                <p><b>Inhaltliche Angaben</b></p>
                <ul><xsl:call-template name="topics-list-items"/></ul>
                </div>
            </div>
            <div class="record-mods" style="display:none;">
                <xsl:variable name="modsDoc">
                    <xsl:copy-of select="." copy-namespaces="no"/>               
                </xsl:variable>
                <textarea rows="20" cols="80" class="codemirror-data" xml:space="preserve"><xsl:sequence select="_:serialize($modsDoc, $modsDoc//LIDOS-Dokument, $serialization-parameters/*)"/></textarea>
            </div>
            <div class="record-lidos" style="display:none;">         
                <xsl:variable name="lidosDoc">
                    <xsl:copy-of select=".//LIDOS-Dokument" copy-namespaces="no"/>               
                </xsl:variable>
                <textarea rows="20" cols="80" class="codemirror-data" xml:space="preserve"><xsl:sequence select="serialize($lidosDoc, $serialization-parameters/*)"/></textarea>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template name="detail-list-items">
        <xsl:apply-templates select="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')][not(./ancestor::mods:relatedItem)]" mode="detail"/>
        <xsl:apply-templates select="mods:titleInfo[not(./ancestor::mods:relatedItem)]" mode="detail"/>
        <xsl:apply-templates select=".//mods:originInfo" mode="detail"/>
    </xsl:template>
    
    <xsl:template name="more-detail-list-items">
        <xsl:apply-templates select=".//mods:relatedItem[@type eq 'series']" mode="more-detail"/>
        <xsl:apply-templates select="mods:physicalDescription" mode="more-detail"/>
        <xsl:call-template name="topic-filterd-subject-links">
            <xsl:with-param name="topic">Form</xsl:with-param>
            <xsl:with-param name="subjects" select="mods:subject[not(@displayLabel)]"/>
        </xsl:call-template>        
        <!-- TODO <li class="eSegment"> Co-Autoren </li>
 Co-Autoren -->
        <xsl:apply-templates select="mods:note[@type eq 'footnotes']" mode="more-detail"/>
    </xsl:template>
    
    <xsl:template name="topics-list-items">
        <xsl:variable name="this" select="."/>
        <xsl:for-each select="('Thema', 'Zeit', 'Region')">
        <xsl:call-template name="topic-filterd-subject-links">
            <xsl:with-param name="topic" select="."/>
            <xsl:with-param name="subjects" select="$this/mods:subject[not(@displayLabel)]"/>
        </xsl:call-template>
        </xsl:for-each>
<!--        <li class="eSegment">Thema</li>
        <li>Religionswissenschaft (<a class="zahl" href="#" title="Neue Abfrage">40</a>)</li>
        <li>Brauchtum und Feste (<a class="zahl" href="#" title="Neue Abfrage">20</a>)</li>-->        
        
<!--        <li class="eSegment">Zeit</li>
        <li>Moderne (1868–1945) (<a class="zahl" href="#" title="Neue Abfrage">4.088</a>)</li>-->
        
<!--        <li class="eSegment">Region</li>
        <li>Japan (<a class="zahl" href="#" title="Neue Abfrage">20.000</a>)</li>
        <li>Korea (<a class="zahl" href="#" title="Neue Abfrage">4.000</a>)</li>-->
        <xsl:call-template name="keywords">
            <xsl:with-param name="keywords" select="mods:subject[@displayLabel eq 'Stichworte']"/>
        </xsl:call-template>        
    </xsl:template>
    
    
    <xsl:template match="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]">
        <span class="authors"><xsl:value-of select="string-join(mods:namePart, '/ ')"/></span>
    </xsl:template>
    
    <xsl:template match="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]" mode="detail">
        <li class="eSegment"><xsl:value-of select="_:dict(mods:role/normalize-space(mods:roleTerm))"/></li>
        <li><xsl:call-template name="link-with-number-of-records">
                <xsl:with-param name="index">author</xsl:with-param>
                <xsl:with-param name="term" select="mods:namePart"/>
            </xsl:call-template>
        </li>
    </xsl:template>
    
    <xsl:template name="link-with-number-of-records">
        <xsl:param name="index" as="xs:string"/>
        <xsl:param name="term" as="xs:string*"/>
        <xsl:param name="separator" as="xs:string" select="' /'"/>
        <xsl:variable name="this" select="."/>
        <xsl:for-each select="$term">
            <xsl:variable name="scanClause" select="$index||'=='||normalize-space(.)"/>
            <xsl:variable name="by-this-term" select="$this/root()//sru:scanResponse[.//sru:scanClause eq $scanClause]//sru:numberOfRecords"/>
            <xsl:value-of select="."/> (<a href="#{_:urlParameters(1, $index||'=&quot;'||.||'&quot;')}" class="zahl" title="Suchergebnisse"><xsl:value-of select="$by-this-term"/></a>)<xsl:if
                test="position() ne last()"><xsl:value-of select="$separator"/></xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="mods:dateIssued">
        <span class="year"><xsl:value-of select="."/></span>
    </xsl:template>
    
    <xsl:template match="mods:titleInfo">
        <span class="title"><xsl:apply-templates select="*"/></span>
    </xsl:template>
    
    <xsl:template match="mods:titleInfo" mode="detail">
        <li class="eSegment"><xsl:value-of select="_:dict('title')"/></li>
        <li><xsl:apply-templates mode='#default'/></li>
    </xsl:template>
    
    <xsl:template match="mods:nonSort"><xsl:value-of select="normalize-space(.)||' '"/></xsl:template>
    
    <xsl:template match="mods:title"><xsl:value-of select="normalize-space(.)"/>.</xsl:template>
    
    <xsl:template match="mods:subTitle"><xsl:text xml:space="preserve"> </xsl:text><xsl:value-of select="normalize-space(.)"/>.</xsl:template>
    
    <xsl:template match="mods:originInfo" mode="detail">
        <li class="eSegment"><xsl:value-of select="_:dict('place')||'/'||_:dict('publisher')||'/'||_:dict('year')"/></li>
        <li><xsl:value-of select="(if (mods:place/mods:placeTerm) then mods:place/mods:placeTerm else _:dict('no-place-abbr'))||': '||
            (if (not(mods:publisher)) then _:dict('no-pub-abbr') else '' )"/>
            <xsl:call-template name="link-with-number-of-records">
                <xsl:with-param name="index">publisher</xsl:with-param>
                <xsl:with-param name="term" select="mods:publisher"/>
            </xsl:call-template>
            <xsl:value-of select="', '||
            (if (mods:dateIssued) then string-join(mods:dateIssued, ', ') else _:dict('no-year-abbr'))"/></li>
    </xsl:template>
    
    <xsl:template match="mods:relatedItem[@type eq 'series']" mode="more-detail">
        <li class="eSegment"><xsl:value-of select="_:dict('series')"/></li>
        <li><xsl:call-template name="link-with-number-of-records">
            <xsl:with-param name="index">series</xsl:with-param>
            <xsl:with-param name="term" select=".//mods:title"/>
        </xsl:call-template><xsl:apply-templates mode="more-detail" select="* except mods:titleInfo"/></li>
    </xsl:template>
    
    <xsl:template match="mods:part[mods:detail[@type eq 'volume']]" mode="more-detail">
       <xsl:value-of select="', '||_:dict('vol-abbr')||' '||mods:detail"/>
    </xsl:template>
    
    <xsl:template match="mods:physicalDescription" mode="more-detail">
        <li class="eSegment">Kollationsvermerk</li>
        <li><xsl:value-of select="mods:note"/></li>
    </xsl:template>
    
    <xsl:template name="topic-filterd-subject-links">
        <xsl:param name="topic" as="xs:string"/>
        <xsl:param name="subjects" as="element(mods:subject)*"/>
        <li class="eSegment"><xsl:value-of select="$topic"/></li>
        <li>TODO -> <xsl:value-of select="count($subjects)"/> subjects</li>
    </xsl:template>
    
    <xsl:template match="mods:note[@type eq 'footnotes']" mode="more-detail">        
        <li class="eSegment">Bemerkungen</li>
        <li><xsl:value-of select="."/></li>        
    </xsl:template>
    
    <xsl:template name="keywords">
        <xsl:param name="keywords" as="element(mods:subject)*"/>
        <xsl:if test="$keywords">
        <li class="eSegment">Stichworte</li>
        <li><xsl:for-each select="$keywords">
            <a href="#{_:urlParameters(1, 'subject=&quot;'||.||'&quot;')}"><xsl:value-of select="."/></a><xsl:text xml:space="preserve"> </xsl:text>
        </xsl:for-each>
        </li></xsl:if>
    </xsl:template>
    
    <!-- Taxonomy -->
    <xsl:template match="taxonomy">
        <ol class="schlagworte showResults"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="category[matches(@n, '^[123456789]$')]">
        <li class="li1"><span><xsl:value-of select="catDesc"/></span>
            <ol><xsl:apply-templates select="category"/></ol>           
        </li>
    </xsl:template>
    
    <xsl:template match="category">
        <xsl:variable name="has-children" as="xs:boolean" select="exists(category)"/>
        <li><!--<span class="catNum"><xsl:value-of select="@n"/></span>-->
            <span>
                <xsl:if test="$has-children">
                    <xsl:attribute name="class">
                        <xsl:if test="$has-children">plusMinus</xsl:if>
                    </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="catDesc"/>
            </span>
            <xsl:if test="numberOfRecords">
                <a href="#{_:urlParameters(1, 'query=subject%3D&quot;'||catDesc||'&quot;')}" class="zahl" title="Suchergebnisse"><xsl:value-of select="numberOfRecords"/></a>
            </xsl:if>
            <xsl:if test="category">
                <ol style="display:none;"><xsl:apply-templates select="category"/></ol>
            </xsl:if>
        </li>
    </xsl:template>
    
</xsl:stylesheet>