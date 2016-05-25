<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:output method="html"/>
	<xsl:template match="/">
		<html>
		<head>
			<title>Performance Report</title>
			<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
			<style type="text/css">
			.trlevel1 {
				font-size: 12pt; color: #276692; font-family: consolas; font-weight: bold; background-color: #a8dbdb;
			}
			.trlevel2 {
				font-size: 12pt; color: #276692; font-family: consolas; background-color: #dce5ec;
			}
			.tdtitle{
				font-size: 12pt; color: #276692; font-family: consolas; font-weight: bold; text-align: center; word-break: break-all;
			}
			.tdtitle_left{
				font-size: 10pt; color: #276692; font-family: consolas; text-align: left; word-break: break-all;
			}
			.tdresult_highlight{
				font-size: 10pt; color: black; font-family: consolas; font-weight: bold; text-align: center; word-break: break-all; background-color: #dce5ec;
			}
			.tdresult{
				font-size: 10pt; font-family: consolas; font-weight: bold; text-align: center; word-break: break-all;
			}
			.tdresult_left{
				font-size: 10pt; font-family: consolas; font-weight: bold; text-align: left; word-break: break-all;
			}
			.tdresult_bigred{
				font-size: 10pt; font-family: consolas; font-weight: bold; text-align: center; word-break: break-all; background-color: #ff0000;
			}
			.tdresult_smallred{
				font-size: 10pt; font-family: consolas; font-weight: bold; text-align: center; word-break: break-all; background-color: #ffacac;
			}
			.tdresult_biggreen{
				font-size: 10pt; font-family: consolas; font-weight: bold; text-align: center; word-break: break-all; background-color: #30e450;
			}
			.tdresult_smallgreen{
				font-size: 10pt; font-family: consolas; font-weight: bold; text-align: center; word-break: break-all; background-color: #b6f5c1;
			}
		</style>
		</head>
		<body topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
			<br /><a href="index.html">返回列表</a>
			<h2 align="center" style="font-size: 16pt; color: #276692; font-family:consolas">Performance Report</h2>
			<hr />
			<div>
			<table align="center" cellpadding="0" cellspacing="0" border="2" style="border-collapse: collapse;" width="90%">
				<tr class="trlevel1">
					<td colspan="2" align="center">statistical information for the last ten</td>
				</tr>
				<tr>
					<td><img src="http://10.67.200.138/ugw0_Update_OPS.PNG" alt="ugw-ops"/></td>
					<td><img src="http://10.67.200.138/ugw0_Update_CPU.PNG" alt="ugw-cpu"/></td>
				</tr>
				<tr>
					<td><img src="http://10.67.200.138/usn0_Update_OPS.PNG" alt="usn-ops"/></td>
					<td><img src="http://10.67.200.138/usn0_Update_CPU.PNG" alt="usn-cpu"/></td>
				</tr>
				<tr>
					<td><img src="http://10.67.200.138/simpleX_Update_OPS.PNG" alt="simpleX-ops"/></td>
					<td><img src="http://10.67.200.138/simpleX_Update_CPU.PNG" alt="simpleX-cpu"/></td>
				</tr>
			</table>
			</div>
			<br />
			<div>
			<table align="center" cellpadding="0" cellspacing="0" border="2" style="border-collapse: collapse;" width="90%">
				<tr class="trlevel1">
					<td class="tdtitle">-</td>
					<td class="tdtitle">Build ID</td>
					<td class="tdtitle">PKG</td>
					<td class="tdtitle">MD5</td>
					<td class="tdtitle">Git Number</td>
				</tr>
				<tr>
					<td class="tdresult">本次测试版本</td>
					<td class="tdresult"><xsl:value-of select="/build/now/@build_id"/></td>
					<td class="tdresult"><xsl:value-of select="/build/now/@pkg"/></td>
					<td class="tdresult"><xsl:value-of select="/build/now/@md5sum"/></td>
					<td class="tdresult"><xsl:value-of select="/build/now/@git"/></td>
				</tr>
				<tr>
					<td class="tdresult">基线测试版本</td>
					<td class="tdresult"><xsl:value-of select="/build/base/@build_id"/></td>
					<td class="tdresult"><xsl:value-of select="/build/base/@pkg"/></td>
					<td class="tdresult"><xsl:value-of select="/build/base/@md5sum"/></td>
					<td class="tdresult"><xsl:value-of select="/build/base/@git"/></td>
				</tr>
				<tr>
					<td class="tdresult">上次测试版本</td>
					<td class="tdresult"><xsl:value-of select="/build/last/@build_id"/></td>
					<td class="tdresult"><xsl:value-of select="/build/last/@pkg"/></td>
					<td class="tdresult"><xsl:value-of select="/build/last/@md5sum"/></td>
					<td class="tdresult"><xsl:value-of select="/build/last/@git"/></td>
				</tr>
			</table>
			</div>
			<br />
			<div>
			<table align="center" cellpadding="0" cellspacing="0" border="2" style="border-collapse: collapse;" width="90%">
				<tr class="trlevel1">
					<td class="tdtitle">操作</td>
					<td class="tdtitle" colspan="5">Insert</td>
					<td class="tdtitle" colspan="5">Update(Target:20000 ops/CORE)</td>
					<td class="tdtitle" colspan="5">Read</td>
					<td class="tdtitle" colspan="5">Delete</td>
					<td class="tdtitle" colspan="5">Append</td>
				</tr>
				<tr class="trlevel2">
					<td class="tdtitle_left">模型\指标</td>
					<td class="tdresult_highlight">吞吐量(ops/CORE)</td>
					<td class="tdtitle_left">对比基线(%)</td>
					<td class="tdtitle_left">对比上次(%)</td>
					<td class="tdtitle_left">时延(min,median,avg/us)</td>
					<td class="tdtitle_left">占用CPU</td>
					<td class="tdresult_highlight">吞吐量(ops/CORE)</td>
					<td class="tdtitle_left">对比基线(%)</td>
					<td class="tdtitle_left">对比上次(%)</td>
					<td class="tdtitle_left">时延(min,median,avg/us)</td>
					<td class="tdtitle_left">占用CPU</td>
					<td class="tdresult_highlight">吞吐量(ops/CORE)</td>
					<td class="tdtitle_left">对比基线(%)</td>
					<td class="tdtitle_left">对比上次(%)</td>
					<td class="tdtitle_left">时延(min,median,avg/us)</td>
					<td class="tdtitle_left">占用CPU</td>
					<td class="tdresult_highlight">吞吐量(ops/CORE)</td>
					<td class="tdtitle_left">对比基线(%)</td>
					<td class="tdtitle_left">对比上次(%)</td>
					<td class="tdtitle_left">时延(min,median,avg/us)</td>
					<td class="tdtitle_left">占用CPU</td>
					<td class="tdresult_highlight">吞吐量(ops/CORE)</td>
					<td class="tdtitle_left">对比基线(%)</td>
					<td class="tdtitle_left">对比上次(%)</td>
					<td class="tdtitle_left">时延(min,median,avg/us)</td>
					<td class="tdtitle_left">占用CPU</td>
				</tr>
				<xsl:for-each select="/build/model">
					<tr>
						<td class="tdresult"><xsl:value-of select="@name"/></td>
						<xsl:for-each select="result">
							<xsl:variable name="var_compbase" select="compbase"/>
							<xsl:variable name="var_complast" select="complast"/>
							<td class="tdresult_highlight"><xsl:value-of select="ops"/></td>
							<xsl:choose>
								<xsl:when test="$var_compbase &gt; 5">
									<td class="tdresult_biggreen" ><xsl:value-of select="compbase"/></td>
								</xsl:when>
								<xsl:when test="$var_compbase &gt; 2">
									<td class="tdresult_smallgreen" ><xsl:value-of select="compbase"/></td>
								</xsl:when>
								<xsl:when test="$var_compbase &lt; -5">
									<td class="tdresult_bigred" ><xsl:value-of select="compbase"/></td>
								</xsl:when>
								<xsl:when test="$var_compbase &lt; -2">
									<td class="tdresult_smallred" ><xsl:value-of select="compbase"/></td>
								</xsl:when>
								<xsl:otherwise>
									<td class="tdresult" ><xsl:value-of select="compbase"/></td>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:choose>
								<xsl:when test="$var_complast &gt; 5">
									<td class="tdresult_biggreen" ><xsl:value-of select="complast"/></td>
								</xsl:when>
								<xsl:when test="$var_complast &gt; 2">
									<td class="tdresult_smallgreen" ><xsl:value-of select="complast"/></td>
								</xsl:when>
								<xsl:when test="$var_complast &lt; -5">
									<td class="tdresult_bigred" ><xsl:value-of select="complast"/></td>
								</xsl:when>
								<xsl:when test="$var_complast &lt; -2">
									<td class="tdresult_smallred" ><xsl:value-of select="complast"/></td>
								</xsl:when>
								<xsl:otherwise>
									<td class="tdresult" ><xsl:value-of select="complast"/></td>
								</xsl:otherwise>
							</xsl:choose>
							<td class="tdresult"><xsl:value-of select="latency"/></td>
							<td class="tdresult"><xsl:value-of select="cpu"/></td>
						</xsl:for-each>
					</tr>
				</xsl:for-each>
			</table>
			</div>
			<br />
			<br />
			<br />
			<div>
			<table align="center" cellpadding="0" cellspacing="0" border="2" style="border-collapse: collapse;" bordercolor="#dce5ec" width="90%">
				<tr>
					<td class="tdtitle">组网图</td>
					<td class="tdresult_left">
						<img src="http://10.67.200.138/network_new.PNG" alt="组网"/>
					</td>
				</tr>
			</table>
			</div>
		</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
