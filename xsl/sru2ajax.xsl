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
    
    <xsl:template match="/">
        <div class="ajax-result">
            <div class="search-result">
                <xsl:apply-templates
                    select="sru:searchRetrieveResponse/sru:records"/>                
            </div>
<!--            <div class="categoryFilter">
                <xsl:apply-templates
                    select="sru:searchRetrieveResponse/sru:extraResponseData/subjects/taxonomy"/>
            </div>-->
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
        <xsl:if test="not(mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')])"><span class="authors">_:dict('no-aut-abbr')</span></xsl:if>
        <xsl:apply-templates select="mods:name[mods:role/mods:roleTerm = 'aut']"/><xsl:text>,</xsl:text>
        <xsl:if test="not(mods:originInfo/mods:dateIssued)"><span class="year"><xsl:value-of select="concat('[',_:dict('no-year-abbr'),']')"/></span></xsl:if>
        <xsl:apply-templates select="mods:originInfo/mods:dateIssued"/>
        <xsl:apply-templates select="." mode="detail"/>
<!--        <a href="{$base-uri-public}?version={$version}&amp;operation=searchRetrieve&amp;x-style=sru2html.xsl&amp;query=id={mods:recordInfo/mods:recordIdentifier}" class="sup" target="_blank"><xsl:apply-templates select="mods:titleInfo"/></a>-->
    </xsl:template>
    
    <xsl:template match="mods:mods" mode="detail">
        <div class="showEntry">
            <div class="showOptions">
                <label>Anzeige des Eintrags: <select name="top5" size="1">
                        <option selected="selected">detailliert</option>
                        <option>MODS</option>
                        <option>Lidos</option>
                    </select>
                </label>
                <span class="erklärung">
                    <span> „Detailliert“ enthält auch Stichworte, über die neue Suchabfragen möglich
                        sind. Alle weiteren Optionen sind für das Kopieren in andere Formate
                        gedacht. </span>
                </span>
            </div>

            <ul><xsl:apply-templates mode="detail"/></ul>
<!--            <p>
                <b>Verwandte Suchabfragen</b>
            </p>
            <ul>
                <li class="eSegment">Thema</li>
                <li>Religionswissenschaft (<a href="#" class="zahl" title="Suchergebnisse"
                    >40</a>)</li>
                <li>Brauchtum und Feste (<a href="#" class="zahl" title="Suchergebnisse"
                    >20</a>)</li>
                <li class="eSegment">Form</li>
                <li>Sammelwerk (<a href="#" class="zahl" title="Suchergebnisse">6.000</a>)</li>
                <li class="eSegment">Stichworte</li>
                <li><a href="#">Nishida Kitarō</a>; <a href="#">Karl Florenz</a>; <a href="#"
                        >Eihei-ji</a>; <a href="#">Ritual</a>; <a href="#">Invented traditions</a>;
                        <a href="#autor">Tagungsbericht</a>
                </li>

            </ul>-->
        </div>
<!--        <div class="showMods" style="display:none;">
            <xsl:variable name="modsDoc">
                <xsl:copy-of select="." copy-namespaces="no"/>               
            </xsl:variable>
            <textarea rows="20" cols="80" class="codemirror-data" xml:space="preserve"><xsl:sequence select="_:serialize($modsDoc, $modsDoc//LIDOS-Dokument, $serialization-parameters/*)"/></textarea>
        </div>
        <div class="showLidos" style="display:none;">         
            <xsl:variable name="lidosDoc">
                <xsl:copy-of select=".//LIDOS-Dokument" copy-namespaces="no"/>               
            </xsl:variable>
            <textarea rows="20" cols="80" class="codemirror-data" xml:space="preserve"><xsl:sequence select="serialize($lidosDoc, $serialization-parameters/*)"/></textarea>
        </div>-->
    </xsl:template>
    
    <xsl:template match="*" mode="detail">
        <xsl:apply-templates select="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')][not(./ancestor::mods:relatedItem)]" mode="detail"/>
        <xsl:apply-templates select="mods:titleInfo[not(./ancestor::mods:relatedItem)]" mode="detail"/>
    </xsl:template>
    
    <xsl:template match="mods:xxx">
        
        <li class="eSegment"> Reihe </li>
        <li> Ostasien-Pazifik (<a href="#" class="zahl" title="Suchergebnisse">6</a>),
            Bd.5</li>
        <li class="eSegment"> Ort/Verlag/Jahr</li>
        <li> Hamburg: LIT-Verl. (<a href="#" class="zahl" title="Suchergebnisse">300</a>),
            1997 </li>
        <li class="eSegment"> Co-Autoren </li>
<!-- TODO       <li> Paul, G. (<a href="#" class="zahl" title="Suchergebnisse">6</a>), Naumann, N.
            (<a href="#" class="zahl" title="Suchergebnisse">6</a>); Ōbayashi, T (<a
                href="#" class="zahl" title="Suchergebnisse">6</a>); Blümmel, V. (<a
                    href="#" class="zahl" title="Suchergebnisse">6</a>), Vollmer, K. (<a
                        href="#" class="zahl" title="Suchergebnisse">6</a>), Zöllner, R. (<a
                            href="#" class="zahl" title="Suchergebnisse">6</a>), Lokowandt, H. (<a
                                href="#" class="zahl" title="Suchergebnisse">6</a>); Fischer, P. (<a
                                    href="#" class="zahl" title="Suchergebnisse">6</a>), Knecht, P. (<a href="#"
                                        class="zahl" title="Suchergebnisse">6</a>), Pörtner, P. (<a href="#"
                                            class="zahl" title="Suchergebnisse">6</a>), Toelken, R. (<a href="#"
                                                class="zahl" title="Suchergebnisse">6</a>), Woirgardt, M. (<a href="#"
                                                    class="zahl" title="Suchergebnisse">6</a>), Ikeda, H. (<a href="#"
                                                        class="zahl" title="Suchergebnisse">6</a>)</li>-->
        <li class="eSegment"> Kollationsvermerk </li>
        <li> 300 S. : Ill., graph. Darst., Notenbeisp.</li>
    </xsl:template>
    
    <xsl:template match="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]">
        <span class="authors"><xsl:value-of select="string-join(mods:namePart, '/ ')"/></span>
    </xsl:template>
    
    <xsl:template match="mods:name[mods:role/normalize-space(mods:roleTerm) = ('aut', 'edt')]" mode="detail">
        <xsl:variable name="scanClause" select="'author='||normalize-space(./mods:namePart)"/>
        <xsl:variable name="by-this-author" select="//sru:scanResponse[.//sru:scanClause eq $scanClause]//sru:numberOfRecords"/>
        <li class="eSegment"><xsl:value-of select="_:dict(mods:role/normalize-space(mods:roleTerm))"/></li>
        <li><xsl:value-of select="string-join(mods:namePart, '/ ')"/>(<a href="#{_:urlParameters()}" class="zahl" title="Suchergebnisse"><xsl:value-of select="$by-this-author"/></a>)<xsl:if test="mods:role/normalize-space(mods:roleTerm) eq 'edt'">,
            <xsl:value-of select="_:dict('edt')"/></xsl:if></li>
    </xsl:template>
    
    <xsl:template match="mods:dateIssued">
        <span class="year"><xsl:value-of select="."/></span>
    </xsl:template>
    
    <xsl:template match="mods:titleInfo">
        <span class="title"><xsl:apply-templates select="*"/></span>
    </xsl:template>
    
    <xsl:template match="mods:titleInfo" mode="detail">
        <li class="eSegment"><xsl:value-of select="_:dict('title')"/></li>
        <li> Rituale und ihre Urheber: Invented Traditions in der japanischen
            Religionsgeschichte</li>
    </xsl:template>
    
    <xsl:template match="mods:title"><xsl:value-of select="normalize-space(.)"/>.</xsl:template>
    
    <xsl:template match="mods:subTitle"><xsl:text xml:space="preserve"> </xsl:text><xsl:value-of select="normalize-space(.)"/>.</xsl:template>

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
        <li><span class="catNum"><xsl:value-of select="@n"/></span><span class="sup"><xsl:value-of select="catDesc"/></span>
            <xsl:if test="numberOfRecords">
                <a href="{$base-uri-public}?version={$version}&amp;operation=searchRetrieve&amp;x-style={$x-style}&amp;startRecord=1&amp;maximumRecords={$maximumRecords}&amp;query=subject%3D&quot;{catDesc}&quot;" class="zahl" title="Suchergebnisse"><xsl:value-of select="numberOfRecords"/></a>
            </xsl:if>
            <xsl:if test="category">
                <ol><xsl:apply-templates select="category"/></ol>
            </xsl:if>
        </li>
    </xsl:template>
    
</xsl:stylesheet>