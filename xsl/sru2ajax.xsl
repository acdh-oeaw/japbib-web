<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:_="urn:sur2html"
    xmlns="http://www.w3.org/1999/xhtml"
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
        <xsl:apply-templates select="sru:searchRetrieveResponse"/>
    </xsl:template>
    
    <xsl:template match="sru:searchRetrieveResponse">        
        <div class="ajax-result">
            <div class="navResults">
                <xsl:call-template name="navbar"/>
            </div>
            <div class="search-result">
                <xsl:apply-templates
                    select="sru:records"/>                
            </div>
            <div class="categoryFilter">
                <xsl:apply-templates
                    select="sru:extraResponseData/subjects/taxonomy"/>
            </div>
        </div>
    </xsl:template>

    <!-- Results -->
    
    <xsl:template name="navbar">
        <xsl:variable name="nOfRec" as="xs:integer" select="/sru:searchRetrieveResponse/sru:numberOfRecords"/>
        <xsl:variable name="lastPage" as="xs:integer" select="(($nOfRec - 1) idiv $maximumRecords) + 1"/>        
        <div class="countResults">
            <span class="numberofRecords"><xsl:value-of select="$nOfRec"/></span>&#xa0;Treffer 
        </div>
        <xsl:if test="$lastPage > 1">
        <div class="hitList">
            <span id="pullLeft" class="pull" title="zum Anfang der Trefferliste">≪</span>
            <a class="hits first{if ($startRecord &lt;= $maximumRecords) then ' here' else ''}" href="#?startRecord=1" title="Treffer 1–{if ($nOfRec > $maximumRecords) then $maximumRecords else $nOfRec}">1</a>
            <span class="fenster" id="fenster1">
                <span id="hitRow">
                    <xsl:for-each select="2 to $lastPage - 1">
                        <a class="hits{if ($startRecord >= ((. - 1) * $maximumRecords + 1) and $startRecord &lt;= ((. - 1) * $maximumRecords + $maximumRecords)) then ' here' else ''}" href="#?startRecord={((. - 1) * $maximumRecords) + 1}" title="Treffer {(. - 1) * $maximumRecords + 1}–{(. - 1) * $maximumRecords + $maximumRecords}"><xsl:value-of select="."/></a>
                    </xsl:for-each>
                </span>  
            </span> 
                <a class="hits last{if ($startRecord &gt;= (($lastPage - 1) * $maximumRecords + 1)) then ' here' else ''}" href="#?startRecord={(($lastPage - 1) * $maximumRecords) + 1}" title="Treffer {($lastPage - 1) * $maximumRecords + 1}–{$nOfRec}"><xsl:value-of select="$lastPage"/></a>
            <span id="pullRight" class="pull" title="zum Ende der Trefferliste">≫</span>
        </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="sru:records">
        <ol data-numberOfRecords="{/sru:searchRetrieveResponse/sru:numberOfRecords}" data-nextRecordPosition="{sru:searchRetrieveResponse/sru:nextRecordPosition}" class="results"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="sru:record">
        <li value="{sru:recordNumber}"><xsl:apply-templates select="sru:recordData/mods:mods"/></li>
    </xsl:template>
    
    <xsl:template match="mods:mods">
        <xsl:if test="not(mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')])"><span class="authors no-aut"><xsl:value-of select="_:dict('no-aut-abbr')"/></span></xsl:if>
        <xsl:for-each select="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]">
           <xsl:apply-templates select="."/><xsl:value-of select="if (position() ne last()) then '/ ' else ''"/>
        </xsl:for-each><xsl:text xml:space="prsserve"> </xsl:text>
        <xsl:if test="not(.//mods:originInfo/mods:dateIssued)"><span class="year no-year"><xsl:value-of select="concat('[',_:dict('no-year-abbr'),']')"/></span></xsl:if>
        <xsl:apply-templates select="(./mods:relatedItem[@type='host']/mods:originInfo, ./mods:originInfo)[1]/mods:dateIssued"/><xsl:text>,</xsl:text>
        <a class="plusMinus" href="#"><xsl:apply-templates select="mods:titleInfo"/></a>
        <xsl:apply-templates select="." mode="detail"/>
    </xsl:template>
    
    <xsl:template match="mods:mods" mode="detail">
        <div class="showEntry" style="display:none;">
            <div class="showOptions">
                <label>Anzeige des Eintrags: <select size="1" data-format="html">
                        <option value="html" selected="selected">detailliert</option>
                        <option value="compact">kompakt</option>
                        <option value="mods">MODS</option>
                        <option value="lidos">Lidos</option>
                    </select>
                </label>
                <span class="tipp" title="Tipp"><span class="display" style="display: none;">
                     MODS: XML Dokument in MODS-Standard (<a href='http://www.loc.gov/standards/mods/' class="externalLink">Library of Congress</a>); Codierung der Daten in der Datenbank. <br/>
                     LIDOS: Ursprüngliche Codierung im Datenbankprogramm LIDOS. 
                </span></span>
                <span id='x' class='closeX'></span>
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
        <li class="eSegment"><xsl:value-of select="_:dict('aut')"/></li>
        <li><xsl:for-each select="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')][not(./ancestor::mods:relatedItem)]">
            <xsl:apply-templates select="." mode="detail"/><xsl:value-of select="if (position() ne last()) then '/ ' else ''"/>
        </xsl:for-each></li>
        <xsl:apply-templates select="mods:titleInfo[not(./ancestor::mods:relatedItem)]" mode="detail"/>
        <xsl:apply-templates select="(./mods:relatedItem[@type eq 'host']/mods:originInfo, ./mods:originInfo)[1]" mode="detail"/>
    </xsl:template>
    
    <xsl:template name="more-detail-list-items">
        <xsl:apply-templates select=".//mods:relatedItem[@type eq 'series']" mode="more-detail"/>
        <xsl:apply-templates select="mods:physicalDescription" mode="more-detail"/>
        <xsl:call-template name="topic-filterd-subject-links">
            <xsl:with-param name="topic">Form</xsl:with-param>
            <xsl:with-param name="subjects" select="mods:subject[not(@displayLabel)]|mods:genre"/>
        </xsl:call-template>        
        <!-- TODO <li class="eSegment"> Co-Autoren </li>
 Co-Autoren -->
        <xsl:apply-templates select="mods:note[@type eq 'footnotes']" mode="more-detail"/>
    </xsl:template>
    
    <xsl:template name="topics-list-items">
        <xsl:variable name="this" select="."/>
        <xsl:for-each select="//subjects/taxonomy/category[catDesc ne 'Form']/catDesc">
        <xsl:call-template name="topic-filterd-subject-links">
            <xsl:with-param name="topic" select="."/>
            <xsl:with-param name="subjects" select="$this/mods:subject[not(@displayLabel)]"/>
        </xsl:call-template>
        </xsl:for-each>
        <xsl:call-template name="keywords">
            <xsl:with-param name="keywords" select="mods:subject[@displayLabel eq 'Stichworte']"/>
        </xsl:call-template>        
    </xsl:template>
    
    
    <xsl:template match="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]">
        <span class="authors"><xsl:value-of select="string-join(mods:namePart, '/ ')"/></span>
    </xsl:template>
    
    <xsl:template match="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]" mode="detail">
        <xsl:call-template name="link-with-number-of-records">
                <xsl:with-param name="index">author</xsl:with-param>
                <xsl:with-param name="term" select="mods:namePart"/>
            <xsl:with-param name="isLast" select="position() eq last()"/>
        </xsl:call-template>        
    </xsl:template>
    
    <xsl:template name="link-with-number-of-records">
        <xsl:param name="index" as="xs:string"/>
        <xsl:param name="term" as="xs:string*"/>
        <xsl:param name="separator" as="xs:string" select="' /'"/>
        <xsl:param name="isLast" as="xs:boolean" select="true()"/>
        <xsl:variable name="this" select="."/>
        <xsl:for-each select="$term">
            <xsl:variable name="scanClause" select="$index||'=='||normalize-space(.)"/>
            <xsl:variable name="by-this-term" select="$this/root()//sru:scanResponse[.//sru:scanClause eq $scanClause]//sru:numberOfRecords"/>
            <xsl:value-of select="_:dict(.)||' '"/><a href="#?query={$index}=&quot;{.}&quot;" class="zahl" title="Suchergebnisse"><xsl:value-of select="$by-this-term"/></a><xsl:if
                test="normalize-space($this//mods:roleTerm) = ('edt', 'trl', 'cbt')"><xsl:value-of select="', '||_:dict(normalize-space($this//mods:roleTerm))"/></xsl:if>
            <xsl:if test="not($isLast)"><xsl:value-of select="$separator"/></xsl:if>
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
    
    <xsl:template match="mods:originInfo[parent::mods:mods]" mode="detail">
        <li class="eSegment"><xsl:value-of select="_:dict('place')||'/'||_:dict('publisher')||'/'||_:dict('year')"/></li>
        <li><xsl:value-of select="(if (mods:place/mods:placeTerm) then mods:place/mods:placeTerm else _:dict('no-place-abbr'))||': '||
            (if (not(mods:publisher)) then _:dict('no-pub-abbr') else '' )"/>
            <xsl:call-template name="link-with-number-of-records">
                <xsl:with-param name="index">publisher</xsl:with-param>
                <xsl:with-param name="term" select="mods:publisher"/>
            </xsl:call-template>
            <xsl:value-of select="', '"/>
            <xsl:choose>
                <xsl:when test="mods:dateIssued">
                    <span class="{../@type}"><xsl:value-of select="string-join(mods:dateIssued, ', ')"/></span><xsl:if test="../../mods:relatedItem[@type='original']/mods:originInfo/mods:dateIssued">
                        <xsl:value-of select="', '"/><span class="original"><xsl:value-of select="../../mods:relatedItem[@type='original']/mods:originInfo/mods:dateIssued"/></span>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <span class="no-year"><xsl:value-of select=" _:dict('no-year-abbr')"/></span>
                </xsl:otherwise>
            </xsl:choose> 
         </li>
    </xsl:template>
    
    <xsl:template match="mods:originInfo[ancestor::mods:mods/mods:genre[@authority='local'] eq 'journalArticle' and parent::mods:relatedItem[@type eq 'host']]" mode="detail" priority="1">
        <li class="eSegment">In: </li>
        <li><a href="#?query=title=&quot;{../mods:titleInfo/mods:title}&quot;" class="stichwort"><xsl:value-of select="../mods:titleInfo/mods:title"/></a>
            <xsl:value-of select="if (../mods:part/mods:detail[@type eq 'volume']) then ', '||_:dict('volumeJournal')||' '||../mods:part/mods:detail[@type eq 'volume']/mods:number else ''"/><xsl:choose>
                <xsl:when test="mods:dateIssued and ../mods:part/mods:detail[@type eq 'volume']">
                    /<span class="{../@type}"><xsl:value-of select="string-join(mods:dateIssued, ', ')"/></span>
                </xsl:when>
                <xsl:when test="mods:dateIssued">                    
                    <xsl:value-of select="', '"/><span class="{../@type}"><xsl:value-of select="string-join(mods:dateIssued, ', ')"/></span>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="', '"/><span class="no-year"><xsl:value-of select=" _:dict('no-year-abbr')"/></span>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="if (../mods:part/mods:detail[@type eq 'issue']) then ', '||_:dict('issue')||' '||../mods:part/mods:detail[@type eq 'issue']/mods:number else ''"/>
            <xsl:value-of select="if (../mods:part/mods:extent[@unit eq 'page']) then ', '||_:dict('pages')||' '||string-join(../mods:part/mods:extent[@unit eq 'page']/(mods:start, mods:end), '-') else ''"/>
        </li>
    </xsl:template>
    
    <xsl:template match="mods:originInfo[parent::mods:relatedItem[ancestor::mods:mods/mods:genre[@authority='local'] eq 'bookSection' and @type eq 'host']]" mode="detail">
        <li class="eSegment">In: </li>
        <li>
            <xsl:apply-templates select="../mods:name" mode="detail"/><xsl:value-of select="', '"/><a href="#?query=title=&quot;{../mods:titleInfo/mods:title}&quot;" class="stichwort"><xsl:value-of select="../mods:titleInfo/mods:title"/></a>
            <xsl:value-of select="'. '||_:dict('place')||': '||(if (mods:place/mods:placeTerm) then mods:place/mods:placeTerm else _:dict('no-place-abbr'))"/>
            <xsl:value-of select="if (not(mods:publisher)) then ', '||_:dict('no-pub-abbr') else ', '"/><xsl:call-template name="link-with-number-of-records">                
                <xsl:with-param name="index">publisher</xsl:with-param>
                <xsl:with-param name="term" select="mods:publisher"/>    
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="mods:dateIssued">
                    <xsl:value-of select="', '"/><span class="{../@type}"><xsl:value-of select="string-join(mods:dateIssued, ', ')"/></span>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="', '"/><span class="no-year"><xsl:value-of select="_:dict('no-year-abbr')"/></span>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="if (../mods:part/mods:extent[@unit eq 'page']) then ', '||_:dict('pages')||' '||string-join(../mods:part/mods:extent[@unit eq 'page']/(mods:start, mods:end), '-') else ''"/>
        </li>
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
        <xsl:apply-templates mode="more-detail"/>
    </xsl:template>
    
    <xsl:template match="mods:extent" mode="more-detail">
        <li><xsl:value-of select=".||' '||_:dict(@unit||'s')"/></li>
    </xsl:template>
    
    <xsl:template match="mods:note" mode="more-detail">
        <li><xsl:value-of select="."/></li>
    </xsl:template>
    
    <xsl:template name="topic-filterd-subject-links">
        <xsl:param name="topic" as="xs:string"/>
        <xsl:param name="subjects" as="element()*"/>
        <xsl:variable name="subjectDescs" select="//subjects/taxonomy/category[catDesc eq $topic]//catDesc" as="xs:string*"/>
        <xsl:variable name="filteredSubjects" select="$subjects[_:dict(.) = $subjectDescs]"/>
        <xsl:if test="exists($filteredSubjects)">
            <li class="eSegment"><xsl:value-of select="$topic"/></li>
            <xsl:for-each select="$filteredSubjects">
                <li><xsl:call-template name="link-with-number-of-records">
                    <xsl:with-param name="index">subject</xsl:with-param>
                    <xsl:with-param name="term" select="."/>
                </xsl:call-template></li>
            </xsl:for-each>            
        </xsl:if>
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
            <a href="#?query=keyword=&quot;{.}&quot;" class="stichwort"><xsl:value-of select="."/></a><xsl:value-of select="if (position() ne last()) then '; ' else ''"/>
        </xsl:for-each>
        </li></xsl:if>
    </xsl:template>
    
    <!-- Taxonomy -->
    <xsl:template match="taxonomy">
        <ol class="schlagworte showResults"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="category[matches(@n, '^[123456789]$')]">
        <xsl:param name="base-path" tunnel="yes">#</xsl:param>
        <li class="li1"><span><xsl:apply-templates select="catDesc"/></span>
            <xsl:apply-templates select="numberOfRecords|numberOfRecordsInGroup">
                <xsl:with-param name="href" select="$base-path||'query=subject%3D&quot;'||catDesc||'&quot;'"/>
                <xsl:with-param name="showGroup" select="true()"/>
            </xsl:apply-templates>
            <ol><xsl:apply-templates select="category"/></ol>           
        </li>
    </xsl:template>
    
    <xsl:template match="category">
        <xsl:param name="base-path" tunnel="yes">#</xsl:param>
        <xsl:variable name="has-children" as="xs:boolean" select="exists(category)"/>
        <li><!--<span class="catNum"><xsl:value-of select="@n"/></span>-->
            <span>
                <xsl:if test="$has-children">
                    <xsl:attribute name="class">
                        <xsl:if test="$has-children">plusMinus</xsl:if>
                    </xsl:attribute>
                </xsl:if>
                <xsl:apply-templates select="catDesc"/>
            </span>
            <xsl:apply-templates select="numberOfRecords|numberOfRecordsInGroup">
                <xsl:with-param name="href" select="$base-path||'?query=subject%3D&quot;'||catDesc||'&quot;'"/>
            </xsl:apply-templates>
            <xsl:if test="category">
                <ol style="display:none;"><xsl:apply-templates select="category"/></ol>
            </xsl:if>
        </li>
    </xsl:template>
    
    <xsl:template match="numberOfRecords">
        <xsl:param name="href" as="xs:string">#</xsl:param>
        <xsl:param name="title" as="xs:string">Suchergebnisse</xsl:param>
        <a href="{$href}" class="zahl eintrag" title="{$title}"><xsl:value-of select="."/></a>
    </xsl:template>
    
    <xsl:template match="numberOfRecordsInGroup">
        <xsl:param name="href"/>
        <xsl:param name="title" as="xs:string">Suchergebnisse</xsl:param>
        <xsl:choose>
            <xsl:when test="exists(../numberOfRecords)">
                <a href="{$href}" class="zahl gruppe" title="{$title}"><xsl:value-of select="."/></a>            
            </xsl:when>
            <xsl:otherwise>
                <span class="zahl gruppe" title="{$title}"><xsl:value-of select="."/></span>                            
            </xsl:otherwise>                
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>