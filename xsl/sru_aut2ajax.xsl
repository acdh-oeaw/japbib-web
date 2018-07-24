<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:sru="http://www.loc.gov/zing/srw/"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs sru"
    version="3.0">
    
    <xsl:output indent="yes" method="xhtml"/>
    
    <xsl:import href="sru2ajax.xsl"/>
    
    <!-- Grundidee: sru erstellt eine distinkte Liste von Autoren (möglicherweise begrenzt auf 100) und ordnet sie alphabetisch; 
         sru_aut2ajax formatiert die Liste;
         ein js-script fragt beim server für jeden Autor nach "author and currentQuery > numberOfRecords"
         trägt die Frage bei jedem Listeneintrag in href ein,
         setzt die ermittelte Zahl in das jeweilige a-Tag ein
         und ordnet die Liste nach Anzahl der Treffer.
         Der User kann die Liste auch alphab. darstellen lassen.         
         -->
    
    <xsl:template match="/">
        <div class="ajax-result">
            <div class="search-result">
                <xsl:apply-templates select="sru:recordsAut"/>                
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="sru:recordsAuts">
        <ol data-numberOfRecords="{/sru:searchRetrieveResponse/sru:norAuts}" 
            class="listAuthorsByResult results">
            <xsl:apply-templates select="*"/>
        </ol>
    </xsl:template>    
    
    <xsl:template match="sru:recordAut">
        <li> 
            <xsl:apply-templates select="sru:recordDataAut/mods:name"/>
        </li>         
    </xsl:template>      
    
    <xsl:template match="mods:name" >
        <xsl:variable name="aut" select="mods:namePart"/>
        <xsl:variable name="hits" select="//sru:recordDataAut/sru:norAut"/>
        <span class="author"><xsl:value-of select="$aut"/></span>
        <!-- in href wird von js die aktuelle query hinzugefügt -->
        <a href="#find?query=author=&quot;{$aut}&quot;"></a>
    </xsl:template>
    
    <xsl:template match="catDesc"> 
        <xsl:value-of select="."/>
    </xsl:template> 

</xsl:stylesheet>