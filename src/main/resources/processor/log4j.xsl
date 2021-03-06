<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:conf="http://yurconf.org"
    xmlns:c="http://yurconf.org/component"
	xmlns:bcl="http://log.yurconf.org"
    xmlns:log4j="http://jakarta.apache.org/log4j/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs bcl c conf" version="2.0">

    <xsl:import href="yurconf://@org.yurconf.base/repo-base.xsl" />
    <xsl:import href="yurconf://@org.yurconf.base/conf-reference.xsl" />

    <xsl:output encoding="UTF-8" method="xml" doctype-system="log4j.dtd" />

    <xsl:param name="configurationComponentId" />

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
        <log4j:configuration debug="false">
            <xsl:variable name="refs"
                select="bcl:logger[c:component[@id=$configurationComponentId]]/bcl:appender-ref/@ref" />
            <xsl:apply-templates
                select="(bcl:console-appender | bcl:rolling-file-appender | bcl:generic-appender )[@name=$refs or c:component/@id=$configurationComponentId]" />
            <xsl:apply-templates select="bcl:logger[c:component[@id=$configurationComponentId]][@name!='ROOT']" />
            <xsl:apply-templates select="bcl:logger[c:component[@id=$configurationComponentId]][@name='ROOT']" />
        </log4j:configuration>
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

    <xsl:template match="bcl:console-appender">
        <appender class="org.apache.log4j.ConsoleAppender">
            <xsl:attribute name="name">
                <xsl:value-of select="@name" />
            </xsl:attribute>
            <param name="Target" value="System.out" />
            <xsl:apply-templates select="bcl:layout" />
        </appender>
    </xsl:template>

    <xsl:template name="appender-pseudo-name">
        <xsl:param name="name" />
        <xsl:attribute name="{$name}">
            <xsl:text>PSEUDO_</xsl:text>
            <xsl:choose>
                <xsl:when test="@id">
                    <xsl:value-of select="@id" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>

    <xsl:template name="async-appender">
        <appender class="org.apache.log4j.AsyncAppender">
            <xsl:attribute name="name">
                <xsl:value-of select="@name" />
            </xsl:attribute>
            <appender-ref>
                <xsl:call-template name="appender-pseudo-name">
                    <xsl:with-param name="name">
                        <xsl:text>ref</xsl:text>
                    </xsl:with-param>
                </xsl:call-template>
            </appender-ref>
        </appender>
    </xsl:template>

    <xsl:template match="bcl:layout">
        <layout class="org.apache.log4j.PatternLayout">
            <param name="ConversionPattern">
                <xsl:attribute name="value">
                    <xsl:value-of select="." />
                </xsl:attribute>
            </param>
        </layout>
    </xsl:template>

    <xsl:template match="bcl:rolling-file-appender/@name | bcl:file-appender/@name">
        <xsl:call-template name="appender-pseudo-name">
            <xsl:with-param name="name">
                <xsl:text>name</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="bcl:rolling-file-appender/@maxSize">
        <param name="MaxFileSize">
            <xsl:attribute name="value">
                <xsl:value-of select="." />
            </xsl:attribute>
        </param>
    </xsl:template>

    <xsl:template match="bcl:rolling-file-appender/@backupIndex">
        <param name="MaxBackupIndex">
            <xsl:attribute name="value">
                <xsl:value-of select="." />
            </xsl:attribute>
        </param>
    </xsl:template>

    <xsl:template match="bcl:rolling-file-appender">
        <xsl:call-template name="async-appender" />
        <appender class="org.apache.log4j.RollingFileAppender">
            <xsl:apply-templates select="@name" />
            <xsl:call-template name="log-file" />
            <xsl:apply-templates select="@maxSize" />
            <xsl:apply-templates select="@backupIndex" />
            <xsl:apply-templates />
        </appender>
    </xsl:template>

    <xsl:template match="bcl:file-appender">
        <xsl:call-template name="async-appender" />
        <appender class="org.apache.log4j.FileAppender">
            <xsl:apply-templates select="@name" />
            <xsl:call-template name="log-file" />
            <xsl:apply-templates />
        </appender>
    </xsl:template>

    <xsl:template match="bcl:logger[@name='ROOT']">
        <root>
            <xsl:apply-templates select="@level" />
            <xsl:apply-templates select="bcl:appender-ref" />
        </root>
    </xsl:template>

    <xsl:template match="bcl:logger">
        <category>
            <xsl:apply-templates select="@name" />
            <xsl:apply-templates select="@additivity" />
            <xsl:apply-templates select="@level" />
            <xsl:apply-templates select="bcl:appender-ref" />
        </category>
    </xsl:template>

    <xsl:template match="bcl:logger/@name">
        <xsl:attribute name="name">
            <xsl:value-of select="." />
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="bcl:logger/@additivity">
        <xsl:attribute name="additivity">
            <xsl:value-of select="." />
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="bcl:logger/@level">
        <level>
            <xsl:attribute name="value">
                <xsl:value-of select="." />
            </xsl:attribute>
        </level>
    </xsl:template>

    <xsl:template match="bcl:appender-ref">
        <appender-ref>
            <xsl:attribute name="ref">
                <xsl:value-of select="@ref" />
            </xsl:attribute>
        </appender-ref>
    </xsl:template>

    <xsl:template name="log-file">
        <param name="File">
            <xsl:attribute name="value">
                <xsl:call-template name="build-log-file-path">
                    <xsl:with-param name="file" select="@file" />
                </xsl:call-template>
            </xsl:attribute>
        </param>
    </xsl:template>

    <xsl:template name="build-log-file-path">
        <xsl:param name="file" />
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
