<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output media-type="text/plain" method="text"></xsl:output>
    <xsl:strip-space elements="*"/>
    <xsl:variable name="context" select="xs:integer(5)"/>
    <xsl:variable name="max_context_length" select="xs:integer(32)"/>
    <xsl:variable name="base_url" select="'http://www.perseids.org/tools/arethusa/app/#/jmh?collid=lattb&amp;objid=7229&amp;doc=lattb.7229.1&amp;chunk=SENTENCE&amp;w=WORD'"/>
    <xsl:param name="doc" select="'phi0959.phi006'"/>

    <xsl:template match="/">
        <xsl:variable name="annotations">
            <xsl:apply-templates select="//word"></xsl:apply-templates>    
        </xsl:variable>
        [ <xsl:value-of select="string-join($annotations/*/text(),',&#xa;')"/>]
    </xsl:template>
    
    
    <xsl:template match="word">
        <xsl:variable name="preceding">
            <xsl:call-template name="gather-previous">
                <xsl:with-param name="word" select="."></xsl:with-param>
                <xsl:with-param name="preceding" select="preceding-sibling::word"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="exact">
            <xsl:value-of select="replace(@form,'&quot;','\\&quot;')"/>
        </xsl:variable>
        <xsl:variable name="next">
            <xsl:call-template name="gather-next">
                <xsl:with-param name="word" select="."></xsl:with-param>
                <xsl:with-param name="next" select="following-sibling::word"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="prefix">
            <xsl:call-template name="truncate">
                <xsl:with-param name="full" select="replace(string-join($preceding/*/@form,' '),'&quot;','\\&quot;')"></xsl:with-param>
                <xsl:with-param name="direction" select="'backward'"></xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="suffix">
            <xsl:call-template name="truncate">
                <xsl:with-param name="full" select="replace(string-join($next/*/@form,' '),'&quot;','\\&quot;')"></xsl:with-param>
                <xsl:with-param name="direction" select="'forward'"></xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="string-length($suffix) gt $max_context_length">
            <xsl:message><xsl:value-of select="$suffix"/> <xsl:value-of select="string-length($suffix)"/></xsl:message>    
        </xsl:if>
        <xsl:variable name="exact"><xsl:text>"exact":"</xsl:text><xsl:value-of select="$exact"/><xsl:text>"</xsl:text></xsl:variable>
        <xsl:variable name="prefix"><xsl:text>"prefix":"</xsl:text><xsl:value-of select="$prefix"/><xsl:text>"</xsl:text></xsl:variable>
        <xsl:variable name="suffix"><xsl:text>"suffix":"</xsl:text><xsl:value-of select="$suffix"/><xsl:text>"</xsl:text></xsl:variable>
        <xsl:variable name="url" select="replace(replace(replace($base_url,'DOC',$doc),'SENTENCE',parent::sentence/@id),'WORD',@id)"></xsl:variable>
        <annotation>
            <xsl:text>{"@context": "http://www.w3.org/ns/anno.jsonld","type": "Annotation","body":"</xsl:text><xsl:value-of select="$url"/><xsl:text>","target": {"selector": { "type": "TextQuoteSelector", </xsl:text><xsl:value-of select="string-join(($exact,$prefix,$suffix),', ')"/><xsl:text>}}}</xsl:text>
        </annotation>        
    </xsl:template>
    
    <xsl:template name="gather-previous">
        <xsl:param name="word"/>
        <xsl:param name="preceding"/>
        <xsl:param name="gathered" select="()"/>
        <xsl:choose>
            <xsl:when test="(count($gathered) lt $context and count($preceding) gt 0)">
                <xsl:variable name="new">
                    <xsl:copy-of select="$gathered"/>
                    <xsl:copy-of select="$preceding[last()]"/>
                </xsl:variable>
                <xsl:call-template name="gather-previous">
                    <xsl:with-param name="word" select="$word"/>
                    <xsl:with-param name="gathered" select="$new/*"/>
                    <xsl:with-param name="preceding" select="$preceding[position() != last()]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="(count($gathered) lt $context) and $word/parent::sentence/preceding-sibling::sentence">
                <xsl:call-template name="gather-previous">
                    <xsl:with-param name="word" select="$word"/>
                    <xsl:with-param name="gathered" select="$gathered"/>
                    <xsl:with-param name="preceding" select="($word/parent::sentence/preceding-sibling::sentence)[last()]/word"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="reverse($gathered)"></xsl:copy-of>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="gather-next">
        <xsl:param name="word"/>
        <xsl:param name="next"/>
        <xsl:param name="gathered" select="()"/>
        <xsl:choose>
            <xsl:when test="(count($gathered) lt $context and count($next) gt 0)">
                <xsl:variable name="new">
                    <xsl:copy-of select="$gathered"/>
                    <xsl:copy-of select="$next[1]"/>
                </xsl:variable>
                <xsl:call-template name="gather-next">
                    <xsl:with-param name="word" select="$word"/>
                    <xsl:with-param name="gathered" select="$new/*"/>
                    <xsl:with-param name="next" select="$next[position() gt 1]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="(count($gathered) lt $context) and $word/parent::sentence/following-sibling::sentence">
                <xsl:call-template name="gather-next">
                    <xsl:with-param name="word" select="$word"/>
                    <xsl:with-param name="gathered" select="$gathered"/>
                    <xsl:with-param name="next" select="($word/parent::sentence/following-sibling::sentence)[1]/word"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$gathered"></xsl:copy-of>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="truncate">
        <xsl:param name="full"></xsl:param>
        <xsl:param name="direction" select="'forward'"></xsl:param>
        <xsl:variable name="length" select="string-length($full)"/>
        <xsl:choose>
            <xsl:when test="$length lt $max_context_length">
                <xsl:copy-of select="$full"></xsl:copy-of>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$direction = 'forward'">
                        <xsl:value-of select="substring($full,xs:integer($length - $max_context_length + 1),$max_context_length)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring($full,1,$max_context_length)"/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>