<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:bcl="http://log.yurconf.org"
    xmlns:c="http://yurconf.org/component"
    xmlns:conf="http://yurconf.org"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs bcl c conf" version="2.0">

    <xsl:import href="yurconf://@org.yurconf.base/repo-base.xsl" />
    <xsl:import href="yurconf://@org.yurconf.base/conf-reference.xsl" />

    <xsl:output encoding="UTF-8" method="xml" />

    <xsl:param name="configurationComponentId"/>

    <xsl:template match="/">
        <xsl:variable name="root">
            <xsl:copy-of select="conf:configuration-source/conf:request" />
            <xsl:apply-templates select="conf:configuration-source/conf:request" mode="load-document-with-variants">
                <xsl:with-param name="prefix" select="'log'" />
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:apply-templates select="$root/bcl:configuration" />
    </xsl:template>

    <xsl:template match="bcl:configuration">
        <configuration>
            <xsl:variable name="refs" select="bcl:logger[c:component[@id=$configurationComponentId]]/bcl:appender-ref/@ref" />
            <xsl:apply-templates select="(bcl:console-appender | bcl:file-appender | bcl:rolling-file-appender | bcl:generic-appender)[@name=$refs or c:component/@id=$configurationComponentId]"/>
            <xsl:apply-templates select="bcl:logger[c:component[@id=$configurationComponentId]]"/>
        </configuration>
    </xsl:template>

    <xsl:template match="c:component" mode="deep-copy-generic">
    </xsl:template>

    <xsl:template match="*" mode="deep-copy-generic">
        <xsl:param name="name" select="name()"></xsl:param>
        <xsl:element name="{$name}">
            <xsl:copy-of select="@*" />
            <xsl:apply-templates select="*" mode="deep-copy-generic" />
            <xsl:if test="text()">
                <xsl:value-of select="text()" />
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="bcl:generic-appender">
        <xsl:comment>
            <xsl:text>Using of generic appenders in log configuration source. </xsl:text>
            <xsl:text>This is not portable across the different logging frameworks. </xsl:text>
            <xsl:text>Use it on your own risk. </xsl:text>
        </xsl:comment>
        <xsl:apply-templates select="." mode="deep-copy-generic">
            <xsl:with-param name="name" select="'appender'" />
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="bcl:logger[@name='ROOT']">
        <root>
            <xsl:apply-templates select="@level"/>
            <xsl:apply-templates select="bcl:appender-ref"/>
        </root>
    </xsl:template>

    <xsl:template match="bcl:logger/@level">
        <xsl:attribute name="level">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="bcl:appender-ref">
        <appender-ref>
            <xsl:attribute name="ref">
                <xsl:value-of select="@ref"/>
            </xsl:attribute>
        </appender-ref>
    </xsl:template>

    <xsl:template match="bcl:logger">
        <logger>
            <xsl:apply-templates select="@name"/>
            <xsl:apply-templates select="@additivity"/>
            <xsl:apply-templates select="@level"/>
            <xsl:apply-templates select="bcl:appender-ref"/>
        </logger>
    </xsl:template>

    <xsl:template match="bcl:logger/@name">
        <xsl:attribute name="name">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="bcl:logger/@additivity">
        <xsl:attribute name="additivity">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="bcl:console-appender">
        <appender class="ch.qos.logback.core.ConsoleAppender">
            <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
            </xsl:attribute>

            <xsl:apply-templates select="bcl:layout"/>
        </appender>
    </xsl:template>

    <xsl:template match="bcl:layout">
        <encoder>
            <pattern>
                <xsl:value-of select="."/>
            </pattern>
        </encoder>
    </xsl:template>

    <xsl:template match="bcl:file-appender">
        <appender class="ch.qos.logback.core.FileAppender">
            <xsl:apply-templates select="@name"/>
            <xsl:call-template name="log-file" />
            <xsl:apply-templates />
        </appender>
    </xsl:template>

    <xsl:template match="bcl:append">
        <append>
            <xsl:value-of select="."/>
        </append>
    </xsl:template>

    <xsl:template match="bcl:rolling-file-appender">
        <appender class="ch.qos.logback.core.rolling.RollingFileAppender">
            <xsl:apply-templates select="@name"/>
            <xsl:call-template name="log-file" />
            <xsl:apply-templates select="@backupIndex"/>
            <xsl:apply-templates select="@maxSize"/>
            <xsl:apply-templates />
        </appender>
    </xsl:template>

    <xsl:template match="bcl:file-appender/@name | bcl:rolling-file-appender/@name">
        <xsl:attribute name="name">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="bcl:rolling-file-appender/@maxSize">
        <triggeringPolicy class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy">
            <maxFileSize>
                <xsl:value-of select="."/>
            </maxFileSize>
        </triggeringPolicy>
    </xsl:template>

    <xsl:template match="bcl:rolling-file-appender/@backupIndex">
        <rollingPolicy class="ch.qos.logback.core.rolling.FixedWindowRollingPolicy">
            <fileNamePattern>
                <xsl:call-template name="build-log-file-path">
                    <xsl:with-param name="file" select="../@file" />
                </xsl:call-template>
                <xsl:text>-%i</xsl:text>
                <xsl:if test="../@compression">
                    <xsl:text>.</xsl:text>
                    <xsl:value-of select="../@compression"></xsl:value-of>
                </xsl:if>
            </fileNamePattern>
            <minIndex>
                <xsl:text>1</xsl:text>
            </minIndex>
            <maxIndex>
                <xsl:value-of select="."/>
            </maxIndex>
        </rollingPolicy>
    </xsl:template>

    <xsl:template name="log-file">
        <file>
            <xsl:call-template name="build-log-file-path">
                <xsl:with-param name="file" select="@file"/>
            </xsl:call-template>
        </file>
    </xsl:template>

    <xsl:template name="build-log-file-path">
        <xsl:param name="file" select="'DEFAULT'" />
        <xsl:choose>
            <xsl:when test="empty($file)">
                <xsl:value-of select="$configurationComponentId" />
                <xsl:text>.log</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$file" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
