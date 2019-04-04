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
    
    <xsl:output indent="yes" method="xhtml"/>
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
    
    
    <xd:doc>
        <xd:desc>Resultate abfragen</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:apply-templates select="sru:searchRetrieveResponse"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
        Erstelle .ajax-result = provisorischer Container für Elemente, 
        die von js gegen alte Elemente ausgetauscht werden 
        </xd:desc>
    </xd:doc>
    <xsl:template match="sru:searchRetrieveResponse">        
        <div class="ajax-result">
            <div class="navResults">
                <xsl:call-template name="navbar"/>
            </div>
            <div class="search-result">
                <xsl:apply-templates select="sru:records"/>                
            </div>
            <div class="categoryFilter">
                <xsl:apply-templates select="sru:extraResponseData/subjects/taxonomy"/>
            </div>
        </div>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
        
        Navigationszeile (.navResults)
        
        </xd:desc>
    </xd:doc>
    <xsl:template name="navbar">
        <xsl:variable name="nOfRec" as="xs:integer" select="/sru:searchRetrieveResponse/sru:numberOfRecords"/>
        <xsl:variable name="lastPage" as="xs:integer" select="(($nOfRec - 1) idiv $maximumRecords) + 1"/>        
        <div class="countResults">
            <span class="numberofRecords"><xsl:value-of select="$nOfRec"/></span>&#xa0;Treffer 
        </div>
        <xsl:choose>
            <xsl:when test="$lastPage > 1">
                <div class="hitList">
                    <span class="pullLeft pull fa fa-chevron-circle-left" title="zum Anfang der Trefferliste"></span>
                    <a class="hits first{if ($startRecord &lt;= $maximumRecords) then ' here' else ''}" 
                       href="#?startRecord=1" title="Treffer 1–{if ($nOfRec > $maximumRecords) then $maximumRecords else $nOfRec}">1</a>
                    <span class="fenster">
                        <span class="hitRow">
                            <xsl:for-each select="2 to $lastPage - 1">
                                <a class="hits{if ($startRecord >= ((. - 1) * $maximumRecords + 1) 
                                               and $startRecord &lt;= ((. - 1) * $maximumRecords + $maximumRecords)) 
                                                   then ' here' else ''}" 
                                    href="#?startRecord={((. - 1) * $maximumRecords) + 1}" 
                                    title="Treffer {(. - 1) * $maximumRecords + 1}–{(. - 1) * $maximumRecords + $maximumRecords}"
                                ><xsl:value-of select="."/></a>
                            </xsl:for-each>
                        </span>  
                    </span> 
                    <a class="hits last {if ($startRecord &gt;= (($lastPage - 1) * $maximumRecords + 1)) then 'here' else ''}" 
                       href="#?startRecord={(($lastPage - 1) * $maximumRecords) + 1}" title="Treffer {($lastPage - 1) * $maximumRecords + 1}–{$nOfRec}">
                        <xsl:value-of select="$lastPage"/>
                    </a>
                    <span class="pullRight pull fa fa-chevron-circle-right" title="zum Ende der Trefferliste"></span>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="hitList">
                    <span class="fenster">
                        <span class="hitRow"/>
                    </span>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>    
    
    <xd:doc>
        <xd:desc> 
            
            RECORDS (.search-result) 
                
        </xd:desc>
    </xd:doc>
    <xsl:template match="sru:records">
        <ol data-numberOfRecords="{/sru:searchRetrieveResponse/sru:numberOfRecords}" 
            data-nextRecordPosition="{sru:searchRetrieveResponse/sru:nextRecordPosition}" 
            class="results">
            <xsl:apply-templates select="*"/>
        </ol>
    </xsl:template>    
    
    
    <xd:doc>
        <xd:desc> Einzeleintrag, container (li) </xd:desc>
    </xd:doc>
    <xsl:template match="sru:record">
        <xsl:variable name="genre" select="sru:recordData//mods:genre[1]/lower-case(.)"/>
        <xsl:variable name="skip" select="sru:recordData//mods:topic[contains(., 'skip')]"/>
        <li value="{sru:recordNumber}" > 
                <xsl:attribute name="class"> 
                   <!-- "skip" kennzeichnet Treffer, die irgendwann einmal ganz entfernt werden sollten -->
                    <xsl:value-of select="normalize-space('pubForm '||$genre||' '||$skip)"/>
                </xsl:attribute>     
           <xsl:apply-templates select="sru:recordData/mods:mods"/>
        </li> 
    </xsl:template>  
    
    <!-- VARIABLE -->
    
    <!-- Rollen der Beteilgten; s.a. dict-de.html -->
    <xsl:variable name="acceptedRoles" select="'aut', 'edt', 'trl', 'ctb', 'com', 'ill', 'pht', 'red', 'win', 'hnr'"/>
    
    <!-- regex-pattern: mögliche alphab. Werte -->
    <xsl:variable name="letter" select="'\wäüößâāôōûū'"/>
    
    <!-- regex-pattern: Schluss-Space nach abc und Punkt --> 
    <xsl:variable name="optionalSpace">[<xsl:value-of select="$letter"/>\.]$</xsl:variable>
    
    <!-- regex-pattern: Schlusspunkt nach abc und Anf.zeichen -->
    <xsl:variable name="optionalPeriod">[<xsl:value-of select="$letter"/>"'\)]$</xsl:variable>
  
          
    <!-- MAIN RECORD TEMPLATE -->
          
    <xd:doc>
        <xd:desc>Einzeleintrag, Inhalt (.shortInfo) </xd:desc>
    </xd:doc>
    <xsl:template match="mods:mods">
        <div class="shortInfo">
            
            <!-- Einzeleintrag, Kurzinformation: Name -->  
            <xsl:apply-templates select="mods:name">
                <xsl:with-param name="roleTerm" select="'aut', 'edt', 'trl', 'ctb', 'red', 'com'"/>
                <xsl:with-param name="query" select="false()"/>
                <xsl:with-param name="description" select="false()"/>
            </xsl:apply-templates>      
            <xsl:call-template name="no-author"/>            
            <xsl:text xml:space="preserve">, </xsl:text> 
            
            <!--  Einzeleintrag, Kurzinformation, Jahr  -->
            <span class="year"> 
                <xsl:apply-templates select="
                    if (mods:originInfo/mods:dateIssued) 
                    then mods:originInfo/mods:dateIssued
                    else mods:relatedItem[@type='host']/mods:originInfo/mods:dateIssued" />
                <xsl:call-template name="no-year"/>
            </span>
            <xsl:text xml:space="preserve"> </xsl:text>
            
            <!--  Einzeleintrag, Kurzinformation, Titel -->
            <a href="#" class="plusMinus titel" title="Details anzeigen/verbergen">
                <xsl:apply-templates select="mods:titleInfo"/> 
            </a>
        </div>
        
        <!--  Einzeleintrag, Details -->
        <div class="showEntry" style="display:none;"> 
            <div class='closeX'>
                <span class="genre">
                    <xsl:value-of select="mods:genre[1]/lower-case(.)"/>
                </span>
            </div>
            <div class="record-html">
                <ul>
                    <!-- Autor --> 
                    <xsl:if test="mods:name/mods:role/mods:roleTerm[. = $acceptedRoles]"> 
                        <li class="eSegment">
                            <xsl:value-of select="_:dict('aut')"/>:
                        </li>  
                        <li> 
                            <xsl:apply-templates select="mods:name">
                                <xsl:with-param name="addAlias" select="true()"/>
                                <xsl:with-param name="nameBreak"><br/></xsl:with-param>
                            </xsl:apply-templates>
                            <xsl:call-template name="no-author"/> 
                        </li>
                    </xsl:if>
                    <!-- Titel -->
                    <li class="eSegment">
                        <xsl:value-of select="_:dict('title')"/>:
                    </li>
                    <li> 
                        <xsl:apply-templates select="mods:titleInfo"/>  
                    </li>
                    <!-- Ort, etc bzw. @host-->
                    <xsl:choose>
                        <xsl:when test="mods:originInfo">                            
                            <li class="eSegment">
                                Erschienen:
                            </li>
                            <li>                                
                                <xsl:apply-templates select="mods:originInfo"/> 
                            </li>
                        </xsl:when>
                        <xsl:when test="mods:relatedItem[@type eq 'host']">  
                            <li class="eSegment">Erschienen in:</li>                                
                            <li>                                 
                                <xsl:apply-templates select="mods:relatedItem[@type eq 'host']" /> 
                            </li>
                        </xsl:when>
                    </xsl:choose>                     
                </ul>
                <div class="addInfo">
                    
                    <!-- Weitere bibl. Angaben -->  
                    
                    <xsl:if test="mods:physicalDescription
                        | mods:relatedItem[not(@type = 'host')]
                        | mods:subject[mods:topic = 'Form']
                        | mods:note[@type eq 'footnotes']
                        ">
                        <h4>Weitere bibliographische Angaben</h4>
                        <ul>
                            <xsl:apply-templates select="mods:relatedItem[not(@type = 'host')]"  /> 
                            <xsl:call-template name="primary-subjects">
                                <xsl:with-param name="topic" select="'Form'" />
                            </xsl:call-template>       
                            <xsl:apply-templates select="mods:physicalDescription" />
                            <xsl:apply-templates select="mods:note[@type eq 'footnotes']" />
                        </ul>
                    </xsl:if> 
                    
                    <!-- Weitere inhaltl. Angaben -->  
                    
                    <xsl:if test="mods:subject[(mods:topic[matches(., '^(Thema|Zeit|Region)$')]) 
                        or @displayLabel = 'Stichworte']">
                        <h4>Inhaltliche Angaben</h4>
                        <ul> 
                            <xsl:call-template name="primary-subjects">
                                <xsl:with-param name="topic" select="'Thema'" />
                            </xsl:call-template>
                            <xsl:call-template name="primary-subjects">
                                <xsl:with-param name="topic" select="'Zeit'" />
                            </xsl:call-template>
                            <xsl:call-template name="primary-subjects">
                                <xsl:with-param name="topic" select="'Region'" />
                            </xsl:call-template>    
                            <xsl:call-template name="Stichwort"/>
                        </ul>  
                    </xsl:if>
                    
                    <!-- Links zu anderen Suchmaschinen -->
                           
                    <xsl:if test="mods:genre[matches(., '^[Bb]ook$')]"> 
                        <xsl:variable name="title4externalQuery" select="mods:titleInfo/mods:title" />
                        <xsl:variable name="author4externalQuery" select="mods:name/mods:namePart" />
                        <h4>Externe Suche</h4>
                        <ul>   
                            <li>
                                <a class="externerLink" title="Bibliothekssuche im Karlsruher Virtueller Katalog" target="kvk"
                                    href="http://kvk.bibliothek.kit.edu/?kataloge=SWB&amp;kataloge=BVB&amp;kataloge=NRW&amp;kataloge=HEBIS&amp;kataloge=HEBIS_RETRO&amp;kataloge=KOBV_SOLR&amp;kataloge=GBV&amp;kataloge=DDB&amp;kataloge=STABI_BERLIN&amp;OESTERREICH=&amp;kataloge=BIBOPAC&amp;kataloge=LBOE&amp;kataloge=OENB&amp;SCHWEIZ=&amp;kataloge=SWISSBIB&amp;kataloge=HELVETICAT&amp;kataloge=BASEL&amp;kataloge=ETH&amp;kataloge=VKCH_RERO&amp;digitalOnly=0&amp;embedFulltitle=0&amp;newTab=1&amp;TI={$title4externalQuery}&amp;AU={$author4externalQuery}&amp;autosubmit=true" > 
                                    Karlsruher Virtueller Katalog
                                </a>
                            </li>  
                            <!-- https://scholar.google.com/scholar?q={$title4externalQuery} -->
                        </ul>
                    </xsl:if> 
                </div>
            </div>
            <div class="toggleRecord">
                <i class="fa fa-code mods" title="Aktuellen Code anzeigen"></i>
            </div> 
            <div class="record-mods" style="display:none;">
                <div class="showOptions"> Aktueller Code
                    <div class="tipp" title="Tipp">
                        <span class="display" style="display: none;">
                            Derzeitige Form des Datensatzes als XML Dokument, nach MODS-Standard (<a class="externalLink" href=
                            'http://www.loc.gov/standards/mods/'>Library of Congress</a>).
                        </span>
                    </div>                        
                </div> 
                <xsl:variable name="modsDoc">
                    <xsl:copy-of select="." copy-namespaces="no"/>               
                </xsl:variable>
                <textarea rows="20" cols="80" class="codemirror-data" xml:space="preserve"><xsl:sequence select="_:serialize($modsDoc, $modsDoc//LIDOS-Dokument, $serialization-parameters/*)"/></textarea>
            </div> 
            <div class="toggleRecord">
                <i class="fa fa-code lidos" title="Ursprünglichen Code anzeigen"></i>
            </div> 
            <div class="record-lidos" style="display: none;">
                <div class="showOptions">Ursprünglicher Code 
                    <div class="tipp" title="Tipp">
                        <span class="display" style="display: none;">
                            Ursprüngliche Form des Datensatzes im Datenbankprogramm LIDOS, als XML-Dokument. 
                        </span>
                    </div>
                </div>       
                <xsl:variable name="lidosDoc">
                    <xsl:copy-of select=".//LIDOS-Dokument" copy-namespaces="no"/>               
                </xsl:variable>
                <textarea rows="20" cols="80" class="codemirror-data" xml:space="preserve"><xsl:sequence select="serialize($lidosDoc, $serialization-parameters/*)"/></textarea>
            </div> 
        </div>
    </xsl:template>
    
    <!-- Templates für Detailangaben --> 
    
    <!-- NAME -->
    
    <xd:doc>
        <xd:desc>Autor: name formatieren</xd:desc>
        <xd:param name="roleTerm"/>
        <xd:param name="query"/>
        <xd:param name="description"/>
        <xd:param name="addAlias"/>
        <xd:param name="nameBreak"/>
    </xd:doc>
    <xsl:template match="mods:name" >
        <xsl:param name="roleTerm" select="$acceptedRoles"/>
        <xsl:param name="query" select="true()"/> 
        <xsl:param name="description" select="true()"/>
        <xsl:param name="nameBreak" select="'/ '"/>
        <xsl:param name="addAlias" select="false()"/>
        <xsl:if test="mods:namePart 
            and mods:role/mods:roleTerm/normalize-space(.) = $roleTerm">
            <xsl:choose>
                <xsl:when test="$query">                    
                    <xsl:call-template name="add-query-link"> 
                        <xsl:with-param name="index" select="'author'"/> 
                        <xsl:with-param name="selection" select="mods:namePart" />
                    </xsl:call-template>   
                </xsl:when>
                <xsl:otherwise>                    
                    <xsl:apply-templates select="mods:namePart" />
                </xsl:otherwise>
            </xsl:choose>  
            <xsl:if test="mods:role/mods:roleTerm[not(. = 'aut')]">
                <xsl:for-each select="mods:role/mods:roleTerm[not(. = 'aut')]">  
                    <xsl:value-of select="if (position() eq 1) then ' (' else ''"/>                  
                    <xsl:value-of select="_:dict(.)"/>           
                    <xsl:value-of select="if (position() ne last()) then ', ' else ')'"/>
                </xsl:for-each> 
            </xsl:if>
            <xsl:if test="$addAlias=true()">
                <xsl:call-template name="alias"/>
            </xsl:if>
            <xsl:if test="following-sibling::mods:name[1][mods:namePart]
                /mods:role/mods:roleTerm/normalize-space(.) = $roleTerm">
                <xsl:copy-of select="$nameBreak"/> 
            </xsl:if>
        </xsl:if>
        <xsl:if test="mods:etal">
            <xsl:value-of select="_:dict(' et al.')"/>
        </xsl:if>   
    </xsl:template>
    
    <xd:doc>
        <xd:desc>name/description vorläufig nicht anzeigen</xd:desc>
    </xd:doc>
    <xsl:template match="mods:description">
        <xsl:value-of select="''"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Suche nach alias Namen in dict-de.xml</xd:desc>
    </xd:doc>
    <xsl:template name="alias">
        <xsl:variable name="aka">
            <xsl:choose>
                <xsl:when test="normalize-space(mods:namePart) ne _:dict(normalize-space(mods:namePart))">
                    <xsl:value-of select="_:dict(normalize-space(mods:namePart))"/>
                </xsl:when>
                <xsl:when test="normalize-space(mods:namePart) ne _:rdict(normalize-space(mods:namePart))">
                    <xsl:value-of select="_:rdict(normalize-space(mods:namePart))"/>
                </xsl:when> 
            </xsl:choose> 
        </xsl:variable>
        <xsl:if test="$aka ne ''">
            <small>
                <xsl:value-of select="' ('"/>
                <i>al.</i>
                <xsl:value-of select="' '"/>
                <xsl:call-template name="add-query-link">  
                    <xsl:with-param name="text" select="$aka" />
                </xsl:call-template>
                <xsl:value-of select="')'"/>
            </small>
        </xsl:if>
    </xsl:template>
     
    <xd:doc>
        <xd:desc>Falls kein gültiger Autor</xd:desc> 
        <xd:param name="roleTerm"/>
    </xd:doc>
    <xsl:template name="no-author">
        <xsl:param name="roleTerm" select="$acceptedRoles"/> 
        <xsl:if test="not(mods:name/mods:role/mods:roleTerm/normalize-space(.)= $roleTerm)"> 
            <xsl:value-of select="_:dict('no-aut-abbr')" />
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Elemente mit query-link ausstatten</xd:desc> 
        <xd:param name="index"/> 
        <xd:param name="selection"/>
        <xd:param name="text"/>
    </xd:doc>
    <xsl:template name="add-query-link">  
        <xsl:param name="index" />   
        <xsl:param name="selection" select="node()"/>  
        <xsl:param name="text"/>  
        <!-- entfernt <b> im Fall von _match_ -->
        <xsl:variable name="term">   
            <xsl:choose>
                <xsl:when test="$text eq ''">
                    <xsl:apply-templates select="$selection"/>                    
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$text"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>  
        
        <xsl:if test="$selection">
            <xsl:choose>
                <xsl:when test="$index">  
                    <xsl:sequence select="$term"/>
                    <a href="#find?query={$index||'='}&quot;{$term}&quot;" 
                        title="{_:dict($index)||'-'}Suche nach {$term}"
                        class="lupe fas fa-search">
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <a href="#find?query=&quot;{$term}&quot;" 
                        title="Suche nach {$term}" >  
                        <xsl:sequence select="$term"/>
                    </a>                
                </xsl:otherwise>
            </xsl:choose> 
        </xsl:if>
    </xsl:template>  
    
    <!-- DATUM -->
    
    <xd:doc>
        <xd:desc>Datum formatieren</xd:desc>
        <xd:param name="substring"/>
        <xd:param name="date"/>
    </xd:doc>    
    <xsl:template match="mods:dateIssued">
        <xsl:param name="substring" select="4"/>
        <xsl:param name="date">
            <xsl:apply-templates/>
        </xsl:param> 
            <!-- zweite Jahresangabe ausschließen -->
            <xsl:value-of select="if (position() = 1) 
                then $date[1]/substring(., 1, $substring) 
                else ''"/>     
    </xsl:template>   
    
    <xd:doc>
        <xd:desc>Datum formatieren</xd:desc>
    </xd:doc>    
    <xsl:template match="mods:dateIssued[@point eq 'start']">  
        <xsl:value-of select=". || '–' || following-sibling::mods:dateIssued[@point='end']" />          
    </xsl:template>   
    
    <xd:doc>
        <xd:desc>YYYYMMDD</xd:desc>
    </xd:doc>
    <xsl:template match="mods:dateIssued[@encoding = 'iso8601']">
        <xsl:value-of select="./substring(., 1, 4)"/>
        <xsl:if test="./substring(., 5)"><xsl:value-of select="'-'||./substring(., 5,2)"/></xsl:if>
        <xsl:if test="./substring(., 7)"><xsl:value-of select="'-'||./substring(., 7,2)"/></xsl:if>  
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Kein Datum</xd:desc>
    </xd:doc>
    <xsl:template name="no-year">
        <xsl:if test="not(//mods:dateIssued)">  
            <xsl:value-of select="_:dict('no-year-abbr')"/>     
        </xsl:if>
    </xsl:template> 
    
    <!-- TITLE -->
        
    <xd:doc>
        <xd:desc>
            Titel formatieren: Schlusspunkt und -space mit Regex ermitteln;
            apply-templates nötig für _match_
        </xd:desc>
    </xd:doc>
    <xsl:template match="mods:titleInfo"> 
        <xsl:variable name="nonSort" >
            <xsl:apply-templates select="mods:nonSort"/>
            <xsl:value-of select="if (mods:nonSort[matches(., $optionalSpace)]) then ' ' else ''"/>
        </xsl:variable> 
        <xsl:variable name="subTitle">
            <xsl:apply-templates select="mods:subTitle"/>
        </xsl:variable> 
        <xsl:variable name="titleClass" select="if
            (following-sibling::mods:originInfo or parent::mods:relatedItem)
            then 'bookTitle' else 'articleTitle'"/> 
        <span class="{$titleClass}">
            <xsl:value-of select="$nonSort"/> 
            <xsl:apply-templates select="mods:title"/>
            <xsl:value-of select="if 
                (mods:title[matches (., $optionalPeriod)] and mods:subTitle) 
                then '. ' 
                else if (mods:subTitle) then ' ' else ''"/> 
            <xsl:sequence select="upper-case(substring($subTitle,1,1)) 
                || substring($subTitle, 2)"/>
        </span> 
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Titel mit query-link</xd:desc>
    </xd:doc>
    <xsl:template match="mods:titleInfo" mode="link"> 
        <xsl:call-template name="add-query-link">
            <xsl:with-param name="selection" select="self::*"/>
        </xsl:call-template> 
    </xsl:template>
    
    <!-- Ort, Verlag, Jahr  -->
    
    <xd:doc>
        <xd:desc>Details zu Ort, etc. für Buch </xd:desc>
    </xd:doc>
    <xsl:template match="mods:originInfo"> 
        <xsl:apply-templates select="mods:place/mods:placeTerm"/>
        <xsl:value-of select="if (mods:place/mods:placeTerm and mods:publisher) then ': ' else ''"/>
        <xsl:call-template name="add-query-link">
            <xsl:with-param name="index" select="'publisher'"/> 
            <xsl:with-param name="selection" select="mods:publisher"/> 
        </xsl:call-template>     
        <xsl:value-of select="if (mods:place/mods:placeTerm or mods:publisher) then ', ' else ''"/> 
        <xsl:apply-templates select="mods:dateIssued" >
            <xsl:with-param name="substring" select="10"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="mods:dateOther" />
        <xsl:apply-templates select="mods:edition" />
    </xsl:template> 
    
    <xd:doc>
        <xd:desc>Anm. zur Veröffentlichung</xd:desc>
    </xd:doc>
    <xsl:template match="mods:edition">
        <xsl:value-of select="' (' || . ||')'"/>
    </xsl:template> 
    
    <xd:doc>
        <xd:desc>Anm. zum Datum</xd:desc>
    </xd:doc>
    <xsl:template match="mods:dateOther">
        <xsl:value-of select="' [' || . ||']'"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Zeitschriftenartikel, Details zusammenstellen</xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type='host']
        [ancestor::mods:mods/mods:genre[matches(., '(journal|newspaper)Article')] or
        ancestor::mods:mods/mods:subject[matches(., '(Zeitschriften|Zeitungs)artikel')]]" 
        priority="1">
        <xsl:variable name="edition" select="mods:originInfo/mods:edition"/> 
        <xsl:variable name="volume" select="mods:part/mods:detail[@type eq 'volume']"/>         
        <xsl:variable name="date">
            <xsl:apply-templates select="mods:originInfo/mods:dateIssued">
                <xsl:with-param name="substring" select="10"/>                    
            </xsl:apply-templates>
        </xsl:variable>
        <!-- Titel -->
        <xsl:apply-templates select="mods:titleInfo" mode="link"/>
        <xsl:value-of select="' '"/> 
        <!-- Jahrgang und Jahr übereinstimmen -->
        <xsl:choose>
            <xsl:when test="$edition">
                <xsl:value-of select="$edition"/>
                <xsl:if test="mods:edition and mods:edition/not(matches(., $date))">
                    <xsl:value-of select="' ['|| $date|| ']'"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$volume">
                <xsl:value-of select="$volume"/> 
                <xsl:if test="$volume and $volume/not(matches(., $date))">
                    <xsl:value-of select="' ('|| $date|| ')'"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$date"/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- Ausgabennummer -->      
        <xsl:value-of select="if (mods:part/mods:detail[@type eq 'issue'])
            then '/'||mods:part/mods:detail[@type eq 'issue'] || ''
            else ''"/>        
        <xsl:value-of select="if (mods:part/mods:extent[@unit eq 'page'])
            then ', ' else ''"/>
        <xsl:apply-templates select="mods:part/mods:extent[@unit eq 'page']"/> 
    </xsl:template> 
    
    <xd:doc>
        <xd:desc>Jg., Bd.</xd:desc>
    </xd:doc>
    <xsl:template match="mods:detail">
        <xsl:value-of select="mods:number"/>
        <xsl:value-of select="if(following-sibling::mods:detail
            or parent::mods:part/following-sibling::mods:part/mods:detail) then '/' else ' '"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Seite-Seite</xd:desc>
    </xd:doc>
    <xsl:template match="mods:extent[@unit eq 'page']">
        <xsl:choose>
            <xsl:when test="mods:start">
                <xsl:value-of select="_:dict('pages')||' '
                    ||string-join((mods:start, mods:end), '–')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="_:dict('pages')|| ' ' || ."/>
            </xsl:otherwise>
        </xsl:choose>  
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Seitenangaben für das ganze Werk</xd:desc>
    </xd:doc>
    <xsl:template match="mods:extent[parent::mods:physicalDescription]">
        <xsl:value-of select=".||' '||_:dict('pages')"/>
        <xsl:value-of select="if (position() ne last()) then '; ' else ''"/> 
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Band und Seiten </xd:desc>
    </xd:doc>
    <xsl:template match="mods:part">
        <xsl:apply-templates select="mods:detail"/>
        <xsl:apply-templates select="mods:extent"/> 
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>Buchbeiträge, Details zusammenstellen</xd:desc>
    </xd:doc>
    <!--  [ancestor::mods:mods/mods:genre[matches(., 'bookSection')]] -->
    <xsl:template match="mods:relatedItem[@type eq 'host']"  >
        <xsl:apply-templates select="mods:name" />    
        <xsl:value-of select="if (position() ne 1) then ', ' else ''"/> 
        <xsl:apply-templates select="mods:titleInfo" mode="link"/> 
        <xsl:if test="mods:originInfo">
            <xsl:value-of select="', '"/> 
            <xsl:apply-templates select="mods:originInfo"/>
        </xsl:if>
        <xsl:if test="mods:part">
            <xsl:value-of select="', '"/> 
            <xsl:apply-templates select="mods:part"/>
        </xsl:if>
        <xsl:if test="mods:relatedItem">  
            <xsl:value-of select="', '"/>                
            <xsl:apply-templates select="mods:relatedItem"/>
        </xsl:if> 
    </xsl:template>
    
    <!-- "Weitere bibliographische Angaben"   -->
    
    <xd:doc>
        <xd:desc>Serien zusammenstellen</xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type eq 'series']">
        <li class="eSegment">
            <xsl:value-of select="_:dict('series')"/>:
        </li>
        <li>
            <xsl:apply-templates select="mods:titleInfo" mode="link"/>
            <xsl:apply-templates  select="node() except mods:titleInfo"/>
        </li>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Serie als Teil von host</xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type eq 'series'][parent::mods:relatedItem]">
        (<xsl:apply-templates/>)
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Details, Kollationsvermerk (Sammeltemplate)</xd:desc>
    </xd:doc>
    <xsl:template match="mods:physicalDescription">
        <li class="eSegment">Kollation:</li>
        <li>            
            <xsl:apply-templates/>
            <xsl:value-of select="if (position() ne last()) then '; ' else ''"/> 
        </li>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Sonstige Details</xd:desc>
    </xd:doc>
    <xsl:template match="mods:note"> 
        <xsl:value-of select="."/>
    </xsl:template>    
   
    <xd:doc>
        <xd:desc>Angabe zur Originalversion, etc. </xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type[matches(., 'original|reviewOf|otherVersion')]]" >
        <li class="eSegment"><xsl:value-of select="_:dict(@type)"/>:</li>
        <li>
            <xsl:if test="mods:name">                
                <xsl:apply-templates select="mods:name"/>
                <xsl:value-of select="', '"/> 
            </xsl:if>
            <xsl:apply-templates select="mods:titleInfo"/>
            <xsl:if test="mods:originInfo"> 
                <xsl:value-of select="', '"/>                
                <xsl:apply-templates select="mods:originInfo"/>
            </xsl:if> 
            <xsl:if test="mods:relatedItem"> 
                <xsl:value-of select="', '"/>                
                <xsl:apply-templates select="mods:relatedItem"/>
            </xsl:if> 
        </li>
    </xsl:template>      
    
    <xd:doc>
        <xd:desc>Fußnoten</xd:desc>
    </xd:doc> 
    <xsl:template match="mods:note[@type eq 'footnotes']">        
        <li class="eSegment">Bemerkungen:</li>
        <li><xsl:value-of select="."/></li>        
    </xsl:template>
    
    <!-- "Weitere inhaltl. Angaben"  -->
    <xd:doc>
        <xd:desc>Thesaurus-Schlagworte, Rahmen</xd:desc>
        <xd:param name="topic"/>
    </xd:doc>
   <xsl:template name="primary-subjects">
        <xsl:param name="topic"  as="xs:string" /> 
        <xsl:if test="mods:subject[@usage = 'primary']
            [following-sibling::mods:subject[@usage = 'secondary'][mods:topic[. = $topic]]]">            
            <li class="eSegment">
                <xsl:value-of select="$topic"/>:
            </li>
            <xsl:for-each select="mods:subject[@usage = 'primary']
                [following-sibling::mods:subject[@usage = 'secondary'][1][mods:topic[. = $topic]]]">
                <li>                 
                    <xsl:for-each select="following-sibling::mods:subject
                        [@usage = 'secondary'][1]/mods:topic[position() gt 1]">
                        <small>
                            <xsl:apply-templates select="."/><i class="fas fa-angle-right"></i>
                        </small>
                    </xsl:for-each>
                    <xsl:apply-templates/>
                </li>
            </xsl:for-each>            
        </xsl:if>
    </xsl:template> 
    
    <xd:doc>
        <xd:desc>Thesaurus-Schlagworte</xd:desc>
    </xd:doc>
    <xsl:template match="mods:topic[parent::*[@usage]]"> 
             <xsl:call-template name="add-query-link">
                 <xsl:with-param name="index" select="'subject'"/>  
             </xsl:call-template> 
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Rahmen für Stichworte</xd:desc>
    </xd:doc>
    <xsl:template name="Stichwort">
        <xsl:if test="mods:subject[@displayLabel = 'Stichworte']">
            <li class="eSegment">Stichworte:</li>
            <li> 
                <xsl:apply-templates select="mods:subject[@displayLabel = 'Stichworte']"/> 
            </li>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc> Stichworte </xd:desc>
    </xd:doc>
    <xsl:template match="mods:subject[@displayLabel='Stichworte']"> 
        <xsl:call-template name="add-query-link" />           
        <xsl:value-of select="if (position() ne last()) then '; ' else ''"/> 
    </xsl:template> 
    
    <!-- Taxonomy -->
   
    <xd:doc>
        <xd:desc>Filterbaum auf #find, Container</xd:desc>
    </xd:doc>
    <xsl:template match="taxonomy">
        <xsl:variable name="nOfRec" as="xs:integer" select="/sru:searchRetrieveResponse/sru:numberOfRecords"/>
        <ol class="schlagworte showResults">
            <xsl:choose>
                <xsl:when test="$nOfRec gt 9">
                    <xsl:apply-templates select="*"/>
                </xsl:when>
                <xsl:otherwise>
                </xsl:otherwise>
            </xsl:choose>
        </ol>
    </xsl:template> 
    
    <xd:doc>
        <xd:desc>Oberste Ebene (Thema, etc.)</xd:desc>
        <xd:param name="base-path"/>
    </xd:doc>
    <xsl:template match="category[matches(@n, '^[123456789]$')]">
        <xsl:param name="base-path" tunnel="yes">#</xsl:param>
        <li class="li1">
            <span>
                <xsl:value-of select="catDesc"/>
            </span>
            <ol><xsl:apply-templates select="category"/></ol>           
        </li>
    </xsl:template> 
    
    <xd:doc>
        <xd:desc>Standard-Element (li) mit link</xd:desc>
    </xd:doc>
    <xsl:template match="category">
        <li> 
            <span class="wrapTerm"> 
                <span class="term {if (category) then 'plusMinus' else ''}"
                title="{if (category) then 'Unterschlagworte zeigen/ verbergen' else ''}">
                    <xsl:value-of select="catDesc"/>
                </span>
                <a href="#find?query=subject%3D&quot;{catDesc}&quot;" class="zahl aFilter" title="Suche filtern">
                    <xsl:value-of select="numberOfRecords"/>
                </a> 
            </span>
            <xsl:if test="category">
                <ol style="display:none;">
                    <xsl:apply-templates select="category"/>
                </ol>
            </xsl:if>
        </li>
    </xsl:template> 
    
    <!-- _match_ -->
    
    <xd:doc>
        <xd:desc>_match_ formatieren</xd:desc>
    </xd:doc>
    <xsl:template match="mods:_match_"> 
        <b><xsl:value-of select="."/></b> 
        <!-- _match_ schluckt Spaces, daher: 
            wenn der folgende Textknoten mit Buchstaben beginnt, dann Space -->
        <xsl:value-of select="if (  
            following-sibling::node()[1][matches(., '^['||$letter||']')] 
            )
            then ' ' else ''"/> 
    </xsl:template>  
  
</xsl:stylesheet>