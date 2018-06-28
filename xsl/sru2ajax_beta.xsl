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
    
    <xd:doc><xd:desc>
        Erstelle .ajax-result = provisorischer Container für Elemente, 
        die von js gegen alte Elemente ausgetauscht werden 
    </xd:desc></xd:doc>
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
    
    <xd:doc><xd:desc>
        Erstelle Navigationszeile (.navResults)
    </xd:desc></xd:doc>
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
                       href="#?startRecord={(($lastPage - 1) * $maximumRecords) + 1}" title="Treffer {($lastPage - 1) * $maximumRecords + 1}–{$nOfRec}"
                    ><xsl:value-of select="$lastPage"/></a>
                    <span class="pullRight pull fa fa-chevron-circle-right" title="zum Ende der Trefferliste"></span>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="hitList"><span class="fenster"><span class="hitRow"/></span></div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc> Ergebnisliste (.search-result) </xd:desc>
    </xd:doc>
    <xsl:template match="sru:records">
        <ol data-numberOfRecords="{/sru:searchRetrieveResponse/sru:numberOfRecords}" data-nextRecordPosition="{sru:searchRetrieveResponse/sru:nextRecordPosition}" class="results"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc> Einzeleintrag, container (li) </xd:desc>
    </xd:doc>
    <xsl:template match="sru:record">
        <li value="{sru:recordNumber}" >
            <xsl:if test="sru:recordData//mods:genre">
               <!-- gernre als class einsetzen, bs -->
               <xsl:variable name="genre" select="sru:recordData//mods:genre[1]/lower-case(.)"></xsl:variable>
               <xsl:attribute name="class"> 
                  <xsl:value-of select="concat('pubForm ', $genre)"/>
               </xsl:attribute>   
            </xsl:if>
           <xsl:apply-templates select="sru:recordData/mods:mods"/>
        </li> 
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Einzeleintrag, Inhalt (.shortInfo) </xd:desc>
    </xd:doc>
    <xsl:template match="mods:mods">
        <div class="shortInfo">
        <!-- Einzeleintrag, Kurzinformation: Name --> 
              <xsl:choose>
                  <xsl:when test="./mods:name[mods:role/mods:roleTerm/normalize-space(.) = ('aut', 'edt', 'trl', 'ctb')] "> 
                      <xsl:for-each select="./mods:name
                          [mods:role/mods:roleTerm/normalize-space(.)= ('aut', 'edt', 'trl', 'ctb')]
                          /mods:namePart
                          ">  
                          <xsl:value-of select="." /><xsl:value-of select="if (position() ne last()) then '/ ' else ''"/>
                      </xsl:for-each> 
                  </xsl:when>
                  <xsl:otherwise>                      
                      <xsl:value-of select="_:dict('no-aut-abbr')"/> 
                  </xsl:otherwise>
              </xsl:choose> 
            <xsl:text xml:space="preserve">, </xsl:text> 
            <!--  Einzeleintrag, Kurzinformation, Jahr  -->
            <span class="year">
            <xsl:choose>
                <xsl:when test="mods:originInfo/mods:dateIssued|
                                mods:relatedItem[@type='host']/mods:originInfo/mods:dateIssued"> 
                    <xsl:for-each select="mods:originInfo/mods:dateIssued|
                        mods:relatedItem[@type='host']/mods:originInfo/mods:dateIssued">                         
                        <xsl:value-of select=".[1]/substring(., 1, 4)"/>  
                        <xsl:if test=".[@point eq 'start']"><xsl:text>–</xsl:text></xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>            
                    <xsl:value-of select="_:dict('no-year-abbr')"/>         
                </xsl:otherwise>
            </xsl:choose>
            </span>
            <!--  Einzeleintrag, Kurzinformation, Titel -->
            <xsl:text xml:space="preserve"> </xsl:text>
            <span class="plusMinus titel" title="Details anzeigen/verbergen"><xsl:apply-templates select="mods:titleInfo"/></span>
        </div>
        <xsl:apply-templates select="." mode="detail"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Einzeleintrag (mode:detail), spez. Information (.showEntry .record-html)</xd:desc>
    </xd:doc>
    <xsl:template match="mods:mods" mode="detail">
        <div class="showEntry" style="display:none;"> 
            <div class='closeX'></div>
            <div class="record-html">
                <ul><xsl:call-template name="detail-list-items"/></ul>
                <div class="addInfo">
                    <xsl:if test="
                        //mods:relatedItem[@type eq 'series'] or
                        //mods:physicalDescription or
                        //mods:subject[topic eq 'Form'] or
                        //mods:note[@type eq 'footnotes']
                        "></xsl:if>
                <h4>Weitere bibliographische Angaben</h4>
                <ul><xsl:call-template name="more-detail-list-items"/></ul>                        
                     
                <h4>Inhaltliche Angaben</h4>
                <ul><xsl:call-template name="topics-list-items"/></ul> 
                    <xsl:call-template name="externeSuche"/>
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
    
    <xd:doc>
        <xd:desc>Einzeleintrag, primäre Details für Buch und Artikel : 
            Autor + Titel+ Ort etc</xd:desc>
    </xd:doc>
    <xsl:template name="detail-list-items">   
        <xsl:if test="mods:name/mods:namePart[not(./ancestor::mods:relatedItem/mods:name)]"><!-- nur wenn ein Autor gefunden wird-->
            <li class="eSegment"><xsl:value-of select="_:dict('aut')"/></li>
            <li>
                <xsl:for-each select="mods:name[mods:role/mods:roleTerm/normalize-space(.) = ('aut', 'edt', 'trl', 'ctb')][not(./ancestor::mods:relatedItem)]">
                   <xsl:apply-templates select="." mode="detail"/><xsl:value-of select="if (position() ne last()) then '/ ' else ''"/>
                </xsl:for-each>
            </li>
        </xsl:if>
        <xsl:apply-templates select="mods:titleInfo[not(./ancestor::mods:relatedItem)]" mode="detail"/>
        <xsl:apply-templates select="(./mods:relatedItem[@type eq 'host']/mods:originInfo, ./mods:originInfo)[1]" mode="detail"/> 
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Einzeleintrag, sek. bibliogr. Details: Reihe, Seiten, etc. </xd:desc>
    </xd:doc>
    <xsl:template name="more-detail-list-items">
        <xsl:apply-templates select="mods:physicalDescription" mode="more-detail"/>
        <xsl:apply-templates select="mods:relatedItem except mods:relatedItem[@type = 'host']" mode="more-detail"/>
        <!--
        <xsl:apply-templates select="mods:relatedItem[@type eq 'series']" mode="more-detail"/>
        <xsl:apply-templates select="mods:relatedItem[@type eq 'original']" mode="more-detail"/>
        <xsl:apply-templates select="mods:relatedItem[@type eq 'reviewOf']" mode="more-detail"/>
        <xsl:apply-templates select="mods:relatedItem[@type eq 'otherVersion']" mode="more-detail"/>
        -->
        <xsl:call-template name="primary-subjects"> 
            <xsl:with-param name="topic">Form</xsl:with-param> 
        </xsl:call-template>         
        <xsl:apply-templates select="mods:note[@type eq 'footnotes']" mode="more-detail"/>
    </xsl:template>
       
    <xd:doc>
        <xd:desc>Schlag- und Stichworte aufrufen</xd:desc>
    </xd:doc>
    <xsl:template name="topics-list-items">  
        <xsl:call-template name="primary-subjects">
            <xsl:with-param name="topic" select="'Thema'" />              
        </xsl:call-template> 
        <xsl:call-template name="primary-subjects">
            <xsl:with-param name="topic" select="'Zeit'" />              
        </xsl:call-template> 
        <xsl:call-template name="primary-subjects">
            <xsl:with-param name="topic" select="'Region'" />              
        </xsl:call-template>  
        <xsl:call-template name="keywords">
            <xsl:with-param name="keywords" select="mods:subject[@displayLabel eq 'Stichworte']"/>
        </xsl:call-template>        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Links zu anderen Suchmaschinen</xd:desc>
    </xd:doc>
    <xsl:template name="externeSuche" >        
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
    </xsl:template> 
    <!--  
    <xsl:template match="mods:name[mods:role/mods:roleTerm/normalize-space(.) = ('aut', 'edt', 'trl')][not(./ancestor::mods:relatedItem)]">
        <xsl:apply-templates select="(mods:namePart|mods:etal)"/>
    </xsl:template>
    -->
    
    <xd:doc>
        <xd:desc> Autor formatieren </xd:desc>
    </xd:doc>    
    <xsl:template match="mods:name">
        <xsl:choose>
            <xsl:when test="mods:name/mods:role/mods:roleTerm/normalize-space(.) = ('aut', 'edt', 'trl', 'ctb')">                
        <xsl:call-template name="link-with-number-of-records">
                <xsl:with-param name="index">author</xsl:with-param>
                <xsl:with-param name="term" select="mods:namePart"/>
                <xsl:with-param name="isLast" select="position() eq last()"/>
        </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="n.A."/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="if (mods:etal) then _:dict(' et al.') else ''"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Elemente mit query-link ausstatten</xd:desc> 
    </xd:doc>
    <xsl:template name="link-with-number-of-records">
        <xsl:param name="index" as="xs:string"/>
        <xsl:param name="term" as="node()*"/>
        <xsl:param name="separator" as="xs:string" select="' /'"/>
        <xsl:param name="isLast" as="xs:boolean" select="true()"/>
        <xsl:variable name="this" select="."/>
        <!-- Default role is aut -->
        <xsl:variable name="knownSpecialRoles" select="('edt', 'trl', 'ctb')"/>
        <xsl:for-each select="$term">
            <xsl:variable name="scanClause" select="$index||'=='||normalize-space(.)"/>
            <xsl:variable name="by-this-term" select="$this/root()//sru:scanResponse[.//sru:scanClause eq $scanClause]//sru:numberOfRecords"/>
            <xsl:variable name="roles" select="$this//mods:roleTerm!normalize-space(.)"/> 
            <xsl:choose>
                <xsl:when test="_:dict(.) eq .">
                    <xsl:apply-templates/>    
                </xsl:when>
                <xsl:when test="exists(./mods:_match_)">
                    <strong><xsl:value-of select="_:dict(.)||''"/></strong>
                </xsl:when>
                <xsl:otherwise>               
                    <xsl:value-of select="_:dict(.)||''"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="$roles = $knownSpecialRoles">
                <xsl:value-of select="' ('||string-join($roles[. = $knownSpecialRoles]!_:dict(.), '; ')||')'"/>
            </xsl:if>
            <a href="#?query={$index}=&quot;{.}&quot;" class="neueSuche fas fa-search" title="Suche nach {.}"><xsl:value-of select="$by-this-term"/></a>
            <xsl:if test="not($isLast)"><xsl:value-of select="$separator"/></xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Datum formatieren</xd:desc>
    </xd:doc>    
    <xsl:template name='full-Date'>
        <xsl:param name="pretext" as="xs:string"  xml:space="preserve" select="''"/>
        <xsl:value-of select="$pretext"/><span class="date">
            <xsl:for-each select="./mods:dateIssued">
            <xsl:choose>
                <xsl:when test=".[@encoding = 'iso8601']">                    
                    <xsl:value-of select="./substring(., 1, 4)"/>
                    <xsl:if test="./substring(., 5)"><xsl:value-of select="'-'||./substring(., 5,2)"/></xsl:if>
                    <xsl:if test="./substring(., 7)"><xsl:value-of select="'-'||./substring(., 7,2)"/></xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test=".[@point eq 'start']"><xsl:text>–</xsl:text></xsl:if>
        </xsl:for-each>  
        </span>
    </xsl:template>   
    
    <!-- TITLE -->
    
    <xd:doc>
        <xd:desc>Details: Titel</xd:desc>
    </xd:doc>
    <xsl:template match="mods:titleInfo" mode="detail">
        <li class="eSegment"><xsl:value-of select="_:dict('title')"/></li>
        <!-- <li><xsl:apply-templates mode='#default'/></li> -->
        <li><span class="title"><xsl:apply-templates select="*"/></span></li>
    </xsl:template>
    
    <xsl:variable name="sentenceNoPunctation">[\w"'\)]$</xsl:variable><!-- Punkt nur nach Buchstaben, " oder ' -->
    <xsl:variable name="canHaveSpace">[\w\.]$</xsl:variable> 
    
    <xd:doc>
        <xd:desc>Verbindung von nonSort mit Rest des Titels; Space nur nach Artikeln</xd:desc>
    </xd:doc>
    <xsl:template match="mods:nonSort">
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:value-of select="if (matches(normalize-space(.), $canHaveSpace)) then ' ' else ''"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Ende des Titels: Punkt nur nach (Buchstaben, ", ')</xd:desc>
    </xd:doc>
    <xsl:template match="mods:title">
        <xsl:apply-templates/>
        <xsl:value-of select="if (matches(normalize-space(.), $sentenceNoPunctation)) then '.' else ''"/>
    </xsl:template>
 
    <xd:doc>
        <xd:desc>Subtitle formatieren</xd:desc>
    </xd:doc>
    <xsl:template match="mods:subTitle">
        <xsl:text xml:space="preserve"> </xsl:text>
        <xsl:variable name="subTitle" select="normalize-space(.)" />
        <xsl:sequence select=  "concat(upper-case(substring($subTitle,1,1)), substring($subTitle, 2) )"/>
        <xsl:value-of select="if (matches(normalize-space(.), $sentenceNoPunctation)) then '.' else ''"/>
    </xsl:template>
    
    <!-- Ort, Verlag, ... -->
    
    <xd:doc>
        <xd:desc>Details zu Ort, etc. für Buch </xd:desc>
    </xd:doc>
    <xsl:template match="mods:originInfo[parent::mods:mods]" mode="detail">          
       <li class="eSegment"><xsl:value-of select="_:dict('place')||'/'||_:dict('publisher')||'/'||_:dict('year')"/></li>
        <li><xsl:value-of select="( if (mods:place/mods:placeTerm) 
               then mods:place/mods:placeTerm 
               else _:dict('no-place-abbr')
               )" /> 
            <xsl:value-of select="if (mods:publisher) then ': ' else ''"/>
            <xsl:call-template name="link-with-number-of-records">
                <xsl:with-param name="index">publisher</xsl:with-param>
                <xsl:with-param name="term" select="mods:publisher"/>
            </xsl:call-template>
            <!-- Datum -->
            <xsl:call-template name="full-Date" >
                <xsl:with-param name="pretext" select="', '" />
            </xsl:call-template> 
            <xsl:if test="./following-sibling::mods:relatedItem[@type='original']/mods:originInfo/mods:dateIssued"> 
                <xsl:value-of select="' [Orig. ' 
                    || ./following-sibling::mods:relatedItem[@type='original']/mods:originInfo/mods:dateIssued 
                    || ']' "/>
            </xsl:if>
         </li>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Zeitschriftenartikel, Details zusammenstellen</xd:desc>
    </xd:doc>
    <!--<xsl:template match="mods:originInfo[ancestor::mods:mods/mods:genre[matches(., 'journalArticle|newspaperArticle')] 
        and parent::mods:relatedItem[@type eq 'host']]" mode="detail" priority="1">-->
    <xsl:template match="mods:relatedItem[@type='host']/mods:originInfo[ancestor::mods:mods/mods:genre[matches(., 'journalArticle|newspaperArticle')]]">
        <li class="eSegment">In: </li>
        <li>
            <span class='journalTitle'><a href="#?query=title=&quot;{../mods:titleInfo/mods:title}&quot;" class="stichwort"><xsl:value-of select="../mods:titleInfo/mods:title"/><!--
                --><xsl:if test="../mods:titleInfo/mods:subTitle">
                    <xsl:value-of select="': ' ||../mods:titleInfo/mods:subTitle"/></xsl:if></a></span><!-- 
                --><xsl:value-of select="if (../mods:part/mods:detail[@type eq 'volume']) then ', '||_:dict('volumeJournal')
                ||' '
                ||../mods:part/mods:detail[@type eq 'volume']/mods:number else ''"/>
            <xsl:choose>
                <xsl:when test="mods:dateIssued and ../mods:part/mods:detail[@type eq 'volume']">
                    <xsl:call-template name="full-Date">
                        <xsl:with-param name="pretext" >/</xsl:with-param>
                    </xsl:call-template>
                </xsl:when> 
                <xsl:otherwise>
                    <xsl:call-template name="full-Date">
                        <xsl:with-param name="pretext" select="', '" />
                   </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="if (../mods:part/mods:detail[@type eq 'issue']) 
                then ', '||_:dict('issue')||' '||../mods:part/mods:detail[@type eq 'issue']/mods:number 
                else ''"/>
            <xsl:value-of select="if (../mods:part/mods:extent[@unit eq 'page']) 
                then ', '||_:dict('pages')||' '||string-join(../mods:part/mods:extent[@unit eq 'page']/(mods:start, mods:end), '–') 
                else ''"/>
        </li>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Buchbeiträge, Details zusammenstellen</xd:desc>
    </xd:doc>
    <xsl:template match="mods:originInfo[parent::mods:relatedItem[ancestor::mods:mods/mods:genre eq 'bookSection' and @type eq 'host']]" mode="detail">
        <li class="eSegment">In: </li>
        <li>
            <xsl:if test="../mods:name">
                <xsl:apply-templates select="../mods:name" /><xsl:value-of select="', '"/>
            </xsl:if> 
            <a href="#?query=title=&quot;{../mods:titleInfo/mods:title}&quot;" class="stichwort"><xsl:value-of select="../mods:titleInfo/mods:title"/></a>
            <xsl:value-of select="'. '||_:dict('place')||': '||(if (mods:place/mods:placeTerm) then mods:place/mods:placeTerm else _:dict('no-place-abbr'))"/>
            <xsl:value-of select="if (mods:publisher) then ', ' else ''"/>
            <xsl:call-template name="link-with-number-of-records">                
                <xsl:with-param name="index">publisher</xsl:with-param>
                <xsl:with-param name="term" select="mods:publisher"/>    
            </xsl:call-template>
            <xsl:call-template name="full-Date">
                <xsl:with-param name="pretext" select="', '" />
            </xsl:call-template>
            <xsl:value-of select="if (../mods:part/mods:extent[@unit eq 'page']) 
                then ', '||_:dict('pages')||' '||string-join(../mods:part/mods:extent[@unit eq 'page']/(mods:start, mods:end), '–') 
                else ''"/>
        </li>
    </xsl:template>
    
    <!-- "Weitere bibliographosche Angaben" (mode="more-detail") -->
    
    <xd:doc>
        <xd:desc>Serien und andere Details zusammenstellen</xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type eq 'series']" mode="more-detail">
        <li class="eSegment"><xsl:value-of select="_:dict('series')"/></li>
        <li><xsl:call-template name="link-with-number-of-records">
                <xsl:with-param name="index">series</xsl:with-param>
                <xsl:with-param name="term" select=".//mods:title"/>
            </xsl:call-template>
           <xsl:apply-templates mode="more-detail" select="* except mods:titleInfo"/></li>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Bandangaben</xd:desc>
    </xd:doc>
    <xsl:template match="mods:part[mods:detail[@type eq 'volume']]" mode="more-detail">
        <xsl:value-of select="', '||_:dict('vol-abbr')||' '||mods:detail[@type eq 'volume']"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Details, Kollationsvermerk (Sammeltemplate)</xd:desc>
    </xd:doc>
    <xsl:template match="mods:physicalDescription" mode="more-detail">
        <li class="eSegment">Kollationsvermerk</li>
        <xsl:apply-templates mode="more-detail"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Seitenangaben</xd:desc>
    </xd:doc>
    <xsl:template match="mods:extent" mode="more-detail">
        <li><xsl:value-of select=".||' '||_:dict(@unit||'s')"/></li>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Sonstige Details</xd:desc>
    </xd:doc>
    <xsl:template match="mods:note" mode="more-detail">
        <li><xsl:value-of select="."/></li>
    </xsl:template>
    
   
    <xd:doc>
        <xd:desc>Angabe zum Original </xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type eq 'original']" mode="more-detail">
        <li class="eSegment">Original</li>
        <li>
            <xsl:for-each select="./node()">
                <xsl:value-of select=" if (position() ne last()) then . ||', ' else ''"/>
            </xsl:for-each>
        </li>
    </xsl:template> 
    <xd:doc>
        <xd:desc>Review </xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type eq 'reviewOf']" mode="more-detail">
        <li class="eSegment">Rezensiertes Werk </li>
        <li><xsl:apply-templates select="mods:name" />
            <xsl:for-each select="./mods:originInfo">
                <xsl:call-template name="full-Date" >
                    <xsl:with-param name="pretext" select="', '"/>
                </xsl:call-template>
            </xsl:for-each>
            <xsl:apply-templates select="mods:title" /> 
        </li>
    </xsl:template> 
    <xd:doc>
        <xd:desc>Andere Version </xd:desc>
    </xd:doc>
    <xsl:template match="mods:relatedItem[@type eq 'otherVersion']" mode="more-detail">
        <li class="eSegment">Andere Version</li>
        <li>
            <xsl:for-each select="./node()">
                <xsl:value-of select=" if (position() ne last()) then . ||', ' else ''"/>
            </xsl:for-each>
        </li>
    </xsl:template>
       
    <xd:doc>
        <xd:desc>Thesaurus-Schlagworte</xd:desc>
    </xd:doc>
    <xsl:template name="primary-subjects">
        <xsl:param name="topic"  as="xs:string" /> 
        <xsl:if test="mods:subject[@usage = 'primary']
            [following-sibling::mods:subject[@usage = 'secondary'][mods:topic[. = $topic]]]">            
            <li class="eSegment"><xsl:value-of select="$topic"/></li>
            <xsl:for-each select="mods:subject[@usage = 'primary']
                [following-sibling::mods:subject[@usage = 'secondary'][1][mods:topic[. = $topic]]]/mods:topic">
                <li><xsl:call-template name="link-with-number-of-records">
                    <xsl:with-param name="index">subject</xsl:with-param>
                    <xsl:with-param name="term" select="."/>
                </xsl:call-template></li>
            </xsl:for-each>            
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Fußnoten</xd:desc>
    </xd:doc> 
    <xsl:template match="mods:note[@type eq 'footnotes']" mode="more-detail">        
        <li class="eSegment">Bemerkungen</li>
        <li><xsl:value-of select="."/></li>        
    </xsl:template>
    
    
    <xsl:template name="keywords">
        <xsl:param name="keywords" as="element(mods:subject)*"/>
        <xsl:if test="$keywords">
        <li class="eSegment">Stichworte</li>
        <li><xsl:for-each select="$keywords">
            <a href="#?query=&quot;{.}&quot;" class="stichwort" title="neue Suche starten"><xsl:value-of select="."/></a><xsl:value-of select="if (position() ne last()) then '; ' else ''"/>
        </xsl:for-each>
        </li></xsl:if>
    </xsl:template>
    
    <!-- Taxonomy -->
   
    <xsl:template match="taxonomy">
        <ol class="schlagworte showResults"><xsl:apply-templates select="*"/></ol>
    </xsl:template>
    
    <xsl:template match="category[matches(@n, '^[123456789]$')]">
        <xsl:param name="base-path" tunnel="yes">#</xsl:param>
        <li class="li1">
            <span><xsl:value-of select="catDesc"/></span><!-- auf der obersten Ebene kein query-link! BS-->
            <ol><xsl:apply-templates select="category"/></ol>           
        </li>
    </xsl:template> 
    <xsl:template match="category">
        <li> <span class="wrapTerm">
            <span class="term {if (category) then 'plusMinus' else ''}"
                title="{if (category) then 'Unterschlagworte zeigen/ verbergen' else ''}"><xsl:value-of select="catDesc"/></span>
            <a href="#?query=subject%3D&quot;{catDesc}&quot;" class="zahl aFilter" title="Suche filtern"><xsl:value-of select="numberOfRecords"/></a> 
        </span>
            <xsl:if test="category">
                <ol style="display:none;"><xsl:apply-templates select="category"/></ol>
            </xsl:if>
        </li>
    </xsl:template> 
    <xsl:template match="numberOfRecords">
        <xsl:param name="href" as="xs:string">#</xsl:param>        
        <xsl:param name="title" as="xs:string">neue Suche starten</xsl:param>
        <a href="{$href}" class="zahl eintrag" title="{$title}"><xsl:value-of select="."/></a>
    </xsl:template> 
    <xsl:template match="mods:_match_">
        <strong><xsl:value-of select="."/></strong>
    </xsl:template>
    
</xsl:stylesheet>